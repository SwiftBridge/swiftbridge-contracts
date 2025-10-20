import { ethers } from "hardhat";
import * as fs from "fs";

async function main() {
  const [signer] = await ethers.getSigners();
  console.log("Interacting with contracts using account:", signer.address, "\n");

  // Load deployment addresses
  const chainId = (await ethers.provider.getNetwork()).chainId.toString();
  const deploymentPath = `./deployments/${chainId}.json`;

  if (!fs.existsSync(deploymentPath)) {
    console.error("Deployment file not found. Please deploy contracts first.");
    return;
  }

  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const { contracts } = deployment;

  // Get contract instances
  const userRegistry = await ethers.getContractAt("UserRegistry", contracts.UserRegistry);
  const escrowManager = await ethers.getContractAt("EscrowManager", contracts.EscrowManager);
  const p2pTransfer = await ethers.getContractAt("P2PTransfer", contracts.P2PTransfer);
  const swapRouter = await ethers.getContractAt("SwapRouter", contracts.SwapRouter);

  console.log("Connected to contracts:");
  console.log("UserRegistry:  ", await userRegistry.getAddress());
  console.log("EscrowManager: ", await escrowManager.getAddress());
  console.log("P2PTransfer:   ", await p2pTransfer.getAddress());
  console.log("SwapRouter:    ", await swapRouter.getAddress());
  console.log("\n");

  // Example interactions

  // 1. Register a username
  console.log("=== Registering Username ===");
  try {
    const username = "testuser_" + Date.now();
    const tx = await userRegistry.registerUsername(username);
    await tx.wait();
    console.log("Is trusted operator:", isOperator ? "Yes ✅" : "No ❌");
  } catch (error: any) {
    console.log("Error:", error.message);
  }
  console.log("\n");

  console.log("=".repeat(60));
  console.log("Interaction complete!");
  console.log("=".repeat(60));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });✅ Username registered:", username);
    
    const registeredAddress = await userRegistry.usernameToAddress(username);
    console.log("   Mapped to address:", registeredAddress);
  } catch (error: any) {
    console.log("ℹ️  Username registration:", error.message);
  }
  console.log("\n");

  // 2. Check if username is registered
  console.log("=== Checking Username ===");
  try {
    const hasUsername = await userRegistry.hasUsername(signer.address);
    if (hasUsername) {
      const username = await userRegistry.addressToUsername(signer.address);
      console.log("✅ Your username:", username);
    } else {
      console.log("ℹ️  No username registered for this address");
    }
  } catch (error: any) {
    console.log("Error:", error.message);
  }
  console.log("\n");

  // 3. Check escrow counter
  console.log("=== Escrow Statistics ===");
  try {
    const escrowCounter = await escrowManager.escrowCounter();
    console.log("Total escrows created:", escrowCounter.toString());
    
    const feeBps = await escrowManager.feeBps();
    console.log("Current fee:", (Number(feeBps) / 100).toFixed(2) + "%");
  } catch (error: any) {
    console.log("Error:", error.message);
  }
  console.log("\n");

  // 4. Check P2P transfer stats
  console.log("=== P2P Transfer Statistics ===");
  try {
    const transferCounter = await p2pTransfer.transferCounter();
    console.log("Total transfers:", transferCounter.toString());
    
    const sentTransfers = await p2pTransfer.getSentTransfers(signer.address);
    console.log("Your sent transfers:", sentTransfers.length);
    
    const receivedTransfers = await p2pTransfer.getReceivedTransfers(signer.address);
    console.log("Your received transfers:", receivedTransfers.length);
  } catch (error: any) {
    console.log("Error:", error.message);
  }
  console.log("\n");

  // 5. Check swap router config
  console.log("=== Swap Router Configuration ===");
  try {
    const feeBps = await swapRouter.feeBps();
    console.log("Swap fee:", (Number(feeBps) / 100).toFixed(2) + "%");
    
    const poolFeeLow = await swapRouter.POOL_FEE_LOW();
    const poolFeeMedium = await swapRouter.POOL_FEE_MEDIUM();
    const poolFeeHigh = await swapRouter.POOL_FEE_HIGH();
    
    console.log("Supported pool fees:");
    console.log("  Low:   ", (Number(poolFeeLow) / 10000).toFixed(2) + "%");
    console.log("  Medium:", (Number(poolFeeMedium) / 10000).toFixed(2) + "%");
    console.log("  High:  ", (Number(poolFeeHigh) / 10000).toFixed(2) + "%");
  } catch (error: any) {
    console.log("Error:", error.message);
  }
  console.log("\n");

  // 6. Check operator status
  console.log("=== Operator Status ===");
  try {
    const isOperator = await escrowManager.trustedOperators(signer.address);
    console.log("