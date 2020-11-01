pragma solidity ^0.6.0;

import "./RemoteAccessControl.sol";

abstract contract Governable is RemoteAccessControl {

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    constructor(bytes32 role, bool isSingleton, IAccessControl accessControl) public RemoteAccessControl(role, isSingleton, accessControl) {
        if (role != ROOT)
            subscribe(GOVERNOR_ROLE, role);
    }

    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "Address doesn't have the governor role");
        _;
    }

    function isGovernor(address addr) public view returns (bool) {
        return hasRole(GOVERNOR_ROLE, addr);
    }

}