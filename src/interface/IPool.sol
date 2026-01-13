// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPool {
    function balanceOf(address) external view returns (uint256);
}
