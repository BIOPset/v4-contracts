
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




interface IEBOP20 is IERC20 {

    //constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_)
    /* Skeleton EBOP20 implementation. not useable*/
    function bet(int256 latestPrice, uint256 amount) external virtual returns (uint256, uint256);
    function unlockAndPayExpirer(uint256 lockValue , uint256 purchaseValue, address expirer) external virtual returns (bool);
    function payout(uint256 lockValue,uint256 purchaseValue, address sender, address buyer) external virtual returns (bool);

}