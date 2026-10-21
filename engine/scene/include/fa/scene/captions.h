// The caption list: the subtitles the game has put on screen and are still running (`audio.play(path, { caption })`,
// `ui.caption(text, seconds)`), and the pass that hands the newest lines to the Captions components that draw them.
// Time comes from the world clock (World::time, the engine clock), never the wall clock. docs/TEXT.md, "Captions".
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/i18n.h"
#include "fa/scene/world.h"

namespace fa {

struct CaptionLine {
    std::string text;      // what is shown; rewritten from `key` in the current language while a key is set
    std::string speaker;   // name shown before the line, "" = none
    std::string key;       // localization key, "" = plain text
    std::string source;    // "audio:<clip path>" for a sound's caption, "ui" for ui.caption
    std::uint32_t voice = 0;  // the sound it lives with (fa::VoiceId), 0 = none
    double endsAt = -1.0;  // world time it ends at, < 0 = only when the sound ends
};

class CaptionList {
public:
    static constexpr std::size_t kMaxLines = 32;  // the oldest are dropped beyond this

    void add(CaptionLine line);
    void remove_voice(std::uint32_t voice);   // audio.stop(voice)
    void remove_all_voices();                 // audio.stopAll()
    void clear() { lines_.clear(); }
    const std::vector<CaptionLine>& lines() const { return lines_; }  // oldest first
    std::size_t size() const { return lines_.size(); }

    // Drops the lines that ended (their sound is no longer playing per `voicePlaying`, or world.time() reached endsAt),
    // rewrites keyed lines in the current language, and writes the newest Captions.maxLines lines into every Captions
    // component. Logs one hint per run when a line is on the list and the world has no Captions entity. Returns true when
    // anything visible changed.
    bool update(World& world, const I18n& i18n, const std::function<bool(std::uint32_t)>& voicePlaying);

private:
    std::vector<CaptionLine> lines_;
    bool hinted_ = false;
};

}  // namespace fa
