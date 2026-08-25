;===============================================================================
; Sea Wolf II (Dave Nutting Associates / Midway, 1978)
;
; ROM address space: $0000-$1FFF
; TERSE IP: BC      data stack: SP      return stack: IX
; Dispatcher: IY=$0043
;
;===============================================================================

;===============================================================================
; Remaining raw-region inventory
;
; Every byte still emitted with DB is classified below.  The inventory covers
; 2,759 bytes in 25 classified address regions; no DB byte is omitted.  All
; reachable native Z80 is expressed as instructions.  Remaining DB bytes are
; TERSE inline operands, tables, graphics/text, padding, or explicitly unknown.
;
; TERSE INLINE OPERANDS                          5 spans / 15 bytes
;   $0375-$0377  HIGH SCORE text Y/X/size operands
;   $037E-$0380  title text Y/X/size operands
;   $05F6-$05F8  English GAME OVER position/renderer operands
;   $0604-$0606  German GAME OVER position/renderer operands
;   $060E-$0610  French GAME OVER position/renderer operands
;   All TERSE execution cells are expressed as labeled DW words.
;
; LOOKUP / PROPERTY / POINTER TABLES             9 spans / 350 DB bytes
;   $0184-$0185  video-RAM diagnostic range parameters
;   $0199-$019A  work-RAM diagnostic range parameters
;   $0355-$0364  initial RAM template copied to $C212
;   $0D48-$0DC7  two 64-byte player-torpedo trajectory tables
;   $0DC8-$0DD1  moving-target type sequence
;   $0DD2-$0DDA  target horizontal-speed table
;   $0DDB-$0E3E  four complete 25-byte object templates
;   $19D8-$1A52  decoded raster-schedule scalar fields; pointers use DW
;   $1A53-$1AE6  pointers use DW; collision/frame thresholds retain 8 DB bytes
;
; GRAPHICS, TEXT OR DIAGNOSTIC PATTERN DATA       9 spans / 2,317 bytes
;   $00B0-$00E7  self-test color/pixel patterns
;   $0E3F-$119E  object and animation bitmaps
;   $119F-$134C  character font
;   $134D-$136F  player-status graphics
;   $1370-$1384  title and Super Sub labels
;   $1AE7-$1B58  short game-state messages
;   $1BC3-$1C72  English prompt text
;   $1CDD-$1E91  German prompt text
;   $1EFC-$1FB3  French prompt text
;
; PADDING OR UNUSED ROM                          1 span / 76 bytes
;   $1FB4-$1FFF  erased-ROM fill; $1FFF is the block checksum adjustment
;
; GENUINELY UNCERTAIN                            1 span / 1 byte
;   $1385        unreferenced $8E between TEXT_SUB and the $1386 ISR entry
;
; Inventory invariant: remaining DB byte count = 2,759.
;===============================================================================

PORT_COLOR_0            EQU     $00
PORT_COLOR_1            EQU     $01
PORT_COLOR_2            EQU     $02
PORT_COLOR_3            EQU     $03
PORT_COLOR_4            EQU     $04
PORT_COLOR_5            EQU     $05
PORT_COLOR_6            EQU     $06
PORT_COLOR_7            EQU     $07
PORT_VIDEO_MODE         EQU     $08 ; write; reads return/clear FG intercept
PORT_COLOR_SPLIT        EQU     $09
PORT_VBLANK_LINE        EQU     $0A
PORT_COLOR_BLOCK        EQU     $0B
PORT_FUNCGEN_CONTROL    EQU     $0C
PORT_INTERRUPT_VECTOR   EQU     $0D
PORT_INTERRUPT_ENABLE   EQU     $0E
PORT_INTERRUPT_LINE     EQU     $0F
PORT_EXPAND_COLOR       EQU     $19
PORT_LEFT_STATION_HANDLE  EQU   $10
PORT_RIGHT_STATION_HANDLE EQU   $11
PORT_COIN_START         EQU     $12
PORT_DIP_SWITCHES       EQU     $13
PORT_SOUND_EVENTS       EQU     $40
PORT_SOUND_CONTROL      EQU     $41
PORT_LEFT_LAMPS         EQU     $42
PORT_RIGHT_LAMPS        EQU     $43

; Cabinet/station ABI.  Logical player 1 occupies the right station and is the
; only station active in a one-player game.  Logical player 2 occupies the left
; station and is enabled only in a two-player game.
;
;              handle   lamps   torpedo records   color   hit-side flag
; left / P2     $10      $42     even: $C0FA...    $08     bit 3 = 1
; right / P1    $11      $43     odd:  $C113...    $04     bit 3 = 0
;
; Both handle ports contain a six-bit Gray-coded position and an active-high
; fire input.  Torpedo-record address parity becomes target flag bit 3 on a
; hit; scoring, hit lamps, bonus state, and collision sound consume that bit.
RAW_HANDLE_POSITION_MASK        EQU $3F
DECODED_HANDLE_POSITION_MASK    EQU $7F
HANDLE_FIRE_MASK                EQU $80
STATION_PORT_PARITY_BIT         EQU $00 ; port $10 left, port $11 right

COIN_INPUT_MASK                 EQU $01 ; port $12 bit 0
INPUT_ONE_PLAYER_START_BIT      EQU $01 ; port $12 bit 1
INPUT_TWO_PLAYER_START_BIT      EQU $02 ; port $12 bit 2
INPUT_ONE_PLAYER_START_MASK     EQU $02
INPUT_TWO_PLAYER_START_MASK     EQU $04
INPUT_START_BUTTON_MASK         EQU $06
LANGUAGE_GERMAN_SWITCH_MASK     EQU $08 ; port $12 bit 3
LANGUAGE_FRENCH_SWITCH_MASK     EQU $40 ; port $11 bit 6

PLAYER_COUNT_ONE                EQU $01
PLAYER_COUNT_TWO                EQU $02

RAM_BASE                EQU     $C000
TERSE_DATA_STACK        EQU     $C3E2
TERSE_RETURN_STACK      EQU     $C400

VIDEO_RAM_BASE          EQU     $4000
VIDEO_RAM_LIMIT         EQU     $8000
WORK_RAM_LIMIT          EQU     $C400

; Native text renderer state used by the power-on and interactive diagnostics.
TEXT_X_POSITION_LO      EQU     $C1FE
TEXT_X_POSITION_HI      EQU     $C1FF
TEXT_Y_POSITION_LO      EQU     $C200
TEXT_Y_POSITION         EQU     $C201
TEXT_COLOR              EQU     $C202
TEXT_DOUBLE_SIZE_FLAG   EQU     $C1DD

; Foreground input, credit and prompt state.
START_ELIGIBILITY_FLAGS EQU     $C203
START_CREDIT_COST       EQU     $C204
LANGUAGE_SELECTION      EQU     $C205
CREDIT_COUNT            EQU     $C206
COIN_INPUT_QUEUE        EQU     $C207
COIN_INPUT_EDGE_LATCH   EQU     $C1F9
UNREFERENCED_RUNTIME_BYTE EQU   $C20A
TARGET_TYPE_SEQUENCE_CURSOR EQU $C20B

START_FLAG_ONE_PLAYER   EQU     $02
START_FLAG_TWO_PLAYER   EQU     $04
START_FLAG_ONE_PLAYER_BIT EQU   $01
START_FLAG_TWO_PLAYER_BIT EQU   $02

; Operator switch bank S1 at port $13.  The manual numbers the two pricing
; contacts S1-1 and S1-2 even though their bits appear in reverse order here.
DIP_COINAGE_MASK                EQU $01 ; S1-2
DIP_PLAY_TIME_MASK              EQU $06 ; S1-3/S1-4
DIP_TWO_PLAYER_PRICE_MASK       EQU $08 ; S1-1
DIP_PRICING_MASK                EQU $09 ; S1-1/S1-2 together
DIP_EXTENDED_PLAY_MASK          EQU $30 ; S1-5/S1-6
DIP_MONITOR_TYPE_MASK           EQU $40 ; S1-7: 0 B/W, 1 color
DIP_SERVICE_MODE_MASK           EQU $80 ; S1-8: 0 test, 1 play

PRICING_1P_2C_2P_2C            EQU $00 ; S1-1 OFF, S1-2 OFF
PRICING_1P_1C_2P_1C            EQU $01 ; S1-1 OFF, S1-2 ON
PRICING_1P_2C_2P_4C            EQU $08 ; S1-1 ON,  S1-2 OFF
PRICING_1P_1C_2P_2C            EQU $09 ; S1-1 ON,  S1-2 ON

DIP_PLAY_TIME_1P70_2P90        EQU $00
DIP_PLAY_TIME_1P60_2P75        EQU $02
DIP_PLAY_TIME_1P50_2P60        EQU $04
DIP_PLAY_TIME_1P40_2P45        EQU $06

DIP_EXTENDED_PLAY_NONE         EQU $00
DIP_EXTENDED_PLAY_5000         EQU $10
DIP_EXTENDED_PLAY_6000         EQU $20
DIP_EXTENDED_PLAY_7000         EQU $30

DIP_MONITOR_BLACK_AND_WHITE    EQU $00
DIP_MONITOR_COLOR              EQU $40
DIP_SERVICE_MODE_TEST          EQU $00
DIP_SERVICE_MODE_PLAY          EQU $80

LANGUAGE_ENGLISH        EQU     $00
LANGUAGE_GERMAN         EQU     $01
LANGUAGE_FRENCH         EQU     $02

INITIAL_INTERRUPT_ENABLE EQU   $08
INITIAL_COLOR_SPLIT_VALUE EQU  $2A

PROMPT_TEXT_COLOR       EQU     EXPAND_COLORS_0_3
PROMPT_TEXT_X           EQU     $28
PROMPT_INITIAL_Y        EQU     $3E
PROMPT_LINE_Y_STEP      EQU     $0C
PROMPT_TEXT_X_WORD      EQU     $2800
PROMPT_INITIAL_Y_WORD   EQU     $3E00
PROMPT_LINE_Y_STEP_WORD EQU     $0C00
GERMAN_PROMPT_TABLE_OFFSET EQU  $011A
FRENCH_PROMPT_TABLE_OFFSET  EQU  $0339

FONT_ASCII_BASE         EQU     $30
FONT_ASCII_LAST         EQU     $5A
FONT_BYTES_PER_GLYPH    EQU     $0A
FONT_GLYPH_COUNT        EQU     $2B
VIDEO_ROW_STRIDE        EQU     $0050
TEXT_DOUBLE_ROW_STRIDE  EQU     $00A0
TEXT_NORMAL_X_ADVANCE   EQU     $0400
TEXT_DOUBLE_X_ADVANCE   EQU     $0800

; Function Generator control register at port $0C.  The hardware pipeline is
; expand -> shift/rotate -> flop -> OR/XOR -> display RAM.  Bits 0-1 select a
; shift of 0-3 two-bit pixels.  Expand alternates high and low source nibbles;
; rotate buffers the first four writes and emits four transposed bytes on the
; next four; flop reverses the four two-bit pixels in one byte.  OR/XOR combine
; with the addressed display byte and update intercept feedback readable at
; port $08.  Writing port $0C resets the shift latch, expansion phase and rotate
; counter.  Bit 7 has no hardware function.
FUNCGEN_SHIFT_MASK          EQU $03
FUNCGEN_ROTATE_BIT          EQU $02
FUNCGEN_EXPAND_BIT          EQU $03
FUNCGEN_OR_BIT              EQU $04
FUNCGEN_XOR_BIT             EQU $05
FUNCGEN_FLOP_BIT            EQU $06
FUNCGEN_ROTATE_MASK         EQU $04
FUNCGEN_EXPAND_MASK         EQU $08
FUNCGEN_OR_MASK             EQU $10
FUNCGEN_XOR_MASK            EQU $20
FUNCGEN_FLOP_MASK           EQU $40

FUNCGEN_MODE_REPLACE        EQU $00
FUNCGEN_MODE_EXPAND         EQU $08
FUNCGEN_MODE_EXPAND_OR      EQU $18
FUNCGEN_MODE_EXPAND_FLOP    EQU $48

; Observed controls are $00, $08-$0B, $18 and $48-$4B.  The low two bits of
; object modes vary with horizontal position.  OR appears only in double-size
; text.  This ROM never asserts rotate or XOR.

; Port $19 packs the output color for a zero source bit in bits 0-1 and the
; output color for a one source bit in bits 2-3.  Sea Wolf II always maps zero
; to color 0 and selects color 1, 2 or 3 for set pixels.
EXPAND_COLORS_0_1           EQU $04
EXPAND_COLORS_0_2           EQU $08
EXPAND_COLORS_0_3           EQU $0C

; CPU writes to $0000-$3FFF pass through the Function Generator and land at
; display RAM $4000-$7FFF.  The last two bytes form a safe expansion/shift
; scratch pair: write through $3FFE/$3FFF, then read the result at $7FFE/$7FFF.
MAGIC_WRITE_WINDOW_BASE     EQU $0000
MAGIC_WRITE_WINDOW_LIMIT    EQU $4000
FUNCGEN_SCRATCH_WRITE_0     EQU $3FFE
FUNCGEN_SCRATCH_WRITE_1     EQU $3FFF
FUNCGEN_SCRATCH_READ_0      EQU $7FFE
FUNCGEN_SCRATCH_READ_1      EQU $7FFF

PLAYER_STATUS_COLOR     EQU     EXPAND_COLORS_0_3
PLAYER_STATUS_Y         EQU     $B8
PLAYER_STATUS_LEFT_X    EQU     $07
PLAYER_STATUS_RIGHT_X   EQU     $82
PLAYER_STATUS_CENTER_X  EQU     $4D
PLAYER_STATUS_LEFT_X_WORD   EQU $0700
PLAYER_STATUS_RIGHT_X_WORD  EQU $8200
PLAYER_STATUS_CENTER_X_WORD EQU $4D00
PLAYER_STATUS_ROWS      EQU     $05
PLAYER_STATUS_SOURCE_WIDTH EQU  $03

SELF_TEST_TEXT_BUFFER   EQU     $C000
SELF_TEST_ROM_BLOCK_SIZE EQU    $0800
SELF_TEST_PALETTE_BYTES EQU     $08
SELF_TEST_FAILURE_PATTERN_BYTES EQU $0028

GAME_CLOCK_DIVIDER          EQU $C1DA
GAME_TIME_BCD               EQU $C1DB
LAST_DRAWN_GAME_TIME_BCD    EQU $C1DC
CONTROL_LOOP_EXIT_FLAG      EQU $C1DE
PATROL_COMPLETE_FLAG        EQU $C1DF
EXTENDED_PATROL_TIME_BCD    EQU $C1E0
ACTIVE_PLAYER_COUNT         EQU $C1FB

; Player score and torpedo-result state.  Each score is two packed-BCD bytes.
; A ship hit clears the active-low redraw latch and advances the station's
; consecutive-hit count/value.  A torpedo miss or mine collision clears that
; streak; reaching four ship hits awards the accumulated value a second time.
LEFT_SCORE_BCD_LO               EQU $C1E2
LEFT_SCORE_BCD_HI               EQU $C1E3
LEFT_SCORE_REDRAW_LATCH         EQU $C1E4
LEFT_HIT_STREAK_COUNT           EQU $C1E5
LEFT_HIT_STREAK_VALUE_BCD       EQU $C1E6
RIGHT_SCORE_BCD_LO              EQU $C1E7
RIGHT_SCORE_BCD_HI              EQU $C1E8
RIGHT_SCORE_REDRAW_LATCH        EQU $C1E9
RIGHT_HIT_STREAK_COUNT          EQU $C1EA
RIGHT_HIT_STREAK_VALUE_BCD      EQU $C1EB

LEFT_FIRE_EDGE_LATCH            EQU $C1EC
LEFT_TORPEDOES_REMAINING        EQU $C1ED
LEFT_LAMP_STATE                 EQU $C1EE
RIGHT_FIRE_EDGE_LATCH           EQU $C1EF
RIGHT_TORPEDOES_REMAINING       EQU $C1F0
RIGHT_LAMP_STATE                EQU $C1F1
RIGHT_BONUS_DISPLAY_ACTIVE      EQU $C1F2
RIGHT_BONUS_DISPLAY_VALUE_BCD   EQU $C1F3
LEFT_BONUS_DISPLAY_ACTIVE       EQU $C1F4
LEFT_BONUS_DISPLAY_VALUE_BCD    EQU $C1F5
SUPER_SUB_SPAWN_COUNT           EQU $C1F7
NEW_HIGH_SCORE_FLAG             EQU $C1F8

HIGH_SCORE_BCD_LO               EQU $C208
HIGH_SCORE_BCD_HI               EQU $C209

; SELF_TEST_PARAMETER_SET_* layout.  The first two bytes form an executable
; JR instruction.  A successful range test jumps through IY and executes that
; JR, selecting the next diagnostic phase without a separate return address.
SELF_TEST_RANGE_LOWER_PAGE EQU  $02
SELF_TEST_RANGE_UPPER_PAGE EQU  $03
SELF_TEST_RANGE_START_LO   EQU  $04
SELF_TEST_RANGE_START_HI   EQU  $05

; Object/entity record ABI.  All three scheduler pools use this exact $19-byte
; layout.  Vertical motion is accelerated fixed-point; horizontal motion uses
; a constant fixed-point velocity.  In each little-endian pair the low byte is
; fractional and the high byte is the screen coordinate used by rendering and
; collision code.
OBJECT_RECORD_SIZE          EQU $19
OBJECT_FLAGS                EQU $00
OBJECT_TYPE                 EQU $01
OBJECT_TIMER                EQU $02
OBJECT_Y_ACCEL_LO           EQU $03
OBJECT_Y_ACCEL_HI           EQU $04
OBJECT_Y_VELOCITY_LO        EQU $05
OBJECT_Y_VELOCITY_HI        EQU $06
OBJECT_Y_POSITION_LO        EQU $07
OBJECT_Y_POSITION_HI        EQU $08
OBJECT_Y_MIN                EQU $09
OBJECT_RESERVED_0A          EQU $0A
OBJECT_RESERVED_0B          EQU $0B
OBJECT_X_VELOCITY_LO        EQU $0C
OBJECT_X_VELOCITY_HI        EQU $0D
OBJECT_X_POSITION_LO        EQU $0E
OBJECT_X_POSITION_HI        EQU $0F
OBJECT_RESERVED_10          EQU $10
OBJECT_X_MAX                EQU $11
OBJECT_BITMAP_PTR_LO        EQU $12
OBJECT_BITMAP_PTR_HI        EQU $13
OBJECT_FUNCGEN_CONTROL      EQU $14
OBJECT_MAGIC_ADDR_LO        EQU $15 ; Function Generator write-window address
OBJECT_MAGIC_ADDR_HI        EQU $16
OBJECT_COLOR                EQU $17
OBJECT_ANIMATION_FRAME      EQU $18

; $0A, $0B and $10 are touched only by whole-record clear/copy operations.
; No constructor, updater, renderer or collision path reads or writes them as
; fields, so they remain explicitly reserved rather than receiving speculative
; meanings.
;
; OBJECT_FUNCGEN_CONTROL holds the port-$0C mode.  Constructors seed expand
; and optional flop; MAP_COORDINATES_TO_MAGIC_ADDRESS replaces bits 0-1 with
; the current pixel shift.  OBJECT_MAGIC_ADDR is the saved CPU write-window
; address in $0000-$3FFF, not the display-RAM read address.  OBJECT_COLOR is the
; packed port-$19 expansion pair used whenever the object is drawn.

BITMAP_SOURCE_WIDTH         EQU $00
BITMAP_ROW_COUNT            EQU $01
BITMAP_SOURCE_PIXELS_PER_BYTE EQU $08
BITMAP_LOGICAL_X_UNITS_PER_BYTE EQU $04

; OBJECT_FLAGS bits.  Bits 0-1 are unused by every object path in this ROM.
; Collision state is deliberately split: bit 6 drives the hit animation while
; bit 5 queues scoring/event processing for the foreground TERSE thread.
OBJECT_FLAG_SCORE_OVERLAY   EQU $04            ; bit 2: hit value is visible
OBJECT_FLAG_HIT_SIDE_BIT    EQU $03            ; 0 right, 1 left
OBJECT_FLAG_HIT_SIDE_MASK   EQU $08
OBJECT_FLAG_AT_BOUNDARY     EQU $10            ; bit 4
OBJECT_FLAG_HIT_PENDING     EQU $20            ; bit 5
OBJECT_FLAG_HIT_ANIMATION   EQU $40            ; bit 6
OBJECT_FLAG_ACTIVE          EQU $80            ; bit 7

; Surface-target IDs $00-$05 are ordered by scoring class.  The 1978 Midway
; flyer names the visible target classes; bitmap dimensions distinguish the ROM
; variants.  Mine and torpedo records are not traversed by PROCESS_SHIP_HIT.
OBJECT_TYPE_WARSHIP_A       EQU $00            ; 20x12 logical / 40x12 display
OBJECT_TYPE_WARSHIP_B       EQU $01            ; 16x11 logical / 32x11 display
OBJECT_TYPE_WARSHIP_C       EQU $02            ; 20x10 logical / 40x10 display
OBJECT_TYPE_FREIGHTER_A     EQU $03            ; 16x10 logical / 32x10 display
OBJECT_TYPE_FREIGHTER_B     EQU $04            ; 16x9 logical / 32x9 display
OBJECT_TYPE_PT_BOAT         EQU $05            ; 12x5 logical / 24x5 display
OBJECT_TYPE_MINE            EQU $06            ; 4x16 logical / 8x16 display
OBJECT_TYPE_TORPEDO         EQU $07            ; three perspective frames
OBJECT_TYPE_SUPER_SUB       EQU $08            ; 16x9 logical / 32x9 display

SCORE_FREIGHTER_BCD         EQU $01
SCORE_WARSHIP_BCD           EQU $03
SCORE_PT_BOAT_BCD           EQU $05
SCORE_SUPER_SUB_BCD         EQU $10
SCORE_UNIT_POINTS           EQU $64            ; one stored unit = 100 points
HIT_STREAK_LENGTH           EQU $04
BONUS_DISPLAY_ACTIVE_VALUE  EQU $3C
BONUS_DISPLAY_DURATION      EQU $78

; Collision resolver constants.  Horizontal overlap tests the torpedo's
; right-edge coordinate against a target span expanded by one four-pixel cell.
TORPEDO_COLLISION_X_BIAS        EQU $04
COLLISION_LAST_TARGET_LANE      EQU $02
COLLISION_SOUND_SIDE_RIGHT      EQU $30
COLLISION_SOUND_SIDE_LEFT       EQU $06
COLLISION_SOUND_CLASS_SHIP      EQU $12
COLLISION_SOUND_CLASS_MINE      EQU $24
SHIP_HIT_SOUND_TIMER_LOAD       EQU $40
MINE_HIT_SOUND_TIMER_LOAD       EQU $08
TORPEDO_SOUND_TIMER_LOAD        EQU $38
HIT_ANIMATION_TIMER_LOAD        EQU $06
RETIRED_OBJECT_TIMER_LOAD       EQU $2D
NEW_HIGH_SCORE_BLINK_PERIOD     EQU $1E
LAMP_HIT_INDICATOR_MASK         EQU $20

GAME_CLOCK_DIVIDER_RELOAD       EQU $3C
EXTENDED_SCORE_BASE_BCD         EQU $40

; Raw X-speed bytes are multiplied by four by ACTIVATE_TARGET_IN_LANE to form
; signed 8.8 velocities.  These become $0080, $0100 and $0200 per update.
TARGET_SPEED_SLOW_RAW       EQU $20
TARGET_SPEED_MEDIUM_RAW     EQU $40
TARGET_SPEED_FAST_RAW       EQU $80

; The bitmap symbols are defined at their descriptor bodies in $0E3F-$119E.
; The initial torpedo templates need literal low/high bytes before those
; forward definitions are resolved by zmac.
BITMAP_TORPEDO_NEAR_LO      EQU $2D
BITMAP_TORPEDO_NEAR_HI      EQU $11

; Scheduler pools contain record starts through the inclusive LAST address.
; Torpedo records are interleaved by station; successive records for one
; station are two records ($32 bytes) apart.
TARGET_POOL_BASE            EQU $C000
TARGET_LANE_UPPER_BASE      EQU $C000
TARGET_LANE_LOWER_BASE      EQU $C032
TARGET_LANE_UPPER_Y         EQU $1A
TARGET_LANE_LOWER_Y         EQU $33
TARGET_POOL_LAST            EQU $C04B
TARGET_POOL_COUNT           EQU $04
MINE_POOL_BASE              EQU $C064
MINE_LANE_UPPER_BASE        EQU $C064
MINE_LANE_MIDDLE_BASE       EQU $C096
MINE_LANE_LOWER_BASE        EQU $C0C8
MINE_LANE_UPPER_Y           EQU $4C
MINE_LANE_MIDDLE_Y          EQU $64
MINE_LANE_LOWER_Y           EQU $82
MINE_POOL_LAST              EQU $C0E1
MINE_POOL_COUNT             EQU $06
TORPEDO_POOL_BASE           EQU $C0FA
TORPEDO_POOL_LEFT_BASE      EQU $C0FA
TORPEDO_POOL_RIGHT_BASE     EQU $C113
TORPEDO_POOL_LAST           EQU $C1A9
TORPEDO_POOL_COUNT          EQU $08
TORPEDO_STATION_STRIDE      EQU $32
TORPEDO_AIM_HANDLE_BASE     EQU $12
TORPEDO_TRAJECTORY_ENTRY_COUNT EQU $20
TORPEDO_TRAJECTORY_TABLE_BYTES EQU $40
TORPEDO_TRAJECTORY_LAST_OFFSET EQU $3E

TORPEDO_FRAME_NEAR_MIN_Y    EQU $78
TORPEDO_FRAME_MIDDLE_MIN_Y  EQU $46
TORPEDO_FRAME_FAR_MIN_Y     EQU $00

TARGET_SCHEDULER_CURSOR     EQU $C1C2
MINE_SCHEDULER_CURSOR       EQU $C1C4
TORPEDO_SCHEDULER_CURSOR    EQU $C1C6

; Raster-interrupt scheduler state.  Each ROM schedule record is ten bytes:
; scanline, reserved byte, colors 4-7, then the IM2 vector and motion-state
; pointers used for the following schedule record.
INTERRUPT_SCHEDULE_CURSOR   EQU $C1FC
INTERRUPT_SCHEDULE_BASE     EQU $C20D
INTERRUPT_BASE_SCANLINE     EQU $C20F
INTERRUPT_MOTION_STATE_PTR  EQU $C210

RASTER_MOTION_STATE_0       EQU $C212
RASTER_MOTION_STATE_1       EQU $C216
RASTER_MOTION_STATE_2       EQU $C21A
RASTER_MOTION_STATE_3       EQU $C21E

RASTER_SCHEDULE_RECORD_SIZE EQU $0A
RASTER_SCHEDULE_END         EQU $FF
RASTER_MOTION_PERIOD        EQU $50

; Frame-timed discrete-sound producers.  The interrupt handler treats every
; nonzero byte as an asserted line and decrements the timers at 60 Hz.
; $C1D0-$C1D5 are packed in reverse address order onto port $40.
SOUND_RIGHT_MINE_HIT_TIMER  EQU $C1D0       ; port $40 bit 5
SOUND_RIGHT_SHIP_HIT_TIMER  EQU $C1D1       ; port $40 bit 4
SOUND_RIGHT_TORPEDO_TIMER   EQU $C1D2       ; port $40 bit 3
SOUND_LEFT_MINE_HIT_TIMER   EQU $C1D3       ; port $40 bit 2
SOUND_LEFT_SHIP_HIT_TIMER   EQU $C1D4       ; port $40 bit 1
SOUND_LEFT_TORPEDO_TIMER    EQU $C1D5       ; port $40 bit 0
COIN_COUNTER_PULSE_TIMER    EQU $C1D6       ; port $41 bit 6
SOUND_LEFT_SONAR_TIMER      EQU $C1D7       ; port $41 bit 5
SOUND_RIGHT_SONAR_TIMER     EQU $C1D8       ; port $41 bit 4
SOUND_DIVE_PAN_TIMER        EQU $C1D9       ; bits 7-5 -> port $41 bits 2-0;
                                                    ; bit 5 also triggers bit 3

SOUND_FRAME_DIVIDER         EQU $C1CA
SOUND_TIMER_BLOCK           EQU $C1CB       ; 16 timers, $C1CB-$C1DA
LEFT_RELOAD_TIMER           EQU $C1CB
RIGHT_RELOAD_TIMER          EQU $C1CC
NEW_HIGH_SCORE_BLINK_TIMER  EQU $C1CC       ; reused while no player is active
SONAR_CADENCE_TIMER         EQU $C1CD
RIGHT_BONUS_DISPLAY_TIMER   EQU $C1CE
LEFT_BONUS_DISPLAY_TIMER    EQU $C1CF
SONAR_PING_COUNT            EQU $C1E1
SOUND_DIVE_PAN_XOR          EQU $C1FA

_DSPATCH                EQU     $E9FD           ; JP (IY), stored little-endian

                        ORG     $0000

;-------------------------------------------------------------------------------
; Reset and TERSE execution kernel
;-------------------------------------------------------------------------------
COLD_START:             NOP
                        NOP
                        DI
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        JP      WARM_START

; ENTER is reached through RST $08.  It moves the caller's threaded instruction
; pointer from BC to the downward-growing IX return stack, then makes the return
; address following the RST instruction the new threaded instruction pointer.
TERSE_ENTER:            DEC     IX
                        DEC     IX
                        LD      (IX+$01),B
                        LD      (IX+$00),C
                        POP     BC
                        DW      _DSPATCH

UNUSED_0015:            EX      (SP),HL

WARM_START:             LD      A,$01
                        OUT     (PORT_VIDEO_MODE),A
                        LD      A,$51
                        OUT     (PORT_COLOR_SPLIT),A
                        LD      A,$CA
                        OUT     (PORT_VBLANK_LINE),A
                        LD      BC,INITIAL_THREAD
                        LD      IX,TERSE_RETURN_STACK
                        LD      IY,TERSE_DISPATCH
                        LD      SP,TERSE_DATA_STACK
                        IN      A,(PORT_DIP_SWITCHES)
                        AND     DIP_SERVICE_MODE_MASK
                        JP      Z,POWER_ON_SELF_TEST
                        DW      _DSPATCH

; Runtime for the TERSE return word (;).
TERSE_RETURN:           LD      C,(IX+$00)
                        LD      B,(IX+$01)
                        INC     IX
                        INC     IX

; NEXT: fetch a little-endian execution address from the threaded stream.
TERSE_DISPATCH:         LD      A,(BC)
                        INC     BC
                        LD      L,A
                        LD      A,(BC)
                        INC     BC
                        LD      H,A
                        JP      (HL)

; Fetch a byte through an address stored inline in the threaded stream.
TERSE_INLINE_BFETCH:    LD      A,(BC)
                        INC     BC
                        LD      L,A
                        LD      A,(BC)
                        INC     BC
                        LD      H,A
                        JR      TERSE_BFETCH_BODY

; B@ -- fetch a byte through an address supplied on the data stack.
TERSE_BFETCH:           POP     HL
TERSE_BFETCH_BODY:      LD      E,(HL)
                        LD      D,$00
                        PUSH    DE
                        DW      _DSPATCH

; B! -- store the low byte of a value through a stacked address.
TERSE_BSTORE:           POP     HL
                        POP     DE
                        LD      (HL),E
                        DW      _DSPATCH

; BEGIN runtime -- save the address of the current threaded cell on the IX
; control stack.  TERSE_UNTIL consumes this address.
TERSE_BEGIN:            DEC     IX
                        DEC     IX
                        LD      HL,$FFFE
                        ADD     HL,BC
                        LD      (IX+$00),L
                        LD      (IX+$01),H
                        DW      _DSPATCH

; UNTIL runtime -- repeat at the saved BEGIN cell while the flag is zero.
TERSE_UNTIL:            LD      D,(IX+$01)
                        LD      E,(IX+$00)
                        INC     IX
                        INC     IX
                        POP     HL
                        LD      A,H
                        OR      L
                        JR      NZ,TERSE_UNTIL_DONE
                        LD      B,D
                        LD      C,E
TERSE_UNTIL_DONE:       DW      _DSPATCH

; Boolean true.
TERSE_TRUE:             LD      HL,$FFFF
                        PUSH    HL
                        DW      _DSPATCH

; LIT -- push the following 16-bit threaded value.
TERSE_LIT:              LD      A,(BC)
                        LD      L,A
                        INC     BC
                        LD      A,(BC)
                        LD      H,A
                        INC     BC
                        PUSH    HL
                        DW      _DSPATCH

; Byte-sized logical complement used by early Sea Wolf II control code.
TERSE_BYTE_NOT:         POP     HL
                        LD      A,L
                        CPL
                        LD      L,A
                        PUSH    HL
                        DW      _DSPATCH

; 0BRANCH -- branch to the following inline address when the flag is zero;
; otherwise skip the inline address.
TERSE_ZERO_BRANCH:      POP     DE
                        LD      A,E
                        OR      D
                        JR      NZ,TERSE_ZERO_BRANCH_SKIP
                        LD      A,(BC)
                        INC     BC
                        LD      E,A
                        LD      A,(BC)
                        LD      B,A
                        LD      C,E
                        DW      _DSPATCH
TERSE_ZERO_BRANCH_SKIP: INC     BC
                        INC     BC
                        DW      _DSPATCH

; BRANCH -- replace BC with the following inline address.
TERSE_BRANCH:           LD      A,(BC)
                        LD      L,A
                        INC     BC
                        LD      A,(BC)
                        LD      B,A
                        LD      C,L
                        DW      _DSPATCH

;-------------------------------------------------------------------------------
; $00B0: Power-on video and RAM test palettes and failure pattern
;-------------------------------------------------------------------------------
; OTIR writes each eight-byte palette to color registers $00-$07.  A memory
; failure copies the four ten-byte rows below twice, then repeats that 80-byte
; seed across display RAM.
SELF_TEST_PATTERN_TABLE:
SELF_TEST_VIDEO_PALETTE:
                        DB      $E2,$E0,$E2,$E0,$E2,$E0,$E2,$E0 ; $00B0-$00B7
SELF_TEST_WORK_RAM_PALETTE:
                        DB      $8A,$88,$8A,$88,$8A,$88,$8A,$88 ; $00B8-$00BF
