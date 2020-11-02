const Migrations = artifacts.require("Migrations");

const QuadAdmin = artifacts.require("QuadAdmin");

module.exports = async function (deployer, network) {
    //network test skips migrations
    if (network == "test")
        return;

    await deployer.deploy(Migrations);

    await deployer.deploy(QuadAdmin);

};
