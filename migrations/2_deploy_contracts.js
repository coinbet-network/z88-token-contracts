const Coinbet = artifacts.require('CoinBet');
const TeamWallet = artifacts.require('TeamWallet');
const AdvisorWallet = artifacts.require('AdvisorWallet');

module.exports = function(deployer, network, accounts) {	
	const walletAddress = accounts[1];
	const admin = accounts[2];
	const airdropAddress = accounts[3];	
	const startPrivateSaleAfter = 3;

	deployer.deploy(Coinbet, admin, walletAddress, airdropAddress, startPrivateSaleAfter)
		.then(() => {			
			const admin1 = accounts[4];
			const admin2 = accounts[5];
			return deployer.deploy(TeamWallet, Coinbet.address, admin1, admin2)
				.then(() => {					
					return deployer.deploy(AdvisorWallet, Coinbet.address);
				})
		});
};