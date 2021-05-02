const BinaryOptions = artifacts.require("BinaryOptions");
const BIOPTokenV4 = artifacts.require("BIOPTokenV4");
const DelegatedGov = artifacts.require("DelegatedGov");
const GovProxy = artifacts.require("GovProxy");
const DelegatedAccessTiers = artifacts.require("DelegatedAccessTiers");
const APP = artifacts.require("APP");
const EBOP20Factory = artifacts.require("EBOP20Factory");
const UtilizationRewards = artifacts.require("UtilizationRewards");

const AdaptiveRateCalc = artifacts.require("AdaptiveRateCalc");
const LateStageBondingCurve = artifacts.require("LateStageBondingCurve");

//fake tings used for testing
const FakePriceProvider = artifacts.require("FakePriceProvider");
const FakeERC20 = artifacts.require("FakeERC20");

//const BN = web3.utils.BN;
const biopSettings = {
  name: "BIOP",
  symbol: "BIOP",
  v3: "0xC961AfDcA1c4A2A17eada10D2e89D052bEf74A85",
};

const boSettings = {
  name: "Pool Share",
  symbol: "pETH",
  owner: "0xC961AfDcA1c4A2A17eada10D2e89D052bEf74A85",
  priceProviderAddress: "0x9326BFA02ADD2366b30bacB125260Af641031331", //"0x9326BFA02ADD2366b30bacB125260Af641031331" //kovan<- ->mainnet // "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", //mainnet address
};

const appSettings = {
  priceProviderAddress: "0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0", ///0x93 is kovan ETH/USD "0x9326BFA02ADD2366b30bacB125260Af641031331", //"0x9326BFA02ADD2366b30bacB125260Af641031331" //kovan<- ->mainnet // "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", //mainnet address
};

const UtilizationRewardsSettings = {
  toTransfer: 100000,
  epochs: 7,
  launchTime: 60 * 60 * 24 * 3, //3days
};

const FakePriceSettings = {
  price: 753520000000,
};

const lateStageBondingCurveSettings = {
  reserveRatio: 500000,
  toTransfer: 100000000,
};

const FakeERC20Settings = {
  toMint: 4000000000000000,
};

//true for testrpc/ganache false for kovan
const testing = true;

