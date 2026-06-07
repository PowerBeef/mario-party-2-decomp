#ifndef PROCESS_H
#define PROCESS_H

#include "common.h"

typedef struct jump_buf {
    void *sp;
    void *func;
    u32 regs[21];
} jmp_buf;

typedef void (*process_func)(void);

typedef struct Process {
    /* 0x00 */ struct Process *next;
    /* 0x04 */ struct Process *youngest_child;
    /* 0x08 */ struct Process *oldest_child;
    /* 0x0C */ struct Process *relative;
    /* 0x10 */ struct Process *parent_oldest_child;
    /* 0x14 */ struct Process *new_process;
    /* 0x18 */ void *heap;
    /* 0x1C */ u16 exec_mode;
    /* 0x1E */ u16 stat;
    /* 0x20 */ u16 priority;
    /* 0x22 */ s16 dtor_idx;
    /* 0x24 */ s32 sleep_time;
    /* 0x28 */ void *base_sp;
    /* 0x2C */ jmp_buf prc_jump;
    /* 0x88 */ process_func destructor;
    /* 0x8C */ void *user_data;
} Process; /* sizeof 0x90 */

void InitProcess(void);
void SleepProcess(s32 time);
void SleepVProcess(void);

#endif
