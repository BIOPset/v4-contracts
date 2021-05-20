# Biopset v4
Repository of contract to deploy V4 of the Decentralized Binary Option Settlement Protocol. Contains trading protocol and surronding infrastructure like DAO (called Settlement DAO or DelegatedGov).

## Settlement DAO Actions
Things you can do with a high enough percentage of staked $BIOP.

When changing high tier actions its recommended that voting power be delegated to pre-deployed well read smart contracts and not individual users accounts.


### Tier 1🌲
These actions require low consensus from the staked community members.
 - Update Max Rounds: Change the maximum time an option can be created for.
 - Update Min Rounds: Change the minimum time an option can be created for.

### Tier 2🤝🤝
These actions require a larger consensus and have larger consequences.
 - Update Settlement Bounty: Change the amount received to exercise or expire a option someone (including you) has created.
 - Add/Remove/Update Oracle RateCalc pair that traders can use with the protocol pool.
 - Pause/Restart Rewards: Flip the switch to enable or disable utilization rewards in the protocol.
 - Harness Treasury Funds: Direct any percentage of total available treasury funds to a specific address.
 - Enable Utilization Rewards.

### Tier 3🔥🔥🔥  
These actions aren't as potentially foundation shaking as Tier 4 but are hot.
 - Update protocol Fee: Update the percentage (2 decimal precision) fee charged to every trade and sent to the proxy.
 - Update Soft Lock Time: Change the minimum amount of time that pool participants must stake for in order to avoid any exit fee.
 - Update Staking Rewards Epoch: Change the interval at which pool staking utilization rewards compound.
 - Replace APP: Activate a new Approved Price Providers contract which contains the list of approved Oracle / RateCalc pairs.
 - Update UtilizationRewards owner.
 - Deactivate TokenDenominatedBinaryOptions: remove a TokenDenominatedBinaryOptions instance when a new version is being introduced.
 

### Tier 4🌏🌏🌏🌏
These actions require the greatest consensus around staked participants.
- Update Direct Distribution: Change the amount of tokens which are sent from the proxy to all $BIOP stakers evenly and do not go to the DAO treasury.
 - Update Consensus Tiers: Change the percentage of staker support needed to access the Settlement DAO tiers of actions.
 - Shutdown A Token: Depreciate a EOL token if the contract is being replaced (this changes the token used to judge participation levels in the Settlment DAO).
 - Replace Rewards Contract: Setup a new rewards contract to distribute governance tokens as utilization rewards to protocol participants on pool.
 - Update Treasury Address: Switch the treasury contract being used by the Settlement DAO.
 - Update Treasury Owner
 - Update Proxy Owner
 - Update Treasury
 - Update Stakers percent: change the amount that is distributed evenly to stakers whenever treasury ETH is spent.

#### initial delgation tier ratios
- T0 = (any amount above 0.000000000000000100)
- T1 = (50%)
- T2 = (66%)
- T3 = (75%)
- T4 = (90%)


#### Audit Descriptions:

APP.sol - Approved price providers, a set of key value pairs mapping Oracle addresses to RateCalcs addresses. Controlled/owned by the Settlement DAO (DAO) and utilized by NativeAssetDenominatedBinaryOptions and TokenDenominatedBinaryOptions.

BasicRateCalc.sol - A rate calculator offering mostly 2x rates based on the belief this is good for marketing. The default RateCalc that will be deployed and mapped to the first Oracle approved in the APP.

NativeAssetDenominatedBinaryOptions.sol - The main contract of the protocol. Allows traders to open trades, Writers to underwrite them, and settlers to exercise/expire them. The underlying asset is ETH. Controlled/owned by the Settlement DAO (DAO) and interfacing with APP, RateCalcs, and UtilizationRewards. Also keeps surface level record of utilization rewards owed to users.

DAO.sol - The Settlement DAO. From here $BIOP stakers oversee every aspect of the protocol. Allows stakers to delegate power to governors who are able to update settings and replace contracts of the protocol. Controls the Oracle/RateCalc pairs in the APP. Also controls the EBOP20Factory. Can be used to pay a percentage of all trading fees directly to $BIOP stakers but doesn't by default. Interfaces with NativeAssetDenominatedBinaryOptions, APP, TokenDenominatedBinaryOptions, TokenDenominatedBinaryOptionsFactory,LateStageBondingCurve, and Treasury.

ReserveBondingCurve.sol - A AMM for $BIOP tokens. Not to be activated until after DEX rewards are complete. Controlled/owned by the DAO.

Treasury.sol - The treasury of funds amassed from trading fees and owned collectively by the Settlement DAO. When ETH is sent from the treasury a percentage is sent to DAO stakers. Can be used to send amassed funds to anywhere by  the Settlement DAO. Controlled/owned by the DAO.

UtilizationRewards.sol - holds and then disperse funds to traders, settlers, and writers using NativeAssetDenominatedBinaryOptions (but not TokenDenominatedBinaryOptions). Designed to be used over multiple "epochs". Controlled/owned by SettlementDAO. Interfaces with NativeAssetDenominatedBinaryOptions. Users call a method on NativeAssetDenominatedBinaryOptions to receive funds from the UtilizationRewards. The only direct calls to the UtilizationRewards are made by the Settlement DAO when depositing funds or updating contracts. 

Vesting.sol - For vesting team tokens over the given period. No cliff, once setup only the claimant can call the relevant funds and is able to transfer the claimant roll to other addresses at their discretion. Does not interface with other contracts.

TieredVesting.sol - For vesting things like UtilizationReward tokens not activated yet. No cliff. Does not interface with other contracts.

Unlock.sol - For vesting things like LateStageBondingCurve tokens that activate all at once at a specific date. Does not interface with other contracts.

DelegatedAccessTiers.sol - used by the DAO to protect access to actions. defines a number of guard functions to check if a user has sufficient endorsement power to call a action. Interfaced with by DAO and uses structure of IAccessTiers.

TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptions.sol - TokenDenominatedBinaryOptions based binary options trading. Any fees it generates are sent directly to the Treasury. Created by TokenDenominatedBinaryOptionsFactory. Controlled/owned by the Settlement DAO. Interfaces with APP.

TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptionsFactory.sol - Handlles creation of new TokenDenominatedBinaryOptions contracts. Controlled/owned by the Settlement DAO. Also contains a key value mapping of ERC20 addresses to TokenDenominatedBinaryOptions addresses used by the Settlement DAO to determine if a TokenDenominatedBinaryOptions exists for a arbitrary TokenDenominatedBinaryOptions already. Allows deactivation of a TokenDenominatedBinaryOptions address.

Interfaces: (these are definitions of aspects that may have different implementations later on, like RateCalc):

interfaces/ITokenDenominatedBinaryOptions.sol - interface for TokenDenominatedBinaryOptions.

interfaces/INativeAssetDenominatedBinaryOptions.sol - interface for NativeAssetDenominatedBinaryOptions.

interfaces/IAPP.sol - interface for APP.

interfaces/IUtilizationRewards.sol - Interface for UtilizationRewards.

interfaces/IRateCalc.sol - Interface for RateCalcs.

interfaces/IAccessTiers.sol - Interface for AccessTiers.



# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
#### Old stuff below this point




## Testing (out of date)

for testing uncomment the "development" network in truffle-config.js


deploy to kovan
```truffle migrate —-network kovan --reset```
also comment out the pool deployment, it's deployed internally by the BinaryOptions contract

after deploying the setPoolAddress function on BinaryOptions has to be called manually to set it
