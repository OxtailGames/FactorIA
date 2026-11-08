// Thread names on Linux, Android, macOS and iOS (and nothing on the web, which also builds the _posix files).
#include "jobs_internal.h"

#if !defined(__EMSCRIPTEN__)
#include <pthread.h>

#include <cstddef>
#include <cstring>
#endif

namespace fa::jobs::detail {

void set_current_thread_name(const char* name) {
#if defined(__EMSCRIPTEN__)
    (void)name;
#elif defined(__APPLE__)
    pthread_setname_np(name);  // Apple's form names only the calling thread
#else
    char buf[16];  // Linux and Android: 15 characters and the terminator, or the call fails
    std::size_t n = std::strlen(name);
    if (n > sizeof buf - 1) n = sizeof buf - 1;
    std::memcpy(buf, name, n);
    buf[n] = '\0';
    pthread_setname_np(pthread_self(), buf);
#endif
}

}  // namespace fa::jobs::detail
