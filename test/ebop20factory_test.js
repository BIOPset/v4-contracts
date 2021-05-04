var EBOP20Factory = artifacts.require("EBOP20Factory");
var FakeERC20 = artifacts.require("FakeERC20");

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



contract("EBOP20Factory", (accounts) => {
  it("exists", () => {
    return EBOP20Factory.new().then(async function (instance) {
      assert.equal(
        typeof instance,
        "object",
        "Contract instance does not exist"
      );
    });
  });

  it("can open", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return EBOP20Factory.new().then(async function (
        instance
      ) {
          await fakeerc20.getSome(1000000000, {from: accounts[0]});
          await fakeerc20.approve(instance.address, 1000000000, {from: accounts[0]});
          await instance.createEBOP20(fakeerc20.address, accounts[2], accounts[1], {from: accounts[0]});
          var addy = await instance.ebop20Addresses(fakeerc20.address);
          console.log(`created pool at ${addy.toString()}`);
          assert.notEqual(
              addy.toString(),
            "0x0000000000000000000000000000000000000000",
            "did not set address"
            );
      });
    });
  });
    it("can remove", () => {
      return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
        return EBOP20Factory.new().then(async function (
          instance
        ) {
            await fakeerc20.getSome(1000000000, {from: accounts[0]});
            await fakeerc20.approve(instance.address, 1000000000, {from: accounts[0]});
            await instance.createEBOP20(fakeerc20.address, accounts[2], accounts[1], {from: accounts[0]});
            await instance.removePool(fakeerc20.address, {from: accounts[0]});
            
            var addy = await instance.ebop20Addresses(fakeerc20.address);
            console.log(`token pool removed to ${addy.toString()}`);
            console.log(addy);
            console.log(addy.toString());
            assert.equal(
                addy.toString(),
              "0x0000000000000000000000000000000000000000",
              "did not set address"
              );
        });
      });
  });

 
});