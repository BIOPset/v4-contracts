pragma solidity ^0.6.6;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IRateCalc.sol";

contract BasicRateCalc is IRateCalc {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option buyer profit
     * @param amount Traders option payment
     * @param l the current amount of locked ETH
     * @param t time/rounds for the option  (not used in this RateCalc)
     * @param k true for call false for put (Not used in this RateCalc)
     * @param s stack, how many open options there are already in this direction
     * @param tP the amount of tokens stored currently in the pool the option be created on
     * @return profit total possible profit amount
     * 
     * @dev the amount returned represents the total amount which is to be locked. This means that any amount returned represents the traders full bet amount and the pools stake compbined.
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 s, uint256 tP) external view override returns (uint256)  {
        
        //check less then 1% is already locked
        require(l < tP.div(100), "pool is full");
        
        uint256 canLock = tP.sub(l);
        uint256 double = amount.mul(2);
        //check bet is less then 0.5%
        require(amount < canLock.div(200), "bet to big");
        
        //for small bets less then 0.001% of pool
        if (amount < canLock.div(100000)) {
            if ( s > 150 ) {
                return actualRate(amount, canLock, amount.add(amount.div(100)));
            } else if (s > 100) {
                //more then 100 bets in the same direction: 1.25x
                return actualRate(amount, canLock, amount.add(amount.div(4)));
            } else  if (s > 50) {
                //more then 50 bets in the same direction: 1.5x
                return actualRate(amount, canLock, amount.add((amount.div(2))));
            } else {
                // 2x
                return actualRate(amount, canLock, double);
            }
        }
        
        //for bets between 0.001%-0.1% of pool
        if (amount < canLock.div(1000)) {
            if (s > 20) {
                return actualRate(amount, canLock, amount);
            } else if (s > 15) {
                //more then 15 bets in the same direction: 1.1x
                return actualRate(amount, canLock, amount.add(amount.div(100)));
            } else if (s > 10) {
                // 1.25x
                return actualRate(amount, canLock, amount.add(amount.div(4)));
            } else  if (s > 5) {
                //1.5x
                return actualRate(amount, canLock, amount.add((amount.div(2))));
            } else {
                // 2x
                return actualRate(amount, canLock, double);
            }
        }
        
        return actualRate(amount, canLock, double.sub(amount.div(10)));
    }
    
    function actualRate(uint256 amount, uint256 canLock, uint256 startRate) internal pure returns (uint256){
        while (startRate > canLock) {
            startRate = startRate.sub(amount.div(100));
        }
        return startRate;
    }
}
