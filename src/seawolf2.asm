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
; 4,517 bytes in 35 address spans; no DB byte is omitted.  Native and TERSE
; spans are conversion work.  Table, graphics/text and padding spans are true
; data and should remain data, although their internal labels can still improve.
;
; NATIVE Z80 AWAITING PROMOTION                 14 spans / 1,611 bytes
;   $0302-$0320  work/video clear primitive
;   $0321-$0354  machine and interrupt initialization
;   $0365-$036E  main-state initializer and TERSE entry
;   $0385-$0396  runtime-state reset prefix
;   $03F6-$0500  start selection and prompt control
;   $0501-$0526  prompt pointer-list renderer
;   $0527-$0543  language-selection reader
;   $0593-$0612  playfield clear and score update
;   $06B5-$0734  score/bonus and station-state handling
;   $0735-$07FB  extended-play, lamp and timer-display handling
;   $0B4C-$0BDE  post-hit status and expired-score clearing
;   $0C1A-$0C55  congratulations state and display
;   $0C6E-$0D47  text/BCD primitives and diving-target presentation
;   $15D7-$16F4  native text and small-bitmap renderer
;
; TERSE INTERPRETER PROGRAM                     1 span / 22 bytes
;   $036F-$0384  MAIN_INITIALIZATION_THREAD inline cells and operands
;   Other TERSE programs are already expressed as labeled DW cells.
;
; LOOKUP / PROPERTY / POINTER TABLES             9 spans / 490 DB bytes
;   $0184-$0185  video-RAM diagnostic range parameters
;   $0199-$019A  work-RAM diagnostic range parameters
;   $0355-$0364  initial RAM template copied to $C212
;   $0D48-$0DC7  two 64-byte player-torpedo trajectory tables
;   $0DC8-$0DD1  moving-target type sequence
;   $0DD2-$0DDA  target horizontal-speed table
;   $0DDB-$0E3E  four complete 25-byte object templates
;   $19D8-$1A52  decoded raster-schedule scalar fields; pointers use DW
;   $1A53-$1AE6  bitmap pointers, collision lanes and frame thresholds
;
; GRAPHICS, TEXT OR DIAGNOSTIC PATTERN DATA       9 spans / 2,317 bytes
;   $00B0-$00E7  self-test color/pixel patterns
;   $0E3F-$119E  object and animation bitmaps
;   $119F-$135B  character font
;   $135C-$136F  player-status graphics
;   $1370-$1384  title and diving-target labels
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
; Inventory invariant: remaining DB byte count = 4,517.
;===============================================================================

PORT_COLOR_0            EQU     $00
PORT_COLOR_1            EQU     $01
PORT_COLOR_2            EQU     $02
PORT_COLOR_3            EQU     $03
PORT_COLOR_4            EQU     $04
PORT_COLOR_5            EQU     $05
PORT_COLOR_6            EQU     $06
PORT_COLOR_7            EQU     $07
PORT_VIDEO_MODE         EQU     $08
PORT_COLOR_SPLIT        EQU     $09
PORT_VBLANK_LINE        EQU     $0A
PORT_COLOR_BLOCK        EQU     $0B
PORT_MAGIC_CONTROL      EQU     $0C
PORT_INTERRUPT_VECTOR   EQU     $0D
PORT_INTERRUPT_ENABLE   EQU     $0E
PORT_INTERRUPT_LINE     EQU     $0F
PORT_P2_HANDLE          EQU     $10
PORT_P1_HANDLE          EQU     $11
PORT_COIN_START         EQU     $12
PORT_DIP_SWITCHES       EQU     $13
PORT_SOUND_EVENTS       EQU     $40
PORT_SOUND_CONTROL      EQU     $41
PORT_LEFT_LAMPS         EQU     $42
PORT_RIGHT_LAMPS        EQU     $43

RAM_BASE                EQU     $C000
TERSE_DATA_STACK        EQU     $C3E2
TERSE_RETURN_STACK      EQU     $C400

VIDEO_RAM_BASE          EQU     $4000
VIDEO_RAM_LIMIT         EQU     $8000
WORK_RAM_LIMIT          EQU     $C400

; Native text renderer state used by the power-on and interactive diagnostics.
TEXT_X_POSITION_LO      EQU     $C1FE
TEXT_X_POSITION_HI      EQU     $C1FF
TEXT_Y_POSITION         EQU     $C201
TEXT_COLOR              EQU     $C202

SELF_TEST_TEXT_BUFFER   EQU     $C000
SELF_TEST_ROM_BLOCK_SIZE EQU    $0800

GAME_TIME_BCD           EQU     $C1DB
LEFT_STATION_DISABLED   EQU     $C1E4
ACTIVE_PLAYER_COUNT     EQU     $C1FB

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
OBJECT_MAGIC_MODE           EQU $14
OBJECT_VRAM_ADDR_LO         EQU $15
OBJECT_VRAM_ADDR_HI         EQU $16
OBJECT_COLOR                EQU $17
OBJECT_ANIMATION_FRAME      EQU $18

; $0A, $0B and $10 are touched only by whole-record clear/copy operations.
; No constructor, updater, renderer or collision path reads or writes them as
; fields, so they remain explicitly reserved rather than receiving speculative
; meanings.

BITMAP_SOURCE_WIDTH         EQU $00
BITMAP_ROW_COUNT            EQU $01

; OBJECT_FLAGS bits.  Bits 0-1 are unused by every object path in this ROM.
; Collision state is deliberately split: bit 6 drives the hit animation while
; bit 5 queues scoring/event processing for the foreground TERSE thread.
OBJECT_FLAG_SCORE_PENDING   EQU $04            ; bit 2
OBJECT_FLAG_HIT_SIDE        EQU $08            ; bit 3: 0 right, 1 left
OBJECT_FLAG_AT_BOUNDARY     EQU $10            ; bit 4
OBJECT_FLAG_HIT_PENDING     EQU $20            ; bit 5
OBJECT_FLAG_HIT_ANIMATION   EQU $40            ; bit 6
OBJECT_FLAG_ACTIVE          EQU $80            ; bit 7

OBJECT_TYPE_MINE            EQU $06
OBJECT_TYPE_TORPEDO         EQU $07
OBJECT_TYPE_DIVE_TARGET     EQU $08

; Scheduler pools contain record starts through the inclusive LAST address.
; Torpedo records are interleaved by station; successive records for one
; station are two records ($32 bytes) apart.
TARGET_POOL_BASE            EQU $C000
TARGET_POOL_LAST            EQU $C04B
TARGET_POOL_COUNT           EQU $04
MINE_POOL_BASE              EQU $C064
MINE_POOL_LAST              EQU $C0E1
MINE_POOL_COUNT             EQU $06
TORPEDO_POOL_BASE           EQU $C0FA
TORPEDO_POOL_LEFT_BASE      EQU $C0FA
TORPEDO_POOL_RIGHT_BASE     EQU $C113
TORPEDO_POOL_LAST           EQU $C1A9
TORPEDO_POOL_COUNT          EQU $08
TORPEDO_STATION_STRIDE      EQU $32

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
SONAR_CADENCE_TIMER         EQU $C1CD
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
                        IN      A,(PORT_P2_HANDLE)
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
                        AND     $80
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
; $00B0: Power-on video and RAM test patterns
;-------------------------------------------------------------------------------
SELF_TEST_PATTERN_TABLE:
                        DB      $E2,$E0,$E2,$E0,$E2,$E0,$E2,$E0,$8A,$88,$8A,$88,$8A,$88,$8A,$88 ; $00B0  ................
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$55,$55,$55,$55,$55,$55 ; $00C0  ..........UUUUUU
                        DB      $55,$55,$55,$55,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$FF,$FF ; $00D0  UUUU............
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF                                 ; $00E0  ........

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
                        AND     $06
                        JP      NZ,SELF_TEST_BUTTON_SELECT

; Clear all $4000 bytes of screen RAM before reporting any ROM failure.
                        LD      HL,VIDEO_RAM_BASE
                        LD      DE,$4000
self_test_clear_video:  LD      (HL),$00
                        INC     HL
                        IN      A,(PORT_P2_HANDLE)
                        DEC     E
                        JR      NZ,self_test_clear_video
                        DEC     D
                        JR      NZ,self_test_clear_video

; Each of the four $0800-byte program ROMs has additive checksum $FF.  HL is
; deliberately allowed to advance across block boundaries; H therefore also
; identifies the block when a checksum fails.
                        LD      A,$0C
                        LD      (TEXT_COLOR),A
                        LD      A,$32
                        LD      (TEXT_X_POSITION_HI),A
                        LD      (TEXT_Y_POSITION),A
                        LD      BC,SELF_TEST_ROM_BLOCK_SIZE
                        LD      HL,$0000
self_test_checksum_rom: XOR     A
self_test_sum_rom_byte: ADD     A,(HL)
                        LD      D,A
                        IN      A,(PORT_P2_HANDLE)
                        LD      A,D
                        INC     HL
                        DEC     C
                        JR      NZ,self_test_sum_rom_byte
                        DJNZ    self_test_sum_rom_byte
                        LD      A,D
                        CP      $FF
                        JR      NZ,self_test_report_rom_failure
self_test_next_rom:     LD      BC,SELF_TEST_ROM_BLOCK_SIZE
                        IN      A,(PORT_P2_HANDLE)
                        LD      A,H
                        CP      $20
                        JR      NZ,self_test_checksum_rom

; The renderer's X-position byte doubles as a work-RAM sentinel during the ROM
; pass.  Corruption stops the test before destructive RAM verification begins.
                        LD      A,(TEXT_X_POSITION_HI)
                        CP      $32
                        JR      Z,SELF_TEST_MEMORY_DIAGNOSTICS
self_test_ram_failure:  IN      A,(PORT_P2_HANDLE)
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
                        IN      A,(PORT_P2_HANDLE)
                        POP     BC
                        POP     DE
                        POP     HL
                        JR      self_test_next_rom

SELF_TEST_BUTTON_SELECT:
                        CP      $02
                        JP      NZ,SELF_TEST_MODE_SELECT

;-------------------------------------------------------------------------------
; $016E: Destructive video/work-RAM verification setup
;-------------------------------------------------------------------------------
SELF_TEST_MEMORY_DIAGNOSTICS:
                        DI
                        LD      A,$14
                        OUT     (PORT_COLOR_SPLIT),A
                        LD      B,$08
                        LD      HL,SELF_TEST_PATTERN_TABLE
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
                        LD      B,$08
                        LD      HL,SELF_TEST_PATTERN_TABLE+$08
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
                        IN      A,(PORT_P2_HANDLE)
                        JR      NZ,self_test_write_bit

self_test_reverse_scan: DEC     HL
                        IN      A,(PORT_P2_HANDLE)
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
                        IN      A,(PORT_P2_HANDLE)
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
                        IN      A,(PORT_P2_HANDLE)
                        LD      DE,VIDEO_RAM_BASE
                        LD      HL,SELF_TEST_PATTERN_TABLE+$10
                        LD      BC,$0028
                        LDIR
                        LD      BC,$0028
                        LD      HL,SELF_TEST_PATTERN_TABLE+$10
                        LDIR
                        LD      HL,VIDEO_RAM_BASE
                        LD      BC,$40B0
self_test_expand_failure_pattern:
                        LD      A,(HL)
                        LD      (DE),A
                        IN      A,(PORT_P2_HANDLE)
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
                        IN      A,(PORT_P2_HANDLE)
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
                        CP      $04
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
                        LD      A,$0C
                        LD      (TEXT_COLOR),A
                        LD      A,$78
                        LD      (TEXT_Y_POSITION),A
self_test_input_loop:   IN      A,(PORT_P2_HANDLE)
                        XOR     A
                        LD      (TEXT_X_POSITION_HI),A
                        IN      A,(PORT_P2_HANDLE)
                        IN      A,(PORT_P2_HANDLE)
                        CALL    SELF_TEST_DRAW_HANDLE_VALUE
                        LD      A,$78
                        LD      (TEXT_X_POSITION_HI),A
                        IN      A,(PORT_P2_HANDLE)
                        IN      A,(PORT_P1_HANDLE)
                        CALL    SELF_TEST_DRAW_HANDLE_VALUE
                        JR      self_test_input_loop

; Convert the hardware's Gray-coded handle value to a six-character binary
; string.  FIRE is not included; this screen verifies the position encoder.
SELF_TEST_DRAW_HANDLE_VALUE:
                        CALL    DECODE_HANDLE_POSITION
                        LD      HL,SELF_TEST_TEXT_BUFFER
                        AND     $7F
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
                        IN      A,(PORT_P2_HANDLE)
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
                        IN      A,(PORT_P2_HANDLE)
                        INC     HL
                        LD      (HL),$03
                        INC     HL
                        DJNZ    convergence_vertical_pattern

                        LD      BC,$0330
