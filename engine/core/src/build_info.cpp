#include "fa/core/build_info.h"

#include <cctype>

#include "fa_build_fingerprint.h"  // generated at build time: FA_BUILD_FINGERPRINT

namespace fa {

namespace {

#define FA_FINGERPRINT_PREFIX "FA-BUILD-FINGERPRINT:"

// Stays in the binary as text: find_build_fingerprint() looks for it in another program's bytes.
#if defined(__GNUC__) || defined(__clang__)
__attribute__((used))
#endif
const char kMarker[] = FA_FINGERPRINT_PREFIX FA_BUILD_FINGERPRINT ";";
const char kFingerprint[] = FA_BUILD_FINGERPRINT;

#define FA_VERSION_PREFIX "FA-ENGINE-VERSION:"
// The engine version next to the fingerprint, so that a program reading another file's bytes can name its release.
#if defined(__GNUC__) || defined(__clang__)
__attribute__((used))
#endif
const char kVersionMarker[] = FA_VERSION_PREFIX FA_ENGINE_VERSION ";";

}  // namespace

const char* build_fingerprint() {
    // Touches the marker, so that every program that asks for its fingerprint keeps it (a linker would drop unused data).
    const volatile char* marker = kMarker;
    (void)marker[0];
    const volatile char* version = kVersionMarker;
    (void)version[0];
    return kFingerprint;
}

std::string find_build_fingerprint(std::string_view bytes) {
    constexpr std::string_view prefix = FA_FINGERPRINT_PREFIX;
    for (std::size_t at = bytes.find(prefix); at != std::string_view::npos; at = bytes.find(prefix, at + 1)) {
        std::size_t i = at + prefix.size();
        const std::size_t start = i;
        while (i < bytes.size() && (std::isalnum(static_cast<unsigned char>(bytes[i])) || bytes[i] == '-')) ++i;
        if (i < bytes.size() && bytes[i] == ';' && i > start) return std::string(bytes.substr(start, i - start));
    }
    return {};
}

std::string find_build_version(std::string_view bytes) {
    constexpr std::string_view prefix = FA_VERSION_PREFIX;
    for (std::size_t at = bytes.find(prefix); at != std::string_view::npos; at = bytes.find(prefix, at + 1)) {
        std::size_t i = at + prefix.size();
        const std::size_t start = i;
        while (i < bytes.size() && (std::isalnum(static_cast<unsigned char>(bytes[i])) || bytes[i] == '-' || bytes[i] == '.' ||
                                    bytes[i] == '+'))
            ++i;
        if (i < bytes.size() && bytes[i] == ';' && i > start) return std::string(bytes.substr(start, i - start));
    }
    return {};
}

}  // namespace fa
