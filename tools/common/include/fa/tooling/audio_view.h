// What an editor shows of one decoded sound: its spectrogram and its measurements. A thin public wrapper over the code behind
// assets.spectrogram and assets.check_mix (tools/common/src/audio_mix.h, which stays private), so the editor's Sound panel
// reads the same numbers the commands report. Pure CPU code, deterministic.
#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "fa/audio/analysis.h"
#include "fa/audio/audio_doc.h"
#include "fa/audio/sfx.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// A short-time Fourier transform of the mid channel on a log frequency axis, in dB (a full-scale sine reads 0 dB):
// `db[row * columns + column]`, row 0 = `maxHz`, the last row = `minHz`; `maxDb` is the loudest cell.
struct AudioSpectrogram {
    int columns = 0, rows = 0;
    double minHz = 20.0, maxHz = 20000.0;
    std::vector<float> db;
    float maxDb = -200.0f;
};
AudioSpectrogram audio_spectrogram(const DecodedAudio& audio, int columns, int rows);

// The numbers of assets.check_mix for one sound that the panel's measurement row needs.
struct AudioViewMetrics {
    double seconds = 0.0;
    double samplePeakDb = -200.0, truePeakDb = -200.0;  // -200 for silence
    std::size_t clippedSamples = 0;  // samples inside runs of 2 or more at full scale (a flattened wave)
    double seamJumpRatio =
        0.0;  // the jump from the last sample to the first, over the typical step: a loop click when large
    bool silent = true;
};
AudioViewMetrics audio_view_metrics(const DecodedAudio& audio);

// Turns a dB matrix into 8-bit RGBA pixels (`columns * rows * 4`) with a dark-to-bright heat map; cells `rangeDb` below the
// loudest are the darkest. Row 0 is the top.
std::vector<unsigned char> audio_spectrogram_pixels(const AudioSpectrogram& s, float rangeDb = 90.0f);

// ---- rendering what a panel shows -------------------------------------------------------------------------------------------------

// What to turn into samples: a patch or an audio document given as JSON (the text the panel holds, not necessarily what is on disk),
// or a sound file of the project.
struct SoundSpec {
    enum class Kind { Patch, Document, File } kind = Kind::Patch;
    Json json;               // Patch, Document
    std::string file;        // project-relative: names the document in messages; for Kind::File the sound to read
    std::uint64_t seed = 0;  // patch: another take of the noise; document: replaces the document's seed when seedSet
    bool seedSet = false;
    std::map<std::string, double> macros;  // patch: macro values that replace the declared ones
    int variant = -1;                      // patch: 0-based variant of its variations
    int stopAfter = -1;                    // document: apply only steps 0..stopAfter
    double maxSeconds = 0.0;               // file: stop decoding there (0 = the whole file)
};

// Interleaved float frames (1 or 2 channels) and what was measured on them.
struct RenderedSound {
    int sampleRate = 44100;
    int channels = 1;
    std::vector<float> samples;
    double lufs = kSilentLufs;
    double peakDb = -200.0;
    std::optional<AudioLoop> loop;       // documents with a loop step
    std::vector<AudioStepReport> steps;  // documents
    std::vector<std::string> inputs;     // documents: the project files the render read
    bool truncated = false;              // file: longer than maxSeconds
    std::size_t frames() const { return channels > 0 ? samples.size() / std::size_t(channels) : 0; }
};

// Renders `spec`. The sound files a document names are read through the VFS: when its project root is not `projectDir` it is set
// to it for the call (so run those calls on the thread that owns the VFS). Failures teach, with the issues' JSON pointers.
Result<RenderedSound> render_sound(const SoundSpec& spec, const std::string& projectDir);

}  // namespace fa
