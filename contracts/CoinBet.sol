/* solium-disable */
pragma solidity ^0.4.24;

import './StandardToken.sol';

contract ITeamWallet {
  function canBurn(address _member) public view returns(bool);  
  function addMember(address _member, uint256 _tokenAmount) public;
  function setAllocateTokenDone() public;
  function getMemberTokenRemain(address _member) public view returns (uint256);
  function burnMemberToken(address _memberAddress) public;
}


contract IAdvisorWallet {    
  function addAdvisor(address _member, uint256 _tokenAmount) public;
  function setAllocateTokenDone() public;
}


library DataLib {
  struct Bracket {
    uint256 total;
    uint256 remainToken;
    uint256 tokenPerEther;    
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
contract CoinBet is StandardToken, Ownable {
  
  string public constant name = "Coinbet";
  string public constant symbol = "Z88";  
  uint256 public constant decimals = 18;
  uint256 public totalSupply = 200000000 * (10 ** decimals); // 200M token will be supplied

  uint256 public constant founderAndTeamAllocation = 20000000 * (10 ** decimals); // 20M tokens allocated for founders and team
  uint256 public constant advisorAllocation = 10000000 * (10 ** decimals); // 10M tokens allocated for advisors
  uint256 public constant airdropAllocation = 50000000 * (10 ** decimals); // 50M tokens (bounty 10M, treasure 30M, partner program 10M) allocated for airdrops
  
  uint256 public constant privateSaleAllocation = 40000000 * (10 ** decimals); // 40M tokens allocated for private sale
  uint256 public constant preSaleAllocation = 20000000 * (10 ** decimals); // 20M tokens allocated for private sale

  uint256 public constant tokenPerBracket1 = 20000000 * (10 ** decimals); // 20M tokens in bracket 1 for public sale
  uint256 public constant tokenPerBracket2 = 40000000 * (10 ** decimals); // 40M tokens in bracket 2 for public sale
  uint256 public constant minAcceptedAmountInSale = 0.1 * (1 ether); // 0.1 ether for mininum ether acception in presale and public sale
  
  address public admin;
  address public walletAddress;
  address public airdropAddress;  
  address public teamWalletAddress;
  address public advisorWalletAddress;
  
  uint256 public privateSaleRemain;
  DataLib.Bracket public presaleBracket;
  DataLib.SaleStates public saleState;
  bool public isSelling;
  uint public sellingTime;
  bool public isTransferable;

  DataLib.Bracket[2] public brackets;  
  uint public currentBracketIndex;

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
    require(msg.sender == admin || msg.sender == owner);
    _;
  }

  constructor(
    address _admin,
    address _walletAddress,
    address _airdropAddress,    
    uint _startPrivateSaleAfter
  ) 
    public 
  { 
    require(_admin != address(0) && _admin != msg.sender);   
    require(_walletAddress != address(0) && _walletAddress != msg.sender);
    require(_airdropAddress != address(0) && _airdropAddress != msg.sender );    

    admin = _admin;
    walletAddress = _walletAddress;
    airdropAddress = _airdropAddress;
    saleState = DataLib.SaleStates.InPrivateSale;
    sellingTime = now + _startPrivateSaleAfter;

    emit StartPrivateSale(sellingTime);
	  initTokenAndBrackets();
  }

  function getSaleState() public view returns (DataLib.SaleStates state, uint time) {
    return (saleState, sellingTime);
  }

  function () external payable isInSale {
    require(walletAddress != address(0));
    require(msg.value >= minAcceptedAmountInSale);

    if(saleState == DataLib.SaleStates.InPresale && now >= sellingTime ) {
      return purchaseTokenInPresale();
    } else if(saleState == DataLib.SaleStates.InPublicSale  && now >= sellingTime ) {
      return purchaseTokenInPublicSale();
    }
    
    revert();
  }

  function getCurrentBracket() 
    public 
    view 
    returns (
      uint256 bracketIndex, 
      uint256 total, 
      uint256 remainToken, 
      uint256 tokenPerEther
    ) 
  {    
    DataLib.Bracket memory bracket = brackets[currentBracketIndex];
    return (currentBracketIndex, bracket.total, bracket.remainToken, bracket.tokenPerEther);
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
    require(walletAddress != _newAddress);
    walletAddress = _newAddress;
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
    require(saleState == DataLib.SaleStates.InPrivateSale);
    require(_to != address(0));
    require(_value > 0);
    require(privateSaleRemain >= _value);

    privateSaleRemain = privateSaleRemain.sub(_value);
    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(owner, _to, _value);
    emit PrivateSale(_to, _value);
    return true;    
  }
  
  function setBracketPrice(uint _bracketIndex, uint256 _tokenPerEther) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(_tokenPerEther > 0);
    require(brackets.length > _bracketIndex);
    require(_bracketIndex >= currentBracketIndex);
    DataLib.Bracket storage bracket = brackets[_bracketIndex];
    bracket.tokenPerEther = _tokenPerEther;
    emit SetBracketPrice(_bracketIndex, _tokenPerEther);
    return true;
  }

  function changeToPublicSale() external onlyAdminOrOwner returns (bool success) {
    require(saleState == DataLib.SaleStates.EndPresale);    
    return startPublicSale();
  }  

  function setPresalePrice(uint256 _tokenPerEther) external onlyAdminOrOwner returns (bool) {
    require(_tokenPerEther > 0);
    presaleBracket.tokenPerEther = _tokenPerEther;
    emit SetPresalePrice(_tokenPerEther);
    return true;
  }

  function startPresale(uint256 _tokenPerEther, uint _startAfter) external onlyAdminOrOwner returns (bool) {
    require(saleState < DataLib.SaleStates.InPresale);
    require(_tokenPerEther > 0);    
    presaleBracket.tokenPerEther = _tokenPerEther;
    isSelling = true;
    saleState = DataLib.SaleStates.InPresale;
    sellingTime = now + _startAfter;
    emit StartPresale(_tokenPerEther, sellingTime);
    return true;
  }
  
  function allocateTokenForTeam(address _teamWallet) external onlyOwner {
    require(teamWalletAddress == address(0) && _teamWallet != address(0));    
    teamWalletAddress = _teamWallet;
    ITeamWallet teamWallet = ITeamWallet(teamWalletAddress);    

    // allocation 20M token for team and founder
    teamWallet.addMember(0x50ce0Eb4c1C1b64f0282f7b118Dfeb72449fbBe6, 10000000 * (10 ** decimals));  
    teamWallet.addMember(0x13C82E64f460C1e000dF81080064665820756dB6, 10000000 * (10 ** decimals));
    teamWallet.setAllocateTokenDone();

    super.transfer(teamWalletAddress, founderAndTeamAllocation);
  }

  function allocateTokenForAdvisor(address _advisorWallet) external onlyOwner {
    require(advisorWalletAddress == address(0) && _advisorWallet != address(0));
    
    advisorWalletAddress = _advisorWallet;
    IAdvisorWallet advisorWallet = IAdvisorWallet(advisorWalletAddress);    

    // allocation 10 token for advisor    
    advisorWallet.addAdvisor(0x50ce0Eb4c1C1b64f0282f7b118Dfeb72449fbBe6, 5000000 * (10 ** decimals));
    advisorWallet.addAdvisor(0x13C82E64f460C1e000dF81080064665820756dB6, 5000000 * (10 ** decimals));
    advisorWallet.setAllocateTokenDone();

    super.transfer(advisorWalletAddress, advisorAllocation);
  }

  function burnMemberToken(address _member) external onlyAdminOrOwner {        
    require(teamWalletAddress != address(0));
    ITeamWallet teamWallet = ITeamWallet(teamWalletAddress);    
    bool canBurn = teamWallet.canBurn(_member);
    uint256 tokenRemain = teamWallet.getMemberTokenRemain(_member);
    require(canBurn && tokenRemain > 0);    
    
    teamWallet.burnMemberToken(_member);

    balances[teamWalletAddress] = balances[teamWalletAddress].sub(tokenRemain);
    totalSupply = totalSupply.sub(tokenRemain);

    emit Transfer(teamWalletAddress, address(0), tokenRemain);
    emit BurnTeamToken(teamWalletAddress, _member, tokenRemain);
  }
  
  function initTokenAndBrackets() private {
    balances[owner] = totalSupply;
	  emit Transfer(address(0), owner, totalSupply);

    // allocate token for airdrop (grow network, bounty, referral, ...)
    super.transfer(airdropAddress, airdropAllocation);

    // allocate token for private sale
    privateSaleRemain = privateSaleAllocation;

    // allocate token for presale
    presaleBracket = DataLib.Bracket(preSaleAllocation, preSaleAllocation, 0);
    
    // bracket token allocation for public sale
    brackets[0] = DataLib.Bracket(tokenPerBracket1, tokenPerBracket1, 0);
    brackets[1] = DataLib.Bracket(tokenPerBracket2, tokenPerBracket2, 0);    

    // allocate token for Z88 Lotto Jackpot
  }

  function purchaseTokenInPresale() private {
    require(presaleBracket.tokenPerEther > 0 && presaleBracket.remainToken > 0);
    uint256 tokenPerEther = presaleBracket.tokenPerEther.mul(10 ** decimals);
    uint256 tokenAmount = msg.value.mul(tokenPerEther).div(1 ether);    

    uint256 refundAmount = 0;
    if(tokenAmount > presaleBracket.remainToken) {
      refundAmount = tokenAmount.sub(presaleBracket.remainToken).mul(1 ether).div(tokenPerEther);
      tokenAmount = presaleBracket.remainToken;
    }

    presaleBracket.remainToken = presaleBracket.remainToken.sub(tokenAmount);
    balances[owner] = balances[owner].sub(tokenAmount);
    balances[msg.sender] = balances[msg.sender].add(tokenAmount);    

    uint256 paymentAmount = msg.value.sub(refundAmount);
    walletAddress.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);

    emit Transfer(owner, msg.sender, tokenAmount);
    emit PreSale(msg.sender, paymentAmount, tokenAmount);

    if(presaleBracket.remainToken == 0) {
      endPresale();
    }    
  }

  function endPresale() private {    
    isSelling = false;
    saleState = DataLib.SaleStates.EndPresale;
    emit EndPresale();
    startPublicSale();
  }

  function startPublicSale() private returns (bool success) {    
    DataLib.Bracket memory bracket = brackets[currentBracketIndex];
    if(bracket.tokenPerEther == 0) return false;    
    isSelling = true;
    saleState = DataLib.SaleStates.InPublicSale;
    emit StartPublicSale(bracket.tokenPerEther);
    return true;
  }

  function purchaseTokenInPublicSale() private {    
    DataLib.Bracket storage bracket = brackets[currentBracketIndex];
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
    balances[owner] = balances[owner].sub(tokenAmount);
    balances[msg.sender] = balances[msg.sender].add(tokenAmount);    

    uint256 paymentAmount = msg.value.sub(refundAmount);
    walletAddress.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);
    
    emit Transfer(owner, msg.sender, tokenAmount);
    emit PublicSale(msg.sender, paymentAmount, tokenAmount);

    // end current bracket and move to next bracket
    if(bracket.remainToken == 0) {      
      nextBracket();
    }
  }

  function nextBracket() private {
    // last bracket - end public sale
    if(currentBracketIndex == brackets.length - 1) {
      isSelling = false;
      saleState = DataLib.SaleStates.EndPublicSale;
      isTransferable = true;
      emit EnableTransfer();
      emit EndPublicSale();
    }        
    else {
      currentBracketIndex = currentBracketIndex + 1;
      emit ChangeBracketIndex(currentBracketIndex);
    }
  }
	
}