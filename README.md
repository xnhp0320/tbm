# Tree Bitmap algorithm in C3

Longest-prefix-match trie (Tree Bitmap) implemented in C3, with an optional C header binding (`tbmlib.h`).

## Ownership

- `Tbm.init(n)` allocates an owned slab. Call only on a **zeroed** `Tbm` (or after `Tbm.free`). Re-init without `free` asserts in safe builds and would leak.
- `Tbm.init_mem(alloc)` borrows an external allocator. Call only when `alloc == null`. Tear down with `Tbm.free_mem`.
- `Tbm.free` is for owned slabs from `init`; `Tbm.free_mem` is for borrowed allocators from `init_mem`.

## Thread safety

`Tbm` is **not thread-safe**. It assumes a single writer:

- Do not call `insert` / `remove` concurrently with `lookup`, `iterate`, or each other.
- Do not mutate the tree from an `iterate` callback. Insert/remove may reallocate packed value and child storage; pointers passed to the callback can become invalid.
- External synchronization is required if multiple threads share one `Tbm`.

## C ABI

- `FibTbm` / `FibCidr` layouts are compiler-generated and may change; treat them as opaque and only use the exported functions.
- Zero a `FibTbm`, then `tbm_init`. Re-init only after `tbm_free`.
- `tbm_init` / `tbm_insert` / `tbm_remove` / `tbm_lookup` return a `c3fault_t` (`NULL` = success). Use `tbm_fault_name` for a short fault name.

## Benchmarks

Benchmarks live in `test/tbmlibtest.c3` (`@benchmark`). Project `c3c benchmark` alone does not pick up `test-sources`, so add the test file explicitly:

```bash
c3c benchmark -O3 --sources test/tbmlibtest.c3
```

Run from the repo root so `ipv4_fib.txt` / `ipv4_fib_large.txt` resolve. Optional: `--benchmark-csv-report` for CSV output.
