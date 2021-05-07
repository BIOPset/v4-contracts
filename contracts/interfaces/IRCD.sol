pragma solidity ^0.6.6;

interface IRCD {
    /**
     * @notice Returns the rate to pay out for a given amount
     * @param amount the bet amount to calc a payout for
     * @param maxAvailable the total pooled ETH unlocked and available to bet
     * @param l the current amount locked
     * @param t time for the option
     * @param k true for call false for put
     * @param s number of open options in this direction
     * @return profit total possible profit amount
     *
     */
    function rate(uint256 amount, uint256 maxAvailable, uint256 l, uint256 t, bool k, uint256 s) external view returns (uint256);

}
