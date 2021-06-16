pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract V2V3Claim{

    using SafeMath for uint256;

    address payable owner;

    address public token;
    address public v3;
    address public v2;
    mapping(address=>uint256) claimants;

    constructor(address token_) public {
      owner = msg.sender;

      token = token_;

      //hardcode all claimants here
      claimants[0x59cE5702F124ae45D63ae1c531E41b8c456a072d] = 10000000;
    }

     modifier onlyOwner() {
      require(msg.sender == owner, "Only callable by owner");
      _;
    }

    function open(uint256 total) public onlyOwner {

      ERC20 v4 = ERC20(token);
      v4.transferFrom(msg.sender, address(this), total);
    }

    function withdraw() public onlyOwner {
        ERC20 v4 = ERC20(token);
        uint256 balance = v4.balanceOf(address(this));
        v4.transfer(msg.sender, balance);
    }

    function transferOwner(address payable newOwner_) public onlyOwner {
        owner = newOwner_;
    }

     /**
     * @dev one time claim
     * @notice you can only claim once
     */
    function claim() external {
        uint256 toSend = claimants[msg.sender];
        require(toSend > 0, "nothing to claim");
        claimants[msg.sender] = 0;
        ERC20 v4 = ERC20(token);
        v4.transfer(msg.sender, toSend);
    }
}
