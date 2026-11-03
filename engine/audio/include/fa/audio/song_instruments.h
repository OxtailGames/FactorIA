// The instruments a song can name without a file (M56.1): a handful of pitched sounds and a small drum kit, each an ordinary sound
// patch (sfx.h, docs/SOUND.md) so an AI can read one with `music.instrument`, copy it to a `.sfx.json`, change a number and point a
// track at the copy. They are the preview's voices (song_preview.h); the real instruments, the mixer and SF2 of M56.2 replace or
// extend this list. Every pitched patch is calibrated so its C4 note at velocity 100 peaks about -12 dBFS, so tracks at volume 1 add up
// to a sensible level without a limiter; the kit lanes sit at levels of their own.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

struct SongInstrumentInfo {
    std::string name;                 // "pluck", "pad", "bass", ...
    std::string what;                 // how it sounds and what it is for
    int low = 24, high = 96;          // the MIDI range it sounds good in (notes outside it are flagged by music.check)
};

// The built-in pitched instruments, in the order the docs list them.
const std::vector<SongInstrumentInfo>& song_instruments();
// The patch (the JSON of a `.sfx.json`) of a built-in instrument ("pluck") or of a drum kit lane ("kit:kick"); nothing for any
// other name.
std::optional<Json> song_instrument_patch(std::string_view name);
// The range of a built-in instrument; nothing for another name.
std::optional<std::pair<int, int>> song_instrument_range(std::string_view name);

}  // namespace fa
