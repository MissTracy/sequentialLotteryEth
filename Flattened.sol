// Sources flattened with hardhat v2.28.6 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v4.9.6

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.9.6

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.9.6

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


// File contracts/VRFV2PlusClient.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

library VRFV2PlusClient {
    struct RandomWordsRequest {
        bytes32 keyHash;
        uint256 subId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        bytes extraArgs;
    }
    struct ExtraArgsV1 { bool nativePayment; }
    function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ExtraArgsV1(bool)")), extraArgs);
    }
}


// File contracts/VRFConsumerBaseV2_5.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

interface IVRFCoordinatorV2_5 {
    function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256);
}

abstract contract VRFConsumerBaseV2_5 {
    address internal immutable s_vrfCoordinator;
    constructor(address _vrfCoordinator) { s_vrfCoordinator = _vrfCoordinator; }
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == s_vrfCoordinator, "Only coordinator can fulfill");
        fulfillRandomWords(requestId, randomWords);
    }
}


// File contracts/SequentialLottery.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.19;




contract SequentialLottery is VRFConsumerBaseV2_5, Ownable, ReentrancyGuard {
    uint256 public ticketPrice = 0.001 ether;
    uint256 public roundId = 1;
    uint256 s_subscriptionId; // Updated to uint256 for v2.5

    struct Ticket {
        address player;
        uint8[] numbers;
    }

    struct Round {
        Ticket[] tickets;
        uint8[] drawnNumbers;
        bool isCompleted;
        uint256 prizePool;
    }

    mapping(uint256 => Round) public rounds;
    mapping(address => uint256) public pendingWithdrawals;

    bytes32 keyHash;
    uint32 callbackGasLimit = 500000;

    event TicketPurchased(address indexed player, uint8[] numbers);
    event NumbersDrawn(uint256 indexed roundId, uint8[] numbers);
    event Winner(address indexed player, uint256 amount, uint8 matches);

    constructor(address vrfCoordinator, bytes32 _keyHash, uint256 subscriptionId) 
        VRFConsumerBaseV2_5(vrfCoordinator) 
    {
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

    function buyTicket(uint8[] calldata _numbers) external payable nonReentrant {
        require(_numbers.length == 7, "7 numbers required");
        require(msg.value == ticketPrice, "Incorrect ETH");
        
        rounds[roundId].tickets.push(Ticket(msg.sender, _numbers));
        rounds[roundId].prizePool += msg.value;
        emit TicketPurchased(msg.sender, _numbers);
    }

    function requestDraw() external onlyOwner {
        require(rounds[roundId].tickets.length > 0, "No tickets");
        
        IVRFCoordinatorV2_5(s_vrfCoordinator).requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: 3,
                callbackGasLimit: callbackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }


    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint8[] memory drawn = new uint8[](7);
        for (uint8 i = 0; i < 7; i++) {
            drawn[i] = uint8((uint256(keccak256(abi.encode(randomWords, i))) % 49) + 1);
        }
        
        rounds[roundId].drawnNumbers = drawn;
        _distributePrizes(roundId);
        rounds[roundId].isCompleted = true;
        emit NumbersDrawn(roundId, drawn);
        roundId++;
    }

    function _distributePrizes(uint256 _roundId) internal {
        Round storage round = rounds[_roundId];
        uint256 ownerShare = (round.prizePool * 30) / 100;
        pendingWithdrawals[owner()] += ownerShare;

        uint256 remainingPool = round.prizePool - ownerShare;

        for (uint256 i = 0; i < round.tickets.length; i++) {
            uint8 matches = _countSequentialMatches(round.tickets[i].numbers, round.drawnNumbers);
            uint256 prize = 0;

            if (matches == 7) prize = (remainingPool * 30) / 100;
            else if (matches == 6) prize = (remainingPool * 20) / 100;
            else if (matches == 5) prize = (remainingPool * 15) / 100;
            else if (matches == 4) prize = (remainingPool * 10) / 100;
            else if (matches == 2 || matches == 3) prize = (remainingPool * 5) / 100;

            if (prize > 0) {
                pendingWithdrawals[round.tickets[i].player] += prize;
                emit Winner(round.tickets[i].player, prize, matches);
            }
        }
    }

    function _countSequentialMatches(uint8[] memory ticket, uint8[] memory drawn) internal pure returns (uint8) {
        uint8 count = 0;
        for (uint8 i = 0; i < 7; i++) {
            if (ticket[i] == drawn[i]) { count++; } else { break; }
        }
        return count;
    }

    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