convergence_clear_seed: LD      (HL),$00
                        IN      A,(PORT_P2_HANDLE)
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
                        IN      A,(PORT_P2_HANDLE)
                        INC     DE
                        INC     HL
                        DEC     C
                        JR      NZ,convergence_repeat_seed
                        DJNZ    convergence_repeat_seed
convergence_halt:       IN      A,(PORT_P2_HANDLE)
                        JR      convergence_halt

;-------------------------------------------------------------------------------
; $02F0: Initial direct-threaded TERSE execution list
;-------------------------------------------------------------------------------
INITIAL_THREAD:
                        DW      CLEAR_RAM_AND_LOWER_VIDEO
                        DW      INITIALIZE_MACHINE
initial_loop:           DW      CLEAR_PLAYFIELD_AND_UPDATE_SCORE
                        DW      INITIALIZE_MAIN_STATE
                        DW      START_SELECTION_AND_PROMPTS
                        DW      RESET_RUNTIME_STATE
                        DW      CONTROL_THREAD_WORD
                        DW      TERSE_BRANCH
                        DW      initial_loop

;-------------------------------------------------------------------------------
; $0302: Clear work RAM and lower video area
;-------------------------------------------------------------------------------
CLEAR_RAM_AND_LOWER_VIDEO:
                        DB      $21,$00,$C0             ; $0302  LD HL,$C000
                        DB      $11,$00,$04             ; $0305  LD DE,$0400
                        DB      $AF                     ; $0308  XOR A
                        DB      $77                     ; $0309  LD (HL),A
                        DB      $23                     ; $030A  INC HL
                        DB      $1D                     ; $030B  DEC E
                        DB      $20,$FB                 ; $030C  JR NZ,$0309
                        DB      $15                     ; $030E  DEC D
                        DB      $20,$F8                 ; $030F  JR NZ,$0309
                        DB      $21,$F0,$77             ; $0311  LD HL,$77F0
                        DB      $11,$C0,$08             ; $0314  LD DE,$08C0
                        DB      $77                     ; $0317  LD (HL),A
                        DB      $23                     ; $0318  INC HL
                        DB      $1D                     ; $0319  DEC E
                        DB      $20,$FB                 ; $031A  JR NZ,$0317
                        DB      $15                     ; $031C  DEC D
                        DB      $20,$F8                 ; $031D  JR NZ,$0317
                        DB      $FD,$E9                 ; $031F  JP (IY)

;-------------------------------------------------------------------------------
; $0321: Interrupt, language pointer, color and video initialization
;-------------------------------------------------------------------------------
INITIALIZE_MACHINE:
                        DB      $C5                     ; $0321  PUSH BC
                        DB      $3E,$08                 ; $0322  LD A,$08
                        DB      $D3,$0E                 ; $0324  OUT ($0E),A
                        DB      $ED,$5E                 ; $0326  IM 2
                        DB      $01,$10,$00             ; $0328  LD BC,$0010
                        DB      $21,$55,$03             ; $032B  LD HL,INITIAL_RAM_TEMPLATE
                        DB      $11,$12,$C2             ; $032E  LD DE,RASTER_MOTION_STATE_0
                        DB      $ED,$B0                 ; $0331  LDIR
                        DB      $DB,$13                 ; $0333  IN A,($13)
                        DB      $E6,$40                 ; $0335  AND $40
                        DB      $21,$16,$1A             ; $0337  LD HL,INTERRUPT_SCHEDULE_SET_B
                        DB      $28,$03                 ; $033A  JR Z,$033F
                        DB      $21,$D8,$19             ; $033C  LD HL,INTERRUPT_SCHEDULE_SET_A
                        DB      $22,$FC,$C1             ; $033F  LD (INTERRUPT_SCHEDULE_CURSOR),HL
                        DB      $22,$0D,$C2             ; $0342  LD (INTERRUPT_SCHEDULE_BASE),HL
                        DB      $3E,$2A                 ; $0345  LD A,$2A
                        DB      $D3,$09                 ; $0347  OUT ($09),A
                        DB      $CD,$48,$14             ; $0349  CALL ALTERNATE_RASTER_INTERRUPT_HANDLER
                        DB      $C1                     ; $034C  POP BC
                        DB      $21,$C8,$0D             ; $034D  LD HL,$0DC8
                        DB      $22,$0B,$C2             ; $0350  LD ($C20B),HL
                        DB      $FD,$E9                 ; $0353  JP (IY)

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
                        DB      $AF                     ; $0365  XOR A
                        DB      $32,$FB,$C1             ; $0366  LD ($C1FB),A
                        DB      $32,$FA,$C1             ; $0369  LD ($C1FA),A
                        DB      $D3,$41                 ; $036C  OUT ($41),A
                        DB      $CF                     ; $036E  RST $08

;-------------------------------------------------------------------------------
; $036F: Inline TERSE cells and operands
;-------------------------------------------------------------------------------
MAIN_INITIALIZATION_THREAD:
                        DB      $97,$03,$6E,$0C,$17,$1B,$02,$4A,$00,$99,$0C,$6E,$0C,$70,$13,$48 ; $036F  ..n....J...n.p.H
                        DB      $3E,$00,$44,$05,$39,$00                                         ; $037F  >.D.9.

;-------------------------------------------------------------------------------
; $0385: Clear runtime RAM/video state
;-------------------------------------------------------------------------------
RESET_RUNTIME_STATE:
                        DB      $AF                     ; $0385  XOR A
                        DB      $32,$0A,$C2             ; $0386  LD ($C20A),A
                        DB      $11,$C0,$08             ; $0389  LD DE,$08C0
                        DB      $21,$F0,$77             ; $038C  LD HL,$77F0
                        DB      $77                     ; $038F  LD (HL),A
                        DB      $23                     ; $0390  INC HL
                        DB      $1D                     ; $0391  DEC E
                        DB      $20,$FB                 ; $0392  JR NZ,$038F
                        DB      $15                     ; $0394  DEC D
                        DB      $20,$F8                 ; $0395  JR NZ,$038F
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
                        AND     $06
                        RRCA
                        LD      B,A
                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      $02
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
                        IN      A,(PORT_P2_HANDLE)
                        INC     HL
                        DEC     E
                        JR      NZ,clear_active_playfield
                        DEC     D
                        JR      NZ,clear_active_playfield

                        LD      A,(ACTIVE_PLAYER_COUNT)
                        CP      $02
                        JR      Z,draw_initial_player_status
                        LD      A,$FF
                        LD      (LEFT_STATION_DISABLED),A
draw_initial_player_status:
                        CALL    DRAW_PLAYER_STATUS
                        POP     BC
                        JP      (IY)

;-------------------------------------------------------------------------------
; $03F6: Start/credit selection and prompt rendering
;-------------------------------------------------------------------------------
START_SELECTION_AND_PROMPTS:
                        DB      $AF                     ; $03F6  XOR A
                        DB      $32,$03,$C2             ; $03F7  LD ($C203),A
                        DB      $32,$04,$C2             ; $03FA  LD ($C204),A
                        DB      $FD,$E5                 ; $03FD  PUSH IY
                        DB      $FD,$21,$06,$04         ; $03FF  LD IY,$0406
                        DB      $C3,$56,$0C             ; $0403  JP $0C56
                        DB      $FD,$E1                 ; $0406  POP IY
                        DB      $3A,$03,$C2             ; $0408  LD A,($C203)
                        DB      $CB,$4F                 ; $040B  BIT 1,A
                        DB      $28,$17                 ; $040D  JR Z,$0426
                        DB      $DB,$12                 ; $040F  IN A,($12)
                        DB      $CB,$4F                 ; $0411  BIT 1,A
                        DB      $28,$11                 ; $0413  JR Z,$0426
                        DB      $3E,$01                 ; $0415  LD A,$01
                        DB      $32,$FB,$C1             ; $0417  LD ($C1FB),A
                        DB      $3A,$06,$C2             ; $041A  LD A,($C206)
                        DB      $21,$04,$C2             ; $041D  LD HL,$C204
                        DB      $96                     ; $0420  SUB (HL)
                        DB      $32,$06,$C2             ; $0421  LD ($C206),A
                        DB      $FD,$E9                 ; $0424  JP (IY)
                        DB      $3A,$03,$C2             ; $0426  LD A,($C203)
                        DB      $CB,$57                 ; $0429  BIT 2,A
                        DB      $28,$0D                 ; $042B  JR Z,$043A
                        DB      $DB,$12                 ; $042D  IN A,($12)
                        DB      $CB,$57                 ; $042F  BIT 2,A
                        DB      $28,$07                 ; $0431  JR Z,$043A
                        DB      $3E,$02                 ; $0433  LD A,$02
                        DB      $32,$FB,$C1             ; $0435  LD ($C1FB),A
                        DB      $18,$E0                 ; $0438  JR $041A
                        DB      $21,$03,$C2             ; $043A  LD HL,$C203
                        DB      $DB,$13                 ; $043D  IN A,($13)
                        DB      $E6,$09                 ; $043F  AND $09
                        DB      $B7                     ; $0441  OR A
                        DB      $CA,$74,$04             ; $0442  JP Z,$0474
                        DB      $FE,$08                 ; $0445  CP $08
                        DB      $CA,$88,$04             ; $0447  JP Z,$0488
                        DB      $FE,$01                 ; $044A  CP $01
                        DB      $CA,$6A,$04             ; $044C  JP Z,$046A
                        DB      $3A,$06,$C2             ; $044F  LD A,($C206)
                        DB      $FE,$01                 ; $0452  CP $01
                        DB      $20,$0A                 ; $0454  JR NZ,$0460
                        DB      $CB,$CE                 ; $0456  SET 1,(HL)
                        DB      $CB,$96                 ; $0458  RES 2,(HL)
                        DB      $23                     ; $045A  INC HL
                        DB      $36,$01                 ; $045B  LD (HL),$01
                        DB      $C3,$B4,$04             ; $045D  JP $04B4
                        DB      $CB,$8E                 ; $0460  RES 1,(HL)
                        DB      $CB,$D6                 ; $0462  SET 2,(HL)
                        DB      $23                     ; $0464  INC HL
                        DB      $36,$02                 ; $0465  LD (HL),$02
                        DB      $C3,$D9,$04             ; $0467  JP $04D9
                        DB      $CB,$CE                 ; $046A  SET 1,(HL)
                        DB      $CB,$D6                 ; $046C  SET 2,(HL)
                        DB      $23                     ; $046E  INC HL
                        DB      $36,$01                 ; $046F  LD (HL),$01
                        DB      $C3,$DE,$04             ; $0471  JP $04DE
                        DB      $3A,$06,$C2             ; $0474  LD A,($C206)
                        DB      $FE,$01                 ; $0477  CP $01
                        DB      $20,$03                 ; $0479  JR NZ,$047E
                        DB      $C3,$E3,$04             ; $047B  JP $04E3
                        DB      $CB,$CE                 ; $047E  SET 1,(HL)
                        DB      $CB,$D6                 ; $0480  SET 2,(HL)
                        DB      $23                     ; $0482  INC HL
                        DB      $36,$02                 ; $0483  LD (HL),$02
                        DB      $C3,$E8,$04             ; $0485  JP $04E8
                        DB      $3A,$06,$C2             ; $0488  LD A,($C206)
                        DB      $FE,$01                 ; $048B  CP $01
                        DB      $20,$03                 ; $048D  JR NZ,$0492
                        DB      $C3,$ED,$04             ; $048F  JP $04ED
                        DB      $FE,$02                 ; $0492  CP $02
                        DB      $20,$09                 ; $0494  JR NZ,$049F
                        DB      $CB,$CE                 ; $0496  SET 1,(HL)
                        DB      $CB,$96                 ; $0498  RES 2,(HL)
                        DB      $23                     ; $049A  INC HL
                        DB      $77                     ; $049B  LD (HL),A
                        DB      $C3,$F2,$04             ; $049C  JP $04F2
                        DB      $FE,$03                 ; $049F  CP $03
                        DB      $20,$07                 ; $04A1  JR NZ,$04AA
                        DB      $CB,$8E                 ; $04A3  RES 1,(HL)
                        DB      $CB,$96                 ; $04A5  RES 2,(HL)
                        DB      $C3,$F7,$04             ; $04A7  JP $04F7
                        DB      $CB,$8E                 ; $04AA  RES 1,(HL)
                        DB      $CB,$D6                 ; $04AC  SET 2,(HL)
                        DB      $23                     ; $04AE  INC HL
                        DB      $36,$04                 ; $04AF  LD (HL),$04
                        DB      $C3,$FC,$04             ; $04B1  JP $04FC
                        DB      $21,$59,$1B             ; $04B4  LD HL,$1B59
                        DB      $CD,$27,$05             ; $04B7  CALL $0527
                        DB      $11,$00,$00             ; $04BA  LD DE,$0000
                        DB      $FE,$00                 ; $04BD  CP $00
                        DB      $28,$0A                 ; $04BF  JR Z,$04CB
                        DB      $11,$1A,$01             ; $04C1  LD DE,$011A
                        DB      $FE,$01                 ; $04C4  CP $01
                        DB      $28,$03                 ; $04C6  JR Z,$04CB
                        DB      $11,$39,$03             ; $04C8  LD DE,$0339
                        DB      $19                     ; $04CB  ADD HL,DE
                        DB      $11,$00,$3E             ; $04CC  LD DE,$3E00
                        DB      $ED,$53,$00,$C2         ; $04CF  LD ($C200),DE
                        DB      $CD,$01,$05             ; $04D3  CALL $0501
                        DB      $C3,$FD,$03             ; $04D6  JP $03FD
                        DB      $21,$67,$1B             ; $04D9  LD HL,$1B67
                        DB      $18,$D9                 ; $04DC  JR $04B7
                        DB      $21,$75,$1B             ; $04DE  LD HL,$1B75
                        DB      $18,$D4                 ; $04E1  JR $04B7
                        DB      $21,$81,$1B             ; $04E3  LD HL,$1B81
                        DB      $18,$CF                 ; $04E6  JR $04B7
                        DB      $21,$87,$1B             ; $04E8  LD HL,$1B87
                        DB      $18,$CA                 ; $04EB  JR $04B7
                        DB      $21,$93,$1B             ; $04ED  LD HL,$1B93
                        DB      $18,$C5                 ; $04F0  JR $04B7
                        DB      $21,$99,$1B             ; $04F2  LD HL,$1B99
                        DB      $18,$C0                 ; $04F5  JR $04B7
                        DB      $21,$A7,$1B             ; $04F7  LD HL,$1BA7
                        DB      $18,$BB                 ; $04FA  JR $04B7
                        DB      $21,$B5,$1B             ; $04FC  LD HL,$1BB5
                        DB      $18,$B6                 ; $04FF  JR $04B7

