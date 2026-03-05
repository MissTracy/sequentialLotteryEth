// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VRFV2PlusClient.sol";

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
