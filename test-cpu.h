#include <stdint.h>

extern uint8_t RAM[];
extern uint32_t nextCpuCycle, programCounter;
extern uint8_t ADL, ADH, dataRegister;

extern uint8_t PCL, PCH, rA, rX, rY, rS;
extern uint8_t flagN, flagV, flagD, flagI, flagZ, flagC;

extern uint32_t _LDAI;

