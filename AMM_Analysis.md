# AMM Mathematical Analysis

## Derivation of the Constant Product Formula

The constant product formula, \( x \cdot y = k \), is the foundation of automated market makers (AMMs) like Uniswap. Here, \( x \) and \( y \) represent the reserves of two tokens in the liquidity pool.

### Why It Works

The formula ensures that the product of the reserves remains constant after trades, maintaining a balance. When a user swaps token A for token B, the amount of A increases in the pool, and B decreases. The new product \( x' \cdot y' \) should equal the original \( k \).

For a swap of \( \Delta x \) amount of token A for \( \Delta y \) of token B:

\[ (x + \Delta x) \cdot (y - \Delta y) = k \]

Solving for \( \Delta y \):

\[ \Delta y = \frac{y \cdot \Delta x}{x + \Delta x} \]

This formula provides the swap amount without requiring an order book.

## How the 0.3% Fee Affects the Invariant k

In practice, AMMs charge a fee (0.3% in Uniswap V2) on swaps to incentivize liquidity providers. The fee increases the invariant k over time.

When a swap occurs with fee \( f = 0.003 \):

The effective input after fee is \( \Delta x \cdot (1 - f) \).

The output \( \Delta y = \frac{y \cdot \Delta x \cdot (1 - f)}{x + \Delta x \cdot (1 - f)} \)

The new k' = (x + \Delta x) \cdot (y - \Delta y) > k, since some of \Delta x is kept as fee, effectively increasing reserves.

Over time, fees accumulate, making k grow, benefiting LPs.

## Impermanent Loss

Impermanent loss (IL) occurs when the price of tokens in the pool changes relative to when liquidity was added.

Suppose a LP adds equal value of token A and B when price is 1:1. If price of A doubles, the pool rebalances.

The value of LP's share decreases compared to holding tokens.

Formula for IL when price changes by factor p:

IL = 2 \sqrt{p} / (1 + p) - 1

For p=2, IL ≈ 0.086 (8.6% loss).

IL is the opportunity cost of not holding the tokens directly.

## Price Impact

Price impact is the change in price due to the trade size.

For a trade of size \Delta x relative to reserve x, the price impact is approximately \Delta x / x.

In constant product, the effective price is dy/dx = y/x for small trades, but for large, it's higher.

Compare to Uniswap V2: Our AMM is similar, but Uniswap has multiple pools, flash swaps, etc. Missing features: time-weighted averages, governance, multiple fee tiers.

## Conclusion

The constant product AMM provides efficient price discovery with low slippage for small trades, but high impact for large ones. Fees ensure sustainability, but IL is a risk for LPs.