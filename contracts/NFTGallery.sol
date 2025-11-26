// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract NFTGallery {
    struct Collection {
        string name;
        address[] nfts;
    }

    mapping(address => Collection) public userCollections;

    event NFTAdded(address indexed user, address nftContract);

    function createCollection(string memory _name) public {
        userCollections[msg.sender].name = _name;
    }

    function addToCollection(address _nftContract) public {
        userCollections[msg.sender].nfts.push(_nftContract);
        emit NFTAdded(msg.sender, _nftContract);
    }

    function getCollection(address _user) public view returns (string memory, address[] memory) {
        return (userCollections[_user].name, userCollections[_user].nfts);
    }
}
