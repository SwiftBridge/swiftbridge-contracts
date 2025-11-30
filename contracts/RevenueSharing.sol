// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract RevenueSharing {
    struct Pool {
        address creator;
        uint256 totalShares;
        bool active;
    }

    struct Shareholder {
        address holder;
        uint256 poolId;
        uint256 shares;
    }

    struct Distribution {
        uint256 poolId;
        uint256 amount;
        uint256 timestamp;
    }

    Pool[] public pools;
    Shareholder[] public shareholders;
    Distribution[] public distributions;
    mapping(uint256 => mapping(address => uint256)) public shareholderIndex;
    mapping(uint256 => mapping(address => uint256)) public claimedAmount;

    event PoolCreated(uint256 indexed poolId, address creator);
    event ShareholderAdded(uint256 indexed poolId, address holder, uint256 shares);
    event RevenueDistributed(uint256 indexed poolId, uint256 amount);
    event RevenueClaimed(uint256 indexed poolId, address holder, uint256 amount);

    function createPool() public {
        pools.push(Pool(msg.sender, 0, true));
        emit PoolCreated(pools.length - 1, msg.sender);
    }

    function addShareholder(uint256 _poolId, address _holder, uint256 _shares) public {
        require(_poolId < pools.length, "Invalid pool");
        Pool storage pool = pools[_poolId];
        require(msg.sender == pool.creator, "Only creator");
        require(pool.active, "Pool not active");
        require(shareholderIndex[_poolId][_holder] == 0, "Already shareholder");

        pool.totalShares += _shares;
        shareholders.push(Shareholder(_holder, _poolId, _shares));
        shareholderIndex[_poolId][_holder] = shareholders.length;

        emit ShareholderAdded(_poolId, _holder, _shares);
    }

    function distributeRevenue(uint256 _poolId) public payable {
        require(_poolId < pools.length, "Invalid pool");
        require(msg.value > 0, "Revenue required");

        distributions.push(Distribution(_poolId, msg.value, block.timestamp));
        emit RevenueDistributed(_poolId, msg.value);
    }

    function claimRevenue(uint256 _poolId) public {
        require(_poolId < pools.length, "Invalid pool");
        Pool storage pool = pools[_poolId];
        uint256 shareholderIdx = shareholderIndex[_poolId][msg.sender];
        require(shareholderIdx > 0, "Not a shareholder");

        Shareholder storage shareholder = shareholders[shareholderIdx - 1];
        uint256 totalRevenue = 0;

        for (uint256 i = 0; i < distributions.length; i++) {
            if (distributions[i].poolId == _poolId) {
                totalRevenue += distributions[i].amount;
            }
        }

        uint256 shareAmount = (totalRevenue * shareholder.shares) / pool.totalShares;
        uint256 claimable = shareAmount - claimedAmount[_poolId][msg.sender];
        require(claimable > 0, "Nothing to claim");

        claimedAmount[_poolId][msg.sender] += claimable;
        payable(msg.sender).transfer(claimable);

        emit RevenueClaimed(_poolId, msg.sender, claimable);
    }
}
