/* Native unit test for the Latin-1 <-> UTF-8 converters in nfs-handler.c.
 * Build and run with `make check`. Pulls the functions straight out of
 * the handler source so the test can never drift from the real code. */
#include <stdio.h>
#include <string.h>
typedef unsigned char UBYTE; typedef unsigned long ULONG; typedef long LONG;
#define NAME_MAX_AMIGA 106
#define CHARSET_FUNCS_ONLY
#include "charset_extract.h"

static int fails;
#define CHECK(c) do { if (!(c)) { printf("FAIL line %d: %s\n", __LINE__, #c); fails++; } } while (0)

int main(void)
{
    char u[2 * NAME_MAX_AMIGA + 2], l[NAME_MAX_AMIGA + 1];
    LONG n;
    const char *lat = "R\xe9sum\xe9 \xe0 l'\xc9t\xe9.txt";

    n = latin1_to_utf8(lat, u);
    CHECK(n == 23);
    CHECK(!memcmp(u, "R\xc3\xa9sum\xc3\xa9 \xc3\xa0 l'\xc3\x89t\xc3\xa9.txt", 24));
    n = utf8_to_latin1((UBYTE *)u, n, l, NAME_MAX_AMIGA);
    CHECK(n == (LONG)strlen(lat) && !strcmp(l, lat));

    /* euro (3 bytes), emoji (4 bytes), stray lead byte at the end */
    { const char *x = "caf\xc3\xa9 \xe2\x82\xac \xf0\x9f\x98\x80 \xc3";
      n = utf8_to_latin1((UBYTE *)x, strlen(x), l, NAME_MAX_AMIGA);
      CHECK(n == 10 && !strcmp(l, "caf\xe9 ? ? \xc3")); }

    /* pure ASCII untouched both ways */
    n = latin1_to_utf8("Hello.txt", u); CHECK(n == 9 && !strcmp(u, "Hello.txt"));

    /* a name that fits only after conversion, and one that never fits */
    { char big[400]; int i;
      for (i = 0; i < 100; i++) { big[2*i] = (char)0xc3; big[2*i+1] = (char)0xa9; }
      n = utf8_to_latin1((UBYTE *)big, 200, l, NAME_MAX_AMIGA);
      CHECK(n == 100);
      memset(big, 'a', 300);
      CHECK(utf8_to_latin1((UBYTE *)big, 300, l, NAME_MAX_AMIGA) == -1); }

    CHECK(lower(0xC9) == 0xE9);   /* E acute */
    CHECK(lower(0xD7) == 0xD7);   /* multiplication sign stays */
    CHECK(lower('A') == 'a' && lower('a') == 'a' && lower(0xE9) == 0xE9);

    printf(fails ? "%d FAILED\n" : "all charset tests passed\n", fails);
    return fails != 0;
}
