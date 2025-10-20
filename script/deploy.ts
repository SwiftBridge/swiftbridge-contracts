import { ethers } from "hardhat";

async function main() {
  console.log("Starting SwiftBridge deployment to Base Sepolia...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // Get fee collector address from env or use deployer
  const feeCollector = process.env.FEE_COLLECTOR_ADDRESS || deployer.address;
  console.log("Fee collector address:", feeCollector, "\n");

  // Uniswap V3 addresses on Base Sepolia
  const UNISWAP_ROUTER = process.env.UNISWAP_ROUTER_ADDRESS || "0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4";
  const UNISWAP_QUOTER = process.env.UNISWAP_QUOTER_ADDRESS || "0xC5290058841028F1614F3A6F0F5816cAd0df5E27";
  const WETH = process.env.WETH_ADDRESS || "0x4200000000000000000000000000000000000006";

  // Deploy UserRegistry
  console.log("Deploying UserRegistry...");
  const UserRegistry = await ethers.getContractFactory("UserRegistry");
  const userRegistry = await UserRegistry.deploy();
  await userRegistry.waitForDeployment();
  const userRegistryAddress = await userRegistry.getAddress();
  console.log("✅ UserRegistry deployed to:", userRegistryAddress, "\n");

  // Deploy EscrowManager
  console.log("Deploying EscrowManager...");
  const EscrowManager = await ethers.getContractFactory("EscrowManager");
  const escrowManager = await EscrowManager.deploy(feeCollector);
  await escrowManager.waitForDeployment();
  const escrowManagerAddress = await escrowManager.getAddress();
  console.log("✅ EscrowManager deployed to:", escrowManagerAddress, "\n");

  // Deploy P2PTransfer
  console.log("Deploying P2PTransfer...");
  const P2PTransfer = await ethers.getContractFactory("P2PTransfer");
  const p2pTransfer = await P2PTransfer.deploy(userRegistryAddress, feeCollector);
  await p2pTransfer.waitForDeployment();
  const p2pTransferAddress = await p2pTransfer.getAddress();
  console.log("✅ P2PTransfer deployed to:", p2pTransferAddress, "\n");

  // Deploy SwapRouter
  console.log("Deploying SwapRouter...");
  const SwapRouter = await ethers.getContractFactory("SwapRouter");
  const swapRouter = await SwapRouter.deploy(
    UNISWAP_ROUTER,
    UNISWAP_QUOTER,
    WETH,
    feeCollector
  );
  await swapRouter.waitForDeployment();
  const swapRouterAddress = await swapRouter.getAddress();
  console.log("✅ SwapRouter deployed to:", swapRouterAddress, "\n");

  // Setup - Add deployer as trusted operator on EscrowManager
  console.log("Setting up EscrowManager...");
  const tx = await escrowManager.addOperator(deployer.address);
  await tx.wait();
  console.log("✅ Added deployer as trusted operator\n");

  // Print deployment summary
  console.log("=".repeat(60));
  console.log("DEPLOYMENT SUMMARY");
  console.log("=".repeat(60));
  console.log("Network:", (await ethers.provider.getNetwork()).name);
  console.log("Chain ID:", (await ethers.provider.getNetwork()).chainId);
  console.log("\nDeployed Contracts:");
  console.log("-".repeat(60));
  console.log("UserRegistry:    ", userRegistryAddress);
  console.log("EscrowManager:   ", escrowManagerAddress);
  console.log("P2PTransfer:     ", p2pTransferAddress);
  console.log("SwapRouter:      ", swapRouterAddress);
  console.log("-".repeat(60));
  console.log("Fee Collector:   ", feeCollector);
  console.log("Deployer:        ", deployer.address);
  console.log("=".repeat(60));

  // Save deployment addresses to file
  const fs = require("fs");
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: Number((await ethers.provider.getNetwork()).chainId),
    deployer: deployer.address,
    feeCollector: feeCollector,
    contracts: {
      UserRegistry: userRegistryAddress,
      EscrowManager: escrowManagerAddress,
      P2PTransfer: p2pTransferAddress,
      SwapRouter: swapRouterAddress,
    },
    timestamp: new Date().toISOString(),
  };

  const deploymentPath = `./deployments/${(await ethers.provider.getNetwork()).chainId}.json`;
  fs.mkdirSync("./deployments", { recursive: true });
  fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
  console.log("\n✅ Deployment info saved to:", deploymentPath);

  console.log("\n📝 Next steps:");
  console.log("1. Verify contracts on BaseScan: npm run verify");
  console.log("2. Update .env file with deployed addresses");
  console.log("3. Fund the contracts with test tokens");
  console.log("4. Add bot operator addresses to EscrowManager");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });