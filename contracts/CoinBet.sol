/* solium-disable */
pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  
  event Transfer(address indexed _from, address indexed _to, uint _value);
  //event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  //event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {  
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    //balances[_from] = balances[_from].sub(_value); // this was removed
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
  * @dev modifier to allow actions only when the contract IS paused
  */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
  * @dev modifier to allow actions only when the contract IS NOT paused
  */
  modifier whenPaused {
    require (paused);
    _;
  }

  /**
  * @dev called by the owner to pause, triggers stopped state
  */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
  * @dev called by the owner to unpause, returns to normal state
  */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


contract LockedWalletForTeam is Ownable {
    
  uint256 public createdAt;
  ERC20 public tokenContract;
  uint256 public totalToken;

  uint256 public firstUnlockDate;
  uint256 public secondUnlockDate;
  uint256 public thirdUnlockDate;

  uint public withdrawStage;

  event WithdrewTokens(address tokenContract, address to, uint256 amount);

  function LockedWalletForTeam(
    ERC20 _tokenContract,
    address _owner,
    uint256 _totalToken
  ) public {
    tokenContract = _tokenContract;
    owner = _owner;    
    totalToken = _totalToken;
    createdAt = now;
    withdrawStage = 0;
    
    firstUnlockDate = now + (11 * 30 * 1 days); // Allow withdraw 20% after 11 month    
    secondUnlockDate = now + (23 * 30 * 1 days); // Allow withdraw 30% after 23 month
    thirdUnlockDate = now + (35 * 30 * 1 days); // Allow withdraw all after 35 month
  }
  
  function() payable public { 
    revert();
  }

  // callable by owner only, after specified time
  function withdrawTokens() onlyOwner public {
    require(now > firstUnlockDate);

    uint256 amount = 0;
    if(now > thirdUnlockDate) {
      // withdrew all remain token in second stage
      amount = tokenContract.balanceOf(this);      
    } else if(now > secondUnlockDate && withdrawStage == 1) {
      // withdrew 30% in second stage
      amount = totalToken * 30 / 100;
    } else if(now > firstUnlockDate && withdrawStage == 0){
      // withdrew 20% in first stage
      amount = totalToken * 20 / 100;
    }

    if(amount > 0) {
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      withdrawStage = withdrawStage + 1;
      return;
    }

    revert();
  }

  function info() public view returns(address, uint256, uint256) {
    uint256 tokenBalance = tokenContract.balanceOf(this);
    return (owner, createdAt, tokenBalance);
  }
}


contract LockedWalletForAdvisor is Ownable {
    
  uint256 public createdAt;
  ERC20 public tokenContract;
  uint256 public totalToken;

  uint256 public firstUnlockDate;
  uint256 public secondUnlockDate;  

  uint public withdrawStage;

  event WithdrewTokens(address tokenContract, address to, uint256 amount);

  function LockedWalletForAdvisor(
    ERC20 _tokenContract,
    address _owner,
    uint256 _totalToken
  ) public {
    tokenContract = _tokenContract;
    owner = _owner;    
    totalToken = _totalToken;
    createdAt = now;
    withdrawStage = 0;
    
    firstUnlockDate = now + (5 * 30 * 1 days); // Allow withdraw 50% after 5 month    
    secondUnlockDate = now + (11 * 30 * 1 days); // Allow withdraw all after 11 month    
  }
  
  function() payable public { 
    revert();
  }

  // callable by owner only, after specified time
  function withdrawTokens() onlyOwner public {
    require(now > firstUnlockDate);

    uint256 amount = 0;
    if(now > secondUnlockDate) {
      // withdrew all remain token in second stage
      amount = tokenContract.balanceOf(this);
    } else if(now > firstUnlockDate && withdrawStage == 0){
      // withdrew 50% in first stage
      amount = totalToken * 50 / 100;
    }

    if(amount > 0) {
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      withdrawStage = withdrawStage + 1;
      return;
    }

    revert();
  }

  function info() public view returns(address, uint256, uint256) {
    uint256 tokenBalance = tokenContract.balanceOf(this);
    return (owner, createdAt, tokenBalance);
  }
}


