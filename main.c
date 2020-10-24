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
#include <SDL2/SDL.h>
#include "core.h"
#include "test-cpu.h"

Uint8 *keys;
SDL_Window *win;
SDL_Renderer *renderer;
SDL_Texture *texture;

#ifndef RELEASE
void opcodeNotImplemented() {
    printf("#### Last opcode not implemented!!!\n");
    exit(1);
}

void writingIO(int address, int value) {
    printf("#### Attempt to write %02X in %04X IO port !!!!\n", value & 0xff, address);
}

void writingEdgeDetectControl(int address, int value) {
    printf("#### Attempt to write %02X in %04X timer register !!!!\n", value & 0xff, address);
}

void readingInvalidTIA(int value) {
//    printf("#### Attempt to read invalid TIA register: %02X\n", value & 0xff);
}

char *TIA_NAME[64] = { "VSYNC", "VBLANK", "WSYNC", "RSYNC", "NUSIZ0", "NUSIZ1",
                       "COLUP0", "COLUP1", "COLUPF", "COLUBK", "CTRLPF", "REFP0",
                       "REFP1", "PF0", "PF1", "PF2", "RESP0", "RESP1", "RESM0",
                       "RESM1", "RESBL", "AUDC0", "AUDC1", "AUDF0", "AUDF1",
                       "AUDV0", "AUDV1", "GRP0", "GRP1", "ENAM0", "ENAM1", "ENABL",
                       "HMP0", "HMP1", "HMM0", "HMM1", "HMBL", "VDELP0", "VDELP1",
                       "VDELBL", "RESMP0", "RESMP1", "HMOVE", "HMCLR", "CXCLR" };
void writingInvalidTIA(int address, int value) {
//    return;
    if (0
//        || 1
//        || address == 0x00
//        || address == 0x01
//        || address == 0x03
//        || address == 0x08
//        || address == 0x0F
//        || address == 0x14
//        || address == 0x1F
//        || address == 0x24
//        || address == 0x2A
//        || address == 0x2B
//        || (address >= 0x15 && address <= 0x1A)   // Sound
    )
//    if (SCANLINE != 209) return;
    printf("#### Writing TIA: %6s <- %02X                                    S/C: %3d/%3d  P: %3d/%3d  M: %3d/%3d B: %d\n",
            address <= 0x2C ? TIA_NAME[address] : "???", value & 0xff,
            SCANLINE, CLOCKCOUNTS, POSITION_P0, POSITION_P1, POSITION_M0, POSITION_M1, POSITION_BL);
}

void writingRAM(int address, int value) {
//    if (address & 0xFF == 0x99)
    printf("#### Writing RAM: %02X <- %02X  S/C: %d/%d\n", address & 0xff, value & 0xff, SCANLINE, CLOCKCOUNTS);
}

void readingIO(int address) {
//    if (address & 0xFF == 0x99)
//    printf("#### Reading IO: %02X S/C: %d/%d\n", address, SCANLINE, CLOCKCOUNTS);
}
#endif

void initSDL(char *filename)
{
    char title[FILENAME_MAX];

    if (SDL_Init(SDL_INIT_VIDEO /*| SDL_INIT_AUDIO | SDL_INIT_JOYSTICK*/ | SDL_INIT_TIMER) < 0) {
        printf("Error initializing SDL: %s\n", SDL_GetError());
        exit(-1);
    }

    // Create window and texture
    snprintf(title, FILENAME_MAX, "Ally - %s", filename);
    win = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 912, 640, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    //win = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 228, 320, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
    //SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, 228, 320); // 160, 192);

    // Setup keyboard and joysticks
    keys = (Uint8*)SDL_GetKeyboardState(NULL);
/*    joy1 = SDL_JoystickOpen(0);
    joy2 = SDL_JoystickOpen(1);

    // Setup audio
    SDL_AudioSpec wanted;
    wanted.freq = 48000;
    wanted.format = AUDIO_U8;
    wanted.channels = 1;
    wanted.samples = wanted.freq / 60 * 2;
    wanted.callback = make_PSG;
    wanted.userdata = NULL;
    if (SDL_OpenAudio(&wanted, NULL) < 0) {
        audio_present = 0;
        printf("Could not open audio: %s\n", SDL_GetError());
    }*/

    // Ignore keyboard and mouse events
    SDL_EventState(SDL_KEYDOWN, SDL_IGNORE);
    SDL_EventState(SDL_KEYUP, SDL_IGNORE);
    SDL_EventState(SDL_TEXTINPUT, SDL_IGNORE);
    SDL_EventState(SDL_MOUSEMOTION, SDL_IGNORE);
    SDL_EventState(SDL_MOUSEBUTTONDOWN, SDL_IGNORE);
    SDL_EventState(SDL_MOUSEBUTTONUP, SDL_IGNORE);
    SDL_EventState(SDL_MOUSEWHEEL, SDL_IGNORE);
}

