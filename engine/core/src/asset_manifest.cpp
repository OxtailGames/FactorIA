#include "fa/core/asset_manifest.h"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <format>
#include <mutex>
#include <unordered_map>
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
    std::int64_t size = -1;     // and its size: two writes within the clock's step (~16 ms on Windows) share a time
    Json doc;
    std::unordered_map<std::string, std::shared_ptr<const Sheet>> sheets;  // parsed sheet entries of this read of the file
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
    cache().sheets.clear();
}

Json sorted_object(const Json& o) {
    std::vector<std::string> keys;
    for (auto it = o.begin(); it != o.end(); ++it) keys.push_back(it.key());
    std::sort(keys.begin(), keys.end());
    Json out = Json::object();
    for (const auto& k : keys) out[k] = o.at(k);
    return out;
}

bool keys_sorted(const Json& o) {
    if (!o.is_object()) return true;
    std::string prev;
    bool first = true;
    for (auto it = o.begin(); it != o.end(); ++it) {
        if (!first && it.key() < prev) return false;
        prev = it.key();
        first = false;
    }
    return true;
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
    // A file whose entries are sorted stays sorted (new entries go to their place); one somebody ordered by hand keeps its
    // order and new entries are appended, so a one-entry change is a one-entry diff.
    const bool sorted = !doc.contains("assets") || keys_sorted(doc["assets"]);
    edit(doc);
    if (!doc.contains("format")) doc["format"] = kManifestFormat;
    if (doc.contains("assets") && doc["assets"].is_object()) {
        if (doc["assets"].empty()) doc.erase("assets");
        else if (sorted) doc["assets"] = sorted_object(doc["assets"]);
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

namespace {
// Re-reads the file when it changed (c.mutex held by the caller).
void refresh_locked(Cache& c) {
    const std::string root = fs::project_root().generic_string();
    const std::int64_t modified = fs::exists(kManifestFile) ? fs::modified_time(kManifestFile) : -1;
    const std::int64_t size = modified == -1 ? -1 : fs::file_size(kManifestFile);
    if (c.root == root && c.modified == modified && c.size == size && c.modified != -2) return;
    c.root = root;
    c.modified = modified;
    c.size = size;
    c.sheets.clear();
    c.doc = empty_manifest();
    if (modified == -1) return;
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
}
}  // namespace

Json manifest() {
    Cache& c = cache();
    std::lock_guard lock(c.mutex);
    refresh_locked(c);
    return c.doc;
}

Json entry(std::string_view path) {
    Json m = manifest();
    auto assets = m.find("assets");
    if (assets == m.end() || !assets->is_object()) return Json::object();
    auto e = assets->find(key_of(path));
    return e != assets->end() && e->is_object() ? *e : Json::object();
}

const SheetClip* Sheet::find(std::string_view name) const {
    for (const SheetClip& c : clips)
        if (c.name == name) return &c;
    return nullptr;
}

std::vector<std::string> Sheet::clip_names() const {
    std::vector<std::string> out;
    for (const SheetClip& c : clips) out.push_back(c.name);
    return out;
}

namespace {
std::optional<std::array<float, 2>> read_pivot(const Json& j) {
    auto it = j.find("pivot");
    if (it == j.end() || !it->is_array() || it->size() != 2 || !(*it)[0].is_number() || !(*it)[1].is_number()) return std::nullopt;
    return std::array<float, 2>{(*it)[0].get<float>(), (*it)[1].get<float>()};
}
int read_int(const Json& j, const char* key, int fallback) {
    auto it = j.find(key);
    return it != j.end() && it->is_number() ? it->get<int>() : fallback;
}
}  // namespace

std::shared_ptr<const Sheet> parse_sheet(const Json& e) {
    if (!e.is_object() || !e.contains("columns") || !e.contains("rows")) return nullptr;
    auto s = std::make_shared<Sheet>();
    s->columns = std::max(1, read_int(e, "columns", 1));
    s->rows = std::max(1, read_int(e, "rows", 1));
    s->frameWidth = std::max(0, read_int(e, "frameWidth", 0));
    s->frameHeight = std::max(0, read_int(e, "frameHeight", 0));
    s->frames = std::max(0, read_int(e, "frames", 0));
    s->padding = std::max(0, read_int(e, "padding", 0));
    s->pivot = read_pivot(e);
    if (auto cl = e.find("clips"); cl != e.end() && cl->is_array()) {
        for (const Json& c : *cl) {
            if (!c.is_object() || !c.contains("name") || !c["name"].is_string()) continue;
            SheetClip sc;
            sc.name = c["name"].get<std::string>();
            sc.firstFrame = std::max(0, read_int(c, "firstFrame", 0));
            sc.lastFrame = std::max(sc.firstFrame, read_int(c, "lastFrame", sc.firstFrame));
            if (auto f = c.find("fps"); f != c.end() && f->is_number()) sc.fps = f->get<float>();
            if (auto l = c.find("loop"); l != c.end() && l->is_boolean()) sc.loop = l->get<bool>();
            sc.pivot = read_pivot(c);
            s->clips.push_back(std::move(sc));
        }
    }
    return s;
}

std::shared_ptr<const Sheet> sheet(std::string_view path) {
    Cache& c = cache();
    const std::string key = key_of(path);
    std::lock_guard lock(c.mutex);
    refresh_locked(c);
    if (auto it = c.sheets.find(key); it != c.sheets.end()) return it->second;
    std::shared_ptr<const Sheet> parsed;
    if (auto assets = c.doc.find("assets"); assets != c.doc.end() && assets->is_object())
        if (auto e = assets->find(key); e != assets->end() && e->is_object())
            if (auto s = e->find("sheet"); s != e->end()) parsed = parse_sheet(*s);
    c.sheets[key] = parsed;
    return parsed;
}

PackedTexture packed_texture(std::string_view path) {
    const Json e = entry(path);
    const auto p = e.find("packed");
    if (p == e.end() || !p->is_object()) return {};
    const auto atlas = p->find("atlas"), rect = p->find("rect");
    if (atlas == p->end() || !atlas->is_string() || rect == p->end() || !rect->is_array() || rect->size() != 4) return {};
    for (const Json& v : *rect)
        if (!v.is_number_integer()) return {};
    return {atlas->get<std::string>(), (*rect)[0].get<int>(), (*rect)[1].get<int>(), (*rect)[2].get<int>(), (*rect)[3].get<int>()};
}

Json import_settings(const Json& m, std::string_view path) {
    const AssetKind kind = kind_of(path);
    Json out = builtin_import_defaults(kind);
    if (auto d = m.find("defaults"); d != m.end() && d->is_object())
        if (auto k = d->find(kind_name(kind)); k != d->end()) merge_into(out, *k);
    if (auto a = m.find("assets"); a != m.end() && a->is_object())
        if (auto e = a->find(key_of(path)); e != a->end() && e->is_object()) merge_into(out, e->value("import", Json::object()));
    return out;
}

Json import_settings(std::string_view path) { return import_settings(manifest(), path); }

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
