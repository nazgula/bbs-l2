// Plugins
require('@nomiclabs/hardhat-ethers');
require('@eth-optimism/hardhat-ovm');
require("hardhat-tracer");
require("hardhat-gas-reporter");

module.exports = {
  networks: {
    hardhat: {
      accounts: {
        mnemonic: 'test test test test test test test test test test test junk'
      }
    },
    optimism: {
      url: 'http://127.0.0.1:8545',
      accounts: {
        mnemonic: 'test test test test test test test test test test test junk'
      },
      gasPrice: 0,
      ovm: true // This sets the network as using the ovm and ensure contract will be compiled against that.
    },
    optimismL1: {
      url: 'http://127.0.0.1:9545',
      accounts: {
        mnemonic: 'test test test test test test test test test test test junk'
      },
      gasPrice: 0,
      ovm: true // This sets the network as using the ovm and ensure contract will be compiled against that.
    },
    rinkeby: {
      url: "https://eth-mainnet.alchemyapi.io/v2/123abc123abc123abc123abc123abcde",
      accounts: ['0x2654f93ae165050dB4AcCA3CCC2c91CF67c730e2'],
      gasPrice: 15000000,
      ovm: true
    },
    'optimistic-kovan': {
      chainId: 69,
      url: 'https://kovan.optimism.io',
      accounts: ['0x2654f93ae165050dB4AcCA3CCC2c91CF67c730e2'],
      gasPrice: 15000000,
      ovm: true
    }
  },
  solidity: '0.7.6',
  ovm: {
    solcVersion: '0.7.6'
  }
}
