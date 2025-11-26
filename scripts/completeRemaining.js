import fs from 'fs';

async function main() {
  console.log("🚀 Completing Remaining Contracts...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH\n");

  const deployedContracts = JSON.parse(fs.readFileSync('./deployedContracts.json', 'utf8'));

  // ReplyMessages (index 12) and TipJar (index 13)
  const missingContracts = [12, 13];
  let totalTxCount = 0;

  for (const idx of missingContracts) {
    const contractInfo = deployedContracts[idx];
    console.log(`\n[${idx + 1}/19] ${contractInfo.name} - ${contractInfo.address}`);

    try {
      const Contract = await ethers.getContractFactory(contractInfo.name);
      const contract = Contract.attach(contractInfo.address).connect(deployer);

      if (contractInfo.name === "ReplyMessages") {
        for (let i = 0; i < 20; i++) {
          const tx = await contract.sendMessage(0, `Reply ${i + 1}`);
          await tx.wait();
          totalTxCount++;
          if (i % 5 === 4) console.log(`  Progress: ${i + 1}/20`);
        }
        console.log(`✅ Completed 20 interactions\n`);
      } else if (contractInfo.name === "TipJar") {
        for (let i = 0; i < 20; i++) {
          const tipAmount = ethers.parseEther("0.00001");
          const tx = await contract.sendMessageWithTip(`Message ${i + 1}`, { value: tipAmount });
          await tx.wait();
          totalTxCount++;
          if (i % 5 === 4) console.log(`  Progress: ${i + 1}/20`);
        }
        console.log(`✅ Completed 20 interactions\n`);
      }
    } catch (error) {
      console.error(`❌ Error:`, error.message, '\n');
    }
  }

  console.log("\n✅ ALL 19 CONTRACTS NOW COMPLETE!");
  console.log(`📊 Total Transactions (this run): ${totalTxCount}`);

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Final Balance: ${ethers.formatEther(finalBalance)} ETH\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
