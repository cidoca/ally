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
%ENDIF

%INCLUDE "cpu.inc"
%INCLUDE "riot.inc"
%INCLUDE "tia.inc"
%INCLUDE "tia_registers.inc"

SECTION .text

; * Draw Playfield
; ******************
GLOBAL drawPlayfiled
drawPlayfiled:
%IFNDEF RELEASE
    test BYTE [_pf], 1
    jz PFX
%ENDIF
    movzx edx, BYTE [CLOCKCOUNTS]
    sub edx, 68
    shr edx, 2
    test BYTE [TIA+CTRLPF], CTRLPF_REF
    jnz PF_REF
    mov edx, [PLAYFIELD_TABLE+edx*4]
    jmp PF_TEST
PF_REF:
    mov edx, [PLAYFIELD_TABLE_REF+edx*4]
PF_TEST:
    test DWORD [TIA+PF0], edx
    jz PFX
    test BYTE [TIA+CTRLPF], CTRLPF_SCORE
    jnz PF_P
    mov eax, [COLOR_PF]
    jmp PFX
PF_P:
    cmp BYTE [CLOCKCOUNTS], 68 + 80
    jae PF_P1
    mov eax, [COLOR_P0]
    jmp PFX
PF_P1:
    mov eax, [COLOR_P1]
PFX:
    ret

; * Render one frame
; ********************
GLOBAL scanFrame, NTC
scanFrame:
%IFNDEF RELEASE
    mov eax, 0FF00h
    mov ecx, 228 * 320
    push rdi
    rep stosd
    pop rdi
%ENDIF

    movzx eax, BYTE [CLOCKCOUNTS]
    shl eax, 2
    add rdi, rax

    mov BYTE [TIA+VSYNC], 0
    mov DWORD [SCANLINE], 0

newLine:

pulseTIA:
    test BYTE [TIA+VSYNC], VSYNC_BIT        ; New frame
    jnz endFrame
    jmp drawBG
CNT:    

    dec BYTE [CLOCKO2]
    jnz NTC2
    mov BYTE [CLOCKO2], 3
    call nextTimerCycle

    test BYTE [TIA+WSYNC], 1
    jnz NTC
    mov edx, [nextCpuCycle]
    jmp rdx

NTC:

NTC2:
    inc BYTE [CLOCKCOUNTS]
    cmp BYTE [CLOCKCOUNTS], 228
    jb pulseTIA
    mov BYTE [CLOCKCOUNTS], 0
    mov BYTE [TIA+WSYNC], 0
%IFNDEF RELEASE
    mov BYTE [TIA+HMOVE], 0
%ENDIF

    inc DWORD [SCANLINE]
    cmp DWORD [SCANLINE], 320
    jb newLine

endFrame:
    ret

drawBG:
    mov eax, [COLOR_BK]                 ; Background color
    
    cmp BYTE [CLOCKCOUNTS], 68
    jb DBG1

    ;mov dl, [CLOCKCOUNTS]
    ;sub dl, 68
    ;test dl, 07h
    ;jnz DBG0
    ;mov edx, [PRE_COLOR_PF]
    ;mov [COLOR_PF], edx
DBG0:

    test BYTE [TIA+CTRLPF], CTRLPF_PFP
    jnz PFA
    call drawPlayfiled
PFA:

    ; Ball
%IFNDEF RELEASE
    test BYTE [_bl], 1
    jz BLX
%ENDIF
    test BYTE [ENABLE_BLB], ENA_BIT
    jz BLX
    mov dl, [POSITION_BL]
    cmp [CLOCKCOUNTS], dl
    jb BLX
    add dl, [SIZE_BL]
    cmp [CLOCKCOUNTS], dl
    jae BLX
    mov eax, [COLOR_PF]
