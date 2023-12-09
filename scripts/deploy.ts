import hre, { ethers } from "hardhat";
import BigNumber from "ethers";

async function main() {
 const USDC = await ethers.getContractFactory("EzPay");
//  console.dir(USDC)
//  const usdc = await USDC.deploy();
//  await usdc.waitForDeployment();

//  console.log('EzPay deployed at', usdc.target);

 await verifyContract("EzPay", "0x41f13e048F658f8dBbAe7eB7841630A9ec8AaD78");
}

async function verifyContract(contractName: any, contractAddress: any, constructorArguments = []) {
  console.log(`Verifying ${contractName} at ${contractAddress}...`);
  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArguments,
  });
  console.log(`${contractName} verified successfully!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
