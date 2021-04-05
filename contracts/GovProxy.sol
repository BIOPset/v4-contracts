pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

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
    uint256 public tFee = 100;//1%

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


    function transferToGov() external onlyDGov returns(uint256){
        require(address(this).balance > 0, "Nothing to transfer");
        uint256 fee = address(this).balance.div(tFee);
        uint256 tG = address(this).balance.sub(fee);
        dgov.send(tG);
        tx.origin.send(fee);
        return tG;
    }

    fallback () external payable {}
}