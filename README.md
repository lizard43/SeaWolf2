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
- The reset path, native TERSE kernel, initial thread at `$02F0`, nested
  initialization thread at `$036F`, and control thread at `$0544` are
  reconstructed as assembly.
- Power-on diagnostics are reconstructed as native Z80 and documented.
- Character fonts, title and status strings, and the English, German, and
  French prompt tables are identified.
- Machine initialization, credit/start selection, coinage paths, language
  selection, prompt rendering, text rendering, and player-status rendering are
  reconstructed as native Z80.
- Cabinet handle/start/coin inputs, the complete S1 operator-switch matrix,
  service-mode selection, and left/right station ownership are resolved.
- A MAME 0.289 input-port error that prevents French prompt selection is
  identified; the supplied driver patch corrects the French contact address.
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
- Collision geometry, station ownership, packed-BCD scoring, four-hit bonuses,
  hit overlays, explosion timing, extended patrol, final-score/high-score
  selection, and localized high-score indication are fully traced.
- Verified RAM, I/O-port, Magic-RAM scratch, bitmap, and localized prompt
  references use source symbols rather than raw addresses.
- Function Generator control bits, expansion colors, write/read windows,
  scratch expansion, shift flushing, flop-based reversal, OR composition,
  object erasure, and collision display reads are fully traced.
- Every reachable native Z80 routine is expressed as assembly. The remaining
  2,759 `DB` bytes are verified TERSE operands, tables, graphics/text, ROM fill,
  and one uncertain byte at `$1385`.

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

## Cabinet inputs, DIP switches, and station ownership

### CPU port map

The ROM uses physical station names. MAME's historical `P1HANDLE` and
`P2HANDLE` tags are opposite the game's logical player numbers.

| CPU port | MAME tag/device | Verified role |
| ---: | --- | --- |
| `$10` | `P1HANDLE` | Left station / logical player 2: Gray-code position bits 0-5, fire bit 7 |
| `$11` | `P2HANDLE` | Right station / logical player 1: Gray-code position bits 0-5, French-select bit 6, fire bit 7 |
| `$12` | `P3HANDLE` | Coin bit 0, one-player start bit 1, two-player start bit 2, German-select bit 3 |
| `$13` | `P4HANDLE` | Operator switch bank S1 |
| `$42` | `lamplatch1` | Left station torpedo, ready/reload, and hit lamps |
| `$43` | `lamplatch0` | Right station torpedo, ready/reload, and hit lamps |

`DECODE_HANDLE_POSITION` converts the six-bit reflected Gray code to a binary
position. The normal fire path uses the decoded position to select a torpedo
trajectory. The interactive service test displays both decoded positions as
six binary digits; it does not display the fire bits.

### Operator switch bank S1

The manual and ROM agree on the complete post-500-game S1 assignment. Values
below are the bytes read by the CPU at port `$13`.

| Switches | Port mask | Function |
| --- | ---: | --- |
| S1-1/S1-2 | `$09` | One- and two-player pricing |
| S1-3/S1-4 | `$06` | Initial play time and extended-play time |
| S1-5/S1-6 | `$30` | Extended-play score threshold |
| S1-7 | `$40` | Color when ON; monochrome when OFF |
| S1-8 | `$80` | Normal play when ON; service test when OFF |

Pricing is implemented by one combined four-way branch:

| S1-1 | S1-2 | Port value | One-player cost | Two-player cost |
| --- | --- | ---: | ---: | ---: |
| ON | ON | `$09` | 1 | 2 |
| OFF | ON | `$01` | 1 | 1 |
| OFF | OFF | `$00` | 2 | 2 |
| ON | OFF | `$08` | 2 | 4 |

The `$08` path intentionally disables both start buttons at three credits and
asks for one more credit for a two-player game. Accepted starts subtract the
selected cost and return to the outer TERSE game loop.

| S1-3 | S1-4 | Port value | One player | Two players | Extended 1P/2P |
| --- | --- | ---: | ---: | ---: | ---: |
| OFF | OFF | `$00` | 70 s | 90 s | 35 s / 45 s |
| ON | OFF | `$02` | 60 s | 75 s | 30 s / 35 s |
| OFF | ON | `$04` | 50 s | 60 s | 25 s / 30 s |
| ON | ON | `$06` | 40 s | 45 s | 20 s / 20 s |

