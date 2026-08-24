;===============================================================================
; Sea Wolf II (Dave Nutting Associates / Midway, 1978)
;
; ROM address space: $0000-$1FFF
; TERSE IP: BC      data stack: SP      return stack: IX
; Dispatcher: IY=$0043
;
;===============================================================================

PORT_VIDEO_MODE         EQU     $08
PORT_COLOR_SPLIT        EQU     $09
PORT_VBLANK_LINE        EQU     $0A
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
                        DB      $F3                     ; $00E8  DI
                        DB      $AF                     ; $00E9  XOR A
                        DB      $D3,$04                 ; $00EA  OUT ($04),A
                        DB      $D3,$0E                 ; $00EC  OUT ($0E),A
                        DB      $3E,$EA                 ; $00EE  LD A,$EA
                        DB      $D3,$09                 ; $00F0  OUT ($09),A
                        DB      $3E,$C8                 ; $00F2  LD A,$C8
                        DB      $D3,$0A                 ; $00F4  OUT ($0A),A
                        DB      $3E,$07                 ; $00F6  LD A,$07
                        DB      $D3,$07                 ; $00F8  OUT ($07),A
                        DB      $DB,$12                 ; $00FA  IN A,($12)
                        DB      $E6,$06                 ; $00FC  AND $06
                        DB      $C2,$69,$01             ; $00FE  JP NZ,$0169
                        DB      $21,$00,$40             ; $0101  LD HL,$4000
                        DB      $11,$00,$40             ; $0104  LD DE,$4000
                        DB      $36,$00                 ; $0107  LD (HL),$00
                        DB      $23                     ; $0109  INC HL
                        DB      $DB,$10                 ; $010A  IN A,($10)
                        DB      $1D                     ; $010C  DEC E
                        DB      $20,$F8                 ; $010D  JR NZ,$0107
                        DB      $15                     ; $010F  DEC D
                        DB      $20,$F5                 ; $0110  JR NZ,$0107
                        DB      $3E,$0C                 ; $0112  LD A,$0C
                        DB      $32,$02,$C2             ; $0114  LD ($C202),A
                        DB      $3E,$32                 ; $0117  LD A,$32
                        DB      $32,$FF,$C1             ; $0119  LD ($C1FF),A
                        DB      $32,$01,$C2             ; $011C  LD ($C201),A
                        DB      $01,$00,$08             ; $011F  LD BC,$0800
                        DB      $21,$00,$00             ; $0122  LD HL,$0000
                        DB      $AF                     ; $0125  XOR A
                        DB      $86                     ; $0126  ADD A, (HL)
                        DB      $57                     ; $0127  LD D,A
                        DB      $DB,$10                 ; $0128  IN A,($10)
                        DB      $7A                     ; $012A  LD A,D
                        DB      $23                     ; $012B  INC HL
                        DB      $0D                     ; $012C  DEC C
                        DB      $20,$F7                 ; $012D  JR NZ,$0126
                        DB      $10,$F5                 ; $012F  DJNZ $0126
                        DB      $7A                     ; $0131  LD A,D
                        DB      $FE,$FF                 ; $0132  CP $FF
                        DB      $20,$15                 ; $0134  JR NZ,$014B
                        DB      $01,$00,$08             ; $0136  LD BC,$0800
                        DB      $DB,$10                 ; $0139  IN A,($10)
                        DB      $7C                     ; $013B  LD A,H
                        DB      $FE,$20                 ; $013C  CP $20
                        DB      $20,$E5                 ; $013E  JR NZ,$0125
                        DB      $3A,$FF,$C1             ; $0140  LD A,($C1FF)
                        DB      $FE,$32                 ; $0143  CP $32
                        DB      $28,$27                 ; $0145  JR Z,$016E
                        DB      $DB,$10                 ; $0147  IN A,($10)
                        DB      $18,$FC                 ; $0149  JR $0147
                        DB      $7C                     ; $014B  LD A,H
                        DB      $E5                     ; $014C  PUSH HL
                        DB      $D5                     ; $014D  PUSH DE
                        DB      $C5                     ; $014E  PUSH BC
                        DB      $0F                     ; $014F  RRCA
                        DB      $0F                     ; $0150  RRCA
                        DB      $0F                     ; $0151  RRCA
                        DB      $E6,$07                 ; $0152  AND $07
                        DB      $C6,$40                 ; $0154  ADD A, $40
                        DB      $21,$00,$C0             ; $0156  LD HL,$C000
                        DB      $77                     ; $0159  LD (HL),A
                        DB      $23                     ; $015A  INC HL
                        DB      $36,$00                 ; $015B  LD (HL),$00
                        DB      $2B                     ; $015D  DEC HL
                        DB      $CD,$E4,$15             ; $015E  CALL $15E4
                        DB      $F3                     ; $0161  DI
                        DB      $DB,$10                 ; $0162  IN A,($10)
                        DB      $C1                     ; $0164  POP BC
                        DB      $D1                     ; $0165  POP DE
                        DB      $E1                     ; $0166  POP HL
                        DB      $18,$CD                 ; $0167  JR $0136
                        DB      $FE,$02                 ; $0169  CP $02
                        DB      $C2,$64,$02             ; $016B  JP NZ,$0264
                        DB      $F3                     ; $016E  DI
                        DB      $3E,$14                 ; $016F  LD A,$14
                        DB      $D3,$09                 ; $0171  OUT ($09),A
                        DB      $06,$08                 ; $0173  LD B,$08
                        DB      $21,$B0,$00             ; $0175  LD HL,$00B0
                        DB      $0E,$0B                 ; $0178  LD C,$0B
                        DB      $ED,$B3                 ; $017A  OTIR
                        DB      $FD,$21,$82,$01         ; $017C  LD IY,$0182
                        DB      $18,$1E                 ; $0180  JR $01A0

;-------------------------------------------------------------------------------
; $0182: Six-byte diagnostic parameter block
;-------------------------------------------------------------------------------
SELF_TEST_PARAMETER_SET_1:
                        DB      $18,$04,$3F,$80,$00,$40                                         ; $0182  ..?..

;-------------------------------------------------------------------------------
; $0188: Second diagnostic setup path
;-------------------------------------------------------------------------------
SELF_TEST_SECOND_PASS:
                        DB      $06,$08                 ; $0188  LD B,$08
                        DB      $21,$B8,$00             ; $018A  LD HL,$00B8
                        DB      $0E,$0B                 ; $018D  LD C,$0B
                        DB      $ED,$B3                 ; $018F  OTIR
                        DB      $FD,$21,$97,$01         ; $0191  LD IY,$0197
                        DB      $18,$09                 ; $0195  JR $01A0

;-------------------------------------------------------------------------------
; $0197: Six-byte diagnostic parameter block
;-------------------------------------------------------------------------------
SELF_TEST_PARAMETER_SET_2:
                        DB      $18,$04,$BF,$C4,$00,$C0                                         ; $0197  ......

;-------------------------------------------------------------------------------
; $019D: Return from diagnostic setup to warm start
;-------------------------------------------------------------------------------
SELF_TEST_RESTART:
                        DB      $C3,$16,$00             ; $019D  JP $0016

