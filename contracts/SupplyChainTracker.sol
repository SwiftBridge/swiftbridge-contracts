// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SupplyChainTracker {
    struct Product {
        string name;
        address owner;
        bool exists;
    }

    struct Checkpoint {
        uint256 productId;
        string location;
        string status;
        uint256 timestamp;
        address updatedBy;
    }

    mapping(uint256 => Product) public products;
    Checkpoint[] public checkpoints;
    mapping(address => bool) public authorizedParties;
    address public admin;
    uint256 public nextProductId;

    event ProductCreated(uint256 indexed productId, string name, address owner);
    event CheckpointAdded(uint256 indexed checkpointId, uint256 productId, string location, string status);
    event PartyAuthorized(address indexed party);

    constructor() {
        admin = msg.sender;
        authorizedParties[msg.sender] = true;
    }

    function authorizeParty(address _party) public {
        require(msg.sender == admin, "Only admin");
        authorizedParties[_party] = true;
        emit PartyAuthorized(_party);
    }

    function createProduct(string memory _name) public {
        require(authorizedParties[msg.sender], "Not authorized");
        products[nextProductId] = Product(_name, msg.sender, true);
        emit ProductCreated(nextProductId, _name, msg.sender);
        nextProductId++;
    }

    function addCheckpoint(uint256 _productId, string memory _location, string memory _status) public {
        require(authorizedParties[msg.sender], "Not authorized");
        require(products[_productId].exists, "Product doesn't exist");

        checkpoints.push(Checkpoint(_productId, _location, _status, block.timestamp, msg.sender));
        emit CheckpointAdded(checkpoints.length - 1, _productId, _location, _status);
    }

    function getCheckpointsCount() public view returns (uint256) {
        return checkpoints.length;
    }
}
