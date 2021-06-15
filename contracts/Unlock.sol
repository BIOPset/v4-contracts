pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/* 
* @dev Unlock: A one time lock for ERC20 tokens that are available to withdraw all at once. A time vault.
* @Author Shalaquiana
 */
contract Unlock {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public immutable tokenAddress;
    address payable claimant;
    uint256 public period;
    uint256 public startTime;//start time of the vesting
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
        startTime = block.timestamp;
    }

    function collect() public onlyClaimant returns(uint256) {
        uint256 elapsed = block.timestamp.sub(startTime);
        IERC20 token = IERC20(tokenAddress);
        if (elapsed > period) {
            //vesting totally complete
            uint256 total = token.balanceOf(address(this));
            token.safeTransfer(claimant, total);
            return total;
        } 
        return 0;
    }
}
