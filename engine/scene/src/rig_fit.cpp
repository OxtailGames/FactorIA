// Fitting a rig template to a model (rig_fit.h): which model part is which bone, where each joint sits, where each number came from.
#include "fa/scene/rig_fit.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <optional>
#include <set>

#include "fa/core/strings.h"
#include "rig_templates.h"

namespace fa {

using namespace rig_detail;

const char* rig_source_name(RigSource s) {
    switch (s) {
        case RigSource::Override: return "override";
        case RigSource::Part: return "part";
        case RigSource::Geometry: return "geometry";
        case RigSource::Proportion: return "proportion";
    }
    return "";
}

int RigFit::find(std::string_view bone) const {
    for (std::size_t i = 0; i < bones.size(); ++i)
        if (bones[i].name == bone) return int(i);
    return -1;
}

namespace {

float axis_of(Vec3 v, int a) { return a == 0 ? v.x : a == 1 ? v.y : v.z; }
void set_axis(Vec3& v, int a, float f) { (a == 0 ? v.x : a == 1 ? v.y : v.z) = f; }

bool is_tail_name(const std::string& s) { return s.size() > 5 && s.compare(s.size() - 5, 5, ".tail") == 0; }
std::string bone_of(const std::string& landmark) {
    return is_tail_name(landmark) ? landmark.substr(0, landmark.size() - 5) : landmark;
}

RigSource weaker(RigSource a, RigSource b) { return int(a) > int(b) ? a : b; }

struct PartInfo {
    std::string name;
    std::vector<std::string> tokens;
    char side = 0;
    Vec3 bmin{1e30f, 1e30f, 1e30f}, bmax{-1e30f, -1e30f, -1e30f};
    std::size_t triangles = 0;
    int maxSpec = 0;
    bool straddlesRejected = false;
};

std::vector<PartInfo> gather_parts(const MeshData& mesh) {
    std::vector<PartInfo> parts;
    for (const MeshSubmesh& sm : mesh.submeshes) {
        if (sm.part.empty()) continue;
        PartInfo* p = nullptr;
        for (PartInfo& q : parts)
            if (q.name == sm.part) p = &q;
        if (!p) {
            parts.emplace_back();
            p = &parts.back();
            p->name = sm.part;
            p->tokens = name_tokens(sm.part, &p->side);
        }
        const std::uint32_t end = std::min<std::uint32_t>(std::uint32_t(mesh.indices.size()), sm.start + sm.count);
        for (std::uint32_t i = sm.start; i < end; ++i) {
            const std::uint32_t v = mesh.indices[i];
            if (std::size_t(v) * 3 + 2 >= mesh.positions.size()) continue;
            const Vec3 q{mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]};
            p->bmin = min(p->bmin, q);
            p->bmax = max(p->bmax, q);
        }
        p->triangles += (end > sm.start ? end - sm.start : 0) / 3;
    }
    parts.erase(std::remove_if(parts.begin(), parts.end(), [](const PartInfo& p) { return p.triangles == 0; }),
                parts.end());
    return parts;
}

// The height at which the model first fills the band around the symmetry plane, scanning up from the ground: the crotch of a biped, the belly of an
// animal standing on separate legs. nullopt when the model is solid down to the ground at the plane (no gap between legs) or the gap is not leg-sized.
std::optional<float> underside_height(const MeshData& mesh, float x0, float W, float ymin, float H) {
    constexpr int kSlices = 96;
    const float band = std::max(0.04f * W, 1e-4f);
    std::vector<char> covered(kSlices, 0);
    for (std::size_t t = 0; t + 2 < mesh.indices.size(); t += 3) {
        float lo_x = 1e30f, hi_x = -1e30f, lo_y = 1e30f, hi_y = -1e30f;
        bool ok = true;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = mesh.indices[t + k];
            if (std::size_t(v) * 3 + 2 >= mesh.positions.size()) {
                ok = false;
                break;
            }
            lo_x = std::min(lo_x, mesh.positions[v * 3]);
            hi_x = std::max(hi_x, mesh.positions[v * 3]);
            lo_y = std::min(lo_y, mesh.positions[v * 3 + 1]);
            hi_y = std::max(hi_y, mesh.positions[v * 3 + 1]);
        }
        if (!ok || hi_x < x0 - band || lo_x > x0 + band) continue;
        for (int s = 0; s < kSlices; ++s) {
            const float y = ymin + (float(s) + 0.5f) / float(kSlices) * H;
            if (y >= lo_y && y <= hi_y) covered[std::size_t(s)] = 1;
        }
    }
    if (covered[0]) return std::nullopt;
    int first = 0;
    while (first < kSlices && !covered[std::size_t(first)]) ++first;
    if (first >= kSlices) return std::nullopt;
    const float y = ymin + float(first) / float(kSlices) * H;
    const float gap = y - ymin;
    if (gap < 0.08f * H || gap > 0.7f * H) return std::nullopt;
    return y;
}

}  // namespace

