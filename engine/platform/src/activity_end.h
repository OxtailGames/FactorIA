// Android: the end of the activity reaches the game. Private to fa_platform; see activity_end_android.cpp.
#pragma once

namespace fa {

// sokol_app's loop thread, once the app's init callback ran (app.cpp): from here on a destroyed activity runs the game's end.
void android_end_attach();
// The game's end, on sokol_app's loop thread (app.cpp): sends AppEvent::Type::Ending to the host once.
void app_android_end();

}  // namespace fa

// Android's main thread, from the onDestroy wrapper of sokol_impl.c, before sokol_app's own onDestroy: asks the loop
// thread to run the game's end and waits for it, at most kAndroidEndBudgetMs. Returns 1 when sokol_app's onDestroy may
// run (the end ran, or the engine never started), 0 when the loop thread did not answer in time: it is busy, so sokol's
// onDestroy (which waits for it without a limit) must not run, and the caller ends the process at once.
extern "C" int fa_android_activity_ending(void);
