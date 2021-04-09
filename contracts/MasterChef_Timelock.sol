// SPDX-License-Identifier: MIT
// Based off yeild yak timelock, because of the simplicity <3


pragma solidity ^0.6.12;

import "../../libraries/IERC20.sol";

interface IChef {
    function add(uint256 _allocPoint,IERC20 _lpToken,bool _withUpdate) public;
    function set(uint256 _pid,uint256 _allocPoint,bool _withUpdate);
    function massUpdatePools() public;
}

contract ChefLock {
    // constants
    uint256 public PROPOSED_ADD_POOL_allocPoint;
    IERC20 public PROPOSED_ADD_POOL_lpToken; // needs import
    uint256 public PROPOSED_SET_POOL_pid;
    uint256 public PROPOSED_SET_POOL_allocPoint;

    //---------------------------------------------------------------

    uint public constant TIME_BEFORE_SET_POOL_EXECUTION = 12 hours;
    uint public constant TIME_BEFORE_ADD_POOL_EXECUTION = 12 hours;
    uint public constant TIME_BEFORE_OWNERSHIP_TRANSFER = 2 days;
    
    //---------------------------------------------------------------
    address public manager;
    IChef public CHEF;
    address public pendingOwner;
    enum Functions { transferOwnership, emergencyWithdraw, add, set}
    mapping(Functions => uint) public timelock;

    constructor(address _CHEF) {
        manager = msg.sender;
        CHEF = IChef(_CHEF);}

    // modifiers
    modifier onlyManager {require(msg.sender == manager);_;}
    modifier setTimelock(Functions _fn, uint timelockLength) {timelock[_fn] = block.timestamp + timelockLength;_;}
    modifier enforceTimelock(Functions _fn) {require(timelock[_fn] != 0 && timelock[_fn] <= block.timestamp, "Yak Based Timelock::enforceTimelock");_;timelock[_fn] = 0;}
    

    // transferOwnership functionality
    function proposeOwner(address _pendingOwner) external onlyManager setTimelock(Functions.transferOwnership, TIME_BEFORE_OWNERSHIP_TRANSFER) {
        pendingOwner = _pendingOwner;}
    
    function executeSetNewOwner() external enforceTimelock(Functions.transferOwnership) {
        CHEF.transferOwnership(pendingOwner);
        pendingOwner = address(0);}// whats this mean?
    

    function proposeAddPool(uint256 _allocPoint, IERC20 _lpToken) external onlyManager setTimelock(Functions.add, TIME_BEFORE_ADD_POOL_EXECUTION) {
        PROPOSED_ADD_POOL_allocPoint = _allocPoint;
        PROPOSED_ADD_POOL_lpToken = _lpToken;
    }
    function executeAddPool() external enforceTimelock(Functions.add) {
        CHEF.add(PROPOSED_ADD_POOL_allocPoint, PROPOSED_ADD_POOL_lpToken, false);
        massUpdatePools();
    }

    function proposeSetPool(uint256 _pid,uint256 _allocPoint) external onlyManager setTimelock(Functions.set, TIME_BEFORE_SET_POOL_EXECUTION) {
        PROPOSED_SET_POOL_allocPoint = _allocPoint;
        PROPOSED_SET_POOL_pid = _lpToken;
    }
    function executeSetPool(uint256 _pid,uint256 _allocPoint) external enforceTimelock(Functions.set) {
        CHEF.set(_pid, _allocPoint, false);
        massUpdatePools();
    }
}
