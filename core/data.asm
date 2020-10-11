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


SECTION .bss

GLOBAL programCounter, PCL, PCH
programCounter:
PCL     RESB 1
PCH     RESB 3      ; padding for 4 bytes

GLOBAL rA, rX, rY, rS
rA      RESB 1
rX      RESB 1
rY      RESB 1
rS      RESB 1

GLOBAL flagN, flagV, flagD, flagI, flagZ, flagC
flagN   RESB 1
flagV   RESB 1
flagD   RESB 1
flagI   RESB 1
flagZ   RESB 1
flagC   RESB 1
