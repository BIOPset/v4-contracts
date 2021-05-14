pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IRateCalc.sol";


contract RateCalc is IRateCalc {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option buyer profit
     * @param amount Option amount
     * @param l the amount locked now
     * @param t time for the option
     * @param k true for call false for put
     * @param s number of open options in this direction
     * @param tP the amount of tokens stored currently in the pool the option be created on
     * @return profit total possible profit amount
     */
    function rate(uint256 amount,  uint256 l, uint256 t, bool k, uint256 s, uint256 tP) external view override returns (uint256)  {
        require(false, "Don't use this ratecalc its for format purpose only");
        /* 
        uint256 oneTenth = amount.div(10);
        uint256 halfMax = msg.sender.balance.div(2);
        if (amount > halfMax) {
            return amount.mul(2).add(oneTenth).add(oneTenth);
        } else {
            if(oneTenth > 0) {
                return amount.mul(2).sub(oneTenth);
            } else {
                uint256 oneThird = amount.div(4);
                require(oneThird > 0, "invalid bet amount");
                return amount.mul(2).sub(oneThird);
            }
        } */
        
    }
}

