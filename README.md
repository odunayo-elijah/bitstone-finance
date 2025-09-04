# BitStone Finance 🟠

## Institutional Bitcoin Collateral Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Clarity](https://img.shields.io/badge/Smart_Contract-Clarity-blue.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Blockchain-Stacks-orange.svg)](https://www.stacks.co/)

> *Transforming Bitcoin holdings into productive capital through secure collateralized loans*

BitStone Finance pioneers the next evolution of Bitcoin-native DeFi by creating a trustless lending infrastructure that maximizes capital efficiency while preserving Bitcoin's store-of-value properties.

## 🚀 Overview

BitStone Finance is a sophisticated decentralized lending platform built on Stacks that enables Bitcoin holders to unlock liquidity from their holdings without selling. Our protocol combines the security of Bitcoin with the programmability of Stacks to deliver institutional-grade lending infrastructure.

### Key Features

- **🔒 Bitcoin-First Design**: Native integration with Stacks layer for seamless Bitcoin collateral management
- **🛡️ Institutional Security**: Multi-signature governance with time-locked protocol upgrades
- **⚡ Dynamic Risk Engine**: AI-powered collateral monitoring with predictive analytics
- **📈 Yield Optimization**: Automated interest rate discovery based on market conditions
- **🔧 Modular Architecture**: Upgradeable contract system supporting future asset classes

## 🏗️ Architecture

### Core Components

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Loan Engine  │    │  Risk Manager   │    │ Price Oracle    │
│                 │    │                 │    │                 │
│ • Loan Creation │    │ • Collateral    │    │ • Asset Prices  │
│ • Repayment     │    │   Monitoring    │    │ • Price Feeds   │
│ • Interest Calc │    │ • Liquidation   │    │ • Validation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Protocol Core   │
                    │                 │
                    │ • Governance    │
                    │ • Parameters    │
                    │ • State Mgmt    │
                    └─────────────────┘
```

### Smart Contract Structure

- **Protocol Management**: Initialization, parameter updates, governance functions
- **Lending Operations**: Loan creation, repayment, liquidation mechanisms
- **Risk Management**: Collateral ratio calculations, liquidation triggers
- **Data Storage**: Loan registry, user positions, price feeds

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/) (v18 or higher)
- [Clarinet](https://github.com/hirosystems/clarinet) (latest version)
- [Git](https://git-scm.com/)

## 🛠️ Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/odunayo-elijah/bitstone-finance.git
   cd bitstone-finance
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify installation**

   ```bash
   clarinet --version
   npm --version
   ```

## 🚀 Quick Start

### Development Environment

1. **Check contract syntax**

   ```bash
   clarinet check
   ```

2. **Run tests**

   ```bash
   npm test
   ```

3. **Watch mode for development**

   ```bash
   npm run test:watch
   ```

4. **Generate test coverage report**

   ```bash
   npm run test:report
   ```

### Contract Interaction

#### Initialize Protocol

```clarity
(contract-call? .bitstone-finance initialize-protocol)
```

#### Set Asset Price (Owner only)

```clarity
(contract-call? .bitstone-finance update-asset-price "BTC" u5000000000)
```

#### Create Loan

```clarity
(contract-call? .bitstone-finance create-loan u100000000 u50000000)
```

#### Repay Loan

```clarity
(contract-call? .bitstone-finance repay-loan u1 u52500000)
```

## 📊 Protocol Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| Minimum Collateral Ratio | 150% | Required overcollateralization |
| Liquidation Threshold | 120% | Triggers liquidation process |
| Base Interest Rate | 5% | Annual interest rate |
| Maximum Active Loans | 10 | Per user limit |

## 🔧 Configuration

### Network Settings

The protocol supports multiple network deployments:

- **Devnet**: Local development and testing
- **Testnet**: Public testing environment  
- **Mainnet**: Production deployment

Configuration files are located in the `settings/` directory.

### Custom Parameters

Protocol administrators can adjust key parameters:

```clarity
;; Update collateral requirements
(contract-call? .bitstone-finance set-collateral-ratio u175)

;; Update liquidation threshold
(contract-call? .bitstone-finance set-liquidation-threshold u125)
```

## 🧪 Testing

Our comprehensive test suite ensures protocol reliability and security.

### Run All Tests

```bash
npm test
```

### Test Coverage

```bash
npm run test:report
```

### Continuous Testing

```bash
npm run test:watch
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: Cross-function interactions
- **Security Tests**: Attack vector validation
- **Edge Cases**: Boundary condition testing

## 📖 API Reference

### Read-Only Functions

#### `get-loan-info`

```clarity
(define-read-only (get-loan-info (loan-id uint)))
```

Returns detailed information about a specific loan including accrued interest.

#### `get-user-positions`

```clarity
(define-read-only (get-user-positions (user principal)))
```

Returns all active loans for a given user.

#### `get-protocol-stats`

```clarity
(define-read-only (get-protocol-stats))
```

Returns protocol-wide statistics and current parameters.

#### `get-asset-price`

```clarity
(define-read-only (get-asset-price (asset (string-ascii 3))))
```

Returns current price for supported assets.

### Public Functions

#### `create-loan`

```clarity
(define-public (create-loan (collateral-amount uint) (requested-amount uint)))
```

Creates a new collateralized loan position.

#### `repay-loan`

```clarity
(define-public (repay-loan (loan-id uint) (payment-amount uint)))
```

Repays an existing loan and releases collateral.

#### `liquidate-loan`

```clarity
(define-public (liquidate-loan (loan-id uint)))
```

Liquidates an undercollateralized loan position.

## 🔒 Security

### Audit Status

- **Internal Review**: ✅ Complete
- **External Audit**: 🔄 In Progress
- **Bug Bounty**: 📋 Planned

### Security Features

- **Access Control**: Owner-only administrative functions
- **Input Validation**: Comprehensive parameter checking
- **Overflow Protection**: Safe arithmetic operations
- **State Consistency**: Atomic transaction handling

### Known Limitations

1. **Price Oracle Dependency**: Relies on external price feeds
2. **Liquidation Risk**: Market volatility may affect collateral value
3. **Smart Contract Risk**: Inherent blockchain-based risks

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Include comprehensive tests
- Document new functions
- Maintain consistent formatting

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌐 Resources

### Documentation

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Guide](https://github.com/hirosystems/clarinet)
