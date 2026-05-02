# Phase 2 — Basic Disassembler (x86-64)

**Prerequisites:** [Phase 1 — x86-64 Basics](../phase1_basics/README.md)  
**Next:** [Phase 3 — Custom Memory Allocator](../phase3_allocator/README.md)

---

## Goal

Parse a byte stream and emit correct assembly for a subset of x86-64:
- Prefixes: REX
- Opcodes: `mov r64, r/m64`, `mov r/m64, r64`, `add r/m64, r64`
- ModRM + SIB + displacement
- Immediate forms: `mov r64, imm32/imm64`

This teaches **real instruction decoding** — you cannot know instruction length without decoding the full prefix/opcode/ModRM/SIB chain.

---

## 1) Why This Matters

An x86 instruction is **not fixed length**. You must decode in order:

1. **Prefixes** (REX)
2. **Opcode**
3. **ModRM** (register + addressing mode)
4. **SIB** (if needed)
5. **Displacement** (if needed)
6. **Immediate** (if needed)

Misreading even one byte breaks every subsequent instruction boundary.

---

## 2) Minimal Decode Model

### Structures

```c
struct Inst {
    uint8_t rex;
    uint8_t opcode;
    uint8_t modrm;
    uint8_t sib;
    int32_t disp;
    int     disp_size;
    uint64_t imm;
    int     imm_size;
};
```

### REX Byte (`0100WRXB`)

| Bit | Name | Effect |
|-----|------|--------|
| W   | 64-bit operand | Promotes to 64-bit |
| R   | Extends ModRM.reg | Adds bit 3 to reg field |
| X   | Extends SIB.index | Adds bit 3 to index field |
| B   | Extends ModRM.r/m or SIB.base | Adds bit 3 |

### ModRM Byte

```
mod = bits 7..6   (addressing mode)
reg = bits 5..3   (register operand or opcode extension)
rm  = bits 2..0   (register/memory operand)
```

| `mod` | Meaning |
|-------|---------|
| `00`  | `[rm]` (disp32 if rm=101) |
| `01`  | `[rm + disp8]` |
| `10`  | `[rm + disp32]` |
| `11`  | register direct (no memory) |

### SIB Byte (when `mod != 11` and `rm == 100`)

```
scale = bits 7..6  (1, 2, 4, 8)
index = bits 5..3
base  = bits 2..0
```

---

## 3) Implementation

See [`disasm_core.c`](disasm_core.c) for the complete decode skeleton.

Key function:

```c
size_t decode_inst(const uint8_t *p, struct Inst *out);
```

Returns the number of bytes consumed.

### Build and test

```bash
gcc -Wall -o disasm disasm_core.c
echo -e '\x48\x8b\x84\x8d\x20\x01\x00\x00' | ./disasm
# Expected: mov rax, [rbp + rcx*4 + 0x120]
```

---

## 4) Step-by-Step Decode Example

Bytes: `48 8B 84 8D 20 01 00 00`

| Byte | Field | Value |
|------|-------|-------|
| `48` | REX   | W=1 (64-bit) |
| `8B` | Opcode | MOV r64, r/m64 |
| `84` | ModRM | mod=10 (disp32), reg=0 (RAX), rm=4 (SIB) |
| `8D` | SIB   | scale=4, index=1 (RCX), base=5 (RBP) |
| `20 01 00 00` | disp32 | 0x00000120 |

Result: `mov rax, [rbp + rcx*4 + 0x120]`

---

## 5) Debugging Walkthrough

```bash
gdb ./disasm
(gdb) x/8xb $rip
(gdb) stepi
```

Compare your disassembler output to GDB's `disassemble $rip`.

---

## 6) Exercises

**Easy**
1. Add decoding for `sub r/m64, r64` (opcode `0x29`).
2. Add `mov r/m64, imm32` (opcode `0xC7` with /0).

**Medium**
1. Add `add r64, imm32` (opcode `0x81 /0`).
2. Sign-extend `disp8` to 64 bits when formatting output.

**Expert**
1. Implement RIP-relative addressing (mod=00, rm=101).
2. Decode and print register names with REX extensions (R8–R15).

---

## 7) Edge Cases & Pitfalls

- `mod=00, rm=101` is **RIP-relative** in x64 — not absolute.
- **SIB with base=5 and mod=00** implies disp32 with no base register.
- Writing to 32-bit register zero-extends; 8/16-bit sub-registers do not.
- Cascade decode failure if any byte is misread.

---

## Navigation

← [Phase 1 — x86-64 Basics](../phase1_basics/README.md)  
→ [Phase 3 — Custom Memory Allocator](../phase3_allocator/README.md)
