pragma solidity ^0.6.0;

import "./RemoteAccessControl.sol";

abstract contract Governor is RemoteAccessControl {

    bytes32 internal constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 internal constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    constructor(IAccessControl accessControl) public RemoteAccessControl(GOVERNOR_ROLE, false, accessControl) {
        subscribe(GOVERNANCE_ROLE, GOVERNOR_ROLE);
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "Address doesn't have the governance role");
        _;
    }

    function isGovernance(address addr) public view returns (bool) {
        return hasRole(GOVERNANCE_ROLE, addr);
    }

}