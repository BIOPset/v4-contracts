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

            //the fee paid to the user that calls the function to transfer funds
            uint256 fee = address(this).balance.div(tFee);
            uint256 tT;//to treasury
            uint256 tG = 0;//to gov(stakers directly)
            if (treasuryFee != 0) {
                //if treasury fee is not zero then calculate it
                tT = (address(this).balance.sub(fee)).div(treasuryFee);
                if (treasuryFee > 1) {
                    //if the entire amount doesn't go to the treasury
                    tG = (address(this).balance.sub(fee)).sub(tT);
                    dgov.send(tG);
                }
                treasury.send(tT);
                tx.origin.send(fee);
            } else {
                //treasury fee is 0 everything goes direct to stakers (minus transferfee, tFee)
                tG = address(this).balance.sub(fee);
                 dgov.send(tG);
                tx.origin.send(fee);
            }
            return tG;
    }

    fallback () external payable {}
}
