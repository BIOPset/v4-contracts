pragma solidity ^0.6.6;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "./RateCalc.sol";
import "./BinaryOptions.sol";

contract FixedRateCalc is IRCD {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option buyer profit
     * @param amount Option amount
     * @param maxAvailable the total pooled ETH unlocked and available to bet
     * @param l the current amount of locked ETH
     * @param t time for the option
     * @param k true for call false for put
     * @param s stack, how many open options there are in this direction
     * @return profit total possible profit amount
     */
    function rate(uint256 amount, uint256 maxAvailable, uint256 l, uint256 t, bool k, uint256 s) external view override returns (uint256)  {

        if (l < maxAvailable.div(1000)) {
            return amount.mul(2);
        }

        return amount.add(amount.div(100));
      
        
    }
}

