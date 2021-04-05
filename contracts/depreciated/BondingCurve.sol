pragma solidity 0.6.6;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


import "../ContinuousToken/curves/BancorBondingCurve.sol";

contract BondingCurve  is BancorBondingCurve {
    using SafeMath for uint256;
    address payable owner;
    address public tk;//token address

    uint256 public tbca =400000000000000000000000000000;//total bonding curve available


    uint256 public soldAmount = 0;
    uint256 public buyFee = 2;//10th of percent
    uint256 public sellFee = 0;//10th of percent

    constructor(address payable tk_, uint32 _reserveRatio) public BancorBondingCurve(_reserveRatio) {
        owner = msg.sender;
        tk = tk_;
    }

    


    //bonding curve functions

     /**
    * @dev method that returns BIOP amount sold by curve
    */   
    function continuousSupply() public override view returns (uint) {
        return soldAmount;
    }

    /**
    * @dev method that returns curves ETH (reserve) balance
    */    
    function reserveBalance() public override view returns (uint) {
        return address(this).balance;
    }

    /**
     * @notice purchase BIOP from the bonding curve. 
     the amount you get is based on the amount in the pool and the amount of eth u send.
     */
     function buy() public payable returns(uint256){
        uint256 purchaseAmount = msg.value;
        
         if (buyFee > 0) {
            uint256 fee = purchaseAmount.div(buyFee).div(100);
            require(owner.send(fee), "buy fee transfer failed");
           
            purchaseAmount = purchaseAmount.sub(fee);
        } 
        uint rewardAmount = getContinuousMintReward(purchaseAmount);
        require(soldAmount.add(rewardAmount) <= tbca, "maximum curve minted");
        ERC20 token = ERC20(tk);
        require(token.transfer(msg.sender, rewardAmount), "transfer failed");
        soldAmount = soldAmount.add(rewardAmount);
        return purchaseAmount;
    }

    
     /**
     * @notice sell BIOP to the bonding curve. Users must first approve this contract for token
     * @param amount the amount of BIOP to sell
     */
     function sell(uint256 amount) public returns (uint256){
         ERC20 token = ERC20(tk);
        require(token.balanceOf(msg.sender) >= amount, "insufficent BIOP balance");

        uint256 ethToSend = getContinuousBurnRefund(amount);
        uint256 fee = 0;
        if (sellFee > 0) {
            fee = ethToSend.div(buyFee).div(100);
            ethToSend = ethToSend.sub(fee);
        }
        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        
        soldAmount = soldAmount.sub(amount);
        if (fee != 0) {
            require(owner.send(fee), "buy fee transfer failed");  
        }
        require(msg.sender.send(ethToSend), "transfer failed");
        return ethToSend;
        }
}