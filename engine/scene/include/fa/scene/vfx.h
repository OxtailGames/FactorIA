// Effect documents: a `*.vfx.json` bundles several emitters, a light flash, sounds and commands (a camera shake, a hit-stop, ...)
// on one timeline, so a game plays "the hit effect" with one call: `vfx.play` (a command and `vfx.play()` in scripts) or an entity
// with a `Vfx` component placed in a scene like a prefab. See docs/PARTICLES.md, "Effect documents".
//
// The file (format "factoria.vfx/1", schemas/vfx.schema.json) is parsed into a VfxDoc: plain data, checked once, with errors that
// name the file and the JSON pointer and say how to fix it. update_vfx() is the system: once per fixed step, with the step's length
// times time.scale, it advances every playing Vfx and starts the parts whose time has come. It uses no clock and no random numbers:
// the same effects at the same steps do the same things on every run and platform.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/curve.h"
#include "fa/scene/world.h"

namespace fa {

// ------------------------------------------------------------------------------------------------------------ limits --
constexpr int kVfxMaxParts = 16;           // parts (emitters, lights, sounds, commands) of one effect
constexpr int kVfxMaxEmitters = 8;         // of those, emitters
constexpr int kVfxMaxCommands = 8;         // of those, commands
constexpr double kVfxMaxDuration = 30.0;   // seconds: the longest an effect, or a part of it, may last
constexpr double kVfxMinLoop = 0.1;        // seconds: a looping effect shorter than this waits until it is this long before it restarts
constexpr double kVfxMaxLinger = 30.0;     // seconds an ended autoDestroy effect waits for its emitters' particles before it goes anyway
constexpr int kVfxMaxPlaying = 64;         // Vfx playing at once: a play past this is dropped (and logged once)
constexpr int kVfxMaxLiveParticles = 4000; // warning: the emitters of one effect may hold more live particles than this together

enum class VfxPartKind { Emitter, Light, Sound, Command };

// One thing the effect does. Which fields are used depends on `kind`; the rest keep their defaults.
struct VfxPart {
    VfxPartKind kind = VfxPartKind::Emitter;
    std::string name;       // names the child entity an emitter or a light becomes ("sparks"); defaults to the kind and index
    double at = 0.0;        // seconds after the effect starts
    double duration = 0.0;  // emitter: how long it keeps emitting its `rate` (0: only its burst); light: how long it lasts
    Vec3 offset{0, 0, 0};   // emitter and light: where, relative to the effect

    Json emitter = Json::object();  // Emitter: the fields of a ParticleEmitter (a patch over the defaults)
    bool light3d = false;           // Light: a 3D Light instead of a Light2D
    Json light = Json::object();    // Light: the fields of the Light2D (or Light when light3d)
    Curve fade;                     // Light: multiplies its intensity over its life, position 0..1; empty = a straight fade out

    std::string clip;               // Sound: the audio file
    float volume = 1.0f;            // Sound
    float pitch = 1.0f;             // Sound
    std::string bus = "sfx";        // Sound: mixer bus

    std::string command;            // Command: the command to call, e.g. "feel.shake"
    Json args = Json::object();     // Command: its arguments
};

struct VfxDoc {
    std::string path;               // where it was read from
    std::string description;        // the file's "doc"
    double duration = 0.0;          // seconds until every part has started and ended (the file's "duration", or worked out)
    std::vector<VfxPart> parts;
    std::int64_t mtime = 0;         // of the file when it was read (cache validity)
};

// One thing wrong, or useless, in a document. `pointer` is a JSON pointer inside the file ("/parts/2/clip").
struct VfxIssue {
    bool error = true;  // false: a warning, the effect still plays
    std::string pointer;
    std::string message;
    std::string hint;
};

// The commands a `command` part may call: the game feel API and the audio commands. An effect cannot write files or destroy
// entities. Matched as a prefix of the command name.
const std::vector<std::string>& vfx_command_prefixes();

// Checks a parsed JSON document. On an error the Error names the file, the pointer and the fix of the first problem (and says how
// many more there are); `issues` receives every problem, warnings included, and is filled on success too.
Result<std::shared_ptr<const VfxDoc>> parse_vfx(const Json& json, std::string_view file, std::vector<VfxIssue>* issues = nullptr);

// Reads a document through fa::fs. Cached per path, modification time and size: every Vfx that plays the same file shares one
// VfxDoc, and a file that changed on disk is read again by the next call (hot reload: effects already playing finish the version
// they started with). An unreadable or invalid file is an Error; the cache keeps the last good version.
Result<std::shared_ptr<const VfxDoc>> load_vfx(std::string_view path, std::vector<VfxIssue>* issues = nullptr);
void clear_vfx_cache();  // forgets every cached document (tests)

// The files a document names that `exists` says are not there (the clips of its sound parts), as errors with the JSON pointer and
// the fix. `exists` takes the path as written in the file; the runtime passes fa::fs::exists, the project validator a check
// against the project folder.
std::vector<VfxIssue> vfx_missing_assets(const VfxDoc& doc, const std::function<bool(const std::string&)>& exists);

// What the system needs from the game. Unset members do nothing (a headless test with no audio).
struct VfxHost {
    // Plays a one-shot sound; returns false when it could not start (logged by the caller once).
    std::function<bool(const std::string& clip, float volume, float pitch, const std::string& bus)> play_sound;
    // Calls a command; returns "" when it worked, else what went wrong.
    std::function<std::string(const std::string& command, const Json& args)> call;
};

// Advances every active Vfx by `dt` seconds (dt 0: only a change of `playing` or `effect` applies): loads its document, starts
// the parts whose time has come (children of the Vfx entity: ParticleEmitter, Light2D / Light), animates the lights, and at the
// end of the effect clears `playing` and, with `autoDestroy`, removes the entity once its emitters have emptied. A document that
// cannot be read is logged once per file and change. Run once per FIXED step, like update_videos().
void update_vfx(World& world, float dt, const VfxHost& host);

// Starts an effect: a new entity with a Vfx component (autoDestroy on), at `position` in the world, or a child of `parent` at
// `position` relative to it. Returns the entity, or the reason it could not start (file problem, budget). The effect starts at
// the next update_vfx.
struct VfxPlayOptions {
    Vec3 position{0, 0, 0};
    Entity parent = kNullEntity;  // not null: follows this entity, `position` is local to it
    float rotation = 0.0f;        // degrees around z (2D)
    float scale = 1.0f;
    float speed = 1.0f;           // 1 = as written; 2 = twice as fast
    bool loop = false;
};
Result<Entity> vfx_play(World& world, std::string_view effect, const VfxPlayOptions& options = {});

// Ends an effect. immediate: the entity and its children go at once (their particles vanish); else the parts that have not
// started never do, lights end, and emitters stop emitting but let their particles finish.
void vfx_stop(World& world, Entity vfx, bool immediate);

// How many Vfx are playing now (the budget kVfxMaxPlaying counts them).
int vfx_playing_count(const World& world);

}  // namespace fa
