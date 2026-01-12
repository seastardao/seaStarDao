pragma solidity ^0.8.30;
interface IUSERLINK {
    function getSupervisor(
        address _user,
        uint _index
    ) external view returns (address[] memory);
}