std::vector<RigBoneInfo> rig_template_bones(const RigDoc& doc) {
    std::vector<TBone> bones = build_template(doc, false, false);
    std::vector<RigBoneInfo> out;
    std::set<std::string> parents;
    for (const TBone& b : bones) parents.insert(b.parent);
    for (const TBone& b : bones) {
        RigBoneInfo i;
        i.name = b.name;
        i.role = b.role;
        i.side = b.side;
        i.parent = b.parent;
        i.index = b.index;
        i.leaf = !parents.count(b.name);
        out.push_back(std::move(i));
    }
    return out;
}

std::vector<RigIssue> rig_check_doc(const RigDoc& doc) {
    std::vector<RigIssue> issues;
    const std::vector<RigBoneInfo> bones = rig_template_bones(doc);
    std::vector<std::string> names, landmarkNames;
    for (const RigBoneInfo& b : bones) {
        names.push_back(b.name);
        landmarkNames.push_back(b.name);
        if (b.leaf) landmarkNames.push_back(b.name + ".tail");
    }
    if (doc.templateName == "generic") {
        std::set<std::string> seen = {"root"};
        for (const RigGenericBone& g : doc.bones) {
            if (g.name == "root")
                issues.push_back({g.pointer + "/name",
                                  "'root' is the bone every rig has; a generic rig lists the others",
                                  "Name this bone something else (the root is added for you), or leave it out."});
            else if (!g.name.empty() && !seen.insert(g.name).second)
                issues.push_back(
                    {g.pointer + "/name", "two bones are called '" + g.name + "'", "Give every bone its own name."});
            if (!g.parent.empty() && g.parent != "root" &&
                !std::any_of(doc.bones.begin(), doc.bones.end(),
                             [&](const RigGenericBone& o) { return &o != &g && o.name == g.parent; }))
                issues.push_back({g.pointer + "/parent",
                                  "bone '" + g.name + "' hangs from '" + g.parent + "', which is not a bone of the rig",
                                  did_you_mean(g.parent, names)});
            else if (!g.parent.empty() && g.parent != "root") {
                const auto at = std::find_if(doc.bones.begin(), doc.bones.end(),
                                             [&](const RigGenericBone& o) { return o.name == g.parent; });
                if (at != doc.bones.end() && at >= doc.bones.begin() + (&g - doc.bones.data()))
                    issues.push_back({g.pointer + "/parent",
                                      "bone '" + g.name + "' hangs from '" + g.parent + "', which is listed after it",
                                      "List parents before their children."});
            }
        }
    }
    if (bones.size() > kRigMaxBones)
        issues.push_back({"",
                          std::format("the rig has {} bones; a skin may have at most {}", bones.size(), kRigMaxBones),
                          "Lower the spine, neck or tail options, or list fewer bones."});
    for (std::size_t i = 0; i < doc.parts.size(); ++i)
        if (std::find(names.begin(), names.end(), doc.parts[i].first) == names.end())
            issues.push_back({"/parts/" + doc.parts[i].first,
                              "'" + doc.parts[i].first + "' is not a bone of the " + doc.templateName + " rig",
                              did_you_mean(doc.parts[i].first, names)});
    for (const auto& [name, v] : doc.landmarks) {
        (void)v;
        if (std::find(landmarkNames.begin(), landmarkNames.end(), name) != landmarkNames.end()) continue;
        std::string hint;
        if (is_tail_name(name) && std::find(names.begin(), names.end(), bone_of(name)) != names.end())
            hint = "Only a bone with no children has a tail landmark (the others end where their child begins): move "
                   "the joint of the child instead.";
        else
            hint = did_you_mean(name, landmarkNames);
        issues.push_back(
            {"/landmarks/" + name, "'" + name + "' is not a landmark of the " + doc.templateName + " rig", hint});
    }
    const std::vector<RigIssue> skinIssues = rig_check_skin(doc, names);
    issues.insert(issues.end(), skinIssues.begin(), skinIssues.end());
    return issues;
}

