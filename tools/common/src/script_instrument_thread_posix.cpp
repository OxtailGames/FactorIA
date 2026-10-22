#include <pthread.h>

#include "script_instrument_thread.h"

namespace fa {
namespace {
struct Start {
    void (*entry)(void*);
    void* arg;
};
void* trampoline(void* p) {
    Start s = *static_cast<Start*>(p);
    delete static_cast<Start*>(p);
    s.entry(s.arg);
    return nullptr;
}
}  // namespace

bool start_big_stack_thread(void (*entry)(void*), void* arg, std::size_t stackBytes) {
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, stackBytes);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    auto* s = new Start{entry, arg};
    pthread_t t;
    int rc = pthread_create(&t, &attr, trampoline, s);
    pthread_attr_destroy(&attr);
    if (rc != 0) {
        delete s;
        return false;
    }
    return true;
}

}  // namespace fa
