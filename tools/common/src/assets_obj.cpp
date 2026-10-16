// Wavefront OBJ (+ MTL and its textures) -> a glTF 2.0 file with an embedded buffer, which the engine's glTF loader and
// MeshRenderer read: one node and mesh per object or group (o, g), one primitive per material (usemtl).
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <limits>
#include <map>
#include <set>
#include <tuple>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

struct Material {
    std::string name;
    float color[4] = {1, 1, 1, 1};
    std::string texture;  // map_Kd as written
    stdfs::path textureFile;  // where it was found ("" = not found)
};

// Vertices of a primitive are shared when v, vt and vn are the same; a face without normals gets its own vertices (and a
// flat normal), which `unique` tells apart.
using VertexKey = std::tuple<int, int, int, std::size_t>;

struct Primitive {
    int material = -1;
    std::vector<float> position, normal, uv;
    std::vector<std::uint32_t> index;
    std::map<VertexKey, std::uint32_t> lookup;
    bool hasUv = false;
};

struct Object {
    std::string name;
    std::vector<Primitive> primitives;
};

struct Vec {
    float x = 0, y = 0, z = 0;
};

struct Parser {
    std::string file;  // for messages
    std::vector<Vec> positions, normals, uvs;
    std::vector<Material> materials;
    std::vector<Object> objects;
    std::string defaultObject;
    int currentMaterial = -1;
    std::size_t unique = 0;
    std::vector<std::string> warnings;
    std::set<std::string> missingMaterials;
    int ignoredLines = 0;
};

std::vector<std::string_view> words(std::string_view line) {
    std::vector<std::string_view> out;
    for (std::size_t i = 0; i < line.size();) {
        while (i < line.size() && std::isspace(static_cast<unsigned char>(line[i]))) ++i;
        std::size_t j = i;
        while (j < line.size() && !std::isspace(static_cast<unsigned char>(line[j]))) ++j;
        if (j > i) out.push_back(line.substr(i, j - i));
        i = j;
    }
    return out;
}

// The words of `line` after the first, as the text they were written as (names with spaces).
std::string rest_of(std::string_view line) {
    const auto w = words(line);
    if (w.size() < 2) return {};
    return std::string(trim(line.substr(std::size_t(w[1].data() - line.data()))));
}

bool number(std::string_view word, float& out) {
    char* end = nullptr;
    out = std::strtof(word.data(), &end);  // a word ends at a space, a line end or the string's terminator
    return end == word.data() + word.size();
}

Error line_error(const Parser& p, int line, const std::string& what, const std::string& hint = {}) {
    return make_error(std::format("{}:{}: {}", p.file, line, what), hint);
}

// "v", "v/vt", "v//vn" or "v/vt/vn" with 1-based or negative (relative) indices -> 0-based, -1 when absent.
Result<std::array<int, 3>> face_vertex(const Parser& p, std::string_view word, int line) {
    std::array<int, 3> idx = {-1, -1, -1};
    const std::size_t counts[3] = {p.positions.size(), p.uvs.size(), p.normals.size()};
    const char* names[3] = {"vertex", "texture coordinate", "normal"};
    std::size_t start = 0;
    for (int k = 0; k < 3 && start <= word.size(); ++k) {
        std::size_t end = word.find('/', start);
        if (end == std::string_view::npos) end = word.size();
        const std::string_view part = word.substr(start, end - start);
        start = end + 1;
        if (part.empty()) continue;
        char* stop = nullptr;
        const long value = std::strtol(part.data(), &stop, 10);
        if (stop != part.data() + part.size() || value == 0)
            return line_error(p, line, "'" + std::string(word) + "' is not a valid face vertex.", "Faces are written f v/vt/vn v/vt/vn v/vt/vn, with 1-based indices.");
        const long resolved = value > 0 ? value - 1 : long(counts[k]) + value;
        if (resolved < 0 || resolved >= long(counts[k]))
            return line_error(p, line, std::format("a face uses {} {}, but only {} {}s are defined before it.", names[k], value, counts[k], names[k]));
        idx[k] = int(resolved);
    }
    return idx;
}

Object& current_object(Parser& p) {
    if (p.objects.empty()) p.objects.push_back({p.defaultObject, {}});
    return p.objects.back();
}

Primitive& current_primitive(Parser& p) {
    Object& object = current_object(p);
    for (Primitive& prim : object.primitives)
        if (prim.material == p.currentMaterial) return prim;
    object.primitives.emplace_back();
    object.primitives.back().material = p.currentMaterial;
    return object.primitives.back();
}

