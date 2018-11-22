/* solium-disable */
pragma solidity ^0.4.24;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './AdvisorWallet.sol';
import './TeamWallet.sol';

library ICOData {
  struct Bracket {
    uint256 total;
    uint256 remainToken;
    uint256 tokenPerEther;
    uint256 minAcceptedAmount;
  }
  
  enum SaleStates {
    InPrivateSale,
    InPresale,
    EndPresale,
    InPublicSale,
    EndPublicSale
  }
}

// ================= Coinbet Token =======================
contract Coinbet is ERC20, Ownable {
  
  string public constant name = "Coinbet";
  string public constant symbol = "Z88";
  uint256 public constant decimals = 18;
  // 200M token will be supplied
  uint256 public constant INITIAL_SUPPLY = 200000000 * (10 ** decimals);

  // 20M tokens allocated for founders and team
  uint256 public constant FOUNDER_AND_TEAM_ALLOCATION = 20000000 * (10 ** decimals);
  // 10M tokens allocated for advisors
  uint256 public constant ADVISOR_ALLOCATION = 10000000 * (10 ** decimals);
  // 5M tokens allocated for bounty & referral
  uint256 public constant AIRDROP_ALLOCATION = 5000000 * (10 ** decimals);
  // 30M tokens allocated for treasury
  uint256 public constant TREASURY_ALLOCATION = 30000000 * (10 ** decimals);
  // 10M tokens allocated for partner
  uint256 public constant PARTNER_ALLOCATION = 10000000 * (10 ** decimals);

  // 40M tokens allocated for pre sale
  uint256 public constant PRIVATE_SALE_ALLOCATION = 40000000 * (10 ** decimals);
  // 20M tokens allocated for private sale
  uint256 public constant PRESALE_ALLOCATION = 20000000 * (10 ** decimals);
  // 20M tokens allocated for public sale in 1st bracket
  uint256 public constant PUBLIC_1_ALLOCATION = 20000000 * (10 ** decimals);
  // 40M tokens allocated for public sale in 2nd bracket
  uint256 public constant PUBLIC_2_ALLOCATION = 40000000 * (10 ** decimals);
  // 1.5M tokens allocated for Lotto645 jackpot
  uint256 public constant LOTTO645_JACKPOT_ALLOCATION = 1500000 * (10 ** decimals);
  // 3M tokens allocated for Lotto655 jackpot 1
  uint256 public constant LOTTO655_JACKPOT_1_ALLOCATION = 3000000 * (10 ** decimals);
  // 0.5M tokens allocated for Lotto655 jackpot 2
  uint256 public constant LOTTO655_JACKPOT_2_ALLOCATION = 500000 * (10 ** decimals);

  // Admin role
  address public admin;
  // Address where funds are collected
  address public fundWallet;
  // Wallet is used for Bounty & Referral program
  address public airdropWallet;
  // Wallet for tokens keeping purpose, no sale
  address public treasuryWallet;
  // Wallet is used for Coinbet Partner Program
  address public partnerWallet;
  // Contract is used for rewarding development team
  TeamWallet public teamWallet;
  // Contract is used for rewarding advisor team
  AdvisorWallet public advisorWallet;
  // Wallet is used for paying Z88 Lotto 645's starting Jackpot
  address public lotto645JackpotWallet;
  // Wallet is used for paying Z88 Lotto 655's starting Jackpot 1
  address public lotto655Jackpot1Wallet;
  // Wallet is used for paying Z88 Lotto 655's starting Jackpot 2
  address public lotto655Jackpot2Wallet;
  
  // Remain number of Z88 tokens for private sale
  uint256 public privateSaleRemain;
  // Info of presale bracket: total tokens, remain tokens, price
  ICOData.Bracket public presaleBracket;
  // Sale states: InPrivateSale, InPresale, EndPresale, InPublicSale, EndPublicSale
  ICOData.SaleStates public saleState;
  // The flag to specify the selling state
  bool public isSelling;
  // The start date for private sale
  uint public sellingTime;
  // The flag to specify the transferable state
  bool public isTransferable;

  // Info of 1st & 2nd public brackets: total tokens, remain tokens, price
  ICOData.Bracket[2] public publicBrackets;  
  // The index of current public bracket: 0 or 1
  uint private currentPublicBracketIndex;

  event PrivateSale(address to, uint256 tokenAmount); // Transfer token to investors in private sale
  event PublicSale(address to, uint256 amount, uint256 tokenAmount); // Investors purchase token in public sale
  event SetBracketPrice(uint bracketIndex, uint256 tokenPerEther); // Set bracket price in public sale  
  event StartPublicSale(uint256 tokenPerEther); // start public sale with price
  event EndPublicSale(); // end public sale
  event SetPresalePrice(uint256 tokenPerEther); // Set price in presale
  event PreSale(address to, uint256 amount, uint256 tokenAmount); // Investors purchase token in presale
  event StartPrivateSale(uint startedTime); // start private sale
  event StartPresale(uint256 tokenPerEther, uint startedTime); // start presale
  event EndPresale(); // end presale
  event ChangeBracketIndex(uint bracketIndex); // change to next bracket for sale  
  event EnableTransfer(); // enable transfer token
  event BurnTeamToken(address lockedWallet, address memberAddress, uint256 amount); // burn token allocated for dev team when they are inactivity

  modifier transferable() {
    require(isTransferable == true);
    _;
  }

  modifier isInSale() {
    require(isSelling == true);
    _;
  }

  modifier onlyAdminOrOwner() {
    require(msg.sender == admin || msg.sender == owner());
    _;
  }

  constructor(
    address _admin,
    address _fundWallet,
    address _airdropWallet,
    address _treasuryWallet,
    address _partnerWallet,
    address _lotto645JackpotWallet,
    address _lotto655Jackpot1Wallet,
    address _lotto655Jackpot2Wallet,
    address _approver1,
    address _approver2,
    uint _startPrivateSaleAfter
  ) 
    public 
  { 
    require(_admin != address(0) && _admin != msg.sender);
    require(_fundWallet != address(0) && _fundWallet != msg.sender);
    require(_airdropWallet != address(0) && _airdropWallet != msg.sender );
    require(_treasuryWallet != address(0) && _treasuryWallet != msg.sender );
    require(_partnerWallet != address(0) && _partnerWallet != msg.sender );
    require(_lotto645JackpotWallet != address(0) && _lotto645JackpotWallet != msg.sender );
    require(_lotto655Jackpot1Wallet != address(0) && _lotto655Jackpot1Wallet != msg.sender );
    require(_lotto655Jackpot2Wallet != address(0) && _lotto655Jackpot2Wallet != msg.sender );

    admin = _admin;
    fundWallet = _fundWallet;
    airdropWallet = _airdropWallet;
    treasuryWallet = _treasuryWallet;
    partnerWallet = _partnerWallet;
    lotto645JackpotWallet = _lotto645JackpotWallet;
    lotto655Jackpot1Wallet = _lotto655Jackpot1Wallet;
    lotto655Jackpot2Wallet = _lotto655Jackpot2Wallet;

    saleState = ICOData.SaleStates.InPrivateSale;
    sellingTime = now + _startPrivateSaleAfter * 1 seconds;

    // create TeamWallet & AdvisorWallet
    teamWallet = new TeamWallet(_approver1, _approver2);
    advisorWallet = new AdvisorWallet();

    emit StartPrivateSale(sellingTime);
	  initTokenAndBrackets();
  }

  function getSaleState() public view returns (ICOData.SaleStates state, uint time) {
    return (saleState, sellingTime);
  }

  function () external payable isInSale {
    require(fundWallet != address(0));    

    if(saleState == ICOData.SaleStates.InPresale && now >= sellingTime ) {
      return purchaseTokenInPresale();
    } else if(saleState == ICOData.SaleStates.InPublicSale  && now >= sellingTime ) {
      return purchaseTokenInPublicSale();
    }
    
    revert();
  }

  function getCurrentPublicBracket()
    public 
    view 
    returns (
      uint256 bracketIndex, 
      uint256 total, 
      uint256 remainToken, 
      uint256 tokenPerEther,
      uint256 minAcceptedAmount
    ) 
  {
    if(saleState == ICOData.SaleStates.InPublicSale) {
      ICOData.Bracket memory bracket = publicBrackets[currentPublicBracketIndex];
      return (currentPublicBracketIndex, bracket.total, bracket.remainToken, bracket.tokenPerEther, bracket.minAcceptedAmount);
    } else {
      return (0, 0, 0, 0, 0);
    }
  }

  function transfer(address _to, uint256 _value) 
    public
    transferable 
    returns (bool success) 
  {
    require(_to != address(0));
    require(_value > 0);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) 
    public 
    transferable 
    returns (bool success) 
  {
    require(_from != address(0));
    require(_to != address(0));
    require(_value > 0);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) 
    public 
    transferable 
    returns (bool success) 
  {
    require(_spender != address(0));
    require(_value > 0);
    return super.approve(_spender, _value);
  }

  function changeWalletAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0));
    require(fundWallet != _newAddress);
    fundWallet = _newAddress;
  }

  function changeAdminAddress(address _newAdmin) external onlyOwner {
    require(_newAdmin != address(0));
    require(admin != _newAdmin);
    admin = _newAdmin;
  }

  function enableTransfer() external onlyOwner {
    require(isTransferable == false);
    isTransferable = true;
    emit EnableTransfer();
  }
  
  function transferPrivateSale(address _to, uint256 _value) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(saleState == ICOData.SaleStates.InPrivateSale);
    require(_to != address(0));
    require(_value > 0);
    require(privateSaleRemain >= _value);

    privateSaleRemain = privateSaleRemain.sub(_value);
    _transfer(owner(), _to, _value);
    emit PrivateSale(_to, _value);
    return true;    
  }
  
  function setPublicPrice(uint _bracketIndex, uint256 _tokenPerEther) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(_tokenPerEther > 0);
    require(publicBrackets.length > _bracketIndex && _bracketIndex >= currentPublicBracketIndex);

    ICOData.Bracket storage bracket = publicBrackets[_bracketIndex];
    require(bracket.tokenPerEther != _tokenPerEther);

    bracket.tokenPerEther = _tokenPerEther;
    emit SetBracketPrice(_bracketIndex, _tokenPerEther);
    return true;
  }

  function setMinAcceptedInPublicSale(uint _bracketIndex, uint256 _minAcceptedAmount) 
    external 
    onlyAdminOrOwner 
    returns (bool success)
  {
    require(_minAcceptedAmount > 0);
    require(publicBrackets.length > _bracketIndex && _bracketIndex >= currentPublicBracketIndex);

    ICOData.Bracket storage bracket = publicBrackets[_bracketIndex];
    require(bracket.minAcceptedAmount != _minAcceptedAmount);

    bracket.minAcceptedAmount = _minAcceptedAmount;
    return true;
  }  

  function changeToPublicSale() external onlyAdminOrOwner returns (bool success) {
    require(saleState == ICOData.SaleStates.EndPresale);    
    return startPublicSale();
  }  

  function setPresalePrice(uint256 _tokenPerEther) external onlyAdminOrOwner returns (bool) {
    require(_tokenPerEther > 0);
    require(presaleBracket.tokenPerEther != _tokenPerEther);

    presaleBracket.tokenPerEther = _tokenPerEther;
    emit SetPresalePrice(_tokenPerEther);
    return true;
  }

  function startPresale(uint256 _tokenPerEther, uint _startAfter) 
    external 
    onlyAdminOrOwner 
    returns (bool) 
  {
    require(saleState < ICOData.SaleStates.InPresale);
    require(_tokenPerEther > 0);    
    presaleBracket.tokenPerEther = _tokenPerEther;
    isSelling = true;
    saleState = ICOData.SaleStates.InPresale;
    sellingTime = now + _startAfter * 1 seconds;
    emit StartPresale(_tokenPerEther, sellingTime);
    return true;
  }

  function setMinAcceptedAmountInPresale(uint256 _minAcceptedAmount) 
    external 
    onlyAdminOrOwner 
    returns (bool)
  {
    require(_minAcceptedAmount > 0);
    require(presaleBracket.minAcceptedAmount != _minAcceptedAmount);

    presaleBracket.minAcceptedAmount = _minAcceptedAmount;
    return true;
  }

  function burnMemberToken(address _member) external onlyAdminOrOwner {        
    require(teamWallet != address(0));
    bool canBurn = teamWallet.canBurn(_member);
    uint256 tokenRemain = teamWallet.getMemberTokenRemain(_member);
    require(canBurn && tokenRemain > 0);    
    
    teamWallet.burnMemberToken(_member);

    _burn(teamWallet, tokenRemain);
    emit BurnTeamToken(teamWallet, _member, tokenRemain);
  }

  function initTokenAndBrackets() private {
    _mint(owner(), INITIAL_SUPPLY);

    // allocate token for bounty, referral, treasury, partner
    super.transfer(airdropWallet, AIRDROP_ALLOCATION);
    super.transfer(treasuryWallet, TREASURY_ALLOCATION);
    super.transfer(partnerWallet, PARTNER_ALLOCATION);

    // allocate token for private sale
    privateSaleRemain = PRIVATE_SALE_ALLOCATION;

    // allocate token for presale
    uint256 minAcceptedAmountInPresale = 1 ether; // 1 ether for mininum ether acception in presale
    presaleBracket = ICOData.Bracket(PRESALE_ALLOCATION, PRESALE_ALLOCATION, 0, minAcceptedAmountInPresale);
    
    // bracket token allocation for public sale
    uint256 minAcceptedAmountInBracket1 = 0.5 * (1 ether); // 0.5 ether for mininum ether acception in bracket 1
    publicBrackets[0] = ICOData.Bracket(PUBLIC_1_ALLOCATION, PUBLIC_1_ALLOCATION, 0, minAcceptedAmountInBracket1);

    uint256 minAcceptedAmountInBracket2 = 0.1 * (1 ether); // 0.1 ether for mininum ether acception in bracket 2
    publicBrackets[1] = ICOData.Bracket(PUBLIC_2_ALLOCATION, PUBLIC_2_ALLOCATION, 0, minAcceptedAmountInBracket2);    

    // allocate token for Z88 Lotto Jackpot
    super.transfer(lotto645JackpotWallet, LOTTO645_JACKPOT_ALLOCATION);
    super.transfer(lotto655Jackpot1Wallet, LOTTO655_JACKPOT_1_ALLOCATION);
    super.transfer(lotto655Jackpot2Wallet, LOTTO655_JACKPOT_2_ALLOCATION);

    // allocate token for Team Wallet
    super.transfer(teamWallet, FOUNDER_AND_TEAM_ALLOCATION);
    // allocate token to Advisor Wallet
    super.transfer(advisorWallet, ADVISOR_ALLOCATION);
    advisorWallet.allocateTokenForAdvisor();
  }

  function purchaseTokenInPresale() private {
    require(msg.value >= presaleBracket.minAcceptedAmount);
    require(presaleBracket.tokenPerEther > 0 && presaleBracket.remainToken > 0);

    uint256 tokenPerEther = presaleBracket.tokenPerEther.mul(10 ** decimals);
    uint256 tokenAmount = msg.value.mul(tokenPerEther).div(1 ether);    

    uint256 refundAmount = 0;
    if(tokenAmount > presaleBracket.remainToken) {
      refundAmount = tokenAmount.sub(presaleBracket.remainToken).mul(1 ether).div(tokenPerEther);
      tokenAmount = presaleBracket.remainToken;
    }

    presaleBracket.remainToken = presaleBracket.remainToken.sub(tokenAmount);
    _transfer(owner(), msg.sender, tokenAmount);

    uint256 paymentAmount = msg.value.sub(refundAmount);
    fundWallet.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);

    emit PreSale(msg.sender, paymentAmount, tokenAmount);

    if(presaleBracket.remainToken == 0) {
      endPresale();
    }    
  }

  function endPresale() private {    
    isSelling = false;
    saleState = ICOData.SaleStates.EndPresale;
    emit EndPresale();
    startPublicSale();
  }

  function startPublicSale() private returns (bool success) {    
    ICOData.Bracket memory bracket = publicBrackets[currentPublicBracketIndex];
    if(bracket.tokenPerEther == 0) return false;    
    isSelling = true;
    saleState = ICOData.SaleStates.InPublicSale;
    emit StartPublicSale(bracket.tokenPerEther);
    return true;
  }

  function purchaseTokenInPublicSale() private {
    ICOData.Bracket storage bracket = publicBrackets[currentPublicBracketIndex];
    require(msg.value >= bracket.minAcceptedAmount);
    require(bracket.tokenPerEther > 0 && bracket.remainToken > 0);

    uint256 tokenPerEther = bracket.tokenPerEther.mul(10 ** decimals);
    uint256 remainToken = bracket.remainToken;
    uint256 tokenAmount = msg.value.mul(tokenPerEther).div(1 ether);
    uint256 refundAmount = 0;

    // check remain token when end bracket
    if(remainToken < tokenAmount) {      
      refundAmount = tokenAmount.sub(remainToken).mul(1 ether).div(tokenPerEther);
      tokenAmount = remainToken;
    }

    bracket.remainToken = bracket.remainToken.sub(tokenAmount);
    _transfer(owner(), msg.sender, tokenAmount);

    uint256 paymentAmount = msg.value.sub(refundAmount);
    fundWallet.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);
    
    emit PublicSale(msg.sender, paymentAmount, tokenAmount);

    // end current bracket and move to next bracket
    if(bracket.remainToken == 0) {      
      nextBracket();
    }
  }

  function nextBracket() private {
    // last bracket - end public sale
    if(currentPublicBracketIndex == publicBrackets.length - 1) {
      isSelling = false;
      saleState = ICOData.SaleStates.EndPublicSale;
      isTransferable = true;
      emit EnableTransfer();
      emit EndPublicSale();
    }        
    else {
      currentPublicBracketIndex = currentPublicBracketIndex + 1;
      emit ChangeBracketIndex(currentPublicBracketIndex);
    }
  }
}