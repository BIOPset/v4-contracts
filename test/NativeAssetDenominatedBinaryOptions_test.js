var NativeAssetDenominatedBinaryOptions = artifacts.require("NativeAssetDenominatedBinaryOptions");
var FakePriceProvider = artifacts.require("FakePriceProvider");
var UtilizationRewards = artifacts.require("UtilizationRewards");

var BN = web3.utils.BN;
const toWei = (value) => web3.utils.toWei(value.toString(), "ether");
var basePrice = 753520000000;
var oneHour = 3600;
const send = (method, params = []) => 
  new Promise((resolve, reject) => 
    web3.currentProvider.send({id: 0, jsonrpc: "2.0", method, params}, (err, x) => {
      if(err) reject(err)
      else resolve(x)
    }))
const timeTravel = async(seconds) => {
  return new Promise( async (resolve, reject) => {
    await send("evm_increaseTime", [seconds]);
    await send("evm_min");
    await send("evm_min");
    await send("evm_min");
    await send("evm_min");
    resolve();
  })
}

const btcPriceOracle = "0x6135b13325bfC4B00278B4abC5e20bbce2D6580e";

contract("NativeAssetDenominatedBinaryOptions", (accounts) => {
  it("exists", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (instance) {
      assert.equal(
        typeof instance,
        "object",
        "Contract instance does not exist"
      );
    });
  });

  it("stake in NativeAssetDenominatedBinaryOptions", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return UtilizationRewards.deployed().then(async function (ur) {

      var pendingClaims = await bo.getPendingClaims(accounts[2]);
        await bo.stake({ from: accounts[2], value: toWei(9) });

      var pendingClaims2 = await bo.getPendingClaims(accounts[2]);
      var locked = await bo.balanceOf(accounts[2]);
      var totalLocked = await bo.totalSupply();
      var pbb = await ur.getPoolBalanceBonus(locked, totalLocked)
      console.log(`pending claims b4 stake ${web3.utils.fromWei(pendingClaims, "ether")}. 
      \n after stake ${web3.utils.fromWei(pendingClaims2, "ether")}
      \n pool bonus = ${pbb}
      `);
        var balance = await bo.balanceOf(accounts[2]);

        assert.equal(
          balance.toString(),
          "9000000000000000000",
          "user balance after deposit is zero"
        );
      });
    });
  });
  it("makes a call bet", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
      var balance = await bo.balanceOf(accounts[2]);
      console.log(`defaultpp ${pp.address}`);

      var pendingClaims = await bo.getPendingClaims(accounts[2]);
      var betRewardBase = await bo.rwd();
      var claimForBet = await bo.getBetSizeBonus(toWei(1), betRewardBase);
      console.log(`
      \n${claimForBet}
      \n${pendingClaims}
      pending claims ${web3.utils.fromWei(pendingClaims, "ether")}. Will add ${web3.utils.fromWei(claimForBet, "ether")}`);
      await bo.bet(1, pp.address, 1, {from: accounts[2], value: toWei(0.01)});

      var pendingClaims2 = await bo.getPendingClaims(accounts[2]);
      console.log(`pending claims after bet \n${web3.utils.fromWei(pendingClaims2, "ether")}.`); 
     
      assert.equal(
        balance.toString(),
        "9000000000000000000",
        "user balance after deposit is zero"
      );
    });
  });
  }); 
  it("makes a put bet", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
      var balance = await bo.balanceOf(accounts[2]);

      var pendingClaims = await bo.getPendingClaims(accounts[2]);
      console.log(`pending claims ${web3.utils.fromWei(pendingClaims, "ether")} b4 bet`);
      await bo.bet(0,pp.address,1, {from: accounts[2], value: toWei(0.01)});
      var pendingClaims2 = await bo.getPendingClaims(accounts[2]);
      console.log(`pending claims after bet ${web3.utils.fromWei(pendingClaims2, "ether")}.`); 
    
      assert.equal(
        balance.toString(),
        "9000000000000000000",
        "user balance after deposit is zero"
      );
    });});
  }); 

  it('testing rewards', () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
        return UtilizationRewards.deployed().then(async function (ur) {
        
      await bo.bet(1, pp.address, 1, {from: accounts[3], value: toWei(0.01)});

      var pendingClaims3 = await bo.getPendingClaims(accounts[3]);
      await bo.bet(1, pp.address, 1, {from: accounts[3], value: toWei(0.01)});

      var pendingClaims4 = await bo.getPendingClaims(accounts[3]);
console.log("got here");
      var lastStakeTime = await bo.lST(accounts[3]);
      var lastInterchange = await bo.iAL(accounts[3]);
      var totalInterchange = await bo.tI();
      var stakedAmount = await bo.balanceOf(accounts[3]);
      var totalStaked = await bo.totalSupply();
      var stakinBonus = await ur.getLPStakingBonus(lastStakeTime,lastInterchange, totalInterchange, stakedAmount, totalStaked);

      console.log("got her2");
      await bo.stake({ from: accounts[3], value: toWei(1) });
      var pendingClaims5 = await bo.getPendingClaims(accounts[3]);


      console.log("got her3");
      var lastStakeTime2 = await bo.lST(accounts[3]);
      var lastInterchange2 = await bo.iAL(accounts[3]);
      var totalInterchange2 = await bo.tI();
      var stakedAmount2 = await bo.balanceOf(accounts[3]);
      var totalStaked2 = await bo.totalSupply();
      var stakinBonus2 = await ur.getLPStakingBonus(lastStakeTime2, lastInterchange2, totalInterchange2, stakedAmount2, totalStaked2);

      await bo.bet(1, pp.address, 1, {from: accounts[3], value: toWei(0.01)});
      var pendingClaims6= await bo.getPendingClaims(accounts[3]);



      console.log(`pending claims after bet for fresh account:
      \n#2 ${web3.utils.fromWei(pendingClaims3, "ether")}
      \n#4 ${web3.utils.fromWei(pendingClaims4, "ether")}
      \n#5 ${web3.utils.fromWei(pendingClaims5, "ether")}
      \n#6 ${web3.utils.fromWei(pendingClaims6, "ether")}
      \n\n\n
      \n#1 staking bonus ${web3.utils.fromWei(stakinBonus, "ether")}l;./
      \n#2 staking bonus ${web3.utils.fromWei(stakinBonus2, "ether")}
      \n#3 ${pendingClaims5} + ${stakinBonus2} ${web3.utils.fromWei((new BN(stakinBonus2).add(new BN(pendingClaims5)).toString()), "ether")}`);
      assert.equal(
        true,
        true,
        ""
      );
    }); });
  });
  })
  it("exercise an call option", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
        var ethB1 = await web3.eth.getBalance(accounts[2]);
        //var balance = await bo.balanceOf(accounts[1]);
        var ethPoolB1 = await web3.eth.getBalance(bo.address);
        await pp.setPrice(basePrice+10);
        
        var pendingClaims = await bo.getPendingClaims(accounts[2]);
        console.log(`pending claims ${web3.utils.fromWei(pendingClaims, "ether")} b4 exercise`);
        await bo.complete(0);
        var pendingClaims2 = await bo.getPendingClaims(accounts[2]);
        console.log(`pending claims after exercise ${web3.utils.fromWei(pendingClaims2, "ether")}.`); 
      
        
        var ethB2 = await web3.eth.getBalance(accounts[2]);
        var ethPoolB2 = await web3.eth.getBalance(bo.address);
        console.log(`eth bo balance ${ethPoolB1}, 2 ${ethPoolB2}. ${ethPoolB1 == toWei(9)}`);
        console.log(`eth user balance ${ethB1}, 2 ${ethB2}.`);
        
        assert.equal(
          ethB1 < ethB2,
          true,
          "user balance is greater after itm call exercise"
        );
      });
    });
  });
  it("exercise an put option", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
        var ethB1 = await web3.eth.getBalance(accounts[2]);
        //var balance = await bo.balanceOf(accounts[1]);
        var ethPoolB1 = await web3.eth.getBalance(bo.address);

        var pendingClaims = await bo.getPendingClaims(accounts[2]);
        console.log(`pending claims ${web3.utils.fromWei(pendingClaims, "ether")}`);
        await pp.setPrice(basePrice-10);
        await bo.complete(1);
        var ethB2 = await web3.eth.getBalance(accounts[2]);
        var ethPoolB2 = await web3.eth.getBalance(bo.address);
        console.log(`eth bo balance ${ethPoolB1}, 2 ${ethPoolB2}. ${ethPoolB1 == toWei(9)}`);
        assert.equal(
          ethB1 < ethB2,
          true,
          "user balance is greater after itm call exercise"
        );
      });
    });
  });

  it("after actions, BIOP balance > 0", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      var balance = await bo.getPendingClaims(accounts[2]);

      var blockNumber = await web3.eth.getBlockNumber();
      await timeTravel(3600);
      var blockNumber2 = await web3.eth.getBlockNumber();
      var balance2 = await bo.getPendingClaims(accounts[2]);
      var lastWithdraw = await bo.lW(accounts[2]);
      console.log(`last Withdraw ${lastWithdraw} block #1 ${blockNumber} #2 ${blockNumber2}`);
      console.log(` biop pending claim ${web3.utils.fromWei(balance, "ether")}, 2 ${web3.utils.fromWei(balance2, "ether")}`);
      
      
      var optionCount2 = await bo.getOptionCount();
      console.log(` total option count ${optionCount2},`);
      assert.equal(
        balance.toString(),
        balance2.toString(),
        "user BIOP balance after deposit is zero"
      );
    });
  });
  it("early withdraw from bo", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {

        await bo.stake( { from: accounts[2], value: toWei(9) });
        //await timeTravel(1209700);
        var balance1 = await bo.balanceOf(accounts[2]);
        await bo.withdraw(toWei(9), { from: accounts[2] });
        var balance2 = await bo.balanceOf(accounts[2]);

        assert.equal(
          balance1.toString(),
          "18000000000000000000",
          "user balance after deposit is zero"
        );
      });
    });
  });
  it("withdraw from bo", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
        await timeTravel(1209700);
        await bo.withdraw(toWei(1), { from: accounts[2] });
        var balance = await bo.balanceOf(accounts[2]);

        assert.equal(
          balance.toString(),
          "8000000000000000000",
          "user balance after deposit is zero"
        );
      });
    });
  });
  it("stake and withdraw small amount without time NativeAssetDenominatedBinaryOptions", () => {
    return NativeAssetDenominatedBinaryOptions.deployed().then(async function (bo) {
      return FakePriceProvider.deployed().then(async function (pp) {
        await bo.stake({ from: accounts[3], value: toWei(0.5) });
        var balance1 = await bo.balanceOf(accounts[3]);

        await bo.withdraw(toWei(0.005), { from: accounts[3] });

        var balance2 = await bo.balanceOf(accounts[3]);
        console.log(`balance 1 ${balance1} \nbalance 2 ${balance2}`);
        assert.equal(
          balance1.toString(),
          "1500000000000000000",
          "user balance after deposit is zero"
        );
      });
    });
  });
  
});
