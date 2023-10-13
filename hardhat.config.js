/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-contract-sizer");
require("hardhat-tracer");
require("@primitivefi/hardhat-dodoc");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("hardhat-spdx-license-identifier");

function accounts(chainKey) {
    // return { mnemonic: "test test test test test test test test test test test junk" }
    return [""]
}

module.exports = {
    namedAccounts: {
        deployer: 0,
    },

    // defaultNetwork: "hardhat",
    defaultNetwork: "base-testnet",

    networks: {
        // mainnet: {
        //     url: "http://192.168.0.131",
        //     zksync: false,
        // },
        avalanche: {
            url: "https://api.avax.network/ext/bc/C/rpc",
            chainId: 43114,
        },
        // goerli: {
        //     url: "https://goerli.infura.io/v3/3c3db51db86543c0bae3ffe656d6715c", // The Ethereum Web3 RPC URL (optional).
        //     zksync: false, // disables zksolc compiler
        // },

        // goerli: {
        //     url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161", // public infura endpoint
        //     chainId: 5,
        //     accounts: accounts(),
        // },
        'bsc-testnet': {
            url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
            chainId: 97,
            accounts: accounts(),
        },
        mumbai: {
            url: "https://rpc-mumbai.maticvigil.com/",
            chainId: 80001,
            accounts: accounts(),
        },
        'arbitrum-rinkeby': {
            url: `https://rinkeby.arbitrum.io/rpc`,
            chainId: 421611,
            accounts: accounts(),
        },
        'optimism-kovan': {
            url: `https://kovan.optimism.io/`,
            chainId: 69,
            accounts: accounts(),
        },
        'fantom-testnet': {
            url: `https://rpc.testnet.fantom.network/`,
            chainId: 4002,
            accounts: accounts(),
        },
        'base-testnet': {
            url: `https://base-goerli.public.blastapi.io`,
            // url: `https://api-goerli.basescan.org/api`,
            chainId: 84531,
            accounts: accounts(),
        },
        lineaTestnet: {
            url: `https://rpc.goerli.linea.build/`,
        },
    },
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    contractSizer: {
        alphaSort: false,
        runOnCompile: true,
        disambiguatePaths: false,
    },
    etherscan: {
        // ploygon
        apiKey: "",
    },
};