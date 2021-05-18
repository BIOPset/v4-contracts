var Treasury = artifacts.require("Treasury");


const toWei = (value) => web3.utils.toWei(value.toString(), "ether");
contract("Treasury", (accounts) => {
  it("non DAO can't use treasury funds", () => {
    return Treasury.new().then(async function (instance) {
        await web3.eth.sendTransaction({
          from: accounts[8],
          to: instance.address,
          value: toWei(1),
        });
        try {
          await instance.sendFunds(toWei(1), accounts[1], {
            from: accounts[3],
          });
          assert.equal(false, true, "this should have thrown");
        } catch (e) {
          assert.equal(true, true, "test intended to throw");
        }
    });
  });

  it("DAO can send funds", () => {
    return Treasury.new().then(async function (instance) {
        await web3.eth.sendTransaction({
          from: accounts[8],
          to: instance.address,
          value: toWei(1),
        });

        var b1 = await web3.eth.getBalance(accounts[4]);

        await instance.sendFunds(toWei(1), accounts[4], {
          from: accounts[0],
        });

        var b2 = await web3.eth.getBalance(accounts[4]);
        assert.equal(
          parseInt(b2.toString()) > parseInt(b1.toString()),
          true,
          "didn't transfer ETH"
        );
    });
  });
});
