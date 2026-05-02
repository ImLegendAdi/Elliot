/*
 * challenge.c — Challenge 2: Hidden Constant
 *
 * The function check_magic is the reverse engineering target.
 * main() exercises it with command-line input.
 *
 * Build with Makefile (which strips the final binary).
 */

#include <stdio.h>
#include <stdlib.h>

/* --- target function --- */
int check_magic(int x)
{
    return (x == 1337) ? 1 : 0;
}

/* --- driver --- */
int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <integer>\n", argv[0]);
        return 1;
    }

    int x      = atoi(argv[1]);
    int result = check_magic(x);
    printf("%d\n", result);
    return 0;
}
