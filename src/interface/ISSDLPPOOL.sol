pragma solidity ^0.8.30;

interface ISSDLPPOOL {
    function consensusToStake(address _sender, uint _amount) external;
}
