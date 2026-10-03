cmake_minimum_required(VERSION 3.24)
project(zlib C)
# Minimal static-only build of zlib (upstream CMake insists on a shared library).
set(Z ${ZLIB_SRC})
add_library(z STATIC
    ${Z}/adler32.c ${Z}/compress.c ${Z}/crc32.c ${Z}/deflate.c ${Z}/gzclose.c ${Z}/gzlib.c ${Z}/gzread.c
    ${Z}/gzwrite.c ${Z}/inflate.c ${Z}/infback.c ${Z}/inftrees.c ${Z}/inffast.c ${Z}/trees.c ${Z}/uncompr.c ${Z}/zutil.c)
target_compile_definitions(z PRIVATE HAVE_UNISTD_H=1 _LARGEFILE64_SOURCE=1 HAVE_STDARG_H=1)
target_include_directories(z PUBLIC ${Z})
install(TARGETS z ARCHIVE DESTINATION lib)
install(FILES ${Z}/zlib.h ${Z}/zconf.h DESTINATION include)
