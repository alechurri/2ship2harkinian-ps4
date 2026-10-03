#!/usr/bin/env bash
# Configures the 2 Ship 2 Harkinian (Majora's Mask) PS4 build in ps4port/build-mm.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/env.sh"
W() { cygpath -m "$1"; }
cmake -G Ninja -S "$(W "$HERE/../2ship2harkinian")" -B "$(W "$HERE/build")" \
    -DCMAKE_TOOLCHAIN_FILE="$(W "$HERE/cmake/ps4-toolchain.cmake")" \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPUSFILE_INCLUDE_DIR="$(W "$HERE/prefix/include/opus")" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    "$@"
