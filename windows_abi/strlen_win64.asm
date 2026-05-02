; strlen_win64.asm — SSE2 strlen, Windows x64 ABI
;
; size_t strlen_win64(const char *s);
;
;   Windows x64 ABI:
;     Arg 1 = RCX  (string pointer)
;     Return = RAX
;
;   Key differences from SysV version (strlen_sse2.asm):
;     - Arg1 arrives in RCX, not RDI.
;     - RDI and RSI are callee-saved on Windows; we don't touch them here.
;     - XMM6-XMM15 are callee-saved; we only use XMM0/XMM1 (volatile).
;
; Build (Windows, NASM + MSVC):
;   nasm -f win64 strlen_win64.asm -o strlen_win64.obj
;
; Build (cross-compile, MinGW):
;   nasm -f win64 strlen_win64.asm -o strlen_win64.o

global strlen_win64

section .text

strlen_win64:
    ; Prologue: this is a leaf function; no frame needed.
    ; Shadow space (32 bytes) was allocated by the caller — we don't touch it.

    mov  rax, rcx           ; rax = base address (save for length calculation)
    pxor xmm0, xmm0         ; xmm0 = all zeros

.loop:
    movdqu xmm1, [rcx]      ; load 16 bytes from current position (unaligned)
    pcmpeqb xmm1, xmm0      ; xmm1[k] = 0xFF where byte k == '\0'
    pmovmskb edx, xmm1      ; edx = 16-bit mask of zero-byte positions
    test edx, edx
    jnz  .found             ; found a null byte in this chunk

    add  rcx, 16            ; advance 16 bytes
    jmp  .loop

.found:
    bsf  edx, edx           ; edx = bit index of first set bit (= offset of '\0')
    add  rcx, rdx           ; rcx now points at the null terminator
    sub  rcx, rax           ; length = (null ptr) - (base ptr)
    mov  rax, rcx
    ret
