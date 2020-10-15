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
    mov [dataRegister], al
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

; * Test bits from accumulator and memory
; *****************************************
%MACRO __BIT 0
    test al, 010000000b
    setnz [flagN]
    test al, 001000000b
    setnz [flagV]
    test [rA], al
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE
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

; * Execute OR operation from accumulator and memory
; ****************************************************
%MACRO __ORA 0
    or [rA], al
    sets [flagN]
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Execute AND operation from accumulator and memory
; *****************************************************
%MACRO __AND 0
    and [rA], al
    sets [flagN]
    setz [flagZ]
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Execute XOR operation from accumulator and memory
; *****************************************************
%MACRO __EOR 0
    xor [rA], al
    sets [flagN]
    setz [flagZ]
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

; * Add memory content to accumulator
; *************************************
%MACRO __ADC 0
    test BYTE [flagD], 1
    jnz %%A
    shr BYTE [flagC], 1
    adc [rA], al
    sets [flagN]
    seto [flagV]
    setz [flagZ]
    setc [flagC]
%%A:    ; TODO: implement opcode with flagD
    __NEXT_CYCLE_FECTH_OPCODE
%ENDMACRO

; * Subtract memory content to accumulator
; ******************************************
%MACRO __SBC 0
    xor BYTE [flagC], 1
    test BYTE [flagD], 1
    jnz %%A
    shr BYTE [flagC], 1
    sbb [rA], al
    sets [flagN]
    seto [flagV]
    setz [flagZ]
    setnc [flagC]
%%A:    ; TODO: implement opcode with flagD
    __NEXT_CYCLE_FECTH_OPCODE
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
GLOBAL _ZP, _ZP2
_ZP:
    __FETCH_ADDRESS_LOW _ZP2
_ZP2:
    __READ_ZERO_PAGE
    __JUMP_MNEMONIC

; * Addressing mode Z-Page, X
; *****************************
GLOBAL _ZPX, _ZPX2
_ZPX:
    __FETCH_ADDRESS_LOW _ZPX2
_ZPX2:
    __ADDRESS_LOW_INDEXED [rX]
    __NEXT_CYCLE _ZP2

; * Addressing mode Z-Page, Y
; *****************************
GLOBAL _ZPY, _ZPY2
_ZPY:
    __FETCH_ADDRESS_LOW _ZPX2
_ZPY2:
    __ADDRESS_LOW_INDEXED [rY]
    __NEXT_CYCLE _ZP2

; * Addressing mode Absolute
; ****************************
GLOBAL _ABS, _ABS2, _ABS3
_ABS:
    __FETCH_ADDRESS_LOW _ABS2
_ABS2:
    __FETCH_ADDRESS_HIGH _ABS3
_ABS3:
    __READ_MEMORY
    __JUMP_MNEMONIC

; * Addressing mode Absolute, X
; *******************************
GLOBAL _ABSX, _ABSX2, _ABSX3
_ABSX:
    __FETCH_ADDRESS_LOW _ABSX2
_ABSX2:
    __FETCH_ADDRESS_HIGH_IBC [rX], _ABSX3, _ABS3
_ABSX3:
    inc BYTE [ADH]
    __NEXT_CYCLE _ABS3

; * Addressing mode Absolute, Y
; *******************************
GLOBAL _ABSY, _ABSY2
_ABSY:
    __FETCH_ADDRESS_LOW _ABSY2
_ABSY2:
    __FETCH_ADDRESS_HIGH_IBC [rX], _ABSX3, _ABS3

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
    mov [dataRegister], al
    inc BYTE [ADL]
    __NEXT_CYCLE _INDX4
_INDX4:
    __READ_MEMORY
    mov [ADH], al
    mov al, [dataRegister]
    mov [ADL], al
    __NEXT_CYCLE _ABS3 

; * Addressing mode (Indirect), Y
; *********************************
GLOBAL _INDY, _INDY2, _INDY3, _INDY4
_INDY:
    __FETCH_ADDRESS_LOW _INDY2
_INDY2:
    __READ_ZERO_PAGE
    mov [dataRegister], al
    inc BYTE [ADL]
    __NEXT_CYCLE _INDY3
