# Challenge 3 — Struct Layout

**Difficulty:** ⭐⭐⭐ Hard  
**Skill:** Reconstruct a struct's field layout from memory access patterns in disassembly

---

## Objective

The binary contains a function that operates on a pointer to an unknown struct. By analyzing the fixed byte offsets used in memory loads and stores, reconstruct:

1. The number of fields in the struct.
2. The type (size) of each field.
3. The order of fields (draw the struct layout).
4. Write a C struct definition that matches your analysis.

---

## Expected Analysis

You should identify:
- Loads/stores at specific byte offsets from a base pointer (the struct pointer).
- The size of each access (byte, dword, qword) tells you the field type.
- The offset of each access tells you the field position in the struct.

---

## Build Instructions

### Linux

```bash
make
# Produces: challenge_stripped  (symbols removed)
#           challenge_debug     (for post-analysis verification)
```

### Windows (MinGW-w64)

```batch
mingw32-make -f Makefile.win
```

---

## Running the Challenge

```bash
./challenge_stripped
# Prints computed values derived from a hidden struct instance.
```

---

## GDB Workflow

```bash
gdb ./challenge_stripped
(gdb) starti
(gdb) x/60i <text_start>     # disassemble the target function
# Look for patterns like:
#   mov eax, [rdi + 0]       # field at offset 0, size 4 (int)
#   mov rax, [rdi + 8]       # field at offset 8, size 8 (long/pointer)
#   movzx eax, byte [rdi+N]  # field at offset N, size 1 (char/uint8_t)
(gdb) break *<function_start>
(gdb) run
(gdb) x/32xb $rdi            # dump raw struct bytes
```

---

## Hints

<details>
<summary>Hint 1 (click to reveal)</summary>
List all unique offsets used in `[rdi + offset]` memory accesses. Sort them in order — this gives you the field positions.
</details>

<details>
<summary>Hint 2 (click to reveal)</summary>
The size of each memory operand tells you the field type:
- `byte ptr [rdi+N]` → 1 byte → `uint8_t` or `char`
- `dword ptr [rdi+N]` → 4 bytes → `int` or `uint32_t`
- `qword ptr [rdi+N]` → 8 bytes → `int64_t`, `uint64_t`, or pointer
</details>

<details>
<summary>Hint 3 (click to reveal)</summary>
Pay attention to gaps between accesses — those are alignment padding bytes added by the compiler.
</details>

<details>
<summary>Solution (click to reveal)</summary>

```c
struct Record {
    int      id;        /* offset  0, size 4 */
    /* 4 bytes padding */
    long     value;     /* offset  8, size 8 */
    uint8_t  flags;     /* offset 16, size 1 */
    /* 3 bytes padding */
    int      score;     /* offset 20, size 4 */
};
/* sizeof(struct Record) == 24 */
```

The function computes `total = record->value + record->score` and
checks whether `record->flags` is non-zero before printing the result.
</details>

---

## Navigation

← [Challenge 2 — Hidden Constant](../challenge2_hidden_constant/README.md)  
↑ [Challenges Overview](../README.md)
