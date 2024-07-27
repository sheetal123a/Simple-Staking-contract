// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import  {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;

    uint256 private totalStakedTokens;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userStakeStartTime;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address stakingToken, address rewardToken, uint256 _rewardRate) Ownable(msg.sender) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external  updateReward(msg.sender) {
        require(amount > 0, "Amount must be greater than zero");
        totalStakedTokens += amount;
        stakedBalance[msg.sender] += amount;
        userStakeStartTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer Failed");
    }

    function withdrawStakedTokens(uint256 amount) external  updateReward(msg.sender) {
        require(amount > 0, "Amount must be greater than zero");
        require(stakedBalance[msg.sender] >= amount, "Staked amount not enough");
        totalStakedTokens -= amount;
        stakedBalance[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
        bool success = s_stakingToken.transfer(msg.sender, amount);
        require(success, "Transfer Failed");
    }

    function calculateReward(address account) public view returns (uint256) {
        uint256 stakedAmount = stakedBalance[account];
        if (stakedAmount == 0) {
            return 0;
        }
        uint256 stakedDuration = block.timestamp - userStakeStartTime[account];
        return stakedAmount * rewardRate * stakedDuration / 1e18;
    }

    modifier updateReward(address account) {
        if (stakedBalance[account] > 0) {
            uint256 reward = calculateReward(account);
            rewards[account] += reward;
            userStakeStartTime[account] = block.timestamp;
        }
        lastUpdateTime = block.timestamp;
        _;
    }

    function getReward() external  updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewards[msg.sender] = 0;
        emit RewardsClaimed(msg.sender, reward);
        bool success = s_rewardToken.transfer(msg.sender, reward);
        require(success, "Transfer Failed");
    }
}
