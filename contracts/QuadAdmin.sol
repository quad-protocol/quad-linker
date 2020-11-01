pragma solidity ^0.6.0;

import "./AccessControl.sol";

import "./interfaces/IRemoteAccessControl.sol";

contract QuadAdmin is AccessControl {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleType {
        bool exists;
        bool isSingleton;
    }

    mapping(bytes32 => EnumerableSet.AddressSet) private _subscribers;
    mapping(bytes32 => RoleType) private _roleTypes;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAuthorized(bytes32 role) {
        bytes32 adminRole = getRoleAdmin(role);
        require(hasRole(adminRole, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, tx.origin), "Not authorized");
        _;
    }

    function grantRole(bytes32 role, address account) public override onlyAuthorized(role) {
        register(role, account);
    }

    function register(bytes32 role, address account) public onlyAuthorized(role) {
        RoleType storage roleType = _roleTypes[role];

        require(!roleType.isSingleton, "Role is singleton");
        if (!roleType.exists) 
            roleType.exists = true;

        _grantRole(role, account);
        _propagateGrant(role, account, false);
    }

    function registerSingleton(bytes32 role, address account) public onlyAuthorized(role) {
        RoleType storage roleType = _roleTypes[role];

        if (roleType.exists) {
            require(roleType.isSingleton, "Role isn't singleton");
            _revokeRole(role, getRoleMember(role, 0));
        }
        else {
            roleType.exists = true;
            roleType.isSingleton = true;
        }

        _grantRole(role, account);
        _propagateGrant(role, account, true);
    }

    function revokeRole(bytes32 role, address account) public override onlyAuthorized(role) {
        RoleType storage roleType = _roleTypes[role];

        require(roleType.exists, "Unknown role");
        require(!roleType.isSingleton, "Cannot revoke a singleton");

        _revokeRole(role, account);
        _propagateRevoke(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyAuthorized(role) {
        _setRoleAdmin(role, adminRole);
    }

    function getRoleMembers(bytes32 role) public view returns (address[] memory members) {
        uint256 roleLength = getRoleMemberCount(role);
        members = new address[](roleLength);

        for (uint256 i = 0; i < roleLength; i++) {
            members[i] = getRoleMember(role, i);
        }
    }

    function subscribe(bytes32 role, bytes32 asRole) external returns (address[] memory members) {
        require(hasRole(asRole, msg.sender), "Address doesn't have role");
        RoleType storage roleType = _roleTypes[role];

        require(!roleType.isSingleton, "Role is singleton");
        
        if (!roleType.exists) 
            roleType.exists = true;
        
        return _subscribe(role);
    }
    //during a non-existent singleton subscription we are setting isSignleton to true
    //without setting exists, this is done as a way to "reserve the signleton spot"
    //in case someone tries to register a non-signleton role with tthe same name as the
    //singleton one because it gets created. 
    function subscribeSingleton(bytes32 role, bytes32 asRole) external returns (address) {
        require(hasRole(asRole, msg.sender), "Address doesn't have role");
        RoleType storage roleType = _roleTypes[role];

        address[] memory members = _subscribe(role);
        if (roleType.exists) {
            require(roleType.isSingleton, "Role isn't singleton");
            return members[0];
        }
        else {
            roleType.isSingleton = true;
            return address(0);
        }
    }

    function _subscribe(bytes32 role) internal returns (address[] memory members) {
        _subscribers[role].add(msg.sender);

        return getRoleMembers(role);
    }

    function _propagateGrant(bytes32 role, address account, bool isSingleton) internal {
        EnumerableSet.AddressSet storage subscribers = _subscribers[role];

        for (uint256 i = 0; i < subscribers.length(); i++) {
            IRemoteAccessControl(subscribers.at(i)).roleGranted(role, account, isSingleton);
        }
    }

    function _propagateRevoke(bytes32 role, address account) internal {
        EnumerableSet.AddressSet storage subscribers = _subscribers[role];

        for (uint256 i = 0; i < subscribers.length(); i++) {
            IRemoteAccessControl(subscribers.at(i)).roleRevoked(role, account);
        }
    }
}
