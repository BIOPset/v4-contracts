pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./NativeAssetDenominatedBinaryOptions.sol";
import "./APP.sol";
import "./UtilizationRewards.sol";
import "./Treasury.sol";
import "./TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptionsFactory.sol";
import "./interfaces/IAccessTiers.sol";




/**
 * @title DAO
 * @author github.com/Shalquiana
 * @dev governance for endorsing biopset protocol changes
 * @notice governance for endorsing biopset protocol changes
 * BIOP
 */
contract DAO {
    using SafeMath for uint256;
    address public pA;//protocol address
    address public appA;//approved price providers address
    address public tA;//token address
    address public aTA;//access tiers address
    address public fcry;//TokenDenominatedBinaryOptions factory address
    address payable public trsy;//treasury

    mapping(address=>uint256) public votes;//amount of endorsement power currently directed at a address
    mapping(address=>address) public rep;//representative/delegate/governer/endorsement currently backed by given address
    mapping(address=>uint256) public staked;//amount of BIOP they have staked
    uint256 public dBIOP = 0;//the total amount of staked BIOP which has been endorsed for governance

    //ETH rewards for stakers
    uint256 public trg = 0;//total rewards generated
    mapping(address=>uint256) public lrc;//last rewards claimed at trg point for this address



    constructor(address bo_, address v4_, address accessTiers_, address app_, address factory_, address payable trsy_) public {
      pA = bo_;
      tA = v4_;
      aTA = accessTiers_;
      appA = app_;
      fcry = factory_;
      trsy = trsy_;
    }


    event Stake(uint256 amount, uint256 total);
    event Withdraw(uint256 amount, uint256 total);

    function totalStaked() public view returns (uint256) {
        ERC20 token = ERC20(tA);
        return token.balanceOf(address(this));
    }

    /**
     * @notice stake your BIOP and begin earning rewards
     * @param amount the amount in BIOP you want to stake
     */
    function stake(uint256 amount) public {
        require(amount > 0, "invalid amount");
        ERC20 token = ERC20(tA);
        require(token.balanceOf(msg.sender) >= amount, "insufficent biop balance");
        require(token.transferFrom(msg.sender, address(this), amount), "staking failed");
        if (staked[msg.sender] == 0) {
            //only for ETH
            lrc[msg.sender] = trg;
        }
        staked[msg.sender] = staked[msg.sender].add(amount);
        emit Stake(amount, totalStaked());
    }



    /**
     * @notice withdraw your BIOP and stop earning rewards. You must unendorse before you can withdraw
     * @param amount the amount in BIOP you want to withdraw
     */
    function withdraw(uint256 amount) public {
        require(staked[msg.sender] >= amount, "invalid amount");
        ERC20 token = ERC20(tA);
        require(rep[msg.sender] ==  0x0000000000000000000000000000000000000000);
        require(token.transfer(msg.sender, amount), "staking failed");
        staked[msg.sender] = staked[msg.sender].sub(amount);

        uint256 totalBalance = token.balanceOf(address(this));
        emit Withdraw(amount, totalBalance);
    }

     /**
     * @notice endorses your voting power to a specific address(sha)
     * @param newSha the address to endorse
     */
    function endorse(address payable newSha) public {
        address oldSha = rep[msg.sender];
        if (oldSha == 0x0000000000000000000000000000000000000000) {
            dBIOP = dBIOP.add(staked[msg.sender]);
        } else {
            votes[oldSha] = votes[oldSha].sub(staked[msg.sender]);
        }
        votes[newSha] = votes[newSha].add(staked[msg.sender]);
        rep[msg.sender] = newSha;
    }

     /**
     * @notice unendorse your voting power. you will still earn staking rewards
     * but your voting power won't back anyone.
     */
    function unendorse() public {
        address oldSha = rep[msg.sender];
        votes[oldSha] = votes[oldSha].sub(staked[msg.sender]);
        rep[msg.sender] =  0x0000000000000000000000000000000000000000;
        dBIOP = dBIOP.sub(staked[msg.sender]);
    }

    /**
    * @notice base ETH rewards since last claim
    * @param acc the account to get the answer for
    */
    function bRSLC(address acc) public view returns (uint256) {
        return trg.sub(lrc[acc]);
    }

    function pendingETHRewards(address account) public view returns (uint256) {
        uint256 base = bRSLC(account);
        return base.mul(staked[account]).div(totalStaked());
    }


    function claimETHRewards() public {
        require(lrc[msg.sender] <= trg, "no rewards available");

        uint256 toSend = pendingETHRewards(msg.sender);
        lrc[msg.sender] = trg;
        require(msg.sender.send(toSend), "transfer failed");
    }



    /**
     * @notice modifier for actions requiring tier 1 endorsement
     */
    modifier tierOneDelegation() {
        IAccessTiers tiers = IAccessTiers(aTA);
        require(tiers.tier1(votes[msg.sender], dBIOP), "insufficent endorsement power");
        _;
    }

    /**
     * @notice modifier for actions requiring a tier 2 endorsement
     */
    modifier tierTwoDelegation() {
        IAccessTiers tiers = IAccessTiers(aTA);
        require(tiers.tier2(votes[msg.sender], dBIOP), "insufficent endorsement power");
        _;
    }

    /**
     * @notice modifier for actions requiring a tier 3 endorsement
     */
    modifier tierThreeDelegation() {
        IAccessTiers tiers = IAccessTiers(aTA);
        require(tiers.tier3(votes[msg.sender], dBIOP), "insufficent endorsement power");
        _;
    }

    /**
     * @notice modifier for actions requiring a tier 4 endorsement
     */
    modifier tierFourDelegation() {
        IAccessTiers tiers = IAccessTiers(aTA);
        require(tiers.tier4(votes[msg.sender], dBIOP), "insufficent endorsement power");
        _;
    }





    //this function has to be present or transfers to the DAO fail silently
    fallback () external payable {
    }

     /**
     * @notice create a new TokenDenominatedBinaryOptions pool
     * @param token_ the erc20 address to underwrite the new pool
     */
    function createTokenDenominatedBinaryOptions(address token_) public {
        TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
        address tAddress = factory.getTokenDenominatedBinaryOptionsAddress(token_);
        require(tAddress == 0x0000000000000000000000000000000000000000, "pool for this token already exists, replace it instead");
        factory.createTokenDenominatedBinaryOptions(token_, trsy, appA);
    }







    /*



                                                              .-=
                      =                               :-=+#%@@@@@
               @+@+* -*   -==: ==-+.           -=+#%@@@@@@@@@@@@@
                :%    %. -%-=* :%              %@@@@@@@@@@@@@@@@@
               .=== .===: -==: ===.            %@@@@%*+=--@@@@@@@
                                               --.       .@@@@@@@
                                                         .@@@@@@@
                                                         .@@@@@@@
                                                         .@@@@@@@
                                                         .@@@@@@@
                                                         .@@@@@@@
                                                         .@@@@@@@
                      .:    :.                           .@@@@@@@
                     -@@#  #@@=                          .@@@@@@@
                     +@@#  %@@=                          .@@@@@@@
                     *@@*  @@@-                          .@@@@@@@
                     #@@+ .@@@:                          .@@@@@@@
                 .---@@@*-+@@@=--                        .@@@@@@@
                 +@@@@@@@@@@@@@@@.                       .@@@@@@@
                    .@@@: =@@@                           .@@@@@@@
                    :@@@. +@@#                           .@@@@@@@
                 -*##@@@##%@@@##*                        .@@@@@@@
                 -##%@@@##@@@%##*                        .@@@@@@@
                    +@@#  #@@=                           .@@@@@@@
                    *@@*  @@@:                           .@@@@@@@
                    *@@+  @@@.                 +**********@@@@@@@**********=
                    #@@= .@@@                  %@@@@@@@@@@@@@@@@@@@@@@@@@@@%
                    .--   :=:                  %@@@@@@@@@@@@@@@@@@@@@@@@@@@%






     */


    /**
     * @notice update the maximum time an option can be created for
     * @param nMT_ the time (in seconds) of maximum possible binary option
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function uMXOT(uint256 nMT_, address addy_) external tierOneDelegation {
        if (addy_ == pA) {
            INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
            pr.setMaxT(nMT_);
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.updateMaxT(nMT_);
        }
    }

    /**
     * @notice update the maximum time an option can be created for
     * @param nMT_ the time (in seconds) of maximum possible binary option
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function uMNOT(uint256 nMT_, address addy_) external tierOneDelegation {
        if (addy_ == pA) {
            INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
            pr.setMinT(nMT_);
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.updateMinT(nMT_);
        }
    }

    /*


                                                    .:-+*##%@@@@@@%#*+=:
              :::::   *                        .=+#@@@@@@@@@@@@@@@@@@@@@@%+:
              @-@=#: =*.  .+=+- :*=+*:        -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=
               .@:    %:  #*--#. **           -@@@@@@@%#+=-::::::-=*@@@@@@@@@@%-
              :+**- :+*++ .++++ -**+          -@@@#=:                :*@@@@@@@@@=
                                              .=.                      :%@@@@@@@@=
                                                                        .@@@@@@@@@.
                                                                         +@@@@@@@@=
                                                                         :@@@@@@@@+
                                                                         -@@@@@@@@=
                                                                         #@@@@@@@@:
                                                                        -@@@@@@@@#
                                                                       :@@@@@@@@%
                                                                      -@@@@@@@@%.
                      *#*   -##-                                    .*@@@@@@@@*
                     =@@@-  @@@%                                   =@@@@@@@@#:
                     +@@@: .@@@#                                 =%@@@@@@@%-
                     *@@@. :@@@*                              .+@@@@@@@@#-
                     #@@@  -@@@=                            .*@@@@@@@@*.
                  ...%@@@..=@@@=..                        :#@@@@@@@%=.
                :@@@@@@@@@@@@@@@@@@                     -%@@@@@@@%-
                 +++*@@@%++%@@@*++=                   :#@@@@@@@#:
                    :@@@+  #@@@                     :#@@@@@@@#:
                    -@@@=  %@@@                    +@@@@@@@%-
                .#%%@@@@@%%@@@@%%%*              -@@@@@@@@*
                .#%%@@@@%%%@@@@%%%*             *@@@@@@@@=
                    #@@@  .@@@*               .%@@@@@@@@-
                    %@@@  :@@@+              .%@@@@@@@@*
                    @@@%  -@@@=              @@@@@@@@@@#**************************.
                    @@@#  =@@@-              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
                    @@@+  =@@@.              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
                     :.    .:.               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:





     */

    /**
     * @notice update fee paid to settlers
     * @param newFee_ the new fee
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function updateSettlerFee(uint256 newFee_, address addy_) external tierTwoDelegation {
        if (addy_ == pA) {
            INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
            pr.updateSettlerFee(newFee_);
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.updateSettlerFee(newFee_);
        }
    }

    /**
     * @notice remove a trading pair
     * @param oldPP_ the address of trading pair to be removed
     */
    function removeTradingPair(address oldPP_) external tierTwoDelegation {
        APP app = APP(appA);
        app.removePP(oldPP_);
    }

    /**
     * @notice add (or update the RateCalc of existing) trading pair
     * @param newPP_ the address of trading pair to be added
     * @param newRateCalc_ the address of the rate calc to be used for this pair
     */
    function addUpdateTradingPair(address newPP_, address newRateCalc_) external tierTwoDelegation {
        APP app = APP(appA);
        app.addPP(newPP_, newRateCalc_);
    }



    /**
     * @notice enable or disable BIOP rewards, only for the main ETH pool
     * @param nx_ the new boolean value of rewardsEnabled
     */
    function enableRewards(bool nx_) external tierTwoDelegation {
        INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
        pr.enableRewards(nx_);
    }

      /**
     * @notice distribute treasury ETH funds to some destination
     * @param amount the new amount to send from the treasury, in wei
     * @param destination where the ETH should be sent
     */
    function sendTreasuryFunds(uint256 amount, address payable destination) external tierTwoDelegation {
        Treasury ty = Treasury(trsy);
        uint256 toAdd = ty.sendFunds(amount, destination);
        trg = trg.add(toAdd);
    }

    /**
     * @notice distribute treasury ERC20 funds to some destination
     * @param token the ERC20 address to transfer tokens of
     * @param amount the new amount to send from the treasury, in wei equivalent
     * @param destination where the tokens should be sent
     */
    function sendTreasuryERC20Funds(address token, uint256 amount, address payable destination) external tierTwoDelegation {
        Treasury ty = Treasury(trsy);
        ty.sendERC20Funds(token, amount, destination);
    }

    /*


                                                        .:::::::::.
                                               .-=*#%@@@@@@@@@@@@@@@@@#*=:
          -+++++   #.                         %@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
          +:+%.%  +%-  .*++*: =%++#:          %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
            +%     %-  +@==+=  @-             %@@@@#*=-:..      .:-+%@@@@@@@@@@%.
           ++++. -++++  -+++. ++++            *+-.                   .+@@@@@@@@@%
                                                                       :@@@@@@@@@-
                                                                        +@@@@@@@@*
                                                                        :@@@@@@@@*
                                                                        :@@@@@@@@+
                                                                        =@@@@@@@@:
                                                                       .@@@@@@@@=
                                                                      :%@@@@@@@=
                                                                    .*@@@@@@@%:
                                                                .:+#@@@@@@@#-
                    .      .                       :======++*#%@@@@@@@@@*-
                  -@@@-  =@@@:                     +@@@@@@@@@@@@@@@@%=.
                  *@@@=  *@@@-                     +@@@@@@@@@@@@@@@@@@@#+-.
                  #@@@-  #@@@:                     -++++++**#%%@@@@@@@@@@@@%+:
                  %@@@.  %@@@.                                  .:=#@@@@@@@@@@%-
                  @@@@   @@@@                                        :*@@@@@@@@@%.
              :::-@@@@:::@@@@:::                                       .#@@@@@@@@@:
             #@@@@@@@@@@@@@@@@@@#                                        #@@@@@@@@@.
             :+++*@@@%++*@@@%+++:                                         @@@@@@@@@+
                 -@@@*  =@@@+                                             *@@@@@@@@#
                 =@@@+  +@@@=                                             +@@@@@@@@%
             =###%@@@%##%@@@%###=                                         *@@@@@@@@#
             *@@@@@@@@@@@@@@@@@@*                                        .@@@@@@@@@+
                 #@@@:  %@@@.                                            %@@@@@@@@@.
                 %@@@.  @@@@                                           .%@@@@@@@@@+
                 @@@@  .@@@%                 +=:                     :*@@@@@@@@@@+
                 @@@@  :@@@#                 %@@@@#+=-.          .-+%@@@@@@@@@@@-
                .@@@%  -@@@*                 %@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@=
                 +%#-   *%#:                 %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-
                                             -+*#%@@@@@@@@@@@@@@@@@@@@%*=.
                                                    ..:--=======--:.


     */



    /**
     * @notice update soft lock time for the main pool.
     * @param newLockSeconds_ the time (in seconds) of the soft pool lock
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function updatePoolLockTime(uint256 newLockSeconds_, address addy_) external tierThreeDelegation {
        if (addy_ == pA) {
            INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
            pr.updatePoolLockSeconds(newLockSeconds_);
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.updatePoolLockSeconds(newLockSeconds_);
        }
    }

    /**
     * @notice update the fee paid by trader when they make a trade
     * @param newProtocolFee_ the time (in seconds) of the soft pool lock
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function updateProtocolFee(uint256 newProtocolFee_, address addy_) external tierThreeDelegation {
        if (addy_ == pA) {
            NativeAssetDenominatedBinaryOptions pr = NativeAssetDenominatedBinaryOptions(pA);
            pr.updateProtocolFee(newProtocolFee_);
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.updateProtocolFee(newProtocolFee_);
        }
    }

   /**
     * @dev update APP
     * @param newAPP_ the new approved price provider (and ratecalc contract to use). Must be a IAPP
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function updateAPP(address newAPP_, address addy_) external tierThreeDelegation {

        if (addy_ == pA) {
            INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
            pr.updateAPP(newAPP_);
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.updateAPP(newAPP_);
        }
    }

    /**
     * @dev update owner of Utilization rewards contract address
     * @param uR_ the utilization rewards contract address
     * @param addy_ the address of the new owner
     */
    function updateUROwner(address uR_, address payable addy_) external tierThreeDelegation {
        UtilizationRewards ur = UtilizationRewards(uR_);
       ur.transferDAO(addy_);
    }


    /**
     * @notice deactivate a TokenDenominatedBinaryOptions pool
     */
    function deactivateTokenDenominatedBinaryOptions(address token_) public {
        TokenDenominatedBinaryOptionsFactory factory =TokenDenominatedBinaryOptionsFactory(fcry);
        require(factory.getTokenDenominatedBinaryOptionsAddress(token_) != 0x0000000000000000000000000000000000000000, "pool for this token already exists, replace it instead");
        factory.removePool(token_);
    }

    /*





                       -                                       +######:
                %*@*+ =*   -=-  =:==                         .%@@@@@@@-
                .:%    @  +#-+= ++ .                        =@@@@@@@@@-
                .=== .===. -==:.==-                       .#@@@@@@@@@@-
                                                         =@@@@@@%@@@@@-
                                                        *@@@@@#.*@@@@@-
                                                      -@@@@@@+  *@@@@@-
                                                     *@@@@@#.   *@@@@@-
                                                   -@@@@@@=     *@@@@@-
                                                  *@@@@@%.      *@@@@@-
                                                :%@@@@@+        *@@@@@-
                       --   .-:                +@@@@@%:         *@@@@@-
                      +@@*  @@@.             .%@@@@@+           *@@@@@-
                      *@@+  @@@.            =@@@@@%:            *@@@@@-
                      #@@= .@@@           .#@@@@@+              *@@@@@-
                      %@@- -@@%          =@@@@@%-               *@@@@@-
                  :***@@@#*#@@@**=      *@@@@@@#################@@@@@@%######-
                  =#%%@@@%%@@@@%%+      %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
                     .@@@  +@@+         %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
                     -@@@  #@@=         .......................:@@@@@@+......
                  +@@@@@@@@@@@@@@#                             .@@@@@@-
                  .-=#@@%==@@@+==:                             .@@@@@@-
                     *@@*  @@@.                                .@@@@@@-
                     #@@+ .@@@                                 .@@@@@@-
                     %@@= :@@@                                 .@@@@@@-
                     *@%. .%@+                                 .@@@@@@-
                                                                ******:

     */

      /**
     * @notice change the amount (as percent) that is sent direct to dao stakers when treasury sends ETH funds
     * @param new_ the new percent. (100 = 100%, 10 = 10%, 2 = 2%)
     */
    function updateStakersPercent(uint256 new_) external tierFourDelegation {
        Treasury ty = Treasury(trsy);
        ty.updateStakerPercent(new_);
    }


       /**
     * @notice change the owner of treasury
     * @param new_ the address of new governance address
     */
    function updateTreasuryOwner(address payable new_) external tierFourDelegation {
        Treasury ty = Treasury(trsy);
        ty.updateDAO(new_);
    }

     /**
     * @notice change the access tiers contract address used to guard all access tier functions
     * @param newAccessTiers_ the new access tiers contract to use. It should conform to AccessTiers interface
     */
    function updateAccessTiers(address newAccessTiers_) external tierFourDelegation {
        aTA = newAccessTiers_;
    }

    /**
     * @notice prevent new deposits into the pool. Effectivly end that pool.
     * @param addy_ the address of the pool to update or the token used for the TokenDenominatedBinaryOptions pool (pass pA to use the default ETH pool)
     */
    function closeStaking(address addy_) external tierFourDelegation {
         if (addy_ == pA) {
            INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
            pr.closeStaking();
        } else {
            TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
            TokenDenominatedBinaryOptions pr = TokenDenominatedBinaryOptions(factory.getTokenDenominatedBinaryOptionsAddress(addy_));
            pr.closeStaking();
        }
    }

    /**
     * @dev update reward base amount, only for main ETH pool
     * @param newUR the new UtilizationRewards contract to use
     */
    function updateUtilizationRewards(address newUR) external tierFourDelegation {
        INativeAssetDenominatedBinaryOptions pr = INativeAssetDenominatedBinaryOptions(pA);
        pr.updateUtilizationRewards(newUR);
    }




    /**
     * @notice update the main ETH pool
     * @param a the address of the new INativeAssetDenominatedBinaryOptions pool to use
     */
    function updateProtocol(address payable a) external  {
        INativeAssetDenominatedBinaryOptions t = INativeAssetDenominatedBinaryOptions(a);
        tA = a;
    }

    /**
     * @notice update the factoryOwner
     * @param a the address of the new DAO to control the factory
     */
    function updateFactoryOwner(address payable a) external  {
        TokenDenominatedBinaryOptionsFactory factory = TokenDenominatedBinaryOptionsFactory(fcry);
        factory.transferOwner(a);
    }

    /**
     * @notice update the factory
     * @param a the address of the new factory to be controlled by the DAO
     */
    function updateFactory(address payable a) external  {
        fcry = a;
    }

}
