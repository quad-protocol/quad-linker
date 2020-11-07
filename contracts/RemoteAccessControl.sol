pragma solidity ^0.6.0;

import "./interfaces/IRemoteAccessControl.sol";

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

abstract contract RemoteAccessControl is IRemoteAccessControl {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Subscription {
        bool isSubscribed;
        bool isSingleton;
    }    
    
    bytes32 constant public ROOT = 0x00;

    IAccessControl public remoteAccessControl;

    mapping(bytes32 => Subscription) private subscriptions;
    mapping(bytes32 => address) private singletons;
    mapping(bytes32 => EnumerableSet.AddressSet) private transients;

    constructor(bytes32 requestedRole, bool isSingleton, IAccessControl accessControl) public {
        remoteAccessControl = accessControl;
        
        if (requestedRole != ROOT)
            requestRole(requestedRole, address(this), isSingleton);
    }

    modifier onlyAccessControl() {
        require(msg.sender == address(remoteAccessControl), "Only AccessControl can call this function");
        _;
    }

    modifier onlyRoot() {
        require(remoteAccessControl.hasRole(ROOT, msg.sender), "Address isn't root");
        _;
    }

    function changeRemoteAccessControl(IAccessControl newAddress) external override onlyAccessControl {
        remoteAccessControl = newAddress;
    }

    function roleGranted(bytes32 role, address target, bool isSingleton) public override onlyAccessControl {
        if (isSingleton)
            singletons[role] = target;
        else
            transients[role].add(target);
    }

    function roleRevoked(bytes32 role, address target) public override onlyAccessControl {
        transients[role].remove(target);
    }

    function requestRole(bytes32 role, address forAddress, bool isSingleton) internal {
        if (isSingleton)
            remoteAccessControl.registerSingleton(role, forAddress);
        else
            remoteAccessControl.register(role, forAddress);
    }

    function subscribeSingleton(bytes32 toRole, bytes32 asRole) internal {
        singletons[toRole] = remoteAccessControl.subscribeSingleton(toRole, asRole);
    }

    function subscribe(bytes32 toRole, bytes32 asRole) internal {
        address[] memory roleMembers = remoteAccessControl.subscribe(toRole, asRole);
        EnumerableSet.AddressSet storage set = transients[toRole];

        for(uint256 i = 0; i < roleMembers.length; i++) {
            set.add(roleMembers[i]);
        }
    }

    function resolve(bytes32 role) internal view returns (EnumerableSet.AddressSet storage) {
        return transients[role];
    }

    function resolveSingleton(bytes32 role) internal view returns (address) {
        return singletons[role];
    }

    function hasRole(bytes32 role, address target) internal view returns (bool) {
        Subscription storage subscription = subscriptions[role];
        //Fallback if the contract isn't subscribed to the role
        if (!subscription.isSubscribed)
            return remoteAccessControl.hasRole(role, target);

        return subscription.isSingleton ? singletons[role] == target : transients[role].contains(target);
    }
}