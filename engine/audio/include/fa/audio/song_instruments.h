// The instruments a song can name without a file (M56.1, M56.2): a library of pitched sounds in families and three drum kits, each an
// ordinary sound patch (sfx.h, docs/SOUND.md) so an AI can read one with `music.instrument`, copy it to a `.sfx.json`, change a number
// and point a track at the copy. They are the voices of the song renderer (song_preview.h).
//
// Levels. Every pitched patch is calibrated so its C4 note at velocity 100 peaks about -12 dBFS, so tracks at volume 1 add up to a
// sensible level; the kit lanes sit at levels of their own (a kick is louder than a hat in a real kit). `tests` pin both.
// Filters of the pitched patches follow the pitch (`keytrack`), so a high note is as bright as a low one.
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

struct SongInstrumentInfo {
    std::string name;                 // "pluck", "pad", "bass", ...
    std::string family;               // "keys", "pluck", "bass", "lead", "pad", "bell", "ensemble" or "chiptune"
    std::string what;                 // how it sounds and what it is for
    int low = 24, high = 96;          // the MIDI range it sounds good in (notes outside it are flagged by music.check)
    int voices = 16;                  // its default polyphony: how many notes can be held at once before the oldest is cut
};

// The built-in pitched instruments, grouped by family, in the order the docs list them.
const std::vector<SongInstrumentInfo>& song_instruments();
// The families, in the order the docs list them, with a line on what each is for.
struct SongInstrumentFamily {
    std::string name;
    std::string what;
};
const std::vector<SongInstrumentFamily>& song_instrument_families();

// A drum kit: the same lanes (song_drum_lanes()) in another style.
struct SongKitInfo {
    std::string name;                 // "acoustic", "electronic" or "chiptune"
    std::string what;
    std::string instrument;           // what a track writes as its instrument: "kit" (acoustic) or "kit:<name>"
};
const std::vector<SongKitInfo>& song_kits();
// "kit" -> "acoustic", "kit:electronic" -> "electronic"; nothing for another name.
std::optional<std::string> song_kit_variant(std::string_view instrument);

// The patch (the JSON of a `.sfx.json`) of a built-in instrument ("pluck") or of a drum kit lane: "kit:kick" is the acoustic kit's
// kick, "kit:electronic:kick" the electronic one; nothing for any other name.
std::optional<Json> song_instrument_patch(std::string_view name);
// The range of a built-in instrument; nothing for another name.
std::optional<std::pair<int, int>> song_instrument_range(std::string_view name);
// The default polyphony of a built-in instrument; nothing for another name.
std::optional<int> song_instrument_voices(std::string_view name);

}  // namespace fa