;-------------------------------------------------------------------------------
; $01A0: Video-memory verification loop
;-------------------------------------------------------------------------------
SELF_TEST_VIDEO_VERIFY:
                        DB      $0E,$00                 ; $01A0  LD C,$00
                        DB      $06,$01                 ; $01A2  LD B,$01
                        DB      $FD,$66,$05             ; $01A4  LD H,(IY+$05)
                        DB      $FD,$6E,$04             ; $01A7  LD L,(IY+$04)
                        DB      $70                     ; $01AA  LD (HL),B
                        DB      $7E                     ; $01AB  LD A,(HL)
                        DB      $A8                     ; $01AC  XOR B
                        DB      $28,$07                 ; $01AD  JR Z,$01B6
                        DB      $DD,$21,$B6,$01         ; $01AF  LD IX,$01B6
                        DB      $C3,$60,$02             ; $01B3  JP $0260
                        DB      $23                     ; $01B6  INC HL
                        DB      $7C                     ; $01B7  LD A,H
                        DB      $FD,$BE,$03             ; $01B8  CP (IY+$03)
                        DB      $DB,$10                 ; $01BB  IN A,($10)
                        DB      $20,$EB                 ; $01BD  JR NZ,$01AA
                        DB      $2B                     ; $01BF  DEC HL
                        DB      $DB,$10                 ; $01C0  IN A,($10)
                        DB      $7C                     ; $01C2  LD A,H
                        DB      $FD,$BE,$02             ; $01C3  CP (IY+$02)
                        DB      $28,$18                 ; $01C6  JR Z,$01E0
                        DB      $7E                     ; $01C8  LD A,(HL)
                        DB      $A8                     ; $01C9  XOR B
                        DB      $28,$07                 ; $01CA  JR Z,$01D3
                        DB      $DD,$21,$D3,$01         ; $01CC  LD IX,$01D3
                        DB      $C3,$60,$02             ; $01D0  JP $0260
                        DB      $78                     ; $01D3  LD A,B
                        DB      $2F                     ; $01D4  CPL
                        DB      $77                     ; $01D5  LD (HL),A
                        DB      $AE                     ; $01D6  XOR (HL)
                        DB      $28,$E6                 ; $01D7  JR Z,$01BF
                        DB      $DD,$21,$BF,$01         ; $01D9  LD IX,$01BF
                        DB      $C3,$60,$02             ; $01DD  JP $0260
                        DB      $23                     ; $01E0  INC HL
                        DB      $DB,$10                 ; $01E1  IN A,($10)
                        DB      $7C                     ; $01E3  LD A,H
                        DB      $FD,$BE,$03             ; $01E4  CP (IY+$03)
                        DB      $28,$0F                 ; $01E7  JR Z,$01F8
                        DB      $78                     ; $01E9  LD A,B
                        DB      $2F                     ; $01EA  CPL
                        DB      $AE                     ; $01EB  XOR (HL)
                        DB      $28,$06                 ; $01EC  JR Z,$01F4
                        DB      $DD,$21,$F4,$01         ; $01EE  LD IX,$01F4
                        DB      $18,$6C                 ; $01F2  JR $0260
                        DB      $AF                     ; $01F4  XOR A
                        DB      $77                     ; $01F5  LD (HL),A
                        DB      $18,$E8                 ; $01F6  JR $01E0
                        DB      $CB,$20                 ; $01F8  SLA B
                        DB      $30,$A8                 ; $01FA  JR NC,$01A4
                        DB      $79                     ; $01FC  LD A,C
                        DB      $A7                     ; $01FD  AND A
                        DB      $20,$02                 ; $01FE  JR NZ,$0202
                        DB      $FD,$E9                 ; $0200  JP (IY)
                        DB      $D9                     ; $0202  EXX
                        DB      $DB,$10                 ; $0203  IN A,($10)
                        DB      $11,$00,$40             ; $0205  LD DE,$4000
                        DB      $21,$C0,$00             ; $0208  LD HL,$00C0
                        DB      $01,$28,$00             ; $020B  LD BC,$0028
                        DB      $ED,$B0                 ; $020E  LDIR
                        DB      $01,$28,$00             ; $0210  LD BC,$0028
                        DB      $21,$C0,$00             ; $0213  LD HL,$00C0
                        DB      $ED,$B0                 ; $0216  LDIR
                        DB      $21,$00,$40             ; $0218  LD HL,$4000
                        DB      $01,$B0,$40             ; $021B  LD BC,$40B0
                        DB      $7E                     ; $021E  LD A,(HL)
                        DB      $12                     ; $021F  LD (DE),A
                        DB      $DB,$10                 ; $0220  IN A,($10)
                        DB      $23                     ; $0222  INC HL
                        DB      $13                     ; $0223  INC DE
                        DB      $0D                     ; $0224  DEC C
                        DB      $20,$F7                 ; $0225  JR NZ,$021E
                        DB      $10,$F5                 ; $0227  DJNZ $021E
                        DB      $D9                     ; $0229  EXX
                        DB      $3E,$47                 ; $022A  LD A,$47
                        DB      $CB,$41                 ; $022C  BIT 0,C
                        DB      $28,$02                 ; $022E  JR Z,$0232
                        DB      $D3,$03                 ; $0230  OUT ($03),A
                        DB      $CB,$49                 ; $0232  BIT 1,C
                        DB      $28,$02                 ; $0234  JR Z,$0238
                        DB      $D3,$02                 ; $0236  OUT ($02),A
                        DB      $CB,$51                 ; $0238  BIT 2,C
                        DB      $28,$02                 ; $023A  JR Z,$023E
                        DB      $D3,$01                 ; $023C  OUT ($01),A
                        DB      $CB,$59                 ; $023E  BIT 3,C
                        DB      $28,$02                 ; $0240  JR Z,$0244
                        DB      $D3,$00                 ; $0242  OUT ($00),A
                        DB      $CB,$61                 ; $0244  BIT 4,C
                        DB      $28,$02                 ; $0246  JR Z,$024A
                        DB      $D3,$07                 ; $0248  OUT ($07),A
                        DB      $CB,$69                 ; $024A  BIT 5,C
                        DB      $28,$02                 ; $024C  JR Z,$0250
                        DB      $D3,$06                 ; $024E  OUT ($06),A
                        DB      $CB,$71                 ; $0250  BIT 6,C
                        DB      $28,$02                 ; $0252  JR Z,$0256
                        DB      $D3,$05                 ; $0254  OUT ($05),A
                        DB      $CB,$79                 ; $0256  BIT 7,C
                        DB      $28,$02                 ; $0258  JR Z,$025C
                        DB      $D3,$04                 ; $025A  OUT ($04),A
                        DB      $DB,$10                 ; $025C  IN A,($10)
                        DB      $18,$FC                 ; $025E  JR $025C
                        DB      $B1                     ; $0260  OR C
                        DB      $4F                     ; $0261  LD C,A
                        DB      $DD,$E9                 ; $0262  JP (IX)

;-------------------------------------------------------------------------------
; $0264: Select reset-button diagnostic path
;-------------------------------------------------------------------------------
SELF_TEST_MODE_SELECT:
                        DB      $FE,$04                 ; $0264  CP $04
                        DB      $C2,$BE,$02             ; $0266  JP NZ,$02BE
                        DB      $31,$E2,$C3             ; $0269  LD SP,$C3E2
                        DB      $DD,$21,$00,$C4         ; $026C  LD IX,$C400
                        DB      $FD,$21,$77,$02         ; $0270  LD IY,$0277
                        DB      $C3,$97,$03             ; $0274  JP $0397

