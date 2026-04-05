# AMM Mathematical Analysis

## 1. Derivation of the Constant Product Formula

The constant product formula, `x · y = k`, is the foundation of automated market makers (AMMs) like Uniswap V2. Here, `x` and `y` represent the reserves of two tokens in the liquidity pool, and `k` is the invariant that must be preserved (or increased) after every trade.

### Why It Works

The formula creates a hyperbolic pricing curve that guarantees liquidity at all price levels. As one token is bought from the pool, its reserve decreases, making it exponentially more expensive — this naturally prevents the pool from being fully drained.

For a swap of `Δx` amount of token A for `Δy` of token B:

```
(x + Δx) · (y - Δy) = k
```

Solving for `Δy`:

```
Δy = (y · Δx) / (x + Δx)
```

This can be derived step by step:

1. Start: `x · y = k`
2. After swap: `(x + Δx) · (y - Δy) = k`
3. Expand: `x·y - x·Δy + Δx·y - Δx·Δy = k`
4. Since `x·y = k`: `-x·Δy + Δx·y - Δx·Δy = 0`
5. Factor: `Δy · (x + Δx) = Δx · y`
6. Solve: `Δy = (Δx · y) / (x + Δx)`

The key property is that this formula provides continuous liquidity without requiring an order book. The price is determined algorithmically from the ratio of reserves: `price_A = y / x`.

### Geometric Interpretation

The constant product curve is a rectangular hyperbola in the (x, y) plane. Every trade moves the state along this curve. The slope at any point gives the marginal exchange rate, while the actual trade price is the secant line between the pre-trade and post-trade states — this difference is the source of price impact.

---

## 2. How the 0.3% Fee Affects the Invariant k

In practice, AMMs charge a trading fee (0.3% in Uniswap V2 and our implementation) on every swap. This fee is retained in the pool and causes the invariant `k` to increase over time.

### Mechanism

When a user swaps with fee `f = 0.003`:

- The effective input is `Δx_eff = Δx · (1 - f) = Δx · 0.997`
- The output is calculated as: `Δy = (y · Δx_eff) / (x + Δx_eff)`

However, the full `Δx` (not just `Δx_eff`) enters the pool. So the new reserves are:

```
x' = x + Δx       (full amount deposited)
y' = y - Δy        (output based on reduced effective input)
```

The new `k'` becomes:

```
k' = x' · y' = (x + Δx) · (y - Δy)
```

Since `Δy` was calculated using `Δx_eff < Δx`, we get:

```
k' = (x + Δx) · y - (x + Δx) · Δy
   = (x + Δx) · y - (x + Δx) · (y · Δx · 0.997) / (x + Δx · 0.997)
```

After simplification, `k' > k` because the fee portion (`Δx · 0.003`) stays in the pool as additional reserves without a corresponding decrease in the other token. Over many trades, `k` grows monotonically, representing accumulated fee revenue for liquidity providers.

### Numerical Example

With reserves x=1000, y=1000 (k=1,000,000):
- User swaps Δx=100 of token A
- Effective input: 100 × 0.997 = 99.7
- Output: (1000 × 99.7) / (1000 + 99.7) = 90.66
- New reserves: x'=1100, y'=909.34
- New k' = 1100 × 909.34 = 1,000,274 > 1,000,000

---

## 3. Impermanent Loss

Impermanent loss (IL) is the difference in value between holding tokens in an AMM pool versus simply holding them in a wallet. It occurs whenever the price ratio of the pooled tokens changes.

### Derivation

Assume an LP deposits tokens A and B at initial reserves `(x₀, y₀)` with initial price `P₀ = y₀ / x₀`.

If the external price of A relative to B changes to `P₁ = P₀ · p` (where `p` is the price multiplier), arbitrageurs will trade until the pool's internal price matches. The constant product constraint gives:

```
x₁ · y₁ = k = x₀ · y₀
y₁ / x₁ = P₁ = p · P₀ = p · (y₀ / x₀)
```

Solving:
```
x₁ = x₀ / √p
y₁ = y₀ · √p
```

The value of the LP position at new prices:
```
V_pool = x₁ · P₁ + y₁ = (x₀ / √p) · p · P₀ + y₀ · √p
       = x₀ · P₀ · √p + y₀ · √p
       = √p · (x₀ · P₀ + y₀)
       = 2 · √p · V₀ / 2    (since initial value V₀ = x₀·P₀ + y₀ = 2·y₀)
```