| S1-5 | S1-6 | Port value | Extended play |
| --- | --- | ---: | --- |
| OFF | OFF | `$00` | Disabled |
| ON | OFF | `$10` | 5000 points |
| OFF | ON | `$20` | 6000 points |
| ON | ON | `$30` | 7000 points |

With S1-8 in service position, reset selects the diagnostic from the two start
inputs: no button runs ROM checksum and memory tests, one-player start skips
the ROM checksum, two-player start opens the two-handle input display, and both
buttons open the convergence grid.

### Language switch and MAME correction

The post-500-game language switch supplies two active-high contacts. The ROM
reads German from port `$12` bit 3 and French from port `$11` bit 6. No contact
selects English. French has priority if both contacts are asserted. The result
selects one of the English, German, or French prompt-pointer groups.

MAME 0.289 defines the German contact correctly but places the French contact
on port `$10` bit 6. The ROM never reads that bit, so MAME's French setting
displays English prompts. The supplied MAME driver patch moves only that
contact to port `$11` bit 6; no ROM change is required.

### Station ownership

| Physical station | Logical player | Active modes | Input | Lamps | Torpedo records | Color | Hit-side bit |
| --- | ---: | --- | ---: | ---: | --- | ---: | ---: |
| Left | 2 | Two-player only | `$10` | `$42` | `$C0FA`, then every `$32` (even low address) | `$08` red | 1 |
| Right | 1 | One- and two-player | `$11` | `$43` | `$C113`, then every `$32` (odd low address) | `$04` yellow | 0 |

The torpedo collision resolver derives ownership from record-address parity
and stores it in target flag bit 3. Scoring, consecutive-hit bonuses, hit-score
cleanup, ship/mine sound selection, and lamp restoration all consume that
single ownership bit. One-player setup suppresses the left score panel and
does not poll the left fire input.

### Foreground initialization

`CLEAR_RAM_AND_LOWER_VIDEO` clears all work RAM at `$C000-$C3FF` and video RAM
at `$77F0-$7FAF`. `INITIALIZE_MACHINE` then:

1. Enables IM 2 interrupts.
2. Copies the 16-byte moving-raster template to `$C212-$C221`.
3. Selects raster schedule `$19D8` or `$1A16` from DIP port `$13` bit 6.
4. Primes the first raster interrupt record and color split `$2A`.
5. Initializes the target-type sequence cursor to `$0DC8`.

The frame interrupt debounces coin input on port `$12` bit 0. A rising edge
increments `COIN_INPUT_QUEUE`. `PULSE_COIN_COUNTER` consumes one queued event,
drives a ten-frame mechanical-counter pulse, and increments `CREDIT_COUNT`.
Start inputs are port `$12` bit 1 for one player and bit 2 for two players.

## Function Generator and Magic RAM

### Addressing and control

Sea Wolf II uses the Astrocade Function Generator as a write path into display
RAM. The CPU address and access direction determine the hardware path:

| CPU access | Result |
| --- | --- |
| Read `$0000-$1FFF` | Program ROM |
| Write `$0000-$3FFF` | Function Generator input; output is written at `$4000 + address` |
| Read/write `$4000-$7FFF` | Direct display RAM access |

Port `$0C` controls the Function Generator. The pipeline order is expand,
shift or rotate, flop, OR/XOR, then display-RAM write.

| Bits | Mask | Function |
| ---: | ---: | --- |
| 0-1 | `$03` | Shift by 0-3 two-bit pixels |
| 2 | `$04` | Rotate: buffer four input bytes, then emit four transposed bytes |
| 3 | `$08` | Expand one-bit source data to two-bit pixels |
| 4 | `$10` | OR generated data with the addressed display byte |
| 5 | `$20` | XOR generated data with the addressed display byte |
| 6 | `$40` | Flop the four two-bit pixels within the generated byte |
| 7 | `$80` | Unused |

Writing port `$0C` resets the expansion phase, shift pipeline, and rotate
counter. Expand mode consumes the high source nibble on the first write and the
low nibble on the second. Port `$19` supplies the two output colors: bits 0-1
select the color for a zero source bit and bits 2-3 select the color for a one.
Sea Wolf II uses `$04`, `$08`, and `$0C`, mapping zero to color 0 and one to
color 1, 2, or 3.