;-------------------------------------------------------------------------------
; $0277: Interactive service-test loop
;-------------------------------------------------------------------------------
SELF_TEST_INTERACTIVE:
                        DB      $3E,$0C                 ; $0277  LD A,$0C
                        DB      $32,$02,$C2             ; $0279  LD ($C202),A
                        DB      $3E,$78                 ; $027C  LD A,$78
                        DB      $32,$01,$C2             ; $027E  LD ($C201),A
                        DB      $DB,$10                 ; $0281  IN A,($10)
                        DB      $AF                     ; $0283  XOR A
                        DB      $32,$FF,$C1             ; $0284  LD ($C1FF),A
                        DB      $DB,$10                 ; $0287  IN A,($10)
                        DB      $DB,$10                 ; $0289  IN A,($10)
                        DB      $CD,$9C,$02             ; $028B  CALL $029C
                        DB      $3E,$78                 ; $028E  LD A,$78
                        DB      $32,$FF,$C1             ; $0290  LD ($C1FF),A
                        DB      $DB,$10                 ; $0293  IN A,($10)
                        DB      $DB,$11                 ; $0295  IN A,($11)
                        DB      $CD,$9C,$02             ; $0297  CALL $029C
                        DB      $18,$E5                 ; $029A  JR $0281
                        DB      $CD,$AC,$0A             ; $029C  CALL $0AAC
                        DB      $21,$00,$C0             ; $029F  LD HL,$C000
                        DB      $E6,$7F                 ; $02A2  AND $7F
                        DB      $07                     ; $02A4  RLCA
                        DB      $06,$06                 ; $02A5  LD B,$06
                        DB      $17                     ; $02A7  RLA
                        DB      $4F                     ; $02A8  LD C,A
                        DB      $3E,$00                 ; $02A9  LD A,$00
                        DB      $CE,$30                 ; $02AB  ADC A, $30
                        DB      $77                     ; $02AD  LD (HL),A
                        DB      $23                     ; $02AE  INC HL
                        DB      $79                     ; $02AF  LD A,C
                        DB      $10,$F5                 ; $02B0  DJNZ $02A7
                        DB      $36,$00                 ; $02B2  LD (HL),$00
                        DB      $21,$00,$C0             ; $02B4  LD HL,$C000
                        DB      $DB,$10                 ; $02B7  IN A,($10)
                        DB      $CD,$E4,$15             ; $02B9  CALL $15E4
                        DB      $F3                     ; $02BC  DI
                        DB      $C9                     ; $02BD  RET

;-------------------------------------------------------------------------------
; $02BE: Convergence/grid display test
;-------------------------------------------------------------------------------
CONVERGENCE_TEST:
                        DB      $21,$00,$40             ; $02BE  LD HL,$4000
                        DB      $06,$28                 ; $02C1  LD B,$28
                        DB      $36,$00                 ; $02C3  LD (HL),$00
                        DB      $DB,$10                 ; $02C5  IN A,($10)
                        DB      $23                     ; $02C7  INC HL
                        DB      $36,$03                 ; $02C8  LD (HL),$03
                        DB      $23                     ; $02CA  INC HL
                        DB      $10,$F6                 ; $02CB  DJNZ $02C3
                        DB      $01,$30,$03             ; $02CD  LD BC,$0330
                        DB      $36,$00                 ; $02D0  LD (HL),$00
                        DB      $DB,$10                 ; $02D2  IN A,($10)
                        DB      $23                     ; $02D4  INC HL
                        DB      $0D                     ; $02D5  DEC C
                        DB      $20,$F8                 ; $02D6  JR NZ,$02D0
                        DB      $10,$F6                 ; $02D8  DJNZ $02D0
                        DB      $EB                     ; $02DA  EX DE,HL
                        DB      $21,$00,$40             ; $02DB  LD HL,$4000
                        DB      $01,$A0,$3D             ; $02DE  LD BC,$3DA0
                        DB      $7E                     ; $02E1  LD A,(HL)
                        DB      $12                     ; $02E2  LD (DE),A
                        DB      $DB,$10                 ; $02E3  IN A,($10)
                        DB      $13                     ; $02E5  INC DE
                        DB      $23                     ; $02E6  INC HL
                        DB      $0D                     ; $02E7  DEC C
                        DB      $20,$F7                 ; $02E8  JR NZ,$02E1
                        DB      $10,$F5                 ; $02EA  DJNZ $02E1
                        DB      $DB,$10                 ; $02EC  IN A,($10)
                        DB      $18,$FC                 ; $02EE  JR $02EC

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
                        DB      $21,$55,$03             ; $032B  LD HL,$0355
                        DB      $11,$12,$C2             ; $032E  LD DE,$C212
                        DB      $ED,$B0                 ; $0331  LDIR
                        DB      $DB,$13                 ; $0333  IN A,($13)
                        DB      $E6,$40                 ; $0335  AND $40
                        DB      $21,$16,$1A             ; $0337  LD HL,$1A16
                        DB      $28,$03                 ; $033A  JR Z,$033F
                        DB      $21,$D8,$19             ; $033C  LD HL,$19D8
                        DB      $22,$FC,$C1             ; $033F  LD ($C1FC),HL
                        DB      $22,$0D,$C2             ; $0342  LD ($C20D),HL
                        DB      $3E,$2A                 ; $0345  LD A,$2A
                        DB      $D3,$09                 ; $0347  OUT ($09),A
                        DB      $CD,$48,$14             ; $0349  CALL $1448
                        DB      $C1                     ; $034C  POP BC
                        DB      $21,$C8,$0D             ; $034D  LD HL,$0DC8
                        DB      $22,$0B,$C2             ; $0350  LD ($C20B),HL
                        DB      $FD,$E9                 ; $0353  JP (IY)

