//SPDX-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";


contract DeployRaffle is Script{

    function run() external returns (Raffle){
        vm.startBroadcast();
        Raffle raffle = new Raffle(1 ether);
        vm.stopBroadcast();
        return raffle;
    }
}