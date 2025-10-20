import { run } from "hardhat";
import * as fs from "fs";

async function main() {
  const chainId = process.env.HARDHAT_NETWORK === "base" ? "8453" : "84532";
  const deploymentPath = `./deployments/${chainId}.json`;

  if (!fs.existsSync(deploymentPath)) {
    console.error(`Deployment file not found: ${deploymentPath}`);
    console.log("Please deploy contracts first using: npm run deploy:testnet");
    return;
  }

  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const { contracts, feeCollector } = deployment;

  // Uniswap addresses
  const UNISWAP_ROUTER = process.env.UNISWAP_ROUTER_ADDRESS || "0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4";
  const UNISWAP_QUOTER = process.env.UNISWAP_QUOTER_ADDRESS || "0xC5290058841028F1614F3A6F0F5816cAd0df5E27";
  const WETH = process.env.WETH_ADDRESS || "0x4200000000000000000000000000000000000006";

  console.log("Starting contract verification...\n");

  // Verify UserRegistry
  try {
    console.log("Verifying UserRegistry...");
    await run("verify:verify", {
      address: contracts.UserRegistry,
      constructorArguments: [],
    });
    console.log("✅ UserRegistry verified\n");
  } catch (error: any) {
    console.log("❌ UserRegistry verification failed:", error.message, "\n");
  }

  // Verify EscrowManager
  try {
    console.log("Verifying EscrowManager...");
    await run("verify:verify", {
      address: contracts.EscrowManager,
      constructorArguments: [feeCollector],
    });
    console.log("✅ EscrowManager verified\n");
  } catch (error: any) {
    console.log("❌ EscrowManager verification failed:", error.message, "\n");
  }

  // Verify P2PTransfer
  try {
    console.log("Verifying P2PTransfer...");
    await run("verify:verify", {
      address: contracts.P2PTransfer,
      constructorArguments: [contracts.UserRegistry, feeCollector],
    });
    console.log("✅ P2PTransfer verified\n");
  } catch (error: any) {
    console.log("❌ P2PTransfer verification failed:", error.message, "\n");
  }

  // Verify SwapRouter
  try {
    console.log("Verifying SwapRouter...");
    await run("verify:verify", {
      address: contracts.SwapRouter,
      constructorArguments: [UNISWAP_ROUTER, UNISWAP_QUOTER, WETH, feeCollector],
    });
    console.log("✅ SwapRouter verified\n");
  } catch (error: any) {
    console.log("❌ SwapRouter verification failed:", error.message, "\n");
  }

  console.log("Verification complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });