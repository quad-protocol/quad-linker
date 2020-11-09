const Migrations = artifacts.require("Migrations");

const QuadAdmin = artifacts.require("QuadAdmin");

module.exports = async function (deployer, network) {
    await deployer.deploy(Migrations);

    //network test skips migrations
    if (network == "test")
        return;

    await deployer.deploy(QuadAdmin);

};
