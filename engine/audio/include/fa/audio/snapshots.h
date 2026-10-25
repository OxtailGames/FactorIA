// The "audio" section of factoria.json: the catalog of mixer snapshots (docs/SCRIPTING.md, "Audio buses").
//
//   "audio": {"snapshots": {
//       "underwater": {"fade": 0.8, "buses": {
//           "sfx":   {"volume": 0.8, "lowpass": 600, "reverb": 0.3},
//           "music": {"lowpass": 400, "duck": {"by": "ui", "amount": 0.5, "attack": 0.05, "release": 0.5}}}},
//       "normal": {}}}
#pragma once

#include <string>
#include <vector>

#include "fa/audio/audio.h"
#include "fa/core/json.h"

namespace fa {

struct AudioIssue {
    std::string pointer, message, hint;  // pointer is a JSON pointer into factoria.json ("/audio/snapshots/underwater/fade")
};

struct AudioSettingsParse {
    AudioSnapshots snapshots;
    std::vector<AudioIssue> issues;    // every problem found; `snapshots` is only usable without any
    std::vector<AudioIssue> warnings;  // keys the engine does not know (a typo), with "did you mean"
    bool ok() const { return issues.empty(); }
};

// Reads the value of "audio" (null = the section is absent = no snapshots). Reports every mistake with its pointer, a fix and a
// "did you mean".
AudioSettingsParse parse_audio_settings(const Json& section);

}  // namespace fa
