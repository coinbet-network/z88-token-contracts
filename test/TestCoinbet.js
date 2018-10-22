const Web3 = require('web3');

const CoinBet = artifacts.require("./CoinBet.sol");
const TeamWallet = artifacts.require("./TeamWallet.sol");
const AdvisorWallet = artifacts.require("./AdvisorWallet.sol");

const IN_PRIVATE_SALE = 0;
const IN_PRESALE = 1;
const END_PRESALE = 2;
const IN_PUBLIC_SALE = 3;
const END_PUBLIC_SALE = 4;

contract('CoinBet test', async (accounts) => {  

	const web3 = new Web3();
	const decimals = 18;
	const presalePrice = 1000000;
	const privateSaleReceiver = accounts[4];
	const tokenTransferPrivateSale = 300000 * (10 ** decimals);

	const etherPurchasePresale = 0.5;
	const preSaleReceiver = accounts[5];
	const purchaseAllPreSaleReceiver = accounts[6];

	const bracketPrice1 = 1500000;
	const bracketPrice2 = 2500000;	
	const purchaseEndBracket1Receiver = accounts[7];
	const purchaseEndBracket2Receiver = accounts[8];

	const tranferTokenReceiver = accounts[9];
	const tokenTransfer = 1000000 * (10 ** decimals);

	const startPresaleAfter = 0;
	
	it("Team wallet creator should match", async () => {
		const coinbet = await CoinBet.deployed();		
		const wallet = await TeamWallet.deployed();
		const creator = await wallet.creator();
		assert.equal(creator, coinbet.address);
	});
	
	it("Advisor wallet creator should match", async () => {
		const coinbet = await CoinBet.deployed();		
		const wallet = await AdvisorWallet.deployed();
		const creator = await wallet.creator();
		assert.equal(creator, coinbet.address);
  });

	it("Allocate token for advisor", async () => {
		const coinbet = await CoinBet.deployed();
		const wallet = await AdvisorWallet.deployed();
		await coinbet.allocateTokenForAdvisor(wallet.address);

		const advisorAllocation = await coinbet.advisorAllocation();
		const walletToken = await wallet.totalToken();		
		assert.equal(advisorAllocation.toString(), walletToken.toString());
  });
	
	it("Allocate token for team", async () => {
		const coinbet = await CoinBet.deployed();
		const teamWallet = await TeamWallet.deployed();		
		await coinbet.allocateTokenForTeam(teamWallet.address);

		const teamAllocation = await coinbet.founderAndTeamAllocation();
		const walletToken = await teamWallet.totalToken();
		assert.equal(teamAllocation.toString(), walletToken.toString());
	});
	
	it("Check sale state is private sale", async () => {
		const coinbet = await CoinBet.deployed();		
		const saleState = await coinbet.saleState();
		const data = await coinbet.getSaleState();		
		assert.equal(saleState, IN_PRIVATE_SALE);
	});

	it("Transfer token in private sale", async () => {
		const coinbet = await CoinBet.deployed();		
		await coinbet.transferPrivateSale(privateSaleReceiver, tokenTransferPrivateSale);
		const balance = await coinbet.balanceOf(privateSaleReceiver);
		assert.equal(balance, tokenTransferPrivateSale);
	});
	
	it("Set sale state to presale", async () => {
		const coinbet = await CoinBet.deployed();
		await coinbet.startPresale(presalePrice, startPresaleAfter);
		const saleState = await coinbet.saleState();
		assert.equal(saleState, IN_PRESALE);
	});
	
	it("Get presale price", async () => {
		const coinbet = await CoinBet.deployed();
		const bracket = await coinbet.presaleBracket();		
		const price = bracket[2].toNumber();
		assert.equal(price, presalePrice);
	});
	
	it("Purchase token in presale", async () => {
		const coinbet = await CoinBet.deployed();
		await coinbet.sendTransaction({ value: web3.toWei(etherPurchasePresale, "ether"), from: preSaleReceiver});
		const balance = await coinbet.balanceOf(preSaleReceiver);		
		assert.equal(balance.toNumber(), presalePrice * etherPurchasePresale * (10 ** decimals));
	});
	
	it("Purchase token to end presale", async () => {
		const coinbet = await CoinBet.deployed();
		const presaleAllocation = await coinbet.preSaleAllocation();		
		const etherToEndPresale = (presaleAllocation / (10 ** decimals) / presalePrice);
		await coinbet.sendTransaction({ value: web3.toWei(etherToEndPresale, "ether"), from: purchaseAllPreSaleReceiver});
		const balance = await coinbet.balanceOf(purchaseAllPreSaleReceiver);
		assert.equal(balance.toNumber(), presalePrice * (etherToEndPresale - etherPurchasePresale) * (10 ** decimals));
	});
	
	it("Check state is end presale", async () => {
		const coinbet = await CoinBet.deployed();
		const saleState = await coinbet.saleState();
		assert.equal(saleState, END_PRESALE);		
	});	
	
	it("Set bracket 1 price", async () => {
		const coinbet = await CoinBet.deployed();
		const index = 0;
		await coinbet.setBracketPrice(index, bracketPrice1);
		const bracket = await coinbet.brackets(index);
		const tokenPerEther = bracket[2].toNumber();
		assert.equal(tokenPerEther, bracketPrice1);
	});

	it("Set bracket 2 price", async () => {
		const coinbet = await CoinBet.deployed();
		const index = 1;
		await coinbet.setBracketPrice(index, bracketPrice2);
		const bracket = await coinbet.brackets(index);
		const tokenPerEther = bracket[2].toNumber();
		assert.equal(tokenPerEther, bracketPrice2);
	});

	it("Set sale state to public sale", async () => {
		const coinbet = await CoinBet.deployed();
		await coinbet.changeToPublicSale();
		const saleState = await coinbet.saleState();
		assert.equal(saleState, IN_PUBLIC_SALE);
	});

	it("Purchase token to end bracket 1", async () => {
		const coinbet = await CoinBet.deployed();
		const bracket = await coinbet.brackets(0);
		const tokenRemain = bracket[1].toNumber();		
		const buffEther = 0.7;
		const etherToEndBracket = (tokenRemain / (10 ** decimals) / bracketPrice1) + buffEther;
		await coinbet.sendTransaction({ value: web3.toWei(etherToEndBracket, "ether"), from: purchaseEndBracket1Receiver});
		const balance = await coinbet.balanceOf(purchaseEndBracket1Receiver);
		assert.equal(balance.toNumber(), bracketPrice1 * (etherToEndBracket - buffEther) * (10 ** decimals));
	});

	it("Check bracket index move from 0 to 1", async () => {
		const coinbet = await CoinBet.deployed();
		const bracket = await coinbet.getCurrentBracket();
		assert.equal(bracket[0].toNumber(), 1);
	});

	it("Purchase token to end bracket 2", async () => {
		const coinbet = await CoinBet.deployed();
		const bracket = await coinbet.brackets(1);
		const tokenRemain = bracket[1].toNumber();		
		const buffEther = 0.7;
		const etherToEndBracket = (tokenRemain / (10 ** decimals) / bracketPrice2) + buffEther;
		await coinbet.sendTransaction({ value: web3.toWei(etherToEndBracket, "ether"), from: purchaseEndBracket2Receiver});
		const balance = await coinbet.balanceOf(purchaseEndBracket2Receiver);
		assert.equal(balance.toNumber(), bracketPrice2 * (etherToEndBracket - buffEther) * (10 ** decimals));
	});

	it("Check state is end public sale", async () => {
		const coinbet = await CoinBet.deployed();
		const saleState = await coinbet.saleState();
		assert.equal(saleState, END_PUBLIC_SALE);		
	});

	it("Transfer token after ICO", async () => {
		const coinbet = await CoinBet.deployed();
		await coinbet.transfer(tranferTokenReceiver, tokenTransfer);
		const balance = await coinbet.balanceOf(tranferTokenReceiver);
		assert.equal(balance.toNumber(), tokenTransfer);		
	});

	

})