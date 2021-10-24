//const {expect} = require('chai');
//const {expectRevert} = require('./utils');

const hre = require("hardhat");
const L2BBS_ADDRESS ='0x5FbDB2315678afecb367f032d93F642f64180aa3';
const L1BBS_ADDRESS ='0x0E801D84Fa97b50751Dbf25036d067dCf18858bF';
const WEI2USD = 0.00000041/100000000;
const EXCHANGE_RATE_DATE = '24/10/2021'

let accounts;
let gasPrice;
let registry;
let bbsTokenL2;
let operator1;


describe('L2 optimism testing', () => {
  before(async() => {
     accounts = await ethers.getSigners();

     //get gas price
     //const l2RpcProvider = new ethers.providers.JsonRpcProvider('http://localhost:8545')
     //const key = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' //
     const l2RpcProvider = new ethers.providers.JsonRpcProvider('https://mainnet.optimism.io');//'https://kovan.optimism.io')
     const key =   '0xe013c13dcf62b53cbe070b00a6886924f58d944d2b43b4aa4050adde3bf7b8e3' //MY WORK METAMASK KEY
     const l2Wallet = new ethers.Wallet(key,l2RpcProvider)
     gasPrice = (await l2Wallet.provider.getGasPrice()).toNumber();

     console.log ("gas price:", gasPrice, " Estimated at ", gasPrice * WEI2USD , "$" );
  });

    it('Deploy registery contract', async() => {
      const Registry = await hre.ethers.getContractFactory("Registry");
      registry = await Registry.deploy();
      await registry.deployed();
      console.log("registry deployed:", registry.address);
    });

    it('Deploy operator contract ', async() => {
      // Deploy OperatorContract for Dweb
      const OperatorContract = await hre.ethers.getContractFactory("OperatorContract");
      operator1 = await OperatorContract.deploy(L2BBS_ADDRESS, registry.address);
      await operator1.deployed();
      console.log("operator1 (dWeb) deployed:", operator1.address);
    });

    it('Execute register dweb', async() => {
      console.log ("callTXandGas -> registry.registerDweb():" );
      await callTXandGas (registry.estimateGas.registerDweb, operator1.address);
      await registry.registerDweb(operator1.address);
    });

    it('Execute register user', async() => {
      console.log ("callTXandGas -> registry.registerUser:");
      await callTXandGas (registry.estimateGas.registerUser, operator1.address, "user1@domain1");
      await registry.registerUser(operator1.address, "user1@domain1");
    });

    it('Execute addComunity (in operator contract & registery)', async() => {
      console.log ("callTXandGas -> operatorContract.addComunity:");
      await callTXandGas (operator1.estimateGas.addComunity, "TST", "user1@domain1", 20, accounts[8].address, accounts[9].address);
      await operator1.addComunity("TST", "user1@domain1", 20, accounts[8].address, accounts[9].address);
    });

    it('Chack balance in accounts before roilties', async() => {
      const erc20L2Artifact = require('../node_modules/@eth-optimism/contracts/artifacts-ovm/contracts/optimistic-ethereum/libraries/standards/L2StandardERC20.sol/L2StandardERC20.json')
      bbsTokenL2 = await hre.ethers.getContractAt(erc20L2Artifact.abi, L2BBS_ADDRESS, accounts[0]);

      console.log ("callTXandGas -> (single) bbsTokenL2.balanceOf:");
      await callTXandGas (bbsTokenL2.estimateGas.balanceOf, accounts[8].address);
      console.log("Dweb balance (operator & DWEB):", (await bbsTokenL2.balanceOf(operator1.address)).toNumber());
      console.log("Community owner balance:", (await bbsTokenL2.balanceOf(accounts[8].address)).toNumber());
      console.log("Cashier balance:", (await bbsTokenL2.balanceOf(accounts[9].address)).toNumber());
    });

    it('Execute user1@domain1 approving to operator1 transfer (to buy CT)', async() => {
      console.log ("callTXandGas -> bbsTokenL2.approve:");
      await callTXandGas (bbsTokenL2.estimateGas.approve, operator1.address, 10);
      await bbsTokenL2.approve(operator1.address, 10);
    });

    it('Execute user1@domain1 buying community tokens (roilties)', async() => {
      bbsTokenL2 = bbsTokenL2.connect(accounts[8]);
      console.log ("callTXandGas -> operator1.buyCommunityTokens:");
      await callTXandGas (operator1.estimateGas.buyCommunityTokens,"TST", 10, accounts[0].address, "user1@domain1");
      await operator1.buyCommunityTokens("TST", 10, accounts[0].address, "user1@domain1");
    });

    it('Chack balance in accounts after roilties', async() => {
      console.log ("callTXandGas -> (single) bbsTokenL2.balanceOf:");
      await callTXandGas (bbsTokenL2.estimateGas.balanceOf, accounts[8].address);
      console.log("Dweb balance (operator & DWEB):", (await bbsTokenL2.balanceOf(operator1.address)).toNumber());
      console.log("Community owner balance:", (await bbsTokenL2.balanceOf(accounts[8].address)).toNumber());
      console.log("Cashier balance:", (await bbsTokenL2.balanceOf(accounts[9].address)).toNumber());
    });

    it('Execute queue exchange request val={2|3|4}', async() => {
      console.log ("callTXandGas -> (single) operator1.queueExchangeRequest:");
      await callTXandGas (operator1.estimateGas.queueExchangeRequest, "TST", 2, accounts[8].address, "user1@domain1");
      await operator1.queueExchangeRequest("TST", 2, accounts[8].address, "user1@domain1");
      await operator1.queueExchangeRequest("TST", 3, accounts[8].address, "user1@domain1");
      await operator1.queueExchangeRequest("TST", 4, accounts[8].address, "user1@domain1");
      console.log("TST community cashierQ nextQAdd, nextQExchange", (await operator1.communities('TST')).nextQAdd.toNumber() , (await operator1.communities('TST')).nextQExchange.toNumber());
    });

    it('Execute cashier approving transfer to operator1 (to buy BBS)', async() => {
      bbsTokenL2 = bbsTokenL2.connect(accounts[9]);
      console.log ("callTXandGas -> bbsTokenL2.approve:");
      await callTXandGas (bbsTokenL2.estimateGas.approve, operator1.address, 5);
      await bbsTokenL2.approve(operator1.address, 5);
    });

    it('Execute queue requests', async() => {
      console.log ("callTXandGas -> operator1.ExecuteQueueRequests:");
      await callTXandGas (operator1.estimateGas.ExecuteQueueRequests, "TST");
      const executedFromQ = await operator1.ExecuteQueueRequests("TST");
      console.log("Community owner balance (bbs buyer):", (await bbsTokenL2.balanceOf(accounts[8].address)).toNumber());
      console.log("Cashier balance (bbs seller):", (await bbsTokenL2.balanceOf(accounts[9].address)).toNumber());
      console.log("TST Q nextQAdd, nextQExchange", (await operator1.communities('TST')).nextQAdd.toNumber() , (await operator1.communities('TST')).nextQExchange.toNumber());
    });



});


async function callTXandGas() {
  //console.log (arguments);
  [func, ...args] = arguments;
  const gasCost = (await func(...args)).toNumber();
  console.log ("Gas costs = ", gasCost * gasPrice , " Estimated at ", gasCost * gasPrice * WEI2USD , "$", EXCHANGE_RATE_DATE);
}
