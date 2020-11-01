pragma solidity ^0.6.0;

import "./RemoteAccessControlUpgradeable.sol";

abstract contract GovernorUpgradeable is RemoteAccessControlUpgradeable {

    bytes32 internal GOVERNANCE_ROLE;
    bytes32 internal GOVERNOR_ROLE;

    function _init(IAccessControl accessControl) public virtual {
        GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
        GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
        super._init(GOVERNOR_ROLE, false, accessControl);
        subscribe(GOVERNANCE_ROLE, GOVERNOR_ROLE);
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "Address doesn't have the governance role");
        _;
    }

    function isGovernance(address addr) public view returns (bool) {
        return hasRole(GOVERNANCE_ROLE, addr);
    }

    uint256[50] private ______gap;
}