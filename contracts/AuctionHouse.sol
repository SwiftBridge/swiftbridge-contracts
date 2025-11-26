// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract AuctionHouse {
    struct Auction {
        string item;
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool ended;
    }

    Auction[] public auctions;

    event AuctionCreated(uint256 indexed auctionId, string item, uint256 endTime);
    event NewBid(uint256 indexed auctionId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 amount);

    function createAuction(string memory _item, uint256 _duration) public {
        auctions.push(Auction(_item, msg.sender, 0, address(0), block.timestamp + _duration, false));
        emit AuctionCreated(auctions.length - 1, _item, block.timestamp + _duration);
    }

    function bid(uint256 _auctionId) public payable {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.highestBid, "Bid too low");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        emit NewBid(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction not ended yet");
        require(!auction.ended, "Auction already ended");

        auction.ended = true;
        if (auction.highestBid > 0) {
            payable(auction.seller).transfer(auction.highestBid);
        }
        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
    }
}
