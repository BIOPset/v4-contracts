# Biopset v3


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



initial delgation tier ratios
   #0(any%)
        - transfer bet fees from proxy
        - enable pool
   #1(50%)⭐️️️
        - update max time
        - update min time
    #2(66%)⭐️️️ ⭐️️️
        - update expire fee
        - update exercise fee
        - update proxy transfer fee
        - remove trading pair/RateCalc
        - add/update trading pair/RateCalc
        - enable/disable BIOP reward distribution
    #3(75%)⭐️️️ ⭐️️️ ⭐️️️
        - disable pool
        - update bet fee
        - update pool lock time
        - update staking rewards epoch length
        - replace APP contract
    #4(90%)⭐️️️ ⭐️️️ ⭐️️️ ⭐️️️
        - close pool from new deposits
        - change delegation tiers ratios
        - update BIOP tokenn address
        - replace rewards contract



for testing uncomment the "development" network in truffle-config.js


deploy to kovan
```truffle migrate —-network kovan --reset```
also comment out the pool deployment, it's deployed internally by the BinaryOptions contract

after deploying the setPoolAddress function on BinaryOptions has to be called manually to set it 