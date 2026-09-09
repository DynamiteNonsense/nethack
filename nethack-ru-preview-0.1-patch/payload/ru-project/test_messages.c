/* Standalone tests for the actual C display helper, not a model.
 * Build and run on the user's MSYS2 UCRT64 compiler before building NetHack. */
#include <assert.h>
#include <stdio.h>
#include "../win/tty/nhr_messages.h"

struct capture {
    unsigned nonspace[8192];
    size_t used;
    int column;
    int limit;
};

static void capture_emit(unsigned cp, void *context)
{
    struct capture *out = (struct capture *) context;
    if (cp == '\n') { out->column = 0; return; }
    assert(out->column < out->limit);
    ++out->column;
    if (cp != ' ') {
        assert(out->used < sizeof out->nonspace / sizeof out->nonspace[0]);
        out->nonspace[out->used++] = cp;
    }
}

int main(int argc, char **argv)
{
    size_t i, j, k, cases = 0;
    const int widths[] = { 1, 2, 10, 39, 79, 119, 159 };
    const char *p;
    struct capture output;
    if (argc > 1 && !strcmp(argv[1], "--expect-disabled")) {
        assert(nhr_lookup(nhr_entries[0].en) == NULL);
        puts("PASS: NETHACK_RU=0 disables lookup.");
        return 0;
    }
    assert(nhr_lookup(NULL) == NULL);
    assert(nhr_lookup("This is not a catalog key.") == NULL);
    p = "\320\201\320\266 \321\211\321\203\320\272\320\260 \321\221";
    assert(nhr_next(&p) == 0x401); /* upper-case Yo */
    assert(nhr_next(&p) == 0x436);
    assert(nhr_next(&p) == ' ');
    assert(nhr_next(&p) == 0x449);
    assert(nhr_next(&p) == 0x443);
    assert(nhr_next(&p) == 0x43a);
    assert(nhr_next(&p) == 0x430);
    assert(nhr_next(&p) == ' ');
    assert(nhr_next(&p) == 0x451); /* lower-case yo */
    assert(nhr_next(&p) == 0);
    p = "\320";
    assert(nhr_next(&p) == '?');
    assert(nhr_next(&p) == 0);
    p = "\320X";
    assert(nhr_next(&p) == '?');
    assert(nhr_next(&p) == 'X');
    assert(nhr_next(&p) == 0);
    for (i = 0; i < NHR_COUNT; ++i) {
        size_t en_len = strlen(nhr_entries[i].en);
        size_t text_len = strlen(nhr_entries[i].display);
        const char *suffix;
        unsigned expected[8192];
        size_t expected_count = 0;
        assert(nhr_lookup(nhr_entries[i].en) == nhr_entries[i].display);
        assert(text_len >= en_len + 3);
        suffix = nhr_entries[i].display + text_len - en_len - 3;
        assert(suffix[0] == ' ' && suffix[1] == '(');
        assert(!memcmp(suffix + 2, nhr_entries[i].en, en_len));
        assert(suffix[en_len + 2] == ')');
        assert(suffix[en_len + 3] == '\0');
        p = nhr_entries[i].display;
        while (*p) {
            unsigned cp = nhr_next(&p);
            if (cp != ' ' && cp != '\n') expected[expected_count++] = cp;
        }
        for (j = 0; j < sizeof widths / sizeof widths[0]; ++j) {
            int start;
            for (start = 0; start < widths[j]; start += widths[j] > 1 ? widths[j]-1 : 1) {
                output.used = 0;
                output.column = start;
                output.limit = widths[j];
                nhr_render(nhr_entries[i].display, widths[j], start,
                           capture_emit, &output);
                assert(output.used == expected_count);
                for (k = 0; k < expected_count; ++k)
                    assert(output.nonspace[k] == expected[k]);
                ++cases;
            }
        }
    }
    printf("PASS: %lu catalog entries, %lu C rendering cases.\n",
           (unsigned long) NHR_COUNT, (unsigned long) cases);
    return 0;
}
