import fs from 'fs';

const NUM_WALLETS = 25;
const TXN_PER_CONTRACT = 20;

async function main() {
  console.log("🚀 Starting Multi-Contract Interaction Script...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Main account:", deployer.address);

  const initialBalance = await ethers.provider.getBalance(deployer.address);
  console.log("Initial balance:", ethers.formatEther(initialBalance), "ETH\n");

  // Generate wallets
  console.log(`📝 Generating ${NUM_WALLETS} wallets...`);
  const wallets = [];
  for (let i = 0; i < NUM_WALLETS; i++) {
    const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
    wallets.push(wallet);
  }
  console.log("✅ Wallets generated\n");

  // Fund wallets
  const reserveForGas = ethers.parseEther("0.002");
  const availableBalance = initialBalance - reserveForGas;
  const amountPerWallet = availableBalance / BigInt(NUM_WALLETS);

  console.log(`💰 Funding ${NUM_WALLETS} wallets (${ethers.formatEther(amountPerWallet)} ETH each)...\n`);
  for (let i = 0; i < wallets.length; i++) {
    const tx = await deployer.sendTransaction({
      to: wallets[i].address,
      value: amountPerWallet
    });
    await tx.wait();
    console.log(`  [${i + 1}/${NUM_WALLETS}] Funded wallet ${i + 1}`);
  }
  console.log("\n✅ All wallets funded!\n");

  // Load deployed contracts
  const deployedContracts = JSON.parse(fs.readFileSync('./deployedContracts.json', 'utf8'));
  console.log(`📋 Found ${deployedContracts.length} deployed contracts\n`);

  let totalTxCount = NUM_WALLETS; // Count funding transactions

  // Interact with each contract
  for (let c = 0; c < deployedContracts.length; c++) {
    const contractInfo = deployedContracts[c];
    console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`📝 Contract ${c + 1}/${deployedContracts.length}: ${contractInfo.name}`);
    console.log(`📍 Address: ${contractInfo.address}`);
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

    try {
      await interactWithContract(contractInfo.name, contractInfo.address, wallets, TXN_PER_CONTRACT);
      totalTxCount += TXN_PER_CONTRACT;
      console.log(`✅ Completed ${TXN_PER_CONTRACT} interactions with ${contractInfo.name}\n`);
    } catch (error) {
      console.error(`❌ Error interacting with ${contractInfo.name}:`, error.message, '\n');
    }
  }

  console.log("\n╔════════════════════════════════════╗");
  console.log(`║   🎉 ALL INTERACTIONS COMPLETE!    ║`);
  console.log("╚════════════════════════════════════╝\n");
  console.log(`📊 Total Transactions: ${totalTxCount}`);
  console.log(`📝 Contracts: ${deployedContracts.length}`);
  console.log(`👥 Wallets Used: ${NUM_WALLETS}`);

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Final Balance: ${ethers.formatEther(finalBalance)} ETH\n`);
}

async function interactWithContract(contractName, contractAddress, wallets, txnCount) {
  const Contract = await ethers.getContractFactory(contractName);
  const txPerWallet = Math.ceil(txnCount / wallets.length);

  switch (contractName) {
    case "BatchMessenger":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.sendMessage(`Message from wallet ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent message`);
      }
      break;

    case "GroupChat":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        let tx = await contract.joinGroup();
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} joined group`);
        if (i * txPerWallet + 1 < txnCount) {
          tx = await contract.sendMessage(1, `Chat message from wallet ${i + 1}`);
          await tx.wait();
        }
      }
      break;

    case "AnnouncementBoard":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.postAnnouncement(
          `Announcement ${i + 1}`,
          `Content from wallet ${i + 1}`,
          "General"
        );
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} posted announcement`);
      }
      break;

    case "VotingMessages":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.createMessage(`Vote message from wallet ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created vote message`);
      }
      break;

    case "EventBoard":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const eventTime = Math.floor(Date.now() / 1000) + 86400;
        const tx = await contract.createEvent(
          `Event ${i + 1}`,
          `Description from wallet ${i + 1}`,
          eventTime
        );
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created event`);
      }
      break;

    case "TaskManager":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const assignee = wallets[(i + 1) % wallets.length].address;
        const tx = await contract.createTask(`Task ${i + 1}`, assignee);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created task`);
      }
      break;

    case "NotificationHub":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const recipient = wallets[(i + 1) % wallets.length].address;
        const tx = await contract.sendNotification(recipient, `Notification from wallet ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent notification`);
      }
      break;

    case "CommentSystem":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.addComment(0, `Comment from wallet ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} added comment`);
      }
      break;

    case "ReviewBoard":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const rating = (i % 5) + 1;
        const tx = await contract.submitReview(`Review from wallet ${i + 1}`, rating);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} submitted review (${rating} stars)`);
      }
      break;

    case "AnonymousBoard":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.createPost(`Anonymous post ${i + 1}`, "secret");
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created anonymous post`);
      }
      break;

    case "PollSystem":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.createPoll(`Poll ${i + 1}?`, ["Yes", "No", "Maybe"]);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created poll`);
      }
      break;

    case "TimedMessages":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const duration = 3600 * (i + 1);
        const tx = await contract.sendMessage(`Timed message ${i + 1}`, duration);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent timed message`);
      }
      break;

    case "ReplyMessages":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.sendMessage(0, `Reply from wallet ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent reply`);
      }
      break;

    case "TipJar":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tipAmount = ethers.parseEther("0.00001");
        const tx = await contract.sendMessageWithTip(`Message with tip ${i + 1}`, { value: tipAmount });
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent message with tip`);
      }
      break;

    case "ModeratedForum":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.submitPost(`Forum post ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} submitted forum post`);
      }
      break;

    case "BadgeSystem":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        if (i === 0) {
          const tx1 = await contract.setBadge(`Badge${i + 1}`);
          await tx1.wait();
        }
        const tx = await contract.sendMessage(`Message from wallet ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent badged message`);
      }
      break;

    case "MultiSigMessages":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.createMessage(`MultiSig message ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created multisig message`);
      }
      break;

    case "StreamMessages":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.createStream(`Stream content ${i + 1}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created stream`);
      }
      break;

    case "TagSystem":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tags = [`tag${i}`, "general"];
        const tx = await contract.sendTaggedMessage(`Tagged message ${i + 1}`, tags);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} sent tagged message`);
      }
      break;

    case "SocialFeed":
      for (let i = 0; i < wallets.length && i * txPerWallet < txnCount; i++) {
        const contract = Contract.attach(contractAddress).connect(wallets[i]);
        const tx = await contract.createPost(`Post ${i + 1}`, `tag${i % 3}`);
        await tx.wait();
        console.log(`  ✓ Wallet ${i + 1} created post`);
      }
      break;

    default:
      console.log(`  ⚠️  No interaction handler for ${contractName}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