// ================= Coinbet Token =======================
contract CoinBet is StandardToken, Pausable {
  
  string public constant name = "Coinbet";
  string public constant symbol = "Z88";  
  uint256 public constant decimals = 18;
  uint256 public constant totalSupply = 100000000 * (10 ** 18); // 100M token will be supplied

  uint256 public constant founderAndTeamAllocation = 15000000 * (10 ** 18); // 15M tokens allocated for founders and team
  uint256 public constant advisorAllocation = 3000000 * (10 ** 18); // 3M tokens allocated for advisors
  uint256 public constant airdropAllocation = 2000000 * (10 ** 18); // 2M tokens allocated for airdrops
  uint256 public constant privateSaleAllocation = 40000000 * (10 ** 18); // 40M tokens allocated for private sale
  uint256 public constant tokenPerBracket = 10000000 * (10 ** 18); // 4 brackets with 10M tokens per one - total 40M tokens for public sale    
  uint256 public constant minAcceptedAmount = 0.1 * (1 ether); // 0.1 ether for mininum ether acception in public sale  
  
  address public walletAddress;
  address public airdropAddress;
  address public privateSaleAddress;

  bool public isTransferable = false;
  bool public isPublicSelling = false;

  struct Bracket {
    uint256 total;
    uint256 remainToken;
    uint256 tokenPerEther;    
  }

  struct TokenLockInfo {
    address owner;
    uint256 tokenAmount;    
  }
    
  Bracket[] public brackets;  
  uint public currentBracketIndex = 0;

  mapping(address => address) public teamWallets;
  mapping(address => address) public advisorWallets;

  event PrivateSale(address to, uint256 tokenAmount); // Transfer token to investors
  event PublicSale(address to, uint256 amount, uint256 tokenAmount); // Investors purchase token in public sale
  event SetBracketPrice(uint bracketIndex, uint256 tokenPerEther); // Set bracket price in public sale
  event StartPublicSale(uint256 tokenPerEther); // start public sale with price
  event EndPublicSale(); // end public sale
  event ChangeBracketIndex(uint bracketIndex); // change to next bracket for sale  
  event EnableTransfer();

  modifier onlyPrivateSaleOrOwner() {
    require(msg.sender == privateSaleAddress || msg.sender == owner);
    _;
  }

  modifier transferable() {
    require(isTransferable == true);
    _;
  }

  modifier isInPublicSale() {
    require(isPublicSelling == true);
    _;
  }

  function CoinBet(    
    address _walletAddress,    
    address _airdropAddress, 
    address _privateSaleAddress
  ) 
    public 
  {    
    require(_walletAddress != address(0));
    require(_airdropAddress != address(0));
    require(_privateSaleAddress != address(0));

    walletAddress = _walletAddress;
    airdropAddress = _airdropAddress;
    privateSaleAddress = _privateSaleAddress;
	
	  initTokenAndBrackets();
  }

  function () external payable isInPublicSale {    
    require(msg.value >= minAcceptedAmount);    
    require(walletAddress != address(0));
    return purchaseTokens();
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
    Bracket memory bracket = brackets[currentBracketIndex];
    return (currentBracketIndex, bracket.total, bracket.remainToken, bracket.tokenPerEther);
  }

  function transfer(address _to, uint256 _value) 
    public 
    whenNotPaused 
    transferable 
    returns (bool success) 
  {
    require(_to != address(0));
    require(_value > 0);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) 
    public 
    whenNotPaused 
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
    whenNotPaused 
    transferable 
    returns (bool success) 
  {
    require(_spender != address(0));
    require(_value > 0);
    return super.approve(_spender, _value);
  }

  function changeWalletAddress(address _newAddress) public onlyOwner {
    require(_newAddress != address(0));
    require(walletAddress != _newAddress);
    walletAddress = _newAddress;
  }

  function enableTransfer() public onlyOwner {
    require(isTransferable == false);
    isTransferable = true;
    emit EnableTransfer();
  }
  
  function transferPrivateSale(address _to, uint256 _value) 
    public 
    onlyPrivateSaleOrOwner 
    returns (bool success) 
  {
    require(_to != address(0));
    require(_value > 0);

    balances[privateSaleAddress] = balances[privateSaleAddress].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit PrivateSale(_to, _value);
    return true;    
  }
  
  function setBracketPrice(uint _bracketIndex, uint256 _tokenPerEther) 
    public 
    onlyOwner 
    returns (bool success) 
  {
    require(_tokenPerEther > 0);
    require(brackets.length > _bracketIndex);
    require(_bracketIndex >= currentBracketIndex);
    Bracket storage bracket = brackets[_bracketIndex];
    bracket.tokenPerEther = _tokenPerEther;
    emit SetBracketPrice(_bracketIndex, _tokenPerEther);
    return true;
  }

  function startPublicSale() public onlyOwner returns (bool success) {
    require(isPublicSelling == false);    
    Bracket memory bracket = brackets[currentBracketIndex];
    require(bracket.tokenPerEther > 0);
    isPublicSelling = true;
    emit StartPublicSale(bracket.tokenPerEther);
    return true;
  }

  function endPublicSale() public onlyOwner returns (bool success) {
    require(isPublicSelling == true);
    isPublicSelling = false;
    isTransferable = true;
    emit EndPublicSale();
    return true;
  }

  function saleToNextBracket() public onlyOwner {
    require(isPublicSelling == true);    
    return nextBracket();
  }

  function nextBracket() private {
    // last bracket - end public sale
    if(currentBracketIndex == brackets.length - 1) {
      isPublicSelling = false;
      isTransferable = true;
      emit EndPublicSale();
    }        
    else {
      currentBracketIndex = currentBracketIndex + 1;
      emit ChangeBracketIndex(currentBracketIndex);
    }
  }
  
  function initTokenAndBrackets() private {
    balances[owner] = totalSupply;
	  emit Transfer(0x0, owner, totalSupply);

    // airdrop and private sale token allocation
    super.transfer(airdropAddress, airdropAllocation);
    super.transfer(privateSaleAddress, privateSaleAllocation);
    
    // bracket token allocation
    brackets.push(Bracket(tokenPerBracket, tokenPerBracket, 0));
    brackets.push(Bracket(tokenPerBracket, tokenPerBracket, 0));
    brackets.push(Bracket(tokenPerBracket, tokenPerBracket, 0));
    brackets.push(Bracket(tokenPerBracket, tokenPerBracket, 0));    

    // allocation 15M token for team and founder
    uint totalTeamMember = 3;
    TokenLockInfo[] memory tokenLockInfos = new TokenLockInfo[](totalTeamMember);
    tokenLockInfos[0] = TokenLockInfo(0x50ce0Eb4c1C1b64f0282f7b118Dfeb72449fbBe6, 5000000 * (10 ** decimals));
    tokenLockInfos[1] = TokenLockInfo(0x13C82E64f460C1e000dF81080064665820756dB6, 5000000 * (10 ** decimals));
    tokenLockInfos[2] = TokenLockInfo(0xd811A297C0E8E6fa3C69442903d0b073d9d5ff96, 5000000 * (10 ** decimals));    

    uint i = 0;
    TokenLockInfo memory tokenInfo;
    address wallet;

    for(i = 0; i < totalTeamMember; i++) {
      tokenInfo = tokenLockInfos[i];
      wallet = new LockedWalletForTeam(this, tokenInfo.owner, tokenInfo.tokenAmount);
      teamWallets[tokenInfo.owner] = wallet;

      super.transfer(wallet, tokenInfo.tokenAmount);
    }

    // allocation 3M token for advisor
    uint totalAdvisor = 2;
    tokenLockInfos = new TokenLockInfo[](totalAdvisor);
    tokenLockInfos[0] = TokenLockInfo(0x50ce0Eb4c1C1b64f0282f7b118Dfeb72449fbBe6, 1500000 * (10 ** decimals));
    tokenLockInfos[1] = TokenLockInfo(0x13C82E64f460C1e000dF81080064665820756dB6, 1500000 * (10 ** decimals));    

    for(i = 0; i < totalAdvisor; i++) {
      tokenInfo = tokenLockInfos[i];
      wallet = new LockedWalletForAdvisor(this, tokenInfo.owner, tokenInfo.tokenAmount);
      advisorWallets[tokenInfo.owner] = wallet;

      super.transfer(wallet, tokenInfo.tokenAmount);
    }

  }  

  function purchaseTokens() private {
    Bracket storage bracket = brackets[currentBracketIndex];
    require(bracket.tokenPerEther > 0);
    require(bracket.remainToken > 0);

    uint256 tokenPerEther = bracket.tokenPerEther.mul(10 ** 18);
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
    emit PublicSale(msg.sender, paymentAmount, tokenAmount);

    // end current bracket and move to next bracket
    if(bracket.remainToken == 0) {      
      nextBracket();
    }
  }
	
}