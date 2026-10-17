// macOS and iOS: the languages of System Settings > Language & Region, in order ("es-ES", "en-US", "zh-Hans-CN").
#import <Foundation/Foundation.h>

#include "fa/platform/system_language.h"

namespace fa {

std::vector<std::string> system_languages() {
    std::vector<std::string> raw;
    for (NSString* language in [NSLocale preferredLanguages]) raw.emplace_back(language.UTF8String ? language.UTF8String : "");
    return normalize_language_list(raw);
}

}  // namespace fa