BLX:

    ; Player 1
    mov dl, [POSITION_P1]
    cmp [CLOCKCOUNTS], dl
    jb P1X
    add dl, [SIZE_P1]
    cmp [CLOCKCOUNTS], dl
    jae P1X
    mov cl, [SIZE_P1]
    shr cl, 4
    sub dl, [CLOCKCOUNTS]
    dec dl
    shr dl, cl
    mov cl, dl
    mov dl, 1
    shl dl, cl
    test [GRP1B], dl
    jz P1X
    mov eax, [COLOR_P1]
P1X:

    ; Player 1-2
    cmp BYTE [COPIES_P1], 2
    jb P12X
    mov dl, [POSITION_P1]
    add dl, [SPACES_P1]
    cmp [CLOCKCOUNTS], dl
    jb P12X
    add dl, [SIZE_P1]
    cmp [CLOCKCOUNTS], dl
    jae P12X
    mov cl, [SIZE_P1]
    shr cl, 4
    sub dl, [CLOCKCOUNTS]
    dec dl
    shr dl, cl
    mov cl, dl
    mov dl, 1
    shl dl, cl
    test [GRP1B], dl
    jz P12X
    mov eax, [COLOR_P1]
P12X:

    ; Player 1-3
    cmp BYTE [COPIES_P1], 3
    jb P13X
    mov dl, [POSITION_P1]
    mov cl, [SPACES_P1]
    add dl, cl
    add dl, cl
    cmp [CLOCKCOUNTS], dl
    jb P13X
    add dl, [SIZE_P1]
    cmp [CLOCKCOUNTS], dl
    jae P13X
    mov cl, [SIZE_P1]
    shr cl, 4
    sub dl, [CLOCKCOUNTS]
    dec dl
    shr dl, cl
    mov cl, dl
    mov dl, 1
    shl dl, cl
    test [GRP1B], dl
    jz P13X
    mov eax, [COLOR_P1]
P13X:

    ; Missile 1
%IFNDEF RELEASE
    test BYTE [_m1], 1
    jz M1X
%ENDIF
    test BYTE [TIA+ENAM1], ENA_BIT
    jz M1X
    test BYTE [TIA+RESMP1], RESMP_BIT
    jnz M1X
    mov dl, [POSITION_M1]
    cmp [CLOCKCOUNTS], dl
    jb M1X
    add dl, [SIZE_M1]
    cmp [CLOCKCOUNTS], dl
    jae M1X
    mov eax, [COLOR_P1]
M1X:

    ; Player 0
    mov dl, [POSITION_P0]
    cmp [CLOCKCOUNTS], dl
    jb P0X
    add dl, [SIZE_P0]
    cmp [CLOCKCOUNTS], dl
    jae P0X
    mov cl, [SIZE_P0]
    shr cl, 4
    sub dl, [CLOCKCOUNTS]
    dec dl
    shr dl, cl
    mov cl, dl
    mov dl, 1
    shl dl, cl
    test [GRP0B], dl
    jz P0X
    mov eax, [COLOR_P0]
P0X:

    ; Player 0-2
    cmp BYTE [COPIES_P0], 2
    jb P02X
    mov dl, [POSITION_P0]
    add dl, [SPACES_P0]
    cmp [CLOCKCOUNTS], dl
    jb P02X
    add dl, [SIZE_P0]
    cmp [CLOCKCOUNTS], dl
    jae P02X
    mov cl, [SIZE_P0]
    shr cl, 4
    sub dl, [CLOCKCOUNTS]
    dec dl
    shr dl, cl
    mov cl, dl
    mov dl, 1
    shl dl, cl
    test [GRP0B], dl
    jz P02X
    mov eax, [COLOR_P0]
