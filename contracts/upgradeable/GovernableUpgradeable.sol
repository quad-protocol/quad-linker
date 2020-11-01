pragma solidity ^0.6.0;

import "./RemoteAccessControlUpgradeable.sol";

abstract contract GovernableUpgradeable is RemoteAccessControlUpgradeable {

    bytes32 internal GOVERNOR_ROLE;

    function _init(bytes32 role, bool isSingleton, IAccessControl accessControl) public override virtual {
        GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
        super._init(role, isSingleton, accessControl);

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

    uint256[50] private ______gap;
}
