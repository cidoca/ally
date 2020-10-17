; Ally, A Atari 2600 emulator
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

%IFNDEF RELEASE
EXTERN readingInvalidTIA, writingInvalidTIA
%ENDIF

%INCLUDE "tia_registers.inc"
EXTERN CLOCKO2, CLOCKCOUNTS, SCANLINE

SECTION .text

; * Initialize TIA
; *******************
GLOBAL initTIA
initTIA:
    xor rax, rax
    mov [COLLISION], rax
    mov [INPT0_3], eax
    mov WORD [INPT4], 08080h

    mov BYTE [CLOCKO2], 1
    mov BYTE [CLOCKCOUNTS], 0
    ret

; * Read from TIA registers 00h - 0Dh
; *************************************
GLOBAL readTIA
readTIA:
    and esi, 03Fh
    cmp esi, 0Dh
    ja readInvalidTIA
    mov al, [COLLISION+rsi]
    ret
readInvalidTIA:
%IFNDEF RELEASE
    push rdi
    mov rdi, rsi
    call readingInvalidTIA
    pop rdi
%ENDIF
    mov al, 0
    ret

; * Write to TIA registers 000h - 02Ch
; **************************************
GLOBAL writeTIA
writeTIA:
    and esi, 03Fh
%IFNDEF RELEASE
    push rax
    push rdi
    push rsi
    mov rdi, rsi
    mov rsi, rax
    call writingInvalidTIA
    pop rsi
    pop rdi
    pop rax
%ENDIF
    mov edx, [TIA_REGISTERS+rsi*4]
    jmp rdx

; * TIA register not implemented
; ********************************
GLOBAL _RNIMP
_RNIMP:
    ret

; * Writes data to a specific TIA register
; ******************************************
GLOBAL _WREG
_WREG:
    mov [TIA+rsi], al
;%IFNDEF RELEASE
;    push rdi
;    mov rdi, rsi
;    mov rsi, rax
;    call writingInvalidTIA
;    pop rdi
;%ENDIF
    ret

; * Halts CPU until reaches the right edge of the screen - 02
; *************************************************************
GLOBAL _WSYNC
_WSYNC:
    mov BYTE [TIA+WSYNC], 1
    ret

; * Clears all horizontal motion registers to zero (no motion) - 2B
; *******************************************************************
GLOBAL _HMCLR
_HMCLR:
    xor eax, eax
    mov DWORD [TIA+HMP0], eax
    mov [TIA+HMBL], al
    ret

; * Clears all collision latches to zero (no collision) - 2C
; ************************************************************
GLOBAL _CXCLR
_CXCLR:
    xor rax, rax
    mov [COLLISION], rax
    ret


SECTION .data

GLOBAL TIA_REGISTERS
TIA_REGISTERS:
    ;    0/8      1/9      2/A      3/B      4/C      5/D      6/E      7/F
    DD _WREG,   _WREG,   _WSYNC,  _RNIMP,  _WREG,   _WREG,   _WREG,   _WREG
    DD _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG     ; 0
    DD _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _WREG,   _WREG,   _WREG
    DD _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG     ; 1
    DD _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG
    DD _WREG,   _WREG,   _RNIMP,  _HMCLR,  _CXCLR,  _RNIMP,  _RNIMP,  _RNIMP    ; 2
    DD _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP
    DD _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP    ; 3


SECTION .bss

GLOBAL COLLISION, INPT4, INPT5
COLLISION   RESB 8
INPT0_3     RESB 4
INPT4       RESB 1
INPT5       RESB 1

GLOBAL TIA
TIA         RESB 48
