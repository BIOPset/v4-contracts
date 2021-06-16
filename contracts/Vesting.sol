pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";



contract Vesting{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public immutable tokenAddress;
    address payable claimant;
    uint256 public period;//total length of the vesting period
    uint256 public total;//total tokens to send over vesting period
    uint256 public startTime;//start time of the vesting
    uint256 public claimed;//amount claimed so far
    bool started = false;

    constructor(address payable claimant_, address tokenAddress_) public {
        claimant = claimant_;

        tokenAddress = tokenAddress_;
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

    function start(uint256 amount, uint256 period_) public {
        require(started == false, "already started");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        started = true;
        period = period_;
        total = amount;
        startTime = block.timestamp;
    }

    function collect() public onlyClaimant returns(uint256) {
        uint256 elapsed = block.timestamp.sub(startTime);
        IERC20 token = IERC20(tokenAddress);
        if (elapsed > period) {
            //vesting totally complete
            uint256 amount = total.sub(claimed);
            claimed = total;
            token.safeTransfer(claimant, amount);
            return amount;
        } else {
            uint256 percentDone;
            uint256 onePercent = period.div(100);
            while (elapsed > 0) {
                if (elapsed >= onePercent) {
                    elapsed = elapsed.sub(onePercent);
                    percentDone = percentDone.add(1);
                } else {
                    elapsed = 0;
                }
            }
            uint256 amount = (total.div(100).mul(percentDone)).sub(claimed);    
            
            claimed = claimed.add(amount);
            token.safeTransfer(claimant, amount);
            return amount;
        }
    }
}
