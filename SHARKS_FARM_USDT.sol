pragma solidity 0.4.25;

import './Auth.sol';
import './SafeMath.sol';
import './ITRC20.sol';

contract SHARKS_FARM_USDT is Auth {
  using SafeMath for uint;

  struct Farmer {
    uint deposited;
    uint claimable;
    uint claimed;
    bool haveJoined;
    uint lastJoined;
    uint leave;
  }

  mapping(address => Farmer) farmers;
  address[] farmerAddresses;
  uint public farmSize = 270219 * (10 ** uint256(5)); // 3% totalSupply
  uint public claimable = farmSize;
  bool public canJoin = true;
  uint public sharksRate = 3000000;
  uint percentInDecimal6 = 10 ** uint256(6);
  uint secondsIn30Minute = 1800;

  ITRC20 sharksToken = ITRC20(0xfBA7c10ab41df6fcdF415879Fb1a2fcD9aEAeCbE);
  ITRC20 usdtToken = ITRC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

  event Joined(address indexed farmer, uint amount);
  event Leave(address indexed farmer, uint amount);
  event Claimed(address indexed farmer, uint amount);

  constructor(address _trigger)
  public
  Auth(msg.sender, _trigger) {}

  function join(uint _amount) public {
    require(canJoin, 'Sorry, Farm is closed now');
    require(usdtToken.transferFrom(msg.sender, address(this), _amount), 'Let approve first');
    Farmer storage farmer = farmers[msg.sender];
    if (!farmer.haveJoined) {
      farmerAddresses.push(msg.sender);
      farmer.haveJoined = true;
    }
    farmer.lastJoined = now;
    farmer.deposited = farmer.deposited.add(_amount);
    emit Joined(msg.sender, _amount);
  }

  function reward(uint _from, uint _to) onlyTrigger public {
    require(_from < _to && _to <= farmerAddresses.length, 'Invalid value');
    for(uint i = _from; i < _to; i++) {
      Farmer storage farmer = farmers[farmerAddresses[i]];
      if (farmer.deposited > 0 && now - farmer.lastJoined > secondsIn30Minute) {
        uint farmerClaimEstimated = farmer.deposited.mul(percentInDecimal6).div(1600).div(sharksRate); // 24 * 2 * 100 / 3
        if (farmerClaimEstimated < claimable) {
          farmer.claimable = farmer.claimable.add(farmerClaimEstimated);
          claimable = claimable.sub(farmerClaimEstimated);
        } else {
          farmer.claimable = farmer.claimable.add(claimable);
          claimable = 0;
        }
      }
    }
  }

  function claim() public {
    Farmer storage farmer = farmers[msg.sender];
    require(farmer.claimable > 0, 'No claimable SHARKS');
    sharksToken.transfer(msg.sender, farmer.claimable);
    farmer.claimed = farmer.claimed.add(farmer.claimable);
    farmer.claimable = 0;
    emit Claimed(msg.sender, farmer.claimable);
  }

  function farmerSize() public view returns (uint) {
    return farmerAddresses.length;
  }

  function stats(address _farmer) public view returns (uint, uint, uint, uint, uint) {
    Farmer storage farmer = farmers[_farmer];
    return (
      farmer.deposited,
      farmer.claimable,
      farmer.claimed,
      farmer.lastJoined,
      farmer.leave
    );
  }

  function myStats() public view returns (uint, uint, uint) {
    Farmer storage farmer = farmers[msg.sender];
    return (
    farmer.deposited,
    farmer.claimable,
    farmer.claimed
    );
  }

  function leave() public {
    Farmer storage farmer = farmers[msg.sender];
    require(farmer.deposited > 0, 'See you in next farm');
    usdtToken.transfer(msg.sender, farmer.deposited);
    farmer.deposited = 0;
    farmer.leave = now;
    if (farmer.claimable > 0 && sharksToken.balanceOf(address(this)) > farmer.claimable) {
      sharksToken.transfer(msg.sender, farmer.claimable);
      farmer.claimable = 0;
    }
    emit Leave(msg.sender, farmer.deposited);
  }

  function openJoin() onlyOwner public {
    canJoin = true;
  }

  function closeJoin() onlyOwner public {
    canJoin = false;
  }

  function transferOwnership(address _newOwner) public {
    _transferOwnership(_newOwner);
  }

  function finish(address _finisher) onlyOwner public {
    sharksToken.transfer(_finisher, sharksToken.balanceOf(address(this)));
    usdtToken.transfer(_finisher, usdtToken.balanceOf(address(this)));
  }

  function newTrigger(address _trigger) onlyOwner public {
    _newTrigger(_trigger);
  }

  function sharksUsdt(uint _sharksUsdt) onlyOwner public {
    sharksRate = _sharksUsdt;
  }
}
