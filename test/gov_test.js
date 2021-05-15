var NativeAssetDenominatedBinaryOptions = artifacts.require("NativeAssetDenominatedBinaryOptions");
var DelegatedGov = artifacts.require("DelegatedGov");
var BIOPTokenV4 = artifacts.require("BIOPTokenV4");
var GovProxy = artifacts.require("GovProxy");
var LateStageBondingCurve = artifacts.require("LateStageBondingCurve");

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

contract("DelegatedGov", (accounts) => {
  it("exists", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      assert.equal(
        typeof instance,
        "object",
        "Contract instance does not exist"
      );
    });
  });
  it("allows staking", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        return LateStageBondingCurve.deployed().then(async function (lsbc) {
        await lsbc.buy({ from: accounts[5], value: 1000 });
        var bought = await bp.balanceOf(accounts[5]);
        var ts = await bp.totalSupply();
        await bp.approve(instance.address, ts, { from: accounts[5] });
        console.log(
          `approved 5 for ${ts} on ${instance.address}. balance is ${bought}`
        );
        await instance.stake(bought, { from: accounts[5] });
        var staked = await instance.staked(accounts[5]);
        console.log(`staked ${staked}.\nbought ${bought}`);
        assert.equal(
          bought.toString(),
          staked.toString(),
          "staked amount is incorrect"
        );
      });
    });
    });
  });
  it("allows delegate", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        var staked = await instance.staked(accounts[5]);

        var rep0 = await instance.rep(accounts[5]);
        await instance.delegate(accounts[5], { from: accounts[5] });
        var rep = await instance.rep(accounts[5]);
        console.log(`staked ${staked}.\nrep b4 ${rep0} \nrep af ${rep}`);
        assert.equal(accounts[5], rep.toString(), "delegate is not correct");
      });
    });
  });
  it("allows sha action", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
        var t0 = 2000;
        await instance.uMXOT(t0, bo.address, { from: accounts[5] });
        var t = await bo.maxT();
        assert.equal(t0.toString(), t.toString(), "time is not correct");
      });
    });
  });
  it("allows withdraw earned fees % on balance increase", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        return GovProxy.deployed().then(async function (proxy) {
          return LateStageBondingCurve.deployed().then(async function (lsbc) {
          //first a second user makes a deposit
          await lsbc.buy({ from: accounts[6], value: 1000 });
          var bought = await bp.balanceOf(accounts[6]);
          var ts = await bp.totalSupply();
          await bp.approve(instance.address, ts, { from: accounts[6] });
          await instance.stake(bought, { from: accounts[6] });

          //then we send some eth to the contract to simulate it recieving bet fees
          
          console.log(`trsansfering to proxy @${proxy.address}`);
          await web3.eth.sendTransaction({
            from: accounts[8],
            to: proxy.address,
            value: 100000,
          });

          var pBalance = await web3.eth.getBalance(proxy.address);
          console.log(`trsansfered ${pBalance }to proxy `);

          //then we transfer the eth from the proxy contract
          console.log("trsansfering to gov");
          await instance.sRTG({from: accounts[6]});
          console.log("trsansfered to gov");
           
          var balance = await web3.eth.getBalance(instance.address);

          var toReceive = await instance.pendingETHRewards(accounts[5]);
          var staked = await instance.staked(accounts[5]);
          var lrc = await instance.lrc(accounts[5]);
          var trg = await instance.trg();
          var ts = await instance.totalStaked();
          var brslc = await instance.bRSLC(accounts[5]);

          console.log(`claiming ${brslc} of ${balance} `);
          await instance.claimETHRewards({ from: accounts[5] });
          var toReceive2 = await instance.pendingETHRewards(accounts[5]);
          var lrc2 = await instance.lrc(accounts[5]);
          console.log(
            `to receive ${toReceive}. should be ${
              ((trg - lrc) * staked) / ts
            }. base ${brslc}. staked ${staked}. ts ${ts}. lrc ${lrc}. trg ${trg}. of balance ${balance}`
          );
          console.log(`to receive2 ${toReceive2}. lrc2 ${lrc2}`);
          assert.equal(
            toReceive.toString() != "0" && toReceive2.toString() == "0",
            true,
            "delegate is not correct"
          );
        });
        });
      });
    });
  });
  it("allows undelegate", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        var staked = await instance.staked(accounts[5]);

        var rep0 = await instance.rep(accounts[5]);
        await instance.undelegate({ from: accounts[5] });
        var rep = await instance.rep(accounts[5]);
        console.log(`staked ${staked}.\nrep b4 ${rep0} \nrep af ${rep}`);
        assert.equal(
          "0x0000000000000000000000000000000000000000",
          rep.toString(),
          "delegate is not correct"
        );
      });
    });
  });
  it("allows withdraw", () => {
    return DelegatedGov.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        var staked = await instance.staked(accounts[5]);

        await instance.withdraw(staked, { from: accounts[5] });
        var staked2 = await instance.staked(accounts[5]);
        console.log(`staked ${staked}.\stake2 ${staked2}`);
        assert.equal(staked2.toString(), "0", "staked amount is incorrect");
      });
    });
  });
});
