// helper function to get the LayerZero endpoint address required by Bridge
let { getLayerZeroAddress } = require("../utils/layerzero")
// import {ethers} from 'hardhat';

function getDependencies() {
    if (hre.network.name === "hardhat") {
        return ["LZEndpointMock", "Router"]
    }
    return ["Router"]
}

module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    let lzAddress
    console.log(`Network: ${hre.network.name}`)
    // lzAddress = getLayerZeroAddress(hre.network.name)
    // mock lending A
    lendMockAAddress = await deploy("LendingMock", {
        from: deployer,
        args: [10001],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> LendingMock: ${lendMockAAddress.address}`)

    const lendMockAContract = await ethers.getContract("LendingMock");

    // mock lending B
    lendMockBAddress = await deploy("LendingMock", {
        from: deployer,
        args: [10102],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> LendingMock: ${lendMockBAddress.address}`)

    const lendMockBContract = await ethers.getContract("LendingMock");

    // mock
    lzAddress = await deploy("LZEndpointMock", {
        from: deployer,
        args: [10001],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> LayerZeroEndpoint: ${lzAddress.address}`)

    const lzAddressFrom = await ethers.getContract("LZEndpointMock");

    // let router = await ethers.getContract("Router")

    // deploy Bridge.sol
    const bridgeContract = await deploy("Bridge", {
        from: deployer,
        // args: [lzAddress.address],
        args: [lzAddress.address,lendMockAAddress.address],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> bridgeContract: ${bridgeContract.address}`)

    const bridgeContractFrom = await ethers.getContract("Bridge");

    // mock
    lzAddressTarget = await deploy("LZEndpointMock", {
        from: deployer,
        args: [10102],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> LayerZeroEndpointTarget: ${lzAddressTarget.address}`)
    const lzAddressTo = await ethers.getContract("LZEndpointMock");

    const bridgeContractTarget = await deploy("Bridge", {
        from: deployer,
        // args: [lzAddress.address],
        args: [lzAddressTarget.address,lendMockBAddress.address],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> bridgeContractTarget: ${bridgeContractTarget.address}`)

    const bridgeContractTo = await ethers.getContract("Bridge");

    await lzAddressFrom.setDestLzEndpoint(bridgeContractTarget.address, lzAddressTarget.address)

    await lzAddressTo.setDestLzEndpoint(bridgeContract.address, lzAddress.address)

    // registerTokenMap + registerBridgeFrom + registerBridgeTo + registerBridgeCPTo + setBridge + setGasAmount + setSendVersion + setReceiveVersion
    let cclpToken = "0x584911C7acB854ebA46E6c23e22CccF9E9e3D942"
    await bridgeContractFrom.registerTokenMap(10102, cclpToken, cclpToken);
    await bridgeContractTo.registerTokenMap(10001, cclpToken, cclpToken);

    await lendMockAContract.setBridge(bridgeContract.address);

    await lendMockBContract.setBridge(bridgeContractTarget.address);

    // let prayLuckToken = "0xAe34D0C711967c501e86d5D1766b08c99cf275Ed"
    // await bridgeContractFrom.registerTokenMap(prayLuckToken, "CP_PrayLuck", "LP_PrxyLuck", 18)
    // await bridgeContractTo.registerTokenMap(prayLuckToken, "CP_T_PrayLuck", "LP_T_PrxyLuck", 18)
    //
    // await bridgeContractFrom.registerBridgeFrom(10102, prayLuckToken, prayLuckToken)
    // await bridgeContractTo.registerBridgeFrom(10001, prayLuckToken, prayLuckToken)
    //
    // await bridgeContractFrom.registerBridgeTo(10102, prayLuckToken, prayLuckToken)
    // await bridgeContractTo.registerBridgeTo(10001, prayLuckToken, prayLuckToken)
    //
    // let cpTokenFrom = await bridgeContractFrom.cpTokenMap(prayLuckToken)
    // let cpTokenTo = await bridgeContractTo.cpTokenMap(prayLuckToken)
    //
    // await bridgeContractFrom.registerBridgeCPTo(10102, cpTokenFrom, cpTokenTo)
    // await bridgeContractTo.registerBridgeCPTo(10001, cpTokenTo, cpTokenFrom)

    await bridgeContractFrom.setBridge(10102, bridgeContractTarget.address)
    await bridgeContractTo.setBridge(10001, bridgeContract.address)

}

module.exports.tags = ["Bridge", "test"]
module.exports.dependencies = getDependencies()
