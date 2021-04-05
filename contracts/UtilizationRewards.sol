pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUtilizationRewards.sol";

contract UtilizationRewards is IUtilizationRewards{
    using SafeMath for uint256;
    address public bO = 0x0000000000000000000000000000000000000000;//binary options
    address payable dao = 0x0000000000000000000000000000000000000000;
    uint256 public lEnd;//launch end
    uint256 public epoch = 0; //rewards epoch 
    uint256 public eS;//end of current epoch
    uint256 public perE;//rewards per epoch (650000000000000000000000000000 total)
    uint256 public tTE;//claims left this epoch
    uint256 maxEpoch;
    ERC20 token;

    //base rewards 
    uint256 public rwd = 20000000000000000;
                                      

    /** 
     * @dev init the contract (dont forget to also configure setupBinaryOptions afterwards, and deposit tokens)
     * @param token_ the BIOP token addressss
     * @param maxEpoch_ total number of reward epochs
     * @param launchTime the length of the launch bonus multiplier (in seconds)
     */
    constructor(address token_, uint256 maxEpoch_, uint256 launchTime) public {
      dao = msg.sender;
      lEnd = block.timestamp + launchTime;
      eS = block.timestamp + 30 days;
      tTE = 92857142857142850000000000000;
      maxEpoch = maxEpoch_;//7 was old default
      token = ERC20(token_);
    }

     /** 
     * @dev deposit tokens into the utilization rewards
    
     * @param total the BIOP tokens to transfer into this contract from multisig
     */
    function deposit(uint256 total) public onlyDAO {

      perE = total.div(maxEpoch); //amount per epoch
      tTE = total.div(maxEpoch); 

      token.transferFrom(msg.sender, address(this), total);
    }


    
    modifier onlyBinaryOptions() {
        require(bO == msg.sender, "Ownable: caller is not the Binary Options Contract");
        _;
    }
    modifier onlyDAO() {
        require(dao == msg.sender, "Ownable: caller is not the dao");
        _;
    }

    /** 
     * @dev transfer ownership of this contract
     * @param g_ the new governance address
     */
    function transferGovernance(address payable g_) external override onlyDAO {
        require(g_ != 0x0000000000000000000000000000000000000000);
        dao = g_;
    }

    
   


    /**
     * @dev called by the binary options contract to claim Reward for user
     * @param amount the amount in BIOP to add to transfer to this user
     **/
    function distributeClaim(uint256 amount ) external override onlyBinaryOptions {
        if (lEnd < block.timestamp) {
            require(token.balanceOf(address(this)) >= amount.mul(8), "insufficent balance remaining");
            updateEpoch(amount.mul(8));
            token.transfer(tx.origin, amount.mul(8));
        } else {
            require(token.balanceOf(address(this)) >= amount, "insufficent balance remaining");
            updateEpoch(amount);
            token.transfer(tx.origin, amount);
        }
    }

 

    /**
     * @dev calculate the staking time bonus (1x every 9 days)
     * @param lastStake timestamp of LPs last stake/claim
     **/
    function getStakingTimeBonus(uint256 lastStake) public view returns(uint256) {
        uint256 dif = block.timestamp.sub(lastStake);
        uint256 bonus = dif.div(777600);//9 days
        if (dif < 777600) {
            return 1;
        }
        return bonus;
    }

    /**
     * @dev calculate the bonus for % of total LP pool
     * @param locked amount the user has staked
     * @param totalLocked the total amount staked by all LPs
     **/
    function getPoolBalanceBonus(uint256 locked, uint256 totalLocked) public view returns(uint256) {
       
        if (locked > 0) {

            if (totalLocked < 100) { //guard
                return 1;
            }
            

            if (locked >= totalLocked.div(2)) {//50th percentile
                return 20;
            }

            if (locked >= totalLocked.div(4)) {//25th percentile
                return 14;
            }

            if (locked >= totalLocked.div(5)) {//20th percentile
                return 10;
            }

            if (locked >= totalLocked.div(10)) {//10th percentile
                return 8;
            }

            if (locked >= totalLocked.div(20)) {//5th percentile
                return 6;
            }

            if (locked >= totalLocked.div(50)) {//2nd percentile
                return 4;
            }

            if (locked >= totalLocked.div(100)) {//1st percentile
                return 3;
            }
           
           return 2;
        } 
        return 0; 
    }

     /**  
    * @notice bonus based  on total interchange. The more bet's are used, the more rewards.
    * @param lastInterchange the total interchange the last time the LP staked/claimed
    * @param totalInterchange the total interchange now
    */
    function getOptionValueBonus(uint256 lastInterchange, uint256 totalInterchange) public view returns(uint256) {
        uint256 dif = totalInterchange.sub(lastInterchange);
        uint256 bonus = dif.div(100000000000000000);//.1ETH
        if(bonus > 0){
            return bonus;
        }
        return 1;
    }

     /**
     * @dev called by the binary options contract to claim Reward for user
     * @param lastStake timestamp of LPs last stake/claim
     * @param lastInterchange the total interchange the last time the LP staked/claimed
     * @param totalInterchange amount interchanged since LPs last claim
     * @param stakedAmount amount the user has staked
     * @param totalStaked the total amount staked by all LPs
     **/
    function getLPStakingBonus(uint256 lastStake, uint256 lastInterchange, uint256 totalInterchange, uint256 stakedAmount, uint256 totalStaked) external override view returns(uint256) {
        return rwd.mul(10)
                .mul(getStakingTimeBonus(lastStake))
                .mul(getPoolBalanceBonus(stakedAmount, totalStaked))
                .mul(getOptionValueBonus(lastInterchange, totalInterchange));
    }



     /**
     * @dev used for betting/exercise/expire calc
     * @param amount the amount of value in bet
     * @param totalLocked total LP pool size
     * @param completion false for bet, true for exercise expire
     **/
    function getBetExerciseBonus(uint256 amount, uint256 totalLocked, bool completion) external view override returns(uint256) {
        return rwd.div(1000);
    }















    // UTILS

    //epochs run 30 days. except the final epoch that goes on until rewards run out.
    // unused rewards are rolled over into the next epoch.
    function updateEpoch(uint256 amount) internal {
            require(tTE.sub(amount) >= 0, "insufficent claims avail");
            tTE = tTE.sub(amount);
            if (block.timestamp > eS && epoch < maxEpoch) {
                //every 30 days the next epoch can begin
                epoch = epoch.add(1);
                eS = block.timestamp + 30 days;
                tTE = perE.add(tTE);
            }
    }
     /**
     * @notice one time function used at deployment to configure the connected binary options contract
     * @param options_ the address of the binary options contract
     */
    function setupBinaryOptions(address payable options_) external onlyDAO {
        bO = options_;
    }
}
