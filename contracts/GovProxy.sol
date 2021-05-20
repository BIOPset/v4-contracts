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
    address payable public dao;
    address payable public treasury;
    uint256 public tFee = 5000;//0.2%. This fee is for the transfer caller
    uint256 public treasuryReserve = 900;//90%

    constructor() public {
        dao = msg.sender;
    }


    modifier onlyDAO() {
        require(dao == msg.sender, "Ownable: caller is not the dao");
        _;
    }

    function updateTFee(uint256 new_) external onlyDAO {
        tFee = new_;
    }

    function updateDAO(address payable new_) external onlyDAO {
        dao = new_;
    }

    function updateTreasuryReserve(uint256 new_) external onlyDAO {
        treasuryReserve = new_;
    }

    function updateTreasury(address payable new_) external onlyDAO {
        treasury = new_;
    }

    /**
    * @dev transfer ETH or ERC20 tokens to the treasury or to the dao directly for stakers to claim
    */
    function transferToGov() external onlyDAO returns(uint256){
            require(address(this).balance > 0, "Nothing to transfer");

            uint256 fee = address(this).balance.div(tFee);
            uint256 tT;
            uint256 tG;
            if (treasuryReserve != 0) {
                //if treasury fee is not zero then calculate it
                tT = (address(this).balance.sub(fee)).div(1000).mul(treasuryReserve);//to treasury
                if (treasuryReserve < 1000) {
                    //if the entire amount doesn't go to the treasury
                    tG = (address(this).balance.sub(fee)).sub(tT);
                    dao.send(tG);
                }
                treasury.send(tT);
                tx.origin.send(fee);
            } else {
                //treasury fee is 0 everything goes direct to stakers (minus transferfee, tFee)
                tG = address(this).balance.sub(fee);
                dao.send(tG);
                tx.origin.send(fee);
            }
            return tG;
    }

    fallback () external payable {}
}
