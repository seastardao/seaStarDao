pragma solidity ^0.8.30;
interface ITOKEN {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function uniswapV2Pair() external view returns (address);
    function mosPair() external view returns (address);
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function marketCapMint(uint256 amount) external;
    function setMarketCapEnabled(bool _marketCapEnabled) external;
}
