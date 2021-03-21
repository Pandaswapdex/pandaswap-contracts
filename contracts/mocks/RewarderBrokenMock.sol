// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "../interfaces/IRewarder.sol";


contract RewarderBrokenMock is IRewarder {

    function onBambooReward (uint256, address, uint256) override external {
        revert();
    }

    function pendingTokens(uint256 pid, address user, uint256 bambooAmount) override external returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts){
        revert();
    }
  
}