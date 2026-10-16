#include "fa/core/asset_manifest.h"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <format>
#include <mutex>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

namespace fa::assets {

namespace {

struct Cache {
    std::mutex mutex;
    std::string root;           // project root the cached manifest belongs to
    std::int64_t modified = -2; // modified_time of the file when read (-1 = missing, -2 = never read)
    Json doc;
    std::string warnedFor;      // "root|mtime" of the last warning, so a broken file warns once
};

Cache& cache() {
    static Cache c;
    return c;
}

Json empty_manifest() { return Json::object({{"format", kManifestFormat}}); }

// Parses the manifest text; an error message when it is not a JSON object.
Result<Json> parse_manifest(std::string_view text) {
    auto j = parse_json(text, kManifestFile);
    if (!j) return j;
    if (!j->is_object())
        return make_error(std::format("{} must be a JSON object", kManifestFile),
                          "Start it as {\"format\": \"factoria.assets/1\"} (schemas/assets.schema.json).");
    return j;
}

void invalidate() {
    std::lock_guard lock(cache().mutex);
    cache().modified = -2;
}

Json sorted_object(const Json& o) {
    std::vector<std::string> keys;
    for (auto it = o.begin(); it != o.end(); ++it) keys.push_back(it.key());
    std::sort(keys.begin(), keys.end());
    Json out = Json::object();
    for (const auto& k : keys) out[k] = o.at(k);
    return out;
}

std::string key_of(std::string_view path) {
    std::string k = fs::normalize(path);
    return k.empty() ? std::string(path) : k;
}

void merge_into(Json& base, const Json& over) {
    if (!over.is_object()) return;
    for (auto it = over.begin(); it != over.end(); ++it) base[it.key()] = it.value();
}

// Built-in import settings of a kind (the defaults schemas/assets.schema.json documents).
Json builtin_import_defaults(AssetKind kind) {
    switch (kind) {
        case AssetKind::Texture: return Json::object({{"compression", "auto"}, {"atlas", ""}});
        case AssetKind::Audio:
            return Json::object({{"stream", "auto"}, {"normalize", false}, {"targetLufs", -16.0}, {"convert", "none"}});
        default: return Json::object();
    }
}

}  // namespace

Result<void> update_manifest(const std::function<void(Json& doc)>& edit) {
    Json doc = empty_manifest();
    if (fs::exists(kManifestFile)) {
        auto text = fs::read_text(kManifestFile);
        if (!text) return make_error(std::format("cannot read {}: {}", kManifestFile, text.error().message), text.error().hint);
        auto parsed = parse_manifest(*text);
        if (!parsed)
            return make_error(std::format("{} is not valid, so it was not changed: {}", kManifestFile, parsed.error().message),
                              "Fix the file (factoria validate shows where) and try again.");
        doc = std::move(*parsed);
    }
    edit(doc);
    if (!doc.contains("format")) doc["format"] = kManifestFormat;
    if (doc.contains("assets") && doc["assets"].is_object()) {
        if (doc["assets"].empty()) doc.erase("assets");
        else doc["assets"] = sorted_object(doc["assets"]);
    }
    auto r = save_json_file(kManifestFile, doc);
    invalidate();
    return r;
}

AssetKind kind_of(std::string_view path) {
    const std::string ext = fs::extension(path);
    static const char* textures[] = {".png", ".jpg", ".jpeg", ".tga", ".bmp", ".psd", ".gif", ".ktx2"};
    static const char* audio[] = {".wav", ".ogg", ".mp3", ".qoa", ".flac"};
    static const char* models[] = {".gltf", ".glb", ".obj", ".fbx"};
    static const char* fonts[] = {".ttf", ".otf"};
    static const char* video[] = {".mp4", ".webm", ".mpg", ".mpeg", ".mov", ".mkv"};
    auto in = [&](const auto& list) { return std::find(std::begin(list), std::end(list), ext) != std::end(list); };
    if (in(textures)) return AssetKind::Texture;
    if (in(audio)) return AssetKind::Audio;
    if (in(models)) return AssetKind::Model;
    if (in(fonts)) return AssetKind::Font;
    if (in(video)) return AssetKind::Video;
    return AssetKind::Other;
}

const char* kind_name(AssetKind kind) {
    switch (kind) {
        case AssetKind::Texture: return "texture";
        case AssetKind::Audio: return "audio";
        case AssetKind::Model: return "model";
        case AssetKind::Font: return "font";
        case AssetKind::Video: return "video";
        case AssetKind::Other: break;
    }
    return "other";
}

Json manifest() {
    Cache& c = cache();
    std::lock_guard lock(c.mutex);
    const std::string root = fs::project_root().generic_string();
    const std::int64_t modified = fs::exists(kManifestFile) ? fs::modified_time(kManifestFile) : -1;
    if (c.root == root && c.modified == modified && c.modified != -2) return c.doc;
    c.root = root;
    c.modified = modified;
    c.doc = empty_manifest();
    if (modified == -1) return c.doc;
    auto text = fs::read_text(kManifestFile);
    auto parsed = text ? parse_manifest(*text) : Result<Json>(make_error(text.error().message));
    if (parsed) {
        c.doc = std::move(*parsed);
    } else {
        const std::string tag = root + "|" + std::to_string(modified);
        if (c.warnedFor != tag) {
            c.warnedFor = tag;
            FA_WARN("assets", "{} is ignored: {} Run `factoria validate` to see the problem.", kManifestFile, parsed.error().message);
        }
    }
    return c.doc;
}

Json entry(std::string_view path) {
    Json m = manifest();
    auto assets = m.find("assets");
    if (assets == m.end() || !assets->is_object()) return Json::object();
    auto e = assets->find(key_of(path));
    return e != assets->end() && e->is_object() ? *e : Json::object();
}

Json import_settings(std::string_view path) {
    const AssetKind kind = kind_of(path);
    Json out = builtin_import_defaults(kind);
    Json m = manifest();
    if (auto d = m.find("defaults"); d != m.end() && d->is_object())
        if (auto k = d->find(kind_name(kind)); k != d->end()) merge_into(out, *k);
    merge_into(out, entry(path).value("import", Json::object()));
    return out;
}

Result<void> update_entry(std::string_view path, const std::function<void(Json& entry)>& edit) {
    const std::string key = key_of(path);
    return update_manifest([&](Json& doc) {
        if (!doc.contains("assets") || !doc["assets"].is_object()) doc["assets"] = Json::object();
        Json& assets = doc["assets"];
        Json e = assets.contains(key) && assets[key].is_object() ? assets[key] : Json::object();
        edit(e);
        if (e.is_object() && !e.empty()) assets[key] = std::move(e);
        else assets.erase(key);
    });
}

std::string today() {
    const std::time_t t = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    std::tm tm{};
#if defined(_WIN32)
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    return std::format("{:04}-{:02}-{:02}", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday);
}

}  // namespace fa::assets
