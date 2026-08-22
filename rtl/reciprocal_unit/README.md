# FP32 Reciprocal Unit — Design & Verification Report

## 1. Objective

Implement a combinational IEEE-754 single-precision (FP32) reciprocal unit
(`reciprocal = 1 / x`) in Verilog, targeting **≤ 0.5% relative error**
against an ideal reciprocal, using a **LUT seed + one Newton–Raphson (NR)
iteration** — the standard hardware approach used in GPU/DSP reciprocal
approximation units, instead of a full division algorithm (e.g. long
division / Goldschmidt / SRT).

---

## 2. Algorithm / Approach

### 2.1 Why LUT + Newton–Raphson

Direct hardware division is expensive (iterative, multi-cycle, large area).
The standard alternative:

1. Decompose `x = M * 2^e` (FP32 mantissa/exponent split).
2. Get a coarse initial estimate `y0 ≈ 1/M` from a small lookup table.
3. Refine `y0` with one (or more) Newton–Raphson iterations for the
   reciprocal function:

```
y1 = y0 * (2 - M * y0)
```

Each NR iteration for reciprocal roughly **doubles the number of correct
bits**, so a LUT seed good to ~4–5 bits + one iteration can land in the
~8–10 correct bit range — enough for sub-1% relative error, which is what
the 0.5% tolerance target required.

4. Recombine the refined mantissa reciprocal with the correctly
   re-derived exponent to reconstruct the final FP32 result.

This is a **single NR pass**, not an iterative/multi-cycle design — the
whole thing is combinational logic in this implementation.

### 2.2 Step-by-step breakdown (matches RTL structure)

| Stage | Operation | Purpose |
|---|---|---|
| 1 | Unpack `x` into `sign`, `exponent`, `fraction` | Standard FP32 field split |
| 2 | `unbiased_exp = exponent - 127` | Recover true exponent `e` where `x = M·2^e` |
| 3 | `lut_index = fraction[22:19]` (top 4 mantissa bits) | Coarse index into seed table |
| 4 | `reciprocal_lut` lookup → `y0` | Initial FP32 estimate of `1/M` |
| 5 | Build `mantissa_fp32 = {0, 127, fraction}` | Re-pack `M` (the 1.x mantissa of `x`) as a standalone FP32 number with exponent forced to 0 (i.e. value in `[1,2)`) so it can be multiplied directly |
| 6 | `mul1 = M * y0` (`fp32_multiplier`) | First half of NR correction term |
| 7 | Negate `mul1` (flip sign bit) | Prepare for `2 - M*y0` |
| 8 | `correction = 2.0 + (-mul1)` (`fp32_adder`, `2.0 = 0x40000000`) | Compute `(2 - M*y0)` |
| 9 | `y1 = y0 * correction` (`fp32_multiplier`) | Newton–Raphson refined mantissa reciprocal |
| 10 | `y1_unbiased_exp = y1.exponent - 127` | Exponent contribution from the refined estimate |
| 11 | `final_unbiased_exp = y1_unbiased_exp - unbiased_exp` | Combine: `1/x = (1/M) * 2^(-e)` |
| 12 | `final_biased_exp = final_unbiased_exp + 127` | Re-bias for FP32 storage |
| 13 | Reconstruct `{sign, final_biased_exp, y1.fraction}` | Final packed FP32 result |

### 2.3 Special-case handling implemented

- **x = 0** → output forced to `±∞` (`exponent = 0xFF, fraction = 0`), sign preserved.
- **Exponent overflow** (`final_biased_exp ≥ 255`) → clamped to `±∞`.
- **Exponent underflow** (`final_biased_exp ≤ 0`) → clamped to `±0`.
- **Sign** is carried through untouched from input to output (reciprocal of a negative number is negative) — note this path was **not exercised** by the current test vectors (see §5).

---

## 3. RTL Structure / Module Hierarchy

```
reciprocal_unit
 ├── reciprocal_lut       (combinational 16-entry seed table, 4-bit index)
 ├── fp32_multiplier  ×2  (mul1: M*y0 ; mul2: y0*correction)
 └── fp32_adder       ×1  (2.0 - M*y0, via pre-negation + add)
```

All logic is **purely combinational** (`assign` / `always @(*)`) — there is
no clock, no pipelining, and no registered output in this version.

---

## 4. Testbench Methodology

- **Self-checking, non-synthesizable Verilog testbench** (`reciprocal_unit_tb.v`).
- Independent **behavioral FP32 ↔ real converter** (`fp32_to_real`) written
  from first principles (manual mantissa/exponent reconstruction, no `**`
  operator, explicit subnormal path) — used both to interpret the DUT
  output and to compute the golden reference (`1.0 / x_real`), so the
  checker does not depend on any RTL logic under test.
- Golden model: plain real-number division (`expected = 1.0 / x_real`).
- Per-vector metrics: absolute error, relative error, running worst-case
  (value + input that produced it).
