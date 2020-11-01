pragma solidity ^0.6.0;

import "./GovernableUpgradeable.sol";

import "../interfaces/IKillable.sol";

abstract contract KillableUpgradeable is IKillable, GovernableUpgradeable {

    bytes32 internal KILLABLE_ROLE;

    bool public _killed;
    uint256 public _killedTimestamp;

    function _init(bytes32 role, bool isSingleton, IAccessControl accessControl) public override virtual {
        KILLABLE_ROLE = keccak256("KILLABLE_ROLE");
        super._init(role, isSingleton, accessControl);

        if (role != ROOT)
            requestRole(KILLABLE_ROLE, address(this), false);
    }

    modifier whenKilled() {
        require(isKilled(), "Contract isn't killed");
        _;
    }

    modifier whenAlive() {
        require(!isKilled(), "Contract is killed");
        _;
    }

    function kill() external override onlyGovernor whenAlive {
        _killed = true;
        _killedTimestamp = now;

        remoteAccessControl.renounceRole(KILLABLE_ROLE, address(this));
    }

    function isKilled() public override view returns (bool) {
        return _killed;
    }

    uint256[50] private ______gap;
}