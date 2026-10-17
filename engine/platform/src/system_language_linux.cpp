// Linux: the locale environment variables (see posix_environment_languages).
#include <cstdlib>

#include "fa/platform/system_language.h"

namespace fa {

namespace {
const char* env(const char* name) {
    const char* v = std::getenv(name);
    return v ? v : "";
}
}  // namespace

std::vector<std::string> system_languages() {
    return posix_environment_languages(env("LANGUAGE"), env("LC_ALL"), env("LC_MESSAGES"), env("LANG"));
}

}  // namespace fa
