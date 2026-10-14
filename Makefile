# nfs-handler - cross-built with Bebbo's m68k-amigaos-gcc.
# No startup code, no libc: the handler is its own world (see the
# comment atop nfs-handler.c). -fno-toplevel-reorder keeps aminfs_entry
# first in the text hunk, which is what makes it the entry point.

CC      = $(HOME)/opt/amiga/bin/m68k-amigaos-gcc
# -fbbb=-: Bebbo's own optimizer pass off. With it, 0.2b1's name_dir
# (inlined into the packet loop) never copied the name it had found -
# seen on the A1200, gone with the pass off (as in every program of the
# terminal family: Knowledge/amiga/toolchain-and-testing.md).
CFLAGS  = -O2 -noixemul -fomit-frame-pointer -fbbb=- \
          -Wall -Wno-pointer-sign -nostartfiles -nostdlib
LIBGCC  = $(shell $(CC) -noixemul -print-libgcc-file-name)

all: nfs-handler NFSDismount

# entry.o MUST stay first: it is the entry point (see entry.c).
nfs-handler: entry.c nfs-handler.c
	$(CC) $(CFLAGS) -c entry.c -o entry.o
	$(CC) $(CFLAGS) -c nfs-handler.c -o nfs-handler.o
	$(CC) $(CFLAGS) entry.o nfs-handler.o -o nfs-handler $(LIBGCC)

NFSDismount: NFSDismount.c
	$(CC) -O2 -noixemul -Wall -Wno-pointer-sign NFSDismount.c -o NFSDismount

# Protocol harness against the live Linux nfsd (no Amiga in the loop).
test:
	python3 tests/nfswire.py selftest 192.168.68.117 /home/creep/nfs-share

clean:
	rm -f nfs-handler NFSDismount

.PHONY: all test clean
