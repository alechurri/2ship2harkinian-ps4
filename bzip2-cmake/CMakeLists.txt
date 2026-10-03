cmake_minimum_required(VERSION 3.24)
project(bzip2 C)
# Minimal static build of libbz2 (upstream 1.0.8 only ships a Makefile).
set(B ${BZIP2_SRC})
add_library(bz2 STATIC ${B}/blocksort.c ${B}/huffman.c ${B}/crctable.c ${B}/randtable.c ${B}/compress.c
    ${B}/decompress.c ${B}/bzlib.c)
target_include_directories(bz2 PUBLIC ${B})
install(TARGETS bz2 ARCHIVE DESTINATION lib)
install(FILES ${B}/bzlib.h DESTINATION include)
