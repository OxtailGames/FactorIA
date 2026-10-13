// sokol implementation translation unit for macOS and iOS (Objective-C, ARC).
// UNTESTED: cannot be compiled on the Linux development machine.
#include <TargetConditionals.h>

#define SOKOL_IMPL

// macOS: we own main() and call sapp_run() from fa::run_app().
// iOS: sokol_app provides main(); the game supplies sokol_main() (player/).
#if !TARGET_OS_IPHONE
#define SOKOL_NO_ENTRY
#endif

#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"
#include "sokol_log.h"
#include "sokol_time.h"
#include "sokol_audio.h"