SELF_TEST_FAILURE_PATTERN:
SELF_TEST_FAILURE_ROW_00:
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00C0-$00C9
SELF_TEST_FAILURE_ROW_55:
                        DB      $55,$55,$55,$55,$55,$55,$55,$55,$55,$55 ; $00CA-$00D3
SELF_TEST_FAILURE_ROW_AA:
                        DB      $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; $00D4-$00DD
SELF_TEST_FAILURE_ROW_FF:
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $00DE-$00E7

;-------------------------------------------------------------------------------
; $00E8: Service-mode diagnostics and hardware verification
;-------------------------------------------------------------------------------
POWER_ON_SELF_TEST:
; With the service DIP active, reset enters here instead of the TERSE game
; thread.  No start button runs the ROM checksum before the destructive memory
; tests.  Holding START 1 skips directly to memory; START 2 selects the input
; display; holding both start buttons selects the convergence grid.
                        DI
                        XOR     A
                        OUT     (PORT_COLOR_4),A
                        OUT     (PORT_INTERRUPT_ENABLE),A
                        LD      A,$EA
                        OUT     (PORT_COLOR_SPLIT),A
                        LD      A,$C8
                        OUT     (PORT_VBLANK_LINE),A
                        LD      A,$07
                        OUT     (PORT_COLOR_7),A
                        IN      A,(PORT_COIN_START)
                        AND     INPUT_START_BUTTON_MASK
                        JP      NZ,SELF_TEST_BUTTON_SELECT

; Clear all $4000 bytes of screen RAM before reporting any ROM failure.
                        LD      HL,VIDEO_RAM_BASE
                        LD      DE,$4000
self_test_clear_video:  LD      (HL),$00
                        INC     HL
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        DEC     E
                        JR      NZ,self_test_clear_video
                        DEC     D
                        JR      NZ,self_test_clear_video

; Each of the four $0800-byte program ROMs has additive checksum $FF.  HL is
; deliberately allowed to advance across block boundaries; H therefore also
; identifies the block when a checksum fails.
                        LD      A,EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        LD      A,$32
                        LD      (TEXT_X_POSITION_HI),A
                        LD      (TEXT_Y_POSITION),A
                        LD      BC,SELF_TEST_ROM_BLOCK_SIZE
                        LD      HL,$0000
self_test_checksum_rom: XOR     A
self_test_sum_rom_byte: ADD     A,(HL)
                        LD      D,A
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        LD      A,D
                        INC     HL
                        DEC     C
                        JR      NZ,self_test_sum_rom_byte
                        DJNZ    self_test_sum_rom_byte
                        LD      A,D
                        CP      $FF
                        JR      NZ,self_test_report_rom_failure
self_test_next_rom:     LD      BC,SELF_TEST_ROM_BLOCK_SIZE
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        LD      A,H
                        CP      $20
                        JR      NZ,self_test_checksum_rom

; The renderer's X-position byte doubles as a work-RAM sentinel during the ROM
; pass.  Corruption stops the test before destructive RAM verification begins.
                        LD      A,(TEXT_X_POSITION_HI)
                        CP      $32
                        JR      Z,SELF_TEST_MEMORY_DIAGNOSTICS
self_test_ram_failure:  IN      A,(PORT_LEFT_STATION_HANDLE)
                        JR      self_test_ram_failure

; Render the failed ROM block identifier, then continue so every program ROM
; is checked in one pass.  Character codes $41-$44 identify the four blocks.
self_test_report_rom_failure:
                        LD      A,H
                        PUSH    HL
                        PUSH    DE
                        PUSH    BC
                        RRCA
                        RRCA
                        RRCA
                        AND     $07
                        ADD     A,$40
                        LD      HL,SELF_TEST_TEXT_BUFFER
                        LD      (HL),A
                        INC     HL
                        LD      (HL),$00
                        DEC     HL
                        CALL    DRAW_TEXT
                        DI
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        POP     BC
                        POP     DE
                        POP     HL
                        JR      self_test_next_rom

SELF_TEST_BUTTON_SELECT:
                        CP      INPUT_ONE_PLAYER_START_MASK
                        JP      NZ,SELF_TEST_MODE_SELECT

;-------------------------------------------------------------------------------
; $016E: Destructive video/work-RAM verification setup
;-------------------------------------------------------------------------------
SELF_TEST_MEMORY_DIAGNOSTICS:
                        DI
                        LD      A,$14
                        OUT     (PORT_COLOR_SPLIT),A
                        LD      B,SELF_TEST_PALETTE_BYTES
                        LD      HL,SELF_TEST_VIDEO_PALETTE
                        LD      C,PORT_COLOR_BLOCK
                        OTIR
                        LD      IY,SELF_TEST_PARAMETER_SET_1
                        JR      SELF_TEST_VIDEO_VERIFY

;-------------------------------------------------------------------------------
; $0182: Video-RAM range descriptor and successful-pass continuation
;-------------------------------------------------------------------------------
SELF_TEST_PARAMETER_SET_1:
                        JR      SELF_TEST_SECOND_PASS
                        DB      $3F                    ; page preceding tested range
                        DB      $80                    ; exclusive upper page
                        DW      VIDEO_RAM_BASE         ; first byte tested

;-------------------------------------------------------------------------------
; $0188: Load the second palette and test the $C000-$C3FF work RAM
;-------------------------------------------------------------------------------
SELF_TEST_SECOND_PASS:
                        LD      B,SELF_TEST_PALETTE_BYTES
                        LD      HL,SELF_TEST_WORK_RAM_PALETTE
                        LD      C,PORT_COLOR_BLOCK
                        OTIR
                        LD      IY,SELF_TEST_PARAMETER_SET_2
                        JR      SELF_TEST_VIDEO_VERIFY

;-------------------------------------------------------------------------------
; $0197: Work-RAM range descriptor and successful-pass continuation
;-------------------------------------------------------------------------------
SELF_TEST_PARAMETER_SET_2:
                        JR      SELF_TEST_RESTART
                        DB      $BF                    ; page preceding tested range
                        DB      $C4                    ; exclusive upper page
                        DW      RAM_BASE               ; first byte tested

;-------------------------------------------------------------------------------
; $019D: Both memory ranges passed; restart through normal initialization
;-------------------------------------------------------------------------------
SELF_TEST_RESTART:
                        JP      WARM_START

;-------------------------------------------------------------------------------
; $01A0: Destructive walking-bit memory verification
;-------------------------------------------------------------------------------
SELF_TEST_VIDEO_VERIFY:
; C accumulates every failing data bit.  B walks $01,$02,...,$80.  Each bit
; receives three checks: write/read while ascending, read/replace with the
; complement while descending, then complement/read/clear while ascending.
                        LD      C,$00
                        LD      B,$01
self_test_begin_bit:    LD      H,(IY+SELF_TEST_RANGE_START_HI)
                        LD      L,(IY+SELF_TEST_RANGE_START_LO)
self_test_write_bit:    LD      (HL),B
                        LD      A,(HL)
                        XOR     B
                        JR      Z,self_test_advance_write
                        LD      IX,self_test_advance_write
                        JP      SELF_TEST_ACCUMULATE_FAILURE
self_test_advance_write:
                        INC     HL
                        LD      A,H
                        CP      (IY+SELF_TEST_RANGE_UPPER_PAGE)
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        JR      NZ,self_test_write_bit

self_test_reverse_scan: DEC     HL
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        LD      A,H
                        CP      (IY+SELF_TEST_RANGE_LOWER_PAGE)
                        JR      Z,self_test_forward_complement_scan
                        LD      A,(HL)
                        XOR     B
                        JR      Z,self_test_write_complement
                        LD      IX,self_test_write_complement
                        JP      SELF_TEST_ACCUMULATE_FAILURE
self_test_write_complement:
                        LD      A,B
                        CPL
                        LD      (HL),A
                        XOR     (HL)
                        JR      Z,self_test_reverse_scan
                        LD      IX,self_test_reverse_scan
                        JP      SELF_TEST_ACCUMULATE_FAILURE

self_test_forward_complement_scan:
                        INC     HL
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        LD      A,H
                        CP      (IY+SELF_TEST_RANGE_UPPER_PAGE)
                        JR      Z,self_test_next_bit
                        LD      A,B
                        CPL
                        XOR     (HL)
                        JR      Z,self_test_clear_test_byte
                        LD      IX,self_test_clear_test_byte
                        JR      SELF_TEST_ACCUMULATE_FAILURE
self_test_clear_test_byte:
                        XOR     A
                        LD      (HL),A
                        JR      self_test_forward_complement_scan

self_test_next_bit:     SLA     B
                        JR      NC,self_test_begin_bit
                        LD      A,C
                        AND     A
                        JR      NZ,SELF_TEST_DISPLAY_MEMORY_FAILURE
                        JP      (IY)
; Preserve the live test registers in the primary set while the shadow set
; builds a full-screen failure pattern.  The accumulated bits in C then select
; palette registers, identifying every data line that failed.
SELF_TEST_DISPLAY_MEMORY_FAILURE:
                        EXX
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        LD      DE,VIDEO_RAM_BASE
                        LD      HL,SELF_TEST_FAILURE_PATTERN
                        LD      BC,SELF_TEST_FAILURE_PATTERN_BYTES
                        LDIR
                        LD      BC,SELF_TEST_FAILURE_PATTERN_BYTES
                        LD      HL,SELF_TEST_FAILURE_PATTERN
                        LDIR
                        LD      HL,VIDEO_RAM_BASE
                        LD      BC,$40B0
self_test_expand_failure_pattern:
                        LD      A,(HL)
                        LD      (DE),A
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        INC     HL
                        INC     DE
                        DEC     C
                        JR      NZ,self_test_expand_failure_pattern
                        DJNZ    self_test_expand_failure_pattern
                        EXX

                        LD      A,$47
                        BIT     0,C
                        JR      Z,self_test_error_bit_1
                        OUT     (PORT_COLOR_3),A
self_test_error_bit_1:  BIT     1,C
                        JR      Z,self_test_error_bit_2
                        OUT     (PORT_COLOR_2),A
self_test_error_bit_2:  BIT     2,C
                        JR      Z,self_test_error_bit_3
                        OUT     (PORT_COLOR_1),A
self_test_error_bit_3:  BIT     3,C
                        JR      Z,self_test_error_bit_4
                        OUT     (PORT_COLOR_0),A
self_test_error_bit_4:  BIT     4,C
                        JR      Z,self_test_error_bit_5
                        OUT     (PORT_COLOR_7),A
self_test_error_bit_5:  BIT     5,C
                        JR      Z,self_test_error_bit_6
                        OUT     (PORT_COLOR_6),A
self_test_error_bit_6:  BIT     6,C
                        JR      Z,self_test_error_bit_7
                        OUT     (PORT_COLOR_5),A
self_test_error_bit_7:  BIT     7,C
                        JR      Z,self_test_memory_failure_halt
                        OUT     (PORT_COLOR_4),A
self_test_memory_failure_halt:
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        JR      self_test_memory_failure_halt

; A holds the nonzero XOR result from one failed byte.  ORing it into C keeps
; the complete failing-bit mask, then IX resumes at the exact interrupted phase.
SELF_TEST_ACCUMULATE_FAILURE:
                        OR      C
                        LD      C,A
                        JP      (IX)

;-------------------------------------------------------------------------------
; $0264: Select reset-button diagnostic path
;-------------------------------------------------------------------------------
SELF_TEST_MODE_SELECT:
                        CP      INPUT_TWO_PLAYER_START_MASK
                        JP      NZ,CONVERGENCE_TEST
                        LD      SP,TERSE_DATA_STACK
                        LD      IX,TERSE_RETURN_STACK
                        LD      IY,SELF_TEST_INTERACTIVE
                        JP      CLEAR_GAME_STATE_AND_PLAYFIELD

;-------------------------------------------------------------------------------
; $0277: Interactive service-test loop
;-------------------------------------------------------------------------------
SELF_TEST_INTERACTIVE:
; Display the decoded six-bit position of both optical handles.  The left
; string begins at X=0 and the right string at X=$78, both on row $78.
                        LD      A,EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        LD      A,$78
                        LD      (TEXT_Y_POSITION),A
self_test_input_loop:   IN      A,(PORT_LEFT_STATION_HANDLE)
                        XOR     A
                        LD      (TEXT_X_POSITION_HI),A
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        CALL    SELF_TEST_DRAW_HANDLE_VALUE
                        LD      A,$78
                        LD      (TEXT_X_POSITION_HI),A
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        IN      A,(PORT_RIGHT_STATION_HANDLE)
                        CALL    SELF_TEST_DRAW_HANDLE_VALUE
                        JR      self_test_input_loop

; Convert the hardware's Gray-coded handle value to a six-character binary
; string.  FIRE is not included; this screen verifies the position encoder.
SELF_TEST_DRAW_HANDLE_VALUE:
                        CALL    DECODE_HANDLE_POSITION
                        LD      HL,SELF_TEST_TEXT_BUFFER
                        AND     DECODED_HANDLE_POSITION_MASK
                        RLCA
                        LD      B,$06
self_test_emit_handle_bit:
                        RLA
                        LD      C,A
                        LD      A,$00
                        ADC     A,$30
                        LD      (HL),A
                        INC     HL
                        LD      A,C
                        DJNZ    self_test_emit_handle_bit
                        LD      (HL),$00
                        LD      HL,SELF_TEST_TEXT_BUFFER
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        CALL    DRAW_TEXT
                        DI
                        RET

;-------------------------------------------------------------------------------
; $02BE: Convergence/grid display test
;-------------------------------------------------------------------------------
CONVERGENCE_TEST:
; The first $50-byte scanline alternates $00/$03, producing vertical lines.
; It is followed by $230 clear bytes.  Repeating that $280-byte seed over the
; remaining screen produces horizontal lines every eight scanlines.
                        LD      HL,VIDEO_RAM_BASE
                        LD      B,$28
convergence_vertical_pattern:
                        LD      (HL),$00
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        INC     HL
                        LD      (HL),$03
                        INC     HL
                        DJNZ    convergence_vertical_pattern

                        LD      BC,$0330
convergence_clear_seed: LD      (HL),$00
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        INC     HL
                        DEC     C
                        JR      NZ,convergence_clear_seed
                        DJNZ    convergence_clear_seed

                        EX      DE,HL
                        LD      HL,VIDEO_RAM_BASE
                        LD      BC,$3DA0
convergence_repeat_seed:
                        LD      A,(HL)
                        LD      (DE),A
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        INC     DE
                        INC     HL
                        DEC     C
                        JR      NZ,convergence_repeat_seed
                        DJNZ    convergence_repeat_seed
convergence_halt:       IN      A,(PORT_LEFT_STATION_HANDLE)
                        JR      convergence_halt

;-------------------------------------------------------------------------------
; $02F0: Initial direct-threaded TERSE execution list
;-------------------------------------------------------------------------------
INITIAL_THREAD:
                        DW      CLEAR_RAM_AND_LOWER_VIDEO
                        DW      INITIALIZE_MACHINE
initial_loop:           DW      FINALIZE_SCORES_AND_DRAW_GAME_OVER
                        DW      INITIALIZE_MAIN_STATE
                        DW      START_SELECTION_AND_PROMPTS
                        DW      RESET_RUNTIME_STATE
                        DW      CONTROL_THREAD_WORD
                        DW      TERSE_BRANCH
                        DW      initial_loop

;-------------------------------------------------------------------------------
; $0302: Clear work RAM and the lower video/status area
;-------------------------------------------------------------------------------
CLEAR_RAM_AND_LOWER_VIDEO:
                        LD      HL,RAM_BASE
                        LD      DE,$0400
                        XOR     A
clear_all_work_ram:     LD      (HL),A
                        INC     HL
                        DEC     E
                        JR      NZ,clear_all_work_ram
                        DEC     D
                        JR      NZ,clear_all_work_ram

; Clear $77F0-$7FAF: the lower $7C0 bytes of visible video RAM.
                        LD      HL,$77F0
                        LD      DE,$08C0
clear_lower_video:      LD      (HL),A
                        INC     HL
                        DEC     E
                        JR      NZ,clear_lower_video
                        DEC     D
                        JR      NZ,clear_lower_video
                        JP      (IY)

;-------------------------------------------------------------------------------
; $0321: Interrupt schedule, moving raster state and object-sequence setup
;-------------------------------------------------------------------------------
INITIALIZE_MACHINE:
                        PUSH    BC
                        LD      A,INITIAL_INTERRUPT_ENABLE
                        OUT     (PORT_INTERRUPT_ENABLE),A
                        IM      2

; Seed four four-byte moving-raster states at $C212-$C221.
                        LD      BC,$0010
                        LD      HL,INITIAL_RAM_TEMPLATE
                        LD      DE,RASTER_MOTION_STATE_0
                        LDIR

; S1-7 selects the six-boundary palette schedule for the installed monitor.
; Color selects the high-chroma schedule; black-and-white selects luminance
; values suitable for the monochrome display option documented by Midway.
                        IN      A,(PORT_DIP_SWITCHES)
                        AND     DIP_MONITOR_TYPE_MASK
                        LD      HL,MONOCHROME_MONITOR_INTERRUPT_SCHEDULE
                        JR      Z,interrupt_schedule_selected
                        LD      HL,COLOR_MONITOR_INTERRUPT_SCHEDULE
interrupt_schedule_selected:
                        LD      (INTERRUPT_SCHEDULE_CURSOR),HL
                        LD      (INTERRUPT_SCHEDULE_BASE),HL
                        LD      A,INITIAL_COLOR_SPLIT_VALUE
                        OUT     (PORT_COLOR_SPLIT),A

; Prime the first schedule record before normal IM 2 interrupts begin.
                        CALL    ALTERNATE_RASTER_INTERRUPT_HANDLER
                        POP     BC
                        LD      HL,TARGET_TYPE_SEQUENCE
                        LD      (TARGET_TYPE_SEQUENCE_CURSOR),HL
                        JP      (IY)

;-------------------------------------------------------------------------------
; $0355: Initial state for the four moving raster boundaries
;-------------------------------------------------------------------------------
INITIAL_RAM_TEMPLATE:
                        DB      $04,$04,$00,$00         ; $C212: base $18 phase/velocity/offset
                        DB      $18,$08,$00,$00         ; $C216: base $30
                        DB      $2C,$10,$00,$00         ; $C21A: base $54
                        DB      $40,$20,$00,$00         ; $C21E: base $84

;-------------------------------------------------------------------------------
; $0365: Clear top-level state and enter its TERSE thread
;-------------------------------------------------------------------------------
INITIALIZE_MAIN_STATE:
                        XOR     A
                        LD      (ACTIVE_PLAYER_COUNT),A
                        LD      (SOUND_DIVE_PAN_XOR),A
                        OUT     (PORT_SOUND_CONTROL),A
                        RST     $08

;-------------------------------------------------------------------------------
; $036F: Nested initialization TERSE thread
;-------------------------------------------------------------------------------
MAIN_INITIALIZATION_THREAD:
                        DW      CLEAR_GAME_STATE_AND_PLAYFIELD
                        DW      TERSE_DRAW_TEXT_INLINE
                        DW      TEXT_HIGH_SCORE
                        DB      $02,$4A,$00             ; Y=$02, X=$4A, normal size
                        DW      DRAW_HIGH_SCORE_WORD
                        DW      TERSE_DRAW_TEXT_INLINE
                        DW      TEXT_SEAWOLF_II
                        DB      $48,$3E,$00             ; Y=$48, X=$3E, normal size
                        DW      CONTROL_THREAD_WORD
                        DW      TERSE_RETURN

;-------------------------------------------------------------------------------
; $0385: Clear runtime RAM/video state
;-------------------------------------------------------------------------------
RESET_RUNTIME_STATE:
                        XOR     A
; $C20A has no other reference in the ROM; its reset is retained explicitly.
                        LD      (UNREFERENCED_RUNTIME_BYTE),A
                        LD      DE,$08C0
                        LD      HL,$77F0
reset_lower_video:      LD      (HL),A
                        INC     HL
                        DEC     E
                        JR      NZ,reset_lower_video
                        DEC     D
                        JR      NZ,reset_lower_video
; Normal game reset enters here by falling through from RESET_RUNTIME_STATE.
; The interactive service test jumps here directly, using IY as its return.
CLEAR_GAME_STATE_AND_PLAYFIELD:
                        LD      HL,RAM_BASE
                        XOR     A
                        PUSH    BC
                        LD      BC,$02C2
clear_object_state:     LD      (HL),A
                        INC     HL
                        DEC     C
                        JR      NZ,clear_object_state
                        DJNZ    clear_object_state

                        LD      HL,SOUND_TIMER_BLOCK
                        LD      B,$2D
clear_timed_state:      LD      (HL),A
                        INC     HL
                        DJNZ    clear_timed_state

; Select the initial packed-BCD game timer from player count and the two play-
; time DIP bits.  Each DIP step removes 10 seconds for one player or 15 seconds
; for two players.
                        IN      A,(PORT_DIP_SWITCHES)
                        AND     DIP_PLAY_TIME_MASK
                        RRCA
                        LD      B,A
                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      PLAYER_COUNT_TWO
                        LD      C,$15
                        LD      D,$91
                        JR      Z,game_time_parameters_ready
                        LD      D,$71
                        LD      C,$10
game_time_parameters_ready:
                        LD      A,B
                        OR      A
                        JR      Z,use_longest_game_time
                        LD      A,D
reduce_game_time:       SUB     C
                        DAA
                        DJNZ    reduce_game_time
                        JR      game_time_ready
use_longest_game_time:  LD      A,D
game_time_ready:        LD      (GAME_TIME_BCD),A

; Clear the active playfield while preserving the upper status area.
                        LD      DE,$38F0
                        LD      HL,VIDEO_RAM_BASE
clear_active_playfield: LD      (HL),$00
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        INC     HL
                        DEC     E
                        JR      NZ,clear_active_playfield
                        DEC     D
                        JR      NZ,clear_active_playfield

                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      PLAYER_COUNT_TWO
                        JR      Z,draw_initial_player_status
                        LD      A,$FF
                        LD      (LEFT_SCORE_REDRAW_LATCH),A ; suppress absent P2 score
draw_initial_player_status:
                        CALL    DRAW_PLAYER_STATUS
                        POP     BC
                        JP      (IY)

;-------------------------------------------------------------------------------
; $03F6: Start/credit selection and prompt rendering
;-------------------------------------------------------------------------------
; START_ELIGIBILITY_FLAGS is recomputed from DIP port bits 3/0 and the current
; credit count.  Bit 1 enables the one-player button; bit 2 enables two-player.
; START_CREDIT_COST is committed only after an enabled button is pressed.
START_SELECTION_AND_PROMPTS:
                        XOR     A
                        LD      (START_ELIGIBILITY_FLAGS),A
                        LD      (START_CREDIT_COST),A

start_selection_loop:   PUSH    IY
                        LD      IY,start_prompt_after_coin_service
                        JP      PULSE_COIN_COUNTER
start_prompt_after_coin_service:
                        POP     IY

; Accept an enabled one-player start input.
                        LD      A,(START_ELIGIBILITY_FLAGS)
                        BIT     START_FLAG_ONE_PLAYER_BIT,A
                        JR      Z,check_two_player_start
                        IN      A,(PORT_COIN_START)
                        BIT     INPUT_ONE_PLAYER_START_BIT,A
                        JR      Z,check_two_player_start
                        LD      A,PLAYER_COUNT_ONE
                        LD      (ACTIVE_PLAYER_COUNT),A
commit_start_credits:   LD      A,(CREDIT_COUNT)
                        LD      HL,START_CREDIT_COST
                        SUB     (HL)
                        LD      (CREDIT_COUNT),A
                        JP      (IY)

; Accept an enabled two-player start input.
check_two_player_start: LD      A,(START_ELIGIBILITY_FLAGS)
                        BIT     START_FLAG_TWO_PLAYER_BIT,A
                        JR      Z,derive_start_options
                        IN      A,(PORT_COIN_START)
                        BIT     INPUT_TWO_PLAYER_START_BIT,A
                        JR      Z,derive_start_options
                        LD      A,PLAYER_COUNT_TWO
                        LD      (ACTIVE_PLAYER_COUNT),A
                        JR      commit_start_credits

; The attract/control thread enters this word only after CREDIT_COUNT becomes
; nonzero.  Tests below for values other than one therefore mean two or more.
derive_start_options:   LD      HL,START_ELIGIBILITY_FLAGS
                        IN      A,(PORT_DIP_SWITCHES)
                        AND     DIP_PRICING_MASK
                        OR      A
                        JP      Z,pricing_two_credits_either_player
                        CP      PRICING_1P_2C_2P_4C
                        JP      Z,pricing_two_or_four_credits
                        CP      PRICING_1P_1C_2P_1C
                        JP      Z,pricing_one_credit_either_player

; DIP mask $09: one credit enables 1P; two or more enable 2P.
pricing_one_or_two_credits:
                        LD      A,(CREDIT_COUNT)
                        CP      $01
                        JR      NZ,enable_two_player_for_two_credits
                        SET     START_FLAG_ONE_PLAYER_BIT,(HL)
                        RES     START_FLAG_TWO_PLAYER_BIT,(HL)
                        INC     HL
                        LD      (HL),$01
                        JP      select_prompt_one_player
enable_two_player_for_two_credits:
                        RES     START_FLAG_ONE_PLAYER_BIT,(HL)
                        SET     START_FLAG_TWO_PLAYER_BIT,(HL)
                        INC     HL
                        LD      (HL),$02
                        JP      select_prompt_two_player

; DIP mask $01: one credit starts either station mode.
pricing_one_credit_either_player:
                        SET     START_FLAG_ONE_PLAYER_BIT,(HL)
                        SET     START_FLAG_TWO_PLAYER_BIT,(HL)
                        INC     HL
                        LD      (HL),$01
                        JP      select_prompt_either_player

; DIP mask $00: two credits start either station mode.
pricing_two_credits_either_player:
                        LD      A,(CREDIT_COUNT)
                        CP      $01
                        JR      NZ,enable_either_player_for_two_credits
                        JP      select_prompt_insert_one_more
enable_either_player_for_two_credits:
                        SET     START_FLAG_ONE_PLAYER_BIT,(HL)
                        SET     START_FLAG_TWO_PLAYER_BIT,(HL)
                        INC     HL
                        LD      (HL),$02
                        JP      select_prompt_two_credit_either

; DIP mask $08: two credits start 1P and four credits start 2P.
pricing_two_or_four_credits:
                        LD      A,(CREDIT_COUNT)
                        CP      $01
                        JR      NZ,check_two_or_four_credit_count
                        JP      select_prompt_need_credit_for_one_player
check_two_or_four_credit_count:
                        CP      $02
                        JR      NZ,check_three_credit_count
                        SET     START_FLAG_ONE_PLAYER_BIT,(HL)
                        RES     START_FLAG_TWO_PLAYER_BIT,(HL)
                        INC     HL
                        LD      (HL),A
                        JP      select_prompt_one_player_or_two_coins
check_three_credit_count:
                        CP      $03
                        JR      NZ,enable_two_player_for_four_credits
                        RES     START_FLAG_ONE_PLAYER_BIT,(HL)
                        RES     START_FLAG_TWO_PLAYER_BIT,(HL)
                        JP      select_prompt_one_more_for_two_player
enable_two_player_for_four_credits:
                        RES     START_FLAG_ONE_PLAYER_BIT,(HL)
                        SET     START_FLAG_TWO_PLAYER_BIT,(HL)
                        INC     HL
                        LD      (HL),$04
                        JP      select_prompt_four_credit_two_player

; Translate the English pointer-list base to the selected language.  The nine
; lists have identical layout in all three language blocks.
select_prompt_one_player:
                        LD      HL,ENGLISH_PROMPT_TABLE_0
render_selected_prompt: CALL    READ_LANGUAGE_SELECTION
                        LD      DE,$0000
                        CP      LANGUAGE_ENGLISH
                        JR      Z,prompt_language_offset_ready
                        LD      DE,GERMAN_PROMPT_TABLE_OFFSET
                        CP      LANGUAGE_GERMAN
                        JR      Z,prompt_language_offset_ready
                        LD      DE,FRENCH_PROMPT_TABLE_OFFSET
prompt_language_offset_ready:
                        ADD     HL,DE
                        LD      DE,PROMPT_INITIAL_Y_WORD
                        LD      (TEXT_Y_POSITION_LO),DE
                        CALL    DRAW_PROMPT_POINTER_LIST
                        JP      start_selection_loop

select_prompt_two_player:
                        LD      HL,ENGLISH_PROMPT_TABLE_1
                        JR      render_selected_prompt
select_prompt_either_player:
                        LD      HL,ENGLISH_PROMPT_TABLE_2
                        JR      render_selected_prompt
select_prompt_insert_one_more:
                        LD      HL,ENGLISH_PROMPT_TABLE_3
                        JR      render_selected_prompt
select_prompt_two_credit_either:
                        LD      HL,ENGLISH_PROMPT_TABLE_4
                        JR      render_selected_prompt
select_prompt_need_credit_for_one_player:
                        LD      HL,ENGLISH_PROMPT_TABLE_5
                        JR      render_selected_prompt
select_prompt_one_player_or_two_coins:
                        LD      HL,ENGLISH_PROMPT_TABLE_6
                        JR      render_selected_prompt
select_prompt_one_more_for_two_player:
                        LD      HL,ENGLISH_PROMPT_TABLE_7
                        JR      render_selected_prompt
select_prompt_four_credit_two_player:
                        LD      HL,ENGLISH_PROMPT_TABLE_8
                        JR      render_selected_prompt

;-------------------------------------------------------------------------------
; $0501: Render a zero-terminated list of text pointers
;-------------------------------------------------------------------------------
; HL points to a sequence of text pointers terminated by $0000.  Every line is
; drawn at X=$28; the 8.8 Y coordinate advances by $0C00 after each string.
DRAW_PROMPT_POINTER_LIST:
                        LD      A,PROMPT_TEXT_COLOR
                        LD      (TEXT_COLOR),A
                        LD      DE,PROMPT_TEXT_X_WORD
                        LD      (TEXT_X_POSITION_LO),DE
                        LD      E,(HL)
                        INC     HL
                        LD      D,(HL)
                        INC     HL
                        LD      A,E
                        OR      D
                        RET     Z
                        PUSH    HL
                        LD      H,D
                        LD      L,E
                        CALL    DRAW_TEXT
                        LD      HL,(TEXT_Y_POSITION_LO)
                        LD      DE,PROMPT_LINE_Y_STEP_WORD
                        ADD     HL,DE
                        LD      (TEXT_Y_POSITION_LO),HL
                        POP     HL
                        JR      DRAW_PROMPT_POINTER_LIST

;-------------------------------------------------------------------------------
; $0527: Decode the two language-select input bits
;-------------------------------------------------------------------------------
; The post-500-game four-position language switch supplies two active-high
; contacts.  Port $12 bit 3 selects German and port $11 bit 6 selects French;
; French has priority if both contacts are asserted.  No contact is English.
READ_LANGUAGE_SELECTION:
                        PUSH    BC
                        IN      A,(PORT_COIN_START)
                        AND     LANGUAGE_GERMAN_SWITCH_MASK
                        LD      B,A
                        IN      A,(PORT_RIGHT_STATION_HANDLE)
                        AND     LANGUAGE_FRENCH_SWITCH_MASK
                        OR      B
                        LD      B,LANGUAGE_ENGLISH
                        JR      Z,language_selected
                        LD      B,LANGUAGE_GERMAN
                        CP      LANGUAGE_GERMAN_SWITCH_MASK
                        JR      Z,language_selected
                        LD      B,LANGUAGE_FRENCH
language_selected:      LD      A,B
                        LD      (LANGUAGE_SELECTION),A
                        POP     BC
                        RET

;-------------------------------------------------------------------------------
; $0544: Native ENTER followed by an inline TERSE control thread
;-------------------------------------------------------------------------------
CONTROL_THREAD_WORD:
                        RST     $08
control_wait:           DW      TERSE_BEGIN
                        DW      TERSE_INLINE_BFETCH,PATROL_COMPLETE_FLAG
                        DW      TERSE_ZERO_BRANCH,control_no_state
                        DW      CHECK_PATROL_END_OR_EXTENDED_PLAY
control_no_state:       DW      TERSE_INLINE_BFETCH,ACTIVE_PLAYER_COUNT
                        DW      TERSE_ZERO_BRANCH,control_no_player
                        DW      ERASE_EXPIRED_HIT_SCORES,PROCESS_SHIP_HIT,REFRESH_DIRTY_PLAYER_SCORES,UPDATE_SONAR_SEQUENCE
                        DW      TERSE_INLINE_BFETCH,PATROL_COMPLETE_FLAG
                        DW      TERSE_BYTE_NOT
                        DW      TERSE_ZERO_BRANCH,control_continue
                        DW      UPDATE_GAME_TIME_DISPLAY,ACTIVATE_TARGET_LANES,POLL_TORPEDO_FIRE
                        DW      TERSE_BRANCH,control_continue
control_no_player:      DW      INITIALIZE_OBJECT_POOLS,UPDATE_NEW_HIGH_SCORE_MESSAGE
                        DW      TERSE_INLINE_BFETCH,CREDIT_COUNT
                        DW      TERSE_ZERO_BRANCH,control_continue
                        DW      TERSE_TRUE
                        DW      TERSE_LIT,PATROL_COMPLETE_FLAG
                        DW      TERSE_BSTORE
control_continue:       DW      PULSE_COIN_COUNTER
                        DW      TERSE_INLINE_BFETCH,CONTROL_LOOP_EXIT_FLAG
                        DW      TERSE_UNTIL
                        DW      TERSE_RETURN

;-------------------------------------------------------------------------------
; $0593: Finalize scores, update the high score, and draw GAME OVER
;-------------------------------------------------------------------------------
; The two screen clears cover $4000-$567F and a 48-byte-wide by 12-row block
; beginning at $7B70.  The second loop adds 32 bytes after each 48-byte clear,
; advancing exactly one $50-byte video row.
FINALIZE_SCORES_AND_DRAW_GAME_OVER:
                        LD      HL,VIDEO_RAM_BASE
                        XOR     A
                        LD      DE,$3C60
clear_game_over_upper:  LD      (HL),A
                        INC     HL
                        DEC     E
                        JR      NZ,clear_game_over_upper
                        DEC     D
                        JR      NZ,clear_game_over_upper

                        LD      HL,$7B70
                        LD      DE,$0020
                        PUSH    BC
                        LD      A,$0C
