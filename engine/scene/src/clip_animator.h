// The Animator when it plays keyframed 2D clips (*.anim.json, anim_clip.h): private to fa_scene. animation.cpp decides
// which kind an Animator is and forwards its public calls here.
//
// How a step runs (update): the state machine and the layers' state machines pick clips; every player (the main clip, its
// cross-fade source, each layer) advances its time and fires clip events; then the pose is composed: every field a clip has
// ever driven on this Animator ("slot") starts from its rest value (what it held before the first clip drove it), the main
// clip (blended with the clip it fades from) overrides it, each layer follows in order, and the result is written into the
// components. A field the current clip does not drive therefore goes back to rest (the "write defaults" of Mecanim).
#pragma once

#include <array>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "fa/scene/anim_clip.h"
#include "fa/scene/world.h"

namespace fa {

// One clip being played by the main player or a layer, with the clip it cross-fades from.
struct ClipPlayer {
    std::string name;               // key in Animator::clips; "" = nothing
    float time = 0.0f;
    float prevTime = -1.0f;         // start of the window of clip events to fire (-1: the clip just started)
    float lastTime = 0.0f;          // `time` after the last update (a different value means a script seeked)
    bool finished = false;          // a clip that does not loop reached its end
    std::string from;               // clip fading out ("" = no fade running)
    float fromTime = 0.0f;
    bool fromLoop = true;
    float fadeElapsed = 0.0f, fadeDuration = 0.0f;
};

// A clip file resolved against the entity that plays it.
struct ClipBinding {
    std::string name, file;
    std::shared_ptr<const ClipAsset> asset;
    std::vector<Entity> targets;    // per ClipAsset::paths; null = not found (yet)
    std::vector<int> slot;          // per ClipAsset::tracks; -1 = its target is missing
    std::vector<ClipIssue> issues;  // tracks that could not be bound (no such entity or component): the others still play
};

// A field some clip drives: the unit of the pose.
struct ClipSlot {
    Entity entity;
    const TypeInfo* type = nullptr;
    const FieldInfo* field = nullptr;
    bool stepped = false;
    bool angle = false;
    std::array<float, 4> rest{};    // interpolating fields: the value before the first clip drove it
    Json restJson;                  // stepping fields: the same, as JSON
    unsigned channels = 0;          // bit i: some track drives channel i (all of a stepping field's value: 1)
    int refs = 0;                   // bindings' tracks that name it
    bool dead = false;
    Json written;                   // stepping fields: what was last written
    bool hasWritten = false;
};

struct ClipLayer {
    std::string name;
    Json config;                    // the Animator.layers entry this was read from
    ClipPlayer player;
    std::string state;              // a layer with `states`
    bool started = false;
    float weight = 1.0f;
    bool additive = false;
    float speed = 1.0f;             // `speed` of the config
    float stateSpeed = 1.0f;        // `speed` of the current state
    bool cfgLoopSet = false, cfgLoop = true;       // `loop` of the config
    bool stateLoopSet = false, stateLoop = true;   // `loop` of the current state
    std::vector<std::string> mask;
    std::string maskKey;
    std::string clipSeen;           // the `clip` of the config the player was started for
};

struct ClipRuntime {
    std::map<std::string, ClipBinding> bindings;   // by clip name
    std::vector<ClipSlot> slots;
    ClipPlayer main;
    bool loopForced = false;        // the state that started the clip set `loop` itself: the clip's own loop is ignored
    std::vector<ClipLayer> layers;
    Json layersSeen;
    std::set<std::string> warned;
    int sincePoll = 0;              // updates since the clip files and target entities were last checked
};

namespace clipanim {

// True when `a` plays *.anim.json clips: it has `clips`, no `model`, and no glTF on the entity's MeshRenderer.
bool uses_clip_files(const World& w, Entity e, const Animator& a);

void update(World& w, Entity e, Animator& a, float dt);
Result<void> play(World& w, Entity e, Animator& a, std::string_view clip, float fade);
Result<void> stop(World& w, Entity e, Animator& a);
Result<Json> clips(World& w, Entity e, Animator& a);
Result<void> sample(World& w, Entity e, Animator& a, std::string_view clip, float time);
Result<void> set_layer_weight(World& w, Entity e, Animator& a, std::string_view layer, float weight);
Result<void> play_layer(World& w, Entity e, Animator& a, std::string_view layer, std::string_view clip, float fade);

}  // namespace clipanim

namespace animdetail {
// The state machine's condition language and the game event, shared with the glTF side of the Animator (animation.cpp).
bool condition_holds(const std::string& expr, const Json& values, const std::vector<std::string>& triggers);
void emit_game_event(World& w, const std::string& name, Entity source, Json data);
}  // namespace animdetail

}  // namespace fa
