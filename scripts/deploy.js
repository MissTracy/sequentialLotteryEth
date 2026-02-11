import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying SequentialLottery with account:", deployer.address);

  const Lottery = await ethers.getContractFactory("SequentialLottery");

  const lottery = await Lottery.deploy(
    "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B", // VRF Coordinator
    "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae", // keyHash
    12579, // subscriptionId
  );

  await lottery.waitForDeployment();

  console.log("Contract deployed to:", await lottery.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
