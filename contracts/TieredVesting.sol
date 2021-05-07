pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract TieredVesting {

    using SafeMath for uint256;
    address public tokenAddress;
    address payable claimant;
    uint256 public total;//total tokens to send over vesting period
    uint256 public startTime;//start time of the vesting
    uint256 public claimed = 0;//amount claimed so far
    uint256 public tiers;//the number of tiers
    uint256 public tierLength;//time for each tier
    uint256 public perTier;//tokens unlocked at each tier
    uint256 public tiersCompleted;
    bool started = false;

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
        require(started == false, "already started");
        ERC20 token = ERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        started = true;
        total = amount;
        perTier = amount.div(tiers);
        startTime = block.timestamp;
    }

    function collect() public onlyClaimant returns(uint256) {
        uint256 elapsed = block.timestamp.sub(startTime);
        ERC20 token = ERC20(tokenAddress);
        uint256 completed = elapsed.div(tierLength);
        if (completed > 0) {
            completed = completed.sub(tiersCompleted);
        }

        if (completed == tierLength) {
                uint256 amount = total.sub(claimed);
                claimed = total;
                tiersCompleted = tiers;
                token.transfer(claimant, amount);
                return amount;
        } else if (completed > 0) {
            uint256 sent = 0;
            while (completed > 0) {
                completed = completed.sub(1);
                tiersCompleted = tiersCompleted.add(1);
                claimed = claimed.add(perTier);
                token.transfer(claimant, perTier);
                sent = sent.add(perTier);
            }
            return sent;
        }
        return 0;
    }
}
