// assets.regenerate: makes a made asset again from the recipe its provenance records (assets_recipe.cpp), through the command
// registry, so any command that writes `provenance.recipe` works with no list of commands here.
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr const char* kCommand = "assets.regenerate";

// One command call that makes one or more assets (assets.draw_icon makes the icon and its Android foreground; a texture its
// normal map; assets.draw_capsules a file per store size): the assets with the same command and arguments are one group.
struct Group {
    std::string command;
    Json args;                          // the recipe's args
    Json recipe;                        // the first output's recipe (inputs are the same for all)
    std::vector<std::string> outputs;   // asset paths, in the order of assets.json
    std::vector<std::string> deps;      // outputs of other groups that this group reads
};

// What a file was before the run: enough to say what changed after it.
struct Snapshot {
    bool exists = false;
    std::uint64_t bytes = 0;
    std::string sha;
    std::optional<Image> image;  // png/jpg/... outputs, to compare pixels
    Json sheet;
    Json provenance;
};

Snapshot snapshot(const std::string& projectDir, const std::string& rel, const Json& entry) {
    Snapshot s;
    const stdfs::path file = stdfs::path(projectDir) / rel;
    std::error_code ec;
    s.exists = stdfs::is_regular_file(file, ec);
    if (entry.is_object()) {
        s.sheet = entry.value("sheet", Json());
        s.provenance = entry.value("provenance", Json());
    }
    if (!s.exists) return s;
    s.bytes = stdfs::file_size(file, ec);
    if (auto h = sha256_file_hex(file); h.ok()) s.sha = *h;
    if (assets::kind_of(rel) == assets::AssetKind::Texture) {
        auto img = load_image(file);
        if (img.ok()) s.image = std::move(*img);
    }
    return s;
}

Json manifest_entry(const std::string& projectDir, const std::string& rel) {
    auto text = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile);
    if (!text) return Json::object();
    auto parsed = parse_json(*text, assets::kManifestFile);
    if (!parsed.ok() || !parsed->is_object() || !parsed->contains("assets") || !(*parsed)["assets"].is_object()) return Json::object();
    auto it = (*parsed)["assets"].find(rel);
    return it == (*parsed)["assets"].end() ? Json::object() : *it;
}

// How `now` differs from `before`: one of "created", "unchanged", "pixels changed", "bytes changed (same pixels)".
Json describe_change(const Snapshot& before, const Snapshot& after, const Json& afterEntry) {
    Json out = Json::object();
    std::string summary;
    if (!after.exists) summary = "missing";
    else if (!before.exists) summary = "created";
    else if (before.sha == after.sha) summary = "unchanged";
    else if (before.image && after.image) summary = before.image->width == after.image->width && before.image->height == after.image->height &&
                                                             before.image->rgba == after.image->rgba
                                                         ? "bytes changed (same pixels)"
                                                         : "pixels changed";
    else summary = "bytes changed";
    out["result"] = summary;
    out["changed"] = summary != "unchanged";
    out["bytes"] = Json::object({{"before", before.bytes}, {"after", after.bytes}});
    if (before.image && after.image && (before.image->width != after.image->width || before.image->height != after.image->height))
        out["size"] = Json::object({{"before", Json::array({before.image->width, before.image->height})}, {"after", Json::array({after.image->width, after.image->height})}});
    else if (after.image)
        out["size"] = Json::array({after.image->width, after.image->height});
    const Json sheetAfter = afterEntry.is_object() ? afterEntry.value("sheet", Json()) : Json();
    if (before.sheet != sheetAfter) out["layout"] = Json::object({{"before", before.sheet}, {"after", sheetAfter}});
    return out;
}

[[noreturn]] void no_recipe(const std::string& rel, const Json& entry) {
    const Json prov = entry.is_object() ? entry.value("provenance", Json()) : Json();
    if (!prov.is_object())
        fail("no_recipe", "'" + rel + "' has no provenance record, so there is no recipe to run.",
             "Only assets made by the offline makers (assets.rasterize_svg, assets.animate_svg, assets.synth_sound...) record one. Make the asset with the command again, or edit the file by hand.");
    const std::string origin = prov.value("origin", std::string());
    if (origin == "generated" && prov.contains("model"))
        fail("not_regenerable", "'" + rel + "' was made by the image provider " + prov.value("provider", std::string("a provider")) +
                                    "; a provider asset is not regenerated (it would cost money and give a different picture).",
             "Call assets.generate_image (or the provider command that made it) again for a new take, with `overwrite: true`.");
    if (origin == "imported")
        fail("not_regenerable", "'" + rel + "' was imported" + (prov.contains("source") ? " from '" + prov.value("source", std::string()) + "'" : std::string()) + ", not made by a command.",
             "Run assets.import again on the source file with `overwrite: true` if it changed.");
    fail("no_recipe", "'" + rel + "' has a provenance record but no recipe, so it was made before recipes existed or by hand.",
         "Make it with its command again (the command records its recipe now), or edit the file by hand.");
}

