# Elliot — x86-64 Assembly & Reverse Engineering Learning Repo

A structured, hands-on curriculum for learning **x86-64 assembly**, **low-level systems programming**, and **reverse engineering** on both Linux (SysV ABI) and Windows (x64 ABI).

---

## How to Progress Through This Repo

Work through the phases in order. Each phase builds on the previous one and includes:
- Deep explanations of *why* and *how*
- Annotated source code
- Step-by-step debugging walkthroughs
- Exercises from easy to expert

```
phases/      ← Core curriculum (start here)
windows_abi/ ← Windows x64 ABI equivalents and ABI comparison
challenges/  ← Reverse engineering challenge binaries
```

---

## Table of Contents

### Phases (Core Curriculum)

| Phase | Topic | Description |
|-------|-------|-------------|
| [Phase 1](phases/phase1_basics/README.md) | x86-64 Basics | Registers, instructions, SysV calling convention |
| [Phase 2](phases/phase2_disassembler/README.md) | Basic Disassembler | Decode x86-64 byte streams; REX/ModRM/SIB |
| [Phase 3](phases/phase3_allocator/README.md) | Custom Memory Allocator | `malloc`/`free` using `sbrk`; free list, coalescing |
| [Phase 4](phases/phase4_reverse_engineering/README.md) | Reverse Engineering | Reconstruct intent from stripped binaries; GDB workflow |
| [Phase 5](phases/phase5_optimized_routines/README.md) | Optimized Routines | SIMD `strlen` & `memcpy` (SSE2/AVX); alignment tricks |

### Windows x64 ABI

| File/Topic | Description |
|------------|-------------|
| [ABI Comparison](windows_abi/README.md) | SysV vs Windows x64: registers, shadow space, alignment |
| [strlen (Win64)](windows_abi/strlen_win64.asm) | SSE2 `strlen` for Windows x64 ABI |
| [memcpy (Win64)](windows_abi/memcpy_win64.asm) | SSE2 `memcpy` for Windows x64 ABI |
| [Calling Conventions](windows_abi/calling_conventions.asm) | Side-by-side function call demos |

### Reverse Engineering Challenges

| Challenge | Difficulty | Skill Practiced |
|-----------|-----------|-----------------|
| [Challenge 1 — Sum Array](challenges/challenge1_sum_array/README.md) | Easy | Recover function behavior, identify loop/array pattern |
| [Challenge 2 — Hidden Constant](challenges/challenge2_hidden_constant/README.md) | Medium | Find hidden constant via branch analysis |
| [Challenge 3 — Struct Layout](challenges/challenge3_struct_layout/README.md) | Hard | Reconstruct struct layout from memory access patterns |

See the [Challenges README](challenges/README.md) for build instructions and analysis guidance.

---

## Prerequisites

- A Linux x86-64 system (or WSL2 on Windows)
- `nasm` — `sudo apt install nasm`
- `gcc` — `sudo apt install gcc`
- `gdb` — `sudo apt install gdb`
- Optional: `objdump`, `readelf`, `xxd`

For Windows-native builds:
- [NASM for Windows](https://www.nasm.us/pub/nasm/releasebuilds/)
- [MinGW-w64](https://www.mingw-w64.org/) or MSVC

---

## Quick Start

```bash
# Clone and explore
git clone https://github.com/ImLegendAdi/Elliot.git
cd Elliot

# Build a challenge
cd challenges/challenge1_sum_array
make

# Work through a phase
cat phases/phase2_disassembler/README.md
```

---

## Repository Map

```
Elliot/
├── README.md                         ← You are here
├── phases/
│   ├── README.md
│   ├── phase1_basics/
│   │   └── README.md
│   ├── phase2_disassembler/
│   │   ├── README.md
│   │   └── disasm_core.c
│   ├── phase3_allocator/
│   │   ├── README.md
│   │   └── allocator.c
│   ├── phase4_reverse_engineering/
│   │   ├── README.md
│   │   └── phase4_re.asm
│   └── phase5_optimized_routines/
│       ├── README.md
│       ├── strlen_sse2.asm
│       └── memcpy_sse2.asm
├── windows_abi/
│   ├── README.md
│   ├── calling_conventions.asm
│   ├── strlen_win64.asm
│   └── memcpy_win64.asm
└── challenges/
    ├── README.md
    ├── challenge1_sum_array/
    │   ├── README.md
    │   ├── challenge.c
    │   └── Makefile
    ├── challenge2_hidden_constant/
    │   ├── README.md
    │   ├── challenge.c
    │   └── Makefile
    └── challenge3_struct_layout/
        ├── README.md
        ├── challenge.c
        └── Makefile
```

---

## Learning Path

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
                                   ↓           ↓
                           Challenges    Windows ABI
```

Start at Phase 1, complete each phase's exercises, then tackle the challenges once you've finished Phase 4 or 5.
