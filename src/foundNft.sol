// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {
    ERC721Enumerable,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
contract FOUNDNFT is ERC721Enumerable {
    uint public _nextTokenId;
    uint public tokenIdTotal = 500;
    address public pool;

    constructor() ERC721("FOUNDNFT", "FOUNDNFT") {
        pool = msg.sender;
    }
    function mint(address _user, uint _count) external {
        require(msg.sender == pool, "Not pool");
        for (uint i = 0; i < _count; i++) {
            uint tokenId = ++_nextTokenId;
            require(tokenId <= tokenIdTotal, "TokenId overflow");
            _mint(_user, tokenId);
        }
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
}
