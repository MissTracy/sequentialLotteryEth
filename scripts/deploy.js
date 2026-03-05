const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const vrfCoordinator = "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B";
  const keyHash = "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae";
  const subId = "109319310681203604710033540367421638478046310807095712953269749014357046271836";

  const Lottery = await hre.ethers.getContractFactory("SequentialLottery");
  const lottery = await Lottery.deploy(vrfCoordinator, keyHash, subId);

  await lottery.waitForDeployment();
  console.log("Lottery V2.5 Deployed to:", await lottery.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
