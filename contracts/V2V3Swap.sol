pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract V2V3Swap{

    using SafeMath for uint256;

    address payable public owner;

    address public token;
    address public v3;
    address public v2;
    mapping(address=>uint256) claimants;

    constructor(address token_, address v2_, address v3_) public {
        owner = msg.sender;
        v3 = v3_;
        v2 = v2_;
        token = token_;
        
        //hardcode all claimants here
        claimants[0x2a8600bbdaab254a2f8a8e00912799295c3dd601] = 20520000000000000000000;
        claimants[0xa67f3a9a43380e471296b897e5bda2ec9372984e] = 16367000000000000000000;
        claimants[0xdd0ddad1ca7b57acac3e1ed2ceac6ebc5526431a] = 14880000000000000000000;
        claimants[0x814fcc59f54c375729084f48a91eafd232e8f19e] = 11480000000000000000000;
        claimants[0x392365d5954a9b8bce72cc6b55bc206120145220] = 10448000000000000000000;
        claimants[0x5814ebfa4c49c60fe898a63c907f8e345419308a] = 9848000000000000000000;
        claimants[0xcbbc5d06be48b9b1d90a8e787b4d42bc4a3b74a8] = 8904000000000000000000;
        claimants[0x9310bcc37e24667a83aca7a495371a47f7401ad0] = 8640000000000000000000;
        claimants[0x6ed1cdfe242e653980c37aeb498b997fa0b584fd] = 8558000000000000000000;
        claimants[0xc67c6e8f19eeb70d3fffba95e5ce9de2d163ed31] = 6400000000000000000000;
        claimants[0x3dac271d1b36a434880c527a678b6487ac9c1f8c] = 6000000000000000000000;
        claimants[0x0682ebec1f898110d1e5741e2c7dafffb6a47870] = 4240000000000000000000;
        claimants[0x7329dd949aa536e23e0a8962f5829c8a3c24b805] = 3360000000000000000000;
        claimants[0x261377cfb52e6fd3048b0ab991d991ee43ef2d4a] = 3160000000000000000000;
        claimants[0x20a56da502f9398db0b3698d984427cd62a7a560] = 2640000000000000000000;
        claimants[0x9a5a4aeb2c93e6ed27b8c5d2392828182ec01bda] = 2640000000000000000000;
        claimants[0x8ed67985496fddff1721033908a5af3bcf2d9de9] = 2600000000000000000000;
        claimants[0xdec08cb92a506b88411da9ba290f3694be223c26] = 2568000000000000000000;
        claimants[0xf994b0748195d347a16e84d261b17a22d8d96135] = 2000000000000000000000;
        claimants[0x590dfbd53781c6d9d8404eb8e1847fea1afad319] = 1920000000000000000000;
        claimants[0x62d107c7555d246a6d2c19cb2a13d256168276eb] = 1920000000000000000000;
        claimants[0x880d930b4ac0b73966de27c5267e304d2093bdde] = 1920000000000000000000;
        claimants[0x656fafabbf1b8c42b4f63ab15f9bee8027a25978] = 1680000000000000000000;
        claimants[0x9a568bfeb8cb19e4bafcb57ee69498d57d9591ca] = 1680000000000000000000;
        claimants[0x6e5d43a620fc9456a1f23be69933a516e177ddec] = 1440000000000000000000;
        claimants[0x02e4f367fc7cb77d9b6818440648fc4dd5d21891] = 1280000000000000000000;
        claimants[0x6ee25007b73fa79902a152a78cab50f4f7fa9eff] = 1200000000000000000000;
        claimants[0xfeeaa6a2ae0d4a15e947afc71dc249a29dc2778d] = 1200000000000000000000;
        claimants[0xf309921083cdaeb3758bc8c24a4156edfa64ca2f] = 1000000000000000000000;
        claimants[0xa76b0152fe8bc2ec3cbfac3d3ecee4a397747051] = 960000000000000000000;
        claimants[0xbe719b05b4dbf02ed9555ef92d36d746312403ae] = 960000000000000000000;
        claimants[0x59ce5702f124ae45d63ae1c531e41b8c456a072d] = 896000000000000000000;
        claimants[0xf58075dabb3ffa6be8f577c037cef8ea60a7b0b8] = 808000000000000000000;
        claimants[0x1ad3e1493a5486f8cb675549ca4d6d124986613b] = 720000000000000000000;
        claimants[0x92b5a3f06fe24cea07a6f92aa94f2994d481afc8] = 720000000000000000000;
        claimants[0xe995e2a9ae5210feb6dd07618af28ec38b2d7ce1] = 720000000000000000000;
        claimants[0x6ee4741bc0c4928f8d878ac7fe0421e35065ad1b] = 648000000000000000000;
        claimants[0x304d0370b024dbef25d49055c38cd0ac349c01e6] = 496000000000000000000;
        claimants[0x1250f4a6aa70fe37880d2028b7664eff3f3a8a76] = 496000000000000000000;
        claimants[0x8950d9117c136b29a9b1ae8cd38db72226404243] = 490000000000000000000;
        claimants[0x0ac125137553a2938c61e6591098443db12f6fe8] = 480000000000000000000;
        claimants[0x3ae8a332a51361ab6b9159529a1a007804f6f3b5] = 480000000000000000000;
        claimants[0x61e754d261c39ee4a5fc772eb7d3d086fd70bd0c] = 480000000000000000000;
        claimants[0x75bd4cbe90cafe7e15b0694c2d03d8345006ee7e] = 480000000000000000000;
        claimants[0xc6234859138eb19e17b3d752ac7744b1169191ef] = 480000000000000000000;
        claimants[0x48b576c87e788a762d6f95a456f2a39113b46950] = 408000000000000000000;
        claimants[0xa50341f5e72ed061cd0adbd338cbf070dc45784c] = 400000000000000000000;
        claimants[0x9125b2457479964540a0557e3b010681317b635e] = 336000000000000000000;
        claimants[0x9e60ac8a2d7e0339101b8a16335480322bdee781] = 320000000000000000000;
        claimants[0xe0b795554ed78c7889635c0044a38c1f5f2f7e0a] = 320000000000000000000;
        claimants[0x2319fc093bead97d0a5c329f09895031ca1ee955] = 240000000000000000000;
        claimants[0x75cace0baba984f721f40443ce4acb6bb229a9b0] = 240000000000000000000;
        claimants[0x89b35895e55e51a549d068e695c62063744f576b] = 240000000000000000000;
        claimants[0x9528aa2822b730260731ec080d959c8e55135810] = 240000000000000000000;
        claimants[0xb3a8eab7efd3e7cdc18567abf4725b99106a259d] = 240000000000000000000;
        claimants[0xc7083893735f9aa7e9ccc4b41f8a3a0b188e9fda] = 240000000000000000000;
        claimants[0xca7f8f6a21c6e0f3b0177207407fc935429bdd27] = 240000000000000000000;
        claimants[0xd80775766186ef44c73422fdf97d92701c27f70e] = 240000000000000000000;
        claimants[0xe7bed7fd83cbd8c548cc59f103b6cec6fabe53a9] = 240000000000000000000;
        claimants[0xf27696c8bca7d54d696189085ae1283f59342fa6] = 240000000000000000000;
        claimants[0xfeb620b14a9c3683cecb9097802af9c32e51c701] = 240000000000000000000;
        claimants[0x3b7318457f091965c488dac7e58559993e4971de] = 240000000000000000000;
        claimants[0x5eefef8238b759bd8b8498ec3d1001be34fbf835] = 240000000000000000000;
        claimants[0x88551e0e83b1a8a47fb7b50507298b229cf12586] = 240000000000000000000;
        claimants[0xdbfe857a4ce4673d99cba3fb7073aab5421d1e77] = 168000000000000000000;
        claimants[0x6b67623ff56c10d9dcfc2152425f90285fc74ddd] = 160000000000000000000;
        claimants[0xea1c4d527f34f7372554b24b9fef950224e4351e] = 160000000000000000000;
        claimants[0x0fd84d7cb911728737556684050782b298f70f0f] = 40000000000000000000;
        claimants[0xf12657e7a1e2320b85b2dd10c5f047eb14f02517] = 32000000000000000000;
        claimants[0xf41d1950282ad07c28e1d469f2cb5586fcd6173b] = 24000000000000000000;
        claimants[0x36cbd78b71a161dfed7c30db2b5989d81fa31f52] = 8000000000000000000;
        claimants[0x7b0ad03877e2311cd0feb6d8dcfb4574e2915b8d] = 8000000000000000000;
        claimants[0x97cdd8176084b24ae8a385d4ea9177c31ba0022b] = 8000000000000000000;
    }
    
     modifier onlyOwner() {
      require(msg.sender == owner, "Only callable by owner");
      _;
    }

    function open(uint256 total) public onlyOwner {
        ERC20 v4 = ERC20(token);
        v4.transferFrom(msg.sender, address(this), total);
    }

    function withdraw() public onlyOwner {
        ERC20 v4 = ERC20(token);
        uint256 balance = v4.balanceOf(address(this));
        v4.transfer(msg.sender, balance);
    }

    function transferOwner(address payable newOwner_) public onlyOwner {
        owner = newOwner_;
    }

     /**
     * @dev one time swap of v2 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv2v4(uint256 amount) external {
        
        require(claimants[msg.sender] >= amount, "not enough whitelisted for u");
        claimants[msg.sender] = claimants[msg.sender].sub(amount);
        ERC20 b2 = ERC20(v2);
        ERC20 v4 = ERC20(token);
        uint256 balance = b2.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv2 balance");
        require(v4.balanceOf(address(this)) >= amount);
        require(b2.transferFrom(msg.sender, address(this), amount), "transfer failed");
        v4.transfer(msg.sender, amount);
    }

    /**
     * @dev one time swap of v3 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv3v4(uint256 amount) external {
        require(claimants[msg.sender] >= amount, "not enough whitelisted for u");
        claimants[msg.sender] = claimants[msg.sender].sub(amount);
        ERC20 b3 = ERC20(v3);
        ERC20 v4 = ERC20(token);
        uint256 balance = b3.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv3 balance");
        require(v4.balanceOf(address(this)) >= amount);
        require(b3.transferFrom(msg.sender, address(this), amount), "transfer failed");
        v4.transfer(msg.sender, amount);
    }
}
