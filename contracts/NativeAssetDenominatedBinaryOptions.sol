pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



import "./BIOPTokenV4.sol";
import "./RateCalc.sol";
import "./interfaces/IUtilizationRewards.sol";
import "./interfaces/INativeAssetDenominatedBinaryOptions.sol";
import "./interfaces/IAPP.sol";


interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}
contract AggregatorProxy is AggregatorV2V3Interface, Owned {

  struct Phase {
    uint16 id;
    AggregatorV2V3Interface aggregator;
  }
  Phase private currentPhase;
  AggregatorV2V3Interface public proposedAggregator;
  mapping(uint16 => AggregatorV2V3Interface) public phaseAggregators;

  uint256 constant private PHASE_OFFSET = 64;
  uint256 constant private PHASE_SIZE = 16;
  uint256 constant private MAX_ID = 2**(PHASE_OFFSET+PHASE_SIZE) - 1;

  constructor(address _aggregator) public Owned() {
    setAggregator(_aggregator);
  }

  /**
   * @notice Reads the current answer from aggregator delegated to.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer()
    public
    view
    virtual
    override
    returns (int256 answer)
  {
    return currentPhase.aggregator.latestAnswer();
  }

  /**
   * @notice Reads the last updated height from aggregator delegated to.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp()
    public
    view
    virtual
    override
    returns (uint256 updatedAt)
  {
    return currentPhase.aggregator.latestTimestamp();
  }

  /**
   * @notice get past rounds answers
   * @param _roundId the answer number to retrieve the answer for
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(uint256 _roundId)
    public
    view
    virtual
    override
    returns (int256 answer)
  {
    if (_roundId > MAX_ID) return 0;

    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(_roundId);
    AggregatorV2V3Interface aggregator = phaseAggregators[phaseId];
    if (address(aggregator) == address(0)) return 0;

    return aggregator.getAnswer(aggregatorRoundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param _roundId the answer number to retrieve the updated timestamp for
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(uint256 _roundId)
    public
    view
    virtual
    override
    returns (uint256 updatedAt)
  {
    if (_roundId > MAX_ID) return 0;

    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(_roundId);
    AggregatorV2V3Interface aggregator = phaseAggregators[phaseId];
    if (address(aggregator) == address(0)) return 0;

    return aggregator.getTimestamp(aggregatorRoundId);
  }

  /**
   * @notice get the latest completed round where the answer was updated. This
   * ID includes the proxy's phase, to make sure round IDs increase even when
   * switching to a newly deployed aggregator.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound()
    public
    view
    virtual
    override
    returns (uint256 roundId)
  {
    Phase memory phase = currentPhase; // cache storage reads
    return addPhase(phase.id, uint64(phase.aggregator.latestRound()));
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param _roundId the requested round ID as presented through the proxy, this
   * is made up of the aggregator's round ID with the phase ID encoded in the
   * two highest order bytes
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(uint80 _roundId)
    public
    view
    virtual
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(_roundId);

    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 ansIn
    ) = phaseAggregators[phaseId].getRoundData(aggregatorRoundId);

    return addPhaseIds(roundId, answer, startedAt, updatedAt, ansIn, phaseId);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData()
    public
    view
    virtual
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    Phase memory current = currentPhase; // cache storage reads

    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 ansIn
    ) = current.aggregator.latestRoundData();

    return addPhaseIds(roundId, answer, startedAt, updatedAt, ansIn, current.id);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param _roundId the round ID to retrieve the round data for
   * @return roundId is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedGetRoundData(uint80 _roundId)
    public
    view
    virtual
    hasProposal()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return proposedAggregator.getRoundData(_roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @return roundId is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedLatestRoundData()
    public
    view
    virtual
    hasProposal()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return proposedAggregator.latestRoundData();
  }

  /**
   * @notice returns the current phase's aggregator address.
   */
  function aggregator()
    external
    view
    returns (address)
  {
    return address(currentPhase.aggregator);
  }

  /**
   * @notice returns the current phase's ID.
   */
  function phaseId()
    external
    view
    returns (uint16)
  {
    return currentPhase.id;
  }

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   */
  function decimals()
    external
    view
    override
    returns (uint8)
  {
    return currentPhase.aggregator.decimals();
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   */
  function version()
    external
    view
    override
    returns (uint256)
  {
    return currentPhase.aggregator.version();
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   */
  function description()
    external
    view
    override
    returns (string memory)
  {
    return currentPhase.aggregator.description();
  }

  /**
   * @notice Allows the owner to propose a new address for the aggregator
   * @param _aggregator The new address for the aggregator contract
   */
  function proposeAggregator(address _aggregator)
    external
    onlyOwner()
  {
    proposedAggregator = AggregatorV2V3Interface(_aggregator);
  }

  /**
   * @notice Allows the owner to confirm and change the address
   * to the proposed aggregator
   * @dev Reverts if the given address doesn't match what was previously
   * proposed
   * @param _aggregator The new address for the aggregator contract
   */
  function confirmAggregator(address _aggregator)
    external
    onlyOwner()
  {
    require(_aggregator == address(proposedAggregator), "Invalid proposed aggregator");
    delete proposedAggregator;
    setAggregator(_aggregator);
  }


  /*
   * Internal
   */

  function setAggregator(address _aggregator)
    internal
  {
    uint16 id = currentPhase.id + 1;
    currentPhase = Phase(id, AggregatorV2V3Interface(_aggregator));
    phaseAggregators[id] = AggregatorV2V3Interface(_aggregator);
  }

  function addPhase(
    uint16 _phase,
    uint64 _originalId
  )
    internal
    view
    returns (uint80)
  {
    return uint80(uint256(_phase) << PHASE_OFFSET | _originalId);
  }

  function parseIds(
    uint256 _roundId
  )
    internal
    view
    returns (uint16, uint64)
  {
    uint16 phaseId = uint16(_roundId >> PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(_roundId);

    return (phaseId, aggregatorRoundId);
  }

  function addPhaseIds(
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound,
      uint16 phaseId
  )
    internal
    view
    returns (uint80, int256, uint256, uint256, uint80)
  {
    return (
      addPhase(phaseId, uint64(roundId)),
      answer,
      startedAt,
      updatedAt,
      addPhase(phaseId, uint64(answeredInRound))
    );
  }

  /*
   * Modifiers
   */

  modifier hasProposal() {
    require(address(proposedAggregator) != address(0), "No proposed aggregator present");
    _;
  }

}


contract NativeAssetDenominatedBinaryOptions is ERC20, INativeAssetDenominatedBinaryOptions {
    using SafeMath for uint56;
    address payable public devFund;
    address payable public owner;
    address public uR; //utilization rewards
    address public biop;
    address public app;//the approved pp/ratecalc
    mapping(address=>uint256) public nW; //next withdraw (used for pool lock time)
    mapping(address=>uint256) public lW;//last withdraw.used for rewards calc
    mapping(address=>uint256) private pClaims;//pending claims
    mapping(address=>uint256) public iAL;//interchange at last claim 
    mapping(address=>uint256) public lST;//last stake time


    uint256 public oC = 0;
    uint256 public oP = 0;



    uint256 public minT;//min rounds
    uint256 public maxT;//max rounds
    uint256 public lockedAmount;
    uint256 public exerciserFee = 50;//in tenth percent
    uint256 public expirerFee = 50;//in tenth percent
    uint256 public devFundBetFee = 0;//200;//0.5%
    uint256 public poolLockSeconds = 7 days;
    uint256 public contractCreated;
    bool public open = true;
    Option[] public options;
    
    uint256 public tI = 0;//total interchange
    uint256 public rwd =  20000000000000000; //base utilitzation reward
    bool public rewEn = true;//rewards enabled


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
        address aPA;//alt pool address 
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


    /**
     * @param name_ the name of the LP token
     * @param symbol_ the symbol of the LP token
     * @param biop_ address of the gov token
     * @param uR_ address of utilization rewards contract
     * @param app_ address of approved price providerss contract
     */
      constructor(string memory name_, string memory symbol_, address biop_, address uR_, address app_) public ERC20(name_, symbol_){
        devFund = msg.sender;
        owner = msg.sender;
        biop = biop_;
        lockedAmount = 0;
        contractCreated = block.timestamp;
        minT = 1;
        maxT = 3;
        uR = uR_;
        app = app_;
    }


    function getMaxAvailable() public view returns(uint256) {
        uint256 balance = address(this).balance;
        if (balance > lockedAmount) {
            return balance.sub(lockedAmount);
        } else {
            return 0;
        }
    }


    function getOptionCount() public view returns(uint256) {
        return options.length;
    }
  

    //used for betting/exercise/expire calc
    function getBetSizeBonus(uint256 amount, bool completion) public view returns(uint256) {
        IUtilizationRewards r = IUtilizationRewards(uR);
        return r.getBetExerciseBonus(amount, address(this).balance, completion);
    }

    /**
     * @dev Update the amount of rewards pending for this user
     * @param amount the size of the trade
     * @param stack the amount of options pending before this execution
     */
    function getCompleteBonus(uint256 amount, uint256 stack) public view returns(uint256) {
        IUtilizationRewards r = IUtilizationRewards(uR);
        return r.getCompleteBonus(amount, address(this).balance, stack);
    }


    function getPendingClaims(address account) public view returns(uint256) {

        IUtilizationRewards r = IUtilizationRewards(uR);
        if (balanceOf(account) > 1) {
            //staker reward bonus
            //base*(weeks)*(poolBalanceBonus/10)*optionsBacked
            return pClaims[account].add(
                r.getLPStakingBonus(lST[account],iAL[account], tI, balanceOf(account), totalSupply())
            );
        } else {
            //normal rewards
            return pClaims[account];
        }
    }

    function updateLPmetrics() internal {
        lST[msg.sender] = block.timestamp;
        iAL[msg.sender] = tI;
    }
     /**
     * @dev distribute pending governance token claims to user
     */
    function claimRewards() external {
        
        BIOPTokenV4 b = BIOPTokenV4(biop);
        
        uint256 claims = getPendingClaims(msg.sender);
        if (balanceOf(msg.sender) >= 1) {
            updateLPmetrics();
        }
        pClaims[msg.sender] = 0;

        IUtilizationRewards r = IUtilizationRewards(uR);
        r.distributeClaim(claims);
    }

    /**
     * @dev address of this contract, convenience method
     */
    function thisAddress() public view returns (address){
        return address(this);
    }

    /**
     * @dev update BIOP token address
     * @param a the address for a new BIOP token to be used
     */
    function updateBIOPToken(address payable a) external override onlyOwner {
        biop = a; 
    }

    /**
     * @dev update reward base amount
     * @param newUR the new UtilizationRewards contract to use
     */
    function updateUtilizationRewards(address newUR) external override onlyOwner {
        uR = newUR; 
    }

    /**
     * @dev update APP
     * @param newAPP the new approved price provider (and ratecalc contract to use). Must be a IAPP
     */
    function updateAPP(address newAPP) external override onlyOwner {
        app = newAPP; 
    }

    

    /**
     * @dev enable or disable BIOP utilization rewards
     * @param nx_ the new position for the rewEn switch
     */
    function enableRewards(bool nx_) external override onlyOwner {
        rewEn = nx_;
    }

    /**
     * @dev update the max rounds for option bets
     * @param newMax_ the new maximum time (in rounds) an option may be created for (inclusive).
     */
    function setMaxT(uint256 newMax_) external override onlyOwner {
        maxT = newMax_;
    }

    /**
     * @dev update the min rounds for option bets
     * @param newMin_ the new minimum rounds (in rounds) an option may be created for (inclusive).
     */
    function setMinT(uint256 newMin_) external override onlyOwner {
        minT = newMin_;
    }

    

    /**
     * @dev set the fee users can recieve for exercising other users options
     * @param exerciserFee_ the new fee (in tenth percent) for exercising a options itm
     */
    function updateExerciserFee(uint256 exerciserFee_) external override onlyOwner {
        require(exerciserFee_ > 1 && exerciserFee_ < 500, "invalid fee");
        exerciserFee = exerciserFee_;
    }

     /**
     * @dev set the fee users can recieve for expiring other users options
     * @param expirerFee_ the new fee (in tenth percent) for expiring a options
     */
    function updateExpirerFee(uint256 expirerFee_) external override onlyOwner {
        require(expirerFee_ > 1 && expirerFee_ < 50, "invalid fee");
        expirerFee = expirerFee_;
    }

    /**
     * @dev set the fee users pay to buy an option
     * @param devFundBetFee_ the new fee (in tenth percent) to buy an option
     */
    function updateDevFundBetFee(uint256 devFundBetFee_) external override onlyOwner {
        require(devFundBetFee_ == 0 || devFundBetFee_ > 50, "invalid fee");
        devFundBetFee = devFundBetFee_;
    }

     /**
     * @dev update the pool stake lock up time.
     * @param newLockSeconds_ the new lock time, in seconds
     */
    function updatePoolLockSeconds(uint256 newLockSeconds_) external override onlyOwner {
        require(newLockSeconds_ >= 0 && newLockSeconds_ < 14 days, "invalid fee");
        poolLockSeconds = newLockSeconds_;
    }

    /**
     * @dev used to transfer ownership
     * @param newOwner_ the address of governance contract which takes over control
     */
    function transferOwner(address payable newOwner_) external override onlyOwner {
        owner = newOwner_;
    }

    /**
     * @dev used to transfer devfund 
     * @param newDevFund the address of governance contract which takes over control
     */
    function transferDevFund(address payable newDevFund) external override onlyOwner {
        devFund = newDevFund;
    }


     /**
     * @dev used to send this pool into EOL mode when a newer one is open
     */
    function closeStaking() external override onlyOwner {
        open = !open;
    }

   
    

    /**
     * @dev send ETH to the pool. Recieve pETH token representing your claim.
     * If rewards are available recieve BIOP governance tokens as well.
    */
    function stake() external payable {
        require(open == true, "pool deposits has closed");
        require(msg.value >= 100, "stake to small");
        if (balanceOf(msg.sender) == 0) {
            lW[msg.sender] = block.timestamp;
            pClaims[msg.sender] = pClaims[msg.sender].add(rwd.mul(2));
        }
        updateLPmetrics();
        nW[msg.sender] = block.timestamp + poolLockSeconds;//this one is seperate because it isn't updated on reward claim
        
        _mint(msg.sender, msg.value);
    }

    /**
     * @dev recieve ETH from the pool. 
     * If the current time is before your next available withdraw a 1% fee will be applied.
     * @param amount The amount of pETH to return the pool (burn).
    */
    function withdraw(uint256 amount) public {
       require (balanceOf(msg.sender) >= amount, "Insufficent Share Balance");
        lW[msg.sender] = block.timestamp;
        //value to receive
        uint256 vTR = amount.mul(address(this).balance).div(totalSupply().sub(lockedAmount));
        _burn(msg.sender, amount);
        if (block.timestamp <= nW[msg.sender]) {
            //early withdraw fee
            uint256 penalty = vTR.div(100);
            require(devFund.send(penalty), "transfer failed");
            require(msg.sender.send(vTR.sub(penalty)), "transfer failed");
        } else {
            require(msg.sender.send(vTR), "transfer failed");
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
        
        return rc.rate(deposit, lockedAmount , t, k, s, address(this).balance);
    }

     /**
    @dev Open a new call or put options.
    @param k_ type of option to buy (true for call )
    @param pp_ the address of the price provider to use (must be in the list of aprvd from IAPP)
    @param t_ the rounds until your options expiration (must be minT < t_ > maxT)
    */
    function bet(bool k_, address pp_, uint80 t_) external payable {
        require(
            t_ >= minT && t_ <= maxT,
            "Invalid time"
        );
        IAPP app_ = IAPP(app);
        require(app_.aprvd(pp_) != 0x0000000000000000000000000000000000000000, "Invalid  price provider");
        
        AggregatorProxy priceProvider = AggregatorProxy(pp_);
        (uint80 lR, int256 lA, , , ) = priceProvider.latestRoundData();
        uint256 oID = options.length;

        
            //normal eth bet
            require(msg.value <= getMaxAvailable(), "bet to big");


            


            uint256 lV = getRate(pp_, msg.value, t_, k_);
            
            if (rewEn) {
                pClaims[msg.sender] = pClaims[msg.sender].add(getBetSizeBonus(msg.value, false));
            }
            lock(lV);
        


        Option memory op = Option(
            msg.sender,
            lA,
            lR,
            msg.value,
            lV,
            t_,//rounds until expiration
            k_,
            pp_,
            address(this)
        );

        options.push(op);
        tI = tI.add(lV);
        if (k_) {
            oC = oC+1;
        } else {
            oP = oP+1;
        }
        emit Create(oID, msg.sender, lA, lV, k_, lR, t_);
    }

  



    

     /**
     * @notice exercises or expire a option
     * @dev exercise and expire functions have been depreciated in favor of this single complete option
     * @param oID id of the option to complete
     */
    function complete(uint256 oID)
        external
    {
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
        }


        if (rewEn) {
            pClaims[msg.sender] = pClaims[msg.sender].add(getCompleteBonus(option.lV, stack));
        }
    }

    /**
     * @notice exercise an option
     * @dev use complete to exercise (or expire) an option. This is a internal function
     * @param option the option to exercise
     * @param oID the option id
     */
    function exercise(Option memory option, uint256 oID) internal {
        //option expires ITM, we pay out

        uint256 lv = option.lV;

        //an optional (to be choosen by contract owner) fee on each option. 
        //A % of the bet money is sent as a fee. see devFundBetFee
        if (lv > devFundBetFee && devFundBetFee > 0) {
                uint256 fee = lv.div(devFundBetFee);
                require(devFund.send(fee), "devFund fee transfer failed");
                lv = lv.sub(fee);
        }

        payout(lv, msg.sender, option.holder);
        lockedAmount = lockedAmount.sub(option.lV);
        
        emit Exercise(oID);
    }

     /**
     * @notice expire an option
     * @dev use complete to expire (or exercise) an option. This is a internal function
     * @param option the option to expire
     * @param oID the option id
     */
    function expire(Option memory option, uint256 oID)
        internal
    {   
        unlock(option.lV, msg.sender);
        lockedAmount = lockedAmount.sub(option.lV);
        emit Expire(oID);
    }

    /**
    @dev called by BinaryOptions contract to lock pool value coresponding to new binary options bought. 
    @param amount amount in ETH to lock from the pool total.
    */
    function lock(uint256 amount) internal {
        lockedAmount = lockedAmount.add(amount);
    }

    /**
    @dev called by BinaryOptions contract to unlock pool value coresponding to an option expiring otm. 
    @param amount amount in ETH to unlock
    @param goodSamaritan the user paying to unlock these funds, they recieve a fee
    */
    function unlock(uint256 amount, address payable goodSamaritan) internal {
        require(amount <= lockedAmount, "insufficent locked pool balance to unlock");
        uint256 fee;
        if (amount <= 10000000000000000) {//small options give bigger fee %
            fee = amount.div(exerciserFee.mul(4)).div(100);
        } else {
            fee = amount.div(exerciserFee).div(100);
        } 
        if (fee > 0) {
            require(goodSamaritan.send(fee), "good samaritan transfer failed");
        }
    }

    /**
    @dev called by BinaryOptions contract to payout pool value coresponding to binary options expiring itm. 
    @param amount amount in ETH to unlock
    @param exerciser address calling the exercise/expire function, this may the winner or another user who then earns a fee.
    @param winner address of the winner.
    @notice exerciser fees are subject to change see updateFeePercent above.
    */
    function payout(uint256 amount, address payable exerciser, address payable winner) internal {
        require(amount <= lockedAmount, "insufficent pool balance available to payout");
        require(amount <= address(this).balance, "insufficent balance in pool");
        if (exerciser != winner) {
            //good samaratin fee
            uint256 fee;
            if (amount <= 10000000000000000) {//small options give bigger fee %
                fee = amount.div(exerciserFee.mul(4)).div(100);
            } else {
                fee = amount.div(exerciserFee).div(100);
            } 
            if (fee > 0) {
                require(exerciser.send(fee), "exerciser transfer failed");
                require(winner.send(amount.sub(fee)), "winner transfer failed");
            }
        } else {  
            require(winner.send(amount), "winner transfer failed");
        }
        emit Payout(amount, winner);
    }

}
