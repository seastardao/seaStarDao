pragma solidity 0.8.30;
interface ISTARNODEWORK {
    function updateHoldPosition(address _user, int _amount) external;
    function ssdStakeClaimToStartLink(address _user, uint _amount) external;
}
