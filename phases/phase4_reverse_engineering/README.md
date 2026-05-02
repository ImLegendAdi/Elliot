# Phase 4 — Reverse Engineering Compiled Binaries

**Prerequisites:** [Phase 3 — Custom Memory Allocator](../phase3_allocator/README.md)  
**Next:** [Phase 5 — Optimized Assembly Routines](../phase5_optimized_routines/README.md)

---

## Goal

Take a stripped binary and recover:
- Function boundaries
- Control flow logic
- Data structures and their layouts
- High-level intent

Tools: **GDB** (Linux), with the mental model applicable to Ghidra/IDA.

---

## 1) Deep Explanation (WHY + HOW)

A compiled binary is:
- Code bytes in `.text`
- Data bytes in `.data` / `.rodata` / `.bss`
- Relocation tables (if not fully linked)
- Import tables (if dynamically linked)

With symbols stripped, you infer:
- **Functions** from prologues (`push rbp; mov rbp, rsp`) and call targets
- **Types** from memory access patterns (size of loads/stores)
- **Logic** from branch + compare patterns

---

## 2) Target Program (Unknown to Reverse Engineer)

The underlying C source (which you should pretend you haven't seen):

```c
int sum(int *a, int n) {
    int s = 0;
    for (int i = 0; i < n; i++) s += a[i];
    return s;
}
```

Typical compiled output (x86-64 SysV, no optimization):

```asm
; See phase4_re.asm for the annotated version
sum:
    xor eax, eax        ; s = 0
    xor ecx, ecx        ; i = 0
.loop:
    cmp ecx, esi        ; i < n ?
    jge .done
    add eax, [rdi + rcx*4]
    inc ecx
    jmp .loop
.done:
    ret
```

---

## 3) Step-by-Step Reconstruction

| Observation | Conclusion |
|-------------|-----------|
| `RDI` used as base pointer in `[rdi + rcx*4]` | First argument is a pointer (SysV: arg1 = RDI) |
| `RSI` used in `cmp ecx, esi` | Second argument is an integer bound (SysV: arg2 = RSI) |
| `xor eax, eax` early | Local accumulator initialized to 0 |
| `xor ecx, ecx` early | Loop counter initialized to 0 |
| `rcx*4` scale | Array element size = 4 bytes → `int` array |
| `add eax, [...]` | Accumulating 32-bit values |
| `cmp ecx, esi; jge .done` | Signed loop bound check |
| `ret` with result in `eax` | Returns the accumulated sum |

**Reconstruction:** `int sum(int *a, int n)` — sums elements of an integer array.

---

## 4) Debugging Walkthrough

```bash
# Compile the target (with symbols for verification; simulate stripping for RE)
gcc -O0 -o target phase4_re.asm   # or compile sum.c
strip target

gdb ./target
(gdb) info functions             # try to list functions (stripped: empty)
(gdb) x/20i 0x401000             # disassemble at a guessed address
(gdb) break *0x401000
(gdb) run
(gdb) info registers rdi rsi rcx eax
(gdb) x/8wx $rdi                  # inspect the array
(gdb) stepi                       # step one instruction
```

---

## 5) Exercises

**Easy**
1. Identify which register is the loop index.
2. Explain why `rcx*4` implies an `int` array rather than `long`.

**Medium**
1. Recompile the C source with `long` arrays; how does the disassembly change?
2. Distinguish unsigned vs signed comparison: when does the compiler use `jb` vs `jl`?

**Expert**
1. Infer a struct layout from a function that accesses multiple fixed offsets.
2. Identify compiler optimizations: strength reduction, loop unrolling, auto-vectorization.

---

## 6) Pitfalls & Edge Cases

- **Inlining** removes function boundaries — the call disappears.
- **Tail calls** replace `call; ret` with `jmp` — the `ret` disappears.
- **Optimized builds** (`-O2`) remove loop counter variables.
- **Compiler vectorization** (-O3) may emit SIMD instructions instead of a simple loop.

---

## 7) Real-World Relevance

- Malware analysis
- Auditing closed-source libraries for vulnerabilities
- Crash forensics with stripped production binaries

---

## Navigation

← [Phase 3 — Custom Memory Allocator](../phase3_allocator/README.md)  
→ [Phase 5 — Optimized Assembly Routines](../phase5_optimized_routines/README.md)
