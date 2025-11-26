async function main() {
  console.log("🚀 Completing ReplyMessages Contract...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH\n");

  const contractAddress = "0x2B31ED427d3e6Ee2235CF8d88E93bE946D144E47";
  console.log("ReplyMessages:", contractAddress, "\n");

  const ReplyMessages = await ethers.getContractFactory("ReplyMessages");
  const contract = ReplyMessages.attach(contractAddress).connect(deployer);

  let txCount = 0;

  for (let i = 0; i < 20; i++) {
    try {
      const tx = await contract.sendMessage(0, `Reply ${i + 1}`);
      await tx.wait();
      txCount++;
      console.log(`  ✓ ${i + 1}/20 - Reply message sent`);
    } catch (error) {
      console.log(`  ✗ ${i + 1}/20 - Error:`, error.message.substring(0, 50));
    }
  }

  console.log(`\n✅ Completed ${txCount} interactions`);

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Final Balance: ${ethers.formatEther(finalBalance)} ETH\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
