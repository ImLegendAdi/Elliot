; phase4_re.asm — Annotated reverse engineering target (Phase 4)
;
; This is the disassembly of:
;   int sum(int *a, int n) { int s=0; for(int i=0;i<n;i++) s+=a[i]; return s; }
;
; Build (Linux, NASM):
;   nasm -f elf64 phase4_re.asm -o phase4_re.o
;   gcc  -o target phase4_re.o -nostdlib -e sum   # won't run standalone; use as lib
;
; Or compile the C version:
;   gcc -O0 -g -o target_dbg sum.c
;   strip -o target_stripped target_dbg

global sum

section .text

; int sum(int *a, int n)
;   RDI = a  (pointer to int array)
;   RSI = n  (element count)
;   Returns sum in EAX (sign-extended to RAX)
sum:
    xor eax, eax            ; eax = 0  (accumulator s)
                             ; xor r32,r32 also zeroes upper 32 bits → zero extends to rax

    xor ecx, ecx            ; ecx = 0  (loop index i)

.loop:
    cmp ecx, esi            ; compare i (ecx) with n (esi)
    jge .done               ; if i >= n, exit loop  (signed >=)

    add eax, [rdi + rcx*4]  ; s += a[i]
                             ; rdi = base of array
                             ; rcx*4 = byte offset (int = 4 bytes)
                             ; [base + index*4] = a[i]

    inc ecx                 ; i++
    jmp .loop

.done:
    ret                     ; return value in eax (SysV: integer return in RAX/EAX)
