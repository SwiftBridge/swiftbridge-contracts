// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract LotterySystem {
    struct Lottery {
        uint256 ticketPrice;
        uint256 endTime;
        address[] participants;
        address winner;
        bool drawn;
    }

    Lottery[] public lotteries;
    address public owner;

    event LotteryCreated(uint256 indexed lotteryId, uint256 ticketPrice, uint256 endTime);
    event TicketPurchased(uint256 indexed lotteryId, address participant);
    event WinnerDrawn(uint256 indexed lotteryId, address winner, uint256 prize);

    constructor() {
        owner = msg.sender;
    }

    function createLottery(uint256 _ticketPrice, uint256 _duration) public {
        require(msg.sender == owner, "Only owner");
        address[] memory emptyArray;
        lotteries.push(Lottery(_ticketPrice, block.timestamp + _duration, emptyArray, address(0), false));
        emit LotteryCreated(lotteries.length - 1, _ticketPrice, block.timestamp + _duration);
    }

    function buyTicket(uint256 _lotteryId) public payable {
        require(_lotteryId < lotteries.length, "Invalid lottery");
        Lottery storage lottery = lotteries[_lotteryId];
        require(block.timestamp < lottery.endTime, "Lottery ended");
        require(!lottery.drawn, "Already drawn");
        require(msg.value == lottery.ticketPrice, "Incorrect ticket price");

        lottery.participants.push(msg.sender);
        emit TicketPurchased(_lotteryId, msg.sender);
    }

    function drawWinner(uint256 _lotteryId) public {
        require(msg.sender == owner, "Only owner");
        require(_lotteryId < lotteries.length, "Invalid lottery");
        Lottery storage lottery = lotteries[_lotteryId];
        require(block.timestamp >= lottery.endTime, "Lottery not ended");
        require(!lottery.drawn, "Already drawn");
        require(lottery.participants.length > 0, "No participants");

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, lottery.participants.length))) % lottery.participants.length;
        lottery.winner = lottery.participants[randomIndex];
        lottery.drawn = true;

        uint256 prize = lottery.participants.length * lottery.ticketPrice;
        payable(lottery.winner).transfer(prize);

        emit WinnerDrawn(_lotteryId, lottery.winner, prize);
    }

    function getParticipantCount(uint256 _lotteryId) public view returns (uint256) {
        require(_lotteryId < lotteries.length, "Invalid lottery");
        return lotteries[_lotteryId].participants.length;
    }
}
