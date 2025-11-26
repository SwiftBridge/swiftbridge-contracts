// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract GiftCard {
    struct Card {
        uint256 balance;
        bool active;
    }

    mapping(bytes32 => Card) public cards;

    event CardCreated(bytes32 indexed codeHash, uint256 amount);
    event CardRedeemed(bytes32 indexed codeHash, address redeemer, uint256 amount);

    function createCard(bytes32 _codeHash) public payable {
        require(msg.value > 0, "No value");
        require(!cards[_codeHash].active, "Hash exists");
        
        cards[_codeHash] = Card(msg.value, true);
        emit CardCreated(_codeHash, msg.value);
    }

    function redeem(string memory _code) public {
        bytes32 codeHash = keccak256(bytes(_code));
        require(cards[codeHash].active, "Invalid or inactive card");
        
        uint256 amount = cards[codeHash].balance;
        cards[codeHash].active = false;
        cards[codeHash].balance = 0;
        
        payable(msg.sender).transfer(amount);
        emit CardRedeemed(codeHash, msg.sender, amount);
    }
}