_INDY3:
    __READ_MEMORY
    mov [ADH], al
    mov al, [dataRegister]
    mov [ADL], al
    __ADDRESS_LOW_INDEXED [rY]
    jnc _INDY4
    __NEXT_CYCLE _ABSX3
_INDY4:
    __NEXT_CYCLE _ABS3

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
%IFNDEF RELEASE
    mov [opcode], al
%ENDIF
    mov eax, [opcodes+eax*4]

%IFNDEF RELEASE
    push rax
    call d6502
    pop rax
    cmp eax, _NIMP
    jne _FO
    push rax
    movzx edi, BYTE [opcode]
    call opcodeNotImplemented
    pop rax
_FO:
%ENDIF
    __NEXT_CYCLE eax

; * Common cycle to store the final result
; ******************************************
GLOBAL _STORE_DATA_RESULT
_STORE_DATA_RESULT:
    __STORE_RESULT [dataRegister]

; * Common cycles to branch to a new location
; *********************************************
GLOBAL _BRANCH, _BRANCH2
_BRANCH:
    mov dl, [ADH]
    movsx eax, BYTE [dataRegister]
    add [programCounter], eax
    cmp [ADH], dl
    je _BRANCH2
    __NEXT_CYCLE _BRANCH2
_BRANCH2:
    __NEXT_CYCLE_FECTH_OPCODE

; ORA Z-Page - 05 $xx - 2 Clocks - N Z
; **************************************
GLOBAL _ORAZ, _ORAZ2
_ORAZ:
    __FETCH_ADDRESS_LOW _ORAZ2
_ORAZ2:
    __READ_ZERO_PAGE
    __ORA

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

; ORA Imm - 09 #xx - 2 Clocks - N Z
; ***********************************
GLOBAL _ORAI
_ORAI:
    __FETCH_NEXT_BYTE
    __ORA

; ASL A - 0A - 2 Clocks - N Z C
; *******************************
GLOBAL _ASLRA
_ASLRA:
    __ASL BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; ASL Abs - 0E $xxxx - 6 Clocks - N Z C
; ***************************************
GLOBAL _ASLA, _ASLA2, _ASLA3, _ASLA4
_ASLA:
    __FETCH_ADDRESS_LOW _ASLA2
_ASLA2:
    __FETCH_ADDRESS_HIGH _ASLA3
_ASLA3:
    __READ_MEMORY
    mov [dataRegister], al
    __NEXT_CYCLE _ASLA4
_ASLA4:
    __ASL BYTE [dataRegister]
    __NEXT_CYCLE_STORE_RESULT

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

; ASL Abs, X - 1E $xxxx - 7 Clocks - N Z C
; ******************************************
GLOBAL _ASLAX, _ASLAX2, _ASLAX3
_ASLAX:
    __FETCH_ADDRESS_LOW _ASLAX2
_ASLAX2:
    __FETCH_ADDRESS_HIGH _ASLAX3
_ASLAX3:
    movzx eax, BYTE [rX]
    add DWORD [ADDRESS], eax
    __NEXT_CYCLE _ASLA3

; JSR Abs - 20 $xxxx - 6 Clocks
; ********************************
GLOBAL _JSRA, _JSRA2, _JSRA3, _JSRA4, _JSRA5
_JSRA:
    __FETCH_NEXT_BYTE
    mov [dataRegister], al
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
    mov al, [dataRegister]
    mov [PCL], al
    __NEXT_CYCLE_FECTH_OPCODE

; BIT Z-Page - 24 $xx - 3 Clocks - N V Z
; ****************************************
GLOBAL _BITZ, _BITZ2
_BITZ:
    __FETCH_ADDRESS_LOW _BITZ2
_BITZ2:
    __READ_ZERO_PAGE
    __BIT

; AND Z-Page - 25 $xx - 3 Clocks - N Z
; **************************************
GLOBAL _ANDZ, _ANDZ2
_ANDZ:
    __FETCH_ADDRESS_LOW _ANDZ2
_ANDZ2:
    __READ_ZERO_PAGE
    __AND

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

; AND Imm - 29 #xx - 2 Clocks - N Z
; ***********************************
GLOBAL _ANDI
_ANDI:
   __FETCH_NEXT_BYTE
   __AND

