import { expect } from "chai";
import { ethers } from "hardhat";
import { UserRegistry } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("UserRegistry", function () {
  let userRegistry: UserRegistry;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const UserRegistry = await ethers.getContractFactory("UserRegistry");
    userRegistry = await UserRegistry.deploy();
    await userRegistry.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await userRegistry.owner()).to.equal(owner.address);
    });
  });

  describe("Username Registration", function () {
    it("Should register a valid username", async function () {
      const username = "testuser123";
      
      await expect(userRegistry.connect(user1).registerUsername(username))
        .to.emit(userRegistry, "UsernameRegistered")
        .withArgs(user1.address, username, await time.latest() + 1);

      expect(await userRegistry.usernameToAddress(username)).to.equal(user1.address);
      expect(await userRegistry.addressToUsername(user1.address)).to.equal(username);
    });

    it("Should reject invalid usernames", async function () {
      // Too short
      await expect(
        userRegistry.connect(user1).registerUsername("test")
      ).to.be.revertedWithCustomError(userRegistry, "InvalidUsername");

      // Too long (33 characters)
      await expect(
        userRegistry.connect(user1).registerUsername("a".repeat(33))
      ).to.be.revertedWithCustomError(userRegistry, "InvalidUsername");

      // Invalid characters
      await expect(
        userRegistry.connect(user1).registerUsername("test@user")
      ).to.be.revertedWithCustomError(userRegistry, "InvalidUsername");

      await expect(
        userRegistry.connect(user1).registerUsername("test-user")
      ).to.be.revertedWithCustomError(userRegistry, "InvalidUsername");
    });

    it("Should reject duplicate usernames", async function () {
      const username = "testuser123";
      
      await userRegistry.connect(user1).registerUsername(username);
      
      await expect(
        userRegistry.connect(user2).registerUsername(username)
      ).to.be.revertedWithCustomError(userRegistry, "UsernameAlreadyTaken");
    });

    it("Should allow updating username if user already has one", async function () {
      await userRegistry.connect(user1).registerUsername("oldusername");
      
      // Fast forward past cooldown
      await time.increase(7 * 24 * 60 * 60 + 1);
      
      await userRegistry.connect(user1).registerUsername("newusername");
      
      expect(await userRegistry.addressToUsername(user1.address)).to.equal("newusername");
      expect(await userRegistry.usernameToAddress("oldusername")).to.equal(ethers.ZeroAddress);
    });
  });

  describe("Username Updates", function () {
    beforeEach(async function () {
      await userRegistry.connect(user1).registerUsername("originaluser");
    });

    it("Should update username after cooldown period", async function () {
      // Fast forward past cooldown
      await time.increase(7 * 24 * 60 * 60 + 1);

      await expect(userRegistry.connect(user1).updateUsername("newuser"))
        .to.emit(userRegistry, "UsernameUpdated")
        .withArgs(user1.address, "originaluser", "newuser", await time.latest() + 1);

      expect(await userRegistry.addressToUsername(user1.address)).to.equal("newuser");
    });

    it("Should reject update during cooldown period", async function () {
      await expect(
        userRegistry.connect(user1).updateUsername("newuser")
      ).to.be.revertedWithCustomError(userRegistry, "UpdateCooldownActive");
    });

    it("Should reject update to already taken username", async function () {
      await userRegistry.connect(user2).registerUsername("takenuser");
      
      await time.increase(7 * 24 * 60 * 60 + 1);
      
      await expect(
        userRegistry.connect(user1).updateUsername("takenuser")
      ).to.be.revertedWithCustomError(userRegistry, "UsernameAlreadyTaken");
    });

    it("Should reject update for user without username", async function () {
      await expect(
        userRegistry.connect(user2).updateUsername("newuser")
      ).to.be.revertedWithCustomError(userRegistry, "NoUsernameRegistered");
    });
  });

  describe("Username Removal", function () {
    it("Should remove username", async function () {
      await userRegistry.connect(user1).registerUsername("testuser");
      
      await expect(userRegistry.connect(user1).removeUsername())
        .to.emit(userRegistry, "UsernameRemoved")
        .withArgs(user1.address, "testuser", await time.latest() + 1);

      expect(await userRegistry.addressToUsername(user1.address)).to.equal("");
      expect(await userRegistry.usernameToAddress("testuser")).to.equal(ethers.ZeroAddress);
    });

    it("Should reject removal for user without username", async function () {
      await expect(
        userRegistry.connect(user1).removeUsername()
      ).to.be.revertedWithCustomError(userRegistry, "NoUsernameRegistered");
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await userRegistry.connect(user1).registerUsername("testuser");
    });

    it("Should get address by username", async function () {
      expect(await userRegistry.getAddressByUsername("testuser")).to.equal(user1.address);
    });

    it("Should revert for non-existent username", async function () {
      await expect(
        userRegistry.getAddressByUsername("nonexistent")
      ).to.be.revertedWithCustomError(userRegistry, "UsernameNotRegistered");
    });

    it("Should get username by address", async function () {
      expect(await userRegistry.getUsernameByAddress(user1.address)).to.equal("testuser");
    });

    it("Should check if username is registered", async function () {
      expect(await userRegistry.isUsernameRegistered("testuser")).to.be.true;
      expect(await userRegistry.isUsernameRegistered("nonexistent")).to.be.false;
    });

    it("Should check if address has username", async function () {
      expect(await userRegistry.hasUsername(user1.address)).to.be.true;
      expect(await userRegistry.hasUsername(user2.address)).to.be.false;
    });

    it("Should get remaining cooldown", async function () {
      const cooldown = await userRegistry.getRemainingCooldown(user1.address);
      expect(cooldown).to.be.closeTo(7 * 24 * 60 * 60, 5);

      await time.increase(3 * 24 * 60 * 60);
      
      const cooldown2 = await userRegistry.getRemainingCooldown(user1.address);
      expect(cooldown2).to.be.closeTo(4 * 24 * 60 * 60, 5);
    });
  });

  describe("Pause Functionality", function () {
    it("Should allow owner to pause", async function () {
      await userRegistry.pause();
      expect(await userRegistry.paused()).to.be.true;
    });

    it("Should prevent registration when paused", async function () {
      await userRegistry.pause();
      
      await expect(
        userRegistry.connect(user1).registerUsername("testuser")
      ).to.be.revertedWithCustomError(userRegistry, "EnforcedPause");
    });

    it("Should allow owner to unpause", async function () {
      await userRegistry.pause();
      await userRegistry.unpause();
      
      expect(await userRegistry.paused()).to.be.false;
      await userRegistry.connect(user1).registerUsername("testuser");
    });

    it("Should reject non-owner pause", async function () {
      await expect(
        userRegistry.connect(user1).pause()
      ).to.be.revertedWithCustomError(userRegistry, "OwnableUnauthorizedAccount");
    });
  });
});