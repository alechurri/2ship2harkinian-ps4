#!/usr/bin/env bash
# Cross-builds every third-party dependency of Ship of Harkinian for PS4 into ps4port/prefix.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/env.sh"
SRC="$HERE/deps/src"; BLD="$HERE/deps/build"; PREFIX="$HERE/prefix"
TC="$HERE/cmake/ps4-toolchain.cmake"
mkdir -p "$SRC" "$BLD" "$PREFIX"
W() { cygpath -m "$1"; }

fetch() { # name url tag
    if [ ! -d "$SRC/$1" ]; then
        git -c advice.detachedHead=false clone -q --depth 1 --branch "$3" "$2" "$SRC/$1"
    fi
}
build() { # name srcdir [cmake args...]
    local name="$1" src="$2"; shift 2
    if [ -f "$BLD/$name/.done" ]; then echo "== $name (cached)"; return; fi
    echo "== $name"
    cmake -G Ninja -S "$(W "$src")" -B "$(W "$BLD/$name")" -DCMAKE_TOOLCHAIN_FILE="$(W "$TC")" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(W "$PREFIX")" -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
        "$@" > "$BLD/$name.configure.log" 2>&1 || { tail -40 "$BLD/$name.configure.log"; exit 1; }
    cmake --build "$(W "$BLD/$name")" > "$BLD/$name.build.log" 2>&1 || { tail -60 "$BLD/$name.build.log"; exit 1; }
    cmake --install "$(W "$BLD/$name")" > "$BLD/$name.install.log" 2>&1 || { tail -40 "$BLD/$name.install.log"; exit 1; }
    touch "$BLD/$name/.done"
}

fetch zlib https://github.com/madler/zlib.git v1.3.1
build zlib "$HERE/zlib-cmake" -DZLIB_SRC="$(W "$SRC/zlib")"

# StormLib (MPQ / .otr archives) wants bzip2 next to zlib
fetch bzip2 https://gitlab.com/bzip2/bzip2.git bzip2-1.0.8
build bzip2 "$HERE/bzip2-cmake" -DBZIP2_SRC="$(W "$SRC/bzip2")"

# 2 Ship 2 Harkinian saves the color pictograph photos as PNG
fetch libpng https://github.com/pnggroup/libpng.git v1.6.43
build libpng "$SRC/libpng" -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_EXECUTABLES=OFF \
    -DPNG_FRAMEWORK=OFF -DAWK=OFF -DZLIB_ROOT="$(W "$PREFIX")"

fetch libzip https://github.com/nih-at/libzip.git v1.10.1
build libzip "$SRC/libzip" -DENABLE_COMMONCRYPTO=OFF -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DENABLE_OPENSSL=OFF \
    -DENABLE_WINDOWS_CRYPTO=OFF -DENABLE_BZIP2=OFF -DENABLE_LZMA=OFF -DENABLE_ZSTD=OFF -DBUILD_TOOLS=OFF \
    -DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF -DLIBZIP_DO_INSTALL=ON

fetch tinyxml2 https://github.com/leethomason/tinyxml2.git 10.0.0
build tinyxml2 "$SRC/tinyxml2" -Dtinyxml2_BUILD_TESTING=OFF -DBUILD_TESTING=OFF

fetch json https://github.com/nlohmann/json.git v3.11.3
build json "$SRC/json" -DJSON_BuildTests=OFF -DJSON_Install=ON

fetch spdlog https://github.com/gabime/spdlog.git v1.15.3
build spdlog "$SRC/spdlog" -DSPDLOG_BUILD_EXAMPLE=OFF -DSPDLOG_BUILD_TESTS=OFF -DSPDLOG_INSTALL=ON

fetch ogg https://github.com/xiph/ogg.git v1.3.5
build ogg "$SRC/ogg" -DBUILD_TESTING=OFF -DINSTALL_DOCS=OFF

fetch vorbis https://github.com/xiph/vorbis.git v1.3.7
build vorbis "$SRC/vorbis" -DBUILD_TESTING=OFF

fetch opus https://github.com/xiph/opus.git v1.5.2
build opus "$SRC/opus" -DOPUS_BUILD_PROGRAMS=OFF -DOPUS_BUILD_TESTING=OFF -DOPUS_INSTALL_PKG_CONFIG_MODULE=OFF

fetch opusfile https://github.com/xiph/opusfile.git v0.12
build opusfile "$HERE/opusfile-cmake" -DOPUSFILE_SRC="$(W "$SRC/opusfile")"

fetch SDL https://github.com/libsdl-org/SDL.git release-2.30.9
build SDL "$SRC/SDL" -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF -DSDL2_DISABLE_SDL2MAIN=ON -DSDL2_DISABLE_INSTALL=OFF     -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_OPENGL=OFF -DSDL_OPENGLES=OFF -DSDL_VULKAN=OFF -DSDL_KMSDRM=OFF -DSDL_RPI=OFF     -DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_ESD=OFF     -DSDL_ARTS=OFF -DSDL_NAS=OFF -DSDL_FUSIONSOUND=OFF -DSDL_LIBSAMPLERATE=OFF -DSDL_DBUS=OFF -DSDL_IBUS=OFF -DSDL_FCITX=OFF     -DSDL_LIBUDEV=OFF -DSDL_HIDAPI_LIBUSB=OFF -DSDL_RPATH=OFF -DSDL_DUMMYVIDEO=ON -DSDL_DUMMYAUDIO=ON -DSDL_DISKAUDIO=OFF     -DSDL_OFFSCREEN=OFF -DSDL_LOADSO=OFF -DSDL_DIRECTFB=OFF -DSDL_SYSTEM_ICONV=OFF -DSDL_LIBICONV=OFF -DSDL_CCACHE=OFF     -DSDL_FILESYSTEM=OFF -DSDL_VIRTUAL_JOYSTICK=ON -DSDL_HIDAPI=ON -DSDL_HIDAPI_JOYSTICK=OFF -DSDL_WERROR=OFF

echo "ALL DEPS OK"
