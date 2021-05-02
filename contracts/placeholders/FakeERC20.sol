pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeERC20 is ERC20 {

    constructor(uint256 a) public ERC20("NAME", "SYMBOL"){
        _mint(msg.sender, a);
    }

    function getSome(uint256 a) public {
        _mint(msg.sender, a);
    }
}
