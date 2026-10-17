// Which language a run starts in (docs/LOCALIZATION.md, "Which language the game starts in").
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/i18n.h"

namespace fa {

// The language a run starts in, always one of the game's languages (`i18n` is configured with them), "" when localization is off.
//   1. `configured` (EngineConfig::language), then `environment` (the FA_LANGUAGE variable): a tag, resolved like
//      I18n::resolve_language. One that names no language of the game is skipped with a message in *problems.
//   2. When `followSystem` (a game in its own window or an exported game; not headless runs, tests, the MCP server, the editor):
//      the best match of `systemLanguages` (fa::best_language_match).
//   3. defaultLanguage. Headless runs end here, so their output never depends on the machine.
std::string choose_start_language(const I18n& i18n, std::string_view configured, std::string_view environment, bool followSystem,
                                  const std::vector<std::string>& systemLanguages, std::vector<std::string>* problems = nullptr);

}  // namespace fa
