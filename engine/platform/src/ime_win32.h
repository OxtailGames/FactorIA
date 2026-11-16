// The Windows IME backend's own interface (ime_win32.cpp), private to fa_platform. The shared hooks are in ime_impl.h.
#pragma once

namespace fa {

class Input;

// Which Input the composition events go to (AppDesc::input; app.cpp sets it when the app starts and clears it at the end).
// The first call hooks sokol_app's window procedure; nullptr gives the window back its own and the IME its default state.
// Without an Input the IME backend does nothing and keys and text reach the game as sokol_app delivers them.
void ime_win32_attach(Input* input);

}  // namespace fa
