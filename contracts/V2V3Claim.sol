pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./BIOPToken.sol";
contract V2V3Claim{

    using SafeMath for uint256;

    address payable dao;

    ERC20 token;
    address public v3;
    address public v2;
    mapping(address=>uint256) claimants;

    constructor(address token_, address v2_, address v3_, uint256 total) public {
      dao = msg.sender;

      token = ERC20(token_);
      token.transferFrom(msg.sender, address(this), total);

      //hardcode all claimants here
      claimants[0x59cE5702F124ae45D63ae1c531E41b8c456a072d] = 10000000;
    }

     /**
     * @dev one time claim
     * @notice you can only claim once
     */
    function claim() external {
        uint256 toSend = claimants[msg.sender];
        require(toSend > 0, "nothing to claim");
        claimants[msg.sender] = 0;
        token.transfer(msg.sender, toSend);
    }

   
}
