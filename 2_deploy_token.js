var GsgcToken = artifacts.require('./GsgcToken.sol');

module.exports = function (deployer, network) {
  if(network == 'mainnet'){
    var name = 'GSG coin';
    var symbol = 'GSGC';
    var totalSupply = 2 * Math.pow(10,9);
    deployer.deploy(GsgcToken, totalSupply, name, symbol);
  }
};
