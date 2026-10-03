/* Force-included into every translation unit of the PS4 build (see cmake/ps4-toolchain.cmake).
 *
 * OpenOrbis v0.5.4 declares mode_t as `unsigned int` in <bits/alltypes.h>. The PS4 kernel (a
 * FreeBSD 9 derivative) uses a 16-bit mode_t, and the C library's stat()/fstat()/lstat() hand
 * the kernel's `struct stat` straight to the caller without converting it. With a 32-bit
 * mode_t every member after st_mode sits 8 bytes too far: st_size reads st_blocks, the
 * timestamps are garbage, and anything that trusts them breaks. That is why libzip could not
 * open a single archive by path ("not a zip archive": it looked for the central directory at
 * the wrong offset).
 *
 * <bits/alltypes.h> only defines a type when its __DEFINED_ guard is not set, so claiming
 * mode_t here, before any system header, gives every header the kernel's layout.
 *
 * Passing a 16-bit mode_t to the prebuilt C library (mkdir, chmod, open...) is fine: the value
 * travels zero-extended in a 32-bit register either way.
 */
#ifndef PS4_FIXUPS_H
#define PS4_FIXUPS_H

#if !defined(__ASSEMBLER__) && !defined(__DEFINED_mode_t)
typedef unsigned short mode_t;
#define __DEFINED_mode_t
#endif

#endif /* PS4_FIXUPS_H */
