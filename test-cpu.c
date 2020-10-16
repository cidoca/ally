/*
  Alis, A Atari 2600 emulator
  Copyright (C) 2002-2020 Cidorvan Leite

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see [http://www.gnu.org/licenses/].
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include "core.h"
#include "test-cpu.h"

//#define F_PCL   (1 << 0)
//#define F_PCH   (1 << 1)
#define F_ADL   (1 << 2)
#define F_ADH   (1 << 3)
#define F_DR    (1 << 4)
#define F_RA    (1 << 5)
#define F_RX    (1 << 6)
#define F_RY    (1 << 7)
#define F_RS    (1 << 8)
#define F_C     (1 << 9)
#define F_Z     (1 << 10)
#define F_I     (1 << 11)
#define F_D     (1 << 12)
#define F_V     (1 << 13)
#define F_N     (1 << 14)
#define F_END   (1 << 20)

#define MAX_ROM 20
#define MAX_MEM 20
#define MAX_CYCLE 32

typedef struct {
    uint8_t PCL, PCH;
    uint8_t ADL, ADH;
    uint8_t DR;
    uint8_t rA, rX, rY, rS;
    uint8_t fC, fZ, fI, fD, fV, fN;
//    uint32_t NCC;
    uint32_t flags;
} CPU_CYCLE;

typedef struct {
    uint32_t address;
    uint8_t value;
} MEMORY;

typedef struct {
    char *name;
    MEMORY mem[MAX_MEM];
    uint8_t ROM[MAX_ROM];
    CPU_CYCLE cycles[MAX_CYCLE];
} CPU_INSTRUCTION;

CPU_INSTRUCTION CLI_58_SEI_78 = {
    "CLI - 58 & SEI - 78",
    {{-1}},
    {0x58, 0x78, 0x58, 0x78},
    {
        // CLI -> i
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x01, .PCH = 0xF0, .fI = 0, .flags = F_I},

        // SEI -> I
        {.PCL = 0x02, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .fI = 1, .flags = F_I},

        // CLI -> i
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .fI = 0, .flags = F_I},

        // SEI -> I
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .fI = 1, .flags = F_I},

        {.PCL = 0x05, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION TXA_8A = {
    "TXA - 8A",
    {{-1}},
    {0xa2, 0x00, 0x8a, 0xa2, 0x42, 0x8a, 0xa2, 0xcd, 0x8a},
    {
        // LDX #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rX = 0x00, .fZ = 1, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TXA
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_RA | F_Z | F_N},

        // LDX #$42 -> zn
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x05, .PCH = 0xF0, .rX = 0x42, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TXA
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_RA | F_Z | F_N},

        // LDX #$cd -> zN
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .rX = 0xcd, .fZ = 0, .fN = 1, .flags = F_RX | F_Z | F_N},

        // TXA
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x09, .PCH = 0xF0, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_RA | F_Z | F_N},

        {.PCL = 0x0a, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION TYA_98 = {
    "TYA - 98",
    {{-1}},
    {0xa0, 0x00, 0x98, 0xa0, 0x42, 0x98, 0xa0, 0xcd, 0x98},
    {
        // LDY #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rY = 0x00, .fZ = 1, .fN = 0, .flags = F_RY | F_Z | F_N},

        // TYA
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_RA | F_Z | F_N},

        // LDY #$42 -> zn
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x05, .PCH = 0xF0, .rY = 0x42, .fZ = 0, .fN = 0, .flags = F_RY | F_Z | F_N},

        // TYA
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_RA | F_Z | F_N},

        // LDY #$cd -> zN
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .rY = 0xcd, .fZ = 0, .fN = 1, .flags = F_RY | F_Z | F_N},

        // TYA
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x09, .PCH = 0xF0, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_RA | F_Z | F_N},

        {.PCL = 0x0a, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDY_A0 = {
    "LDY Imm - A0 #xx",
    {{-1}},
    {0xa0, 0x00, 0xa0, 0x42, 0xa0, 0xcd},
    {
        // LDY #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rY = 0x00, .fZ = 1, .fN = 0, .flags = F_RY | F_Z | F_N},

        // LDY #$42 -> zn
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .rY = 0x42, .fZ = 0, .fN = 0, .flags = F_RY | F_Z | F_N},

        // LDY #$cd -> zN
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rY = 0xcd, .fZ = 0, .fN = 1, .flags = F_RY | F_Z | F_N},

        {.PCL = 0x07, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_A1 = {
    "LDA (Ind, X) - A1 $xx",
    {{0x0030, 0x11}, {0x0031, 0x91}, {0x9111, 0x00},  {0x0040, 0x12}, {0x0041, 0x91}, {0x9112, 0x42},
     {0x00ff, 0x13}, {0x0000, 0x91}, {0x9113, 0x73},  {0x0050, 0x14}, {0x0051, 0x91}, {0x9114, 0xcd},  {-1}},
    {0xa2, 0x10, 0xa1, 0x20, 0xa1, 0x30, 0xa1, 0xef, 0xa1, 0x40},
    {
        // LDX #$10 -> zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rX = 0x10, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDA ($20,X) -> Zn    (0030:11 0031:91 9111:00)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x20, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x30, .ADH = 0, .flags = F_ADL | F_ADH},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x31, .ADH = 0, .DR = 0x11, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x11, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x11, .ADH = 0x91, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA ($30,X) -> zn    (0040:12 0041:91 9112:42)
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x30, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x40, .ADH = 0, .flags = F_ADL | F_ADH},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x41, .ADH = 0, .DR = 0x12, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x12, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x12, .ADH = 0x91, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA ($ef,X) -> zn    (00ff:13 0000:91 9113:73) BO
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0xef, .flags = F_ADL},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0xff, .ADH = 0, .flags = F_ADL | F_ADH},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x00, .ADH = 0, .DR = 0x13, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x13, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x13, .ADH = 0x91, .rA = 0x73, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA ($40,X) -> zN    (0050:14 0051:91 9114:cd)
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x40, .flags = F_ADL},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x50, .ADH = 0, .flags = F_ADL | F_ADH},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x51, .ADH = 0, .DR = 0x14, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x14, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x14, .ADH = 0x91, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x0b, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDX_A2 = {
    "LDX Imm - A2 #xx",
    {{-1}},
    {0xa2, 0x00, 0xa2, 0x42, 0xa2, 0xcd},
    {
        // LDX #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rX = 0x00, .fZ = 1, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDX #$42 -> zn
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .rX = 0x42, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDX #$cd -> zN
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rX = 0xcd, .fZ = 0, .fN = 1, .flags = F_RX | F_Z | F_N},

        {.PCL = 0x07, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDY_A4 = {
    "LDY Z-Page - A4 $xx",
    {{0x0080, 0x00}, {0x00a0, 0x42}, {0x00c0, 0xcd}, {-1}},
    {0xa4, 0x80, 0xa4, 0xa0, 0xa4, 0xc0},
    {
        // LDY $80 -> Zn    (0080:00)
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x80, .flags = F_ADL},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x80, .ADH = 0x00, .rY = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RY | F_Z | F_N},

        // LDY $A0 -> zn    (00a0:42)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0xa0, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0xa0, .ADH = 0x00, .rY = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RY | F_Z | F_N},

        // LDY $C0 -> zN    (00c0:cd)
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0xc0, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0xc0, .ADH = 0x00, .rY = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RY | F_Z | F_N},

        {.PCL = 0x07, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_A5 = {
    "LDA Z-Page - A5 $xx",
    {{0x0080, 0x00}, {0x00a0, 0x42}, {0x00c0, 0xcd}, {-1}},
    {0xa5, 0x80, 0xa5, 0xa0, 0xa5, 0xc0},
    {
        // LDA $80 -> Zn    (0080:00)
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x80, .flags = F_ADL},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x80, .ADH = 0x00, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $a0 -> zn    (00a0:42)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0xa0, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0xa0, .ADH = 0x00, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $c0 -> zN    (00c0:cd)
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0xc0, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0xc0, .ADH = 0x00, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x07, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDX_A6 = {
    "LDX Z-Page - A6 $xx",
    {{0x0080, 0x00}, {0x00a0, 0x42}, {0x00c0, 0xcd}, {-1}},
    {0xa6, 0x80, 0xa6, 0xa0, 0xa6, 0xc0},
    {
        // LDX $80 -> Zn    (0080:00)
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x80, .flags = F_ADL},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x80, .ADH = 0x00, .rX = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RX | F_Z | F_N},

        // LDX $a0 -> zn    (00a0:42)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0xa0, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0xa0, .ADH = 0x00, .rX = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RX | F_Z | F_N},

        // LDX $c0 -> zN    (00c0:cd)
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0xc0, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0xc0, .ADH = 0x00, .rX = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RX | F_Z | F_N},

        {.PCL = 0x07, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION TAY_A8 = {
    "TAY - A8",
    {{-1}},
    {0xa9, 0x00, 0xa8, 0xa9, 0x42, 0xa8, 0xa9, 0xcd, 0xa8},
    {
        // LDA #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_RA | F_Z | F_N},

        // TAY
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .rY = 0x00, .fZ = 1, .fN = 0, .flags = F_RY | F_Z | F_N},

        // LDA #$42 -> zn
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x05, .PCH = 0xF0, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_RA | F_Z | F_N},

        // TAY
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rY = 0x42, .fZ = 0, .fN = 0, .flags = F_RY | F_Z | F_N},

        // LDA #$cd -> zN
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_RA | F_Z | F_N},

        // TAY
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x09, .PCH = 0xF0, .rY = 0xcd, .fZ = 0, .fN = 1, .flags = F_RY | F_Z | F_N},

        {.PCL = 0x0a, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_A9 = {
    "LDA Imm - A9 #xx",
    {{-1}},
    {0xa9, 0x00, 0xa9, 0x42, 0xa9, 0xcd},
    {
        // LDA #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_RA | F_Z | F_N},

        // LDA #$42 -> zn
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_RA | F_Z | F_N},

        // LDA #$cd -> zN
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_RA | F_Z | F_N},

        {.PCL = 0x07, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION TAX_AA = {
    "TAX - AA",
    {{-1}},
    {0xa9, 0x00, 0xaa, 0xa9, 0x42, 0xaa, 0xa9, 0xcd, 0xaa},
    {
        // LDA #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_RA | F_Z | F_N},

        // TAX
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .rX = 0x00, .fZ = 1, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDA #$42 -> zn
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x05, .PCH = 0xF0, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_RA | F_Z | F_N},

        // TAX
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rX = 0x42, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDA #$cd -> zN
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_RA | F_Z | F_N},

        // TAX
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x09, .PCH = 0xF0, .rX = 0xcd, .fZ = 0, .fN = 1, .flags = F_RX | F_Z | F_N},

        {.PCL = 0x0a, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_AD = {
    "LDA Abs - AD $xxxx",
    {{0xf100, 0x00}, {0xf210, 0x42}, {0xf333, 0xcd}, {-1}},
    {0xad, 0x00, 0xf1, 0xad, 0x10, 0xf2, 0xad, 0x33, 0xf3},
    {
        // LDA $f100 -> Zn  (f100:00)
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .ADL = 0x00, .flags = F_ADL},
        {.PCL = 0x03, .PCH = 0xF0, .ADH = 0xf1, .flags = F_ADH},
        {.PCL = 0x03, .PCH = 0xF0, .ADL = 0x00, .ADH = 0xf1, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f210 -> zn  (f210:42)
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x05, .PCH = 0xF0, .ADL = 0x10, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADH = 0xf2, .flags = F_ADH},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf2, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f333 -> zN  (f333:cd)
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x33, .flags = F_ADL},
        {.PCL = 0x09, .PCH = 0xF0, .ADH = 0xf3, .flags = F_ADH},
        {.PCL = 0x09, .PCH = 0xF0, .ADL = 0x33, .ADH = 0xf3, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x0a, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_B1 = {
    "LDA (Ind), Y - B1 $xx",
    {{0x0020, 0x11}, {0x0021, 0x91}, {0x9121, 0x00},  {0x0030, 0x12}, {0x0031, 0x91}, {0x9122, 0x42},
     {0x0040, 0xf8}, {0x0041, 0x90}, {0x9108, 0x73},  {0x0050, 0x14}, {0x0051, 0x91}, {0x9124, 0xcd},  {-1}},
    {0xa0, 0x10, 0xb1, 0x20, 0xb1, 0x30, 0xb1, 0x40, 0xb1, 0x50},
    {
        // LDY #$10 -> zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rY = 0x10, .fZ = 0, .fN = 0, .flags = F_RY | F_Z | F_N},

        // LDA ($20), Y -> Zn    (0020:11 0021:91 9121:00)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x20, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x21, .ADH = 0x00, .DR = 0x11, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x21, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x21, .ADH = 0x91, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA ($30), Y -> zn    (0030:12 0031:91 9122:42)
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x30, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x31, .ADH = 0x00, .DR = 0x12, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x22, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x22, .ADH = 0x91, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA ($40), Y -> zn    (0040:f8 0041:90 9108:73) BO
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x40, .flags = F_ADL},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x41, .ADH = 0x00, .DR = 0xf8, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x08, .ADH = 0x90, .flags = F_ADL | F_ADH},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x08, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x08, .ADH = 0x91, .rA = 0x73, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA ($50), Y -> zN    (0050:14 0051:91 9124:cd)
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x50, .flags = F_ADL},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x51, .ADH = 0x00, .DR = 0x14, .flags = F_ADL | F_ADH | F_DR},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x24, .ADH = 0x91, .flags = F_ADL | F_ADH},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0x24, .ADH = 0x91, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x0b, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_B5 = {
    "LDA Z-Page, X - B5 $xx",
    {{0x0040, 0x00}, {0x0060, 0x42}, {0x0010, 0xcd}, {-1}},
    {0xa2, 0x20, 0xb5, 0x20, 0xb5, 0x40, 0xb5, 0xf0},
    {
        // LDX #$20 -> zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rX = 0x20, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDA $20, X -> Zn (0040:00)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x20, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x40, .flags = F_ADL},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x40, .ADH = 0x00, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $40, X -> zn (0060:42)
        {.PCL = 0x05, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x40, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x60, .flags = F_ADL},
        {.PCL = 0x06, .PCH = 0xF0, .ADL = 0x60, .ADH = 0x00, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f0, X -> zN (0010:cd) BO
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0xf0, .flags = F_ADL},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x10, .flags = F_ADL},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x10, .ADH = 0x00, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x09, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_B9 = {
    "LDA Abs, Y - B9 $xxxx",
    {{0xf120, 0x00}, {0xf230, 0x42}, {0xf310, 0x73}, {0xf440, 0xcd}, {-1}},
    {0xa0, 0x20, 0xb9, 0x00, 0xf1, 0xb9, 0x10, 0xf2, 0xb9, 0xf0, 0xf2, 0xb9, 0x20, 0xf4},
    {
        // LDY #$20 -> zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rY = 0x20, .fZ = 0, .fN = 0, .flags = F_RY | F_Z | F_N},

        // LDA $f100, Y -> Zn (f120:00)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x00, .flags = F_ADL},
        {.PCL = 0x05, .PCH = 0xF0, .ADL = 0x20, .ADH = 0xf1, .flags = F_ADL | F_ADH},
        {.PCL = 0x05, .PCH = 0xF0, .ADL = 0x20, .ADH = 0xf1, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f210, Y -> zn (f230:42)
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x07, .PCH = 0xF0, .ADL = 0x10, .flags = F_ADL},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x30, .ADH = 0xf2, .flags = F_ADL | F_ADH},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x30, .ADH = 0xf2, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f2f0, Y -> zn (f310:42) BO
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0xf0, .flags = F_ADL},
        {.PCL = 0x0b, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf2, .flags = F_ADL | F_ADH},
        {.PCL = 0x0b, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf3, .flags = F_ADL | F_ADH},
        {.PCL = 0x0b, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf3, .rA = 0x73, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f420, Y -> zN (f440:cd)
        {.PCL = 0x0c, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0d, .PCH = 0xF0, .ADL = 0x20, .flags = F_ADL},
        {.PCL = 0x0e, .PCH = 0xF0, .ADL = 0x40, .ADH = 0xf4, .flags = F_ADL | F_ADH},
        {.PCL = 0x0e, .PCH = 0xF0, .ADL = 0x40, .ADH = 0xf4, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x0f, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION TXS_9A_TSX_BA = {
    "TXS - 9A & TSX - BA",
    {{-1}},
    {0xa2, 0x00, 0x9a, 0xa2, 0x55, 0xba, 0xa2, 0x42, 0x9a, 0xa2, 0x55, 0xba, 0xa2, 0xcd, 0x9a, 0xa2, 0x55, 0xba},
    {
        // LDX #$00 -> Zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rX = 0x00, .fZ = 1, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TXS
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .rS = 0x00, .flags = F_RS},

        // LDX #$55 -> zn
        {.PCL = 0x04, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x05, .PCH = 0xF0, .rX = 0x55, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TSX -> Zn
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x06, .PCH = 0xF0, .rX = 0x00, .fZ = 1, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDX #$42 -> zn
        {.PCL = 0x07, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x08, .PCH = 0xF0, .rX = 0x42, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TXS
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x09, .PCH = 0xF0, .rS = 0x42, .flags = F_RS},

        // LDX #$55 -> zn
        {.PCL = 0x0a, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0b, .PCH = 0xF0, .rX = 0x55, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TSX -> Zn
        {.PCL = 0x0c, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0c, .PCH = 0xF0, .rX = 0x42, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDX #$cd -> zN
        {.PCL = 0x0d, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0e, .PCH = 0xF0, .rX = 0xcd, .fZ = 0, .fN = 1, .flags = F_RX | F_Z | F_N},

        // TXS
        {.PCL = 0x0f, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0f, .PCH = 0xF0, .rS = 0xcd, .flags = F_RS},

        // LDX #$55 -> zn
        {.PCL = 0x10, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x11, .PCH = 0xF0, .rX = 0x55, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // TSX -> zN
        {.PCL = 0x12, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x12, .PCH = 0xF0, .rX = 0xcd, .fZ = 0, .fN = 1, .flags = F_RX | F_Z | F_N},

        {.PCL = 0x13, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION LDA_BD = {
    "LDA Abs, X - BD $xxxx",
    {{0xf120, 0x00}, {0xf230, 0x42}, {0xf310, 0x73}, {0xf440, 0xcd}, {-1}},
    {0xa2, 0x20, 0xbd, 0x00, 0xf1, 0xbd, 0x10, 0xf2, 0xbd, 0xf0, 0xf2, 0xbd, 0x20, 0xf4},
    {
        // LDX #$20 -> zn
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .rX = 0x20, .fZ = 0, .fN = 0, .flags = F_RX | F_Z | F_N},

        // LDA $f100, X -> Zn (f120:00)
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x04, .PCH = 0xF0, .ADL = 0x00, .flags = F_ADL},
        {.PCL = 0x05, .PCH = 0xF0, .ADL = 0x20, .ADH = 0xf1, .flags = F_ADL | F_ADH},
        {.PCL = 0x05, .PCH = 0xF0, .ADL = 0x20, .ADH = 0xf1, .rA = 0x00, .fZ = 1, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f210, X -> zn (f230:42)
        {.PCL = 0x06, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x07, .PCH = 0xF0, .ADL = 0x10, .flags = F_ADL},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x30, .ADH = 0xf2, .flags = F_ADL | F_ADH},
        {.PCL = 0x08, .PCH = 0xF0, .ADL = 0x30, .ADH = 0xf2, .rA = 0x42, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f2f0, X -> zn (f310:42) BO
        {.PCL = 0x09, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0a, .PCH = 0xF0, .ADL = 0xf0, .flags = F_ADL},
        {.PCL = 0x0b, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf2, .flags = F_ADL | F_ADH},
        {.PCL = 0x0b, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf3, .flags = F_ADL | F_ADH},
        {.PCL = 0x0b, .PCH = 0xF0, .ADL = 0x10, .ADH = 0xf3, .rA = 0x73, .fZ = 0, .fN = 0, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        // LDA $f420, X -> zN (f440:cd)
        {.PCL = 0x0c, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x0d, .PCH = 0xF0, .ADL = 0x20, .flags = F_ADL},
        {.PCL = 0x0e, .PCH = 0xF0, .ADL = 0x40, .ADH = 0xf4, .flags = F_ADL | F_ADH},
        {.PCL = 0x0e, .PCH = 0xF0, .ADL = 0x40, .ADH = 0xf4, .rA = 0xcd, .fZ = 0, .fN = 1, .flags = F_ADL | F_ADH | F_RA | F_Z | F_N},

        {.PCL = 0x0f, .PCH = 0xF0, .flags = F_END}
    }
};

CPU_INSTRUCTION NOP_EA = {
    "NOP - EA",
    {{-1}},
    {0xea, 0xea, 0xea},
    {
        // NOP
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x01, .PCH = 0xF0, .flags = 0},

        // NOP
        {.PCL = 0x02, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x02, .PCH = 0xF0, .flags = 0},

        // NOP
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},
        {.PCL = 0x03, .PCH = 0xF0, .flags = 0},

        {.PCL = 0x04, .PCH = 0xF0, .flags = F_END}
    }
};

void printError(int cycle, char *reg, uint8_t expected, uint8_t current) {
    printf("#### CYCLE %d FAIL #### -> %s %02X %02X\n", cycle, reg, expected, current);
}

void runTest(const CPU_INSTRUCTION *i) {
    static int count = 1;
    const CPU_CYCLE *c = &i->cycles[0];
    const MEMORY *m = &i->mem[0];

    printf("Testing #%02d: %-22s -> ", count++, i->name);

    memcpy(ROM, i->ROM, MAX_ROM);
    ROM[0x0FFC] = 0x00;
    ROM[0x0FFD] = 0xF0;
    while (m->address != -1) {
        uint32_t a = m->address & 0x1FFF;
        if (a & 0x1000)
            ROM[a - 0x1000] = m->value;
        else
            RAM[a] = m->value;
        m++;
    }

    initCpu();
    ADL = ADH = rA = rX = rY = rS = DATA_BUFFER = 0x55;
    flagC = flagZ = flagI = flagD = flagV = flagN = 0;
    while (1) {
        int n = (int)(c - &i->cycles[0]);

        pulseCpu();
        if (PCL != c->PCL) {
            printError(n, "PCL", c->PCL, PCL);
            return;
        }
        if (PCH != c->PCH) {
            printError(n, "PCH", c->PCH, PCH);
            return;
        }
        if (c->flags & F_ADL && ADL != c->ADL) {
            printError(n, "ADL", c->ADL, ADL);
            return;
        }
        if (c->flags & F_ADH && ADH != c->ADH) {
            printError(n, "ADH", c->ADH, ADH);
            return;
        }
        if (c->flags & F_DR && DATA_BUFFER != c->DR) {
            printError(n, "DR", c->DR, DATA_BUFFER);
            return;
        }
        if (c->flags & F_RA && rA != c->rA) {
            printError(n, "A", c->rA, rA);
            return;
        }
        if (c->flags & F_RX && rX != c->rX) {
            printError(n, "X", c->rX, rX);
            return;
        }
        if (c->flags & F_RY && rY != c->rY) {
            printError(n, "Y", c->rY, rY);
            return;
        }
        if (c->flags & F_RS && rS != c->rS) {
            printError(n, "S", c->rS, rS);
            return;
        }
        if (c->flags & F_C && flagC != c->fC) {
            printError(n, "flagC", c->fC, flagC);
            return;
        }
        if (c->flags & F_Z && flagZ != c->fZ) {
            printError(n, "flagZ", c->fZ, flagZ);
            return;
        }
        if (c->flags & F_I && flagI != c->fI) {
            printError(n, "flagI", c->fI, flagI);
            return;
        }
        if (c->flags & F_D && flagD != c->fD) {
            printError(n, "flagD", c->fD, flagD);
            return;
        }
        if (c->flags & F_V && flagV != c->fV) {
            printError(n, "flagV", c->fV, flagV);
            return;
        }
        if (c->flags & F_N && flagN != c->fN) {
            printError(n, "flagN", c->fN, flagN);
            return;
        }

        if (c->flags & F_END)
            break;
        else
            c++;
    }

    printf("OK\n");
    return;
}

int main(int argc, char **argv)
{
    runTest(&NOP_EA);
    runTest(&CLI_58_SEI_78);

    runTest(&LDA_A9);
    runTest(&LDA_A5);
    runTest(&LDA_B5);
    runTest(&LDA_AD);
    runTest(&LDA_BD);
    runTest(&LDA_B9);
    runTest(&LDA_A1);
    runTest(&LDA_B1);

    runTest(&LDX_A2);
    runTest(&LDX_A6);

    runTest(&LDY_A0);
    runTest(&LDY_A4);

    runTest(&TXA_8A);
    runTest(&TYA_98);
    runTest(&TXS_9A_TSX_BA);
    runTest(&TAY_A8);
    runTest(&TAX_AA);

    return 0;
}

void opcodeNotImplemented(int opcode) { }
void d6502() { }
