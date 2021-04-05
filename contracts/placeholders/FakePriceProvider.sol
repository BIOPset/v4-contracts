pragma solidity ^0.6.6;

//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

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
/* contract FakePriceProvider is AggregatorV3Interface {
    uint256 public price;
    uint8 public override decimals = 8;
    string public override description = "Test implementatiln";
    uint256 public override version = 0;
    uint80 public round;

    constructor(uint256 _price) public {
        price = _price;
        round = uint80(5);
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function updateRound(uint256 _price, uint80 _round) external {
        price = _price;
        round = _round;
    }

    function getRoundData(uint80) external override view returns (uint80, int256, uint256, uint256, uint80) {
        return (round,int(price), uint256(0), uint256(0), uint80(0));
    }

    function latestAnswer() external view returns(int result) {
        (, result, , , ) = latestRoundData();
    }

    function latestRoundData()
        public
        override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256,
            uint256,
            uint80
        )
    {
        answer = int(price);
        roundId = round;
    }
} */
interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

/**
 * @title A trusted proxy for updating where current answers are read from
 * @notice This contract provides a consistent address for the
 * CurrentAnwerInterface but delegates where it reads from to the owner, who is
 * trusted to update it.
 */
contract FakePriceProvider is AggregatorV2V3Interface, Owned {

     uint256 public price;
    uint8 private override decimals_ = 8;
    string private override description_ = "Test implementatiln";
    uint80 public round;

  constructor(uint256 _price) public {
        price = _price;
        round = uint80(5);
    }

     function setPrice(uint256 _price) external {
        price = _price;
    }

    function updateRound(uint256 _price, uint80 _round) external {
        price = _price;
        round = _round;
    }

  function latestAnswer()
    public
    view
    virtual
    override
    returns (int256)
  {
    return int256(price);
  }

  function latestTimestamp()
    public
    view
    virtual
    override
    returns (uint256)
  {
    return block.timestamp;
  }

  function getAnswer(uint256 _roundId)
    public
    view
    virtual
    override
    returns (int256)
  {
      return int256(0);
  }

  function getTimestamp(uint256 _roundId)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return uint256(0);
  }

 
  function latestRound()
    public
    view
    virtual
    override
    returns (uint256)
  {
    return round;
  }

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
        answer = int256(price);
        roundId = round;
    return (roundId, answer, uint256(0), uint256(0), uint80(0));
  }

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
      answer = int256(price);
        roundId = round;
    return (roundId, answer, uint256(0), uint256(0), uint80(0));
 
  }

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
     answer = int256(price);
        roundId = round;
    return (roundId, answer, uint256(0), uint256(0), uint80(0));
 
  }

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
      answer = int256(price);
        roundId = round;
    return (roundId, answer, uint256(0), uint256(0), uint80(0));
 
  }

  function aggregator()
    external
    view
    returns (address)
  {
    return address(this);
  }

  function phaseId()
    external
    view
    returns (uint16)
  {
    return uint16(0);
  }

  function decimals()
    external
    view
    override
    returns (uint8)
  {
    return decimals_;
  }

  
  function version()
    external
    view
    override
    returns (uint256)
  {
    return uint256(0);
  }

  
  function description()
    external
    view
    override
    returns (string memory)
  {
    return description_;
  }

 
  function proposeAggregator(address _aggregator)
    external
    onlyOwner()
  {
   price = price;
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
      price = price;
  }


  /*
   * Internal
   */

  function setAggregator(address _aggregator)
    internal
  {
      price = price;
  }

  function addPhase(
    uint16 _phase,
    uint64 _originalId
  )
    internal
    view
    returns (uint80)
  {
    return uint80(0);
  }

  function parseIds(
    uint256 _roundId
  )
    internal
    view
    returns (uint16, uint64)
  {
    return (uint16(0), uint64(0));
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
    return (uint80(0), int256(0), uint256(0), uint256(0), uint80(0));
  }

  /*
   * Modifiers
   */

  modifier hasProposal() {
    require(true, "No proposed aggregator present");
    _;
  }

}