- Pass/fail threshold: **0.5% relative error**, applied per test vector.
- **18 directed test vectors** across three categories:
  - Powers of two: 0.5, 1, 2, 4, 8, 16, 32
  - Non-power-of-two integers: 3, 5, 7, 10, 12, 25, 40
  - Fractional / non-integer mantissas: 0.75, 0.875, 1.5, 1.75

### Key fix made during this session

The original testbench declared `x` / `reciprocal` and drove stimulus, but
**never instantiated the DUT**. `reciprocal` was a floating (`z`) wire, and
the custom `fp32_to_real` function silently interpreted unknown bits as
`0.0` instead of erroring — producing a deceptive **100% fail, DUT = 0.0**
result set that looked like a functional bug but was actually a wiring
omission. Fix: added

```verilog
reciprocal_unit dut (
    .x          (x),
    .reciprocal (reciprocal)
);
```

This is a good general lesson for self-checking testbenches: an
unconnected DUT and a genuinely broken DUT can both present as "all
outputs zero," so it's worth eyeballing the instantiation before trusting
a 0% pass rate as a design defect.

---

## 5. Results (current run)

```
PASS COUNT       = 18
FAIL COUNT       = 0
MAX RELATIVE ERR  = 0.091833%
WORST INPUT       = 0.5
```

- All 18 vectors pass comfortably inside the 0.5% tolerance — max observed
  error (0.0918%) is **~5.4× better than the tolerance budget**, not just
  barely passing.
- Worst-case error occurs at the power-of-two inputs (0.5, 1, 2, 4, 8, 16,
  32), all at an identical **0.0918%** — consistent with `lut_index = 0`
  (mantissa fraction bits all zero) always hitting the same LUT entry and
  the same NR rounding behavior regardless of exponent, which is expected
  since exponent scaling is exact (power-of-two shifts) and only the
  mantissa reciprocal is approximated.
- Non-power-of-two and fractional cases show **lower** error (0.03–0.06%),
  meaning the LUT is not simply "worst at the boundaries" — it's actually
  most accurate away from `lut_index = 0`.

---

## 6. Verified Scope

What this test run actually demonstrates:
- Correct exponent bookkeeping (bias/unbias/rebias, exponent subtraction
  for `1/x = (1/M)·2^-e`) across a range from `2^-1` to `2^5`.
- Correct LUT-seeded NR convergence for **positive, normal, non-zero**
  FP32 inputs, mantissas spanning at least the top 4 fraction bits' worth
  of LUT entries exercised by the 18 vectors.
- Correct combinational wiring end-to-end from input unpacking through
  final FP32 reconstruction.

## 7. NOT Verified / Explicit Gaps

Being direct about what this does **not** prove, so it isn't mistaken for
full verification:

- **Negative inputs** — no test vector had `sign = 1`. The sign-passthrough
  logic is untested.
- **Subnormal inputs** — `reciprocal_lut`/`fp32_multiplier`/`fp32_adder`
  internals were not provided or reviewed for subnormal handling; the top
  module's zero-check only covers exact zero.
- **NaN / Inf inputs** — no defined or tested behavior for `x = Inf` or
  `x = NaN`.
- **Full mantissa/LUT coverage** — only vectors hitting a subset of the 16
  `lut_index` values were tested; not all 16 entries were exercised, and
  no exhaustive/random sweep was run.
- **Overflow/underflow clamp paths** — the `≥255` and `≤0` exponent clamp
  branches were never triggered by these 18 vectors (no input small/large
  enough to force clamping).
- **Rounding mode** — result truncates to `y1.fraction` directly; no
  round-to-nearest-even or other IEEE rounding is applied, so worst-case
  error near LUT/NR boundaries beyond the tested set is unknown.
- **Timing / synthesis** — this is a functional/behavioral check only. No
  synthesis, timing closure, area, or gate-level simulation was done. The
  design is fully combinational, so critical path (2 multiplies + 1 add +
  LUT, back to back) has not been analyzed and could be a real bottleneck
  at synthesis time.
- **`reciprocal_lut`, `fp32_multiplier`, `fp32_adder` internals** — these
  submodules were never reviewed in this session; only their black-box
  behavior (via the passing testbench) is validated.

## 8. Recommended Next Steps

1. Add negative, zero-sign, subnormal, NaN, and Inf test vectors.
2. Randomized/constrained-random testing (thousands of vectors) instead of
   18 hand-picked ones, ideally with an exhaustive or near-exhaustive sweep
   of all 16 `lut_index` values combined with varying exponents.
3. Explicitly test the overflow/underflow clamp branches (very large and
   very small `x`).
4. Review `reciprocal_lut`, `fp32_multiplier`, `fp32_adder` source for
   correctness and rounding behavior, not just black-box pass/fail.
5. If this is headed toward silicon/FPGA: synthesize and check
   timing/area, and decide whether to pipeline the combinational path.