Wait — more precisely, since `x₀·P₀ = y₀`, we have `V₀ = 2·y₀`:
```
V_pool = √p · 2 · y₀ = 2 · y₀ · √p
```

The value if holding (not providing liquidity):
```
V_hold = x₀ · P₁ + y₀ = x₀ · p · P₀ + y₀ = y₀ · p + y₀ = y₀ · (1 + p)
```

The IL ratio:
```
IL = V_pool / V_hold - 1 = (2·√p) / (1 + p) - 1
```

### Calculation for 2× Price Change

When `p = 2`:

```
IL = 2·√2 / (1 + 2) - 1
   = 2·1.4142 / 3 - 1
   = 2.8284 / 3 - 1
   = 0.9428 - 1
   = -0.0572
```

**IL ≈ -5.72%**, meaning the LP loses about 5.72% compared to simply holding.

For other values:
- p = 1.5: IL ≈ -1.03%
- p = 3: IL ≈ -13.4%
- p = 5: IL ≈ -25.5%

IL is "impermanent" because if the price returns to the original ratio, the loss disappears. However, if the LP withdraws while prices have diverged, the loss is realized.

---

## 4. Price Impact as a Function of Trade Size

Price impact measures how much a trade moves the market price. In a constant product AMM, larger trades relative to pool reserves cause disproportionately worse execution prices.

### Formula

For a trade of size `Δx` against reserve `x`, the effective execution price versus the spot price:

```
Spot price: P_spot = y / x
Execution price: P_exec = Δy / Δx = y / (x + Δx)    (ignoring fees)
Price impact: PI = 1 - P_exec / P_spot = Δx / (x + Δx)
```

As a percentage of reserve: if `r = Δx / x`, then:

```
PI = r / (1 + r)
```

### Examples

| Trade size (% of reserve) | Price Impact |
|---|---|
| 1% | 0.99% |
| 5% | 4.76% |
| 10% | 9.09% |
| 50% | 33.3% |

This shows that small trades experience near-zero slippage, but large trades suffer significantly. This is why slippage protection (`minAmountOut`) is essential.

---

## 5. Comparison with Uniswap V2

Our AMM implements the core constant product mechanism matching Uniswap V2's fundamental design. However, several features present in Uniswap V2 are missing:

| Feature | Our AMM | Uniswap V2 |
|---|---|---|
| Constant product formula | ✅ | ✅ |
| 0.3% swap fee | ✅ | ✅ |
| LP tokens | ✅ | ✅ |
| Slippage protection | ✅ | ✅ |
| Factory pattern (create pairs dynamically) | ❌ | ✅ |
| TWAP (time-weighted average price) oracle | ❌ | ✅ |
| Flash swaps (borrow without collateral within tx) | ❌ | ✅ |
| Protocol fee switch (1/6 of LP fees) | ❌ | ✅ |
| Minimum liquidity lock (prevent zero-division) | ❌ | ✅ (1000 wei) |
| Permit (gasless approvals via EIP-2612) | ❌ | ✅ |
| Router contract (multi-hop swaps, ETH wrapping) | ❌ | ✅ |
| Reentrancy protection | ❌ | ✅ (lock modifier) |

### Key Differences

1. **TWAP Oracle**: Uniswap V2 accumulates price data every block, allowing other contracts to compute time-weighted average prices resistant to manipulation. Our AMM has no oracle functionality.

2. **Factory Pattern**: Uniswap V2 uses a factory contract to deploy pair contracts permissionlessly. Our AMM is a single contract for one token pair.

3. **Minimum Liquidity**: Uniswap V2 permanently locks the first 1000 wei of LP tokens (sent to address(0)) to prevent division-by-zero attacks and share inflation attacks. Our AMM does not implement this.

4. **Flash Swaps**: Uniswap V2 allows users to receive output tokens before paying input tokens within the same transaction, enabling arbitrage and liquidation without upfront capital.

5. **Reentrancy Guards**: Our AMM updates reserves before transferring tokens but lacks explicit reentrancy protection that Uniswap V2 employs via a lock modifier.

---

## Conclusion

The constant product AMM provides efficient, permissionless price discovery with guaranteed liquidity at all price levels. Small trades experience minimal slippage, while the 0.3% fee compensates LPs and grows the invariant k over time. However, LPs face impermanent loss when prices diverge. Our implementation captures the core mechanism but lacks production features like TWAP oracles, flash swaps, minimum liquidity locks, and reentrancy protection that make Uniswap V2 production-ready.
