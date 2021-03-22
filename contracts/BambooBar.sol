// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// BambooBar is the coolest bar in town. You come in with some Bamboo, and leave with more! The longer you stay, the more Bamboo you get.
//
// This contract handles swapping to and from xBamboo, PandaSwap's staking token.
contract BambooBar is ERC20("BambooBar", "sBAMBOO"){
    using SafeMath for uint256;
    IERC20 public bamboo;

    // Define the Bamboo token contract
    constructor(IERC20 _bamboo) public {
        bamboo = _bamboo;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Bamboo and mints xBamboo
    function enter(uint256 _amount) public {
        // Gets the amount of Bamboo locked in the contract
        uint256 totalBamboo = bamboo.balanceOf(address(this));
        // Gets the amount of xBamboo in existence
        uint256 totalShares = totalSupply();
        // If no xBamboo exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalBamboo == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xBamboo the Bamboo is worth. The ratio will change overtime, as xBamboo is burned/minted and Bamboo deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalBamboo);
            _mint(msg.sender, what);
        }
        // Lock the Bamboo in the contract
        bamboo.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Bamboo and burns xBamboo
    function leave(uint256 _share) public {
        // Gets the amount of xBamboo in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Bamboo the xBamboo is worth
        uint256 what = _share.mul(bamboo.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        bamboo.transfer(msg.sender, what);
    }
}
