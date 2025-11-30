// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract QueueSystem {
    struct QueueItem {
        address user;
        uint256 joinedAt;
        bool processed;
    }

    QueueItem[] public queue;
    uint256 public entryFee;
    address public owner;

    event UserJoined(uint256 indexed position, address user);
    event ItemProcessed(uint256 indexed position, address user);
    event FeeUpdated(uint256 newFee);

    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
    }

    function joinQueue() public payable {
        require(msg.value >= entryFee, "Insufficient fee");
        queue.push(QueueItem(msg.sender, block.timestamp, false));
        emit UserJoined(queue.length - 1, msg.sender);

        if (msg.value > entryFee) {
            payable(msg.sender).transfer(msg.value - entryFee);
        }
    }

    function processNext() public {
        require(msg.sender == owner, "Only owner");
        require(queue.length > 0, "Queue empty");

        for (uint256 i = 0; i < queue.length; i++) {
            if (!queue[i].processed) {
                queue[i].processed = true;
                emit ItemProcessed(i, queue[i].user);
                return;
            }
        }
    }

    function getQueueLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < queue.length; i++) {
            if (!queue[i].processed) {
                count++;
            }
        }
        return count;
    }

    function getPosition(address _user) public view returns (int256) {
        uint256 position = 0;
        for (uint256 i = 0; i < queue.length; i++) {
            if (!queue[i].processed) {
                if (queue[i].user == _user) {
                    return int256(position);
                }
                position++;
            }
        }
        return -1;
    }

    function updateFee(uint256 _newFee) public {
        require(msg.sender == owner, "Only owner");
        entryFee = _newFee;
        emit FeeUpdated(_newFee);
    }
}
