// The state of the Music panel (music_panel.cpp): which track and pattern the piano roll shows, the notes being dragged, the drum grid, the
// arrangement selection, what plays. The rules that need no window (the edits, the renders, the undo steps) are in music_model.h and the
// playback in music_preview.h.
#pragma once

#include <cstdint>
#include <memory>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "music_model.h"
#include "music_preview.h"

namespace fa::editor {

struct MusicUi {
    std::unique_ptr<MusicModel> model;
    std::unique_ptr<MusicPreview> preview;
    std::string openError;  // why the file the user asked for could not be opened
    bool focused = false;
    std::uint64_t lastPoll = 0;

    enum class Tab { Roll, Drums, Arrangement, Mixer } tab = Tab::Roll;

    // ---- transport
    float intensity = 0.0f;  // the slider; the layers fade to it while the preview plays
    bool loopSection = false;
    int section = 0;  // the section "Play section" and "Loop" mean (index in the song)
    int pendingSection =
        -2;  // Play was pressed before the first render finished: -2 nothing waits, -1 the whole song, else a section
    bool pendingLoop = false;

    // ---- the piano roll
    std::string track, pattern;
    int snap = 3;       // index in the snap table (1/1 ... 1/32)
    int velocity = 90;  // the velocity a new note gets, and the slider that sets the selected notes
    bool scaleHighlight = true;
    float pxPerBeat = 56.0f;
    int pitchTop = 0;             // the highest pitch row shown (0: fit to the notes next frame)
    std::int64_t cursorTick = 0;  // where the last click was (chords are inserted here)
    float rollX0 = 0, rollY0 = 0, rollW = 0,
          rollH = 0;                  // the roll in screen coordinates (last frame): X0 is where tick 0 is
    std::vector<SongRollNote> notes;  // the notes of track/pattern as the model has them
    std::string notesKey;
    std::uint64_t notesRev = ~0ULL;
    std::vector<SongRollNote> work;  // the working copy while a drag is going on
    std::vector<SongRollNote> orig;  // what the drag started from
    enum class Drag { None, Draw, Move, Resize, Velocity } drag = Drag::None;
    bool dragChanged = false;
    int dragNote = -1;
    std::int64_t anchorTick = 0;
    int anchorPitch = 0;
    std::set<int> sel;  // indices into the notes being shown
    std::vector<std::pair<std::int64_t, int>>
        selKeys;  // (tick, pitch) of the selection, to find it again after an edit
    std::string chordName = "Am7";
    int chordOctave = 3;
    std::string progression;
    int arpDirection = 0, arpOctaves = 1, arpRate = 1, bassStyle = 1, drumStyle = 0;
    bool drumFill = false;

    // ---- the drum grid
    std::string drumTrack, drumPattern;
    std::string newLane = "kick";
    float gridX0 = 0, gridY0 = 0, cellW = 0, cellH = 0;  // the grid's cells in screen coordinates (last frame)
    std::vector<std::string> gridLanes;                  // the lanes in the order drawn

    // ---- the arrangement
    std::string newSection = "bridge";
    std::string newLayer = "extra";
    std::string textKey, text;  // the text field being typed in (its key) and what it holds
    std::string liveKey;        // the drag field being dragged (its key) and the value it shows meanwhile
    double liveValue = 0.0;

    // ---- the mixer
    std::string newTrack = "keys";
    std::string newTrackInstrument = "pluck";
    std::string newBus = "hall";
    std::string newEffect = "reverb";
    Json measured;  // the last music.mix result
    bool overwriteBaked = false;
};

}  // namespace fa::editor
