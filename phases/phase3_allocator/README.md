# Phase 3 — Custom Memory Allocator

**Prerequisites:** [Phase 2 — Basic Disassembler](../phase2_disassembler/README.md)  
**Next:** [Phase 4 — Reverse Engineering](../phase4_reverse_engineering/README.md)

---

## Goal

Build a minimal but real allocator implementing `malloc(size)` and `free(ptr)` using `sbrk` for heap growth, with a **free list** and block headers.

---

## 1) Deep Explanation (WHY + HOW)

### Heap Basics

- Heap memory grows upward in virtual address space.
- `sbrk(n)` moves the program break (heap end) forward by `n` bytes.
- Each allocated block needs metadata: size + free/used flag.

### Block Layout

```
+----------------------+-----------------------------+
| Header (16 bytes)    | User data                   |
+----------------------+-----------------------------+
^                      ^
h                      h+1  (returned to caller)
```

### Header Structure

```c
struct header {
    size_t         size;  /* total size including header */
    struct header *next;  /* next block in free list */
    int            free;  /* 1 if free, 0 if allocated */
};
```

### Free List Strategy (First-Fit)

- On `malloc`: walk the free list, find the first block with `free==1` and `size >= requested`.
- On `free`: mark the block's header `free = 1`.
- Coalescing (merging adjacent free blocks) reduces fragmentation.

---

## 2) Implementation

See [`allocator.c`](allocator.c) for the complete implementation.

### Build and test

```bash
gcc -Wall -o alloctest allocator.c
./alloctest
```

---

## 3) Step-by-Step Execution Trace

### `malloc(24)` on an empty heap

1. `ALIGN8(24)` → 24 (already aligned)
2. `total = 24 + sizeof(header)` = 24 + 24 = 48
3. Free list is empty → call `sbrk(48)`
4. Header placed at break address; `free=0`
5. Return `h + 1` (pointer past the header)

Free list after:
```
[header: size=48, free=0, next=NULL]
```

### `free(ptr)` 

1. Recover header: `h = (header*)ptr - 1`
2. Set `h->free = 1`

### Second `malloc(24)` after free

1. Walk free list, find block with `free==1` and `size >= 48`
2. Mark `free=0`, return same pointer — **no new sbrk call**

---

## 4) Debugging Walkthrough

```bash
gdb ./alloctest
(gdb) break malloc
(gdb) run
(gdb) stepi
(gdb) x/4gx free_list   # inspect header fields
```

Check:
- `free_list->size`
- `free_list->free`
- Returned pointer vs header address

---

## 5) Exercises

**Easy**
1. Add `calloc(n, size)` (allocate + zero the memory).
2. Add `realloc(ptr, size)` (alloc new, `memcpy`, free old).

**Medium**
1. Split oversized blocks to reduce waste.
2. Coalesce adjacent free blocks in `free()`.

**Expert**
1. Use `mmap` instead of `sbrk` for large allocations (> 128 KB).
2. Add size-class buckets (segregated free lists).

---

## 6) Pitfalls & Edge Cases

- **Alignment errors** → crashes on SIMD loads.
- **Double free** → corrupt free list.
- **No coalescing** → fragmentation fills the heap with unusable slivers.
- **No split** → small allocs in a large block waste space.

---

## 7) Real-World Relevance

- This is the conceptual core of `ptmalloc` (glibc) and `jemalloc`.
- Heap layout knowledge is prerequisite for heap exploitation.
- Reverse engineers identify allocators to model memory corruption.

---

## Navigation

← [Phase 2 — Basic Disassembler](../phase2_disassembler/README.md)  
→ [Phase 4 — Reverse Engineering](../phase4_reverse_engineering/README.md)