;-------------------------------------------------------------------------------
; $0501: Render a zero-terminated list of text pointers
;-------------------------------------------------------------------------------
DRAW_PROMPT_POINTER_LIST:
                        DB      $3E,$0C                 ; $0501  LD A,$0C
                        DB      $32,$02,$C2             ; $0503  LD ($C202),A
                        DB      $11,$00,$28             ; $0506  LD DE,$2800
                        DB      $ED,$53,$FE,$C1         ; $0509  LD ($C1FE),DE
                        DB      $5E                     ; $050D  LD E,(HL)
                        DB      $23                     ; $050E  INC HL
                        DB      $56                     ; $050F  LD D,(HL)
                        DB      $23                     ; $0510  INC HL
                        DB      $7B                     ; $0511  LD A,E
                        DB      $B2                     ; $0512  OR D
                        DB      $C8                     ; $0513  RET Z
                        DB      $E5                     ; $0514  PUSH HL
                        DB      $62                     ; $0515  LD H,D
                        DB      $6B                     ; $0516  LD L,E
                        DB      $CD,$E4,$15             ; $0517  CALL $15E4
                        DB      $2A,$00,$C2             ; $051A  LD HL,($C200)
                        DB      $11,$00,$0C             ; $051D  LD DE,$0C00
                        DB      $19                     ; $0520  ADD HL,DE
                        DB      $22,$00,$C2             ; $0521  LD ($C200),HL
                        DB      $E1                     ; $0524  POP HL
                        DB      $18,$DA                 ; $0525  JR $0501

;-------------------------------------------------------------------------------
; $0527: Decode the two language-select input bits
;-------------------------------------------------------------------------------
READ_LANGUAGE_SELECTION:
                        DB      $C5                     ; $0527  PUSH BC
                        DB      $DB,$12                 ; $0528  IN A,($12)
                        DB      $E6,$08                 ; $052A  AND $08
                        DB      $47                     ; $052C  LD B,A
                        DB      $DB,$11                 ; $052D  IN A,($11)
                        DB      $E6,$40                 ; $052F  AND $40
                        DB      $B0                     ; $0531  OR B
                        DB      $06,$00                 ; $0532  LD B,$00
                        DB      $28,$08                 ; $0534  JR Z,$053E
                        DB      $06,$01                 ; $0536  LD B,$01
                        DB      $FE,$08                 ; $0538  CP $08
                        DB      $28,$02                 ; $053A  JR Z,$053E
                        DB      $06,$02                 ; $053C  LD B,$02
                        DB      $78                     ; $053E  LD A,B
                        DB      $32,$05,$C2             ; $053F  LD ($C205),A
                        DB      $C1                     ; $0542  POP BC
                        DB      $C9                     ; $0543  RET

;-------------------------------------------------------------------------------
; $0544: Native ENTER followed by an inline TERSE control thread
;-------------------------------------------------------------------------------
CONTROL_THREAD_WORD:
                        RST     $08
control_wait:           DW      TERSE_BEGIN
                        DW      TERSE_INLINE_BFETCH,$C1DF
                        DW      TERSE_ZERO_BRANCH,control_no_state
                        DW      $0735
control_no_state:       DW      TERSE_INLINE_BFETCH,$C1FB
                        DW      TERSE_ZERO_BRANCH,control_no_player
                        DW      ERASE_EXPIRED_HIT_SCORES,PROCESS_SHIP_HIT,$0711,UPDATE_SONAR_SEQUENCE
                        DW      TERSE_INLINE_BFETCH,$C1DF
                        DW      TERSE_BYTE_NOT
                        DW      TERSE_ZERO_BRANCH,control_continue
                        DW      $07C4,ACTIVATE_TARGET_LANES,POLL_TORPEDO_FIRE
                        DW      TERSE_BRANCH,control_continue
control_no_player:      DW      INITIALIZE_OBJECT_POOLS,$0C1A
                        DW      TERSE_INLINE_BFETCH,$C206
                        DW      TERSE_ZERO_BRANCH,control_continue
                        DW      TERSE_TRUE
                        DW      TERSE_LIT,$C1DF
                        DW      TERSE_BSTORE
control_continue:       DW      PULSE_COIN_COUNTER
                        DW      TERSE_INLINE_BFETCH,$C1DE
                        DW      TERSE_UNTIL
                        DW      TERSE_RETURN