; ROL A - 2A - 2 Clocks - N Z C
; *******************************
GLOBAL _ROLRA
_ROLRA:
    __ROL BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; AND Abs - 2D $xxxx - 4 Clocks - N Z
; *************************************
GLOBAL _ANDA, _ANDA2, _ANDA3
_ANDA:
    __FETCH_ADDRESS_LOW _ANDA2
_ANDA2:
    __FETCH_ADDRESS_HIGH _ANDA3
_ANDA3:
    __READ_MEMORY
    __AND

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

; EOR Z-Page - 45 $xx - 3 Clocks - N Z
; **************************************
GLOBAL _EORZ, _EORZ2
_EORZ:
    __FETCH_ADDRESS_LOW _EORZ2
_EORZ2:
    __READ_ZERO_PAGE
    __EOR

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

; EOR Imm - 49 #xx - 2 Clocks - N Z
; ***********************************
GLOBAL _EORI
_EORI:
    __FETCH_NEXT_BYTE
    __EOR

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

; ADC Z-Page - 65 $xx - 3 Clocks - N V Z C
; ******************************************
GLOBAL _ADCZ, _ADCZ2
_ADCZ:
    __FETCH_ADDRESS_LOW _ADCZ2
_ADCZ2:
    __READ_ZERO_PAGE
    __ADC

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

; ADC Imm - 69 #xx - 2 Clocks - N V Z C
; ***************************************
GLOBAL _ADCI
_ADCI:
    __FETCH_NEXT_BYTE
    __ADC

; ROR A - 6A - 2 Clocks - N Z C
; *******************************
GLOBAL _RORRA
_RORRA:
    __ROR BYTE [rA]
    __NEXT_CYCLE_FECTH_OPCODE

; ADC Abs - 6D $xxxx - 4 Clocks - N V Z C
; *****************************************
GLOBAL _ADCA, _ADCA2, _ADCA3
_ADCA:
    __FETCH_ADDRESS_LOW _ADCA2
_ADCA2:
    __FETCH_ADDRESS_HIGH _ADCA3
_ADCA3:
    __READ_MEMORY
    __ADC

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

; ADC Abs, X - 7D $xxxx - 4/5 Clocks - N V Z C
; **********************************************
GLOBAL _ADCAX, _ADCAX2, _ADCAX3
_ADCAX:
    __FETCH_ADDRESS_LOW _ADCAX2
_ADCAX2:
    __FETCH_ADDRESS_HIGH_IBC [rX], _ADCAX3, _ADCA3
_ADCAX3:
    inc BYTE [ADH]
    __NEXT_CYCLE _ADCA3

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

; LDY Imm - A0 #xx - 2 Clocks - N Z
; ***********************************
GLOBAL _LDYI
_LDYI:
    __FETCH_NEXT_BYTE
    __LOAD_REGISTER [rY]

; LDA (Ind, X) - A1 $xx - 6 Clocks - N Z
; ****************************************
GLOBAL _LDAIX, _LDAIX2, _LDAIX3, _LDAIX4
_LDAIX:
    __FETCH_ADDRESS_LOW _LDAIX2
_LDAIX2:
    __ADDRESS_LOW_INDEXED [rX]
    mov BYTE [ADH], 0
    __NEXT_CYCLE _LDAIX3
_LDAIX3:
    __READ_MEMORY
    inc BYTE [ADL]
    mov [dataRegister], al
    __NEXT_CYCLE _LDAIX4
_LDAIX4:
    __READ_MEMORY
    mov [ADH], al
    mov al, [dataRegister]
    mov [ADL], al
    __NEXT_CYCLE _LDAA3

; LDX Imm - A2 #xx - 2 Clocks - N Z
; ***********************************
GLOBAL _LDXI
_LDXI:
    __FETCH_NEXT_BYTE
    __LOAD_REGISTER [rX]

; LDY Z-Page - A4 $xx - 3 Clocks - N Z
; **************************************
GLOBAL _LDYZ, _LDYZ2
_LDYZ:
    __FETCH_ADDRESS_LOW _LDYZ2
_LDYZ2:
    __READ_ZERO_PAGE
    __LOAD_REGISTER [rY]