std::uint32_t add_vertex(Parser& p, Primitive& prim, const std::array<int, 3>& idx, const Vec& flatNormal, bool flat) {
    const VertexKey key{idx[0], idx[1], idx[2], flat ? p.unique : 0};
    if (auto it = prim.lookup.find(key); it != prim.lookup.end()) return it->second;
    const Vec& v = p.positions[std::size_t(idx[0])];
    const Vec n = flat ? flatNormal : p.normals[std::size_t(idx[2])];
    prim.position.insert(prim.position.end(), {v.x, v.y, v.z});
    prim.normal.insert(prim.normal.end(), {n.x, n.y, n.z});
    if (idx[1] >= 0) {
        prim.hasUv = true;
        prim.uv.insert(prim.uv.end(), {p.uvs[std::size_t(idx[1])].x, 1.0f - p.uvs[std::size_t(idx[1])].y});  // OBJ's v goes up, glTF's down
    } else {
        prim.uv.insert(prim.uv.end(), {0.0f, 0.0f});
    }
    const auto index = std::uint32_t(prim.position.size() / 3 - 1);
    prim.lookup.emplace(key, index);
    return index;
}

Vec face_normal(const Vec& a, const Vec& b, const Vec& c) {
    const Vec u{b.x - a.x, b.y - a.y, b.z - a.z}, v{c.x - a.x, c.y - a.y, c.z - a.z};
    Vec n{u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x};
    const float length = std::sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
    return length > 1e-12f ? Vec{n.x / length, n.y / length, n.z / length} : Vec{0, 1, 0};
}

Result<void> add_face(Parser& p, const std::vector<std::string_view>& w, int line) {
    if (w.size() < 4) return line_error(p, line, "a face needs at least 3 vertices.");
    std::vector<std::array<int, 3>> corners;
    for (std::size_t i = 1; i < w.size(); ++i) {
        auto c = face_vertex(p, w[i], line);
        if (!c.ok()) return c.error();
        corners.push_back(*c);
    }
    Primitive& prim = current_primitive(p);
    for (std::size_t i = 1; i + 1 < corners.size(); ++i) {  // a fan: right for the convex polygons OBJ files hold
        const std::array<int, 3>* tri[3] = {&corners[0], &corners[i], &corners[i + 1]};
        const bool flat = (*tri[0])[2] < 0 || (*tri[1])[2] < 0 || (*tri[2])[2] < 0;
        const Vec normal = flat ? face_normal(p.positions[std::size_t((*tri[0])[0])], p.positions[std::size_t((*tri[1])[0])],
                                              p.positions[std::size_t((*tri[2])[0])])
                                : Vec{};
        if (flat) ++p.unique;
        for (const auto* corner : tri) prim.index.push_back(add_vertex(p, prim, *corner, normal, flat));
    }
    return {};
}

// "map_Kd -s 1 1 1 wood.png" -> "wood.png": the options before the file name are skipped with their arguments.
std::string texture_name(std::string_view line) {
    static const std::map<std::string_view, int> optionArgs = {{"-blendu", 1}, {"-blendv", 1}, {"-cc", 1},  {"-clamp", 1},
                                                               {"-bm", 1},     {"-imfchan", 1}, {"-texres", 1}, {"-type", 1},
                                                               {"-mm", 2},     {"-o", 3},       {"-s", 3},      {"-t", 3}};
    const auto w = words(line);
    std::size_t i = 1;
    while (i < w.size() && optionArgs.count(w[i])) {
        const int n = optionArgs.at(w[i++]);
        float ignored;
        for (int k = 0; k < n && i < w.size() && (n < 3 || number(w[i], ignored) || k == 0); ++k) ++i;
    }
    return i < w.size() ? std::string(trim(line.substr(std::size_t(w[i].data() - line.data())))) : std::string();
}

