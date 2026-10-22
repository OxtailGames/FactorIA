#include <windows.h>
#include <process.h>

#include "script_instrument_thread.h"

namespace fa {
namespace {
struct Start {
    void (*entry)(void*);
    void* arg;
};
unsigned __stdcall trampoline(void* p) {
    Start s = *static_cast<Start*>(p);
    delete static_cast<Start*>(p);
    s.entry(s.arg);
    return 0;
}
}  // namespace

bool start_big_stack_thread(void (*entry)(void*), void* arg, std::size_t stackBytes) {
    auto* s = new Start{entry, arg};
    HANDLE h = reinterpret_cast<HANDLE>(
        _beginthreadex(nullptr, static_cast<unsigned>(stackBytes), trampoline, s, STACK_SIZE_PARAM_IS_A_RESERVATION, nullptr));
    if (!h) {
        delete s;
        return false;
    }
    CloseHandle(h);
    return true;
}

}  // namespace fa
