/*
 * challenge.c — Challenge 1: Sum Array
 *
 * The function sum_array is the target for reverse engineering.
 * main() drives it with a test case so the binary produces visible output.
 *
 * Build with Makefile (which strips the final binary).
 */

#include <stdio.h>

/* --- target function (do not read before attempting RE) --- */
int sum_array(int *a, int n)
{
    int s = 0;
    for (int i = 0; i < n; i++) s += a[i];
    return s;
}

/* --- driver ------------------------------------------------ */
int main(void)
{
    int data[] = {10, 20, 30, 40, 50};
    int n      = (int)(sizeof(data) / sizeof(data[0]));

    int result = sum_array(data, n);
    printf("result: %d\n", result);   /* expected: 150 */
    return 0;
}