clear_game_over_lower_row:
                        LD      B,$30
clear_game_over_lower_byte:
                        LD      (HL),$00
                        INC     HL
                        DJNZ    clear_game_over_lower_byte
                        ADD     HL,DE
                        DEC     A
                        JR      NZ,clear_game_over_lower_row

; Scores are two-byte packed BCD in units of 100 points.  Select the larger
; station score; a two-player tie selects the left station.  The high score is
; replaced only when that candidate is strictly greater, and C1F8 records the
; new-high-score event for the blinking congratulations message.
                        LD      HL,(LEFT_SCORE_BCD_LO)
                        LD      DE,(RIGHT_SCORE_BCD_LO)
                        LD      B,H
                        LD      C,L
                        XOR     A                       ; left candidate selector
                        SBC     HL,DE
                        JR      NC,final_score_selected
                        LD      A,$FF                   ; right candidate selector
                        LD      B,D
                        LD      C,E
final_score_selected:   LD      HL,(HIGH_SCORE_BCD_LO)
                        LD      D,A
                        XOR     A
                        SBC     HL,BC
                        JR      NC,store_new_high_score_flag
                        LD      A,D
                        OR      A
                        LD      DE,LEFT_SCORE_BCD_LO
                        JR      Z,new_high_score_source_ready
                        LD      DE,RIGHT_SCORE_BCD_LO
new_high_score_source_ready:
                        LD      HL,HIGH_SCORE_BCD_LO
                        LD      A,(DE)
                        LD      (HL),A
                        INC     HL
                        INC     DE
                        LD      A,(DE)
                        LD      (HL),A
                        LD      A,$FF
store_new_high_score_flag:
                        LD      (NEW_HIGH_SCORE_FLAG),A
                        POP     BC

; The language reader returns 0 English, 1 German, or 2 French.  Each branch
; enters a short inline TERSE program so the common text word can consume its
; pointer and screen-position operands directly.
                        CALL    READ_LANGUAGE_SELECTION
                        CP      LANGUAGE_ENGLISH
                        JR      NZ,game_over_not_english
                        RST     $08
                        DW      TERSE_DRAW_TEXT_INLINE
                        DW      TEXT_GAME_OVER_EN
                        DB      $B4,$2C,$FF            ; Y, X, double size
                        DW      TERSE_RETURN
game_over_not_english:  CP      LANGUAGE_GERMAN
                        JR      NZ,draw_game_over_french
                        RST     $08
                        DW      TERSE_DRAW_TEXT_INLINE
                        DW      TEXT_GAME_OVER_DE
                        DB      $B4,$2C,$FF            ; Y, X, double size
                        DW      TERSE_RETURN
draw_game_over_french:  RST     $08
                        DW      TERSE_DRAW_TEXT_INLINE
                        DW      TEXT_GAME_OVER_FR
                        DB      $B4,$2C,$FF            ; Y, X, double size
                        DW      TERSE_RETURN

;-------------------------------------------------------------------------------
; $0613: Hit processing, score update and ready/reload lamp output
;-------------------------------------------------------------------------------
PROCESS_SHIP_HIT:
; Walk the four moving-target records and consume collision-event bit 5.  Bit 3
; identifies the station that fired the successful torpedo.  Collision-event
; and hit-animation state are independent so scoring runs once while animation
; continues in the interrupt scheduler.
                        LD      HL,TARGET_POOL_BASE
                        PUSH    BC
                        PUSH    IY
process_target_hit:     BIT     5,(HL)
                        JP      Z,next_target_hit
                        RES     5,(HL)
                        BIT     OBJECT_FLAG_HIT_SIDE_BIT,(HL)
                        LD      DE,RIGHT_SCORE_BCD_LO
                        LD      A,(RIGHT_LAMP_STATE)
                        LD      C,PORT_RIGHT_LAMPS
                        JR      Z,hit_station_selected
                        LD      DE,LEFT_SCORE_BCD_LO
                        LD      A,(LEFT_LAMP_STATE)
                        LD      C,PORT_LEFT_LAMPS
hit_station_selected:   INC     HL                      ; OBJECT_TYPE
                        OR      LAMP_HIT_INDICATOR_MASK
                        OUT     (C),A
                        LD      A,(HL)
                        DEC     HL
                        PUSH    HL
                        POP     IY
                        EX      DE,HL

; Convert target type to packed BCD in 100-point units: warships $03,
; freighters $01, PT Boat $05, and Super Sub $10.  The ordered IDs make the
; three class boundaries direct comparisons.  The same increment is added to
; the station's consecutive-hit accumulator for the four-hit bonus.
                        LD      B,SCORE_WARSHIP_BCD
                        CP      OBJECT_TYPE_FREIGHTER_A
                        JR      C,hit_score_value_ready
                        LD      B,SCORE_FREIGHTER_BCD
                        CP      OBJECT_TYPE_PT_BOAT
                        JR      C,hit_score_value_ready
                        LD      B,SCORE_PT_BOAT_BCD
                        CP      OBJECT_TYPE_TORPEDO
                        JR      C,hit_score_value_ready
                        LD      B,SCORE_SUPER_SUB_BCD
hit_score_value_ready:  LD      A,(HL)
                        ADD     A,B
                        DAA
                        LD      (HL),A
                        INC     HL
                        LD      A,(HL)
                        ADC     A,$00
                        DAA
                        LD      (HL),A
                        INC     HL
                        LD      (HL),$00
                        INC     HL
                        INC     (HL)
                        INC     HL
                        LD      A,(HL)
                        ADD     A,B
                        DAA
                        LD      (HL),A
                        LD      A,(IY+OBJECT_COLOR)
                        LD      (TEXT_COLOR),A
                        PUSH    DE
                        PUSH    BC
                        CALL    AWARD_FOUR_HIT_BONUS
                        POP     BC
                        SET     2,(IY+OBJECT_FLAGS)    ; OBJECT_FLAG_SCORE_OVERLAY
                        LD      A,(IY+OBJECT_X_POSITION_HI)
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,(IY+OBJECT_Y_POSITION_HI)
                        SUB     $1A
                        LD      (TEXT_Y_POSITION),A
                        LD      HL,$0000
                        PUSH    HL
                        LD      HL,$3030
                        PUSH    HL
                        LD      A,B
                        CALL    PUSH_BCD_DIGITS
                        LD      HL,$0000
                        ADD     HL,SP
                        LD      A,(HL)
                        CP      $30
                        JR      NZ,draw_hit_score
                        LD      (HL),$40
draw_hit_score:         CALL    DRAW_TEXT
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        POP     HL
next_target_hit:        LD      DE,OBJECT_RECORD_SIZE
                        ADD     HL,DE
                        LD      A,L
                        CP      $64
                        JP      NZ,process_target_hit
                        POP     IY
                        POP     BC
                        JP      (IY)

;-------------------------------------------------------------------------------
; $06B5: Award and display the four-consecutive-ship-hit bonus
;-------------------------------------------------------------------------------
; HL enters at the station's accumulated BCD hit value.  The preceding byte is
; its hit count and the four bytes before that are score low/high and redraw
; state.  A miss or mine collision clears count/value in
; CLEAR_PLAYER_HIT_STREAK.  Four ship hits therefore double the BCD value of
; those four hits, reset the streak, and display BONUS plus the awarded value.
AWARD_FOUR_HIT_BONUS:
                        LD      D,(HL)
                        DEC     HL
                        LD      A,(HL)
                        CP      HIT_STREAK_LENGTH
                        RET     NZ
                        LD      (HL),$00
                        INC     HL
                        LD      (HL),$00
                        DEC     HL
                        DEC     HL
                        DEC     HL
                        DEC     HL
                        LD      A,(HL)
                        ADD     A,D
                        DAA
                        LD      (HL),A
                        INC     HL
                        LD      A,(HL)
                        ADC     A,$00
                        DAA
                        LD      (HL),A

; L is $E3 for the left score-high byte and $E8 for the right.  E preserves
; that selector while D carries the BCD bonus value.
                        LD      A,L
                        LD      E,L
                        CP      $E3
                        LD      A,$78
                        LD      HL,RIGHT_BONUS_DISPLAY_ACTIVE
                        LD      BC,RIGHT_BONUS_DISPLAY_TIMER
                        JR      NZ,bonus_station_selected
                        LD      A,$00
                        LD      HL,LEFT_BONUS_DISPLAY_ACTIVE
                        LD      BC,LEFT_BONUS_DISPLAY_TIMER
bonus_station_selected:
                        LD      (HL),BONUS_DISPLAY_ACTIVE_VALUE
                        INC     HL
                        LD      (HL),D
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,$96
                        LD      (TEXT_Y_POSITION),A
                        LD      A,BONUS_DISPLAY_DURATION
                        LD      (BC),A
                        LD      HL,TEXT_BONUS
                        CALL    DRAW_TEXT_DOUBLE_SIZE

                        LD      A,E
                        CP      $E3
                        LD      A,$82
                        JR      NZ,bonus_value_x_ready
                        LD      A,$07
bonus_value_x_ready:    LD      (TEXT_X_POSITION_HI),A
                        LD      A,$AB
                        LD      (TEXT_Y_POSITION),A
                        LD      C,D
                        LD      B,$00
                        CALL    DRAW_BCD_VALUE
                        RET

;-------------------------------------------------------------------------------
; $0711: Redraw either station score after PROCESS_SHIP_HIT changes it
;-------------------------------------------------------------------------------
; The score update clears its active-low latch.  This foreground TERSE word
; redraws the packed-BCD score once and restores the latch to $FF.
REFRESH_DIRTY_PLAYER_SCORES:
                        LD      HL,LEFT_SCORE_REDRAW_LATCH
                        LD      A,(HL)
                        OR      A
                        JR      NZ,right_score_refresh
                        LD      (HL),$FF
                        DEC     HL
                        LD      A,$07
                        LD      D,$0B
                        CALL    DRAW_SCORE_AT_STATION
right_score_refresh:    LD      HL,RIGHT_SCORE_REDRAW_LATCH
                        LD      A,(HL)
                        OR      A
                        JR      NZ,score_refresh_done
                        LD      (HL),$FF
                        DEC     HL
                        LD      A,$82
                        LD      D,$07
                        CALL    DRAW_SCORE_AT_STATION
score_refresh_done:     JP      (IY)

;-------------------------------------------------------------------------------
; $0735: Finish a patrol or award the one permitted extended patrol
;-------------------------------------------------------------------------------
; EXTENDED_PATROL_TIME_BCD is zero until an extension is awarded.  DIP bits
; 4-5 select no extension or a 5000/6000/7000-point threshold.  Either station
; can qualify.  Score words are packed BCD in 100-point units, so the compare
; thresholds are $0050, $0060, and $0070.
CHECK_PATROL_END_OR_EXTENDED_PLAY:
                        PUSH    BC
                        LD      A,(EXTENDED_PATROL_TIME_BCD)
                        OR      A
                        JR      NZ,finish_patrol
                        IN      A,(PORT_DIP_SWITCHES)
                        AND     DIP_EXTENDED_PLAY_MASK
                        JR      Z,finish_patrol
                        ADD     A,EXTENDED_SCORE_BASE_BCD
                        LD      E,A
                        LD      D,$00
                        LD      HL,(LEFT_SCORE_BCD_LO)
                        XOR     A
                        SBC     HL,DE
                        JR      NC,start_extended_patrol
                        LD      HL,(RIGHT_SCORE_BCD_LO)
                        XOR     A
                        SBC     HL,DE
                        JR      NC,start_extended_patrol

; Turn off both station lamps and empty both magazines.  The foreground keeps
; servicing active torpedoes so their collision, score, explosion, and sound
; paths finish normally.  It exits the control loop only after all eight
; torpedo records are inactive.
finish_patrol:          XOR     A
                        OUT     (PORT_LEFT_LAMPS),A
                        OUT     (PORT_RIGHT_LAMPS),A
                        LD      (LEFT_TORPEDOES_REMAINING),A
                        LD      (RIGHT_TORPEDOES_REMAINING),A
                        LD      HL,TORPEDO_POOL_BASE
                        LD      B,TORPEDO_POOL_COUNT
                        LD      DE,OBJECT_RECORD_SIZE
wait_for_torpedo_end:   BIT     7,(HL)
                        JR      NZ,patrol_end_check_done
                        ADD     HL,DE
                        DJNZ    wait_for_torpedo_end
                        LD      A,$FF
                        LD      (CONTROL_LOOP_EXIT_FLAG),A
patrol_end_check_done:  POP     BC
                        JP      (IY)

; DIP bits 1-2 select the patrol clock.  D is the two-player value and E the
; one-player value: 45/35, 35/30, 30/25, or 20/20 packed-BCD seconds.
; EXTENDED_PATROL_TIME_BCD both records the awarded duration and prevents a
; second extension.  Resetting SUPER_SUB_SPAWN_COUNT permits up to two Super
; Subs during the new patrol.
start_extended_patrol: XOR     A
                        LD      (PATROL_COMPLETE_FLAG),A
                        IN      A,(PORT_DIP_SWITCHES)
                        AND     DIP_PLAY_TIME_MASK
                        RLCA
                        LD      DE,$4535
                        JR      Z,extended_time_selected
                        LD      DE,$3530
                        CP      $04
                        JR      Z,extended_time_selected
                        LD      DE,$3025
                        CP      $08
                        JR      Z,extended_time_selected
                        LD      DE,$2020
extended_time_selected:
                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      PLAYER_COUNT_TWO
                        LD      A,D
                        JR      Z,store_extended_time
                        LD      A,E
store_extended_time:   LD      (GAME_TIME_BCD),A
                        LD      (EXTENDED_PATROL_TIME_BCD),A
                        XOR     A
                        LD      (SUPER_SUB_SPAWN_COUNT),A
                        LD      A,$BE
                        LD      (TEXT_Y_POSITION),A
                        LD      A,$28
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        LD      HL,TEXT_EXTENDED_PATROL
                        PUSH    BC
                        CALL    DRAW_TEXT
                        POP     BC
                        JP      (IY)

;-------------------------------------------------------------------------------
; $07C4: Redraw the packed-BCD game clock only when its value changes
;-------------------------------------------------------------------------------
; PUSH_BCD_DIGITS places the two ASCII digits on the stack.  They overwrite
; the "00" in the already displayed EXTENDED 00 PATROL line when an extended
; patrol is active.  Reaching zero raises PATROL_COMPLETE_FLAG before station
; reload service continues.
UPDATE_GAME_TIME_DISPLAY:
                        LD      A,(GAME_TIME_BCD)
                        LD      HL,LAST_DRAWN_GAME_TIME_BCD
                        CP      (HL)
                        JP      Z,SERVICE_STATION_RELOADS
                        LD      (HL),A
                        PUSH    AF
                        PUSH    BC
                        LD      HL,$0000
                        PUSH    HL
                        CALL    PUSH_BCD_DIGITS
                        LD      HL,$0000
                        ADD     HL,SP
                        LD      A,$BE
                        LD      (TEXT_Y_POSITION),A
                        LD      A,$4C
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        CALL    DRAW_TEXT
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        POP     BC
                        POP     AF
                        OR      A
                        JR      NZ,SERVICE_STATION_RELOADS
                        LD      A,$FF
                        LD      (PATROL_COMPLETE_FLAG),A

; Service the left station only in two-player mode; the right station is always
; present.  Each station has its own magazine byte, reload timer and lamp port.
SERVICE_STATION_RELOADS:
                        PUSH    BC
                        LD      C,PORT_LEFT_LAMPS
                        LD      DE,LEFT_RELOAD_TIMER
                        LD      HL,LEFT_TORPEDOES_REMAINING
                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      PLAYER_COUNT_TWO
                        CALL    Z,RELOAD_PLAYER_TORPEDOES_AND_ACTIVATE_MINES
                        INC     C
                        INC     DE
                        LD      HL,RIGHT_TORPEDOES_REMAINING
                        CALL    RELOAD_PLAYER_TORPEDOES_AND_ACTIVATE_MINES
                        POP     BC
                        JP      (IY)

;-------------------------------------------------------------------------------
; $0818: Reload one station and activate its score-qualified mine lanes
;-------------------------------------------------------------------------------
; HL is the station's remaining-torpedo count, DE its reload timer, and C its
; lamp port.  Once both state bytes reach zero, the magazine returns to four
; shots.  The larger player's low packed-BCD score byte controls the mine lanes:
; below $10 activates the upper lane, $10-$19 adds the middle lane, and $20+
; adds the lower lane.  These correspond to 1000- and 2000-point thresholds.
RELOAD_PLAYER_TORPEDOES_AND_ACTIVATE_MINES:
                        LD      A,(HL)
                        OR      A
                        RET     NZ
                        LD      A,(DE)
                        OR      A
                        RET     NZ
                        LD      (HL),$04
                        LD      A,$1F
                        OUT     (C),A
                        PUSH    IY
                        EXX
                        LD      A,(LEFT_SCORE_BCD_LO)
                        LD      D,A
                        LD      A,(RIGHT_SCORE_BCD_LO)
                        CP      D
                        JR      NC,mine_score_selected
                        LD      A,D
mine_score_selected:    CP      $10
                        JR      C,spawn_near_mine_lane
                        CP      $20
                        JR      C,spawn_middle_mine_lane
                        LD      HL,MINE_LANE_LOWER_BASE
                        LD      D,MINE_LANE_LOWER_Y
                        CALL    ACTIVATE_MINE_IN_LANE
spawn_middle_mine_lane: LD      HL,MINE_LANE_MIDDLE_BASE
                        LD      D,MINE_LANE_MIDDLE_Y
                        CALL    ACTIVATE_MINE_IN_LANE
spawn_near_mine_lane:   LD      HL,MINE_LANE_UPPER_BASE
                        LD      D,MINE_LANE_UPPER_Y
                        CALL    ACTIVATE_MINE_IN_LANE
                        EXX
                        POP     IY
                        RET

; HL addresses the first of two records in one mine lane; D is the fixed Y
; coordinate.  Allocate the first inactive record and stagger its X coordinate
; from the other mine in the lane.  Mines use expand/replace with set pixels
; mapped to color 3.  Inactive OBJECT_TIMER does not gate reuse;
; CLEAR_OBJECT_RECORD removes all prior collision/animation state.
ACTIVATE_MINE_IN_LANE:  BIT     7,(HL)
                        JR      NZ,try_second_mine_slot
                        PUSH    HL
                        POP     IY
                        CALL    CLEAR_OBJECT_RECORD
                        LD      A,(IY+$28)             ; second record X position
                        ADD     A,$1E
                        JP      set_new_mine_position
try_second_mine_slot:   LD      BC,OBJECT_RECORD_SIZE
                        ADD     HL,BC
                        BIT     7,(HL)
                        RET     NZ
                        PUSH    HL
                        POP     IY
                        CALL    CLEAR_OBJECT_RECORD
                        LD      A,(IY-$0A)             ; first record X position
set_new_mine_position:  ADD     A,$50
                        CP      $A0
                        JR      C,mine_x_ready
                        SUB     $A0
mine_x_ready:           LD      (IY+OBJECT_X_POSITION_HI),A
                        LD      (IY+OBJECT_Y_POSITION_HI),D
                        LD      (IY+OBJECT_TYPE),OBJECT_TYPE_MINE
                        LD      (IY+OBJECT_X_VELOCITY_LO),$80
                        LD      (IY+OBJECT_X_MAX),$A0
                        LD      (IY+OBJECT_FUNCGEN_CONTROL),FUNCGEN_MODE_EXPAND
                        LD      (IY+OBJECT_COLOR),EXPAND_COLORS_0_3
                        LD      (IY+OBJECT_FLAGS),OBJECT_FLAG_ACTIVE
                        RET

; Zero one complete object record.  HL returns one byte past the record.
CLEAR_OBJECT_RECORD:    LD      B,OBJECT_RECORD_SIZE
                        XOR     A
clear_object_byte:      LD      (HL),A
                        INC     HL
                        DJNZ    clear_object_byte
                        RET
;-------------------------------------------------------------------------------
; $08A7: Populate the two moving-target lanes
;-------------------------------------------------------------------------------
ACTIVATE_TARGET_LANES:  PUSH    IY
                        EXX
                        LD      HL,TARGET_POOL_BASE
                        CALL    ACTIVATE_TARGET_IN_LANE
                        LD      HL,TARGET_LANE_LOWER_BASE
                        CALL    ACTIVATE_TARGET_IN_LANE
                        POP     IY
                        EXX
                        JP      (IY)

; HL addresses the first record in a two-record target lane.  The second target
; is launched only after the first has crossed X=$80 moving right or X=$20
; moving left.  An inactive first record is reused immediately; its scheduler-
; decayed OBJECT_TIMER is not an allocation condition.
ACTIVATE_TARGET_IN_LANE:
                        PUSH    HL
                        POP     IY
                        BIT     7,(IY+OBJECT_RECORD_SIZE)
                        RET     NZ
                        BIT     7,(HL)
                        JR      NZ,derive_target_direction
                        LD      A,R
                        RRCA
                        JR      target_slot_selected
derive_target_direction:
                        LD      A,(IY+OBJECT_X_VELOCITY_HI)
                        RLA
                        LD      A,(IY+OBJECT_X_POSITION_HI)
                        JR      C,target_moving_left
                        CP      $80
                        RET     C
                        OR      A                       ; carry clear: move right
                        JR      allocate_second_target
target_moving_left:     CP      $20
                        RET     NC
                        SCF                             ; carry set: move left
allocate_second_target:
                        PUSH    AF
                        LD      DE,OBJECT_RECORD_SIZE
                        ADD     HL,DE
                        PUSH    HL
                        POP     IY
                        POP     AF
target_slot_selected:   PUSH    AF
                        CALL    CLEAR_OBJECT_RECORD
; Port $19 maps clear source bits to color 0.  The random carry selects color
; 1 or 2 for set target pixels.
                        LD      A,R
                        RRA
                        LD      A,EXPAND_COLORS_0_1
                        JR      C,target_color_ready
                        LD      A,EXPAND_COLORS_0_2
target_color_ready:     LD      (IY+OBJECT_COLOR),A
                        LD      A,L
                        CP      TARGET_LANE_LOWER_Y
                        LD      A,TARGET_LANE_UPPER_Y
                        JR      C,target_lane_y_ready
                        LD      A,TARGET_LANE_LOWER_Y
target_lane_y_ready:    LD      (IY+OBJECT_Y_POSITION_HI),A

; TARGET_TYPE_SEQUENCE supplies the six surface targets.  FREIGHTER_A entries
; can be replaced by the 1000-point Super Sub while its progression counter is
; below two and fewer than 24 BCD seconds remain.
                        LD      HL,(TARGET_TYPE_SEQUENCE_CURSOR)
                        LD      B,(HL)
                        INC     HL
                        LD      A,(HL)
                        CP      $FF
                        JR      NZ,target_sequence_ready
                        LD      HL,TARGET_TYPE_SEQUENCE
target_sequence_ready:  LD      (TARGET_TYPE_SEQUENCE_CURSOR),HL
                        LD      A,B
                        CP      OBJECT_TYPE_FREIGHTER_A
                        JR      NZ,target_type_ready
                        LD      A,(GAME_TIME_BCD)
                        CP      $24
                        LD      A,OBJECT_TYPE_FREIGHTER_A
                        JR      NC,target_type_ready
                        LD      A,(SUPER_SUB_SPAWN_COUNT)
                        CP      $02
                        JR      Z,target_type_ready
                        INC     A
                        LD      (SUPER_SUB_SPAWN_COUNT),A
                        CALL    SHOW_SUPER_SUB_ANNOUNCEMENT
                        LD      A,OBJECT_TYPE_SUPER_SUB
target_type_ready:      LD      (IY+OBJECT_TYPE),A
                        LD      (IY+OBJECT_FUNCGEN_CONTROL),FUNCGEN_MODE_EXPAND

; Convert the type's signed byte speed to 8.8 fixed point by multiplying by
; four.  Carry saved on entry selects leftward or rightward travel.
                        LD      HL,TARGET_SPEED_TABLE
                        LD      E,A
                        LD      D,$00
                        ADD     HL,DE
                        LD      A,(HL)
                        LD      E,$00
                        SLA     A
                        RL      E
                        SLA     A
                        RL      E
                        LD      (IY+OBJECT_X_VELOCITY_LO),A
                        LD      (IY+OBJECT_X_VELOCITY_HI),E
                        LD      A,(IY+OBJECT_TYPE)
                        CP      OBJECT_TYPE_PT_BOAT
                        LD      A,$8E
                        JR      NZ,target_right_limit_ready
                        LD      A,$9A
target_right_limit_ready:
                        LD      (IY+OBJECT_X_MAX),A
                        POP     AF
                        JR      NC,target_direction_ready
                        LD      (IY+OBJECT_X_MAX),$A0
; Left-moving targets set Function Generator flop.  The renderer also walks
; destination addresses backward, producing a complete horizontal mirror.
                        SET     FUNCGEN_FLOP_BIT,(IY+OBJECT_FUNCGEN_CONTROL)
                        LD      B,(IY+OBJECT_X_VELOCITY_HI)
                        LD      A,(IY+OBJECT_X_VELOCITY_LO)
                        CPL
                        LD      C,A
                        LD      A,B
                        CPL
                        LD      B,A
                        INC     BC
                        LD      (IY+OBJECT_X_VELOCITY_LO),C
                        LD      (IY+OBJECT_X_VELOCITY_HI),B
                        LD      A,(IY+OBJECT_TYPE)
                        CP      OBJECT_TYPE_PT_BOAT
                        LD      A,$96
                        JR      Z,target_left_start_ready
                        LD      A,$8C
target_left_start_ready:
                        LD      (IY+OBJECT_X_POSITION_HI),A
target_direction_ready: LD      A,(IY+OBJECT_TYPE)
                        CP      OBJECT_TYPE_PT_BOAT
                        JR      C,target_sound_done
                        CP      OBJECT_TYPE_SUPER_SUB
                        JR      NZ,START_SONAR_SEQUENCE

; The Super Sub begins the dive effect.  Function Generator flop is also the
; persistent left/right direction flag used to orient the pan sweep.  $F0
; supplies both the descending three-bit pan code and the first port-$41 bit-3
; trigger edge.
START_DIVE_SOUND:
                        LD      A,$F0
                        LD      (SOUND_DIVE_PAN_TIMER),A
                        BIT     FUNCGEN_FLOP_BIT,(IY+OBJECT_FUNCGEN_CONTROL)
                        LD      A,$87
                        JR      Z,dive_pan_selected
                        LD      A,$80
dive_pan_selected:      LD      (SOUND_DIVE_PAN_XOR),A
                        LD      (IY+OBJECT_COLOR),EXPAND_COLORS_0_3
                        JR      target_sound_done

; The PT Boat asserts one left pulse immediately, then seeds ten scheduled
; pulses.  The first scheduled pulse is also left; the remaining pulses
; alternate right/left as SONAR_CADENCE_TIMER enters its final seven counts.
START_SONAR_SEQUENCE:   LD      A,$14
                        LD      (SONAR_CADENCE_TIMER),A
TRIGGER_INITIAL_LEFT_SONAR:
                        LD      A,$05
                        LD      (SOUND_LEFT_SONAR_TIMER),A
                        LD      A,$0A
                        LD      (SONAR_PING_COUNT),A
target_sound_done:      LD      (IY+OBJECT_FLAGS),OBJECT_FLAG_ACTIVE
                        RET

;-------------------------------------------------------------------------------
; $09C1: Poll both stations and create a torpedo on a fire-button edge
;-------------------------------------------------------------------------------
POLL_TORPEDO_FIRE:
                        PUSH    BC
                        PUSH    IY
                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      PLAYER_COUNT_TWO
                        JR      NZ,poll_right_torpedo
                        LD      C,PORT_LEFT_STATION_HANDLE
                        LD      DE,LEFT_RELOAD_TIMER
                        LD      HL,LEFT_TORPEDOES_REMAINING
                        LD      IY,TORPEDO_POOL_LEFT_BASE
                        CALL    UPDATE_PLAYER_TORPEDO_FIRE
poll_right_torpedo:     LD      C,PORT_RIGHT_STATION_HANDLE
                        LD      DE,RIGHT_RELOAD_TIMER
                        LD      HL,RIGHT_TORPEDOES_REMAINING
                        LD      IY,TORPEDO_POOL_RIGHT_BASE
                        CALL    UPDATE_PLAYER_TORPEDO_FIRE
                        POP     IY
                        POP     BC
                        JP      (IY)

; C = handle/fire input port; DE = reload timer; HL = player fire state;
; IY = first torpedo object for the station.
; A four-shot magazine allocates station slots in order 3, 2, 1, 0.  Since
; station records are $32 bytes apart, left/right records remain interleaved in
; the global eight-record scheduler pool.
UPDATE_PLAYER_TORPEDO_FIRE:
                        LD      A,(HL)
                        OR      A
                        RET     Z
                        DEC     HL
                        IN      A,(C)
                        AND     HANDLE_FIRE_MASK
                        CP      (HL)
                        RET     Z
                        LD      (HL),A
                        OR      A
                        RET     Z
                        LD      A,HANDLE_FIRE_MASK
                        LD      (SOUND_DIVE_PAN_XOR),A
                        INC     HL
                        DEC     (HL)
                        JR      NZ,torpedo_slot_available
                        LD      A,$A0
                        LD      (DE),A
                        XOR     A
                        JR      torpedo_slot_selected
torpedo_slot_available: LD      B,(HL)
                        XOR     A
torpedo_slot_mask:      SCF
                        RLA
                        DJNZ    torpedo_slot_mask
                        OR      $10
torpedo_slot_selected:  INC     HL
                        LD      (HL),A
                        DEC     HL
                        LD      B,A
                        LD      D,C
                        LD      A,C
                        ADD     A,$32
                        LD      C,A
                        OUT     (C),B
                        LD      C,D
                        LD      A,(HL)
                        OR      A
                        LD      HL,$0000
                        JR      Z,torpedo_record_selected
                        LD      DE,TORPEDO_STATION_STRIDE
torpedo_record_offset:  ADD     HL,DE
                        DEC     A
                        JR      NZ,torpedo_record_offset
torpedo_record_selected:
                        PUSH    IY
                        POP     DE
                        ADD     HL,DE
                        PUSH    HL
                        POP     IY
                        CALL    INITIALIZE_TORPEDO_OBJECT
                        IN      A,(C)
                        CALL    DECODE_HANDLE_POSITION
                        SUB     TORPEDO_AIM_HANDLE_BASE
                        JR      NC,torpedo_aim_nonnegative
                        LD      A,$00
torpedo_aim_nonnegative:
                        ADD     A,A
                        CP      TORPEDO_TRAJECTORY_TABLE_BYTES
                        JR      C,torpedo_aim_in_range
                        LD      A,TORPEDO_TRAJECTORY_LAST_OFFSET
torpedo_aim_in_range:   AND     TORPEDO_TRAJECTORY_LAST_OFFSET
                        LD      HL,TORPEDO_TRAJECTORY_LEFT_TABLE
                        BIT     STATION_PORT_PARITY_BIT,C
                        JR      Z,torpedo_trajectory_table
                        LD      HL,TORPEDO_TRAJECTORY_RIGHT_TABLE
torpedo_trajectory_table:
                        LD      E,A
                        LD      D,$00
                        ADD     HL,DE
                        LD      A,(HL)
                        LD      (IY+OBJECT_X_POSITION_HI),A
                        INC     HL
                        LD      A,(HL)
                        LD      (IY+OBJECT_X_VELOCITY_LO),A
                        RLCA
                        JR      NC,torpedo_velocity_ready
                        LD      (IY+OBJECT_X_VELOCITY_HI),$FF
torpedo_velocity_ready: LD      (IY+OBJECT_FLAGS),OBJECT_FLAG_ACTIVE

; Port $10 is the left station and port $11 is the right station in the sound
; wiring.  A new torpedo holds its corresponding trigger high for $38 frames.
TRIGGER_TORPEDO_SOUND:
                        BIT     STATION_PORT_PARITY_BIT,C
                        LD      HL,SOUND_LEFT_TORPEDO_TIMER
                        JR      Z,torpedo_sound_selected
                        LD      HL,SOUND_RIGHT_TORPEDO_TIMER
torpedo_sound_selected: LD      (HL),TORPEDO_SOUND_TIMER_LOAD
                        RET

INITIALIZE_TORPEDO_OBJECT:
; Gameplay torpedoes start at Y=$BB00 with velocity -$0400 and acceleration
; +$000C.  The decoded handle selects initial X and signed X velocity from the
; station-specific 32-entry trajectory table.  Left torpedoes expand set bits
; to color 2; right torpedoes use color 1.
                        CALL    CLEAR_OBJECT_RECORD
                        LD      (IY+OBJECT_TYPE),OBJECT_TYPE_TORPEDO
                        LD      (IY+OBJECT_Y_ACCEL_LO),$0C
                        LD      (IY+OBJECT_Y_VELOCITY_HI),$FC
                        LD      (IY+OBJECT_Y_POSITION_HI),$BB
                        LD      (IY+OBJECT_Y_MIN),$23
                        LD      (IY+OBJECT_X_MAX),$9C
                        LD      (IY+OBJECT_FUNCGEN_CONTROL),FUNCGEN_MODE_EXPAND
                        LD      (IY+OBJECT_BITMAP_PTR_HI),BITMAP_TORPEDO_NEAR_HI
                        LD      (IY+OBJECT_BITMAP_PTR_LO),BITMAP_TORPEDO_NEAR_LO
                        LD      A,EXPAND_COLORS_0_2
                        BIT     STATION_PORT_PARITY_BIT,C
                        JR      Z,torpedo_color_selected
                        LD      A,EXPAND_COLORS_0_1
torpedo_color_selected: LD      (IY+OBJECT_COLOR),A
                        RET

DECODE_HANDLE_POSITION:
                        PUSH    BC
                        PUSH    DE
                        AND     RAW_HANDLE_POSITION_MASK
                        LD      C,A
                        LD      B,A
                        LD      D,$20
decode_handle_bit:      LD      A,C
                        AND     D
                        LD      E,A
                        LD      A,B
                        SRL     A
                        AND     D
                        XOR     E
                        LD      E,A
                        LD      A,D
                        CPL
                        AND     B
                        OR      E
                        LD      B,A
                        SRL     D
                        JR      NZ,decode_handle_bit
                        LD      A,B
                        POP     DE
                        POP     BC
                        RET
                        SCF                             ; $0ACA, unreachable pad