namespace {

struct Frame {
    Vec3 bmin, bmax;
    float x0 = 0, W = 1, H = 1, D = 1;
    Vec3 at(Vec3 p) const { return {x0 + p.x * W, bmin.y + p.y * H, bmin.z + p.z * D}; }
};

// Is the part `p` a candidate for a bone on `side`? straddle is set when it was rejected only because it covers both sides.
bool side_compatible(char side, const PartInfo& p, const Frame& f, bool& straddle) {
    if (side == 0) return p.side == 0;
    if (p.side) return p.side == side;
    const float cx = (p.bmin.x + p.bmax.x) * 0.5f - f.x0;
    if (p.bmin.x < f.x0 - 0.08f * f.W && p.bmax.x > f.x0 + 0.08f * f.W) {
        straddle = true;
        return false;
    }
    return side == 'l' ? cx > 0.02f * f.W : cx < -0.02f * f.W;
}

bool tokens_match(const Hint& h, const PartInfo& p) {
    if (!h.exact.empty()) return p.name == h.exact;
    if (h.words.empty()) return false;
    for (const std::string& w : h.words)
        if (std::find(p.tokens.begin(), p.tokens.end(), w) == p.tokens.end()) return false;
    return true;
}
int spec_of(const Hint& h) { return h.exact.empty() ? int(h.words.size()) : 100; }

// Where a hint puts a landmark, given the union bounds of its parts. `along` is head or tail of the hint; `ref` the point that says which end is near.
Vec3 place(const Hint& h, Vec3 lo, Vec3 hi, float along, bool isTail, Vec3 ref) {
    const Vec3 c = (lo + hi) * 0.5f;
    switch (h.mode) {
        case 'X':
        case 'Y':
        case 'Z': {
            const int a = h.mode == 'X' ? 0 : h.mode == 'Y' ? 1 : 2;
            Vec3 p = c;
            set_axis(p, a, axis_of(lo, a) + (axis_of(hi, a) - axis_of(lo, a)) * along);
            return p;
        }
        case 'A': {
            const Vec3 a = isTail ? h.aTail : h.aHead;
            const Vec3 half = (hi - lo) * 0.5f;
            return c + Vec3{a.x * half.x, a.y * half.y, a.z * half.z};
        }
        default: {  // 'L'
            const Vec3 ext = hi - lo;
            int a = 1;
            if (ext.z > ext.y + 1e-4f) a = 2;
            if (ext.x > axis_of(ext, a) + 1e-4f) a = 0;
            Vec3 e0 = c, e1 = c;
            set_axis(e0, a, axis_of(lo, a));
            set_axis(e1, a, axis_of(hi, a));
            const bool near0 = length_sq(e0 - ref) <= length_sq(e1 - ref);
            const Vec3 prox = near0 ? e0 : e1, dist = near0 ? e1 : e0;
            return prox + (dist - prox) * along;
        }
    }
}

struct Work {
    TBone t;
    std::vector<std::vector<int>> hintParts;  // per hint: the model parts it can use
    std::vector<int> parts;                   // every part the bone is bound to
    bool leaf = true;
    int parentIdx = -1;
    int mainChild = -1;
    Vec3 defHead{}, defTail{};
    bool defTailKnown = false;
    Vec3 head{}, tail{};
    RigSource headSource = RigSource::Proportion, tailSource = RigSource::Proportion;
    bool headDone = false, tailDone = false;
};

}  // namespace