module.exports = function (deployer) {
  try {
    if (testing) {
      deployer
        .deploy(FakePriceProvider, FakePriceSettings.price)
        .then((ppInstance) => {
          return deployer.deploy(AdaptiveRateCalc).then((rcInstance) => {
            console.log("deploy 1 complete");
            console.log(ppInstance.address);
            return deployer
              .deploy(BIOPTokenV4, biopSettings.name, biopSettings.symbol)
              .then((biopInstance) => {
                return deployer
                  .deploy(APP, ppInstance.address, rcInstance.address)
                  .then((appInstance) => {
                    return deployer
                      .deploy(EBOP20Factory)
                      .then((factoryInstance) => {
                        return deployer
                          .deploy(FakeERC20, FakeERC20Settings.toMint)
                          .then((fakeERC20) => {
                            return deployer
                              .deploy(
                                UtilizationRewards,
                                biopInstance.address,
                                UtilizationRewardsSettings.epochs,
                                UtilizationRewardsSettings.launchTime
                              )
                              .then(async (urInstance) => {
                                return deployer
                                  .deploy(
                                    LateStageBondingCurve,
                                    biopInstance.address,
                                    lateStageBondingCurveSettings.reserveRatio
                                  )
                                  .then(async (lsbcInstance) => {
                                    await biopInstance.approve(
                                      urInstance.address,
                                      UtilizationRewardsSettings.toTransfer
                                    );
                                    await urInstance.deposit(
                                      UtilizationRewardsSettings.toTransfer
                                    );
                                    await biopInstance.approve(
                                      lsbcInstance.address,
                                      lateStageBondingCurveSettings.toTransfer
                                    );
                                    await lsbcInstance.open(
                                      lateStageBondingCurveSettings.toTransfer
                                    );
                                    console.log("deploy 2 complete");
                                    console.log(biopInstance.address);
                                    return deployer
                                      .deploy(
                                        BinaryOptions,
                                        boSettings.name,
                                        boSettings.symbol,
                                        biopInstance.address,
                                        urInstance.address,
                                        appInstance.address
                                      )
                                      .then(async (boInstance) => {
                                        return deployer
                                          .deploy(DelegatedAccessTiers)
                                          .then(async (tiersInstance) => {
                                            return deployer
                                              .deploy(GovProxy)
                                              .then(async (proxyInstance) => {
                                                return deployer
                                                  .deploy(
                                                    DelegatedGov,
                                                    boInstance.address,
                                                    biopInstance.address,
                                                    tiersInstance.address,
                                                    proxyInstance.address,
                                                    factoryInstance.address,
                                                    appInstance.address
                                                  )
                                                  .then(async (govInstance) => {
                                                    await boInstance.transferDevFund(
                                                      proxyInstance.address
                                                    );
                                                    await boInstance.transferOwner(
                                                      govInstance.address
                                                    );
                                                    await factoryInstance.transferOwner(
                                                      govInstance.address
                                                    );
                                                    await proxyInstance.updateDGov(
                                                      govInstance.address
                                                    );
                                                    await biopInstance.disableWhitelist();
                                                    return await urInstance.setupBinaryOptions(
                                                      boInstance.address
                                                    );
                                                  });
                      });});
                  });
              });
          });
        })})})})})})
        .catch((e) => {
          console.log("caught");
          console.log(e);
        });
    } else {
      //this script uses a Fake price provider
      deployer
        .deploy(BIOPTokenV4, biopSettings.name, biopSettings.symbol)
        .then((biopInstance) => {
          console.log("deploy 1 complete");
          console.log(biopInstance.address);
          return deployer.deploy(AdaptiveRateCalc).then((rcInstance) => {
            return deployer
              .deploy(APP, appSettings.priceProviderAddress, rcInstance.address)
              .then((appInstance) => {
                return deployer
                  .deploy(EBOP20Factory)
                  .then((factoryInstance) => {
                    return deployer
                      .deploy(
                        UtilizationRewards,
                        biopInstance.address,
                        UtilizationRewardsSettings.epochs,
                        UtilizationRewardsSettings.launchTime
                      )
                      .then(async (urInstance) => {
                        await biopInstance.approve(
                          urInstance.address,
                          UtilizationRewardsSettings.toTransfer
                        );
                        await urInstance.deposit(
                          UtilizationRewardsSettings.toTransfer
                        );
                        return deployer
                          .deploy(
                            BinaryOptions,
                            boSettings.name,
                            boSettings.symbol,
                            biopInstance.address,
                            urInstance.address,
                            appInstance.address
                          )
                          .then(async (boInstance) => {
                            return deployer
                              .deploy(DelegatedAccessTiers)
                              .then(async (tiersInstance) => {
                                return deployer
                                  .deploy(GovProxy)
                                  .then(async (proxyInstance) => {
                                    return deployer
                                      .deploy(
                                        DelegatedGov,
                                        boInstance.address,
                                        biopInstance.address,
                                        tiersInstance.address,
                                        proxyInstance.address,
                                        factoryInstance.address,
                                        appInstance.address
                                      )
                                      .then(async (govInstance) => {
                                        await boInstance.transferDevFund(
                                          proxyInstance.address
                                        );
                                        await boInstance.transferOwner(
                                          govInstance.address
                                        );
                                        await factoryInstance.transferOwner(
                                          govInstance.address
                                        );
                                        await proxyInstance.updateDGov(
                                          govInstance.address
                                        );

                                        return await urInstance.setupBinaryOptions(
                                          boInstance.address
                                        );
                                      });
                                  });
                              });
                          });
                      });
                  });
              });
          });
        });
    }
  } catch (e) {
    console.log(e);
  }
};

/* real kovan deplyment script
deployer
        .deploy(BIOPTokenV4, biopSettings.name, biopSettings.symbol)
        .then((biopInstance) => {
          console.log("deploy 1 complete");
          console.log(biopInstance.address);
          return deployer.deploy(AdaptiveRateCalc).then((rcInstance) => {
            return deployer.deploy(
              APP,
              appSettings.priceProviderAddress,
              rcInstance.address
              ).then((appInstance) => {
              return deployer.deploy(
                UtilizationRewards,
                biopInstance.address,
                UtilizationRewardsSettings.epochs,
                UtilizationRewardsSettings.launchTime
                ).then(async (urInstance) => {
                  await biopInstance.approve(
                    urInstance.address,
                    UtilizationRewardsSettings.toTransfer
                  );
                  await urInstance.deposit(
                    UtilizationRewardsSettings.toTransfer
                  );
                return deployer
                  .deploy(
                    BinaryOptions,
                    boSettings.name,
                    boSettings.symbol,
                    biopInstance.address,
                    urInstance.address,
                    appInstance.address
                  )
                  .then(async (boInstance) => {
                    return deployer
                      .deploy(DelegatedAccessTiers)
                      .then(async (tiersInstance) => {
                        return deployer
                          .deploy(GovProxy)
                          .then(async (proxyInstance) => {
                            return deployer
                              .deploy(
                                DelegatedGov,
                                boInstance.address,
                                biopInstance.address,
                                tiersInstance.address,
                                proxyInstance.address
                              )
                              .then(async (govInstance) => {
                                await boInstance.transferDevFund(
                                  proxyInstance.address
                                );
                                await boInstance.transferOwner(
                                  govInstance.address
                                );
                                await proxyInstance.updateDGov(
                                  govInstance.address
                                );

                                return await urInstance.setupBinaryOptions(
                                  boInstance.address
                                );
                              });
                          });
                      });
                  });
              });
            });
          });
        });
*/