;-------------------------------------------------------------------------------
; $0ACB: Alternate sonar between speakers while the sequence remains active
;-------------------------------------------------------------------------------
UPDATE_SONAR_SEQUENCE:
                        LD      HL,SONAR_CADENCE_TIMER
                        LD      A,(HL)
                        OR      A
                        JR      Z,sonar_update_done
                        CP      $08
                        JR      NC,sonar_update_done
                        LD      DE,SONAR_PING_COUNT
                        LD      A,(DE)
                        OR      A
                        JR      Z,sonar_update_done
                        DEC     A
                        LD      (DE),A
                        RRA
                        JR      C,TRIGGER_LEFT_SONAR
TRIGGER_RIGHT_SONAR:    LD      A,$04
                        LD      (SOUND_RIGHT_SONAR_TIMER),A
                        LD      (HL),$20
                        JR      sonar_update_done
TRIGGER_LEFT_SONAR:     LD      A,$04
                        LD      (SOUND_LEFT_SONAR_TIMER),A
                        LD      (HL),$10
sonar_update_done:      JP      (IY)
;-------------------------------------------------------------------------------
; $0AF4: Retire target-hit score overlays after the explosion advances
;-------------------------------------------------------------------------------
; PROCESS_SHIP_HIT sets bit 2 after drawing a score beside the struck target.
; The overlay is removed on frame 3 for ordinary targets and frame 5 for the
; Super Sub, then the owning station's saved lamp state is restored.
ERASE_EXPIRED_HIT_SCORES:
                        PUSH    BC
                        PUSH    IY
                        LD      IY,TARGET_POOL_BASE
                        LD      DE,OBJECT_RECORD_SIZE
                        LD      B,TARGET_POOL_COUNT
erase_hit_score_loop:   BIT     2,(IY+OBJECT_FLAGS)   ; OBJECT_FLAG_SCORE_OVERLAY
                        JR      Z,next_hit_score_record
                        LD      A,(IY+OBJECT_TYPE)
                        CP      OBJECT_TYPE_SUPER_SUB
                        LD      A,$04
                        JR      Z,hit_score_frame_limit_ready
                        LD      A,$02
hit_score_frame_limit_ready:
                        CP      (IY+OBJECT_ANIMATION_FRAME)
                        JR      NC,next_hit_score_record
                        RES     2,(IY+OBJECT_FLAGS)    ; OBJECT_FLAG_SCORE_OVERLAY
                        PUSH    BC
                        PUSH    DE
                        LD      A,(IY+OBJECT_X_POSITION_HI)
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,(IY+OBJECT_Y_POSITION_HI)
                        SUB     $1A
                        LD      (TEXT_Y_POSITION),A
                        XOR     A
                        LD      (TEXT_COLOR),A
                        LD      HL,TEXT_BLANK_HIT_SCORE
                        CALL    DRAW_TEXT
                        BIT     OBJECT_FLAG_HIT_SIDE_BIT,(IY+OBJECT_FLAGS)
                        LD      A,(RIGHT_LAMP_STATE)
                        LD      C,PORT_RIGHT_LAMPS
                        JR      Z,restore_hit_lamps
                        LD      A,(LEFT_LAMP_STATE)
                        LD      C,PORT_LEFT_LAMPS
restore_hit_lamps:      OUT     (C),A
                        POP     DE
                        POP     BC
next_hit_score_record:  ADD     IY,DE
                        DJNZ    erase_hit_score_loop

; The four-hit bonus is a timed overlay independent of the per-target score
; overlay above.  Expired panels are cleared before any active left/right
; BONUS label and BCD value are redrawn.
UPDATE_BONUS_DISPLAYS:
                        LD      HL,RIGHT_BONUS_DISPLAY_ACTIVE
                        LD      DE,RIGHT_BONUS_DISPLAY_TIMER
                        LD      BC,$6F1C               ; right panel VRAM origin
                        CALL    CLEAR_EXPIRED_BONUS_PANEL
                        LD      HL,LEFT_BONUS_DISPLAY_ACTIVE
                        LD      DE,LEFT_BONUS_DISPLAY_TIMER
                        LD      BC,$6EE0               ; left panel VRAM origin
                        CALL    CLEAR_EXPIRED_BONUS_PANEL

                        LD      A,$96
                        LD      (TEXT_Y_POSITION),A
                        LD      A,$00
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,EXPAND_COLORS_0_2
                        LD      (TEXT_COLOR),A
                        LD      HL,TEXT_BONUS
                        LD      A,(LEFT_BONUS_DISPLAY_ACTIVE)
                        OR      A
                        CALL    NZ,DRAW_TEXT_DOUBLE_SIZE

                        LD      A,$78
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,EXPAND_COLORS_0_1
                        LD      (TEXT_COLOR),A
                        LD      HL,TEXT_BONUS
                        LD      A,(RIGHT_BONUS_DISPLAY_ACTIVE)
                        OR      A
                        CALL    NZ,DRAW_TEXT_DOUBLE_SIZE

                        LD      A,$AB
                        LD      (TEXT_Y_POSITION),A
                        LD      A,$82
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,(RIGHT_BONUS_DISPLAY_VALUE_BCD)
                        LD      C,A
                        LD      B,$00
                        LD      A,(RIGHT_BONUS_DISPLAY_ACTIVE)
                        OR      A
                        CALL    NZ,DRAW_BCD_VALUE

                        LD      A,EXPAND_COLORS_0_2
                        LD      (TEXT_COLOR),A
                        LD      A,$07
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,(LEFT_BONUS_DISPLAY_VALUE_BCD)
                        LD      C,A
                        LD      B,$00
                        LD      A,(LEFT_BONUS_DISPLAY_ACTIVE)
                        OR      A
                        CALL    NZ,DRAW_BCD_VALUE
                        POP     IY
                        POP     BC
                        JP      (IY)

; HL = active flag, DE = frame timer, BC = top-left VRAM address.  The panel is
; 20 bytes wide by 32 rows.  The $003C stride plus the 20 cleared bytes advances
; exactly one 80-byte video row.
CLEAR_EXPIRED_BONUS_PANEL:
                        LD      A,(HL)
                        OR      A
                        RET     Z
                        LD      A,(DE)
                        OR      A
                        RET     NZ
                        LD      (HL),$00
                        LD      H,B
                        LD      L,C
                        LD      DE,$003C
                        XOR     A
                        LD      C,$20
clear_bonus_panel_row:  LD      B,$14
clear_bonus_panel_byte: LD      (HL),A
                        INC     HL
                        DJNZ    clear_bonus_panel_byte
                        ADD     HL,DE
                        DEC     C
                        JR      NZ,clear_bonus_panel_row
                        RET

;-------------------------------------------------------------------------------
; $0BDF: Seed the target and interleaved torpedo pools from ROM templates
;-------------------------------------------------------------------------------
; Records 0 and 2 of the four-record target pool receive distinct templates;
; records 1 and 3 remain available as their trailing lane partners.  The next
; two templates initialize the first left/right torpedo records at $C0FA/$C113.
; This TERSE word runs in the no-player control path; gameplay fire events use
; INITIALIZE_TORPEDO_OBJECT instead.
INITIALIZE_OBJECT_POOLS:
                        LD      A,(TARGET_POOL_BASE+OBJECT_FLAGS)
                        BIT     7,A
                        JR      NZ,object_pools_ready
                        LD      A,(TARGET_LANE_LOWER_BASE+OBJECT_FLAGS)
                        BIT     7,A
                        JR      NZ,object_pools_ready
                        PUSH    BC
                        LD      HL,OBJECT_INITIAL_TEMPLATES
                        LD      DE,TARGET_POOL_BASE
                        LD      BC,OBJECT_RECORD_SIZE
                        PUSH    BC
                        LDIR
                        POP     BC
                        EX      DE,HL
                        ADD     HL,BC                   ; leave target record 1 free
                        EX      DE,HL
                        PUSH    BC
                        LDIR
                        POP     BC
                        LD      DE,TORPEDO_POOL_BASE
                        SLA     C                       ; two adjacent templates
                        LDIR
                        LD      A,OBJECT_FLAG_ACTIVE
                        LD      (TARGET_POOL_BASE+OBJECT_FLAGS),A
                        LD      (TARGET_LANE_LOWER_BASE+OBJECT_FLAGS),A
                        LD      (TORPEDO_POOL_LEFT_BASE+OBJECT_FLAGS),A
                        LD      (TORPEDO_POOL_RIGHT_BASE+OBJECT_FLAGS),A
                        POP     BC
object_pools_ready:     JP      (IY)

;-------------------------------------------------------------------------------
; $0C1A: Blink the localized congratulations message after a high score
;-------------------------------------------------------------------------------
; The no-player control path calls this continuously.  C1CC normally times the
; right-station reload, but is free here; interrupt decay turns its $1E reload
; into a 30-frame blink cadence.  Alternating TEXT_COLOR between $0C and $00
; draws and erases the same text in place.
UPDATE_NEW_HIGH_SCORE_MESSAGE:
                        PUSH    BC
                        LD      A,(NEW_HIGH_SCORE_FLAG)
                        OR      A
                        JR      Z,new_high_score_message_done
                        LD      HL,NEW_HIGH_SCORE_BLINK_TIMER
                        LD      A,(HL)
                        OR      A
                        JR      NZ,new_high_score_message_done
                        LD      (HL),NEW_HIGH_SCORE_BLINK_PERIOD
                        LD      A,$02
                        LD      (TEXT_Y_POSITION),A
                        LD      A,$0A
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,(TEXT_COLOR)
                        XOR     EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        LD      HL,TEXT_CONGRATULATIONS_EN
                        LD      A,(LANGUAGE_SELECTION)
                        CP      $00
                        JR      Z,draw_new_high_score_message
                        LD      HL,TEXT_CONGRATULATIONS_DE
                        CP      $01
                        JR      Z,draw_new_high_score_message
                        LD      HL,TEXT_CONGRATULATIONS_FR
draw_new_high_score_message:
                        CALL    DRAW_TEXT
new_high_score_message_done:
                        POP     BC
                        JP      (IY)

; $C1D6 is adjacent to the sound timers but drives port-$41 bit 6, the coin
; counter output.  Each queued coin produces a ten-frame hardware pulse.
PULSE_COIN_COUNTER:
                        LD      DE,COIN_COUNTER_PULSE_TIMER
                        LD      A,(DE)
                        OR      A
                        JR      NZ,coin_counter_done
                        LD      HL,COIN_INPUT_QUEUE
                        LD      A,(HL)
                        OR      A
                        JR      Z,coin_counter_done
                        DEC     (HL)
                        LD      A,$0A
                        LD      (DE),A
                        LD      HL,CREDIT_COUNT
                        INC     (HL)
coin_counter_done:      JP      (IY)

;-------------------------------------------------------------------------------
; $0C6E: TERSE text word with five inline operands
;-------------------------------------------------------------------------------
; Inline layout: text pointer, Y high byte, X high byte, size flag.  A zero
; flag uses the ordinary renderer; nonzero selects the double-size renderer.
TERSE_DRAW_TEXT_INLINE:
                        LD      A,(BC)
                        INC     BC
                        LD      E,A
                        LD      A,(BC)
                        INC     BC
                        LD      D,A
                        LD      A,(BC)
                        INC     BC
                        LD      H,A
                        LD      L,$00
                        LD      (TEXT_Y_POSITION_LO),HL
                        LD      A,(BC)
                        INC     BC
                        LD      H,A
                        LD      (TEXT_X_POSITION_LO),HL
                        LD      A,EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        EX      DE,HL
                        LD      A,(BC)
                        INC     BC
                        OR      A
                        PUSH    BC
                        JR      NZ,draw_inline_text_double_size
                        CALL    DRAW_TEXT
                        JR      inline_text_done
draw_inline_text_double_size:
                        CALL    DRAW_TEXT_DOUBLE_SIZE
inline_text_done:       POP     BC
                        JP      (IY)

; TERSE wrapper used by the game-state thread to redraw the high score.
DRAW_HIGH_SCORE_WORD:   PUSH    BC
                        CALL    DRAW_HIGH_SCORE
                        POP     BC
                        JP      (IY)

DRAW_HIGH_SCORE:        LD      HL,HIGH_SCORE_BCD_HI
                        LD      A,$76
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,$02
                        LD      D,$0C
                        JR      draw_score_at_fixed_position

; BC is a two-byte packed-BCD value.  Position and color are already set.
DRAW_BCD_VALUE:         PUSH    BC
                        JR      format_and_draw_score

; HL addresses the high BCD byte.  A is X and D is color; scores use Y=$BE.
DRAW_SCORE_AT_STATION:  LD      (TEXT_X_POSITION_HI),A
                        LD      A,$BE
draw_score_at_fixed_position:
                        LD      (TEXT_Y_POSITION),A
                        LD      A,D
                        LD      (TEXT_COLOR),A
                        PUSH    BC
                        LD      B,(HL)
                        DEC     HL
                        LD      C,(HL)

; Build four ASCII digits plus a zero terminator on the native stack.  Leading
; zeroes become spaces before DRAW_TEXT consumes the temporary string.
format_and_draw_score:  LD      HL,$0000
                        PUSH    HL
                        LD      HL,$3030
                        PUSH    HL
                        LD      A,C
                        CALL    PUSH_BCD_DIGITS
                        LD      A,B
                        CALL    PUSH_BCD_DIGITS
                        LD      HL,$0000
                        ADD     HL,SP
                        PUSH    HL
                        LD      BC,$0440               ; four digits, space $40
                        LD      A,$30
blank_leading_zero:     CP      (HL)
                        JR      NZ,draw_formatted_score
                        LD      (HL),C
                        INC     HL
                        DJNZ    blank_leading_zero
draw_formatted_score:   POP     HL
                        CALL    DRAW_TEXT
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        INC     SP
                        POP     BC
                        RET

; Replace the CALL return word on the stack with two ASCII digits, then jump
; through the displaced return address.  The high nibble is emitted first.
PUSH_BCD_DIGITS:        LD      D,A
                        RRA
                        RRA
                        RRA
                        RRA
                        AND     $0F
                        OR      $30
                        LD      L,A
                        LD      A,D
                        AND     $0F
                        OR      $30
                        LD      H,A
                        EX      (SP),HL
                        JP      (HL)

;-------------------------------------------------------------------------------
; $0D02: Suspend object service and present the Super Sub warning
;-------------------------------------------------------------------------------
; Displays TEXT_SUPER and TEXT_SUB, waits $40 interrupts, clears the warning
; rectangle, then releases SOUND_FRAME_DIVIDER so object service resumes.  The
; lightweight raster interrupts continue while the frame object workload is
; held.
SHOW_SUPER_SUB_ANNOUNCEMENT:
                        LD      A,$01
                        LD      (SOUND_FRAME_DIVIDER),A
                        LD      A,$3C
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,$4B
                        LD      (TEXT_Y_POSITION),A
                        LD      A,EXPAND_COLORS_0_3
                        LD      (TEXT_COLOR),A
                        LD      HL,TEXT_SUPER
                        CALL    DRAW_TEXT_DOUBLE_SIZE
                        LD      A,$44
                        LD      (TEXT_X_POSITION_HI),A
                        LD      A,$69
                        LD      (TEXT_Y_POSITION),A
                        LD      HL,TEXT_SUB
                        CALL    DRAW_TEXT_DOUBLE_SIZE
                        LD      B,$40
super_sub_message_hold: HALT
                        DJNZ    super_sub_message_hold

; Clear the 20-byte by 50-row announcement rectangle.  Row stride is $50.
                        LD      HL,$578E
                        LD      DE,$003C
                        XOR     A
                        LD      C,$32
clear_super_sub_row:    LD      B,$14
clear_super_sub_byte:   LD      (HL),A
                        INC     HL
                        DJNZ    clear_super_sub_byte
                        ADD     HL,DE
                        DEC     C
                        JR      NZ,clear_super_sub_row
                        LD      (SOUND_FRAME_DIVIDER),A
                        RET

;-------------------------------------------------------------------------------
; $0D48-$0DC7: Station torpedo launch X/velocity tables
;-------------------------------------------------------------------------------
; FIRE_TORPEDO decodes the six-bit handle, subtracts $12, clamps the result to
; 0-$1F, and doubles it to select one two-byte entry.  Byte 0 is the initial
; X coordinate.  Byte 1 is sign-extended into the low byte of signed 8.8 X
; velocity.  Handle values below $12 use entry 0; values above $31 use entry 31.

TORPEDO_TRAJECTORY_LEFT_TABLE:
TORPEDO_TRAJECTORY_LEFT_00:
                        DB      $90,$70                 ; index $00, handle $12, X=$90, dX=$0070
TORPEDO_TRAJECTORY_LEFT_01:
                        DB      $8A,$6D                 ; index $01, handle $13, X=$8A, dX=$006D
TORPEDO_TRAJECTORY_LEFT_02:
                        DB      $85,$6A                 ; index $02, handle $14, X=$85, dX=$006A
TORPEDO_TRAJECTORY_LEFT_03:
                        DB      $7F,$67                 ; index $03, handle $15, X=$7F, dX=$0067
TORPEDO_TRAJECTORY_LEFT_04:
                        DB      $7A,$64                 ; index $04, handle $16, X=$7A, dX=$0064
TORPEDO_TRAJECTORY_LEFT_05:
                        DB      $75,$61                 ; index $05, handle $17, X=$75, dX=$0061
TORPEDO_TRAJECTORY_LEFT_06:
                        DB      $6F,$5E                 ; index $06, handle $18, X=$6F, dX=$005E
TORPEDO_TRAJECTORY_LEFT_07:
                        DB      $6A,$5B                 ; index $07, handle $19, X=$6A, dX=$005B
TORPEDO_TRAJECTORY_LEFT_08:
                        DB      $65,$58                 ; index $08, handle $1A, X=$65, dX=$0058
TORPEDO_TRAJECTORY_LEFT_09:
                        DB      $61,$55                 ; index $09, handle $1B, X=$61, dX=$0055
TORPEDO_TRAJECTORY_LEFT_10:
                        DB      $5C,$52                 ; index $0A, handle $1C, X=$5C, dX=$0052
TORPEDO_TRAJECTORY_LEFT_11:
                        DB      $57,$4F                 ; index $0B, handle $1D, X=$57, dX=$004F
TORPEDO_TRAJECTORY_LEFT_12:
                        DB      $52,$4C                 ; index $0C, handle $1E, X=$52, dX=$004C
TORPEDO_TRAJECTORY_LEFT_13:
                        DB      $4E,$49                 ; index $0D, handle $1F, X=$4E, dX=$0049
TORPEDO_TRAJECTORY_LEFT_14:
                        DB      $49,$46                 ; index $0E, handle $20, X=$49, dX=$0046
TORPEDO_TRAJECTORY_LEFT_15:
                        DB      $44,$43                 ; index $0F, handle $21, X=$44, dX=$0043
TORPEDO_TRAJECTORY_LEFT_16:
                        DB      $40,$40                 ; index $10, handle $22, X=$40, dX=$0040
TORPEDO_TRAJECTORY_LEFT_17:
                        DB      $3B,$3D                 ; index $11, handle $23, X=$3B, dX=$003D
TORPEDO_TRAJECTORY_LEFT_18:
                        DB      $37,$3A                 ; index $12, handle $24, X=$37, dX=$003A
TORPEDO_TRAJECTORY_LEFT_19:
                        DB      $33,$37                 ; index $13, handle $25, X=$33, dX=$0037
TORPEDO_TRAJECTORY_LEFT_20:
                        DB      $2E,$34                 ; index $14, handle $26, X=$2E, dX=$0034
TORPEDO_TRAJECTORY_LEFT_21:
                        DB      $2A,$31                 ; index $15, handle $27, X=$2A, dX=$0031
TORPEDO_TRAJECTORY_LEFT_22:
                        DB      $26,$2E                 ; index $16, handle $28, X=$26, dX=$002E
TORPEDO_TRAJECTORY_LEFT_23:
                        DB      $21,$2B                 ; index $17, handle $29, X=$21, dX=$002B
TORPEDO_TRAJECTORY_LEFT_24:
                        DB      $1D,$28                 ; index $18, handle $2A, X=$1D, dX=$0028
TORPEDO_TRAJECTORY_LEFT_25:
                        DB      $19,$25                 ; index $19, handle $2B, X=$19, dX=$0025
TORPEDO_TRAJECTORY_LEFT_26:
                        DB      $15,$22                 ; index $1A, handle $2C, X=$15, dX=$0022
TORPEDO_TRAJECTORY_LEFT_27:
                        DB      $10,$1F                 ; index $1B, handle $2D, X=$10, dX=$001F
TORPEDO_TRAJECTORY_LEFT_28:
                        DB      $0D,$1C                 ; index $1C, handle $2E, X=$0D, dX=$001C
TORPEDO_TRAJECTORY_LEFT_29:
                        DB      $08,$19                 ; index $1D, handle $2F, X=$08, dX=$0019
TORPEDO_TRAJECTORY_LEFT_30:
                        DB      $04,$16                 ; index $1E, handle $30, X=$04, dX=$0016
TORPEDO_TRAJECTORY_LEFT_31:
                        DB      $00,$13                 ; index $1F, handle $31, X=$00, dX=$0013

TORPEDO_TRAJECTORY_RIGHT_TABLE:
TORPEDO_TRAJECTORY_RIGHT_00:
                        DB      $9B,$00                 ; index $00, handle $12, X=$9B, dX=$0000
TORPEDO_TRAJECTORY_RIGHT_01:
                        DB      $96,$FD                 ; index $01, handle $13, X=$96, dX=$FFFD
TORPEDO_TRAJECTORY_RIGHT_02:
                        DB      $92,$FA                 ; index $02, handle $14, X=$92, dX=$FFFA
TORPEDO_TRAJECTORY_RIGHT_03:
                        DB      $8E,$F7                 ; index $03, handle $15, X=$8E, dX=$FFF7
TORPEDO_TRAJECTORY_RIGHT_04:
                        DB      $8A,$F4                 ; index $04, handle $16, X=$8A, dX=$FFF4
TORPEDO_TRAJECTORY_RIGHT_05:
                        DB      $86,$F1                 ; index $05, handle $17, X=$86, dX=$FFF1
TORPEDO_TRAJECTORY_RIGHT_06:
                        DB      $81,$EE                 ; index $06, handle $18, X=$81, dX=$FFEE
TORPEDO_TRAJECTORY_RIGHT_07:
                        DB      $7D,$EB                 ; index $07, handle $19, X=$7D, dX=$FFEB
TORPEDO_TRAJECTORY_RIGHT_08:
                        DB      $79,$E8                 ; index $08, handle $1A, X=$79, dX=$FFE8
TORPEDO_TRAJECTORY_RIGHT_09:
                        DB      $75,$E5                 ; index $09, handle $1B, X=$75, dX=$FFE5
TORPEDO_TRAJECTORY_RIGHT_10:
                        DB      $70,$E2                 ; index $0A, handle $1C, X=$70, dX=$FFE2
TORPEDO_TRAJECTORY_RIGHT_11:
                        DB      $6C,$DF                 ; index $0B, handle $1D, X=$6C, dX=$FFDF
TORPEDO_TRAJECTORY_RIGHT_12:
                        DB      $68,$DC                 ; index $0C, handle $1E, X=$68, dX=$FFDC
TORPEDO_TRAJECTORY_RIGHT_13:
                        DB      $63,$D9                 ; index $0D, handle $1F, X=$63, dX=$FFD9
TORPEDO_TRAJECTORY_RIGHT_14:
                        DB      $5F,$D6                 ; index $0E, handle $20, X=$5F, dX=$FFD6
TORPEDO_TRAJECTORY_RIGHT_15:
                        DB      $5A,$D3                 ; index $0F, handle $21, X=$5A, dX=$FFD3
TORPEDO_TRAJECTORY_RIGHT_16:
                        DB      $56,$D0                 ; index $10, handle $22, X=$56, dX=$FFD0
TORPEDO_TRAJECTORY_RIGHT_17:
                        DB      $51,$CD                 ; index $11, handle $23, X=$51, dX=$FFCD
TORPEDO_TRAJECTORY_RIGHT_18:
                        DB      $4D,$CD                 ; index $12, handle $24, X=$4D, dX=$FFCD
TORPEDO_TRAJECTORY_RIGHT_19:
                        DB      $48,$CA                 ; index $13, handle $25, X=$48, dX=$FFCA
TORPEDO_TRAJECTORY_RIGHT_20:
                        DB      $43,$C7                 ; index $14, handle $26, X=$43, dX=$FFC7
TORPEDO_TRAJECTORY_RIGHT_21:
                        DB      $3E,$C4                 ; index $15, handle $27, X=$3E, dX=$FFC4
TORPEDO_TRAJECTORY_RIGHT_22:
                        DB      $3A,$C1                 ; index $16, handle $28, X=$3A, dX=$FFC1
TORPEDO_TRAJECTORY_RIGHT_23:
                        DB      $35,$BE                 ; index $17, handle $29, X=$35, dX=$FFBE
TORPEDO_TRAJECTORY_RIGHT_24:
                        DB      $30,$BB                 ; index $18, handle $2A, X=$30, dX=$FFBB
TORPEDO_TRAJECTORY_RIGHT_25:
                        DB      $2B,$B8                 ; index $19, handle $2B, X=$2B, dX=$FFB8
TORPEDO_TRAJECTORY_RIGHT_26:
                        DB      $25,$B5                 ; index $1A, handle $2C, X=$25, dX=$FFB5
TORPEDO_TRAJECTORY_RIGHT_27:
                        DB      $20,$B2                 ; index $1B, handle $2D, X=$20, dX=$FFB2
TORPEDO_TRAJECTORY_RIGHT_28:
                        DB      $1B,$AF                 ; index $1C, handle $2E, X=$1B, dX=$FFAF
TORPEDO_TRAJECTORY_RIGHT_29:
                        DB      $16,$AC                 ; index $1D, handle $2F, X=$16, dX=$FFAC
TORPEDO_TRAJECTORY_RIGHT_30:
                        DB      $10,$A9                 ; index $1E, handle $30, X=$10, dX=$FFA9
TORPEDO_TRAJECTORY_RIGHT_31:
                        DB      $0A,$A6                 ; index $1F, handle $31, X=$0A, dX=$FFA6
;-------------------------------------------------------------------------------
; $0DC8: Cyclic surface-target sequence for both target lanes
;-------------------------------------------------------------------------------
; The sequence contains all five large-ship silhouettes and two PT Boat slots.
; FREIGHTER_A slots are the only entries eligible for Super Sub replacement.
TARGET_TYPE_SEQUENCE:
                        DB      OBJECT_TYPE_FREIGHTER_A
                        DB      OBJECT_TYPE_WARSHIP_A
                        DB      OBJECT_TYPE_PT_BOAT
                        DB      OBJECT_TYPE_FREIGHTER_B
                        DB      OBJECT_TYPE_WARSHIP_B
                        DB      OBJECT_TYPE_FREIGHTER_A
                        DB      OBJECT_TYPE_WARSHIP_C
                        DB      OBJECT_TYPE_FREIGHTER_B
                        DB      OBJECT_TYPE_PT_BOAT
                        DB      $FF                     ; sequence terminator

;-------------------------------------------------------------------------------
; $0DD2: Base horizontal speed indexed by all nine object types
;-------------------------------------------------------------------------------
; ACTIVATE_TARGET_IN_LANE multiplies these values by four.  Mine and torpedo
; constructors supply their own velocities; their table entries are zero.
TARGET_SPEED_TABLE:
                        DB      TARGET_SPEED_MEDIUM_RAW  ; type 0 WARSHIP_A: +1.0
                        DB      TARGET_SPEED_MEDIUM_RAW  ; type 1 WARSHIP_B: +1.0
                        DB      TARGET_SPEED_MEDIUM_RAW  ; type 2 WARSHIP_C: +1.0
                        DB      TARGET_SPEED_SLOW_RAW    ; type 3 FREIGHTER_A: +0.5
                        DB      TARGET_SPEED_SLOW_RAW    ; type 4 FREIGHTER_B: +0.5
                        DB      TARGET_SPEED_FAST_RAW    ; type 5 PT_BOAT: +2.0
                        DB      $00                      ; type 6 MINE: constructor
                        DB      $00                      ; type 7 TORPEDO: aim table
                        DB      TARGET_SPEED_MEDIUM_RAW  ; type 8 SUPER_SUB: +1.0

;-------------------------------------------------------------------------------
; $0DDB: Four complete 25-byte object records copied into scheduler pools
;-------------------------------------------------------------------------------
; INITIALIZE_OBJECT_POOLS copies these records in order to target records 0/2
; and the first left/right torpedo records.  It asserts ACTIVE after the copy.
OBJECT_INITIAL_TEMPLATES:
INITIAL_UPPER_WARSHIP_TEMPLATE:
                        DB      $00,OBJECT_TYPE_WARSHIP_A,$00 ; flags, type, timer
                        DB      $00,$00                 ; Y acceleration, 8.8
                        DB      $00,$00                 ; Y velocity, 8.8
                        DB      $00,TARGET_LANE_UPPER_Y ; Y position $1A00
                        DB      $00,$00,$00             ; Y minimum, reserved $0A/$0B
                        DB      $80,$00                 ; X velocity +$0080
                        DB      $00,$00                 ; X position $0000
                        DB      $00,$8C                 ; reserved $10, X maximum
                        DB      $00,$00                 ; bitmap selected on first update
                        DB      FUNCGEN_MODE_EXPAND     ; expand, forward direction
                        DB      $00,$00                 ; no prior Magic write address
                        DB      EXPAND_COLORS_0_1,$00   ; set pixels color 1, frame 0

INITIAL_LOWER_SUPER_SUB_TEMPLATE:
                        DB      $00,OBJECT_TYPE_SUPER_SUB,$00 ; flags, type, timer
                        DB      $00,$00                 ; Y acceleration, 8.8
                        DB      $00,$00                 ; Y velocity, 8.8
                        DB      $00,TARGET_LANE_LOWER_Y ; Y position $3300
                        DB      $00,$00,$00             ; Y minimum, reserved $0A/$0B
                        DB      $80,$FF                 ; X velocity -$0080
                        DB      $00,$8C                 ; X position $8C00
                        DB      $00,$9F                 ; reserved $10, X maximum
                        DB      $00,$00                 ; bitmap selected on first update
                        DB      FUNCGEN_MODE_EXPAND_FLOP ; expand + flop, reverse direction
                        DB      $00,$00                 ; no prior Magic write address
                        DB      EXPAND_COLORS_0_3,$00   ; set pixels color 3, surfaced frame

INITIAL_LEFT_TORPEDO_TEMPLATE:
                        DB      $00,OBJECT_TYPE_TORPEDO,$00 ; flags, type, timer
                        DB      $06,$00                 ; Y acceleration +$0006
                        DB      $00,$FD                 ; Y velocity -$0300
                        DB      $00,$BE                 ; Y position $BE00
                        DB      $23,$00,$00             ; Y minimum, reserved $0A/$0B
                        DB      $00,$00                 ; X velocity supplied later
                        DB      $00,$20                 ; initial X position $2000
                        DB      $00,$9F                 ; reserved $10, X maximum
                        DB      BITMAP_TORPEDO_NEAR_LO,BITMAP_TORPEDO_NEAR_HI
                        DB      FUNCGEN_MODE_EXPAND     ; expand, forward direction
                        DB      $00,$00                 ; no prior Magic write address
                        DB      EXPAND_COLORS_0_2,$00   ; left set pixels color 2, near frame

INITIAL_RIGHT_TORPEDO_TEMPLATE:
                        DB      $00,OBJECT_TYPE_TORPEDO,$00 ; flags, type, timer
                        DB      $06,$00                 ; Y acceleration +$0006
                        DB      $00,$FD                 ; Y velocity -$0300
                        DB      $00,$BE                 ; Y position $BE00
                        DB      $23,$00,$00             ; Y minimum, reserved $0A/$0B
                        DB      $00,$00                 ; X velocity supplied later
                        DB      $00,$78                 ; initial X position $7800
                        DB      $00,$9F                 ; reserved $10, X maximum
                        DB      BITMAP_TORPEDO_NEAR_LO,BITMAP_TORPEDO_NEAR_HI
                        DB      FUNCGEN_MODE_EXPAND     ; expand, forward direction
                        DB      $00,$00                 ; no prior Magic write address
                        DB      EXPAND_COLORS_0_1,$00   ; right set pixels color 1, near frame

;-------------------------------------------------------------------------------
; $0E3F-$119E: One-bit object bitmap descriptors and animation frames
;-------------------------------------------------------------------------------
; Each descriptor is: DB source-byte width, row count; then width*rows mask
; bytes in top-to-bottom, left-to-right order.  Bits are read MSB first.
; Function Generator expand mode maps each source bit to one two-bit display
; pixel.  One source byte is eight display pixels but four object X units
; because the object coordinate mapper doubles X before addressing video RAM.
;
; Inline rows use: . = source 0 -> color 0; 1 = source 1 -> OBJECT_COLOR.
; The bitmap pointer lists reference 26 descriptors.  Two additional blocks
; at $1044 and $1090 have valid descriptor geometry but no ROM consumer.
; $1044 is the complete 12-row form of the shrinking medium/small hit pattern;
; the active 9-, 6-, 4- and 2-row frames are exact prefixes of its payload.
; $1090 is a unique sparse impact/debris mask whose intended object class is
; not recoverable because no code or pointer table selects it.
OBJECT_BITMAP_DATA:

;*******************************************************************************
; BITMAP_WARSHIP_A
; 5 source bytes/row = 40 expanded display pixels = 20 object X units, 12 rows
; Source mask size: 60 bytes ($3C)
; Descriptor total size: 62 bytes ($3E), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_WARSHIP_A:
                        DB      $05,$0C           ; source width bytes, height rows
                        DB      $00,$00,$20,$00,$00     ; row 00: . . . . . . . . . . . . . . . . . . 1 . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$00,$00,$00     ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$0C,$E0,$00,$00     ; row 02: . . . . . . . . . . . . 1 1 . . 1 1 1 . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$0E,$E3,$F8,$00     ; row 03: . . . . . . . . . . . . 1 1 1 . 1 1 1 . . . 1 1 1 1 1 1 1 . . . . . . . . . . .
                        DB      $00,$0E,$F3,$80,$00     ; row 04: . . . . . . . . . . . . 1 1 1 . 1 1 1 1 . . 1 1 1 . . . . . . . . . . . . . . .
                        DB      $1F,$DF,$F7,$DF,$E0     ; row 05: . . . 1 1 1 1 1 1 1 . 1 1 1 1 1 1 1 1 1 . 1 1 1 1 1 . 1 1 1 1 1 1 1 1 . . . . .
                        DB      $03,$DF,$F7,$DE,$00     ; row 06: . . . . . . 1 1 1 1 . 1 1 1 1 1 1 1 1 1 . 1 1 1 1 1 . 1 1 1 1 . . . . . . . . .
                        DB      $3F,$FF,$FF,$FF,$FF     ; row 07: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                        DB      $3F,$FF,$FF,$FF,$FE     ; row 08: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
                        DB      $3F,$FF,$FF,$FF,$FC     ; row 09: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $1F,$FF,$FF,$FF,$F8     ; row 10: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $0F,$FF,$FF,$FF,$F0     ; row 11: . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; BITMAP_WARSHIP_B
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 11 rows
; Source mask size: 44 bytes ($2C)
; Descriptor total size: 46 bytes ($2E), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_B_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_WARSHIP_B:
                        DB      $04,$0B           ; source width bytes, height rows
                        DB      $00,$00,$40,$00         ; row 00: . . . . . . . . . . . . . . . . . 1 . . . . . . . . . . . . . .
                        DB      $00,$00,$30,$00         ; row 01: . . . . . . . . . . . . . . . . . . 1 1 . . . . . . . . . . . .
                        DB      $00,$36,$38,$00         ; row 02: . . . . . . . . . . 1 1 . 1 1 . . . 1 1 1 . . . . . . . . . . .
                        DB      $00,$36,$78,$00         ; row 03: . . . . . . . . . . 1 1 . 1 1 . . 1 1 1 1 . . . . . . . . . . .
                        DB      $00,$36,$78,$00         ; row 04: . . . . . . . . . . 1 1 . 1 1 . . 1 1 1 1 . . . . . . . . . . .
                        DB      $1F,$7E,$79,$F8         ; row 05: . . . 1 1 1 1 1 . 1 1 1 1 1 1 . . 1 1 1 1 . . 1 1 1 1 1 1 . . .
                        DB      $07,$7F,$FD,$C0         ; row 06: . . . . . 1 1 1 . 1 1 1 1 1 1 1 1 1 1 1 1 1 . 1 1 1 . . . . . .
                        DB      $3F,$FF,$FF,$FF         ; row 07: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                        DB      $3F,$FF,$FF,$FE         ; row 08: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
                        DB      $1F,$FF,$FF,$FC         ; row 09: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $1F,$FF,$FF,$F8         ; row 10: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .

;*******************************************************************************
; BITMAP_WARSHIP_C
; 5 source bytes/row = 40 expanded display pixels = 20 object X units, 10 rows
; Source mask size: 50 bytes ($32)
; Descriptor total size: 52 bytes ($34), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_WARSHIP_C:
                        DB      $05,$0A           ; source width bytes, height rows
                        DB      $00,$00,$44,$00,$00     ; row 00: . . . . . . . . . . . . . . . . . 1 . . . 1 . . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$1E,$00,$00     ; row 01: . . . . . . . . . . . . . . . . . . . 1 1 1 1 . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$1E,$00,$00     ; row 02: . . . . . . . . . . . . . . . . . . . 1 1 1 1 . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$1E,$F0,$00     ; row 03: . . . . . . . . . . . . . . . . . . . 1 1 1 1 . 1 1 1 1 . . . . . . . . . . . .
                        DB      $19,$99,$BE,$C0,$00     ; row 04: . . . 1 1 . . 1 1 . . 1 1 . . 1 1 . 1 1 1 1 1 . 1 1 . . . . . . . . . . . . . .
                        DB      $3F,$FF,$FF,$FF,$FF     ; row 05: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                        DB      $3F,$FF,$FF,$FF,$FC     ; row 06: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $1F,$FF,$FF,$FF,$F8     ; row 07: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $1F,$FF,$FF,$FF,$F0     ; row 08: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
                        DB      $0F,$FF,$FF,$FF,$F0     ; row 09: . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; BITMAP_FREIGHTER_A
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 10 rows
; Source mask size: 40 bytes ($28)
; Descriptor total size: 42 bytes ($2A), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: FREIGHTER_A_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_FREIGHTER_A:
                        DB      $04,$0A           ; source width bytes, height rows
                        DB      $04,$00,$01,$00         ; row 00: . . . . . 1 . . . . . . . . . . . . . . . . . 1 . . . . . . . .
                        DB      $04,$00,$81,$00         ; row 01: . . . . . 1 . . . . . . . . . . 1 . . . . . . 1 . . . . . . . .
                        DB      $04,$00,$61,$00         ; row 02: . . . . . 1 . . . . . . . . . . . 1 1 . . . . 1 . . . . . . . .
                        DB      $04,$00,$61,$00         ; row 03: . . . . . 1 . . . . . . . . . . . 1 1 . . . . 1 . . . . . . . .
                        DB      $04,$1F,$E1,$00         ; row 04: . . . . . 1 . . . . . 1 1 1 1 1 1 1 1 . . . . 1 . . . . . . . .
                        DB      $04,$3F,$E1,$00         ; row 05: . . . . . 1 . . . . 1 1 1 1 1 1 1 1 1 . . . . 1 . . . . . . . .
                        DB      $3C,$3F,$E1,$3F         ; row 06: . . 1 1 1 1 . . . . 1 1 1 1 1 1 1 1 1 . . . . 1 . . 1 1 1 1 1 1
                        DB      $3F,$FF,$FF,$FE         ; row 07: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
                        DB      $3F,$FF,$FF,$FC         ; row 08: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $1F,$FF,$FF,$F8         ; row 09: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .

;*******************************************************************************
; BITMAP_FREIGHTER_B
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 9 rows
; Source mask size: 36 bytes ($24)
; Descriptor total size: 38 bytes ($26), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: FREIGHTER_B_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_FREIGHTER_B:
                        DB      $04,$09           ; source width bytes, height rows
                        DB      $00,$10,$00,$20         ; row 00: . . . . . . . . . . . 1 . . . . . . . . . . . . . . 1 . . . . .
                        DB      $03,$10,$00,$20         ; row 01: . . . . . . 1 1 . . . 1 . . . . . . . . . . . . . . 1 . . . . .
                        DB      $03,$10,$00,$20         ; row 02: . . . . . . 1 1 . . . 1 . . . . . . . . . . . . . . 1 . . . . .
                        DB      $0F,$10,$00,$20         ; row 03: . . . . 1 1 1 1 . . . 1 . . . . . . . . . . . . . . 1 . . . . .
                        DB      $1F,$10,$00,$20         ; row 04: . . . 1 1 1 1 1 . . . 1 . . . . . . . . . . . . . . 1 . . . . .
                        DB      $3F,$10,$00,$3F         ; row 05: . . 1 1 1 1 1 1 . . . 1 . . . . . . . . . . . . . . 1 1 1 1 1 1
                        DB      $3F,$FF,$FF,$FE         ; row 06: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
                        DB      $1F,$FF,$FF,$FC         ; row 07: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $1F,$FF,$FF,$FC         ; row 08: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .

;*******************************************************************************
; BITMAP_PT_BOAT
; 3 source bytes/row = 24 expanded display pixels = 12 object X units, 5 rows
; Source mask size: 15 bytes ($0F)
; Descriptor total size: 17 bytes ($11), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: PT_BOAT_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_PT_BOAT:
                        DB      $03,$05           ; source width bytes, height rows
                        DB      $00,$0F,$00             ; row 00: . . . . . . . . . . . . 1 1 1 1 . . . . . . . .
                        DB      $00,$1F,$80             ; row 01: . . . . . . . . . . . 1 1 1 1 1 1 . . . . . . .
                        DB      $00,$FF,$FC             ; row 02: . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $0F,$FF,$F8             ; row 03: . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $0F,$FF,$F0             ; row 04: . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; BITMAP_SUPER_SUB_SURFACED
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 9 rows
; Source mask size: 36 bytes ($24)
; Descriptor total size: 38 bytes ($26), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: SUPER_SUB_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_SUPER_SUB_SURFACED:
                        DB      $04,$09           ; source width bytes, height rows
                        DB      $00,$00,$00,$00         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$06,$00         ; row 01: . . . . . . . . . . . . . . . . . . . . . 1 1 . . . . . . . . .
                        DB      $00,$00,$04,$00         ; row 02: . . . . . . . . . . . . . . . . . . . . . 1 . . . . . . . . . .
                        DB      $00,$00,$3E,$00         ; row 03: . . . . . . . . . . . . . . . . . . 1 1 1 1 1 . . . . . . . . .
                        DB      $00,$00,$3E,$00         ; row 04: . . . . . . . . . . . . . . . . . . 1 1 1 1 1 . . . . . . . . .
                        DB      $30,$00,$7E,$00         ; row 05: . . 1 1 . . . . . . . . . . . . . 1 1 1 1 1 1 . . . . . . . . .
                        DB      $3C,$3F,$FF,$FC         ; row 06: . . 1 1 1 1 . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $3F,$FF,$FF,$FF         ; row 07: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                        DB      $3F,$FF,$FF,$FF         ; row 08: . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1

;*******************************************************************************
; BITMAP_SUPER_SUB_DIVE_1
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 8 rows
; Source mask size: 32 bytes ($20)
; Descriptor total size: 34 bytes ($22), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: SUPER_SUB_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_SUPER_SUB_DIVE_1:
                        DB      $04,$08           ; source width bytes, height rows
                        DB      $00,$00,$00,$00         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$00,$00         ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$06,$00         ; row 02: . . . . . . . . . . . . . . . . . . . . . 1 1 . . . . . . . . .
                        DB      $00,$00,$04,$00         ; row 03: . . . . . . . . . . . . . . . . . . . . . 1 . . . . . . . . . .
                        DB      $00,$00,$3E,$00         ; row 04: . . . . . . . . . . . . . . . . . . 1 1 1 1 1 . . . . . . . . .
                        DB      $00,$00,$3E,$00         ; row 05: . . . . . . . . . . . . . . . . . . 1 1 1 1 1 . . . . . . . . .
                        DB      $00,$00,$7E,$00         ; row 06: . . . . . . . . . . . . . . . . . 1 1 1 1 1 1 . . . . . . . . .
                        DB      $00,$3F,$FF,$FC         ; row 07: . . . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .

;*******************************************************************************
; BITMAP_SUPER_SUB_DIVE_2
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 6 rows
; Source mask size: 24 bytes ($18)
; Descriptor total size: 26 bytes ($1A), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: SUPER_SUB_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_SUPER_SUB_DIVE_2:
                        DB      $04,$06           ; source width bytes, height rows
                        DB      $00,$00,$00,$00         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
                        DB      $00,$00,$06,$00         ; row 01: . . . . . . . . . . . . . . . . . . . . . 1 1 . . . . . . . . .
                        DB      $00,$00,$04,$00         ; row 02: . . . . . . . . . . . . . . . . . . . . . 1 . . . . . . . . . .
                        DB      $00,$00,$3E,$00         ; row 03: . . . . . . . . . . . . . . . . . . 1 1 1 1 1 . . . . . . . . .
                        DB      $00,$00,$3E,$00         ; row 04: . . . . . . . . . . . . . . . . . . 1 1 1 1 1 . . . . . . . . .
                        DB      $00,$00,$7E,$00         ; row 05: . . . . . . . . . . . . . . . . . 1 1 1 1 1 1 . . . . . . . . .

;*******************************************************************************
; BITMAP_LARGE_HIT_FRAME_2
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 13 rows
; Source mask size: 52 bytes ($34)
; Descriptor total size: 54 bytes ($36), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE, WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_LARGE_HIT_FRAME_2:
                        DB      $04,$0D           ; source width bytes, height rows
                        DB      $00,$00,$00,$04         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 1 . .
                        DB      $00,$00,$00,$8C         ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 . .
                        DB      $00,$00,$01,$1C         ; row 02: . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 . .
                        DB      $00,$00,$02,$3C         ; row 03: . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 1 . .
                        DB      $24,$00,$06,$7C         ; row 04: . . 1 . . 1 . . . . . . . . . . . . . . . 1 1 . . 1 1 1 1 1 . .
                        DB      $72,$00,$0E,$FC         ; row 05: . 1 1 1 . . 1 . . . . . . . . . . . . . 1 1 1 . 1 1 1 1 1 1 . .
                        DB      $7B,$00,$7F,$F8         ; row 06: . 1 1 1 1 . 1 1 . . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $FF,$80,$7F,$F0         ; row 07: 1 1 1 1 1 1 1 1 1 . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 . . . .
                        DB      $7F,$8C,$3F,$E0         ; row 08: . 1 1 1 1 1 1 1 1 . . . 1 1 . . . . 1 1 1 1 1 1 1 1 1 . . . . .
                        DB      $3F,$3C,$7F,$C0         ; row 09: . . 1 1 1 1 1 1 . . 1 1 1 1 . . . 1 1 1 1 1 1 1 1 1 . . . . . .
                        DB      $1F,$FC,$7F,$80         ; row 10: . . . 1 1 1 1 1 1 1 1 1 1 1 . . . 1 1 1 1 1 1 1 1 . . . . . . .
                        DB      $0F,$F8,$FF,$00         ; row 11: . . . . 1 1 1 1 1 1 1 1 1 . . . 1 1 1 1 1 1 1 1 . . . . . . . .
                        DB      $07,$F8,$FF,$00         ; row 12: . . . . . 1 1 1 1 1 1 1 1 . . . 1 1 1 1 1 1 1 1 . . . . . . . .

;*******************************************************************************
; UNUSED_LARGE_HIT_PATTERN_TAIL
; Two four-byte rows follow BITMAP_LARGE_HIT_FRAME_2.  Appending them would
; produce a 15-row form of the same pattern, but the descriptor declares 13
; rows and the renderer stops at $0FD7.  The active 10-, 7-, 4- and 2-row large
; hit frames are exact prefixes of frame 2; no pointer targets this tail.
;*******************************************************************************
UNUSED_LARGE_HIT_PATTERN_TAIL:
                        DB      $03,$FC,$CC,$00     ; unused row 00: . . . . . . 1 1 1 1 1 1 1 1 . . 1 1 . . 1 1 . . . . . . . . . .
                        DB      $00,$9F,$88,$00     ; unused row 01: . . . . . . . . 1 . . 1 1 1 1 1 1 . . . 1 . . . . . . . . . . .

;*******************************************************************************
; BITMAP_LARGE_HIT_FRAME_3
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 10 rows
; Source mask size: 40 bytes ($28)
; Descriptor total size: 42 bytes ($2A), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE, WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_LARGE_HIT_FRAME_3:
                        DB      $04,$0A           ; source width bytes, height rows
                        DB      $00,$00,$00,$04         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 1 . .
                        DB      $00,$00,$00,$8C         ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 . .
                        DB      $00,$00,$01,$1C         ; row 02: . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 . .
                        DB      $00,$00,$02,$3C         ; row 03: . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 1 . .
                        DB      $24,$00,$06,$7C         ; row 04: . . 1 . . 1 . . . . . . . . . . . . . . . 1 1 . . 1 1 1 1 1 . .
                        DB      $72,$00,$0E,$FC         ; row 05: . 1 1 1 . . 1 . . . . . . . . . . . . . 1 1 1 . 1 1 1 1 1 1 . .
                        DB      $7B,$00,$7F,$F8         ; row 06: . 1 1 1 1 . 1 1 . . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $FF,$80,$7F,$F0         ; row 07: 1 1 1 1 1 1 1 1 1 . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 . . . .
                        DB      $7F,$8C,$3F,$E0         ; row 08: . 1 1 1 1 1 1 1 1 . . . 1 1 . . . . 1 1 1 1 1 1 1 1 1 . . . . .
                        DB      $3F,$3C,$7F,$C0         ; row 09: . . 1 1 1 1 1 1 . . 1 1 1 1 . . . 1 1 1 1 1 1 1 1 1 . . . . . .

;*******************************************************************************
; BITMAP_LARGE_HIT_FRAME_4
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 7 rows
; Source mask size: 28 bytes ($1C)
; Descriptor total size: 30 bytes ($1E), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE, WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_LARGE_HIT_FRAME_4:
                        DB      $04,$07           ; source width bytes, height rows
                        DB      $00,$00,$00,$04         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 1 . .
                        DB      $00,$00,$00,$8C         ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 . .
                        DB      $00,$00,$01,$1C         ; row 02: . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 . .
                        DB      $00,$00,$02,$3C         ; row 03: . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 1 . .
                        DB      $24,$00,$06,$7C         ; row 04: . . 1 . . 1 . . . . . . . . . . . . . . . 1 1 . . 1 1 1 1 1 . .
                        DB      $72,$00,$0E,$FC         ; row 05: . 1 1 1 . . 1 . . . . . . . . . . . . . 1 1 1 . 1 1 1 1 1 1 . .
                        DB      $7B,$00,$7F,$F8         ; row 06: . 1 1 1 1 . 1 1 . . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . .

;*******************************************************************************
; BITMAP_LARGE_HIT_FRAME_5
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 4 rows
; Source mask size: 16 bytes ($10)
; Descriptor total size: 18 bytes ($12), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE, WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_LARGE_HIT_FRAME_5:
                        DB      $04,$04           ; source width bytes, height rows
                        DB      $00,$00,$00,$04         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 1 . .
                        DB      $00,$00,$00,$8C         ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 . .
                        DB      $00,$00,$01,$1C         ; row 02: . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 . .
                        DB      $00,$00,$02,$3C         ; row 03: . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 1 1 . .

;*******************************************************************************
; BITMAP_LARGE_HIT_FRAME_6
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 2 rows
; Source mask size: 8 bytes ($08)
; Descriptor total size: 10 bytes ($0A), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE, WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_LARGE_HIT_FRAME_6:
                        DB      $04,$02           ; source width bytes, height rows
                        DB      $00,$00,$00,$04         ; row 00: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 1 . .
                        DB      $00,$00,$00,$8C         ; row 01: . . . . . . . . . . . . . . . . . . . . . . . . 1 . . . 1 1 . .

;*******************************************************************************
; UNUSED_MEDIUM_HIT_PATTERN_12_ROWS
; 2 source bytes/row = 16 expanded display pixels = 8 object X units, 12 rows
; Source mask size: 24 bytes ($18)
; Descriptor total size: 26 bytes ($1A), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; The active medium/small hit frames at $105E, $1072, $1080 and $108A are
; exact 9-, 6-, 4- and 2-row prefixes.  No bitmap list selects this 12-row form.
;*******************************************************************************
UNUSED_MEDIUM_HIT_PATTERN_12_ROWS:
                        DB      $02,$0C           ; source width bytes, height rows
                        DB      $08,$00                 ; row 00: . . . . 1 . . . . . . . . . . .
                        DB      $0C,$40                 ; row 01: . . . . 1 1 . . . 1 . . . . . .
                        DB      $0E,$80                 ; row 02: . . . . 1 1 1 . 1 . . . . . . .
                        DB      $3F,$00                 ; row 03: . . 1 1 1 1 1 1 . . . . . . . .
                        DB      $1F,$88                 ; row 04: . . . 1 1 1 1 1 1 . . . 1 . . .
                        DB      $0F,$DC                 ; row 05: . . . . 1 1 1 1 1 1 . 1 1 1 . .
                        DB      $07,$FE                 ; row 06: . . . . . 1 1 1 1 1 1 1 1 1 1 .
                        DB      $03,$FC                 ; row 07: . . . . . . 1 1 1 1 1 1 1 1 . .
                        DB      $01,$F8                 ; row 08: . . . . . . . 1 1 1 1 1 1 . . .
                        DB      $00,$FC                 ; row 09: . . . . . . . . 1 1 1 1 1 1 . .
                        DB      $00,$78                 ; row 10: . . . . . . . . . 1 1 1 1 . . .
                        DB      $00,$20                 ; row 11: . . . . . . . . . . 1 . . . . .

;*******************************************************************************
; BITMAP_MEDIUM_HIT_FRAME_2
; 2 source bytes/row = 16 expanded display pixels = 8 object X units, 9 rows
; Source mask size: 18 bytes ($12)
; Descriptor total size: 20 bytes ($14), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_B_BITMAP_SEQUENCE, FREIGHTER_A_BITMAP_SEQUENCE, FREIGHTER_B_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_MEDIUM_HIT_FRAME_2:
                        DB      $02,$09           ; source width bytes, height rows
                        DB      $08,$00                 ; row 00: . . . . 1 . . . . . . . . . . .
                        DB      $0C,$40                 ; row 01: . . . . 1 1 . . . 1 . . . . . .
                        DB      $0E,$80                 ; row 02: . . . . 1 1 1 . 1 . . . . . . .
                        DB      $3F,$00                 ; row 03: . . 1 1 1 1 1 1 . . . . . . . .
                        DB      $1F,$88                 ; row 04: . . . 1 1 1 1 1 1 . . . 1 . . .
                        DB      $0F,$DC                 ; row 05: . . . . 1 1 1 1 1 1 . 1 1 1 . .
                        DB      $07,$FE                 ; row 06: . . . . . 1 1 1 1 1 1 1 1 1 1 .
                        DB      $03,$FC                 ; row 07: . . . . . . 1 1 1 1 1 1 1 1 . .
                        DB      $01,$F8                 ; row 08: . . . . . . . 1 1 1 1 1 1 . . .

;*******************************************************************************
; BITMAP_MEDIUM_HIT_FRAME_3
; 2 source bytes/row = 16 expanded display pixels = 8 object X units, 6 rows
; Source mask size: 12 bytes ($0C)
; Descriptor total size: 14 bytes ($0E), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_B_BITMAP_SEQUENCE, FREIGHTER_A_BITMAP_SEQUENCE, FREIGHTER_B_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_MEDIUM_HIT_FRAME_3:
                        DB      $02,$06           ; source width bytes, height rows
                        DB      $08,$00                 ; row 00: . . . . 1 . . . . . . . . . . .
                        DB      $0C,$40                 ; row 01: . . . . 1 1 . . . 1 . . . . . .
                        DB      $0E,$80                 ; row 02: . . . . 1 1 1 . 1 . . . . . . .
                        DB      $3F,$00                 ; row 03: . . 1 1 1 1 1 1 . . . . . . . .
                        DB      $1F,$88                 ; row 04: . . . 1 1 1 1 1 1 . . . 1 . . .
                        DB      $0F,$DC                 ; row 05: . . . . 1 1 1 1 1 1 . 1 1 1 . .

;*******************************************************************************
; BITMAP_SMALL_HIT_FRAME_2
; 2 source bytes/row = 16 expanded display pixels = 8 object X units, 4 rows
; Source mask size: 8 bytes ($08)
; Descriptor total size: 10 bytes ($0A), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_B/FREIGHTER_A/FREIGHTER_B/PT_BOAT/SUPER_SUB sequences
;*******************************************************************************
BITMAP_SMALL_HIT_FRAME_2:
                        DB      $02,$04           ; source width bytes, height rows
                        DB      $08,$00                 ; row 00: . . . . 1 . . . . . . . . . . .
                        DB      $0C,$40                 ; row 01: . . . . 1 1 . . . 1 . . . . . .
                        DB      $0E,$80                 ; row 02: . . . . 1 1 1 . 1 . . . . . . .
                        DB      $3F,$00                 ; row 03: . . 1 1 1 1 1 1 . . . . . . . .

;*******************************************************************************
; BITMAP_SMALL_HIT_FRAME_3
; 2 source bytes/row = 16 expanded display pixels = 8 object X units, 2 rows
; Source mask size: 4 bytes ($04)
; Descriptor total size: 6 bytes ($06), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_B/FREIGHTER_A/FREIGHTER_B/PT_BOAT/SUPER_SUB sequences
;*******************************************************************************
BITMAP_SMALL_HIT_FRAME_3:
                        DB      $02,$02           ; source width bytes, height rows
                        DB      $08,$00                 ; row 00: . . . . 1 . . . . . . . . . . .
                        DB      $0C,$40                 ; row 01: . . . . 1 1 . . . 1 . . . . . .

;*******************************************************************************
; UNREFERENCED_BITMAP_1090
; 2 source bytes/row = 16 expanded display pixels = 8 object X units, 15 rows
; Source mask size: 30 bytes ($1E)
; Descriptor total size: 32 bytes ($20), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; The payload is unique in ROM and forms a sparse burst/debris silhouette with
; a dense bottom row.  No pointer or native-code path identifies its event or
; object class, so the address-based label deliberately remains neutral.
;*******************************************************************************
UNREFERENCED_BITMAP_1090:
                        DB      $02,$0F           ; source width bytes, height rows
                        DB      $21,$2A                 ; row 00: . . 1 . . . . 1 . . 1 . 1 . 1 .
                        DB      $11,$46                 ; row 01: . . . 1 . . . 1 . 1 . . . 1 1 .
                        DB      $00,$48                 ; row 02: . . . . . . . . . 1 . . 1 . . .
                        DB      $89,$01                 ; row 03: 1 . . . 1 . . 1 . . . . . . . 1
                        DB      $45,$22                 ; row 04: . 1 . . . 1 . 1 . . 1 . . . 1 .
                        DB      $31,$02                 ; row 05: . . 1 1 . . . 1 . . . . . . 1 .
                        DB      $18,$18                 ; row 06: . . . 1 1 . . . . . . 1 1 . . .
                        DB      $0C,$39                 ; row 07: . . . . 1 1 . . . . 1 1 1 . . 1
                        DB      $24,$60                 ; row 08: . . 1 . . 1 . . . 1 1 . . . . .
                        DB      $A4,$00                 ; row 09: 1 . 1 . . 1 . . . . . . . . . .
                        DB      $20,$04                 ; row 10: . . 1 . . . . . . . . . . 1 . .
                        DB      $04,$42                 ; row 11: . . . . . 1 . . . 1 . . . . 1 .
                        DB      $0C,$E1                 ; row 12: . . . . 1 1 . . 1 1 1 . . . . 1
                        DB      $1C,$F0                 ; row 13: . . . 1 1 1 . . 1 1 1 1 . . . .
                        DB      $3F,$F1                 ; row 14: . . 1 1 1 1 1 1 1 1 1 1 . . . 1

;*******************************************************************************
; BITMAP_SMALL_HIT_FRAME_1
; 3 source bytes/row = 24 expanded display pixels = 12 object X units, 5 rows
; Source mask size: 15 bytes ($0F)
; Descriptor total size: 17 bytes ($11), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: PT_BOAT_BITMAP_SEQUENCE, SUPER_SUB_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_SMALL_HIT_FRAME_1:
                        DB      $03,$05           ; source width bytes, height rows
                        DB      $E0,$40,$21             ; row 00: 1 1 1 . . . . . . 1 . . . . . . . . 1 . . . . 1
                        DB      $3C,$10,$C2             ; row 01: . . 1 1 1 1 . . . . . 1 . . . . 1 1 . . . . 1 .
                        DB      $07,$01,$8C             ; row 02: . . . . . 1 1 1 . . . . . . . 1 1 . . . 1 1 . .
                        DB      $C0,$44,$F0             ; row 03: 1 1 . . . . . . . 1 . . . 1 . . 1 1 1 1 . . . .
                        DB      $0F,$FF,$F0             ; row 04: . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; BITMAP_MEDIUM_HIT_FRAME_1
; 4 source bytes/row = 32 expanded display pixels = 16 object X units, 11 rows
; Source mask size: 44 bytes ($2C)
; Descriptor total size: 46 bytes ($2E), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_B_BITMAP_SEQUENCE, FREIGHTER_A_BITMAP_SEQUENCE, FREIGHTER_B_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_MEDIUM_HIT_FRAME_1:
                        DB      $04,$0B           ; source width bytes, height rows
                        DB      $20,$62,$08,$48         ; row 00: . . 1 . . . . . . 1 1 . . . 1 . . . . . 1 . . . . 1 . . 1 . . .
                        DB      $10,$10,$44,$41         ; row 01: . . . 1 . . . . . . . 1 . . . . . 1 . . . 1 . . . 1 . . . . . 1
                        DB      $0C,$00,$82,$22         ; row 02: . . . . 1 1 . . . . . . . . . . 1 . . . . . 1 . . . 1 . . . 1 .
                        DB      $07,$00,$80,$4C         ; row 03: . . . . . 1 1 1 . . . . . . . . 1 . . . . . . . . 1 . . 1 1 . .
                        DB      $40,$18,$00,$58         ; row 04: . 1 . . . . . . . . . 1 1 . . . . . . . . . . . . 1 . 1 1 . . .
                        DB      $08,$11,$08,$00         ; row 05: . . . . 1 . . . . . . 1 . . . 1 . . . . 1 . . . . . . . . . . .
                        DB      $0F,$18,$00,$FF         ; row 06: . . . . 1 1 1 1 . . . 1 1 . . . . . . . . . . . 1 1 1 1 1 1 1 1
                        DB      $0F,$C0,$07,$FE         ; row 07: . . . . 1 1 1 1 1 1 . . . . . . . . . . . 1 1 1 1 1 1 1 1 1 1 .
                        DB      $0F,$F0,$1F,$FC         ; row 08: . . . . 1 1 1 1 1 1 1 1 . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 . .
                        DB      $07,$FF,$FF,$F8         ; row 09: . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $07,$FF,$FF,$F0         ; row 10: . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; BITMAP_LARGE_HIT_FRAME_1
; 5 source bytes/row = 40 expanded display pixels = 20 object X units, 12 rows
; Source mask size: 60 bytes ($3C)
; Descriptor total size: 62 bytes ($3E), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: WARSHIP_A_BITMAP_SEQUENCE, WARSHIP_C_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_LARGE_HIT_FRAME_1:
                        DB      $05,$0C           ; source width bytes, height rows
                        DB      $40,$01,$10,$80,$41     ; row 00: . 1 . . . . . . . . . . . . . 1 . . . 1 . . . . 1 . . . . . . . . 1 . . . . . 1
                        DB      $20,$02,$08,$84,$42     ; row 01: . . 1 . . . . . . . . . . . 1 . . . . . 1 . . . 1 . . . . 1 . . . 1 . . . . 1 .
                        DB      $10,$C2,$00,$90,$8C     ; row 02: . . . 1 . . . . 1 1 . . . . 1 . . . . . . . . . 1 . . 1 . . . . 1 . . . 1 1 . .
                        DB      $18,$44,$10,$00,$9C     ; row 03: . . . 1 1 . . . . 1 . . . 1 . . . . . 1 . . . . . . . . . . . . 1 . . 1 1 1 . .
                        DB      $06,$20,$90,$89,$00     ; row 04: . . . . . 1 1 . . . 1 . . . . . 1 . . 1 . . . . 1 . . . 1 . . 1 . . . . . . . .
                        DB      $00,$20,$81,$30,$00     ; row 05: . . . . . . . . . . 1 . . . . . 1 . . . . . . 1 . . 1 1 . . . . . . . . . . . .
                        DB      $18,$00,$40,$00,$0F     ; row 06: . . . 1 1 . . . . . . . . . . . . 1 . . . . . . . . . . . . . . . . . . 1 1 1 1
                        DB      $3E,$00,$00,$00,$0E     ; row 07: . . 1 1 1 1 1 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 1 1 1 .
                        DB      $3F,$80,$00,$00,$FC     ; row 08: . . 1 1 1 1 1 1 1 . . . . . . . . . . . . . . . . . . . . . . . 1 1 1 1 1 1 . .
                        DB      $3F,$E1,$F0,$1F,$F8     ; row 09: . . 1 1 1 1 1 1 1 1 1 . . . . 1 1 1 1 1 . . . . . . . 1 1 1 1 1 1 1 1 1 1 . . .
                        DB      $1F,$FF,$FF,$FF,$F0     ; row 10: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
                        DB      $1F,$FF,$FF,$FF,$E0     ; row 11: . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . . .

;*******************************************************************************
; BITMAP_TORPEDO_NEAR
; 1 source bytes/row = 8 expanded display pixels = 4 object X units, 21 rows
; Source mask size: 21 bytes ($15)
; Descriptor total size: 23 bytes ($17), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: TORPEDO_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_TORPEDO_NEAR:
                        DB      $01,$15           ; source width bytes, height rows
                        DB      $20                     ; row 00: . . 1 . . . . .
                        DB      $70                     ; row 01: . 1 1 1 . . . .
                        DB      $70                     ; row 02: . 1 1 1 . . . .
                        DB      $70                     ; row 03: . 1 1 1 . . . .
                        DB      $70                     ; row 04: . 1 1 1 . . . .
                        DB      $70                     ; row 05: . 1 1 1 . . . .
                        DB      $70                     ; row 06: . 1 1 1 . . . .
                        DB      $70                     ; row 07: . 1 1 1 . . . .
                        DB      $70                     ; row 08: . 1 1 1 . . . .
                        DB      $70                     ; row 09: . 1 1 1 . . . .
                        DB      $70                     ; row 10: . 1 1 1 . . . .
                        DB      $70                     ; row 11: . 1 1 1 . . . .
                        DB      $70                     ; row 12: . 1 1 1 . . . .
                        DB      $20                     ; row 13: . . 1 . . . . .
                        DB      $20                     ; row 14: . . 1 . . . . .
                        DB      $20                     ; row 15: . . 1 . . . . .
                        DB      $70                     ; row 16: . 1 1 1 . . . .
                        DB      $00                     ; row 17: . . . . . . . .
                        DB      $00                     ; row 18: . . . . . . . .
                        DB      $00                     ; row 19: . . . . . . . .
                        DB      $00                     ; row 20: . . . . . . . .

;*******************************************************************************
; BITMAP_PADDING_1144
; 3 unreferenced zero bytes between descriptors.
;*******************************************************************************
BITMAP_PADDING_1144:
                        DB      $00,$00,$00

