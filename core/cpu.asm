; Alis, A Atari 2600 emulator
; Copyright (C) 2002-2020 Cidorvan Leite

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see [http://www.gnu.org/licenses/].


%INCLUDE "data.inc"
%INCLUDE "banks.inc"

%IFNDEF RELEASE
EXTERN opcodeNotImplemented, d6502
%ENDIF

; * Addressing modes
; ********************
__IMP    EQU (0 << 28)
__IMM    EQU (1 << 28)
__ZP     EQU (2 << 28)
__ZP2    EQU (3 << 28)
__ZPX    EQU (4 << 28)
__ZPX2   EQU (5 << 28)
__ZPY    EQU (6 << 28)
__ABS    EQU (7 << 28)
__ABS2   EQU (8 << 28)
__ABSX   EQU (9 << 28)
__ABSX2  EQU (10 << 28)
__ABSY   EQU (11 << 28)
__ABSY2  EQU (12 << 28)
__INDX   EQU (13 << 28)
__INDY   EQU (14 << 28)
__INDY2  EQU (15 << 28)


SECTION .text

GLOBAL pulseCpu
pulseCpu:
    mov edx, [nextCpuCycle]
    jmp rdx
NTC:
    ret

; * Initialize CPU
; ******************
GLOBAL initCpu
initCpu:
    mov BYTE [rS], 0FFh
    mov BYTE [flagD], 0
    mov BYTE [flagI], 1
    mov esi, 0FFFCh
    call readMemory
    mov [PCL], al
    mov esi, 0FFFDh
    call readMemory
    mov [PCH], al
;    mov DWORD [programCounter], 0F000h
    mov DWORD [nextCpuCycle], _FETCH_OPCODE
    ret

; * Merge all flags in one byte
; *******************************
GLOBAL saveFlags
saveFlags:
    mov al, [flagN]
    shl al, 1
    or al, [flagV]
    shl al, 2
    or al, 3        ; flag B always 1, there is no IRQB pin
    shl al, 1
    or al, [flagD]
    shl al, 1
    or al, [flagI]
    shl al, 1
    or al, [flagZ]
    shl al, 1
    or al, [flagC]
    ret

; * Extract all flags from one byte
; ***********************************
GLOBAL loadFlags
loadFlags:
    test al, 001h
    setnz [flagC]
    test al, 002h
    setnz [flagZ]
    test al, 004h
    setnz [flagI]
    test al, 008h
    setnz [flagD]
    test al, 040h
    setnz [flagV]
    test al, 080h
    setnz [flagN]
    ret

; *****************************************
; **** MACROS *****************************
; *****************************************

; * Define next cycle
; *********************
%MACRO __NEXT_CYCLE 1
    mov DWORD [nextCpuCycle], %1
    jmp NTC
%ENDMACRO

; * Point next CPU cycle to _FETCH_OPCODE
; *****************************************
%MACRO __NEXT_CYCLE_FECTH_OPCODE 0
    __NEXT_CYCLE _FETCH_OPCODE
%ENDMACRO

; * Point next CPU cycle to _STORE_DATA_RESULT
; **********************************************
%MACRO __NEXT_CYCLE_STORE_RESULT 0
    __NEXT_CYCLE _STORE_DATA_RESULT
%ENDMACRO

; * Point next CPU cycle to ALU
; * *****************************
%MACRO __NEXT_CYCLE_ALU 0
    mov eax, [MNEMONIC]
    __NEXT_CYCLE eax
%ENDMACRO

; * After resolve addressing mode, jump to ALU
; **********************************************
%MACRO __JUMP_MNEMONIC 0
    mov edx, [MNEMONIC]
    jmp rdx
%ENDMACRO

; * Fetch next byte from Program Counter
; ***************************************
%MACRO __FETCH_NEXT_BYTE 0
    mov esi, [programCounter]
    inc DWORD [programCounter]
    call readMemory
%ENDMACRO

; * Fetch low address byte from Program Counter
; ***********************************************
%MACRO __FETCH_ADDRESS_LOW 1
    __FETCH_NEXT_BYTE
    mov [ADL], al
    __NEXT_CYCLE %1
%ENDMACRO

; * Fetch high address byte from Program Counter
; ************************************************
%MACRO __FETCH_ADDRESS_HIGH 1
    __FETCH_NEXT_BYTE
    mov [ADH], al
    __NEXT_CYCLE %1
%ENDMACRO

; * Update address register with index
; **************************************
%MACRO __ADDRESS_LOW_INDEXED 1
    mov al, %1
    add [ADL], al
%ENDMACRO

; * Fetch high address byte from Program Counter
; * indexed with boundary check
; ************************************************
%MACRO __FETCH_ADDRESS_HIGH_IBC 3
    __FETCH_NEXT_BYTE
    mov [ADH], al
    __ADDRESS_LOW_INDEXED %1
    jnc %%A
    __NEXT_CYCLE %2
%%A:__NEXT_CYCLE %3
%ENDMACRO

; * Read memory from address register
; *************************************
%MACRO __READ_MEMORY 0
    mov esi, [ADDRESS]
    call readMemory
%ENDMACRO

; * Read memory from zero page address
; **************************************
%MACRO __READ_ZERO_PAGE 0
    mov BYTE [ADH], 0
    __READ_MEMORY
%ENDMACRO

; * Update flags NZ
; *******************
%MACRO __SET_FLAG_NZ 0
    or al, al
    sets [flagN]
    setz [flagZ]
%ENDMACRO

; * Load register and update flags NZ
; *************************************
%MACRO __LOAD_REGISTER 1
    mov %1, al
    __SET_FLAG_NZ
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Store result in last cycle
; ******************************
%MACRO __STORE_RESULT 1
    mov al, %1
    mov esi, [ADDRESS]
    call writeMemory
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Check flag before branch
; ****************************
%MACRO __BRANCH 2
    test %1, 1
    j%2 %%A
    __FETCH_NEXT_BYTE
    mov [DATA_BUFFER], al
    __NEXT_CYCLE _BRANCH
%%A:inc DWORD [programCounter]
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Increment register or memory and update flags
; *************************************************
%MACRO __INC 1
    inc %1
    sets [flagN]
    setz [flagZ]
%ENDMACRO

; * Decrement register or memory and update flags
; *************************************************
%MACRO __DEC 1
    dec %1
    sets [flagN]
    setz [flagZ]
%ENDMACRO

; * Compare accumulator with memory
; ***********************************
%MACRO __CMP 1
    cmp %1, al
    sets [flagN]
    setz [flagZ]
    setnc [flagC]
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Shift one bit to left from accumulator or memory
; ****************************************************
%MACRO __ASL 1
    shl %1, 1
    sets [flagN]
    setz [flagZ]
    setc [flagC]
%ENDMACRO

; * Shift one bit to right from accumulator or memory
; *****************************************************
%MACRO __LSR 1
    shr %1, 1
    sets [flagN]
    setz [flagZ]
    setc [flagC]
%ENDMACRO

; * Rotate one bit to left from accumulator or memory
; *****************************************************
%MACRO __ROL 1
    shr BYTE [flagC], 1
    rcl %1, 1
    setc [flagC]
    mov al, %1
    __SET_FLAG_NZ
%ENDMACRO

; * Rotate one bit to right from accumulator or memory
; ******************************************************
%MACRO __ROR 1
    shr BYTE [flagC], 1
    rcr %1, 1
    setc [flagC]
    mov al, %1
    __SET_FLAG_NZ
%ENDMACRO

; *****************************************
; **** COMMON CYCLES **********************
; *****************************************

; * Addressing mode Immediate
; *****************************
GLOBAL _IMM
_IMM:
    __FETCH_NEXT_BYTE
    __JUMP_MNEMONIC

; * Addressing mode Z-Page
; **************************
GLOBAL _ZP, _ZP_2
_ZP:
    __FETCH_ADDRESS_LOW _ZP_2
_ZP_2:
    __READ_ZERO_PAGE
    __JUMP_MNEMONIC

; * Addressing mode Z-Page (c=2)
; ********************************
GLOBAL _ZP2
_ZP2:
    __FETCH_ADDRESS_LOW _ZP2_2
_ZP2_2:
    __READ_ZERO_PAGE
    mov [DATA_BUFFER], al
    __NEXT_CYCLE_ALU

; * Addressing mode Z-Page, X
; *****************************
GLOBAL _ZPX, _ZPX_2
_ZPX:
    __FETCH_ADDRESS_LOW _ZPX_2
_ZPX_2:
    __ADDRESS_LOW_INDEXED [rX]
    __NEXT_CYCLE _ZP_2

; * Addressing mode Z-Page, X (c=2)
; ***********************************
GLOBAL _ZPX2
_ZPX2:
    __FETCH_ADDRESS_LOW _ZPX2_2
_ZPX2_2:
    __ADDRESS_LOW_INDEXED [rX]
    __NEXT_CYCLE _ZP2_2

; * Addressing mode Z-Page, Y
; *****************************
GLOBAL _ZPY, _ZPY2
_ZPY:
    __FETCH_ADDRESS_LOW _ZPY2
_ZPY2:
    __ADDRESS_LOW_INDEXED [rY]
    __NEXT_CYCLE _ZP_2

; * Addressing mode Absolute
; ****************************
GLOBAL _ABS, _ABS_2, _ABS_3
_ABS:
    __FETCH_ADDRESS_LOW _ABS_2
_ABS_2:
    __FETCH_ADDRESS_HIGH _ABS_3
_ABS_3:
    __READ_MEMORY
    __JUMP_MNEMONIC

; * Addressing mode Absolute (c=2)
; **********************************
GLOBAL _ABS2, _ABS2_2, _ABS2_3
_ABS2:
    __FETCH_ADDRESS_LOW _ABS2_2
_ABS2_2:
    __FETCH_ADDRESS_HIGH _ABS2_3
_ABS2_3:
    __READ_MEMORY
    mov [DATA_BUFFER], al
    __NEXT_CYCLE_ALU

; * Addressing mode Absolute, X
; *******************************
GLOBAL _ABSX, _ABSX_2, _ABSX_3
_ABSX:
    __FETCH_ADDRESS_LOW _ABSX_2
_ABSX_2:
    __FETCH_ADDRESS_HIGH_IBC [rX], _ABSX_3, _ABS_3
_ABSX_3:
    inc BYTE [ADH]
    __NEXT_CYCLE _ABS_3

; * Addressing mode Absolute, X (c=2)
; *************************************
GLOBAL _ABSX2, _ABSX2_2, _ABSX2_3
_ABSX2:
    __FETCH_ADDRESS_LOW _ABSX2_2
_ABSX2_2:
    __FETCH_ADDRESS_HIGH _ABSX2_3
_ABSX2_3:
    movzx eax, BYTE [rX]
    add DWORD [ADDRESS], eax
    __NEXT_CYCLE _ABS2_3

; * Addressing mode Absolute, Y
; *******************************
GLOBAL _ABSY, _ABSY2
_ABSY:
    __FETCH_ADDRESS_LOW _ABSY2
_ABSY2:
    __FETCH_ADDRESS_HIGH_IBC [rX], _ABSX_3, _ABS_3

; * Addressing mode Absolute, Y (no boundary check)
; ***************************************************
GLOBAL _ABSYN
_ABSYN:
    ; TODO

; * Addressing mode (Indirect, X)
; *********************************
GLOBAL _INDX, _INDX2, _INDX3, _INDX4
_INDX:
    __FETCH_ADDRESS_LOW _INDX2
_INDX2:
    __ADDRESS_LOW_INDEXED [rX]
    mov BYTE [ADH], 0
    __NEXT_CYCLE _INDX3
_INDX3:
    __READ_MEMORY
    mov [DATA_BUFFER], al
    inc BYTE [ADL]
    __NEXT_CYCLE _INDX4
_INDX4:
    __READ_MEMORY
    mov [ADH], al
    mov al, [DATA_BUFFER]
    mov [ADL], al
    __NEXT_CYCLE _ABS_3

; * Addressing mode (Indirect), Y
; *********************************
GLOBAL _INDY, _INDY2, _INDY3, _INDY4
_INDY:
    __FETCH_ADDRESS_LOW _INDY2
_INDY2:
    __READ_ZERO_PAGE
    mov [DATA_BUFFER], al
    inc BYTE [ADL]
    __NEXT_CYCLE _INDY3
_INDY3:
    __READ_MEMORY
    mov [ADH], al
    mov al, [DATA_BUFFER]
    mov [ADL], al
    __ADDRESS_LOW_INDEXED [rY]
    jnc _INDY4
    __NEXT_CYCLE _ABSX_3
_INDY4:
    __NEXT_CYCLE _ABS_3

; * Addressing mode (Indirect), Y (no bounday check)
; ****************************************************
GLOBAL _INDYN
_INDYN:
    ; TODO

; * Opcode not implemented
; **************************
GLOBAL _NIMP
_NIMP:
    __NEXT_CYCLE_FECTH_OPCODE

; * First CPU cycle
; *******************
GLOBAL _FETCH_OPCODE
_FETCH_OPCODE:
    __FETCH_NEXT_BYTE
    movzx eax, al
    mov eax, [OPCODES+eax*4]

%IFNDEF RELEASE
    push rax
    call d6502
    pop rax
    cmp eax, _NIMP
    jne _FO
    push rax
    call opcodeNotImplemented
    pop rax
_FO:
%ENDIF

    test eax, 0F0000000h
    jnz _FO2
    __NEXT_CYCLE eax

_FO2:
    mov edx, eax
    and eax, 0FFFFFFFh
    mov [MNEMONIC], eax
    shr edx, 28
    mov edx, [ADDRESSING_MODES+edx*4]
    __NEXT_CYCLE edx

; * Common cycle to store the final result
; ******************************************
GLOBAL _STORE_DATA_RESULT
_STORE_DATA_RESULT:
    __STORE_RESULT [DATA_BUFFER]

; * Common cycles to branch to a new location
; *********************************************
GLOBAL _BRANCH, _BRANCH2
_BRANCH:
    mov dl, [ADH]
    movsx eax, BYTE [DATA_BUFFER]
    add [programCounter], eax
    cmp [ADH], dl
    je _BRANCH2
    __NEXT_CYCLE _BRANCH2
_BRANCH2:
    __NEXT_CYCLE_FECTH_OPCODE

; ORA - 01/05/09/0D/11/15/19/AD - N Z
;  ************************************
GLOBAL _ORA
_ORA:
    or [rA], al
    sets [flagN]
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE

; ASL - 06/0E/16/1E - N Z C
; ***************************
GLOBAL _ASL
_ASL:
    __ASL BYTE [DATA_BUFFER]
    __NEXT_CYCLE_STORE_RESULT

; PHP - 08 - 3 Clocks
; *********************
GLOBAL _PHP, _PHP2
_PHP:
    __NEXT_CYCLE _PHP2
_PHP2:
    mov al, [rS]
    dec BYTE [rS]
    mov [ADL], al
    mov BYTE [ADH], 1
    call saveFlags
    mov esi, [ADDRESS]
    call writeMemory
    __NEXT_CYCLE_FECTH_OPCODE

; ASL A - 0A - 2 Clocks - N Z C
; *******************************
GLOBAL _ASLRA
_ASLRA:
    __ASL BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; BPL Imm - 10 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BPL
_BPL:
    __BRANCH BYTE [flagN], nz

; CLC - 18 - 2 Clocks - C
; *************************
GLOBAL _CLC
_CLC:
    mov BYTE [flagC], 0
    __NEXT_CYCLE_FECTH_OPCODE

; JSR Abs - 20 $xxxx - 6 Clocks
; ********************************
GLOBAL _JSRA, _JSRA2, _JSRA3, _JSRA4, _JSRA5
_JSRA:
    __FETCH_NEXT_BYTE
    mov [DATA_BUFFER], al
    __NEXT_CYCLE _JSRA2
_JSRA2:
    mov al, [rS]
    mov [ADL], al
    mov BYTE [ADH], 1
    __NEXT_CYCLE _JSRA3
_JSRA3:
    mov al, [PCH]
    mov esi, [ADDRESS]
    call writeMemory
    dec BYTE [rS]
    dec DWORD [ADDRESS]
    __NEXT_CYCLE _JSRA4
_JSRA4:
    mov al, [PCL]
    mov esi, [ADDRESS]
    call writeMemory
    dec BYTE [rS]
    __NEXT_CYCLE _JSRA5
_JSRA5:
    __FETCH_NEXT_BYTE
    mov [PCH], al
    mov al, [DATA_BUFFER]
    mov [PCL], al
    __NEXT_CYCLE_FECTH_OPCODE

; AND - 21/25/29/2D/31/35/39/3D - N Z
; *************************************
GLOBAL _AND
_AND:
    and [rA], al
    sets [flagN]
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE

; BIT 24/2C - N V Z
; *******************
GLOBAL _BIT
_BIT:
    test al, 010000000b
    setnz [flagN]
    test al, 001000000b
    setnz [flagV]
    test [rA], al
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE

; ROL - 26/2E/36/3E - N Z C
; ***************************
GLOBAL _ROL
_ROL:
    __ROL BYTE [DATA_BUFFER]
    __NEXT_CYCLE_STORE_RESULT

; PLP - 28 - 4 Clocks
; **********************
GLOBAL _PLP, _PLP2, _PLP3
_PLP:
    __NEXT_CYCLE _PLP2
_PLP2:
    mov al, [rS]
    mov [ADL], al
    mov BYTE [ADH], 1
    __NEXT_CYCLE _PLP3
_PLP3:
    inc BYTE [rS]
    inc DWORD [ADDRESS]
    mov esi, [ADDRESS]
    call readMemory
    call loadFlags
    __NEXT_CYCLE_FECTH_OPCODE

; ROL A - 2A - 2 Clocks - N Z C
; *******************************
GLOBAL _ROLRA
_ROLRA:
    __ROL BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; BMI Imm - 30 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BMI
_BMI:
    __BRANCH BYTE [flagN], z

; SEC - 38 - 2 Clocks - C
; *************************
GLOBAL _SEC
_SEC:
    mov BYTE [flagC], 1
    __NEXT_CYCLE_FECTH_OPCODE

; EOR - 41/45/49/4D/51/55/59/5D - N Z
; *************************************
GLOBAL _EOR
_EOR:
    xor [rA], al
    sets [flagN]
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE

; LSR 46/4E/56/5E - N Z C
; *************************
GLOBAL _LSR
_LSR:
    __LSR BYTE [DATA_BUFFER]
    __NEXT_CYCLE_STORE_RESULT

; PHA - 48 - 3 Clocks
; *********************
GLOBAL _PHA, _PHA2
_PHA:
    __NEXT_CYCLE _PHA2
_PHA2:
    mov al, [rS]
    dec BYTE [rS]
    mov [ADL], al
    mov BYTE [ADH], 1
    mov al, [rA]
    mov esi, [ADDRESS]
    call writeMemory
    __NEXT_CYCLE_FECTH_OPCODE

; LSR A - 4A - 2 Clocks - N Z C
; *******************************
GLOBAL _LSRRA
_LSRRA:
    __LSR BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; JMP Abs - 4C $xxxx - 3 Clocks
; *******************************
GLOBAL _JMPA, _JMPA2
_JMPA:
    __FETCH_ADDRESS_LOW _JMPA2
_JMPA2:
    __FETCH_NEXT_BYTE
    mov [PCH], al
    mov al, [ADL]
    mov [PCL], al
    __NEXT_CYCLE_FECTH_OPCODE

; BVC Imm - 50 #xx - 2/3/4 CLocks
; *********************************
GLOBAL _BVC
_BVC:
    __BRANCH BYTE [flagV], nz

; CLI - 58 - 2 Clocks - I
; *************************
GLOBAL _CLI
_CLI:
    mov BYTE [flagI], 0
    __NEXT_CYCLE_FECTH_OPCODE

; RTS - 60 - 6 Clocks
; *********************
GLOBAL _RTS, _RTS2, _RTS3, _RTS4, _RTS5
_RTS:
    __NEXT_CYCLE _RTS2
_RTS2:
    mov al, [rS]
    mov [ADL], al
    mov BYTE [ADH], 1
    __NEXT_CYCLE _RTS3
_RTS3:
    inc BYTE [rS]
    inc DWORD [ADDRESS]
    mov esi, [ADDRESS]
    call readMemory
    mov [PCL], al
    __NEXT_CYCLE _RTS4
_RTS4:
    inc BYTE [rS]
    inc DWORD [ADDRESS]
    mov esi, [ADDRESS]
    call readMemory
    mov [PCH], al
    __NEXT_CYCLE _RTS5
_RTS5:
    inc DWORD [programCounter]
    __NEXT_CYCLE_FECTH_OPCODE

; ADC - 61/65/69/6D/71/75/79/7D - N V Z C
; *****************************************
GLOBAL _ADC
_ADC:
    test BYTE [flagD], 1
    jnz _ADC2
    shr BYTE [flagC], 1
    adc [rA], al
    sets [flagN]
    seto [flagV]
    setz [flagZ]
    setc [flagC]
_ADC2:    ; TODO: implement opcode with flagD
    __NEXT_CYCLE_FECTH_OPCODE

; ROR - 66/6E/76/7E - N Z C
; ***************************
GLOBAL _ROR
_ROR:
    __ROR BYTE [DATA_BUFFER]
    __NEXT_CYCLE_STORE_RESULT

; PLA - 68 - 4 Clocks - N Z
; ***************************
GLOBAL _PLA, _PLA2, _PLA3
_PLA:
    __NEXT_CYCLE _PLA2
_PLA2:
    mov al, [rS]
    mov [ADL], al
    mov BYTE [ADH], 1
    __NEXT_CYCLE _PLA3
_PLA3:
    inc BYTE [rS]
    inc DWORD [ADDRESS]
    mov esi, [ADDRESS]
    call readMemory
    mov [rA], al
    __SET_FLAG_NZ
    __NEXT_CYCLE_FECTH_OPCODE

; ROR A - 6A - 2 Clocks - N Z C
; *******************************
GLOBAL _RORRA
_RORRA:
    __ROR BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; JMP (Ind) - 6C $xx $xx - 5 Clocks
; ***********************************
GLOBAL _JMPI, _JMPI2, _JMPI3, _JMPI4
_JMPI:
    __FETCH_ADDRESS_LOW _JMPI2
_JMPI2:
    __FETCH_ADDRESS_HIGH _JMPI3
_JMPI3:
    __READ_MEMORY
    mov [DATA_BUFFER], al
    __NEXT_CYCLE _JMPI4
_JMPI4:
    inc BYTE [ADL]
    __READ_MEMORY
    mov [PCH], al
    mov al, [DATA_BUFFER]
    mov [PCL], al
    __NEXT_CYCLE_FECTH_OPCODE

; BVS Imm - 70 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BVS
_BVS:
    __BRANCH BYTE [flagV], z

; SEI - 78 - 2 Clocks - I
; *************************
GLOBAL _SEI
_SEI:
    mov BYTE [flagI], 1
    __NEXT_CYCLE_FECTH_OPCODE

; STY Z-Page - 84 $xx - 3 Clocks
; ********************************
GLOBAL _STYZ, _STYZ2
_STYZ:
    __FETCH_ADDRESS_LOW _STYZ2
_STYZ2:
    mov BYTE [ADH], 0
    __STORE_RESULT [rY]

; STA Z-Page - 85 $xx - 3 Clocks
; ********************************
GLOBAL _STAZ, _STAZ2
_STAZ:
    __FETCH_ADDRESS_LOW _STAZ2
_STAZ2:
    mov BYTE [ADH], 0
    __STORE_RESULT [rA]

; STX Z-Page - 86 $xx - 3 Clocks
; ********************************
GLOBAL _STXZ, _STXZ2
_STXZ:
    __FETCH_ADDRESS_LOW _STXZ2
_STXZ2:
    mov BYTE [ADH], 0
    __STORE_RESULT [rX]

; DEY - 88 - 2 Clocks - N Z
; ***************************
GLOBAL _DEY
_DEY:
    __DEC BYTE [rY]
    __NEXT_CYCLE_FECTH_OPCODE

; TXA - 8A - 2 Clocks - N Z
; ***************************
GLOBAL _TXA
_TXA:
    mov al, [rX]
    __LOAD_REGISTER [rA]

; STY Abs - 8C $xxxx - 4 Clocks
; *******************************
GLOBAL _STYA, _STYA2, _STYA3
_STYA:
    __FETCH_ADDRESS_LOW _STYA2
_STYA2:
    __FETCH_ADDRESS_HIGH _STYA3
_STYA3:
    __STORE_RESULT [rY]

; STA Abs - 8D $xxxx - 4 Clocks
; *******************************
GLOBAL _STAA, _STAA2, _STAA3
_STAA:
    __FETCH_ADDRESS_LOW _STAA2
_STAA2:
    __FETCH_ADDRESS_HIGH _STAA3
_STAA3:
    __STORE_RESULT [rA]

; STX Abs - 8E $xxxx - 4 Clocks
; *******************************
GLOBAL _STXA, _STXA2, _STXA3
_STXA:
    __FETCH_ADDRESS_LOW _STXA2
_STXA2:
    __FETCH_ADDRESS_HIGH _STXA3
_STXA3:
    __STORE_RESULT [rX]

; BCC Imm - 90 #xx - 2/3/4 Clocks -
; ***********************************
GLOBAL _BCC
_BCC:
    __BRANCH BYTE [flagC], nz

; STA Z-Page, X - 95 $xx - 4 Clocks
; ***********************************
GLOBAL _STAZX, _STAZX2
_STAZX:
    __FETCH_ADDRESS_LOW _STAZX2
_STAZX2:
    __ADDRESS_LOW_INDEXED [rX]
    mov BYTE [ADH], 0
    __NEXT_CYCLE _STAA3

; TYA - 98 - 2 Clocks - N Z
; ***************************
GLOBAL _TYA
_TYA:
    mov al, [rY]
    __LOAD_REGISTER [rA]

; TXS - 9A - 2 Clocks -
; ************************
GLOBAL _TXS
_TXS:
    mov al, [rX]
    mov [rS], al
    __NEXT_CYCLE_FECTH_OPCODE

; LDY A0/A4/AC/B4/VC - N Z
; **************************
GLOBAL _LDY
_LDY:
    __LOAD_REGISTER [rY]

; LDA - A1/A5/A9/AD/B1/B5/B9/BD - N Z
; *************************************
GLOBAL _LDA
_LDA:
    __LOAD_REGISTER [rA]

; LDX - A2/A6/AE/B6/BE - N Z
; ****************************
GLOBAL _LDX
_LDX:
    __LOAD_REGISTER [rX]

; TAY - A8 - 2 Clocks - N Z
; ***************************
GLOBAL _TAY
_TAY:
    mov al, [rA]
    __LOAD_REGISTER [rY]

; TAX - AA - 2 Clocks - N Z
; ***************************
GLOBAL _TAX
_TAX:
    mov al, [rA]
    __LOAD_REGISTER [rX]

; BCS Imm - B0 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BCS
_BCS:
    __BRANCH BYTE [flagC], z

; TSX - BA - 2 Clocks - N Z
; ***************************
GLOBAL _TSX
_TSX:
    mov al, [rS]
    __LOAD_REGISTER [rX]

; CPY - C0/C4/CC - N Z C
; ************************
GLOBAL _CPY
_CPY:
    __CMP [rY]

; CMP - C1/C5/C9/CD/D1/D5/D9/DD - N Z C
; ***************************************
GLOBAL _CMP
_CMP:
    __CMP [rA]

; DEC - C6/CE/D6/DE - N Z
; *************************
GLOBAL _DEC
_DEC:
    __DEC BYTE [DATA_BUFFER]
    __NEXT_CYCLE_STORE_RESULT

; INY - C8 - 2 Clocks - N Z
; ***************************
GLOBAL _INY
_INY:
    __INC BYTE [rY]
    __NEXT_CYCLE_FECTH_OPCODE

; DEX - CA - 2 Clocks - N Z
; ***************************
GLOBAL _DEX
_DEX:
    __DEC BYTE [rX]
    __NEXT_CYCLE_FECTH_OPCODE

; BNE Imm - D0 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BNE
_BNE:
    __BRANCH BYTE [flagZ], nz

; CLD - D8 - 2 Clocks - D
; *************************
GLOBAL _CLD
_CLD:
    mov BYTE [flagD], 0
    __NEXT_CYCLE_FECTH_OPCODE

; CPX - E0/E4/EC - N Z C
; ************************
GLOBAL _CPX
_CPX:
    __CMP [rX]

; SBC - E1/E5/E9/ED/F1/F5/F9/FD - N V Z C
; *****************************************
GLOBAL _SBC
_SBC:
    xor BYTE [flagC], 1
    test BYTE [flagD], 1
    jnz _SBC2
    shr BYTE [flagC], 1
    sbb [rA], al
    sets [flagN]
    seto [flagV]
    setz [flagZ]
    setnc [flagC]
_SBC2:    ; TODO: implement opcode with flagD
    __NEXT_CYCLE_FECTH_OPCODE

; INC - E6/EE/F6/FE - N Z
; *************************
GLOBAL _INC
_INC:
    __INC BYTE [DATA_BUFFER]
    __NEXT_CYCLE_STORE_RESULT

; INX - E8 - 2 Clocks - N Z
; ***************************
GLOBAL _INX
_INX:
    __INC BYTE [rX]
    __NEXT_CYCLE_FECTH_OPCODE

; * NOP - EA - 2 Clocks
; ***********************
GLOBAL _NOP
_NOP:
    __NEXT_CYCLE_FECTH_OPCODE

; BEQ Imm - F0 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BEQ
_BEQ:
    __BRANCH BYTE [flagZ], z

; SED - F8 - 2 Clocks - D
; *************************
GLOBAL _SED
_SED:
    mov BYTE [flagD], 1
    __NEXT_CYCLE_FECTH_OPCODE

SECTION .data

GLOBAL OPCODES
OPCODES:
    ;   0/8             1/9             2/A             3/B             4/C             5/D             6/E             7/F
    DD _NIMP,          _ORA + __INDX,  _NIMP,          _NIMP,          _NIMP,          _ORA + __ZP,    _ASL + __ZP2,   _NIMP
    DD _PHP,           _ORA + __IMM,   _ASLRA,         _NIMP,          _NIMP,          _ORA + __ABS,   _ASL + __ABS2,  _NIMP    ; 0
    DD _BPL,           _ORA + __INDY,  _NIMP,          _NIMP,          _NIMP,          _ORA + __ZPX,   _ASL + __ZPX2,  _NIMP
    DD _CLC,           _ORA + __ABSY,  _NIMP,          _NIMP,          _NIMP,          _ORA + __ABSX,  _ASL + __ABSX2, _NIMP    ; 1

    DD _JSRA,          _AND + __INDX,  _NIMP,          _NIMP,          _BIT + __ZP,    _AND + __ZP,    _ROL + __ZP2,   _NIMP
    DD _PLP,           _AND + __IMM,   _ROLRA,         _NIMP,          _BIT + __ABS,   _AND + __ABS,   _ROL + __ABS2,  _NIMP    ; 2
    DD _BMI,           _AND + __INDY,  _NIMP,          _NIMP,          _NIMP,          _AND + __ZPX,   _ROL + __ZPX2,  _NIMP
    DD _SEC,           _AND + __ABSY,  _NIMP,          _NIMP,          _NIMP,          _AND + __ABSX,  _ROL + __ABSX2, _NIMP    ; 3

    DD _NIMP,          _EOR + __INDX,  _NIMP,          _NIMP,          _NIMP,          _EOR + __ZP,    _LSR + __ZP2,   _NIMP
    DD _PHA,           _EOR + __IMM,   _LSRRA,         _NIMP,          _JMPA,          _EOR + __ABS,   _LSR + __ABS2,  _NIMP    ; 4
    DD _BVC,           _EOR + __INDY,  _NIMP,          _NIMP,          _NIMP,          _EOR + __ZPX,   _LSR + __ZPX2,  _NIMP
    DD _CLI,           _EOR + __ABSY,  _NIMP,          _NIMP,          _NIMP,          _EOR + __ABSX,  _LSR + __ABSX2, _NIMP    ; 5

    DD _RTS,           _ADC + __INDX,  _NIMP,          _NIMP,          _NIMP,          _ADC + __ZP,    _ROR + __ZP2,   _NIMP
    DD _PLA,           _ADC + __IMM,   _RORRA,         _NIMP,          _JMPI,          _ADC + __ABS,   _ROR + __ABS2,  _NIMP    ; 6
    DD _BVS,           _ADC + __INDY,  _NIMP,          _NIMP,          _NIMP,          _ADC + __ZPX,   _ROR + __ZPX2,  _NIMP
    DD _SEI,           _ADC + __ABSY,  _NIMP,          _NIMP,          _NIMP,          _ADC + __ABSX,  _ROR + __ABSX2, _NIMP    ; 7

    DD _NIMP,          _NIMP,          _NIMP,          _NIMP,          _STYZ,          _STAZ,          _STXZ,          _NIMP
    DD _DEY,           _NIMP,          _TXA,           _NIMP,          _STYA,          _STAA,          _STXA,          _NIMP    ; 8
    DD _BCC,           _NIMP,          _NIMP,          _NIMP,          _NIMP,          _STAZX,         _NIMP,          _NIMP
    DD _TYA,           _NIMP,          _TXS,           _NIMP,          _NIMP,          _NIMP,          _NIMP,          _NIMP    ; 9

    DD _LDY + __IMM,   _LDA + __INDX,  _LDX + __IMM,   _NIMP,          _LDY + __ZP,    _LDA + __ZP,    _LDX + __ZP,    _NIMP
    DD _TAY,           _LDA + __IMM,   _TAX,           _NIMP,          _LDY + __ABS,   _LDA + __ABS,   _LDX + __ABS,   _NIMP    ; A
    DD _BCS,           _LDA + __INDY,  _NIMP,          _NIMP,          _LDY + __ZPX,   _LDA + __ZPX,   _LDX + __ZPY,   _NIMP
    DD _NIMP,          _LDA + __ABSY,  _TSX,           _NIMP,          _LDY + __ABSX,  _LDA + __ABSX,  _LDX + __ABSY,  _NIMP    ; B

    DD _CPY + __IMM,   _CMP + __INDX,  _NIMP,          _NIMP,          _CPY + __ZP,    _CMP + __ZP,    _DEC + __ZP2,   _NIMP
    DD _INY,           _CMP + __IMM,   _DEX,           _NIMP,          _CPY + __ABS,   _CMP + __ABS,   _DEC + __ABS2,  _NIMP    ; C
    DD _BNE,           _CMP + __INDY,  _NIMP,          _NIMP,          _NIMP,          _CMP + __ZPX,   _DEC + __ZPX2,  _NIMP
    DD _CLD,           _CMP + __ABSY,  _NIMP,          _NIMP,          _NIMP,          _CMP + __ABSX,  _DEC + __ABSX2, _NIMP    ; D

    DD _CPX + __IMM,   _SBC + __INDX,  _NIMP,          _NIMP,          _CPX + __ZP,    _SBC + __ZP,    _INC + __ZP2,   _NIMP
    DD _INX,           _SBC + __IMM,   _NOP,           _NIMP,          _CPX + __ABS,   _SBC + __ABS,   _INC + __ABS2,  _NIMP    ; E
    DD _BEQ,           _SBC + __INDY,  _NIMP,          _NIMP,          _NIMP,          _SBC + __ZPX,   _INC + __ZPX2,  _NIMP
    DD _SED,           _SBC + __ABSY,  _NIMP,          _NIMP,          _NIMP,          _SBC + __ABSX,  _INC + __ABSX2, _NIMP    ; F

GLOBAL ADDRESSING_MODES
ADDRESSING_MODES:
    DD 0        ; Implied
    DD _IMM     ; Immediate #
    DD _ZP      ; Z-Page
    DD _ZP2     ; Z-Page (c=2)
    DD _ZPX     ; Z-Page, X
    DD _ZPX2    ; Z-Page, X (c=2)
    DD _ZPY     ; Z-Page, Y
    DD _ABS     ; Absolute
    DD _ABS2    ; Absolute (c=2)
    DD _ABSX    ; Absolute, X
    DD _ABSX2   ; Absolute, X (c=2)
    DD _ABSY    ; Absolute, Y
    DD _ABSYN   ; Absolute, Y (no boundary check)
    DD _INDX    ; (Indirect, X)
    DD _INDY    ; (Indirect), Y
    DD _INDYN   ; (Indirect), Y (no boundary check)


SECTION .bss

GLOBAL nextCpuCycle, MNEMONIC
nextCpuCycle    RESD 1
MNEMONIC        RESD 1

GLOBAL ADDRESS, ADL, ADH
ADDRESS:
ADL             RESB 1
ADH             RESB 3      ; padding for 4 bytes

GLOBAL DATA_BUFFER
DATA_BUFFER    RESB 1
