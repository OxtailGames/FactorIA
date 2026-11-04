#include "validate_anim.h"

#include <map>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/components.h"
#include "fa/scene/ik3d.h"
#include "fa/scene/rig3d.h"
#include "fa/scene/skeleton.h"

namespace fa::validate_detail {

namespace {

void collect_pointers(const Json& entity, const std::string& pointer, std::map<std::string, std::string>& out) {
    if (!entity.is_object()) return;
    if (entity.contains("id") && entity["id"].is_string()) out.emplace(entity["id"].get<std::string>(), pointer);
    if (entity.contains("children") && entity["children"].is_array()) {
        int i = 0;
        for (const Json& c : entity["children"]) collect_pointers(c, pointer + "/children/" + std::to_string(i++), out);
    }
}

std::vector<std::string> project_clip_files() {
    std::vector<std::string> out;
    for (const std::string& f : fs::list(".", true, ".json")) {
        if (!ends_with(to_lower(f), ".anim.json")) continue;
        const std::vector<std::string> parts = split(f, '/');
        bool skip = false;
        for (std::size_t i = 0; i + 1 < parts.size(); ++i)
            if ((!parts[i].empty() && parts[i][0] == '.') || parts[i] == "node_modules" || (i == 0 && parts[i] == "build")) skip = true;
        if (!skip) out.push_back(f);
    }
    return out;
}

// The glTF an Animator plays: its `model`, else the mesh of the MeshRenderer on the same entity ("" when it has none).
std::string animator_model(const World& world, Entity e, const Animator& an) {
    if (!an.model.empty()) return an.model;
    if (const MeshRenderer* mr = world.get<MeshRenderer>(e)) {
        const std::string lower = to_lower(mr->mesh);
        if (ends_with(lower, ".glb") || ends_with(lower, ".gltf")) return mr->mesh;
    }
    return {};
}

// An Animator on a glTF: its `clips` are 3D bone clips (docs/ANIMATION.md, "3D bone clips"). Each file must exist, be a 3D clip and
// name bones the model has.
void check_bone_clips(const std::string& file, const World& world, Entity e, const Animator& an, const std::string& model, const Json&,
                      const std::map<std::string, std::string>& pointers, std::set<std::string>& named, const std::vector<std::string>& existing,
                      ValidationReport& report) {
    auto at = pointers.find(world.id_of(e));
    const std::string entityPointer = at == pointers.end() ? std::string() : at->second;
    const std::string who = "'" + world.id_of(e) + "'";
    std::shared_ptr<const SkeletonAsset> skeleton;
    if (fs::exists(model)) {
        auto sk = load_skeleton(model);
        if (sk.ok()) skeleton = *sk;
    }
    for (auto it = an.clips.begin(); it != an.clips.end(); ++it) {
        const std::string pointer = entityPointer.empty() ? std::string() : entityPointer + "/components/Animator/clips/" + it.key();
        if (!it.value().is_string() || it.value().get<std::string>().empty()) {
            report.errors.push_back({file, pointer, "Animator clip '" + it.key() + "' of " + who + " must be the path of a clip file, got " + describe_json_value(it.value()) + ".",
                                     "Example: \"" + it.key() + "\": \"anim/" + it.key() + ".anim.json\". anim3d.generate or anim3d.create makes one for a rig."});
            continue;
        }
        const std::string path = it.value().get<std::string>();
        named.insert(path);
        if (!fs::exists(path)) {
            report.errors.push_back({file, pointer, "Animator clip '" + it.key() + "' of " + who + " names '" + path + "', which does not exist. " + did_you_mean(path, existing),
                                     "Create it with anim3d.generate {rig, kind, out} or anim3d.create, or fix the path."});
            continue;
        }
        auto text = fs::read_text(path);
        if (!text.ok()) continue;
        auto json = parse_json(*text, path);
        if (!json.ok() || !is_anim3d_json(*json)) continue;  // reported on the clip file itself
        auto clip = load_anim3d(path);
        if (!clip.ok() || !skeleton) continue;
        const Rig3D rig = make_rig3d(*skeleton, 0);
        for (const ClipIssue& p : check_anim3d_rig(**clip, rig))
            report.errors.push_back({file, pointer, "Clip '" + it.key() + "' (" + path + ") on " + who + ": " + p.message, p.hint});
    }
}

}  // namespace

void check_animator_clips(const std::string& file, const World& world, const Json& source, std::set<std::string>& named, ValidationReport& report) {
    std::map<std::string, std::string> pointers;
    if (source.is_object()) {
        if (source.contains("entities") && source["entities"].is_array()) {
            int i = 0;
            for (const Json& e : source["entities"]) collect_pointers(e, "/entities/" + std::to_string(i++), pointers);
        }
        if (source.contains("entity")) collect_pointers(source["entity"], "/entity", pointers);
    }
    const TypeInfo* type = TypeRegistry::global().of<Animator>();
    const std::vector<std::string> existing = project_clip_files();
    for (Entity e : world.entities_with(type)) {
        const Animator* an = world.get<Animator>(e);
        if (!an || !an->clips.is_object() || an->clips.empty()) continue;
        if (const std::string model = animator_model(world, e, *an); !model.empty()) {
            check_bone_clips(file, world, e, *an, model, source, pointers, named, existing, report);
            continue;
        }
        if (const MeshRenderer* mr = world.get<MeshRenderer>(e); mr && !mr->mesh.empty()) continue;  // a model animates it
        auto at = pointers.find(world.id_of(e));
        const std::string entityPointer = at == pointers.end() ? std::string() : at->second;
        const std::string who = "'" + world.id_of(e) + "'";
        for (auto it = an->clips.begin(); it != an->clips.end(); ++it) {
            const std::string pointer = entityPointer.empty() ? std::string() : entityPointer + "/components/Animator/clips/" + it.key();
            if (!it.value().is_string() || it.value().get<std::string>().empty()) {
                report.errors.push_back({file, pointer, "Animator clip '" + it.key() + "' of " + who + " must be the path of a clip file, got " + describe_json_value(it.value()) + ".",
                                         "Example: \"" + it.key() + "\": \"anim/" + it.key() + ".anim.json\". anim.create_clip makes one."});
                continue;
            }
            const std::string path = it.value().get<std::string>();
            named.insert(path);
            if (!fs::exists(path)) {
                report.errors.push_back({file, pointer, "Animator clip '" + it.key() + "' of " + who + " names '" + path + "', which does not exist. " + did_you_mean(path, existing),
                                         "Create it with anim.create_clip {path, duration}, or fix the path."});
                continue;
            }
            auto clip = load_anim_clip(path);
            if (!clip.ok()) continue;  // reported on the clip file itself, with the pointer inside it
            std::vector<ClipIssue> problems = check_clip_paths(world, e, **clip);
            for (const ClipIssue& p : problems)
                report.errors.push_back({file, pointer, "Clip '" + it.key() + "' (" + path + ") on " + who + ": " + p.message, p.hint});
            for (const ClipTrack& tr : (*clip)->tracks) {
                auto part = resolve_clip_path(world, e, tr.path);
                if (part.ok() && tr.type && !world.get(*part, *tr.type))
                    report.errors.push_back({file, pointer,
                                             "Clip '" + it.key() + "' (" + path + ") on " + who + ": the part '" + (tr.path.empty() ? world.id_of(e) : tr.path) + "' has no " + tr.component +
                                                 " component, so the track " + tr.component + "." + tr.spelled + " drives nothing.",
                                             "Add the component to that part, or change the track's component."});
            }
        }
    }
}

void check_ik3d(const std::string& file, const World& world, const Json& source, ValidationReport& report) {
    std::map<std::string, std::string> pointers;
    if (source.is_object()) {
        if (source.contains("entities") && source["entities"].is_array()) {
            int i = 0;
            for (const Json& e : source["entities"]) collect_pointers(e, "/entities/" + std::to_string(i++), pointers);
        }
        if (source.contains("entity")) collect_pointers(source["entity"], "/entity", pointers);
    }
    for (Entity e : world.entities_with(TypeRegistry::global().of<IK3D>())) {
        const IK3D* ik = world.get<IK3D>(e);
        if (!ik) continue;
        auto at = pointers.find(world.id_of(e));
        const std::string base = (at == pointers.end() ? std::string() : at->second) + "/components/IK3D";
        const std::string who = "'" + world.id_of(e) + "'";
        const Animator* an = world.get<Animator>(e);
        const std::string model = an ? animator_model(world, e, *an) : std::string();
        if (!an || model.empty()) {
            report.errors.push_back({file, base, "IK3D on " + who + " needs an Animator on the same entity that plays a skinned model (a .rig.glb).",
                                     "Add an Animator and a MeshRenderer whose mesh is the rig.bake output, or remove the IK3D."});
            continue;
        }
        std::shared_ptr<const SkeletonAsset> skeleton;
        if (fs::exists(model)) {
            auto sk = load_skeleton(model);
            if (sk.ok()) skeleton = *sk;
        }
        const Rig3D rig = skeleton ? make_rig3d(*skeleton, 0) : Rig3D{};
        for (const IKIssue& i : ik3d_check_solvers(ik->solvers, skeleton ? &rig : nullptr))
            report.errors.push_back({file, base + "/solvers" + i.pointer, "IK3D on " + who + ": " + i.message, i.hint});
        if (ik->weight < 0.0f || ik->weight > 1.0f)
            report.errors.push_back({file, base + "/weight", "IK3D on " + who + ": weight is " + std::to_string(ik->weight) + ", expected 0..1.", "Use 0 for the animated pose and 1 for the solved one."});
    }
}

void check_clip_files(const std::set<std::string>& named, ValidationReport& report) {
    std::set<std::string> files(named.begin(), named.end());
    for (const std::string& f : project_clip_files()) files.insert(f);
    for (const std::string& f : files) {
        if (!fs::exists(f)) continue;  // an Animator names it: reported there
        auto text = fs::read_text(f);
        if (!text.ok()) { report.errors.push_back({f, "", text.error().message, text.error().hint}); continue; }
        auto json = parse_json(*text, f);
        if (!json.ok()) { report.errors.push_back({f, "", json.error().message, "Fix the JSON syntax of the clip."}); continue; }
        std::vector<ClipIssue> issues;
        std::string message, hint;
        bool ok = false;
        if (is_anim3d_json(*json)) {
            auto clip = parse_anim3d(*json, f, &issues);
            ok = clip.ok();
            if (!ok) { message = clip.error().message; hint = clip.error().hint; }
        } else {
            auto clip = parse_anim_clip(*json, f, &issues);
            ok = clip.ok();
            if (!ok) { message = clip.error().message; hint = clip.error().hint; }
        }
        if (ok) continue;
        if (issues.empty()) report.errors.push_back({f, "", message, hint});
        for (const ClipIssue& i : issues) report.errors.push_back({f, i.pointer, i.message, i.hint});
    }
}

}  // namespace fa::validate_detail
