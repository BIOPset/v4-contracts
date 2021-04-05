

var BIOPTokenV4 = artifacts.require('BIOPTokenV4');
var LateStageBondingCurve = artifacts.require('LateStageBondingCurve');

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

contract("Bonding curve", (accounts) => {
  it("exists", () => {
    return LateStageBondingCurve.deployed().then(async function (instance) {
      assert.equal(
        typeof instance,
        "object",
        "Contract instance does not exist"
      );
    });
  });

  it("buy from curve", () => {
    return BIOPTokenV4.deployed().then(async function (token) {
    return LateStageBondingCurve.deployed().then(async function (bp) {
      
      var balance1 = await token.balanceOf(accounts[4]);
      
      await bp.buy({ from: accounts[4], value: 100 });
      
      var sold2 = await bp.soldAmount();
      
      console.log("sold");
      console.log(web3.utils.fromWei(sold2, "ether"));
      var balance2 = await token.balanceOf(accounts[4]);
      await bp.buy({ from: accounts[4], value: toWei(1) });
      
      var balance3 = await token.balanceOf(accounts[4]);
      var sold3= await bp.soldAmount();
      var uBalance = await web3.eth.getBalance(accounts[4]);
      var cBalance = await web3.eth.getBalance(bp.address);
      console.log(`contract balance b4 sale: ${web3.utils.fromWei(cBalance, "ether")}
                  \n user balance ${web3.utils.fromWei(uBalance, "ether")}`);
      
      await bp.buy({ from: accounts[4], value: toWei(10) });
      var cBalance2 = await web3.eth.getBalance(bp.address);
      var uBalance2 = await web3.eth.getBalance(accounts[4]);
      
      console.log(`contract balance af sale: ${web3.utils.fromWei(cBalance2, "ether")}
      \n user balance ${web3.utils.fromWei(uBalance2, "ether")}`);
      
      console.log(`
      \n balance1 ${web3.utils.fromWei(balance1, "ether")}
      \n balance2 = ${web3.utils.fromWei(balance2, "ether")}
      \n balance3 = ${web3.utils.fromWei(balance3, "ether")}
      \n sold3 ${web3.utils.fromWei(sold3, "ether")}

      `);
        assert.equal(
          balance2 < balance3,
          true,
          "user balance after deposit is zero"
        );
    });});
  });
 /*  describe("Curve integral calulations", async () => {
    // priceToMint is the same as the internal function curveIntegral if
    // totalSupply and poolBalance is zero
    const testWithExponent2 = async () => {
      const tmpPolyToken = await BIOPTokenV3.new(
        "BIOP",
        "BIOP",
        "0xC961AfDcA1c4A2A17eada10D2e89D052bEf74A85"
      );
      let res;
      let last = 0;
      for (let i = 1; i < 500000; i += 10000) {
        
        var sold= await tmpPolyToken.soldAmount();
        res = (await tmpPolyToken.s(sold, sold+toWei(i)));
        if (i / 10000 > 0) {
          console.log(`next price ${res} > ${last} ${typeof(res)}`);
        }
        assert.equal(
          res>last,
          true,
          "should calculate curveIntegral correcly " + i
        );
        last = res;
      }
    };
    it("works with exponent = 2", async () => {
      await testWithExponent2();
    });
  }); */

 
  it("sell to curve", () => {
    return BIOPTokenV4.deployed().then(async function (token) {
      return LateStageBondingCurve.deployed().then(async function (bp) {
      var sold1 = await bp.soldAmount();
      console.log(`sold1 ${web3.utils.fromWei(sold1)}`);
      var cBalance = await web3.eth.getBalance(bp.address);
      console.log(`contract balance b4 sale: ${web3.utils.fromWei(cBalance, "ether")}
      `);
      var bv31 = await token.balanceOf(accounts[4]);
      await token.approve(bp.address,bv31,{ from: accounts[4] });
      var recieved1 = await bp.sell(Math.floor(sold1/100), { from: accounts[4] });
      var cBalance2 = await web3.eth.getBalance(bp.address);
      console.log(`contract balance af sale: ${web3.utils.fromWei(cBalance2, "ether")}
      `);
      var cb2 = await web3.eth.getBalance(bp.address);
      var b1 = await web3.eth.getBalance(accounts[4]);
      var bv32 = await token.balanceOf(accounts[4]);
      console.log(`rpci
      \n cb2 ${web3.utils.fromWei(cb2)}
      \n b2 ${web3.utils.fromWei(b1)}
      
      \n bv31 ${web3.utils.fromWei(bv31)}
      \n bv32 ${web3.utils.fromWei(bv32)}
      `);
      var recieved2 = await bp.sell(Math.floor(sold1/100), { from: accounts[4] });
      var cBalance3 = await web3.eth.getBalance(bp.address);
      console.log(`contract balance af2 sale: ${web3.utils.fromWei(cBalance3, "ether")}
      `);
      console.log(`sell prices
      \n ${recieved1}
      \n ${recieved2}
      `);
      console.log(bv31);
      console.log(bv32);

      assert.equal(
        cBalance-cBalance2>cBalance2-cBalance3,
        true,
        "didn't get less on second sale"
      )

    })
  })})
       
});
