// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract PredictionMarket {
    struct Market {
        string description;
        uint256 endTime;
        uint256 totalYes;
        uint256 totalNo;
        bool resolved;
        bool outcome;
    }

    struct Bet {
        address bettor;
        uint256 marketId;
        bool prediction;
        uint256 amount;
        bool claimed;
    }

    Market[] public markets;
    Bet[] public bets;
    address public owner;

    event MarketCreated(uint256 indexed marketId, string description, uint256 endTime);
    event BetPlaced(uint256 indexed betId, uint256 marketId, bool prediction, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool outcome);
    event Claimed(uint256 indexed betId, uint256 payout);

    constructor() {
        owner = msg.sender;
    }

    function createMarket(string memory _description, uint256 _duration) public {
        require(msg.sender == owner, "Only owner");
        markets.push(Market(_description, block.timestamp + _duration, 0, 0, false, false));
        emit MarketCreated(markets.length - 1, _description, block.timestamp + _duration);
    }

    function placeBet(uint256 _marketId, bool _prediction) public payable {
        require(_marketId < markets.length, "Invalid market");
        Market storage market = markets[_marketId];
        require(block.timestamp < market.endTime, "Market ended");
        require(!market.resolved, "Market resolved");
        require(msg.value > 0, "Bet amount required");

        if (_prediction) {
            market.totalYes += msg.value;
        } else {
            market.totalNo += msg.value;
        }

        bets.push(Bet(msg.sender, _marketId, _prediction, msg.value, false));
        emit BetPlaced(bets.length - 1, _marketId, _prediction, msg.value);
    }

    function resolveMarket(uint256 _marketId, bool _outcome) public {
        require(msg.sender == owner, "Only owner");
        require(_marketId < markets.length, "Invalid market");
        Market storage market = markets[_marketId];
        require(block.timestamp >= market.endTime, "Market not ended");
        require(!market.resolved, "Already resolved");

        market.resolved = true;
        market.outcome = _outcome;
        emit MarketResolved(_marketId, _outcome);
    }

    function claimWinnings(uint256 _betId) public {
        require(_betId < bets.length, "Invalid bet");
        Bet storage bet = bets[_betId];
        require(bet.bettor == msg.sender, "Not your bet");
        require(!bet.claimed, "Already claimed");

        Market storage market = markets[bet.marketId];
        require(market.resolved, "Market not resolved");
        require(bet.prediction == market.outcome, "Lost bet");

        bet.claimed = true;
        uint256 totalPool = market.totalYes + market.totalNo;
        uint256 winningPool = market.outcome ? market.totalYes : market.totalNo;
        uint256 payout = (bet.amount * totalPool) / winningPool;

        payable(msg.sender).transfer(payout);
        emit Claimed(_betId, payout);
    }
}
