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

%INCLUDE "tia.inc"
%INCLUDE "tia_registers.inc"

BUFFERSIZE EQU 31440 / 60

SECTION .text

GLOBAL initSound
initSound:
    xor eax, eax
    mov [SIGNAL], al
    inc eax
    mov [PERIOD0], eax
    mov [PERIOD1], eax
;    mov pPoly0, eax
;    mov pPoly1, eax
;    mov p2Poly0, eax
 ;   mov p2Poly1, eax
    ret

GLOBAL fillSoundBuffer
fillSoundBuffer:
    push rbx
    mov eax, 80808080h
    mov ecx, BUFFERSIZE / 2
    mov rdi, rsi
    rep stosd

    ; Apply all masks here, instead of in tia.asm

    ; Channel 1
    mov ah, 1
    mov al, [TIA+AUDV0]
    movzx ebx, BYTE [TIA+AUDF0]
    mov ecx, BUFFERSIZE
    movzx edx, BYTE [TIA+AUDC0]
    mov r8d, [TIA_SOUND+rdx*4]
    mov edx, [PERIOD0]
    mov rdi, rsi
    call r8
    mov [PERIOD0], edx

    ; Channel 2
    mov ah, 2
    mov al, [TIA+AUDV1]
    movzx ebx, BYTE [TIA+AUDF1]
    mov ecx, BUFFERSIZE
    movzx edx, BYTE [TIA+AUDC1]
    mov r8d, [TIA_SOUND+rdx*4]
    mov edx, [PERIOD1]
    mov rdi, rsi
    inc rdi
    call r8
    mov [PERIOD1], edx

    pop rbx
    ret

GLOBAL _XXX
_XXX:
    ret

GLOBAL _DIV2:
_DIV2:
    test [SIGNAL], ah
    jz _DIV2_1
    neg al
_DIV2_1:
    add [rdi], al
    inc rdi
    inc rdi
    dec edx
    jnz _DIV2_2
    neg al
    xor [SIGNAL], ah
    movzx edx, bl
_DIV2_2:
    loop _DIV2_1
    ret

GLOBAL _DIV6:
_DIV6:
    imul ebx, ebx, 3
    jmp _DIV2

GLOBAL _DIV31:
_DIV31:
    imul ebx, ebx, 15
    jmp _DIV2

GLOBAL _DIV93:
_DIV93:
    imul ebx, ebx, 46
    jmp _DIV2

SECTION .data

GLOBAL TIA_SOUND
TIA_SOUND:
    DD _XXX,  _XXX,  _XXX,  _XXX,  _DIV2,  _DIV2,  _DIV31,  _XXX
    DD _XXX,  _XXX,  _XXX,  _XXX,  _DIV6,  _DIV6,  _DIV93,  _XXX
;    DD Nada, P4BIT, D15P4, P5B4B, DIV2, DIV2, DIV31, P5BIT
;    DD P9BIT, P5BIT, DIV31, Nada, DIV6, DIV6, DIV93, P5D6

GLOBAL POLY4, POLY5, Div15
POLY4   DB 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0
POLY5   DB 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0
        DB 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0
Div15   DB 0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0


SECTION .bss

GLOBAL SIGNAL, PERIOD0, PERIOD1, pPoly0, pPoly1, p2Poly0, p2Poly1
PERIOD0     RESD 1
PERIOD1     RESD 1
pPoly0      RESD 1
pPoly1      RESD 1
p2Poly0     RESD 1
p2Poly1     RESD 1
SIGNAL      RESB 1
