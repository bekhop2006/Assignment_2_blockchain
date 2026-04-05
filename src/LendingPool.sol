// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LendingPool {
    using SafeERC20 for IERC20;

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint256 public constant LTV = 75; // 75%
    uint256 public constant LIQUIDATION_THRESHOLD = 80; // 80% for health
    uint256 public constant INTEREST_RATE = 10; // 10% per year, in basis points? Wait, simple

    // For simplicity, interest per second = rate / 365 days
    uint256 public constant SECONDS_PER_YEAR = 365 * 24 * 3600;
    uint256 public interestRatePerSecond = INTEREST_RATE * 1e18 / 100 / SECONDS_PER_YEAR; // 10% per year

    // Mock price, assume borrowToken is stable
    uint256 public collateralPrice = 1e18; // 1 USD per collateral

    struct UserPosition {
        uint256 deposited;
        uint256 borrowed;
        uint256 lastUpdate;
    }

    mapping(address => UserPosition) public positions;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, uint256 debtPaid, uint256 collateralSeized);

    constructor(address _collateral, address _borrow) {
        collateralToken = IERC20(_collateral);
        borrowToken = IERC20(_borrow);
        owner = msg.sender;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        positions[msg.sender].deposited += amount;
        positions[msg.sender].lastUpdate = block.timestamp;
        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        UserPosition storage pos = positions[msg.sender];
        require(pos.deposited > 0, "No collateral");
        uint256 maxBorrow = (pos.deposited * collateralPrice * LTV / 100) / 1e18;
        uint256 currentBorrow = _getCurrentBorrow(msg.sender);
        require(currentBorrow + amount <= maxBorrow, "Exceeds LTV");
        borrowToken.safeTransfer(msg.sender, amount);
        pos.borrowed += amount;
        pos.lastUpdate = block.timestamp;
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        UserPosition storage pos = positions[msg.sender];
        uint256 currentBorrow = _getCurrentBorrow(msg.sender);
        require(amount <= currentBorrow, "Repay too much");
        borrowToken.safeTransferFrom(msg.sender, address(this), amount);
        pos.borrowed = currentBorrow > amount ? currentBorrow - amount : 0;
        pos.lastUpdate = block.timestamp;
        emit Repaid(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        UserPosition storage pos = positions[msg.sender];
        uint256 currentBorrow = _getCurrentBorrow(msg.sender);
        uint256 maxWithdraw = pos.deposited - (currentBorrow * 100 * 1e18 / LTV) / collateralPrice;
        require(amount <= maxWithdraw, "Would violate LTV");
        pos.deposited -= amount;
        collateralToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function liquidate(address user) external {
        UserPosition storage pos = positions[user];
        uint256 health = getHealthFactor(user);
        require(health < 1e18, "Not undercollateralized");
        uint256 currentBorrow = _getCurrentBorrow(user);
        // Pay debt, seize collateral
        borrowToken.safeTransferFrom(msg.sender, address(this), currentBorrow);
        collateralToken.safeTransfer(msg.sender, pos.deposited);
        emit Liquidated(user, currentBorrow, pos.deposited);
        // Reset position
        pos.deposited = 0;
        pos.borrowed = 0;
    }

    function getHealthFactor(address user) public view returns (uint256) {
        UserPosition storage pos = positions[user];
        if (pos.borrowed == 0) return type(uint256).max;
        uint256 currentBorrow = _getCurrentBorrow(user);
        uint256 collateralValue = pos.deposited * collateralPrice / 1e18;
        return collateralValue * 1e18 / currentBorrow;
    }

    function _getCurrentBorrow(address user) internal view returns (uint256) {
        UserPosition storage pos = positions[user];
        uint256 timeElapsed = block.timestamp - pos.lastUpdate;
        uint256 interest = pos.borrowed * interestRatePerSecond * timeElapsed / 1e18;
        return pos.borrowed + interest;
    }

    function getCurrentBorrow(address user) public view returns (uint256) {
        return _getCurrentBorrow(user);
    }

    function getDeposited(address user) public view returns (uint256) {
        return positions[user].deposited;
    }

    function getBorrowed(address user) public view returns (uint256) {
        return positions[user].borrowed;
    }

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // For testing price changes (simulates oracle)
    function setCollateralPrice(uint256 price) public onlyOwner {
        collateralPrice = price;
    }
}