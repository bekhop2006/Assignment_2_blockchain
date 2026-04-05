# Assignment 2 — DeFi Protocol Development (AMM / DEX)

Blockchain Technologies 2, Weeks 3-5

## Project Overview

This project contains:
- ERC-20 token contracts with unit, fuzz, and invariant tests
- Constant Product AMM (x * y = k) with LP tokens
- Lending/Borrowing protocol with liquidation
- Fork tests against Ethereum mainnet (Uniswap V2, USDC)
- CI/CD pipeline with GitHub Actions and Slither

## Prerequisites

- Foundry (forge, cast, anvil): https://book.getfoundry.sh/getting-started/installation
- Alchemy or Infura API key for fork tests: https://www.alchemy.com/

## Setup

```shell
git clone <repo-url>
cd Assignment_2
forge install
forge build
```

## Running Tests

Run all tests except fork tests (no RPC needed):

```shell
forge test -vvv --no-match-contract "ForkTest"
```

Run fork tests (requires Ethereum mainnet RPC):

```shell
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
forge test -vvv --match-contract "ForkTest"
```

Run all tests at once:

```shell
export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
forge test -vvv
```

## Gas Report

```shell
forge test --gas-report --no-match-contract "ForkTest"
```

## Coverage Report

```shell
forge coverage
```

## Gas Snapshot

```shell
forge snapshot --no-match-contract "ForkTest"
```

## Project Structure

```
src/
  SimpleToken.sol     - ERC-20 token (Task 1)
  Tokens.sol          - TokenA and TokenB for AMM/Lending
  LPToken.sol         - LP token with access control
  AMM.sol             - Constant Product AMM (Task 3)
  LendingPool.sol     - Lending/borrowing protocol (Task 5)

test/
  SimpleToken.t.sol   - 13 tests (unit + fuzz + invariant)
  AMM.t.sol           - 15 tests (unit + fuzz)
  LendingPool.t.sol   - 12 tests
  ForkTest.t.sol      - 3 mainnet fork tests (Task 2)

docs/
  AMM_Analysis.md             - AMM mathematical analysis (Task 4)
  LendingPool_Workflow.md     - Lending pool workflow diagram
  Fuzz_vs_Unit_Testing.md     - Fuzz vs unit testing explanation
  Fork_Testing.md             - Fork testing explanation
  CI_CD_Pipeline.md           - CI/CD pipeline documentation
  REPORT.md                   - Full assignment report

.github/workflows/test.yml   - GitHub Actions CI pipeline (Task 6)
```

## Built With

- Foundry (Forge, Cast, Anvil)
- OpenZeppelin Contracts
- Solidity 0.8.19