P02X:

    ; Player 0-3
    cmp BYTE [COPIES_P0], 3
    jb P03X
    mov dl, [POSITION_P0]
    mov cl, [SPACES_P0]
    add dl, cl
    add dl, cl
    cmp [CLOCKCOUNTS], dl
    jb P03X
    add dl, [SIZE_P0]
    cmp [CLOCKCOUNTS], dl
    jae P03X
    mov cl, [SIZE_P0]
    shr cl, 4
    sub dl, [CLOCKCOUNTS]
    dec dl
    shr dl, cl
    mov cl, dl
    mov dl, 1
    shl dl, cl
    test [GRP0B], dl
    jz P03X
    mov eax, [COLOR_P0]
P03X:

    ; Missile 0
%IFNDEF RELEASE
    test BYTE [_m0], 1
    jz M0X
%ENDIF
    test BYTE [TIA+ENAM0], ENA_BIT
    jz M0X
    test BYTE [TIA+RESMP0], RESMP_BIT
    jnz M0X
    mov dl, [POSITION_M0]
    cmp [CLOCKCOUNTS], dl
    jb M0X
    add dl, [SIZE_M0]
    cmp [CLOCKCOUNTS], dl
    jae M0X
    mov eax, [COLOR_P0]
M0X:

    test BYTE [TIA+CTRLPF], CTRLPF_PFP
    jz PFB
    call drawPlayfiled
PFB:

DBG1:

%IFNDEF RELEASE
    test BYTE [TIA+VBLANK], VBLANK_VERTBLANK
    jnz PURPLE
    cmp BYTE [CLOCKCOUNTS], 68 + 8
    jae DBG2
    test BYTE [TIA+HMOVE], 1
    jnz PURPLE
    cmp BYTE [CLOCKCOUNTS], 68
    jae DBG2

PURPLE:
    mov edx, eax
    shr edx, 16
    add edx, 0FFh
    shr edx, 1
    mov esi, edx
    shl esi, 8

    mov edx, eax
    shr edx, 8
    and edx, 0FFh
    shr edx, 1
    or esi, edx
    shl esi, 8

    and eax, 0FFh
    add eax, 0FFh
    shr eax, 1
    or eax, esi
%ENDIF

DBG2:
    mov [rdi], eax
    add rdi, 4

    jmp CNT


SECTION .data

GLOBAL PALETTE
PALETTE:
    DD 0000000h, 0404040h, 0686C68h, 0909090h, 0B0B0B0h, 0C8C8C8h, 0D8DCD8h, 0E8ECE8h
    DD 0404400h, 0606410h, 0808420h, 0A0A030h, 0B8B840h, 0D0D050h, 0E8E858h, 0F8FC68h
    DD 0702800h, 0804410h, 0985C28h, 0A87838h, 0B88C48h, 0C8A058h, 0D8B468h, 0E8C878h
    DD 0801800h, 0983418h, 0A85030h, 0C06848h, 0D08058h, 0E09470h, 0E8A880h, 0F8BC90h
    DD 0880000h, 0982020h, 0B03C38h, 0C05858h, 0D07070h, 0E08888h, 0E8A0A0h, 0F8B4B0h
    DD 0780058h, 0882070h, 0A03C88h, 0B05898h, 0C070B0h, 0D084C0h, 0D89CD0h, 0E8B0E0h
    DD 0480078h, 0602090h, 0783CA0h, 08858B8h, 0A070C8h, 0B084D8h, 0C09CE8h, 0D0B0F8h
    DD 0100080h, 0302098h, 0483CA8h, 06858C0h, 07870D0h, 09088E0h, 0A8A0E8h, 0B8B4F8h
    DD 0000088h, 0182098h, 03840B0h, 0505CC0h, 06874D0h, 0788CE0h, 090A4E8h, 0A0B8F8h
    DD 0001878h, 0183890h, 03854A8h, 05070B8h, 06888C8h, 0789CD8h, 090B4E8h, 0A0C8F8h
    DD 0002C58h, 0184C78h, 0386890h, 05084A8h, 0689CC0h, 078B4D0h, 090CCE8h, 0A0E0F8h
    DD 0003C28h, 0185C48h, 0387C60h, 0509C80h, 068B490h, 078D0A8h, 090E4C0h, 0A0FCD0h
    DD 0003C00h, 0205C20h, 0407C40h, 0589C58h, 070B470h, 088D088h, 0A0E4A0h, 0B8FCB8h
    DD 0103800h, 0305C18h, 0507C38h, 0689850h, 080B468h, 098CC78h, 0B0E490h, 0C8FCA0h
    DD 0283000h, 0485018h, 0687030h, 0808C48h, 098A860h, 0B0C078h, 0C8D488h, 0E0EC98h
    DD 0402800h, 0604818h, 0806830h, 0A08440h, 0B89C58h, 0D0B468h, 0E8CC78h, 0F8E088h

