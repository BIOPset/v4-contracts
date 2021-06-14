pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";




contract TieredVesting { 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public tokenAddress;
    address payable claimant;
    uint256 public total;//total tokens to send over vesting period
    uint256 public startTime;//start time of the vesting
    uint256 public claimed;//amount claimed so far
    uint256 public tiers;//the number of tiers
    uint256 public tierLength;//time for each tier
    uint256 public perTier;//tokens unlocked at each tier
    uint256 public tiersClaimed;//amount of tiers paid out

    constructor(address payable claimant_, address tokenAddress_, uint256 tiers_, uint256 tierLength_) public {
        claimant = claimant_;
        tokenAddress = tokenAddress_;
        tiers = tiers_;
        tierLength = tierLength_;
    }

     /**
    * @dev set the new claimant
    * @param new_ the new claimant's address
    */
    function updateClaimant(address payable new_) public onlyClaimant {
        claimant = new_;
    }

    modifier onlyClaimant() {
        require(claimant == msg.sender, "Ownable: caller is not the claimant");
        _;
    }

    function start(uint256 amount) public {
        IERC20 token = IERC20(tokenAddress);
        require (token.balanceOf(address(this)) == 0, "Vesting already initialized");
        token.safeTransferFrom(msg.sender, address(this), amount);
        total = amount;
        perTier = amount.div(tiers);
        startTime = block.timestamp;
    }

    function collect() public onlyClaimant {
        uint256 elapsed = block.timestamp.sub(startTime);
        uint256 endTime = startTime.add(perTier.mul(tiers));
        IERC20 token = IERC20(tokenAddress);
        if (block.timestamp >= endTime) {
                token.safeTransfer(claimant, token.balanceOf(address(this)));
                claimed = total;
        } else {
            uint256 alreadyPaid = tiersClaimed;
            while (elapsed > 0) {
                if (elapsed > tierLength) {
                    if (alreadyPaid > 0) {
                        alreadyPaid.sub(1);
                        elapsed = elapsed.sub(tierLength);
                    } else {
                        
                    //pay out a tier
                    elapsed = elapsed.sub(tierLength);
                    token.safeTransfer(claimant, perTier);
                    claimed = claimed.add(perTier);
                    tiersClaimed = tiersClaimed.add(1);
                    }
                } else {
                    elapsed = 0;
                }
            }
        }
    }
}

