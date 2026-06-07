#ifndef VARIABLES_H
#define VARIABLES_H

#include "common_structs.h"

extern GW_SYSTEM GwSystem;   /* VRAM 0x800F93A8 */
extern GW_PLAYER gPlayers[4]; /* VRAM 0x800FD2C0 stride 0x34 */
extern s16 omovlhisidx;
extern omOvlHisData omovlhis[12];
extern void *permHeapPtr;    /* VRAM 0x800DEFD0 */
extern void *tempHeapPtr;    /* VRAM 0x800DEFD4 */
extern OverlayTableEntry overlayTable[]; /* ROM table at 0x800CAD90 */

#endif
