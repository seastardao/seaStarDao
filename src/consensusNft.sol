// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {
    ERC721Enumerable,
    ERC721
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
contract CONSENSUSNFT is ERC721Enumerable {
    uint256 public _nextTokenId;
    address public consensus;
    constructor(address _consensus) ERC721("ConsensusNFT", "CNFT") {
        consensus = _consensus;
    }
    function mintNft(address _user) external returns (uint) {
        require(_nextTokenId < 2000, "Max supply");
        require(msg.sender == consensus, "Not consensus");
        uint256 tokenId = ++_nextTokenId;
        _mint(_user, tokenId);
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
}
