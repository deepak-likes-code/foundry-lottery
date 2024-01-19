//SPDX-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title Raffle
 * @author Deepak
 * @notice This contract is used to create a raffle
 * @dev This contract implements the Chainlink VRF2
 */

contract Raffle {

  /** Errors */
    error Raffle_NotEnoughEthSent();

/** State Variables */

uint256 private constant REQUEST_CONFIRMATIONS = 3;
uint256 private constant NUM_WORDS = 1;


    uint256 private immutable i_entranceFee;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable  i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;


    uint256 private s_interval; 
    uint256 private s_lastTimeStamp;
    address payable[] public s_participants;


/** Events */
    event EnteredRaffle(address indexed participant);

    constructor(uint256 _entranceFee, uint256 _interval, address _vrfCoordinator, bytes32 _gasLane, uint64 _subscriptionId, uint32 _callbackGasLimit) {
        i_entranceFee = _entranceFee;
        s_interval = _interval;

        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = _vrfCoordinator;
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthSent();
        }
        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }


// get a random number -> pick a winner -> automate this process
    function pickWinner() public {
        if(block.timestamp - s_lastTimeStamp < s_interval){
            revert();
        }

        uint256 requestId= i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
        NUM_WORDS
        );


    }

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