Json run_group(const CommandRegistry& registry, const std::string& projectDir, const Group& g, bool single) {
    Json item = Json::object({{"command", g.command}, {"outputs", Json(g.outputs)}});
    std::map<std::string, Snapshot> before;
    for (const std::string& rel : g.outputs) before[rel] = snapshot(projectDir, rel, manifest_entry(projectDir, rel));

    Json args = g.args;
    if (const CommandInfo* info = registry.info(g.command))
        if (info->inputSchema.contains("properties") && info->inputSchema["properties"].contains("overwrite")) args["overwrite"] = true;
    CommandResult r = registry.call(g.command, args);
    if (!r.ok) {
        const std::string message = r.error.value("message", std::string("the command failed"));
        const std::string hint = r.error.value("hint", std::string());
        if (single) fail(r.error.value("code", std::string("failed")).c_str(), "Making '" + g.outputs.front() + "' again with " + g.command + " failed: " + message, hint);
        item["error"] = Json::object({{"code", r.error.value("code", std::string("failed"))}, {"message", message}, {"hint", hint}});
        return item;
    }
    if (r.result.is_object() && r.result.contains("warnings")) item["warnings"] = r.result["warnings"];

    Json changes = Json::object();
    bool any = false;
    for (const std::string& rel : g.outputs) {
        // The new provenance carries the new recipe and date; what a person recorded since (license, author, notes) stays.
        const Json fresh = manifest_entry(projectDir, rel);
        const Json& old = before[rel].provenance;
        Json merged = fresh.is_object() ? fresh.value("provenance", Json()) : Json();
        if (old.is_object() && merged.is_object()) {
            merged = old;
            for (const char* key : {"recipe", "date"}) {
                if (fresh["provenance"].contains(key)) merged[key] = fresh["provenance"][key];
                else merged.erase(key);
            }
        }
        // A maker that draws a picture clears its `sheet` (new pixels, old grid unknown); the same picture made again keeps the grid
        // that was recorded for it (a rasterized picture sliced in place).
        bool keepSheet = !before[rel].sheet.is_null() && !(fresh.is_object() && fresh.contains("sheet")) && before[rel].image;
        if (keepSheet) {
            const Snapshot now = snapshot(projectDir, rel, fresh);
            keepSheet = now.image && now.image->width == before[rel].image->width && now.image->height == before[rel].image->height;
        }
        if (merged != (fresh.is_object() ? fresh.value("provenance", Json()) : Json()) || keepSheet) {
            ProjectRootGuard root(projectDir);
            (void)assets::update_entry(rel, [&](Json& e) {
                if (merged.is_object()) e["provenance"] = merged;
                if (keepSheet) e["sheet"] = before[rel].sheet;
            });
        }
        const Snapshot after = snapshot(projectDir, rel, manifest_entry(projectDir, rel));
        changes[rel] = describe_change(before[rel], after, manifest_entry(projectDir, rel));
        any = any || changes[rel].value("changed", false);
    }
    item["changes"] = changes;
    item["changed"] = any;
    return item;
}

