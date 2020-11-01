pragma solidity ^0.6.0;

import "./IAccessControl.sol";

interface IRemoteAccessControl {
    function changeRemoteAccessControl(IAccessControl newAddress) external;

    function roleGranted(bytes32 role, address target, bool isSingleton) external;
    function roleRevoked(bytes32 role, address target) external;

}