pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



import "../RateCalc.sol";
import "../interfaces/IUtilizationRewards.sol";
import "../interfaces/ITokenDenominatedBinaryOptions.sol";
import "../interfaces/IAPP.sol";
import "../Chainlink/AggregatorProxy.sol";


contract TokenDenominatedBinaryOptions is ERC20, ITokenDenominatedBinaryOptions {
  address public sT;//the token pooled in this contract
  address payable public owner;
  address payable public treasury;


  address public app;//the approved pp/ratecalc
  mapping(address=>uint256) public nW; //next withdraw (used for pool lock time)


  uint256 public oC = 0;
  uint256 public oP = 0;

  uint256 base = 1000000000000000000;//one token of the underlying, used for expiring
  uint256 public minT;//min rounds
  uint256 public maxT;//max rounds
  uint256 public lockedAmount;
  uint256 public exerciserFee = 50;//in tenth percent
  uint256 public expirerFee = 50;//in tenth percent
  uint256 public daoBetFee = 0;//200;//0.5%
  uint256 public poolLockSeconds = 7 days;
  bool public open = true;
  Option[] public options;

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
    uint256 lV;// purchaseAmount+possible reward for correct bet
    uint80 exp;//final round of option s
    bool dir;//direction (true for call)
    address pP;//price provider
  }

  /* Events */
  event Create(
    uint256 indexed id,
    address payable account,
    int256 sP,//strike
    uint256 lV,//locked value
    bool dir,
    uint80 pR,//purchase round
    uint80 exp//expiration round
  );
    event Payout(uint256 poolLost, address winner);
    event Exercise(uint256 indexed id);
    event Expire(uint256 indexed id);

  constructor(string memory name_, string memory symbol_, address token_, address payable dao_, address app_, address payable treasury_) public ERC20(name_, symbol_) {
    sT = token_;
    owner = dao_;
    app = app_;
    treasury = treasury_;
    minT = 1;
    maxT = 3;
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
    * @param newAPP_ the new APP address
    */
  function updateAPP(address newAPP_) public onlyOwner {
    app = newAPP_;
  }

  /**
    * @dev set the new address of the treasury that early withdraw fees or bet fees go to
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
    * @dev set the fee users can recieve for exercising other users options
    * @param exerciserFee_ the new fee (in tenth percent) for exercising a options itm
    */
  function updateExerciserFee(uint256 exerciserFee_) external onlyOwner {
    require(exerciserFee_ > 1 && exerciserFee_ < 500, "invalid fee");
    exerciserFee = exerciserFee_;
  }

  /**
    * @dev set the fee users can recieve for expiring other users options
    * @param expirerFee_ the new fee (in tenth percent) for expiring a options
    */
  function updateExpirerFee(uint256 expirerFee_) external onlyOwner {
    require(expirerFee_ > 1 && expirerFee_ < 50, "invalid fee");
    expirerFee = expirerFee_;
  }

  /**
    * @dev set the fee users pay to buy an option
    * @param daoBetFee_ the new fee (in tenth percent) to buy an option
    */
  function updateDAOBetFee(uint256 daoBetFee_) external onlyOwner {
    require(daoBetFee_ == 0 || daoBetFee_ > 50, "invalid fee");
    daoBetFee = daoBetFee_;
  }

  /**
    * @dev update the pool stake lock up time.
    * @param newLockSeconds_ the new lock time, in seconds
    */
  function updatePoolLockSeconds(uint256 newLockSeconds_) external onlyOwner {
    require(newLockSeconds_ >= 0 && newLockSeconds_ < 14 days, "invalid fee");
    poolLockSeconds = newLockSeconds_;
  }

  /**
    * @dev update the max rounds for option bets
    * @param newMax_ the new maximum time (in rounds) an option may be created for (inclusive).
    */
  function updateMaxT(uint256 newMax_) external onlyOwner {
    maxT = newMax_;
  }

  /**
    * @dev update the min rounds for option bets
    * @param newMin_ the new minimum rounds (in rounds) an option may be created for (inclusive).
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
    require(open == true, "pool deposits has closed");
    ERC20 token = ERC20(sT);
    require(token.transferFrom(msg.sender, address(this), amount_), "deposit failed");
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
    ERC20 token = ERC20(sT);
    //value to receive
    uint256 vTR = amount_.mul(token.balanceOf(address(this))).div(totalSupply().sub(lockedAmount));
    _burn(msg.sender, amount_);
    if (block.timestamp <= nW[msg.sender]) {
      //early withdraw fee
      uint256 penalty = vTR.div(100);
      require(token.transfer(treasury, penalty), "transfer failed");
      require(token.transfer(msg.sender, vTR.sub(penalty)), "transfer failed");
    } else {
      require(token.transfer(msg.sender, vTR), "transfer failed");
    }
  }

  /**
    @dev Get the largest amount a bet can be created for
    */
  function getMaxAvailable() public view returns(uint256) {
    ERC20 token = ERC20(sT);
    uint256 balance = token.balanceOf(address(this));
    if (balance > lockedAmount) {
      return balance.sub(lockedAmount);
    } else {
      return 0;
    }
  }

  /**
    @dev helper for getting rate
    @param pair the price provider
    @param deposit bet amount
    @param t time
    @param k direction bool, true is call
    @return the rate
    */
  function getRate(address pair, uint256 deposit, uint256 t, bool k) public view returns (uint256) {
    IAPP app_ = IAPP(app);
    require(app_.aprvd(pair) != 0x0000000000000000000000000000000000000000, "invalid trading pair");
          
    RateCalc rc = RateCalc(app_.aprvd(pair));
    uint256 s;
    if (k){
      if (oP >= oC) {
        s = 1;
      } else {
        s = oC.sub(oP);
      }
    } else {
      if (oC >= oP) {
        s = 1;
      } else {
        s = oP.sub(oC);
      }
    }
    ERC20 token = ERC20(sT);
    return rc.rate(deposit, lockedAmount , t, k, s, token.balanceOf(address(this)));
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
  function bet(bool k_, address pp_, uint80 t_, uint256 a_) external override {
    require(
      t_ >= minT && t_ <= maxT,
      "Invalid time"
    );
    require(isApproved(pp_), "Invalid  price provider");
    require(a_ <= getMaxAvailable(), "bet to big");  

    ERC20 token = ERC20(sT);
    token.transferFrom(msg.sender, address(this), a_);

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
      pp_
    );
    if (k_) {
      oC = oC+1;
    } else {
      oP = oP+1;
    }
    options.push(op);
    emit Create(oID, msg.sender, lA, lV, k_, lR, lR+t_);
  }

  /**
    * @notice exercises or expire a option
    * @dev exercise and expire functions have been depreciated in favor of this single complete option
    * @param oID id of the option to complete
    */
  function complete(uint256 oID) external override returns(bool){
    Option memory option = options[oID];
    AggregatorProxy priceProvider = AggregatorProxy(option.pP);
    (uint80 lR, int256 lA, , , ) = priceProvider.getRoundData(uint80(option.pR+option.exp));
    require(lA != 0 && lR != 0, "not ready yet");
    uint256 stack = oC.add(oP);
    if (option.dir) {
      //call option
      if (option.sP > lA) {
        //OTM expire
        expire(option, oID);
      } else {
        //ITM exercise
        exercise(option, oID);
      }
      oC = oC-1;
    } else {
      //put option
      if (lA > option.sP) {
        //OTM expire
        expire(option, oID);
      } else {
        //ITM exercise
        exercise(option, oID);
      }
      oP = oP-1;
      return option.dir;
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

    ERC20 token = ERC20(sT);
    require(amount <= token.balanceOf(address(this)), "insufficent balance in pool");
    if (exerciser != winner) {
      //good samaratin fee
      uint256 fee;
      if (amount <= 10000000000000000) {//small options give bigger fee %
        fee = amount.div(exerciserFee.mul(4)).div(100);
      } else {
        fee = amount.div(exerciserFee).div(100);
      } 

      if (fee > 0) {
        require(token.transfer(exerciser, fee), "exerciser transfer failed");
        require(token.transfer(winner, amount.sub(fee)), "winner transfer failed");
      }
    } else {  
      require(token.transfer(winner, amount), "winner transfer failed");
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
    //A % of the bet money is sent as a fee. see daoBetFee
    if (lv > daoBetFee && daoBetFee > 0) {
      uint256 fee = lv.div(daoBetFee);
      require(owner.send(fee), "devFund fee transfer failed");
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
    
    
    ERC20 token = ERC20(sT);
    require(option.lV <= token.balanceOf(address(this)), "insufficent balance in pool");
    uint256 fee;
    if (option.lV <= base) {//small options give bigger fee %
      fee = option.lV.div(exerciserFee.mul(4)).div(100);
    } else {
      fee = option.lV.div(exerciserFee).div(100);
    } 

    if (fee > 0) {
      require(token.transfer(msg.sender, fee), "good samaritan transfer failed");
    }
    lockedAmount = lockedAmount.sub(option.lV);
    emit Expire(oID);
  }
}
