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
     * @param s stack, how many open options there are already in this direction
     * @param tP the amount of tokens currently stored in the active pool
     * @return profit total possible profit amount
     *
     * @dev the amount returned represents the total amount which is to be locked. This means that any amount returned represents the option's purchase price and the pool's stake combined.
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 s, uint256 tP) external view override returns (uint256)  {

        //check that no more than 1% of the pool is locked
        require(l < tP.div(100), "pool is full");

        uint256 canLock = tP.sub(l);
        uint256 double = amount.mul(2);
        uint256 limited = amount.add((amount.div(2)));

        //if the amount of ETH that can be locked is less than (or equal to) 0.5% of the pool
        if (canLock <= tP.div(200)) {
            //the return rate of biopset options drops to 1.5x
            return actualRate(amount, canLock, limited);
        } else {
            //the default return rate of biopset options is 2x
            return actualRate(amount, canLock, double);
        }
    }

    function actualRate(uint256 amount, uint256 canLock, uint256 startRate) internal pure returns (uint256){
        //make sure that the option value is less than (or equal to) the amount that can be locked.
        require(startRate <= canLock, "position too large");
        return startRate;
    }
}
