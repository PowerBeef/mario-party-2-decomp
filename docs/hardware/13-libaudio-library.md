# libaudio Library

Nintendo's **libaudio** SDK layer — synthesizer, sequence player, sound player, and the pull-based audio processing graph used by Mario Party 2.

## Architecture

```mermaid
flowchart TB
    subgraph players [High-level players]
        SeqP[alSeqp sequence player]
        SndP[alSndp sound player]
    end
    subgraph core [Synthesizer]
        Syn[alSyn voice pool]
    end
    subgraph graph [Processing graph pull nodes]
        Load[alLoad]
        Env[alEnvmixer]
        Res[alResample]
        Aux[alAuxBus]
        Main[alMainBus]
        Fx[alFx reverb]
        Save[alSave PCM out]
    end
    subgraph frame [Per tick]
        AF[alAudioFrame]
    end
    SeqP --> Syn
    SndP --> Syn
    Syn --> Load --> Env --> Res --> Main
    Main --> Aux --> Fx
    Main --> Save
    AF --> SeqP
    AF --> SndP
    AF --> graph
    Save --> RSP[aspMain acmd]
```

MP2 links the **full libaudio stack** — ~80 symbols in [`symbol_addrs.txt`](../../symbol_addrs.txt).

## Heap and File Loading

| Function | VRAM | Role |
|----------|------|------|
| `alHeapInit` | `0x8009EB70` | Initialize audio heap |
| `alHeapDBAlloc` | `0x8009EBB0` | Double-buffered heap alloc |
| `alHeapCheck` | `0x800A8530` | Heap integrity |
| `alBnkfNew` | `0x8009E4A0` | Load **instrument bank** file (.bank) |
| `alSeqFileNew` | `0x8009E534` | Load **sequence** file (.seq) |
| `alCSeqNew` | `0x8009F258` | Compact sequence parser |

Audio heap is separate from game **`HuMem`** heaps — typically a fixed RDRAM region @ `D_800D7B08`.

### Bank file contents

- Instrument definitions (program → sample mapping)
- **ADPCM** sample blobs or pointers into ROM
- Envelope (ADSR) tables
- Key map, velocity layers

### Sequence file contents

- MIDI-like event stream: tempo, program change, note on/off, pitch bend
- Track markers for looping / branching

## Sequence Player (`alSeqp*`)

Drives **background music**. MP2 music cluster @ `0x8000ECB8`–`0x800100BC` is dominated by these calls.

| Function | VRAM | Role |
|----------|------|------|
| `alSeqpNew` | `0x800AC0F4` | Create sequence player |
| `alSeqpSetSeq` | `0x8009F8A0` | Assign sequence data |
| `alSeqpSetBank` | `0x8009F870` | Assign instrument bank |
| `alSeqpPlay` | `0x8009F840` | Start playback |
| `alSeqpStop` | `0x8009F950` | Stop |
| `alSeqpSetVol` | `0x8009F920` | Master volume |
| `alSeqpSetTempo` | `0x8009F8D0` | Tempo scale |
| `alSeqpGetState` | `0x8009F830` | Running / stopped |
| `alSeqpDelete` | `0x8009F700` | Tear down |
| `alSeqpGetChlVol/Pan/Program/FXMix` | `0x8009F720`+ | Per-channel query |

### Internal sequence engine

| Function | Role |
|----------|------|
| `alCSeqNextEvent` | Parse next MIDI event |
| `alCSeqNextDelta` | Time until next event |
| `postNextSeqEvent` | Schedule event on queue |
| `alEvtqNew/PostEvent/NextEvent` | Event timing queue |

Sequence player allocates **`alSyn`** voices for each note and releases them on note-off.

## Sound Player (`alSndp*`)

Drives **one-shot SFX** — the path behind **`PlaySound`**.

| Function | VRAM | Role |
|----------|------|------|
| `alSndpNew` | (via init) | Create sound player |
| `alSndpAllocate` | `0x800A0C10` | Grab sound handle |
| `alSndpSetSound` | `0x800A0D20` | Bind sample from bank |
| `alSndpPlay` | `0x800A0D30` | Start one-shot |
| `alSndpStop` | `0x800A0D90` | Stop |
| `alSndpSetVol/Pan/Pitch/FXMix/Priority` | `0x800A0E00`+ | Parameters |
| `alSndpDeallocate` | `0x800A0CD0` | Release handle |
| `alSndpGetState` | `0x800A0DE0` | Playing / done |

### Internal lookup

