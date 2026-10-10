# nfs-handler - cross-built with Bebbo's m68k-amigaos-gcc.
# No startup code, no libc: the handler is its own world (see the
# comment atop nfs-handler.c). -fno-toplevel-reorder keeps aminfs_entry
# first in the text hunk, which is what makes it the entry point.

# Toolchain: first m68k-amigaos-gcc found on PATH, else Bebbo's default
# location, else ApolloCrossDev's. Override with  make CC=/path/to/gcc
CC ?= $(shell command -v m68k-amigaos-gcc 2>/dev/null)
ifeq ($(CC),)
  ifneq ($(wildcard $(HOME)/opt/amiga/bin/m68k-amigaos-gcc),)
    CC = $(HOME)/opt/amiga/bin/m68k-amigaos-gcc
  else
    CC = $(HOME)/ApolloCrossDev/Compilers/GCC-6.50-Dev/bin/m68k-amigaos-gcc
  endif
endif
CFLAGS  = -O2 -noixemul -fomit-frame-pointer \
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

# Native unit test of the charset converters (no Amiga toolchain needed).
check:
	sh tests/extract_charset.sh && gcc -Wall -Wextra -Wno-unused-variable -O2 -o tests/charset_test tests/charset_test.c && ./tests/charset_test

clean:
	rm -f nfs-handler NFSDismount *.o tests/charset_test

.PHONY: all test check clean
