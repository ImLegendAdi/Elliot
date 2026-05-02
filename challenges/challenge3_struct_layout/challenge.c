/*
 * challenge.c — Challenge 3: Struct Layout
 *
 * The function process_record is the reverse engineering target.
 * Analyze the disassembly to reconstruct the struct definition.
 *
 * Build with Makefile (which strips the final binary).
 */

#include <stdio.h>
#include <stdint.h>

/* --- hidden struct (do not read before attempting RE) --- */
struct Record {
    int      id;      /* offset  0 */
                      /* 4 bytes padding */
    long     value;   /* offset  8 */
    uint8_t  flags;   /* offset 16 */
                      /* 3 bytes padding */
    int      score;   /* offset 20 */
};
/* sizeof(struct Record) == 24 */

/* --- target function --- */
long process_record(struct Record *r)
{
    long total = 0;

    if (r->flags) {
        total = r->value + (long)r->score;
    }

    return total;
}

/* --- driver --- */
int main(void)
{
    struct Record rec = {
        .id    = 42,
        .value = 1000000LL,
        .flags = 1,
        .score = 9999,
    };

    long result = process_record(&rec);
    printf("result: %ld\n", result);   /* expected: 1009999 */

    struct Record rec2 = {
        .id    = 7,
        .value = 500LL,
        .flags = 0,    /* flags == 0: total stays 0 */
        .score = 200,
    };

    long result2 = process_record(&rec2);
    printf("result: %ld\n", result2);  /* expected: 0 */

    return 0;
}
