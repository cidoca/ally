/*
  Ally, A Atari 2600 emulator
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

extern unsigned char ROM[];
extern unsigned int SCANLINE;
extern unsigned char CLOCKCOUNTS;
extern unsigned char PORTA, PORTB, INPT4, INPT5;

extern unsigned char TIA[], POSITION_P0, POSITION_P1, POSITION_M0, POSITION_M1, POSITION_BL;
extern unsigned char _pf, _bl, _m0, _m1;

void setupBanks(int);
void initCpu();
void pulseCpu();
void initRIOT();
void nextTimerCycle();
void initTIA();
void scanFrame(void *);

void initSound();
void fillSoundBuffer(void *userdata, unsigned char *stream, int len);
