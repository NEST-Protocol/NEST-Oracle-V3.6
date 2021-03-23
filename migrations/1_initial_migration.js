const Migrations = artifacts.require("Migrations");
const IterableMapping = artifacts.require("IterableMapping");
const IBNEST = artifacts.require("IBNEST");

module.exports = function(deployer, network) {
  //deployer.deploy(Migrations);
  console.log('network:' + network);

  if (network == 'development') {
    deployer.deploy(IterableMapping);
    deployer.link(IterableMapping, IBNEST);
  }
  // deployer.deploy(IBNEST);
};
