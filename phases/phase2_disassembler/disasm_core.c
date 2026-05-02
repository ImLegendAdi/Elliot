/*
 * disasm_core.c — Minimal x86-64 decoder (Phase 2)
 *
 * Supports:
 *   - REX prefix
 *   - Opcodes: 0x89 (MOV r/m64,r64), 0x8B (MOV r64,r/m64),
 *              0x01 (ADD r/m64,r64), 0xB8-0xBF (MOV r64,imm)
 *   - ModRM, SIB, disp8/disp32, imm32/imm64
 *
 * Build:
 *   gcc -Wall -o disasm disasm_core.c
 *
 * Usage:
 *   Supply raw bytes via stdin or modify main() with a test buffer.
 */

#include <stdint.h>
#include <stddef.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

/* ---------- data structures ---------- */

typedef struct {
    uint8_t  rex;
    uint8_t  opcode;
    uint8_t  modrm;
    uint8_t  sib;
    int32_t  disp;
    int      disp_size;
    uint64_t imm;
    int      imm_size;
} Inst;

/* ---------- register name tables ---------- */

static const char *reg64[16] = {
    "rax","rcx","rdx","rbx","rsp","rbp","rsi","rdi",
    "r8", "r9", "r10","r11","r12","r13","r14","r15"
};

/* ---------- decode ---------- */

/*
 * Decode one instruction starting at *p.
 * Returns the number of bytes consumed, or 0 on error.
 */
size_t decode_inst(const uint8_t *p, Inst *out)
{
    size_t i = 0;

    memset(out, 0, sizeof(*out));

    /* REX prefix: 0100WRXB */
    if ((p[i] & 0xF0) == 0x40) {
        out->rex = p[i++];
    }

    out->opcode = p[i++];

    /* Opcodes that use ModRM */
    if (out->opcode == 0x8B || out->opcode == 0x89 || out->opcode == 0x01) {
        out->modrm = p[i++];

        uint8_t mod = out->modrm >> 6;
        uint8_t rm  = out->modrm & 0x7;

        /* SIB byte present when mod != 11 and rm == 100 */
        if (mod != 3 && rm == 4) {
            out->sib = p[i++];
        }

        /* Displacement */
        if (mod == 1) {                          /* disp8 */
            out->disp_size = 1;
            out->disp = (int8_t)p[i++];
        } else if (mod == 2 || (mod == 0 && rm == 5)) { /* disp32 */
            out->disp_size = 4;
            memcpy(&out->disp, p + i, 4);
            i += 4;
        }
    }

    /* MOV r64, imm: opcodes 0xB8..0xBF */
    if ((out->opcode & 0xF8) == 0xB8) {
        out->imm_size = (out->rex & 0x08) ? 8 : 4;  /* REX.W → imm64 */
        if (out->imm_size == 8) {
            memcpy(&out->imm, p + i, 8);
        } else {
            uint32_t tmp;
            memcpy(&tmp, p + i, 4);
            out->imm = tmp;
        }
        i += out->imm_size;
    }

    return i;
}

/* ---------- format ---------- */

/*
 * Print a decoded instruction in Intel syntax.
 * offset: byte offset of this instruction in the stream.
 * raw:    pointer to the raw bytes (for hex dump).
 * len:    number of bytes in this instruction.
 */
void print_inst(uint64_t offset, const uint8_t *raw, size_t len,
                const Inst *inst)
{
    /* Hex dump */
    printf("%04" PRIx64 ": ", offset);
    for (size_t k = 0; k < len; k++) printf("%02x ", raw[k]);
    /* Pad to fixed width */
    for (size_t k = len; k < 10; k++) printf("   ");
    printf("  ");

    /* Mnemonic */
    int rex_r = (inst->rex >> 2) & 1;
    int rex_b = (inst->rex >> 0) & 1;
    int reg   = ((inst->modrm >> 3) & 7) | (rex_r << 3);
    int rm    = (inst->modrm & 7)        | (rex_b << 3);
    int mod   = inst->modrm >> 6;

    const char *mnem = "???";
    if (inst->opcode == 0x8B) mnem = "mov";
    else if (inst->opcode == 0x89) mnem = "mov";
    else if (inst->opcode == 0x01) mnem = "add";
    else if ((inst->opcode & 0xF8) == 0xB8) mnem = "mov";

    printf("%s ", mnem);

    /* Destination / source operands */
    if ((inst->opcode & 0xF8) == 0xB8) {
        /* MOV r64, imm */
        int r = (inst->opcode & 7) | rex_b;
        printf("%s, 0x%" PRIx64, reg64[r], inst->imm);
    } else if (inst->opcode == 0x8B) {
        /* MOV reg, r/m */
        printf("%s, ", reg64[reg]);
        if (mod == 3) {
            printf("%s", reg64[rm]);
        } else {
            printf("[");
            if (inst->sib || (inst->modrm & 7) == 4) {
                /* SIB addressing */
                int scale = 1 << (inst->sib >> 6);
                int idx   = ((inst->sib >> 3) & 7) | ((inst->rex >> 1 & 1) << 3);
                int base  = (inst->sib & 7)        | (rex_b << 3);
                printf("%s", reg64[base]);
                if (idx != 4) printf(" + %s*%d", reg64[idx], scale);
            } else {
                printf("%s", reg64[rm]);
            }
            if (inst->disp_size == 1) printf(" + 0x%x", (uint8_t)inst->disp);
            else if (inst->disp_size == 4) printf(" + 0x%x", inst->disp);
            printf("]");
        }
    } else if (inst->opcode == 0x89 || inst->opcode == 0x01) {
        /* MOV/ADD r/m, reg */
        if (mod == 3) {
            printf("%s, %s", reg64[rm], reg64[reg]);
        } else {
            printf("[%s", reg64[rm]);
            if (inst->disp_size == 1) printf(" + 0x%x", (uint8_t)inst->disp);
            else if (inst->disp_size == 4) printf(" + 0x%x", inst->disp);
            printf("], %s", reg64[reg]);
        }
    }

    printf("\n");
}

/* ---------- main ---------- */

int main(void)
{
    /*
     * Example buffer: mov rax, [rbp + rcx*4 + 0x120]
     *   48 8B 84 8D 20 01 00 00
     */
    uint8_t buf[] = {
        0x48, 0x8B, 0x84, 0x8D, 0x20, 0x01, 0x00, 0x00,  /* mov rax,[rbp+rcx*4+0x120] */
        0x48, 0x89, 0xC3,                                  /* mov rbx, rax              */
        0x48, 0xB8, 0x37, 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* mov rax, 0x1337 */
        0x48, 0x01, 0xD8,                                  /* add rax, rbx              */
    };

    size_t offset = 0;
    while (offset < sizeof(buf)) {
        Inst inst;
        size_t len = decode_inst(buf + offset, &inst);
        if (len == 0) {
            fprintf(stderr, "decode error at offset %zu\n", offset);
            break;
        }
        print_inst((uint64_t)offset, buf + offset, len, &inst);
        offset += len;
    }
    return 0;
}
