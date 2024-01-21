//SPDX-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/VRFConsumerBaseV2.sol";

/**
 * @title Raffle
 * @author Deepak
 * @notice This contract is used to create a raffle
 * @dev This contract implements the Chainlink VRF2
 */

contract Raffle is VRFConsumerBaseV2 {
    /**
     * Errors
     */
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 state, uint256 participants);

    /**
     * Type Declarations
     */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * State Variables
     */

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_interval;
    uint256 private s_lastTimeStamp;
    address payable[] private s_participants;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**
     * Events
     */
    event EnteredRaffle(address indexed participant);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        s_interval = _interval;

        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep(bytes memory /*checkData*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool hasTimeInvervalPassed = block.timestamp - s_lastTimeStamp >= s_interval;
        bool isOpenState = s_raffleState == RaffleState.OPEN;
        bool hasParticipants = s_participants.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = hasTimeInvervalPassed && isOpenState && hasParticipants && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    // get a random number -> pick a winner -> automate this process
    function performUpkeep(bytes calldata /*performData*/ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, uint256(s_raffleState), s_participants.length);
        }

        s_raffleState = RaffleState.CALCULATING;

        i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable winner = s_participants[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOf ) external view returns (address ) {
        return s_participants[indexOf];
    }
}
