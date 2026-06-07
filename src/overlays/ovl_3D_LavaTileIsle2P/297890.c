#include "common.h"
#include "functions.h"

extern s16 D_800CD414_CE014;
extern void func_80066F6C(void *dst, s16 size);
extern s32 IsBoardFeatureDisabled(s32 feature);
extern void func_8006836C_68F6C(s32 arg0);

void func_80102800_297890_LavaTileIsle2P(void) {
    func_80066F6C((void *)0x80102A20, D_800CD414_CE014);
}

void func_80102830_2978C0_LavaTileIsle2P(void) {
    if (IsBoardFeatureDisabled(0) != 0) {
        func_8006836C_68F6C(0x41);
    }
    InitObjSys(10, 0);
}
