# Fork Testing — Benefits and Limitations

## How vm.createSelectFork and vm.rollFork Work

### vm.createSelectFork

`vm.createSelectFork("mainnet")` creates a local fork of the Ethereum mainnet by connecting to an RPC endpoint (configured in `foundry.toml` or via environment variable `ETH_RPC_URL`). It copies the entire blockchain state at the latest block into a local cache, allowing tests to read real contract storage, call deployed contracts, and simulate transactions — all without spending gas or affecting the live network.

The function returns a fork ID that can be used to switch between multiple forks (e.g., mainnet and a testnet) within the same test using `vm.selectFork(forkId)`. An optional block number parameter allows forking from a specific historical block: `vm.createSelectFork("mainnet", 18000000)`.

### vm.rollFork

`vm.rollFork(blockNumber)` changes the active fork's block number to a different point in time. This is useful for testing how contract state changes across blocks — for example, checking the USDC total supply at different points in history, or simulating how a protocol behaves before and after a specific on-chain event (upgrade, hack, governance vote).

After rolling, all subsequent calls to forked contracts will read state from the new block number.

## Benefits of Fork Testing

1. **Test against real state**: Fork testing allows interaction with actual deployed contracts (Uniswap, USDC, Aave) with their real storage and balances, ensuring tests reflect production behavior rather than simplified mocks.

2. **No deployment cost**: Developers can test integration with complex protocols without deploying mock versions of every dependency, saving significant development time.

3. **Historical analysis**: Using `vm.rollFork`, developers can test their contracts against the blockchain state at any historical block, enabling investigation of past incidents or verification of behavior during specific market conditions.

4. **Realistic integration tests**: Fork tests catch issues that mock-based tests miss — such as token contracts with non-standard behavior, protocol-specific edge cases, or state-dependent logic in deployed contracts.

## Limitations of Fork Testing

1. **RPC dependency**: Fork tests require an RPC endpoint (Alchemy, Infura), which introduces external dependency. Tests may fail if the RPC service is down or rate-limited.

2. **Slow execution**: Fetching state from an RPC node is orders of magnitude slower than local tests. Each storage slot read requires a network request (though Foundry caches results).

3. **Non-deterministic**: The "latest" block changes constantly, so tests run at different times may produce different results unless a specific block number is pinned.

4. **No guarantee of future state**: Fork tests validate against current or past state. They cannot predict how deployed contracts will behave after future upgrades or governance changes.

5. **Cache staleness**: Foundry caches RPC responses locally. If the cache becomes stale or corrupted, tests may behave unexpectedly.

Fork testing is most valuable when building contracts that integrate with existing DeFi protocols, as it provides high confidence that on-chain interactions work correctly without risking real funds.
