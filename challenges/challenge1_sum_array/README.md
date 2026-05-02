# Challenge 1 — Sum Array

**Difficulty:** ⭐ Easy  
**Skill:** Recover function behavior, identify loop and array access patterns

---

## Objective

The binary contains a single function. Reverse engineer it to answer:

1. What does the function do?
2. What are its arguments (types and roles)?
3. What does it return?

---

## Expected Analysis

You should be able to reconstruct pseudocode equivalent to:

```c
// Hint appears after your analysis
```

Key observations that lead to the answer:
- The SysV ABI tells you which registers are the arguments.
- The scale factor in the index addressing tells you the element size.
- The accumulator pattern (zero + repeated add) tells you the operation.

---

## Build Instructions

### Linux

```bash
make
# Produces: challenge_stripped  (symbols removed)
#           challenge_debug     (symbols present, for verification)
```

### Windows (MinGW-w64)

```batch
mingw32-make -f Makefile.win
```

---

## Running the Challenge

```bash
./challenge_stripped
# Runs with a built-in test array; prints a single integer result.
```

Use GDB to trace execution:

```bash
gdb ./challenge_stripped
(gdb) info functions          # try to find function boundaries (stripped: empty)
(gdb) x/30i 0x$(nm challenge_debug | grep main | awk '{print $1}')
(gdb) break *<address>
(gdb) run
(gdb) info registers
(gdb) stepi
```

---

## Hints

<details>
<summary>Hint 1 (click to reveal)</summary>
Look at the SysV calling convention: what register holds the first argument? What type does the addressing mode suggest?
</details>

<details>
<summary>Hint 2 (click to reveal)</summary>
The scale factor `*4` in `[base + index*4]` tells you the size of each array element. What C type is 4 bytes?
</details>

<details>
<summary>Solution (click to reveal)</summary>

```c
int sum_array(int *a, int n) {
    int s = 0;
    for (int i = 0; i < n; i++) s += a[i];
    return s;
}
```

The function sums an array of `int` values and returns the result.
</details>

---

## Navigation

← [Challenges Overview](../README.md)  
→ [Challenge 2 — Hidden Constant](../challenge2_hidden_constant/README.md)
