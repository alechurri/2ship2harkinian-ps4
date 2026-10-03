# CMake toolchain for PS4 homebrew using the OpenOrbis toolchain + stock LLVM.
#
#   cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=<this file> ...
#
# Paths default to the layout of this repo (<workspace>/tools/...), override with
# -DOO_PS4_TOOLCHAIN=... / -DPS4_LLVM_BIN=... or the matching environment variables.

set(CMAKE_SYSTEM_NAME PS4)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_CROSSCOMPILING TRUE)
set(PS4 TRUE)

get_filename_component(_PS4_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

if(NOT OO_PS4_TOOLCHAIN)
    if(DEFINED ENV{OO_PS4_TOOLCHAIN})
        file(TO_CMAKE_PATH "$ENV{OO_PS4_TOOLCHAIN}" OO_PS4_TOOLCHAIN)
    else()
        set(OO_PS4_TOOLCHAIN "${_PS4_ROOT}/tools/OpenOrbis/OpenOrbis/PS4Toolchain")
    endif()
endif()
if(NOT PS4_LLVM_BIN)
    if(DEFINED ENV{PS4_LLVM_BIN})
        file(TO_CMAKE_PATH "$ENV{PS4_LLVM_BIN}" PS4_LLVM_BIN)
    else()
        set(PS4_LLVM_BIN "${_PS4_ROOT}/tools/llvm/bin")
    endif()
endif()
if(NOT PS4_PREFIX)
    set(PS4_PREFIX "${_PS4_ROOT}/ps4port/prefix")
endif()
set(OO_PS4_TOOLCHAIN "${OO_PS4_TOOLCHAIN}" CACHE PATH "OpenOrbis toolchain root")
set(PS4_LLVM_BIN "${PS4_LLVM_BIN}" CACHE PATH "LLVM bin directory")
set(PS4_PREFIX "${PS4_PREFIX}" CACHE PATH "Install prefix of the cross-built dependencies")

# try_compile() re-reads this file in a fresh scope: forward what it needs.
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES OO_PS4_TOOLCHAIN PS4_LLVM_BIN PS4_PREFIX)

if(CMAKE_HOST_WIN32)
    set(_EXE ".exe")
    set(PS4_HOST_BIN "${OO_PS4_TOOLCHAIN}/bin/windows")
else()
    set(_EXE "")
    set(PS4_HOST_BIN "${OO_PS4_TOOLCHAIN}/bin/linux")
endif()

set(CMAKE_C_COMPILER "${PS4_LLVM_BIN}/clang${_EXE}")
set(CMAKE_CXX_COMPILER "${PS4_LLVM_BIN}/clang++${_EXE}")
set(CMAKE_ASM_COMPILER "${PS4_LLVM_BIN}/clang${_EXE}")
set(CMAKE_AR "${PS4_LLVM_BIN}/llvm-ar${_EXE}" CACHE FILEPATH "")
set(CMAKE_RANLIB "${PS4_LLVM_BIN}/llvm-ranlib${_EXE}" CACHE FILEPATH "")
set(CMAKE_NM "${PS4_LLVM_BIN}/llvm-nm${_EXE}" CACHE FILEPATH "")
set(CMAKE_STRIP "${PS4_LLVM_BIN}/llvm-strip${_EXE}" CACHE FILEPATH "")
set(CMAKE_OBJCOPY "${PS4_LLVM_BIN}/llvm-objcopy${_EXE}" CACHE FILEPATH "")
set(PS4_LINKER "${PS4_LLVM_BIN}/ld.lld${_EXE}")

set(_PS4_TARGET x86_64-pc-freebsd12-elf)
set(CMAKE_C_COMPILER_TARGET ${_PS4_TARGET})
set(CMAKE_CXX_COMPILER_TARGET ${_PS4_TARGET})
set(CMAKE_ASM_COMPILER_TARGET ${_PS4_TARGET})


# try_compile links real executables (the link rule below is complete), so feature checks are accurate.

