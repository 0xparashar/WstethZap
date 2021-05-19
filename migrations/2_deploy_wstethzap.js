const WstethZap = artifacts.require("WstEthZap");

module.exports = async function (deployer) {
  await deployer.deploy(WstethZap);
};