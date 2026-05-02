; calling_conventions.asm — Side-by-side SysV vs Windows x64 ABI (windows_abi/)
;
; Demonstrates the same integer-add function in both ABIs,
; a caller stub showing shadow-space allocation (Windows x64),
; and callee-saved register discipline differences.
;
; ========================================================
; PART 1 — add_two: SysV AMD64
; ========================================================
;
; int add_two_sysv(int a, int b)
;   a → RDI (arg1)
;   b → RSI (arg2)
;   return → EAX
;
; On Linux, assemble with:
;   nasm -f elf64 calling_conventions.asm -o calling_conventions.o

; ========================================================
; PART 2 — add_two: Windows x64
; ========================================================
;
; int add_two_win64(int a, int b)
;   a → RCX (arg1)
;   b → RDX (arg2)
;   return → EAX
;
; On Windows, assemble with:
;   nasm -f win64 calling_conventions.asm -o calling_conventions.obj
;
; Note: This file contains both versions; include only the
; relevant one in your link, or rename/alias as needed.

; ---- SysV version ----------------------------------------
global add_two_sysv

section .text

add_two_sysv:
    ; No prologue needed: leaf function, no locals, no callee-saved regs used.
    lea  eax, [edi + esi]   ; eax = a + b  (32-bit add, zero-extends to RAX)
    ret

; ---- Windows x64 version ----------------------------------
global add_two_win64

add_two_win64:
    ; Shadow space (32 bytes) was allocated by the CALLER before CALL.
    ; We are free to use [rsp+8]..[rsp+32] to spill our args if needed.
    lea  eax, [ecx + edx]   ; eax = a + b  (args in RCX, RDX on Windows)
    ret

; ---- Caller stub: Windows x64 ----------------------------
;
; Demonstrates correct caller protocol for Windows x64:
;   - Allocate 32 bytes of shadow space + alignment padding before CALL.
;   - Pass arguments in RCX, RDX, R8, R9, then stack.
;   - Clean up after the call.
;
; This stub calls add_two_win64(3, 7) and returns the result.
global caller_example_win64

caller_example_win64:
    push rbp
    mov  rbp, rsp

    ; Align RSP to 16 bytes, then allocate shadow space (32 bytes).
    ; Before PUSH RBP: RSP was 16-byte aligned (at call site).
    ; After PUSH RBP:  RSP is 8-byte aligned.
    ; We need RSP % 16 == 0 at the CALL instruction.
    ; Allocate 32 (shadow) + 8 (align pad) = 40 bytes total.
    sub  rsp, 40

    mov  ecx, 3             ; arg1 = 3
    mov  edx, 7             ; arg2 = 7
    call add_two_win64      ; result in EAX

    add  rsp, 40            ; restore stack
    pop  rbp
    ret

; ---- Callee-saved register demo: Windows x64 vs SysV -----
;
; On Windows x64, RDI and RSI are CALLEE-SAVED.
; On SysV AMD64,  RDI and RSI are CALLER-SAVED (scratch).
;
; A function that uses RDI/RSI on Windows must save/restore them.
;
; Example: Windows x64 function that uses RDI/RSI internally.
global use_rdi_rsi_win64

use_rdi_rsi_win64:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16

    ; Save callee-saved regs (required on Windows x64)
    mov  [rsp],    rdi
    mov  [rsp+8],  rsi

    ; Use RDI/RSI for internal computation
    mov  rdi, rcx           ; copy arg1 (Windows: RCX) into RDI
    mov  rsi, rdx           ; copy arg2 (Windows: RDX) into RSI
    lea  eax, [edi + esi]

    ; Restore callee-saved regs
    mov  rdi, [rsp]
    mov  rsi, [rsp+8]

    add  rsp, 16
    pop  rbp
    ret

; ---- SysV equivalent: no save/restore needed for RDI/RSI --
global use_rdi_rsi_sysv

use_rdi_rsi_sysv:
    ; RDI=arg1, RSI=arg2 already (SysV convention)
    ; RDI and RSI are scratch — no need to save them.
    lea  eax, [edi + esi]
    ret
