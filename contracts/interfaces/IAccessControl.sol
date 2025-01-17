// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAccessControl {
    function register(bytes32 role, address account) external;
    function registerSingleton(bytes32 role, address account) external;
    function subscribe(bytes32 role, bytes32 asRole) external returns (address[] memory members);
    function subscribeSingleton(bytes32 role, bytes32 asRole) external returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
