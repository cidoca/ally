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
%INCLUDE "frame.inc"

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
    ret

; * Halts CPU until reaches the right edge of the screen - 02
; *************************************************************
GLOBAL _WSYNC
_WSYNC:
    mov BYTE [TIA+WSYNC], 1
    ret

GLOBAL _COLUP0
_COLUP0:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_P0], eax
    ret

GLOBAL _COLUP1
_COLUP1:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_P1], eax
    ret

GLOBAL _COLUPF
_COLUPF:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_PF], eax
    ret

GLOBAL _COLUBK
_COLUBK:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_BK], eax
    ret

GLOBAL _CTRLPF
_CTRLPF:
    mov BYTE [TIA+CTRLPF], al
    mov cl, al
    shr cl, 4
    and cl, 3
    mov al, 1
    shl al, cl
    mov [SIZE_BL], al
    ret

GLOBAL _RESBL
_RESBL:
    mov al, [CLOCKCOUNTS]
    cmp al, 68
    jb RBL0
    ;add al, 4         ; ????????????
    ;add al, [SIZE_BL] ; ????????????
    mov [POSITION_BL], al
    ret
RBL0:
    mov BYTE [POSITION_BL], 68
    ret

; * 
GLOBAL _HMOVE
_HMOVE:
    mov al, [TIA+HMBL]
    sar al, 4
    sub [POSITION_BL], al
    ;mov BYTE [TIA+HMOVE], 1
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
    DD _WREG,   _WREG,   _WSYNC,  _RNIMP,  _WREG,   _WREG,   _COLUP0, _COLUP1
    DD _COLUPF, _COLUBK, _CTRLPF, _WREG,   _WREG,   _WREG,   _WREG,   _WREG     ; 0
    DD _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RESBL,  _WREG,   _WREG,   _WREG
    DD _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG     ; 1
    DD _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _WREG
    DD _WREG,   _WREG,   _HMOVE,  _HMCLR,  _CXCLR,  _RNIMP,  _RNIMP,  _RNIMP    ; 2
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
