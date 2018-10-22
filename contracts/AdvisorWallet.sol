pragma solidity ^0.4.24;

import './ERC20Interface.sol';

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

  constructor(address _tokenAddress) public {
    require(_tokenAddress != address(0));

    creator = _tokenAddress;
    tokenContract = ERC20(_tokenAddress);

    firstUnlockDate = now + (6 * 30 days); // Allow withdraw 50% after 6 month
    secondUnlockDate = now + (12 * 30 days); // Allow withdraw all after 12 month
  }
  
  function() payable public { 
    revert();
  }

	function setAllocateTokenDone() external onlyCreator {
		require(!allocateTokenDone);
		allocateTokenDone = true;
	}

	function addAdvisor(address _memberAddress, uint256 _tokenAmount) external onlyCreator {		
		require(!allocateTokenDone);
		advisors[_memberAddress] = Advisor(_tokenAmount, 0);
    totalToken = totalToken.add(_tokenAmount);
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