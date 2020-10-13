//var SimpleBank = artifacts.require("./SimpleBank.sol");
var SupplyChain = artifacts.require("./SupplyChain.sol");
//var ActorProxy = artifacts.require("./ActorProxy.sol");

module.exports = function(deployer) {
  //deployer.deploy(SimpleBank);
  deployer.deploy(SupplyChain);
  //deployer.deploy(ActorProxy);
};
