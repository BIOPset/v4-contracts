pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Treasury {
    using SafeMath for uint256;
    
    //the dao variable could be any address, but it should be the Settlement DAO address is designed so that the DAO can upgrade itself without losing the treasury
    address payable public dao;

    constructor() public {
     dao = msg.sender;
    }

    modifier onlyDAO() {
        require(dao == msg.sender, "Ownable: caller is not the dao");
        _;
    }

    function updateDGov(address payable dg) public onlyDAO {
        require(dg != 0x0000000000000000000000000000000000000000, "invalid gov");
        dao = dg;
    }

    function sendFunds(uint256 amount, address payable destination) public onlyDAO {
        require(address(this).balance >= amount, "not enough to send");
        destination.send(amount);
        emit FundsSent(amount, destination);
    }

    function sendERC20Funds(address token, uint256 amount, address payable destination) public onlyDAO {
        ERC20 tk = ERC20(token);
        uint256 balance = tk.balanceOf(address(this));
        require(balance >= amount, "not enough to send");
        tk.transfer(destination, amount);
        emit ERC20FundsSent(token, amount, destination);
    }


    event FundsSent(uint256 amount, address destination);
    event ERC20FundsSent(address token, uint256 amount, address destination);

}