; LDA Z-Page - A5 $xx - 3 Clocks - N Z
; **************************************
GLOBAL _LDAZ, _LDAZ2
_LDAZ:
    __FETCH_ADDRESS_LOW _LDAZ2
_LDAZ2:
    __READ_ZERO_PAGE
    __LOAD_REGISTER [rA]

; LDX Z-Page - A6 $xx - 3 Clocks - N Z
; **************************************
GLOBAL _LDXZ, _LDXZ2
_LDXZ:
    __FETCH_ADDRESS_LOW _LDXZ2
_LDXZ2:
    __READ_ZERO_PAGE
    __LOAD_REGISTER [rX]

; TAY - A8 - 2 Clocks - N Z
; ***************************
GLOBAL _TAY
_TAY:
    mov al, [rA]
    __LOAD_REGISTER [rY]

; LDA Imm - A9 #xx - 2 Clocks - N Z
; ***********************************
GLOBAL _LDAI
_LDAI:
    __FETCH_NEXT_BYTE
    __LOAD_REGISTER [rA]

; TAX - AA - 2 Clocks - N Z
; ***************************
GLOBAL _TAX
_TAX:
    mov al, [rA]
    __LOAD_REGISTER [rX]

; LDY Abs - AC $xxxx - 4 Clocks - N Z
; *************************************
GLOBAL _LDYA, _LDYA2, _LDYA3
_LDYA:
    __FETCH_ADDRESS_LOW _LDYA2
_LDYA2:
    __FETCH_ADDRESS_HIGH _LDYA3
_LDYA3:
    __READ_MEMORY
    __LOAD_REGISTER [rY]

; LDA Abs - AD $xxxx - 4 Clocks - N Z
; *************************************
GLOBAL _LDAA, _LDAA2, _LDAA3
_LDAA:
    __FETCH_ADDRESS_LOW _LDAA2
_LDAA2:
    __FETCH_ADDRESS_HIGH _LDAA3
_LDAA3:
    __READ_MEMORY
    __LOAD_REGISTER [rA]

; LDX Abs - AE $xxxx - 4 Clocks - N Z
; *************************************
GLOBAL _LDXA, _LDXA2, _LDXA3
_LDXA:
    __FETCH_ADDRESS_LOW _LDXA2
_LDXA2:
    __FETCH_ADDRESS_HIGH _LDXA3
_LDXA3:
    __READ_MEMORY
    __LOAD_REGISTER [rX]

; BCS Imm - B0 #xx - 2/3/4 Clocks
; *********************************
GLOBAL _BCS
_BCS:
    __BRANCH BYTE [flagC], z

; LDA (Ind), Y - B1 $xx - 5/6 Clocks - N Z
; ******************************************
GLOBAL _LDAIY, _LDAIY2, _LDAIY3
_LDAIY:
    __FETCH_ADDRESS_LOW _LDAIY2
_LDAIY2:
    __READ_ZERO_PAGE
    mov [dataRegister], al
    inc BYTE [ADL]
    __NEXT_CYCLE _LDAIY3
_LDAIY3:
    __READ_MEMORY
    mov [ADH], al
    mov al, [dataRegister]
    mov [ADL], al
    __ADDRESS_LOW_INDEXED [rY]
    jnc _LDAIY3_2
    __NEXT_CYCLE _LDAAY3
_LDAIY3_2:
    __NEXT_CYCLE _LDAA3

; LDA Z-Page, X - B5 $xx - 4 Clocks - N Z
; *****************************************
GLOBAL _LDAZX, _LDAZX2
_LDAZX:
    __FETCH_ADDRESS_LOW _LDAZX2
_LDAZX2:
    __ADDRESS_LOW_INDEXED [rX]
    __NEXT_CYCLE _LDAZ2

; LDA Abs, Y - B9 $xxxx - 4/5 Clocks - N Z
; ******************************************
GLOBAL _LDAAY, _LDAAY2, _LDAAY3
_LDAAY:
    __FETCH_ADDRESS_LOW _LDAAY2
_LDAAY2:
    __FETCH_ADDRESS_HIGH_IBC [rY], _LDAAY3, _LDAA3
