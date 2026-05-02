# Phase 5 — Optimized Assembly Routines (`strlen` & `memcpy`)

**Prerequisites:** [Phase 4 — Reverse Engineering](../phase4_reverse_engineering/README.md)  
**Next:** [Windows ABI](../../windows_abi/README.md) | [Challenges](../../challenges/README.md)

---

## Goal

Build fast, real-world versions of `strlen` and `memcpy` using:
- **Alignment tricks** (avoid page-boundary faults)
- **SSE2 vector loads** (16 bytes at a time)
- **SIMD zero detection** (`pcmpeqb` + `pmovmskb` + `bsf`)

Focus: x86-64 **SysV ABI** (Linux/macOS).  
For Windows x64 equivalents see [`windows_abi/`](../../windows_abi/README.md).

---

## Part A — Optimized `strlen` (SSE2)

### Why SIMD?

Naive `strlen` reads one byte per iteration.  
SSE2 reads **16 bytes per iteration** using 128-bit XMM registers, giving ~16× throughput on long strings.

### Key Instructions

| Instruction | Effect |
|-------------|--------|
| `pxor xmm0, xmm0` | xmm0 = 0 (zero vector) |
| `movdqu xmm1, [rdi]` | Load 16 bytes (unaligned) |
| `pcmpeqb xmm1, xmm0` | Each byte: 0xFF if equal to 0, else 0x00 |
| `pmovmskb ecx, xmm1` | 16-bit mask: bit k set if byte k was zero |
| `bsf ecx, ecx` | Index of lowest set bit (= offset of first null byte) |

### Assembly Source

See [`strlen_sse2.asm`](strlen_sse2.asm).

### Build & Test

```bash
nasm -f elf64 strlen_sse2.asm -o strlen_sse2.o
gcc  -o test_strlen strlen_sse2.o test_strlen.c
./test_strlen
```

### Step-by-Step Trace

String in memory: `"HELLO\0<garbage>"`

1. Load 16 bytes into XMM1.
2. `pcmpeqb` → `[0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, ...]`
3. `pmovmskb ecx` → `0b0000000000100000` = 0x0020
4. `bsf ecx, ecx` → 5
5. Length = `(rdi + 5) - rax` = 5.

### Pitfalls

- Reading past the end of the string is valid **as long as we stay within the same mapped page**.
- If the null byte is in the last byte of a page, the next 15-byte read may fault.
- Real libc handles this with page alignment checks (align down to 16, then check boundary).

---

## Part B — Optimized `memcpy` (SSE2 + alignment)

### Strategy

1. **Align** destination to a 16-byte boundary by copying bytes one at a time.
2. **Bulk copy** in 16-byte chunks using `movdqu`/`movdqa`.
3. **Tail copy** the remaining 0–15 bytes.

### Assembly Source

See [`memcpy_sse2.asm`](memcpy_sse2.asm).

### Build & Test

```bash
nasm -f elf64 memcpy_sse2.asm -o memcpy_sse2.o
gcc  -o test_memcpy memcpy_sse2.o test_memcpy.c
./test_memcpy
```

### Step-by-Step Trace

`dst=0x1003, src=0x2003, n=40`

1. `0x1003 & 0xF = 3` → align: copy 13 bytes, `dst` becomes `0x1010`, `n = 27`
2. Bulk: copy 16 bytes, `n = 11`
3. Tail: copy remaining 11 bytes

### Pitfalls

- **Overlapping regions** → use `memmove` instead.
- `movdqa` requires 16-byte aligned destination (we align first).
- Reading past end of `src` can fault if it crosses an unmapped page.
- For tiny sizes, SIMD overhead outweighs the benefit; add a size threshold.

---

## Exercises

**Easy**
1. Replace `movdqu` load with `movdqa` and explain the additional alignment requirement.
2. Add a 32-byte AVX path using `vmovdqu`.

**Medium**
1. Add `rep movsb` as a fallback for very small sizes (< 16 bytes).
2. Implement a size threshold: skip SIMD for `n < 16`.

**Expert**
1. Add non-temporal stores (`movntdq`) for large copies (bypasses cache).
2. Add page-boundary checks to make `strlen` safe at end-of-page.

---

## Real-World Relevance

- High-performance libc routines (glibc, musl, MSVCRT) use exactly these patterns.
- Exploit devs rely on knowing which routines read past bounds.
- Compiler autovectorization generates similar code automatically.

---

## Navigation

← [Phase 4 — Reverse Engineering](../phase4_reverse_engineering/README.md)  
→ [Windows ABI](../../windows_abi/README.md)  
→ [Challenges](../../challenges/README.md)
