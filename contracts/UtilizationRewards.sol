pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IUtilizationRewards.sol";

contract UtilizationRewards is IUtilizationRewards{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public bO = 0x0000000000000000000000000000000000000000;//binary options
    address payable dao = 0x0000000000000000000000000000000000000000;

    uint256 public dailyMax = 0;
    uint256 public claimedToday = 0;
    uint256 public todayStarted = 0;

    uint256 public stakerBalance = 0; //balance of BIOP tokens for stakers
    uint256 public otherBalance = 0;//balance of BIOP tokens for trader/settler
    IERC20 public immutable token;

    uint256 pricePoint = 1;//the BIOP/ETH price ratio used to determine Trader/Settler gas rewards

    //base rewards
    uint256 public rwd = 13000;


    /**
     * @dev init the contract (dont forget to also configure setupBinaryOptions afterwards, and deposit tokens)
     * @param token_ the BIOP token addressss
     */
    constructor(address token_) public {
      dao = msg.sender;
      token = IERC20(token_);
    }

     /**
     * @dev deposit tokens into the utilization rewards

     * @param newP the BIOP tokens to transfer into this contract from multisig
     */
    function updatePricePoint(uint256 newP) public onlyDAO {
      pricePoint = newP;
    }

    /**
     * @dev deposit tokens into the utilization rewards

     * @param nw the BIOP tokens to transfer into this contract from multisig
     */
    function updateDailyMax(uint256 nw) public onlyDAO {
      dailyMax = nw;
    }



     /**
     * @dev deposit tokens into the utilization rewards

     * @param staker the BIOP tokens to transfer into this contract from multisig for staker rewards
     * @param other the BIOP tokens to transfer into this contract from the multisig for trader/settler rewards
     */
    function deposit(uint256 staker, uint256 other) public onlyDAO {
        require(token.balanceOf(address(this)) == 0, "can't deposit while reward balance is not zero");
      token.safeTransferFrom(msg.sender, address(this), staker.add(other));
      stakerBalance = stakerBalance.add(staker);
      otherBalance = otherBalance.add(other);
    }

     /**
     * @dev emergency withdraw function to recover funds if theres a error in the rewards contract
     */
    function withdraw() public onlyDAO {
      token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

   /**
     * restricts amount that can be transfered out for stakers 
     * @param amount input amount
     **/
    function stakerAmountGuard(uint256 amount ) internal returns (uint256) {
        if (stakerBalance == 0) {
            //no rewards available
            return 0;
        }
        if (amount < stakerBalance) {
            stakerBalance = stakerBalance.sub(amount);
            return amount;
        }
        amount = stakerBalance;
        stakerBalance = 0;
        return amount;
    }

      /**
     * restricts amount that can be transfered out for traders/settlers 
     * @param amount input amount
     **/
    function otherAmountGuard(uint256 amount ) internal returns (uint256) {
        if (otherBalance == 0) {
            //no rewards available
            return 0;
        }
        if (amount < otherBalance) {
            otherBalance = otherBalance.sub(amount);
            return amount;
        }
        amount = otherBalance;
        otherBalance = 0;
        return amount;
    }

    /**
     * @dev restriscts maximum amount that can be transfered out in a single day
     * @param amount input amount
     */
    function dailyMaxGuard(uint256 amount) internal returns(uint256) {
        if (block.timestamp > todayStarted.add(86400)) {
            todayStarted = block.timestamp;
            claimedToday = 0;
        }

        if (claimedToday < dailyMax) {
            uint256 maxAmount = claimedToday.add(amount);
            if (maxAmount < dailyMax) {
                claimedToday = maxAmount;
                return amount;
            }
            maxAmount = dailyMax.sub(claimedToday);
            claimedToday = claimedToday.add(maxAmount);
            return maxAmount;

        }
        return 0;
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
     * @dev called by the binary options contract to claim Reward for user
     * @param amountStaker the amount in BIOP to transfer to this user for staking
     * @param amountOther the amount in BIOP to transfer to this user for trading/settling
     * @param claimant the address who triggered the function higher up and should receive the claim
     **/
    function distributeClaim(uint256 amountStaker, uint256 amountOther, address payable claimant ) external override onlyBinaryOptions returns(uint256) {
       if (amountStaker > 0) {
            amountStaker = stakerAmountGuard(amountStaker);
       }
       if (amountOther > 0) {
            amountOther = otherAmountGuard(amountOther);
       }
       uint256 total = dailyMaxGuard(amountStaker.add(amountOther));
       require(token.balanceOf(address(this)) >= total, "insufficent balance remaining");
       if (total > 0) {
            token.safeTransfer(claimant, total);
       }
       return amountOther;
    }

   

    /**
     * @dev calculate the staking time bonus
     * @param lastStake blocknumber of LPs last stake/claim
     **/
    function getStakingTimeBonus(uint256 lastStake) public view returns(uint256) {
        if (lastStake == 0) {
            return 1;
        }
        uint256 b = block.number.div(lastStake);
        if (b == 0) {
            return 1;
        }
        return uint256(1).add(sqrt(b));
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
        return rwd.mul(getStakingTimeBonus(lastStake));
    }



     /**
     * @dev used for openposition/exercise/expire calc
     * @param amount the option value
     * @param totalLocked total LP pool size
     * @param completion false for an open position, true for exercise expire
     **/
    function getTradeExerciseBonus(uint256 amount, uint256 totalLocked, bool completion) external view override returns(uint256) {
        return (rwd.mul(tx.gasprice)).div(pricePoint);
    }














    // UTILS
     /**
     * @notice function used at deployment to configure the connected binary options contract
     * @param options_ the address of the binary options contract
     */
    function setupBinaryOptions(address payable options_) external onlyDAO {
        bO = options_;
    }

      /**
     * @dev transfer ownership of this contract
     * @param g_ the new governance address
     */
    function transferDAO(address payable g_) external override onlyDAO {
        require(g_ != 0x0000000000000000000000000000000000000000);
        dao = g_;
    }

    function sqrt(uint x) private view returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
}
