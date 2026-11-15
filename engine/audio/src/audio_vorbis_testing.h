// Test-only view into audio_vorbis.c (the C translation unit that wraps stb_vorbis). Not part of the public API.
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// How many blocks stb_vorbis has allocated (through fa_vorbis_malloc) on the calling thread and not freed yet. A failed
// fa_vorbis_open must leave this where it found it; a stream that is open holds some until it is closed.
long fa_vorbis_live_blocks(void);

#ifdef __cplusplus
}
#endif
