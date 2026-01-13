// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
interface IPAIR {
    function getReserves()
        external
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external returns (address);
    function token1() external returns (address);
    function price0CumulativeLast() external returns (uint);
    function price1CumulativeLast() external returns (uint);
}
