// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TimeLockVault {
    struct Vault {
        address owner;
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    Vault[] public vaults;
    uint256 public penaltyPercent = 10;
    address public admin;

    event VaultCreated(uint256 indexed vaultId, address owner, uint256 amount, uint256 unlockTime);
    event Withdrawn(uint256 indexed vaultId, uint256 amount, bool early);
    event PenaltyUpdated(uint256 newPercent);

    constructor() {
        admin = msg.sender;
    }

    function createVault(uint256 _lockDuration) public payable {
        require(msg.value > 0, "Amount required");
        require(_lockDuration > 0, "Duration required");

        vaults.push(Vault(msg.sender, msg.value, block.timestamp + _lockDuration, false));
        emit VaultCreated(vaults.length - 1, msg.sender, msg.value, block.timestamp + _lockDuration);
    }

    function withdraw(uint256 _vaultId) public {
        require(_vaultId < vaults.length, "Invalid vault");
        Vault storage vault = vaults[_vaultId];
        require(vault.owner == msg.sender, "Not vault owner");
        require(!vault.withdrawn, "Already withdrawn");

        vault.withdrawn = true;
        uint256 amount = vault.amount;
        bool early = block.timestamp < vault.unlockTime;

        if (early) {
            uint256 penalty = (amount * penaltyPercent) / 100;
            amount -= penalty;
            if (penalty > 0) {
                payable(admin).transfer(penalty);
            }
        }

        payable(msg.sender).transfer(amount);
        emit Withdrawn(_vaultId, amount, early);
    }

    function withdrawAfterUnlock(uint256 _vaultId) public {
        require(_vaultId < vaults.length, "Invalid vault");
        Vault storage vault = vaults[_vaultId];
        require(vault.owner == msg.sender, "Not vault owner");
        require(!vault.withdrawn, "Already withdrawn");
        require(block.timestamp >= vault.unlockTime, "Still locked");

        vault.withdrawn = true;
        payable(msg.sender).transfer(vault.amount);
        emit Withdrawn(_vaultId, vault.amount, false);
    }

    function updatePenalty(uint256 _newPercent) public {
        require(msg.sender == admin, "Only admin");
        require(_newPercent <= 100, "Invalid percent");
        penaltyPercent = _newPercent;
        emit PenaltyUpdated(_newPercent);
    }

    function getVaultCount() public view returns (uint256) {
        return vaults.length;
    }
}