| Function | VRAM | Role |
|----------|------|------|
| `lookupSoundQuick` | `0x800ABA3C` | Fast bank index → sample |
| `initFromBank` | `0x800ABB10` | Initialize voice from bank entry |

Priority and **`alSndpSetPriority`** control voice stealing when the pool is full.

## Synthesizer (`alSyn*`)

Central **voice pool** shared by sequence and sound players.

| Function | VRAM | Role |
|----------|------|------|
| `alSynNew` | `0x800A1244` | Create synthesizer |
| `alSynAddPlayer` | `0x800A15C0` | Register seq/snd player |
| `alSynRemovePlayer` | `0x800A1610` | Unregister |
| `alSynAllocVoice` | `0x800A1750` | Allocate voice slot |
| `alSynFreeVoice` | `0x800A16B0` | Release voice |
| `alSynStartVoice` | `0x800A19B0` | Begin note/sample |
| `alSynStopVoice` | `0x800A1930` | Stop note |
| `alSynSetVol/Pitch/Pan/FXMix` | `0x800A1AE0`+ | Per-voice params |
| `alSynStartVoiceParams` | `0x80092AF0` | Bulk param setup |
| `alSynSetPriority` | `0x800AD220` | Voice priority |
| `alSynAllocFX` | `0x800A1C40` | FX resource |

Internal voice mapping: `lookupVoice`, `mapVoice`, `unmapVoice`, `seqpReleaseVoice`.

## Audio Processing Graph

Pull-based node architecture — each node implements **Param** (configure) and **Pull** (generate samples).

| Node | Pull function | Role |
|------|---------------|------|
| `alLoad` | `alLoadNew` | Fetch ADPCM/PCM sample data |
| `alEnvmixer` | `alEnvmixerPull` | ADSR envelope application |
| `alResample` | `alResamplePull` | Pitch / sample-rate conversion |
| `alAuxBus` | `alAuxBusPull` | Send to reverb bus |
| `alMainBus` | `alMainBusPull` | Sum voices to master |
| `alFx` | `alFxPull` | Reverb / delay |
| `alSave` | `alSavePull` | Write final PCM for RSP |
| `alFilter` | `alFilterNew` | Optional low-pass |

Nodes are wired at init (`alEnvmixerNew`, `alMainBusNew`, etc.) and traversed each **`alAudioFrame`**.

## alAudioFrame

| Property | Value |
|----------|-------|
| VRAM | `0x800A1094` |
| Called | Once per audio tick on audio thread |
| Role | Advance players, update graph, build acmd, submit `M_AUDTASK` |

Per-frame work:

1. **`alEvtqNextEvent`** — fire due sequence events
2. Update envelope states on active voices
3. Walk processing graph (pull samples through nodes)
4. Build acmd list for aspMain
5. **`osSpTaskStartGo`** with `M_AUDTASK`
6. Queue next PCM buffer with AI if needed

## Sample Formats

### ADPCM (`alAdpcmPull` @ `0x800A9448`)

- **4-bit** Nintendo ADPCM — primary format for music and SFX samples
- ~1:4 compression vs 16-bit PCM
- Decoder maintains predictor state per voice
- Book/order tables in bank file header

### Raw 16 (`alRaw16Pull` @ `0x800A90AC`)

- Uncompressed 16-bit PCM — rare, used for short high-quality samples

### Envelope

- **`alEnvmixer`** applies attack/decay/sustain/release from bank tables
- Shapes note amplitude over time

## Event Queue (`alEvtq*`)

| Function | Role |
|----------|------|
| `alEvtqNew` | Create queue |
| `alEvtqPostEvent` | Schedule future event |
| `alEvtqNextEvent` | Pop due event |
| `alEvtqFlush` | Clear queue |

Used for sample-accurate sequence timing between `alAudioFrame` calls.

## MP2 Call Density (main segment)

| Region | APIs | Purpose |
|--------|------|---------|
| `0x8000ED00`–`0x800100BC` | `alSeqp*` | Music, fades, track changes |
| `0x80012400`–`0x80014274` | `alSndp*` | PlaySound SFX path |
| `0x8007EFD8`+ | `alSyn*` | Direct synth voice (engine) |

See [audio-call-inventory.md](audio-call-inventory.md) for exact counts.

## Related Docs

- [12-ai-hardware-and-aspMain.md](12-ai-hardware-and-aspMain.md) — RSP side (aspMain)
- [14-mp2-audio-engine-and-assets.md](14-mp2-audio-engine-and-assets.md) — Engine wrappers
- [11-audio-pipeline-overview.md](11-audio-pipeline-overview.md) — Pipeline summary
