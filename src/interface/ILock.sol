// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
interface ILock {
    function locking(address account, uint256 lock) external;
}
