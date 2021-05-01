pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Vesting{

    using SafeMath for uint256;
    address public tokenAddress;
    address payable claimant;
    uint256 public period;
    uint256 public total;//total tokens to send over vesting period
    uint256 public start;//start time of the vesting
    uint256 claimed;//amount claimed so far

    constructor(address payable claimant_) public {
        claimant = claimant_;
    }

     /**
    * @dev set the new claimant
    * @param new_ the new claimant's address
    */
    function updateClaimant(address payable new_, address tokenAddress_) public onlyClaimant {
        claimant = new_;
        tokenAddress = tokenAddress_;
    }

    modifier onlyClaimant() {
        require(claimant == msg.sender, "Ownable: caller is not the claimant");
        _;
    }

    function start(uint256 amount, uint256 period_) public {
        ERC20 token = ERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        period = period;
        total = amount;
        start = block.timestamp;
    }

    function collect() public onlyClaimant {
        uint256 elapsed = block.timestamp.sub(start);
        ERC20 token = ERC20(tokenAddress);
        if (elapsed > block.timestamp.add(period)) {
            //vesting totally complete
            uint256 amount = total.sub(claimed);
            token.transfer(claimant, amount);
        } else {
            uint256 perComplete = period.div(elapsed);
            uint256 amount = total.div(perComplete);
            amount = amount.sub(claimed);
            token.transfer(claimant, amount);
        }
    }
}
