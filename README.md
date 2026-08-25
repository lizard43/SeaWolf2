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
- Power-on diagnostics are reconstructed as native Z80 and documented.
- Character fonts, title and status strings, and the English, German, and
  French prompt tables are identified.
- The 25-byte object-record ABI, all three scheduler pools, object selection,
  fixed-point movement, rendering, and the target/torpedo/mine handlers are
  reconstructed as native Z80.
- All nine object type IDs, their target classes, speeds, scores, bitmap lists,
  hit animations, collision lanes, and torpedo perspective frames are mapped.
- Torpedo, surface-target, mine, and Super Sub lifecycles are traced from
  allocation through scheduling, movement, drawing, collision, scoring,
  sound, animation, retirement, and reuse.
- Both six-entry raster schedules, their IM 2 vector selection, the primary and
  alternate interrupt handlers, and the four moving split-line states are fully
  decoded.
- The frame interrupt's discrete-sound output, timer decay, torpedo producers,
  collision producers, sonar sequence, dive effect, and coin-counter pulse are
  labeled and documented.
- The remaining `DB` regions are inventoried by address and type. They contain
  1,105 bytes of native Z80 awaiting promotion, 22 bytes of TERSE, verified
  tables and graphics, ROM fill, and one uncertain byte at `$1385`.

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

## Object types

`OBJECT_TYPE` is byte 1 of every 25-byte object record. The complete type map
is:

