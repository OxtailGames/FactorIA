// Baking an audio document: the WAV or OGG next to it, its provenance and recipe in assets.json, and the status of a baked document.
// "Stale" is the recipe's, like every made asset (docs/ASSETS.md "Recipes").
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <format>
#include <set>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/tooling/audio_doc.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using assets_detail::ProjectRootGuard;

constexpr const char* kBakeCommand = "audio.bake";

std::string normalized(const std::string& rel) {
    auto norm = fs::normalize_checked(rel);
    return norm.ok() && !norm->empty() ? *norm : rel;
}

Json manifest_entry(const std::string& projectDir, const std::string& rel) {
    ProjectRootGuard root(projectDir);
    return assets::entry(rel);
}

// Loads the document and reports why it cannot be baked; `doc` is filled when it can.
bool load_for_bake(const std::string& projectDir, const std::string& rel, AudioDoc& doc, AudioBakeStatus& status) {
    ProjectRootGuard root(projectDir);
    auto loaded = load_audio_doc(rel);
    if (!loaded.ok()) {
        status.state = AudioBakeState::Broken;
        status.reason = loaded.error().message;
        status.hint = loaded.error().hint;
        return false;
    }
    doc = std::move(*loaded);
    status.output = audio_document_output(doc, rel);
    if (normalized(doc.source.path) == status.output) {
        status.state = AudioBakeState::Broken;
        status.reason = rel + ": the baked sound would overwrite its own source '" + doc.source.path + "'";
        status.hint = "Set \"output\": {\"path\": \"assets/audio/<name>_clean." + doc.output.format + "\"} (or move the original to assets/raw/) so the source stays untouched.";
        status.output.clear();
        return false;
    }
    return true;
}

}  // namespace

std::string audio_document_output(const AudioDoc& doc, const std::string& relIn) {
    if (!doc.output.path.empty()) return normalized(doc.output.path);
    const std::string rel = normalized(relIn);
    const std::string ext = doc.output.format == "ogg" ? ".ogg" : ".wav";
    if (ends_with(rel, kAudioDocSuffix)) return rel.substr(0, rel.size() - std::strlen(kAudioDocSuffix)) + ext;
    const auto dot = rel.rfind('.');
    return (dot == std::string::npos ? rel : rel.substr(0, dot)) + ext;
}

const char* audio_bake_state_name(AudioBakeState state) {
    switch (state) {
        case AudioBakeState::Fresh: return "fresh";
        case AudioBakeState::Missing: return "missing";
        case AudioBakeState::Stale: return "stale";
        case AudioBakeState::Unrecorded: return "unrecorded";
        case AudioBakeState::Broken: return "broken";
    }
    return "";
}

AudioBakeStatus audio_bake_status(const std::string& projectDir, const std::string& relIn) {
    AudioBakeStatus status;
    const std::string rel = normalized(relIn);
    AudioDoc doc;
    if (!load_for_bake(projectDir, rel, doc, status)) return status;
    auto file = resolve_project_path(projectDir, status.output);
    std::error_code ec;
    if (!file.ok() || !stdfs::is_regular_file(*file, ec)) {
        status.state = AudioBakeState::Missing;
        status.reason = "'" + status.output + "' has not been baked yet.";
        return status;
    }
    const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, status.output));
    if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand || recipe["args"].value("path", std::string()) != rel) {
        status.state = AudioBakeState::Unrecorded;
        status.reason = "'" + status.output + "' exists, but assets.json does not say it was baked from '" + rel + "'.";
        return status;
    }
    const assets_detail::RecipeCheck check = assets_detail::check_recipe(projectDir, recipe);
    if (!check.changed.empty() || !check.missing.empty()) {
        status.state = AudioBakeState::Stale;
        status.reason = !check.changed.empty() ? "changed since the bake: " + join(check.changed, ", ") : "no longer readable: " + join(check.missing, ", ");
        return status;
    }
    status.state = AudioBakeState::Fresh;
    status.reason = "'" + status.output + "' matches the document and the files it reads.";
    return status;
}

