pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ContinuousToken/curves/BancorBondingCurve.sol";
contract LateStageBondingCurve is BancorBondingCurve {
    using SafeMath for uint256;
    ERC20 token;
    address payable dao = 0x0000000000000000000000000000000000000000;
    uint256 public tbca;//total bonding curve available
                                      

    uint256 public soldAmount = 0;
    uint256 public buyFee = 2;//in 10th of percent
    uint256 public sellFee = 0;//in 10th of percent

    constructor(address token_,  uint32 _reserveRatio) public BancorBondingCurve(_reserveRatio) {
      dao = msg.sender;
      token = ERC20(token_);
      soldAmount = 100000;//require a non zero value to start
    }

    /**
    * @dev run this function to make the deposit that starts the latestage bonding curve
    * @param total the amount of erc20 tokens to transfer into this contract
     */
    function open(uint256 total) public onlyDAO {
      token.transferFrom(msg.sender, address(this), total);
      tbca = total;
    }

    function transferDAO(address payable newDAO_) public onlyDAO {
        dao = newDAO_;
    }


     /** 
     * @dev set the fee users pay in ETH to buy BIOP from the bonding curve
     * @param newFee_ the new fee (in tenth percent) for buying on the curve
     */
    function updateBuyFee(uint256 newFee_) external onlyDAO {
        require(newFee_ > 0 && newFee_ < 40, "invalid fee");
        buyFee = newFee_;
    }

    /** 
     * @dev set the fee users pay in ETH to sell BIOP to the bonding curve
     * @param newFee_ the new fee (in tenth percent) for selling on the curve
     */
    function updateSellFee(uint256 newFee_) external onlyDAO {
        require(newFee_ > 0 && newFee_ < 40, "invalid fee");
        sellFee = newFee_;
    }

    
    modifier onlyDAO() {
        require(dao == msg.sender, "Ownable: caller is not the dao");
        _;
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
     function buy() public payable {
        uint256 purchaseAmount = msg.value;
        
         if (buyFee > 0) {
            uint256 fee = purchaseAmount.div(buyFee).div(100);
            require(dao.send(fee), "buy fee transfer failed");
            purchaseAmount = purchaseAmount.sub(fee);
        } 
        uint rewardAmount = getContinuousMintReward(purchaseAmount);
        require(soldAmount.add(rewardAmount) <= tbca, "maximum curve minted");
        token.transfer(msg.sender, rewardAmount);
        soldAmount = soldAmount.add(rewardAmount);
    }

    
     /**
     * @notice sell BIOP to the bonding curve
     * @param amount the amount of BIOP to sell
     */
     function sell(uint256 amount) public returns (uint256){
        require(token.balanceOf(msg.sender) >= amount, "insufficent BIOP balance");

        uint256 ethToSend = getContinuousBurnRefund(amount);
        if (sellFee > 0) {
            uint256 fee = ethToSend.div(buyFee).div(100);
            require(dao.send(fee), "buy fee transfer failed");
            
            ethToSend = ethToSend.sub(fee);
        }
        soldAmount = soldAmount.sub(amount);
        token.transferFrom(msg.sender, address(this), amount);
        require(msg.sender.send(ethToSend), "transfer failed");
        return ethToSend;
        }
}
