# nfs-handler - cross-built with Bebbo's m68k-amigaos-gcc.
# No startup code, no libc: the handler is its own world (see the
# comment atop nfs-handler.c). -fno-toplevel-reorder keeps aminfs_entry
# first in the text hunk, which is what makes it the entry point.

# Toolchain: m68k-amigaos-gcc on PATH, else under AMIGA.
# Bebbo's m68k-amigaos-gcc: set AMIGA to where it is installed, otherwise it is
# looked for in the usual places (/opt/amiga, its own default, then ~/opt/amiga).
# Or override the compiler itself with  make CC=/path/to/gcc
AMIGA   ?= $(firstword $(wildcard /opt/amiga $(HOME)/opt/amiga))
ifeq ($(origin CC),default)
  CC := $(shell command -v m68k-amigaos-gcc 2>/dev/null)
  ifeq ($(CC),)
    CC := $(AMIGA)/bin/m68k-amigaos-gcc
  endif
endif
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
# Use the server's LAN address and a scratch export:
#   make test NFS_SERVER=192.168.1.10 NFS_EXPORT=/srv/nfs-share
NFS_SERVER ?=
NFS_EXPORT ?=
test:
	@test -n "$(NFS_SERVER)" -a -n "$(NFS_EXPORT)" || { echo "Set NFS_SERVER and NFS_EXPORT: make test NFS_SERVER=192.168.1.10 NFS_EXPORT=/srv/nfs-share"; exit 1; }
	python3 tests/nfswire.py selftest $(NFS_SERVER) $(NFS_EXPORT)

# Native unit test of the charset converters (no Amiga toolchain needed).
check:
	sh tests/extract_charset.sh && gcc -Wall -Wextra -Wno-unused-variable -O2 -o tests/charset_test tests/charset_test.c && ./tests/charset_test

clean:
	rm -f nfs-handler NFSDismount *.o tests/charset_test

.PHONY: all test check clean
