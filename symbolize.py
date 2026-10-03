"""Turns the code offsets of a "[PS4] FATAL" crash report back into function names.

    py ps4port/symbolize.py <elf> <ps4_boot.log>

The offsets are relative to __text_start, which the OpenOrbis linker script puts at address 0, so
they are ELF addresses already. Use the exact ELF that went into the package.
"""
import bisect
import os
import re
import subprocess
import sys

NM = os.path.join(os.path.dirname(__file__), '..', 'tools', 'llvm', 'bin', 'llvm-nm.exe')


def main():
    elf, log = sys.argv[1], sys.argv[2]
    out = subprocess.run([NM, '-n', '-C', '--defined-only', elf], capture_output=True, text=True,
                         check=True).stdout
    addrs, names = [], []
    for line in out.splitlines():
        parts = line.split(' ', 2)
        if len(parts) == 3 and parts[1] in 'TtWw':
            addrs.append(int(parts[0], 16))
            names.append(parts[2])

    def lookup(a):
        i = bisect.bisect_right(addrs, a) - 1
        return f'{names[i]} +0x{a - addrs[i]:x}' if i >= 0 else '??'

    for line in open(log, encoding='utf-8', errors='replace'):
        if 'FATAL' in line or 'HANG' in line:
            print(line.rstrip())
            m = re.search(r'code offset ([0-9a-f]+)', line)
            if m:
                print(f'  crash at 0x{m.group(1)}  {lookup(int(m.group(1), 16))}')
        elif 'code addresses on the' in line or 'call chain (offsets)' in line:
            print(line.split('(offsets)')[0].strip())
            for o in line.split('(offsets):')[1].split('[PS4]')[0].split():
                print(f'  0x{o}  {lookup(int(o, 16))}')


if __name__ == '__main__':
    main()
