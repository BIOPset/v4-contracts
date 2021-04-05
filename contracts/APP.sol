pragma solidity ^0.6.6;


import "./interfaces/IAPP.sol";

/******************************************************************************\
* Author: BIOPset (https://biopset.com)
* APP: Approved Price Providers
/******************************************************************************/

contract APP is IAPP {
    address public owner;
    mapping(address=>address) private approved;

     /**
    * @param pp_ the price provider to add initially
    * @param rc_ the ratecalc to add initially
    */
    constructor(address pp_, address rc_) public {
        owner = msg.sender;
        approved[pp_] = rc_;
    }

     /**
    * @dev Reverts if called by anyone other than the contract owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

     /**
    * @dev get the ratecalc for a price provider
    * @param pp the price provider to look up
    */
    function aprvd(address pp)  external view override returns(address){
       return approved[pp];
    }

    /**
    * @dev transfer the owner
    * @param newOwner new owner address
    */
    function transferOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

     /**
    * @dev enable a new price provider
    * @param newPP_ the price provider to add
    * @param rateCalc_ the rate calc to use with the new price provider
    */
    function addPP(address newPP_, address rateCalc_) external override onlyOwner {
        approved[newPP_] = rateCalc_;
    }

    /**
    * @dev disable a new price provider
    * @param oldPP_ the price provider to disable
    */
    function removePP(address oldPP_) external override onlyOwner {
        approved[oldPP_] = 0x0000000000000000000000000000000000000000;
    }
    
}