void deinitSDL()
{
/*    SDL_CloseAudio();
    if (joy2)
        SDL_JoystickClose(joy2);
    if (joy1)
        SDL_JoystickClose(joy1); */
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(win);
    SDL_Quit();
}

void openROM(char *filename)
{
    int fd = open(filename, O_RDONLY);
    if (fd == -1) {
        printf("** Error opening rom %s\n", filename);
        exit(-1);
    }

    int size = read(fd, ROM, 32768);
    close(fd);

    setupBanks(size);
    initCpu();
    initRIOT();
    initTIA();

#ifndef RELEASE
    _pf = _bl = _m0 = _m1 = 1;
#endif
}

void getControls()
{
    PORTA = 0xFF;
    PORTB = 0x3F;
    INPT4 = INPT5 = 0x80;

    // Player 0
    if (keys[SDL_SCANCODE_RIGHT])
        PORTA &= ~0x80;
    if (keys[SDL_SCANCODE_LEFT])
        PORTA &= ~0x40;
    if (keys[SDL_SCANCODE_DOWN])
        PORTA &= ~0x20;
    if (keys[SDL_SCANCODE_UP])
        PORTA &= ~0x10;
    if (keys[SDL_SCANCODE_LCTRL])
        INPT4 &= ~0x80;

    // Reset
    if (keys[SDL_SCANCODE_ESCAPE])
        PORTB &= ~0x01;

    // Select
    if (keys[SDL_SCANCODE_TAB])
        PORTB &= ~0x02;

    // Debug
#ifndef RELEASE
    static int f9 = 0, f10 = 0, f11 = 0, f12 = 0, wo = 0, wd = 1;
    if (keys[SDL_SCANCODE_F9]) { if (!f9) { f9 = 1; _pf = !_pf; } } else f9 = 0;
    if (keys[SDL_SCANCODE_F10]) { if (!f10) { f10 = 1; _bl = !_bl; } } else f10 = 0;
    if (keys[SDL_SCANCODE_F11]) { if (!f11) { f11 = 1; _m0 = !_m0; } } else f11 = 0;
    if (keys[SDL_SCANCODE_F12]) { if (!f12) { f12 = 1; _m1 = !_m1; } } else f12 = 0;
    if (keys[SDL_SCANCODE_MINUS]) { if (wd) { wo = 1; wd = 0; SDL_SetWindowSize(win, 228, 320); } }
    if (keys[SDL_SCANCODE_EQUALS]) { if (wo) { wo = 0; wd = 1; SDL_SetWindowSize(win, 912, 640); } }
#endif
}

void mainLoop()
{
    SDL_Event event;
    void *frameBuffer;
    int done = 0, pitch;
    unsigned int t, tc, tf = 0;

    t = SDL_GetTicks();
    while (!done) {

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT)
                done = 1;
        }

//        printf("\n###### NEW FRAME ########\n\n");
        getControls();
        SDL_LockTexture(texture, NULL, &frameBuffer, &pitch);
        scanFrame(frameBuffer);
        SDL_UnlockTexture(texture);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);

//        SDL_Delay(200);
        t += (tf++ % 3 == 0) ? 16 : 17;
        tc = SDL_GetTicks();
        if (t > tc)
            SDL_Delay(t - tc);
        else
            t = tc;
    }
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        printf("Ally - Atari 2600 emulator\n");
        printf("usage: %s <rom-file>\n\n", argv[0]);
        return 0;
    }

    openROM(argv[1]);
    initSDL(argv[1]);
    mainLoop();
    deinitSDL();

    return 0;
}
