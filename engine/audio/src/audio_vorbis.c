/* stb_vorbis implementation lives in its own C translation unit (it defines
 * single-letter macros that must not leak into C++ code). */
#define STB_VORBIS_NO_STDIO
/* GCC 13 cannot see that getn() fills the page header it reads next (stb_vorbis.c:1366, a false positive). This
 * silences that one warning for the vendored code only: external/ is not edited, and the rest of this file is checked. */
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#endif
#include "stb_vorbis.c"
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic pop
#endif

/* The pull API the C++ decoders use (audio_decoder.cpp), so no stb_vorbis type crosses the language boundary. */
void* fa_vorbis_open(const unsigned char* data, int size, int* channels, int* rate, unsigned int* frames) {
    int error = 0;
    stb_vorbis* v = stb_vorbis_open_memory(data, size, &error, NULL);
    if (!v) return NULL;
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
