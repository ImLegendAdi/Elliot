; memcpy_win64.asm — SSE2 memcpy, Windows x64 ABI
;
; void *memcpy_win64(void *dst, const void *src, size_t n);
;
;   Windows x64 ABI:
;     Arg 1 = RCX  (dst)
;     Arg 2 = RDX  (src)
;     Arg 3 = R8   (n)
;     Return = RAX (original dst)
;
;   Key differences from SysV version (memcpy_sse2.asm):
;     - Args arrive in RCX/RDX/R8, not RDI/RSI/RDX.
;     - RDI and RSI are callee-saved on Windows.
;       This implementation uses R9/R10 as working pointers so
;       RDI/RSI are never touched, avoiding the need to save them.
;     - XMM6-XMM15 are callee-saved; we only use XMM0 (volatile).
;
;   Does NOT handle overlapping src/dst.
;
; Build (Windows, NASM + MSVC):
;   nasm -f win64 memcpy_win64.asm -o memcpy_win64.obj
;
; Build (cross-compile, MinGW):
;   nasm -f win64 memcpy_win64.asm -o memcpy_win64.o

global memcpy_win64

section .text

memcpy_win64:
    mov  rax, rcx           ; return value = original dst

    test r8, r8
    je   .done              ; n == 0

    ; Use R9/R10 as dst/src working pointers
    ; (avoids touching callee-saved RDI/RSI)
    mov  r9,  rcx           ; r9  = dst (working)
    mov  r10, rdx           ; r10 = src (working)
    ; r8 = n (already set)

    ; ---- Phase 1: align dst to 16-byte boundary ----
.align_loop:
    test r9, 0xF            ; is dst 16-byte aligned?
    jz   .bulk

    mov  cl, [r10]          ; copy one byte  (NB: cl clobbers rcx; save rax already done)
    mov  [r9], cl
    inc  r10
    inc  r9
    dec  r8
    jnz  .align_loop
    jmp  .done

    ; ---- Phase 2: bulk 16-byte copies ----
.bulk:
    cmp  r8, 16
    jb   .tail

.bulk_loop:
    movdqu xmm0, [r10]      ; load 16 bytes (src may be unaligned)
    movdqa [r9],  xmm0      ; store 16 bytes (dst is 16-byte aligned)
    add  r10, 16
    add  r9,  16
    sub  r8,  16
    cmp  r8,  16
    jae  .bulk_loop

    ; ---- Phase 3: tail bytes ----
.tail:
    test r8, r8
    je   .done

.tail_loop:
    mov  cl, [r10]
    mov  [r9], cl
    inc  r10
    inc  r9
    dec  r8
    jnz  .tail_loop

.done:
    ret
