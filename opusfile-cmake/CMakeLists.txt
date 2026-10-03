cmake_minimum_required(VERSION 3.24)
project(opusfile C)
# Minimal static build of opusfile 0.12 (no HTTP support).
set(O ${OPUSFILE_SRC})
add_library(opusfile STATIC ${O}/src/info.c ${O}/src/internal.c ${O}/src/opusfile.c ${O}/src/stream.c)
target_include_directories(opusfile PRIVATE ${O}/include ${CMAKE_INSTALL_PREFIX}/include ${CMAKE_INSTALL_PREFIX}/include/opus)
target_compile_definitions(opusfile PRIVATE OP_DISABLE_HTTP=1 OP_HAVE_LRINTF=1)
install(TARGETS opusfile ARCHIVE DESTINATION lib)
install(FILES ${O}/include/opusfile.h DESTINATION include/opus)
