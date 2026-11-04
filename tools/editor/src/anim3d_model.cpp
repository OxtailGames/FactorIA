#include "anim3d_model.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <fstream>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/rig3d.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

// ------------------------------------------------------------------------------------------------------------------ keys --
long long key3d_ms(double seconds) { return std::llround(seconds * 1000.0); }

const char* channel3d_name(int channel) { return channel == 1 ? "translation" : channel == 2 ? "scale" : "rotation"; }
const char* channel3d_short(int channel) { return channel == 1 ? "pos" : channel == 2 ? "scl" : "rot"; }

Json key3d_refs(const Key3DSet& keys) {
    Json out = Json::array();
    for (const Key3D& k : keys)
        out.push_back(Json::object({{"bone", k.bone}, {"channel", channel3d_name(k.channel)}, {"t", double(k.ms) / 1000.0}}));
    return out;
}

double earliest_time3d(const Key3DSet& keys) {
    long long best = 0;
    bool first = true;
    for (const Key3D& k : keys)
        if (first || k.ms < best) best = k.ms, first = false;
    return double(best) / 1000.0;
}

double latest_time3d(const Key3DSet& keys) {
    long long best = 0;
    bool first = true;
    for (const Key3D& k : keys)
        if (first || k.ms > best) best = k.ms, first = false;
    return double(best) / 1000.0;
}

std::string key3d_interp(const ClipKey& key) {
    switch (key.interp) {
        case ClipInterp::Step: return "step";
        case ClipInterp::Bezier: return "bezier";
        case ClipInterp::Ease: {
            const auto& names = clip_ease_names();
            return key.ease >= 0 && std::size_t(key.ease) < names.size() ? names[std::size_t(key.ease)] : "linear";
        }
        default: return "linear";
    }
}

bool anim3d_file_is_3d(const std::string& projectDir, const std::string& rel) {
    std::ifstream in(stdfs::path(projectDir) / rel, std::ios::binary);
    if (!in) return false;
    std::stringstream buf;
    buf << in.rdbuf();
    const Json json = Json::parse(buf.str(), nullptr, false);
    return !json.is_discarded() && is_anim3d_json(json);
}

// ---------------------------------------------------------------------------------------------------------------- results --
namespace {

std::string error_text(const Json& error) {
    if (!error.is_object()) return error.dump();
    std::string s = error.value("message", std::string());
    const std::string hint = error.value("hint", std::string());
    if (!hint.empty()) s += " " + hint;
    return s.empty() ? error.dump() : s;
}

int channel_of(Anim3DChannel c) { return c == Anim3DChannel::Translation ? 1 : c == Anim3DChannel::Scale ? 2 : 0; }

}  // namespace

// ---------------------------------------------------------------------------------------------------------------- the model --
Anim3DModel::Anim3DModel(std::string projectDir, Anim3DCommandFn call) : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

void Anim3DModel::stat_file() {
    std::error_code ec;
    mtime_ = stdfs::last_write_time(stdfs::path(projectDir_) / clipRel_, ec);
    size_ = stdfs::file_size(stdfs::path(projectDir_) / clipRel_, ec);
}

bool Anim3DModel::open(const std::string& clipRel, const std::string& rigRel) {
    close();
    clipRel_ = clipRel;
    open_ = true;
    if (!reload()) {
        const std::string why = clipError_;
        close();
        clipError_ = why;
        return false;
    }
    std::string rig = rigRel;
    if (rig.empty()) rig = clip_->rig;
    if (rig.empty()) {
        rigError_ = "The clip names no rig: choose the baked rig (*.rig.glb) to pose with it.";
        return true;
    }
    if (!load_rig(rig) ) return true;   // the clip is open, error() says what the rig lacks
    return true;
}

bool Anim3DModel::load_rig(const std::string& rigRel) {
    rig_.reset();
    binding_ = Anim3DBinding{};
    rigRel_ = rigRel;
    auto loaded = load_anim3d_rig_model(projectDir_, rigRel);
    if (!loaded.ok()) {
        rigError_ = "Cannot pose the clip with " + rigRel + ": " + loaded.error().message + (loaded.error().hint.empty() ? "" : " " + loaded.error().hint);
        return false;
    }
    rig_ = *loaded;
    rigError_.clear();
    bind();
    ++revision_;
    return true;
}

bool Anim3DModel::set_rig(const std::string& rigRel) {
    if (!open_) return false;
    return load_rig(rigRel);
}