Result<AudioBakeResult> bake_audio_document(const std::string& projectDir, const std::string& relIn, const AudioBakeOptions& options) {
    const std::string rel = normalized(relIn);
    if (!ends_with(rel, kAudioDocSuffix))
        return make_error("'" + rel + "' is not an audio document (its name must end in " + kAudioDocSuffix + ").", "Name it like \"assets/audio/door.audio.json\".");
    AudioDoc doc;
    AudioBakeStatus status;
    if (!load_for_bake(projectDir, rel, doc, status)) return make_error(status.reason, status.hint);
    AudioBakeResult result;
    result.document = rel;
    result.output = status.output;
    if (options.onlyIfNeeded && audio_bake_status(projectDir, rel).state == AudioBakeState::Fresh) return result;
    if (!starts_with(result.output, "assets/"))
        return make_error(rel + ": the sound would be written to '" + result.output + "', outside assets/.", "Put it under assets/, e.g. \"output\": {\"path\": \"assets/audio/door.wav\"}.");

    auto outPath = resolve_project_path(projectDir, result.output);
    if (!outPath.ok()) return make_error(outPath.error().message, outPath.error().hint);
    if (!options.overwrite) {
        std::error_code ec;
        if (stdfs::exists(*outPath, ec)) {
            const Json recipe = assets_detail::recipe_of(manifest_entry(projectDir, result.output));
            if (recipe.is_null() || recipe.value("command", std::string()) != kBakeCommand)
                return make_error("'" + result.output + "' already exists and was not baked by an audio document.", "Pass overwrite: true to replace it, or set another \"output\": {\"path\"} in the document.");
        }
    }

    ProjectRootGuard root(projectDir);
    auto clip = render_audio_doc(doc, rel);
    if (!clip.ok()) return make_error(clip.error().message, clip.error().hint);
    auto bytes = audio_encode(*clip, doc.output);
    if (!bytes.ok()) return make_error(rel + ": cannot encode '" + result.output + "': " + bytes.error().message, bytes.error().hint);
    result.sha256 = sha256_hex(bytes->data(), bytes->size());
    result.bytes = bytes->size();

    std::vector<std::string> inputs = {rel};
    std::vector<std::string> sources = clip->inputs;
    std::sort(sources.begin(), sources.end());
    sources.erase(std::unique(sources.begin(), sources.end()), sources.end());
    for (const std::string& s : sources)
        if (s != rel) inputs.push_back(s);
    result.inputs = inputs;

    // who made the pieces: AI-made sources make the sound AI-made, and their licenses travel
    bool ai = false;
    std::set<std::string> licenses, authors;
    for (const std::string& input : sources) {
        const Json entry = manifest_entry(projectDir, input);
        const Json prov = entry.is_object() ? entry.value("provenance", Json()) : Json();
        if (!prov.is_object()) continue;
        ai = ai || prov.value("ai", false);
        if (prov.contains("license") && prov["license"].is_string()) licenses.insert(prov["license"].get<std::string>());
        if (prov.contains("author") && prov["author"].is_string()) authors.insert(prov["author"].get<std::string>());
    }

    try {
        assets_detail::require_usable_manifest(projectDir);
        const Json previous = manifest_entry(projectDir, result.output);
        const Json previousProv = previous.is_object() ? previous.value("provenance", Json()) : Json();
        std::string err;
        bool same = false;
        if (auto old = tooling_detail::read_file(*outPath)) same = *old == std::string_view(reinterpret_cast<const char*>(bytes->data()), bytes->size());
        if (!same && !tooling_detail::write_file(*outPath, std::string_view(reinterpret_cast<const char*>(bytes->data()), bytes->size()), &err))
            return make_error("Cannot write '" + result.output + "': " + err, "Check that the folder is writable.");
        result.written = true;

        const bool madeHere = previousProv.is_object() && previousProv.value("provider", std::string()) == "factoria audio.bake";
        std::string license = licenses.empty() ? "CC0-1.0" : join(std::vector<std::string>(licenses.begin(), licenses.end()), "; ");
        if (madeHere && previousProv.contains("license") && previousProv["license"].is_string()) license = previousProv["license"].get<std::string>();
        std::string author = authors.empty() ? "factoria" : join(std::vector<std::string>(authors.begin(), authors.end()), "; ");
        if (madeHere && previousProv.contains("author") && previousProv["author"].is_string()) author = previousProv["author"].get<std::string>();
        const std::string notes = std::format("Rendered from the audio document '{}' ({} step{}), {:.2f} s, {:.1f} LUFS.", rel, doc.steps.size(), doc.steps.size() == 1 ? "" : "s", clip->seconds(), clip->lufs);
        Json prov = Json::object({{"origin", ai ? "generated" : "original"},
                                  {"ai", ai},
                                  {"kind", "sound"},
                                  {"provider", "factoria audio.bake"},
                                  {"license", license},
                                  {"author", author},
                                  {"source", rel},
                                  {"notes", notes},
                                  {"date", assets::today()}});
        prov["recipe"] = assets_detail::make_recipe(projectDir, kBakeCommand, Json::object({{"path", rel}}), inputs);
        result.provenance = prov;
        const std::optional<AudioLoop> loop = clip->loop;
        const double rate = double(clip->sampleRate);
        auto updated = assets::update_entry(result.output, [&](Json& e) {
            e.erase("analysis");
            e["provenance"] = prov;
            if (loop) {
                if (!e.contains("import") || !e["import"].is_object()) e["import"] = Json::object();
                // Seconds, rounded to a microsecond: the engine turns them back into the same frame.
                e["import"]["loopStart"] = std::round(double(loop->start) / rate * 1e6) / 1e6;
                e["import"]["loopEnd"] = std::round(double(loop->end) / rate * 1e6) / 1e6;
            } else if (e.contains("import") && e["import"].is_object()) {
                e["import"].erase("loopStart");
                e["import"].erase("loopEnd");
                if (e["import"].empty()) e.erase("import");
            }
        });
        if (!updated.ok()) return make_error("The sound was written, but assets.json was not updated: " + updated.error().message, updated.error().hint);
    } catch (const CommandError& e) {
        return make_error(e.what(), e.hint);
    }
    result.clip = std::move(*clip);
    return result;
}

std::vector<std::string> list_audio_documents(const std::string& projectDir) {
    std::vector<std::string> out;
    const stdfs::path root(projectDir);
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        const std::string rel = it->path().lexically_relative(root).generic_string();
        std::error_code e2;
        if (it->is_directory(e2)) {
            if ((!name.empty() && name[0] == '.') || name == "node_modules" || rel == "build") it.disable_recursion_pending();
            continue;
        }
        if (ends_with(name, kAudioDocSuffix)) out.push_back(rel);
    }
    std::sort(out.begin(), out.end());
    return out;
}

Result<std::vector<AudioBakeResult>> bake_audio_documents_if_needed(const std::string& projectDir) {
    std::vector<AudioBakeResult> baked;
    for (const std::string& rel : list_audio_documents(projectDir)) {
        if (audio_bake_status(projectDir, rel).state == AudioBakeState::Fresh) continue;
        auto r = bake_audio_document(projectDir, rel, {false, false});
        if (!r.ok()) return make_error(r.error().message, r.error().hint);
        baked.push_back(std::move(*r));
    }
    return baked;
}

}  // namespace fa
