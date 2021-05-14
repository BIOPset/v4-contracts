pragma solidity ^0.6.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IRCD {
    /**
     * @notice Returns the rate to pay out for a given amount
     * @param amount the bet amount to calc a payout for
     * @param l the current amount locked
     * @param t time for the option
     * @param k true for call false for put
     * @param s number of open options in this direction
     * @return profit total possible profit amount
     *
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 s) external view returns (uint256);

}


contract AdaptiveRateCalc is IRCD {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option buyer profit
     * @param amount Traders option payment
     * @param l the current amount of locked ETH
     * @param t time/rounds for the option  (not used in this RateCalc)
     * @param k true for call false for put (Not used in this RateCalc)
     * @param s stack, how many open options there are already in this direction
     * @return profit total possible profit amount
     * 
     * @dev the amount returned represents the total amount which is to be locked. This means that any amount returned represents the traders full bet amount and the pools stake compbined.
     * 
     * 
    
     * 
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 s) external view override returns (uint256)  {
        
        //check less then 1% is already locked
        require(l < msg.sender.balance.div(100), "pool is full");
        
        uint256 canLock = msg.sender.balance.sub(l);
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
