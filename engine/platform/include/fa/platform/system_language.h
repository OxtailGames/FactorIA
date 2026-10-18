// The languages the user asked their system for, as BCP 47 tags ("es-ES", "en-US", "zh-Hans-CN"), best first.
//
//   Windows    GetUserPreferredUILanguages.
//   macOS/iOS  NSLocale preferredLanguages.
//   Android    java.util.Locale.getDefault().toLanguageTag() of the process (the system language, set up by the activity).
//   web        navigator.languages.
//   Linux      LANGUAGE (a colon list), then LC_ALL, LC_MESSAGES and LANG: "es_ES.UTF-8" -> "es-ES"; "C" and "POSIX" are
//              no language and are ignored.
// Empty when the system says nothing. The engine picks the game's language from this list (fa::best_language_match,
// docs/LOCALIZATION.md); headless runs never call it.
#pragma once

#include <string>
#include <string_view>
#include <vector>

namespace fa {

std::vector<std::string> system_languages();

// Normalizes every entry (fa::normalize_language_tag), drops what is no tag and repeats.
std::vector<std::string> normalize_language_list(const std::vector<std::string>& raw);

// The Linux rule on its own (the values of the environment variables; "" = unset). Every platform compiles it so that
// tests can run it anywhere.
std::vector<std::string> posix_environment_languages(std::string_view language, std::string_view lcAll, std::string_view lcMessages,
                                                     std::string_view lang);

}  // namespace fa