void Anim3DModel::bind() {
    binding_ = rig_ && clip_ ? bind_anim3d(*clip_, *rig_->skeleton) : Anim3DBinding{};
}

void Anim3DModel::close() {
    open_ = false;
    clipRel_.clear();
    rigRel_.clear();
    clipError_.clear();
    rigError_.clear();
    clip_.reset();
    rig_.reset();
    binding_ = Anim3DBinding{};
    ++revision_;
}

bool Anim3DModel::reload() {
    if (!open_) return false;
    std::ifstream in(stdfs::path(projectDir_) / clipRel_, std::ios::binary);
    if (!in) {
        clipError_ = "Cannot read " + clipRel_ + ".";
        clip_.reset();
        return false;
    }
    std::stringstream buf;
    buf << in.rdbuf();
    Json json = Json::parse(buf.str(), nullptr, false);
    if (json.is_discarded()) {
        clipError_ = clipRel_ + " is not valid JSON.";
        clip_.reset();
        return false;
    }
    if (!is_anim3d_json(json)) {
        clipError_ = clipRel_ + " is not a 3D bone clip (its format is not " + std::string(kAnim3DFormat) + "); the 2D mode edits 2D clips.";
        clip_.reset();
        return false;
    }
    auto parsed = parse_anim3d(json, clipRel_);
    if (!parsed.ok()) {
        clipError_ = parsed.error().message + (parsed.error().hint.empty() ? "" : " " + parsed.error().hint);
        clip_.reset();
        return false;
    }
    clip_ = *parsed;
    clipError_.clear();
    bind();
    stat_file();
    ++revision_;
    return true;
}

bool Anim3DModel::poll() {
    if (!open_) return false;
    std::error_code ec;
    const auto t = stdfs::last_write_time(stdfs::path(projectDir_) / clipRel_, ec);
    const auto s = stdfs::file_size(stdfs::path(projectDir_) / clipRel_, ec);
    if (ec) return false;
    if (t == mtime_ && s == size_) return false;
    return reload();
}

Pose Anim3DModel::pose_at(double t) const {
    if (!rig_) return Pose{};
    Pose pose = rig_->rig.rest;
    if (clip_) sample_anim3d(*clip_, binding_, *rig_->skeleton, float(t), pose);
    return pose;
}

MeshData Anim3DModel::skin(const Pose& pose) const { return rig_ ? skin_rig_mesh(*rig_, pose) : MeshData{}; }

int Anim3DModel::node_of(const std::string& bone) const { return rig_ ? rig_->rig.find(bone) : -1; }

std::string Anim3DModel::bone_name(int node) const {
    return rig_ && node >= 0 && node < rig_->rig.node_count() ? rig_->rig.node(node).name : std::string();
}

int Anim3DModel::track_index(const std::string& bone, int channel) const {
    if (!clip_) return -1;
    for (std::size_t i = 0; i < clip_->tracks.size(); ++i)
        if (clip_->tracks[i].bone == bone && channel_of(clip_->tracks[i].channel) == channel) return int(i);
    return -1;
}

const ClipKey* Anim3DModel::key_at(const Key3D& key) const {
    const int i = track_index(key.bone, key.channel);
    if (i < 0) return nullptr;
    for (const ClipKey& k : clip_->tracks[std::size_t(i)].keys)
        if (key3d_ms(k.t) == key.ms) return &k;
    return nullptr;
}

int Anim3DModel::key_count(const std::string& bone) const {
    int n = 0;
    if (clip_)
        for (const Anim3DTrack& t : clip_->tracks)
            if (t.bone == bone) n += int(t.keys.size());
    return n;
}

std::vector<Anim3DBoneRow> Anim3DModel::rows() const {
    std::vector<Anim3DBoneRow> out;
    if (!rig_) return out;
    const Rig3D& rig = rig_->rig;
    for (int node : rig.bones) {
        Anim3DBoneRow r;
        r.node = node;
        r.name = rig.node(node).name;
        for (int p = rig.node(node).parent; p >= 0; p = rig.node(p).parent)
            if (rig.is_bone(p)) ++r.depth;
        r.keys = key_count(r.name);
        out.push_back(r);
    }
    return out;
}

