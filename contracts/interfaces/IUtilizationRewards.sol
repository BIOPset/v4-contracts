pragma solidity ^0.6.6;

interface IUtilizationRewards {


    /**
     * @dev transfer ownership of this contract
     * @param g_ the new governance address
     */
    function transferDAO(address payable g_) external virtual;



    /**
     * @dev called by the binary options contract to claim Reward for user
     * @param amountStaker the amount in BIOP to transfer to this user for staking
     * @param amountOther the amount in BIOP to transfer to this user for trading/settling
     **/
    function distributeClaim(uint256 amountStaker, uint256 amountOther) external virtual returns(uint256);



     /**
     * @dev called by the binary options contract to claim Reward for user
     * @param lastStake timestamp of LPs last stake/claim
     * @param lastInterchange the total interchange the last time the LP staked/claimed
     * @param totalInterchange amount interchanged since LPs last claim
     * @param stakedAmount amount the user has staked
     * @param totalStaked the total amount staked by all LPs
     **/
    function getLPStakingBonus(uint256 lastStake, uint256 lastInterchange, uint256 totalInterchange, uint256 stakedAmount, uint256 totalStaked) external virtual view returns(uint256);



     /**
     * @dev used for openPosition/exercise/expire calc
     * @param amount the amount of value in the binary option
     * @param totalLocked total LP pool size
     * @param completion false for open position, true for exercise expire
     **/
    function getTradeExerciseBonus(uint256 amount, uint256 totalLocked, bool completion) external virtual view returns(uint256);



}