;-------------------------------------------------------------------------------
; $0355: Sixteen bytes copied to RAM at $C212
;-------------------------------------------------------------------------------
INITIAL_RAM_TEMPLATE:
                        DB      $04,$04,$00,$00,$18,$08,$00,$00,$2C,$10,$00,$00,$40,$20,$00,$00 ; $0355  ........,...  ..

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
                        DB      $21,$00,$C0             ; $0397  LD HL,$C000
                        DB      $AF                     ; $039A  XOR A
                        DB      $C5                     ; $039B  PUSH BC
                        DB      $01,$C2,$02             ; $039C  LD BC,$02C2
                        DB      $77                     ; $039F  LD (HL),A
                        DB      $23                     ; $03A0  INC HL
                        DB      $0D                     ; $03A1  DEC C
                        DB      $20,$FB                 ; $03A2  JR NZ,$039F
                        DB      $10,$F9                 ; $03A4  DJNZ $039F
                        DB      $21,$CB,$C1             ; $03A6  LD HL,$C1CB
                        DB      $06,$2D                 ; $03A9  LD B,$2D
                        DB      $77                     ; $03AB  LD (HL),A
                        DB      $23                     ; $03AC  INC HL
                        DB      $10,$FC                 ; $03AD  DJNZ $03AB
                        DB      $DB,$13                 ; $03AF  IN A,($13)
                        DB      $E6,$06                 ; $03B1  AND $06
                        DB      $0F                     ; $03B3  RRCA
                        DB      $47                     ; $03B4  LD B,A
                        DB      $3A,$FB,$C1             ; $03B5  LD A,($C1FB)
                        DB      $FE,$02                 ; $03B8  CP $02
                        DB      $0E,$15                 ; $03BA  LD C,$15
                        DB      $16,$91                 ; $03BC  LD D,$91
                        DB      $28,$04                 ; $03BE  JR Z,$03C4
                        DB      $16,$71                 ; $03C0  LD D,$71
                        DB      $0E,$10                 ; $03C2  LD C,$10
                        DB      $78                     ; $03C4  LD A,B
                        DB      $B7                     ; $03C5  OR A
                        DB      $28,$07                 ; $03C6  JR Z,$03CF
                        DB      $7A                     ; $03C8  LD A,D
                        DB      $91                     ; $03C9  SUB C
                        DB      $27                     ; $03CA  DAA
                        DB      $10,$FC                 ; $03CB  DJNZ $03C9
                        DB      $18,$01                 ; $03CD  JR $03D0
                        DB      $7A                     ; $03CF  LD A,D
                        DB      $32,$DB,$C1             ; $03D0  LD ($C1DB),A
                        DB      $11,$F0,$38             ; $03D3  LD DE,$38F0
                        DB      $21,$00,$40             ; $03D6  LD HL,$4000
                        DB      $36,$00                 ; $03D9  LD (HL),$00
                        DB      $DB,$10                 ; $03DB  IN A,($10)
                        DB      $23                     ; $03DD  INC HL
                        DB      $1D                     ; $03DE  DEC E
                        DB      $20,$F8                 ; $03DF  JR NZ,$03D9
                        DB      $15                     ; $03E1  DEC D
                        DB      $20,$F5                 ; $03E2  JR NZ,$03D9
                        DB      $3A,$FB,$C1             ; $03E4  LD A,($C1FB)
                        DB      $FE,$02                 ; $03E7  CP $02
                        DB      $28,$05                 ; $03E9  JR Z,$03F0
                        DB      $3E,$FF                 ; $03EB  LD A,$FF
                        DB      $32,$E4,$C1             ; $03ED  LD ($C1E4),A
                        DB      $CD,$82,$16             ; $03F0  CALL $1682
                        DB      $C1                     ; $03F3  POP BC
                        DB      $FD,$E9                 ; $03F4  JP (IY)

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
                        DW      $0AF4,PROCESS_SHIP_HIT,$0711,UPDATE_SONAR_SEQUENCE
                        DW      TERSE_INLINE_BFETCH,$C1DF
                        DW      TERSE_BYTE_NOT
                        DW      TERSE_ZERO_BRANCH,control_continue
                        DW      $07C4,$08A7,POLL_TORPEDO_FIRE
                        DW      TERSE_BRANCH,control_continue
