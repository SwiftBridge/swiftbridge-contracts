const CONTRACT_ADDRESS = "0x19EdA32707ED0d3e793BA9fFAE3B5D3C49b8C1d8";
const NUM_WALLETS = 25;
const TARGET_TRANSACTIONS = 1000;

const names = [
  "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry",
  "Ivy", "Jack", "Kate", "Leo", "Mia", "Noah", "Olivia", "Peter",
  "Quinn", "Rachel", "Sam", "Tina", "Uma", "Victor", "Wendy", "Xander", "Zoe"
];

const messageTemplates = [
  "Hello from the SocialBook!",
  "This is amazing! Love this platform!",
  "Just joined, excited to be here!",
  "Web3 social is the future!",
  "Building on Base is awesome!",
  "Decentralization rocks!",
  "GM everyone!",
  "This contract is so cool!",
  "Learning Solidity is fun!",
  "On-chain social ftw!",
  "Base Sepolia testing!",
  "Smart contracts are incredible!",
  "Blockchain technology is revolutionary!",
  "Loving the features here!",
  "This is my first post!",
  "Can't wait to see this grow!",
  "Community is everything!",
  "Web3 is here to stay!",
  "Ethereum scaling solutions!",
  "Layer 2 for the win!",
  "Building the future!",
  "Decentralized social media!",
  "No censorship, just freedom!",
  "Open source everything!",
  "Crypto is changing the world!"
];

const bios = [
  "Web3 enthusiast",
  "Blockchain developer",
  "Crypto trader",
  "NFT collector",
  "DeFi explorer",
  "Smart contract auditor",
  "Full-stack dev",
  "Solidity wizard",
  "DAO contributor",
  "Tech innovator",
  "Crypto researcher",
  "Digital nomad",
  "Content creator",
  "Community builder",
  "Early adopter",
  "Tech geek",
  "Blockchain advocate",
  "Startup founder",
  "Code enthusiast",
  "Decentralization fan",
  "Open source lover",
  "Tech writer",
  "Protocol designer",
  "Security researcher",
  "Web3 builder"
];

