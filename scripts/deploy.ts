import { ethers } from "hardhat";

async function main() {
  console.log("Deploying PriceOracle...");

  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  const oracle = await PriceOracle.deploy();
  await oracle.waitForDeployment();

  const oracle_address = await oracle.getAddress();

  console.log(`PriceOracle deployed to: ${oracle_address}`);

  // Add Chainlink price feeds (Sepolia testnet addresses)
  const priceFeeds = {
    "ETH": "0x694AA1769357215DE4FAC081bf1f309aDC325306", // ETH/USD
    "BTC": "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43", // BTC/USD
    "LINK": "0xc59E3633BAAC79493d908e63626716e204A45EdF", // LINK/USD
    "USDC": "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", // USDC/USD
  };

  console.log("\nAdding price feeds...");
  for (const [symbol, address] of Object.entries(priceFeeds)) {
    const tx = await oracle.addPriceFeed(symbol, address);
    await tx.wait();
    console.log(`✅ Added ${symbol} price feed`);
  }

  console.log("\nUpdating initial prices...");
  for (const symbol of Object.keys(priceFeeds)) {
    const tx = await oracle.updatePrice(symbol);
    await tx.wait();
    
    const [price, timestamp, decimals] = await oracle.getPrice(symbol);
    console.log(`✅ ${symbol}: $${ethers.formatUnits(price, decimals)}`);
  }

  console.log("\n🎉 Deployment complete!");
  console.log(`\nContract: ${oracle_address}`);
  console.log("\nVerify with:");
  console.log(`npx hardhat verify --network sepolia ${oracle_address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});