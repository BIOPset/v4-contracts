# Biopset v4


TODOS
    - write ebop20binaryotpions
    - add EBOP20 pools to DelegatedGov
    - write uniswap pool stake rewards contract
    - add more tests
    - create APP✅
    - use APP in binaryoptions✅
    - update times to be rounds✅
    - set update UtilizationRewards and APP✅

DelegatedGov tests:
    - exists✅
    - allows staking✅
    - allows withdraw✅
    - allows delegation✅
    - allows undelegation✅
    - allows reward claim✅
    - allows a sha to take an action✅

contracts:
 - BinaryOptions✅
    - update rewards system ✅
    - replace AggregatorV3 with AggregatorProxy✅
    - add/remove erc20 pools✅
    - bet using pooled erc20s✅
    - payout, exercise, expire from pooled erc20s✅
 - BIOPToken✅
    - v2->v3 token swap✅
    - single rewards system✅
    - launch reward bonus 4x✅
    - BIOP/ETH bonding curve✅
 - DelegratedGovernance✅
    - stake BIOP tokens✅
    - earn ETH for staked tokens✅
    - unstake BIOP tokens✅
    - delegrate voting power✅
    - undelegate voting power✅
    - voting power based guard functions✅
    - only delegated voting power is used in guard tier calculations✅
    - update settings based on voting power✅
    - update voting power guard tiers✅



## Settlement DAO Actions
Things you can do with a high enough percentage of staked $BIOP. 

When changing high tier actions its recommended that voting power be delegated to predeployed well read smart contracts and not individual users accounts.

### Tier 0
These actions are able to be done by anyone in the community.
 - Enable Pool: connect a deployed EBOP20 (ERC20 binary options pool) to the settlement dao.
 - Proxy Transfer: send pool amassed fees to their destination (the treasury or direct to $BIOP stakers) and earn a fee for the task.

### Tier 1
These actions require low consensous from the staked community members.
 - 

### Tier 2
These actions require a larger consensous and have larger consequences.

### Tier 3 
These actions aren't as potentially foundation shaking as Tier 4 but are hot.

### Tier 4
These actions require the greatest consensous amound staked participants.
 - Shutdown A Pool: Deactivate a pool if the contract is EOL and a new one has taking it's place. It can be reactivated as a new pool at any time
 - Update Consensous Tiers: Change the percentage of staker support needed to access the Settlement DAO tiers of actions.
 - Shutdown A Token: Depreciate a EOL token if the contract is being replaced (this changes the token used to judge participation levels in the Settlment DAO).
 - Replace Rewards Contract: Setup a new rewards contract to distribute governace tokens as utilization rewards to protocol participants on pool.
 - Update Treasury Address: Switch the treasury contract being used by the Settlement DAO.

#### initial delgation tier ratios
- T0 = (any amount above 0.000000000000000100)
- T1 = (50%)
- T2 = (66%)
- T3 = (75%)
- T4 = (90%)


   - t0(any%): 
       t1 - transfer bet fees from proxy
       t1 - enable pool
   - t1(50%)⭐️️️
        - update max time
        - update min time
    #2(66%)⭐️️️ ⭐️️️
        - update expire fee
        - update exercise fee
        - update proxy transfer fee
        - remove trading pair/RateCalc
        - add/update trading pair/RateCalc
        - enable/disable BIOP reward distribution
        - send treasury funds anywhere
    #3(75%)⭐️️️ ⭐️️️ ⭐️️️
        - disable pool
        - update bet fee
        - update pool lock time
        - update staking rewards epoch length
        - replace APP contract
        - update treasury percent
    #4(90%)⭐️️️ ⭐️️️ ⭐️️️ ⭐️️️
        - close pool from new deposits
        - change delegation tiers ratios
        - update BIOP tokenn address
        - replace rewards contract
        - update treasury address



## Testing (out of date)

for testing uncomment the "development" network in truffle-config.js


deploy to kovan
```truffle migrate —-network kovan --reset```
also comment out the pool deployment, it's deployed internally by the BinaryOptions contract

after deploying the setPoolAddress function on BinaryOptions has to be called manually to set it 
