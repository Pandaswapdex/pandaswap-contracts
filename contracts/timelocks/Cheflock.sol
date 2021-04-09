// SPDX-License-Identifier: MIT
// Based off yeild yak timelock, because of the simplicity <3


pragma solidity ^0.6.12;

import "../MasterChefV2.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    MasterChefV2 public CHEF;
    address public pendingOwner;
    enum Functions { transferOwnership, emergencyWithdraw, add, set}
    mapping(Functions => uint) public timelock;

    constructor(address _CHEF) public {
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
        CHEF.massUpdatePools();
    }

    function proposeSetPool(uint256 _pid, uint256 _allocPoint) external onlyManager setTimelock(Functions.set, TIME_BEFORE_SET_POOL_EXECUTION) {
        PROPOSED_SET_POOL_allocPoint = _allocPoint;
        PROPOSED_SET_POOL_pid = _pid;
        
    }
    function executeSetPool(uint256 _pid, uint256 _allocPoint) external enforceTimelock(Functions.set) {
        CHEF.set(_pid, _allocPoint, false);
        CHEF.massUpdatePools();
    }
}
