pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Binary Options Gov Proxy
 * @author github.com/BIOPset
 * @dev intermediary holds funds generated from bets until they are transfered to gov
 * @notice intermediary holds funds generated from bets until they are transfered to gov
 * Biop
 */
contract GovProxy {
    using SafeMath for uint256;
    address payable public dgov;
    address payable public treasury;
    uint256 public tFee = 100;//1%. This fee is for the transfer caller
    uint256 public treasuryFee = 10;//10%

    constructor() public {
        dgov = msg.sender;
    }
      

    modifier onlyDGov() {
        require(dgov == msg.sender, "Ownable: caller is not the dgov");
        _;
    }

    function updateTFee(uint256 new_) external onlyDGov {
        tFee = new_;
    }

    function updateDGov(address payable new_) external onlyDGov {
        dgov = new_;
    }

    function updateTreasuryAmount(uint256 new_) external onlyDGov {
        treasuryFee = new_;
    }

    function updateTreasury(address payable new_) external onlyDGov {
        treasury = new_;
    }

    /**
    * @dev transfer ETH or ERC20 tokens to the treasury or to the DGov directly for stakers to claim
    */
    function transferToGov() external onlyDGov returns(uint256){
            require(address(this).balance > 0, "Nothing to transfer");
            uint256 fee = address(this).balance.div(tFee);
            uint256 tT;
            if (treasuryFee != 0) {
                //if treasury fee is not zero then calculate it
                tT = (address(this).balance.sub(fee)).div(treasuryFee);
                treasury.send(tT);
            }
            uint256 fG = 0;//amount for gov direct is zero by default
            if (treasuryFee > 1) {
                //if treasury fee is not 100% send some direct to gov
                uint256 tG = address(this).balance.sub(fee);
                dgov.send(tG);
                fG = tG;
            }
            tx.origin.send(fee);
            return fG;
       
    }

    fallback () external payable {}
}