;-------------------------------------------------------------------------------
; $0593: Major native rendering/state routine
;-------------------------------------------------------------------------------
CLEAR_PLAYFIELD_AND_UPDATE_SCORE:
                        DB      $21,$00,$40,$AF,$11,$60,$3C,$77,$23,$1D,$20,$FB,$15,$20,$F8,$21 ; $0593  !. ..`<w#. .. .!
                        DB      $70,$7B,$11,$20,$00,$C5,$3E,$0C,$06,$30,$36,$00,$23,$10,$FB,$19 ; $05A3  p{. ..>..06.#...
                        DB      $3D,$20,$F5,$2A,$E2,$C1,$ED,$5B,$E7,$C1,$44,$4D,$AF,$ED,$52,$30 ; $05B3  = .*...[..DM..R0
                        DB      $04,$3E,$FF,$42,$4B,$2A,$08,$C2,$57,$AF,$ED,$42,$30,$15,$7A,$B7 ; $05C3  .>.BK*..W..B0.z.
                        DB      $11,$E2,$C1,$28,$03,$11,$E7,$C1,$21,$08,$C2,$1A,$77,$23,$13,$1A ; $05D3  ...(....!...w#..
                        DB      $77,$3E,$FF,$32,$F8,$C1,$C1,$CD,$27,$05,$FE,$00,$20,$0A,$CF,$6E ; $05E3  w>.2....'... ..n
                        DB      $0C,$22,$1B,$B4,$2C,$FF,$39,$00,$FE,$01,$20,$0A,$CF,$6E,$0C,$2C ; $05F3  ."..,.9... ..n.,
                        DB      $1B,$B4,$2C,$FF,$39,$00,$CF,$6E,$0C,$36,$1B,$B4,$2C,$FF,$39,$00 ; $0603  ..,.9..n.6..,.9.

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
                        BIT     3,(HL)
                        LD      DE,$C1E7
                        LD      A,($C1F1)
                        LD      C,PORT_RIGHT_LAMPS
                        JR      Z,hit_station_selected
                        LD      DE,$C1E2
                        LD      A,($C1EE)
                        LD      C,PORT_LEFT_LAMPS
hit_station_selected:   INC     HL                      ; OBJECT_TYPE
                        OR      $20
                        OUT     (C),A
                        LD      A,(HL)
                        DEC     HL
                        PUSH    HL
                        POP     IY
                        EX      DE,HL

; Convert target type to the BCD score increment used by this record.
                        LD      B,$03
                        CP      $03
                        JR      C,hit_score_value_ready
                        LD      B,$01
                        CP      $05
                        JR      C,hit_score_value_ready
                        LD      B,$05
                        CP      $07
                        JR      C,hit_score_value_ready
                        LD      B,$10
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
                        LD      ($C202),A
                        PUSH    DE
                        PUSH    BC
                        CALL    $06B5
                        POP     BC
                        SET     2,(IY+OBJECT_FLAGS)
                        LD      A,(IY+OBJECT_X_POSITION_HI)
                        LD      ($C1FF),A
                        LD      A,(IY+OBJECT_Y_POSITION_HI)
                        SUB     $1A
                        LD      ($C201),A
                        LD      HL,$0000
                        PUSH    HL
                        LD      HL,$3030
                        PUSH    HL
                        LD      A,B
                        CALL    $0CF0
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
                        DB      $56,$2B,$7E,$FE,$04,$C0,$36,$00,$23,$36,$00,$2B,$2B,$2B ; $06B5
                        DB      $2B,$7E,$82,$27,$77,$23,$7E,$CE,$00,$27,$77,$7D,$5D,$FE,$E3,$3E ; $06C3  +~.'w#~..'w}]..>
                        DB      $78,$21,$F2,$C1,$01,$CE,$C1,$20,$08,$3E,$00,$21,$F4,$C1,$01,$CF ; $06D3  x!..... .>.!....
                        DB      $C1,$36,$3C,$23,$72,$32,$FF,$C1,$3E,$96,$32,$01,$C2,$3E,$78,$02 ; $06E3  .6<#r2..>.2..>x.
                        DB      $21,$53,$1B,$CD,$D7,$15,$7B,$FE,$E3,$3E,$82,$20,$02,$3E,$07,$32 ; $06F3  !S....{..>. .>.2
                        DB      $FF,$C1,$3E,$AB,$32,$01,$C2,$4A,$06,$00,$CD,$AE,$0C,$C9,$21,$E4 ; $0703  ..>.2..J......!.
                        DB      $C1,$7E,$B7,$20,$0A,$36,$FF,$2B,$3E,$07,$16,$0B,$CD,$B1,$0C,$21 ; $0713  .~. .6.+>......!
                        DB      $E9,$C1,$7E,$B7,$20,$0A,$36,$FF,$2B,$3E,$82,$16,$07,$CD,$B1,$0C ; $0723  ..~. .6.+>......
                        DB      $FD,$E9                                                         ; $0733  ..

;-------------------------------------------------------------------------------
; $0735: Extended-play qualification and lamp reset
;-------------------------------------------------------------------------------
UPDATE_EXTENDED_PLAY_AND_LAMPS:
                        DB      $C5,$3A,$E0,$C1,$B7,$20,$1B,$DB,$13,$E6,$30,$28,$15,$C6,$40,$5F ; $0735  .:... ....0(.. _
                        DB      $16,$00,$2A,$E2,$C1,$AF,$ED,$52,$30,$2A,$2A,$E7,$C1,$AF,$ED,$52 ; $0745  ..*....R0**....R
                        DB      $30,$22                                                         ; $0755  0"

;-------------------------------------------------------------------------------
; $0757: Clear both player lamp latches
;-------------------------------------------------------------------------------
CLEAR_PLAYER_LAMPS:
                        DB      $AF,$D3,$42,$D3,$43,$32,$ED,$C1,$32,$F0,$C1,$21,$FA,$C0,$06,$08 ; $0757  ..B.C2..2..!....
                        DB      $11,$19,$00,$CB,$7E,$20,$08,$19,$10,$F9,$3E,$FF,$32,$DE,$C1,$C1 ; $0767  ....~ ....>.2...
                        DB      $FD,$E9,$AF,$32,$DF,$C1,$DB,$13,$E6,$06,$07,$11,$35,$45,$28,$11 ; $0777  ...2........5E(.
                        DB      $11,$30,$35,$FE,$04,$28,$0A,$11,$25,$30,$FE,$08,$28,$03,$11,$20 ; $0787  .05..(..%0..(..
                        DB      $20,$3A,$FB,$C1,$FE,$02,$7A,$28,$01,$7B,$32,$DB,$C1,$32,$E0,$C1 ; $0797   :....z(.{2..2..
                        DB      $AF,$32,$F7,$C1,$3E,$BE,$32,$01,$C2,$3E,$28,$32,$FF,$C1,$3E,$0C ; $07A7  .2..>.2..>(2..>.
                        DB      $32,$02,$C2,$21,$40,$1B,$C5,$CD,$E4,$15,$C1,$FD,$E9,$3A,$DB,$C1 ; $07B7  2..! ........:..
                        DB      $21,$DC,$C1,$BE,$CA,$FC,$07,$77,$F5,$C5,$21,$00,$00,$E5,$CD,$F0 ; $07C7  !......w..!.....
                        DB      $0C,$21,$00,$00,$39,$3E,$BE,$32,$01,$C2,$3E,$4C,$32,$FF,$C1,$3E ; $07D7  .!..9>.2..>L2..>
                        DB      $0C,$32,$02,$C2,$CD,$E4,$15,$33,$33,$33,$33,$C1,$F1,$B7,$20,$05 ; $07E7  .2.....3333... .
                        DB      $3E,$FF,$32,$DF,$C1     ; $07F7

; Service the left station only in two-player mode; the right station is always
; present.  Each station has its own magazine byte, reload timer and lamp port.
SERVICE_STATION_RELOADS:
                        PUSH    BC
                        LD      C,PORT_LEFT_LAMPS
                        LD      DE,$C1CB
                        LD      HL,$C1ED
                        LD      A,($C1FB)
                        CP      $02
                        CALL    Z,RELOAD_PLAYER_TORPEDOES_AND_ACTIVATE_MINES
                        INC     C
                        INC     DE
                        LD      HL,$C1F0
                        CALL    RELOAD_PLAYER_TORPEDOES_AND_ACTIVATE_MINES
                        POP     BC
                        JP      (IY)

;-------------------------------------------------------------------------------
; $0818: Reload one station and activate its score-qualified mine lanes
;-------------------------------------------------------------------------------
; HL is the station's remaining-torpedo count, DE its reload timer, and C its
; lamp port.  Once both state bytes reach zero, the magazine returns to four
; shots and the larger player score controls whether one, two, or all three
; two-record mine lanes are populated.
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
                        LD      A,($C1E2)
                        LD      D,A
                        LD      A,($C1E7)
                        CP      D
                        JR      NC,mine_score_selected
                        LD      A,D
mine_score_selected:    CP      $10
                        JR      C,spawn_near_mine_lane
                        CP      $20
                        JR      C,spawn_middle_mine_lane
                        LD      HL,$C0C8
                        LD      D,$82
                        CALL    ACTIVATE_MINE_IN_LANE
spawn_middle_mine_lane: LD      HL,$C096
                        LD      D,$64
                        CALL    ACTIVATE_MINE_IN_LANE
spawn_near_mine_lane:   LD      HL,MINE_POOL_BASE
                        LD      D,$4C
                        CALL    ACTIVATE_MINE_IN_LANE
                        EXX
                        POP     IY
                        RET

; HL addresses the first of two records in one mine lane; D is the fixed Y
; coordinate.  Allocate the first inactive record and stagger its X coordinate
; from the other mine in the lane.
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
                        LD      (IY+OBJECT_MAGIC_MODE),$08
                        LD      (IY+OBJECT_COLOR),$0C
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
                        LD      HL,$C032
                        CALL    ACTIVATE_TARGET_IN_LANE
                        POP     IY
                        EXX
                        JP      (IY)

; HL addresses the first record in a two-record target lane.  The second target
; is launched only after the first has crossed the lane's spawn threshold.
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
                        LD      A,R
                        RRA
                        LD      A,$04
                        JR      C,target_color_ready
                        LD      A,$08
target_color_ready:     LD      (IY+OBJECT_COLOR),A
                        LD      A,L
                        CP      $33
                        LD      A,$1A
                        JR      C,target_lane_y_ready
                        LD      A,$33
target_lane_y_ready:    LD      (IY+OBJECT_Y_POSITION_HI),A

; TARGET_TYPE_SEQUENCE supplies normal target types.  Type $03 can be promoted
; to the special diving target while its progression counter is below two.
                        LD      HL,($C20B)
                        LD      B,(HL)
                        INC     HL
                        LD      A,(HL)
                        CP      $FF
                        JR      NZ,target_sequence_ready
                        LD      HL,TARGET_TYPE_SEQUENCE
target_sequence_ready:  LD      ($C20B),HL
                        LD      A,B
                        CP      $03
                        JR      NZ,target_type_ready
                        LD      A,($C1DB)
                        CP      $24
                        LD      A,$03
                        JR      NC,target_type_ready
                        LD      A,($C1F7)
                        CP      $02
                        JR      Z,target_type_ready
                        INC     A
                        LD      ($C1F7),A
                        CALL    $0D02
                        LD      A,OBJECT_TYPE_DIVE_TARGET
target_type_ready:      LD      (IY+OBJECT_TYPE),A
                        LD      (IY+OBJECT_MAGIC_MODE),$08

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
                        CP      $05
                        LD      A,$8E
                        JR      NZ,target_right_limit_ready
                        LD      A,$9A
target_right_limit_ready:
                        LD      (IY+OBJECT_X_MAX),A
                        POP     AF
                        JR      NC,target_direction_ready
                        LD      (IY+OBJECT_X_MAX),$A0
                        SET     6,(IY+OBJECT_MAGIC_MODE)
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
                        CP      $05
                        LD      A,$96
                        JR      Z,target_left_start_ready
                        LD      A,$8C
target_left_start_ready:
                        LD      (IY+OBJECT_X_POSITION_HI),A
target_direction_ready: LD      A,(IY+OBJECT_TYPE)
                        CP      $05
                        JR      C,target_sound_done
                        CP      OBJECT_TYPE_DIVE_TARGET
                        JR      NZ,START_SONAR_SEQUENCE

; Target type $08 begins the dive effect.  $F0 supplies both the descending
; three-bit pan code and the first port-$41 bit-3 trigger edge.
START_DIVE_SOUND:
                        LD      A,$F0
                        LD      (SOUND_DIVE_PAN_TIMER),A
                        BIT     6,(IY+OBJECT_MAGIC_MODE)
                        LD      A,$87
                        JR      Z,dive_pan_selected
                        LD      A,$80
dive_pan_selected:      LD      (SOUND_DIVE_PAN_XOR),A
                        LD      (IY+OBJECT_COLOR),$0C
                        JR      target_sound_done

; Other target types start a ten-ping alternating sonar sequence.  The first
; left-channel pulse is asserted immediately; UPDATE_SONAR_SEQUENCE schedules
; the remaining left/right pulses as SONAR_CADENCE_TIMER expires.
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
                        LD      A,($C1FB)
                        CP      $02
                        JR      NZ,poll_right_torpedo
                        LD      C,PORT_P2_HANDLE
                        LD      DE,$C1CB
                        LD      HL,$C1ED
                        LD      IY,TORPEDO_POOL_LEFT_BASE
                        CALL    UPDATE_PLAYER_TORPEDO_FIRE
poll_right_torpedo:     LD      C,PORT_P1_HANDLE
                        LD      DE,$C1CC
                        LD      HL,$C1F0
                        LD      IY,TORPEDO_POOL_RIGHT_BASE
                        CALL    UPDATE_PLAYER_TORPEDO_FIRE
                        POP     IY
                        POP     BC
                        JP      (IY)

; C = handle/fire input port; DE = reload timer; HL = player fire state;
; IY = first torpedo object for the station.
UPDATE_PLAYER_TORPEDO_FIRE:
                        LD      A,(HL)
                        OR      A
                        RET     Z
                        DEC     HL
                        IN      A,(C)
                        AND     $80
                        CP      (HL)
                        RET     Z
                        LD      (HL),A
                        OR      A
                        RET     Z
                        LD      A,$80
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
                        SUB     $12
                        JR      NC,torpedo_aim_nonnegative
                        LD      A,$00
torpedo_aim_nonnegative:
                        ADD     A,A
                        CP      $40
                        JR      C,torpedo_aim_in_range
                        LD      A,$3E
torpedo_aim_in_range:   AND     $3E
                        LD      HL,TORPEDO_TRAJECTORY_LEFT_TABLE
                        BIT     0,C
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
                        BIT     0,C
                        LD      HL,SOUND_LEFT_TORPEDO_TIMER
                        JR      Z,torpedo_sound_selected
                        LD      HL,SOUND_RIGHT_TORPEDO_TIMER
torpedo_sound_selected: LD      (HL),$38
                        RET

INITIALIZE_TORPEDO_OBJECT:
                        CALL    CLEAR_OBJECT_RECORD
                        LD      (IY+OBJECT_TYPE),OBJECT_TYPE_TORPEDO
                        LD      (IY+OBJECT_Y_ACCEL_LO),$0C
                        LD      (IY+OBJECT_Y_VELOCITY_HI),$FC
                        LD      (IY+OBJECT_Y_POSITION_HI),$BB
                        LD      (IY+OBJECT_Y_MIN),$23
                        LD      (IY+OBJECT_X_MAX),$9C
                        LD      (IY+OBJECT_MAGIC_MODE),$08
                        LD      (IY+OBJECT_BITMAP_PTR_HI),$11
                        LD      (IY+OBJECT_BITMAP_PTR_LO),$2D
                        LD      A,$08
                        BIT     0,C
                        JR      Z,torpedo_color_selected
                        LD      A,$04
torpedo_color_selected: LD      (IY+OBJECT_COLOR),A
                        RET

DECODE_HANDLE_POSITION:
                        PUSH    BC
                        PUSH    DE
                        AND     $3F
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
; The overlay survives through two animation frames, or four for the diving
; target, before this pass erases it and restores the owning station's lamps.
ERASE_EXPIRED_HIT_SCORES:
                        PUSH    BC
                        PUSH    IY
                        LD      IY,TARGET_POOL_BASE
                        LD      DE,OBJECT_RECORD_SIZE
                        LD      B,TARGET_POOL_COUNT
erase_hit_score_loop:   BIT     2,(IY+OBJECT_FLAGS)
                        JR      Z,next_hit_score_record
                        LD      A,(IY+OBJECT_TYPE)
                        CP      OBJECT_TYPE_DIVE_TARGET
                        LD      A,$04
                        JR      Z,hit_score_frame_limit_ready
                        LD      A,$02
hit_score_frame_limit_ready:
                        CP      (IY+OBJECT_ANIMATION_FRAME)
                        JR      NC,next_hit_score_record
                        RES     2,(IY+OBJECT_FLAGS)
                        PUSH    BC
                        PUSH    DE
                        LD      A,(IY+OBJECT_X_POSITION_HI)
                        LD      ($C1FF),A
                        LD      A,(IY+OBJECT_Y_POSITION_HI)
                        SUB     $1A
                        LD      ($C201),A
                        XOR     A
                        LD      ($C202),A
                        LD      HL,$136B               ; blank score overlay
                        CALL    DRAW_TEXT
                        BIT     3,(IY+OBJECT_FLAGS)
                        LD      A,($C1F1)
                        LD      C,PORT_RIGHT_LAMPS
                        JR      Z,restore_hit_lamps
                        LD      A,($C1EE)
                        LD      C,PORT_LEFT_LAMPS
restore_hit_lamps:      OUT     (C),A
                        POP     DE
                        POP     BC
next_hit_score_record:  ADD     IY,DE
                        DJNZ    erase_hit_score_loop
                        DB      $21,$F2,$C1,$11,$CE,$C1,$01,$1C,$6F,$CD,$C4 ; $0B4C
                        DB      $0B,$21,$F4,$C1,$11,$CF,$C1,$01,$E0,$6E,$CD,$C4,$0B,$3E,$96,$32 ; $0B57  .!.......n...>.2
                        DB      $01,$C2,$3E,$00,$32,$FF,$C1,$3E,$08,$32,$02,$C2,$21,$53,$1B,$3A ; $0B67  ..>.2..>.2..!S.:
                        DB      $F4,$C1,$B7,$C4,$D7,$15,$3E,$78,$32,$FF,$C1,$3E,$04,$32,$02,$C2 ; $0B77  ......>x2..>.2..
                        DB      $21,$53,$1B,$3A,$F2,$C1,$B7,$C4,$D7,$15,$3E,$AB,$32,$01,$C2,$3E ; $0B87  !S.:......>.2..>
                        DB      $82,$32,$FF,$C1,$3A,$F3,$C1,$4F,$06,$00,$3A,$F2,$C1,$B7,$C4,$AE ; $0B97  .2..:..O..:.....
                        DB      $0C,$3E,$08,$32,$02,$C2,$3E,$07,$32,$FF,$C1,$3A,$F5,$C1,$4F,$06 ; $0BA7  .>.2..>.2..:..O.
                        DB      $00,$3A,$F4,$C1,$B7,$C4,$AE,$0C,$FD,$E1,$C1,$FD,$E9,$7E,$B7,$C8 ; $0BB7  .:...........~..
                        DB      $1A,$B7,$C0,$36,$00,$60,$69,$11,$3C,$00,$AF,$0E,$20,$06,$14,$77 ; $0BC7  ...6.`i.<... ..w
                        DB      $23,$10,$FC,$19,$0D,$20,$F6,$C9 ; $0BD7