// ---------------------------------------------------------------------------------------------------------------- edits --
Anim3DEdit Anim3DModel::run(const std::string& command, Json args) {
    Anim3DEdit out;
    if (!open_) {
        out.ok = false;
        out.error = "No 3D clip is open.";
        return out;
    }
    if (!args.is_object()) args = Json::object();
    if (!args.contains("path")) args["path"] = clipRel_;
    const CommandResult r = call_(command, args);
    if (!r.ok) {
        out.ok = false;
        out.error = command + ": " + error_text(r.error);
        return out;
    }
    out.result = r.result;
    if (r.result.is_object() && r.result.contains("undo")) out.undo = r.result["undo"];
    reload();
    return out;
}

Anim3DEdit Anim3DModel::move_keys(const Key3DSet& keys, double dt, bool extend) {
    Json a = Json::object({{"keys", key3d_refs(keys)}, {"dt", dt}});
    if (extend) a["extendDuration"] = true;
    return run("anim3d.move_keys", a);
}

Anim3DEdit Anim3DModel::remove_keys(const Key3DSet& keys) { return run("anim3d.remove_keys", Json::object({{"keys", key3d_refs(keys)}})); }

Anim3DEdit Anim3DModel::set_interp(const Key3DSet& keys, const std::string& interp) {
    return run("anim3d.set_interp", Json::object({{"keys", key3d_refs(keys)}, {"interp", interp}}));
}

Anim3DEdit Anim3DModel::set_key(const std::string& bone, int channel, double t, const std::array<float, 4>& value, const std::string& interp) {
    const bool quat = channel == 0 && clip_ && clip_->quat;
    Json v = Json::array();
    for (int i = 0; i < (quat ? 4 : 3); ++i) v.push_back(double(std::round(value[std::size_t(i)] * 10000.0f)) / 10000.0);
    Json key = Json::object({{"t", t}, {"value", v}});
    if (!interp.empty()) key["interp"] = interp;
    return run("anim3d.set_keys", Json::object({{"bone", bone}, {"channel", channel3d_name(channel)}, {"keys", Json::array({key})}}));
}

Anim3DEdit Anim3DModel::key_sampled(const std::string& bone, int channel, double t) {
    Anim3DEdit none;
    if (!clip_ || !rig_) {
        none.ok = false;
        none.error = "Pose a rig with the clip first.";
        return none;
    }
    const int track = track_index(bone, channel);
    std::array<float, 4> v{};
    if (track >= 0) {
        v = sample_anim3d_track(clip_->tracks[std::size_t(track)], clip_->quat && channel == 0, float(t));
    } else if (channel == 0 && clip_->quat) {
        v = {0, 0, 0, 1};
    } else if (channel == 2) {
        v = {1, 1, 1, 0};
    }
    return set_key(bone, channel, t, v);
}

Anim3DEdit Anim3DModel::ik_key(double t, const Json& solver) {
    Json a = Json::object({{"time", t}, {"solver", solver}});
    if (!rigRel_.empty()) a["rig"] = rigRel_;
    return run("ik3d.key", a);
}

Anim3DEdit Anim3DModel::mirror(double t, double to, const std::string& from) {
    Json a = Json::object({{"time", t}, {"to", to}, {"from", from}});
    if (!rigRel_.empty()) a["rig"] = rigRel_;
    return run("anim3d.mirror_pose", a);
}

Anim3DEdit Anim3DModel::add_event(double t, const std::string& name, const Json& data) {
    Json a = Json::object({{"t", t}, {"name", name}});
    if (data.is_object() && !data.empty()) a["data"] = data;
    return run("anim3d.add_event", a);
}

Anim3DEdit Anim3DModel::set_event(int index, const Json& changes) {
    Json a = changes.is_object() ? changes : Json::object();
    a["event"] = index;
    return run("anim3d.set_event", a);
}

Anim3DEdit Anim3DModel::remove_event(int index) { return run("anim3d.remove_event", Json::object({{"event", index}})); }

Anim3DEdit Anim3DModel::set_clip(const Json& changes) { return run("anim3d.set_clip", changes); }

Anim3DEdit Anim3DModel::generate(const std::string& kind, const Json& params, const std::string& out, bool overwrite) {
    Anim3DEdit e;
    if (rigRel_.empty()) {
        e.ok = false;
        e.error = "Choose a rig first: a clip is generated for one.";
        return e;
    }
    Json a = Json::object({{"rig", rigRel_}, {"kind", kind}, {"out", out}});
    if (params.is_object() && !params.empty()) a["params"] = params;
    if (overwrite) a["overwrite"] = true;
    const CommandResult r = call_("anim3d.generate", a);
    if (!r.ok) {
        e.ok = false;
        e.error = "anim3d.generate: " + error_text(r.error);
        return e;
    }
    e.result = r.result;
    if (r.result.contains("undo")) e.undo = r.result["undo"];
    return e;
}