;*******************************************************************************
; BITMAP_TORPEDO_MIDDLE
; 1 source bytes/row = 8 expanded display pixels = 4 object X units, 21 rows
; Source mask size: 21 bytes ($15)
; Descriptor total size: 23 bytes ($17), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: TORPEDO_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_TORPEDO_MIDDLE:
                        DB      $01,$15           ; source width bytes, height rows
                        DB      $60                     ; row 00: . 1 1 . . . . .
                        DB      $60                     ; row 01: . 1 1 . . . . .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $60                     ; row 04: . 1 1 . . . . .
                        DB      $60                     ; row 05: . 1 1 . . . . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $00                     ; row 07: . . . . . . . .
                        DB      $60                     ; row 08: . 1 1 . . . . .
                        DB      $00                     ; row 09: . . . . . . . .
                        DB      $00                     ; row 10: . . . . . . . .
                        DB      $00                     ; row 11: . . . . . . . .
                        DB      $00                     ; row 12: . . . . . . . .
                        DB      $00                     ; row 13: . . . . . . . .
                        DB      $00                     ; row 14: . . . . . . . .
                        DB      $00                     ; row 15: . . . . . . . .
                        DB      $00                     ; row 16: . . . . . . . .
                        DB      $00                     ; row 17: . . . . . . . .
                        DB      $00                     ; row 18: . . . . . . . .
                        DB      $00                     ; row 19: . . . . . . . .
                        DB      $00                     ; row 20: . . . . . . . .

;*******************************************************************************
; BITMAP_PADDING_115E
; 4 unreferenced zero bytes between descriptors.
;*******************************************************************************
BITMAP_PADDING_115E:
                        DB      $00,$00,$00,$00

;*******************************************************************************
; BITMAP_TORPEDO_FAR
; 1 source bytes/row = 8 expanded display pixels = 4 object X units, 11 rows
; Source mask size: 11 bytes ($0B)
; Descriptor total size: 13 bytes ($0D), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: TORPEDO_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_TORPEDO_FAR:
                        DB      $01,$0B           ; source width bytes, height rows
                        DB      $40                     ; row 00: . 1 . . . . . .
                        DB      $40                     ; row 01: . 1 . . . . . .
                        DB      $40                     ; row 02: . 1 . . . . . .
                        DB      $40                     ; row 03: . 1 . . . . . .
                        DB      $40                     ; row 04: . 1 . . . . . .
                        DB      $00                     ; row 05: . . . . . . . .
                        DB      $00                     ; row 06: . . . . . . . .
                        DB      $00                     ; row 07: . . . . . . . .
                        DB      $00                     ; row 08: . . . . . . . .
                        DB      $00                     ; row 09: . . . . . . . .
                        DB      $00                     ; row 10: . . . . . . . .

;*******************************************************************************
; BITMAP_PADDING_116F
; 12 unreferenced zero bytes between descriptors.
;*******************************************************************************
BITMAP_PADDING_116F:
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;*******************************************************************************
; BITMAP_MINE
; 1 source bytes/row = 8 expanded display pixels = 4 object X units, 16 rows
; Source mask size: 16 bytes ($10)
; Descriptor total size: 18 bytes ($12), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: MINE_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_MINE:
                        DB      $01,$10           ; source width bytes, height rows
                        DB      $08                     ; row 00: . . . . 1 . . .
                        DB      $5D                     ; row 01: . 1 . 1 1 1 . 1
                        DB      $3E                     ; row 02: . . 1 1 1 1 1 .
                        DB      $7F                     ; row 03: . 1 1 1 1 1 1 1
                        DB      $3E                     ; row 04: . . 1 1 1 1 1 .
                        DB      $1C                     ; row 05: . . . 1 1 1 . .
                        DB      $2A                     ; row 06: . . 1 . 1 . 1 .
                        DB      $08                     ; row 07: . . . . 1 . . .
                        DB      $00                     ; row 08: . . . . . . . .
                        DB      $08                     ; row 09: . . . . 1 . . .
                        DB      $00                     ; row 10: . . . . . . . .
                        DB      $10                     ; row 11: . . . 1 . . . .
                        DB      $00                     ; row 12: . . . . . . . .
                        DB      $00                     ; row 13: . . . . . . . .
                        DB      $20                     ; row 14: . . 1 . . . . .
                        DB      $00                     ; row 15: . . . . . . . .

;*******************************************************************************
; BITMAP_MINE_HIT
; 1 source bytes/row = 8 expanded display pixels = 4 object X units, 16 rows
; Source mask size: 16 bytes ($10)
; Descriptor total size: 18 bytes ($12), including 2-byte width/height header
; Pixels: . = color 0; 1 = OBJECT_COLOR through port $19
; Consumer: MINE_BITMAP_SEQUENCE
;*******************************************************************************
BITMAP_MINE_HIT:
                        DB      $01,$10           ; source width bytes, height rows
                        DB      $91                     ; row 00: 1 . . 1 . . . 1
                        DB      $52                     ; row 01: . 1 . 1 . . 1 .
                        DB      $44                     ; row 02: . 1 . . . 1 . .
                        DB      $28                     ; row 03: . . 1 . 1 . . .
                        DB      $18                     ; row 04: . . . 1 1 . . .
                        DB      $25                     ; row 05: . . 1 . . 1 . 1
                        DB      $A4                     ; row 06: 1 . 1 . . 1 . .
                        DB      $18                     ; row 07: . . . 1 1 . . .
                        DB      $28                     ; row 08: . . 1 . 1 . . .
                        DB      $44                     ; row 09: . 1 . . . 1 . .
                        DB      $42                     ; row 10: . 1 . . . . 1 .
                        DB      $92                     ; row 11: 1 . . 1 . . 1 .
                        DB      $09                     ; row 12: . . . . 1 . . 1
                        DB      $10                     ; row 13: . . . 1 . . . .
                        DB      $08                     ; row 14: . . . . 1 . . .
                        DB      $10                     ; row 15: . . . 1 . . . .
;-------------------------------------------------------------------------------
; $119F-$134C: 43 ten-row font glyphs for character codes $30-$5A
;-------------------------------------------------------------------------------
; DRAW_CHARACTER subtracts $30 and multiplies the index by ten.  Each source
; byte is one 8-pixel 1bpp row, MSB first.  Function Generator expand mode
; maps . to the selected background color and 1 to the selected text color.
; Codes $3A-$3F are solid full-mask slots, not punctuation artwork.  No ROM
; string uses them.  Code $40 is the blank used by ROM strings.
FONT_BITMAPS:

;*******************************************************************************
; FONT_GLYPH_0: ASCII $30 '0', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_0:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $66                     ; row 05: . 1 1 . . 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_1: ASCII $31 '1', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_1:
                        DB      $18                     ; row 00: . . . 1 1 . . .
                        DB      $38                     ; row 01: . . 1 1 1 . . .
                        DB      $18                     ; row 02: . . . 1 1 . . .
                        DB      $18                     ; row 03: . . . 1 1 . . .
                        DB      $18                     ; row 04: . . . 1 1 . . .
                        DB      $18                     ; row 05: . . . 1 1 . . .
                        DB      $18                     ; row 06: . . . 1 1 . . .
                        DB      $18                     ; row 07: . . . 1 1 . . .
                        DB      $3C                     ; row 08: . . 1 1 1 1 . .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_2: ASCII $32 '2', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_2:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $06                     ; row 03: . . . . . 1 1 .
                        DB      $3E                     ; row 04: . . 1 1 1 1 1 .
                        DB      $7C                     ; row 05: . 1 1 1 1 1 . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $60                     ; row 07: . 1 1 . . . . .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 09: . 1 1 1 1 1 1 .

;*******************************************************************************
; FONT_GLYPH_3: ASCII $33 '3', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_3:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $06                     ; row 03: . . . . . 1 1 .
                        DB      $1C                     ; row 04: . . . 1 1 1 . .
                        DB      $1E                     ; row 05: . . . 1 1 1 1 .
                        DB      $06                     ; row 06: . . . . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_4: ASCII $34 '4', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_4:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 04: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $06                     ; row 06: . . . . . 1 1 .
                        DB      $06                     ; row 07: . . . . . 1 1 .
                        DB      $06                     ; row 08: . . . . . 1 1 .
                        DB      $06                     ; row 09: . . . . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_5: ASCII $35 '5', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_5:
                        DB      $7C                     ; row 00: . 1 1 1 1 1 . .
                        DB      $7C                     ; row 01: . 1 1 1 1 1 . .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $7C                     ; row 04: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $06                     ; row 06: . . . . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_6: ASCII $36 '6', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_6:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7C                     ; row 01: . 1 1 1 1 1 . .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $7C                     ; row 04: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_7: ASCII $37 '7', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_7:
                        DB      $7E                     ; row 00: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $06                     ; row 02: . . . . . 1 1 .
                        DB      $0E                     ; row 03: . . . . 1 1 1 .
                        DB      $0C                     ; row 04: . . . . 1 1 . .
                        DB      $1C                     ; row 05: . . . 1 1 1 . .
                        DB      $18                     ; row 06: . . . 1 1 . . .
                        DB      $38                     ; row 07: . . 1 1 1 . . .
                        DB      $30                     ; row 08: . . 1 1 . . . .
                        DB      $30                     ; row 09: . . 1 1 . . . .

;*******************************************************************************
; FONT_GLYPH_8: ASCII $38 '8', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_8:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $3C                     ; row 04: . . 1 1 1 1 . .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_9: ASCII $39 '9', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_9:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 04: . 1 1 1 1 1 1 .
                        DB      $3E                     ; row 05: . . 1 1 1 1 1 .
                        DB      $06                     ; row 06: . . . . . 1 1 .
                        DB      $06                     ; row 07: . . . . . 1 1 .
                        DB      $3E                     ; row 08: . . 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_FULL_MASK_3A: code $3A, solid 8x10 1bpp mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_FULL_MASK_3A:
                        DB      $FF                     ; row 00: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 01: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 02: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 03: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 04: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 05: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 07: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 08: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 09: 1 1 1 1 1 1 1 1

;*******************************************************************************
; FONT_GLYPH_FULL_MASK_3B: code $3B, solid 8x10 1bpp mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_FULL_MASK_3B:
                        DB      $FF                     ; row 00: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 01: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 02: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 03: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 04: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 05: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 07: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 08: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 09: 1 1 1 1 1 1 1 1

;*******************************************************************************
; FONT_GLYPH_FULL_MASK_3C: code $3C, solid 8x10 1bpp mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_FULL_MASK_3C:
                        DB      $FF                     ; row 00: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 01: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 02: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 03: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 04: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 05: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 07: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 08: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 09: 1 1 1 1 1 1 1 1

;*******************************************************************************
; FONT_GLYPH_FULL_MASK_3D: code $3D, solid 8x10 1bpp mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_FULL_MASK_3D:
                        DB      $FF                     ; row 00: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 01: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 02: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 03: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 04: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 05: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 07: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 08: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 09: 1 1 1 1 1 1 1 1

;*******************************************************************************
; FONT_GLYPH_FULL_MASK_3E: code $3E, solid 8x10 1bpp mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_FULL_MASK_3E:
                        DB      $FF                     ; row 00: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 01: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 02: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 03: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 04: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 05: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 07: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 08: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 09: 1 1 1 1 1 1 1 1

;*******************************************************************************
; FONT_GLYPH_FULL_MASK_3F: code $3F, solid 8x10 1bpp mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_FULL_MASK_3F:
                        DB      $FF                     ; row 00: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 01: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 02: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 03: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 04: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 05: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 07: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 08: 1 1 1 1 1 1 1 1
                        DB      $FF                     ; row 09: 1 1 1 1 1 1 1 1

;*******************************************************************************
; FONT_GLYPH_BLANK: ASCII $40 blank, 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_BLANK:
                        DB      $00                     ; row 00: . . . . . . . .
                        DB      $00                     ; row 01: . . . . . . . .
                        DB      $00                     ; row 02: . . . . . . . .
                        DB      $00                     ; row 03: . . . . . . . .
                        DB      $00                     ; row 04: . . . . . . . .
                        DB      $00                     ; row 05: . . . . . . . .
                        DB      $00                     ; row 06: . . . . . . . .
                        DB      $00                     ; row 07: . . . . . . . .
                        DB      $00                     ; row 08: . . . . . . . .
                        DB      $00                     ; row 09: . . . . . . . .

;*******************************************************************************
; FONT_GLYPH_A: ASCII $41 'A', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_A:
                        DB      $18                     ; row 00: . . . 1 1 . . .
                        DB      $3C                     ; row 01: . . 1 1 1 1 . .
                        DB      $7E                     ; row 02: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $66                     ; row 05: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 06: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 07: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 08: . 1 1 . . 1 1 .
                        DB      $66                     ; row 09: . 1 1 . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_B: ASCII $42 'B', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_B:
                        DB      $7C                     ; row 00: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $7C                     ; row 04: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $7C                     ; row 09: . 1 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_C: ASCII $43 'C', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_C:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $60                     ; row 04: . 1 1 . . . . .
                        DB      $60                     ; row 05: . 1 1 . . . . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_D: ASCII $44 'D', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_D:
                        DB      $7C                     ; row 00: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $66                     ; row 05: . 1 1 . . 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $7C                     ; row 09: . 1 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_E: ASCII $45 'E', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_E:
                        DB      $7E                     ; row 00: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $7C                     ; row 04: . 1 1 1 1 1 . .
                        DB      $7C                     ; row 05: . 1 1 1 1 1 . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $60                     ; row 07: . 1 1 . . . . .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 09: . 1 1 1 1 1 1 .

;*******************************************************************************
; FONT_GLYPH_F: ASCII $46 'F', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_F:
                        DB      $7E                     ; row 00: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $7C                     ; row 04: . 1 1 1 1 1 . .
                        DB      $7C                     ; row 05: . 1 1 1 1 1 . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $60                     ; row 07: . 1 1 . . . . .
                        DB      $60                     ; row 08: . 1 1 . . . . .
                        DB      $60                     ; row 09: . 1 1 . . . . .

;*******************************************************************************
; FONT_GLYPH_G: ASCII $47 'G', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_G:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $60                     ; row 04: . 1 1 . . . . .
                        DB      $6E                     ; row 05: . 1 1 . 1 1 1 .
                        DB      $6E                     ; row 06: . 1 1 . 1 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_H: ASCII $48 'H', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_H:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 04: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $66                     ; row 08: . 1 1 . . 1 1 .
                        DB      $66                     ; row 09: . 1 1 . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_I: ASCII $49 'I', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_I:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $3C                     ; row 01: . . 1 1 1 1 . .
                        DB      $18                     ; row 02: . . . 1 1 . . .
                        DB      $18                     ; row 03: . . . 1 1 . . .
                        DB      $18                     ; row 04: . . . 1 1 . . .
                        DB      $18                     ; row 05: . . . 1 1 . . .
                        DB      $18                     ; row 06: . . . 1 1 . . .
                        DB      $18                     ; row 07: . . . 1 1 . . .
                        DB      $3C                     ; row 08: . . 1 1 1 1 . .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_J: ASCII $4A 'J', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_J:
                        DB      $06                     ; row 00: . . . . . 1 1 .
                        DB      $06                     ; row 01: . . . . . 1 1 .
                        DB      $06                     ; row 02: . . . . . 1 1 .
                        DB      $06                     ; row 03: . . . . . 1 1 .
                        DB      $06                     ; row 04: . . . . . 1 1 .
                        DB      $06                     ; row 05: . . . . . 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_K: ASCII $4B 'K', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_K:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $6E                     ; row 02: . 1 1 . 1 1 1 .
                        DB      $7C                     ; row 03: . 1 1 1 1 1 . .
                        DB      $78                     ; row 04: . 1 1 1 1 . . .
                        DB      $78                     ; row 05: . 1 1 1 1 . . .
                        DB      $6C                     ; row 06: . 1 1 . 1 1 . .
                        DB      $6E                     ; row 07: . 1 1 . 1 1 1 .
                        DB      $66                     ; row 08: . 1 1 . . 1 1 .
                        DB      $66                     ; row 09: . 1 1 . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_L: ASCII $4C 'L', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_L:
                        DB      $60                     ; row 00: . 1 1 . . . . .
                        DB      $60                     ; row 01: . 1 1 . . . . .
                        DB      $60                     ; row 02: . 1 1 . . . . .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $60                     ; row 04: . 1 1 . . . . .
                        DB      $60                     ; row 05: . 1 1 . . . . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $60                     ; row 07: . 1 1 . . . . .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 09: . 1 1 1 1 1 1 .

;*******************************************************************************
; FONT_GLYPH_M: ASCII $4D 'M', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_M:
                        DB      $C3                     ; row 00: 1 1 . . . . 1 1
                        DB      $E7                     ; row 01: 1 1 1 . . 1 1 1
                        DB      $E7                     ; row 02: 1 1 1 . . 1 1 1
                        DB      $DB                     ; row 03: 1 1 . 1 1 . 1 1
                        DB      $DB                     ; row 04: 1 1 . 1 1 . 1 1
                        DB      $C3                     ; row 05: 1 1 . . . . 1 1
                        DB      $C3                     ; row 06: 1 1 . . . . 1 1
                        DB      $C3                     ; row 07: 1 1 . . . . 1 1
                        DB      $C3                     ; row 08: 1 1 . . . . 1 1
                        DB      $C3                     ; row 09: 1 1 . . . . 1 1

;*******************************************************************************
; FONT_GLYPH_N: ASCII $4E 'N', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_N:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $76                     ; row 02: . 1 1 1 . 1 1 .
                        DB      $7E                     ; row 03: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 04: . 1 1 1 1 1 1 .
                        DB      $6E                     ; row 05: . 1 1 . 1 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $66                     ; row 08: . 1 1 . . 1 1 .
                        DB      $66                     ; row 09: . 1 1 . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_O: ASCII $4F 'O', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_O:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $66                     ; row 05: . 1 1 . . 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_P: ASCII $50 'P', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_P:
                        DB      $7C                     ; row 00: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 04: . 1 1 1 1 1 1 .
                        DB      $7C                     ; row 05: . 1 1 1 1 1 . .
                        DB      $60                     ; row 06: . 1 1 . . . . .
                        DB      $60                     ; row 07: . 1 1 . . . . .
                        DB      $60                     ; row 08: . 1 1 . . . . .
                        DB      $60                     ; row 09: . 1 1 . . . . .

;*******************************************************************************
; FONT_GLYPH_Q: ASCII $51 'Q', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_Q:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $66                     ; row 05: . 1 1 . . 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $6E                     ; row 07: . 1 1 . 1 1 1 .
                        DB      $64                     ; row 08: . 1 1 . . 1 . .
                        DB      $3A                     ; row 09: . . 1 1 1 . 1 .

;*******************************************************************************
; FONT_GLYPH_R: ASCII $52 'R', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_R:
                        DB      $7C                     ; row 00: . 1 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 04: . 1 1 1 1 1 1 .
                        DB      $7C                     ; row 05: . 1 1 1 1 1 . .
                        DB      $6E                     ; row 06: . 1 1 . 1 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $66                     ; row 08: . 1 1 . . 1 1 .
                        DB      $66                     ; row 09: . 1 1 . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_S: ASCII $53 'S', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_S:
                        DB      $3C                     ; row 00: . . 1 1 1 1 . .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $60                     ; row 03: . 1 1 . . . . .
                        DB      $7C                     ; row 04: . 1 1 1 1 1 . .
                        DB      $3E                     ; row 05: . . 1 1 1 1 1 .
                        DB      $06                     ; row 06: . . . . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_T: ASCII $54 'T', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_T:
                        DB      $7E                     ; row 00: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $18                     ; row 02: . . . 1 1 . . .
                        DB      $18                     ; row 03: . . . 1 1 . . .
                        DB      $18                     ; row 04: . . . 1 1 . . .
                        DB      $18                     ; row 05: . . . 1 1 . . .
                        DB      $18                     ; row 06: . . . 1 1 . . .
                        DB      $18                     ; row 07: . . . 1 1 . . .
                        DB      $18                     ; row 08: . . . 1 1 . . .
                        DB      $18                     ; row 09: . . . 1 1 . . .

;*******************************************************************************
; FONT_GLYPH_U: ASCII $55 'U', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_U:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $66                     ; row 05: . 1 1 . . 1 1 .
                        DB      $66                     ; row 06: . 1 1 . . 1 1 .
                        DB      $66                     ; row 07: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 09: . . 1 1 1 1 . .

;*******************************************************************************
; FONT_GLYPH_V: ASCII $56 'V', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_V:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $66                     ; row 02: . 1 1 . . 1 1 .
                        DB      $66                     ; row 03: . 1 1 . . 1 1 .
                        DB      $66                     ; row 04: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 05: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 06: . . 1 1 1 1 . .
                        DB      $3C                     ; row 07: . . 1 1 1 1 . .
                        DB      $18                     ; row 08: . . . 1 1 . . .
                        DB      $18                     ; row 09: . . . 1 1 . . .

;*******************************************************************************
; FONT_GLYPH_W: ASCII $57 'W', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_W:
                        DB      $C3                     ; row 00: 1 1 . . . . 1 1
                        DB      $C3                     ; row 01: 1 1 . . . . 1 1
                        DB      $C3                     ; row 02: 1 1 . . . . 1 1
                        DB      $DB                     ; row 03: 1 1 . 1 1 . 1 1
                        DB      $DB                     ; row 04: 1 1 . 1 1 . 1 1
                        DB      $DB                     ; row 05: 1 1 . 1 1 . 1 1
                        DB      $FF                     ; row 06: 1 1 1 1 1 1 1 1
                        DB      $E7                     ; row 07: 1 1 1 . . 1 1 1
                        DB      $C3                     ; row 08: 1 1 . . . . 1 1
                        DB      $C3                     ; row 09: 1 1 . . . . 1 1

;*******************************************************************************
; FONT_GLYPH_X: ASCII $58 'X', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_X:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 02: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 03: . . 1 1 1 1 . .
                        DB      $18                     ; row 04: . . . 1 1 . . .
                        DB      $18                     ; row 05: . . . 1 1 . . .
                        DB      $3C                     ; row 06: . . 1 1 1 1 . .
                        DB      $7E                     ; row 07: . 1 1 1 1 1 1 .
                        DB      $66                     ; row 08: . 1 1 . . 1 1 .
                        DB      $66                     ; row 09: . 1 1 . . 1 1 .

;*******************************************************************************
; FONT_GLYPH_Y: ASCII $59 'Y', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_Y:
                        DB      $66                     ; row 00: . 1 1 . . 1 1 .
                        DB      $66                     ; row 01: . 1 1 . . 1 1 .
                        DB      $7E                     ; row 02: . 1 1 1 1 1 1 .
                        DB      $3C                     ; row 03: . . 1 1 1 1 . .
                        DB      $18                     ; row 04: . . . 1 1 . . .
                        DB      $18                     ; row 05: . . . 1 1 . . .
                        DB      $18                     ; row 06: . . . 1 1 . . .
                        DB      $18                     ; row 07: . . . 1 1 . . .
                        DB      $18                     ; row 08: . . . 1 1 . . .
                        DB      $18                     ; row 09: . . . 1 1 . . .

;*******************************************************************************
; FONT_GLYPH_Z: ASCII $5A 'Z', 8x10 1bpp source mask, 10 bytes
;*******************************************************************************
FONT_GLYPH_Z:
                        DB      $7E                     ; row 00: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 01: . 1 1 1 1 1 1 .
                        DB      $06                     ; row 02: . . . . . 1 1 .
                        DB      $0E                     ; row 03: . . . . 1 1 1 .
                        DB      $1C                     ; row 04: . . . 1 1 1 . .
                        DB      $38                     ; row 05: . . 1 1 1 . . .
                        DB      $70                     ; row 06: . 1 1 1 . . . .
                        DB      $60                     ; row 07: . 1 1 . . . . .
                        DB      $7E                     ; row 08: . 1 1 1 1 1 1 .
                        DB      $7E                     ; row 09: . 1 1 1 1 1 1 .

;-------------------------------------------------------------------------------
; $134D-$136A: Fixed player-status graphics
;-------------------------------------------------------------------------------
; DRAW_PLAYER_STATUS passes each five-row, three-byte mask to DRAW_SMALL_BITMAP.
; Each row expands from 24 one-bit source pixels to 24 two-bit display pixels.
; Inline rows use . = color 0 and 1 = PLAYER_STATUS_COLOR.
;
;*******************************************************************************
; PLAYER_STATUS_CENTER_BITMAP
; 3 source bytes/row = 24 expanded display pixels = 12 logical X units, 5 rows
; Source mask size: 15 bytes ($0F); no width/height header
; Consumer: DRAW_PLAYER_STATUS at X=$4D, Y=$B8
;*******************************************************************************
PLAYER_STATUS_CENTER_BITMAP:
                        DB      $EB,$EE,$00 ; row 00: 1 1 1 . 1 . 1 1 1 1 1 . 1 1 1 . . . . . . . . .
                        DB      $4A,$A8,$00 ; row 01: . 1 . . 1 . 1 . 1 . 1 . 1 . . . . . . . . . . .
                        DB      $4A,$AC,$00 ; row 02: . 1 . . 1 . 1 . 1 . 1 . 1 1 . . . . . . . . . .
                        DB      $4A,$28,$00 ; row 03: . 1 . . 1 . 1 . . . 1 . 1 . . . . . . . . . . .
                        DB      $4A,$2E,$00 ; row 04: . 1 . . 1 . 1 . . . 1 . 1 1 1 . . . . . . . . .

;*******************************************************************************
; PLAYER_STATUS_BITMAP
; 3 source bytes/row = 24 expanded display pixels = 12 logical X units, 5 rows
; Source mask size: 15 bytes ($0F); no width/height header
; Consumer: DRAW_PLAYER_STATUS at X=$07/$82, Y=$B8
;*******************************************************************************
PLAYER_STATUS_BITMAP:
                        DB      $EE,$EF,$70 ; row 00: 1 1 1 . 1 1 1 . 1 1 1 . 1 1 1 1 . 1 1 1 . . . .
                        DB      $88,$A9,$40 ; row 01: 1 . . . 1 . . . 1 . 1 . 1 . . 1 . 1 . . . . . .
                        DB      $E8,$AF,$60 ; row 02: 1 1 1 . 1 . . . 1 . 1 . 1 1 1 1 . 1 1 . . . . .
                        DB      $28,$AA,$40 ; row 03: . . 1 . 1 . . . 1 . 1 . 1 . 1 . . 1 . . . . . .
                        DB      $EE,$E9,$70 ; row 04: 1 1 1 . 1 1 1 . 1 1 1 . 1 . . 1 . 1 1 1 . . . .

TEXT_BLANK_HIT_SCORE:
                        DB      $40,$40,$40,$40,$00                                             ; $136B

;-------------------------------------------------------------------------------
; $1370: Title text and nearby short labels
;-------------------------------------------------------------------------------
TEXT_SEAWOLF_II:
                        DB      $53,$45,$41,$57,$4F,$4C,$46,$40,$49,$49,$00                     ; $1370  SEAWOLF II.

;-------------------------------------------------------------------------------
; $137B: SUPER label
;-------------------------------------------------------------------------------
TEXT_SUPER:
                        DB      $53,$55,$50,$45,$52,$00                                         ; $137B  SUPER.

;-------------------------------------------------------------------------------
; $1381: SUB label
;-------------------------------------------------------------------------------
TEXT_SUB:
                        DB      $53,$55,$42,$00                                         ; $1381  SUB.

; $1385 is neither referenced as data nor reached as code.  It is retained as
; the inventory's sole genuinely uncertain byte rather than assigned a role.
UNCERTAIN_1385:
                        DB      $8E                                                     ; $1385

;-------------------------------------------------------------------------------
; $1386: Primary video-interrupt entry selected by the schedule tables
;-------------------------------------------------------------------------------
; ADVANCE_INTERRUPT_SCHEDULE preloads the next boundary's color-4 value into
; A'.  The entry swaps that value into A, waits exactly 90 Z80 T-states, then
; changes color register 4 at the calibrated raster position.  The paired
; EX (SP),HL instructions preserve both HL and the interrupted return address.
VIDEO_INTERRUPT_HANDLER:
                        EX      AF,AF'
                        EX      (SP),HL
                        EX      (SP),HL
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP

;-------------------------------------------------------------------------------
; $1395: Primary video-interrupt body and hardware update loop
;-------------------------------------------------------------------------------
video_interrupt_handler_body:
                        OUT     (PORT_COLOR_4),A
                        EX      AF,AF'
                        PUSH    AF
                        PUSH    BC
                        PUSH    DE
                        PUSH    HL
                        PUSH    IX
                        PUSH    IY
                        CALL    ADVANCE_INTERRUPT_SCHEDULE
                        ; Permit the five lightweight raster handlers to nest
                        ; while this interrupt performs the frame workload.
                        EI
                        ; Intentional input read; its value is discarded.
                        IN      A,(PORT_LEFT_STATION_HANDLE)
                        LD      HL,SOUND_FRAME_DIVIDER
                        LD      A,(HL)
                        INC     (HL)
                        OR      A
                        JR      NZ,decay_frame_timers

;-------------------------------------------------------------------------------
; $13AE: Pack $C1D0-$C1D9 and output both discrete-sound control ports
;-------------------------------------------------------------------------------
UPDATE_DISCRETE_SOUND:
; The reverse walk created by RL maps the six sequential timers as follows:
; D5/D4/D3 -> left torpedo/ship/mine on bits 0/1/2, and
; D2/D1/D0 -> right torpedo/ship/mine on bits 3/4/5.
; Port output precedes object service.  A collision generated by the torpedo
; updater is therefore loaded after this frame's write and decremented before
; the following write: ship-hit load $40 asserts 63 writes, mine-hit load $08
; asserts 7.  Foreground torpedo, sonar, dive, and coin producers are loaded
; between interrupts and retain their full programmed assertion count.
                        LD      HL,SOUND_RIGHT_MINE_HIT_TIMER
                        LD      BC,$0600
                        XOR     A
pack_port40_bit:        CP      (HL)
                        RL      C
                        INC     HL
                        DJNZ    pack_port40_bit
                        LD      A,C
                        OUT     (PORT_SOUND_EVENTS),A

; D6/D7/D8 become port-$41 bits 6/5/4: coin counter, left sonar,
; right sonar.  HL then advances to D9 for the dive pan/trigger field.
                        XOR     A
                        LD      BC,$0300
pack_port41_timer:      CP      (HL)
                        RL      C
                        INC     HL
                        DJNZ    pack_port41_timer
                        SLA     C
                        SLA     C
                        SLA     C
                        SLA     C
                        LD      A,(HL)
                        RLCA
                        RLCA
                        RLCA
                        AND     $07
                        LD      HL,SOUND_DIVE_PAN_XOR
                        RES     3,A
                        BIT     0,A
                        JR      Z,dive_trigger_ready
                        SET     3,A                   ; D9 bit 5 also starts dive
dive_trigger_ready:     XOR     (HL)
                        OR      C
                        OUT     (PORT_SOUND_CONTROL),A
; Round-robin workload per 60 Hz frame service: two of four targets, four of
; eight torpedoes, and one of six mines.  Each target and torpedo is therefore
; visited at 30 Hz; each mine is visited at 10 Hz.  Persistent cursors cover
; each complete pool without scanning inactive records linearly.
                        CALL    SERVICE_TARGET_POOL
                        CALL    SERVICE_TARGET_POOL
                        CALL    SERVICE_TORPEDO_POOL
                        CALL    SERVICE_TORPEDO_POOL
                        CALL    SERVICE_TORPEDO_POOL
                        CALL    SERVICE_TORPEDO_POOL
                        CALL    SERVICE_MINE_POOL
                        LD      HL,SOUND_FRAME_DIVIDER
                        DEC     (HL)
                        LD      A,(HL)
                        OR      A
                        JR      NZ,UPDATE_DISCRETE_SOUND

; All nonzero bytes in $C1CB-$C1DA decay once per video frame.  This includes
; the ten output producers at $C1D0-$C1D9 and their surrounding cadence timers.
decay_frame_timers:     LD      B,$10
                        LD      HL,SOUND_TIMER_BLOCK
decay_frame_timer:      XOR     A
                        CP      (HL)
                        JR      Z,frame_timer_done
                        DEC     (HL)
frame_timer_done:       INC     HL
                        DJNZ    decay_frame_timer
                        LD      HL,GAME_CLOCK_DIVIDER
                        XOR     A
                        CP      (HL)
                        JR      NZ,read_coin_input
                        LD      (HL),GAME_CLOCK_DIVIDER_RELOAD
                        INC     HL
                        LD      A,(HL)
                        OR      A
                        JR      Z,read_coin_input
                        SUB     $01
                        DAA
                        LD      (HL),A
read_coin_input:
coin_input_stable:      IN      A,(PORT_COIN_START)
                        LD      B,A
                        IN      A,(PORT_COIN_START)
                        CP      B
                        JR      NZ,coin_input_stable
                        AND     COIN_INPUT_MASK
                        LD      HL,COIN_INPUT_EDGE_LATCH
                        PUSH    AF
                        XOR     (HL)
                        JR      Z,save_coin_input
                        AND     (HL)
                        JR      Z,save_coin_input
                        LD      A,(COIN_INPUT_QUEUE)
                        INC     A
                        LD      (COIN_INPUT_QUEUE),A
save_coin_input:        POP     AF
                        LD      (HL),A
                        POP     IY
                        POP     IX
                        POP     HL
                        POP     DE
                        POP     BC
                        POP     AF
                        EI
                        RET
;-------------------------------------------------------------------------------
; $1448: Alternate raster-interrupt entry selected by the schedule tables
;-------------------------------------------------------------------------------
; This entry uses the same 90-T-state color-4 delay but saves only the registers
; touched by ADVANCE_INTERRUPT_SCHEDULE.  It services the five non-frame raster
; boundaries without running the game, object or sound workload.
ALTERNATE_RASTER_INTERRUPT_HANDLER:
                        EX      AF,AF'
                        EX      (SP),HL
                        EX      (SP),HL
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        OUT     (PORT_COLOR_4),A
                        EX      AF,AF'
                        PUSH    AF
                        PUSH    HL
                        CALL    ADVANCE_INTERRUPT_SCHEDULE
                        POP     HL
                        POP     AF
                        EI
                        RET

;-------------------------------------------------------------------------------
; $1463: Update one moving target from the four-record target pool
;-------------------------------------------------------------------------------
UPDATE_TARGET_OBJECT:   BIT     6,(IX+OBJECT_FLAGS)
                        JP      NZ,ADVANCE_OBJECT_HIT_ANIMATION
                        CALL    INTEGRATE_OBJECT_MOTION
                        BIT     4,(IX+OBJECT_FLAGS)
                        JR      NZ,ERASE_AND_DEACTIVATE_OBJECT