async function main() {
  console.log("🚀 Starting SocialBook 1000 Transaction Script...\n");
  console.log(`Target: ${TARGET_TRANSACTIONS} transactions\n`);

  const [deployer] = await ethers.getSigners();
  console.log("Main account:", deployer.address);

  const initialBalance = await ethers.provider.getBalance(deployer.address);
  console.log("Initial balance:", ethers.formatEther(initialBalance), "ETH\n");

  // Generate wallets
  console.log(`📝 Generating ${NUM_WALLETS} random wallets...`);
  const wallets = [];
  for (let i = 0; i < NUM_WALLETS; i++) {
    const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
    wallets.push(wallet);
  }
  console.log("✅ Wallets generated\n");

  // Calculate funding
  const reserveForGas = ethers.parseEther("0.002");
  const availableBalance = initialBalance - reserveForGas;
  const amountPerWallet = availableBalance / BigInt(NUM_WALLETS);

  let txCount = 0;

  console.log(`💰 Funding ${NUM_WALLETS} wallets (${ethers.formatEther(amountPerWallet)} ETH each)...\n`);
  for (let i = 0; i < wallets.length; i++) {
    const tx = await deployer.sendTransaction({
      to: wallets[i].address,
      value: amountPerWallet
    });
    await tx.wait();
    txCount++;
    console.log(`  [${txCount}/${TARGET_TRANSACTIONS}] Funded ${names[i]} - ${wallets[i].address.substring(0, 10)}...`);
  }

  console.log(`\n✅ All wallets funded! (${txCount} transactions)\n`);

  const SocialBook = await ethers.getContractFactory("SocialBook");
  const mainContract = SocialBook.attach(CONTRACT_ADDRESS).connect(deployer);

  // Calculate remaining transactions
  const remainingTxns = TARGET_TRANSACTIONS - txCount;
  const txnsPerWallet = Math.floor(remainingTxns / NUM_WALLETS);

  console.log(`🎭 Each wallet will perform ~${txnsPerWallet} contract interactions...\n`);

  // Track message IDs for each wallet
  const walletMessageIds = Array(NUM_WALLETS).fill(null).map(() => []);

  // Phase 1: Update profiles (25 txns)
  console.log("👤 Phase 1: Updating profiles...");
  for (let i = 0; i < NUM_WALLETS; i++) {
    const contract = SocialBook.attach(CONTRACT_ADDRESS).connect(wallets[i]);
    const tx = await contract.updateProfile(names[i], bios[i]);
    await tx.wait();
    txCount++;
    console.log(`  [${txCount}/${TARGET_TRANSACTIONS}] ${names[i]} updated profile`);
  }
  console.log("");

  // Phase 2: Post multiple messages per wallet
  const messagesPerWallet = Math.floor((remainingTxns - txCount) * 0.4 / NUM_WALLETS); // 40% for messages
  console.log(`📢 Phase 2: Posting messages (${messagesPerWallet} per wallet)...`);
  for (let i = 0; i < NUM_WALLETS; i++) {
    const contract = SocialBook.attach(CONTRACT_ADDRESS).connect(wallets[i]);
    for (let j = 0; j < messagesPerWallet; j++) {
      const messageIndex = (j * NUM_WALLETS + i) % messageTemplates.length;
      const message = `${messageTemplates[messageIndex]} #${j + 1}`;
      const tx = await contract.postMessage(names[i], message);
      await tx.wait();
      const totalMessages = await mainContract.getTotalMessages();
      walletMessageIds[i].push(Number(totalMessages) - 1);
      txCount++;
      console.log(`  [${txCount}/${TARGET_TRANSACTIONS}] ${names[i]} posted message ${j + 1}`);
    }
  }
  console.log("");

  // Phase 3: Like messages
  const likesPerWallet = Math.floor((TARGET_TRANSACTIONS - txCount) * 0.35 / NUM_WALLETS); // 35% for likes
  console.log(`❤️  Phase 3: Liking messages (${likesPerWallet} per wallet)...`);
  for (let i = 0; i < NUM_WALLETS; i++) {
    const contract = SocialBook.attach(CONTRACT_ADDRESS).connect(wallets[i]);
    const totalMessages = await mainContract.getTotalMessages();
    const likedMessages = new Set();

    for (let j = 0; j < likesPerWallet && txCount < TARGET_TRANSACTIONS; j++) {
      let messageId;
      let attempts = 0;
      do {
        messageId = Math.floor(Math.random() * Number(totalMessages));
        attempts++;
      } while ((walletMessageIds[i].includes(messageId) || likedMessages.has(messageId)) && attempts < 50);

      if (attempts >= 50) break;

      likedMessages.add(messageId);
      try {
        const tx = await contract.likeMessage(messageId);
        await tx.wait();
        txCount++;
        console.log(`  [${txCount}/${TARGET_TRANSACTIONS}] ${names[i]} liked message ${messageId}`);
      } catch (error) {
        // Already liked, skip
      }
    }
  }
  console.log("");

  // Phase 4: Follow users
  const followsPerWallet = Math.floor((TARGET_TRANSACTIONS - txCount) * 0.15 / NUM_WALLETS); // 15% for follows
  console.log(`👥 Phase 4: Following users (${followsPerWallet} per wallet)...`);
  for (let i = 0; i < NUM_WALLETS && txCount < TARGET_TRANSACTIONS; i++) {
    const contract = SocialBook.attach(CONTRACT_ADDRESS).connect(wallets[i]);
    const followed = new Set();

    for (let j = 0; j < followsPerWallet && txCount < TARGET_TRANSACTIONS; j++) {
      let userIndex;
      let attempts = 0;
      do {
        userIndex = Math.floor(Math.random() * NUM_WALLETS);
        attempts++;
      } while ((userIndex === i || followed.has(userIndex)) && attempts < 50);

      if (attempts >= 50) break;

      followed.add(userIndex);
      try {
        const tx = await contract.followUser(wallets[userIndex].address);
        await tx.wait();
        txCount++;
        console.log(`  [${txCount}/${TARGET_TRANSACTIONS}] ${names[i]} followed ${names[userIndex]}`);
      } catch (error) {
        // Already following, skip
      }
    }
  }
  console.log("");

  // Phase 5: Additional posts to reach 1000
  console.log("📢 Phase 5: Additional posts to reach target...");
  let walletIndex = 0;
  while (txCount < TARGET_TRANSACTIONS) {
    const contract = SocialBook.attach(CONTRACT_ADDRESS).connect(wallets[walletIndex]);
    const messageIndex = Math.floor(Math.random() * messageTemplates.length);
    const message = `${messageTemplates[messageIndex]} (Extra post #${txCount})`;

    try {
      const tx = await contract.postMessage(names[walletIndex], message);
      await tx.wait();
      txCount++;
      console.log(`  [${txCount}/${TARGET_TRANSACTIONS}] ${names[walletIndex]} posted additional message`);
    } catch (error) {
      console.log(`  Error posting message: ${error.message}`);
    }

    walletIndex = (walletIndex + 1) % NUM_WALLETS;
  }
  console.log("");

  // Final stats
  console.log("📊 Final Statistics:\n");
  console.log(`✅ Total transactions executed: ${txCount}`);

  const totalMessages = await mainContract.getTotalMessages();
  console.log(`📝 Total messages on contract: ${totalMessages}`);

  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Main account remaining: ${ethers.formatEther(finalBalance)} ETH`);

  console.log("\n🎉 Mission accomplished! 1000 transactions completed!");
  console.log(`\n🔗 View contract on BaseScan: https://sepolia.basescan.org/address/${CONTRACT_ADDRESS}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
