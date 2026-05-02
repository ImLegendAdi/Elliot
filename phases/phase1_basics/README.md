# Phase 1 — x86-64 Basics

**Prerequisites:** None  
**Next:** [Phase 2 — Basic Disassembler](../phase2_disassembler/README.md)

---

## Goal

Understand the fundamental building blocks of x86-64 assembly before writing or reading any code:
- General-purpose registers and their roles
- The SysV AMD64 calling convention
- Common instructions: `mov`, `add`, `sub`, `push`, `pop`, `call`, `ret`
- Memory addressing modes
- The stack frame layout

---

## 1) Registers

x86-64 has 16 general-purpose 64-bit registers:

| Register | Alt names (32/16/8) | Role in SysV ABI |
|----------|---------------------|-----------------|
| `rax`    | `eax`, `ax`, `al`   | Return value, scratch |
| `rbx`    | `ebx`, `bx`, `bl`   | Callee-saved |
| `rcx`    | `ecx`, `cx`, `cl`   | 4th argument |
| `rdx`    | `edx`, `dx`, `dl`   | 3rd argument |
| `rsi`    | `esi`, `si`, `sil`  | 2nd argument |
| `rdi`    | `edi`, `di`, `dil`  | 1st argument |
| `rbp`    | `ebp`, `bp`, `bpl`  | Frame pointer (callee-saved) |
| `rsp`    | `esp`, `sp`, `spl`  | Stack pointer |
| `r8`–`r11` | `r8d`–`r11d` etc. | 5th–8th args / scratch |
| `r12`–`r15` | `r12d`–`r15d` etc. | Callee-saved |

**Key rule:** Writing to a 32-bit register (e.g., `eax`) **zero-extends** to 64 bits. Writing to 8/16-bit sub-registers does **not**.

---

## 2) SysV AMD64 Calling Convention

Used on Linux, macOS, and most Unix-like systems.

### Integer/Pointer Arguments
```
Arg 1 → RDI
Arg 2 → RSI
Arg 3 → RDX
Arg 4 → RCX
Arg 5 → R8
Arg 6 → R9
Arg 7+ → pushed on stack (right-to-left)
```

### Return Values
- Integer/pointer: `RAX` (64-bit), `RAX:RDX` (128-bit)
- Floating point: `XMM0`

### Caller-saved (scratch) registers
`RAX`, `RCX`, `RDX`, `RSI`, `RDI`, `R8`–`R11`  
The callee may destroy these freely.

### Callee-saved registers
`RBX`, `RBP`, `R12`–`R15`  
The callee **must** preserve these (push/pop around use).

### Stack Alignment
The stack must be **16-byte aligned before a `call`** instruction (i.e., `RSP % 16 == 0` at the point of `call`, which means `RSP % 16 == 8` inside the prologue after `call` pushes the return address).

---

## 3) Common Instructions

```asm
; Data movement
mov  rax, rdi          ; rax = rdi
mov  rax, [rdi]        ; rax = *rdi  (load)
mov  [rdi], rax        ; *rdi = rax  (store)
lea  rax, [rdi + 8]    ; rax = rdi + 8  (address, no load)

; Arithmetic
add  rax, rdx          ; rax += rdx
sub  rax, 1            ; rax -= 1
imul rax, rdx          ; rax *= rdx (signed)
inc  rcx               ; rcx++
dec  rcx               ; rcx--
xor  eax, eax          ; eax = 0  (also clears upper 32 bits)

; Stack
push rbx               ; rsp -= 8; [rsp] = rbx
pop  rbx               ; rbx = [rsp]; rsp += 8

; Control flow
call func              ; push rip+len; jmp func
ret                    ; pop rip
jmp  label             ; unconditional jump
cmp  rax, 0            ; sets flags: ZF, SF, CF, OF
je   label             ; jump if equal (ZF=1)
jne  label             ; jump if not equal
jl   label             ; jump if less (signed)
jb   label             ; jump if below (unsigned)
jg   label             ; jump if greater (signed)
```

---

## 4) Memory Addressing Modes

x86-64 uses the form: `[base + index*scale + displacement]`

```asm
[rdi]                   ; base only
[rdi + 8]               ; base + displacement
[rdi + rcx]             ; base + index
[rdi + rcx*4]           ; base + index * scale (scale: 1,2,4,8)
[rdi + rcx*4 + 0x10]    ; full form
[rip + symbol]          ; RIP-relative (used for globals in x64)
```

---

## 5) Stack Frame Layout

A typical function prologue/epilogue:

```asm
func:
    push rbp               ; save caller's frame pointer
    mov  rbp, rsp          ; set our frame pointer
    sub  rsp, 32           ; allocate 32 bytes of locals
    ; ... body ...
    mov  rsp, rbp          ; restore stack
    pop  rbp
    ret
```

Stack layout (addresses decrease downward):
```
Higher address
  [ret addr]   ← RSP+8 on entry (pushed by caller's CALL)
  [saved RBP]  ← RBP after push
  [local vars] ← RBP - N
Lower address (RSP)
```

---

## 6) Exercises

**Easy**
1. Write a NASM function `add_two(a, b)` that returns `a + b`.
2. Write `negate(x)` that returns `-x` using `neg`.

**Medium**
1. Write a loop that sums an array of 64-bit integers.
2. Implement `strlen` using `repne scasb`.

**Expert**
1. Write a recursive factorial function; verify callee-saved register discipline.
2. Implement `memset` using `rep stosb`, then benchmark it against a loop.

---

## Navigation

← [Phases Overview](../README.md)  
→ [Phase 2 — Basic Disassembler](../phase2_disassembler/README.md)
