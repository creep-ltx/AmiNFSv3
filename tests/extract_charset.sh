#!/bin/sh
# Copies the charset block of nfs-handler.c into tests/charset_extract.h
# so the native test always exercises the real code.
awk '/^\/\* ASCII plus the ISO-8859-1/{p=1} /^static LONG names_equal_nocase/{p=0} p' "$(dirname "$0")/../nfs-handler.c" > "$(dirname "$0")/charset_extract.h"