;-------------------------------------------------------------------------------
; $0BDF: Seed the target and interleaved torpedo pools from ROM templates
;-------------------------------------------------------------------------------
; Records 0 and 2 of the four-record target pool receive distinct templates;
; records 1 and 3 remain available as their trailing lane partners.  The next
; two templates initialize the first left/right torpedo records at $C0FA/$C113.
INITIALIZE_OBJECT_POOLS:
                        LD      A,(TARGET_POOL_BASE+OBJECT_FLAGS)
                        BIT     7,A
                        JR      NZ,object_pools_ready
                        LD      A,($C032+OBJECT_FLAGS)
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
                        LD      ($C032+OBJECT_FLAGS),A
                        LD      (TORPEDO_POOL_LEFT_BASE+OBJECT_FLAGS),A
                        LD      (TORPEDO_POOL_RIGHT_BASE+OBJECT_FLAGS),A
                        POP     BC
object_pools_ready:     JP      (IY)
                        DB      $C5,$3A,$F8,$C1,$B7,$28,$32,$21,$CC,$C1,$7E,$B7,$20 ; $0C1A
                        DB      $2B,$36,$1E,$3E,$02,$32,$01,$C2,$3E,$0A,$32,$FF,$C1,$3A,$02,$C2 ; $0C27  +6.>.2..>.2..:..
                        DB      $EE,$0C,$32,$02,$C2,$21,$E7,$1A,$3A,$05,$C2,$FE,$00,$28,$0A,$21 ; $0C37  ..2..!..:....(.!
                        DB      $F7,$1A,$FE,$01,$28,$03,$21,$07,$1B,$CD,$E4,$15,$C1,$FD,$E9     ; $0C47

; $C1D6 is adjacent to the sound timers but drives port-$41 bit 6, the coin
; counter output.  Each queued coin produces a ten-frame hardware pulse.
PULSE_COIN_COUNTER:
                        LD      DE,COIN_COUNTER_PULSE_TIMER
                        LD      A,(DE)
                        OR      A
                        JR      NZ,coin_counter_done
                        LD      HL,$C207
                        LD      A,(HL)
                        OR      A
                        JR      Z,coin_counter_done
                        DEC     (HL)
                        LD      A,$0A
                        LD      (DE),A
                        LD      HL,$C206
                        INC     (HL)
coin_counter_done:      JP      (IY)
                        DB      $0A,$03,$5F,$0A,$03,$57,$0A,$03,$67 ; $0C6E
                        DB      $2E,$00,$22,$00,$C2,$0A,$03,$67,$22,$FE,$C1,$3E,$0C,$32,$02,$C2 ; $0C77  .."....g"..>.2..
                        DB      $EB,$0A,$03,$B7,$C5,$20,$05,$CD,$E4,$15,$18,$03,$CD,$D7,$15,$C1 ; $0C87  ..... ..........
                        DB      $FD,$E9,$C5,$CD,$A0,$0C,$C1,$FD,$E9,$21,$09,$C2,$3E,$76,$32,$FF ; $0C97  .........!..>v2.
                        DB      $C1,$3E,$02,$16,$0C,$18,$08,$C5,$18,$10,$32,$FF,$C1,$3E,$BE,$32 ; $0CA7  .>........2..>.2
                        DB      $01,$C2,$7A,$32,$02,$C2,$C5,$46,$2B,$4E,$21,$00,$00,$E5,$21,$30 ; $0CB7  ..z2...F+N!...!0
                        DB      $30,$E5,$79,$CD,$F0,$0C,$78,$CD,$F0,$0C,$21,$00,$00,$39,$E5,$01 ; $0CC7  0.y...x...!..9..
                        DB      $40,$04,$3E,$30,$BE,$20,$04,$71,$23,$10,$F9,$E1,$CD,$E4,$15,$33 ; $0CD7   .>0. .q#......3
                        DB      $33,$33,$33,$33,$33,$33,$33,$C1,$C9,$57,$1F,$1F,$1F,$1F,$E6,$0F ; $0CE7  3333333..W......
                        DB      $F6,$30,$6F,$7A,$E6,$0F,$F6,$30,$67,$E3,$E9,$3E,$01,$32,$CA,$C1 ; $0CF7  .0oz...0g..>.2..
                        DB      $3E,$3C,$32,$FF,$C1,$3E,$4B,$32,$01,$C2,$3E,$0C,$32,$02,$C2,$21 ; $0D07  ><2..>K2..>.2..!
                        DB      $7B,$13,$CD,$D7,$15,$3E,$44,$32,$FF,$C1,$3E,$69,$32,$01,$C2,$21 ; $0D17  {....>D2..>i2..!
                        DB      $81,$13,$CD,$D7,$15,$06,$40,$76,$10,$FD,$21,$8E,$57,$11,$3C,$00 ; $0D27  ...... v..!.W.<.
                        DB      $AF,$0E,$32,$06,$14,$77,$23,$10,$FC,$19,$0D,$20,$F6,$32,$CA,$C1 ; $0D37  ..2..w#.... .2..
                        DB      $C9                                                     ; $0D47  RET

;-------------------------------------------------------------------------------
; $0D48: Left-station torpedo launch X/velocity pairs
;-------------------------------------------------------------------------------
TORPEDO_TRAJECTORY_LEFT_TABLE:
                        DB      $90,$70,$8A,$6D,$85,$6A,$7F,$67,$7A,$64,$75,$61,$6F,$5E,$6A ; $0D48
                        DB      $5B,$65,$58,$61,$55,$5C,$52,$57,$4F,$52,$4C,$4E,$49,$49,$46,$44 ; $0D57  [eXaU\RWORLNIIFD
                        DB      $43,$40,$40,$3B,$3D,$37,$3A,$33,$37,$2E,$34,$2A,$31,$26,$2E,$21 ; $0D67  C  ;=7:37.4*1&.!
                        DB      $2B,$1D,$28,$19,$25,$15,$22,$10,$1F,$0D,$1C,$08,$19,$04,$16,$00 ; $0D77  +.(.%.".........
                        DB      $13                                                     ; $0D87

;-------------------------------------------------------------------------------
; $0D88: Right-station torpedo launch X/velocity pairs
;-------------------------------------------------------------------------------
TORPEDO_TRAJECTORY_RIGHT_TABLE:
                        DB      $9B,$00,$96,$FD,$92,$FA,$8E,$F7,$8A,$F4,$86,$F1,$81,$EE,$7D ; $0D88
                        DB      $EB,$79,$E8,$75,$E5,$70,$E2,$6C,$DF,$68,$DC,$63,$D9,$5F,$D6,$5A ; $0D97  .y.u.p.l.h.c._.Z
                        DB      $D3,$56,$D0,$51,$CD,$4D,$CD,$48,$CA,$43,$C7,$3E,$C4,$3A,$C1,$35 ; $0DA7  .V.Q.M.H.C.>.:.5
                        DB      $BE,$30,$BB,$2B,$B8,$25,$B5,$20,$B2,$1B,$AF,$16,$AC,$10,$A9,$0A ; $0DB7  .0.+.%. ........
                        DB      $A6                                                     ; $0DC7

;-------------------------------------------------------------------------------
; $0DC8: Cyclic object-type sequence for the two moving-target lanes
;-------------------------------------------------------------------------------
TARGET_TYPE_SEQUENCE:
                        DB      $03,$00,$05,$04,$01,$03,$02,$04,$05,$FF                 ; $0DC8

;-------------------------------------------------------------------------------
; $0DD2: Signed base horizontal speed indexed by object type
;-------------------------------------------------------------------------------
TARGET_SPEED_TABLE:
                        DB      $40,$40,$40,$20,$20                                     ; $0DD2
                        DB      $80,$00,$00,$40                                         ; $0DD7

;-------------------------------------------------------------------------------
; $0DDB: Four 25-byte records copied into target and torpedo pools
;-------------------------------------------------------------------------------
OBJECT_INITIAL_TEMPLATES:
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$1A,$00,$00,$00         ; $0DDB
                        DB      $80,$00,$00,$00,$00,$8C,$00,$00,$08,$00,$00,$04,$00,$00,$08,$00 ; $0DE7  ................
                        DB      $00,$00,$00,$00,$00,$33,$00,$00,$00,$80,$FF,$00,$8C,$00,$9F,$00 ; $0DF7  .....3..........
                        DB      $00,$48,$00,$00,$0C,$00,$00,$07,$00,$06,$00,$00,$FD,$00,$BE,$23 ; $0E07  .H.............#
                        DB      $00,$00,$00,$00,$00,$20,$00,$9F,$2D,$11,$08,$00,$00,$08,$00,$00 ; $0E17  ..... ..-.......
                        DB      $07,$00,$06,$00,$00,$FD,$00,$BE,$23,$00,$00,$00,$00,$00,$78,$00 ; $0E27  ........#.....x.
                        DB      $9F,$2D,$11,$08,$00,$00,$04,$00                         ; $0E37

;-------------------------------------------------------------------------------
; $0E3F: Object bitmap descriptors and animation frames
;-------------------------------------------------------------------------------
OBJECT_BITMAP_DATA:
                        DB      $05,$0C,$00,$00,$20,$00,$00,$00                         ; $0E3F
                        DB      $00,$00,$00,$00,$00,$0C,$E0,$00,$00,$00,$0E,$E3,$F8,$00,$00,$0E ; $0E47  ................
                        DB      $F3,$80,$00,$1F,$DF,$F7,$DF,$E0,$03,$DF,$F7,$DE,$00,$3F,$FF,$FF ; $0E57  .............?..
                        DB      $FF,$FF,$3F,$FF,$FF,$FF,$FE,$3F,$FF,$FF,$FF,$FC,$1F,$FF,$FF,$FF ; $0E67  ..?....?........
                        DB      $F8,$0F,$FF,$FF,$FF,$F0,$04,$0B,$00,$00,$40,$00,$00,$00,$30,$00 ; $0E77  .......... ...0.
                        DB      $00,$36,$38,$00,$00,$36,$78,$00,$00,$36,$78,$00,$1F,$7E,$79,$F8 ; $0E87  .68..6x..6x..~y.
                        DB      $07,$7F,$FD,$C0,$3F,$FF,$FF,$FF,$3F,$FF,$FF,$FE,$1F,$FF,$FF,$FC ; $0E97  ....?...?.......
                        DB      $1F,$FF,$FF,$F8,$05,$0A,$00,$00,$44,$00,$00,$00,$00,$1E,$00,$00 ; $0EA7  ........D.......
                        DB      $00,$00,$1E,$00,$00,$00,$00,$1E,$F0,$00,$19,$99,$BE,$C0,$00,$3F ; $0EB7  ...............?
                        DB      $FF,$FF,$FF,$FF,$3F,$FF,$FF,$FF,$FC,$1F,$FF,$FF,$FF,$F8,$1F,$FF ; $0EC7  ....?...........
                        DB      $FF,$FF,$F0,$0F,$FF,$FF,$FF,$F0,$04,$0A,$04,$00,$01,$00,$04,$00 ; $0ED7  ................
                        DB      $81,$00,$04,$00,$61,$00,$04,$00,$61,$00,$04,$1F,$E1,$00,$04,$3F ; $0EE7  ....a...a......?
                        DB      $E1,$00,$3C,$3F,$E1,$3F,$3F,$FF,$FF,$FE,$3F,$FF,$FF,$FC,$1F,$FF ; $0EF7  ..<?.??...?.....
                        DB      $FF,$F8,$04,$09,$00,$10,$00,$20,$03,$10,$00,$20,$03,$10,$00,$20 ; $0F07  ....... ... ...
                        DB      $0F,$10,$00,$20,$1F,$10,$00,$20,$3F,$10,$00,$3F,$3F,$FF,$FF,$FE ; $0F17  ... ... ?..??...
                        DB      $1F,$FF,$FF,$FC,$1F,$FF,$FF,$FC,$03,$05,$00,$0F,$00,$00,$1F,$80 ; $0F27  ................
                        DB      $00,$FF,$FC,$0F,$FF,$F8,$0F,$FF,$F0,$04,$09,$00,$00,$00,$00,$00 ; $0F37  ................
                        DB      $00,$06,$00,$00,$00,$04,$00,$00,$00,$3E,$00,$00,$00,$3E,$00,$30 ; $0F47  .........>...>.0
                        DB      $00,$7E,$00,$3C,$3F,$FF,$FC,$3F,$FF,$FF,$FF,$3F,$FF,$FF,$FF,$04 ; $0F57  .~.<?..?...?....
                        DB      $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$04 ; $0F67  ................
                        DB      $00,$00,$00,$3E,$00,$00,$00,$3E,$00,$00,$00,$7E,$00,$00,$3F,$FF ; $0F77  ...>...>...~..?.
                        DB      $FC,$04,$06,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$04,$00,$00 ; $0F87  ................
                        DB      $00,$3E,$00,$00,$00,$3E,$00,$00,$00,$7E,$00,$04,$0D,$00,$00,$00 ; $0F97  .>...>...~......
                        DB      $04,$00,$00,$00,$8C,$00,$00,$01,$1C,$00,$00,$02,$3C,$24,$00,$06 ; $0FA7  ............<$..
                        DB      $7C,$72,$00,$0E,$FC,$7B,$00,$7F,$F8,$FF,$80,$7F,$F0,$7F,$8C,$3F ; $0FB7  |r...{.........?
                        DB      $E0,$3F,$3C,$7F,$C0,$1F,$FC,$7F,$80,$0F,$F8,$FF,$00,$07,$F8,$FF ; $0FC7  .?<.............
                        DB      $00,$03,$FC,$CC,$00,$00,$9F,$88,$00,$04,$0A,$00,$00,$00,$04,$00 ; $0FD7  ................
                        DB      $00,$00,$8C,$00,$00,$01,$1C,$00,$00,$02,$3C,$24,$00,$06,$7C,$72 ; $0FE7  ..........<$..|r
                        DB      $00,$0E,$FC,$7B,$00,$7F,$F8,$FF,$80,$7F,$F0,$7F,$8C,$3F,$E0,$3F ; $0FF7  ...{.........?.?
                        DB      $3C,$7F,$C0,$04,$07,$00,$00,$00,$04,$00,$00,$00,$8C,$00,$00,$01 ; $1007  <...............
                        DB      $1C,$00,$00,$02,$3C,$24,$00,$06,$7C,$72,$00,$0E,$FC,$7B,$00,$7F ; $1017  ....<$..|r...{..
                        DB      $F8,$04,$04,$00,$00,$00,$04,$00,$00,$00,$8C,$00,$00,$01,$1C,$00 ; $1027  ................
                        DB      $00,$02,$3C,$04,$02,$00,$00,$00,$04,$00,$00,$00,$8C,$02,$0C,$08 ; $1037  ..<.............
                        DB      $00,$0C,$40,$0E,$80,$3F,$00,$1F,$88,$0F,$DC,$07,$FE,$03,$FC,$01 ; $1047  .. ..?..........
                        DB      $F8,$00,$FC,$00,$78,$00,$20,$02,$09,$08,$00,$0C,$40,$0E,$80,$3F ; $1057  ....x. ..... ..?
                        DB      $00,$1F,$88,$0F,$DC,$07,$FE,$03,$FC,$01,$F8,$02,$06,$08,$00,$0C ; $1067  ................
                        DB      $40,$0E,$80,$3F,$00,$1F,$88,$0F,$DC,$02,$04,$08,$00,$0C,$40,$0E ; $1077   ..?.......... .
                        DB      $80,$3F,$00,$02,$02,$08,$00,$0C,$40,$02,$0F,$21,$2A,$11,$46,$00 ; $1087  .?...... ..!*.F.
                        DB      $48,$89,$01,$45,$22,$31,$02,$18,$18,$0C,$39,$24,$60,$A4,$00,$20 ; $1097  H..E"1....9$`..
                        DB      $04,$04,$42,$0C,$E1,$1C,$F0,$3F,$F1,$03,$05,$E0,$40,$21,$3C,$10 ; $10A7  ..B....?.... !<.
                        DB      $C2,$07,$01,$8C,$C0,$44,$F0,$0F,$FF,$F0,$04,$0B,$20,$62,$08,$48 ; $10B7  .....D...... b.H
                        DB      $10,$10,$44,$41,$0C,$00,$82,$22,$07,$00,$80,$4C,$40,$18,$00,$58 ; $10C7  ..DA..."...L ..X
                        DB      $08,$11,$08,$00,$0F,$18,$00,$FF,$0F,$C0,$07,$FE,$0F,$F0,$1F,$FC ; $10D7  ................
                        DB      $07,$FF,$FF,$F8,$07,$FF,$FF,$F0,$05,$0C,$40,$01,$10,$80,$41,$20 ; $10E7  .......... ...A
                        DB      $02,$08,$84,$42,$10,$C2,$00,$90,$8C,$18,$44,$10,$00,$9C,$06,$20 ; $10F7  ...B......D....
                        DB      $90,$89,$00,$00,$20,$81,$30,$00,$18,$00,$40,$00,$0F,$3E,$00,$00 ; $1107  .... .0... ..>..
                        DB      $00,$0E,$3F,$80,$00,$00,$FC,$3F,$E1,$F0,$1F,$F8,$1F,$FF,$FF,$FF ; $1117  ..?....?........
                        DB      $F0,$1F,$FF,$FF,$FF,$E0,$01,$15,$20,$70,$70,$70,$70,$70,$70,$70 ; $1127  ........ ppppppp
                        DB      $70,$70,$70,$70,$70,$20,$20,$20,$70,$00,$00,$00,$00,$00,$00,$00 ; $1137  ppppp   p.......
                        DB      $01,$15,$60,$60,$60,$60,$60,$60,$60,$00,$60,$00,$00,$00,$00,$00 ; $1147  ..```````.`.....
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$0B,$40,$40,$40 ; $1157  .............
                        DB      $40,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $1167    ..............
                        DB      $00,$00,$00,$00,$01,$10,$08,$5D,$3E,$7F,$3E,$1C,$2A,$08,$00,$08 ; $1177  .......]>.>.*...
                        DB      $00,$10,$00,$00,$20,$00,$01,$10,$91,$52,$44,$28,$18,$25,$A4,$18 ; $1187  .... ....RD(.%..
                        DB      $28,$44,$42,$92,$09,$10,$08,$10                                 ; $1197  (DB.....

;-------------------------------------------------------------------------------
; $119F: Ten-byte character bitmaps indexed by character minus ASCII '0'
;-------------------------------------------------------------------------------
FONT_BITMAPS:
                        DB      $3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C,$18,$38,$18,$18,$18,$18 ; $119F  <~ffffff~<.8....
                        DB      $18,$18,$3C,$3C,$3C,$7E,$66,$06,$3E,$7C,$60,$60,$7E,$7E,$3C,$7E ; $11AF  ..<<<~f.>|``~~<~
                        DB      $66,$06,$1C,$1E,$06,$66,$7E,$3C,$66,$66,$66,$66,$7E,$7E,$06,$06 ; $11BF  f....f~<ffff~~..
                        DB      $06,$06,$7C,$7C,$60,$60,$7C,$7E,$06,$66,$7E,$3C,$3C,$7C,$60,$60 ; $11CF  ..||``|~.f~<<|``
                        DB      $7C,$7E,$66,$66,$7E,$3C,$7E,$7E,$06,$0E,$0C,$1C,$18,$38,$30,$30 ; $11DF  |~ff~<~~.....800
                        DB      $3C,$7E,$66,$66,$3C,$7E,$66,$66,$7E,$3C,$3C,$7E,$66,$66,$7E,$3E ; $11EF  <~ff<~ff~<<~ff~>
                        DB      $06,$06,$3E,$3C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $11FF  ..><............
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $120F  ................
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $121F  ................
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $122F  ................
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18,$3C,$7E,$66,$66,$66 ; $123F  ...........<~fff
                        DB      $7E,$7E,$66,$66,$7C,$7E,$66,$66,$7C,$7E,$66,$66,$7E,$7C,$3C,$7E ; $124F  ~~ff|~ff|~ff~|<~
                        DB      $66,$60,$60,$60,$60,$66,$7E,$3C,$7C,$7E,$66,$66,$66,$66,$66,$66 ; $125F  f````f~<|~ffffff
                        DB      $7E,$7C,$7E,$7E,$60,$60,$7C,$7C,$60,$60,$7E,$7E,$7E,$7E,$60,$60 ; $126F  ~|~~``||``~~~~``
                        DB      $7C,$7C,$60,$60,$60,$60,$3C,$7E,$60,$60,$60,$6E,$6E,$66,$7E,$3C ; $127F  ||````<~```nnf~<
                        DB      $66,$66,$66,$66,$7E,$7E,$66,$66,$66,$66,$3C,$3C,$18,$18,$18,$18 ; $128F  ffff~~ffff<<....
                        DB      $18,$18,$3C,$3C,$06,$06,$06,$06,$06,$06,$66,$66,$7E,$3C,$66,$66 ; $129F  ..<<......ff~<ff
                        DB      $6E,$7C,$78,$78,$6C,$6E,$66,$66,$60,$60,$60,$60,$60,$60,$60,$60 ; $12AF  n|xxlnff````````
                        DB      $7E,$7E,$C3,$E7,$E7,$DB,$DB,$C3,$C3,$C3,$C3,$C3,$66,$66,$76,$7E ; $12BF  ~~..........ffv~
                        DB      $7E,$6E,$66,$66,$66,$66,$3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C ; $12CF  ~nffff<~ffffff~<
                        DB      $7C,$7E,$66,$66,$7E,$7C,$60,$60,$60,$60,$3C,$7E,$66,$66,$66,$66 ; $12DF  |~ff~|````<~ffff
                        DB      $66,$6E,$64,$3A,$7C,$7E,$66,$66,$7E,$7C,$6E,$66,$66,$66,$3C,$7E ; $12EF  fnd:|~ff~|nfff<~
                        DB      $66,$60,$7C,$3E,$06,$66,$7E,$3C,$7E,$7E,$18,$18,$18,$18,$18,$18 ; $12FF  f`|>.f~<~~......
                        DB      $18,$18,$66,$66,$66,$66,$66,$66,$66,$66,$7E,$3C,$66,$66,$66,$66 ; $130F  ..ffffffff~<ffff
                        DB      $66,$7E,$3C,$3C,$18,$18,$C3,$C3,$C3,$DB,$DB,$DB,$FF,$E7,$C3,$C3 ; $131F  f~<<............
                        DB      $66,$66,$7E,$3C,$18,$18,$3C,$7E,$66,$66,$66,$66,$7E,$3C,$18,$18 ; $132F  ff~<..<~ffff~<..
                        DB      $18,$18,$18,$18,$7E,$7E,$06,$0E,$1C,$38,$70,$60,$7E,$7E,$EB,$EE ; $133F  ....~~...8p`~~..
                        DB      $00,$4A,$A8,$00,$4A,$AC,$00,$4A,$28,$00,$4A,$2E,$00             ; $134F  .J..J..J(.J..

;-------------------------------------------------------------------------------
; $135C: Small status graphics used by player display rendering
;-------------------------------------------------------------------------------
PLAYER_STATUS_BITMAPS:
                        DB      $EE,$EF,$70,$88,$A9,$40,$E8,$AF,$60,$28,$AA,$40,$EE,$E9,$70,$40 ; $135C  ..p.. ..`(. ..p
                        DB      $40,$40,$40,$00                                                 ; $136C     .

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
                        IN      A,(PORT_P2_HANDLE)
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
; Round-robin workload per service pass: two of four targets, four of eight
; torpedoes, and one of six mines.  Persistent cursors cover each complete pool
; across subsequent interrupts without scanning inactive records linearly.
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
                        LD      HL,$C1DA
                        XOR     A
                        CP      (HL)
                        JR      NZ,read_coin_input
                        LD      (HL),$3C
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
                        AND     $01
                        LD      HL,$C1F9
                        PUSH    AF
                        XOR     (HL)
                        JR      Z,save_coin_input
                        AND     (HL)
                        JR      Z,save_coin_input
                        LD      A,($C207)
                        INC     A
                        LD      ($C207),A
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

; The diving target advances its first two frames on a 42-tick cadence.  Other
; target types retain the animation frame selected by their state path.
                        LD      A,(IX+OBJECT_TYPE)
                        CP      OBJECT_TYPE_DIVE_TARGET
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
                        CALL    ERASE_OBJECT_BITMAP
                        RES     7,(IX+OBJECT_FLAGS)
                        RET

; Clear the two per-station result bytes selected by torpedo-record parity.
; The even interleaved torpedo records belong to the left station.
CLEAR_TORPEDO_RESULT_STATE:
                        PUSH    IX
                        POP     HL
                        BIT     0,L
                        LD      HL,$C1EA
                        JR      NZ,torpedo_result_state_selected
                        LD      HL,$C1E5
torpedo_result_state_selected:
                        LD      (HL),$00
                        INC     HL
                        LD      (HL),$00
                        RET
;-------------------------------------------------------------------------------
; $14B4: Update one torpedo and resolve its collision lane
;-------------------------------------------------------------------------------
UPDATE_TORPEDO_OBJECT:  LD      HL,$112D               ; base torpedo bitmap
                        LD      (IX+OBJECT_BITMAP_PTR_HI),H
                        LD      (IX+OBJECT_BITMAP_PTR_LO),L
                        LD      H,(IX+OBJECT_VRAM_ADDR_HI)
                        LD      L,(IX+OBJECT_VRAM_ADDR_LO)
                        PUSH    HL                      ; previous draw address
                        CALL    INTEGRATE_OBJECT_MOTION
                        BIT     4,(IX+OBJECT_FLAGS)
                        PUSH    AF
                        CALL    NZ,CLEAR_TORPEDO_RESULT_STATE
                        POP     AF
                        PUSH    AF
                        CALL    Z,PREPARE_OBJECT_RENDER
                        POP     AF
                        POP     HL
                        JR      NZ,ERASE_AND_DEACTIVATE_OBJECT
                        LD      A,H
                        OR      L
                        JP      Z,DRAW_NEW_TORPEDO_FRAME

; Probe the seven Magic-RAM bytes covered by the torpedo's old bitmap.  Only
; pixel values with either high color bit set can represent a target overlap.
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

; The torpedo's Y coordinate selects one of five two-record collision lanes.
; C preserves the lane number: 1-2 are ships, 3-5 are mines.
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

; Lane selection establishes vertical overlap.  Horizontal overlap uses the
; target bitmap width in four-pixel units.  Already exploding targets are not
; eligible for a second collision.
scan_collision_candidates:
                        BIT     7,(IY+OBJECT_FLAGS)
                        JR      Z,next_collision_candidate
                        LD      A,(IX+OBJECT_X_POSITION_HI)
                        ADD     A,$04
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
; target.  IX record parity selects the cabinet side; the target class in C
; selects ship-hit or mine-hit.  D becomes the matching two-bit side mask.
SELECT_COLLISION_SOUND_SIDE:
                        PUSH    IX
                        POP     HL
                        LD      D,$30                  ; right ship/mine bits 4/5
                        RES     3,(IY+OBJECT_FLAGS)
                        BIT     0,L
                        JR      NZ,collision_side_selected
                        SET     3,(IY+OBJECT_FLAGS)
                        LD      D,$06                  ; left ship/mine bits 1/2
collision_side_selected:
                        LD      B,(IX+OBJECT_COLOR)
                        RES     7,(IX+OBJECT_FLAGS)

; C > 2 is a mine collision: mask $24 selects bits 2/5 and produces an
; eight-frame mine-hit pulse.  C <= 2 is a ship collision: mask $12 selects
; bits 1/4 and produces a $40-frame ship-hit pulse.
TRIGGER_SHIP_OR_MINE_HIT_SOUND:
                        LD      A,$02
                        CP      C
select_mine_hit_sound:
                        LD      A,$24
                        LD      C,$08
                        PUSH    AF
                        CALL    C,CLEAR_TORPEDO_RESULT_STATE
                        POP     AF
                        JR      C,hit_sound_class_selected
select_ship_hit_sound:
                        LD      A,$12
                        LD      C,$40
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
; compact duplicated-pixel renderer.
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
                        DB      $3E,$01,$32,$DD,$C1,$CD,$E4,$15,$AF,$32,$DD,$C1,$C9 ; $15D7

;-------------------------------------------------------------------------------
; $15E4: Draw a zero-terminated text string
;-------------------------------------------------------------------------------
DRAW_TEXT:
                        DB      $C5,$D5,$7E,$B7,$28,$08,$E5,$CD,$F5,$15,$E1,$23,$18,$F4,$D1,$C1 ; $15E4  ..~.(......#....
                        DB      $C9                                                             ; $15F4  .

;-------------------------------------------------------------------------------
; $15F5: Map a character code to its ten-byte font bitmap
;-------------------------------------------------------------------------------
DRAW_CHARACTER:
                        DB      $D6,$30,$6F,$26,$00,$29,$E5,$29,$29,$D1,$19,$11,$9F,$11,$19,$E5 ; $15F5  .0o&.).)).......
                        DB      $ED,$5B,$00,$C2,$2A,$FE,$C1,$CD,$51,$19,$D1,$CD,$DF,$16         ; $1605  .[..*...Q.....

;-------------------------------------------------------------------------------
; $1613: Render a ten-row character bitmap
;-------------------------------------------------------------------------------
DRAW_CHARACTER_ROWS:
                        DB      $06,$0A,$3A,$DD,$C1,$B7,$20,$28,$E5,$3A,$02,$C2,$F3,$D3,$19,$3E ; $1613  ..:... (.:.....>
                        DB      $08,$D3,$0C,$1A,$77,$23,$77,$FB,$E1,$D5,$11,$50,$00,$19,$D1,$13 ; $1623  ....w#w....P....
                        DB      $10,$E6,$CD,$DF,$16,$2A,$FE,$C1,$11,$00,$04,$19,$22,$FE,$C1,$C9 ; $1633  .....*......"...
                        DB      $E5,$3E,$0C,$F3,$D3,$19,$3E,$08,$D3,$0C,$1A,$32,$FE,$3F,$FB,$32 ; $1643  .>....>....2.?.2
                        DB      $FF,$3F,$3A,$02,$C2,$F3,$D3,$19,$3E,$18,$D3,$0C,$3A,$FE,$7F,$77 ; $1653  .?:.....>...:..w
                        DB      $23,$77,$3A,$FF,$7F,$23,$77,$23,$FB,$77,$E1,$D5,$11,$A0,$00,$19 ; $1663  #w:..#w#.w......
                        DB      $D1,$13,$10,$CC,$2A,$FE,$C1,$11,$00,$08,$19,$22,$FE,$C1,$C9     ; $1673  ....*......"...

;-------------------------------------------------------------------------------
; $1682: Draw player-specific status graphics
;-------------------------------------------------------------------------------
DRAW_PLAYER_STATUS:
                        DB      $3A,$FB,$C1,$B7,$C8,$FE,$02,$20,$10,$06,$00,$16,$B8,$21,$00,$07 ; $1682  :...... .....!..
                        DB      $CD,$51,$19,$11,$5C,$13,$CD,$BC,$16,$06,$00,$16,$B8,$21,$00,$82 ; $1692  .Q..\........!..
                        DB      $CD,$51,$19,$11,$5C,$13,$CD,$BC,$16,$06,$00,$16,$B8,$21,$00,$4D ; $16A2  .Q..\........!.M
                        DB      $CD,$51,$19,$11,$4D,$13,$CD,$BC,$16,$C9                         ; $16B2  .Q..M.....

;-------------------------------------------------------------------------------
; $16BC: Render a compact bitmap through Magic RAM
;-------------------------------------------------------------------------------
DRAW_SMALL_BITMAP:
                        DB      $0E,$05,$E5,$3E,$0C,$F3,$D3,$19,$3E,$08,$D3,$0C,$06,$03,$1A,$77 ; $16BC  ...>....>......w
                        DB      $23,$77,$23,$13,$10,$F8,$FB,$E1,$7D,$C6,$50,$6F,$30,$01,$24,$0D ; $16CC  #w#.....}.Po0.$.
                        DB      $20,$E0,$C9                                                     ; $16DC   ..

;-------------------------------------------------------------------------------
; $16DF: Clear the current character cell rows
;-------------------------------------------------------------------------------
CLEAR_CHARACTER_ROWS:
                        DB      $E5,$3A,$02,$C2,$F3,$D3,$19,$3E,$08,$D3,$0C,$AF,$77,$23,$77,$FB ; $16DF  .:.....>....w#w.
                        DB      $E1,$01,$50,$00,$09,$C9 ; $16EF

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

; Inactive records reuse byte 2 as a respawn/cooldown timer.
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
ADVANCE_OBJECT_HIT_ANIMATION:
                        CALL    DECAY_OBJECT_TIMER
                        OR      A
                        RET     NZ
                        LD      (IX+OBJECT_TIMER),$06
                        CALL    ERASE_OBJECT_BITMAP
                        LD      A,(IX+OBJECT_TYPE)
                        CP      OBJECT_TYPE_DIVE_TARGET
                        JR      NZ,advance_hit_frame
                        LD      A,(IX+OBJECT_ANIMATION_FRAME)
                        CP      $02
                        JR      NC,advance_hit_frame
                        LD      (IX+OBJECT_ANIMATION_FRAME),$02
advance_hit_frame:      INC     (IX+OBJECT_ANIMATION_FRAME)
                        CALL    SELECT_OBJECT_BITMAP
                        JP      NZ,DRAW_OBJECT_BITMAP
                        RES     7,(IX+OBJECT_FLAGS)
                        LD      (IX+OBJECT_TIMER),$2D
                        RET

; Clear the complete bounding box occupied by the prior bitmap.  The bitmap
; descriptor begins with source-byte width and row count; VRAM rows are $50
; bytes apart.
ERASE_OBJECT_BITMAP:    LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        LD      E,(HL)
                        INC     E
                        INC     HL
                        LD      D,(HL)
                        LD      H,(IX+OBJECT_VRAM_ADDR_HI)
                        LD      L,(IX+OBJECT_VRAM_ADDR_LO)
                        XOR     A
                        OUT     ($0C),A
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
; $1856: Draw the selected bitmap in its configured horizontal direction
;-------------------------------------------------------------------------------
DRAW_OBJECT_BITMAP:     BIT     6,(IX+OBJECT_MAGIC_MODE)
                        JP      NZ,DRAW_OBJECT_BITMAP_REVERSED
                        CALL    PREPARE_OBJECT_RENDER
                        LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        LD      D,(IX+OBJECT_VRAM_ADDR_HI)
                        LD      E,(IX+OBJECT_VRAM_ADDR_LO)
                        PUSH    HL
                        POP     IY
                        INC     HL
                        INC     HL
                        LD      C,(IY+BITMAP_ROW_COUNT)
draw_object_forward_row:
                        LD      B,(IY+BITMAP_SOURCE_WIDTH)
                        PUSH    DE
                        BIT     3,(IX+OBJECT_MAGIC_MODE)
                        JR      NZ,draw_forward_expanded
draw_forward_byte:      LD      A,(HL)
                        LD      (DE),A
                        INC     DE
                        INC     HL
                        DJNZ    draw_forward_byte
                        JR      finish_forward_row
draw_forward_expanded:  LD      A,(HL)
                        LD      (DE),A
                        INC     DE
                        LD      (DE),A
                        INC     DE
                        INC     HL
                        DJNZ    draw_forward_expanded
finish_forward_row:     XOR     A
                        LD      (DE),A
                        LD      ($3FFF),A
                        POP     DE
                        DEC     C
                        RET     Z
                        LD      A,E
                        ADD     A,$50
                        LD      E,A
                        JR      NC,draw_object_forward_row
                        INC     D
                        JR      draw_object_forward_row

; Reverse drawing starts at the bitmap's right edge and walks VRAM backward.
DRAW_OBJECT_BITMAP_REVERSED:
                        CALL    PREPARE_OBJECT_RENDER
                        LD      D,(IX+OBJECT_VRAM_ADDR_HI)
                        LD      E,(IX+OBJECT_VRAM_ADDR_LO)
                        LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        PUSH    HL
                        POP     IY
                        INC     HL
                        INC     HL
                        LD      B,(IY+BITMAP_SOURCE_WIDTH)
                        BIT     3,(IX+OBJECT_MAGIC_MODE)
                        JR      Z,reverse_width_ready
                        SLA     B
reverse_width_ready:    LD      A,(IX+OBJECT_MAGIC_MODE)
                        XOR     $03
                        OUT     ($0C),A
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
                        BIT     3,(IX+OBJECT_MAGIC_MODE)
                        JR      NZ,draw_reverse_expanded
draw_reverse_byte:      LD      A,(HL)
                        LD      (DE),A
                        DEC     DE
                        INC     HL
                        DJNZ    draw_reverse_byte
                        JR      finish_reverse_row
draw_reverse_expanded:  LD      A,(HL)
                        LD      (DE),A
                        DEC     DE
                        LD      (DE),A
                        DEC     DE
                        INC     HL
                        DJNZ    draw_reverse_expanded
finish_reverse_row:     XOR     A
                        LD      (DE),A
                        LD      ($3FFF),A
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
; Torpedo frames are a vertical byte stream.  Each source byte is duplicated
; horizontally and successive bytes advance one $50-byte video row.
DRAW_TORPEDO_BITMAP:    LD      A,(IX+OBJECT_COLOR)
                        OUT     ($19),A
                        LD      A,(IX+OBJECT_MAGIC_MODE)
                        OUT     ($0C),A
                        LD      D,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      E,(IX+OBJECT_BITMAP_PTR_LO)
                        LD      H,(IX+OBJECT_VRAM_ADDR_HI)
                        LD      L,(IX+OBJECT_VRAM_ADDR_LO)
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

; Convert fixed-point object coordinates to a video address and Magic-RAM
; shift.  OBJECT_Y_POSITION_HI is the bitmap's bottom edge, so its row count is
; subtracted before mapping the top-left draw position.
CALCULATE_OBJECT_SCREEN_ADDRESS:
                        LD      B,(IX+OBJECT_MAGIC_MODE)
                        LD      A,(IX+OBJECT_Y_POSITION_HI)
                        LD      H,(IX+OBJECT_BITMAP_PTR_HI)
                        LD      L,(IX+OBJECT_BITMAP_PTR_LO)
                        INC     HL
                        SUB     (HL)
                        LD      D,A
                        LD      H,(IX+OBJECT_X_POSITION_HI)
                        LD      L,(IX+OBJECT_X_POSITION_LO)
                        CALL    MAP_OBJECT_COORDINATES_TO_VRAM
                        RET

; Program the object's color/mode and retain the mapped VRAM address.  The
; coordinate mapper inserts the sub-byte horizontal shift into B.
PREPARE_OBJECT_RENDER:  CALL    CALCULATE_OBJECT_SCREEN_ADDRESS
                        LD      A,(IX+OBJECT_COLOR)
                        OUT     ($19),A
                        LD      A,B
                        OUT     ($0C),A
                        LD      (IX+OBJECT_MAGIC_MODE),B
                        LD      (IX+OBJECT_VRAM_ADDR_HI),H
                        LD      (IX+OBJECT_VRAM_ADDR_LO),L
                        RET

; D = video row; HL = 8.8 horizontal coordinate; B = base Magic-RAM mode.
; Returns HL as row*80 + x/2 and merges the two-bit pixel shift into B.
MAP_OBJECT_COORDINATES_TO_VRAM:
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
; $19D8: Raster schedule selected when DIP-switch bit 6 is set
;-------------------------------------------------------------------------------
; Each record is:
;   DB scanline, reserved, color4, color5, color6, color7
;   DW interrupt handler, optional raster-motion state
;
; The scanline order crosses the hardware counter wrap: $84, $D7, $0C, $18,
; $30, $54.  The handler and motion words in each record configure the following
; scanline.  The $0C record therefore selects the full frame service at $18.
; Records $0C, $18, $30 and $54 animate bases $18, $30, $54 and $84.
INTERRUPT_SCHEDULE_SET_A:
interrupt_schedule_a_84:
                        DB      $84,$00,$DC,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
interrupt_schedule_a_d7:
                        DB      $D7,$00,$1C,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
interrupt_schedule_a_0c:
                        DB      $0C,$00,$D8,$77,$58,$00
                        DW      VIDEO_INTERRUPT_HANDLER,RASTER_MOTION_STATE_0 ; next: $18
interrupt_schedule_a_18:
                        DB      $18,$00,$D9,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_1 ; next: $30
interrupt_schedule_a_30:
                        DB      $30,$00,$DA,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_2 ; next: $54
interrupt_schedule_a_54:
                        DB      $54,$00,$DB,$77,$58,$00
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_3 ; next: $84
                        DB      RASTER_SCHEDULE_END,$FF   ; second byte is table padding

;-------------------------------------------------------------------------------
; $1A16: Raster schedule selected when DIP-switch bit 6 is clear
;-------------------------------------------------------------------------------
INTERRUPT_SCHEDULE_SET_B:
interrupt_schedule_b_84:
                        DB      $84,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
interrupt_schedule_b_d7:
                        DB      $D7,$00,$01,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,$0000
interrupt_schedule_b_0c:
                        DB      $0C,$00,$00,$03,$07,$05
                        DW      VIDEO_INTERRUPT_HANDLER,RASTER_MOTION_STATE_0 ; next: $18
interrupt_schedule_b_18:
                        DB      $18,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_1 ; next: $30
interrupt_schedule_b_30:
                        DB      $30,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_2 ; next: $54
interrupt_schedule_b_54:
                        DB      $54,$00,$00,$03,$07,$05
                        DW      ALTERNATE_RASTER_INTERRUPT_HANDLER,RASTER_MOTION_STATE_3 ; next: $84
                        DB      RASTER_SCHEDULE_END

;-------------------------------------------------------------------------------
; $1A53: Per-type lists of object bitmap and animation-frame pointers
;-------------------------------------------------------------------------------
OBJECT_BITMAP_POINTER_LISTS:
                        DB      $3F,$0E,$EF,$10,$A2,$0F,$E0,$0F,$0A,$10,$28,$10             ; $1A53
                        DB      $3A,$10,$00,$00,$7D,$0E,$C1,$10,$5E,$10,$72,$10,$80,$10,$8A,$10 ; $1A5F  :...}...^.r.....
                        DB      $00,$00,$AB,$0E,$EF,$10,$A2,$0F,$E0,$0F,$0A,$10,$28,$10,$3A,$10 ; $1A6F  ............(.:.
                        DB      $00,$00,$DF,$0E,$C1,$10,$5E,$10,$72,$10,$80,$10,$8A,$10,$00,$00 ; $1A7F  ......^.r.......
                        DB      $09,$0F,$C1,$10,$5E,$10,$72,$10,$80,$10,$8A,$10,$00,$00,$2F,$0F ; $1A8F  ....^.r......./.
                        DB      $B0,$10,$80,$10,$8A,$10,$00,$00,$40,$0F,$66,$0F,$88,$0F,$B0,$10 ; $1A9F  ........ .f.....
                        DB      $80,$10,$8A,$10,$00,$00,$7B,$11,$8D,$11,$00,$00,$2D,$11,$47,$11 ; $1AAF  ......{.....-.G.
                        DB      $62,$11,$00,$00                                             ; $1ABF

;-------------------------------------------------------------------------------
; $1AC3: Object type to bitmap-pointer-list table
;-------------------------------------------------------------------------------
OBJECT_BITMAP_SET_TABLE:
                        DB      $53,$1A,$63,$1A,$71,$1A,$81,$1A,$8F,$1A,$9D,$1A             ; $1AC3
                        DB      $B5,$1A,$BB,$1A,$A7,$1A                                     ; $1ACF

;-------------------------------------------------------------------------------
; $1AD5: Torpedo Y thresholds and two-record collision-lane bases
;-------------------------------------------------------------------------------
TORPEDO_COLLISION_LANE_TABLE:
                        DB      $82,$C8,$C0,$64,$96,$C0,$4C,$64,$C0,$33                     ; $1AD5
                        DB      $32,$C0,$1A,$00,$C0                                         ; $1ADF

;-------------------------------------------------------------------------------
; $1AE4: Torpedo perspective-frame Y thresholds
;-------------------------------------------------------------------------------
TORPEDO_FRAME_Y_TABLE:
                        DB      $78,$46,$00                                                 ; $1AE4

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
                        DW      $1BC3,$1C5D,$1BD9,$1BEF,$1C05,$1C1B,$0000
ENGLISH_PROMPT_TABLE_1:
                        DW      $1BC3,$1C5D,$1C31,$1C5D,$1C5D,$1C5D,$0000
ENGLISH_PROMPT_TABLE_2:
                        DW      $1BC3,$1C5D,$1BD9,$1BEF,$1C31,$0000
ENGLISH_PROMPT_TABLE_3:
                        DW      $1C05,$1C5D,$0000
ENGLISH_PROMPT_TABLE_4:
                        DW      $1BC3,$1C5D,$1BD9,$1BEF,$1C31,$0000
ENGLISH_PROMPT_TABLE_5:
                        DW      $1C05,$1C5D,$0000
ENGLISH_PROMPT_TABLE_6:
                        DW      $1BC3,$1C5D,$1BD9,$1BEF,$1C47,$1C1B,$0000
ENGLISH_PROMPT_TABLE_7:
                        DW      $1C05,$1C1B,$1C5D,$1C5D,$1C5D,$1C5D,$0000
ENGLISH_PROMPT_TABLE_8:
                        DW      $1BC3,$1C5D,$1C31,$1C5D,$1C5D,$1C5D,$0000

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
                        DW      $1CDD,$1CF4,$1D0B,$1D22,$1D39,$1D50,$0000
GERMAN_PROMPT_TABLE_1:
                        DW      $1D67,$1CF4,$1D7E,$1E7B,$1E7B,$1E7B,$0000
GERMAN_PROMPT_TABLE_2:
                        DW      $1D95,$1DAC,$1DC3,$1E7B,$1E7B,$0000
GERMAN_PROMPT_TABLE_3:
                        DW      $1DDA,$1DF1,$0000
GERMAN_PROMPT_TABLE_4:
                        DW      $1D95,$1DAC,$1DC3,$1E7B,$1E7B,$0000
GERMAN_PROMPT_TABLE_5:
                        DW      $1DDA,$1DF1,$0000
GERMAN_PROMPT_TABLE_6:
                        DW      $1CDD,$1CF4,$1D0B,$1E08,$1E1F,$1E36,$0000
GERMAN_PROMPT_TABLE_7:
                        DW      $1DDA,$1E4D,$1E64,$1D50,$1E7B,$1E7B,$0000
GERMAN_PROMPT_TABLE_8:
                        DW      $1D67,$1CF4,$1D7E,$1E7B,$1E7B,$1E7B,$0000

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
                        DW      $1EFC,$1F13,$1F2A,$1F41,$1F9D,$1F9D,$0000
FRENCH_PROMPT_TABLE_1:
                        DW      $1EFC,$1F58,$1F9D,$1F9D,$1F9D,$1F9D,$0000
FRENCH_PROMPT_TABLE_2:
                        DW      $1EFC,$1F6F,$1F9D,$1F9D,$1F9D,$0000
FRENCH_PROMPT_TABLE_3:
                        DW      $1F2A,$1F9D,$0000
FRENCH_PROMPT_TABLE_4:
                        DW      $1EFC,$1F6F,$1F9D,$1F9D,$1F9D,$0000
FRENCH_PROMPT_TABLE_5:
                        DW      $1F2A,$1F9D,$0000
FRENCH_PROMPT_TABLE_6:
                        DW      $1EFC,$1F13,$1F86,$1F41,$1F9D,$1F9D,$0000
FRENCH_PROMPT_TABLE_7:
                        DW      $1F2A,$1F41,$1F9D,$1F9D,$1F9D,$1F9D,$0000
FRENCH_PROMPT_TABLE_8:
                        DW      $1EFC,$1F58,$1F9D,$1F9D,$1F9D,$1F9D,$0000

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
