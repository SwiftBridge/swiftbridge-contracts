# swiftbridge-contracts
contracts for swift
# SwiftBridge Contracts

Smart contracts for SwiftBridge - A Telegram-based crypto bridge enabling offramp, onramp, swaps, and P2P transfers on Base network.

## 🏗️ Architecture

### Core Contracts

1. **UserRegistry.sol** - Maps Telegram usernames to wallet addresses
2. **EscrowManager.sol** - Handles buy/sell escrow for fiat on/offramp
3. **P2PTransfer.sol** - Enables P2P transfers via Telegram username
4. **SwapRouter.sol** - Token swaps via Uniswap V3 on Base

### Features

- ✅ Username-based transfers (send crypto to @username)
- ✅ Escrow system for fiat on/offramp
- ✅ Token swaps with multiple pool fee tiers
- ✅ Pending transfer claims for unregistered users
- ✅ Dispute resolution mechanism
- ✅ Pausable for emergency stops
- ✅ Fee collection system

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/your-org/swiftbridge-contracts
cd swiftbridge-contracts

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your values
nano .env
```

## 🔧 Configuration

Update `.env` file with your settings:

```bash
PRIVATE_KEY=your_private_key_without_0x
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key
FEE_COLLECTOR_ADDRESS=your_fee_collector_address
```

## 🚀 Deployment

### Compile Contracts

```bash
npm run compile
```

### Run Tests

```bash
npm test
```

### Deploy to Base Sepolia Testnet

```bash
npm run deploy:testnet
```

### Verify Contracts

```bash
npm run verify
```

### Deploy to Base Mainnet

```bash
npm run deploy:mainnet
```

## 📝 Contract Addresses

### Base Sepolia Testnet

Addresses will be saved to `deployments/84532.json` after deployment.

### Uniswap V3 on Base Sepolia

- Router: `0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4`
- Quoter: `0xC5290058841028F1614F3A6F0F5816cAd0df5E27`
- WETH: `0x4200000000000000000000000000000000000006`

## 🎯 Usage Examples

### Register Username

```solidity
// User registers their Telegram username
userRegistry.registerUsername("myusername");
```

### Create Buy Escrow (Bot/Operator)

```solidity
// Bot creates escrow when user wants to buy crypto
escrowManager.createBuyEscrow(
    userAddress,
    usdtAddress,
    100 * 10**6, // 100 USDT
    160000, // 160,000 Naira
    "PAY-REF-12345"
);
```

### Send to Username

```solidity
// Send 50 USDT to @friend
p2pTransfer.sendToUsername(
    "friend",
    usdtAddress,
    50 * 10**6,
    "Thanks for dinner!"
);
```

### Swap Tokens

```solidity
// Swap 100 USDC for ETH
swapRouter.swapExactTokensForETH(
    usdcAddress,
    100 * 10**6,
    0.01 ether, // minimum ETH out
    3000 // 0.3% pool fee
);
```

## 🧪 Testing

Run the full test suite:

```bash
npm test
```

Run specific test file:

```bash
npx hardhat test test/UserRegistry.test.ts
```

Generate coverage report:

```bash
npm run coverage
```

## 📊 Gas Reporting

Enable gas reporting in `.env`:

```bash
REPORT_GAS=true
COINMARKETCAP_API_KEY=your_api_key
```

Then run tests:

```bash
npm test
```

## 🔐 Security

- Uses OpenZeppelin audited contracts
- ReentrancyGuard on all state-changing functions
- Pausable for emergency stops
- Access control with Ownable pattern
- Custom errors for gas efficiency
- SafeERC20 for token transfers

### Audit Status

⚠️ **NOT AUDITED** - These contracts have not been professionally audited. Use at your own risk.

## 📖 Contract Documentation

### UserRegistry

Maps Telegram usernames to wallet addresses with the following features:

- Username validation (5-32 characters, alphanumeric + underscore)
- 7-day cooldown for username updates
- Username removal functionality
- Pausable registration

### EscrowManager

Manages escrow for buy/sell operations:

- **BUY**: User pays Naira → Bot locks crypto → Release on confirmation
- **SELL**: User locks crypto → Bot pays Naira → Release on confirmation
- 24-hour timeout with auto-refund capability
- Dispute resolution system
- Operator management for trusted bots

### P2PTransfer

Peer-to-peer transfers using Telegram usernames:

- Instant transfer if username registered
- Pending transfers for unregistered users
- Batch transfers to multiple recipients
- Claim pending transfers after registration
- Transfer history tracking

### SwapRouter

Token swaps via Uniswap V3:

- Multiple pool fee tiers (0.05%, 0.3%, 1%)
- ETH ↔ Token swaps
- Token ↔ Token swaps
- Quote functionality
- Auto-select best pool fee
- Slippage protection

## 🛠️ Development

### Project Structure

```
swiftbridge-contracts/
├── contracts/
│   ├── core/
│   │   ├── UserRegistry.sol
│   │   ├── EscrowManager.sol
│   │   ├── P2PTransfer.sol
│   │   └── SwapRouter.sol
│   ├── interfaces/
│   └── mocks/
├── test/
│   └── UserRegistry.test.ts
├── scripts/
│   ├── deploy.ts
│   └── verify.ts
├── deployments/
├── hardhat.config.ts
└── package.json
```

### Adding New Tests

Create test files in `test/` directory following the pattern:

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ContractName", function () {
  // Your tests here
});
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Links

- [Base Documentation](https://docs.base.org)
- [Uniswap V3 Documentation](https://docs.uniswap.org/contracts/v3/overview)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Hardhat Documentation](https://hardhat.org/docs)

## ⚠️ Disclaimer

This software is provided "as is", without warranty of any kind. Use at your own risk. Always conduct thorough testing and security audits before deploying to mainnet.

## 📞 Support

For questions and support, please open an issue in the GitHub repository.