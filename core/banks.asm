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

SECTION .text

readTIA:
    mov al, 0
    ret

writeTIA:
    ret

; * Read memory
; ***************
GLOBAL readMemory
readMemory:
    and esi, 01FFFh
    test esi, 01000h
    jnz readROM
    test esi, 00080h
    jz readTIA
    test esi, 00200h
    jz readRAM
    test esi, 00004h
    jnz readTimer
    jmp readIO
readROM:
    mov al, [ROM+rsi-01000h]
    ret


; * Write memory
; ****************
GLOBAL writeMemory
writeMemory:
    and esi, 01FFFh
    test esi, 01000h
    jnz writeROM
    test esi, 00080h
    jz writeTIA
    test esi, 00200h
    jz writeRAM
    test esi, 00004h
    jnz writeTimer
    jmp writeIO
writeROM:
    ret


SECTION .bss

GLOBAL ROM
ROM     RESB 32768
