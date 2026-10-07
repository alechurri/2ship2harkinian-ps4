# Installation guide

## Requirements

- A PS4 with a jailbreak that can install fake packages and run an FTP server. The port has only
  been tested on a **PS4 Pro, firmware 12.02, with GoldHEN**.
- A PC (Windows, Linux or macOS) to generate the game assets.
- Your own *Majora's Mask* ROM, in a version 2 Ship 2 Harkinian supports (the US N64 release; the
  US GameCube release is also accepted by 2S2H).
- An FTP client such as FileZilla.

You will end up with these files on the console:

| File | Where it comes from | Destination on the PS4 |
| --- | --- | --- |
| `IV0000-TSHP00001_00-TWOSHIPHARKINIAN.pkg` | [Releases page](https://github.com/alechurri/2ship2harkinian-ps4/releases) | installed as a package |
| `mm.o2r` | generated from your ROM, step 1 | `/data/2ship/` |
| `libScePigletv2VSH.sprx` | see step 2 | `/data/self/system/common/lib/` |
| `libSceShaccVSH.sprx` | see step 2 | `/data/self/system/common/lib/` |

It installs next to the Ocarina of Time port ([shipofharkinian-ps4](https://github.com/alechurri/shipofharkinian-ps4)),
they don't replace each other. If you already run that one, the two `.sprx` files are already in
place.

## Step 1: generate `mm.o2r` on a PC

The console build has no ROM extractor, so the asset archive is made with the regular PC release.

1. Download 2 Ship 2 Harkinian **5.0.1** for your PC from
   <https://github.com/HarbourMasters/2ship2harkinian/releases/tag/5.0.1>.
   It has to be exactly 5.0.1: archives created by a different major version are rejected.
2. Unzip it and run it.
3. When asked, select your ROM. The program extracts the assets and writes `mm.o2r` next to the
   executable. If your ROM ends in `.n64` (byte-swapped), convert it to `.z64` first.
4. Close the program. `mm.o2r` is the only file you need from that folder.

## Step 2: get the two Piglet modules

Piglet is Sony's OpenGL ES library. Retail firmware ships it without its runtime shader compiler,
so GLES homebrew uses a matching pair of modules:

- `libScePigletv2VSH.sprx`
- `libSceShaccVSH.sprx`

They are Sony binaries and are **not** distributed here. Two ways to get them:

- **From the Super Mario 64 PS4 port.** Its release archive carries them under
  `data/self/system/common/lib/`.
- **From RetroArch for PS4.** Install and start RetroArch, then connect over FTP while it is
  running: its `sce_module` folder is mounted in the app sandbox and holds both files. This route
  comes from the [OpenPS4 orbisdev install guide](https://github.com/OpenPS4/guide-to-install-orbisdev)
  and has not been tested with this port yet.

Check them before copying, a damaged copy is the most common cause of the game not starting:

| File | Size (bytes) | SHA-256 |
| --- | --- | --- |
| `libScePigletv2VSH.sprx` | 744,208 | `69d6b3adc85b6edf5208b7f18fad3b2638ae7c4648f78880877bae3aa4202efd` |
| `libSceShaccVSH.sprx` | 10,394,272 | `0a64982b0d7e33701745ab5180a1d314c11980215e418d14e868c75de3ca1e12` |

## Step 3: copy the files over FTP

1. On the PS4, with GoldHEN loaded: *Settings → GoldHEN → Server Settings → Enable FTP Server*.
   Note the console's IP address.
2. In FileZilla connect to that IP, port **2121**, with empty user name and password.
3. Set *Transfer → Transfer type → Binary*. In automatic or text mode the `.sprx` files get
   corrupted. **Do not use WinSCP for the `.sprx` files.**
4. Upload, all of them in **binary mode** (step 3.3):
   - `mm.o2r` → `/data/2ship/` (create the `2ship` folder inside `/data` if it does not exist)
   - both `.sprx` files → `/data/self/system/common/lib/` (create the folders if needed)
   - the `.pkg` → `/data/pkg/` (create it if needed), or put it on a USB drive instead

## Step 4: install the package

*Settings → GoldHEN → Package Installer* (or *Debug Settings → Game → Package Installer*), pick
the package and install it. To update later, install the new package over the old one; saves and
settings live in `/data/2ship/` and are not touched.

## Step 5: play

Launch "2 Ship 2 Harkinian" from the home screen.

- The **first run** compiles shaders as they are needed, so expect short hitches when new effects
  appear. They are remembered in `/data/2ship/ps4_shaders.txt`.
- From the **second run** on, those shaders are compiled at boot, behind the system splash screen.
  The more you have played, the longer this takes (about 45 s after a couple of hours).
- Press the **touchpad** to open the 2S2H menu.
- Controls follow the N64 layout: **Cross = A, Circle = B, OPTIONS = Start** (Square and
  Triangle are not A/B), L2 = Z, R2 = R, right stick = C buttons. Full table in the
  [README](../README.md#controls); everything can be remapped from the menu.

## Files the game creates in `/data/2ship/`

| File | Purpose |
| --- | --- |
| `saves/` | Save files |
| `2ship2harkinian.json` | Settings |
| `mods/` | Mods (not tested on PS4 yet) |
| `ps4_boot.log` | Log of the last run. This is the file to attach to any bug report. |
| `logs/` | The regular 2 Ship 2 Harkinian log |
| `ps4_shaders.txt` | List of shaders to precompile at boot. Safe to delete (boot gets faster, hitches come back). |
| `imgui.ini` | Menu layout |

Optional marker file:

| File | Effect |
| --- | --- |
| `ps4_vsync` (empty) | Enables vertical sync. Off by default. |

## Recommended settings

- Internal resolution: anything up to about 150%. It makes no difference to the frame rate (the
  bottleneck is the CPU).
- Frame interpolation: 60 fps runs at 53 to 59 fps in busy areas; 30 fps is steadier.

## Troubleshooting

**The game drops back to the home screen immediately (CE-34878-0).**
Almost always the Piglet modules. Open `/data/2ship/ps4_boot.log` and look for
`sceKernelLoadStartModule(".../libScePigletv2VSH.sprx") failed`:

- `0x80020002`: the file is not there. Check the folder name, `/data/self/system/common/lib/`.
- `0x8002000D`: the file is there but damaged, usually by an FTP client in text mode or by
  WinSCP. Delete both `.sprx` files on the console, check their size and SHA-256 on the PC (table
  in step 2), and upload them again with FileZilla in binary mode.

If the modules load, the last lines of the log say how far the game got. A crash or a freeze is
written to the log as a `[PS4] FATAL` or `[PS4] HANG` report with code addresses.

**A popup says "No ROM Archive".**
`mm.o2r` is missing from `/data/2ship/`.

**A popup says "Outdated ROM Archive".**
`mm.o2r` was generated with a version of 2 Ship 2 Harkinian other than 5.0.1.

**Anything else.**
Open an issue and attach `/data/2ship/ps4_boot.log`, with your console model and firmware version.
Download the log before starting the game again, each run overwrites it.
