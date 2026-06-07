#include "common.h"
#include "game/malloc.h"
#include "functions.h"

void *MakeHeap(void *addr, u32 size) {
    HeapBlock *heap = addr;

    heap->size = size;
    heap->marker = 0xA5;
    heap->allocated = 0;
    heap->prev = heap;
    heap->next = heap;
    return addr;
}

void *Malloc(void *heap, u32 size) {
    HeapBlock *block = heap;
    HeapBlock *cursor;
    u32 aligned = (size + 0x1F) & ~0x1F;

    for (cursor = block->next;; cursor = cursor->next) {
        if (cursor->allocated) {
            if (cursor == block) {
                return NULL;
            }
            continue;
        }
        if (cursor->size < aligned) {
            if (cursor == block) {
                return NULL;
            }
            continue;
        }
        if (cursor->size < aligned + 0x21) {
            cursor->allocated = 1;
            return (void *)((u8 *)cursor + 0x10);
        }
        {
            HeapBlock *split = (HeapBlock *)((u8 *)cursor + aligned);
            split->size = cursor->size - aligned;
            split->marker = 0xA5;
            split->allocated = 0;
            split->prev->next = split;
            split->next = cursor->next;
            split->next->prev = split;
            cursor->next = split;
            split->prev = cursor;
            cursor->size = aligned;
            cursor->allocated = 1;
            return (void *)((u8 *)cursor + 0x10);
        }
    }
}

void Free(void *ptr) {
    HeapBlock *block;
    HeapBlock *prev;
    HeapBlock *next;

    if (ptr == NULL) {
        return;
    }
    block = (HeapBlock *)((u8 *)ptr - 0x10);
    if (block->marker != 0xA5) {
        return;
    }
    prev = block->prev;
    if (!prev->allocated && prev < block) {
        prev->size += block->size;
        prev->next = block->next;
        block->next->prev = prev;
        block = prev;
    }
    next = block->next;
    if (next != block && !next->allocated) {
        block->size += next->size;
        block->next = next->next;
        next->next->prev = block;
    }
    block->allocated = 0;
}
