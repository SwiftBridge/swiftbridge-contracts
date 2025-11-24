// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract EventBoard {
    struct Event {
        address organizer;
        string name;
        string description;
        uint256 eventTime;
        uint256 timestamp;
    }

    Event[] public events;

    event EventCreated(address indexed organizer, string name);
    event BatchEventsCreated(address indexed organizer, uint256 count);

    function createEvent(string memory _name, string memory _description, uint256 _eventTime) public {
        events.push(Event(msg.sender, _name, _description, _eventTime, block.timestamp));
        emit EventCreated(msg.sender, _name);
    }

    function batchCreateEvents(
        string[] memory _names,
        string[] memory _descriptions,
        uint256[] memory _eventTimes
    ) public {
        require(_names.length == _descriptions.length && _descriptions.length == _eventTimes.length, "Length mismatch");
        for (uint256 i = 0; i < _names.length; i++) {
            events.push(Event(msg.sender, _names[i], _descriptions[i], _eventTimes[i], block.timestamp));
        }
        emit BatchEventsCreated(msg.sender, _names.length);
    }

    function getEventCount() public view returns (uint256) {
        return events.length;
    }
}
