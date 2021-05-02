pragma solidity 0.6.6;// We declare the version of solidity this file is written in


import "@openzeppelin/contracts/math/SafeMath.sol";// We bring in OpenZeppelin's SafeMath Library
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";// We bring in OpenZeppelin's ERC20 implementation


/**
* @title Tiered IBCO (ITCO)
* @author Shalaquiana
* @notice this implementation has a known flaw, the price of tokens does not change if tier increases during a single purhcase, the buyer receives all tokens for the previous tier price.
* Licensed to everyone
*/
contract ITCO { //We define that this is the Tiered IBCO(ITCO) contract
    using SafeMath for uint256;// We set the SafeMath library for all uint256 variables
    address payable public tk; //address of the token being used in the ibco
    address payable owner; //the address that is running the ITCO
    uint256 totalDeps = 0;//total deposits that have been recieved by the pool
    uint256 public sta = 0;//start of the itco
    uint256 public end = 0; //the end time of the itco
    uint256 public total;// total amount of tokens available from the itco


    uint256 public base = 1000000000000000000;//1 token with 18 decimals, helper

    
    //Tiers. The amount (in the) that marks the top of that tier
    uint256 t1 =  450000000000000000000000;// 18 decimals by default so this is 450000
    uint256 t2 =  550000000000000000000000;
    uint256 t3 =  750000000000000000000000;
    uint256 t4 = 1050000000000000000000000;
    uint256 t5 = 1400000000000000000000000;
    uint256 t6 = 1800000000000000000000000;

    //token price at each tier. Dates are from like maybe 1/4/21?
    uint256 p1 =  80000000000000;//~$0.12
    uint256 p2 =  90000000000000;//~$0.14
    uint256 p3 = 100000000000000;//~$0.16
    uint256 p4 = 110000000000000;//~$0.17
    uint256 p5 = 120000000000000;//~$0.19
    uint256 p6 = 130000000000000;//~$0.20


    /**
    * @notice start the ibco
    * @param tk_ address of token to be ibco'd
    */
    constructor(address payable tk_) public {
        owner = msg.sender;// set the owner of the itco contract
        tk = tk_;// set teh token used for the itco
    }

    modifier onlyOwner() {// this section defines a guard function run to protect functions only accessible by the owner
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;// weird requirement for modififer types in solidity, if you know why plz share
    }

      /**
    * @dev transfer ownership
    * @param newOwner_ the new address to assume ownership responsiblity (the multisig)
    */
    function transferOwner(address payable newOwner_) public onlyOwner {
      owner = newOwner_;
    }

    /**
    * @notice start the ibco
    * @dev owner must approve IBCO contract before start will succeed
    * @param a the amount of token to include in ibco
    * @param t the total length of the ibco (seconnds after start)
     */
    function open(uint a, uint256 t) external onlyOwner {
        ERC20 token = ERC20(tk);//load the token being itco'd for transfering the total amount to distribute in
        require(token.transferFrom(msg.sender, address(this), a), "transfer failed");// transfer the amount from the owner to the itco contract
        sta = block.timestamp;// set the start time of the itco to when this function is called
        end = block.timestamp + t;// set the end time of the itco to t seconds from when this function is called
        total = a;// set the total amount in the itco equal to the the amount deposited
    }

    /**
    * @notice returns the current tier and current price. helper function
    * @dev first variable returned is tier, second is price
     */
    function currentTier() external view returns (uint256, uint256){
        uint256 price;
        uint256 t;
        if (totalDeps >= t5) {// if the total deposits so far exceeds the top of t5(tier five), use tier 6
            t = 6;// set the tier to 6
            price = p6;// set the price to the tier 6 price
        } else if (totalDeps >= t4) {// if the total deposits so far exceeds the top of t4(tier four), use tier 5
            t = 5;
            price = p5;
        } else if (totalDeps >= t3) {// if the total deposits so far exceeds the top of t4(tier three), use tier 4
            t = 4;
            price = p4;
        } else if (totalDeps >= t2) {// if the total deposits so far exceeds the top of t2(tier two), use tier 3
            t = 3;
            price = p3;
        } else if (totalDeps >= t1) {// if the total deposits so far exceeds the top of t1(tier one), use tier 2
            t = 2;
            price = p2;
        } else {//use tier one if we haven't exceeded it's top yet
            t = 1;
            price = p1;
        }
        return (t, price);//now that the tier and price have been found we return them to the function caller
    }


    /**
    * @notice withdraw the ETH emassed in the ibco
    */
    function collect() external onlyOwner {
        require(end != 0, "ITCO not opened yet");// have to wait for itco to end to withdraw funds
        require(block.timestamp > end, "ITCO not ended yet");// have to wait for itco to end to withdraw funds
        require(msg.sender.send(address(this).balance), "transfer failed");//send all ETH held in the contract to the owner

        //collect leftover tokens from unreached tiers
        ERC20 token = ERC20(tk);//load the token that was ITCO'd
        uint256 balance = token.balanceOf(address(this));// load the current balance of the tokens the itco still has
        require(token.transfer(msg.sender, balance), "transfer failed");//return any left over tokens(those that didn't sell) to the owner
    }

    

    /**
    * @notice recieve ETH in this contract
    */
    fallback () external payable {//this is what happens when users send ETH to particpate in the itco
        require(sta > 0, "IBCO not opened yet");//return ETH if itco didn't start yet
        require(block.timestamp < end, "IBCO has ended");//return ETH if itco has already ended
        
        uint256 price;
        if (totalDeps >= t5) {// if the total deposits so far exceeds the top of t5(tier five), use tier 6
            price = p6;// set the price to the tier 6 price
        } else if (totalDeps >= t4) {// if the total deposits so far exceeds the top of t4(tier four), use tier 5
            price = p5;
        } else if (totalDeps >= t3) {// if the total deposits so far exceeds the top of t4(tier three), use tier 4
            price = p4;
        } else if (totalDeps >= t2) {// if the total deposits so far exceeds the top of t2(tier two), use tier 3
            price = p3;
        } else if (totalDeps >= t1) {// if the total deposits so far exceeds the top of t1(tier one), use tier 2
            price = p2;
        } else {//use tier one if we haven't exceeded it's top yet
            price = p1;
        }
        
        require(msg.value > price, "insufficent payment for one token");//minimum purchase from the itco during any one transaction is one full token

        //tokens to send
        uint256 tTS = (msg.value.div(price));//calculate the number of tokens that will be transfered in this sale.
        tTS = tTS.mul(base);//add 18 0s, change base if using for a token with more or less then 18 decimals)
        
        ERC20 token = ERC20(tk);// load the token being used in the itco
        uint256 balance = token.balanceOf(address(this));// load the current number of tokens left in the itco
        require(balance >= tTS, "insufficent balance left in itco");// return ETH if all there arent enough tokens left for this sale

        totalDeps = totalDeps.add(msg.value);// update the total amount deposited in the pool
        require(token.transfer(msg.sender, tTS), "transfer failed");// send tokens to the user who purchased them
    }

}