void read_mtl(Parser& p, const stdfs::path& mtlFile) {
    const auto text = tooling_detail::read_file(mtlFile);
    if (!text) return;
    Material* mat = nullptr;
    for (const std::string& raw : split(*text, '\n', false)) {
        const std::string_view line = trim(raw);
        const auto w = words(line);
        if (w.empty() || w[0][0] == '#') continue;
        if (w[0] == "newmtl") {
            p.materials.push_back(Material{rest_of(line)});
            mat = &p.materials.back();
        } else if (!mat) {
            continue;
        } else if (w[0] == "Kd" && w.size() >= 4) {
            for (int k = 0; k < 3; ++k) number(w[std::size_t(k) + 1], mat->color[k]);
        } else if ((w[0] == "d" || w[0] == "Tr") && w.size() >= 2) {
            float v = 1;
            if (number(w[1], v)) mat->color[3] = w[0] == "d" ? v : 1 - v;
        } else if (w[0] == "map_Kd") {
            mat->texture = texture_name(line);
            for (const stdfs::path& dir : {mtlFile.parent_path(), mtlFile.parent_path().parent_path()}) {
                std::error_code ec;
                const stdfs::path candidate = dir / stdfs::path(replace_all(mat->texture, "\\", "/"));
                if (!mat->texture.empty() && stdfs::is_regular_file(candidate, ec)) {
                    mat->textureFile = candidate;
                    break;
                }
            }
        }
    }
}

Json accessor(int view, int componentType, std::size_t count, const char* type) {
    return Json::object({{"bufferView", view}, {"componentType", componentType}, {"count", count}, {"type", type}});
}

double r6(float v) { return std::round(double(v) * 1e6) / 1e6; }  // JSON numbers without float noise

}  // namespace

