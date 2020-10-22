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
EXTERN writingIO, writingEdgeDetectControl, writingRAM, readingIO
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
    mov DWORD [TIMER], 0FFFFFF00h
    mov BYTE [TIMER_DIV], 0
    mov BYTE [TIMER_FLAG], 0
    ret

; * Decrement timer and update interrupt flag
; *********************************************
GLOBAL nextTimerCycle
nextTimerCycle:
    cmp DWORD [TIMER], 0
    jne NZ
    mov BYTE [TIMER_DIV], 0
    mov BYTE [TIMER_FLAG], 0C0h
NZ:
    cmp DWORD [TIMER], 0FFFFFF00h
    je NR
    dec DWORD [TIMER]
NR:
    ret

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
;%IFNDEF RELEASE
%IFDEF XXXX
    push rax
    push rdi
    push rsi
    mov rdi, rsi
    mov esi, eax
    call writingRAM
    pop rsi
    pop rdi
    pop rax
%ENDIF
    and esi, 07Fh
    mov [RAM+rsi], al
    ret

; * Read IO port 280h - 283h
; ****************************
GLOBAL readIO
readIO:
    and esi, 3
;%IFNDEF RELEASE
%IFDEF XXX
    push rdi
    push rsi
    mov rdi, rsi
    call readingIO
    pop rsi
    pop rdi
%ENDIF
    mov al, [PORTA+rsi]
    ret

; * Write IO port 280h - 283h
; * !!! Should never happen ???
; *******************************
GLOBAL writeIO
writeIO:
%IFNDEF RELEASE
    push rdi
    mov rdi, rsi
    movzx esi, al
    call writingIO
    pop rdi
%ENDIF
    ret

; * Read from timer registers
; *****************************
GLOBAL readTimer
readTimer:
    test esi, 1
    jnz readInterruptFLag

    ; TODO: Check bit A3 for timer interrupt, should not be necessary
    and BYTE [TIMER_FLAG], 040h
    mov eax, [TIMER]
    mov cl, [TIMER_DIV]
    shr eax, cl
    ret

readInterruptFLag:
    and BYTE [TIMER_FLAG], 080h
    mov al, [TIMER_FLAG]
    ret

; * Write to timer registers
; ****************************
GLOBAL writeTimer
writeTimer:
    test esi, 010h
    jz writeEdgeDetectControl

    ; TODO: Check bit A3 for timer interrupt, should not be necessary
    and BYTE [TIMER_FLAG], 040h
    and esi, 3
    mov cl, [TIMER_DIV_TABLE+rsi]
    mov [TIMER_DIV], cl
    movzx eax, al
    shl eax, cl
    mov [TIMER], eax
    ret

writeEdgeDetectControl: ; Should never happen ????
%IFNDEF RELEASE
    push rdi
    mov rdi, rsi
    movzx esi, al
    call writingEdgeDetectControl
    pop rdi
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
