pragma solidity ^0.6.0;

interface IKillable {
    function kill() external;
    function isKilled() external view returns (bool);
}