#ifndef GAME_MALLOC_H
#define GAME_MALLOC_H

#include "common.h"

typedef struct HeapBlock {
    u32 size;
    u8 marker;      /* 0xA5 */
    u8 allocated;
    u8 pad[2];
    struct HeapBlock *prev;
    struct HeapBlock *next;
} HeapBlock;

#endif
