
import "../interfaces/IERC20Named.sol";
import "./TokenDenominatedBinaryOptions.sol";


contract TokenDenominatedBinaryOptionsFactory {
    mapping(address => address) public tokenDenominatedBinaryOptionsAddresses;//erc20 token address mapped to ebop20 pool address
    event TokenDenominatedBinaryOptionsCreated(TokenDenominatedBinaryOptions tokenDelegatedBinaryOptions);

    address payable public owner;
    address payable public pendingOwner;

    constructor() public {
        owner = msg.sender ;
    }

    function getTokenDenominatedBinaryOptionsAddress(address token_) public returns(address) {
        return tokenDenominatedBinaryOptionsAddresses[token_];
    }

    /**
    * @dev set the new pending address to control this contract, before ownership is transfered the new address must accept
    * @param newDAO_ the new owner's address
    */
    function transferOwner(address payable newDAO_) public onlyOwner {
        pendingOwner = newDAO_;
    }

    /**
    * @dev accept ownership of the factory contract
    */
    function acceptOwnership() public {
        require(pendingOwner == msg.sender, "only pending owner can accept ownership");
        owner = pendingOwner;
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
        require(tokenDenominatedBinaryOptionsAddresses[token_] == 0x0000000000000000000000000000000000000000, "a pool for this token already exists");
        IERC20Named token = IERC20Named(token_);
        TokenDenominatedBinaryOptions newPool = new TokenDenominatedBinaryOptions(string(abi.encodePacked("Pool ", token.name)),  string(abi.encodePacked("p", token.symbol)), token_, owner, app_, treasury_);
        tokenDenominatedBinaryOptionsAddresses[address(token)] = address(newPool);
        emit TokenDenominatedBinaryOptionsCreated(newPool);
    }

    /**
    * @dev remove a tokenDenominatedBinaryOptions contract
    * @param tokenAddress_ the underlying asset of the pool to delist
    */
    function removePool(address tokenAddress_) external onlyOwner {
        delete tokenDenominatedBinaryOptionsAddresses[tokenAddress_];
    }
}