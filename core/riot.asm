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
EXTERN writingIO, readingIntFlag, writingEdgeDetectControl
%ENDIF

SECTION .text

; * Initialize RIOT
; *******************
GLOBAL initRIOT
initRIOT:
    mov BYTE [PORTA], 0FFh
    mov BYTE [DDRA], 0
    mov BYTE [PORTB], 03Fh
    mov BYTE [DDRB], 0
    mov DWORD [TIMER], 0FFFFFFFFh
    mov BYTE [TIMER_DIV], 0
    mov BYTE [TIMER_FLAG], 0
    ret

; * Decrement timer and update interrupt flag
; *********************************************
GLOBAL nextTimerCycle
nextTimerCycle:
    ; TODO: After interrupt flag, don't cross 0
    dec DWORD [TIMER]
    jns NTC

    mov BYTE [TIMER_DIV], 0
    or BYTE [TIMER_FLAG], 080h

NTC:ret

; * Read from memory RAM 080h - 0FFh
; ************************************
GLOBAL readRAM
readRAM:
    and esi, 07Fh
    mov al, [RAM+rsi]
    ret

; * Write to memory RAM 080h - 0FFh
; ***********************************
GLOBAL writeRAM
writeRAM:
    and esi, 07Fh
    mov [RAM+rsi], al
    ret

; * Read IO port 280h - 283h
; ****************************
GLOBAL readIO
readIO:
    and esi, 3
    mov al, [PORTA+rsi]
    ret

; * Write IO port 280h - 283h
; * !!! Should never happen ???
; *******************************
GLOBAL writeIO
writeIO:
%IFNDEF RELEASE
    mov rdi, rsi
    movzx esi, al
    call writingIO
%ENDIF
    ret

; * Read from timer registers
; *****************************
GLOBAL readTimer
readTimer:
    test esi, 1
    jnz readInterruptFLag

    ; TODO: Check bit A3 for timer interrupt, should not be necessary
    mov BYTE [TIMER_FLAG], 0
    mov eax, [TIMER]
    mov cl, [TIMER_DIV]
    shr eax, cl
    ret

readInterruptFLag:  ; Should never happen ????
%IFNDEF RELEASE
    call readingIntFlag
%ENDIF
    mov al, [TIMER_FLAG]
    ret

; * Write to timer registers
; ****************************
GLOBAL writeTimer
writeTimer:
    test esi, 010h
    jz writeEdgeDetectControl

    ; TODO: Check bit A3 for timer interrupt, should not be necessary
    and esi, 3
    mov cl, [TIMER_DIV_TABLE+rsi]
    mov [TIMER_DIV], cl
    movzx eax, al
    shl eax, cl
    mov [TIMER], eax
    mov BYTE [TIMER_FLAG], 0
    ret

writeEdgeDetectControl: ; Should never happen ????
%IFNDEF RELEASE
    mov rdi, rsi
    movzx esi, al
    call writingEdgeDetectControl
%ENDIF
    ret


SECTION .data

GLOBAL TIMER_DIV_TABLE
TIMER_DIV_TABLE DB 0, 3, 6, 10


SECTION .bss

GLOBAL RAM
RAM         RESB 128

GLOBAL PORTA, DDRA, PORTB, DDRB
PORTA       RESB 1
DDRA        RESB 1
PORTB       RESB 1
DDRB        RESB 1

GLOBAL TIMER, TIMER_DIV, TIMER_FLAG
TIMER       RESD 1
TIMER_DIV   RESB 1
TIMER_FLAG  RESB 1
