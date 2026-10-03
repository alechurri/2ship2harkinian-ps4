# Building

The port has been built on **Windows 11 from Git Bash**, with portable tools. The scripts are
plain bash and CMake, so Linux should work with small changes (use the `linux` binaries of the
OpenOrbis tools), but that has not been tried. The setup is the same as for
[soh-ps4](https://github.com/alechurri/soh-ps4); one workspace can hold both.

## Workspace layout

Everything lives side by side in one workspace directory, and this repository has to be cloned
under the name `ps4port`:

```
<workspace>/
├─ ps4port/          this repository
├─ 2ship2harkinian/  2 Ship 2 Harkinian 5.0.1 + the patches
└─ tools/
   ├─ llvm/                                  LLVM 18.1.8 (clang, ld.lld, llvm-ar...)
   ├─ cmake-<version>-windows-x86_64/        CMake 3.26 or newer
   ├─ ninja/                                 ninja.exe
   └─ OpenOrbis/OpenOrbis/PS4Toolchain/      OpenOrbis toolchain v0.5.4
```

## 1. Tools

Download and unpack into `tools/` as shown above:

- **LLVM 18.1.8** for Windows: `LLVM-18.1.8-win64.exe` from the
  [LLVM releases](https://github.com/llvm/llvm-project/releases/tag/llvmorg-18.1.8). It is a
  self-extracting archive; it can be unpacked with 7-Zip instead of installed
  (`7z x -otools/llvm LLVM-18.1.8-win64.exe`).
- **CMake** (`cmake-*-windows-x86_64.zip`) and **Ninja** (`ninja-win.zip`).
- **OpenOrbis toolchain v0.5.4**: `toolchain-llvm-18.tar.gz` from the
  [OpenOrbis releases](https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain/releases/tag/v0.5.4),
  extracted into `tools/OpenOrbis/`.
- Git, Python 3 and a .NET runtime (`PkgTool.Core` is a .NET application; any recent runtime
  works, the scripts set `DOTNET_ROLL_FORWARD`).

## 2. Sources

The patched sources are published as forks. The 2 Ship 2 Harkinian fork's submodule already
points at the libultraship fork (branch `ps4-2s2h`), so one recursive clone gets everything:

```bash
cd <workspace>
git clone --recurse-submodules --branch ps4 https://github.com/alechurri/2ship2harkinian.git
git clone https://github.com/alechurri/2s2h-ps4.git ps4port
```

Alternatively, the same changes are available as patches against the upstream repositories
(2 Ship 2 Harkinian tag 5.0.1, commit `8a24047`, and libultraship `7cb1022`):

```bash
git clone --recurse-submodules --branch 5.0.1 https://github.com/HarbourMasters/2ship2harkinian.git
cd 2ship2harkinian
git apply ../ps4port/patches/2ship2harkinian-5.0.1-ps4.patch
cd libultraship
git apply ../../ps4port/patches/libultraship-ps4.patch
```

## 3. Dependencies

```bash
cd <workspace>/ps4port
./build-deps.sh
```

Cross-builds zlib, bzip2, libpng, libzip, tinyxml2, nlohmann-json, spdlog, ogg, vorbis, opus,
opusfile and SDL2 2.30.9 into `ps4port/prefix/`. This is only needed once (but again after
changing the toolchain file: everything has to be rebuilt with the same flags).

## 4. Game

```bash
./configure.sh
source env.sh
cmake --build build --target 2ship
```

The result is `build/mm/2ship.elf`. The toolchain compiles for the PS4's CPU (`-march=btver2`),
keeps frame pointers and line tables (`-gline-tables-only`) so crash reports can be resolved; none
of this changes what goes into the package.

## 5. Package

`package.sh` needs the `2ship.o2r` of the matching PC release (it holds 2 Ship 2 Harkinian's own
assets, no game data). Take it from the 5.0.1 release zip and put it in `ps4port/release-pc/`:

```bash
mkdir -p release-pc
unzip -o 2Ship-Battler-Bravo-Win64.zip 2ship.o2r -d release-pc
./package.sh
```

The package is written to `ps4port/out/`.

### Self-contained package (personal use only)

`package.sh` can also bundle the Piglet modules and your ROM archive, so that nothing has to be
copied to `/data` by hand. Such a package contains Sony binaries and game assets: **do not
distribute it.**

```bash
BUNDLE_SPRX_DIR=/path/to/dir/with/both/sprx \
BUNDLE_MM_O2R=/path/to/mm.o2r \
OUT_DIR="$PWD/out-personal" ./package.sh
```

## Reading crash reports

When the game crashes or freezes, `/data/2ship/ps4_boot.log` gets a `[PS4] FATAL` or
`[PS4] HANG` report with code offsets. With the exact `2ship.elf` that went into the package:

```bash
py symbolize.py build/mm/2ship.elf ps4_boot.log
```

prints the function names; `llvm-symbolizer --obj=build/mm/2ship.elf 0x<offset>` gives file and
line.
