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


%INCLUDE "riot.inc"
%INCLUDE "tia.inc"

SECTION .text

; * Read from 2K ROM
; ********************
GLOBAL readROM2K
readROM2K:
    and esi, 07FFh
    mov al, [ROM+rsi]
    ret

; * Read from 4K ROM
; ********************
GLOBAL readROM4K
readROM4K:
    mov al, [ROM+rsi]
    ret

; * Write to 2K or 4K ROM
; *************************
GLOBAL writeROM2_4K
writeROM2_4K:
    ret

; * Read from 8K ROM
; ********************
GLOBAL readROM8K
readROM8K:
    cmp esi, 0FF8h
    jb RB8
    cmp esi, 0FF9h
    ja RB8

    mov eax, esi
    sub eax, 0FF8h
    shl eax, 12
    add eax, ROM
    mov [BANK_PTR], eax

RB8:
    add esi, [BANK_PTR]
    mov al, [rsi]
    ret

; * Write to 8K ROM
; *******************
GLOBAL writeROM8K
writeROM8K:
    cmp esi, 0FF8h
    jb WB8
    cmp esi, 0FF9h
    ja WB8

    mov eax, esi
    sub eax, 0FF8h
    shl eax, 12
    add eax, ROM
    mov [BANK_PTR], eax

WB8:
    ret

; * Setup ROM banks
; *******************
GLOBAL setupBanks
setupBanks:
    cmp edi, 0800h      ; 2K
    jne SB0
    mov DWORD [READ_ROM], readROM2K
    mov DWORD [WRITE_ROM], writeROM2_4K
    mov DWORD [BANK_PTR], ROM
    ret
SB0:
    cmp edi, 1000h      ; 4K
    jne SB1
    mov DWORD [READ_ROM], readROM4K
    mov DWORD [WRITE_ROM], writeROM2_4K
    mov DWORD [BANK_PTR], ROM
    ret
SB1:
    cmp edi, 2000h      ; 8K
    jne SB_ERROR
    mov DWORD [READ_ROM], readROM8K
    mov DWORD [WRITE_ROM], writeROM8K
    mov DWORD [BANK_PTR], ROM + 1000h
    ret
SB_ERROR:
    xor eax, eax
    ret

; * Read memory
; ***************
GLOBAL readMemory
readMemory:
    and esi, 01FFFh
    test esi, 01000h
    jz RM
    and esi, 0FFFh
    mov edx, [READ_ROM]
    jmp rdx
RM:
    test esi, 00080h
    jz readTIA
    test esi, 00200h
    jz readRAM
    test esi, 00004h
    jnz readTimer
    jmp readIO

; * Write memory
; ****************
GLOBAL writeMemory
writeMemory:
    and esi, 01FFFh
    test esi, 01000h
    jz WM
    and esi, 0FFFh
    mov edx, [WRITE_ROM]
    jmp rdx
WM:
    test esi, 00080h
    jz writeTIA
    test esi, 00200h
    jz writeRAM
    test esi, 00004h
    jnz writeTimer
    jmp writeIO


SECTION .bss

GLOBAL READ_ROM, WRITE_ROM, BANK_PTR, ROM
READ_ROM    RESD 1
WRITE_ROM   RESD 1
BANK_PTR    RESD 1
ROM         RESB 32768
