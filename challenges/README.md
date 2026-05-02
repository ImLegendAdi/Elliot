# Reverse Engineering Challenges

A set of small challenge programs to practice reverse engineering skills. Each challenge has a compiled binary (stripped), and you must analyze it to recover the behavior.

Start with Challenge 1 and work upward. Check each challenge's individual README for the objective, hints, and expected analysis.

---

## Challenges Overview

| Challenge | Difficulty | Core Skill |
|-----------|-----------|-----------|
| [Challenge 1 — Sum Array](challenge1_sum_array/README.md) | ⭐ Easy | Recover function behavior, identify loop/array |
| [Challenge 2 — Hidden Constant](challenge2_hidden_constant/README.md) | ⭐⭐ Medium | Find hidden constant via branch analysis |
| [Challenge 3 — Struct Layout](challenge3_struct_layout/README.md) | ⭐⭐⭐ Hard | Reconstruct struct layout from memory access patterns |

---

## Building All Challenges

### Linux (x86-64)

```bash
# Build all
for d in challenge1_sum_array challenge2_hidden_constant challenge3_struct_layout; do
    (cd "$d" && make)
done

# Or build individually
cd challenge1_sum_array && make
cd challenge2_hidden_constant && make
cd challenge3_struct_layout && make
```

### Windows (MinGW-w64)

```batch
cd challenge1_sum_array
mingw32-make -f Makefile.win
```

---

## Tools for Analysis

| Tool | Purpose |
|------|---------|
| `objdump -d <binary>` | Quick disassembly |
| `gdb <binary>` | Dynamic analysis, breakpoints, register inspection |
| `readelf -a <binary>` | ELF headers, sections, symbols |
| `strings <binary>` | Extract printable strings |
| `xxd <binary> \| head` | Hex dump |
| Ghidra / IDA Free | Graphical decompiler |

---

## How to Approach a Challenge

1. **Static first**: `objdump -d ./challenge_stripped` — find the entry point and main logic.
2. **Find data references**: look for constants, strings, offsets.
3. **Trace control flow**: identify loops, conditionals, function calls.
4. **Run dynamically**: `gdb ./challenge_stripped`, set breakpoints, inspect registers.
5. **Form a hypothesis**: write a pseudocode reconstruction.
6. **Verify**: compare output with the challenge's test inputs.

---

## Navigation

← [Phase 5 — Optimized Routines](../phases/phase5_optimized_routines/README.md)  
↑ [Top-level README](../README.md)