_LDAAY3:
    inc BYTE [ADH]
    __NEXT_CYCLE _LDAA3

; TSX - BA - 2 Clocks - N Z
; ***************************
GLOBAL _TSX
_TSX:
    mov al, [rS]
    __LOAD_REGISTER [rX]

; LDA Abs, X - BD $xxxx - 4/5 Clocks - N Z
; ******************************************
GLOBAL _LDAAX, _LDAAX2
_LDAAX:
    __FETCH_ADDRESS_LOW _LDAAX2
_LDAAX2:
    __FETCH_ADDRESS_HIGH_IBC [rX], _LDAAY3, _LDAA3

; LDX Abs, Y - BE $xxxx - 4/5 Clocks - N Z
; ******************************************
GLOBAL _LDXAY, _LDXAY2, _LDXAY3
_LDXAY:
    __FETCH_ADDRESS_LOW _LDXAY2
_LDXAY2:
    __FETCH_ADDRESS_HIGH_IBC [rY], _LDXAY3, _LDXA3
_LDXAY3:
    inc BYTE [ADH]
    __NEXT_CYCLE _LDXA3

; CPY Imm - C0 $xx - 2 Clocks - N Z C
; *************************************
GLOBAL _CPYI
_CPYI:
    __FETCH_NEXT_BYTE
    __CMP [rY]

; CPY Z-Page - C4 $xx - 3 Clocks - N Z C
; ****************************************
GLOBAL _CPYZ, _CPYZ2
_CPYZ:
    __FETCH_ADDRESS_LOW _CPYZ2
_CPYZ2:
    __READ_ZERO_PAGE
    __CMP [rY]

; CMP Z-Page - C5 $xx - 3 Clocks - N Z C
; ****************************************
GLOBAL _CMPZ, _CMPZ2
_CMPZ:
    __FETCH_ADDRESS_LOW _CMPZ2
_CMPZ2:
    __READ_ZERO_PAGE
    __CMP [rA]

; DEC Z-Page - C6 $xx - 5 Clocks - N Z
; **************************************
GLOBAL _DECZ, _DECZ2, _DECZ3
_DECZ:
    __FETCH_ADDRESS_LOW _DECZ2
_DECZ2:
    __READ_ZERO_PAGE
    mov [dataRegister], al
    __NEXT_CYCLE _DECZ3
_DECZ3:
    __DEC BYTE [dataRegister]
    __NEXT_CYCLE_STORE_RESULT

; INY - C8 - 2 Clocks - N Z
; ***************************
GLOBAL _INY
_INY:
    __INC BYTE [rY]
    __NEXT_CYCLE_FECTH_OPCODE

; CMP Imm - C9 #xx - 2 Clocks - N Z C
; *************************************
GLOBAL _CMPI
_CMPI:
   __FETCH_NEXT_BYTE
   __CMP [rA]

; DEX - CA - 2 Clocks - N Z
; ***************************
GLOBAL _DEX
_DEX:
    __DEC BYTE [rX]
    __NEXT_CYCLE_FECTH_OPCODE

; CMP Abs - CD $xxxx - 4 Clocks - N Z C
; ***************************************
GLOBAL _CMPA, _CMPA2, _CMPA3
_CMPA:
    __FETCH_ADDRESS_LOW _CMPA2
_CMPA2:
    __FETCH_ADDRESS_HIGH _CMPA3
_CMPA3:
    __READ_MEMORY
    __CMP [rA]

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

; CPX Imm - E0 $xx - 2 Clocks - N Z C
; *************************************
GLOBAL _CPXI
_CPXI:
    __FETCH_NEXT_BYTE
    __CMP [rX]

; SBC Z-Page - E5 $xx - 3 Clocks - N V Z C
; ******************************************
GLOBAL _SBCZ, _SBCZ2
_SBCZ:
    __FETCH_ADDRESS_LOW _SBCZ2
_SBCZ2:
    __READ_ZERO_PAGE
    __SBC

; INC Z-Page - E6 $xx - 5 Clocks - N Z
; **************************************
GLOBAL _INCZ, _INCZ2, _INCZ3
_INCZ:
    __FETCH_ADDRESS_LOW _INCZ2
