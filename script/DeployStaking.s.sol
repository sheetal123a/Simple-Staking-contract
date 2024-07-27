// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/Staking.sol";
import "../src/StakeToken.sol";
import "../src/RewardToken.sol";

contract DeployStaking is Script {
    function run() external {
       
        uint256 initialSupply = 1000000; 
        uint256 rewardRate = 1e18; 
    

       
        vm.startBroadcast();

      RewardToken rewardToken = new RewardToken(initialSupply);
        StakeToken stakeToken = new StakeToken(initialSupply);

        // Deploy Staking contract with deployer as initial owner
        Staking stakingContract = new Staking(
            address(stakeToken),
            address(rewardToken),
            rewardRate
        );

      
        vm.stopBroadcast();


         console.log("Stake Token deployed to:", address(stakeToken));
        console.log("Reward Token deployed to:", address(rewardToken));
        console.log("Staking contract deployed to:", address(stakingContract));
    }
}
