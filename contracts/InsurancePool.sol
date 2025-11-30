// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract InsurancePool {
    struct Policy {
        address holder;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
    }

    struct Claim {
        uint256 policyId;
        uint256 amount;
        bool approved;
        bool processed;
    }

    Policy[] public policies;
    Claim[] public claims;
    address public owner;

    event PolicyCreated(uint256 indexed policyId, address holder, uint256 coverageAmount);
    event ClaimFiled(uint256 indexed claimId, uint256 policyId, uint256 amount);
    event ClaimProcessed(uint256 indexed claimId, bool approved);

    constructor() {
        owner = msg.sender;
    }

    function createPolicy(uint256 _coverageAmount) public payable {
        require(msg.value > 0, "Premium required");
        policies.push(Policy(msg.sender, msg.value, _coverageAmount, true));
        emit PolicyCreated(policies.length - 1, msg.sender, _coverageAmount);
    }

    function fileClaim(uint256 _policyId, uint256 _amount) public {
        require(_policyId < policies.length, "Invalid policy");
        Policy storage policy = policies[_policyId];
        require(policy.holder == msg.sender, "Not policy holder");
        require(policy.active, "Policy not active");
        require(_amount <= policy.coverageAmount, "Exceeds coverage");

        claims.push(Claim(_policyId, _amount, false, false));
        emit ClaimFiled(claims.length - 1, _policyId, _amount);
    }

    function processClaim(uint256 _claimId, bool _approve) public {
        require(msg.sender == owner, "Only owner");
        require(_claimId < claims.length, "Invalid claim");
        Claim storage claim = claims[_claimId];
        require(!claim.processed, "Already processed");

        claim.approved = _approve;
        claim.processed = true;

        if (_approve) {
            Policy storage policy = policies[claim.policyId];
            payable(policy.holder).transfer(claim.amount);
        }

        emit ClaimProcessed(_claimId, _approve);
    }
}
