pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract V2V3Swap{

    using SafeMath for uint256;

    address payable public owner;

    address public token;
    address public v3;
    address public v2;
    mapping(address=>uint256) claimants;

    constructor(address token_, address v2_, address v3_) public {
      owner = msg.sender;
      v3 = v3_;
      v2 = v2_;

      token = token_;
      //hardcode all claimants here
      claimants[0x59cE5702F124ae45D63ae1c531E41b8c456a072d] = 10000000;
      claimants[0x78Ebe56BC138069557C89af35EB29023fF31Ae2c] = 1000000000000000000;
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
     * @dev one time swap of v2 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv2v4(uint256 amount) external {
        
        require(claimants[msg.sender] >= amount, "not enough whitelisted for u");
        claimants[msg.sender] = claimants[msg.sender].sub(amount);
        ERC20 b2 = ERC20(v2);
        ERC20 v4 = ERC20(token);
        uint256 balance = b2.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv2 balance");
        require(v4.balanceOf(address(this)) >= amount);
        require(b2.transferFrom(msg.sender, address(this), amount), "transfer failed");
        v4.transfer(msg.sender, amount);
    }

    /**
     * @dev one time swap of v3 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv3v4(uint256 amount) external {
        require(claimants[msg.sender] >= amount, "not enough whitelisted for u");
        claimants[msg.sender] = claimants[msg.sender].sub(amount);
        ERC20 b3 = ERC20(v3);
        ERC20 v4 = ERC20(token);
        uint256 balance = b3.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv3 balance");
        require(v4.balanceOf(address(this)) >= amount);
        require(b3.transferFrom(msg.sender, address(this), amount), "transfer failed");
        v4.transfer(msg.sender, amount);
    }
}
