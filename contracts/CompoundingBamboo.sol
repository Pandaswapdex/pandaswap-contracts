//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./MasterChefV2.sol";
import "./BambooBar.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CompoundingBamboo is ERC20("CompoundingBamboo", "cBAMBOO"), Ownable {
    using SafeMath for uint;
    uint totalDeposits; 

    // constants
    MasterChefV2 public masterChef;
    BambooBar public Bamboobar;
    IERC20 public sBamboo;
    IERC20 public Bamboo;
    address public thisContract = address(this);
    uint public _totalSupply = uint(totalSupply());
    uint public PID;
    uint public MIN_TOKENS_TO_REINVEST = 20;
    uint public REINVEST_REWARD_BIPS = 500;     // 5%
    uint public ADMIN_FEE_BIPS = 500;           // 5%
    uint constant private BIPS_DIVISOR = 10000;

    event Deposit(address account, uint amount);
    event Withdraw(address account, uint amount);
    event Reinvest(uint newTotalDeposits, uint newTotalSupply);
    event Recovered(address token, uint amount);
    event UpdateAdminFee(uint oldValue, uint newValue);
    event UpdateReinvestReward(uint oldValue, uint newValue);
    event UpdateMinTokensToReinvest(uint oldValue, uint newValue);


    constructor(address _sBamboo, address _Bamboo, address _masterChef, uint _pid) public {
        sBamboo    = IERC20(_sBamboo);
        Bamboo     = IERC20(_Bamboo);
        masterChef = MasterChefV2(_masterChef);
        Bamboobar  = BambooBar(_sBamboo);
        PID = _pid;
        IERC20(_Bamboo).approve(_sBamboo, uint(-1));
        IERC20(_sBamboo).approve(_masterChef, uint(-1));
        IERC20(_Bamboo).approve(thisContract, uint(-1));
        IERC20(_sBamboo).approve(thisContract, uint(-1));}
        
    // make sure caller isn't a contract
    modifier onlyEOA() {
      require(tx.origin == msg.sender, "onlyEOA");
      _;}

    // deposits
    function deposit(uint amount) external {_deposit(amount);}

    function _deposit(uint amount) internal {
        require(amount > 0, "amount too small");
        require(totalDeposits >= _totalSupply, "deposit failed");
        require(sBamboo.approve(thisContract, amount), "approval failed");
        require(sBamboo.transferFrom(msg.sender, address(this), amount), "transferFrom() failed");
        _stakeSBamboo(amount);
        _mint(msg.sender, getSharesinSBamboo(amount));
        totalDeposits = totalDeposits.add(amount);
        emit Deposit(msg.sender, amount);}
        
    // deposit with bamboo
    function depositBamboo(uint amount) external {_deposit(amount);}

    function _depositBamboo(uint amount) internal {
        require(amount > 0, "amount too small");
        require(totalDeposits >= _totalSupply, "deposit failed");
        require(Bamboo.approve(thisContract, amount), "approval failed");
        require(Bamboo.transferFrom(msg.sender, address(this), amount), "transferFrom() failed");        
        _convertBambooToSBamboo(amount);
        _stakeSBamboo(amount);
        _mint(msg.sender, getSharesinSBamboo(amount));
        totalDeposits = totalDeposits.add(amount);
        emit Deposit(msg.sender, amount);}
    
    // withdraws
    function withdraw(uint amount) external {
        uint sBambooAmount = getSBambooForShares(amount);
        if (sBambooAmount > 0) {
        _withdrawSBamboo(sBambooAmount);
        require(sBamboo.transfer(msg.sender, sBambooAmount), "transfer failed");
        _burn(msg.sender, amount);
        totalDeposits = totalDeposits.sub(sBambooAmount);
        emit Withdraw(msg.sender, sBambooAmount);}}

    function _withdrawSBamboo(uint amount) internal {
        require(amount > 0, "amount too low");
        masterChef.withdraw(PID, amount);}

    // get rates of exchange
    function getSharesinSBamboo(uint amount) public view returns (uint) {
        if (_totalSupply.mul(totalDeposits) == 0) {return amount;}
        return amount.mul(_totalSupply).div(totalDeposits);}

    function getSBambooForShares(uint amount) public view returns (uint) {
        if (_totalSupply.mul(totalDeposits) == 0) {return 0;}
        return amount.mul(totalDeposits).div(_totalSupply);}

    // current total pending reward for frontend
    function checkReward() public view returns (uint) {
        uint pendingReward = masterChef.pendingBamboo(PID, address(this));
        uint contractBalance = Bamboo.balanceOf(address(this));
        return pendingReward.add(contractBalance);}

    // internal functionality for staking into the masterchef
    function _stakeSBamboo(uint amount) internal {
        require(amount > 0, "amount too low");
        masterChef.deposit(PID, amount);}

    // Update reinvest minimum earned bamboo threshold
    function updateMinTokensToReinvest(uint newValue) external onlyOwner {
        emit UpdateMinTokensToReinvest(MIN_TOKENS_TO_REINVEST, newValue);
        MIN_TOKENS_TO_REINVEST = newValue;}

    // Update reinvest reward for caller
    function updateReinvestReward(uint newValue) external onlyOwner {
        require(newValue.add(ADMIN_FEE_BIPS) <= BIPS_DIVISOR, "reinvest reward too high");
        emit UpdateReinvestReward(REINVEST_REWARD_BIPS, newValue);
        REINVEST_REWARD_BIPS = newValue;}
    
    // estimate reward from calling reinvest for the frontend
    function estimateReinvestReward() external view returns (uint) {
        uint unclaimedRewards = checkReward();
        if (unclaimedRewards >= MIN_TOKENS_TO_REINVEST) {return unclaimedRewards.mul(REINVEST_REWARD_BIPS).div(BIPS_DIVISOR);}
        return 0;}

    function updateAdminFee(uint newValue) external onlyOwner {
        require(newValue.add(REINVEST_REWARD_BIPS) <= BIPS_DIVISOR, "admin fee too high");
        emit UpdateAdminFee(ADMIN_FEE_BIPS, newValue);
        ADMIN_FEE_BIPS = newValue;}

    function reinvest() external onlyEOA {
        uint unclaimedRewards = checkReward();
        require(unclaimedRewards >= MIN_TOKENS_TO_REINVEST, "MIN_TOKENS_TO_REINVEST");
        // harvests
        masterChef.deposit(PID, 0);
        
        // pays admin
        uint adminFee = unclaimedRewards.mul(ADMIN_FEE_BIPS).div(BIPS_DIVISOR);
        if (adminFee > 0) {require(Bamboo.transfer(owner(), adminFee), "admin fee transfer failed");}
        
        // pays caller
        uint reinvestFee = unclaimedRewards.mul(REINVEST_REWARD_BIPS).div(BIPS_DIVISOR);
        if (reinvestFee > 0) {require(Bamboo.transfer(msg.sender, reinvestFee), "reinvest fee transfer failed");}
        
        // convert rewarded Bamboo to sBamboo, then restakes
        uint sBambooAmount = _convertBambooToSBamboo(unclaimedRewards.sub(adminFee).sub(reinvestFee));
        _stakeSBamboo(sBambooAmount);
        totalDeposits = totalDeposits.add(sBambooAmount);
        emit Reinvest(totalDeposits, _totalSupply);}

    // enters bamboobar, aka swaps bamboo for bamboo
    function _convertBambooToSBamboo(uint amount) internal returns (uint) {
        Bamboobar.enter(amount);}
}
