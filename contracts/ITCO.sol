pragma solidity 0.6.6;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ITCO {
    using SafeMath for uint256;
    address payable public tk; //address of the token being used in the ibco
    address payable owner;
    uint256 totalDeps = 0;//total deposits
    uint256 public sta = 0;//start
    uint256 public end = 0;
    uint256 public total;
    uint256 public base = 1000000000000000000;//1 token with 18 decimals

    
    //Tiers
    uint256 t1 =  450000000000000000000000;
    uint256 t2 =  550000000000000000000000;
    uint256 t3 =  750000000000000000000000;
    uint256 t4 = 1050000000000000000000000;
    uint256 t5 = 1400000000000000000000000;
    uint256 t6 = 1800000000000000000000000;

    //token price at each tier
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
        owner = msg.sender;
        tk = tk_;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @notice start the ibco
    * @dev owner must approve IBCO contract before start will succeed
    * @param a the amount of token to include in ibco
    * @param t the total length of the ibco (seconnds after start)
     */
    function open(uint a, uint256 t) external onlyOwner {
        ERC20 token = ERC20(tk);
        require(token.transferFrom(msg.sender, address(this), a), "transfer failed");
        sta = block.timestamp;
        end = block.timestamp + t;
        total = a;
    }

    /**
    * @notice returns the current tier and current price
     */
    function currentTier() external view returns (uint256, uint256){
        uint256 price;
        uint256 t;
        if (totalDeps >= t5) {
            t = 6;
            price = p6;
        } else if (totalDeps >= t4) {
            t = 5;
            price = p5;
        } else if (totalDeps >= t3) {
            t = 4;
            price = p4;
        } else if (totalDeps >= t2) {
            t = 3;
            price = p3;
        } else if (totalDeps >= t1) {
            t = 2;
            price = p2;
        } else {
            t = 1;
            price = p1;
        }
        return (t, price);
    }


    /**
    * @notice withdraw the ETH emassed in the ibco
    */
    function collect() external onlyOwner {
        require(end != 0, "IBCO not opened yet");
        require(block.timestamp > end, "IBCO not ended yet");
        require(msg.sender.send(address(this).balance), "transfer failed");

        //collect leftover tokens from unreached tiers
        ERC20 token = ERC20(tk);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "transfer failed");
    }

    


    fallback () external payable {
        require(sta > 0, "IBCO not opened yet");
        require(block.timestamp < end, "IBCO has ended");
        uint256 price;
        if (totalDeps >= t6) {
            price = p6;
        } else if (totalDeps >= t5) {
            price = p5;
        } else if (totalDeps >= t4) {
            price = p4;
        } else if (totalDeps >= t3) {
            price = p3;
        } else if (totalDeps >= t2) {
            price = p2;
        } else {
            price = p1;
        }
        require(msg.value > price, "insufficent payment for one token");

    //tokens to send
        uint256 tTS = (msg.value.div(price));//x18
        tTS = tTS.mul(base);
        
        ERC20 token = ERC20(tk);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= tTS, "insufficent balance left in itco");

        totalDeps = totalDeps.add(msg.value);
        require(token.transfer(msg.sender, tTS), "transfer failed");
    }

}