# Windows x64 ABI — Comparison with SysV AMD64

This directory contains Windows x64 ABI equivalents of the assembly examples in [`phases/`](../phases/README.md).

---

## ABI Comparison: SysV AMD64 vs Windows x64

### Integer/Pointer Argument Passing

| Position | SysV AMD64 (Linux/macOS) | Windows x64 |
|----------|--------------------------|-------------|
| Arg 1    | `RDI`                    | `RCX`       |
| Arg 2    | `RSI`                    | `RDX`       |
| Arg 3    | `RDX`                    | `R8`        |
| Arg 4    | `RCX`                    | `R9`        |
| Arg 5    | `R8`                     | Stack (shadow space + 40) |
| Arg 6    | `R9`                     | Stack |
| Arg 7+   | Stack                    | Stack |

### Floating-Point Arguments

| Position | SysV AMD64 | Windows x64 |
|----------|-----------|-------------|
| FP Arg 1 | `XMM0`    | `XMM0`      |
| FP Arg 2 | `XMM1`    | `XMM1`      |
| FP Arg 3 | `XMM2`    | `XMM2`      |
| FP Arg 4 | `XMM3`    | `XMM3`      |

**Key difference (Windows):** Integer and FP arguments share the same slots. If arg1 is FP, slot 1 (`RCX`/`XMM0`) is used — the integer register for that slot is undefined, and vice versa.

### Return Values

| Type | SysV AMD64 | Windows x64 |
|------|-----------|-------------|
| Integer ≤ 64 bits | `RAX` | `RAX` |
| Integer 128 bits | `RAX:RDX` | via hidden pointer in `RCX` |
| Float | `XMM0` | `XMM0` |

### Caller-Saved (Volatile) Registers

| ABI | Registers |
|-----|-----------|
| SysV AMD64 | `RAX`, `RCX`, `RDX`, `RSI`, `RDI`, `R8`–`R11`, `XMM0`–`XMM15` |
| Windows x64 | `RAX`, `RCX`, `RDX`, `R8`–`R11`, `XMM0`–`XMM5` |

### Callee-Saved (Non-Volatile) Registers

| ABI | Registers |
|-----|-----------|
| SysV AMD64 | `RBX`, `RBP`, `R12`–`R15` |
| Windows x64 | `RBX`, `RBP`, `RDI`, `RSI`, `R12`–`R15`, `XMM6`–`XMM15` |

> **Critical difference:** On Windows, `RDI` and `RSI` are **callee-saved**. On Linux they are scratch registers. An assembly function that clobbers `RSI`/`RDI` is correct on Linux but **wrong** on Windows unless it saves/restores them.

---

## Shadow Space (Windows x64 Only)

The caller **always** allocates 32 bytes of **shadow space** (also called "home space" or "spill area") above the return address before every `call`. The callee may use these 32 bytes to spill the first four register arguments.

```
Stack layout at entry to callee (Windows x64):
  [rsp + 0]   ← return address (pushed by CALL)
  [rsp + 8]   ← shadow for RCX (arg1) — 8 bytes
  [rsp + 16]  ← shadow for RDX (arg2)
  [rsp + 24]  ← shadow for R8  (arg3)
  [rsp + 32]  ← shadow for R9  (arg4)
  [rsp + 40]  ← 5th argument (if any)
```

On SysV there is **no** shadow space. The caller does not pre-allocate anything for the callee.

### Caller responsibilities

```asm
; Windows x64 caller example: call foo(a, b, c, d, e)
sub rsp, 40        ; 32 bytes shadow + 8 to align (total 40, if RSP was 16-byte aligned)
mov rcx, a         ; arg1
mov rdx, b         ; arg2
mov r8,  c         ; arg3
mov r9,  d         ; arg4
mov qword [rsp+32], e  ; arg5 (above shadow space)
call foo
add rsp, 40        ; restore stack
```

---

## Stack Alignment

Both ABIs require the stack to be **16-byte aligned before a `call`** instruction.

- In SysV: `RSP % 16 == 0` at the `call` site (so `RSP % 16 == 8` on function entry).
- In Windows x64: same rule, but the shadow space allocation must be included in the alignment calculation.

---

## XMM Register Preservation

- **SysV:** All XMM registers are caller-saved. The callee can use any XMM register freely.
- **Windows x64:** `XMM6`–`XMM15` are **callee-saved**. A function that uses these must save and restore them.

---

## Files in This Directory

| File | Description |
|------|-------------|
| [`calling_conventions.asm`](calling_conventions.asm) | Side-by-side: same function in SysV and Windows x64 ABI |
| [`strlen_win64.asm`](strlen_win64.asm) | SSE2 `strlen` — Windows x64 ABI |
| [`memcpy_win64.asm`](memcpy_win64.asm) | SSE2 `memcpy` — Windows x64 ABI |

---

## Building on Windows

### With NASM + MSVC link

```batch
nasm -f win64 strlen_win64.asm -o strlen_win64.obj
nasm -f win64 memcpy_win64.asm -o memcpy_win64.obj
cl /c test_win64.c
link test_win64.obj strlen_win64.obj memcpy_win64.obj /out:test_win64.exe
test_win64.exe
```

### With NASM + MinGW-w64

```batch
nasm -f win64 strlen_win64.asm -o strlen_win64.o
nasm -f win64 memcpy_win64.asm -o memcpy_win64.o
x86_64-w64-mingw32-gcc -o test_win64.exe test_win64.c strlen_win64.o memcpy_win64.o
test_win64.exe
```

---

## Quick Reference: Porting SysV → Windows x64

| Change | SysV | Windows x64 |
|--------|------|-------------|
| Arg 1 register | `RDI` | `RCX` |
| Arg 2 register | `RSI` | `RDX` |
| Arg 3 register | `RDX` | `R8` |
| Arg 4 register | `RCX` | `R9` |
| Shadow space | none | 32 bytes allocated by caller |
| `RDI`/`RSI` volatile? | yes | no (callee must save) |
| `XMM6`–`XMM15` volatile? | yes | no (callee must save) |

---

## Navigation

← [Phase 5 — Optimized Routines](../phases/phase5_optimized_routines/README.md)  
→ [Challenges](../challenges/README.md)  
↑ [Top-level README](../README.md)