Result<RigFit> fit_rig(const RigDoc& doc, const MeshData& mesh) {
    {
        const std::vector<RigIssue> issues = rig_check_doc(doc);
        if (!issues.empty()) {
            std::string message = (issues[0].pointer.empty() ? "" : issues[0].pointer + ": ") + issues[0].message;
            if (issues.size() > 1)
                message += std::format(" (and {} more problem{})", issues.size() - 1, issues.size() == 2 ? "" : "s");
            return make_error(message, issues[0].hint);
        }
    }
    if (mesh.positions.size() < 9)
        return make_error("the model has no geometry to fit a rig to",
                          "Check the model document: `model.bake` must produce a mesh with triangles.");
    Frame f;
    f.bmin = Vec3{1e30f, 1e30f, 1e30f};
    f.bmax = Vec3{-1e30f, -1e30f, -1e30f};
    for (std::size_t i = 0; i + 2 < mesh.positions.size(); i += 3) {
        const Vec3 q{mesh.positions[i], mesh.positions[i + 1], mesh.positions[i + 2]};
        f.bmin = min(f.bmin, q);
        f.bmax = max(f.bmax, q);
    }
    if (f.bmax.y - f.bmin.y < 1e-5f)
        return make_error("the model has no height (all its points are at y = " + std::format("{:.4g}", f.bmin.y) + ")",
                          "A rig expects a model standing on +Y. Check the model's rotation, or use the generic "
                          "template with landmarks.");
    f.W = std::max(f.bmax.x - f.bmin.x, 1e-4f);
    f.H = f.bmax.y - f.bmin.y;
    f.D = std::max(f.bmax.z - f.bmin.z, 1e-4f);
    f.x0 = doc.symmetryX ? *doc.symmetryX : (f.bmin.x + f.bmax.x) * 0.5f;

    RigFit fit;
    fit.templateName = doc.templateName;
    fit.bmin = f.bmin;
    fit.bmax = f.bmax;
    fit.symmetryX = f.x0;
    fit.symmetrySource = doc.symmetryX ? "document" : "bounds";

    std::vector<PartInfo> parts = gather_parts(mesh);
    std::vector<std::string> partNames;
    for (const PartInfo& p : parts) partNames.push_back(p.name);
    auto find_part = [&](const std::string& name) -> int {
        for (std::size_t i = 0; i < parts.size(); ++i)
            if (parts[i].name == name) return int(i);
        return -1;
    };

    const bool armsOut =
        doc.optionString("pose", "auto") == "out" || (doc.optionString("pose", "auto") == "auto" && f.W / f.H > 0.75f);
    const bool wingsSpread =
        doc.optionString("pose", "auto") == "spread" || (doc.optionString("pose", "auto") == "auto" && f.W > f.D);
    std::vector<std::string> warnings;
    std::vector<TBone> tbones = build_template(doc, armsOut, wingsSpread);
    if (tbones.size() > kRigMaxBones)
        return make_error(std::format("the rig has {} bones; a skin may have at most {}", tbones.size(), kRigMaxBones),
                          "Lower the spine, neck or tail options.");

    std::vector<Work> W(tbones.size());
    std::map<std::string, int> indexOf;
    for (std::size_t i = 0; i < tbones.size(); ++i) {
        W[i].t = tbones[i];
        indexOf[tbones[i].name] = int(i);
    }
    for (std::size_t i = 0; i < W.size(); ++i) {
        if (!W[i].t.parent.empty()) {
            auto it = indexOf.find(W[i].t.parent);
            if (it == indexOf.end() || it->second >= int(i))
                return make_error("internal: template bone '" + W[i].t.name +
                                      "' has a parent that is not listed before it",
                                  "Report this as an engine bug.");
            W[i].parentIdx = it->second;
            W[std::size_t(it->second)].leaf = false;
            if (W[std::size_t(it->second)].mainChild < 0) W[std::size_t(it->second)].mainChild = int(i);
        }
    }

    // ---- chains: the region the bones are spread over
    if (doc.templateName == "tail" || doc.templateName == "chain") {
        std::vector<int> region;
        for (std::size_t i = 0; i < parts.size(); ++i) {
            bool any = false;
            for (const Hint& h : W[1].t.hints) any = any || tokens_match(h, parts[i]);
            if (any && parts[i].side == 0) region.push_back(int(i));
        }
        for (const auto& [bone, names] : doc.parts)
            if (bone == W[1].t.name) {
                region.clear();
                for (const std::string& n : names) {
                    const int p = find_part(n);
                    if (p < 0)
                        return make_error(
                            "/parts/" + bone + ": the model has no part '" + n + "'",
                            partNames.empty()
                                ? "The model has no named parts: name the nodes of the model document with `part`."
                                : did_you_mean(n, partNames));
                    region.push_back(p);
                }
            }
        Vec3 lo = f.bmin, hi = f.bmax;
        if (!region.empty()) {
            lo = Vec3{1e30f, 1e30f, 1e30f};
            hi = Vec3{-1e30f, -1e30f, -1e30f};
            for (int p : region) {
                lo = min(lo, parts[std::size_t(p)].bmin);
                hi = max(hi, parts[std::size_t(p)].bmax);
            }
        }
        const std::string axis = doc.optionString("axis", doc.templateName == "tail" ? "-z" : "-y");
        const int a = axis[1] == 'x' ? 0 : axis[1] == 'y' ? 1 : 2;
        const bool negative = axis[0] == '-';
        const float length = axis_of(hi, a) - axis_of(lo, a);
        if (length < 1e-4f)
            return make_error("the " + doc.templateName + " has no length along " + axis,
                              "Choose the axis the model is longest along (`options.axis`), or give landmarks.");
        Vec3 base = (lo + hi) * 0.5f, dir{0, 0, 0};
        set_axis(base, a, negative ? axis_of(hi, a) : axis_of(lo, a));
        set_axis(dir, a, negative ? -1.0f : 1.0f);
        Vec3 ext = hi - lo;
        for (int k = 0; k < 3; ++k)
            if (k != a && axis_of(ext, k) > length * 1.01f) {
                warnings.push_back(std::format("the model is longer along {} than along {}: the chain follows {}. Set "
                                               "options.axis to \"{}\" if it should follow that.",
                                               "xyz"[k], axis, axis,
                                               std::string(axis_of(ext, k) > 0 ? "+" : "-") + "xyz"[k]));
                break;
            }
        const RigSource src = region.empty() ? RigSource::Geometry : RigSource::Part;
        const int n = int(W.size()) - 1;
        std::vector<std::string> regionNames;
        for (int p : region) regionNames.push_back(parts[std::size_t(p)].name);
        W[0].t.hasAbs = true;
        W[0].t.absHead = base;
        W[0].t.absSource = src;
        for (int k = 1; k <= n; ++k) {
            TBone& b = W[std::size_t(k)].t;
            b.hasAbs = true;
            b.absHead = base + dir * (length * float(k - 1) / float(n));
            b.absSource = src;
        }
        W.back().t.hasAbsTail = true;
        W.back().t.absTail = base + dir * length;
        W.back().t.absTailSource = src;
        for (Work& w : W) {
            w.t.hints.clear();  // placed by the region, not by hints
            w.parts = region;
        }
    }

    // ---- generic: root at the bottom centre, each bone's part must exist
    if (doc.templateName == "generic") {
        W[0].t.hasAbs = true;
        W[0].t.absHead = Vec3{f.x0, f.bmin.y, (f.bmin.z + f.bmax.z) * 0.5f};
        W[0].t.absSource = RigSource::Geometry;
        for (std::size_t i = 1; i < W.size(); ++i)
            for (const Hint& h : W[i].t.hints)
                if (find_part(h.exact) < 0)
                    return make_error(std::format("/bones/{}/part: the model has no part '{}'", i - 1, h.exact),
                                      partNames.empty() ? "The model has no named parts: give the nodes of the model "
                                                          "document a `part` (model.info lists them)."
                                                        : did_you_mean(h.exact, partNames));
    }

    // ---- which parts are which bone
    for (PartInfo& p : parts) {
        for (const Work& w : W)
            for (const Hint& h : w.t.hints) {
                if (!tokens_match(h, p)) continue;
                bool straddle = false;
                if (h.exact.empty() && !side_compatible(w.t.side.empty() ? char(0) : w.t.side[0], p, f, straddle)) {
                    if (straddle) p.straddlesRejected = true;
                    continue;
                }
                p.maxSpec = std::max(p.maxSpec, spec_of(h));
            }
    }
    for (Work& w : W) {
        w.hintParts.assign(w.t.hints.size(), {});
        std::set<int> all(w.parts.begin(), w.parts.end());
        for (std::size_t hi = 0; hi < w.t.hints.size(); ++hi) {
            const Hint& h = w.t.hints[hi];
            for (std::size_t pi = 0; pi < parts.size(); ++pi) {
                const PartInfo& p = parts[pi];
                if (!tokens_match(h, p) || spec_of(h) != p.maxSpec) continue;
                bool straddle = false;
                if (h.exact.empty() && !side_compatible(w.t.side.empty() ? char(0) : w.t.side[0], p, f, straddle))
                    continue;
                w.hintParts[hi].push_back(int(pi));
                all.insert(int(pi));
            }
        }
        w.parts.assign(all.begin(), all.end());
    }
    for (const auto& [bone, names] : doc.parts) {  // explicit parts replace what the names said
        if (doc.templateName == "tail" || doc.templateName == "chain") break;
        Work& w = W[std::size_t(indexOf[bone])];
        std::vector<int> forced;
        for (const std::string& n : names) {
            const int p = find_part(n);
            if (p < 0)
                return make_error("/parts/" + bone + ": the model has no part '" + n + "'",
                                  partNames.empty() ? "The model has no named parts: give the nodes of the model "
                                                      "document a `part` (model.info lists them), or use `landmarks`."
                                                    : did_you_mean(n, partNames));
            forced.push_back(p);
        }
        if (w.t.hints.empty()) {
            Hint h;
            h.mode = 'L';
            h.head = 0;
            h.tail = 1;
            w.t.hints.push_back(h);
        }
        w.hintParts.assign(w.t.hints.size(), forced);
        w.parts = forced;
        std::sort(w.parts.begin(), w.parts.end());
    }
    // a bone with no part of its own that sits between two others follows what they share
    for (Work& w : W) {
        if (!w.parts.empty() || w.t.lerpA.empty()) continue;
        const Work& a = W[std::size_t(indexOf[bone_of(w.t.lerpA)])];
        const Work& b = W[std::size_t(indexOf[bone_of(w.t.lerpB)])];
        std::vector<int> both;
        std::set_intersection(a.parts.begin(), a.parts.end(), b.parts.begin(), b.parts.end(), std::back_inserter(both));
        w.parts = both.empty() ? a.parts : both;
    }

    // ---- default (proportion) positions, the reference of the limb hints
    for (Work& w : W) {
        w.defHead = w.t.hasAbs ? w.t.absHead : f.at(w.t.prop);
    }
    auto resolve_def = [&](const std::string& landmark) -> Vec3 {
        const Work& o = W[std::size_t(indexOf[bone_of(landmark)])];
        if (is_tail_name(landmark)) return o.t.hasTailProp ? f.at(o.t.tailProp) : o.defHead;
        return o.defHead;
    };
    for (Work& w : W)
        if (!w.t.lerpA.empty()) w.defHead = lerp(resolve_def(w.t.lerpA), resolve_def(w.t.lerpB), w.t.lerpT);

    // ---- overrides
    std::map<std::string, Vec3> overrides;
    for (const auto& [name, v] : doc.landmarks) overrides[name] = v;

    auto union_bounds = [&](const std::vector<int>& ids, Vec3& lo, Vec3& hi) {
        lo = Vec3{1e30f, 1e30f, 1e30f};
        hi = Vec3{-1e30f, -1e30f, -1e30f};
        for (int p : ids) {
            lo = min(lo, parts[std::size_t(p)].bmin);
            hi = max(hi, parts[std::size_t(p)].bmax);
        }
    };
    auto part_placement = [&](const Work& w, bool tail, Vec3& out, std::vector<int>* used) -> bool {
        for (std::size_t hi = 0; hi < w.t.hints.size(); ++hi) {
            const Hint& h = w.t.hints[hi];
            const float along = tail ? h.tail : h.head;
            if (!has(along) || w.hintParts[hi].empty()) continue;
            Vec3 lo, hi3;
            union_bounds(w.hintParts[hi], lo, hi3);
            Vec3 ref = w.defHead;
            if (!h.ref.empty()) ref = W[std::size_t(indexOf[h.ref])].defHead;
            out = place(h, lo, hi3, along, tail, ref);
            if (used) *used = w.hintParts[hi];
            return true;
        }
        return false;
    };

    const std::optional<float> under = underside_height(mesh, f.x0, f.W, f.bmin.y, f.H);

    // tails that do not depend on heads
    for (Work& w : W) {
        if (!w.leaf) continue;
        const std::string key = w.t.name + ".tail";
        Vec3 p;
        if (auto o = overrides.find(key); o != overrides.end()) {
            w.tail = o->second;
            w.tailSource = RigSource::Override;
            w.tailDone = true;
        } else if (w.t.hasAbsTail) {
            w.tail = w.t.absTail;
            w.tailSource = w.t.absTailSource;
            w.tailDone = true;
        } else if (part_placement(w, true, p, nullptr)) {
            w.tail = p;
            w.tailSource = RigSource::Part;
            w.tailDone = true;
        } else if (w.t.hasTailProp) {
            Vec3 q = f.at(w.t.tailProp);
            bool geo = false;
            for (int a = 0; a < 3; ++a) {
                const float e = axis_of(w.t.tailExt, a);
                if (e != 0) {
                    set_axis(q, a, e > 0 ? axis_of(f.bmax, a) : axis_of(f.bmin, a));
                    geo = true;
                }
            }
            w.tail = q;
            w.tailSource = geo ? RigSource::Geometry : RigSource::Proportion;
            w.tailDone = true;
        }
    }
    auto landmark_pos = [&](const std::string& landmark, Vec3& pos, RigSource& src) -> bool {
        const Work& o = W[std::size_t(indexOf[bone_of(landmark)])];
        if (is_tail_name(landmark)) {
            if (!o.tailDone) return false;
            pos = o.tail;
            src = o.tailSource;
            return true;
        }
        if (!o.headDone) return false;
        pos = o.head;
        src = o.headSource;
        return true;
    };
    // heads: first the ones that stand alone, then the ones between two others
    for (int pass = 0; pass < 2; ++pass)
        for (Work& w : W) {
            if (w.headDone || (pass == 0) != w.t.lerpA.empty()) continue;
            Vec3 p;
            if (auto o = overrides.find(w.t.name); o != overrides.end()) {
                w.head = o->second;
                w.headSource = RigSource::Override;
            } else if (part_placement(w, false, p, nullptr)) {
                w.head = p;
                w.headSource = RigSource::Part;
            } else if (!w.t.lerpA.empty()) {
                Vec3 a, b;
                RigSource sa, sb;
                if (!landmark_pos(w.t.lerpA, a, sa) || !landmark_pos(w.t.lerpB, b, sb))
                    return make_error("internal: bone '" + w.t.name +
                                          "' lies between landmarks that are not placed yet",
                                      "Report this as an engine bug.");
                w.head = lerp(a, b, w.t.lerpT);
                w.headSource = weaker(sa, sb);
            } else if (w.t.hasAbs) {
                w.head = w.t.absHead;
                w.headSource = w.t.absSource;
            } else if (w.t.under && under) {
                w.head = f.at(w.t.prop);
                w.head.y = *under + w.t.underOffset * f.H;
                w.headSource = RigSource::Geometry;
            } else {
                w.head = f.at(w.t.prop);
                w.headSource = RigSource::Proportion;
            }
            w.headDone = true;
        }
    // tails of the rest: a bone ends where its main child begins; a leaf with nothing else says extends the parent's direction
    for (Work& w : W) {
        if (w.tailDone) continue;
        if (!w.leaf) {
            const Work& c = W[std::size_t(w.mainChild)];
            w.tail = c.head;
            w.tailSource = c.headSource;
        } else {
            Vec3 d{0, f.H * 0.05f, 0};
            if (w.parentIdx >= 0) {
                const Vec3 pd = w.head - W[std::size_t(w.parentIdx)].head;
                if (length(pd) > 1e-5f) d = normalize(pd) * (0.5f * length(pd));
            }
            w.tail = w.head + d;
            w.tailSource = RigSource::Proportion;
        }
        w.tailDone = true;
    }

    // ---- the result
    for (std::size_t i = 0; i < W.size(); ++i) {
        const Work& w = W[i];
        RigBoneFit b;
        b.name = w.t.name;
        b.role = w.t.role;
        b.index = w.t.index;
        b.side = w.t.side;
        b.parent = w.t.parent;
        b.parentIndex = w.parentIdx;
        b.head = w.head;
        b.tail = w.tail;
        b.leaf = w.leaf;
        b.headSource = w.headSource;
        b.tailSource = w.tailSource;
        for (int p : w.parts) b.parts.push_back(parts[std::size_t(p)].name);
        fit.bones.push_back(std::move(b));
    }
    std::set<std::string> usedParts;
    for (const RigBoneFit& b : fit.bones) usedParts.insert(b.parts.begin(), b.parts.end());
    std::vector<std::string> estimatedNames;
    auto tally = [&](RigSource s, const std::string& name) {
        switch (s) {
            case RigSource::Override: ++fit.overrides; break;
            case RigSource::Part: ++fit.fromParts; break;
            case RigSource::Geometry: ++fit.fromGeometry; break;
            case RigSource::Proportion:
                ++fit.estimated;
                estimatedNames.push_back(name);
                break;
        }
    };
    for (const RigBoneFit& b : fit.bones) {
        tally(b.headSource, b.name);
        if (b.leaf) tally(b.tailSource, b.name + ".tail");
    }
    for (const PartInfo& p : parts)
        if (!usedParts.count(p.name)) fit.unusedParts.push_back(p.name);

    // ---- what the fit noticed
    if (parts.empty() && doc.templateName != "tail" && doc.templateName != "chain")
        warnings.push_back("The model has no named parts, so the joints come from the model's bounds and the "
                           "template's proportions. Name the nodes of the model document with `part` "
                           "(\"head\", \"torso\", \"arm_l\"...) or give `landmarks` to put them where they belong.");
    for (const PartInfo& p : parts)
        if (p.straddlesRejected && !usedParts.count(p.name))
            warnings.push_back("Part '" + p.name +
                               "' covers both sides of the symmetry plane, so it was not used for a left or right "
                               "bone. Split it into two parts named with _l and _r, "
                               "or put the joints with `landmarks`.");
    for (const PartInfo& p : parts)
        if (p.side && usedParts.count(p.name)) {
            const float cx = (p.bmin.x + p.bmax.x) * 0.5f - f.x0;
            if ((p.side == 'l' && cx < -0.05f * f.W) || (p.side == 'r' && cx > 0.05f * f.W))
                warnings.push_back("Part '" + p.name + "' is named for the " + (p.side == 'l' ? "left" : "right") +
                                   " but sits on the " + (cx < 0 ? "-X" : "+X") +
                                   " side: character-left is +X (the character looks towards +Z). The name wins; "
                                   "rename the part or the model if this is a mistake.");
        }
    for (const std::string& name : fit.unusedParts)
        if (std::find_if(warnings.begin(), warnings.end(), [&](const std::string& w) {
                return w.find("Part '" + name + "' covers") == 0;
            }) == warnings.end())
            warnings.push_back(
                "Part '" + name + "' matched no bone of the " + doc.templateName +
                " template. If it should move with one, name it in `parts` (for example {\"<bone>\": [\"" + name +
                "\"]}); `rig.templates {name: \"" + doc.templateName + "\"}` lists the words it recognises.");
    if (fit.estimated > 0 && !parts.empty()) {
        std::vector<std::string> first(estimatedNames.begin(),
                                       estimatedNames.begin() + std::min<std::size_t>(estimatedNames.size(), 8));
        warnings.push_back(std::format("{} landmark{} estimated from the template's proportions: {}{}. Name the parts "
                                       "that hold them or give `landmarks` to be sure.",
                                       fit.estimated, fit.estimated == 1 ? " was" : "s were", join(first, ", "),
                                       estimatedNames.size() > first.size() ? ", ..." : ""));
    }
    {
        const Vec3 pad{0.15f * f.W, 0.15f * f.H, 0.15f * f.D};
        std::vector<std::string> outside;
        for (const RigBoneFit& b : fit.bones) {
            const Vec3 p = b.head;
            if (p.x < f.bmin.x - pad.x || p.x > f.bmax.x + pad.x || p.y < f.bmin.y - pad.y || p.y > f.bmax.y + pad.y ||
                p.z < f.bmin.z - pad.z || p.z > f.bmax.z + pad.z)
                outside.push_back(b.name);
        }
        if (!outside.empty())
            warnings.push_back("Joint" + std::string(outside.size() == 1 ? " " : "s ") + join(outside, ", ") + " lie" +
                               (outside.size() == 1 ? "s" : "") +
                               " well outside the model's bounds: check the `landmarks` (they are in the model's space "
                               "after its gameReady origin) and the symmetryX.");
    }
    fit.warnings = std::move(warnings);

    if (doc.strict && fit.estimated > 0) {
        std::vector<std::string> first(estimatedNames.begin(),
                                       estimatedNames.begin() + std::min<std::size_t>(estimatedNames.size(), 10));
        return make_error(
            std::format("the rig is strict and {} landmark{} could only be estimated from proportions: {}{}",
                        fit.estimated, fit.estimated == 1 ? "" : "s", join(first, ", "),
                        estimatedNames.size() > first.size() ? ", ..." : ""),
            "Name the model parts that hold them (`rig.templates {name: \"" + doc.templateName +
                "\"}` lists the words each bone looks for), map parts with `parts`, "
                "or place the joints with `landmarks`; or set strict to false.");
    }
    return fit;
}

