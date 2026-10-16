/* stb_vorbis implementation lives in its own C translation unit (it defines
 * single-letter macros that must not leak into C++ code). */
#define STB_VORBIS_NO_STDIO
#include "stb_vorbis.c"

/* The pull API the C++ decoders use (audio_decoder.cpp), so no stb_vorbis type crosses the language boundary. */
void* fa_vorbis_open(const unsigned char* data, int size, int* channels, int* rate, unsigned int* frames) {
    int error = 0;
    stb_vorbis* v = stb_vorbis_open_memory(data, size, &error, NULL);
    if (!v) return NULL;
    stb_vorbis_info info = stb_vorbis_get_info(v);
    *channels = info.channels;
    *rate = (int)info.sample_rate;
    *frames = stb_vorbis_stream_length_in_samples(v);  /* scans the last page: start decoding from a clean state */
    stb_vorbis_seek_start(v);
    return v;
}

/* Interleaved float frames; fewer than asked only at the end of the stream. */
int fa_vorbis_read(void* v, int channels, float* out, int frames) {
    return stb_vorbis_get_samples_float_interleaved((stb_vorbis*)v, channels, out, frames * channels);
}

int fa_vorbis_rewind(void* v) { return stb_vorbis_seek_start((stb_vorbis*)v); }

void fa_vorbis_close(void* v) { stb_vorbis_close((stb_vorbis*)v); }
