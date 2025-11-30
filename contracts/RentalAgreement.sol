// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract RentalAgreement {
    struct Agreement {
        address landlord;
        address tenant;
        uint256 monthlyRent;
        uint256 securityDeposit;
        uint256 startDate;
        uint256 endDate;
        bool active;
        uint256 depositReturned;
    }

    Agreement[] public agreements;

    event AgreementCreated(uint256 indexed agreementId, address landlord, address tenant, uint256 monthlyRent);
    event RentPaid(uint256 indexed agreementId, uint256 amount);
    event DepositReturned(uint256 indexed agreementId, uint256 amount);
    event AgreementEnded(uint256 indexed agreementId);

    function createAgreement(address _tenant, uint256 _monthlyRent, uint256 _duration) public payable {
        require(msg.value > 0, "Security deposit required");
        require(_tenant != address(0), "Invalid tenant");

        agreements.push(Agreement(
            msg.sender,
            _tenant,
            _monthlyRent,
            msg.value,
            block.timestamp,
            block.timestamp + _duration,
            true,
            0
        ));

        emit AgreementCreated(agreements.length - 1, msg.sender, _tenant, _monthlyRent);
    }

    function payRent(uint256 _agreementId) public payable {
        require(_agreementId < agreements.length, "Invalid agreement");
        Agreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.tenant, "Not tenant");
        require(agreement.active, "Agreement not active");
        require(msg.value == agreement.monthlyRent, "Incorrect rent amount");

        payable(agreement.landlord).transfer(msg.value);
        emit RentPaid(_agreementId, msg.value);
    }

    function returnDeposit(uint256 _agreementId, uint256 _amount) public {
        require(_agreementId < agreements.length, "Invalid agreement");
        Agreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.landlord, "Only landlord");
        require(block.timestamp >= agreement.endDate, "Agreement not ended");
        require(_amount <= agreement.securityDeposit, "Amount exceeds deposit");
        require(agreement.depositReturned + _amount <= agreement.securityDeposit, "Already returned");

        agreement.depositReturned += _amount;
        payable(agreement.tenant).transfer(_amount);
        emit DepositReturned(_agreementId, _amount);
    }

    function endAgreement(uint256 _agreementId) public {
        require(_agreementId < agreements.length, "Invalid agreement");
        Agreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.landlord, "Only landlord");
        require(agreement.active, "Already ended");

        agreement.active = false;
        emit AgreementEnded(_agreementId);
    }
}
