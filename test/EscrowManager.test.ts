import { expect } from "chai";
import { ethers } from "hardhat";
import { EscrowManager, MockERC20 } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("EscrowManager", function () {
  let escrowManager: EscrowManager;
  let token: MockERC20;
  let owner: SignerWithAddress;
  let operator: SignerWithAddress;
  let user: SignerWithAddress;
  let feeCollector: SignerWithAddress;

  const INITIAL_BALANCE = ethers.parseUnits("1000", 6); // 1000 USDT

  beforeEach(async function () {
    [owner, operator, user, feeCollector] = await ethers.getSigners();

    // Deploy mock token
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    token = await MockERC20.deploy("USD Tether", "USDT", 6);
    await token.waitForDeployment();

    // Mint tokens
    await token.mint(operator.address, INITIAL_BALANCE);
    await token.mint(user.address, INITIAL_BALANCE);

    // Deploy EscrowManager
    const EscrowManager = await ethers.getContractFactory("EscrowManager");
    escrowManager = await EscrowManager.deploy(feeCollector.address);
    await escrowManager.waitForDeployment();

    // Add operator
    await escrowManager.addOperator(operator.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await escrowManager.owner()).to.equal(owner.address);
    });

    it("Should set the right fee collector", async function () {
      expect(await escrowManager.feeCollector()).to.equal(feeCollector.address);
    });

    it("Should have correct default fee", async function () {
      expect(await escrowManager.feeBps()).to.equal(50); // 0.5%
    });
  });

  describe("Operator Management", function () {
    it("Should add operator", async function () {
      const newOperator = user.address;
      await expect(escrowManager.addOperator(newOperator))
        .to.emit(escrowManager, "OperatorAdded")
        .withArgs(newOperator);

      expect(await escrowManager.trustedOperators(newOperator)).to.be.true;
    });

    it("Should remove operator", async function () {
      await expect(escrowManager.removeOperator(operator.address))
        .to.emit(escrowManager, "OperatorRemoved")
        .withArgs(operator.address);

      expect(await escrowManager.trustedOperators(operator.address)).to.be.false;
    });

    it("Should reject non-owner adding operator", async function () {
      await expect(
        escrowManager.connect(user).addOperator(user.address)
      ).to.be.revertedWithCustomError(escrowManager, "OwnableUnauthorizedAccount");
    });
  });

  describe("Buy Escrow", function () {
    const amount = ethers.parseUnits("100", 6); // 100 USDT
    const nairaAmount = 160000; // 160,000 NGN
    const paymentRef = "PAY-REF-123";

    beforeEach(async function () {
      await token.connect(operator).approve(await escrowManager.getAddress(), amount);
    });

    it("Should create buy escrow", async function () {
      await expect(
        escrowManager.connect(operator).createBuyEscrow(
          user.address,
          await token.getAddress(),
          amount,
          nairaAmount,
          paymentRef
        )
      ).to.emit(escrowManager, "EscrowCreated");

      const escrow = await escrowManager.getEscrow(1);
      expect(escrow.user).to.equal(user.address);
      expect(escrow.amount).to.equal(amount);
      expect(escrow.nairaAmount).to.equal(nairaAmount);
      expect(escrow.escrowType).to.equal(0); // BUY
      expect(escrow.status).to.equal(0); // PENDING
    });

    it("Should transfer tokens to contract on buy escrow creation", async function () {
      const contractAddress = await escrowManager.getAddress();
      const balanceBefore = await token.balanceOf(contractAddress);

      await escrowManager.connect(operator).createBuyEscrow(
        user.address,
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      const balanceAfter = await token.balanceOf(contractAddress);
      expect(balanceAfter - balanceBefore).to.equal(amount);
    });

    it("Should reject buy escrow from non-operator", async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
      
      await expect(
        escrowManager.connect(user).createBuyEscrow(
          user.address,
          await token.getAddress(),
          amount,
          nairaAmount,
          paymentRef
        )
      ).to.be.revertedWithCustomError(escrowManager, "UnauthorizedOperator");
    });
  });

  describe("Sell Escrow", function () {
    const amount = ethers.parseUnits("100", 6);
    const nairaAmount = 160000;
    const paymentRef = "PAY-REF-456";

    beforeEach(async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
    });

    it("Should create sell escrow", async function () {
      await expect(
        escrowManager.connect(user).createSellEscrow(
          await token.getAddress(),
          amount,
          nairaAmount,
          paymentRef
        )
      ).to.emit(escrowManager, "EscrowCreated");

      const escrow = await escrowManager.getEscrow(1);
      expect(escrow.user).to.equal(user.address);
      expect(escrow.escrowType).to.equal(1); // SELL
    });

    it("Should transfer tokens to contract on sell escrow creation", async function () {
      const contractAddress = await escrowManager.getAddress();
      const balanceBefore = await token.balanceOf(contractAddress);

      await escrowManager.connect(user).createSellEscrow(
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      const balanceAfter = await token.balanceOf(contractAddress);
      expect(balanceAfter - balanceBefore).to.equal(amount);
    });
  });

  describe("Release Escrow", function () {
    const amount = ethers.parseUnits("100", 6);
    const nairaAmount = 160000;
    const paymentRef = "PAY-REF-789";

    it("Should release buy escrow to user", async function () {
      await token.connect(operator).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(operator).createBuyEscrow(
        user.address,
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      const userBalanceBefore = await token.balanceOf(user.address);
      
      await escrowManager.connect(operator).releaseEscrow(1);
      
      const userBalanceAfter = await token.balanceOf(user.address);
      const fee = (amount * 50n) / 10000n; // 0.5% fee
      const amountAfterFee = amount - fee;
      
      expect(userBalanceAfter - userBalanceBefore).to.equal(amountAfterFee);
    });

    it("Should collect fee on release", async function () {
      await token.connect(operator).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(operator).createBuyEscrow(
        user.address,
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      const feeCollectorBalanceBefore = await token.balanceOf(feeCollector.address);
      
      await escrowManager.connect(operator).releaseEscrow(1);
      
      const feeCollectorBalanceAfter = await token.balanceOf(feeCollector.address);
      const expectedFee = (amount * 50n) / 10000n;
      
      expect(feeCollectorBalanceAfter - feeCollectorBalanceBefore).to.equal(expectedFee);
    });

    it("Should reject release from non-operator", async function () {
      await token.connect(operator).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(operator).createBuyEscrow(
        user.address,
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      await expect(
        escrowManager.connect(user).releaseEscrow(1)
      ).to.be.revertedWithCustomError(escrowManager, "UnauthorizedOperator");
    });
  });

  describe("Cancel Escrow", function () {
    const amount = ethers.parseUnits("100", 6);
    const nairaAmount = 160000;
    const paymentRef = "PAY-REF-CANCEL";

    it("Should allow user to cancel sell escrow", async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(user).createSellEscrow(
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      const userBalanceBefore = await token.balanceOf(user.address);
      
      await escrowManager.connect(user).cancelEscrow(1);
      
      const userBalanceAfter = await token.balanceOf(user.address);
      expect(userBalanceAfter - userBalanceBefore).to.equal(amount);
      
      const escrow = await escrowManager.getEscrow(1);
      expect(escrow.status).to.equal(3); // CANCELLED
    });

    it("Should allow operator to cancel escrow", async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(user).createSellEscrow(
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      await escrowManager.connect(operator).cancelEscrow(1);
      
      const escrow = await escrowManager.getEscrow(1);
      expect(escrow.status).to.equal(3); // CANCELLED
    });
  });

  describe("Dispute Handling", function () {
    const amount = ethers.parseUnits("100", 6);
    const nairaAmount = 160000;
    const paymentRef = "PAY-REF-DISPUTE";

    beforeEach(async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
      await escrowManager.connect(user).createSellEscrow(
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );
    });

    it("Should allow user to dispute escrow", async function () {
      await expect(escrowManager.connect(user).disputeEscrow(1))
        .to.emit(escrowManager, "EscrowDisputed")
        .withArgs(1, user.address);

      const escrow = await escrowManager.getEscrow(1);
      expect(escrow.status).to.equal(2); // DISPUTED
    });

    it("Should allow owner to resolve dispute", async function () {
      await escrowManager.connect(user).disputeEscrow(1);
      
      await expect(escrowManager.resolveDispute(1, true))
        .to.emit(escrowManager, "DisputeResolved")
        .withArgs(1, true);

      const escrow = await escrowManager.getEscrow(1);
      expect(escrow.status).to.equal(1); // COMPLETED
    });

    it("Should reject non-owner dispute resolution", async function () {
      await escrowManager.connect(user).disputeEscrow(1);
      
      await expect(
        escrowManager.connect(user).resolveDispute(1, true)
      ).to.be.revertedWithCustomError(escrowManager, "OwnableUnauthorizedAccount");
    });
  });

  describe("Expired Escrow", function () {
    const amount = ethers.parseUnits("100", 6);
    const nairaAmount = 160000;
    const paymentRef = "PAY-REF-EXPIRE";

    it("Should allow claiming expired sell escrow", async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(user).createSellEscrow(
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      // Fast forward past timeout
      await time.increase(24 * 60 * 60 + 1);

      const userBalanceBefore = await token.balanceOf(user.address);
      
      await escrowManager.connect(user).claimExpiredEscrow(1);
      
      const userBalanceAfter = await token.balanceOf(user.address);
      expect(userBalanceAfter - userBalanceBefore).to.equal(amount);
    });

    it("Should reject claiming non-expired escrow", async function () {
      await token.connect(user).approve(await escrowManager.getAddress(), amount);
      
      await escrowManager.connect(user).createSellEscrow(
        await token.getAddress(),
        amount,
        nairaAmount,
        paymentRef
      );

      await expect(
        escrowManager.connect(user).claimExpiredEscrow(1)
      ).to.be.revertedWithCustomError(escrowManager, "EscrowNotExpired");
    });
  });
});