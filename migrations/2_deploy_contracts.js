const Coinbet = artifacts.require('./CoinBet.sol');

module.exports = function(deployer, network, accounts) {
	const wallet = accounts[1];

	return deployer
		.then(() => {
			return deployer.deploy(Coinbet);
		});        
};