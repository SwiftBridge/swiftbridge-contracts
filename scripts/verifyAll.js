import fs from 'fs';
import { exec } from 'child_process';
import { promisify } from 'util';

const execPromise = promisify(exec);

async function main() {
  console.log("🔍 Verifying all contracts on BaseScan...\n");

  // Read deployed contracts
  const deployedContracts = JSON.parse(fs.readFileSync('./deployedContracts.json', 'utf8'));

  console.log(`Found ${deployedContracts.length} contracts to verify\n`);

  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < deployedContracts.length; i++) {
    const contract = deployedContracts[i];
    console.log(`[${i + 1}/${deployedContracts.length}] Verifying ${contract.name} at ${contract.address}...`);

    try {
      const command = `npx hardhat verify --network baseSepolia ${contract.address}`;
      const { stdout, stderr } = await execPromise(command);

      if (stdout.includes('Successfully verified') || stdout.includes('Already Verified')) {
        console.log(`✅ ${contract.name} verified successfully\n`);
        successCount++;
      } else {
        console.log(`⚠️  ${contract.name} verification result unclear\n`);
        console.log(stdout);
      }
    } catch (error) {
      if (error.stdout && error.stdout.includes('Already Verified')) {
        console.log(`✅ ${contract.name} already verified\n`);
        successCount++;
      } else {
        console.error(`❌ Failed to verify ${contract.name}:`, error.message.substring(0, 100), '\n');
        failCount++;
      }
    }

    // Wait a bit between verifications to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  console.log("\n📊 Verification Summary:");
  console.log(`✅ Successful: ${successCount}`);
  console.log(`❌ Failed: ${failCount}`);
  console.log(`📝 Total: ${deployedContracts.length}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
