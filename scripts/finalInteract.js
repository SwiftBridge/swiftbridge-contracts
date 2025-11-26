import fs from 'fs';

const NUM_INTERACTIONS = 20;
const START_FROM_INDEX = 15; // Continue from BadgeSystem

async function main() {
  console.log("🚀 Final Interaction Script...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH\n");

  const deployedContracts = JSON.parse(fs.readFileSync('./deployedContracts.json', 'utf8'));
  console.log(`📋 Processing ${deployedContracts.length - START_FROM_INDEX} remaining contracts\n`);

  let totalTxCount = 0;

  for (let c = START_FROM_INDEX; c < deployedContracts.length; c++) {
    const contractInfo = deployedContracts[c];
    console.log(`\n[${c + 1}/${deployedContracts.length}] ${contractInfo.name} - ${contractInfo.address}`);

    try {
      const txCount = await interactWithContract(contractInfo.name, contractInfo.address, deployer, NUM_INTERACTIONS);
      totalTxCount += txCount;
      console.log(`✅ Completed ${txCount} interactions\n`);
    } catch (error) {
      console.error(`❌ Error:`, error.message.substring(0, 100), '\n');
    }
  }

  console.log("\n🎉 ALL CONTRACTS COMPLETE!");
  console.log(`📊 Total Transactions: ${totalTxCount}`);

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Final Balance: ${ethers.formatEther(finalBalance)} ETH\n`);
}

async function interactWithContract(contractName, contractAddress, signer, count) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = Contract.attach(contractAddress).connect(signer);
  let txCount = 0;

  switch (contractName) {
    case "BadgeSystem":
      const tx1 = await contract.setBadge("VIP");
      await tx1.wait();
      txCount++;
      for (let i = 0; i < count - 1; i++) {
        const tx = await contract.sendMessage(`Message ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count - 1}`);
      }
      break;

    case "MultiSigMessages":
      for (let i = 0; i < count; i++) {
        const tx = await contract.createMessage(`MultiSig message ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "StreamMessages":
      for (let i = 0; i < count; i++) {
        const tx = await contract.createStream(`Stream content ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "TagSystem":
      for (let i = 0; i < count; i++) {
        const tags = [`tag${i}`, "general"];
        const tx = await contract.sendTaggedMessage(`Tagged message ${i + 1}`, tags);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    default:
      console.log(`  ⚠️  No handler for ${contractName}`);
  }

  return txCount;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
