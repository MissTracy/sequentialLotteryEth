// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract SequentialLottery is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    uint256 public ticketPrice = 0.001 ether;
    uint8 public constant MAX_BALL = 49;
    uint256 public roundId = 1;
    uint256 public constant ROUND_DURATION = 2 minutes; 

    struct Ticket {
        address player;
        uint8[] numbers;
    }

    struct Round {
        Ticket[] tickets;
        uint8[] drawnNumbers;
        bool isCompleted;
        uint256 prizePool;
        uint256 startTime;
        mapping(address => uint256) winnings;
    }

    mapping(uint256 => Round) private rounds;
    mapping(uint256 => uint256) public roundWinnersCount;

    // Chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;

    event TicketPurchased(address indexed player, uint8[] numbers);
    event NumbersRequested(uint256 roundId, uint256 requestId);
    event NumbersDrawn(uint8[] numbers);
    event PrizeDistributed(uint256 roundId);
    event Winner(
    uint256 indexed roundId,
    address indexed player,
    uint256 prize,
    uint8 matches,
    );


    constructor(
        address vrfCoordinator,
        bytes32 _keyHash,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

    function buyTicket(uint8[] calldata _numbers) external payable nonReentrant {
        require(_numbers.length ==7, "Must select exactly 7 numbers");
        for (uint8 i = 0; i < 7; i++) {
            require(_numbers[i] >= 1 && _numbers[i] <= MAX_BALL, "Numbers must be 1-49");
        // Check duplicates
        for (uint8 j = i + 1; j < 7; j++) {
            require(_numbers[i] != _numbers[j], "Duplicate numbers not allowed");
        }
        }
    }


        require(msg.value == ticketPrice, "Invalid ETH sent");

        Round storage round = rounds[roundId];

        // Start round once ticket purch
        if (round.tickets.length == 0) {
            round.startTime = block.timestamp;
        }

        // Auto-check round expiration
        if (!round.isCompleted && block.timestamp >= round.startTime + ROUND_DURATION) {
            _triggerDraw();
        }

        // Add ticket
        round.tickets.push(Ticket(msg.sender, _numbers));
        round.prizePool += msg.value;

        emit TicketPurchased(msg.sender, _numbers);
    }

    //vrf draw
    function _triggerDraw() internal {
        Round storage round = rounds[roundId];
        require(round.tickets.length > 0, "No tickets sold");
        require(!round.isCompleted, "Round already completed");

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 
        );

        emit NumbersRequested(roundId, requestId);
    }
    //  where random num unit256 random array valuesuted auto
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        Round storage round = rounds[roundId];
        require(!round.isCompleted, "Round already completed");

        uint8[] memory pool = new uint8[](MAX_BALL);

        //  Initialize pool 1-49
        for (uint8 i = 0; i < MAX_BALL; i++) {
            pool[i] = i + 1;
        }

        // Use VRF word to pick 7 unique numbers
        uint256 randomness = randomWords[0]; 
        // uint8 ;

        for (uint8 i = 0; i < 7; i++) {
            // Pick random index from remaining pool
            uint256 index = uint256(keccak256(abi.encode(randomness, i))) % (MAX_BALL - i);

            // Swap chosen number to the end of pool
            drawn[i] = pool[index];
            pool[index] = pool[MAX_BALL - 1 - i];
        }

        // Save drawn numbers
        round.drawnNumbers = drawn;
        round.isCompleted = true;

        emit NumbersDrawn(drawn);

        // Distribute prizes automatically
        _distributePrizes(roundId);
    }


    function _distributePrizes(uint256 _roundId) internal {
        Round storage round = rounds[_roundId];
        uint256 pool = round.prizePool;
        uint256 ownerShare = (pool * 30) / 100;
        payable(owner()).transfer(ownerShare);
        uint256 remainingPool = pool - ownerShare;

        for (uint256 i = 0; i < round.tickets.length; i++) {
            Ticket storage ticket = round.tickets[i];
            uint8 matched = _countSequentialMatches(ticket.numbers, round.drawnNumbers);
            uint256 prize = 0;

            if (matched == 2 || matched == 3) prize = (remainingPool * 5) / 100;
            else if (matched == 4) prize = (remainingPool * 10) / 100;
            else if (matched == 5) prize = (remainingPool * 15) / 100;
            else if (matched == 6) prize = (remainingPool * 20) / 100;
            else if (matched == 7) prize = (remainingPool * 30) / 100;

            if (prize > 0) {
                payable(ticket.player).transfer(prize);
                roundWinnersCount[_roundId]++;

            emit Winner(
                _roundId,
                ticket.player,
                prize,
                matched
            );
        }

        }

        // Roll over if no winners
        uint256 nextRoundId = _roundId + 1;
        if (roundWinnersCount[_roundId] == 0) {
            rounds[nextRoundId].prizePool = remainingPool;
        }

        roundId = nextRoundId;
        emit PrizeDistributed(_roundId);
    }

    //match by sequence
    function _countSequentialMatches(uint8[] memory ticket, uint8[] memory drawn) internal pure returns (uint8) {
        uint8 count = 0;
        uint8 minLength = ticket.length < drawn.length ? uint8(ticket.length) : uint8(drawn.length);
        for (uint8 i = 0; i < minLength; i++) {
            if (ticket[i] == drawn[i]) count++;
            else break;
        }
        return count;
    }

    //view func
    function getPoolBalance(uint256 _roundId) external view returns (uint256) {
        return rounds[_roundId].prizePool;
    }

    function getTickets(uint256 _roundId) external view returns (Ticket[] memory) {
        return rounds[_roundId].tickets;
    }

    function getDrawnNumbers(uint256 _roundId) external view returns (uint8[] memory) {
        return rounds[_roundId].drawnNumbers;
    }

    function getRoundStartTime(uint256 _roundId) external view returns (uint256) {
        return rounds[_roundId].startTime;
    }
}
