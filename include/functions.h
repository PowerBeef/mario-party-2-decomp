#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include "common_structs.h"

void *MakeHeap(void *addr, u32 size);
void *Malloc(void *heap, u32 size);
void Free(void *ptr);
void MakePermHeap(void *addr, u32 size);
void *MallocPerm(u32 size);
void FreePerm(void *ptr);
void MakeTempHeap(void *addr, u32 size);
void *MallocTemp(u32 size);
void FreeTemp(void *ptr);

void InitObjSys(s32 maxObjects, s32 arg1);
void InitProcess(void);
void SleepProcess(s32 time);
void SleepVProcess(void);

s32 omOvlCallEx(s32 overlayID, s16 event, s16 stat);
void omOvlGotoEx(s32 overlayID, s16 event, u16 stat);
s32 omOvlReturnEx(s16 arg0);

void *ReadMainFS(u32 fileId);
void FreeMainFS(void *ptr);
void PlaySound(s32 soundIndex);
void PlayMusic(s16 musicIndex);

void *GetSpaceData(s16 spaceIndex);
s16 GetAbsSpaceIndexFromChainSpaceIndex(s16 chainIndex, s16 spaceIndex);
void SetPlayerOntoChain(s32 playerIndex, s16 chainIndex, s16 spaceIndex);
GW_PLAYER *GetPlayerStruct(s32 playerIndex);
s16 GetCurrentPlayerIndex(void);
void AdjustPlayerCoins(s32 playerIndex, s16 amount);
s32 IsBoardFeatureDisabled(s32 feature);

#endif
