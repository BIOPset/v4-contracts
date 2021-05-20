Why is the directory here?

We are importing the contracts in here as a dependency from Chainlink. Because of import conflicts with the OpenZeppelin ERC20 & SafeMath files we use as well it is easier to keep these ones here then import them from npm as normal dependencies.

Where are these files used?

In NativeAssetDenominatedBinaryOptions & TokenDenominatedBinaryOptions.
