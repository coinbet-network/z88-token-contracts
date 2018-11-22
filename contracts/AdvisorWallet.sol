pragma solidity ^0.4.24;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract AdvisorWallet {  
	using SafeMath for uint256;

	struct Advisor {		
		uint256 tokenAmount;    
		uint withdrawStage;		
	}

  ERC20 public tokenContract;
	uint256 public totalToken;
	address public creator;
	bool public allocateTokenDone = false;

	mapping(address => Advisor) public advisors;

  uint public firstUnlockDate;
  uint public secondUnlockDate;  

  event WithdrewTokens(address _tokenContract, address _to, uint256 _amount);

	modifier onlyCreator() {
		require(msg.sender == creator);
		_;
	}

  constructor() public {
    creator = msg.sender;
    tokenContract = ERC20(creator);

    firstUnlockDate = now + (6 * 30 days); // Allow withdraw 50% after 6 month
    secondUnlockDate = now + (12 * 30 days); // Allow withdraw all after 12 month
  }
  
  function() payable public { 
    revert();
  }

	function setAllocateTokenDone() internal {
		require(!allocateTokenDone);
		allocateTokenDone = true;
	}

	function addAdvisor(address _memberAddress, uint256 _tokenAmount) internal {		
		require(!allocateTokenDone);
		advisors[_memberAddress] = Advisor(_tokenAmount, 0);
    totalToken = totalToken.add(_tokenAmount);
	}

  function allocateTokenForAdvisor() external onlyCreator {
    // allocation 10M token for advisor
    addAdvisor(0xf8E2d6a822f70c5c5788fa10f080810a8579d407, 2000000 * (10 ** 18));
    addAdvisor(0xab74072a37e08Ff9ceA098d4E33438257589B044, 1000000 * (10 ** 18));
    addAdvisor(0x3DFD289380Cbe25456B5973306129753c4ed3dF3, 7000000 * (10 ** 18));
    setAllocateTokenDone();
  }
	
  // callable by advisor only, after specified time
  function withdrawTokens() external {		
    require(now > firstUnlockDate);
		Advisor storage advisor = advisors[msg.sender];
		require(advisor.tokenAmount > 0);

    uint256 amount = 0;
    if(now > secondUnlockDate) {
      // withdrew all token remain in second stage
      amount = advisor.tokenAmount;
    } else if(now > firstUnlockDate && advisor.withdrawStage == 0){
      // withdrew 50% in first stage
      amount = advisor.tokenAmount * 50 / 100;
    }

    if(amount > 0) {
			advisor.tokenAmount = advisor.tokenAmount.sub(amount);      
			advisor.withdrawStage = advisor.withdrawStage + 1;      
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      return;
    }

    revert();
  }
}