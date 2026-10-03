# 2 Ship 2 Harkinian for PS4

An experimental native port of [2 Ship 2 Harkinian](https://github.com/HarbourMasters/2ship2harkinian)
5.0.1 "Battler Bravo" (the PC port of the *Majora's Mask* decompilation) to jailbroken PS4
consoles. It is built with the [OpenOrbis toolchain](https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain)
and renders through Piglet, Sony's OpenGL ES 2.0 implementation. It is not an emulator.

It is the sibling of [soh-ps4](https://github.com/alechurri/soh-ps4) (Ocarina of Time) and shares
its platform layer.

**Download:** the installable package is on the [Releases page](https://github.com/alechurri/2s2h-ps4/releases).

Where everything lives:

| Repository | Contents |
| --- | --- |
| [alechurri/2s2h-ps4](https://github.com/alechurri/2s2h-ps4) (this one) | Releases, build scripts, CMake toolchain, documentation |
| [alechurri/2ship2harkinian, branch `ps4`](https://github.com/alechurri/2ship2harkinian/tree/ps4) | 2 Ship 2 Harkinian 5.0.1 with the PS4 changes applied |
| [alechurri/libultraship, branch `ps4-2s2h`](https://github.com/alechurri/libultraship/tree/ps4-2s2h) | libultraship with the PS4 platform layer and renderer |

**None of this contains game assets or Sony binaries.** You need your own legally obtained ROM,
and the two Piglet modules described in the install guide.

> **Status: early.** Tested on one console only: PS4 Pro, firmware 12.52, GoldHEN, for about two
> hours of play (title screen, intro, Clock Town and surroundings). Reports are welcome.

## What works

- Graphics, audio (music, sound effects, voices), DualShock 4, saves
- Frame interpolation to 60 fps; in busy areas such as Clock Town it runs at about 53 to 59 fps
  (see below)
- The 2S2H menu (touchpad click): graphics options, enhancements

Not tested yet: Randomizer, mods.

## Known limitations

- **Frame rate in busy scenes.** Drawing is CPU-bound: each presented frame costs 13 to 17 ms of
  CPU time in Clock Town, the GPU is almost idle, so lowering the internal resolution does not
  help. Setting the frame interpolation to 30 fps in the menu gives a steadier picture.
- **Long boot.** Piglet cannot cache compiled shaders, so every shader the game has used is
  compiled at boot (about 45 s once you have played for a while). The first time a shader is
  needed while playing there is a hitch of about 0.2 s.
- No MSAA, no gyro aiming, 16-bit depth for offscreen framebuffers, light glows not occluded by
  walls (GLES2 cannot read the depth buffer back).
- No ROM extractor on the console; assets are generated on a PC.
- This build still writes diagnostic lines to its log (audio queue, frame time). They are cheap
  and help with bug reports.

## Installing

Full walkthrough: **[docs/INSTALL.md](docs/INSTALL.md)**. In short:

1. Generate `mm.o2r` from your ROM with 2 Ship 2 Harkinian **5.0.1** on a PC.
2. Copy `mm.o2r` to `/data/2ship/` and the two Piglet modules to `/data/self/system/common/lib/`
   on the console over FTP.
3. Install the `.pkg` with GoldHEN's Package Installer and launch the game.

## Controls

| DualShock 4 | N64 |
| --- | --- |
| Cross | A |
| Circle | B |
| L2 | Z |
| R2 | R |
| L1 | L |
| OPTIONS | Start |
| Right stick | C buttons |
| D-pad | D-pad |
| **Touchpad click** | opens / closes the 2S2H menu |

Everything can be remapped from the menu.

## Building

See **[docs/BUILDING.md](docs/BUILDING.md)**. The build runs on Windows (Git Bash) with portable
copies of LLVM 18, CMake, Ninja and the OpenOrbis toolchain.

## How it works

[docs/TECHNICAL.md](docs/TECHNICAL.md) describes the port and the bugs that only showed up on real
hardware. Several of them are latent in 2 Ship 2 Harkinian on every platform and only became
visible because of how the PS4 lays out memory.

## Disclosure

The person who published this port is not a C++ developer. The code was written with an AI coding
assistant (Claude) and debugged by installing builds on a console and feeding the logs back. It
has had no review by anyone who knows the 2 Ship 2 Harkinian or libultraship codebases; review and
corrections are very welcome.

## Credits

- The [HarbourMasters](https://github.com/HarbourMasters) team for 2 Ship 2 Harkinian and
  [libultraship](https://github.com/Kenix3/libultraship), which is where all of the actual game
  port lives.
- The [OpenOrbis](https://github.com/OpenOrbis) team for the toolchain.
- flat_z and the orbisdev contributors for the Piglet research, and OsirizX's
  [Super Mario 64 PS4 port](https://github.com/OsirizX/sm64-port/tree/ps4), which showed how to
  bring Piglet up with runtime shader compilation.

## License

The build scripts, CMake files and documentation in this repository are released under the
[MIT License](LICENSE). The files under `patches/` are modifications of 2 Ship 2 Harkinian and
libultraship and remain subject to the terms of those projects.

This project is not affiliated with or endorsed by Nintendo or Sony.
