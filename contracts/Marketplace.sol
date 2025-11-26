// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Marketplace {
    struct Item {
        string name;
        uint256 price;
        address seller;
        bool sold;
    }

    Item[] public items;

    event ItemListed(uint256 indexed itemId, string name, uint256 price);
    event ItemSold(uint256 indexed itemId, address buyer);

    function listItem(string memory _name, uint256 _price) public {
        items.push(Item(_name, _price, msg.sender, false));
        emit ItemListed(items.length - 1, _name, _price);
    }

    function buyItem(uint256 _itemId) public payable {
        require(_itemId < items.length, "Invalid item");
        Item storage item = items[_itemId];
        require(!item.sold, "Item already sold");
        require(msg.value >= item.price, "Insufficient funds");

        item.sold = true;
        payable(item.seller).transfer(item.price);
        emit ItemSold(_itemId, msg.sender);
    }
}
