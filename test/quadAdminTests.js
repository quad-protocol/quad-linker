const QuadAdmin = artifacts.require("QuadAdmin");

const RemoteAccessControl = artifacts.require("RemoteAccessControlMock");
const truffleAssert = require("truffle-assertions");

const { expect } = require("chai");

contract("QuadAdmin", addresses => {

    let owner = addresses[0];
    let random = addresses[1];

    beforeEach(async () => {
        this.quadAdmin = await QuadAdmin.new({ from: owner });
        this.remoteAccess = await RemoteAccessControl.new(this.quadAdmin.address);
        this.testRole = web3.utils.soliditySha3("TEST_ROLE");
    });

    it("shouldn't allow a random address to register or subscribe", async () => {
        await truffleAssert.reverts(
            this.quadAdmin.register(this.testRole, random, { from: random }), "Not authorized"
        );

        await truffleAssert.reverts(
            this.quadAdmin.registerSingleton(this.testRole, random, { from: random }), "Not authorized"
        );

        await truffleAssert.reverts(
            this.quadAdmin.subscribe(this.testRole, this.testRole, { from: random }), "Address doesn't have role"
        );

        await truffleAssert.reverts(
            this.quadAdmin.subscribeSingleton(this.testRole, this.testRole, { from: random }), "Address doesn't have role"
        );
    });

    it("should allow the owner to register a role", async () => {
        await truffleAssert.passes(
            this.quadAdmin.register(this.testRole, this.remoteAccess.address, { from: owner })
        );
    });

    it("should allow a role member to subscribe to a transient", async () => {
        await truffleAssert.passes(
            this.quadAdmin.register(this.testRole, this.remoteAccess.address, { from: owner })
        );
        
        await truffleAssert.passes(
            this.remoteAccess._subscribe(this.testRole, this.testRole)
        );

        expect(await this.remoteAccess._resolve(this.testRole)).deep.equal([this.remoteAccess.address]);
    });

    it("should allow a role member to subscribe to a singleton", async () => {
        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(this.testRole, this.remoteAccess.address, { from: owner })
        );

        await truffleAssert.passes(
            this.remoteAccess._subscribeSingleton(this.testRole, this.testRole)
        );

        expect(await this.remoteAccess._resolveSingleton(this.testRole)).equal(this.remoteAccess.address);
    });

    it("shouldn't allow transient subscription to a singleton", async () => {
        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(this.testRole, this.remoteAccess.address, { from: owner })
        );

        await truffleAssert.reverts(
            this.remoteAccess._subscribe(this.testRole, this.testRole), "Role is singleton"
        );
    });

    it("shouldn't allow singleton subscription to a transient", async () => {
        await truffleAssert.passes(
            this.quadAdmin.register(this.testRole, this.remoteAccess.address, { from: owner })
        );

        await truffleAssert.reverts(
            this.remoteAccess._subscribeSingleton(this.testRole, this.testRole), "Role isn't singleton"
        );
    });

    it("should allow subscriptions before a singleton is created", async () => {
        await truffleAssert.passes(
            this.quadAdmin.register(this.testRole, this.remoteAccess.address, { from: owner })
        );

        let testSingleton = web3.utils.soliditySha3("TEST_SINGLETON");

        await truffleAssert.passes(
            this.remoteAccess._subscribeSingleton(testSingleton, this.testRole)
        );

        expect(await this.remoteAccess._resolveSingleton(testSingleton)).equal("0x0000000000000000000000000000000000000000");

        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(testSingleton, this.remoteAccess.address, { from: owner })
        );

        expect(await this.remoteAccess._resolveSingleton(testSingleton)).equal(this.remoteAccess.address);

    });

    it("should allow subscriptions before a transient is created", async () => {
        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(this.testRole, this.remoteAccess.address, { from: owner })
        );

        let testTransient = web3.utils.soliditySha3("TEST_TRANSIENT");

        await truffleAssert.passes(
            this.remoteAccess._subscribe(testTransient, this.testRole)
        );

        expect(await this.remoteAccess._resolve(testTransient)).deep.equal([]);

        await truffleAssert.passes(
            this.quadAdmin.register(testTransient, this.remoteAccess.address, { from: owner })
        );

        expect(await this.remoteAccess._resolve(testTransient)).deep.equal([this.remoteAccess.address]);
    });

    it("should be able to override a singleton", async () => {
        await truffleAssert.passes(
            this.quadAdmin.register(this.testRole, this.remoteAccess.address, { from: owner })
        );

        let testSingleton = web3.utils.soliditySha3("TEST_SINGLETON");

        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(testSingleton, random, { from: owner })
        );

        await truffleAssert.passes(
            this.remoteAccess._subscribeSingleton(testSingleton, this.testRole)
        );

        expect(await this.remoteAccess._resolveSingleton(testSingleton)).equal(random);

        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(testSingleton, owner, { from: owner })
        );

        expect(await this.remoteAccess._resolveSingleton(testSingleton)).equal(owner);
    });

    it("should be able to revoke a transient", async () => {
        await truffleAssert.passes(
            this.quadAdmin.register(this.testRole, this.remoteAccess.address, { from: owner })
        );

        let testTransient = web3.utils.soliditySha3("TEST_TRANSIENT");

        await truffleAssert.passes(
            this.quadAdmin.register(testTransient, random, { from: owner })
        );

        await truffleAssert.passes(
            this.remoteAccess._subscribe(testTransient, this.testRole)
        );

        expect(await this.remoteAccess._resolve(testTransient)).deep.equal([random]);

        await truffleAssert.passes(
            this.quadAdmin.revokeRole(testTransient, random, { from: owner })
        );

        expect(await this.remoteAccess._resolve(testTransient)).deep.equal([]);
    });

    it("shouldn't be able to revoke a singleton", async () => {
        let testSingleton = web3.utils.soliditySha3("TEST_SINGLETON");
        
        await truffleAssert.passes(
            this.quadAdmin.registerSingleton(testSingleton, this.remoteAccess.address, { from: owner })
        );

        await truffleAssert.reverts(
            this.quadAdmin.revokeRole(testSingleton, this.remoteAccess.address, { from: owner }), "Cannot revoke a singleton"
        );
    });

});