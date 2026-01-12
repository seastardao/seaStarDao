// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {
    ERC721Enumerable,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
event AssignQualifications(address indexed user);
contract FOUNDNFT is ERC721Enumerable {
    uint public _nextTokenId;
    address public owner;
    mapping(address => uint) public isMint;

    constructor() ERC721("FOUNDNFT", "FOUNDNFT") {
        owner = msg.sender;
    }

    function mint() external {
        address _user = msg.sender;
        require(isMint[_user] > 0, "Already minted");
        for (uint i = 0; i < isMint[_user]; i++) {
            _mint(_user, ++_nextTokenId);
        }
        isMint[_user] = 0;
    }

    function assignQualifications(
        address _user,
        uint _amount
    ) external returns (bool) {
        require(msg.sender == owner, "Not owner");
        isMint[_user] = _amount;
        emit AssignQualifications(_user);
        return true;
    }
    function batchTransfer(address to, uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            transferFrom(msg.sender, to, tokenIds[i]);
        }
    }
    function batchApprove(address to, uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            approve(to, tokenIds[i]);
        }
    }
    function transferShipOwner(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
}
