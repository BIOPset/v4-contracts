pragma solidity ^0.6.6;

    //DEPRECIATE USER V2V3Claim intead!!!!!!!!
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../BIOPToken.sol";
contract V2V3Swap{

    //DEPRECIATE USER V2V3Claim intead!!!!!!!!
    using SafeMath for uint256;

    address payable dao;

    ERC20 token;
    address public v3;
    address public v2;

    constructor(address token_, address v2_, address v3_, uint256 total) public {
      dao = msg.sender;
      v3 = v3_;
      v2 = v2_;

      token = ERC20(token_);
      token.transferFrom(msg.sender, address(this), total);
    }
    //DEPRECIATE USER V2V3Claim intead!!!!!!!!

     /**
     * @dev one time swap of v2 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv2v4(uint256 amount) external {
        BIOPToken b2 = BIOPToken(v2);
        uint256 balance = b2.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv2 balance");
        require(token.balanceOf(address(this)) >= amount);
        require(b2.transferFrom(msg.sender, address(this), amount), "transfer failed");
        token.transfer(msg.sender, amount);
    }

    /**
     * @dev one time swap of v3 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv3v4(uint256 amount) external {
        BIOPToken b3 = BIOPToken(v3);
        uint256 balance = b3.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv3 balance");
        require(token.balanceOf(address(this)) >= amount);
        require(b3.transferFrom(msg.sender, address(this), amount), "transfer failed");
        token.transfer(msg.sender, amount);
    }

    //DEPRECIATE USER V2V3Claim intead!!!!!!!!
}
