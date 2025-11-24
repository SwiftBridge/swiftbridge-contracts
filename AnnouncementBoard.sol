// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract AnnouncementBoard {
    struct Announcement {
        address announcer;
        string title;
        string content;
        string category;
        uint256 timestamp;
    }

    Announcement[] public announcements;

    event AnnouncementPosted(address indexed announcer, string category);
    event BatchAnnouncementsPosted(address indexed announcer, uint256 count);

    function postAnnouncement(string memory _title, string memory _content, string memory _category) public {
        announcements.push(Announcement(msg.sender, _title, _content, _category, block.timestamp));
        emit AnnouncementPosted(msg.sender, _category);
    }

    function batchPostAnnouncements(
        string[] memory _titles,
        string[] memory _contents,
        string[] memory _categories
    ) public {
        require(_titles.length == _contents.length && _contents.length == _categories.length, "Length mismatch");
        for (uint256 i = 0; i < _titles.length; i++) {
            announcements.push(Announcement(msg.sender, _titles[i], _contents[i], _categories[i], block.timestamp));
        }
        emit BatchAnnouncementsPosted(msg.sender, _titles.length);
    }

    function getAnnouncementCount() public view returns (uint256) {
        return announcements.length;
    }
}
