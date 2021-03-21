pragma solidity 0.6.12;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/math/SafeMath.sol";


contract BambooBar is ERC20("BambooBar", "xBAMBOO"){
    using SafeMath for uint256;
    IERC20 public bamboo;

    constructor(IERC20 _bamboo) public {
        bamboo = _bamboo;
    }

    // Enter the bar. Pay some BAMBOOs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalBamboo = bamboo.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalBamboo == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalBamboo);
            _mint(msg.sender, what);
        }
        bamboo.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your BAMBOOs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(bamboo.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        bamboo.transfer(msg.sender, what);
    }
}