// The logic of the Animation panel's 3D mode with no ImGui and no window: the 3D clip being edited (a factoria.anim3d/1 *.anim.json) and the
// rig it poses, the keys picked in the dopesheet, what a drag of keys, a gizmo or an IK handle asks of the anim3d.* commands, and the maths of the
// bone tools (rings around a bone, a plane to drag in, the limb of an IK handle). anim3d_panel.cpp draws it; anim3d_tests.cpp and the autotest drive it.
//
// ONE SET OF CODE. Every edit is the anim3d.* / ik3d.key call an AI would make, so the file on disk is what the command wrote. Each writing command
// returns its own `undo` (anim3d.restore with the whole previous document); the panel puts that on the editor's undo stack. A gizmo or a handle
// being dragged only changes the pose the viewport shows (the clip is evaluated again from the file); letting go makes ONE command.
#pragma once

#include <array>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/anim3d.h"
#include "fa/tooling/anim3d_tools.h"
#include "fa/tooling/model_view.h"

namespace fa::editor {

using Anim3DCommandFn = std::function<CommandResult(const std::string& name, const Json& args)>;

// ------------------------------------------------------------------------------------------------------------------ keys --
// A key of the clip: the track (bone and channel 0 rotation, 1 translation, 2 scale) and its time in milliseconds (the commands match within 1 ms).
struct Key3D {
    std::string bone;
    int channel = 0;
    long long ms = 0;
    bool operator<(const Key3D& o) const {
        if (bone != o.bone) return bone < o.bone;
        return channel != o.channel ? channel < o.channel : ms < o.ms;
    }
    bool operator==(const Key3D& o) const { return bone == o.bone && channel == o.channel && ms == o.ms; }
};
using Key3DSet = std::set<Key3D>;

long long key3d_ms(double seconds);        // rounded to a millisecond
const char* channel3d_name(int channel);   // "rotation", "translation", "scale"
const char* channel3d_short(int channel);  // "rot", "pos", "scl": the label of a dopesheet row
Json key3d_refs(const Key3DSet& keys);     // [{bone, channel, t}] for the commands' `keys`
double earliest_time3d(const Key3DSet& keys);
double latest_time3d(const Key3DSet& keys);
// "linear", "step", "bezier" or the easing name of a key.
std::string key3d_interp(const ClipKey& key);

// True when project file `rel` is a 3D bone clip (its `format` is factoria.anim3d/1); false for a 2D clip or a file that does not read.
bool anim3d_file_is_3d(const std::string& projectDir, const std::string& rel);

// ---------------------------------------------------------------------------------------------------------------- results --
struct Anim3DEdit {
    bool ok = true;
    std::string error;  // what went wrong, with the command's hint
    Json
        undo;  // {command: "anim3d.restore", args}: what the editor's undo stack keeps (null when the call wrote nothing)
    Json result;
};

// One line of the bone list: the rig's joints, parents first, with how many keys the clip has on each.
struct Anim3DBoneRow {
    std::string name;
    int node = -1;
    int depth = 0;
    int keys = 0;  // keys over every channel of this bone
};

// ---------------------------------------------------------------------------------------------------------------- the model --
class Anim3DModel {
public:
    Anim3DModel(std::string projectDir, Anim3DCommandFn call);

    // ---- the document ---------------------------------------------------------------------------------------------
    // Opens a 3D clip. The rig is `rigRel` (a .rig.glb or .rig.json) or, when empty, the clip's own. Without a rig the clip still opens
    // (the dopesheet works); has_rig() is false and error() says which rig is missing. False when the clip itself does not load.
    bool open(const std::string& clipRel, const std::string& rigRel = {});
    bool set_rig(const std::string& rigRel);  // pose another baked rig with the open clip
    void close();
    bool is_open() const { return open_; }
    bool has_rig() const { return rig_ != nullptr; }
    const std::string& path() const { return clipRel_; }
    const std::string& rig_path() const { return rigRel_; }
    const std::string& error() const { return clipError_.empty() ? rigError_ : clipError_; }
    bool reload();  // reads the clip again; true when it loaded
    bool poll();    // reads it again when the file changed on disk; true when it did
    std::uint64_t revision() const { return revision_; }  // bumped on every (re)load, open and close
    const std::shared_ptr<const Anim3DClip>& clip() const { return clip_; }
    const Anim3DRigModel* rig() const { return rig_.get(); }
    const std::string& projectDir() const { return projectDir_; }

    // ---- the pose -------------------------------------------------------------------------------------------------
    Pose pose_at(double t) const;           // the clip sampled at t (the rig's rest pose when there is no rig)
    MeshData skin(const Pose& pose) const;  // the bind mesh skinned by a pose
    std::vector<Anim3DBoneRow> rows() const;
    int node_of(const std::string& bone) const;  // -1 when the rig has no such joint
    std::string bone_name(int node) const;
    int track_index(const std::string& bone, int channel) const;  // -1 when the clip has no such track
    const ClipKey* key_at(const Key3D& key) const;                // nullptr when there is no such key
    int key_count(const std::string& bone) const;

