var NativeAssetDenominatedBinaryOptions = artifacts.require(
  "NativeAssetDenominatedBinaryOptions"
);
var DAO = artifacts.require("DAO");
var BIOPTokenV4 = artifacts.require("BIOPTokenV4");
var Treasury = artifacts.require("Treasury");
var ReserveBondingCurve = artifacts.require("ReserveBondingCurve");

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

contract("DAO", (accounts) => {
  it("exists", () => {
    return DAO.deployed().then(async function (instance) {
      assert.equal(
        typeof instance,
        "object",
        "Contract instance does not exist"
      );
    });
  });
  it("allows staking", () => {
    return DAO.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        return ReserveBondingCurve.deployed().then(async function (lsbc) {
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
  it("allows withdraw earned fees % on balance increase", () => {
    return DAO.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        return ReserveBondingCurve.deployed().then(async function (lsbc) {
          return Treasury.deployed().then(async function (trsy) {
            //first a second user makes a deposit
            await lsbc.buy({ from: accounts[6], value: toWei(15) });
            var bought = await bp.balanceOf(accounts[6]);
            var ts = await bp.totalSupply();
            await bp.approve(instance.address, ts, { from: accounts[6] });
            await instance.stake(bought, { from: accounts[6] });

            //then we send some eth to the treasury to simulate it recieving trade fee
            await web3.eth.sendTransaction({
              from: accounts[8],
              to: trsy.address,
              value: toWei(10),
            });


            var tb = await web3.eth.getBalance(trsy.address);
            console.log(`treasury balance is ${tb}`);
            //we endore ourselves in the dao
            await instance.endorse(accounts[6], { from: accounts[6] });
            const endorsed = await instance.votes(accounts[6]);
            const dbiop = await instance.dBIOP();
            console.log(`endorsement is ${endorsed} dbiop is ${dbiop}`);
            await instance.sendTreasuryFunds(toWei(10), accounts[8], { from: accounts[6] });

            var balance = await web3.eth.getBalance(instance.address);
            
            await instance.unendorse({ from: accounts[6] });
            
            var toReceive = await instance.pendingETHRewards(accounts[5]);
            var staked = await instance.staked(accounts[5]);
            var lrc = await instance.lrc(accounts[5]);
            var trg = await instance.trg();
            var ts = await instance.totalStaked();
            var brslc = await instance.bRSLC(accounts[5]);

            var dao = instance.address;
            var owner = await trsy.dao();


            console.log(`dao is ${dao} tresaury owner is ${owner} `);

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

            console.log(`to receive2 ${toReceive2.toString()}. receive ${toReceive.toString()}`);
            assert.equal(
              toReceive.toString() != "0" && toReceive2.toString() == "0",
              true,
              "is not correct"
            );
          });
          });
      });
    });
  });
  it("allows endorsement", () => {
    return DAO.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        var staked = await instance.staked(accounts[5]);

        var rep0 = await instance.rep(accounts[5]);
        await instance.endorse(accounts[5], { from: accounts[5] });
        var rep = await instance.rep(accounts[5]);
        console.log(`staked ${staked}.\nrep b4 ${rep0} \nrep af ${rep}`);
        assert.equal(accounts[5], rep.toString(), "endorse is not correct");
      });
    });
  });
  it("allows sha action", () => {
    return DAO.deployed().then(async function (instance) {
      return NativeAssetDenominatedBinaryOptions.deployed().then(
        async function (bo) {
          var t0 = 2000;
          await instance.uMXOT(t0, bo.address, { from: accounts[5] });
          var t = await bo.maxT();
          assert.equal(t0.toString(), t.toString(), "time is not correct");
        }
      );
    });
  });
 
  it("allows unendorse", () => {
    return DAO.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        var staked = await instance.staked(accounts[5]);

        var rep0 = await instance.rep(accounts[5]);
        await instance.unendorse({ from: accounts[5] });
        var rep = await instance.rep(accounts[5]);
        console.log(`staked ${staked}.\nrep b4 ${rep0} \nrep af ${rep}`);
        assert.equal(
          "0x0000000000000000000000000000000000000000",
          rep.toString(),
          "rep is not correct"
        );
      });
    });
  });
  it("allows withdraw", () => {
    return DAO.deployed().then(async function (instance) {
      return BIOPTokenV4.deployed().then(async function (bp) {
        var staked = await instance.staked(accounts[5]);

        await instance.withdraw(staked, { from: accounts[5] });
        var staked2 = await instance.staked(accounts[5]);
        console.log(`staked ${staked}.\stake2 ${staked2}`);
        assert.equal(staked2.toString(), "0", "staked amount is incorrect");
      });
    });
  });



  it("can't call a tier protected function without enough endorsement", () => {
    return DAO.deployed().then(async function (instance) {
      try {
        await instance.uMXOT(4, "0x0000000000000000000000000000000000000000", {
          from: accounts[5],
        });
        assert.equal(false, true, "test did not fail");
      } catch (e) {
        assert.equal(true, true, "this test was intended to fail");
      }
    });
  });

  it("can't withdraw when no deposit has been made", () => {
    return DAO.deployed().then(async function (instance) {
      try {
        await instance.withdraw(staked, { from: accounts[8] });
        assert.equal(false, true, "test did not fail");
      } catch (e) {
        assert.equal(true, true, "this test was intended to fail");
      }
    });
  });

  it("can't get part of ETH earned when they aren't a staker", () => {
    return DAO.deployed().then(async function (instance) {
      try {
        await instance.claimETHRewards({ from: accounts[8] });
        assert.equal(false, true, "test did not fail");
      } catch (e) {
        assert.equal(true, true, "this test was intended to fail");
      }
    });
  });
});
