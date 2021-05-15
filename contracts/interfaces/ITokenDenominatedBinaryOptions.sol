
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




interface ITokenDenominatedBinaryOptions is IERC20 {

    //constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_)
    /* Skeleton EBOP20 implementation*/
    function bet(bool k_, address pp_, uint80 t_, uint256 a_) external;
    function complete(uint256 oID) external returns (bool);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
}