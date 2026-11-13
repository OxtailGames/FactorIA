/* dr_wav / dr_mp3 implementations (single C translation unit). */
#define DR_WAV_IMPLEMENTATION
#define DR_WAV_NO_STDIO
/* MSVC C4701 at dr_wav.h:3728 is a false positive: fileSize is read only when hasKnownFileSize says it was set.
 * Silenced for the vendored code only: external/ is not edited. */
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4701)
#endif
#include "dr_wav.h"
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

#define DR_MP3_IMPLEMENTATION
#define DR_MP3_NO_STDIO
#include "dr_mp3.h"