Class names and displayed values follow Midway's
[1978 sales flyer](https://flyers.arcade-museum.com/videogames/show/905). The
ROM's BCD score decoder matches those values.

| ID | Source label | Live bitmap | Size | X motion per update | Score |
| ---: | --- | ---: | ---: | ---: | ---: |
| `$00` | `OBJECT_TYPE_WARSHIP_A` | `$0E3F` | 20x12 | 1.0 pixel | 300 |
| `$01` | `OBJECT_TYPE_WARSHIP_B` | `$0E7D` | 16x11 | 1.0 pixel | 300 |
| `$02` | `OBJECT_TYPE_WARSHIP_C` | `$0EAB` | 20x10 | 1.0 pixel | 300 |
| `$03` | `OBJECT_TYPE_FREIGHTER_A` | `$0EDF` | 16x10 | 0.5 pixel | 100 |
| `$04` | `OBJECT_TYPE_FREIGHTER_B` | `$0F09` | 16x9 | 0.5 pixel | 100 |
| `$05` | `OBJECT_TYPE_PT_BOAT` | `$0F2F` | 12x5 | 2.0 pixels | 500 |
| `$06` | `OBJECT_TYPE_MINE` | `$117B` | 4x16 | 0.5 pixel | none |
| `$07` | `OBJECT_TYPE_TORPEDO` | `$112D` | 4x21 near | trajectory table | none |
| `$08` | `OBJECT_TYPE_SUPER_SUB` | `$0F40` | 16x9 surfaced | 1.0 pixel | 1000 |

The A/B/C suffixes identify distinct ROM silhouettes within Midway's named
Warship and Freighter classes. They do not assign unsupported real-world vessel
classes.

`PROCESS_SHIP_HIT` scans only the four target records at `$C000-$C04B`. A mine
collision stops the torpedo and triggers `minehit`; it does not add score.
The PT Boat starts the sonar sequence; the Super Sub starts the dive effect.

The table ranges are fully structured:

- `$0DC8-$0DD1` cycles through all five surface-ship silhouettes and two PT
  Boat slots. Only a `FREIGHTER_A` slot can become the Super Sub.
- `$0DD2-$0DDA` supplies the per-type horizontal speed. Mine and torpedo entries
  are zero because their constructors set velocity separately.
- `$0DDB-$0E3E` contains complete initial records for an upper-lane Warship A,
  lower-lane Super Sub, left torpedo, and right torpedo.
- `$1A53-$1AC2` contains the nine bitmap sequences. Warships, freighters, and
  the PT Boat share size-appropriate hit-animation tails.
- `$1AC3-$1AD4` maps every type ID to its bitmap sequence.
- `$1AD5-$1AE3` maps torpedo Y to two target lanes and three mine lanes.
- `$1AE4-$1AE6` selects near, middle, and far torpedo perspective frames.

The normal target constructor promotes a `FREIGHTER_A` slot to the Super Sub
only when fewer than 24 BCD seconds remain and the `$C1F7` counter is below two.
It displays `SUPER` / `SUB`, starts the dive sound, advances through two dive
frames every 42 target updates, and skips directly to its explosion sequence
when hit.

## Object lifecycles

The video interrupt services the object pools at fixed round-robin rates:

| Pool | Records | Calls per 60 Hz frame | Per-record rate |
| --- | ---: | ---: | ---: |
| Surface targets | 4 | 2 | 30 Hz |
| Player torpedoes | 8 | 4 | 30 Hz |
| Mines | 6 | 1 | 10 Hz |

Inactive target and mine records still have `OBJECT_TIMER` decremented by their
schedulers. Neither allocator tests that timer; reuse is controlled by
`OBJECT_FLAG_ACTIVE`, and allocation clears the complete 25-byte record.

### Player torpedo

`POLL_TORPEDO_FIRE` detects a fire-button edge for each active station.
`UPDATE_PLAYER_TORPEDO_FIRE` decrements the four-shot magazine, updates the
ready/reload lamps, and allocates that station's records in order 3, 2, 1, 0.
The left and right records are interleaved in `$C0FA-$C1A9`; records for one
station are `$32` bytes apart. The fourth shot starts the `$A0`-frame reload
timer.

`INITIALIZE_TORPEDO_OBJECT` sets Y=`$BB00`, Y velocity=`-$0400`, Y
acceleration=`+$000C`, Y minimum=`$23`, and the near perspective bitmap. The
decoded handle position indexes the station-specific table at `$0D48` or
`$0D88`, which supplies initial X and signed X velocity. Activation starts the
left or right torpedo sound for `$38` video frames.

`UPDATE_TORPEDO_OBJECT` runs at 30 Hz. It integrates the 8.8 coordinates,
selects near/middle/far frames at Y=`$78/$46/$00`, and probes seven Magic-RAM
bytes from the preceding draw for collision pixels. Y selects one of five
two-record lanes:

| Y range | Collision pool |
| ---: | --- |
| `$82+` | Lower mine lane `$C0C8` |
| `$64-$81` | Middle mine lane `$C096` |
| `$4C-$63` | Upper mine lane `$C064` |
| `$33-$4B` | Lower target lane `$C032` |
| `$23-$32` | Upper target lane `$C000` |

A ship collision deactivates the torpedo, marks the target for hit animation
and foreground scoring, records station ownership in target flag bit 3, copies
the torpedo color to the target, and starts `shiphit` for `$40` frames. A mine
collision deactivates the torpedo, marks the mine for hit animation, clears the
station's consecutive-ship-hit streak, and starts `minehit` for `$08` frames.
A boundary miss also clears the streak before the torpedo is erased and made
inactive.

### Surface target

`ACTIVATE_TARGET_IN_LANE` maintains two records in each target lane. An inactive
first slot is reused immediately. A second target is admitted only after the
first reaches X=`$80` moving right or crosses below X=`$20` moving left. The
constructor consumes the cyclic type list at `$0DC8`, assigns color `$04` or
`$08`, converts the type speed to 8.8 motion, and selects the draw direction.
Right-moving targets start at X=`$00`; left-moving targets start at `$8C`, or
`$96` for the PT Boat. Boundary exit erases the bitmap and clears `ACTIVE`.

A torpedo collision sets `HIT_ANIMATION` for the interrupt path and
`HIT_PENDING` for `PROCESS_SHIP_HIT`. The foreground path consumes
`HIT_PENDING` once, adds the type's packed-BCD score, redraws the station score,
draws the temporary value beside the target, and preserves the firing station's
hit streak. Four consecutive ship hits add their accumulated BCD value to the
score a second time, reset the streak, and display `BONUS` plus the awarded
value for `$78` frames.

Target explosion frames advance every six target visits: 12 video frames, or
about 0.2 seconds. Warship A/C use six hit frames; Warship B and both freighters
use five; the PT Boat uses three. The score overlay is erased on animation frame
3. The zero pointer ending each bitmap list clears `ACTIVE` and leaves
`OBJECT_TIMER=$2D`; that timer does not gate target allocation.

The PT Boat follows the same movement, collision, score, and retirement path.
Its constructor additionally starts the ten-ping alternating sonar sequence.

### Mine

Mines are created only when a station completes reload. The larger player's
low packed-BCD score byte controls the active lane count: below `$10` creates an
upper-lane mine, `$10-$19` also creates a middle-lane mine, and `$20+` also
creates a lower-lane mine. These are 1000- and 2000-point thresholds. Each lane
has two slots; one inactive slot is populated per reload and its X position is
staggered from the other slot modulo `$A0`.

A live mine moves right by 0.5 pixel per 10 Hz visit. At X=`$A0` it wraps to
X=`$0000`, integrates once, and remains active. A torpedo hit does not enter
`PROCESS_SHIP_HIT` and awards no score. The mine displays its single hit bitmap
for one mine visit, reaches the zero animation pointer on the next visit, and
clears `ACTIVE`.

### Super Sub diving target

The no-player initialization path seeds one Super Sub template. During normal
play, only a `FREIGHTER_A` sequence entry can be promoted. Promotion requires
game time below `$24` packed BCD and `SUPER_SUB_SPAWN_COUNT < 2`. The
constructor presents `SUPER` / `SUB` while object service is held, starts the
dive effect, and then activates the target.

The Super Sub otherwise uses the surface-target scheduler and 1.0-pixel motion.
Its animation advances from surfaced to dive frame 1 and dive frame 2 every 42
target visits. At 30 Hz this is 84 video frames, about 1.4 seconds per step;
dive frame 2 persists until exit or collision. A hit skips directly to
explosion frame 3, awards 1000 points, and removes the score overlay on frame 5.

This pass promoted the lifecycle support code at `$06B5-$0734`,
`$0B4C-$0BDE`, `$0C6E-$0D47`, and `$15D7-$15E3` from raw bytes to labeled Z80.

## TERSE

Sea Wolf II uses a direct-threaded TERSE engine. Threaded programs contain
little-endian execution addresses and inline operands. Native Z80 routines can
serve as TERSE words when they finish with `JP (IY)`.

### Engine state

| Register/address | Function |
| --- | --- |
| `BC` | Threaded instruction pointer |
| `SP`, initialized to `$C3E2` | Downward-growing data stack |
| `IX`, initialized to `$C400` | Downward-growing return/control stack |
| `IY`, initialized to `$0043` | Address of `TERSE_DISPATCH` |
| `RST $08` | Enter an inline threaded program through `TERSE_ENTER` |

`TERSE_ENTER` saves the caller's current `BC` on the IX stack and uses the Z80
return address following `RST $08` as the new threaded instruction pointer.
`TERSE_DISPATCH` fetches a 16-bit address through `BC` and jumps to it.
`TERSE_RETURN` restores the prior threaded instruction pointer from IX.

### Recovered words

| Address | Source label | Operation |
| ---: | --- | --- |
| `$0039` | `TERSE_RETURN` | Return from the current threaded program |
| `$004A` | `TERSE_INLINE_BFETCH` | Fetch a byte through the following inline address |
| `$0052` | `TERSE_BFETCH` | `( address -- byte )` |
| `$0059` | `TERSE_BSTORE` | `( value address -- )`, storing the low byte |
| `$005E` | `TERSE_BEGIN` | Save the current threaded cell on the IX control stack |
| `$006E` | `TERSE_UNTIL` | `( flag -- )`, repeat at `BEGIN` while zero |
| `$0081` | `TERSE_TRUE` | Push `$FFFF` |
| `$0087` | `TERSE_LIT` | Push the following inline 16-bit value |
| `$0090` | `TERSE_BYTE_NOT` | Complement the low byte of the top stack value |
| `$0097` | `TERSE_ZERO_BRANCH` | `( flag -- )`, branch to the inline address when zero |
| `$00A8` | `TERSE_BRANCH` | Unconditional branch to the inline address |

The initial thread at `$02F0` controls startup and the outer game loop. The
native entry at `$0544` enters the structured control thread at `$0545`, which
coordinates game state, object creation, hit processing, sonar, firing, and
coin handling. The 22-byte stream at `$036F-$0384` is the remaining raw TERSE
program.

## Raster interrupt scheduler

Machine initialization selects one of two schedules through DIP-switch port
`$13`, bit 6. Each schedule contains six 10-byte records:

```text
scanline, reserved, color4, color5, color6, color7,
IM2 handler word for the next record, motion-state word for the next record
```

The scanlines execute in this order. The handler and motion state are selected
by the preceding record:

| Base scanline | Handler | Motion state |
| ---: | --- | ---: |
| `$84` | `ALTERNATE_RASTER_INTERRUPT_HANDLER` | `$C21E` |
| `$D7` | `ALTERNATE_RASTER_INTERRUPT_HANDLER` | none |
| `$0C` | `ALTERNATE_RASTER_INTERRUPT_HANDLER` | none |
| `$18` | `VIDEO_INTERRUPT_HANDLER` | `$C212` |
| `$30` | `ALTERNATE_RASTER_INTERRUPT_HANDLER` | `$C216` |
| `$54` | `ALTERNATE_RASTER_INTERRUPT_HANDLER` | `$C21A` |

The `$0C` record selects `VIDEO_INTERRUPT_HANDLER` for the following `$18`
boundary. That `$18` interrupt runs the complete frame service: sound output,
object-pool updates, timer decay, game-time maintenance, and coin-input
handling. The other five interrupts only advance palette, vector, line, and
split-motion state. After advancing the schedule, the frame handler re-enables
interrupts so the lightweight raster handlers can nest while the frame workload
continues.

`ADVANCE_INTERRUPT_SCHEDULE` writes color registers 5-7, selects the next IM 2
handler through the record's embedded vector word, arms the following scanline,
and preloads its color-4 value into `A'`. Both interrupt entries execute a
90-T-state calibrated delay before writing color register 4.

The two schedules use different palette values:

| Schedule | Color 4 sequence | Constant colors 5/6/7 |
| --- | --- | --- |
| `$19D8` | `$DC,$1C,$D8,$D9,$DA,$DB` | `$77,$58,$00` |
| `$1A16` | `$00,$01,$00,$00,$00,$00` | `$03,$07,$05` |

Each four-byte motion state contains a phase timer, signed velocity, and 8.8
scanline displacement. Initial phase/velocity pairs are `$04/$04`, `$18/$08`,
`$2C/$10`, and `$40/$20` for base lines `$18`, `$30`, `$54`, and `$84`.
Each velocity reverses after `$50` visits. The signed high displacement byte is
added to the next record's base scanline before port `$0F` is rewritten.

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
