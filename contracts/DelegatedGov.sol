pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "./BIOPTokenV4.sol";

import "./interfaces/IBinaryOptions.sol";
import "./interfaces/IAPP.sol";
import "./GovProxy.sol";
interface AccessTiers {
    /**
     * @notice Returns the rate to pay out for a given amount
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier1(uint256 power, uint256 total) external returns (bool);

    /**
     * @notice Returns the rate to pay out for a given amount
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier2(uint256 power, uint256 total) external returns (bool);


    /**
     * @notice Returns the rate to pay out for a given amount
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier3(uint256 power, uint256 total) external returns (bool);


    /**
     * @notice Returns the rate to pay out for a given amount
     * @param power the amount of control held by user trying to access this action
     * @param total the total amount of control available
     * @return boolean of users access to this tier
     */
    function tier4(uint256 power, uint256 total) external returns (bool);
}

contract DelegatedAccessTiers is AccessTiers {
    using SafeMath for uint256;
    function tier1(uint256 power, uint256 total) external override returns (bool) {
        uint256 half = total.div(2);
        if (power >= half) {
            return true;
        }
        return false;
    }

    function tier2(uint256 power, uint256 total) external override returns (bool) {
        uint256 twothirds = total.div(3).mul(2);
        if (power >= twothirds) {
            return true;
        }
        return false;
    }

    function tier3(uint256 power, uint256 total) external override returns (bool) {
        uint256 threeQuarters = total.div(4).mul(3);
        if (power >= threeQuarters) {
            return true;
        }
        return false;
    }

    function tier4(uint256 power, uint256 total) external override returns (bool) {
        uint256 ninety = total.div(10).mul(9);
        if (power >= ninety) {
            return true;
        }
        return false;
    }
}



/**
 * @title DelegatedGov
 * @author github.com/Shalquiana
 * @dev governance for biopset protocol
 * @notice governance for biopset protocol
 * BIOP
 */
