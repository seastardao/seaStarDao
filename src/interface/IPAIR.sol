pragma solidity 0.8.30;
interface IPAIR {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
    function token0() external view returns (address);
}
