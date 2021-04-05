pragma solidity ^0.6.6;


/******************************************************************************\
* Author: BIOPset (https://biopset.com)
* IBinaryOptions: Binary Option Settlement Protocol
/******************************************************************************/

interface IBinaryOptions {

    function setMaxT(uint256 newMax_) external;
    function setMinT(uint256 newMin_) external;
    function updateExerciserFee(uint256 exerciserFee_) external;
    function updateExpirerFee(uint256 expirerFee_) external;
    function enableRewards(bool nx_) external ;
    function updatePoolLockSeconds(uint256 newLockSeconds_) external;
    function updateDevFundBetFee(uint256 devFundBetFee_) external;
    function closeStaking() external;
    function transferOwner(address payable newOwner_) external;
    function transferDevFund(address payable newDevFund) external;
    function updateBIOPToken(address payable a) external;
    function updateUtilizationRewards(address newUR) external;
    function updateAPP(address newAPP) external;
    
}
