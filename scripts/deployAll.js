import fs from 'fs';

const contracts = [
  "BatchMessenger",
  "SocialFeed",
  "GroupChat",
  "AnnouncementBoard",
  "VotingMessages",
  "EventBoard",
  "TaskManager",
  "NotificationHub",
  "CommentSystem",
  "ReviewBoard",
  "AnonymousBoard",
  "PollSystem",
  "TimedMessages",
  "ReplyMessages",
  "TipJar",
  "ModeratedForum",
  "BadgeSystem",
  "MultiSigMessages",
  "StreamMessages",
  "TagSystem"
];

async function main() {
  console.log("🚀 Deploying 20 Contracts to Base Sepolia...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH\n");

  const deployedContracts = [];

  for (let i = 0; i < contracts.length; i++) {
    const contractName = contracts[i];
    console.log(`\n[${i + 1}/20] Deploying ${contractName}...`);

    try {
      const Contract = await ethers.getContractFactory(contractName);
      const contract = await Contract.deploy();
      await contract.waitForDeployment();

      const address = await contract.getAddress();
      console.log(`✅ ${contractName} deployed at: ${address}`);

      deployedContracts.push({
        name: contractName,
        address: address
      });
    } catch (error) {
      console.error(`❌ Failed to deploy ${contractName}:`, error.message);
    }
  }

  // Save addresses to file
  const outputPath = './deployedContracts.json';
  fs.writeFileSync(outputPath, JSON.stringify(deployedContracts, null, 2));
  console.log(`\n📝 Contract addresses saved to ${outputPath}`);

  console.log("\n✅ All deployments complete!");
  console.log("\n📋 Summary:");
  deployedContracts.forEach((contract, i) => {
    console.log(`${i + 1}. ${contract.name}: ${contract.address}`);
  });

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`\n💰 Remaining balance: ${ethers.formatEther(finalBalance)} ETH`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
