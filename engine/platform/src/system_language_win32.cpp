// Windows: the user's preferred UI languages, in the order of Settings > Time & language > Language.
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include "fa/platform/system_language.h"

namespace fa {

std::vector<std::string> system_languages() {
    ULONG count = 0, size = 0;
    if (!GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &count, nullptr, &size) || size == 0) return {};
    std::wstring buffer(size, L'\0');
    if (!GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &count, buffer.data(), &size)) return {};
    std::vector<std::string> raw;  // "en-US\0es-ES\0\0": the names are ASCII
    for (std::size_t i = 0; i < buffer.size() && buffer[i];) {
        std::string tag;
        for (; i < buffer.size() && buffer[i]; ++i) tag += static_cast<char>(buffer[i]);
        raw.push_back(std::move(tag));
        ++i;
    }
    return normalize_language_list(raw);
}

}  // namespace fa
