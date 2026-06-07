#include "common.h"
#include "functions.h"
#include "variables.h"

void MakePermHeap(void *addr, u32 size) {
    permHeapPtr = MakeHeap(addr, size);
}

void *MallocPerm(u32 size) {
    return Malloc(permHeapPtr, size);
}

void FreePerm(void *ptr) {
    Free(ptr);
}

void MakeTempHeap(void *addr, u32 size) {
    tempHeapPtr = MakeHeap(addr, size);
}

void *MallocTemp(u32 size) {
    return Malloc(tempHeapPtr, size);
}

void FreeTemp(void *ptr) {
    Free(ptr);
}