| Control | Verified use |
| ---: | --- |
| `$00` | Direct replacement during object erasure |
| `$08-$0B` | Expand with shift 0-3 for text, status graphics, objects, mines, and torpedoes |
| `$18` | Expand plus OR for the second double-size text stage |
| `$48-$4B` | Expand plus flop with shift 0-3 for left-moving targets |

The ROM never enables rotate or XOR. OR/XOR operations update intercept
feedback readable at port `$08`; Sea Wolf II never reads that feedback.

### Text and status graphics

`DRAW_TEXT` consumes zero-terminated character strings. Character code `$30`
is font index zero; every glyph is ten one-bit source bytes. Normal text uses
control `$08`. Writing each source byte twice expands its high and low nibbles
into two display bytes, producing eight two-bit pixels. Rows advance by `$50`,
text X advances by `$04`, and a two-byte blank row is emitted above and below
the glyph.

Double-size text uses two Function Generator passes. The first maps 0/1 to
colors 0/3 and writes the font byte through `$3FFE/$3FFF`; the generated bytes
are read from display RAM at `$7FFE/$7FFF`. The second pass re-expands each
scratch byte with the requested text colors using `$18`, so the result is ORed
with existing display pixels. Four destination bytes are produced per source
row. Row stride is `$A0`; X advances by `$08`.

`DRAW_PLAYER_STATUS` draws five rows of three source bytes at X=`$07` and
X=`$82`; the left panel is omitted in one-player mode. A fixed center panel is
drawn at X=`$4D`. `DRAW_SMALL_BITMAP` uses `$08` and two writes per source byte,
producing six display bytes per row.

### Objects, torpedoes, erasure, and collision reads

Each object record stores a Function Generator control byte, a saved Magic
write-window address, and a packed port-`$19` color pair. Constructors use
`$08` for forward drawing. Left-moving targets set flop, producing base control
`$48`. `MAP_COORDINATES_TO_MAGIC_ADDRESS` replaces bits 0-1 with the current
horizontal shift and returns `row*80 + x/2` in the `$0000-$3FFF` write window.

Forward object rows write each one-bit source byte twice, expanding its high
and low nibbles. A destination zero write flushes shifted trailing pixels; a
zero write at `$3FFF` consumes the other expansion phase and clears the shift
latch before the next row. Reverse rows start at the expanded right edge, walk
addresses backward, flop each generated byte, and complement shift bits 0-1
with XOR `$03`. Together these operations mirror the complete bitmap.

Torpedo frames use `$08-$0B` and one source byte per video row. Each byte is
written twice for high-/low-nibble expansion; torpedoes never use flop, OR,
XOR, or rotate.

`ERASE_OBJECT_BITMAP` programs `$00` and writes direct zero bytes through the
Magic window. It clears `2 * (source width + 1)` bytes per row, covering the
expanded bitmap and shift spill. The saved object address is the Function
Generator write address, not a display-RAM read address.

The torpedo collision probe converts that saved write address into display-RAM
reads by adding `$3F60`, `$3F61`, `$3FB0`, `$3FB1`, `$40A0`, `$40F0`, and
`$4140`. These are pixel-presence tests against readable display RAM; they do
not pass through the Function Generator.

## Remaining raw data

No reachable native Z80 remains encoded as `DB`.

| Classification | Regions | Bytes |
| --- | ---: | ---: |
| TERSE inline operands | 5 | 15 |
| Lookup, property, and pointer tables | 9 | 350 |
| Graphics, text, and diagnostic patterns | 9 | 2,317 |
| Padding and unused ROM | 1 | 76 |
| Uncertain mixed role | 1 | 1 |
| **Total** | **25** | **2,759** |

The uncertain byte is `$8E` at `$1385`. It is not referenced as data and is
not reachable from adjacent native code.

The remaining `DB` regions are intentional data encodings. Named RAM cells,
hardware ports, bitmap addresses, and prompt-string pointers are symbolic at
their use sites.

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
`$0D88`, which supplies initial X and signed X velocity. Left torpedoes use
port-`$19` pair `$08` (set pixels color 2); right torpedoes use `$04` (color 1).
Activation starts the left or right torpedo sound for `$38` video frames.