Json rig_fit_to_json(const RigFit& fit) {
    Json bones = Json::array();
    for (const RigBoneFit& b : fit.bones) {
        Json o = Json::object({{"name", b.name}, {"role", b.role}});
        if (b.index) o["index"] = b.index;
        if (!b.side.empty()) o["side"] = b.side;
        if (!b.parent.empty()) o["parent"] = b.parent;
        o["head"] = to_json(b.head);
        o["tail"] = to_json(b.tail);
        o["headSource"] = rig_source_name(b.headSource);
        if (b.leaf) o["tailSource"] = rig_source_name(b.tailSource);
        if (!b.parts.empty()) o["parts"] = b.parts;
        bones.push_back(o);
    }
    Json j = Json::object({{"template", fit.templateName},
                           {"bones", bones},
                           {"boneCount", fit.bones.size()},
                           {"bounds", Json::object({{"min", to_json(fit.bmin)}, {"max", to_json(fit.bmax)}})},
                           {"symmetryX", to_json(fit.symmetryX)},
                           {"symmetrySource", fit.symmetrySource},
                           {"landmarks", Json::object({{"override", fit.overrides},
                                                       {"part", fit.fromParts},
                                                       {"geometry", fit.fromGeometry},
                                                       {"estimated", fit.estimated}})},
                           {"unusedParts", fit.unusedParts},
                           {"warnings", fit.warnings}});
    return j;
}

