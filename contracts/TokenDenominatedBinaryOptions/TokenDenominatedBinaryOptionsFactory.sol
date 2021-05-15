
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TokenDenominatedBinaryOptions.sol";

contract TokenDenominatedBinaryOptionsFactory {
    mapping(address => address) public tokenDenominatedBinaryOptionsAddresses;//erc20 token address mapped to ebop20 pool address
    event TokenDenominatedBinaryOptionsCreated(TokenDenominatedBinaryOptions tokenDelegatedBinaryOptions);

    address payable public owner;

    constructor() public {
        owner = msg.sender ;
    }

    function getTokenDenominatedBinaryOptionsAddress(address token_) public returns(address) {
        return tokenDenominatedBinaryOptionsAddresses[token_];
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
    * @dev create a new TokenDenominatedBinaryOptions contract
    * @param token_ the token which will be used as the underlying asset
    */
    function createTokenDenominatedBinaryOptions(address token_, address payable treasury_, address app_) external {
        ERC20 token = ERC20(token_);
        TokenDenominatedBinaryOptions newPool = new TokenDenominatedBinaryOptions(string(abi.encodePacked("Pool ", token.name)),  string(abi.encodePacked("p", token.symbol)), token_, owner, app_, treasury_);
        tokenDenominatedBinaryOptionsAddresses[address(token)] = address(newPool);
        emit TokenDenominatedBinaryOptionsCreated(newPool);
    }

    /**
    * @dev remove a tokenDenominatedBinaryOptions contract
    * @param tokenAddress_ the underlying asset of the pool to delist
    */
    function removePool(address tokenAddress_) external onlyOwner {
        tokenDenominatedBinaryOptionsAddresses[tokenAddress_] = 0x0000000000000000000000000000000000000000;
    }
}