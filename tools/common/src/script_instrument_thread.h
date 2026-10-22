// A detached thread with a large, explicit stack, for the script instrumenter's QuickJS work (script_instrument.cpp).
// Implemented per platform: script_instrument_thread_posix.cpp, script_instrument_thread_win32.cpp.
#pragma once

#include <cstddef>

namespace fa {

// Starts `entry(arg)` on a new detached thread whose stack is `stackBytes`. False if the thread could not be created.
bool start_big_stack_thread(void (*entry)(void*), void* arg, std::size_t stackBytes);


}  // namespace fa