; The Super Sub advances through its two dive frames every 42 target visits.
; At the 30 Hz target cadence this is 84 video frames, about 1.4 seconds, per
; step.  Frame 2 then persists until boundary retirement or collision.
                        LD      A,(IX+OBJECT_TYPE)
                        CP      OBJECT_TYPE_SUPER_SUB
                        JR      NZ,target_bitmap_ready
                        INC     (IX+OBJECT_TIMER)
                        LD      A,(IX+OBJECT_TIMER)
                        CP      $2A
                        JR      C,target_bitmap_ready
                        LD      (IX+OBJECT_TIMER),$00
                        LD      A,(IX+OBJECT_ANIMATION_FRAME)
                        CP      $02
                        JR      NC,target_bitmap_ready
                        INC     (IX+OBJECT_ANIMATION_FRAME)
target_bitmap_ready:    CALL    SELECT_OBJECT_BITMAP
                        CALL    DRAW_OBJECT_BITMAP
                        RET

ERASE_AND_DEACTIVATE_OBJECT:
; Boundary retirement erases the last bitmap and clears ACTIVE.  Target and
; torpedo allocation tests ACTIVE only, so no timer delays subsequent reuse.
                        CALL    ERASE_OBJECT_BITMAP
                        RES     7,(IX+OBJECT_FLAGS)
                        RET

; Clear the consecutive-ship-hit count/value selected by torpedo-record parity.
; The even interleaved torpedo records belong to the left station.  This runs
; when a torpedo misses at a boundary and when it strikes a mine.
CLEAR_PLAYER_HIT_STREAK:
                        PUSH    IX
                        POP     HL
                        BIT     STATION_PORT_PARITY_BIT,L
                        LD      HL,RIGHT_HIT_STREAK_COUNT
                        JR      NZ,hit_streak_selected
                        LD      HL,LEFT_HIT_STREAK_COUNT
hit_streak_selected:
                        LD      (HL),$00
                        INC     HL
                        LD      (HL),$00
                        RET
;-------------------------------------------------------------------------------
; $14B4: Update one torpedo and resolve its collision lane
;-------------------------------------------------------------------------------
UPDATE_TORPEDO_OBJECT:  LD      HL,BITMAP_TORPEDO_NEAR
                        LD      (IX+OBJECT_BITMAP_PTR_HI),H
                        LD      (IX+OBJECT_BITMAP_PTR_LO),L
                        LD      H,(IX+OBJECT_MAGIC_ADDR_HI)
                        LD      L,(IX+OBJECT_MAGIC_ADDR_LO)
                        PUSH    HL                      ; previous draw address
                        CALL    INTEGRATE_OBJECT_MOTION
                        BIT     4,(IX+OBJECT_FLAGS)
                        PUSH    AF
                        CALL    NZ,CLEAR_PLAYER_HIT_STREAK
                        POP     AF
                        PUSH    AF
                        CALL    Z,PREPARE_OBJECT_RENDER
                        POP     AF
                        POP     HL
                        JR      NZ,ERASE_AND_DEACTIVATE_OBJECT
                        LD      A,H
                        OR      L
                        JP      Z,DRAW_NEW_TORPEDO_FRAME

; Probe seven display-RAM bytes relative to the torpedo's saved Magic write
; address: +$3F60, +$3F61, +$3FB0, +$3FB1, +$40A0, +$40F0 and +$4140.  The
; constants cross from the $0000-$3FFF write window into readable display RAM.
; Any nonzero bit in the first four bytes is accepted; the final three
; contribute only bits 6-7.  This cheap pixel test gates the lane/coordinate
; test below; it does not by itself select the collided record.
                        LD      DE,$3F60
                        ADD     HL,DE
                        LD      A,(HL)
                        INC     HL
                        OR      (HL)
                        LD      DE,$004F
                        ADD     HL,DE
                        OR      (HL)
                        INC     HL
                        OR      (HL)
                        LD      DE,$00EF
                        LD      B,A
                        ADD     HL,DE
                        OR      (HL)
                        LD      DE,$0050
                        ADD     HL,DE
                        OR      (HL)
                        ADD     HL,DE
                        OR      (HL)
                        AND     $C0
                        OR      B
                        JP      Z,DRAW_NEW_TORPEDO_FRAME
                        CALL    ERASE_OBJECT_BITMAP

; The torpedo's high-byte Y coordinate selects one of five two-record lanes.
; The table establishes the vertical band; no second Y comparison is made.
; C preserves the one-based lane number: 1-2 are targets, 3-5 are mines.
                        LD      A,(IX+OBJECT_Y_POSITION_HI)
                        LD      B,$05
                        LD      HL,TORPEDO_COLLISION_LANE_TABLE
find_collision_lane:    CP      (HL)
                        JR      NC,collision_lane_found
                        INC     HL
                        INC     HL
                        INC     HL
                        DJNZ    find_collision_lane
collision_lane_found:   LD      C,B
                        INC     HL
                        LD      E,(HL)
                        INC     HL
                        LD      D,(HL)
                        PUSH    DE
                        POP     IY
                        LD      B,$02

; Horizontal eligibility is:
;   delta = torpedo_x + 4 - candidate_x
;   0 <= delta < 4 * (bitmap source width + 1)
; The width byte is the source width used by the expanded object renderer.
; ACTIVE must be set and HIT_ANIMATION must be clear, preventing repeat hits.
scan_collision_candidates:
                        BIT     7,(IY+OBJECT_FLAGS)
                        JR      Z,next_collision_candidate
                        LD      A,(IX+OBJECT_X_POSITION_HI)
                        ADD     A,TORPEDO_COLLISION_X_BIAS
                        SUB     (IY+OBJECT_X_POSITION_HI)
                        JR      C,next_collision_candidate
                        LD      H,(IY+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IY+OBJECT_BITMAP_PTR_LO)
                        LD      D,(HL)
                        INC     D
                        SLA     D
                        SLA     D
                        CP      D
                        JR      NC,next_collision_candidate
                        BIT     6,(IY+OBJECT_FLAGS)
                        JR      NZ,next_collision_candidate
                        XOR     A
                        LD      (IY+OBJECT_TIMER),A
                        SET     6,(IY+OBJECT_FLAGS)
                        SET     5,(IY+OBJECT_FLAGS)

; The collision resolver reaches this producer after a torpedo overlaps a
; candidate.  Interleaved torpedo records have even low addresses for the left
; station and odd low addresses for the right.  The selected candidate records
; that ownership in HIT_SIDE; D becomes the station's ship/mine output mask.
SELECT_COLLISION_SOUND_SIDE:
                        PUSH    IX
                        POP     HL
                        LD      D,COLLISION_SOUND_SIDE_RIGHT
                        RES     OBJECT_FLAG_HIT_SIDE_BIT,(IY+OBJECT_FLAGS)
                        BIT     STATION_PORT_PARITY_BIT,L
                        JR      NZ,collision_side_selected
                        SET     OBJECT_FLAG_HIT_SIDE_BIT,(IY+OBJECT_FLAGS)
                        LD      D,COLLISION_SOUND_SIDE_LEFT
collision_side_selected:
                        LD      B,(IX+OBJECT_COLOR)
                        RES     7,(IX+OBJECT_FLAGS)

; C > 2 is a mine collision: the mine-hit mask selects port-$40 bits 2/5,
; clears the firing station's consecutive-hit streak, and loads an eight-frame
; event timer.  C <= 2 is a target collision: the ship-hit mask selects bits
; 1/4, preserves the streak, copies torpedo color to the target, and loads $40.
; The torpedo is deactivated for both classes before this selection.
TRIGGER_SHIP_OR_MINE_HIT_SOUND:
                        LD      A,COLLISION_LAST_TARGET_LANE
                        CP      C
select_mine_hit_sound:
                        LD      A,COLLISION_SOUND_CLASS_MINE
                        LD      C,MINE_HIT_SOUND_TIMER_LOAD
                        PUSH    AF
                        CALL    C,CLEAR_PLAYER_HIT_STREAK
                        POP     AF
                        JR      C,hit_sound_class_selected
select_ship_hit_sound:
                        LD      A,COLLISION_SOUND_CLASS_SHIP
                        LD      C,SHIP_HIT_SOUND_TIMER_LOAD
                        LD      (IY+OBJECT_COLOR),B
hit_sound_class_selected:
                        AND     D
                        LD      HL,SOUND_LEFT_TORPEDO_TIMER
                        LD      B,$06

; Scan port-$40 order from bit 0 / $C1D5 down to bit 5 / $C1D0.  The masks
; above never select the torpedo slots; they land only on ship-hit or mine-hit.
store_hit_sound_timer:  SRL     A
                        JR      NC,next_hit_sound_timer
                        LD      (HL),C
                        RET
next_hit_sound_timer:   DEC     HL
                        DJNZ    store_hit_sound_timer
next_collision_candidate:
                        LD      DE,OBJECT_RECORD_SIZE
                        ADD     IY,DE
                        DJNZ    scan_collision_candidates
                        RET
; Select the torpedo perspective frame from its Y coordinate, then use the
; one-byte-per-row Function Generator expander.
DRAW_NEW_TORPEDO_FRAME:
                        LD      A,(IX+OBJECT_Y_POSITION_HI)
                        LD      B,$00
                        LD      HL,TORPEDO_FRAME_Y_TABLE
find_torpedo_frame:     CP      (HL)
                        JR      NC,torpedo_frame_selected
                        INC     HL
                        INC     B
                        JR      find_torpedo_frame
torpedo_frame_selected:
                        LD      (IX+OBJECT_ANIMATION_FRAME),B
                        CALL    SELECT_OBJECT_BITMAP
                        CALL    DRAW_TORPEDO_BITMAP
                        RET

;-------------------------------------------------------------------------------
; $15AB: Update one mine from the six-record mine pool
;-------------------------------------------------------------------------------
; Live mines move right by half a pixel per 10 Hz visit and wrap at X=$A0.
; Hit mines force TIMER to zero, so their single hit bitmap lasts one mine visit
; before the following visit reaches the zero animation terminator.
UPDATE_MINE_OBJECT:     BIT     6,(IX+OBJECT_FLAGS)
                        JR      Z,move_mine_object
                        LD      (IX+OBJECT_TIMER),$00
                        JP      ADVANCE_OBJECT_HIT_ANIMATION
move_mine_object:       CALL    INTEGRATE_OBJECT_MOTION
                        BIT     4,(IX+OBJECT_FLAGS)
                        JR      Z,draw_mine_object
                        RES     4,(IX+OBJECT_FLAGS)
                        LD      (IX+OBJECT_X_POSITION_HI),$00
                        LD      (IX+OBJECT_X_POSITION_LO),$00
                        CALL    INTEGRATE_OBJECT_MOTION
draw_mine_object:       CALL    SELECT_OBJECT_BITMAP
                        CALL    DRAW_OBJECT_BITMAP
                        RET

; Select the double-width/double-height glyph path for one complete string.
DRAW_TEXT_DOUBLE_SIZE:  LD      A,$01
                        LD      (TEXT_DOUBLE_SIZE_FLAG),A
                        CALL    DRAW_TEXT
                        XOR     A
                        LD      (TEXT_DOUBLE_SIZE_FLAG),A
                        RET

;-------------------------------------------------------------------------------
; $15E4: Draw a zero-terminated text string
;-------------------------------------------------------------------------------
; HL addresses character codes.  The font begins at ASCII $30; code $40 is the
; blank used in all ROM strings.  BC and DE are preserved across the string.
DRAW_TEXT:
                        PUSH    BC
                        PUSH    DE
draw_next_character:    LD      A,(HL)
                        OR      A
                        JR      Z,text_string_complete
                        PUSH    HL
                        CALL    DRAW_CHARACTER
                        POP     HL
                        INC     HL
                        JR      draw_next_character
text_string_complete:   POP     DE
                        POP     BC
                        RET

;-------------------------------------------------------------------------------
; $15F5: Map a character code to its ten-byte font bitmap
;-------------------------------------------------------------------------------
DRAW_CHARACTER:
                        SUB     FONT_ASCII_BASE
                        LD      L,A
                        LD      H,$00
                        ADD     HL,HL                  ; 2 * character index
                        PUSH    HL
                        ADD     HL,HL
                        ADD     HL,HL                  ; 8 * character index
                        POP     DE
                        ADD     HL,DE                  ; 10 * character index
                        LD      DE,FONT_BITMAPS
                        ADD     HL,DE
                        PUSH    HL                     ; font source

                        LD      DE,(TEXT_Y_POSITION_LO)
                        LD      HL,(TEXT_X_POSITION_LO)
                        CALL    MAP_COORDINATES_TO_MAGIC_ADDRESS
                        POP     DE                     ; font source

; Supply a blank row immediately above the glyph.  The helper returns HL at
; the following video row, which is the first bitmap destination.
                        CALL    CLEAR_CHARACTER_ROW
                        ; fall through

;-------------------------------------------------------------------------------
; $1613: Render a ten-row character bitmap
;-------------------------------------------------------------------------------
DRAW_CHARACTER_ROWS:
                        LD      B,FONT_BYTES_PER_GLYPH
                        LD      A,(TEXT_DOUBLE_SIZE_FLAG)
                        OR      A
                        JR      NZ,draw_double_size_character_row

; Normal glyph: port $19 maps source 0/1 to the selected background/foreground
; colors and $08 enables expansion with replacement writes.  Programming port
; $0C resets the expansion phase.  The first write expands the source byte's
; high nibble and the second expands its low nibble, producing eight two-bit
; pixels across two display bytes.  Rows advance by $50; a blank row follows.
draw_normal_character_row:
                        PUSH    HL
                        LD      A,(TEXT_COLOR)
                        DI
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,FUNCGEN_MODE_EXPAND
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        LD      A,(DE)
                        LD      (HL),A
                        INC     HL
                        LD      (HL),A
                        EI
                        POP     HL
                        PUSH    DE
                        LD      DE,VIDEO_ROW_STRIDE
                        ADD     HL,DE
                        POP     DE
                        INC     DE
                        DJNZ    draw_normal_character_row
                        CALL    CLEAR_CHARACTER_ROW
                        LD      HL,(TEXT_X_POSITION_LO)
                        LD      DE,TEXT_NORMAL_X_ADVANCE
                        ADD     HL,DE
                        LD      (TEXT_X_POSITION_LO),HL
                        RET

; Double-size glyph, stage 1: $0C maps clear bits to color 0 and set bits to
; color 3.  Two writes of the font byte through $3FFE/$3FFF expand its high and
; low nibbles into readable scratch bytes at $7FFE/$7FFF.
;
; Stage 2 re-expands each scratch byte with the requested text colors.  Mode
; $18 is expand plus OR, so generated foreground pixels are combined with the
; existing display instead of replacing it.  Two writes per scratch byte
; consume both nibble phases and produce four destination bytes.  A $00A0 row
; stride and eight-unit X advance select the double-size layout.
draw_double_size_character_row:
                        PUSH    HL
                        LD      A,EXPAND_COLORS_0_3
                        DI
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,FUNCGEN_MODE_EXPAND
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        LD      A,(DE)
                        LD      (FUNCGEN_SCRATCH_WRITE_0),A
                        EI
                        LD      (FUNCGEN_SCRATCH_WRITE_1),A

                        LD      A,(TEXT_COLOR)
                        DI
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,FUNCGEN_MODE_EXPAND_OR
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        LD      A,(FUNCGEN_SCRATCH_READ_0)
                        LD      (HL),A
                        INC     HL
                        LD      (HL),A
                        LD      A,(FUNCGEN_SCRATCH_READ_1)
                        INC     HL
                        LD      (HL),A
                        INC     HL
                        EI
                        LD      (HL),A
                        POP     HL
                        PUSH    DE
                        LD      DE,TEXT_DOUBLE_ROW_STRIDE
                        ADD     HL,DE
                        POP     DE
                        INC     DE
                        DJNZ    draw_double_size_character_row
                        LD      HL,(TEXT_X_POSITION_LO)
                        LD      DE,TEXT_DOUBLE_X_ADVANCE
                        ADD     HL,DE
                        LD      (TEXT_X_POSITION_LO),HL
                        RET

;-------------------------------------------------------------------------------
; $1682: Draw player-specific status graphics
;-------------------------------------------------------------------------------
; With two players, identical 15-byte station panels are drawn at X=$07 and
; X=$82.  One-player mode omits the left panel.  Both modes draw the fixed
; center panel at X=$4D.  All three start at Y=$B8.
DRAW_PLAYER_STATUS:
                        LD      A,(ACTIVE_PLAYER_COUNT)
                        OR      A
                        RET     Z
                        CP      PLAYER_COUNT_TWO
                        JR      NZ,draw_right_status_panel
                        LD      B,$00
                        LD      D,PLAYER_STATUS_Y
                        LD      HL,PLAYER_STATUS_LEFT_X_WORD
                        CALL    MAP_COORDINATES_TO_MAGIC_ADDRESS
                        LD      DE,PLAYER_STATUS_BITMAP
                        CALL    DRAW_SMALL_BITMAP
draw_right_status_panel:
                        LD      B,$00
                        LD      D,PLAYER_STATUS_Y
                        LD      HL,PLAYER_STATUS_RIGHT_X_WORD
                        CALL    MAP_COORDINATES_TO_MAGIC_ADDRESS
                        LD      DE,PLAYER_STATUS_BITMAP
                        CALL    DRAW_SMALL_BITMAP
                        LD      B,$00
                        LD      D,PLAYER_STATUS_Y
                        LD      HL,PLAYER_STATUS_CENTER_X_WORD
                        CALL    MAP_COORDINATES_TO_MAGIC_ADDRESS
                        LD      DE,PLAYER_STATUS_CENTER_BITMAP
                        CALL    DRAW_SMALL_BITMAP
                        RET

;-------------------------------------------------------------------------------
; $16BC: Render a compact one-bit bitmap through the Function Generator
;-------------------------------------------------------------------------------
; DE addresses five rows of three source bytes.  Mode $08 expands each source
; byte's high and low nibble on successive writes, mapping 0 to color 0 and 1
; to color 3.  Each source byte therefore produces two display bytes; each row
; produces six.
DRAW_SMALL_BITMAP:
                        LD      C,PLAYER_STATUS_ROWS
draw_small_bitmap_row:  PUSH    HL
                        LD      A,PLAYER_STATUS_COLOR
                        DI
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,FUNCGEN_MODE_EXPAND
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        LD      B,PLAYER_STATUS_SOURCE_WIDTH
draw_small_bitmap_byte: LD      A,(DE)
                        LD      (HL),A
                        INC     HL
                        LD      (HL),A
                        INC     HL
                        INC     DE
                        DJNZ    draw_small_bitmap_byte
                        EI
                        POP     HL
                        LD      A,L
                        ADD     A,$50
                        LD      L,A
                        JR      NC,small_bitmap_row_ready
                        INC     H
small_bitmap_row_ready: DEC     C
                        JR      NZ,draw_small_bitmap_row
                        RET

;-------------------------------------------------------------------------------
; $16DF: Clear one two-byte character row and advance to the next video row
;-------------------------------------------------------------------------------
; Two zero writes in expand mode consume both nibble phases.  Because every
; text expansion pair maps source zero to color 0, the result is eight cleared
; pixels across two display bytes.
CLEAR_CHARACTER_ROW:
                        PUSH    HL
                        LD      A,(TEXT_COLOR)
                        DI
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,FUNCGEN_MODE_EXPAND
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        XOR     A
                        LD      (HL),A
                        INC     HL
                        LD      (HL),A
                        EI
                        POP     HL
                        LD      BC,VIDEO_ROW_STRIDE
                        ADD     HL,BC
                        RET

;-------------------------------------------------------------------------------
; $16F5: Advance a round-robin scheduler cursor to one object record
;-------------------------------------------------------------------------------
; HL is the saved cursor, BC the first record and DE the last record start.
; A zero cursor or the last record wraps to the pool base.  IX receives the
; selected record while HL remains available for saving as the new cursor.
SELECT_NEXT_OBJECT_RECORD:
                        LD      A,H
                        OR      L
                        JR      Z,wrap_object_cursor
                        PUSH    HL
                        OR      A
                        SBC     HL,DE
                        LD      A,H
                        OR      L
                        POP     HL
                        JR      NZ,advance_object_cursor
wrap_object_cursor:     LD      H,B
                        LD      L,C
                        JR      object_cursor_selected
advance_object_cursor:  LD      DE,OBJECT_RECORD_SIZE
                        ADD     HL,DE
object_cursor_selected: PUSH    HL
                        POP     IX
                        RET

; Return A as the timer value observed on entry.  A nonzero value is decremented
; but remains nonzero to the caller; zero-driven work therefore occurs on the
; visit after a 1-to-0 decrement.
DECAY_OBJECT_TIMER:     LD      A,(IX+OBJECT_TIMER)
                        OR      A
                        RET     Z
                        DEC     (IX+OBJECT_TIMER)
                        RET

; The interrupt calls this twice, updating two of four moving targets.
SERVICE_TARGET_POOL:    LD      HL,(TARGET_SCHEDULER_CURSOR)
                        LD      BC,TARGET_POOL_BASE
                        LD      DE,TARGET_POOL_LAST
                        CALL    SELECT_NEXT_OBJECT_RECORD
                        LD      (TARGET_SCHEDULER_CURSOR),HL
                        BIT     7,(IX+OBJECT_FLAGS)
                        PUSH    AF
                        CALL    NZ,UPDATE_TARGET_OBJECT
                        POP     AF
                        CALL    Z,DECAY_OBJECT_TIMER
                        RET

; Four calls service half of the eight interleaved torpedo records.
SERVICE_TORPEDO_POOL:   LD      HL,(TORPEDO_SCHEDULER_CURSOR)
                        LD      BC,TORPEDO_POOL_BASE
                        LD      DE,TORPEDO_POOL_LAST
                        CALL    SELECT_NEXT_OBJECT_RECORD
                        LD      (TORPEDO_SCHEDULER_CURSOR),HL
                        BIT     7,(IX+OBJECT_FLAGS)
                        CALL    NZ,UPDATE_TORPEDO_OBJECT
                        RET

; One call advances the six-record mine pool.
SERVICE_MINE_POOL:      LD      HL,(MINE_SCHEDULER_CURSOR)
                        LD      BC,MINE_POOL_BASE
                        LD      DE,MINE_POOL_LAST
                        CALL    SELECT_NEXT_OBJECT_RECORD
                        LD      (MINE_SCHEDULER_CURSOR),HL
                        BIT     7,(IX+OBJECT_FLAGS)
                        PUSH    AF
                        CALL    NZ,UPDATE_MINE_OBJECT
                        POP     AF
                        CALL    Z,DECAY_OBJECT_TIMER
                        RET
;-------------------------------------------------------------------------------
; $1766: Advance and program the active raster-interrupt schedule
;-------------------------------------------------------------------------------
; The interrupt stub has already written the current record's color-4 byte.
; This routine writes the current record's colors 5-7, then uses its embedded
; handler and motion-state words to arm the following record.
;
; A schedule cycle contains six records.  The $0C record selects
; VIDEO_INTERRUPT_HANDLER for the following $18 boundary.  Every other
; transition selects ALTERNATE_RASTER_INTERRUPT_HANDLER.  A $FF scanline ends
; the schedule and returns the cursor to the selected base.
ADVANCE_INTERRUPT_SCHEDULE:
                        LD      HL,(INTERRUPT_SCHEDULE_CURSOR)
                        INC     HL                      ; reserved
                        INC     HL                      ; color 4, written by ISR
                        INC     HL                      ; color 5
                        LD      A,(HL)
                        OUT     (PORT_COLOR_5),A
                        INC     HL
                        LD      A,(HL)
                        OUT     (PORT_COLOR_6),A
                        INC     HL
                        LD      A,(HL)
                        OUT     (PORT_COLOR_7),A

; The handler word is also the IM 2 vector-table entry for the following
; interrupt.  Port $0D supplies its low address byte; I supplies the high byte.
                        INC     HL
                        LD      A,L
                        OUT     (PORT_INTERRUPT_VECTOR),A
                        LD      A,H
                        LD      I,A

; Copy the motion-state pointer for the following record to RAM.  A null pointer
; keeps that next interrupt line fixed.
                        INC     HL
                        INC     HL
                        LD      A,(HL)
                        LD      (INTERRUPT_MOTION_STATE_PTR),A
                        INC     HL
                        LD      A,(HL)
                        LD      (INTERRUPT_MOTION_STATE_PTR+$01),A

; Select the following record, wrapping at the $FF terminator.  Its scanline is
; armed immediately and its color-4 value is parked in A' for the ISR prologue.
                        INC     HL
                        LD      A,(HL)
                        CP      RASTER_SCHEDULE_END
                        JR      NZ,raster_schedule_next_ready
                        LD      HL,(INTERRUPT_SCHEDULE_BASE)
raster_schedule_next_ready:
                        LD      (INTERRUPT_SCHEDULE_CURSOR),HL
                        LD      A,(HL)
                        OUT     (PORT_INTERRUPT_LINE),A
                        LD      (INTERRUPT_BASE_SCANLINE),A
                        INC     HL
                        INC     HL
                        EX      AF,AF'
                        LD      A,(HL)
                        EX      AF,AF'

; Four schedule transitions point at four-byte motion states initialized at
; $C212.  They animate the following base lines $18, $30, $54 and $84.
; Layout: phase timer, signed velocity, 8.8 displacement low/high.  The high
; displacement byte is added to the record's base scanline before port $0F is
; rewritten.  Each boundary reverses every $50 visits.
                        LD      HL,(INTERRUPT_MOTION_STATE_PTR)
                        LD      A,H
                        OR      L
                        RET     Z
                        DEC     (HL)
                        JR      Z,raster_motion_reverse
raster_motion_tick:     INC     HL
                        LD      A,(HL)                 ; signed velocity
raster_motion_apply_velocity:
                        INC     HL                     ; displacement low byte
                        BIT     7,A
                        JR      NZ,raster_motion_negative
                        ADD     A,(HL)
                        LD      (HL),A
                        INC     HL
                        LD      A,(HL)
                        ADC     A,$00
raster_motion_store_high:
                        LD      (HL),A
                        LD      A,(INTERRUPT_BASE_SCANLINE)
                        ADD     A,(HL)
                        OUT     (PORT_INTERRUPT_LINE),A
                        RET

; Sign-extend a negative eight-bit velocity into the high displacement byte.
raster_motion_negative:
                        ADD     A,(HL)
                        LD      (HL),A
                        INC     HL
                        LD      A,(HL)
                        ADC     A,$FF
                        JR      raster_motion_store_high

; Reverse velocity at the end of a motion phase.  Beginning the negative half
; clears the displacement, so every boundary moves upward from its base and
; returns to that base during the following positive half.
raster_motion_reverse:  LD      (HL),RASTER_MOTION_PERIOD
                        INC     HL
                        LD      A,(HL)
                        NEG
                        LD      (HL),A
                        JP      P,raster_motion_apply_velocity
                        INC     HL
                        LD      (HL),$00
                        INC     HL
                        LD      (HL),$00
                        DEC     HL
                        DEC     HL
                        JR      raster_motion_apply_velocity

;-------------------------------------------------------------------------------
; $17DA: Advance a collided target or mine through its hit-animation frames
;-------------------------------------------------------------------------------
; Targets load TIMER=$06 after a frame change.  DECAY_OBJECT_TIMER reports its
; pre-decrement value, so the next change occurs on the seventh 30 Hz visit:
; 14 video frames, about 0.233 seconds.  UPDATE_MINE_OBJECT forces TIMER to zero
; and advances its two-entry sequence on consecutive 10 Hz mine visits.  A hit
; Super Sub skips any remaining dive frames and enters explosion index 3.
ADVANCE_OBJECT_HIT_ANIMATION:
                        CALL    DECAY_OBJECT_TIMER
                        OR      A
                        RET     NZ
                        LD      (IX+OBJECT_TIMER),HIT_ANIMATION_TIMER_LOAD
                        CALL    ERASE_OBJECT_BITMAP
                        LD      A,(IX+OBJECT_TYPE)
                        CP      OBJECT_TYPE_SUPER_SUB
                        JR      NZ,advance_hit_frame
                        LD      A,(IX+OBJECT_ANIMATION_FRAME)
                        CP      $02
                        JR      NC,advance_hit_frame
                        LD      (IX+OBJECT_ANIMATION_FRAME),$02
advance_hit_frame:      INC     (IX+OBJECT_ANIMATION_FRAME)
                        CALL    SELECT_OBJECT_BITMAP
                        JP      NZ,DRAW_OBJECT_BITMAP
                        RES     7,(IX+OBJECT_FLAGS)
                        LD      (IX+OBJECT_TIMER),RETIRED_OBJECT_TIMER_LOAD
                        RET

; Clear the complete bounding box occupied by the prior bitmap.  Control $00
; selects shift 0, no rotate/expand/blend/flop: every Magic-window write
; replaces one display byte directly.  The saved address is the prior draw's
; $0000-$3FFF Function Generator address.  For each descriptor row the routine
; clears 2*(source width+1) bytes, covering expanded pixels and shift spill;
; display rows are $50 bytes apart.
ERASE_OBJECT_BITMAP:    LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        LD      E,(HL)
                        INC     E
                        INC     HL
                        LD      D,(HL)
                        LD      H,(IX+OBJECT_MAGIC_ADDR_HI)
                        LD      L,(IX+OBJECT_MAGIC_ADDR_LO)
                        XOR     A                       ; FUNCGEN_MODE_REPLACE
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        XOR     A
                        LD      C,A
erase_object_row:       LD      B,E
                        PUSH    HL
erase_object_byte:      LD      (HL),C
                        INC     HL
                        LD      (HL),C
                        INC     HL
                        DJNZ    erase_object_byte
                        POP     HL
                        LD      A,L
                        ADD     A,$50
                        LD      L,A
                        JR      NC,erase_row_address_ready
                        INC     H
erase_row_address_ready:
                        DEC     D
                        JR      NZ,erase_object_row
                        RET

; OBJECT_TYPE selects an animation pointer list; OBJECT_ANIMATION_FRAME selects
; one bitmap descriptor within that list.  A null pointer terminates a hit
; animation and is returned with Z set.
SELECT_OBJECT_BITMAP:   LD      A,(IX+OBJECT_TYPE)
                        LD      HL,OBJECT_BITMAP_SET_TABLE
                        CALL    LOOKUP_WORD_BY_INDEX
                        LD      A,(IX+OBJECT_ANIMATION_FRAME)
                        CALL    LOOKUP_WORD_BY_INDEX
                        LD      (IX+OBJECT_BITMAP_PTR_LO),L
                        LD      (IX+OBJECT_BITMAP_PTR_HI),H
                        LD      A,H
                        OR      L
                        RET

LOOKUP_WORD_BY_INDEX:   SLA     A
                        LD      D,$00
                        LD      E,A
                        ADD     HL,DE
                        LD      E,(HL)
                        INC     HL
                        LD      D,(HL)
                        EX      DE,HL
                        RET
;-------------------------------------------------------------------------------
; $1856: Expand and draw the selected one-bit object bitmap
;-------------------------------------------------------------------------------
; Constructors seed control $08 for forward objects or $48 for reverse objects.
; The coordinate mapper replaces control bits 0-1 with the current two-bit-
; pixel shift.  Port $19 maps clear source bits to color 0 and set bits to the
; object's selected color.  Neither object path uses OR, XOR or rotate.
DRAW_OBJECT_BITMAP:     BIT     FUNCGEN_FLOP_BIT,(IX+OBJECT_FUNCGEN_CONTROL)
                        JP      NZ,DRAW_OBJECT_BITMAP_REVERSED
                        CALL    PREPARE_OBJECT_RENDER
                        LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        LD      D,(IX+OBJECT_MAGIC_ADDR_HI)
                        LD      E,(IX+OBJECT_MAGIC_ADDR_LO)
                        PUSH    HL
                        POP     IY
                        INC     HL
                        INC     HL
                        LD      C,(IY+BITMAP_ROW_COUNT)
draw_object_forward_row:
                        LD      B,(IY+BITMAP_SOURCE_WIDTH)
                        PUSH    DE
                        BIT     FUNCGEN_EXPAND_BIT,(IX+OBJECT_FUNCGEN_CONTROL)
                        JR      NZ,draw_forward_expanded
draw_forward_byte:      LD      A,(HL)
                        LD      (DE),A
                        INC     DE
                        INC     HL
                        DJNZ    draw_forward_byte
                        JR      finish_forward_row
draw_forward_expanded:  LD      A,(HL)
; Two writes consume the expander's high- then low-nibble phases, producing
; two display bytes from one one-bit source byte.
                        LD      (DE),A
                        INC     DE
                        LD      (DE),A
                        INC     DE
                        INC     HL
                        DJNZ    draw_forward_expanded
; The destination zero write flushes the shift pipeline into the byte following
; the bitmap.  The scratch zero write consumes the other expansion phase and
; leaves zero in the previous-data latch before the next row.
finish_forward_row:     XOR     A
                        LD      (DE),A
                        LD      (FUNCGEN_SCRATCH_WRITE_1),A
                        POP     DE
                        DEC     C
                        RET     Z
                        LD      A,E
                        ADD     A,$50
                        LD      E,A
                        JR      NC,draw_object_forward_row
                        INC     D
                        JR      draw_object_forward_row

; Reverse drawing starts one expanded width beyond the saved left edge and
; walks Magic addresses backward.  Flop reverses the four two-bit pixels within
; each generated byte.  Complementing shift bits 0-1 with XOR $03 aligns that
; byte-level flop with the backward address walk, completing the mirror.
DRAW_OBJECT_BITMAP_REVERSED:
                        CALL    PREPARE_OBJECT_RENDER
                        LD      D,(IX+OBJECT_MAGIC_ADDR_HI)
                        LD      E,(IX+OBJECT_MAGIC_ADDR_LO)
                        LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        PUSH    HL
                        POP     IY
                        INC     HL
                        INC     HL
                        LD      B,(IY+BITMAP_SOURCE_WIDTH)
                        BIT     FUNCGEN_EXPAND_BIT,(IX+OBJECT_FUNCGEN_CONTROL)
                        JR      Z,reverse_width_ready
                        SLA     B
