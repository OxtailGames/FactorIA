#include "fa/scene/lightmap_manifest.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/lightmap_uv.h"

namespace fa {

namespace {

const std::vector<std::string> kTopKeys = {"version", "uvVersion", "settingsHash", "pages", "entities"};
const std::vector<std::string> kPageKeys = {"file", "width", "height"};
const std::vector<std::string> kEntityKeys = {"id", "mesh", "uv", "meshHash", "settingsHash", "page", "scaleOffset"};

Error err(const std::string& file, const std::string& pointer, const std::string& what, const std::string& hint) {
    return Error{std::format("{} {}: {}", file, pointer.empty() ? "(document)" : pointer, what), hint};
}

// Rejects a key the format does not have, with the closest one that it does.
Result<void> check_keys(const Json& o, const std::vector<std::string>& known, const std::string& file,
                        const std::string& pointer) {
    for (auto it = o.begin(); it != o.end(); ++it) {
        bool ok = false;
        for (const std::string& k : known) ok = ok || k == it.key();
        if (ok) continue;
        return err(
            file, pointer + "/" + it.key(),
            "unknown key \"" + it.key() + "\"", did_you_mean(it.key(), known) + " The keys are: " + [&] {
                std::string s;
                for (const std::string& k : known) s += (s.empty() ? "" : ", ") + k;
                return s;
            }() + ".");
    }
    return {};
}

bool is_hex16(const std::string& s) {
    if (s.size() != 16) return false;
    for (char c : s)
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return false;
    return true;
}

// An integer member (a JSON number without a fraction), clamped to what an int holds; false when it is not one.
bool read_int(const Json& o, const char* key, int& out) {
    const auto it = o.find(key);
    if (it == o.end() || !it->is_number_integer()) return false;
    const long long v = it->get<long long>();
    out = int(std::clamp<long long>(v, -2147483647LL, 2147483647LL));
    return true;
}

float round6(float v) { return std::round(v * 1e6f) / 1e6f; }

}  // namespace

const LightmapEntry* LightmapManifest::find(const std::string& id) const {
    const auto it = byId_.find(id);
    return it == byId_.end() ? nullptr : &entities[it->second];
}

void LightmapManifest::index() {
    byId_.clear();
    for (std::size_t i = 0; i < entities.size(); ++i) byId_.emplace(entities[i].id, i);
}

Result<LightmapManifest> parse_lightmap_manifest(const Json& json, const std::string& file) {
    if (!json.is_object())
        return err(file, "", "the lightmap manifest must be a JSON object",
                   "It looks like {\"version\": 1, \"uvVersion\": 1, \"pages\": [...], \"entities\": [...]}; "
                   "`lightmap.bake` writes it.");
    if (auto r = check_keys(json, kTopKeys, file, ""); !r) return r.error();
    LightmapManifest m;
    int version = 0;
    if (!read_int(json, "version", version))
        return err(file, "/version", "\"version\" is missing or not an integer",
                   "Write \"version\": " + std::to_string(kLightmapManifestVersion) + ".");
    if (version != kLightmapManifestVersion)
        return err(
            file, "/version",
            std::format("the manifest has version {}, this engine reads version {}", version, kLightmapManifestVersion),
            "Bake the lightmaps again (lightmap.bake) with this engine.");
    m.version = version;
    if (!read_int(json, "uvVersion", m.uvVersion))
        return err(file, "/uvVersion", "\"uvVersion\" is missing or not an integer",
                   "Write \"uvVersion\": " + std::to_string(kLightmapUvVersion) + ".");
    if (m.uvVersion != kLightmapUvVersion)
        return err(file, "/uvVersion",
                   std::format("the lightmap UVs of the bake are version {}, this engine makes version {}", m.uvVersion,
                               kLightmapUvVersion),
                   "The mesh's lightmap UVs changed since the bake: bake the lightmaps again (lightmap.bake).");
    if (const auto it = json.find("settingsHash"); it != json.end()) {
        if (!it->is_string()) return err(file, "/settingsHash", "\"settingsHash\" must be a string", "");
        m.settingsHash = it->get<std::string>();
    }
    const auto pages = json.find("pages");
    if (pages == json.end() || !pages->is_array())
        return err(file, "/pages", "\"pages\" is missing or not an array",
                   "List the page images: [{\"file\": \"scenes/level.lightmap.0.hdr\", \"width\": 512, \"height\": "
                   "512}].");
    if (pages->size() > std::size_t(kLightmapMaxPages))
        return err(file, "/pages", std::format("{} pages: at most {} are read", pages->size(), kLightmapMaxPages),
                   "Bake with a lower density or a larger page size.");
    for (std::size_t i = 0; i < pages->size(); ++i) {
        const Json& p = (*pages)[i];
        const std::string ptr = "/pages/" + std::to_string(i);
        if (!p.is_object())
            return err(file, ptr, "a page must be an object", "{\"file\": ..., \"width\": ..., \"height\": ...}");
        if (auto r = check_keys(p, kPageKeys, file, ptr); !r) return r.error();
        LightmapPage page;
        const auto f = p.find("file");
        if (f == p.end() || !f->is_string() || f->get<std::string>().empty())
            return err(file, ptr + "/file", "\"file\" is missing or not a path",
                       "Give the project-relative path of the Radiance .hdr page.");
        page.file = f->get<std::string>();
        if (fs::extension(page.file) != ".hdr")
            return err(file, ptr + "/file", "the page '" + page.file + "' is not a .hdr file",
                       "Pages are Radiance .hdr images (lightmap.bake writes them).");
        if (!read_int(p, "width", page.width) || !read_int(p, "height", page.height) || page.width < 1 ||
            page.height < 1 || page.width > kLightmapMaxPageSize || page.height > kLightmapMaxPageSize)
            return err(file, ptr,
                       std::format("\"width\" and \"height\" must be integers from 1 to {}", kLightmapMaxPageSize),
                       "They are the size in texels of the page image.");
        m.pages.push_back(std::move(page));
    }
    const auto ents = json.find("entities");
    if (ents == json.end() || !ents->is_array())
        return err(file, "/entities", "\"entities\" is missing or not an array",
                   "List the lit entities: [{\"id\": ..., \"page\": 0, \"scaleOffset\": [sx, sy, ox, oy], ...}].");
    std::set<std::string> seen;
    for (std::size_t i = 0; i < ents->size(); ++i) {
        const Json& e = (*ents)[i];
        const std::string ptr = "/entities/" + std::to_string(i);
        if (!e.is_object()) return err(file, ptr, "an entity entry must be an object", "");
        if (auto r = check_keys(e, kEntityKeys, file, ptr); !r) return r.error();
        LightmapEntry en;
        const auto id = e.find("id");
        if (id == e.end() || !id->is_string() || id->get<std::string>().empty())
            return err(file, ptr + "/id", "\"id\" is missing or not a string",
                       "It is the entity's stable id (EntityInfo.id).");
        en.id = id->get<std::string>();
        if (!seen.insert(en.id).second)
            return err(file, ptr + "/id", "the entity id \"" + en.id + "\" is listed twice",
                       "Each entity has one rectangle in the lightmap: bake again.");
        for (const char* key : {"mesh", "uv", "meshHash", "settingsHash"}) {
            const auto it = e.find(key);
            if (it == e.end()) continue;
            if (!it->is_string())
                return err(file, ptr + "/" + key, std::string("\"") + key + "\" must be a string", "");
            std::string& dst = std::string(key) == "mesh"       ? en.mesh
                               : std::string(key) == "uv"       ? en.uv
                               : std::string(key) == "meshHash" ? en.meshHash
                                                                : en.settingsHash;
            dst = it->get<std::string>();
        }
        if (!en.uv.empty() && en.uv != "gltf" && en.uv != "generated")
            return err(file, ptr + "/uv", "\"uv\" is \"" + en.uv + "\"",
                       "Use \"gltf\" (the file's TEXCOORD_1) or \"generated\" (the engine's unwrap).");
        if (!en.meshHash.empty() && !is_hex16(en.meshHash))
            return err(file, ptr + "/meshHash", "\"meshHash\" must be 16 lower-case hex digits",
                       "Do not edit it: bake again.");
        if (!read_int(e, "page", en.page))
            return err(file, ptr + "/page", "\"page\" is missing or not an integer",
                       "It is the index in \"pages\" (0 to " +
                           std::to_string(m.pages.empty() ? 0 : m.pages.size() - 1) + ").");
        if (en.page < 0 || std::size_t(en.page) >= m.pages.size())
            return err(file, ptr + "/page",
                       std::format("page {} does not exist: the manifest lists {} page(s)", en.page, m.pages.size()),
                       "Use an index from 0 to " + std::to_string(m.pages.empty() ? 0 : m.pages.size() - 1) +
                           ", or bake again.");
        const auto so = e.find("scaleOffset");
        if (so == e.end() || !so->is_array() || so->size() != 4)
            return err(file, ptr + "/scaleOffset", "\"scaleOffset\" must be an array of four numbers",
                       "[sx, sy, ox, oy]: the entity's rectangle of the page, in 0..1 of the page.");
        for (std::size_t k = 0; k < 4; ++k) {
            const Json& v = (*so)[k];
            if (!v.is_number()) return err(file, ptr + "/scaleOffset/" + std::to_string(k), "not a number", "");
            const double d = v.get<double>();
            if (!std::isfinite(d))
                return err(file, ptr + "/scaleOffset/" + std::to_string(k), "not a finite number", "Bake again.");
            en.scaleOffset[k] = float(d);
        }
        constexpr float tol = 1e-4f;
        if (!(en.scaleOffset[0] > 0 && en.scaleOffset[1] > 0) || en.scaleOffset[0] > 1 + tol ||
            en.scaleOffset[1] > 1 + tol || en.scaleOffset[2] < -tol || en.scaleOffset[3] < -tol ||
            en.scaleOffset[2] + en.scaleOffset[0] > 1 + tol || en.scaleOffset[3] + en.scaleOffset[1] > 1 + tol)
            return err(file, ptr + "/scaleOffset",
                       std::format("the rectangle [{}, {}, {}, {}] is not inside the page", en.scaleOffset[0],
                                   en.scaleOffset[1], en.scaleOffset[2], en.scaleOffset[3]),
                       "The scale must be above 0 and offset + scale must stay within 1: the lightmap UV of the mesh "
                       "is mapped "
                       "to uv * scale + offset. Bake again.");
        m.entities.push_back(std::move(en));
    }
    m.index();
    return m;
}

Json lightmap_manifest_to_json(const LightmapManifest& m) {
    Json j = Json::object();
    j["version"] = m.version;
    j["uvVersion"] = m.uvVersion;
    if (!m.settingsHash.empty()) j["settingsHash"] = m.settingsHash;
    Json pages = Json::array();
    for (const LightmapPage& p : m.pages)
        pages.push_back(Json{{"file", p.file}, {"width", p.width}, {"height", p.height}});
    j["pages"] = std::move(pages);
    Json ents = Json::array();
    for (const LightmapEntry& e : m.entities) {
        Json o = Json::object();
        o["id"] = e.id;
        if (!e.mesh.empty()) o["mesh"] = e.mesh;
        if (!e.uv.empty()) o["uv"] = e.uv;
        if (!e.meshHash.empty()) o["meshHash"] = e.meshHash;
        o["page"] = e.page;
        o["scaleOffset"] = Json::array(
            {round6(e.scaleOffset[0]), round6(e.scaleOffset[1]), round6(e.scaleOffset[2]), round6(e.scaleOffset[3])});
        if (!e.settingsHash.empty()) o["settingsHash"] = e.settingsHash;
        ents.push_back(std::move(o));
    }
    j["entities"] = std::move(ents);
    return j;
}

Result<LightmapManifest> load_lightmap_manifest(const std::string& path) {
    auto text = fs::read_text(path);
    if (!text)
        return Error{"cannot read the lightmap manifest '" + path + "': " + text.error().message, text.error().hint};
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    return parse_lightmap_manifest(*json, path);
}

double lightmap_texels_per_meter(double baseTexelsPerMeter, float lightmapScale) {
    if (!(lightmapScale > 0) || !std::isfinite(lightmapScale) || !(baseTexelsPerMeter > 0) ||
        !std::isfinite(baseTexelsPerMeter))
        return 0;
    return baseTexelsPerMeter * double(std::min(lightmapScale, 100.0f));
}

std::string lightmap_hash_hex(std::uint64_t hash) { return std::format("{:016x}", hash); }

std::uint64_t lightmap_hash_bytes(std::uint64_t h, const void* data, std::size_t size) {
    const auto* p = static_cast<const unsigned char*>(data);
    for (std::size_t i = 0; i < size; ++i) {
        h ^= p[i];
        h *= 0x100000001b3ull;
    }
    return h;
}

}  // namespace fa
