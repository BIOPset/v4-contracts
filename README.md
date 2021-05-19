# Biopset v4
Repository of contract to deploy V4 of the Decentralized Binary Option Settlement Protocol. Contains trading protocol and surronding infrastructure like DAO (called Settlement DAO or DelegatedGov).

## Settlement DAO Actions
Things you can do with a high enough percentage of staked $BIOP.

When changing high tier actions its recommended that voting power be delegated to pre-deployed well read smart contracts and not individual users accounts.

### Tier 0🏴
These actions are able to be done by anyone in the community.
 - Proxy Transfer: send pool amassed fees to their destination (the treasury or direct to $BIOP stakers) and earn a bounty for the task.

### Tier 1🌲
These actions require low consensus from the staked community members.
 - Update Max Rounds: Change the maximum time an option can be created for.
 - Update Min Rounds: Change the minimum time an option can be created for.

### Tier 2🤝🤝
These actions require a larger consensus and have larger consequences.
 - Update Settlement Bounty: Change the amount received to exercise or expire a option someone (including you) has created.
 - Update Proxy Transfer Bounty: Change the amount a received to transfer the amassed proxy funds into the treasury or directly to all stakers (on a available until claimed basis).
 - Add/Remove/Update Oracle RateCalc pair that traders can use with the protocol pool.
 - Pause/Restart Rewards: Flip the switch to enable or disable utilization rewards in the protocol.
 - Harness Treasury Funds: Direct any percentage of total available treasury funds to a specific address.

### Tier 3🔥🔥🔥  
These actions aren't as potentially foundation shaking as Tier 4 but are hot.
 - Update trade Fee: Update the percentage (2 decimal precision) fee charged to every bet and sent to the proxy.
 - Update Soft Lock Time: Change the minimum amount of time that pool participants must stake for in order to avoid any exit fee.
 - Update Staking Rewards Epoch: Change the interval at which pool staking utilization rewards compound.
 - Replace APP: Activate a new Approved Price Providers contract which contains the list of approved Oracle / RateCalc pairs.
 

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

#### initial delgation tier ratios
- T0 = (any amount above 0.000000000000000100)
- T1 = (50%)
- T2 = (66%)
- T3 = (75%)
- T4 = (90%)



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
