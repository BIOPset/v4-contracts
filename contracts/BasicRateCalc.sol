pragma solidity ^0.6.6;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IRateCalc.sol";

contract BasicRateCalc is IRateCalc {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option value
     * @param amount the trader's option payment
     * @param l the current amount of locked ETH
     * @param t time/rounds for the option  (not used in this RateCalc)
     * @param k true for call false for put (not used in this RateCalc)
     * @param oC  how many open call options there are currently
     * @param oP  how many open put options there are currently
     * @param tP the amount of tokens currently stored in the active pool
     * @return profit total possible profit amount
     *
     * @dev the amount returned represents the total amount which is to be locked. This means that any amount returned represents the option's purchase price and the pool's stake combined.
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 oC, uint256 oP, uint256 tP) external view override returns (uint256)  {

        //limit pool utilization (should never exceed 99% if amount is 0.5% of the pool)
        uint256 uP = oC.add(oP); //define pool utilization to be the sum of open calls and open puts
        require(uP < tP.div(10), "pool is at maximum utilization"); //limit pool utilization to 10% of the pool

        //check that option premium/payment is no more than 0.5% of the pool
        require(amount < tP.div(200), "position too large");

        uint256 canLock;
        //if the difference between calls and puts is zero
        if (oC == oP) {
          canLock = tP.div(200); //limit the lock to 0.5% of pool
        } else if (oC > oP) {
          if (k) { //opening a call option
            canLock = tP.div(200).add(oP).sub(oC); //adjust the lock the lock downward for balance
          } else { //opening a put option
            canLock = tP.div(200).add(oC).sub(oP); //adjust the lock the lock upward for balance
          }
        } else if (oP > oC) {
          if (k) { //opening a call option
            canLock = tP.div(200).add(oP).sub(oC); //adjust the lock the lock upward for balance
          } else { //opening a put option
            canLock = tP.div(200).add(oC).sub(oP); //adjust the lock the lock downward for balance
          }

        }

        //the default return rate of biopset options is 2x
        uint256 double = amount.mul(2);
        return actualRate(amount, canLock, double);
    }

    function actualRate(uint256 amount, uint256 canLock, uint256 startRate) internal pure returns (uint256){
        //make sure that the option value is less than (or equal to) the amount that can be locked.
        require(startRate <= canLock, "position too large");
        return startRate;
    }
}
