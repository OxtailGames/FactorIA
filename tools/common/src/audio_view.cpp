#include "fa/tooling/audio_view.h"

#include <algorithm>
#include <cmath>

#include "audio_mix.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

AudioSpectrogram audio_spectrogram(const DecodedAudio& audio, int columns, int rows) {
    AudioSpectrogram out;
    if (audio.frames() == 0 || columns < 1 || rows < 1) return out;
    audio_mix::Spectrogram s = audio_mix::spectrogram(audio, columns, rows);
    out.columns = s.columns;
    out.rows = s.rows;
    out.minHz = s.minHz;
    out.maxHz = s.maxHz;
    out.db = std::move(s.db);
    out.maxDb = s.maxDb;
    return out;
}

AudioViewMetrics audio_view_metrics(const DecodedAudio& audio) {
    AudioViewMetrics out;
    if (audio.frames() == 0) return out;
    const audio_mix::Metrics m = audio_mix::measure(audio);
    out.seconds = m.seconds;
    out.samplePeakDb = m.samplePeakDb;
    out.truePeakDb = m.truePeakDb;
    out.clippedSamples = m.clippedSamples;
    out.seamJumpRatio = m.seamJumpRatio;
    out.silent = m.silent;
    return out;
}

std::vector<unsigned char> audio_spectrogram_pixels(const AudioSpectrogram& s, float rangeDb) {
    std::vector<unsigned char> px(std::size_t(std::max(s.columns, 0)) * std::size_t(std::max(s.rows, 0)) * 4, 255);
    if (s.db.size() != std::size_t(s.columns) * std::size_t(s.rows)) return px;
    // Black, deep blue, magenta, orange, pale yellow.
    static const float stops[5][3] = {{0.02f, 0.02f, 0.06f}, {0.15f, 0.08f, 0.45f}, {0.70f, 0.15f, 0.50f}, {0.98f, 0.55f, 0.15f}, {1.0f, 0.97f, 0.75f}};
    for (std::size_t i = 0; i < s.db.size(); ++i) {
        const float t = std::clamp((s.db[i] - (s.maxDb - rangeDb)) / rangeDb, 0.0f, 1.0f) * 4.0f;
        const int k = std::min(int(t), 3);
        const float f = t - float(k);
        for (int c = 0; c < 3; ++c) px[i * 4 + std::size_t(c)] = static_cast<unsigned char>(std::lround(255.0f * (stops[k][c] * (1.0f - f) + stops[k + 1][c] * f)));
    }
    return px;
}

namespace {

std::string issues_text(const std::vector<SfxIssue>& issues) {
    std::string out;
    for (std::size_t i = 0; i < issues.size() && i < 4; ++i) out += (i ? " " : "") + issues[i].pointer + ": " + issues[i].message;
    return out;
}

struct RootGuard {
    std::filesystem::path saved = fs::project_root();
    bool changed = false;
    explicit RootGuard(const std::string& dir) {
        if (std::filesystem::path(dir) != saved) {
            fs::set_project_root(dir);
            changed = true;
        }
    }
    ~RootGuard() {
        if (changed) fs::set_project_root(saved);
    }
};

}  // namespace

Result<RenderedSound> render_sound(const SoundSpec& spec, const std::string& projectDir) {
    RenderedSound out;
    switch (spec.kind) {
    case SoundSpec::Kind::Patch: {
        std::vector<SfxIssue> issues;
        auto patch = parse_sfx(spec.json, spec.file, &issues);
        if (!patch.ok()) return Error{patch.error().message + (issues.empty() ? "" : " " + issues_text(issues)), patch.error().hint};
        SfxPatch effective = std::move(*patch);
        bool binds = false;
        for (const SfxMacroDef& d : effective.macroDefs) binds = binds || !d.binds.empty();
        if (binds) {
            auto bound = sfx_apply_macro_binds(spec.json, effective, spec.macros);
            if (!bound.ok()) return Error{bound.error().message, bound.error().hint};
            issues.clear();
            auto again = parse_sfx(*bound, spec.file, &issues);
            if (!again.ok()) return Error{again.error().message + (issues.empty() ? "" : " " + issues_text(issues)), "A macro bind moves a number outside its range."};
            effective = std::move(*again);
        }
        SfxRenderOptions options;
        options.seed = spec.seed;
        options.macros = spec.macros;
        options.variant = spec.variant;
        if (spec.variant >= effective.variations.count && spec.variant >= 0)
            return Error{"The patch has " + std::to_string(effective.variations.count) + " variants, not " + std::to_string(spec.variant + 1) + ".", "Add or raise \"variations\".count."};
        auto audio = render_sfx(effective, options);
        if (!audio.ok()) return audio.error();
        out.sampleRate = audio->sampleRate;
        out.channels = 1;
        out.samples = std::move(audio->samples);
        out.lufs = audio->lufs;
        out.peakDb = audio->peakDb;
        return out;
    }
    case SoundSpec::Kind::Document: {
        std::vector<AudioDocIssue> issues;
        auto doc = parse_audio_doc(spec.json, spec.file, &issues);
        if (!doc.ok()) return Error{doc.error().message + (issues.empty() ? "" : " " + issues_text(issues)), doc.error().hint};
        RootGuard root(projectDir);
        AudioRenderOptions options;
        if (spec.seedSet) options.seed = spec.seed;
        options.stopAfter = spec.stopAfter;
        auto clip = render_audio_doc(*doc, spec.file, options);
        if (!clip.ok()) return clip.error();
        out.sampleRate = clip->sampleRate;
        out.channels = clip->channels;
        out.samples = std::move(clip->samples);
        out.lufs = clip->lufs;
        out.peakDb = clip->peakDb;
        out.loop = clip->loop;
        out.steps = std::move(clip->steps);
        out.inputs = std::move(clip->inputs);
        return out;
    }
    case SoundSpec::Kind::File: {
        RootGuard root(projectDir);
        auto file = read_audio_file(spec.file);
        if (!file.ok()) return file.error();
        std::string ext = to_lower(std::filesystem::path(file->path).extension().string());
        auto decoded = decode_audio(file->bytes, ext, spec.maxSeconds);
        if (!decoded.ok()) return decoded.error();
        out.sampleRate = decoded->rate;
        out.channels = decoded->channels;
        out.samples = std::move(decoded->samples);
        auto loud = measure_loudness(file->bytes, ext);
        if (loud.ok()) {
            out.lufs = loud->integratedLufs;
            out.peakDb = loud->peakDb;
            out.truncated = spec.maxSeconds > 0.0 && loud->seconds > spec.maxSeconds + 0.01;
        }
        return out;
    }
    }
    return Error{"Unknown sound kind.", ""};
}

}  // namespace fa
