pragma solidity ^0.6.6;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IRCD.sol";

contract AdaptiveRateCalc is IRCD {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option buyer profit
     * @param amount Option amount
     * @param l the current amount of locked ETH
     * @param t time for the option
     * @param k true for call false for put
     * @param s stack, how many open options there are in this direction
     * @return profit total possible profit amount
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 s) external view override returns (uint256)  {
        require(s > 0, "invalid stack");

        if (amount < address(msg.sender).balance.sub(l).div(1000)) {
            return amount.mul(2);
        } else {
           //bottom 1.01x
           return amount.add(amount.div(100));
        }

    }
}
