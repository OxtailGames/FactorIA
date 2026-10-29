#include "validate_anim.h"

#include <map>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/components.h"

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
        if (!an || !an->clips.is_object() || an->clips.empty() || !an->model.empty()) continue;
        if (const MeshRenderer* mr = world.get<MeshRenderer>(e); mr && !mr->mesh.empty()) continue;  // a glTF animates it
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
        auto clip = parse_anim_clip(*json, f, &issues);
        if (clip.ok()) continue;
        if (issues.empty()) report.errors.push_back({f, "", clip.error().message, clip.error().hint});
        for (const ClipIssue& i : issues) report.errors.push_back({f, i.pointer, i.message, i.hint});
    }
}

}  // namespace fa::validate_detail
