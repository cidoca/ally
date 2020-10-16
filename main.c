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

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "core.h"
#include "test-cpu.h"

void opcodeNotImplemented() {
    printf("#### Last opcode not implemented!!!\n");
    exit(1);
}

void writingIO(int address, int value) {
    printf("#### Attempt to write %02X in %04X IO port !!!!\n", value, address);
}

void readingIntFlag() {
    printf("#### Attempt to read interrupt flag !!!!\n");
}

void writingEdgeDetectControl(int address, int value) {
    printf("#### Attempt to write %02X in %04X timer register !!!!\n", value, address);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        printf("Ally - Atari 2600 emulator\n");
        printf("usage: %s <rom-file>\n\n", argv[0]);
        return 0;
    }

    int fd = open(argv[1], O_RDONLY);
    if (fd > 0) {
        read(fd, ROM, 32768);
        close(fd);
    }

    int count = 1000000;

    initCpu();
    initRIOT();
    while (count--) {
        nextTimerCycle();
        pulseCpu();
    }

    return 0;
}
