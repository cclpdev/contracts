// helper function to get the LayerZero endpoint address required by Bridge
let { getLayerZeroAddress } = require("../utils/layerzero")
// import {ethers} from 'hardhat';

function getDependencies() {
    if (hre.network.name === "hardhat") {
        return ["LZEndpointMock", "Router"]
    }
    return ["Router"]
}

// // goerli + polygon
// module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
//     const { deploy } = deployments
//     const { deployer } = await getNamedAccounts()
//
//     let lzAddress
//     console.log(`Network: ${hre.network.name}`)
//     lzAddress = getLayerZeroAddress(hre.network.name)
//
//     let tokenAddr
//     let targetTokenAddr
//     let toChainId
//     if (hre.network.name === "goerli") {
//         tokenAddr = "0xCCde586AD3959725818631f550008CF8471037bB"
//         targetTokenAddr = "0x584911c7acb854eba46e6c23e22cccf9e9e3d942"
//         toChainId = 10109
//     } else if (hre.network.name === "mumbai") {
//         tokenAddr = "0x584911c7acb854eba46e6c23e22cccf9e9e3d942"
//         targetTokenAddr = "0xCCde586AD3959725818631f550008CF8471037bB"
//         toChainId = 10121
//     }
//     // mock lending A
//     lendMockAAddress = await deploy("LendingMock", {
//         from: deployer,
//         args: [10002],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> LendingMock: ${lendMockAAddress.address}`)
//
//     const lendMockContract = await ethers.getContract("LendingMock");
//
//     // deploy Bridge.sol
//     const bridgeAddr = await deploy("Bridge", {
//         from: deployer,
//         args: [lzAddress, lendMockAAddress.address],
//         // args: [lzAddress.address,lendMockAAddress.address],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> bridgeContract: ${bridgeAddr.address}`)
//
//     const bridgeContract = await ethers.getContract("Bridge");
//
//     await lendMockContract.registerToken(tokenAddr);
//     await lendMockContract.setBridge(bridgeAddr.address);
//
//     await bridgeContract.setSendVersion(3);
//     await bridgeContract.setReceiveVersion(3);
//     await bridgeContract.setGasAmount(toChainId, 0, 200000);
//     await bridgeContract.setGasAmount(toChainId, 1, 200000);
//     await bridgeContract.registerTokenMap(toChainId, tokenAddr, targetTokenAddr);
//
//     // await bridgeContract.setBridge();
// }

