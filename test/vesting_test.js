var FakeERC20 = artifacts.require("FakeERC20");
var Vesting = artifacts.require("Vesting");

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

contract("FakeERC20", (accounts) => {
  it("FakeERC20", () => {
    return FakeERC20.new(4000000000000000).then(async function (instance) {
      assert.equal(
        typeof instance,
        "object",
        "Contract instance does not exist"
      );
    });
  });
});

contract("Vesting", (accounts) => {
  it("Vesting exists", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return Vesting.new(accounts[0], fakeerc20.address).then(async function (
        instance
      ) {
        assert.equal(
          typeof instance,
          "object",
          "Contract instance does not exist"
        );
      });
    });
  });

  it("can open", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return Vesting.new(accounts[1], fakeerc20.address).then(async function (
        instance
      ) {
          await fakeerc20.getSome(1000000000, {from: accounts[0]});
          await fakeerc20.approve(instance.address, 1000000000, {from: accounts[0]});
          await instance.start(1000000000, 60*60*24*7*56*3/* 3yrs */, {from: accounts[0]});

          var total = await instance.total();
          console.log(total);
            assert.equal(
            total,
            "1000000000",
            "opened with correct amount"
            );
      });
    });
  });

  it("claimant can collect based on time elapsed", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return Vesting.new(accounts[1], fakeerc20.address).then(async function (
        instance
      ) {
          await fakeerc20.getSome(1000000000, {from: accounts[0]});
          await fakeerc20.approve(instance.address, 1000000000, {from: accounts[0]});
          await instance.start(1000000000, 60*60*24*7*56*3/* 3yrs */, {from: accounts[0]});
          await timeTravel((60*60*24*7*56*3)/10);//jump forward a bit
          var claimed1 = await instance.collect({from: accounts[1]});
          var claimed2 = await instance.claimed();
          console.log(`claimed ${claimed1} ${claimed2}`);
            assert.equal(
                claimed2,
            `${1000000000/10}`,
            "collected correct amount"
            );
      });
    });
  });

  it("test multiple claims", () => {
    return FakeERC20.new(4000000000000000).then(async function (fakeerc20) {
      return Vesting.new(accounts[1], fakeerc20.address).then(async function (
        instance
      ) {
          await fakeerc20.getSome(1000000000, {from: accounts[0]});
          await fakeerc20.approve(instance.address, 1000000000, {from: accounts[0]});
          await instance.start(1000000000, 60*60*24*7*56*3/* 3yrs */, {from: accounts[0]});
          await timeTravel((60*60*24*7*56*3)/10);//jump forward a bit
          var claimed1 = await instance.collect({from: accounts[1]});
          var claimed2 = await instance.claimed();
          console.log(`claimed ${claimed1} ${claimed2}`);
          await timeTravel((60*60*24*7*56*3)/10);//jump forward a bit

          var claimed3 = await instance.collect({from: accounts[1]});

          var claimed4 = await instance.claimed();
            assert.equal(
                `${claimed4*1}`,
            `${claimed2*2}`,
            "collected correct amount"
            );
      });
    });
  });
});
