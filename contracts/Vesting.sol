pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Vesting{

    using SafeMath for uint256;
    address public tokenAddress;
    address payable claimant;
    uint256 public period;
    uint256 public total;//total tokens to send over vesting period
    uint256 public startTime;//start time of the vesting
    uint256 public claimed;//amount claimed so far

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
        ERC20 token = ERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        period = period_;
        total = amount;
        startTime = block.timestamp;
    }

    function collect() public onlyClaimant returns(uint256) {
        uint256 elapsed = block.timestamp.sub(startTime);
        ERC20 token = ERC20(tokenAddress);
        if (elapsed > block.timestamp.add(period)) {
            //vesting totally complete
            uint256 amount = total.sub(claimed);
            claimed = total;
            token.transfer(claimant, amount);
        } else {
            uint256 perComplete = period.div(elapsed);
            uint256 amount = total.div(perComplete);
            amount = amount.sub(claimed);
            claimed = claimed.add(amount);
            token.transfer(claimant, amount);
            return amount;
        }
    }
}