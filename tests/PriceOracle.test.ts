import { expect } from "chai";
import { ethers } from "hardhat";
import { PriceOracle } from "../typechain-types";

describe("PriceOracle", function () {
  let oracle: PriceOracle;
  let owner: any;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    oracle = await PriceOracle.deploy();
    await oracle.waitForDeployment();
  });

  it("Should deploy successfully", async function () {
    expect(await oracle.owner()).to.equal(owner.address);
  });

  it("Should add price feed", async function () {
    // Mock Chainlink aggregator address
    const mockFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
    
    await oracle.addPriceFeed("ETH", mockFeed);
    
    const feed = await oracle.priceFeeds("ETH");
    expect(feed).to.equal(mockFeed);
  });

  it("Should reject invalid price feed address", async function () {
    await expect(
      oracle.addPriceFeed("ETH", ethers.ZeroAddress)
    ).to.be.revertedWith("Invalid address");
  });

  it("Should not allow duplicate price feeds", async function () {
    const mockFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
    
    await oracle.addPriceFeed("ETH", mockFeed);
    
    await expect(
      oracle.addPriceFeed("ETH", mockFeed)
    ).to.be.revertedWith("Feed already exists");
  });

  it("Should return supported tokens", async function () {
    const mockFeed1 = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
    const mockFeed2 = "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43";
    
    await oracle.addPriceFeed("ETH", mockFeed1);
    await oracle.addPriceFeed("BTC", mockFeed2);
    
    const tokens = await oracle.getSupportedTokens();
    expect(tokens).to.deep.equal(["ETH", "BTC"]);
  });

  // Add more tests for price updates with mocked Chainlink responses
});