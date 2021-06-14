pragma solidity 0.6.6;

interface IRateCalc {
    /**
     * @notice Returns the rate to pay out for a given amount
     * @param amount the option premium to calc a payout for
     * @param l the current amount locked
     * @param t time for the option
     * @param k true for call false for put
     * @param oC number of open call options
     * @param oP number of open put options
     * @param tP the amount of tokens stored currently in the pool the option be created on
     * @return profit total possible profit amount
     *
     */
    function rate(uint256 amount, uint256 l, uint256 t, bool k, uint256 oC, uint256 oP, uint256 tP) external view returns (uint256);

}
