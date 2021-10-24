

async function main() {
  const BBSL1 = await hre.ethers.getContractFactory("BBSTokenL1");
  bbsL1 = await BBSL1.deploy();
  await bbsL1.deployed();
  console.log("bbsL1 deployed:", bbsL1.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
