// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
interface IFACTORY {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}
