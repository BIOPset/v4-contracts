var TokenDenominatedBinaryOptions = artifacts.require("TokenDenominatedBinaryOptions");
var FakeERC20 = artifacts.require("FakeERC20");
var APP = artifacts.require("APP");
var FakePriceProvider = artifacts.require("FakePriceProvider");
var BasicRateCalc = artifacts.require("BasicRateCalc");

var BN = web3.utils.BN;
const toWei = (value) => web3.utils.toWei(value.toString(), "ether");
var basePrice = 753520000000;
var oneHour = 3600;
const send = (method, params = []) =>
  new Promise((resolve, reject) =>
    web3.currentProvider.send(
      { id: 0, jsonrpc: "2.0", method, params },
      (err, x) => {
        if (err) reject(err);
        else resolve(x);
      }
    )
  );
const timeTravel = async (seconds) => {
  return new Promise(async (resolve, reject) => {
    await send("evm_increaseTime", [seconds]);
    await send("evm_min");
    await send("evm_min");
    await send("evm_min");
    await send("evm_min");
    resolve();
  });
};

contract("TokenDenominatedBinaryOptions", (accounts) => {
  it("exists", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return TokenDenominatedBinaryOptions.new(
        "poolName",
        "PoolSymbol",
        fakeerc20.address,
        accounts[2],
        accounts[1],
        accounts[3]
      ).then(async function (instance) {
        assert.equal(
          typeof instance,
          "object",
          "Contract instance does not exist"
        );
      });
    });
  });

  it("can deposit", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return TokenDenominatedBinaryOptions.new(
        "poolName",
        "PoolSymbol",
        fakeerc20.address,
        accounts[2],
        accounts[1],
        accounts[3]
      ).then(async function (instance) {
        await fakeerc20.getSome(1000000000, { from: accounts[0] });
        await fakeerc20.approve(instance.address, 1000000000, {
          from: accounts[0],
        });
        await instance.stake(1000000000, { from: accounts[0] });
        var poolShares = await instance.balanceOf(accounts[0]);
        var poolBalance = await fakeerc20.balanceOf(instance.address);
        console.log(`pool shares = ${poolShares * 1}`);
        console.log(`pool balance = ${poolBalance * 1}`);
        assert.equal(
          `${poolShares * 1}`,
          `${poolBalance * 1}`,
          "outstanding shares is not equal to balance"
        );
      });
    });
  });
  it("can withdraw", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return TokenDenominatedBinaryOptions.new(
        "poolName",
        "PoolSymbol",
        fakeerc20.address,
        accounts[2],
        accounts[1],
        accounts[3]
      ).then(async function (instance) {
        await fakeerc20.getSome(1000000000, { from: accounts[0] });
        await fakeerc20.approve(instance.address, 1000000000, {
          from: accounts[0],
        });
        await instance.stake(1000000000, { from: accounts[0] });
        await instance.withdraw(1000000000, { from: accounts[0] });
        var poolShares = await instance.balanceOf(accounts[0]);
        var poolBalance = await fakeerc20.balanceOf(instance.address);
        console.log(`pool shares = ${poolShares * 1}`);
        console.log(`pool balance = ${poolBalance * 1}`);
        assert.equal(
          `${poolShares * 1}`,
          `${poolBalance * 1}`,
          "outstanding shares is not equal to balance"
        );
      });
    });
  });
  it("can take a call bet", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return FakePriceProvider.new(100000).then(async function (fakePP) {
        return BasicRateCalc.new().then(async function (rcInstance) {
          return APP.new(fakePP.address, rcInstance.address).then(
            async function (fakeAPP) {
              return TokenDenominatedBinaryOptions.new(
                "poolName",
                "PoolSymbol",
                fakeerc20.address,
                accounts[2],
                fakeAPP.address,
                accounts[3]
              ).then(async function (instance) {
                await fakeerc20.getSome(1000000000, { from: accounts[0] });
                await fakeerc20.approve(instance.address, 1000000000, {
                  from: accounts[0],
                });
                await instance.stake(1000000000, { from: accounts[0] });
                await fakeerc20.getSome(10000, { from: accounts[4] });
                await fakeerc20.approve(instance.address, 10000, {
                  from: accounts[4],
                });
                await instance.bet(true, fakePP.address, 1, 10000, {
                  from: accounts[4],
                });
                var poolBalance = await fakeerc20.balanceOf(instance.address);
                console.log(`pool balance = ${poolBalance * 1}`);
                assert.equal(
                  `${10000+1000000000}`,
                  `${poolBalance * 1}`,
                  "pool balance is invalid"
                );
              });
            }
          );
        });
      });
    });
  });
  it("can take a put bet", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return FakePriceProvider.new(100000).then(async function (fakePP) {
        return BasicRateCalc.new().then(async function (rcInstance) {
          return APP.new(fakePP.address, rcInstance.address).then(
            async function (fakeAPP) {
              return TokenDenominatedBinaryOptions.new(
                "poolName",
                "PoolSymbol",
                fakeerc20.address,
                accounts[2],
                fakeAPP.address,
                accounts[3]
              ).then(async function (instance) {
                await fakeerc20.getSome(1000000000, { from: accounts[0] });
                await fakeerc20.approve(instance.address, 1000000000, {
                  from: accounts[0],
                });
                await instance.stake(1000000000, { from: accounts[0] });
                await fakeerc20.getSome(10000, { from: accounts[4] });
                await fakeerc20.approve(instance.address, 10000, {
                  from: accounts[4],
                });
                await instance.bet(false, fakePP.address, 1, 10000, {
                  from: accounts[4],
                });
                var poolBalance = await fakeerc20.balanceOf(instance.address);
                console.log(`pool balance = ${poolBalance * 1}`);
                assert.equal(
                  `${10000+1000000000}`,
                  `${poolBalance * 1}`,
                  "pool balance is invalid"
                );
              });
            }
          );
        });
      });
    });
  });
  it("can exercise a bet", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return FakePriceProvider.new(100000).then(async function (fakePP) {
        return BasicRateCalc.new().then(async function (rcInstance) {
          return APP.new(fakePP.address, rcInstance.address).then(
            async function (fakeAPP) {
              return TokenDenominatedBinaryOptions.new(
                "poolName",
                "PoolSymbol",
                fakeerc20.address,
                accounts[2],
                fakeAPP.address,
                accounts[3]
              ).then(async function (instance) {
                await fakeerc20.getSome(1000000000, { from: accounts[0] });
                await fakeerc20.approve(instance.address, 1000000000, {
                  from: accounts[0],
                });
                await instance.stake(1000000000, { from: accounts[0] });
                await fakeerc20.getSome(10000, { from: accounts[4] });
                await fakeerc20.approve(instance.address, 10000, {
                  from: accounts[4],
                });
                await instance.bet(true, fakePP.address, 1, 10000, {
                  from: accounts[4],
                });
                await fakePP.updateRound(100005, 6, {from: accounts[0]});
                await instance.complete(0, {from: accounts[4]});
                var poolBalance = await fakeerc20.balanceOf(instance.address);
                console.log(`pool balance = ${poolBalance * 1}`);
                assert.equal(
                  `999990000`, //pool is down the bet amount
                  `${poolBalance * 1}`,
                  "pool balance is invalid after exercise"
                );
              });
            }
          );
        });
      });
    });
  });
  it("can expire a bet", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return FakePriceProvider.new(100000).then(async function (fakePP) {
        return BasicRateCalc.new().then(async function (rcInstance) {
          return APP.new(fakePP.address, rcInstance.address).then(
            async function (fakeAPP) {
              return TokenDenominatedBinaryOptions.new(
                "poolName",
                "PoolSymbol",
                fakeerc20.address,
                accounts[2],
                fakeAPP.address,
                accounts[3]
              ).then(async function (instance) {
                await fakeerc20.getSome(1000000000, { from: accounts[0] });
                await fakeerc20.approve(instance.address, 1000000000, {
                  from: accounts[0],
                });
                await instance.stake(1000000000, { from: accounts[0] });
                await fakeerc20.getSome(10000, { from: accounts[4] });
                await fakeerc20.approve(instance.address, 10000, {
                  from: accounts[4],
                });
                await instance.bet(true, fakePP.address, 1, 10000, {
                  from: accounts[4],
                });
                await fakePP.updateRound(090000, 6, {from: accounts[0]});
                await instance.complete(0, {from: accounts[4]});
                var poolBalance = await fakeerc20.balanceOf(instance.address);
                console.log(`pool balance = ${poolBalance * 1}`);
                assert.equal(
                  `1000009999`,//pool is up the bet amount minus complete fee
                  `${poolBalance * 1}`,
                  "pool balance is invalid after expire"
                );
              });
            }
          );
        });
      });
    });
  });
  it("can unstake after pool changes", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return FakePriceProvider.new(100000).then(async function (fakePP) {
        return BasicRateCalc.new().then(async function (rcInstance) {
          return APP.new(fakePP.address, rcInstance.address).then(
            async function (fakeAPP) {
              return TokenDenominatedBinaryOptions.new(
                "poolName",
                "PoolSymbol",
                fakeerc20.address,
                accounts[2],
                fakeAPP.address,
                accounts[3]
              ).then(async function (instance) {
                await fakeerc20.getSome(1000000000, { from: accounts[0] });
                await fakeerc20.approve(instance.address, 1000000000, {
                  from: accounts[0],
                });
                await instance.stake(1000000000, { from: accounts[0] });
                await fakeerc20.getSome(10000, { from: accounts[4] });
                await fakeerc20.approve(instance.address, 10000, {
                  from: accounts[4],
                });
                await instance.bet(true, fakePP.address, 1, 10000, {
                  from: accounts[4],
                });
                await fakePP.updateRound(090000, 6, {from: accounts[0]});
                await instance.complete(0, {from: accounts[4]});
                await instance.withdraw(1000000000, { from: accounts[0] });
                var poolBalance = await fakeerc20.balanceOf(instance.address);
                console.log(`pool balance = ${poolBalance * 1}`);
                assert.equal(
                  `0`,
                  `${poolBalance * 1}`,
                  "pool balance is not zero after withdraw"
                );
              });
            }
          );
        });
      });
    });
  });
  it("can unstake with no fee after stake time elapsed", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return FakePriceProvider.new(100000).then(async function (fakePP) {
        return BasicRateCalc.new().then(async function (rcInstance) {
          return APP.new(fakePP.address, rcInstance.address).then(
            async function (fakeAPP) {
              return TokenDenominatedBinaryOptions.new(
                "poolName",
                "PoolSymbol",
                fakeerc20.address,
                accounts[2],
                fakeAPP.address,
                accounts[3]
              ).then(async function (instance) {
                await fakeerc20.getSome(1000000000, { from: accounts[2] });
                await fakeerc20.approve(instance.address, 1000000000, {
                  from: accounts[2],
                });
                await instance.stake(1000000000, { from: accounts[2] });
                await timeTravel(60*60*24*8);//jump forward 8 days (default stake time is 7)
                await instance.withdraw(1000000000, { from: accounts[2] });
                
                var poolBalance = await fakeerc20.balanceOf(accounts[2]);
                console.log(`pool balance = ${poolBalance * 1}`);
                assert.equal(
                  `1000000000`,
                  `${poolBalance * 1}`,
                  "staker balance is not the same after withdraw"
                );
              });
            }
          );
        });
      });
    });
  });
});
