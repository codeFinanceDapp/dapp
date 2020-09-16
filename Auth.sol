pragma solidity 0.4.25;

contract Auth {

  address internal owner;
  address internal trigger;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event TriggerUpdated(address indexed _newTrigger);

  constructor(
    address _owner,
    address _trigger
  ) internal {
    owner = _owner;
    trigger = _trigger;
  }

  modifier onlyOwner() {
    require(isOwner(), '401');
    _;
  }

  modifier onlyTrigger() {
    require(isTrigger() || isOwner(), '401');
    _;
  }

  function _transferOwnership(address _newOwner) onlyOwner internal {
    require(_newOwner != address(0x0));
    owner = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function _newTrigger(address _trigger) onlyOwner internal {
    require(_trigger != address(0x0));
    trigger = _trigger;
    emit TriggerUpdated(_trigger);
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function isTrigger() public view returns (bool) {
    return msg.sender == trigger;
  }
}
