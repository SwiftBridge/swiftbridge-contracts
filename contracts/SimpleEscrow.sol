// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SimpleEscrow {
    struct Escrow {
        address depositor;
        address beneficiary;
        uint256 amount;
        bool released;
    }

    Escrow[] public escrows;

    event EscrowCreated(uint256 indexed escrowId, address depositor, address beneficiary, uint256 amount);
    event Released(uint256 indexed escrowId);

    function deposit(address _beneficiary) public payable {
        escrows.push(Escrow(msg.sender, _beneficiary, msg.value, false));
        emit EscrowCreated(escrows.length - 1, msg.sender, _beneficiary, msg.value);
    }

    function release(uint256 _escrowId) public {
        require(_escrowId < escrows.length, "Invalid escrow");
        Escrow storage e = escrows[_escrowId];
        require(msg.sender == e.depositor, "Only depositor can release");
        require(!e.released, "Already released");

        e.released = true;
        payable(e.beneficiary).transfer(e.amount);
        emit Released(_escrowId);
    }
}
