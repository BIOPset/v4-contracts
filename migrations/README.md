## Rinkeby Deployment Instructions

1. Clone repository:

```bash
git clone https://github.com/BIOPset/v4-contracts.git
```

2. Install Truffle:

```bash
sudo npm install -g truffle
```

3. Migrate contracts to Rinkeby

```bash
cd biopset-v4-contracts
git checkout -b master
truffle migrate --network rinkeby
```

4. Make yourself the contract owner (where ever such roles exist).

For example, change the variable value to your private key in the repository here:

https://github.com/BIOPset/v4-contracts/blob/main/truffle-config.js#L24

5. Confirm the hardcoded oracle address is for Rinkeby. Here is a ETH/USD oracle address for Rinkeby:

```bash
0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
```
