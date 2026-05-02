/*
 * allocator.c — Minimal malloc/free using sbrk (Phase 3)
 *
 * Implements:
 *   void *malloc(size_t size)
 *   void  free(void *ptr)
 *
 * Strategy: first-fit free list over sbrk-grown heap.
 *
 * Build:
 *   gcc -Wall -o alloctest allocator.c
 */

#include <unistd.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

/* ---------- block header ---------- */

typedef struct header {
    size_t         size;  /* total block size including this header */
    struct header *next;
    int            free;
} header_t;

static header_t *free_list = NULL;

/* Round x up to the nearest multiple of 8 */
#define ALIGN8(x)  (((x) + 7) & ~(size_t)7)

/* ---------- internal helpers ---------- */

static header_t *request_from_os(size_t total)
{
    void *p = sbrk((intptr_t)total);
    if (p == (void *)-1) return NULL;

    header_t *h = (header_t *)p;
    h->size = total;
    h->next = NULL;
    h->free = 0;
    return h;
}

/* ---------- public API ---------- */

void *malloc(size_t size)
{
    if (size == 0) return NULL;

    size = ALIGN8(size);
    size_t total = size + sizeof(header_t);

    /* Walk the free list looking for a suitable block */
    header_t *prev = NULL;
    header_t *cur  = free_list;

    while (cur) {
        if (cur->free && cur->size >= total) {
            cur->free = 0;
            return (void *)(cur + 1);
        }
        prev = cur;
        cur  = cur->next;
    }

    /* No suitable block found — ask the OS */
    header_t *h = request_from_os(total);
    if (!h) return NULL;

    if (prev) prev->next = h;
    else      free_list  = h;

    return (void *)(h + 1);
}

void free(void *ptr)
{
    if (!ptr) return;
    header_t *h = (header_t *)ptr - 1;
    h->free = 1;
}

/* ---------- diagnostics ---------- */

static void dump_free_list(void)
{
    printf("free_list dump:\n");
    header_t *cur = free_list;
    int i = 0;
    while (cur) {
        printf("  [%d] addr=%p size=%zu free=%d\n",
               i++, (void *)cur, cur->size, cur->free);
        cur = cur->next;
    }
}

/* ---------- test driver ---------- */

int main(void)
{
    printf("=== allocator test ===\n");

    void *a = malloc(24);
    void *b = malloc(48);
    void *c = malloc(8);
    printf("a=%p  b=%p  c=%p\n", a, b, c);
    dump_free_list();

    free(b);
    printf("\nAfter free(b):\n");
    dump_free_list();

    void *d = malloc(32);
    printf("\nd=%p (should reuse b's slot)\n", d);
    dump_free_list();

    free(a);
    free(c);
    free(d);
    return 0;
}
