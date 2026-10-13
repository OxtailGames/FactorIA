/* stb_vorbis implementation lives in its own C translation unit (it defines
 * single-letter macros that must not leak into C++ code). */
#define STB_VORBIS_NO_STDIO
#include "stb_vorbis.c"