_INCZ2:
    __READ_ZERO_PAGE
    mov [dataRegister], al
    __NEXT_CYCLE _INCZ3
_INCZ3:
    __INC BYTE [dataRegister]
    __NEXT_CYCLE_STORE_RESULT

; INX - E8 - 2 Clocks - N Z
; ***************************
GLOBAL _INX
_INX:
    __INC BYTE [rX]
    __NEXT_CYCLE_FECTH_OPCODE

; SBC Imm - E9 #xx - 2 Clocks - N V C Z
; ***************************************
GLOBAL _SBCI
_SBCI:
    __FETCH_NEXT_BYTE
    __SBC

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

GLOBAL opcodes
opcodes:
    ;   0/8     1/9     2/A     3/B     4/C     5/D     6/E     7/F
    DD _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _ORAZ,  _NIMP,  _NIMP
    DD _PHP,   _ORAI,  _ASLRA, _NIMP,  _NIMP,  _NIMP,  _ASLA,  _NIMP    ; 0
    DD _BPL,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP
    DD _CLC,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _ASLAX, _NIMP    ; 1
    DD _JSRA,  _NIMP,  _NIMP,  _NIMP,  _BITZ,  _ANDZ,  _NIMP,  _NIMP
    DD _PLP,   _ANDI,  _ROLRA, _NIMP,  _NIMP,  _ANDA,  _NIMP,  _NIMP    ; 2
    DD _BMI,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP
    DD _SEC,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP    ; 3
    DD _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _EORZ,  _NIMP,  _NIMP
    DD _PHA,   _EORI,  _LSRRA, _NIMP,  _JMPA,  _NIMP,  _NIMP,  _NIMP    ; 4
    DD _BVC,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP
    DD _CLI,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP    ; 5
    DD _RTS,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _ADCZ,  _NIMP,  _NIMP
    DD _PLA,   _ADCI,  _RORRA, _NIMP,  _NIMP,  _ADCA,  _NIMP,  _NIMP    ; 6
    DD _BVS,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP
    DD _SEI,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _ADCAX, _NIMP,  _NIMP    ; 7
    DD _NIMP,  _NIMP,  _NIMP,  _NIMP,  _STYZ,  _STAZ,  _STXZ,  _NIMP
    DD _DEY,   _NIMP,  _TXA,   _NIMP,  _STYA,  _STAA,  _STXA,  _NIMP    ; 8
    DD _BCC,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _STAZX, _NIMP,  _NIMP
    DD _TYA,   _NIMP,  _TXS,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP    ; 9
    DD _LDYI,  _LDAIX, _LDXI,  _NIMP,  _LDYZ,  _LDAZ,  _LDXZ,  _NIMP
    DD _TAY,   _LDAI,  _TAX,   _NIMP,  _LDYA,  _LDAA,  _LDXA,  _NIMP    ; A
    DD _BCS,   _LDAIY, _NIMP,  _NIMP,  _NIMP,  _LDAZX, _NIMP,  _NIMP
    DD _NIMP,  _LDAAY, _TSX,   _NIMP,  _NIMP,  _LDAAX, _LDXAY, _NIMP    ; B
    DD _CPYI,  _NIMP,  _NIMP,  _NIMP,  _CPYZ,  _CMPZ,  _DECZ,  _NIMP
    DD _INY,   _CMPI,  _DEX,   _NIMP,  _NIMP,  _CMPA,  _NIMP,  _NIMP    ; C
    DD _BNE,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP
    DD _CLD,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP    ; D
    DD _CPXI,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _SBCZ,  _INCZ,  _NIMP
    DD _INX,   _SBCI,  _NOP,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP    ; E
    DD _BEQ,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP
    DD _SED,   _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP,  _NIMP    ; F

GLOBAL addressingModes
addressingModes:
    DB 0


SECTION .bss

GLOBAL nextCpuCycle, MNEMONIC
nextCpuCycle    RESD 1
MNEMONIC        RESD 1

GLOBAL ADDRESS, ADL, ADH
ADDRESS:
ADL             RESB 1
ADH             RESB 3      ; padding for 4 bytes

GLOBAL dataRegister
dataRegister    RESB 1

%IFNDEF RELEASE
opcode          RESB 1
%ENDIF
