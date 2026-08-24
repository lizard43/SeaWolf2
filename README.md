# Sea Wolf II

This project is a byte-exact reconstruction and reverse-engineering baseline
for **Sea Wolf II**, released by Dave Nutting Associates / Midway in 1978.

Sea Wolf II is a notable Dave Nutting Associates title because most of the game
is implemented in TERSE, DNA's direct-threaded Z80 language. Native Z80
primitives, 16-bit threaded addresses, inline operands, graphics, text, and
tables share the same 8 KB ROM image. A conventional linear disassembly does
not describe that structure correctly.

## Current status

- All four source ROMs match the canonical MAME CRC32 and SHA1 values.
- `src/seawolf2.asm` assembles into a byte-identical 8 KB program image.
- The generated `roms/seawolf2.zip` runs successfully in MAME 0.289.
- A controlled title-string edit was tested in MAME, confirming that MAME was
  executing the locally assembled ROM set.
- The reset path, native TERSE kernel, initial thread at `$02F0`, and control
  thread at `$0544` are reconstructed as assembly.
- Power-on diagnostics are instruction-aligned and documented.
- Character fonts, title and status strings, and the English, German, and
  French prompt tables are identified.
- The frame interrupt's discrete-sound output, timer decay, torpedo producers,
  collision producers, sonar sequence, dive effect, and coin-counter pulse are
  labeled and documented.
- Remaining mixed or unclassified regions are retained as byte-exact `DB`
  blocks. They can be replaced incrementally without losing the working build.

## ROM organization

The four 2 KB ROMs form one contiguous Z80 image mapped at `$0000-$1FFF`.

| ROM | Address | CRC32 | SHA1 |
| --- | ---: | --- | --- |
| `sw2x1.bin` | `$0000-$07FF` | `ad0103f6` | `c6e411444a824ce54b0eee10f7dc15e4229ec070` |
| `sw2x2.bin` | `$0800-$0FFF` | `e0430f0a` | `63d8c6b77e0aa536b4f5bb774bc9285f736d4265` |
| `sw2x3.bin` | `$1000-$17FF` | `05ad1619` | `c9dbeaa4540dc95f98970f501a420b18b9898c91` |
| `sw2x4.bin` | `$1800-$1FFF` | `1a1a14a2` | `57d0ddea9f8bf082f50d0468a726fd91aaabf4e4` |

Combined 8 KB image SHA1:
`23bbc0b9ceb066f1db6332cb4b8bc1540090dc1b`

## Discrete-sound control

The video interrupt converts the ten frame-timed bytes at `$C1D0-$C1D9` into
the two sound-board output ports. A nonzero event timer asserts its output, and
the interrupt decrements the timer once per video frame.

| RAM | Output | Function |
| --- | --- | --- |
| `$C1D5` | Port `$40`, bit 0 | Left torpedo |
| `$C1D4` | Port `$40`, bit 1 | Left ship hit |
| `$C1D3` | Port `$40`, bit 2 | Left mine hit |
| `$C1D2` | Port `$40`, bit 3 | Right torpedo |
| `$C1D1` | Port `$40`, bit 4 | Right ship hit |
| `$C1D0` | Port `$40`, bit 5 | Right mine hit |
| `$C1D6` | Port `$41`, bit 6 | Coin-counter pulse |
| `$C1D7` | Port `$41`, bit 5 | Left sonar |
| `$C1D8` | Port `$41`, bit 4 | Right sonar |
| `$C1D9` | Port `$41`, bits 0-3 | Dive trigger and pan sweep |

The source follows each producer back to its gameplay event:

- `TRIGGER_TORPEDO_SOUND` selects the left or right torpedo timer when a fire
  input creates a torpedo object.
- `TRIGGER_SHIP_OR_MINE_HIT_SOUND` selects the cabinet side and collision type,
  then writes the matching ship-hit or mine-hit timer.
- `START_SONAR_SEQUENCE` and `UPDATE_SONAR_SEQUENCE` generate the alternating
  left/right sonar pulses.
- `START_DIVE_SOUND` loads the dive countdown used for the trigger and pan
  field.
- `PULSE_COIN_COUNTER` handles `$C1D6`, which shares the timer block but drives
  the mechanical coin counter rather than audio.
- `UPDATE_DISCRETE_SOUND` packs the timers and writes ports `$40` and `$41`.

## Build

The project includes Bruce Norskog's zmac 1.3 for Linux and Windows. Both build
scripts use the bundled assembler explicitly and place the assembled image at
`src/seawolf2.bin`.

Linux:

```sh
./build.sh
```

Assembler command used by `build.sh`:

```sh
./tools/zmac -o src/seawolf2.bin src/seawolf2.asm
```

Windows 10/11:

```bat
build.bat
```

Assembler command used by `build.bat`:

```bat
tools\zmac.exe -o src\seawolf2.bin src\seawolf2.asm
```

Each script performs the same four steps:

1. Assemble `src/seawolf2.asm` into the 8 KB image and listing.
2. Split the image into the four original 2 KB ROM filenames.
3. Create `roms/seawolf2.zip` for MAME.
4. Print the SHA1 value of each generated ROM.

Generated files:

```text
src/seawolf2.bin
src/seawolf2.lst
roms/sw2x1.bin
roms/sw2x2.bin
roms/sw2x3.bin
roms/sw2x4.bin
roms/seawolf2.zip
```

## Run in MAME

From the project directory:

```sh
mame seawolf2 -rompath roms -samplepath samples
```

MAME must load `roms/seawolf2.zip`, not the reference archive under
`roms/original`.

## Sound samples

Sea Wolf II's original discrete sound board is not yet emulated by MAME. MAME
plays five external samples in response to the game's output on ports `$40`
and `$41`.

The controlled sample archive for this project is:

```text
samples/seawolf.zip
```

Using `-samplepath samples` as shown above makes MAME load the archive directly
from this project. To use the controlled archive with an existing MAME setup
instead, copy `samples/seawolf.zip` into the directory configured as MAME's
`samplepath`. Display that directory with:

```sh
mame -showconfig | grep '^samplepath'
```

The sample archive must contain these five files at its root:

```text
dive.wav
minehit.wav
shiphit.wav
sonar.wav
torpedo.wav
```

The archive name is shared with the original **Sea Wolf** ROM set. A ROM
archive containing files such as `sw0041.h` and `sw0044.e` is not the sound
sample archive. Confirm the installed samples with:

```sh
mame seawolf2 -samplepath samples -verifysamples
```

## Project layout

| Path | Contents |
| --- | --- |
| `src/seawolf2.asm` | Reconstructed and annotated source |
| `src/seawolf2.bin` | Generated contiguous 8 KB image |
| `src/seawolf2.lst` | Generated zmac listing |
| `build.sh` | Linux build and packaging script |
| `build.bat` | Windows build and packaging script |
| `tools/zmac` | Bundled Linux zmac 1.3 executable |
| `tools/zmac.exe` | Bundled Windows zmac 1.3 executable |
| `roms/original/seawolf2.zip` | Canonical reference ROM archive |
| `roms/seawolf2.zip` | Generated MAME ROM archive |
| `samples/seawolf.zip` | Controlled MAME sound-sample archive |
| `docs/` | Manuals, schematics, and technical references |
| `images/` | Cabinet and hardware reference photographs |
| `cfg/` | MAME configuration files used by the project |

## Verification

The reconstruction is considered valid only when the complete 8 KB output and
all four split ROMs retain the canonical hashes above. Labels, comments,
equates, and decoded instructions may change; assembled bytes may not.
