# CI/CD Pipeline Documentation

## Overview

Our GitHub Actions pipeline automates the build, test, and analysis workflow for the smart contract project. It runs on every push to `main` and on pull requests targeting `main`.

## Pipeline Stages

### 1. Checkout & Setup
The pipeline starts by checking out the repository with all git submodules (required for Foundry dependencies like forge-std and OpenZeppelin). It then installs Foundry using the official `foundry-rs/foundry-toolchain@v1` action, which provides `forge`, `cast`, and `anvil`.

### 2. Dependency Installation
`forge install` ensures all Foundry dependencies specified in `.gitmodules` are properly installed and available for compilation.

### 3. Contract Compilation
`forge build --sizes` compiles all Solidity contracts and reports their bytecode sizes. This step catches syntax errors, import issues, and contracts exceeding the EIP-170 size limit (24,576 bytes).

### 4. Test Execution
`forge test -vvv` runs all unit tests, fuzz tests, and invariant tests with verbose output. Fork tests are excluded from CI (via `--no-match-test "Fork"`) since they require RPC endpoints and API keys that may not be available in the CI environment. The verbose flag (`-vvv`) provides detailed stack traces for any failures.

### 5. Gas Report Generation
`forge test --gas-report` re-runs the tests and outputs a detailed gas consumption report for every external function call in the tested contracts. `forge snapshot` generates a `.gas-snapshot` file that can be used to track gas regressions over time.

### 6. Static Analysis with Slither
Slither is a Solidity static analysis framework that detects common vulnerabilities including reentrancy, unchecked return values, and access control issues. The pipeline installs it via pip and runs it against all project contracts, filtering out library code (`--filter-paths "lib/"`). This step helps catch security issues before they reach production.

## Key Design Decisions

- **Fork tests excluded from CI**: Fork tests require an Ethereum RPC endpoint (Alchemy/Infura API key). These are run locally by developers instead.
- **Slither with `|| true`**: Slither may report warnings in dependencies or informational findings that should not block the pipeline. Critical findings should still be reviewed manually.
- **Submodule checkout**: Foundry uses git submodules for dependency management, so `submodules: recursive` is required for the checkout step.
