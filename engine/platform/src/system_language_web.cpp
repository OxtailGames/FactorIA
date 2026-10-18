// Web: navigator.languages, the languages the user put in the browser's settings, best first ("es-ES", "en-US").
// Empty when the browser says nothing.
#include <emscripten.h>

#include <cstdlib>

#include "fa/core/strings.h"
#include "fa/platform/system_language.h"

// The tags joined with commas, in a malloc'd UTF-8 string.
EM_JS(char*, fa_web_languages, (), {
    const list = (navigator.languages && navigator.languages.length) ? navigator.languages : (navigator.language ? [navigator.language] : []);
    return stringToNewUTF8(list.join(','));
});

namespace fa {

std::vector<std::string> system_languages() {
    char* joined = fa_web_languages();
    std::vector<std::string> raw;
    if (joined) {
        raw = split(joined, ',');
        std::free(joined);
    }
    return normalize_language_list(raw);
}

}  // namespace fa
