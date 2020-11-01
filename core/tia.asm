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
%IFNDEF RELEASE
    push rdi
    push rsi
    mov rdi, rsi
    call readingInvalidTIA
    pop rsi
    pop rdi
%ENDIF
    and esi, 0Fh
    cmp esi, 0Dh
    ja readInvalidTIA
    mov al, [COLLISION+rsi]
    ret
readInvalidTIA:
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

; * 04
GLOBAL _NUSIZ0
_NUSIZ0:
    mov cl, al
    shr cl, 4
    and cl, 3
    mov dl, 1
    shl dl, cl
    mov [SIZE_M0], dl
    and eax, 7
    mov dl, [GRP_COPIES+rax]
    mov [COPIES_P0], dl
    mov dl, [GRP_SIZES+rax]
    mov [SIZE_P0], dl
    mov al, [GRP_SPACES+rax]
    mov [SPACE_P0], al
    ret

; * 05
GLOBAL _NUSIZ1
_NUSIZ1:
    mov cl, al
    shr cl, 4
    and cl, 3
    mov dl, 1
    shl dl, cl
    mov [SIZE_M1], dl
    and eax, 7
    mov dl, [GRP_COPIES+rax]
    mov [COPIES_P1], dl
    mov dl, [GRP_SIZES+rax]
    mov [SIZE_P1], dl
    mov al, [GRP_SPACES+rax]
    mov [SPACE_P1], al
    ret

; * 06
GLOBAL _COLUP0
_COLUP0:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_P0], eax
    ret

; * 07
GLOBAL _COLUP1
_COLUP1:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_P1], eax
    ret

; * 08
GLOBAL _COLUPF
_COLUPF:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    ;mov [PRE_COLOR_PF], eax
    mov [COLOR_PF], eax
    ret

; * 09
GLOBAL _COLUBK
_COLUBK:
    and eax, 0FEh
    mov eax, [PALETTE+eax*2]
    mov [COLOR_BK], eax
    ret

; * 0A
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

; * 10
GLOBAL _RESP0
_RESP0:
    mov al, [CLOCKCOUNTS]
    cmp al, 68
    jb RP00
    add al, 5         ; ????????????
    mov [POSITION_P0], al
    ret
RP00:
    mov BYTE [POSITION_P0], 68 + 3 ; ????????????
    ret

; * 11
GLOBAL _RESP1
_RESP1:
    mov al, [CLOCKCOUNTS]
    cmp al, 68
    jb RP10
    add al, 5         ; ????????????
    mov [POSITION_P1], al
    ret
RP10:
    mov BYTE [POSITION_P1], 68 + 3 ; ????????????
    ret

; * 12
GLOBAL _RESM0
_RESM0:
    test BYTE [TIA+RESMP0], RESMP_BIT
    jnz RM01
    mov al, [CLOCKCOUNTS]
    cmp al, 68
    jb RM00
    add al, 4         ; ????????????
    mov [POSITION_M0], al
    ret
RM00:
    mov BYTE [POSITION_M0], 68 + 2 ; ????????????
RM01:
    ret

; * 13
GLOBAL _RESM1
_RESM1:
    test BYTE [TIA+RESMP1], RESMP_BIT
    jnz RM11
    mov al, [CLOCKCOUNTS]
    cmp al, 68
    jb RM10
    add al, 4         ; ????????????
    mov [POSITION_M1], al
    ret
RM10:
    mov BYTE [POSITION_M1], 68 + 2 ; ??????????????????
RM11:
    ret

; * 14
GLOBAL _RESBL
_RESBL:
    mov al, [CLOCKCOUNTS]
    cmp al, 68
    jb RBL0
    add al, 4         ; ????????????
    mov [POSITION_BL], al
    ret
RBL0:
    mov BYTE [POSITION_BL], 68 + 2 ; ??????????????????
    ret

; * 1B
GLOBAL _GRP0
_GRP0:
    test BYTE [TIA+VDELP0], VDEL_BIT
    jnz GRP0_0
    mov [GRP0B], al
GRP0_0:
    mov [GRP0A], al
GRP0_1:
    test BYTE [TIA+VDELP1], VDEL_BIT
    jz GRP0_2
    mov al, [GRP1A]
    mov [GRP1B], al
GRP0_2:
    ret

; * 1C
GLOBAL _GRP1
_GRP1:
    test BYTE [TIA+VDELP1], VDEL_BIT
    jnz GRP1_0
    mov [GRP1B], al
GRP1_0:
    mov [GRP1A], al
GRP1_1:
    test BYTE [TIA+VDELP0], VDEL_BIT
    jz GRP1_2
    mov al, [GRP0A]
    mov [GRP0B], al
