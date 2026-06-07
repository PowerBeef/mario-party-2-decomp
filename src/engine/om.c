#include "include_asm.h"

/* Object manager and overlay loader entry points (main segment). */
INCLUDE_ASM("InitObjSys");
INCLUDE_ASM("InitProcess");
INCLUDE_ASM("omOvlCallEx");
INCLUDE_ASM("omOvlGotoEx");
INCLUDE_ASM("omOvlReturnEx");
