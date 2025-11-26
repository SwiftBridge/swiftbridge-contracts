// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract VestingWallet {
    mapping(address => uint256) public totalVested;
    mapping(address => uint256) public released;
    mapping(address => uint256) public start;
    mapping(address => uint256) public duration;

    event Vested(address indexed beneficiary, uint256 amount);
    event Released(address indexed beneficiary, uint256 amount);

    function addVesting(address _beneficiary, uint256 _start, uint256 _duration) public payable {
        require(msg.value > 0, "No funds");
        totalVested[_beneficiary] += msg.value;
        start[_beneficiary] = _start;
        duration[_beneficiary] = _duration;
        emit Vested(_beneficiary, msg.value);
    }

    function release() public {
        uint256 vested = vestedAmount(msg.sender);
        uint256 releasable = vested - released[msg.sender];
        require(releasable > 0, "Nothing to release");

        released[msg.sender] += releasable;
        payable(msg.sender).transfer(releasable);
        emit Released(msg.sender, releasable);
    }

    function vestedAmount(address _beneficiary) public view returns (uint256) {
        if (block.timestamp < start[_beneficiary]) {
            return 0;
        } else if (block.timestamp >= start[_beneficiary] + duration[_beneficiary]) {
            return totalVested[_beneficiary];
        } else {
            return (totalVested[_beneficiary] * (block.timestamp - start[_beneficiary])) / duration[_beneficiary];
        }
    }
}
