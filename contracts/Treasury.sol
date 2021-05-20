pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Treasury {
    using SafeMath for uint256;

    //the amount of each ETH transaction from the treasury that is distributed
    //directly and equally to all current DAO stakers
    uint256 public sP = 10;//staker percentage //10%

    //the dao variable could be any address.
    //it should be the Settlement DAO address.
    //this is so that the DAO can upgrade itself without losing its treasury.
    address payable public dao;


    constructor() public {
     dao = msg.sender;
    }

    modifier onlyDAO() {
        require(dao == msg.sender, "Ownable: caller is not the dao");
        _;
    }

    function updateDAO(address payable dg) public onlyDAO {
        require(dg != 0x0000000000000000000000000000000000000000, "invalid gov");
        dao = dg;
    }

    function updateStakerPercent(uint256 sP_) public onlyDAO {
        sP = sP_;
    }

    function sendFunds(uint256 amount, address payable destination) public onlyDAO returns(uint256){
        require(address(this).balance >= amount, "not enough to send");
        uint256 toStakers = 0;
        if (sP > 0) {
            toStakers = amount.div(100).mul(sP);
            amount = amount.sub(toStakers);
            require(msg.sender.send(toStakers), "staker transfer failed");
        }
        require(destination.send(amount), "transfer failed");

        emit FundsSent(amount, destination);
        return toStakers;
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


    fallback () external payable {}
}