    // ---- edits: each is one command; `undo` is what the editor's undo stack keeps ----------------------------------
    Anim3DEdit move_keys(const Key3DSet& keys, double dt, bool extend = false);
    Anim3DEdit remove_keys(const Key3DSet& keys);
    Anim3DEdit set_interp(const Key3DSet& keys, const std::string& interp);
    // One key: `value` is 3 numbers (4 for a quaternion rotation). interp "" keeps what an existing key has.
    Anim3DEdit set_key(const std::string& bone, int channel, double t, const std::array<float, 4>& value,
                       const std::string& interp = {});
    // Keys what the clip gives for `bone`/`channel` at t (the current pose: a key that changes nothing but pins the value).
    Anim3DEdit key_sampled(const std::string& bone, int channel, double t);
    Anim3DEdit ik_key(double t, const Json& solver);
    Anim3DEdit mirror(double t, double to, const std::string& from);
    // `name` may be empty when `feel` (game feel actions, an object or array) is given: an event that only runs actions.
    Anim3DEdit add_event(double t, const std::string& name, const Json& data = Json::object(),
                         const Json& feel = Json());
    Anim3DEdit set_event(int index, const Json& changes);  // any of t, name, data
    Anim3DEdit remove_event(int index);
    Anim3DEdit set_clip(const Json& changes);  // any of duration, loop, groundSpeed, doc
    Anim3DEdit generate(const std::string& kind, const Json& params, const std::string& out, bool overwrite = false);
    Anim3DEdit retarget(const std::string& toRig, const std::string& out, bool overwrite = false);
    // Any other command, with the clip's `path` (and the rig) put in; for the panel's one-off calls.
    Anim3DEdit run(const std::string& command, Json args);

private:
    std::string projectDir_;
    Anim3DCommandFn call_;
    bool open_ = false;
    std::string clipRel_, rigRel_, clipError_, rigError_;
    std::shared_ptr<const Anim3DClip> clip_;
    std::shared_ptr<Anim3DRigModel> rig_;
    Anim3DBinding binding_;
    std::uint64_t revision_ = 0;
    std::filesystem::file_time_type mtime_{};
    std::uintmax_t size_ = 0;
    bool load_rig(const std::string& rigRel);
    void bind();
    void stat_file();
};

// ------------------------------------------------------------------------------------------------------------------ maths --
// The panel's rotation gizmo turns a bone about the axes of its PARENT's frame (the frame its pitch, yaw and roll are measured in), so a ring and the
// number it edits agree. `axis` 0, 1, 2 = x, y, z.
Vec3 gizmo_axis_world(const Anim3DRigModel& rig, const Pose& pose, int node, int axis);
// The local rotation of `node` turned by `angle` radians about axis `axis` of its parent's frame.
Quat rotated_local(const Anim3DRigModel& rig, const Pose& pose, int node, int axis, double angle);
// Where bone `node`'s head is in the model's space in `pose`, and the tail (the head of its first joint child, else head + rest axis * length).
Vec3 bone_head(const Anim3DRigModel& rig, const Pose& pose, int node);
Vec3 bone_tail(const Anim3DRigModel& rig, const Pose& pose, int node);
// The angle of the mouse (pixel sx, sy) round `axis` through `center`, in radians in (-pi, pi], measured from a fixed direction of that plane.
// False when the ray runs parallel to the plane.
bool ring_angle(const ModelViewCamera& cam, double sx, double sy, Vec3 center, Vec3 axis, double& angle);
// A turn between two ring angles, taking the short way round.
double angle_delta(double from, double to);
// The point of the plane (through `point`, perpendicular to `normal`) the pixel's ray hits.
bool plane_hit(const ModelViewCamera& cam, double sx, double sy, Vec3 point, Vec3 normal, Vec3& out);
// The distance along the line (`origin` + `direction` * s) of its point nearest to the pixel's ray; false when they are parallel.
bool line_param(const ModelViewCamera& cam, double sx, double sy, Vec3 origin, Vec3 direction, double& s);
// Pixel distance from (px, py) to the segment a-b of the screen.
double segment_distance(double px, double py, double ax, double ay, double bx, double by);
// A point on the circle of `radius` round `center` in the plane perpendicular to `axis`, at `angle` (the same zero ring_angle uses).
Vec3 ring_point(Vec3 center, Vec3 axis, double radius, double angle);

// The three bones of a limb handle: the dragged bone is the END, its parent the MID, the parent's parent the ROOT (all joints), or -1.
struct Anim3DLimb {
    int root = -1, mid = -1, end = -1;
    bool valid() const { return root >= 0 && mid >= 0 && end >= 0; }
};
Anim3DLimb limb_of(const Anim3DRigModel& rig, int endNode);
// A point for the pole handle of a limb: the mid joint pushed out of the root-end line by the length of the shorter bone, in the direction it bends.
Vec3 default_pole(const Anim3DRigModel& rig, const Pose& pose, const Anim3DLimb& limb);
// The solver objects of ik3d.key / ik3d_solve_once for a handle.
Json two_bone_solver(const Anim3DRigModel& rig, const Anim3DLimb& limb, Vec3 target, Vec3 pole);
Json look_at_solver(const Anim3DRigModel& rig, int node, Vec3 target);
// True for a bone the look-at handle suits (head, neck, an eye).
bool aims_like_a_head(const Anim3DRigModel& rig, int node);

}  // namespace fa::editor
