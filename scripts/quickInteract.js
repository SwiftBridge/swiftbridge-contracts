import fs from 'fs';

const NUM_INTERACTIONS = 20;
const START_FROM_INDEX = 5; // Continue from TaskManager

async function main() {
  console.log("🚀 Quick Interaction Script (Using deployer account)...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH\n");

  // Load deployed contracts
  const deployedContracts = JSON.parse(fs.readFileSync('./deployedContracts.json', 'utf8'));
  console.log(`📋 Processing ${deployedContracts.length - START_FROM_INDEX} remaining contracts\n`);

  let totalTxCount = 0;

  // Interact with remaining contracts using deployer account only
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

  console.log("\n🎉 Complete!");
  console.log(`📊 Total Transactions: ${totalTxCount}`);

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Final Balance: ${ethers.formatEther(finalBalance)} ETH\n`);
}

async function interactWithContract(contractName, contractAddress, signer, count) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = Contract.attach(contractAddress).connect(signer);
  let txCount = 0;

  switch (contractName) {
    case "TaskManager":
      for (let i = 0; i < count; i++) {
        const tx = await contract.createTask(`Task ${i + 1}`, signer.address);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "NotificationHub":
      for (let i = 0; i < count; i++) {
        const tx = await contract.sendNotification(signer.address, `Notification ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "CommentSystem":
      for (let i = 0; i < count; i++) {
        const tx = await contract.addComment(0, `Comment ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "ReviewBoard":
      for (let i = 0; i < count; i++) {
        const rating = (i % 5) + 1;
        const tx = await contract.submitReview(`Review ${i + 1}`, rating);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "AnonymousBoard":
      for (let i = 0; i < count; i++) {
        const tx = await contract.createPost(`Anonymous post ${i + 1}`, "secret");
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "PollSystem":
      for (let i = 0; i < count; i++) {
        const tx = await contract.createPoll(`Poll ${i + 1}?`, ["Yes", "No", "Maybe"]);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "TimedMessages":
      for (let i = 0; i < count; i++) {
        const duration = 3600 * (i + 1);
        const tx = await contract.sendMessage(`Timed message ${i + 1}`, duration);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "ReplyMessages":
      for (let i = 0; i < count; i++) {
        const tx = await contract.sendMessage(0, `Reply ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "TipJar":
      for (let i = 0; i < count; i++) {
        const tipAmount = ethers.parseEther("0.00001");
        const tx = await contract.sendMessageWithTip(`Message with tip ${i + 1}`, { value: tipAmount });
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

    case "ModeratedForum":
      for (let i = 0; i < count; i++) {
        const tx = await contract.submitPost(`Forum post ${i + 1}`);
        await tx.wait();
        txCount++;
        if (i % 5 === 4) console.log(`  Progress: ${i + 1}/${count}`);
      }
      break;

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
