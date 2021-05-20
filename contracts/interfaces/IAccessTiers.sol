pragma solidity ^0.6.6;
interface IAccessTiers {
    /**
     * @notice checks if a user meets the requirement to call the given action
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier1(uint256 power, uint256 total) external returns (bool);

    /**
     * @notice checks if a user meets the requirement to call the given action
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier2(uint256 power, uint256 total) external returns (bool);


    /**
     * @notice checks if a user meets the requirement to call the given action
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier3(uint256 power, uint256 total) external returns (bool);


    /**
     * @notice checks if a user meets the requirement to call the given action
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier4(uint256 power, uint256 total) external returns (bool);
}
