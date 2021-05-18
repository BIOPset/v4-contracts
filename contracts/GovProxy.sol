pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Binary Options Treasury Proxy
 * @author github.com/BIOPset
 * @dev intermediary holds funds generated from bets until they are transferred to the treasury.
 * @notice intermediary holds funds generated from bets until they are transferred to the treasury.
 * Biop
 */
contract GovProxy {
    using SafeMath for uint256;
    address payable public treasury;
    uint256 public treasuryFee = 1;//1%

    constructor() public {
        governance = msg.sender;
    }


    //ensure that this contract is only callable by governance (the Settlement DAO).
    modifier onlyGovernance() {
        require(governance == msg.sender, "Ownable: caller is not the governance");
        _;
    }

    //change the address of governance (the Settlement DAO) if required.
    function updateGovernance(address payable new_) external onlyGovernance {
        governance = new_;
    }

    function updateTreasuryAmount(uint256 new_) external onlyGovernance {
        treasuryFee = new_;
    }

    //change the address of the treasury if required.
    function updateTreasury(address payable new_) external onlyGovernance {
        treasury = new_;
    }

    /**
    * @dev transfer ETH or ERC20 tokens to the treasury.
    */
    function transferToGov() external onlyGovernance returns(uint256){
            require(address(this).balance > 0, "Nothing to transfer");
            uint256 fee = address(this).balance.div(100).mul(treasuryFee);
            if (fee != 0) {
                //if treasury fee is not zero send it to the treasury
                treasury.send(fee);
            }
            tx.origin.send(fee);
            return fG;

    }

    fallback () external payable {}
}
