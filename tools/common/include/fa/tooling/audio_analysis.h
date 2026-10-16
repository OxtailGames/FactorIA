// Loudness of a project's sounds, for the tools: the command `assets.analyze_audio`, the loudness check of
// `project.validate` and the audio step of `factoria export` (docs/ASSETS.md, "Import settings > Audio").
//
// The measurement is ITU-R BS.1770-4 / EBU R128 integrated loudness and sample peak (fa/audio/analysis.h). It is cached in
// assets.json under the sound's `analysis` together with the size and SHA-256 of the file it describes, so a record whose
// file was edited since is ignored instead of trusted.
#pragma once

#include <string>
#include <vector>

#include "fa/audio/analysis.h"
#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/validate.h"

namespace fa {

struct AudioAnalysis {
    std::string path;     // project-relative path that was asked for
    std::string file;     // the file that was read: `path`, or its twin `<path>.qoa` when only that exists
    Loudness loudness;
    bool cached = false;  // the measurement came from the `analysis` record of assets.json (it still described the file)
    Json record;          // the `analysis` keys that describe `file` (loudnessLufs, peakDb, seconds, bytes, sha256)
    Json settings;        // effective audio import settings: stream, normalize, targetLufs, convert
};

// The sound files of the project at `projectDir`, sorted: every .wav, .ogg, .mp3 and .qoa under assets/, plus the ones
// scenes and prefabs name wherever they are kept.
std::vector<std::string> project_audio_files(const std::string& projectDir);

// Measures `path` (project-relative), or reuses the fresh `analysis` record of assets.json. Writes nothing.
Result<AudioAnalysis> analyze_audio_file(const std::string& projectDir, const std::string& path);

// Loudness warnings of `project.validate`: a clip that peaks at 0 dBFS or above, one louder than -9 LUFS or quieter than
// -35 LUFS, and sound effects more than 12 LU apart. Read-only: it never writes assets.json.
std::vector<ValidationIssue> check_audio_loudness(const std::string& projectDir);

// assets.analyze_audio
void register_audio_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
