; memcpy_sse2.asm — Optimized memcpy using SSE2 (Phase 5, SysV ABI)
;
; void *memcpy_sse2(void *dst, const void *src, size_t n);
;
;   RDI = dst
;   RSI = src
;   RDX = n
;   Returns original dst in RAX.
;
; Strategy:
;   1. Align dst to 16-byte boundary (byte-by-byte copy).
;   2. Bulk copy in 16-byte chunks (movdqu load + movdqa store).
;   3. Copy remaining 0-15 tail bytes.
;
; Note: Does NOT handle overlapping src/dst (use memmove for that).
;
; Build (Linux):
;   nasm -f elf64 memcpy_sse2.asm -o memcpy_sse2.o
;
; Build (macOS):
;   nasm -f macho64 memcpy_sse2.asm -o memcpy_sse2.o

global memcpy_sse2

section .text

memcpy_sse2:
    mov  rax, rdi           ; preserve original dst for return value
    test rdx, rdx
    je   .done              ; n == 0: nothing to do

    ; ---- Phase 1: align dst to 16-byte boundary ----
.align_loop:
    test rdi, 0xF           ; is dst aligned to 16 bytes?
    jz   .bulk              ; yes: jump to bulk copy

    mov  bl, [rsi]          ; copy one byte
    mov  [rdi], bl
    inc  rsi
    inc  rdi
    dec  rdx
    jnz  .align_loop        ; keep aligning if n > 0
    jmp  .done              ; n hit zero during alignment

    ; ---- Phase 2: bulk 16-byte aligned copies ----
.bulk:
    cmp  rdx, 16
    jb   .tail              ; fewer than 16 bytes left → tail copy

.bulk_loop:
    movdqu xmm0, [rsi]      ; load 16 bytes (src may be unaligned)
    movdqa [rdi], xmm0      ; store 16 bytes (dst is 16-byte aligned here)
    add  rsi, 16
    add  rdi, 16
    sub  rdx, 16
    cmp  rdx, 16
    jae  .bulk_loop         ; while n >= 16

    ; ---- Phase 3: tail copy (0-15 bytes) ----
.tail:
    test rdx, rdx
    je   .done

.tail_loop:
    mov  bl, [rsi]
    mov  [rdi], bl
    inc  rsi
    inc  rdi
    dec  rdx
    jnz  .tail_loop

.done:
    ret
