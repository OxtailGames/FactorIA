// The ONE translation unit that contains the sokol implementations for every
// non-Apple platform (Apple uses sokol_impl_apple.m). Other modules include the
// sokol headers without SOKOL_IMPL.
//
// The graphics backend macro (SOKOL_GLCORE / SOKOL_D3D11 / SOKOL_GLES3) comes
// from the fa_ext_sokol interface target.
#if !defined(__APPLE__)

#define SOKOL_IMPL

// Desktop: we own main() and call sapp_run() from fa::run_app(). On Android
// (and iOS, see the .m file) sokol_app provides the entry point and the game
// supplies sokol_main() (see fa/platform/sokol_entry.h and player/).
#if !defined(__ANDROID__)
#define SOKOL_NO_ENTRY
#endif

#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"
#include "sokol_log.h"
#include "sokol_time.h"
// No audio device library available at build time: sokol_audio becomes a dummy
// backend. (SOKOL_DUMMY_BACKEND is shared with sokol_gfx, so it is only defined
// here, after every other header has been processed.)
#if defined(FA_NO_AUDIO_DEVICE)
#define SOKOL_DUMMY_BACKEND
#endif
#include "sokol_audio.h"

#endif  // !__APPLE__