reverse_width_ready:    LD      A,(IX+OBJECT_FUNCGEN_CONTROL)
                        XOR     FUNCGEN_SHIFT_MASK
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        PUSH    HL
                        LD      L,B
                        LD      H,$00
                        ADD     HL,DE
                        EX      DE,HL
                        POP     HL
                        LD      C,(IY+BITMAP_ROW_COUNT)
draw_object_reverse_row:
                        LD      B,(IY+BITMAP_SOURCE_WIDTH)
                        PUSH    DE
                        BIT     FUNCGEN_EXPAND_BIT,(IX+OBJECT_FUNCGEN_CONTROL)
                        JR      NZ,draw_reverse_expanded
draw_reverse_byte:      LD      A,(HL)
                        LD      (DE),A
                        DEC     DE
                        INC     HL
                        DJNZ    draw_reverse_byte
                        JR      finish_reverse_row
draw_reverse_expanded:  LD      A,(HL)
; The same high-/low-nibble expansion order is emitted at descending addresses.
                        LD      (DE),A
                        DEC     DE
                        LD      (DE),A
                        DEC     DE
                        INC     HL
                        DJNZ    draw_reverse_expanded
; Flush the trailing shifted pixels, balance expansion phase, and clear the
; Function Generator previous-data latch exactly as in the forward path.
finish_reverse_row:     XOR     A
                        LD      (DE),A
                        LD      (FUNCGEN_SCRATCH_WRITE_1),A
                        POP     DE
                        DEC     C
                        RET     Z
                        LD      A,E
                        ADD     A,$50
                        LD      E,A
                        JR      NC,draw_object_reverse_row
                        INC     D
                        JR      draw_object_reverse_row
;-------------------------------------------------------------------------------
; $18FA: Draw the narrow perspective torpedo bitmap
;-------------------------------------------------------------------------------
; Torpedo frames are a vertical one-byte-per-row stream.  Control $08 plus the
; mapped shift expands each source byte: the two writes consume its high and
; low nibbles and produce two display bytes.  Torpedoes never set flop and do
; not use OR/XOR/rotate.  Successive source bytes advance one $50-byte row.
DRAW_TORPEDO_BITMAP:    LD      A,(IX+OBJECT_COLOR)
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,(IX+OBJECT_FUNCGEN_CONTROL)
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        LD      D,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      E,(IX+OBJECT_BITMAP_PTR_LO)
                        LD      H,(IX+OBJECT_MAGIC_ADDR_HI)
                        LD      L,(IX+OBJECT_MAGIC_ADDR_LO)
                        INC     DE
                        LD      A,(DE)
                        LD      B,A
                        INC     DE
draw_torpedo_row:       LD      A,(DE)
                        INC     DE
                        LD      (HL),A
                        INC     HL
                        LD      (HL),A
                        LD      A,L
                        ADD     A,$4F
                        LD      L,A
                        JR      NC,torpedo_row_address_ready
                        INC     H
torpedo_row_address_ready:
                        DJNZ    draw_torpedo_row
                        RET

; Convert fixed-point object coordinates to a Function Generator write address
; and shift.  OBJECT_Y_POSITION_HI is the bitmap's bottom edge, so its row
; count is subtracted before mapping the top-left draw position.
CALCULATE_OBJECT_SCREEN_ADDRESS:
                        LD      B,(IX+OBJECT_FUNCGEN_CONTROL)
                        LD      A,(IX+OBJECT_Y_POSITION_HI)
                        LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        INC     HL
                        SUB     (HL)
                        LD      D,A
                        LD      H,(IX+OBJECT_X_POSITION_HI)
                        LD      L,(IX+OBJECT_X_POSITION_LO)
                        CALL    MAP_COORDINATES_TO_MAGIC_ADDRESS
                        RET

; Program the port-$19 expansion colors and port-$0C control, then retain the
; mapped $0000-$3FFF write-window address.  The coordinate mapper inserts the
; horizontal two-bit-pixel shift into control bits 0-1.
PREPARE_OBJECT_RENDER:  CALL    CALCULATE_OBJECT_SCREEN_ADDRESS
                        LD      A,(IX+OBJECT_COLOR)
                        OUT     (PORT_EXPAND_COLOR),A
                        LD      A,B
                        OUT     (PORT_FUNCGEN_CONTROL),A
                        LD      (IX+OBJECT_FUNCGEN_CONTROL),B
                        LD      (IX+OBJECT_MAGIC_ADDR_HI),H
                        LD      (IX+OBJECT_MAGIC_ADDR_LO),L
                        RET

; D = video row; HL = 8.8 horizontal coordinate; B = base Function Generator
; control.  Returns the Magic-window address HL=row*80+x/2.  The doubled 8.8 X
; coordinate supplies shift 0-3 in B bits 0-1; all other control bits survive.
MAP_COORDINATES_TO_MAGIC_ADDRESS:
                        LD      A,$03
                        CPL
                        AND     B
                        LD      B,A
                        PUSH    HL
                        ADD     HL,HL
                        LD      A,H
                        AND     $03
                        OR      B
                        LD      B,A
                        LD      L,D
                        LD      H,$00
                        ADD     HL,HL
                        ADD     HL,HL
                        ADD     HL,HL
                        ADD     HL,HL
                        LD      D,H
                        LD      E,L
                        ADD     HL,HL
                        ADD     HL,HL
                        ADD     HL,DE                  ; row * $50
                        POP     DE
                        SRL     D
                        LD      E,D
                        LD      D,$00
                        ADD     HL,DE
                        RET
;-------------------------------------------------------------------------------
; $1971: Integrate one object's 8.8 fixed-point motion
;-------------------------------------------------------------------------------
; Y velocity is accelerated, then added to Y position.  Crossing OBJECT_Y_MIN
; clamps the coordinate and raises OBJECT_FLAG_AT_BOUNDARY.  X uses constant
; velocity and is clamped against zero/OBJECT_X_MAX through the same flag.
INTEGRATE_OBJECT_MOTION:
                        LD      L,(IX+OBJECT_Y_VELOCITY_LO)
                        LD      H,(IX+OBJECT_Y_VELOCITY_HI)
                        LD      E,(IX+OBJECT_Y_ACCEL_LO)
                        LD      D,(IX+OBJECT_Y_ACCEL_HI)
                        ADD     HL,DE
                        LD      (IX+OBJECT_Y_VELOCITY_LO),L
                        LD      (IX+OBJECT_Y_VELOCITY_HI),H
                        LD      E,(IX+OBJECT_Y_POSITION_LO)
                        LD      D,(IX+OBJECT_Y_POSITION_HI)
                        ADD     HL,DE
                        LD      (IX+OBJECT_Y_POSITION_LO),L
                        LD      (IX+OBJECT_Y_POSITION_HI),H
                        LD      D,(IX+OBJECT_Y_MIN)
                        LD      E,$00
                        OR      A
                        SBC     HL,DE
                        JR      NC,object_y_in_range
                        SET     4,(IX+OBJECT_FLAGS)
                        LD      (IX+OBJECT_Y_POSITION_LO),E
                        LD      (IX+OBJECT_Y_POSITION_HI),D
object_y_in_range:
                        LD      L,(IX+OBJECT_X_VELOCITY_LO)
                        LD      H,(IX+OBJECT_X_VELOCITY_HI)
                        LD      E,(IX+OBJECT_X_POSITION_LO)
                        LD      D,(IX+OBJECT_X_POSITION_HI)
                        ADD     HL,DE
                        LD      (IX+OBJECT_X_POSITION_LO),L
                        LD      (IX+OBJECT_X_POSITION_HI),H
                        PUSH    HL
                        LD      DE,$0000
                        OR      A
                        SBC     HL,DE
                        CALL    C,CLAMP_OBJECT_X_AND_FLAG_BOUNDARY
                        POP     HL
                        LD      D,(IX+OBJECT_X_MAX)
                        OR      A
                        SBC     HL,DE
                        CALL    NC,CLAMP_OBJECT_X_AND_FLAG_BOUNDARY
                        RET

CLAMP_OBJECT_X_AND_FLAG_BOUNDARY:
                        SET     4,(IX+OBJECT_FLAGS)
                        LD      (IX+OBJECT_X_POSITION_LO),E
                        LD      (IX+OBJECT_X_POSITION_HI),D
                        RET

;-------------------------------------------------------------------------------
; $19D8: Color-monitor raster schedule selected by S1-7
;-------------------------------------------------------------------------------
; Each record is:
;   DB scanline, reserved, color4, color5, color6, color7
;   DW interrupt handler, optional raster-motion state
;
; The scanline order crosses the hardware counter wrap: $84, $D7, $0C, $18,
; $30, $54.  The handler and motion words in each record configure the following
; scanline.  The $0C record therefore selects the full frame service at $18.
; Records $0C, $18, $30 and $54 animate bases $18, $30, $54 and $84.
COLOR_MONITOR_INTERRUPT_SCHEDULE:
color_monitor_schedule_84:
                        DB      $84,$00,$DC,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
color_monitor_schedule_d7:
                        DB      $D7,$00,$1C,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
color_monitor_schedule_0c:
                        DB      $0C,$00,$D8,$77,$58,$00
                        DW      VIDEO_INTERRUPT_HANDLER,RASTER_MOTION_STATE_0 ; next: $18
color_monitor_schedule_18:
                        DB      $18,$00,$D9,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_1 ; next: $30
color_monitor_schedule_30:
                        DB      $30,$00,$DA,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_2 ; next: $54
color_monitor_schedule_54:
                        DB      $54,$00,$DB,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_3 ; next: $84
                        DB      RASTER_SCHEDULE_END,$FF   ; second byte is table padding

;-------------------------------------------------------------------------------
; $1A16: Black-and-white-monitor raster schedule selected by S1-7
;-------------------------------------------------------------------------------
MONOCHROME_MONITOR_INTERRUPT_SCHEDULE:
monochrome_monitor_schedule_84:
                        DB      $84,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
monochrome_monitor_schedule_d7:
                        DB      $D7,$00,$01,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
monochrome_monitor_schedule_0c:
                        DB      $0C,$00,$00,$03,$07,$05
                        DW      VIDEO_INTERRUPT_HANDLER,RASTER_MOTION_STATE_0 ; next: $18
monochrome_monitor_schedule_18:
                        DB      $18,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_1 ; next: $30
monochrome_monitor_schedule_30:
                        DB      $30,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_2 ; next: $54
monochrome_monitor_schedule_54:
                        DB      $54,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_3 ; next: $84
                        DB      RASTER_SCHEDULE_END

;-------------------------------------------------------------------------------
; $1A53: Per-type bitmap and hit-animation pointer lists
;-------------------------------------------------------------------------------
; Frame zero is the live object.  Target collision handling increments the
; frame every seventh target visit after loading TIMER=$06 and deactivates the
; record at the zero terminator.  Mines intentionally advance on consecutive
; mine visits.  Shared tails are ROM-space reuse.
OBJECT_BITMAP_POINTER_LISTS:
WARSHIP_A_BITMAP_SEQUENCE:
                        DW      BITMAP_WARSHIP_A
                        DW      BITMAP_LARGE_HIT_FRAME_1
                        DW      BITMAP_LARGE_HIT_FRAME_2
                        DW      BITMAP_LARGE_HIT_FRAME_3
                        DW      BITMAP_LARGE_HIT_FRAME_4
                        DW      BITMAP_LARGE_HIT_FRAME_5
                        DW      BITMAP_LARGE_HIT_FRAME_6
                        DW      $0000

WARSHIP_B_BITMAP_SEQUENCE:
                        DW      BITMAP_WARSHIP_B
                        DW      BITMAP_MEDIUM_HIT_FRAME_1
                        DW      BITMAP_MEDIUM_HIT_FRAME_2
                        DW      BITMAP_MEDIUM_HIT_FRAME_3
                        DW      BITMAP_SMALL_HIT_FRAME_2
                        DW      BITMAP_SMALL_HIT_FRAME_3
                        DW      $0000

WARSHIP_C_BITMAP_SEQUENCE:
                        DW      BITMAP_WARSHIP_C
                        DW      BITMAP_LARGE_HIT_FRAME_1
                        DW      BITMAP_LARGE_HIT_FRAME_2
                        DW      BITMAP_LARGE_HIT_FRAME_3
                        DW      BITMAP_LARGE_HIT_FRAME_4
                        DW      BITMAP_LARGE_HIT_FRAME_5
                        DW      BITMAP_LARGE_HIT_FRAME_6
                        DW      $0000

FREIGHTER_A_BITMAP_SEQUENCE:
                        DW      BITMAP_FREIGHTER_A
                        DW      BITMAP_MEDIUM_HIT_FRAME_1
                        DW      BITMAP_MEDIUM_HIT_FRAME_2
                        DW      BITMAP_MEDIUM_HIT_FRAME_3
                        DW      BITMAP_SMALL_HIT_FRAME_2
                        DW      BITMAP_SMALL_HIT_FRAME_3
                        DW      $0000

FREIGHTER_B_BITMAP_SEQUENCE:
                        DW      BITMAP_FREIGHTER_B
                        DW      BITMAP_MEDIUM_HIT_FRAME_1
                        DW      BITMAP_MEDIUM_HIT_FRAME_2
                        DW      BITMAP_MEDIUM_HIT_FRAME_3
                        DW      BITMAP_SMALL_HIT_FRAME_2
                        DW      BITMAP_SMALL_HIT_FRAME_3
                        DW      $0000

PT_BOAT_BITMAP_SEQUENCE:
                        DW      BITMAP_PT_BOAT
                        DW      BITMAP_SMALL_HIT_FRAME_1
                        DW      BITMAP_SMALL_HIT_FRAME_2
                        DW      BITMAP_SMALL_HIT_FRAME_3
                        DW      $0000

; The Super Sub advances from surfaced through DIVE_1 and DIVE_2 every 42
; target updates.  A collision skips directly to SMALL_HIT_FRAME_1.
SUPER_SUB_BITMAP_SEQUENCE:
                        DW      BITMAP_SUPER_SUB_SURFACED
                        DW      BITMAP_SUPER_SUB_DIVE_1
                        DW      BITMAP_SUPER_SUB_DIVE_2
                        DW      BITMAP_SMALL_HIT_FRAME_1
                        DW      BITMAP_SMALL_HIT_FRAME_2
                        DW      BITMAP_SMALL_HIT_FRAME_3
                        DW      $0000

MINE_BITMAP_SEQUENCE:
                        DW      BITMAP_MINE
                        DW      BITMAP_MINE_HIT
                        DW      $0000

; Torpedoes select one of three perspective frames from their Y coordinate.
; They do not use the hit-animation path.
TORPEDO_BITMAP_SEQUENCE:
                        DW      BITMAP_TORPEDO_NEAR
                        DW      BITMAP_TORPEDO_MIDDLE
                        DW      BITMAP_TORPEDO_FAR
                        DW      $0000

;-------------------------------------------------------------------------------
; $1AC3: Object type to bitmap-sequence table
;-------------------------------------------------------------------------------
OBJECT_BITMAP_SET_TABLE:
                        DW      WARSHIP_A_BITMAP_SEQUENCE  ; type 0
                        DW      WARSHIP_B_BITMAP_SEQUENCE  ; type 1
                        DW      WARSHIP_C_BITMAP_SEQUENCE  ; type 2
                        DW      FREIGHTER_A_BITMAP_SEQUENCE ; type 3
                        DW      FREIGHTER_B_BITMAP_SEQUENCE ; type 4
                        DW      PT_BOAT_BITMAP_SEQUENCE     ; type 5
                        DW      MINE_BITMAP_SEQUENCE        ; type 6
                        DW      TORPEDO_BITMAP_SEQUENCE     ; type 7
                        DW      SUPER_SUB_BITMAP_SEQUENCE   ; type 8

;-------------------------------------------------------------------------------
; $1AD5: Torpedo Y thresholds and two-record collision-lane bases
;-------------------------------------------------------------------------------
; Entries are ordered from the bottom of the screen upward.  The collision
; resolver records lane numbers 5..1; lanes 5..3 are mines and 2..1 targets.
TORPEDO_COLLISION_LANE_TABLE:
                        DB      MINE_LANE_LOWER_Y
                        DW      MINE_LANE_LOWER_BASE
                        DB      MINE_LANE_MIDDLE_Y
                        DW      MINE_LANE_MIDDLE_BASE
                        DB      MINE_LANE_UPPER_Y
                        DW      MINE_LANE_UPPER_BASE
                        DB      TARGET_LANE_LOWER_Y
                        DW      TARGET_LANE_LOWER_BASE
                        DB      TARGET_LANE_UPPER_Y
                        DW      TARGET_LANE_UPPER_BASE

;-------------------------------------------------------------------------------
; $1AE4: Torpedo perspective-frame Y thresholds
;-------------------------------------------------------------------------------
TORPEDO_FRAME_Y_TABLE:
                        DB      TORPEDO_FRAME_NEAR_MIN_Y   ; frame 0: 4x21 logical / 8x21 display
                        DB      TORPEDO_FRAME_MIDDLE_MIN_Y ; frame 1: 4x21 logical / 8x21 display
                        DB      TORPEDO_FRAME_FAR_MIN_Y    ; frame 2: 4x11 logical / 8x11 display

TEXT_CONGRATULATIONS_EN:
                        DB      $43,$4F,$4E,$47,$52,$41,$54,$55,$4C,$41,$54,$49,$4F,$4E,$53,$00 ; $1AE7  CONGRATULATIONS

TEXT_CONGRATULATIONS_DE:
                        DB      $40,$40,$40,$40,$47,$52,$41,$54,$55,$4C,$41,$54,$49,$4F,$4E,$00 ; $1AF7      GRATULATION

TEXT_CONGRATULATIONS_FR:
                        DB      $40,$40,$46,$45,$4C,$49,$43,$49,$54,$41,$54,$49,$4F,$4E,$53,$00 ; $1B07    FELICITATIONS

TEXT_HIGH_SCORE:
                        DB      $48,$49,$47,$48,$40,$53,$43,$4F,$52,$45,$00                     ; $1B17  HIGH SCORE

TEXT_GAME_OVER_EN:
                        DB      $47,$41,$4D,$45,$40,$4F,$56,$45,$52,$00                         ; $1B22  GAME OVER

TEXT_GAME_OVER_DE:
                        DB      $53,$50,$49,$45,$4C,$45,$4E,$44,$45,$00                         ; $1B2C  SPIELENDE

TEXT_GAME_OVER_FR:
                        DB      $40,$40,$40,$46,$49,$4E,$40,$40,$40,$00                         ; $1B36     FIN

TEXT_EXTENDED_PATROL:
                        DB      $45,$58,$54,$45,$4E,$44,$45,$44,$40,$30,$30,$40,$50,$41,$54,$52,$4F,$4C,$00 ; $1B40  EXTENDED 00 PATROL

TEXT_BONUS:
                        DB      $42,$4F,$4E,$55,$53,$00                                         ; $1B53  BONUS

;-------------------------------------------------------------------------------
; $1B59: Nine English prompt pointer lists
;-------------------------------------------------------------------------------
ENGLISH_PROMPT_TABLE_0:
                        DW      ENGLISH_PROMPT_LINE_0,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_1,ENGLISH_PROMPT_LINE_2
                        DW      ENGLISH_PROMPT_LINE_3,ENGLISH_PROMPT_LINE_4,$0000
ENGLISH_PROMPT_TABLE_1:
                        DW      ENGLISH_PROMPT_LINE_0,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_5,ENGLISH_PROMPT_LINE_7
                        DW      ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_7,$0000
ENGLISH_PROMPT_TABLE_2:
                        DW      ENGLISH_PROMPT_LINE_0,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_1
                        DW      ENGLISH_PROMPT_LINE_2,ENGLISH_PROMPT_LINE_5,$0000
ENGLISH_PROMPT_TABLE_3:
                        DW      ENGLISH_PROMPT_LINE_3,ENGLISH_PROMPT_LINE_7,$0000
ENGLISH_PROMPT_TABLE_4:
                        DW      ENGLISH_PROMPT_LINE_0,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_1
                        DW      ENGLISH_PROMPT_LINE_2,ENGLISH_PROMPT_LINE_5,$0000
ENGLISH_PROMPT_TABLE_5:
                        DW      ENGLISH_PROMPT_LINE_3,ENGLISH_PROMPT_LINE_7,$0000
ENGLISH_PROMPT_TABLE_6:
                        DW      ENGLISH_PROMPT_LINE_0,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_1,ENGLISH_PROMPT_LINE_2
                        DW      ENGLISH_PROMPT_LINE_6,ENGLISH_PROMPT_LINE_4,$0000
ENGLISH_PROMPT_TABLE_7:
                        DW      ENGLISH_PROMPT_LINE_3,ENGLISH_PROMPT_LINE_4,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_7
                        DW      ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_7,$0000
ENGLISH_PROMPT_TABLE_8:
                        DW      ENGLISH_PROMPT_LINE_0,ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_5,ENGLISH_PROMPT_LINE_7
                        DW      ENGLISH_PROMPT_LINE_7,ENGLISH_PROMPT_LINE_7,$0000

ENGLISH_PROMPT_LINE_0:
                        DB      $54,$4F,$40,$53,$54,$41,$52,$54,$40,$47,$41,$4D,$45,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1BC3  TO START GAME

ENGLISH_PROMPT_LINE_1:
                        DB      $50,$52,$45,$53,$53,$40,$31,$40,$50,$4C,$41,$59,$45,$52,$40,$42,$55,$54,$54,$4F,$4E,$00 ; $1BD9  PRESS 1 PLAYER BUTTON

ENGLISH_PROMPT_LINE_2:
                        DB      $4F,$52,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1BEF  OR

ENGLISH_PROMPT_LINE_3:
                        DB      $49,$4E,$53,$45,$52,$54,$40,$31,$40,$4D,$4F,$52,$45,$40,$43,$4F,$49,$4E,$40,$40,$40,$00 ; $1C05  INSERT 1 MORE COIN

ENGLISH_PROMPT_LINE_4:
                        DB      $46,$4F,$52,$40,$32,$40,$50,$4C,$41,$59,$45,$52,$40,$47,$41,$4D,$45,$40,$40,$40,$40,$00 ; $1C1B  FOR 2 PLAYER GAME

ENGLISH_PROMPT_LINE_5:
                        DB      $50,$52,$45,$53,$53,$40,$32,$40,$50,$4C,$41,$59,$45,$52,$40,$42,$55,$54,$54,$4F,$4E,$00 ; $1C31  PRESS 2 PLAYER BUTTON

ENGLISH_PROMPT_LINE_6:
                        DB      $49,$4E,$53,$45,$52,$54,$40,$32,$40,$4D,$4F,$52,$45,$40,$43,$4F,$49,$4E,$53,$40,$40,$00 ; $1C47  INSERT 2 MORE COINS

ENGLISH_PROMPT_LINE_7:
                        DB      $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1C5D  

;-------------------------------------------------------------------------------
; $1C73: Nine German prompt pointer lists
;-------------------------------------------------------------------------------
GERMAN_PROMPT_TABLE_0:
                        DW      GERMAN_PROMPT_LINE_0,GERMAN_PROMPT_LINE_1,GERMAN_PROMPT_LINE_2,GERMAN_PROMPT_LINE_3
                        DW      GERMAN_PROMPT_LINE_4,GERMAN_PROMPT_LINE_5,$0000
GERMAN_PROMPT_TABLE_1:
                        DW      GERMAN_PROMPT_LINE_6,GERMAN_PROMPT_LINE_1,GERMAN_PROMPT_LINE_7,GERMAN_PROMPT_LINE_18
                        DW      GERMAN_PROMPT_LINE_18,GERMAN_PROMPT_LINE_18,$0000
GERMAN_PROMPT_TABLE_2:
                        DW      GERMAN_PROMPT_LINE_8,GERMAN_PROMPT_LINE_9,GERMAN_PROMPT_LINE_10
                        DW      GERMAN_PROMPT_LINE_18,GERMAN_PROMPT_LINE_18,$0000
GERMAN_PROMPT_TABLE_3:
                        DW      GERMAN_PROMPT_LINE_11,GERMAN_PROMPT_LINE_12,$0000
GERMAN_PROMPT_TABLE_4:
                        DW      GERMAN_PROMPT_LINE_8,GERMAN_PROMPT_LINE_9,GERMAN_PROMPT_LINE_10
                        DW      GERMAN_PROMPT_LINE_18,GERMAN_PROMPT_LINE_18,$0000
GERMAN_PROMPT_TABLE_5:
                        DW      GERMAN_PROMPT_LINE_11,GERMAN_PROMPT_LINE_12,$0000
GERMAN_PROMPT_TABLE_6:
                        DW      GERMAN_PROMPT_LINE_0,GERMAN_PROMPT_LINE_1,GERMAN_PROMPT_LINE_2,GERMAN_PROMPT_LINE_13
                        DW      GERMAN_PROMPT_LINE_14,GERMAN_PROMPT_LINE_15,$0000
GERMAN_PROMPT_TABLE_7:
                        DW      GERMAN_PROMPT_LINE_11,GERMAN_PROMPT_LINE_16,GERMAN_PROMPT_LINE_17,GERMAN_PROMPT_LINE_5
                        DW      GERMAN_PROMPT_LINE_18,GERMAN_PROMPT_LINE_18,$0000
GERMAN_PROMPT_TABLE_8:
                        DW      GERMAN_PROMPT_LINE_6,GERMAN_PROMPT_LINE_1,GERMAN_PROMPT_LINE_7,GERMAN_PROMPT_LINE_18
                        DW      GERMAN_PROMPT_LINE_18,GERMAN_PROMPT_LINE_18,$0000

GERMAN_PROMPT_LINE_0:
                        DB      $44,$52,$55,$45,$43,$4B,$45,$4E,$40,$53,$49,$45,$40,$31,$40,$53,$50,$49,$45,$4C,$45,$52,$00 ; $1CDD  DRUECKEN SIE 1 SPIELER

GERMAN_PROMPT_LINE_1:
                        DB      $4B,$4E,$4F,$50,$46,$40,$55,$4D,$40,$44,$41,$53,$40,$53,$50,$49,$45,$4C,$40,$5A,$55,$40,$00 ; $1CF4  KNOPF UM DAS SPIEL ZU

GERMAN_PROMPT_LINE_2:
                        DB      $53,$54,$41,$52,$54,$45,$4E,$40,$4F,$44,$45,$52,$40,$57,$45,$52,$46,$45,$4E,$40,$40,$40,$00 ; $1D0B  STARTEN ODER WERFEN

GERMAN_PROMPT_LINE_3:
                        DB      $53,$49,$45,$40,$31,$40,$57,$45,$49,$54,$45,$52,$45,$40,$4D,$55,$45,$4E,$5A,$45,$40,$40,$00 ; $1D22  SIE 1 WEITERE MUENZE

GERMAN_PROMPT_LINE_4:
                        DB      $46,$55,$45,$52,$40,$32,$40,$53,$50,$49,$45,$4C,$45,$52,$40,$53,$50,$49,$45,$4C,$40,$40,$00 ; $1D39  FUER 2 SPIELER SPIEL

GERMAN_PROMPT_LINE_5:
                        DB      $45,$49,$4E,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1D50  EIN

GERMAN_PROMPT_LINE_6:
                        DB      $44,$52,$55,$45,$43,$4B,$45,$4E,$40,$53,$49,$45,$40,$32,$40,$53,$50,$49,$45,$4C,$45,$52,$00 ; $1D67  DRUECKEN SIE 2 SPIELER

GERMAN_PROMPT_LINE_7:
                        DB      $53,$54,$41,$52,$54,$45,$4E,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1D7E  STARTEN

GERMAN_PROMPT_LINE_8:
                        DB      $44,$52,$55,$45,$43,$4B,$45,$4E,$40,$53,$49,$45,$40,$31,$40,$4F,$44,$45,$52,$40,$32,$40,$00 ; $1D95  DRUECKEN SIE 1 ODER 2

GERMAN_PROMPT_LINE_9:
                        DB      $53,$50,$49,$45,$4C,$45,$52,$40,$4B,$4E,$4F,$50,$46,$40,$55,$4D,$40,$44,$41,$53,$40,$40,$00 ; $1DAC  SPIELER KNOPF UM DAS

GERMAN_PROMPT_LINE_10:
                        DB      $53,$50,$49,$45,$4C,$40,$5A,$55,$40,$53,$54,$41,$52,$54,$45,$4E,$40,$40,$40,$40,$40,$40,$00 ; $1DC3  SPIEL ZU STARTEN

GERMAN_PROMPT_LINE_11:
                        DB      $57,$45,$52,$46,$45,$4E,$40,$53,$49,$45,$40,$45,$49,$4E,$45,$40,$40,$40,$40,$40,$40,$40,$00 ; $1DDA  WERFEN SIE EINE

GERMAN_PROMPT_LINE_12:
                        DB      $57,$45,$49,$54,$45,$52,$45,$40,$4D,$55,$45,$4E,$5A,$45,$40,$45,$49,$4E,$40,$40,$40,$40,$00 ; $1DF1  WEITERE MUENZE EIN

GERMAN_PROMPT_LINE_13:
                        DB      $53,$49,$45,$40,$5A,$57,$45,$49,$40,$57,$45,$49,$54,$45,$52,$45,$40,$40,$40,$40,$40,$40,$00 ; $1E08  SIE ZWEI WEITERE

GERMAN_PROMPT_LINE_14:
                        DB      $4D,$55,$45,$4E,$5A,$45,$4E,$40,$46,$55,$45,$52,$40,$32,$40,$53,$50,$49,$45,$4C,$45,$52,$00 ; $1E1F  MUENZEN FUER 2 SPIELER

GERMAN_PROMPT_LINE_15:
                        DB      $53,$50,$49,$45,$4C,$40,$45,$49,$4E,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1E36  SPIEL EIN

GERMAN_PROMPT_LINE_16:
                        DB      $57,$45,$49,$54,$45,$52,$45,$40,$4D,$55,$45,$4E,$5A,$45,$40,$46,$55,$45,$52,$40,$40,$40,$00 ; $1E4D  WEITERE MUENZE FUER

GERMAN_PROMPT_LINE_17:
                        DB      $45,$49,$4E,$40,$32,$40,$53,$50,$49,$45,$4C,$45,$52,$40,$53,$50,$49,$45,$4C,$40,$40,$40,$00 ; $1E64  EIN 2 SPIELER SPIEL

GERMAN_PROMPT_LINE_18:
                        DB      $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1E7B  

;-------------------------------------------------------------------------------
; $1E92: Nine French prompt pointer lists
;-------------------------------------------------------------------------------
FRENCH_PROMPT_TABLE_0:
                        DW      FRENCH_PROMPT_LINE_0,FRENCH_PROMPT_LINE_1,FRENCH_PROMPT_LINE_2,FRENCH_PROMPT_LINE_3
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_1:
                        DW      FRENCH_PROMPT_LINE_0,FRENCH_PROMPT_LINE_4,FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_2:
                        DW      FRENCH_PROMPT_LINE_0,FRENCH_PROMPT_LINE_5,FRENCH_PROMPT_LINE_7
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_3:
                        DW      FRENCH_PROMPT_LINE_2,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_4:
                        DW      FRENCH_PROMPT_LINE_0,FRENCH_PROMPT_LINE_5,FRENCH_PROMPT_LINE_7
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_5:
                        DW      FRENCH_PROMPT_LINE_2,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_6:
                        DW      FRENCH_PROMPT_LINE_0,FRENCH_PROMPT_LINE_1,FRENCH_PROMPT_LINE_6,FRENCH_PROMPT_LINE_3
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_7:
                        DW      FRENCH_PROMPT_LINE_2,FRENCH_PROMPT_LINE_3,FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000
FRENCH_PROMPT_TABLE_8:
                        DW      FRENCH_PROMPT_LINE_0,FRENCH_PROMPT_LINE_4,FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7
                        DW      FRENCH_PROMPT_LINE_7,FRENCH_PROMPT_LINE_7,$0000

FRENCH_PROMPT_LINE_0:
                        DB      $50,$4F,$55,$52,$40,$4A,$4F,$55,$45,$52,$40,$41,$50,$50,$55,$59,$45,$52,$40,$40,$40,$40,$00 ; $1EFC  POUR JOUER APPUYER

FRENCH_PROMPT_LINE_1:
                        DB      $42,$4F,$55,$54,$4F,$4E,$40,$4A,$4F,$55,$45,$55,$52,$40,$31,$40,$4F,$55,$40,$40,$40,$40,$00 ; $1F13  BOUTON JOUEUR 1 OU

FRENCH_PROMPT_LINE_2:
                        DB      $4D,$45,$54,$54,$45,$5A,$40,$45,$4E,$43,$4F,$52,$45,$40,$31,$40,$50,$49,$45,$43,$45,$40,$00 ; $1F2A  METTEZ ENCORE 1 PIECE

FRENCH_PROMPT_LINE_3:
                        DB      $50,$4F,$55,$52,$40,$32,$40,$4A,$4F,$55,$45,$55,$52,$53,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1F41  POUR 2 JOUEURS

FRENCH_PROMPT_LINE_4:
                        DB      $42,$4F,$55,$54,$4F,$4E,$40,$4A,$4F,$55,$45,$55,$52,$40,$32,$40,$40,$40,$40,$40,$40,$40,$00 ; $1F58  BOUTON JOUEUR 2

FRENCH_PROMPT_LINE_5:
                        DB      $42,$4F,$55,$54,$4F,$4E,$40,$4A,$4F,$55,$45,$55,$52,$40,$31,$40,$4F,$55,$40,$32,$40,$40,$00 ; $1F6F  BOUTON JOUEUR 1 OU 2

FRENCH_PROMPT_LINE_6:
                        DB      $4D,$45,$54,$54,$45,$5A,$40,$32,$40,$50,$49,$45,$43,$45,$53,$40,$40,$40,$40,$40,$40,$40,$00 ; $1F86  METTEZ 2 PIECES

FRENCH_PROMPT_LINE_7:
                        DB      $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00 ; $1F9D  

;-------------------------------------------------------------------------------
; $1FB4: Unused/padding area at the end of ROM
;-------------------------------------------------------------------------------
ROM_TAIL_PADDING:
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $1FB4  ................
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $1FC4  ................
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $1FD4  ................
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $1FE4  ................
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF                 ; $1FF4

; $1FFF balances the additive checksum of ROM block $1800-$1FFF to $FF.
ROM_BLOCK_CHECKSUM_ADJUSTMENT:
                        DB      $1C                                                     ; $1FFF

ROM_END:
                        END
