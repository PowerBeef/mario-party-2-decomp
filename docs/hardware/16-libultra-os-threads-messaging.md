# libultra OS — Threads, Messaging, and Timers

How Nintendo's libultra OS multiplexes the VR4300 for I/O managers, RCP task delivery, and retrace-driven game timing.

## OS Thread Model

libultra implements **preemptive threads** on top of a single VR4300. Each thread has:

- Stack pointer and saved register context
- Priority (0 = highest)
- State: `RUNNING`, `WAITING`, `STOPPED`

| API | VRAM | Role |
|-----|------|------|
| `osCreateThread` | `0x800A6030` | Allocate TCB, set entrypoint |
| `osStartThread` | `0x800A62D0` | Mark runnable, maybe preempt |
| `osStopThread` | `0x800A61A0` | Suspend until restarted |
| `osDestroyThread` | `0x800A6100` | Tear down (rare in retail) |

Boot creates at least two threads from **`0x80000460`**:

```text
osCreateThread(D_800D53F0, id=1, entry=func_800004C0, ...)  // main game thread
osCreateThread(D_800D5400, id=2, entry=func_80000520, ...)  // idle / PI helper
osStartThread(D_800D53F0)
```

Manager threads (PI, VI, SI, AI, RSP) are created during **`osInitialize`** / subsystem init — not all symbols are named in MP2's `symbol_addrs.txt`, but **`osCreatePiManager`** @ `0x8009D7C0` is explicit.

## Message Queues

Threads block on **message queues** instead of polling hardware.

| API | VRAM |
|-----|------|
| `osCreateMesgQueue` | `0x800A5720` |
| `osSendMesg` | `0x800A59C0` |
| `osRecvMesg` | `0x800A5890` |
| `osJamMesg` | `0x800A5940` |

Typical pattern:

```c
// Producer (interrupt or manager thread)
osSendMesg(&queue, (OSMesg)completionFlag, OS_MESG_BLOCK);

// Consumer (game or DMA manager)
osRecvMesg(&queue, &msg, OS_MESG_BLOCK);
```

**`osRecvMesg`** is heavily used in the main segment — RSP task completion, PI DMA done, VI retrace, and controller events all funnel through queues.

## Events and Hardware Interrupts

| API | VRAM | Role |
|-----|------|------|
| `osSetEventMesg` | `0x800A56A0` | Bind `OS_EVENT_*` to a queue |
| `osSetIntMask` | `0x800A5A80` | Mask/unmask CP0 `Status.IE` bits |

Common **`OS_EVENT_*`** bindings in N64 titles:

| Event | Source | Typical consumer |
|-------|--------|------------------|
| `OS_EVENT_VI` | Vertical retrace | Frame pacing, `SleepVProcess` |
| `OS_EVENT_SP` | RSP break | Graphics/audio task completion |
| `OS_EVENT_PI` | PI DMA finish | Overlay load, MainFS read |
| `OS_EVENT_SI` | Controller poll | Input thread |
| `OS_EVENT_AI` | Audio buffer swap | Rare direct use; aspMain uses SP |

MP2 registers VI events early via **`func_8007E260`** @ `0x8007E260` (called from boot). Full interrupt routing: [06-serial-save-interrupts.md](06-serial-save-interrupts.md).

## Timers and `osGetTime`

| API | VRAM | Role |
|-----|------|------|
| `osGetTime` | `0x800A6540` | Read 64-bit counter (µs) |
| `osSetTimer` | `0x800A65D0` | One-shot or periodic alarm |
| `osSetTimerIntr` | `0x800A6800` | Program compare register |

Timers use the **Count** CP0 register incremented at bus clock ÷ 2. HuPrc **`SleepProcess(n)`** often maps frame waits to VI retraces rather than raw timers; **`osGetTime`** appears in profiling and music sync paths.

## Exception and Context Switch

On interrupt or thread preemption:

1. CPU enters exception vector @ **`0x80000400`** (KSEG0)
2. libultra saves GPRs + COP0 on current thread stack
3. ISR runs (short), may **`osSendMesg`**
4. Scheduler picks highest-priority runnable thread
5. Restore context and **`eret`**

Game code rarely touches exception vectors directly; **`osSetIntMask`** is the main game-facing primitive when disabling interrupts around critical sections.

## PI Manager (CPU-side DMA queue)

| API | VRAM | Role |
|-----|------|------|
| `osCreatePiManager` | `0x8009D7C0` | Spawn PI manager thread |
| `osPiGetAccess` | `0x8009D8A0` | Acquire PI bus |
| `osPiRelAccess` | `0x8009D900` | Release PI bus |
| `osEPiStartDma` | `0x8009D9C0` | Start cart DMA |
| `osPiStartDma` | `0x8009DA80` | Legacy PI DMA API |

All cartridge reads (overlays, MainFS, HVQ) go through this queue so multiple subsystems do not stomp PI registers concurrently.

## RSP Task Delivery (CPU → RCP)

CPU builds **`OSTask`** structures and submits via SP manager:

| Field | Purpose |
|-------|---------|
| `t.type` | `M_GFXTASK` or `M_AUDTASK` |
| `t.ucode` | Microcode DRAM pointer |
| `t.ucode_data` | DMEM/ucode data |
| `t.data_ptr` | Display list or audio command list |
| `t.yield_data_ptr` | Yield buffer for gfx |

Submission path (symbol names vary): **`osSpTaskStartGo`** / **`osSpTaskLoad`** → SP interrupt → **`osRecvMesg`** on game thread. See [08-gbi-rsp-microcode.md](08-gbi-rsp-microcode.md) and [12-ai-hardware-and-aspMain.md](12-ai-hardware-and-aspMain.md).

## Thread vs HuPrc (Important Distinction)

| | libultra thread | HuPrc process |
|--|-----------------|---------------|
| Preemption | Yes | No — cooperative |
| Stack | Dedicated per thread | Shared process table stacks |
| Wait | `osRecvMesg`, `osStopThread` | `SleepProcess`, `SleepVProcess` |
| Count | ~6–10 OS threads | Dozens of game processes |

Engine gameplay uses **HuPrc** almost exclusively; **libultra threads** handle hardware and RCP completion. See [18-mp2-cpu-engine-scheduling.md](18-mp2-cpu-engine-scheduling.md).

## Symbol Reference

Generated call counts: [cpu-call-inventory.md](cpu-call-inventory.md) (OS group).

Related hardware docs:

- [03-boot-and-cartridge.md](03-boot-and-cartridge.md) — PI hardware
- [06-serial-save-interrupts.md](06-serial-save-interrupts.md) — SI + exception table
- [15-cpu-software-stack-overview.md](15-cpu-software-stack-overview.md) — stack diagram
