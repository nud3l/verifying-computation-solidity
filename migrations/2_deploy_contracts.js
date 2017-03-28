module.exports = function(deployer) {
  deployer.deploy(usingOraclize);
  deployer.autolink();
  deployer.deploy(ComputationService);
};
