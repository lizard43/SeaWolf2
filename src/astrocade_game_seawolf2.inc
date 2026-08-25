; ==============================================================================
; astrocade_game_seawolf2.inc
; ------------------------------------------------------------------------------
; Seawolf II arcade-specific I/O and memory definitions.
; ==============================================================================

        include "astrocade_arcade_io_core.inc"

SEAWOLF2_GAME_ID        equ 6

; MAME seawolf2_map.
SW2_ROM_START           equ $0000
SW2_ROM_END             equ $1FFF
SW2_FUNCGEN_START       equ $0000
SW2_FUNCGEN_END         equ $3FFF
SW2_VRAM_START          equ $4000
SW2_VRAM_END            equ $7FFF
SW2_WORK_RAM_START      equ $C000
SW2_WORK_RAM_END        equ $C3FF

; Seawolf II uses port_map_discrete, not the generic Astrocade sound/I/O map.
SW2_PORT_HANDLE_P2      equ AC_PORT_HANDLE1 ; player 2 positional + fire + lang bit
SW2_PORT_HANDLE_P1      equ AC_PORT_HANDLE2 ; player 1 positional + fire
SW2_PORT_HANDLE_SYSTEM  equ AC_PORT_HANDLE3 ; coin/start/lang
SW2_PORT_HANDLE_DIP     equ AC_PORT_HANDLE4 ; S1 DIP bank
SW2_PORT_SOUND1         equ ACSW_PORT_SOUND1
SW2_PORT_SOUND2         equ ACSW_PORT_SOUND2
SW2_PORT_LAMP_LEFT      equ ACSW_PORT_LAMP_LEFT
SW2_PORT_LAMP_RIGHT     equ ACSW_PORT_LAMP_RIGHT

; P1HANDLE / port $10: player 2 scope + language 1 + fire
SW2_P2_POSITION_MASK    equ $3F
SW2_LANG1               equ BIT_6
SW2_P2_FIRE             equ BIT_7  ; active high

; P2HANDLE / port $11: player 1 scope + fire
SW2_P1_POSITION_MASK    equ $3F
SW2_P1_UNUSED6          equ BIT_6
SW2_P1_FIRE             equ BIT_7  ; active high

; P3HANDLE / port $12: system
SW2_COIN1               equ BIT_0  ; active high
SW2_START1              equ BIT_1  ; active high
SW2_START2              equ BIT_2  ; active high
SW2_LANG2               equ BIT_3
SW2_SYSTEM_UNUSED       equ $F0

; P4HANDLE / port $13: S1
SW2_DIP_COINAGE         equ BIT_0
SW2_DIP_PLAY_TIME_MASK  equ BIT_1+BIT_2
SW2_DIP_2PLAYERS_GAME   equ BIT_3
SW2_DIP_EXTENDED_MASK   equ BIT_4+BIT_5
SW2_DIP_MONITOR         equ BIT_6
SW2_DIP_SERVICE         equ BIT_7  ; active low service DIP

; Discrete sound port $40.
SW2_SOUND1_LEFT_TORP    equ ACSW_SOUND1_LEFT_TORP
SW2_SOUND1_LEFT_SHIP    equ ACSW_SOUND1_LEFT_SHIP
SW2_SOUND1_LEFT_MINE    equ ACSW_SOUND1_LEFT_MINE
SW2_SOUND1_RIGHT_TORP   equ ACSW_SOUND1_RIGHT_TORP
SW2_SOUND1_RIGHT_SHIP   equ ACSW_SOUND1_RIGHT_SHIP
SW2_SOUND1_RIGHT_MINE   equ ACSW_SOUND1_RIGHT_MINE

; Discrete sound port $41.
SW2_SOUND2_DIVE_PAN     equ ACSW_SOUND2_DIVE_PAN
SW2_SOUND2_DIVE_START   equ ACSW_SOUND2_DIVE_START
SW2_SOUND2_RIGHT_SONAR  equ ACSW_SOUND2_RIGHT_SONAR
SW2_SOUND2_LEFT_SONAR   equ ACSW_SOUND2_LEFT_SONAR
SW2_SOUND2_COIN_COUNTER equ ACSW_SOUND2_COIN_COUNT
SW2_SOUND2_VOLUME       equ ACSW_SOUND2_VOL_ENABLE

; ------------------------------------------------------------------------------
; End of astrocade_game_seawolf2.inc
; ------------------------------------------------------------------------------
