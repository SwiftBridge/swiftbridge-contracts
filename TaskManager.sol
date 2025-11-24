// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TaskManager {
    struct Task {
        address creator;
        string description;
        address assignee;
        bool completed;
        uint256 timestamp;
    }

    Task[] public tasks;

    event TaskCreated(address indexed creator, address assignee);
    event BatchTasksCreated(address indexed creator, uint256 count);

    function createTask(string memory _description, address _assignee) public {
        tasks.push(Task(msg.sender, _description, _assignee, false, block.timestamp));
        emit TaskCreated(msg.sender, _assignee);
    }

    function batchCreateTasks(string[] memory _descriptions, address[] memory _assignees) public {
        require(_descriptions.length == _assignees.length, "Length mismatch");
        for (uint256 i = 0; i < _descriptions.length; i++) {
            tasks.push(Task(msg.sender, _descriptions[i], _assignees[i], false, block.timestamp));
        }
        emit BatchTasksCreated(msg.sender, _descriptions.length);
    }

    function completeTask(uint256 taskId) public {
        require(taskId < tasks.length, "Invalid task");
        require(tasks[taskId].assignee == msg.sender, "Not assignee");
        tasks[taskId].completed = true;
    }

    function getTaskCount() public view returns (uint256) {
        return tasks.length;
    }
}