contract DelegatedGov {
    using SafeMath for uint256;
    address public pA;//protocol address
    address public tA;//token address
    address public aTA;//access tiers address
    address payable public pX;//proxy
    
    mapping(address=>uint256) public shas;//amounts of voting power held by each sha
    mapping(address=>address) public rep;//representative/delegate/governer currently backed by given address
    mapping(address=>uint256) public staked;//amount of BIOP they have staked
    uint256 dBIOP = 0;//the total amount of staked BIOP which has been delegated for governance

    //rewards for stakers
    uint256 public trg = 0;//total rewards generated
    mapping(address=>uint256) public lrc;//last rewards claimed at trg point for this address 
    

     constructor(address bo_, address v3_, address accessTiers_, address payable proxy_) public {
      pA = bo_;
      tA = v3_;
      aTA = accessTiers_;
      pX = proxy_;
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
            lrc[msg.sender] = trg;
        }
        staked[msg.sender] = staked[msg.sender].add(amount);
        emit Stake(amount, totalStaked());
    }

    /**
     * @notice withdraw your BIOP and stop earning rewards. You must undelegate before you can withdraw
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
     * @notice delegates your voting power to a specific address(sha)
     * @param newSha the address of the delegate to voting power
     */
    function delegate(address payable newSha) public {
        address oldSha = rep[msg.sender];
        if (oldSha == 0x0000000000000000000000000000000000000000) {
            dBIOP = dBIOP.add(staked[msg.sender]);
        } else {
            shas[oldSha] = shas[oldSha].sub(staked[msg.sender]);
        }
        shas[newSha] = shas[newSha].add(staked[msg.sender]);
        rep[msg.sender] = newSha;
    }

     /**
     * @notice undelegate your voting power. you will still earn staking rewards 
     * but your voting power won't back any delegate.
     */
    function undelegate() public {
        address oldSha = rep[msg.sender];
        shas[oldSha] = shas[oldSha].sub(staked[msg.sender]);
        rep[msg.sender] =  0x0000000000000000000000000000000000000000;
        dBIOP = dBIOP.sub(staked[msg.sender]);
    }

    /** 
    * @notice base rewards since last claim
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
        require(lrc[msg.sender] < trg, "no rewards available");
        
        uint256 toSend = pendingETHRewards(msg.sender);
        lrc[msg.sender] = trg;
        require(msg.sender.send(toSend), "transfer failed");
    }

    

    /**
     * @notice modifier for actions requiring tier 1 delegation
     */
    modifier tierOneDelegation() {
        AccessTiers tiers = AccessTiers(aTA);
        require(tiers.tier1(shas[msg.sender], dBIOP), "insufficent delegate power");
        _;
    }

    /**
     * @notice modifier for actions requiring a tier 2 delegation
     */
    modifier tierTwoDelegation() {
        AccessTiers tiers = AccessTiers(aTA);
        require(tiers.tier2(shas[msg.sender], dBIOP), "insufficent delegate power");
        _;
    }

    /**
     * @notice modifier for actions requiring a tier 3 delegation
     */
    modifier tierThreeDelegation() {
        AccessTiers tiers = AccessTiers(aTA);
        require(tiers.tier3(shas[msg.sender], dBIOP), "insufficent delegate power");
        _;
    }

    /**
     * @notice modifier for actions requiring a tier 4 delegation
     */
    modifier tierFourDelegation() {
        AccessTiers tiers = AccessTiers(aTA);
        require(tiers.tier4(shas[msg.sender], dBIOP), "insufficent delegate power");
        _;
    }


    // 0 tier anyone whose staked can do these two
    /**
     * @notice Send rewards from the proxy to gov and collect a fee
     */
    function sRTG() external {
        require(staked[msg.sender] > 100, "invalid user");
        GovProxy gp = GovProxy(pX);
        uint256 r = gp.transferToGov();
        trg = trg.add(r);
    }

    //this function has to be present or transfers to the GOV fail silently
    fallback () external payable {}


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
     * @param nMT_ the time (in seconds) of maximum possible bet
     */
    function uMXOT(uint256 nMT_) external tierOneDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.setMaxT(nMT_);
    }

    /**
     * @notice update the maximum time an option can be created for
     * @param newMinTime_ the time (in seconds) of maximum possible bet
     */
    function uMNOT(uint256 newMinTime_) external tierOneDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.setMinT(newMinTime_);
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
     * @notice update fee paid to exercisers
     * @param newFee_ the new fee
     */
    function updateExerciserFee(uint256 newFee_) external tierTwoDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.updateExerciserFee(newFee_);
    }

    /**
     * @notice update fee paid to expirers
     * @param newFee_ the new fee
     */
    function updateExpirerFee(uint256 newFee_) external tierTwoDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.updateExpirerFee(newFee_);
    }

    /**
     * @notice remove a trading pair
     * @param oldPP_ the address of trading pair to be removed
     */
    function removeTradingPair(address oldPP_) external tierTwoDelegation {
        IAPP app = IAPP(pA);
        app.removePP(oldPP_);
    }

    /**
     * @notice add (or update the RateCalc of existing) trading pair 
     * @param newPP_ the address of trading pair to be added
     * @param newRateCalc_ the address of the rate calc to be used for this pair
     */
    function addUpdateTradingPair(address newPP_, address newRateCalc_) external tierTwoDelegation {
        IAPP app = IAPP(pA);
        app.addPP(newPP_, newRateCalc_);
    }

   

    /**
     * @notice enable or disable BIOP rewards
     * @param nx_ the new boolean value of rewardsEnabled
     */
    function enableRewards(bool nx_) external tierTwoDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.enableRewards(nx_);
    }

    /**
     * @notice update the fee paid to the user whose tx transfers bet fees from GovProxy to the DelegatedGov
     * @param n_ the new fee
     */
    function enableRewards(uint256 n_) external tierTwoDelegation {
        GovProxy gp = GovProxy(pX);
        gp.updateTFee(n_);
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
     */
    function updatePoolLockTime(uint256 newLockSeconds_) external tierThreeDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.updatePoolLockSeconds(newLockSeconds_);
    }

    /**
     * @notice update the fee paid by betters when they make a bet
     * @param newBetFee_ the time (in seconds) of the soft pool lock
     */
    function updateBetFee(uint256 newBetFee_) external tierThreeDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.updateDevFundBetFee(newBetFee_);
    }

   /**
     * @dev update APP
     * @param newAPP the new approved price provider (and ratecalc contract to use). Must be a IAPP
     */
    function updateAPP(address newAPP) external tierThreeDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.updateAPP(newAPP);
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
     * @notice change the access tiers contract address used to guard all access tier functions
     * @param newAccessTiers_ the new access tiers contract to use. It should conform to AccessTiers interface
     */
    function updateAccessTiers(address newAccessTiers_) external tierFourDelegation {
        aTA = newAccessTiers_;
    }

    /**
     * @notice prevent new deposits into the pool. Effectivly end the protocol. This cannot be undone.
     */
    function closeStaking() external tierFourDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.closeStaking();
    }

    /**
     * @dev update reward base amount
     * @param newUR the new UtilizationRewards contract to use
     */
    function updateUtilizationRewards(address newUR) external tierFourDelegation {
        IBinaryOptions pr = IBinaryOptions(pA);
        pr.updateUtilizationRewards(newUR);
    }



    /**
     * @notice prevent new deposits into the pool. Effectivly end the protocol. This cannot be undone.
     * @param a the address of the new ERC20 BIOP token to use
     */
    function updateBIOPToken(address payable a) external  {
        ERC20 t = ERC20(a);
        require(keccak256(abi.encodePacked((t.symbol()))) == keccak256(abi.encodePacked(("BIOP"))), "Invalid token");
        tA = a;
    }

    /**
     * @notice prevent new deposits into the pool. Effectivly end the protocol. This cannot be undone.
     * @param a the address of the new ERC20 BIOP token to use
     */
    function updateProtocol(address payable a) external  {
        IBinaryOptions t = IBinaryOptions(a);
        tA = a;
    }

}