`UPDATE_TORPEDO_OBJECT` runs at 30 Hz. It integrates the 8.8 coordinates,
selects near/middle/far frames at Y=`$78/$46/$00`, and probes seven display-RAM
bytes derived from the preceding Magic write address. Y selects one of five
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
the torpedo color to the target, and loads the `shiphit` timer with `$40`. A mine
collision deactivates the torpedo, marks the mine for hit animation, clears the
station's consecutive-ship-hit streak, and loads `minehit` with `$08`.
A boundary miss also clears the streak before the torpedo is erased and made
inactive.

### Surface target

`ACTIVATE_TARGET_IN_LANE` maintains two records in each target lane. An inactive
first slot is reused immediately. A second target is admitted only after the
first reaches X=`$80` moving right or crosses below X=`$20` moving left. The
constructor consumes the cyclic type list at `$0DC8`, assigns port-`$19` pair
`$04` or `$08` (set pixels color 1 or 2), converts the type speed to 8.8
motion, and selects the draw direction.
Right-moving targets start at X=`$00`; left-moving targets start at `$8C`, or
`$96` for the PT Boat. Boundary exit erases the bitmap and clears `ACTIVE`.

A torpedo collision sets `HIT_ANIMATION` for the interrupt path and
`HIT_PENDING` for `PROCESS_SHIP_HIT`. The foreground path consumes
`HIT_PENDING` once, adds the type's packed-BCD score, redraws the station score,
draws the temporary value beside the target, and preserves the firing station's
hit streak. Four consecutive ship hits add their accumulated BCD value to the
score a second time, reset the streak, and display `BONUS` plus the awarded
value for `$78` frames.

Target explosion frames advance on the seventh target visit after loading
`OBJECT_TIMER=$06`: 14 video frames, about 0.233 seconds. Warship A/C use six
hit frames; Warship B and both freighters use five; the PT Boat uses three. The
score overlay is erased when ordinary targets reach animation frame 3. The zero
pointer ending each bitmap list clears `ACTIVE` and leaves `OBJECT_TIMER=$2D`;
that timer does not gate target allocation.

The PT Boat follows the same movement, collision, score, and retirement path.
Its constructor additionally asserts one left sonar pulse and starts ten
scheduled sonar pulses.

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

The lifecycle and collision/scoring passes promoted `$0593-$07FB`,
`$0B4C-$0C55`, `$0C6E-$0D47`, and `$15D7-$15E3` where those ranges are native
code. Inline TERSE operands inside the promoted regions remain explicit data.

## Collision, scoring, explosions, and patrol completion

### Collision resolver

`UPDATE_TORPEDO_OBJECT` first performs a cheap display-RAM probe relative to
the torpedo's saved Magic write address. It reads offsets `$3F60`, `$3F61`,
`$3FB0`, `$3FB1`, `$40A0`, `$40F0`, and `$4140`. Any nonzero bit in the first
four bytes passes the probe; the last three contribute only color bits 6-7.

The probe gates the exact record test:

| Test | Verified condition |
| --- | --- |
| Vertical band | Torpedo Y selects one of the five two-record lane pools; no second Y test is made |
| Active state | Candidate flag bit 7 is set |
| Horizontal span | `delta = torpedo_x + 4 - candidate_x`; accept `0 <= delta < 4 * (bitmap_width + 1)` |
| Hit state | Candidate flag bit 6 is clear |

On acceptance, the resolver clears the candidate timer, sets hit-animation bit
6 and foreground-event bit 5, and deactivates the torpedo. Even low bytes of the
interleaved torpedo record addresses belong to the left station; odd low bytes
belong to the right. Candidate flag bit 3 preserves that ownership for scoring,
lamp restoration, and sound selection.

### Scoring and overlays

Station scores are two-byte packed BCD values in 100-point units. Target type
IDs are ordered so `PROCESS_SHIP_HIT` can select the increment with three
comparisons:

| Target class | Stored increment | Displayed points |
| --- | ---: | ---: |
| Warship A/B/C | `$03` | 300 |
| Freighter A/B | `$01` | 100 |
| PT Boat | `$05` | 500 |
| Super Sub | `$10` | 1000 |

Foreground event bit 5 is consumed once. The routine adds the increment with
`DAA`, clears the station's active-low score-redraw latch, asserts lamp bit 5,
increments the consecutive-hit count, and adds the same value to the streak
accumulator. A miss or mine collision clears both streak bytes.

