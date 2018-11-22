pragma solidity ^0.4.24;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract TeamWallet {  
	using SafeMath for uint256;

	struct Member {		
    uint256 tokenAmount;
		uint256 tokenRemain;
		uint withdrawStage;		
		address lastRejecter;
    bool isRejected;
	}

  ERC20 public tokenContract;
	uint256 public totalToken;
	address public creator;
	bool public allocateTokenDone = false;

	mapping(address => Member) public members;

  uint public firstUnlockDate;
  uint public secondUnlockDate;
  uint public thirdUnlockDate;

  address public approver1;
  address public approver2;

  event WithdrewTokens(address _tokenContract, address _to, uint256 _amount);  
  event RejectedWithdrawal(address _rejecter, address _member, uint _withdrawStage);

	modifier onlyCreator() {
		require(msg.sender == creator);
		_;
	}

  modifier onlyApprover() {
    require(msg.sender == approver1 || msg.sender == approver2);
    _;
  }

  constructor(
    address _approver1,
    address _approver2
  ) public {
    require(_approver1 != address(0));
    require(_approver2 != address(0));

    creator = msg.sender;
    tokenContract = ERC20(creator);
    
    firstUnlockDate = now + (12 * 30 days); // Allow withdraw 20% after 12 month    
    secondUnlockDate = now + (24 * 30 days); // Allow withdraw 30% after 24 month
    thirdUnlockDate = now + (36 * 30 days); // Allow withdraw all after 36 month    

    approver1 = _approver1;
    approver2 = _approver2;
  }
  
  function() payable public { 
    revert();
  }

	function setAllocateTokenDone() internal {
		require(!allocateTokenDone);
		allocateTokenDone = true;
	}

	function addMember(address _memberAddress, uint256 _tokenAmount) internal {		
		require(!allocateTokenDone);
		members[_memberAddress] = Member(_tokenAmount, _tokenAmount, 0, address(0), false);
    totalToken = totalToken.add(_tokenAmount);
	}
  
  function allocateTokenForTeam() external onlyApprover {
    // allocation 20M token for team and founder
    addMember(0x0929C384F12914Fe20dE96af934A35b8333Bbe11, 97656 * (10 ** 18));
    addMember(0x0A0aC5949FE7Af47B566F0dC02f92DF6B6980AA5, 65104 * (10 ** 18));
    addMember(0x0eE878D94e22Cb50A62e4D685193B35015e3eDf8, 640000 * (10 ** 18));
    addMember(0x1A5912eEb9490B0937CD36636eEEFA82aA4Aa549, 177083 * (10 ** 18));
    addMember(0x1b2298A5d5342452D87D6684Fe31aEe52A31433d, 130208 * (10 ** 18));
    addMember(0x1eF0f9F6CcD2528d7038d4cEe47a417cA7f4c79d, 175781 * (10 ** 18));
    addMember(0x23a18F3A82F9EE302a1e6350b8D9f9F3B65ED5D7, 104167 * (10 ** 18));
    addMember(0x24F29d95a0D41a1713b67b29Bf664A1b70B5D683, 97656 * (10 ** 18));
    addMember(0x2598aCe98c1117f72Da929441b56a26994d5b13A, 680000 * (10 ** 18));
    addMember(0x275c667B3B372Ffb03BF05B97841C66eF1f1DF99, 480000 * (10 ** 18));
    addMember(0x27be83EBDC7D7917e2A4247bb8286cB192b74C51, 65104 * (10 ** 18));
    addMember(0x2847aFA0348284658A2cAFf676361A26220ccE7d, 280000 * (10 ** 18));
    addMember(0x29904b46fb7e411654dd16b1e9680A81Aa5A472D, 240000 * (10 ** 18));
    addMember(0x2B6f1941101c633Bbe24ce13Fd49ba14480F7242, 120000 * (10 ** 18));
    addMember(0x2c647B2D6a5B3FFE21bebA4467937cEd24c4292B, 720000 * (10 ** 18));
    addMember(0x2d8cdfBfc3C8Df06f70257eAca63aB742db62562, 110677 * (10 ** 18));
    addMember(0x3289E2310108699e22c2CDF81485885a3E9d3683, 31250 * (10 ** 18));
    addMember(0x375814a2D26A8cB1a010Db1FE8cE9Bc06e5224af, 125000 * (10 ** 18));
    addMember(0x401438aD9584A68D5A68FA1E8a2ef716862d82d9, 149740 * (10 ** 18));
    addMember(0x44be551E017893A0dD74e5160Ef0DB0aed2BdA54, 400000 * (10 ** 18));
    addMember(0x451B389a9F7365B09A24481F9EB5a125F64Ae4aB, 280000 * (10 ** 18));
    addMember(0x500D157FA3E3Ab5133ee0C7EFff3Ad5cdBCE01F3, 400000 * (10 ** 18));
    addMember(0x577FEE18cCD840b2a41c9180bbE6412a89c1aD2C, 720000 * (10 ** 18));
    addMember(0x58eA48c5FD9ac82e6CCb8aC67aCB48D1fb38b592, 80000 * (10 ** 18));
    addMember(0x5DdfCd7d8FAe31014010C3877E4Bf91F2E683F2D, 130208 * (10 ** 18));
    addMember(0x5E5Fc9f5C8B2EA3436D92dC07f621496C6E3EeC4, 800000 * (10 ** 18));
    addMember(0x5F89F3FeeeB67B3229b17E389D8BaD28f44d08aA, 120000 * (10 ** 18));
    addMember(0x60a09Fa998a1A6625c1161C452aAab26e6151cfA, 45573 * (10 ** 18));
    addMember(0x63Fa2cE8C891690fF40FB197E09C72B84Ca1030e, 121094 * (10 ** 18));
    addMember(0x66e898bA75FC329d872e61eE16fc4ea0248Eb369, 320000 * (10 ** 18));
    addMember(0x66F212e3Ba5F44BeB014FCe2beD1b1F290b13009, 15625 * (10 ** 18));
    addMember(0x6736ead91e4E9131262Aa033B8811071BbCa3f85, 117188 * (10 ** 18));
    addMember(0x6B99cE47bf47D91159109506B4722c732B5d7b46, 120000 * (10 ** 18));
    addMember(0x6f9140d408Faf111eF3D693645638B863650057d, 320000 * (10 ** 18));
    addMember(0x7510CC3635470Bd033c94a10B0a7ed46d98EbcC7, 156250 * (10 ** 18));
    addMember(0x7692bF394c84D3a880407E8cf4167b01007A9880, 175781 * (10 ** 18));
    addMember(0x7726bDa7d29FC141Eb65150eA7CBB1bC985693Dd, 93750 * (10 ** 18));
    addMember(0x7B6c1d3475974d5904c31BE4F3B9aA26F6eCAebB, 400000 * (10 ** 18));
    addMember(0x7D0E17DEa015B5A687385116d443466B2a42c65B, 109375 * (10 ** 18));
    addMember(0x8a0D93CF316b6Eb58aa5463533d06F18Bfa58ade, 640000 * (10 ** 18));
    addMember(0x8F25dD569c72fB507D72D743f070273556123AED, 169271 * (10 ** 18));
    addMember(0x908D0CF89bc46510b1B472F51905169Ad025f99F, 120000 * (10 ** 18));
    addMember(0x99A43289E131640534E147596F05d40699214673, 160000 * (10 ** 18));
    addMember(0x9C16FA8a4e04d67781D3d02a6b17De7a3e27e168, 600000 * (10 ** 18));
    addMember(0x9DAeD1073C38902a9a6dD8834f8a7c7851717b86, 360000 * (10 ** 18));
    addMember(0xa0dc24Aa838946d39d3d76f0f776BE6D26cB7b2b, 520000 * (10 ** 18));
    addMember(0xa40b31177E908d235FDF6AE8010e135d204BE19c, 160000 * (10 ** 18));
    addMember(0xa428FEcCc9E9F972498303d2C91982f1B6813827, 109375 * (10 ** 18));
    addMember(0xa7951c07d25d88D75662BD68B5dF4D6D08F17600, 104167 * (10 ** 18));
    addMember(0xA7fD89962f76233b68c33b0d9795c5899Feb11B3, 320000 * (10 ** 18));
    addMember(0xA8B6FB38F8BeC4C331E922Eb5a842921081267ce, 156250 * (10 ** 18));
    addMember(0xafbE656FbBC42704ef04aa6D8Ee1FEa9F3b71E7F, 136719 * (10 ** 18));
    addMember(0xb1cf51D7e8F987d0e64bBB2e1bE277821c600778, 130208 * (10 ** 18));
    addMember(0xB694854b6d8e6eAbDC15bE93005CCd54B841a79f, 560000 * (10 ** 18));
    addMember(0xb6dFc3227E2dd9CA569fFCE69014539F138D1bcC, 280000 * (10 ** 18));
    addMember(0xc230934C7610e39Ae06d4799e21b938bB44E60f2, 280000 * (10 ** 18));
    addMember(0xc6888650Dec537dD4f056008D9d3ED171d48F1CD, 640000 * (10 ** 18));
    addMember(0xccE1fc98815307BcDdE9596544802945a664C8b7, 440000 * (10 ** 18));
    addMember(0xd1326c632009979713BD92855cecc04c7ebE29F0, 36458 * (10 ** 18));
    addMember(0xD3859645cECCEFB1210567BaEB9c714272c9f61B, 149740 * (10 ** 18));
    addMember(0xDB252f9D8Bd0Cb0bB83df4E50870977c771C6b50, 26042 * (10 ** 18));
    addMember(0xDc87F026A5d5E37B9AD67321a19802Bb5082cC67, 400000 * (10 ** 18));
    addMember(0xE01b721ef02A550B11DF7e0B3f55809227a4F1B4, 680000 * (10 ** 18));
    addMember(0xe13E61A210724D50F5D39cd3f8b08955993E9309, 80000 * (10 ** 18));
    addMember(0xe2D9a70307383072f18bf9D0eff9Cb98d1278777, 600000 * (10 ** 18));
    addMember(0xe81CF8A8F052B6dd9dFfF452a593e5638A4097ee, 109375 * (10 ** 18));
    addMember(0xEC80389aF763b4d141b1AD2a1E8579f8B5500fAF, 560000 * (10 ** 18));
    addMember(0xF568705D7A1Df478CF6118420fA482B71092Ca66, 156250 * (10 ** 18));
    addMember(0xF662482E8196Fb5e4f680964263A5bA618E295A7, 149740 * (10 ** 18));
    addMember(0xF84FB7E6d21364B4F919Cab2A205Af70ae86f013, 800000 * (10 ** 18));
    addMember(0xF9Cd27047e11DdDb93C5623a97b49278B1443576, 110677 * (10 ** 18));
    addMember(0xF9d41D1409cdf2AfD629ab437760Bb41260CC81D, 20833 * (10 ** 18));
    addMember(0xFbAEF91d25e3cfad0aDef2F9C43f9eC957615E43, 680000 * (10 ** 18));
    addMember(0xfe5e823c967476bC4cFB8D84Dfaf6699A76062F4, 140625 * (10 ** 18));
    setAllocateTokenDone();
  }
	
  // callable by team member only, after specified time
  function withdrawTokens() external {		
    require(now > firstUnlockDate);
		Member storage member = members[msg.sender];
		require(member.tokenRemain > 0 && member.isRejected == false);

    uint256 amount = 0;
    if(now > thirdUnlockDate) {
      // withdrew all remain token in third stage
      amount = member.tokenRemain;      
    } else if(now > secondUnlockDate && member.withdrawStage == 1) {
      // withdrew 30% in second stage
      amount = member.tokenAmount * 30 / 100;
    } else if(now > firstUnlockDate && member.withdrawStage == 0){
      // withdrew 20% in first stage
      amount = member.tokenAmount * 20 / 100;
    }

    if(amount > 0) {
			member.tokenRemain = member.tokenRemain.sub(amount);      
			member.withdrawStage = member.withdrawStage + 1;      
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      return;
    }

    revert();
  }  

  function rejectWithdrawal(address _memberAddress) external onlyApprover {
		Member storage member = members[_memberAddress];
    require(member.lastRejecter != msg.sender);
		require(member.tokenRemain > 0 && member.isRejected == false);

    //have a admin reject member before
    if(member.lastRejecter != address(0)) {      
			member.isRejected = true;
		}

    member.lastRejecter = msg.sender;
    emit RejectedWithdrawal(msg.sender, _memberAddress, member.withdrawStage);
  }

	function canBurn(address _memberAddress) external view returns(bool) {
		Member memory member = members[_memberAddress];
		if(member.tokenRemain > 0) return member.isRejected;
		return false;
	}

	function getMemberTokenRemain(address _memberAddress) external view returns(uint256) {
		Member memory member = members[_memberAddress];
		if(member.tokenRemain > 0) return member.tokenRemain;
		return 0;
	}	

	function burnMemberToken(address _memberAddress) external onlyCreator() {
		Member storage member = members[_memberAddress];
		require(member.tokenRemain > 0 && member.isRejected);
		member.tokenRemain = 0;
	}	
}