# Biopset V4
A repository of contracts required to deploy version 4 of the Decentralized Binary Option Settlement Protocol. It contains the essential trading protocol and its surronding infrastructure (like the DAO contract, which is used to upgrade the protocol and control its settings).

To learn more about BIOPset please read the [Medium Publication](https://medium.com/biopset).

## Protocol Settings

The protocol charges a 1% fee on ITM options. This and other key configurable settings are listed below:

```javascript
actualRate = 2x  // The rate of return on ITM options. This drops to 1.5x during periods of high usage.
protocolFee = 1% // The fee charged by BIOPset on ITM options. Accrues to the BIOPset treasury.
sP = 10% // The percentage of treasury expenditures accruing to BIOP token holders participating in governance by staking their tokens.
settlerFee = 0.2% // The bounty paid for settling options. Traders may settle options themselves to avoid this cost.
l < 1% // The maximum utilization of the pool (the collective liquidity provided by options sellers).
amount < 0.5% // The maximum position size as a percentage of the pool (the collective liquidity provided by options sellers).
```

## Contract List

Here are a list of the contracts that comprize the protocol:

```javascript
APP.sol
BasicRateCalc.sol
NativeAssetDenominatedBinaryOptions.sol
DAO.sol
ReserveBondingCurve.sol
Treasury.sol
UtilizationRewards.sol
Vesting.sol
TieredVesting.sol
Unlock.sol
DelegatedAccessTiers.sol
TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptions.sol
TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptionsFactory.sol
interfaces/ITokenDenominatedBinaryOptions.sol
interfaces/INativeAssetDenominatedBinaryOptions.sol
interfaces/IAPP.sol
interfaces/IUtilizationRewards.sol
interfaces/IRateCalc.sol
interfaces/IAccessTiers.sol
```

## Contract Descriptions

Please note that **interfaces** are definitions of aspects of the protocol that may have a different implementations later on (like RateCalc).

### AggregatorProxy.sol

The contract retrieving trading pair pricing information from Chainlink. It’s taken from the NPM dependencies and placed in the “Chainlink” folder to make compilation easier. It could be replaced by another provider if necessary.

Interfaces with: TokenDenominatedBinaryOptions.sol and NativeAssetDenominatedBinaryOptions.sol.

### APP.sol

Approved price providers, a set of key value pairs mapping oracle addresses to RateCalc addresses.

Controlled/owned by: DAO.sol.

Interfaces with: NativeAssetDenominatedBinaryOptions.sol and TokenDenominatedBinaryOptions.sol.

Initialization parameters: pp_ the initial price provider(oracle) contract address, rc_ the initial rate calc contract address.

### BasicRateCalc.sol

The default RateCalc that will be deployed and mapped to the first oracle approved in the APP. It is responsible for limiting the percentage of the pool that can be allocated to 1%. This prevents the pool from being depleted before the laws of probability kick in.

Interfaces with: NativeAssetDenominatedBinaryOptions.sol and TokenDenominatedBinaryOptions.sol.

Initialization parameters: none.

### NativeAssetDenominatedBinaryOptions.sol

The main contract of the protocol. Allows traders to open positions, writers the ability to underwrite them, and settlers the ability to settle them. Binary options are denominated in the native asset of the underlying blockchain. On the Ethereum Blockchain, the options are denominated in ETH.

Also keeps surface level record of utilization rewards owed to users.

Controlled/owned by: DAO.sol.

Interfaces with: APP.sol, BasicRateCalc.sol, UtilizationRewards.sol, and GovProxy.sol.

Initialization parameters: name_ the name of the pool token (like Pool ETH), symbol_ the symbol of the pool token(like pETH), biop_ the address of the BIOP token contract, uR_ the address of the utilization rewards contract, app_ the address of the APP contract to be used with this pool at launch.

### DAO.sol

The Settlement DAO essentially. Those staking BIOP tokens use this contract to oversee every aspect of the protocol. It allows them to endorse contracts. Those contracts are then able to update settings and/or swap out contracts of the protocol. In particular, this component of the protocol controls the oracle & RateCalc pairs used.

It also controls the NativeAssetDenominatedBinaryOptions.sol contract.

Interfaces with: NativeAssetDenominatedBinaryOptions.sol, TokenDenominatedBinaryOptions.sol, APP.sol, TokenDenominatedBinaryOptionsFactory.sol, GovProxy.sol, LateStageBondingCurve.sol, and Treasury.sol.

Initialization parameters: bo_ the address of the NativeAssetDenominatedBinaryOptions contract, v4_ the address of the deployed BIOP token contract, accessTiers_ the address of the deployed DelegatedAccessTiers contract, factory_ the address of the TokenDenominatedBinaryOptionsFactory contract, trsy_ the address of the Treasury contract.

### ReserveBondingCurve.sol

An automatic market maker (or "**AMM**") for BIOP governance tokens. The purpose is to ensure there is always a marketplace for buying and selling BIOP tokens. It is not to be activated until after DEX rewards are complete.

Controlled/owned by: DAO.sol.

Initialization parameters: token_ the address of the BIOP token contract, _reserveRatio the ratio (initial price) of tokens to ETH (intended to be 500000 in testing).

### Treasury.sol

The treasury of funds amassed from protocol fees on ITM options. It is collectively managed by Settlement DAO members staking their BIOP governance tokens. Wheneve the treasury's ETH is spent, a percentage is sent to DAO stakers. Can be used to send amassed funds to anywhere by approved by the Settlement DAO.

Controlled/owned by: DAO.sol.

Initialization parameters: N/A.

### UtilizationRewards.sol

This contract holds and then disperse utilization rewards (in the form of BIOP governance tokens) to traders, settlers, and writers using NativeAssetDenominatedBinaryOptions.sol contract. Users call a method on NativeAssetDenominatedBinaryOptions.sol to receive funds from UtilizationRewards.sol. The only direct calls to the UtilizationRewards.sol contract are made by the Settlement DAO when depositing funds or updating contracts.

Utilization Rewards are designed to be dispersed over multiple "epochs".

Controlled/owned by: DAO.sol.

Interfaces with: NativeAssetDenominatedBinaryOptions.sol

**Note:** Token denominated binary options are ineligble for utilization rewards. Therefore this contract does not interact with TokenDenominatedBinaryOptions.sol.

Initialization parameters: token_ the address of the BIOP token contract, maxEpoch_ the total number of epochs(rounds) the rewards should run for, launchTime how long the initial bonus rewards should last for, epochLength how long(in seconds) each epoch(round) of rewards goes for.

### Vesting.sol

For vesting team tokens over the given period. There is no cliff. Once setup, only the claimant may call the relevant funds and is able to transfer the claimant roll to other addresses at their discretion.

Interfaces with: N/A.

Initialization parameters: claimant_ the address of the user who will receive the vested tokens, tokenAddress_ the address of the BIOP token contract.

### TieredVesting.sol

For vesting things like UtilizationReward tokens not activated yet. There is no cliff.

Interfaces with: N/A.

Initialization parameters: claimant_ the address of the user who will receive the vested tokens, tokenAddress_ the address of the BIOP token contract, tiers_ the number of tiers to split the token vesting into, tierLength_ the length(in seconds) of each tier.

### Unlock.sol

For vesting things like ReserveBondingCurve.sol tokens. All tokens vest at the specified date.

Interfaces with: N/A.

Initialization parameters: claimant_ the address of the user who will receive the vested tokens, tokenAddress_ the address of the BIOP token contract.

### DelegatedAccessTiers.sol

This contract is used by the DAO to protect access to protocol settings. It defines a number of *guard* functions to determine whether a user has received sufficient support of the Settlement DAO (called an "**endorsement**") to upgrade the protocol or change settings/parameters.

Interfaces with: DAO.sol and uses structure of IAccessTiers.

Initialization parameters: none.

### TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptions.sol

This contract enables token-denominated binary options trading. In particular, it allows for ERC-20 token-denominated trading on the Ethereum Network. As with NativeAssetDenominatedBinaryOptions.sol, protocol fees accrue to the Treasury.

Created by: TokenDenominatedBinaryOptionsFactory.sol.

Controlled/owned by: DAO.sol

Interfaces with: APP.sol

Initialization parameters: name_ the name of the pool token (like Pool ETH), symbol_ the symbol of the pool token(like pETH), token_ the address of the ERC20 token that will be used for this pool(and to buy binary options from it), dao_ the address DAO which will manage this pool, app_ the address of the APP contract to be used with this pool at launch, treasury_ the address of the DAO Treasury contract.

### TokenDenominatedBinaryOptions/TokenDenominatedBinaryOptionsFactory.sol

This contract handles the creation of new TokenDenominatedBinaryOptions.sol contracts.

It contains a key value mapping of ERC20 addresses to TokenDenominatedBinaryOptions addresses used by DAO.sol to determine whether TokenDenominatedBinaryOptions contracts already exist. It also controls the deactivation of any particular TokenDenominatedBinaryOptions address.

Controlled/owned by: DAO.sol.

Initialization parameters: none.

### interfaces/ITokenDenominatedBinaryOptions.sol

An interface for TokenDenominatedBinaryOptions.

### interfaces/INativeAssetDenominatedBinaryOptions.sol

An interface for NativeAssetDenominatedBinaryOptions.

### interfaces/IAPP.sol

An interface for APP.

### interfaces/IUtilizationRewards.sol

An interface for UtilizationRewards.

### interfaces/IRateCalc.sol

An interface for RateCalcs.

### interfaces/IAccessTiers.sol

An interface for AccessTiers.

## The Process For Creating BIOPSET Options

In order to commence the trading on binary options on BIOPset, the Settlement DAO (via DAO.sol) must first determine the appropriate rate-limiting (choose a **RateCalc**) and price providers (**Oracle**).

![slide0](./images/the-smart-contract-process-for-creating-biopset-options-0.png)
![slide1](./images/the-smart-contract-process-for-creating-biopset-options-1.png)
![slide2](./images/the-smart-contract-process-for-creating-biopset-options-2.png)
![slide3](./images/the-smart-contract-process-for-creating-biopset-options-3.png)
![slide4](./images/the-smart-contract-process-for-creating-biopset-options-4.png)
![slide5](./images/the-smart-contract-process-for-creating-biopset-options-5.png)
![slide6](./images/the-smart-contract-process-for-creating-biopset-options-6.png)
![slide7](./images/the-smart-contract-process-for-creating-biopset-options-7.png)

## Protocol Governance & The Settlement DAO

The more BIOP a token holder has staked into the protocol, the more their ability to control the protocol operation via smart contracts.

The Settlement DAO uses an endorsement system of governance for smart contract modifications because no single token holder possesses enough BIOP to meet the highest threshold of changes. The various thresholds are called tiers.

The amount of BIOP required for each tier is as follows:

```
- Tier 0 = (any amount above 0.000000000000000100)
- Tier 1 = (50%)
- Tier 2 = (66%)
- Tier 3 = (75%)
- Tier 4 = (90%)
```

With enough staked $BIOP every aspect of the protocol can be changed. However, since BIOP tokens are fairly distributed, changes in higher tiers require political action. Furthermore, governance guidelines stipulate that staked BIOP voting power is used to endorse pre-deployed, well-read smart contracts and not individual users accounts.

You can read more about protocol level changes [here](https://medium.com/biopset/endorsing-contracts-2f8c9447650f).

## Testing Instructions

1. Download the repository.

```bash
git clone https://github.com/BIOPset/v4-contracts.git
```

2. Navigate into a command line within the v4-contracts folder.

```bash
cd v4-contracts
```

3. Run NPM install.

```bash
npm install
```

4. Globally install ganache-cli to your system.

```bash
npm install -g ganache-cli
```

5. Globally install truffle to your system.

```bash
npm install -g truffle
```

6. Launch ganache-cli.

```bash
ganache-cli
```

7. In a seperate command line window within the same v4-contracts folder, run truffle test.

```bash
truffle test
```
