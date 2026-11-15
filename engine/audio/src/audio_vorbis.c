/* stb_vorbis implementation lives in its own C translation unit (it defines
 * single-letter macros that must not leak into C++ code). */
#define STB_VORBIS_NO_STDIO
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#include <malloc.h>
#endif

/* stb_vorbis_open_memory leaks the "temp" blocks it holds (the codeword lengths of a sparse codebook, the multiplicands'
 * scratch) when the setup header turns out to be damaged: its error paths return without freeing them, and with no
 * alloc_buffer they come from malloc. A fixed alloc_buffer cannot replace that (the size a valid file needs is not
 * known beforehand and the buffer would stay alive as long as the stream). So every malloc/free stb_vorbis.c makes goes
 * through the pair below: each block carries a small header and, while fa_vorbis_open runs, the blocks live in a list
 * that a failed open frees whole. After a successful open the list is dissolved and the blocks are plain. */
typedef struct fa_vblock {
    struct fa_vblock* prev;
    struct fa_vblock* next;
    int linked; /* 1 while the block is in the open list */
    int pad;
} fa_vblock;
#define FA_VHDR ((sizeof(fa_vblock) + 15u) & ~(size_t)15u) /* payload keeps malloc's 16-byte alignment */

#if defined(_MSC_VER)
#define FA_THREAD_LOCAL __declspec(thread)
#else
#define FA_THREAD_LOCAL _Thread_local
#endif
static FA_THREAD_LOCAL fa_vblock* fa_open_list = NULL;
static FA_THREAD_LOCAL int fa_open_active = 0;

static void* fa_vorbis_malloc(size_t n) {
    fa_vblock* b = (fa_vblock*)malloc(FA_VHDR + n);
    if (!b) return NULL;
    b->prev = NULL;
    b->next = NULL;
    b->linked = 0;
    if (fa_open_active) {
        b->next = fa_open_list;
        if (fa_open_list) fa_open_list->prev = b;
        fa_open_list = b;
        b->linked = 1;
    }
    return (char*)b + FA_VHDR;
}

static void fa_vorbis_free(void* p) {
    fa_vblock* b;
    if (!p) return;
    b = (fa_vblock*)((char*)p - FA_VHDR);
    if (b->linked) {
        if (b->prev)
            b->prev->next = b->next;
        else
            fa_open_list = b->next;
        if (b->next) b->next->prev = b->prev;
    }
    free(b);
}

/* realloc is only used by stb_vorbis_decode_memory/_filename, which the engine never calls: refuse rather than guess.
 * A function, not a constant macro, so MSVC does not flag the code after stb's NULL check as unreachable (C4702). */
static void* fa_vorbis_realloc(void* p, size_t n) {
    (void)p;
    (void)n;
    return NULL;
}
#define malloc(n) fa_vorbis_malloc(n)
#define free(p) fa_vorbis_free(p)
#define realloc(p, n) fa_vorbis_realloc(p, n)
/* GCC 13 cannot see that getn() fills the page header it reads next (stb_vorbis.c:1366, a false positive). This
 * silences that one warning for the vendored code only: external/ is not edited, and the rest of this file is checked. */
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#endif
/* MSVC C4701 at stb_vorbis.c:4758 is the same kind of false positive: mid is read on the second probe, after the first
 * probe set it. */
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4701)
#endif
#include "stb_vorbis.c"
#undef malloc
#undef free
#undef realloc
#if defined(_MSC_VER)
#pragma warning(pop)
#endif
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic pop
#endif

/* The pull API the C++ decoders use (audio_decoder.cpp), so no stb_vorbis type crosses the language boundary. */
void* fa_vorbis_open(const unsigned char* data, int size, int* channels, int* rate, unsigned int* frames) {
    int error = 0;
    stb_vorbis* v;
    fa_open_list = NULL;
    fa_open_active = 1;
    v = stb_vorbis_open_memory(data, size, &error, NULL);
    fa_open_active = 0;
    if (!v) { /* free what the failed open left behind (see the top of this file) */
        while (fa_open_list) {
            fa_vblock* b = fa_open_list;
            fa_open_list = b->next;
            free(b);
        }
        return NULL;
    }
    while (fa_open_list) { /* success: the blocks left are the stream's own, freed by stb_vorbis_close */
        fa_vblock* b = fa_open_list;
        fa_open_list = b->next;
        b->prev = b->next = NULL;
        b->linked = 0;
    }
    stb_vorbis_info info = stb_vorbis_get_info(v);
    *channels = info.channels;
    *rate = (int)info.sample_rate;
    *frames = stb_vorbis_stream_length_in_samples(v); /* scans the last page: start decoding from a clean state */
    stb_vorbis_seek_start(v);
    return v;
}

/* Interleaved float frames; fewer than asked only at the end of the stream. */
int fa_vorbis_read(void* v, int channels, float* out, int frames) {
    return stb_vorbis_get_samples_float_interleaved((stb_vorbis*)v, channels, out, frames * channels);
}

int fa_vorbis_rewind(void* v) { return stb_vorbis_seek_start((stb_vorbis*)v); }

/* Sample-accurate: the next read returns frame `frame` (the same samples a front-to-back decode makes there). */
int fa_vorbis_seek(void* v, unsigned int frame) { return stb_vorbis_seek((stb_vorbis*)v, frame); }

void fa_vorbis_close(void* v) { stb_vorbis_close((stb_vorbis*)v); }
