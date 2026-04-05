# Fuzz Testing vs Unit Testing — When to Use Each

## Unit Testing

Unit tests are deterministic tests where the developer manually specifies exact input values and expected outputs. Each test case covers a single, specific scenario — for example, transferring exactly 50 tokens from Alice to Bob and asserting the balances change correctly.

**Strengths:**
- Easy to write and understand
- Deterministic and reproducible
- Good for testing known edge cases (zero amounts, max values, unauthorized access)
- Clear intent — each test documents an expected behavior

**Limitations:**
- Only tests the exact inputs the developer thought of
- May miss unexpected edge cases or boundary conditions
- Developer bias — we tend to test the "happy path" and obvious error cases

In our project, unit tests verify specific behaviors like minting tokens, transferring with insufficient balance, and ensuring approval works correctly. They are essential for establishing that core functionality works as expected.

## Fuzz Testing

Fuzz testing (property-based testing) lets the testing framework automatically generate random inputs across a wide range of values. Instead of testing one specific transfer amount, a fuzz test runs hundreds or thousands of iterations with different randomly generated values. The developer defines properties that must always hold true, rather than specific input-output pairs.

**Strengths:**
- Discovers edge cases the developer never considered
- Tests properties across a vast input space (Foundry runs 256+ iterations by default)
- Catches overflow, underflow, and boundary issues automatically
- Especially valuable for mathematical functions like AMM swap calculations

**Limitations:**
- Harder to write — requires thinking in terms of properties/invariants rather than specific cases
- Random inputs may not cover very specific corner cases without proper bounding
- Failures can be harder to debug since inputs are auto-generated
- May give false confidence if properties are too weak

## When to Use Each

**Use unit tests** when you need to verify specific, known scenarios: access control, exact revert messages, event emissions, and integration flows where the sequence of operations matters.

**Use fuzz tests** when you want to verify that a property holds across all possible inputs: "transfers never create tokens out of thin air," "swap output is always less than reserves," or "the AMM invariant k never decreases." Fuzz testing is particularly valuable for financial contracts like AMMs and lending pools where mathematical correctness across all input ranges is critical.

**Best practice:** Use both together. Unit tests provide baseline coverage and document expected behavior, while fuzz tests provide confidence that properties hold across the entire input space. In our project, we use unit tests for specific flows (deposit → borrow → repay) and fuzz tests for mathematical properties (swap amounts, transfer invariants).