Json regenerate(const CommandRegistry& registry, const std::string& projectDir, const Json& a) {
    check_arg_keys(kCommand, a, "", {"path", "all", "stale", "dryRun"});
    const std::string pathArg = tooling_detail::arg_string(a, "path", false);
    const bool all = tooling_detail::arg_bool(a, "all", false), staleOnly = tooling_detail::arg_bool(a, "stale", false);
    const bool dryRun = tooling_detail::arg_bool(a, "dryRun", false);
    if ((!pathArg.empty()) + all + staleOnly != 1)
        fail("invalid_argument", "Give exactly one of `path` (one asset), `all` (every asset with a recipe) and `stale` (only those whose source changed).",
             "Example: {\"stale\":true,\"dryRun\":true} lists what is out of date.");

    auto text = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile);
    Json doc = Json::object();
    if (text) {
        auto parsed = parse_json(*text, assets::kManifestFile);
        if (!parsed.ok()) fail("invalid_manifest", parsed.error().message, "Fix assets.json first (factoria validate).");
        if (parsed->is_object()) doc = std::move(*parsed);
    }
    const Json assetsJson = doc.contains("assets") && doc["assets"].is_object() ? doc["assets"] : Json::object();

    std::string wanted;
    if (!pathArg.empty()) {
        auto norm = fs::normalize_checked(pathArg);
        if (!norm.ok() || norm->empty()) fail("invalid_argument", "Invalid path '" + pathArg + "'.", "Use a project-relative path such as \"assets/hero.png\".");
        wanted = *norm;
        auto it = assetsJson.find(wanted);
        if (it == assetsJson.end()) {
            std::vector<std::string> keys;
            for (const auto& [k, v] : assetsJson.items())
                if (!recipe_of(v).is_null()) keys.push_back(k);
            fail("not_found", "'" + wanted + "' has no entry in assets.json, so there is no recipe to run.",
                 keys.empty() ? "Make the asset with a maker command (assets.rasterize_svg, assets.animate_svg...) so it records its recipe." : did_you_mean(wanted, keys));
        }
        if (recipe_of(*it).is_null()) no_recipe(wanted, *it);
    }

    // The groups: assets with a recipe, those with the same command and arguments together, in the order of assets.json.
    std::vector<Group> groups;
    std::map<std::string, std::size_t> byKey;
    for (const auto& [rel, entry] : assetsJson.items()) {
        const Json recipe = recipe_of(entry);
        if (recipe.is_null()) continue;
        const std::string key = recipe["command"].get<std::string>() + "\n" + recipe["args"].dump();
        auto [it, inserted] = byKey.emplace(key, groups.size());
        if (inserted) groups.push_back({recipe["command"].get<std::string>(), recipe["args"], recipe, {}, {}});
        groups[it->second].outputs.push_back(rel);
    }
    std::map<std::string, std::size_t> producer;  // asset path -> group
    for (std::size_t i = 0; i < groups.size(); ++i)
        for (const std::string& rel : groups[i].outputs) producer[rel] = i;
    for (std::size_t i = 0; i < groups.size(); ++i)
        if (groups[i].recipe.contains("inputs") && groups[i].recipe["inputs"].is_array())
            for (const Json& in : groups[i].recipe["inputs"])
                if (in.is_object() && in.value("path", std::string()).size())
                    if (auto p = producer.find(in["path"].get<std::string>()); p != producer.end() && p->second != i) groups[i].deps.push_back(in["path"].get<std::string>());

    // Which groups to consider, upstream ones first (a sheet sliced from a picture made from an SVG: the picture, then the sheet).
    std::vector<std::size_t> order;
    std::set<std::size_t> seen, wantedGroups;
    for (std::size_t i = 0; i < groups.size(); ++i) {
        if (!wanted.empty() && std::find(groups[i].outputs.begin(), groups[i].outputs.end(), wanted) == groups[i].outputs.end()) continue;
        wantedGroups.insert(i);
    }
    std::function<void(std::size_t)> visit = [&](std::size_t i) {
        if (!seen.insert(i).second) return;
        if (wanted.empty())
            for (const std::string& dep : groups[i].deps) visit(producer[dep]);
        if (wantedGroups.contains(i)) order.push_back(i);
    };
    for (std::size_t i = 0; i < groups.size(); ++i) visit(i);

    const bool single = !wanted.empty();
    Json regenerated = Json::array(), skipped = Json::array(), failed = Json::array(), would = Json::array();
    Json warnings = Json::array();
    for (std::size_t gi : order) {
        const Group& g = groups[gi];
        const RecipeCheck check = check_recipe(projectDir, g.recipe);  // now: an upstream asset made again moved its hash
        Json brief = Json::object({{"command", g.command}, {"outputs", Json(g.outputs)}});
        if (!check.missing.empty()) {
            const std::string where = check.missing.front();
            if (single)
                fail("missing_input", "'" + wanted + "' cannot be made again: its input '" + where + "' no longer exists.",
                     "Restore '" + where + "' (version control, or make it again), or run " + g.command + " with another source.");
            Json f = brief;
            f["error"] = Json::object({{"code", "missing_input"}, {"message", "input '" + where + "' no longer exists"},
                                       {"hint", "Restore it, or run " + g.command + " again with another source."}});
            failed.push_back(f);
            continue;
        }
        if (staleOnly && !check.stale()) {
            Json s = brief;
            s["reason"] = "up to date";
            skipped.push_back(s);
            continue;
        }
        if (const CommandInfo* info = registry.info(g.command); !info || info->category != "assets" || g.command == kCommand || info->readOnly) {
            std::vector<std::string> names;
            for (const CommandInfo* c : registry.list("assets"))
                if (!c->readOnly && c->name != kCommand) names.push_back(c->name);
            const std::string message = info ? "'" + g.command + "' is not an asset maker, and regenerate only runs those (assets.* commands that write files)."
                                             : "the recipe names the command '" + g.command + "', which does not exist.";
            const std::string hint = info ? "Edit provenance.recipe in assets.json, or make the asset again with its own command."
                                          : (names.empty() ? std::string() : did_you_mean(g.command, names));
            if (single) fail("unknown_command", "Cannot make '" + wanted + "' again: " + message, hint);
            Json f = brief;
            f["error"] = Json::object({{"code", "unknown_command"}, {"message", message}, {"hint", hint}});
            failed.push_back(f);
            continue;
        }
        if (dryRun) {
            Json w = brief;
            w["args"] = g.args;
            w["stale"] = check.stale();
            if (check.stale()) w["changedInputs"] = Json(check.changed);
            would.push_back(w);
            continue;
        }
        if (single)
            for (const std::string& dep : g.deps) {
                const Group& up = groups[producer[dep]];
                if (check_recipe(projectDir, up.recipe).stale())
                    warnings.push_back("'" + dep + "', which '" + wanted + "' is made from, is itself stale: run assets.regenerate {\"stale\":true} to make both again in order.");
            }
        Json item = run_group(registry, projectDir, g, single);
        (item.contains("error") ? failed : regenerated).push_back(item);
    }

    Json result = Json::object();
    if (dryRun) {
        result["dryRun"] = true;
        result["wouldRun"] = would;
        result["count"] = would.size();
    } else {
        result["regenerated"] = regenerated;
        result["count"] = regenerated.size();
    }
    if (!skipped.empty()) result["skipped"] = skipped;
    if (!failed.empty()) result["failed"] = failed;
    if (!warnings.empty()) result["warnings"] = warnings;
    Json next = Json::array();
    if (groups.empty()) next.push_back("No asset records a recipe yet. The offline makers (assets.rasterize_svg, assets.draw_icon, assets.synth_sound...) write one when they make an asset.");
    else if (dryRun) next.push_back("Run it without dryRun to make these assets again.");
    else if (!failed.empty()) next.push_back("Fix the failed ones (see their hint) and call assets.regenerate again.");
    else next.push_back("Look at the pictures (game.screenshot, or open the file) and run factoria validate.");
    result["nextSteps"] = next;
    return result;
}

}  // namespace