Result<ImportOutput> import_obj(const ImportRequest& request) {
    const auto text = tooling_detail::read_file(request.source);
    if (!text) return make_error("cannot read '" + request.source.string() + "'");
    Parser p;
    p.file = request.source.filename().string();
    p.defaultObject = request.source.stem().string();
    ImportOutput out;

    // ---- OBJ ----
    int lineNo = 0;
    for (const std::string& raw : split(*text, '\n', false)) {
        const std::string_view line = trim(raw);
        ++lineNo;
        const auto w = words(line);
        if (w.empty() || w[0][0] == '#') continue;
        const std::string_view key = w[0];
        if (key == "v" || key == "vn" || key == "vt") {
            Vec value;
            float* parts[3] = {&value.x, &value.y, &value.z};
            const std::size_t need = key == "vt" ? 1 : 3;
            if (w.size() <= need) return line_error(p, lineNo, "'" + std::string(key) + "' needs " + std::to_string(need) + " numbers.");
            for (std::size_t k = 0; k < std::min<std::size_t>(3, w.size() - 1); ++k)
                if (!number(w[k + 1], *parts[k])) return line_error(p, lineNo, "'" + std::string(w[k + 1]) + "' is not a number.");
            (key == "v" ? p.positions : key == "vn" ? p.normals : p.uvs).push_back(value);
        } else if (key == "f") {
            if (auto r = add_face(p, w, lineNo); !r.ok()) return r.error();
        } else if (key == "o" || key == "g") {
            p.objects.push_back({rest_of(line).empty() ? p.defaultObject : rest_of(line), {}});
        } else if (key == "mtllib") {
            const std::string names = rest_of(line);
            std::vector<std::string> candidates = {names};
            for (const auto& word : words(names)) candidates.emplace_back(word);
            bool found = false;
            for (const std::string& name : candidates) {
                std::error_code ec;
                const stdfs::path file = request.source.parent_path() / stdfs::path(replace_all(name, "\\", "/"));
                if (!name.empty() && stdfs::is_regular_file(file, ec)) {
                    read_mtl(p, file);
                    found = true;
                    break;
                }
            }
            if (!found) p.warnings.push_back("The material library '" + names + "' is not next to the OBJ, so the materials are missing (white).");
        } else if (key == "usemtl") {
            const std::string name = rest_of(line);
            const auto it = std::find_if(p.materials.begin(), p.materials.end(), [&](const Material& m) { return m.name == name; });
            p.currentMaterial = it == p.materials.end() ? -1 : int(it - p.materials.begin());
            if (it == p.materials.end() && p.missingMaterials.insert(name).second)
                p.warnings.push_back("Material '" + name + "' is not defined in any .mtl: its faces are white.");
        } else if (key == "l" || key == "p") {
            ++p.ignoredLines;
        }
    }
    p.objects.erase(std::remove_if(p.objects.begin(), p.objects.end(), [](const Object& o) { return o.primitives.empty(); }), p.objects.end());
    if (p.objects.empty())
        return make_error("'" + p.file + "' has no faces (" + std::to_string(p.positions.size()) + " vertices).",
                          "Only polygon faces (f lines) are imported, not points or lines. Export the mesh with faces (triangulated or not).");
    if (p.ignoredLines > 0) p.warnings.push_back(std::to_string(p.ignoredLines) + " point and line elements were skipped (only faces are imported).");

    // ---- glTF ----
    std::vector<std::uint8_t> buffer;
    Json views = Json::array(), accessors = Json::array(), meshes = Json::array(), nodes = Json::array(), sceneNodes = Json::array();
    auto add_view = [&](const void* data, std::size_t bytes, int target) {
        while (buffer.size() % 4 != 0) buffer.push_back(0);
        views.push_back(Json::object({{"buffer", 0}, {"byteOffset", buffer.size()}, {"byteLength", bytes}, {"target", target}}));
        buffer.insert(buffer.end(), static_cast<const std::uint8_t*>(data), static_cast<const std::uint8_t*>(data) + bytes);
        return int(views.size()) - 1;
    };
    std::vector<int> gltfMaterial(p.materials.size(), -1);  // OBJ material -> glTF material, in order of first use
    Json gltfMaterials = Json::array(), textures = Json::array(), images = Json::array();
    std::map<stdfs::path, int> textureIndex;  // texture file -> glTF texture (-1: unreadable), so a texture is written once
    std::set<std::string> usedNames;
    const std::string destDir = fs::parent(request.dest);
    float lo[3] = {std::numeric_limits<float>::max(), std::numeric_limits<float>::max(), std::numeric_limits<float>::max()};
    float hi[3] = {std::numeric_limits<float>::lowest(), std::numeric_limits<float>::lowest(), std::numeric_limits<float>::lowest()};
    std::size_t vertices = 0, triangles = 0;

    // The glTF texture of a material's map_Kd: the file is copied next to the glTF (PNG and JPEG as they are, other formats
    // converted to PNG, which glTF requires). -1 and a warning when it is missing or unreadable.
    auto texture_for = [&](const Material& m) -> int {
        if (m.texture.empty()) return -1;
        const std::string what = "Texture '" + m.texture + "' of material '" + m.name + "'";
        if (m.textureFile.empty()) {
            out.warnings.push_back(what + " was not found next to the OBJ or its .mtl: the material keeps its color only.");
            return -1;
        }
        if (auto it = textureIndex.find(m.textureFile); it != textureIndex.end()) return it->second;
        int index = -1;
        const auto bytes = tooling_detail::read_file(m.textureFile);
        auto image = bytes ? decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size()) : Result<Image>(make_error("cannot read the file"));
        if (!image.ok()) {
            out.warnings.push_back(what + " cannot be read (" + image.error().message + "): the material keeps its color only.");
        } else {
            const std::string ext = to_lower(m.textureFile.extension().string());
            const bool keep = ext == ".png" || ext == ".jpg" || ext == ".jpeg";
            const std::string stem = safe_file_name(m.textureFile.stem().string(), "texture");
            std::string name = stem + (keep ? ext : ".png");
            for (int n = 2; !usedNames.insert(name).second; ++n) name = stem + "_" + std::to_string(n) + (keep ? ext : ".png");
            out.files.push_back({destDir + "/" + name, keep ? std::vector<std::uint8_t>(bytes->begin(), bytes->end()) : encode_png(*image)});
            images.push_back(Json::object({{"uri", name}}));
            textures.push_back(Json::object({{"source", int(images.size()) - 1}}));
            index = int(textures.size()) - 1;
        }
        textureIndex[m.textureFile] = index;
        return index;
    };
    auto material_index = [&](int obj) -> int {
        if (obj < 0) return -1;
        if (gltfMaterial[std::size_t(obj)] >= 0) return gltfMaterial[std::size_t(obj)];
        const Material& m = p.materials[std::size_t(obj)];
        Json pbr = Json::object({{"baseColorFactor", Json::array({r6(m.color[0]), r6(m.color[1]), r6(m.color[2]), r6(m.color[3])})},
                                 {"metallicFactor", 0.0}, {"roughnessFactor", 1.0}});
        if (const int texture = texture_for(m); texture >= 0) pbr["baseColorTexture"] = Json::object({{"index", texture}});
        Json material = Json::object({{"name", m.name}, {"pbrMetallicRoughness", pbr}});
        if (m.color[3] < 1) material["alphaMode"] = "BLEND";
        gltfMaterials.push_back(material);
        return gltfMaterial[std::size_t(obj)] = int(gltfMaterials.size()) - 1;
    };

    for (const Object& object : p.objects) {
        Json primitives = Json::array();
        for (const Primitive& prim : object.primitives) {
            const std::size_t count = prim.position.size() / 3;
            float pmin[3] = {prim.position[0], prim.position[1], prim.position[2]}, pmax[3] = {pmin[0], pmin[1], pmin[2]};
            for (std::size_t i = 0; i < count; ++i)
                for (int k = 0; k < 3; ++k) {
                    pmin[k] = std::min(pmin[k], prim.position[i * 3 + std::size_t(k)]);
                    pmax[k] = std::max(pmax[k], prim.position[i * 3 + std::size_t(k)]);
                }
            for (int k = 0; k < 3; ++k) {
                lo[k] = std::min(lo[k], pmin[k]);
                hi[k] = std::max(hi[k], pmax[k]);
            }
            Json attributes = Json::object();
            Json a = accessor(add_view(prim.position.data(), prim.position.size() * 4, 34962), 5126, count, "VEC3");
            a["min"] = Json::array({r6(pmin[0]), r6(pmin[1]), r6(pmin[2])});
            a["max"] = Json::array({r6(pmax[0]), r6(pmax[1]), r6(pmax[2])});
            accessors.push_back(a);
            attributes["POSITION"] = int(accessors.size()) - 1;
            accessors.push_back(accessor(add_view(prim.normal.data(), prim.normal.size() * 4, 34962), 5126, count, "VEC3"));
            attributes["NORMAL"] = int(accessors.size()) - 1;
            if (prim.hasUv) {
                accessors.push_back(accessor(add_view(prim.uv.data(), prim.uv.size() * 4, 34962), 5126, count, "VEC2"));
                attributes["TEXCOORD_0"] = int(accessors.size()) - 1;
            }
            int indexView;
            int indexType;
            if (count <= 65535) {
                std::vector<std::uint16_t> small(prim.index.begin(), prim.index.end());
                indexView = add_view(small.data(), small.size() * 2, 34963);
                indexType = 5123;
            } else {
                indexView = add_view(prim.index.data(), prim.index.size() * 4, 34963);
                indexType = 5125;
            }
            accessors.push_back(accessor(indexView, indexType, prim.index.size(), "SCALAR"));
            Json primitive = Json::object({{"attributes", attributes}, {"indices", int(accessors.size()) - 1}, {"mode", 4}});
            if (const int m = material_index(prim.material); m >= 0) primitive["material"] = m;
            primitives.push_back(primitive);
            vertices += count;
            triangles += prim.index.size() / 3;
        }
        meshes.push_back(Json::object({{"name", object.name}, {"primitives", primitives}}));
        nodes.push_back(Json::object({{"name", object.name}, {"mesh", int(meshes.size()) - 1}}));
        sceneNodes.push_back(int(nodes.size()) - 1);
    }

    Json gltf = Json::object({{"asset", Json::object({{"version", "2.0"}, {"generator", "FactorIA assets.import (OBJ)"}})},
                              {"scene", 0}, {"scenes", Json::array({Json::object({{"nodes", sceneNodes}})})},
                              {"nodes", nodes}, {"meshes", meshes}});
    if (!gltfMaterials.empty()) gltf["materials"] = gltfMaterials;
    if (!images.empty()) {
        gltf["images"] = images;
        gltf["textures"] = textures;
    }
    gltf["accessors"] = accessors;
    gltf["bufferViews"] = views;
    gltf["buffers"] = Json::array({Json::object({{"byteLength", buffer.size()},
                                                 {"uri", "data:application/octet-stream;base64," + base64_encode(buffer.data(), buffer.size())}})});
    const std::string json = dump_json(gltf);
    out.files.insert(out.files.begin(), OutFile{request.dest, std::vector<std::uint8_t>(json.begin(), json.end())});
    out.warnings.insert(out.warnings.begin(), p.warnings.begin(), p.warnings.end());
    out.details = Json::object({{"objects", p.objects.size()}, {"vertices", vertices}, {"triangles", triangles},
                                {"materials", gltfMaterials.size()}, {"textures", textures.size()},
                                {"boundsMin", Json::array({r6(lo[0]), r6(lo[1]), r6(lo[2])})}, {"boundsMax", Json::array({r6(hi[0]), r6(hi[1]), r6(hi[2])})},
                                {"size", Json::array({r6(hi[0] - lo[0]), r6(hi[1] - lo[1]), r6(hi[2] - lo[2])})}});
    out.nextSteps = {"Show it: a MeshRenderer with \"mesh\": \"" + request.dest + "\" (unless unlit it needs a light). Its size is in `details.size` "
                     "in the OBJ's own units; scale the entity if that is not what you want (OBJ has no unit, 1 = 1 meter in the engine).",
                     "OBJ files have no smoothing groups here: faces without normals are flat shaded. Check it with game.screenshot."};
    return out;
}

}  // namespace fa::assets_detail
