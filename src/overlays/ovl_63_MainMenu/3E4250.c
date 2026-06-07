#include "common.h"
#include "common_structs.h"
#include "functions.h"
#include "variables.h"

/* Main menu overlay bootstrap (ovl_63, ROM 0x3E4250). */

extern s16 D_800CD414_CE014;
extern void func_80066F6C(void *dst, s16 size);
extern void func_80073EF8(void);
extern void func_800771EC_77DEC(s32, s32, s32);
extern void func_80077538(s32, s32, s32, s32);

void func_80102800_3E4250_MainMenu(void) {
    func_80066F6C((void *)0x801028B0, D_800CD414_CE014);
}

void func_80102830_3E4280_MainMenu(void) {
    GwSystem.unk_0A = 7;
    InitObjSys(10, 0);
    func_80073EF8();
    omOvlCallEx(0x63, 1, 0x192);
    omOvlGotoEx(0, 0x63, 1, 0x192);
}

void func_80102888_3E42D8_MainMenu(void) {
    InitObjSys(10, 0);
    func_80073EF8();
    omOvlCallEx(0x63, 1, 0x192);
    omOvlGotoEx(0, 0x63, 1, 0x192);
}
