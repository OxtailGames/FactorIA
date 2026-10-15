#define DOCTEST_CONFIG_IMPLEMENT
#include <doctest.h>

#include <cstdio>
#include <iostream>

#if defined(_MSC_VER) && !defined(_DLL)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

int main(int argc, char** argv) {
    int result = doctest::Context(argc, argv).run();
#if defined(_MSC_VER) && !defined(_DLL)
    // Static MSVC runtime: returning from main tears the CRT down (heap locks, locale) while other threads still run,
    // and a thread that starts in that window (XInput starts some) runs doctest's thread_local std::ostringstream
    // constructors on the dead CRT and crashes. ExitProcess ends the other threads first and leaves the CRT intact.
    // The shipping exes have no thread_local with a constructor, so they do not need this.
    std::cout.flush();
    std::cerr.flush();
    std::fflush(nullptr);
    ExitProcess(static_cast<UINT>(result));
#else
    return result;
#endif
}
