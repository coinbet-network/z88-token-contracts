const Coinbet = artifacts.require('CoinBet');
const TeamWallet = artifacts.require('TeamWallet');
const AdvisorWallet = artifacts.require('AdvisorWallet');

module.exports = async function(deployer, network, accounts) {	
	const walletAddress = "0xd811A297C0E8E6fa3C69442903d0b073d9d5ff96";
	const airdropAddress = "0x8Acd871946a7e051ae286e90a7e80b9BDd7a4916";
	const privateSaleAddress = "0x13C82E64f460C1e000dF81080064665820756dB6";
	await deployer.deploy(Coinbet, walletAddress, airdropAddress, privateSaleAddress);

	console.log(Coinbet.address);

	const admin1 = "0x8Acd871946a7e051ae286e90a7e80b9BDd7a4916";
	const admin2 = "0x13C82E64f460C1e000dF81080064665820756dB6";
	await deployer.deploy(TeamWallet, Coinbet.address, admin1, admin2);

	const advisorWallet = await deployer.deploy(AdvisorWallet, Coinbet.address);
	return advisorWallet;
};