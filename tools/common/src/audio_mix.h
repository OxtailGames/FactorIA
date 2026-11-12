// The measurements behind assets.spectrogram and assets.check_mix (docs/ASSETS.md, "Hear what you made"): everything that
// is computed from the decoded samples of one sound. Pure CPU code, deterministic (no clock, no random numbers): the
// same samples always give the same numbers, so a test can assert them.
#pragma once

#include <array>
#include <cstddef>
#include <optional>
#include <vector>

#include <string>

#include "fa/audio/analysis.h"
#include "fa/core/json.h"

namespace fa::audio_mix {

// Octave bands from 31.5 Hz to 16 kHz. Band 0 also takes everything below it, the last band everything above it.
inline constexpr int kBands = 10;
extern const char* const kBandNames[kBands];  // "31 Hz" ... "16 kHz"
inline constexpr double kBandCentreHz[kBands] = {31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000};
inline constexpr double kBandAbsent = -200.0;  // the level of a band the sound's sample rate cannot hold

// A sample at or above this level counts as full scale.
inline constexpr float kFullScale = 0.9995f;

struct Metrics {
    double seconds = 0.0;
    int rate = 0, channels = 0;
    double samplePeakDb = -200.0, truePeakDb = -200.0;  // dBFS / dBTP (4x oversampled), -200 for silence
    std::size_t fullScaleSamples = 0;  // samples at full scale, any channel
    std::size_t clippedSamples = 0;    // those inside runs of 2 or more in a row on the same side (a flattened wave)
    double firstSample = 0.0, lastSample = 0.0;  // largest |sample| of any channel at the very start / end (0..1)
    double firstStep = 0.0, lastStep = 0.0;      // |x[1]-x[0]| and |x[n-1]-x[n-2]| of the channel that has the largest
    double typicalStep = 0.0;                    // RMS of the sample-to-sample differences (largest over the channels)
    // The loop seam: the jump from the last sample to the first, and the change of slope across it, with each one divided
    // by what the sound does everywhere else (RMS of its first / second differences).
    double seamJump = 0.0, seamJumpRatio = 0.0, seamSlope = 0.0, seamSlopeRatio = 0.0;
    // Long-term level of each octave band in dB (power relative to a full-scale signal: a full-scale sine is -3 dB), taken
    // over the frames that are not silent; kBandAbsent for a band above the Nyquist frequency.
    std::array<double, kBands> bandDb{};
    int dominantBand = -1;  // the loudest band; -1 for a silent sound
    bool silent = true;     // no sample above -90 dBFS
};
// `loop` = loop points in frames (end exclusive) the sound is played between (assets.json import.loopStart/loopEnd, which the engine
// plays; for a WAV without them the `smpl` chunk of a `loop` step, which only this check reads): the seam
// metrics then judge the join from the frame before `end` to `start` (what is heard when playback wraps) instead of the file's ends.
struct LoopPoints {
    std::size_t start = 0, end = 0;
};
Metrics measure(const DecodedAudio& audio, const std::optional<LoopPoints>& loop = std::nullopt);

// A short-time Fourier transform of the mid channel on a log frequency axis, in dB (a full-scale sine reads 0 dB):
// `db[row * columns + column]`, row 0 = `maxHz`, the last row = `minHz`.
struct Spectrogram {
    int columns = 0, rows = 0;
    double minHz = 20.0, maxHz = 20000.0;
    std::vector<float> db;
    float maxDb = -200.0f;  // the loudest cell
};
Spectrogram spectrogram(const DecodedAudio& audio, int columns, int rows);

// The octave band that holds `hz`.
int band_of(double hz);

// What assets.spectrogram returns for a call with these arguments ({"path", "width", "height", "out", "loop", "channels"}): the
// measurements and the `$image` picture. Throws CommandError. For commands that make a sound and show it (sfx.render).
// `command` names the calling command: a caller-given "out" needs its writeProject capability.
Json spectrogram_picture(const std::string& projectDir, const Json& args, const char* command);

// One row of a contact sheet of sounds: a name, a line of numbers and the mono samples (rendered in memory, no file needed).
struct SheetRow {
    std::string label, note;
    std::vector<float> samples;
    int rate = 44100;
};
// A picture with one row per sound, all on the same time and level scale so they compare at a glance: a waveform strip over a
// spectrogram, the name and numbers on the left. Returns {"$image", "picture"}; `outRel` (a .png path) keeps the file. Throws CommandError.
Json spectrogram_sheet(const std::string& projectDir, const std::string& title, const std::vector<SheetRow>& rows, int width,
                       const std::string& outRel, const char* command);

}  // namespace fa::audio_mix