# Flags every translation unit needs. They are injected through the compile rules
# (see Platform/PS4.cmake) instead of CMAKE_<LANG>_FLAGS because several third-party
# projects overwrite CMAKE_CXX_FLAGS wholesale.
#  - libc++ headers have to come before the C headers (they wrap them with #include_next).
#  - our own builds (SDL2 2.30...) must win over the old copies bundled with OpenOrbis.
set(_PS4_COMMON "-fPIC -funwind-tables -fno-omit-frame-pointer -gline-tables-only -march=btver2 -D__PS4__ -D__ORBIS__ -D_BSD_SOURCE -D_GNU_SOURCE -isysroot \"${OO_PS4_TOOLCHAIN}\"")
# ps4_fixups.h corrects the struct stat layout of the OpenOrbis headers; it has to be seen
# before any system header, hence the forced include.
set(_PS4_COMPAT "-isystem \"${_PS4_ROOT}/ps4port/compat/include\" -include \"${_PS4_ROOT}/ps4port/compat/include/ps4_fixups.h\"")
set(_PS4_PREFIX_INC "-isystem \"${PS4_PREFIX}/include\"")
set(PS4_C_MANDATORY_FLAGS "${_PS4_COMMON} ${_PS4_PREFIX_INC} -isystem \"${OO_PS4_TOOLCHAIN}/include\" ${_PS4_COMPAT}")
set(PS4_CXX_MANDATORY_FLAGS "${_PS4_COMMON} -nostdinc++ -isystem \"${OO_PS4_TOOLCHAIN}/include/c++/v1\" ${_PS4_PREFIX_INC} -isystem \"${OO_PS4_TOOLCHAIN}/include\" ${_PS4_COMPAT} -fexceptions -fcxx-exceptions")

set(CMAKE_C_FLAGS_DEBUG_INIT "-g -O0")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g -O0")
set(CMAKE_C_FLAGS_RELEASE_INIT "-O2 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O2 -DNDEBUG")

# System libraries every executable gets. Extra SCE libraries are added per target
# through PS4_SCE_LIBS.
set(PS4_BASE_LIBS "-lc++ -lc++abi -lunwind -lc -lkernel -lclang_rt.builtins-x86_64")
set(PS4_SCE_LIBS "-lSceSysmodule -lSceSystemService -lSceUserService -lScePad -lSceAudioOut -lSceVideoOut -lScePigletv2VSH -lSceNet -lSceRtc"
    CACHE STRING "SCE stub libraries linked into executables")

set(_PS4_LINK "\"${PS4_LINKER}\" -m elf_x86_64 -pie --script \"${OO_PS4_TOOLCHAIN}/link.x\" --eh-frame-hdr -o <TARGET> \"${OO_PS4_TOOLCHAIN}/lib/crt1.o\" <OBJECTS> <LINK_FLAGS> -L\"${PS4_PREFIX}/lib\" -L\"${OO_PS4_TOOLCHAIN}/lib\" --start-group <LINK_LIBRARIES> ${PS4_BASE_LIBS} --end-group ${PS4_SCE_LIBS}")
set(CMAKE_C_LINK_EXECUTABLE "${_PS4_LINK}")
set(CMAKE_CXX_LINK_EXECUTABLE "${_PS4_LINK}")

set(CMAKE_EXECUTABLE_SUFFIX ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_C ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_CXX ".elf")
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_FIND_ROOT_PATH "${PS4_PREFIX}" "${OO_PS4_TOOLCHAIN}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
list(APPEND CMAKE_PREFIX_PATH "${PS4_PREFIX}")
set(CMAKE_INSTALL_PREFIX "${PS4_PREFIX}" CACHE PATH "")

# Platform/PS4.cmake lives next to this file.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

set(THREADS_PREFER_PTHREAD_FLAG OFF)
set(CMAKE_THREAD_LIBS_INIT "")
set(CMAKE_HAVE_THREADS_LIBRARY 1)
set(CMAKE_USE_PTHREADS_INIT 1)
set(Threads_FOUND TRUE)