GLOBAL PLAYFIELD_MASK
PLAYFIELD_TABLE:
    DD 000010h, 000020h, 000040h, 000080h
    DD 008000h, 004000h, 002000h, 001000h, 000800h, 000400h, 000200h, 000100h
    DD 010000h, 020000h, 040000h, 080000h, 100000h, 200000h, 400000h, 800000h
    DD 000010h, 000020h, 000040h, 000080h
    DD 008000h, 004000h, 002000h, 001000h, 000800h, 000400h, 000200h, 000100h
    DD 010000h, 020000h, 040000h, 080000h, 100000h, 200000h, 400000h, 800000h

GLOBAL PLAYFIELD_TABLE_REF
PLAYFIELD_TABLE_REF:
    DD 000010h, 000020h, 000040h, 000080h
    DD 008000h, 004000h, 002000h, 001000h, 000800h, 000400h, 000200h, 000100h
    DD 010000h, 020000h, 040000h, 080000h, 100000h, 200000h, 400000h, 800000h
    DD 800000h, 400000h, 200000h, 100000h, 080000h, 040000h, 020000h, 010000h
    DD 000100h, 000200h, 000400h, 000800h, 001000h, 002000h, 004000h, 008000h
    DD 000080h, 000040h, 000020h, 000010h

SECTION .bss

GLOBAL SCANLINE, CLOCKCOUNTS, CLOCKO2
SCANLINE    RESD 1
CLOCKCOUNTS RESB 1
CLOCKO2     RESB 1

GLOBAL COLOR_P0, COLOR_P1, COLOR_PF, COLOR_BK
COLOR_P0    RESD 1
COLOR_P1    RESD 1
COLOR_PF    RESD 1
COLOR_BK    RESD 1

;GLOBAL PRE_COLOR_PF
;PRE_COLOR_PF RESD 1

GLOBAL POSITION_P0, GRP0A, GRP0B, COPIES_P0, SIZE_P0, SPACES_P0
GRP0A       RESB 1
GRP0B       RESB 1
POSITION_P0 RESB 1
COPIES_P0   RESB 1
SIZE_P0     RESB 1
SPACES_P0   RESB 1

GLOBAL POSITION_P1, GRP1A, GRP1B, COPIES_P1, SIZE_P1, SPACES_P1
GRP1A       RESB 1
GRP1B       RESB 1
POSITION_P1 RESB 1
COPIES_P1   RESB 1
SIZE_P1     RESB 1
SPACES_P1   RESB 1

GLOBAL POSITION_M0, SIZE_M0
POSITION_M0 RESB 1
SIZE_M0     RESB 1

GLOBAL POSITION_M1, SIZE_M1
POSITION_M1 RESB 1
SIZE_M1     RESB 1

GLOBAL POSITION_BL, SIZE_BL, ENABLE_BLA, ENABLE_BLB
POSITION_BL RESB 1
SIZE_BL     RESB 1
ENABLE_BLA  RESB 1
ENABLE_BLB  RESB 1

%IFNDEF RELEASE
GLOBAL _pf, _bl, _m0, _m1
_pf  RESB 1
_bl  RESB 1
_m0  RESB 1
_m1  RESB 1
%ENDIF
