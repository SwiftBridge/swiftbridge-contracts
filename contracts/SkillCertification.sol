// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SkillCertification {
    struct Certificate {
        address holder;
        address issuer;
        string skillName;
        uint256 issuedAt;
        bool revoked;
    }

    Certificate[] public certificates;
    mapping(address => bool) public authorizedIssuers;
    address public owner;

    event IssuerAuthorized(address indexed issuer);
    event IssuerRevoked(address indexed issuer);
    event CertificateIssued(uint256 indexed certId, address holder, string skillName);
    event CertificateRevoked(uint256 indexed certId);

    constructor() {
        owner = msg.sender;
        authorizedIssuers[msg.sender] = true;
    }

    function authorizeIssuer(address _issuer) public {
        require(msg.sender == owner, "Only owner");
        authorizedIssuers[_issuer] = true;
        emit IssuerAuthorized(_issuer);
    }

    function revokeIssuer(address _issuer) public {
        require(msg.sender == owner, "Only owner");
        authorizedIssuers[_issuer] = false;
        emit IssuerRevoked(_issuer);
    }

    function issueCertificate(address _holder, string memory _skillName) public {
        require(authorizedIssuers[msg.sender], "Not authorized");
        certificates.push(Certificate(_holder, msg.sender, _skillName, block.timestamp, false));
        emit CertificateIssued(certificates.length - 1, _holder, _skillName);
    }

    function revokeCertificate(uint256 _certId) public {
        require(_certId < certificates.length, "Invalid certificate");
        Certificate storage cert = certificates[_certId];
        require(cert.issuer == msg.sender || msg.sender == owner, "Not authorized");
        require(!cert.revoked, "Already revoked");

        cert.revoked = true;
        emit CertificateRevoked(_certId);
    }

    function getCertificatesCount() public view returns (uint256) {
        return certificates.length;
    }
}
