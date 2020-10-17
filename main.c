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

void opcodeNotImplemented() {
    printf("#### Last opcode not implemented!!!\n");
    exit(1);
}

void writingIO(int address, int value) {
//    printf("#### Attempt to write %02X in %04X IO port !!!!\n", value & 0xff, address);
}

void readingIntFlag() {
    printf("#### Attempt to read interrupt flag !!!!\n");
}

void writingEdgeDetectControl(int address, int value) {
    printf("#### Attempt to write %02X in %04X timer register !!!!\n", value & 0xff, address);
}

void readingInvalidTIA(int value) {
//    printf("#### Attempt to read invalid TIA register: %02X\n", value & 0xff);
}

void writingInvalidTIA(int address, int value) {
    if (
        address == 0x00
        || address == 0x01
        || address == 0x03
    )
    printf("#### Writing TIA: %02X <- %02X  S/C: %d/%d\n", address, value & 0xff, SCANLINE, CLOCKCOUNTS);
}

void writingRAM(int address, int value) {
//    if (address & 0xFF == 0x99)
    printf("#### Writing RAM: %02X <- %02X  S/C: %d/%d\n", address & 0xff, value & 0xff, SCANLINE, CLOCKCOUNTS);
}

void readingIO(int address) {
//    if (address & 0xFF == 0x99)
//    printf("#### Reading IO: %02X S/C: %d/%d\n", address, SCANLINE, CLOCKCOUNTS);
}

void initSDL(char *filename)
{
    char title[FILENAME_MAX];

    if (SDL_Init(SDL_INIT_VIDEO /*| SDL_INIT_AUDIO | SDL_INIT_JOYSTICK*/ | SDL_INIT_TIMER) < 0) {
        printf("Error initializing SDL: %s\n", SDL_GetError());
        exit(-1);
    }

    // Create window and texture
    snprintf(title, FILENAME_MAX, "Ally - %s", filename);
    win = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1140, 900, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, 228, 361); // 160, 192);

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

    read(fd, ROM, 32768);
    close(fd);

    initCpu();
    initRIOT();
    initTIA();
}

void mainLoop()
{
    SDL_Event event;
    void *frameBuffer;
    unsigned int t1, t2;
    int done = 0, pitch;

//    t1 = SDL_GetTicks();
    while (!done) {

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT)
                done = 1;
        }

        printf("*** NEW FRAME ***\n");
        SDL_LockTexture(texture, NULL, &frameBuffer, &pitch);
        scanFrame(frameBuffer);
        SDL_UnlockTexture(texture);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);

//        t2 = SDL_GetTicks();
//        printf("%d\n", t2 - t1);
        SDL_Delay(16);
//        t1 = t2;
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

/*    while (1) {
        nextTimerCycle();
        pulseCpu();
    } */

    return 0;
}
