// The state of the Sound panel (sound_panel.cpp): how the waveform is looked at, the selection, the A/B slots, what plays. The rules that need no
// window (the renders, the measurements, the edits, the undo steps) are in sound_model.h and the playback in sound_player.h.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "sound_model.h"
#include "sound_schema.h"
#include "sound_player.h"

namespace fa::editor {

struct SoundUi {
    std::unique_ptr<SoundModel> model;
    std::unique_ptr<SoundPlayer> player;
    std::string openError;            // why the file the user asked for could not be opened

    // ---- the view of the time axis (seconds)
    double viewStart = 0.0, viewLen = 0.0;   // viewLen 0: fit the whole sound next frame
    bool fitNext = true;
    float waveX = 0, waveY = 0, waveW = 0, waveH = 0;   // the waveform, in screen coordinates (last frame)
    double shownSeconds = 0.0;        // the length the view was fitted to

    // ---- selection and cursor
    bool hasSelection = false;
    double sel0 = 0.0, sel1 = 0.0;    // seconds, sel0 <= sel1 once released
    double cursor = 0.0;              // where Play starts without a selection
    enum class Drag { None, Select, Pan, LoopStart, LoopEnd } drag = Drag::None;
    double dragAnchor = 0.0;
    double panAnchor = 0.0;

    // ---- playing
    bool loopPlay = false;
    bool playSelection = true;        // play the selection when there is one
    bool levelMatch = true;           // A/B at the same loudness
    SoundSlot slotA{SoundSlotKind::Current, 0}, slotB{SoundSlotKind::Before, 0};
    int heard = 0;                    // 0 nothing, 1 slot A, 2 slot B, 3 the sound itself
    int heardVariant = 0;             // 1-based; the variant a list row plays (0 none)
    std::string playingName;

    // ---- the spectrogram
    std::uint32_t specImage = 0, specView = 0;
    std::uint64_t specRender = 0;
    struct Dead {
        std::uint32_t image, view;
        std::uint64_t frame;
    };
    std::vector<Dead> graveyard;

    // ---- panels
    bool showSpectrogram = true;
    std::string presetPick;
    bool overwriteBaked = false;
    std::string newStepType = "gain";
    std::string newEffectType = "filter";
    bool focused = false;
    std::uint64_t lastPoll = 0;
    std::string textKey;              // the text field being typed in (its JSON pointer / step field) and what it holds
    std::string text;
    int openStep = -1;                // the chain step whose fields show
};

}  // namespace fa::editor