On the fourth consecutive ship hit, the complete streak value is added to the
score a second time. The count and accumulator reset, and `BONUS` plus the BCD
award remain active for `$78` video frames, exactly two seconds at 60 Hz.

Each ship hit also draws its value beside the target. Ordinary overlays are
erased at animation frame 3; the Super Sub overlay is erased at frame 5. That
same cleanup restores the saved ready/reload lamp state for the owning station.

### Explosion state

| Object | Hit sequence | Advance cadence | Retirement |
| --- | --- | --- | --- |
| Warship A/C | 6 hit frames | Every 7 target visits = 14 video frames | Zero pointer clears `ACTIVE` |
| Warship B, Freighter A/B | 5 hit frames | Every 7 target visits = 14 video frames | Zero pointer clears `ACTIVE` |
| PT Boat | 3 hit frames | Every 7 target visits = 14 video frames | Zero pointer clears `ACTIVE` |
| Super Sub | Frames 3-5 | Every 7 target visits = 14 video frames | Zero pointer clears `ACTIVE` |
| Mine | 1 hit frame | Consecutive 10 Hz mine visits | Next visit reaches the zero pointer |

`DECAY_OBJECT_TIMER` returns the timer value observed before decrementing it.
The `$06` load therefore reaches zero on six visits and advances on the seventh.
Explosion drawing and score cleanup do not retrigger the collision sound.

### Sound-event timing

The frame interrupt writes ports `$40/$41` before object service, then decays
all timers. This ordering changes collision-event duration by one output write:

| Event | Producer load | Result |
| --- | ---: | --- |
| Left/right torpedo | `$38` | 56 asserted port writes |
| Left/right ship hit | `$40` | 63 asserted port writes |
| Left/right mine hit | `$08` | 7 asserted port writes |
| Initial PT Boat sonar | `$05` | 5 asserted port writes |
| Scheduled sonar pulse | `$04` | 4 asserted port writes |
| Super Sub dive field | `$F0` | 240 frame updates of trigger/pan state |

Torpedo, sonar, and dive producers run in the foreground between interrupts and
retain their full loads. Ship/mine timers are created during interrupt-driven
torpedo service, after the current output write, and are immediately decremented.
The PT Boat emits one immediate left pulse and seeds ten scheduled pulses. Dive
timer bits 7-5 become the three-bit pan field; timer bit 5 also drives trigger
bit 3, and `$C1FA` selects the sweep orientation. Scoring, four-hit bonuses,
explosion frames, and object retirement have no separate sound producer.

### Patrol completion and high score

`GAME_TIME_BCD` decrements once per 60 video frames. At zero,
`PATROL_COMPLETE_FLAG` stops new target and torpedo creation. Unless an
extension clears the flag, the foreground continues collision, scoring,
explosion, sound, and score-redraw service until all eight torpedoes are
inactive.

An extended patrol can be awarded once. DIP bits 4-5 select no extension or a
5000/6000/7000-point threshold; either station can qualify. DIP bits 1-2 select
the packed-BCD extension time:

| DIP mask | One player | Two players |
| ---: | ---: | ---: |
| `$00` | 35 seconds | 45 seconds |
| `$02` | 30 seconds | 35 seconds |
| `$04` | 25 seconds | 30 seconds |
| `$06` | 20 seconds | 20 seconds |

The awarded duration is stored in `EXTENDED_PATROL_TIME_BCD`, preventing a
second extension, and the Super Sub spawn counter resets for the new patrol.
If no extension is awarded, both lamp ports and magazines are cleared; control
returns to the outer game loop only after the active-torpedo drain completes.

At game over, the larger station score becomes the high-score candidate; a tie
selects the left station. The stored high score changes only when the candidate
is strictly greater. A new record sets `NEW_HIGH_SCORE_FLAG`, and the localized
congratulations message toggles draw/erase color every `$1E` video frames.

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
coin handling. The nested initialization thread at `$036F-$0384` is expressed
as named execution cells. Its six Y/X/size operand bytes remain explicit data.

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
- `START_SONAR_SEQUENCE` asserts the initial left pulse and seeds ten scheduled
  pulses; `UPDATE_SONAR_SEQUENCE` generates the subsequent side sequence.
- `START_DIVE_SOUND` loads the `$F0` countdown and the orientation XOR used for
  the trigger and three-bit pan field.
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
4. Verify every generated ROM against its official SHA1 value and fail on any
   mismatch.

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
