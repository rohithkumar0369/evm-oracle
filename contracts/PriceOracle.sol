// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceOracle
 * @notice Aggregates token prices from Chainlink feeds
 * @dev Uses Chainlink price feeds for accurate, decentralized price data
 */
contract PriceOracle {
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint256 decimals;
    }
    
    // Token symbol => Chainlink aggregator
    mapping(string => AggregatorV3Interface) public priceFeeds;
    
    // Token symbol => Latest price data
    mapping(string => PriceData) public latestPrices;
    
    // Supported tokens
    string[] public supportedTokens;
    
    address public owner;
    
    event PriceUpdated(
        string indexed symbol,
        uint256 price,
        uint256 timestamp
    );
    
    event PriceFeedAdded(
        string indexed symbol,
        address priceFeed
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @notice Add a Chainlink price feed for a token
     * @param symbol Token symbol (e.g., "ETH", "BTC")
     * @param priceFeedAddress Chainlink aggregator address
     */
    function addPriceFeed(
        string calldata symbol,
        address priceFeedAddress
    ) external onlyOwner {
        require(priceFeedAddress != address(0), "Invalid address");
        require(
            address(priceFeeds[symbol]) == address(0),
            "Feed already exists"
        );
        
        priceFeeds[symbol] = AggregatorV3Interface(priceFeedAddress);
        supportedTokens.push(symbol);
        
        emit PriceFeedAdded(symbol, priceFeedAddress);
    }
    
    /**
     * @notice Update price for a token
     * @param symbol Token symbol to update
     */
    function updatePrice(string calldata symbol) external {
        AggregatorV3Interface priceFeed = priceFeeds[symbol];
        require(address(priceFeed) != address(0), "Price feed not found");
        
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        require(answer > 0, "Invalid price");
        require(updatedAt > 0, "Incomplete round");
        require(answeredInRound >= roundId, "Stale price");
        
        uint256 decimals = priceFeed.decimals();
        
        latestPrices[symbol] = PriceData({
            price: uint256(answer),
            timestamp: updatedAt,
            decimals: decimals
        });
        
        emit PriceUpdated(symbol, uint256(answer), updatedAt);
    }
    
    /**
     * @notice Get latest price for a token
     * @param symbol Token symbol
     * @return price Latest price
     * @return timestamp When the price was updated
     * @return decimals Price decimals
     */
    function getPrice(string calldata symbol)
        external
        view
        returns (
            uint256 price,
            uint256 timestamp,
            uint256 decimals
        )
    {
        PriceData memory data = latestPrices[symbol];
        require(data.timestamp > 0, "Price not available");
        
        return (data.price, data.timestamp, data.decimals);
    }
    
    /**
     * @notice Get price in USD with 8 decimals
     * @param symbol Token symbol
     * @return priceUSD Price in USD (8 decimals)
     */
    function getPriceUSD(string calldata symbol)
        external
        view
        returns (uint256 priceUSD)
    {
        PriceData memory data = latestPrices[symbol];
        require(data.timestamp > 0, "Price not available");
        
        // Normalize to 8 decimals (standard for USD prices)
        if (data.decimals > 8) {
            priceUSD = data.price / (10 ** (data.decimals - 8));
        } else if (data.decimals < 8) {
            priceUSD = data.price * (10 ** (8 - data.decimals));
        } else {
            priceUSD = data.price;
        }
    }
    
    /**
     * @notice Check if price is stale (older than 1 hour)
     * @param symbol Token symbol
     * @return isStale True if price is stale
     */
    function isPriceStale(string calldata symbol)
        external
        view
        returns (bool isStale)
    {
        PriceData memory data = latestPrices[symbol];
        if (data.timestamp == 0) return true;
        
        return block.timestamp - data.timestamp > 1 hours;
    }
    
    /**
     * @notice Get all supported tokens
     * @return tokens Array of token symbols
     */
    function getSupportedTokens()
        external
        view
        returns (string[] memory tokens)
    {
        return supportedTokens;
    }
    
    /**
     * @notice Update multiple token prices in one transaction
     * @param symbols Array of token symbols to update
     */
    function updatePrices(string[] calldata symbols) external {
        for (uint256 i = 0; i < symbols.length; i++) {
            this.updatePrice(symbols[i]);
        }
    }
}