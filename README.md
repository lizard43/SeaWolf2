# Sea Wolf II
Sea Wolf II is an interesting Dave Nutting Associates (DNA) title because it was written mostly in TERSE, DNA’s direct-threaded Z80 Forth system

This project is a byte-exact reconstruction and reverse-engineering baseline for **Sea Wolf II**, released by Dave Nutting Associates / Midway in 1978.

## Sea Wolf II Disassembly
A linear Z80 disassembly looks confusing because much of the 8 KB image consists of 16-bit threaded addresses and data, interspersed with native Z80 primitives.

The game occupies four 2 KB ROMs mapped contiguously at `$0000-$1FFF`. It uses a Z80 native-code kernel and direct-threaded TERSE game code. 

## Current status: Phase 1

- All four source ROMs validated against the canonical MAME SHA1 values.
- Complete 8 KB source assembles byte-for-byte.
- Reset path and TERSE execution kernel reconstructed as native Z80 assembly.
- Initial TERSE execution thread decoded at `$02F0`.
- Early control thread decoded at `$0544`.
- Power-on diagnostics instruction-aligned and documented.
- Character font, title strings, status strings
- All English, German, and French prompt pointer tables identified.
- Frame sound-output routine and player lamp-output sites identified.
- Unclassified mixed-code regions remain as byte-exact `DB` blocks. Each block can be replaced incrementally without losing a working build.


## ROM checksums

| ROM | Address | CRC32 | SHA1 |
| --- | ---: | --- | --- |
| `sw2x1.bin` | `$0000-$07FF` | `ad0103f6` | `c6e411444a824ce54b0eee10f7dc15e4229ec070` |
| `sw2x2.bin` | `$0800-$0FFF` | `e0430f0a` | `63d8c6b77e0aa536b4f5bb774bc9285f736d4265` |
| `sw2x3.bin` | `$1000-$17FF` | `05ad1619` | `c9dbeaa4540dc95f98970f501a420b18b9898c91` |
| `sw2x4.bin` | `$1800-$1FFF` | `1a1a14a2` | `57d0ddea9f8bf082f50d0468a726fd91aaabf4e4` |

Combined image SHA1: `23bbc0b9ceb066f1db6332cb4b8bc1540090dc1b`

## Build

The source targets zmac 1.3.

Linux:

```sh
./build.sh
```

Windows 10/11:

```bat
build.bat
```

Set `ZMAC` to an explicit executable when zmac is not in `PATH`.

The scripts assemble the 8 KB image, split it into the four original 2 KB ROM
names, and create `roms/seawolf2.zip` for MAME.

## Project layout