control_no_player:      DW      $0BDF,$0C1A
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
                        DB      $21,$00,$C0,$C5,$FD,$E5,$CB,$6E,$CA,$A6,$06,$CB,$AE,$CB,$5E,$11 ; $0613  !......n......^.
                        DB      $E7,$C1,$3A,$F1,$C1,$0E,$43,$28,$08,$11,$E2,$C1,$3A,$EE,$C1,$0E ; $0623  ..:...C(....:...
                        DB      $42,$23,$F6,$20,$ED,$79,$7E,$2B,$E5,$FD,$E1,$EB,$06,$03,$FE,$03 ; $0633  B#. .y~+........
                        DB      $38,$0E,$06,$01,$FE,$05,$38,$08,$06,$05,$FE,$07,$38,$02,$06,$10 ; $0643  8.....8.....8...
                        DB      $7E,$80,$27,$77,$23,$7E,$CE,$00,$27,$77,$23,$36,$00,$23,$34,$23 ; $0653  ~.'w#~..'w#6.#4#
                        DB      $7E,$80,$27,$77,$FD,$7E,$17,$32,$02,$C2,$D5,$C5,$CD,$B5,$06,$C1 ; $0663  ~.'w.~.2........
                        DB      $FD,$CB,$00,$D6,$FD,$7E,$0F,$32,$FF,$C1,$FD,$7E,$08,$D6,$1A,$32 ; $0673  .....~.2...~...2
                        DB      $01,$C2,$21,$00,$00,$E5,$21,$30,$30,$E5,$78,$CD,$F0,$0C,$21,$00 ; $0683  ..!...!00.x...!.
                        DB      $00,$39,$7E,$FE,$30,$20,$02,$36,$40,$CD,$E4,$15,$33,$33,$33,$33 ; $0693  .9~.0 .6 ...3333
                        DB      $33,$33,$E1,$11,$19,$00,$19,$7D,$FE,$64,$C2,$19,$06,$FD,$E1,$C1 ; $06A3  33.....}.d......
                        DB      $FD,$E9,$56,$2B,$7E,$FE,$04,$C0,$36,$00,$23,$36,$00,$2B,$2B,$2B ; $06B3  ..V+~...6.#6.+++
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
                        DB      $3E,$FF,$32,$DF,$C1,$C5,$0E,$42,$11,$CB,$C1,$21,$ED,$C1,$3A,$FB ; $07F7  >.2....B...!..:.
                        DB      $C1,$FE,$02,$CC,$18,$08,$0C,$13,$21,$F0,$C1,$CD,$18,$08,$C1,$FD ; $0807  ........!.......
                        DB      $E9,$7E,$B7,$C0,$1A,$B7,$C0,$36,$04,$3E,$1F,$ED,$79,$FD,$E5,$D9 ; $0817  .~.....6.>..y...
                        DB      $3A,$E2,$C1,$57,$3A,$E7,$C1,$BA,$30,$01,$7A,$FE,$10,$38,$14,$FE ; $0827  :..W:...0.z..8..
                        DB      $20,$38,$08,$21,$C8,$C0,$16,$82,$CD,$56,$08,$21,$96,$C0,$16,$64 ; $0837   8.!.....V.!...d
                        DB      $CD,$56,$08,$21,$64,$C0,$16,$4C,$CD,$56,$08,$D9,$FD,$E1,$C9,$CB ; $0847  .V.!d..L.V......
                        DB      $7E,$20,$0E,$E5,$FD,$E1,$CD,$9F,$08,$FD,$7E,$28,$C6,$1E,$C3,$78 ; $0857  ~ ........~(...x
                        DB      $08,$01,$19,$00,$09,$CB,$7E,$C0,$E5,$FD,$E1,$CD,$9F,$08,$FD,$7E ; $0867  ......~........~
                        DB      $F6,$C6,$50,$FE,$A0,$38,$02,$D6,$A0,$FD,$77,$0F,$FD,$72,$08,$FD ; $0877  ..P..8....w..r..
                        DB      $36,$01,$06,$FD,$36,$0C,$80,$FD,$36,$11,$A0,$FD,$36,$14,$08,$FD ; $0887  6...6...6...6...
                        DB      $36,$17,$0C,$FD,$36,$00,$80,$C9,$06,$19,$AF,$77,$23,$10,$FC,$C9 ; $0897  6...6......w#...
                        DB      $FD,$E5,$D9,$21,$00,$C0,$CD,$BB,$08,$21,$32,$C0,$CD,$BB,$08,$FD ; $08A7  ...!.....!2.....
                        DB      $E1,$D9,$FD,$E9,$E5,$FD,$E1,$FD,$CB,$19,$7E,$C0,$CB,$7E,$20,$05 ; $08B7  ..........~..~ .
                        DB      $ED,$5F,$0F,$18,$1C,$FD,$7E,$0D,$17,$FD,$7E,$0F,$38,$06,$FE,$80 ; $08C7  ._....~...~.8...
                        DB      $D8,$B7,$18,$04,$FE,$20,$D0,$37,$F5,$11,$19,$00,$19,$E5,$FD,$E1 ; $08D7  ..... .7........
                        DB      $F1,$F5,$CD,$9F,$08,$ED,$5F,$1F,$3E,$04,$38,$02,$3E,$08,$FD,$77 ; $08E7  ......_.>.8.>..w
                        DB      $17,$7D,$FE,$33,$3E,$1A,$38,$02,$3E,$33,$FD,$77,$08,$2A,$0B,$C2 ; $08F7  .}.3>.8.>3.w.*..
                        DB      $46,$23,$7E,$FE,$FF,$20,$03,$21,$C8,$0D,$22,$0B,$C2,$78,$FE,$03 ; $0907  F#~.. .!.."..x..
                        DB      $20,$19,$3A,$DB,$C1,$FE,$24,$3E,$03,$30,$10,$3A,$F7,$C1,$FE,$02 ; $0917   .:...$>.0.:....
                        DB      $28,$09,$3C,$32,$F7,$C1,$CD,$02,$0D,$3E,$08,$FD,$77,$01,$FD,$36 ; $0927  (.<2.....>..w..6
                        DB      $14,$08,$21,$D2,$0D,$5F,$16,$00,$19,$7E,$1E,$00,$CB,$27,$CB,$13 ; $0937  ..!.._...~...'..
                        DB      $CB,$27,$CB,$13,$FD,$77,$0C,$FD,$73,$0D,$FD,$7E,$01,$FE,$05,$3E ; $0947  .'...w..s..~...>
                        DB      $8E,$20,$02,$3E,$9A,$FD,$77,$11,$F1,$30,$28,$FD,$36,$11,$A0,$FD ; $0957  . .>..w..0(.6...
                        DB      $CB,$14,$F6,$FD,$46,$0D,$FD,$7E,$0C,$2F,$4F,$78,$2F,$47,$03,$FD ; $0967  ....F..~./Ox/G..
                        DB      $71,$0C,$FD,$70,$0D,$FD,$7E,$01,$FE,$05,$3E,$96,$28,$02,$3E,$8C ; $0977  q..p..~...>.(.>.
                        LD      (IY+$0F),A
                        LD      A,(IY+$01)
                        CP      $05
                        JR      C,target_sound_done
                        CP      $08
                        JR      NZ,START_SONAR_SEQUENCE

; Target type $08 begins the dive effect.  $F0 supplies both the descending
; three-bit pan code and the first port-$41 bit-3 trigger edge.
START_DIVE_SOUND:
                        LD      A,$F0
                        LD      (SOUND_DIVE_PAN_TIMER),A
                        BIT     6,(IY+$14)
                        LD      A,$87
                        JR      Z,dive_pan_selected
                        LD      A,$80
dive_pan_selected:      LD      (SOUND_DIVE_PAN_XOR),A
                        LD      (IY+$17),$0C
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
target_sound_done:      LD      (IY+$00),$80
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
                        LD      IY,$C0FA
                        CALL    UPDATE_PLAYER_TORPEDO_FIRE
poll_right_torpedo:     LD      C,PORT_P1_HANDLE
                        LD      DE,$C1CC
                        LD      HL,$C1F0
                        LD      IY,$C113
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
                        LD      DE,$0032
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
                        LD      HL,$0D48
                        BIT     0,C
                        JR      Z,torpedo_trajectory_table
                        LD      HL,$0D88
torpedo_trajectory_table:
                        LD      E,A
                        LD      D,$00
                        ADD     HL,DE
                        LD      A,(HL)
                        LD      (IY+$0F),A
                        INC     HL
                        LD      A,(HL)
                        LD      (IY+$0C),A
                        RLCA
                        JR      NC,torpedo_velocity_ready
                        LD      (IY+$0D),$FF
torpedo_velocity_ready: LD      (IY+$00),$80

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
                        CALL    $089F
                        LD      (IY+$01),$07
                        LD      (IY+$03),$0C
                        LD      (IY+$06),$FC
                        LD      (IY+$08),$BB
                        LD      (IY+$09),$23
                        LD      (IY+$11),$9C
                        LD      (IY+$14),$08
                        LD      (IY+$13),$11
                        LD      (IY+$12),$2D
                        LD      A,$08
                        BIT     0,C
                        JR      Z,torpedo_color_selected
                        LD      A,$04
torpedo_color_selected: LD      (IY+$17),A
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
                        DB      $C5,$FD,$E5             ; $0AF4
                        DB      $FD,$21,$00,$C0,$11,$19,$00,$06,$04,$FD,$CB,$00,$56,$28,$42,$FD ; $0AF7  .!..........V(B.
                        DB      $7E,$01,$FE,$08,$3E,$04,$28,$02,$3E,$02,$FD,$BE,$18,$30,$32,$FD ; $0B07  ~...>.(.>....02.
                        DB      $CB,$00,$96,$C5,$D5,$FD,$7E,$0F,$32,$FF,$C1,$FD,$7E,$08,$D6,$1A ; $0B17  ......~.2...~...
                        DB      $32,$01,$C2,$AF,$32,$02,$C2,$21,$6B,$13,$CD,$E4,$15,$FD,$CB,$00 ; $0B27  2...2..!k.......
                        DB      $5E,$3A,$F1,$C1,$0E,$43,$28,$05,$3A,$EE,$C1,$0E,$42,$ED,$79,$D1 ; $0B37  ^:...C(.:...B.y.
                        DB      $C1,$FD,$19,$10,$B4,$21,$F2,$C1,$11,$CE,$C1,$01,$1C,$6F,$CD,$C4 ; $0B47  .....!.......o..
                        DB      $0B,$21,$F4,$C1,$11,$CF,$C1,$01,$E0,$6E,$CD,$C4,$0B,$3E,$96,$32 ; $0B57  .!.......n...>.2
                        DB      $01,$C2,$3E,$00,$32,$FF,$C1,$3E,$08,$32,$02,$C2,$21,$53,$1B,$3A ; $0B67  ..>.2..>.2..!S.:
                        DB      $F4,$C1,$B7,$C4,$D7,$15,$3E,$78,$32,$FF,$C1,$3E,$04,$32,$02,$C2 ; $0B77  ......>x2..>.2..
                        DB      $21,$53,$1B,$3A,$F2,$C1,$B7,$C4,$D7,$15,$3E,$AB,$32,$01,$C2,$3E ; $0B87  !S.:......>.2..>
                        DB      $82,$32,$FF,$C1,$3A,$F3,$C1,$4F,$06,$00,$3A,$F2,$C1,$B7,$C4,$AE ; $0B97  .2..:..O..:.....
                        DB      $0C,$3E,$08,$32,$02,$C2,$3E,$07,$32,$FF,$C1,$3A,$F5,$C1,$4F,$06 ; $0BA7  .>.2..>.2..:..O.
                        DB      $00,$3A,$F4,$C1,$B7,$C4,$AE,$0C,$FD,$E1,$C1,$FD,$E9,$7E,$B7,$C8 ; $0BB7  .:...........~..
                        DB      $1A,$B7,$C0,$36,$00,$60,$69,$11,$3C,$00,$AF,$0E,$20,$06,$14,$77 ; $0BC7  ...6.`i.<... ..w
                        DB      $23,$10,$FC,$19,$0D,$20,$F6,$C9,$3A,$00,$C0,$CB,$7F,$20,$32,$3A ; $0BD7  #.... ..:.... 2:
                        DB      $32,$C0,$CB,$7F,$20,$2B,$C5,$21,$DB,$0D,$11,$00,$C0,$01,$19,$00 ; $0BE7  2... +.!........
                        DB      $C5,$ED,$B0,$C1,$EB,$09,$EB,$C5,$ED,$B0,$C1,$11,$FA,$C0,$CB,$21 ; $0BF7  ...............!
                        DB      $ED,$B0,$3E,$80,$32,$00,$C0,$32,$32,$C0,$32,$FA,$C0,$32,$13,$C1 ; $0C07  ..>.2..22.2..2..
                        DB      $C1,$FD,$E9,$C5,$3A,$F8,$C1,$B7,$28,$32,$21,$CC,$C1,$7E,$B7,$20 ; $0C17  ....:...(2!..~.
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
                        DB      $C9,$90,$70,$8A,$6D,$85,$6A,$7F,$67,$7A,$64,$75,$61,$6F,$5E,$6A ; $0D47  ..p.m.j.gzduao^j
                        DB      $5B,$65,$58,$61,$55,$5C,$52,$57,$4F,$52,$4C,$4E,$49,$49,$46,$44 ; $0D57  [eXaU\RWORLNIIFD
                        DB      $43,$40,$40,$3B,$3D,$37,$3A,$33,$37,$2E,$34,$2A,$31,$26,$2E,$21 ; $0D67  C  ;=7:37.4*1&.!
                        DB      $2B,$1D,$28,$19,$25,$15,$22,$10,$1F,$0D,$1C,$08,$19,$04,$16,$00 ; $0D77  +.(.%.".........
                        DB      $13,$9B,$00,$96,$FD,$92,$FA,$8E,$F7,$8A,$F4,$86,$F1,$81,$EE,$7D ; $0D87  ...............}
                        DB      $EB,$79,$E8,$75,$E5,$70,$E2,$6C,$DF,$68,$DC,$63,$D9,$5F,$D6,$5A ; $0D97  .y.u.p.l.h.c._.Z
                        DB      $D3,$56,$D0,$51,$CD,$4D,$CD,$48,$CA,$43,$C7,$3E,$C4,$3A,$C1,$35 ; $0DA7  .V.Q.M.H.C.>.:.5
                        DB      $BE,$30,$BB,$2B,$B8,$25,$B5,$20,$B2,$1B,$AF,$16,$AC,$10,$A9,$0A ; $0DB7  .0.+.%. ........
                        DB      $A6,$03,$00,$05,$04,$01,$03,$02,$04,$05,$FF,$40,$40,$40,$20,$20 ; $0DC7  ...........
                        DB      $80,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,$00,$1A,$00,$00,$00 ; $0DD7  ... ............
                        DB      $80,$00,$00,$00,$00,$8C,$00,$00,$08,$00,$00,$04,$00,$00,$08,$00 ; $0DE7  ................
                        DB      $00,$00,$00,$00,$00,$33,$00,$00,$00,$80,$FF,$00,$8C,$00,$9F,$00 ; $0DF7  .....3..........
                        DB      $00,$48,$00,$00,$0C,$00,$00,$07,$00,$06,$00,$00,$FD,$00,$BE,$23 ; $0E07  .H.............#
                        DB      $00,$00,$00,$00,$00,$20,$00,$9F,$2D,$11,$08,$00,$00,$08,$00,$00 ; $0E17  ..... ..-.......
                        DB      $07,$00,$06,$00,$00,$FD,$00,$BE,$23,$00,$00,$00,$00,$00,$78,$00 ; $0E27  ........#.....x.
                        DB      $9F,$2D,$11,$08,$00,$00,$04,$00,$05,$0C,$00,$00,$20,$00,$00,$00 ; $0E37  .-.......... ...
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
                        DB      $53,$55,$42,$00,$8E,$08,$E3,$E3,$00,$00,$00,$00,$00,$00,$00,$00 ; $1381  SUB.............
                        DB      $00,$00,$00,$00                                                 ; $1391  ....

;-------------------------------------------------------------------------------
; $1395: Frame interrupt entry and hardware update loop
;-------------------------------------------------------------------------------
VIDEO_INTERRUPT_HANDLER:
                        OUT     ($04),A
                        EX      AF,AF'
                        PUSH    AF
                        PUSH    BC
                        PUSH    DE
                        PUSH    HL
                        PUSH    IX
                        PUSH    IY
                        CALL    $1766
                        EI
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
                        CALL    $1717
                        CALL    $1717
                        CALL    $1733
                        CALL    $1733
                        CALL    $1733
                        CALL    $1733
                        CALL    $174A
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
                        DB      $08,$E3,$E3,$00,$00,$00 ; $1448
                        DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$D3,$04,$08,$F5,$E5,$CD,$66 ; $144E  ...............f
                        DB      $17,$E1,$F1,$FB,$C9,$DD,$CB,$00,$76,$C2,$DA,$17,$CD,$71,$19,$DD ; $145E  ........v....q..
                        DB      $CB,$00,$66,$20,$26,$DD,$7E,$01,$FE,$08,$20,$18,$DD,$34,$02,$DD ; $146E  ..f &.~... ..4..
                        DB      $7E,$02,$FE,$2A,$38,$0E,$DD,$36,$02,$00,$DD,$7E,$18,$FE,$02,$30 ; $147E  ~..*8..6...~...0
                        DB      $03,$DD,$34,$18,$CD,$33,$18,$CD,$56,$18,$C9,$CD,$0A,$18,$DD,$CB ; $148E  ..4..3..V.......
                        DB      $00,$BE,$C9,$DD,$E5,$E1,$CB,$45,$21,$EA,$C1,$20,$03,$21,$E5,$C1 ; $149E  .......E!.. .!..
                        DB      $36,$00,$23,$36,$00,$C9,$21,$2D,$11,$DD,$74,$13,$DD,$75,$12,$DD ; $14AE  6.#6..!-..t..u..
                        DB      $66,$16,$DD,$6E,$15,$E5,$CD,$71,$19,$DD,$CB,$00,$66,$F5,$C4,$A1 ; $14BE  f..n...q....f...
                        DB      $14,$F1,$F5,$CC,$3C,$19,$F1,$E1,$20,$C1,$7C,$B5,$CA,$92,$15,$11 ; $14CE  ....<... .|.....
                        DB      $60,$3F,$19,$7E,$23,$B6,$11,$4F,$00,$19,$B6,$23,$B6,$11,$EF,$00 ; $14DE  `?.~#..O...#....
                        DB      $47,$19,$B6,$11,$50,$00,$19,$B6,$19,$B6,$E6,$C0,$B0,$CA,$92,$15 ; $14EE  G...P...........
                        DB      $CD,$0A,$18,$DD,$7E,$08,$06,$05,$21,$D5,$1A,$BE,$30,$05,$23,$23 ; $14FE  ....~...!...0.##
                        DB      $23,$10,$F8,$48,$23,$5E,$23,$56,$D5,$FD,$E1,$06,$02,$FD,$CB,$00 ; $150E  #..H#^#V........
                        DB      $7E,$28,$69,$DD,$7E,$0F,$C6,$04,$FD,$96,$0F,$38,$5F,$FD,$66,$13 ; $151E  ~(i.~......8_.f.
                        DB      $FD,$6E,$12,$56,$14,$CB,$22,$CB,$22,$BA,$30,$50,$FD,$CB,$00,$76 ; $152E  .n.V..".".0P...v
                        DB      $20,$4A,$AF,$FD,$77,$02,$FD,$CB,$00,$F6,$FD,$CB,$00,$EE ; $153E

; The collision resolver reaches this producer after a torpedo overlaps a
; target.  IX record parity selects the cabinet side; the target class in C
; selects ship-hit or mine-hit.  D becomes the matching two-bit side mask.
SELECT_COLLISION_SOUND_SIDE:
                        PUSH    IX
                        POP     HL
                        LD      D,$30                  ; right ship/mine bits 4/5
                        RES     3,(IY+$00)
                        BIT     0,L
                        JR      NZ,collision_side_selected
                        SET     3,(IY+$00)
                        LD      D,$06                  ; left ship/mine bits 1/2
collision_side_selected:
                        LD      B,(IX+$17)
                        RES     7,(IX+$00)

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
                        CALL    C,$14A1
                        POP     AF
                        JR      C,hit_sound_class_selected
select_ship_hit_sound:
                        LD      A,$12
                        LD      C,$40
                        LD      (IY+$17),B
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
                        LD      DE,$0019
                        ADD     IY,DE
                        DJNZ    $151B
                        RET
                        DB      $DD,$7E,$08,$06,$00,$21,$E4,$1A,$BE,$30,$04,$23 ; $1592
                        DB      $04,$18,$F9,$DD,$70,$18,$CD,$33,$18,$CD,$FA,$18,$C9,$DD,$CB,$00 ; $159E  ....p..3........
                        DB      $76,$28,$07,$DD,$36,$02,$00,$C3,$DA,$17,$CD,$71,$19,$DD,$CB,$00 ; $15AE  v(..6......q....
                        DB      $66,$28,$0F,$DD,$CB,$00,$A6,$DD,$36,$0F,$00,$DD,$36,$0E,$00,$CD ; $15BE  f(......6...6...
                        DB      $71,$19,$CD,$33,$18,$CD,$56,$18,$C9,$3E,$01,$32,$DD,$C1,$CD,$E4 ; $15CE  q..3..V..>.2....
                        DB      $15,$AF,$32,$DD,$C1,$C9                                         ; $15DE  ..2...

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
                        DB      $E1,$01,$50,$00,$09,$C9,$7C,$B5,$28,$09,$E5,$B7,$ED,$52,$7C,$B5 ; $16EF  ..P...|.(....R|.
                        DB      $E1,$20,$04,$60,$69,$18,$04,$11,$19,$00,$19,$E5,$DD,$E1,$C9,$DD ; $16FF  . .`i...........
                        DB      $7E,$02,$B7,$C8,$DD,$35,$02,$C9,$2A,$C2,$C1,$01,$00,$C0,$11,$4B ; $170F  ~....5..*......K
                        DB      $C0,$CD,$F5,$16,$22,$C2,$C1,$DD,$CB,$00,$7E,$F5,$C4,$63,$14,$F1 ; $171F  ....".....~..c..
                        DB      $CC,$0E,$17,$C9,$2A,$C6,$C1,$01,$FA,$C0,$11,$A9,$C1,$CD,$F5,$16 ; $172F  ....*...........
                        DB      $22,$C6,$C1,$DD,$CB,$00,$7E,$C4,$B4,$14,$C9,$2A,$C4,$C1,$01,$64 ; $173F  ".....~....*...d
                        DB      $C0,$11,$E1,$C0,$CD,$F5,$16,$22,$C4,$C1,$DD,$CB,$00,$7E,$F5,$C4 ; $174F  .......".....~..
                        DB      $AB,$15,$F1,$CC,$0E,$17,$C9,$2A,$FC,$C1,$23,$23,$23,$7E,$D3,$05 ; $175F  .......*..###~..
                        DB      $23,$7E,$D3,$06,$23,$7E,$D3,$07,$23,$7D,$D3,$0D,$7C,$ED,$47,$23 ; $176F  #~..#~..#}..|.G#
                        DB      $23,$7E,$32,$10,$C2,$23,$7E,$32,$11,$C2,$23,$7E,$FE,$FF,$20,$03 ; $177F  #~2..#~2..#~.. .
                        DB      $2A,$0D,$C2,$22,$FC,$C1,$7E,$D3,$0F,$32,$0F,$C2,$23,$23,$08,$7E ; $178F  *.."..~..2..##.~
                        DB      $08,$2A,$10,$C2,$7C,$B5,$C8,$35,$28,$1D,$23,$7E,$23,$CB,$7F,$20 ; $179F  .*..|..5(.#~#..
                        DB      $0E,$86,$77,$23,$7E,$CE,$00,$77,$3A,$0F,$C2,$86,$D3,$0F,$C9,$86 ; $17AF  ..w#~..w:.......
                        DB      $77,$23,$7E,$CE,$FF,$18,$F0,$36,$50,$23,$7E,$ED,$44,$77,$F2,$AB ; $17BF  w#~....6P#~.Dw..
                        DB      $17,$23,$36,$00,$23,$36,$00,$2B,$2B,$18,$D1,$CD,$0E,$17,$B7,$C0 ; $17CF  .#6.#6.++.......
                        DB      $DD,$36,$02,$06,$CD,$0A,$18,$DD,$7E,$01,$FE,$08,$20,$0B,$DD,$7E ; $17DF  .6......~... ..~
                        DB      $18,$FE,$02,$30,$04,$DD,$36,$18,$02,$DD,$34,$18,$CD,$33,$18,$C2 ; $17EF  ...0..6...4..3..
                        DB      $56,$18,$DD,$CB,$00,$BE,$DD,$36,$02,$2D,$C9,$DD,$66,$13,$DD,$6E ; $17FF  V......6.-..f..n
                        DB      $12,$5E,$1C,$23,$56,$DD,$66,$16,$DD,$6E,$15,$AF,$D3,$0C,$AF,$4F ; $180F  .^.#V.f..n.....O
                        DB      $43,$E5,$71,$23,$71,$23,$10,$FA,$E1,$7D,$C6,$50,$6F,$30,$01,$24 ; $181F  C.q#q#...}.Po0.$
                        DB      $15,$20,$ED,$C9,$DD,$7E,$01,$21,$C3,$1A,$CD,$4B,$18,$DD,$7E,$18 ; $182F  . ...~.!...K..~.
                        DB      $CD,$4B,$18,$DD,$75,$12,$DD,$74,$13,$7C,$B5,$C9,$CB,$27,$16,$00 ; $183F  .K..u..t.|...'..
                        DB      $5F,$19,$5E,$23,$56,$EB,$C9,$DD,$CB,$14,$76,$C2,$9F,$18,$CD,$3C ; $184F  _.^#V.....v....<
                        DB      $19,$DD,$66,$13,$DD,$6E,$12,$DD,$56,$16,$DD,$5E,$15,$E5,$FD,$E1 ; $185F  ..f..n..V..^....
                        DB      $23,$23,$FD,$4E,$01,$FD,$46,$00,$D5,$DD,$CB,$14,$5E,$20,$08,$7E ; $186F  ##.N..F.....^ .~
                        DB      $12,$13,$23,$10,$FA,$18,$08,$7E,$12,$13,$12,$13,$23,$10,$F8,$AF ; $187F  ..#....~....#...
                        DB      $12,$32,$FF,$3F,$D1,$0D,$C8,$7B,$C6,$50,$5F,$30,$D8,$14,$18,$D5 ; $188F  .2.?...{.P_0....
                        DB      $CD,$3C,$19,$DD,$56,$16,$DD,$5E,$15,$DD,$66,$13,$DD,$6E,$12,$E5 ; $189F  .<..V..^..f..n..
                        DB      $FD,$E1,$23,$23,$FD,$46,$00,$DD,$CB,$14,$5E,$28,$02,$CB,$20,$DD ; $18AF  ..##.F....^(.. .
                        DB      $7E,$14,$EE,$03,$D3,$0C,$E5,$68,$26,$00,$19,$EB,$E1,$FD,$4E,$01 ; $18BF  ~......h&.....N.
                        DB      $FD,$46,$00,$D5,$DD,$CB,$14,$5E,$20,$08,$7E,$12,$1B,$23,$10,$FA ; $18CF  .F.....^ .~..#..
                        DB      $18,$08,$7E,$12,$1B,$12,$1B,$23,$10,$F8,$AF,$12,$32,$FF,$3F,$D1 ; $18DF  ..~....#....2.?.
                        DB      $0D,$C8,$7B,$C6,$50,$5F,$30,$D8,$14,$18,$D5,$DD,$7E,$17,$D3,$19 ; $18EF  ..{.P_0.....~...
                        DB      $DD,$7E,$14,$D3,$0C,$DD,$56,$13,$DD,$5E,$12,$DD,$66,$16,$DD,$6E ; $18FF  .~....V..^..f..n
                        DB      $15,$13,$1A,$47,$13,$1A,$13,$77,$23,$77,$7D,$C6,$4F,$6F,$30,$01 ; $190F  ...G...w#w}.Oo0.
                        DB      $24,$10,$F2,$C9,$DD,$46,$14,$DD,$7E,$08,$DD,$66,$13,$DD,$6E,$12 ; $191F  $....F..~..f..n.
                        DB      $23,$96,$57,$DD,$66,$0F,$DD,$6E,$0E,$CD,$51,$19,$C9,$CD,$23,$19 ; $192F  #.W.f..n..Q...#.
                        DB      $DD,$7E,$17,$D3,$19,$78,$D3,$0C,$DD,$70,$14,$DD,$74,$16,$DD,$75 ; $193F  .~...x...p..t..u
                        DB      $15,$C9,$3E,$03,$2F,$A0,$47,$E5,$29,$7C,$E6,$03,$B0,$47,$6A,$26 ; $194F  ..>./.G.)|...Gj&
                        DB      $00,$29,$29,$29,$29,$54,$5D,$29,$29,$19,$D1,$CB,$3A,$5A,$16,$00 ; $195F  .))))T]))...:Z..
                        DB      $19,$C9,$DD,$6E,$05,$DD,$66,$06,$DD,$5E,$03,$DD,$56,$04,$19,$DD ; $196F  ...n..f..^..V...
                        DB      $75,$05,$DD,$74,$06,$DD,$5E,$07,$DD,$56,$08,$19,$DD,$75,$07,$DD ; $197F  u..t..^..V...u..
                        DB      $74,$08,$DD,$56,$09,$1E,$00,$B7,$ED,$52,$30,$0A,$DD,$CB,$00,$E6 ; $198F  t..V.....R0.....
                        DB      $DD,$73,$07,$DD,$72,$08,$DD,$6E,$0C,$DD,$66,$0D,$DD,$5E,$0E,$DD ; $199F  .s..r..n..f..^..
                        DB      $56,$0F,$19,$DD,$75,$0E,$DD,$74,$0F,$E5,$11,$00,$00,$B7,$ED,$52 ; $19AF  V...u..t.......R
                        DB      $DC,$CD,$19,$E1,$DD,$56,$11,$B7,$ED,$52,$D4,$CD,$19,$C9,$DD,$CB ; $19BF  .....V...R......
                        DB      $00,$E6,$DD,$73,$0E,$DD,$72,$0F,$C9,$84,$00,$DC,$77,$58,$00,$48 ; $19CF  ...s..r.....wX.H
                        DB      $14,$00,$00,$D7,$00,$1C,$77,$58,$00,$48,$14,$00,$00,$0C,$00,$D8 ; $19DF  ......wX.H......
                        DB      $77,$58,$00,$86,$13,$12,$C2,$18,$00,$D9,$77,$58,$00,$48,$14,$16 ; $19EF  wX........wX.H..
                        DB      $C2,$30,$00,$DA,$77,$58,$00,$48,$14,$1A,$C2,$54,$00,$DB,$77,$58 ; $19FF  .0..wX.H...T..wX
                        DB      $00,$48,$14,$1E,$C2,$FF,$FF,$84,$00,$00,$03,$07,$05,$48,$14,$00 ; $1A0F  .H...........H..
                        DB      $00,$D7,$00,$01,$03,$07,$05,$48,$14,$00,$00,$0C,$00,$00,$03,$07 ; $1A1F  .......H........
                        DB      $05,$86,$13,$12,$C2,$18,$00,$00,$03,$07,$05,$48,$14,$16,$C2,$30 ; $1A2F  ...........H...0
                        DB      $00,$00,$03,$07,$05,$48,$14,$1A,$C2,$54,$00,$00,$03,$07,$05,$48 ; $1A3F  .....H...T.....H
                        DB      $14,$1E,$C2,$FF,$3F,$0E,$EF,$10,$A2,$0F,$E0,$0F,$0A,$10,$28,$10 ; $1A4F  ....?.........(.
                        DB      $3A,$10,$00,$00,$7D,$0E,$C1,$10,$5E,$10,$72,$10,$80,$10,$8A,$10 ; $1A5F  :...}...^.r.....
                        DB      $00,$00,$AB,$0E,$EF,$10,$A2,$0F,$E0,$0F,$0A,$10,$28,$10,$3A,$10 ; $1A6F  ............(.:.
                        DB      $00,$00,$DF,$0E,$C1,$10,$5E,$10,$72,$10,$80,$10,$8A,$10,$00,$00 ; $1A7F  ......^.r.......
                        DB      $09,$0F,$C1,$10,$5E,$10,$72,$10,$80,$10,$8A,$10,$00,$00,$2F,$0F ; $1A8F  ....^.r......./.
                        DB      $B0,$10,$80,$10,$8A,$10,$00,$00,$40,$0F,$66,$0F,$88,$0F,$B0,$10 ; $1A9F  ........ .f.....
                        DB      $80,$10,$8A,$10,$00,$00,$7B,$11,$8D,$11,$00,$00,$2D,$11,$47,$11 ; $1AAF  ......{.....-.G.
                        DB      $62,$11,$00,$00,$53,$1A,$63,$1A,$71,$1A,$81,$1A,$8F,$1A,$9D,$1A ; $1ABF  b...S.c.q.......
                        DB      $B5,$1A,$BB,$1A,$A7,$1A,$82,$C8,$C0,$64,$96,$C0,$4C,$64,$C0,$33 ; $1ACF  .........d..Ld.3
                        DB      $32,$C0,$1A,$00,$C0,$78,$46,$00                                 ; $1ADF  2....xF.

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
                        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C                 ; $1FF4  ............

ROM_END:
                        END
