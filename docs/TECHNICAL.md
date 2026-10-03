# Technical notes

The platform layer (Piglet renderer, EGL setup, DualShock 4 through scePad, sceAudioOut, heap,
logging) is the one from [shipofharkinian-ps4](https://github.com/alechurri/shipofharkinian-ps4/blob/main/docs/TECHNICAL.md),
carried over to the newer libultraship that 2 Ship 2 Harkinian 5.0.1 uses (`7cb1022`). Read that
document first; this one covers what was different, and the bugs found on the way.

## Porting to the newer libultraship

- **Input before graphics.** This libultraship attaches the controller in `InitControlDeck`,
  before the window exists. The user service, pad and audio modules used to be loaded by the
  graphics init, so the first `scePad` call jumped into a module that was not loaded yet and the
  app died without a trace. `Ship::Ps4::LoadSystemModules()` now runs before any of them is used.
- **Renderer interface.** The second shader id is 64 bits wide, there is a `ClearShaderCache` and a
  `ClearDepthRegion`, and `G_ZS_PRIM` (primitive depth). GLES2 has no `gl_FragDepth`, so the
  primitive depth is written in the vertex shader instead; it is constant over the primitive, so
  the result is the same.
- **libpng** is needed (colour pictograph photos are saved as PNG).

## Bugs that only showed on PS4

On PC every one of these lands on harmless memory, or on memory that happens to be zero. On PS4 the
executable is loaded at 0x400000, its globals sit below 2 GiB right after each other, and the heap
recycles memory, so they became hangs, crashes or silence.

1. **Every note was skipped.** `AudioPlayback_ProcessNotes` ignored any note whose sequence layer
   pointer was below `0x7FFFFFFF`, a leftover from N64 address ranges (Wii U already had an
   exception). The layers live in `gAudioCtx`, a global, so on PS4 no note ever got its volume,
   pitch or sample state updated: notes kept the position of the previous sound and ran past the
   end of the new one. Symptoms: Link's voice silent, sounds cut off, and (through bug 3) memory
   corruption, hangs and crashes.
2. **`OSMesg` received into a `u32`.** `OSMesg` is pointer sized in the port; four audio queues were
   received straight into 32-bit variables, so every message wrote 4 bytes past them. With clang
   that hit the saved frame pointer.
3. **DMEM writes outside the mixer buffer.** A note past its end made the sample counts in
   `AudioSynth_ProcessSample` negative, and the DMEM addresses derived from them wrapped to values
   such as `0xB532`. The N64's RSP masks DMEM addresses to 4 KiB; the port's mixer indexes a
   3 KiB array with them and wrote up to 64 KiB past it, over the audio globals (the script load
   queue, the sfx lists, `gFontMap`). The synthesis now clamps the count, and on PS4 every mixer
   access is checked: out of range addresses go to a scratch area and sizes are bounded.
4. **`sampleEnd` never set.** Majora's Mask keeps the total sample count at offset 0x0C of
   `AdpcmLoop`; the resource importer never filled it. It is now computed from the size and codec.
   (No sample in the archive actually uses it, loops have a count of 0 or -1.)
5. **Script load index 0xFF.** A failed async load reports `0xFFFFFFFF`, and its index was used to
   read entry 255 of a 16 entry array and write through whatever pointer was there.

## Audio pacing

Audio is produced on the game thread's schedule, once per game frame, and the game runs slightly
under 60 fps in busy areas. The audio thread now adds updates when the output queue runs low and
skips one when it is full, like the N64, whose audio ran on its own clock. The output keeps a
100 ms cushion, since `sceAudioOut` has no buffer of its own beyond one 256 frame block.

## Performance

Measured per presented frame in Clock Town: about 0.1 ms waiting for the GPU and 13 to 17 ms of CPU
building the frame. With frame interpolation at 60 fps the display list is interpreted three times
per game frame, and Majora's Mask scenes are much busier than Ocarina of Time ones. Resolution does
not matter; the next step would be measuring the interpreter against Piglet's driver calls.

## Diagnostics left in

- Crashes and freezes: `sceKernelInstallExceptionHandler` (kernel signal numbers, not musl's) and a
  watchdog that interrupts the game thread with `sceKernelRaiseException` when no frame is
  presented for 6 s. Reports print code offsets; `symbolize.py` turns them into function names.
- `[PS4] audio:` and `[PS4] frame time` lines every few seconds.
- Guards that log and repair instead of hanging: `DMEM OUT OF RANGE`, `SFX LIST BROKEN`,
  `AUDIO CORRUPTION`, `NOTE PAST END`. None of them fire in a normal session with this build.