GRP1_2:
    test BYTE [TIA+VDELBL], VDEL_BIT
    jz GRP1_3
    mov al, [ENABLE_BLA]
    mov [ENABLE_BLB], al
GRP1_3:
    ret

; * 1F
GLOBAL _ENABL
_ENABL:
    test BYTE [TIA+VDELBL], 1
    jz EB0
    mov BYTE [ENABLE_BLA], al
    ret
EB0:
    mov BYTE [ENABLE_BLB], al
    ret

; * 25
GLOBAL _VDELP0
_VDELP0:
    mov [TIA+VDELP0], al
    mov al, [GRP0A]
    mov [GRP0B], al
    ret

; * 26
GLOBAL _VDELP1
_VDELP1:
    mov [TIA+VDELP1], al
    mov al, [GRP1A]
    mov [GRP1B], al
    ret

; * 28
GLOBAL _RESMP0
_RESMP0:
    mov [TIA+RESMP0], al
    test al, RESMP_BIT
    jz RMP0
    mov al, [POSITION_P0]
    add al, 4
    mov [POSITION_M0], al
RMP0:
    ret

; * 29
GLOBAL _RESMP1
_RESMP1:
    mov [TIA+RESMP1], al
    test al, RESMP_BIT
    jz RMP1
    mov al, [POSITION_P1]
    add al, 4
    mov [POSITION_M1], al
RMP1:
    ret

; * 2A
GLOBAL _HMOVE
_HMOVE:
    mov al, [TIA+HMP0]
    sar al, 4
    sub [POSITION_P0], al

    test BYTE [TIA+RESMP0], RESMP_BIT
    jz HM0
    mov al, [POSITION_P0]
    add al, 4
    mov [POSITION_M0], al
    jmp HM1
HM0:
    mov al, [TIA+HMM0]
    sar al, 4
    sub [POSITION_M0], al
HM1:

    mov al, [TIA+HMP1]
    sar al, 4
    sub [POSITION_P1], al

    test BYTE [TIA+RESMP1], RESMP_BIT
    jz HM2
    mov al, [POSITION_P1]
    add al, 4
    mov [POSITION_M1], al
    jmp HM3
HM2:
    mov al, [TIA+HMM1]
    sar al, 4
    sub [POSITION_M1], al
HM3:

    mov al, [TIA+HMBL]
    sar al, 4
    sub [POSITION_BL], al

    cmp BYTE [CLOCKCOUNTS], 68
    jae HM4
    mov BYTE [TIA+HMOVE], 1
HM4:
    ret

; 15/16
GLOBAL _AUDCX
_AUDCX:
    and al, 0Fh
    mov [TIA+rsi], al
    ret

; 17/18
GLOBAL _AUDFX
_AUDFX:
    and al, 01Fh
    inc al
    mov [TIA+rsi], al
    ret

; 19/1A
GLOBAL _AUDVX
_AUDVX:
    and al, 0Fh
    shl al, 1
    mov [TIA+rsi], al
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
    DD _WREG,   _WREG,   _WSYNC,  _RNIMP,  _NUSIZ0, _NUSIZ1, _COLUP0, _COLUP1
    DD _COLUPF, _COLUBK, _CTRLPF, _WREG,   _WREG,   _WREG,   _WREG,   _WREG     ; 0
    DD _RESP0,  _RESP1,  _RESM0,  _RESM1,  _RESBL,  _AUDCX,  _AUDCX,  _AUDFX
    DD _AUDFX,  _AUDVX,  _AUDVX,  _GRP0,   _GRP1,   _WREG,   _WREG,   _ENABL    ; 1
    DD _WREG,   _WREG,   _WREG,   _WREG,   _WREG,   _VDELP0, _VDELP1, _WREG
    DD _RESMP0, _RESMP1, _HMOVE,  _HMCLR,  _CXCLR,  _RNIMP,  _RNIMP,  _RNIMP    ; 2
    DD _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP
    DD _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP,  _RNIMP    ; 3

GLOBAL GRP_COPIES, GRP_SIZES, GRP_SPACES
GRP_COPIES      DB 1, 2, 2, 3, 2, 1, 3, 1
GRP_SIZES       DB 8, 8, 8, 8, 8, 16, 8, 32
GRP_SPACES      DB 0, 16, 32, 16, 64, 0, 32, 0

SECTION .bss

GLOBAL COLLISION, INPT4, INPT5
COLLISION   RESB 8
INPT0_3     RESB 4
INPT4       RESB 1
INPT5       RESB 1

GLOBAL TIA
TIA         RESB 48
