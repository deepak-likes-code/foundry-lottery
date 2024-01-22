//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script{


    function run () external returns (uint64){
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig()public returns (uint64){
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,,) = helperConfig.activeConfig();

    return createSubscription(vrfCoordinator);

    }

    function createSubscription(address vrfCoordinator) public returns (uint64){
        console.log("Creating Subscription on ChainID: %s", block.chainid);
        vm.startBroadcast();
        uint64 subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID: %s", subscriptionId);
        return subscriptionId;
    }
}