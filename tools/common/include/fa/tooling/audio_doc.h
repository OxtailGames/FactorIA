// Baking audio documents (`*.audio.json`, docs/SOUND.md "Audio documents"): the sound file next to the document, its provenance and
// recipe in assets.json, and whether that file is current. The format, the renderer and the DSP are fa_audio's (fa/audio/audio_doc.h);
// this is the project side, shared by the audio.* commands, project.validate and `factoria export` (which bakes first, like image documents).
#pragma once

#include <string>
#include <vector>

#include "fa/audio/audio_doc.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// The project-relative sound a document at `rel` bakes to: `output.path`, else `rel` with ".audio.json" replaced by the format's
// extension (.wav or .ogg).
std::string audio_document_output(const AudioDoc& doc, const std::string& rel);

enum class AudioBakeState {
    Fresh,       // the sound exists and the recipe in assets.json matches the document and every file it read
    Missing,     // no sound yet
    Stale,       // the document or a file it reads changed since the bake
    Unrecorded,  // the file exists but assets.json does not say it was baked from this document
    Broken       // the document does not load, or its output is the file it reads
};
struct AudioBakeStatus {
    AudioBakeState state = AudioBakeState::Missing;
    std::string output;  // project-relative; "" when Broken
    std::string reason;  // one sentence for a person
    std::string hint;    // how to fix it, when Broken
};
AudioBakeStatus audio_bake_status(const std::string& projectDir, const std::string& rel);
const char* audio_bake_state_name(AudioBakeState state);

struct AudioBakeOptions {
    bool onlyIfNeeded = false;  // do nothing when the status is Fresh
    bool overwrite = false;     // replace a file at the output that this document did not make
};
struct AudioBakeResult {
    std::string document;  // project-relative
    std::string output;    // the sound, project-relative
    bool written = false;  // false: it was Fresh and onlyIfNeeded was set
    std::size_t bytes = 0;
    AudioClip clip;        // what was rendered (empty when not written)
    std::string sha256;    // of the file's bytes
    std::vector<std::string> inputs;
    Json provenance;       // the record written to assets.json
};
// Renders the document and writes the sound (deterministic bytes), then records provenance + recipe {command "audio.bake",
// args {path}, inputs: the document and every file it read} in assets.json, and the loop points of a `loop` step as the import
// settings loopStart / loopEnd (erased when the document has no loop). Keeps the license and author a person recorded.
Result<AudioBakeResult> bake_audio_document(const std::string& projectDir, const std::string& rel, const AudioBakeOptions& options = {});

// Every *.audio.json of the project (project-relative, sorted; hidden folders, node_modules and a top-level build/ skipped).
std::vector<std::string> list_audio_documents(const std::string& projectDir);
// Bakes the documents whose sound is missing or stale (what `factoria export` does first). A document that does not load is an error
// naming it. Returns the baked documents.
Result<std::vector<AudioBakeResult>> bake_audio_documents_if_needed(const std::string& projectDir);

}  // namespace fa
