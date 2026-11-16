// fa::crypto::random_bytes: the operating system's CSPRNG, one #if per platform (see fa/core/crypto.h). Never rand() and never
// the simulation's world.rng(): this is I/O, and a nonce that repeats breaks the encryption.
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <string>

#include "fa/core/crypto.h"

#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include <bcrypt.h>
#elif defined(__EMSCRIPTEN__)
#include <unistd.h>  // getentropy: emscripten backs it with crypto.getRandomValues in a browser and with the OS in Node
#elif defined(__ANDROID__)
#include <fcntl.h>  // the NDK's minimum API level (26) predates getrandom / getentropy (28): read /dev/urandom
#include <unistd.h>
#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
#include <stdlib.h>  // arc4random_buf
#elif defined(__linux__)
#include <sys/random.h>  // getrandom
#else
#error "fa::crypto::random_bytes has no random source for this platform: add one in crypto_random.cpp"
#endif

namespace fa::crypto {

Result<void> random_bytes(std::span<std::uint8_t> out) {
    if (out.empty()) return {};
#if defined(_WIN32)
    std::size_t done = 0;
    while (done < out.size()) {
        const ULONG chunk = ULONG(std::min<std::size_t>(out.size() - done, 1u << 20));
        const NTSTATUS st = BCryptGenRandom(nullptr, reinterpret_cast<PUCHAR>(out.data() + done), chunk,
                                            BCRYPT_USE_SYSTEM_PREFERRED_RNG);
        if (st < 0)
            return make_error("BCryptGenRandom failed (status 0x" + std::to_string(static_cast<unsigned long>(st)) + ").",
                              "The system's random number generator is not available; nothing was sealed.");
        done += chunk;
    }
    return {};
#elif defined(__EMSCRIPTEN__)
    std::size_t done = 0;
    while (done < out.size()) {
        const std::size_t chunk = std::min<std::size_t>(out.size() - done, 256);  // getentropy's limit
        if (::getentropy(out.data() + done, chunk) != 0)
            return make_error(std::string("getentropy failed: ") + std::strerror(errno) + ".",
                              "The browser's crypto.getRandomValues is not available; nothing was sealed.");
        done += chunk;
    }
    return {};
#elif defined(__ANDROID__)
    int fd;
    do {
        fd = ::open("/dev/urandom", O_RDONLY | O_CLOEXEC);
    } while (fd < 0 && errno == EINTR);
    if (fd < 0)
        return make_error(std::string("Cannot open /dev/urandom: ") + std::strerror(errno) + ".",
                          "The system's random number generator is not available; nothing was sealed.");
    std::size_t done = 0;
    while (done < out.size()) {
        const ssize_t n = ::read(fd, out.data() + done, out.size() - done);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) {
            const int e = n < 0 ? errno : EIO;
            ::close(fd);
            return make_error(std::string("Reading /dev/urandom failed: ") + std::strerror(e) + ".",
                              "The system's random number generator is not available; nothing was sealed.");
        }
        done += std::size_t(n);
    }
    ::close(fd);
    return {};
#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
    arc4random_buf(out.data(), out.size());  // cannot fail
    return {};
#else  // Linux
    std::size_t done = 0;
    while (done < out.size()) {
        const ssize_t n = ::getrandom(out.data() + done, out.size() - done, 0);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0)
            return make_error(std::string("getrandom failed: ") + std::strerror(n < 0 ? errno : EIO) + ".",
                              "The system's random number generator is not available; nothing was sealed.");
        done += std::size_t(n);
    }
    return {};
#endif
}

}  // namespace fa::crypto