std::vector<std::uint16_t> rig_rigid_binding(const RigFit& fit, const MeshData& mesh) {
    const std::size_t n = mesh.vertex_count();
    std::vector<std::uint16_t> out(n, 0);
    std::vector<const std::string*> partOf(n, nullptr);
    for (const MeshSubmesh& sm : mesh.submeshes) {
        const std::uint32_t end = std::min<std::uint32_t>(std::uint32_t(mesh.indices.size()), sm.start + sm.count);
        for (std::uint32_t i = sm.start; i < end; ++i) {
            const std::uint32_t v = mesh.indices[i];
            if (v < n && !partOf[v]) partOf[v] = &sm.part;
        }
    }
    std::map<std::string, std::vector<int>> candidates;
    for (std::size_t b = 0; b < fit.bones.size(); ++b)
        for (const std::string& p : fit.bones[b].parts) candidates[p].push_back(int(b));
    std::vector<int> everyone;
    for (std::size_t b = 0; b < fit.bones.size(); ++b) everyone.push_back(int(b));
    for (std::size_t v = 0; v < n; ++v) {
        const std::vector<int>* list = &everyone;
        if (partOf[v]) {
            auto it = candidates.find(*partOf[v]);
            if (it != candidates.end()) list = &it->second;
        }
        const Vec3 p{mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]};
        float best = 1e30f;
        int bestBone = 0;
        for (int b : *list) {
            const RigBoneFit& bone = fit.bones[std::size_t(b)];
            const Vec3 seg = bone.tail - bone.head;
            const float len2 = length_sq(seg);
            float t = len2 > 1e-12f ? dot(p - bone.head, seg) / len2 : 0.0f;
            t = clamp(t, 0.0f, 1.0f);
            const float d = length_sq(p - (bone.head + seg * t));
            if (d < best) {
                best = d;
                bestBone = b;
            }
        }
        out[v] = std::uint16_t(bestBone);
    }
    return out;
}

}  // namespace fa
