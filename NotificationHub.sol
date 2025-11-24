// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract NotificationHub {
    struct Notification {
        address sender;
        address recipient;
        string message;
        bool read;
        uint256 timestamp;
    }

    Notification[] public notifications;

    event NotificationSent(address indexed sender, address indexed recipient);
    event BatchNotificationsSent(address indexed sender, uint256 count);

    function sendNotification(address _recipient, string memory _message) public {
        notifications.push(Notification(msg.sender, _recipient, _message, false, block.timestamp));
        emit NotificationSent(msg.sender, _recipient);
    }

    function batchSendNotifications(address[] memory _recipients, string[] memory _messages) public {
        require(_recipients.length == _messages.length, "Length mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            notifications.push(Notification(msg.sender, _recipients[i], _messages[i], false, block.timestamp));
        }
        emit BatchNotificationsSent(msg.sender, _recipients.length);
    }

    function markAsRead(uint256 notifId) public {
        require(notifId < notifications.length, "Invalid notification");
        require(notifications[notifId].recipient == msg.sender, "Not recipient");
        notifications[notifId].read = true;
    }

    function getNotificationCount() public view returns (uint256) {
        return notifications.length;
    }
}