// goerli + base
module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    let lzAddress
    console.log(`Network: ${hre.network.name}`)
    lzAddress = getLayerZeroAddress(hre.network.name)

    let tokenAddr
    let targetTokenAddr
    let toChainId
    if (hre.network.name === "goerli") {
        tokenAddr = "0xCCde586AD3959725818631f550008CF8471037bB"
        targetTokenAddr = "0x2a73EDc99351488c63538B6016B1fDdb04E4Ca32"
        toChainId = 10160
    } else if (hre.network.name === "base-testnet") {
        tokenAddr = "0x2a73EDc99351488c63538B6016B1fDdb04E4Ca32"
        targetTokenAddr = "0xCCde586AD3959725818631f550008CF8471037bB"
        toChainId = 10121
    }
    // mock lending A
    lendMockAAddress = await deploy("LendingMock", {
        from: deployer,
        args: [10003],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> LendingMock: ${lendMockAAddress.address}`)

    const lendMockContract = await ethers.getContract("LendingMock");

    // deploy Bridge.sol
    const bridgeAddr = await deploy("Bridge", {
        from: deployer,
        args: [lzAddress, lendMockAAddress.address],
        // args: [lzAddress.address,lendMockAAddress.address],
        log: true,
        skipIfAlreadyDeployed: false,
        waitConfirmations: 1,
    })
    console.log(`  -> bridgeContract: ${bridgeAddr.address}`)

    const bridgeContract = await ethers.getContract("Bridge");

    await lendMockContract.registerToken(tokenAddr);
    await lendMockContract.setBridge(bridgeAddr.address);

    if (hre.network.name === "goerli") {
        await bridgeContract.setSendVersion(3);
        await bridgeContract.setReceiveVersion(3);
    }

    await bridgeContract.setGasAmount(toChainId, 0, 200000);
    await bridgeContract.setGasAmount(toChainId, 1, 200000);
    await bridgeContract.registerTokenMap(toChainId, tokenAddr, targetTokenAddr);

    // await bridgeContract.setBridge();
}


// module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
//     const { deploy } = deployments
//     const { deployer } = await getNamedAccounts()
//
//     let lzAddress
//     console.log(`Network: ${hre.network.name}`)
//     // lzAddress = getLayerZeroAddress(hre.network.name)
//     // mock lending A
//     lendMockAAddress = await deploy("LendingMock", {
//         from: deployer,
//         args: [10001],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> LendingMock: ${lendMockAAddress.address}`)
//
//     const lendMockAContract = await ethers.getContract("LendingMock");
//
//     // mock lending B
//     lendMockBAddress = await deploy("LendingMock", {
//         from: deployer,
//         args: [10102],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> LendingMock: ${lendMockBAddress.address}`)
//
//     const lendMockBContract = await ethers.getContract("LendingMock");
//
//     // mock
//     lzAddress = await deploy("LZEndpointMock", {
//         from: deployer,
//         args: [10001],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> LayerZeroEndpoint: ${lzAddress.address}`)
//
//     const lzAddressFrom = await ethers.getContract("LZEndpointMock");
//
//     // let router = await ethers.getContract("Router")
//
//     // deploy Bridge.sol
//     const bridgeContract = await deploy("Bridge", {
//         from: deployer,
//         // args: [lzAddress.address],
//         args: [lzAddress.address,lendMockAAddress.address],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> bridgeContract: ${bridgeContract.address}`)
//
//     const bridgeContractFrom = await ethers.getContract("Bridge");
//
//     // mock
//     lzAddressTarget = await deploy("LZEndpointMock", {
//         from: deployer,
//         args: [10102],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> LayerZeroEndpointTarget: ${lzAddressTarget.address}`)
//     const lzAddressTo = await ethers.getContract("LZEndpointMock");
//
//     const bridgeContractTarget = await deploy("Bridge", {
//         from: deployer,
//         // args: [lzAddress.address],
//         args: [lzAddressTarget.address,lendMockBAddress.address],
//         log: true,
//         skipIfAlreadyDeployed: false,
//         waitConfirmations: 1,
//     })
//     console.log(`  -> bridgeContractTarget: ${bridgeContractTarget.address}`)
//
//     const bridgeContractTo = await ethers.getContract("Bridge");
//
//     await lzAddressFrom.setDestLzEndpoint(bridgeContractTarget.address, lzAddressTarget.address)
//
//     await lzAddressTo.setDestLzEndpoint(bridgeContract.address, lzAddress.address)
//
//     // registerTokenMap + registerBridgeFrom + registerBridgeTo + registerBridgeCPTo + setBridge + setGasAmount + setSendVersion + setReceiveVersion
//     let cclpToken = "0x584911C7acB854ebA46E6c23e22CccF9E9e3D942"
//     await bridgeContractFrom.registerTokenMap(10102, cclpToken, cclpToken);
//     await bridgeContractTo.registerTokenMap(10001, cclpToken, cclpToken);
//
//     await lendMockAContract.setBridge(bridgeContract.address);
//     await lendMockAContract.registerToken(cclpToken);
//
//     await lendMockBContract.setBridge(bridgeContractTarget.address);
//     await lendMockBContract.registerToken(cclpToken);
//
//     // let prayLuckToken = "0xAe34D0C711967c501e86d5D1766b08c99cf275Ed"
//     // await bridgeContractFrom.registerTokenMap(prayLuckToken, "CP_PrayLuck", "LP_PrxyLuck", 18)
//     // await bridgeContractTo.registerTokenMap(prayLuckToken, "CP_T_PrayLuck", "LP_T_PrxyLuck", 18)
//     //
//     // await bridgeContractFrom.registerBridgeFrom(10102, prayLuckToken, prayLuckToken)
//     // await bridgeContractTo.registerBridgeFrom(10001, prayLuckToken, prayLuckToken)
//     //
//     // await bridgeContractFrom.registerBridgeTo(10102, prayLuckToken, prayLuckToken)
//     // await bridgeContractTo.registerBridgeTo(10001, prayLuckToken, prayLuckToken)
//     //
//     // let cpTokenFrom = await bridgeContractFrom.cpTokenMap(prayLuckToken)
//     // let cpTokenTo = await bridgeContractTo.cpTokenMap(prayLuckToken)
//     //
//     // await bridgeContractFrom.registerBridgeCPTo(10102, cpTokenFrom, cpTokenTo)
//     // await bridgeContractTo.registerBridgeCPTo(10001, cpTokenTo, cpTokenFrom)
//
//     await bridgeContractFrom.setBridge(10102, bridgeContractTarget.address)
//     await bridgeContractTo.setBridge(10001, bridgeContract.address)
//
// }

module.exports.tags = ["Bridge", "test"]
module.exports.dependencies = getDependencies()
