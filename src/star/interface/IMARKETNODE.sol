pragma solidity 0.8.30;
interface IMARKETNODE {
    function ssdStakeClaimToStartLink(address _user, uint _amount) external;
    function updateHoldPosition(address _user, int _amount) external;
    function getSupervisor(
        address _user
    ) external view returns (address[] memory);
    function supervisor(address _user) external view returns (address);
}
