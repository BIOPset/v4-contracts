var FakeERC20 = artifacts.require("FakeERC20");
var UtilizationRewards = artifacts.require("UtilizationRewards");

contract("UtilizationRewards", (accounts) => {
  it("deploys", () => {
    return FakeERC20.new(4000000000000000).then(async function (token) {
      return UtilizationRewards.new(token.address).then(async function (
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

  it("deposit", () => {
    return FakeERC20.new(4000000000000000).then(async function (token) {
      return UtilizationRewards.new(token.address, { from: accounts[0] }).then(
        async function (instance) {
          await token.getSome(1000000, { from: accounts[0] });
          await token.approve(instance.address, 1000000, { from: accounts[0] });
          await instance.deposit(500000, 500000, { from: accounts[0] });
          var balance = await token.balanceOf(instance.address);
          assert.equal(balance.toString(), "1000000", "balance if incorrect");
        }
      );
    });
  });

  it("withdraw", () => {
    return FakeERC20.new(4000000000000000).then(async function (token) {
      return UtilizationRewards.new(token.address, { from: accounts[0] }).then(
        async function (instance) {
          await token.getSome(1000000, { from: accounts[0] });
          await token.approve(instance.address, 1000000, { from: accounts[0] });
          await instance.deposit(5000, 5000, { from: accounts[0] });
          await instance.withdraw({ from: accounts[0] });
          var balance = await token.balanceOf(instance.address);
          assert.equal(balance.toString(), "0", "balance if incorrect");
        }
      );
    });
  });
  it("claim some", () => {
    return FakeERC20.new(4000000000000000).then(async function (token) {
      return UtilizationRewards.new(token.address, { from: accounts[0] }).then(
        async function (instance) {
          await token.getSome(1000000, { from: accounts[0] });
          await token.approve(instance.address, 1000000, { from: accounts[0] });
          await instance.deposit(5000, 5000, { from: accounts[0] });
          await instance.updateDailyMax(5000, {from: accounts[0]});
          await instance.setupBinaryOptions(accounts[1], {from: accounts[0]});
          await instance.distributeClaim(0, 5000, accounts[1],  {from: accounts[1]})
          var balance = await token.balanceOf(accounts[1]);
          assert.equal(balance.toString(), "5000", "balance if incorrect");
        }
      );
    });
  });
  it("can't claim above daily max", () => {
    return FakeERC20.new(4000000000000000).then(async function (token) {
      return UtilizationRewards.new(token.address, { from: accounts[0] }).then(
        async function (instance) {
            
          await token.getSome(1000000, { from: accounts[0] });
          await token.approve(instance.address, 1000000, { from: accounts[0] });
          await instance.deposit(5000, 5000, { from: accounts[0] });
          await instance.updateDailyMax(5000, {from: accounts[0]});
          await instance.setupBinaryOptions(accounts[1], {from: accounts[0]});
          await instance.distributeClaim(0, 6000, accounts[1],  {from: accounts[1]})
          var balance = await token.balanceOf(accounts[1]);
          assert.equal(balance.toString(), "5000", "balance if incorrect");
        }
      );
    });
  });

  it("can't claim wrong funds", () => {
    return FakeERC20.new(4000000000000000).then(async function (token) {
      return UtilizationRewards.new(token.address, { from: accounts[0] }).then(
        async function (instance) {
            
          await token.getSome(1000000, { from: accounts[0] });
          await token.approve(instance.address, 1000000, { from: accounts[0] });
          await instance.deposit(5000, 0, { from: accounts[0] });
          await instance.updateDailyMax(5000, {from: accounts[0]});
          await instance.setupBinaryOptions(accounts[1], {from: accounts[0]});
          await instance.distributeClaim(0, 5000, accounts[0],  {from: accounts[1]})
          var balance = await token.balanceOf(accounts[1]);
          assert.equal(balance.toString(), "0", "balance if incorrect");
        }
      );
    });
  });
});
