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

; * TIA registers
; *****************
VSYNC		EQU 000h
VBLANK		EQU 001h
WSYNC		EQU 002h
RSYNC		EQU 003h
NUSIZ0		EQU 004h
NUSIZ1		EQU 005h
COLUP0		EQU 006h
COLUP1		EQU 007h
COLUPF		EQU 008h
COLUBK		EQU 009h
CTRLPF		EQU 00Ah
REFP0		EQU 00Bh
REFP1		EQU 00Ch
PF0			EQU 00Dh
PF1			EQU 00Eh
PF2			EQU 00Fh
RESP0		EQU 010h
RESP1		EQU 011h
RESM0		EQU 012h
RESM1		EQU 013h
RESBL		EQU 014h
AUDC0		EQU 015h
AUDC1		EQU 016h
AUDF0		EQU 017h
AUDF1		EQU 018h
AUDV0		EQU 019h
AUDV1		EQU 01Ah
GRP0		EQU 01Bh
GRP1		EQU 01Ch
ENAM0		EQU 01Dh
ENAM1		EQU 01Eh
ENABL		EQU 01Fh
HMP0		EQU 020h
HMP1		EQU 021h
HMM0		EQU 022h
HMM1		EQU 023h
HMBL		EQU 024h
VDELP0		EQU 025h
VDELP1		EQU 026h
VDELBL		EQU 027h
RESMP0		EQU 028h
RESMP1		EQU 029h
HMOVE		EQU 02Ah
HMCLR		EQU 02Bh
CXCLR		EQU 02Ch

; TIA registers bits
; ********************
VSYNC_BIT			EQU 002h
VBLANK_VERTBLANK	EQU 002h
VBLANK_ENALATCH		EQU 040h
VBLANK_DUMPPORT		EQU 080h
CTRLPF_REF			EQU 001h
CTRLPF_SCORE		EQU 002h
CTRLPF_PFP			EQU 004h
RESMP_BIT			EQU 002h
ENA_BIT				EQU 002h
REFP_BIT			EQU 008h
VDEL_BIT			EQU 001h

; * Collisions bits
; *******************
CXM0P1		EQU 080h
CXM0P0		EQU 040h
CXM1P0		EQU 080h
CXM1P1		EQU 040h
CXP0PF		EQU 080h
CXP0BL		EQU 040h
CXP1PF		EQU 080h
CXP1BL		EQU 040h
CXM0PF		EQU 080h
CXM0BL		EQU 040h
CXM1PF		EQU 080h
CXM1BL		EQU 040h
CXBLPF		EQU 080h
CXP0P1		EQU 080h
CXM0M1		EQU 040h
