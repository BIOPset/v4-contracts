pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Treasury {
    using SafeMath for uint256;
    address payable public dgov;

    constructor() public {
     dgov = msg.sender;
    }

    modifier onlyDGov() {
        require(dgov == msg.sender, "Ownable: caller is not the dgov");
        _;
    }

    function updateDGov(address payable dg) public onlyDGov {
        require(dg != 0x0000000000000000000000000000000000000000, "invalid gov");
        dgov = dg;
    }

    function sendFunds(uint256 amount, address payable destination) public onlyDGov {
        require(address(this).balance <= amount, "not enough to send");
        destination.send(amount);
        emit FundsSent(amount, destination);
    }


    event FundsSent(uint256 amount, address destination);

}