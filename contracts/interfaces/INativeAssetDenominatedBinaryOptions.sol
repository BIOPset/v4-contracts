pragma solidity 0.6.6;


/******************************************************************************\
* Author: BIOPset (https://biopset.com)
* INativeAssetDenominatedBinaryOptions: Binary Option Settlement Protocol
/******************************************************************************/

interface INativeAssetDenominatedBinaryOptions {

    function setMaxT(uint256 newMax_) external;
    function setMinT(uint256 newMin_) external;
    function updateSettlerFee(uint256 fee_) external;
    function enableRewards(bool nx_) external ;
    function updatePoolLockSeconds(uint256 newLockSeconds_) external;
    function updateProtocolFee(uint256 newProtocolFee_) external;
    function openPosition(bool k_, address pp_, uint80 t_) external payable;
    function closeStaking() external;
    function transferOwner(address payable newOwner_) external;
    function transferDevFund(address payable newDevFund) external;
    function updateUtilizationRewards(address newUR) external;
    function updateAPP(address newAPP) external;
    
}
