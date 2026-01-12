// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {
    ERC721Enumerable,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
interface ISTARNODEDATA {
    function starLinkLevel(address _user) external view returns (uint);
}
contract S10NFT is ERC721Enumerable {
    uint public _nextTokenId;
    uint public level = 10;
    address public owner;
    address public starLinkLevel;
    mapping(address => bool) public isMint;
    constructor() ERC721("S10NFT", "S10NFT") {
        owner = msg.sender;
    }
    function setAddress(address _starLinkLevel, uint _level) external {
        require(msg.sender == owner, "Not owner");
        starLinkLevel = _starLinkLevel;
        level = _level;
    }
    function mint() external returns (uint256) {
        address _user = msg.sender;
        uint _level = ISTARNODEDATA(starLinkLevel).starLinkLevel(_user);
        require(_level == level, "Not S10");
        require(!isMint[_user], "Already minted");
        uint256 tokenId = ++_nextTokenId;
        _mint(_user, tokenId);
        isMint[_user] = true;
        return tokenId;
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
    function transferShipOwner(address newOwner) public {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
}
