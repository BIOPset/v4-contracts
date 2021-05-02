
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./EBOP20.sol";

contract EBOP20Factory {
    mapping(address => address) private ebop20Addresses;//erc20 token address mapped to ebop20 pool address
    event EBOP20Created(EBOP20 ebop20);

    address payable public owner;

    constructor() public {
        owner = msg.sender ;
    }

    function getEBOP20Address(address token_) public returns(address) {
        return ebop20Addresses[token_];
    }

    /**
    * @dev set the new address to control this contract
    * @param newDAO_ the new owner's address
    */
    function transferOwner(address payable newDAO_) public onlyOwner {
        owner = newDAO_;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev create a new EBOP20 contract
    * @param token_ the token which will be used as the underlying asset
    */
    function createEBOP20(address token_, address payable treasury_, address app_) external {
        ERC20 token = ERC20(token_);
        EBOP20 newPool = new EBOP20(string(abi.encodePacked("Pool ", token.name)),  string(abi.encodePacked("p", token.name)), token_, owner, app_, treasury_);
        ebop20Addresses[address(token)] = address(newPool);
        emit EBOP20Created(newPool);
    }

    /**
    * @dev remove a new EBOP20 contract
    * @param tokenAddress_ the underlying asset of the pool to delist
    */
    function removePool(address tokenAddress_) external onlyOwner {
        ebop20Addresses[tokenAddress_] = 0x0000000000000000000000000000000000000000;
    }
}