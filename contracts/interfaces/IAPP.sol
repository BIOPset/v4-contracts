pragma solidity ^0.6.6;


/******************************************************************************\
* Author: BIOPset (https://biopset.com)
* IAPP: Approved Price Providers
/******************************************************************************/

interface IAPP {

    function aprvd(address pp) external view returns(address);
    function addPP(address newPP_, address rateCalc_) external;
    function removePP(address oldPP_) external;
    
}