Anim3DEdit Anim3DModel::retarget(const std::string& toRig, const std::string& out, bool overwrite) {
    Anim3DEdit e;
    if (!open_) {
        e.ok = false;
        e.error = "No 3D clip is open.";
        return e;
    }
    Json a = Json::object({{"path", clipRel_}, {"to", toRig}, {"out", out}});
    if (!rigRel_.empty()) a["from"] = rigRel_;
    if (overwrite) a["overwrite"] = true;
    const CommandResult r = call_("anim3d.retarget", a);
    if (!r.ok) {
        e.ok = false;
        e.error = "anim3d.retarget: " + error_text(r.error);
        return e;
    }
    e.result = r.result;
    if (r.result.contains("undo")) e.undo = r.result["undo"];
    return e;
}

// ------------------------------------------------------------------------------------------------------------------ maths --
namespace {

constexpr double kPi = 3.14159265358979323846;

Quat parent_global(const Anim3DRigModel& rig, const Pose& pose, int node) {
    const SkeletonAsset& sk = *rig.skeleton;
    const int parent = sk.nodes[std::size_t(node)].parent;
    if (parent < 0) return Quat{};
    const PoseFrame f = pose_frame(sk, pose);
    return f.rot[std::size_t(parent)];
}

// Two directions perpendicular to `axis` (the same pair for the same axis: ring_angle and ring_point agree).
void plane_basis(Vec3 axis, Vec3& u, Vec3& v) {
    const Vec3 a = normalize(axis);
    const Vec3 helper = std::fabs(a.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
    u = normalize(cross(helper, a));
    v = cross(a, u);
}

}  // namespace

Vec3 gizmo_axis_world(const Anim3DRigModel& rig, const Pose& pose, int node, int axis) {
    const Vec3 unit = axis == 0 ? Vec3{1, 0, 0} : axis == 1 ? Vec3{0, 1, 0} : Vec3{0, 0, 1};
    return normalize(parent_global(rig, pose, node).rotate(unit));
}

Quat rotated_local(const Anim3DRigModel& rig, const Pose& pose, int node, int axis, double angle) {
    const Vec3 unit = axis == 0 ? Vec3{1, 0, 0} : axis == 1 ? Vec3{0, 1, 0} : Vec3{0, 0, 1};
    (void)rig;
    return normalize(Quat::axis_angle_deg(unit, float(angle * 180.0 / kPi)) * pose.rotation[std::size_t(node)]);
}

Vec3 bone_head(const Anim3DRigModel& rig, const Pose& pose, int node) {
    const PoseFrame f = pose_frame(*rig.skeleton, pose);
    return f.pos[std::size_t(node)];
}

Vec3 bone_tail(const Anim3DRigModel& rig, const Pose& pose, int node) {
    const PoseFrame f = pose_frame(*rig.skeleton, pose);
    const Rig3D& r = rig.rig;
    for (int c : r.bones)
        if (r.node(c).parent == node) return f.pos[std::size_t(c)];
    const float len = r.length[std::size_t(node)] > 0 ? r.length[std::size_t(node)] : 0.1f;
    Vec3 axis = r.axis[std::size_t(node)];
    if (length_sq(axis) < 1e-8f) axis = {0, 1, 0};
    return f.pos[std::size_t(node)] + f.rot[std::size_t(node)].rotate(axis) * len;
}

bool ring_angle(const ModelViewCamera& cam, double sx, double sy, Vec3 center, Vec3 axis, double& angle) {
    Vec3 hit;
    if (!plane_hit(cam, sx, sy, center, axis, hit)) return false;
    Vec3 u, v;
    plane_basis(axis, u, v);
    const Vec3 d = hit - center;
    angle = std::atan2(double(dot(d, v)), double(dot(d, u)));
    return true;
}

double angle_delta(double from, double to) {
    double d = to - from;
    while (d > kPi) d -= 2 * kPi;
    while (d < -kPi) d += 2 * kPi;
    return d;
}

bool plane_hit(const ModelViewCamera& cam, double sx, double sy, Vec3 point, Vec3 normal, Vec3& out) {
    Vec3 o, d;
    cam.ray(sx, sy, o, d);
    const Vec3 n = normalize(normal);
    const double denom = double(dot(n, d));
    if (std::fabs(denom) < 1e-6) return false;
    const double s = double(dot(n, point - o)) / denom;
    if (s < 0 && !cam.orthographic) return false;
    out = o + d * float(s);
    return true;
}

bool line_param(const ModelViewCamera& cam, double sx, double sy, Vec3 origin, Vec3 direction, double& s) {
    Vec3 o, d;
    cam.ray(sx, sy, o, d);
    const Vec3 l = normalize(direction);
    const Vec3 w = origin - o;
    const double a = double(dot(l, l)), b = double(dot(l, d)), c = double(dot(d, d));
    const double e = double(dot(l, w)), f = double(dot(d, w));
    const double den = a * c - b * b;
    if (std::fabs(den) < 1e-8) return false;
    s = (b * f - c * e) / den;
    return true;
}

double segment_distance(double px, double py, double ax, double ay, double bx, double by) {
    const double dx = bx - ax, dy = by - ay;
    const double len2 = dx * dx + dy * dy;
    double t = len2 > 1e-12 ? ((px - ax) * dx + (py - ay) * dy) / len2 : 0.0;
    t = std::clamp(t, 0.0, 1.0);
    const double cx = ax + dx * t - px, cy = ay + dy * t - py;
    return std::sqrt(cx * cx + cy * cy);
}

Vec3 ring_point(Vec3 center, Vec3 axis, double radius, double angle) {
    Vec3 u, v;
    plane_basis(axis, u, v);
    return center + u * float(std::cos(angle) * radius) + v * float(std::sin(angle) * radius);
}

Anim3DLimb limb_of(const Anim3DRigModel& rig, int endNode) {
    Anim3DLimb l;
    const Rig3D& r = rig.rig;
    if (!r.is_bone(endNode)) return l;
    const int mid = r.node(endNode).parent;
    if (mid < 0 || !r.is_bone(mid)) return l;
    const int root = r.node(mid).parent;
    if (root < 0 || !r.is_bone(root)) return l;
    l.root = root;
    l.mid = mid;
    l.end = endNode;
    return l;
}

Vec3 default_pole(const Anim3DRigModel& rig, const Pose& pose, const Anim3DLimb& limb) {
    const PoseFrame f = pose_frame(*rig.skeleton, pose);
    const Vec3 a = f.pos[std::size_t(limb.root)], b = f.pos[std::size_t(limb.mid)], c = f.pos[std::size_t(limb.end)];
    const Vec3 line = c - a;
    const float len2 = std::max(length_sq(line), 1e-8f);
    const Vec3 onLine = a + line * (dot(b - a, line) / len2);
    Vec3 bend = b - onLine;
    const float upper = length(b - a), lower = length(c - b);
    const float reach = std::max(std::min(upper, lower), 0.2f);
    if (length(bend) < 1e-3f) {
        // A straight limb: bend towards the character's front (+Z), else up.
        bend = std::fabs(normalize(line).z) < 0.9f ? Vec3{0, 0, 1} : Vec3{0, 1, 0};
        bend = bend - normalize(line) * dot(bend, normalize(line));
    }
    return b + normalize(bend) * reach;
}

namespace {
Json vec_json(Vec3 v) { return Json::array({double(v.x), double(v.y), double(v.z)}); }
}  // namespace

Json two_bone_solver(const Anim3DRigModel& rig, const Anim3DLimb& limb, Vec3 target, Vec3 pole) {
    return Json::object({{"type", "twoBone"},
                         {"root", rig.rig.node(limb.root).name},
                         {"mid", rig.rig.node(limb.mid).name},
                         {"end", rig.rig.node(limb.end).name},
                         {"target", vec_json(target)},
                         {"pole", vec_json(pole)}});
}

Json look_at_solver(const Anim3DRigModel& rig, int node, Vec3 target) {
    return Json::object({{"type", "lookAt"}, {"bone", rig.rig.node(node).name}, {"target", vec_json(target)}});
}

bool aims_like_a_head(const Anim3DRigModel& rig, int node) {
    if (node < 0 || node >= rig.rig.node_count()) return false;
    const std::string& role = rig.rig.node(node).role;
    return role == "head" || role == "neck" || role == "eye";
}

}  // namespace fa::editor
