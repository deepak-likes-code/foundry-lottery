//SPDX-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {

    // Events
    event EnteredRaffle(address indexed participant);

    Raffle raffle;
    HelperConfig helperConfig;

    address public PLAYER = makeAddr("Player");
    uint256 public constant ENTRANCE_FEE = 0.25 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant interval = 30;


    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        helperConfig = new HelperConfig();
        raffle = deployRaffle.run();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = helperConfig.activeConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public  {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRafflesRevertsWhenNotEnoughEthSent() public{
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

 function testRaffleRecordsPlayersWhenTheyEnter() public{

    vm.prank(PLAYER);
    raffle.enterRaffle{value:ENTRANCE_FEE}();

    assert(address(raffle.getPlayer(0)) == PLAYER);


 }

 function testRaffleEventEmmitedOnEntrance() public{
    vm.prank(PLAYER);
    vm.expectEmit(true,false,false,false,address(raffle));
    emit EnteredRaffle(PLAYER);
    raffle.enterRaffle{value:ENTRANCE_FEE}();


 }

 function testRaffleRevertWhenCalculating() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value:ENTRANCE_FEE}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("0x00");

    // the state will go into calculating after the upkeep

    vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value:ENTRANCE_FEE}();
 }

}
