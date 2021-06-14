pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IAccessTiers.sol";

contract DelegatedAccessTiers is IAccessTiers {
    using SafeMath for uint256;
    function tier1(uint256 power, uint256 total) external override returns (bool) {
        uint256 half = total.div(2);
        if (power >= half) {
            return true;
        }
        return false;
    }

    function tier2(uint256 power, uint256 total) external override returns (bool) {
        uint256 twothirds = total.mul(2).div(3);
        if (power >= twothirds) {
            return true;
        }
        return false;
    }

    function tier3(uint256 power, uint256 total) external override returns (bool) {
        uint256 threeQuarters = total.mul(3).div(4);
        if (power >= threeQuarters) {
            return true;
        }
        return false;
    }

    function tier4(uint256 power, uint256 total) external override returns (bool) {
        uint256 ninety = total.mul(9).div(10);
        if (power >= ninety) {
            return true;
        }
        return false;
    }
}