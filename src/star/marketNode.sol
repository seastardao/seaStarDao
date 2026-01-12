// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
contract MARKETNODE {
    event BindSupervisor(address indexed _user, address indexed _supervisor);
    mapping(address => address) public supervisor;
    mapping(address => address[]) public subordinates;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    function setUserNode(address _user) public onlyOwner {
        require(_user != address(0), "User is zero address");
        require(supervisor[_user] == address(0), "User has supervisor");
        supervisor[_user] = address(this);
        subordinates[address(this)].push(_user);
    }
    function bindSupervisor(address _supervisor) public {
        address _user = msg.sender;
        require(_supervisor != address(0), "Supervisor is zero address");
        require(
            supervisor[_supervisor] != address(0),
            "Supervisor has no supervisor"
        );
        require(supervisor[_user] == address(0), "Binder supervisor is error");
        supervisor[_user] = _supervisor;
        subordinates[_supervisor].push(_user);
        emit BindSupervisor(_user, _supervisor);
    }
    function getSubordinatesCount(address _user) public view returns (uint) {
        return subordinates[_user].length;
    }
    function getSupervisor(
        address _user
    ) public view returns (address[] memory) {
        uint count;
        address _current = _user;
        for (uint i = 0; i <= 1000; i++) {
            _current = supervisor[_current];
            if (_current == address(0)) {
                break;
            }
            count++;
        }
        count++;

        address[] memory _supervisors = new address[](count);
        _current = _user;
        for (uint i = 0; i < count; i++) {
            _supervisors[i] = _current;
            _current = supervisor[_current];
        }

        return _supervisors;
    }
    function getSubordinates(
        address _user
    ) public view returns (address[] memory) {
        return subordinates[_user];
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is zero address");
        owner = _newOwner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
