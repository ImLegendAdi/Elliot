# Challenge 2 — Hidden Constant

**Difficulty:** ⭐⭐ Medium  
**Skill:** Find a hidden constant through branch and comparison analysis

---

## Objective

The binary contains a function that validates a user-provided integer against a secret constant. Reverse engineer the binary to:

1. Identify the comparison instruction and its operands.
2. Recover the hidden constant.
3. Describe the full function behavior (what it computes/checks and what it returns).

---

## Expected Analysis

You should discover:
- A branch guarded by a comparison of the input against a fixed immediate value.
- The hidden constant embedded directly in the code (not in `.rodata`).
- The function returns different values depending on whether the input matches.

---

## Build Instructions

### Linux

```bash
make
# Produces: challenge_stripped  (symbols removed)
#           challenge_debug     (for verification after your analysis)
```

### Windows (MinGW-w64)

```batch
mingw32-make -f Makefile.win
```

---

## Running the Challenge

```bash
./challenge_stripped <integer>
# Example:
./challenge_stripped 42
./challenge_stripped 0
```

The program prints `1` (match) or `0` (no match).

---

## GDB Workflow

```bash
gdb ./challenge_stripped
(gdb) starti                # stop at very first instruction
(gdb) info proc mappings    # find .text region
(gdb) x/50i <text_start>   # disassemble
(gdb) break *<comparison_address>
(gdb) run 99
(gdb) info registers        # inspect comparison operands
```

Look for: `cmp`, `test`, `je`/`jne` instructions. The right operand of `cmp` is your constant.

---

## Hints

<details>
<summary>Hint 1 (click to reveal)</summary>
Use `objdump -d ./challenge_stripped` and look for `cmp` instructions. One of them compares the first argument (which register on SysV?) against an immediate value.
</details>

<details>
<summary>Hint 2 (click to reveal)</summary>
The constant is embedded as a 32-bit immediate in the `cmp` instruction. Convert hex to decimal.
</details>

<details>
<summary>Solution (click to reveal)</summary>

The hidden constant is **1337**.

```c
int check_magic(int x) {
    return (x == 1337) ? 1 : 0;
}
```
</details>

---

## Navigation

← [Challenge 1 — Sum Array](../challenge1_sum_array/README.md)  
→ [Challenge 3 — Struct Layout](../challenge3_struct_layout/README.md)
