#include <algorithm>

#include "fa/core/i18n.h"
#include "fa/core/strings.h"
#include "fa/platform/system_language.h"

namespace fa {

std::vector<std::string> normalize_language_list(const std::vector<std::string>& raw) {
    std::vector<std::string> out;
    for (const std::string& r : raw) {
        std::string tag = normalize_language_tag(r);
        if (!tag.empty() && std::find(out.begin(), out.end(), tag) == out.end()) out.push_back(std::move(tag));
    }
    return out;
}

std::vector<std::string> posix_environment_languages(std::string_view language, std::string_view lcAll, std::string_view lcMessages,
                                                     std::string_view lang) {
    std::vector<std::string> raw = split(language, ':');
    for (std::string_view v : {lcAll, lcMessages, lang}) raw.emplace_back(v);
    return normalize_language_list(raw);
}

}  // namespace fa
