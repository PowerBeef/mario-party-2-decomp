#include "common.h"
#include "functions.h"

extern s16 D_800CD414_CE014;
extern void func_80066F6C(void *dst, s16 size);

void func_80102800_37F290_BumperBallMaze1P(void) {
    func_80066F6C((void *)0x80102A10, D_800CD414_CE014);
}
