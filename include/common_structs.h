#ifndef COMMON_STRUCTS_H
#define COMMON_STRUCTS_H

#include "ultra64.h"

typedef struct Vec {
    f32 x;
    f32 y;
    f32 z;
} Vec;

typedef struct GW_SYSTEM {
    /* 0x00 */ s16 unk_00;
    /* 0x02 */ s16 current_board_index;
    /* 0x04 */ s16 current_game_length;
    /* 0x06 */ s16 total_turns;
    /* 0x08 */ s16 current_turn;
    /* 0x0A */ s16 unk_0A;
    /* 0x0C */ s16 star_spawn_indices[7];
    /* 0x1A */ s16 unk_1A;
    /* 0x1C */ s16 unk_1C;
    /* 0x1E */ s16 current_player_index;
    /* 0x20 */ s16 chosenMinigameIndex;
    /* 0x22 */ s16 curPlayerAbsSpaceIndex;
    /* 0x24 */ char unk_24[1];
    /* 0x25 */ s8 unk_25;
    /* 0x26 */ char unk_26[2];
} GW_SYSTEM;

typedef struct GW_PLAYER {
    /* 0x00 */ u8 group;
    /* 0x01 */ u8 cpu_difficulty;
    /* 0x02 */ u8 cpu_difficulty2;
    /* 0x03 */ u8 port;
    /* 0x04 */ u8 character;
    /* 0x05 */ char unk_05;
    /* 0x06 */ s16 flags;
    /* 0x08 */ s16 coins;
    /* 0x0A */ s16 coins_mg;
    /* 0x0C */ s16 coins_mg_bonus;
    /* 0x0E */ s16 stars;
    /* 0x10 */ s16 cur_chain_index;
    /* 0x12 */ s16 cur_space_index;
    /* 0x14 */ s16 next_chain_index;
    /* 0x16 */ s16 next_space_index;
    /* 0x18 */ char unk_18;
    /* 0x19 */ s8 item;
    /* 0x1A */ s8 turn_status;
    /* 0x1B */ u8 player_space_color;
    /* 0x1C */ char unk_1C[4];
    /* 0x20 */ void *unk_20;
    /* 0x24 */ void *unk_24;
    /* 0x28 */ s16 coins_total;
    /* 0x2A */ s16 coins_max;
    /* 0x2C */ u8 happening_spaces_landed_on;
    /* 0x2D */ u8 red_spaces_landed_on;
    /* 0x2E */ u8 blue_spaces_landed_on;
    /* 0x2F */ u8 chance_spaces_landed_on;
    /* 0x30 */ u8 bowser_spaces_landed_on;
    /* 0x31 */ u8 battle_spaces_landed_on;
    /* 0x32 */ u8 item_spaces_landed_on;
    /* 0x33 */ u8 bank_spaces_landed_on;
} GW_PLAYER;

typedef struct omOvlHisData {
    /* 0x00 */ s32 overlayID;
    /* 0x04 */ s16 event;
    /* 0x06 */ u16 stat;
} omOvlHisData;

typedef struct omObjData {
    /* 0x00 */ u16 stat;
    /* 0x02 */ s16 next_idx_alloc;
    /* 0x04 */ s16 prio;
    /* 0x06 */ s16 model_id;
    /* 0x08 */ s16 mdl_data_idx;
    /* 0x0A */ s16 parent;
    /* 0x0C */ s16 next;
    /* 0x0E */ s16 link;
    /* 0x10 */ s16 unk_10;
    /* 0x12 */ s16 unk_12;
    /* 0x14 */ void *func;
    /* 0x18 */ void *unk_18;
    /* 0x1C */ u8 data[];
} omObjData;

typedef struct OverlayTableEntry {
    u32 romStart;
    u32 romEnd;
    u32 vramText;
    u32 vramData;
    u32 vramEnd;
    u32 unk14;
    u32 unk18;
    u32 unk1C;
    u32 unk20;
} OverlayTableEntry;

#endif
