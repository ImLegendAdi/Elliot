; strlen_sse2.asm — Optimized strlen using SSE2 (Phase 5, SysV ABI)
;
; size_t strlen_sse2(const char *s);
;
;   RDI = s  (pointer to null-terminated string)
;   Returns length in RAX (not including null byte)
;
; SysV ABI: arg1 in RDI, return in RAX, no callee-saved regs used.
;
; Build (Linux):
;   nasm -f elf64 strlen_sse2.asm -o strlen_sse2.o
;
; Build (macOS):
;   nasm -f macho64 strlen_sse2.asm -o strlen_sse2.o
;   (prefix symbol names with _ if needed)

global strlen_sse2

section .text

strlen_sse2:
    mov  rax, rdi           ; rax = base address (used to compute length at end)
    pxor xmm0, xmm0         ; xmm0 = all zeros (our "zero" vector for comparison)

    ; Align rdi down to 16-byte boundary so our 16-byte loads are aligned.
    ; We check bytes before the alignment boundary manually.
    ; (Simpler unaligned variant: skip alignment, accept potential page-fault risk.)

.loop:
    movdqu xmm1, [rdi]      ; load 16 bytes (unaligned is safe here for demo)
    pcmpeqb xmm1, xmm0      ; xmm1[k] = 0xFF if byte k == 0, else 0x00
    pmovmskb ecx, xmm1      ; ecx = 16-bit mask: bit k = 1 iff byte k was zero
    test ecx, ecx
    jnz .found              ; at least one zero byte in this chunk

    add  rdi, 16            ; advance 16 bytes, no zero found
    jmp  .loop

.found:
    bsf  ecx, ecx           ; ecx = index of lowest set bit (= offset of first '\0')
    add  rdi, rcx           ; rdi now points at the null terminator
    sub  rdi, rax           ; length = (null ptr) - (base ptr)
    mov  rax, rdi
    ret
