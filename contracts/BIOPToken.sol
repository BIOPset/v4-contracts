pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract BIOPToken is ERC20 {
    using SafeMath for uint256;
    address public binaryOptions = 0x0000000000000000000000000000000000000000;
    address public gov;
    address public owner;
    uint256 public earlyClaimsAvailable = 450000000000000000000000000000;
    uint256 public totalClaimsAvailable = 750000000000000000000000000000;
    bool public earlyClaims = true;
    bool public binaryOptionsSet = false;

    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
      owner = msg.sender;
    }
    
    modifier onlyBinaryOptions() {
        require(binaryOptions == msg.sender, "Ownable: caller is not the Binary Options Contract");
        _;
    }
    modifier onlyOwner() {
        require(binaryOptions == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function updateEarlyClaim(uint256 amount) external onlyBinaryOptions {
        require(totalClaimsAvailable.sub(amount) >= 0, "insufficent claims available");
        if (earlyClaims) {
            earlyClaimsAvailable = earlyClaimsAvailable.sub(amount);
            _mint(tx.origin, amount);
            if (earlyClaimsAvailable <= 0) {
                earlyClaims = false;
            }
        } else {
            updateClaim(amount.div(4));
        }
    }

     function updateClaim( uint256 amount) internal {
        require(totalClaimsAvailable.sub(amount) >= 0, "insufficent claims available");
        totalClaimsAvailable.sub(amount);
        _mint(tx.origin, amount);
    }

    function setupBinaryOptions(address payable options_) external {
        if (binaryOptions != 0x0000000000000000000000000000000000000000) {
            require(binaryOptions == msg.sender, "invalid origin");
        }
        binaryOptions = options_;
    }

    function setupGovernance(address payable gov_) external onlyOwner {
        _mint(owner, 100000000000000000000000000000);
        _mint(gov_, 450000000000000000000000000000);
        owner = 0x0000000000000000000000000000000000000000;
    }
}
