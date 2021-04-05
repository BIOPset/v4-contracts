pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./BIOPToken.sol";
contract BIOPTokenV4 is ERC20 {
    bool public whitelistEnabled = false;
    mapping(address=>bool) public whitelist;
    address public owner;

    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
      _mint(msg.sender, 1300000300000000000000000000000);
      /*
      (✅ means a contract for this has been written)
      late bonding curve = 250000000000000000000000000000✅
      utilization rewards =650000000000000000000000000000✅
      swap =                    ?300000000000000000000000✅
      ITCO =               250000000000000000000000000000✅
      DEX rewards =         80000000000000000000000000000 TODO
      dev fund =            70000000000000000000000000000
      */
      whitelistEnabled = true;
      whitelist[msg.sender] = true;
      owner = msg.sender;
    }

     /**
    * @dev enables DAO to burn tokens 
    * @param amount the amount of tokens to burn
    */
    function burn(uint256 amount) public {
      require(balanceOf(msg.sender) >= amount, "insufficent balance");
      _burn(msg.sender, amount);
    }

    //Temp whitelist functionality

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
    modifier onlyOwner() {
      require(msg.sender == owner, "Only callable by owner");
      _;
    }

     /**
    * @dev transfer ownership
    * @param newOwner_ the new address to assume ownership responsiblity (the multisig)
    */
    function transferOwner(address payable newOwner_) public onlyOwner {
      owner = newOwner_;
    }

   /**
    * @dev enable a address to access the approve function while the whitelist is active
    * @param user the address to approve
    */
    function addToWhitelist(address payable user) public onlyOwner {
      whitelist[user] = true;
    }

   /**
    * @dev disable a address to access the approve function while the whitelist is active
    * @param user the address to revoke access from
    */
    function removeFromWhitelist(address payable user) public onlyOwner {
      whitelist[user] = false;
    }

    /**
    * @dev end the whitelist. This is a one time call, the whitelist cannot be renabled
    */
    function disableWhitelist() public onlyOwner {
      whitelistEnabled = false;
    }

    /**
    * @dev works like normal erc20 approve except when whitelist is enabled then sender must be whitelisted or revert.
    */
    function approve(address spender, uint256 amount) public override returns (bool) {      
      if (whitelistEnabled) {
        require(whitelist[_msgSender()] == true, "unapproved sender");
      }
      _approve(_msgSender(), spender, amount);
      return true;
    }


}