void register_regenerate_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make a made asset again from the recipe its provenance records, and say what changed.";
    info.description =
        "The offline makers (assets.rasterize_svg, assets.draw_icon, assets.draw_capsules, assets.generate_texture, assets.synth_sound, "
        "assets.generate_loop, assets.pack_atlas, assets.slice_sheet) record in assets.json "
        "`provenance.recipe`: {command, args, inputs: [{path, sha256}]}, the command that made the asset, the arguments that make the "
        "same bytes again and the project files it read with their hashes. This command runs that recipe through the command registry "
        "(any assets.* command that writes a recipe works, there is no list) with `overwrite: true`, and reports per file what changed: "
        "\"pixels changed\", \"bytes changed (same pixels)\", \"unchanged\" or \"created\", the size and the `sheet` layout before and after. "
        "Give `path` for one asset, `all` for every asset with a recipe, or `stale` for those whose `inputs` no longer match the files "
        "(an SVG or other source file you edited). Assets that read the output of another (a sheet sliced from a picture made from an SVG) "
        "are made after it, and `stale` looks again at their inputs when their turn comes. `dryRun` lists what would run and which inputs "
        "changed, and changes nothing. What a person recorded in the provenance (license, author, notes) is kept; the recipe and the date "
        "are new. Several files made by one call (an icon and its foreground, a texture and its normal map, the capsules of a store) are "
        "made once. Provider-made assets (assets.generate_image...) have no recipe: they would cost money and give a different picture, so "
        "asking for one is an error that says so. `factoria validate` warns about a stale asset with this command in its hint. "
        "Example: {\"stale\":true} or {\"path\":\"assets/art/coin.png\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "path":{"type":"string","description":"Project-relative path of the asset to make again (it must record a recipe)."},
        "all":{"type":"boolean","description":"Make every asset with a recipe again."},
        "stale":{"type":"boolean","description":"Make again only the assets whose recipe inputs (the files they were made from) changed since."},
        "dryRun":{"type":"boolean","description":"List what would run (command, arguments, which inputs changed) and change nothing."}
      }})");
    registry.add(info, [&registry, projectDir](const Json& args) { return regenerate(registry, projectDir, args); });
}

}  // namespace fa::assets_detail
