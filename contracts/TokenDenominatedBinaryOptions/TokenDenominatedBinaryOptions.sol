pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";



import "../RateCalc.sol";
import "../interfaces/IUtilizationRewards.sol";
import "../interfaces/ITokenDenominatedBinaryOptions.sol";
import "../interfaces/IAPP.sol";
import "../Chainlink/AggregatorProxy.sol";


contract TokenDenominatedBinaryOptions is ERC20, ITokenDenominatedBinaryOptions {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  address payable public treasury;
  address payable public owner;
  address public app;//the approved pp/ratecalc
  mapping(address=>uint256) public nW; //next withdraw (used for pool lock time)

  uint256 public oC;
  uint256 public oP;



  uint256 public minT;//minimum number of rounds
  uint256 public maxT;//maximum number of rounds
  uint256 public lockedAmount;//the amount locked into the pool by the liquidity provider
  uint256 public settlerFee = 5;//0.2%
  uint256 public protocolFee = 100;//1%
  uint256 public poolLockSeconds = 1209600;//14 days

  bool public open = true;
  Option[] public options;

  IERC20 public sT;//the token pooled in this contract
  uint256 base = 1000000000000000000;//one token of the underlying, used for expiring

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /* Types */
  struct Option {
    address payable holder;
    int256 sP;//strike
    uint80 pR;//purchase round
    uint256 pV;//purchase value
    uint256 lV;//in-the-money option value (lockedValue)
    uint80 exp;//final round of option s
    bool dir;//direction (true for call)
    address pP;//price provider
    bool complete;//has the option been exercised/expired yet
  }

  /* Events */
  event Create(
    uint256 indexed id,
    address payable account,
    int256 sP,//strike
    uint256 lV,//locked value
    bool dir,//direction (true for call)
    uint80 pR,//purchase round
    uint80 exp//expiration round
  );
    event Payout(uint256 poolLost, address winner);
    event Exercise(uint256 indexed id);
    event Expire(uint256 indexed id);

  constructor(string memory name_, string memory symbol_, address token_, address payable dao_, address app_, address payable treasury_) public ERC20(name_, symbol_) {
    sT = IERC20(token_);
    owner = dao_;
    app = app_;
    treasury = treasury_;
    minT = 1;
    maxT = 1;
    lockedAmount = 0;
  }

  //start of governance/maintanance functions

  /**
    * @dev set the new address to control this contract
    * @param newDAO_ the new owner's address
    */
  function updateOwner(address payable newDAO_) public onlyOwner {
    owner = newDAO_;
  }

  /**
    * @dev set the new address of the Approved Price Providers(APP)
    * @param newAPP_ the new approved price provider (and ratecalc contract to use). Must be a IAPP
    */
  function updateAPP(address newAPP_) public onlyOwner {
    app = newAPP_;
  }

  /**
    * @dev set the new address of the treasury that early withdraw fees or protocol fees go to
    * @param newTreasury_ the new Treasury address
    */
  function updateTreasury(address payable newTreasury_) public onlyOwner {
    treasury = newTreasury_;
  }

  /**
    * @dev set the base amount of the token. important for tokens that have more or less then 18 decimal places
    * @param newBase_ the new base amount
    */
  function updateBase(uint256 newBase_) public onlyOwner {
    base = newBase_;
  }

  /**
    * @dev set the fee users can recieve for exercising/expiring other users options
    * @param fee_ the new fee for exercising/expiring a options
    */
  function updateSettlerFee(uint256 fee_) external onlyOwner {
    require(fee_ >= 5, "invalid fee");
    settlerFee = settlerFee;
  }


  /**
    * @dev set the fee users pay to buy an option
    * @param newProtocolFee_ the new fee (in tenth percent) to buy an option
    */
  function updateProtocolFee(uint256 newProtocolFee_) external onlyOwner {
    require(newProtocolFee_ == 0 || newProtocolFee_ > 50, "invalid fee");
    protocolFee = newProtocolFee_;
  }

  /**
    * @dev update the pool stake lock up time.
    * @param newLockSeconds_ the new lock time, in seconds
    */
  function updatePoolLockSeconds(uint256 newLockSeconds_) external onlyOwner {
    //make sure that the pool lock period never exceeds 14 days (1209600 seconds)
    require(newLockSeconds_ >= 0 && newLockSeconds_ < 1209600, "invalid pool lock period");
    poolLockSeconds = newLockSeconds_;
  }

  /**
    * @dev update the max rounds for an option position
    * @param newMax_ the new maximum time (in rounds) an option may be created for (inclusive).
    */
  function updateMaxT(uint256 newMax_) external onlyOwner {
    maxT = newMax_;
  }

  /**
    * @dev update the min rounds for an option position
    * @param newMin_ the new minimum time (in rounds) an option may be created for (inclusive).
    */
  function updateMinT(uint256 newMin_) external onlyOwner {
    minT = newMin_;
  }

   /**
     * @dev used to send this pool into EOL mode when a newer one is open
     */
    function closeStaking() external onlyOwner {
        open = !open;
    }

  // End of governance/maintanance functions

  //start of usage functions

   /**
    * @dev deposit into the pool
    * @param amount_ the amount you want to deposit to be used for underwriting options
    */
  function stake(uint256 amount_) public override {
    require(open, "pool deposits has closed");
    sT.safeTransferFrom(msg.sender, address(this), amount_);
    nW[msg.sender] = block.timestamp + poolLockSeconds;
    _mint(msg.sender, amount_);
  }

  /**
    * @dev recieve tokens from the pool.
    * If the current time is before your next available withdraw a 1% fee will be applied.
    * @param amount_ The amount of LP token to return the pool (burn).
    */
  function withdraw(uint256 amount_) public override {
    require (balanceOf(msg.sender) >= amount_, "Insufficent Share Balance");
    //value to receive
    uint256 vTR = amount_.mul(sT.balanceOf(address(this)).sub(lockedAmount)).div(totalSupply());
    _burn(msg.sender, amount_);
    if (block.timestamp <= nW[msg.sender]) {
      //early withdraw fee
      uint256 penalty = vTR.div(100);
      sT.safeTransfer(treasury, penalty);
      sT.safeTransfer(msg.sender, vTR.sub(penalty));
    } else {
      sT.safeTransfer(msg.sender, vTR);
    }
  }

  /**
    @dev Get the maximum possible option size
    */
  function getMaxAvailable() public view returns(uint256) {
    uint256 balance = sT.balanceOf(address(this));
    if (balance > lockedAmount) {
      return balance.sub(lockedAmount);
    } else {
      return 0;
    }
  }

  /**
    @dev helper for getting rate
    @param pair the price provider
    @param deposit option premium (payment) amount
    @param t time
    @param k direction bool, true is call
    @return the rate
    */
  function getRate(address pair, uint256 deposit, uint256 t, bool k) public view returns (uint256) {
    IAPP app_ = IAPP(app);
    require(app_.aprvd(pair) != 0x0000000000000000000000000000000000000000, "invalid trading pair");
    RateCalc rc = RateCalc(app_.aprvd(pair));
    return rc.rate(deposit, lockedAmount , t, k, oC, oP, sT.balanceOf(address(this)));
  }

  /**
    @dev called by BinaryOptions contract to lock pool value coresponding to new binary options bought.
    @param amount amount in ETH to lock from the pool total.
    */
  function lock(uint256 amount) internal {
    lockedAmount = lockedAmount.add(amount);
  }

  /**
    @dev check if a price provider is approved.
    @param pp_ the oracle feed to check
    **/
  function isApproved(address pp_) internal returns(bool){
    IAPP app_ = IAPP(app);
    return app_.aprvd(pp_) != 0x0000000000000000000000000000000000000000;
  }

  /**
    @dev Open a new call or put options.
    @param k_ type of option to buy (true for call )
    @param pp_ the address of the price provider to use (must be in the list of aprvd from IAPP)
    @param t_ the rounds until your options expiration (must be minT < t_ > maxT)
    @param a_ the amount to spend on on the option
    */
  function openPosition(bool k_, address pp_, uint80 t_, uint256 a_) external override {
    require(
      t_ >= minT && t_ <= maxT,
      "Invalid time"
    );
    require(isApproved(pp_), "Invalid price provider");
    require(a_ <= getMaxAvailable(), "option size too big");

    sT.safeTransferFrom(msg.sender, address(this), a_);

    AggregatorProxy priceProvider = AggregatorProxy(pp_);
    (uint80 lR, int256 lA, , , ) = priceProvider.latestRoundData();
    uint256 oID = options.length;

    uint256 lV = getRate(pp_, a_, t_, k_);
    lock(lV);

    Option memory op = Option(
      msg.sender,
      lA,
      lR,
      a_,
      lV,
      t_,//rounds until expiration
      k_,
      pp_,
      false
    );
    if (k_) {
      oC = oC.add(lV);
    } else {
      oP = oP.add(lV);
    }
    options.push(op);
    emit Create(oID, msg.sender, lA, lV, k_, lR, lR+t_);
  }

  /**
    * @notice exercises or expire a option
    * @dev exercise and expire functions have been depreciated in favor of this single complete option
    * @param oID id of the option to complete
    */
  function complete(uint256 oID) external override{
    Option memory option = options[oID];
    require(option.complete == false, "option already completed");
    AggregatorProxy priceProvider = AggregatorProxy(option.pP);
    (uint80 lR, int256 lA, , , ) = priceProvider.getRoundData(uint80(option.pR+option.exp));
    require(lA != 0 && lR != 0, "not ready yet");
    option.complete = true;
    if (option.dir) {
      //call option
      if (option.sP > lA) {
        //OTM expire
        expire(option, oID);
      } else {
        //ITM exercise
        exercise(option, oID);
      }
      oC = oC.sub(option.lV);
    } else {
      //put option
      if (lA > option.sP) {
        //OTM expire
        expire(option, oID);
      } else {
        //ITM exercise
        exercise(option, oID);
      }
      oP = oP.sub(option.lV);
    }
  }

  /**
    @dev called by BinaryOptions contract to payout pool value coresponding to binary options expiring itm.
    @param amount amount in ERC20 to send
    @param exerciser address calling the exercise/expire function, this may the winner or another user who then earns a fee.
    @param winner address of the winner.
    @notice exerciser fees are subject to change see updateFeePercent above.
    */
  function payout(uint256 amount, address payable exerciser, address payable winner) internal {
    require(amount <= lockedAmount, "insufficent pool balance available to payout");

    require(amount <= sT.balanceOf(address(this)), "insufficent balance in pool");
    if (exerciser != winner) {
      //good samaratin fee
      uint256 fee = amount.div(settlerFee).div(100);

      if (fee > 0) {
        sT.safeTransfer(exerciser, fee);
      }
      sT.safeTransfer(winner, amount.sub(fee));
    } else {
      sT.safeTransfer(winner, amount);
    }
    emit Payout(amount, winner);
  }

  /**
     * @notice exercise an option
     * @dev use complete to exercise an option. This is a internal function
     * @param option the option to exercise
     * @param oID the option id
     */
  function exercise(Option memory option, uint256 oID) internal {
    //option expires ITM, pool pays out

    uint256 lv = option.lV;

    //an optional (to be choosen by contract owner) fee on each option.
    //A % of the trade money is sent as a fee. see protocolFee
    if (lv > protocolFee && protocolFee > 0) {
      uint256 fee = lv.div(protocolFee);

      sT.safeTransfer(treasury, fee);
      lv = lv.sub(fee);
    }

    payout(lv, msg.sender, option.holder);
    lockedAmount = lockedAmount.sub(option.lV);

    emit Exercise(oID);
  }

  /**
     * @notice expire an option
     * @dev use complete to expire an option. This is a internal function
     * @param option the option to exercise
     * @param oID the option id
     */
  function expire(Option memory option, uint256 oID) internal {
    require(option.lV <= lockedAmount, "insufficent locked pool balance to unlock");


    require(option.lV <= sT.balanceOf(address(this)), "insufficent balance in pool");

    uint256 fee = option.lV.div(settlerFee).div(100);
    if (fee > 0) {
      sT.safeTransfer(msg.sender, fee);
    }
    lockedAmount = lockedAmount.sub(option.lV);
    emit Expire(oID);
  }
}
