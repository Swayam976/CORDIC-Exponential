# CORDIC Fixed-Point Exponential (eˣ) in Verilog

> A hardware block that computes **eˣ** using the **hyperbolic CORDIC** algorithm, with range reduction so it works on the whole 16-bit input range.

![language](https://img.shields.io/badge/language-Verilog-blue)
![verification](https://img.shields.io/badge/verification-exhaustive%20(65%2C536%20inputs)-green)
![scope](https://img.shields.io/badge/scope-RTL%20%2B%20simulation-lightgrey)

---

## 📖 What is this?

Computing `e^x` in hardware is hard, because multipliers and dividers are big and slow.
**CORDIC** gets around that. It finds the answer using only **shifts, adds and subtracts**, one small step per clock cycle.

**Like you're 5:** imagine you need to walk to a spot exactly `x` steps away, but you're only allowed giant steps, then half steps, then quarter steps, and so on. At each step you only decide *forward or backward*. After enough steps you land very close to the spot. CORDIC does the same thing with numbers, and where it lands gives you `e^x`.

---

## ✨ Features

- ✅ **Shift-and-add only**: no multipliers in the iterative core
- ✅ **Range reduction**: handles every 16-bit input, not just small ones
- ✅ **Hyperbolic CORDIC** with the required repeated iterations (i = 4 and i = 13) for convergence
- ✅ **Simple handshake**: `start` pulse in, `done` pulse out
- ✅ **Exhaustively verified**: all 65,536 inputs checked bit-for-bit against a golden reference

---

## 🧮 How It Works

### Step 1 — Range reduction (`range_reduce.v`)

CORDIC only converges for small inputs (about |r| < 1.118), so the input is split into an integer part and a small part first:

$$
x = k \cdot \ln 2 + r, \qquad |r| \le \tfrac{\ln 2}{2} \approx 0.347
$$

$$
k = \text{round}\!\left(\frac{x}{\ln 2}\right), \qquad r = x - k \ln 2
$$

so that

$$
e^{x} = e^{r} \cdot 2^{k}
$$

Multiplying by `2^k` is just a shift, so it's essentially free.

**Example:** `x = 3.0`

| Quantity | Calculation | Value |
|---|---|---|
| k | round(3.0 / 0.6931) = round(4.328) | **4** |
| r | 3.0 − 4 × 0.6931 | **0.2274** |
| eʳ | e^0.2274 | **1.2553** |
| eˣ | 1.2553 × 2⁴ | **20.085** ✔ (true e³ = 20.0855) |

### Step 2 — Hyperbolic CORDIC (`cordic.v`)

Start with `x₀ = 1/K`, `y₀ = 0`, `z₀ = r`. Then at each step `i`:

$$
d_i = \begin{cases} +1 & z_i \ge 0 \\ -1 & z_i < 0 \end{cases}
$$

$$
\begin{aligned}
x_{i+1} &= x_i + d_i \, y_i \, 2^{-i} \\
y_{i+1} &= y_i + d_i \, x_i \, 2^{-i} \\
z_{i+1} &= z_i - d_i \, \tanh^{-1}(2^{-i})
\end{aligned}
$$

When `z` reaches ≈ 0:

$$
x \to \cosh r, \qquad y \to \sinh r, \qquad x + y = e^{r}
$$

**Why the repeats?** In hyperbolic mode, iterations `i = 4, 13, 40, …` must be done **twice**, or the algorithm won't converge. This design runs the shift sequence:

```
1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 13, 14, 15, 16   → 18 iterations
```

The `tanh⁻¹(2⁻ⁱ)` constants are stored in a small lookup table (Q2.20).

### Step 3 — Top level (`exp_top.v`)

Connects the two blocks, holds `k` in a register while the core runs, and registers the final outputs.

```
          ┌──────────────┐   r (Q2.20)   ┌──────────────┐   eʳ    ┌──────────┐
 x_in ───►│ range_reduce │──────────────►│    cordic    │────────►│          │──► mant
 (Q4.12)  │              │               │ (18 iters)   │         │  output  │
          │              │── k ──► [k_reg] ─────────────────────►│ register │──► expo
          └──────────────┘               └──────────────┘         └──────────┘
```

---

## 🔢 Number Formats

| Signal | Width | Format | Meaning | Range |
|---|---|---|---|---|
| `x_in` | 16-bit signed | **Q4.12** | input x | −8.0 … +7.9998 |
| `r` | 22-bit signed | **Q2.20** | reduced input | ≈ ±0.347 |
| `mant` | 22-bit signed | **Q2.20** | eʳ | ≈ 0.70 … 1.42 |
| `expo` | 5-bit signed | integer | k | −12 … +12 |

**Final answer:**

$$
e^{x} = \text{mant} \times 2^{\text{expo}}
$$

**Reading Qm.n:** a Q4.12 number is the integer value divided by 2¹². For example `0x3000` = 12288 → 12288 / 4096 = **3.0**.

---

## 🔌 Interface (`exp_top`)

| Port | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst` | in | 1 | Synchronous reset (active high) |
| `start` | in | 1 | Pulse high for one cycle to begin |
| `x_in` | in | 16 | Input x (Q4.12); only needs to be valid on the `start` cycle |
| `done` | out | 1 | One-cycle pulse when the result is ready |
| `mant` | out | 22 | eʳ in Q2.20 |
| `expo` | out | 5 | Exponent k |

**Timing:** `x_in` is sampled when `start` is pulsed, so it can change right afterwards (the testbench checks this on purpose). The result appears about **20 cycles** later, when `done` pulses.

---

## 📂 Folder Structure

```
CORDIC/
├── rtl/
│   ├── exp_top.v          # Top level: range reduction + CORDIC + output regs
│   ├── range_reduce.v     # x → (k, r)
│   └── cordic.v           # Iterative hyperbolic CORDIC core, r → eʳ
├── tb/
│   ├── tb_exp_top.v       # Full-system testbench (all 65,536 inputs)
│   ├── cordic_tb.v        # Core-only testbench
│   ├── top_vectors.txt    # Golden vectors for exp_top:  x  mant  k   (hex)
│   └── vectors.txt        # Golden vectors for cordic:   r  eʳ        (decimal)
└── README.md
```

---

## 🚀 How to Run

### 1. Clone

```bash
git clone https://github.com/<your-username>/CORDIC.git
cd CORDIC
```

### 2. Fix the vector file paths

The testbenches currently open files by **absolute Windows paths**:

```verilog
$fopen("C:/Xilinx Projects/CORDIC/top_vectors.txt", "r");
```

Change them to paths relative to where you run the simulation, for example:

```verilog
$fopen("tb/top_vectors.txt", "r");   // in tb_exp_top.v
$fopen("tb/vectors.txt", "r");       // in cordic_tb.v
```

### 3. Simulate

**Icarus Verilog (from the repo root):**

```bash
# Full system
iverilog -o sim_top tb/tb_exp_top.v rtl/exp_top.v rtl/range_reduce.v rtl/cordic.v
vvp sim_top

# CORDIC core only
iverilog -o sim_core tb/cordic_tb.v rtl/cordic.v
vvp sim_core
```

**Vivado:** add `rtl/*.v` as design sources and `tb/*.v` as simulation sources, set the testbench as top, and run *Behavioral Simulation*.

### 4. Expected output

```
------------------------------------------
checked=65536  skipped=0  errors=0  ...  latency=.. cycles
PASS
------------------------------------------
```

---

## 🧪 Verification

- **Method:** golden-vector comparison. Each line of the vector file holds an input and the exact expected output. The testbench drives each input, waits for `done`, and compares **bit-for-bit**.
- **Coverage:** `top_vectors.txt` contains **every possible 16-bit input** (65,536 cases), so there are no untested corners.
- **Extra check:** right after `start`, the testbench changes `x_in` to `0x7FFF`. This proves that `k` is latched correctly and not read live.
- **Safety:** a watchdog timeout ends the simulation if `done` never arrives.

---

## 🗺️ Roadmap

- [x] Hyperbolic CORDIC core
- [x] Range reduction
- [x] Exhaustive verification of the full system
- [ ] Add the golden-model script that generates the vector files
- [ ] Pipelined (1 result per cycle) version
- [ ] Error analysis (max ULP error vs. double-precision `exp`)

---

## 📚 References

- J. S. Walther, *"A Unified Algorithm for Elementary Functions,"* AFIPS Spring Joint Computer Conference, 1971.
- J. E. Volder, *"The CORDIC Trigonometric Computing Technique,"* IRE Trans. Electronic Computers, 1959.
- R. Andraka, *"A Survey of CORDIC Algorithms for FPGA Based Computers,"* FPGA '98.

---

## 👤 Authors

Course project, IIT Guwahati.
- **Swayam** — RTL design & verification
- *Partner name* — Report

---

## 📄 License

MIT. See [LICENSE](LICENSE).
