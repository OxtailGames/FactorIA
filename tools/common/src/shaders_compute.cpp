// Compute materials ("kind": "compute", docs/SHADERS.md "Compute materials"): the workgroup size and storage buffers of the
// material file, the std430 layout of a buffer element, the top file around the snippet, and which dialects and platforms a
// compute material has shaders for.
#include <algorithm>
#include <cmath>
#include <regex>

#include "fa/core/strings.h"
#include "fa/tooling/shaders.h"
#include "shaders_internal.h"
#include "util.h"

namespace fa {

using tooling_detail::escape_token;

namespace {

const std::vector<std::string> kFieldTypes = {"float", "vec2", "vec3", "vec4", "int", "uint"};
const std::vector<std::string> kBufferAccess = {"readWrite", "read"};
// The formats sokol-shdc takes as a storage image layout (its access_format) and every compute backend can write.
const std::vector<std::string> kImageFormats = {"rgba8", "rgba16f", "r32f", "rgba32f"};
// sokol-shdc refuses a readonly image2D ("use regular textures instead"), so the access of an image is write or readWrite.
const std::vector<std::string> kImageAccess = {"write", "readWrite"};

int type_size(const std::string& type) {
    if (type == "vec2") return 8;
    if (type == "vec3") return 12;
    if (type == "vec4") return 16;
    return 4;
}
int type_align(const std::string& type) {
    if (type == "vec2") return 8;
    if (type == "vec3" || type == "vec4") return 16;
    return 4;
}
int round_up(int value, int multiple) { return (value + multiple - 1) / multiple * multiple; }

}  // namespace

namespace shaders_detail {

void layout_buffer(MaterialBuffer& buffer) {
    int cursor = 0, maxAlign = 4;
    for (MaterialBufferField& f : buffer.fields) {
        const int align = type_align(f.type);
        f.offset = round_up(cursor, align);
        cursor = f.offset + type_size(f.type);
        maxAlign = std::max(maxAlign, align);
    }
    buffer.stride = round_up(std::max(cursor, 4), maxAlign);
}

namespace {

void error(std::vector<MaterialIssue>& errors, std::string pointer, std::string message, std::string hint = {}) {
    errors.push_back({std::move(pointer), std::move(message), std::move(hint)});
}

void parse_workgroup(const Json& doc, MaterialDef& m, std::vector<MaterialIssue>& errors) {
    auto it = doc.find("workgroupSize");
    if (it == doc.end()) return;
    const char* hint =
        "Write \"workgroupSize\": [64, 1, 1] (x, y, z; z and y may be left out). 64 threads in x is a good "
        "start for a 1D job, [8, 8, 1] for an image.";
    if (!it->is_array() || it->empty() || it->size() > 3) {
        error(errors, "/workgroupSize", "expected an array of 1 to 3 integers, got " + describe_json_value(*it), hint);
        return;
    }
    int size[3] = {1, 1, 1};
    bool good = true;
    for (std::size_t i = 0; i < it->size(); ++i) {
        const Json& v = (*it)[i];
        const std::string ptr = "/workgroupSize/" + std::to_string(i);
        const bool whole = v.is_number() && std::floor(v.get<double>()) == v.get<double>();
        if (!whole || v.get<double>() < 1 || v.get<double>() > kComputeMaxWorkgroupInvocations) {
            error(errors, ptr,
                  "expected a whole number from 1 to " + std::to_string(kComputeMaxWorkgroupInvocations) + ", got " +
                      describe_json_value(v),
                  hint);
            good = false;
        } else {
            size[i] = int(v.get<double>());
        }
    }
    if (!good) return;
    if (size[2] > kComputeMaxWorkgroupZ) {  // D3D11's numthreads and the GL minimum limit z (but not x or y) to 64
        error(errors, "/workgroupSize/2",
              "z is " + std::to_string(size[2]) + ", at most " + std::to_string(kComputeMaxWorkgroupZ) +
                  " (the limit of Direct3D 11 and the minimum every OpenGL driver guarantees)",
              "Use a smaller z, or spread the threads over x and y: [8, 8, 1] or [4, 4, 4].");
        return;
    }
    if (size[0] * size[1] * size[2] > kComputeMaxWorkgroupInvocations) {
        error(errors, "/workgroupSize",
              "the workgroup has " + std::to_string(size[0] * size[1] * size[2]) + " threads (" +
                  std::to_string(size[0]) + " x " + std::to_string(size[1]) + " x " + std::to_string(size[2]) +
                  "), at most " + std::to_string(kComputeMaxWorkgroupInvocations),
              "Use a smaller workgroup; dispatch more workgroups to cover the work (the dispatch counts groups, not "
              "threads).");
        return;
    }
    if ((size[0] * size[1] * size[2]) % 32 !=
        0) {  // sokol-shdc refuses any other product (a hardware wave is 32 threads)
        error(errors, "/workgroupSize",
              "the workgroup has " + std::to_string(size[0] * size[1] * size[2]) + " threads (" +
                  std::to_string(size[0]) + " x " + std::to_string(size[1]) + " x " + std::to_string(size[2]) +
                  "), which is not a multiple of 32",
              "Use 32, 64, 128 or 256 threads, e.g. [64] or [8, 8, 1]; check `i.global_id` against your element count "
              "in the snippet for the threads past the end.");
        return;
    }
    std::copy(size, size + 3, m.workgroupSize);
}

void parse_field(const Json& f, const std::string& ptr, MaterialBuffer& buffer, std::vector<MaterialIssue>& errors,
                 const CheckName& checkName) {
    if (!f.is_object()) {
        error(errors, ptr, "expected an object, got " + describe_json_value(f),
              "Write {\"name\": \"pos\", \"type\": \"vec3\", \"doc\": \"What it holds.\"}.");
        return;
    }
    static const std::vector<std::string> keys = {"name", "type", "doc"};
    for (auto it = f.begin(); it != f.end(); ++it)
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
            error(errors, ptr + "/" + escape_token(it.key()), "unknown key \"" + it.key() + "\"",
                  did_you_mean(it.key(), keys));
    MaterialBufferField field;
    bool ok = true;
    if (auto n = f.find("name"); n == f.end() || !n->is_string()) {
        error(errors, ptr + "/name",
              n == f.end() ? "missing \"name\"" : "expected a string, got " + describe_json_value(*n),
              "Name the field like a GLSL variable, e.g. \"pos\"; the snippet reads it as <buffer>.data[i].pos.");
        ok = false;
    } else {
        field.name = n->get<std::string>();
        ok = checkName(ptr + "/name", field.name, "buffer field");
        if (ok && std::any_of(buffer.fields.begin(), buffer.fields.end(),
                              [&](const MaterialBufferField& o) { return o.name == field.name; })) {
            error(errors, ptr + "/name", "field name \"" + field.name + "\" is used twice in this buffer",
                  "Give every field of an element its own name.");
            ok = false;
        }
    }
    if (auto t = f.find("type"); t == f.end()) {
        error(errors, ptr + "/type", "missing \"type\"", "Use one of: " + join(kFieldTypes, ", ") + ".");
        ok = false;
    } else if (!t->is_string() ||
               std::find(kFieldTypes.begin(), kFieldTypes.end(), t->get<std::string>()) == kFieldTypes.end()) {
        error(errors, ptr + "/type",
              std::string("unknown field type ") +
                  (t->is_string() ? "\"" + t->get<std::string>() + "\"" : describe_json_value(*t)),
              t->is_string() ? did_you_mean(t->get<std::string>(), kFieldTypes)
                             : "Use one of: " + join(kFieldTypes, ", ") + ".");
        ok = false;
    } else {
        field.type = t->get<std::string>();
    }
    if (auto d = f.find("doc"); d != f.end()) {
        if (d->is_string())
            field.doc = d->get<std::string>();
        else
            error(errors, ptr + "/doc", "expected a string, got " + describe_json_value(*d), "Write \"doc\": \"...\".");
    }
    if (ok) buffer.fields.push_back(std::move(field));
}

void parse_buffers(const Json& doc, MaterialDef& m, std::vector<MaterialIssue>& errors, std::set<std::string>& taken,
                   const CheckName& checkName) {
    auto bs = doc.find("buffers");
    if (bs == doc.end()) return;
    if (!bs->is_object()) {
        error(errors, "/buffers", "expected an object, got " + describe_json_value(*bs),
              "Write \"buffers\": {\"particles\": {\"fields\": [{\"name\": \"pos\", \"type\": \"vec3\"}]}}.");
        return;
    }
    if (int(bs->size()) > kComputeMaxMaterialBuffers)
        error(errors, "/buffers",
              std::to_string(bs->size()) + " buffers, at most " + std::to_string(kComputeMaxMaterialBuffers) +
                  " (the uniform block, the textures and the buffers share the binding slots of every GPU the shader "
                  "runs on)",
              "Put the arrays that are always read together into one buffer with more fields.");
    static const std::vector<std::string> keys = {"doc", "access", "fields"};
    for (auto it = bs->begin(); it != bs->end(); ++it) {
        const std::string ptr = "/buffers/" + escape_token(it.key());
        const bool nameOk = checkName(ptr, it.key(), "buffer");
        MaterialBuffer buffer;
        buffer.name = it.key();
        const Json& b = it.value();
        if (!b.is_object()) {
            error(errors, ptr, "expected an object, got " + describe_json_value(b),
                  "Write \"" + it.key() +
                      "\": {\"access\": \"readWrite\", \"fields\": [{\"name\": \"pos\", \"type\": \"vec3\"}]}.");
            continue;
        }
        for (auto k = b.begin(); k != b.end(); ++k)
            if (std::find(keys.begin(), keys.end(), k.key()) == keys.end())
                error(errors, ptr + "/" + escape_token(k.key()), "unknown key \"" + k.key() + "\"",
                      did_you_mean(k.key(), keys));
        if (auto d = b.find("doc"); d != b.end()) {
            if (d->is_string())
                buffer.doc = d->get<std::string>();
            else
                error(errors, ptr + "/doc", "expected a string, got " + describe_json_value(*d),
                      "Write \"doc\": \"...\".");
        }
        if (auto a = b.find("access"); a != b.end()) {
            if (!a->is_string() ||
                std::find(kBufferAccess.begin(), kBufferAccess.end(), a->get<std::string>()) == kBufferAccess.end())
                error(errors, ptr + "/access",
                      std::string("unknown access ") +
                          (a->is_string() ? "\"" + a->get<std::string>() + "\"" : describe_json_value(*a)),
                      a->is_string() ? did_you_mean(a->get<std::string>(), kBufferAccess)
                                     : "Use \"readWrite\" (the default) or \"read\" (the shader only reads it).");
            else
                buffer.access = a->get<std::string>();
        }
        auto fs = b.find("fields");
        if (fs == b.end() || !fs->is_array() || fs->empty()) {
            error(errors, ptr + "/fields",
                  fs == b.end() ? "missing \"fields\"" : "expected a non-empty array, got " + describe_json_value(*fs),
                  "List what one element holds: \"fields\": [{\"name\": \"pos\", \"type\": \"vec3\"}, {\"name\": "
                  "\"life\", "
                  "\"type\": \"float\"}]. The buffer is an array of these.");
        } else {
            if (int(fs->size()) > kComputeMaxBufferFields)
                error(errors, ptr + "/fields",
                      std::to_string(fs->size()) + " fields, at most " + std::to_string(kComputeMaxBufferFields),
                      "Split the element into two buffers.");
            for (std::size_t i = 0; i < fs->size(); ++i)
                parse_field((*fs)[i], ptr + "/fields/" + std::to_string(i), buffer, errors, checkName);
        }
        if (!nameOk) continue;
        // The generated GLSL names the element struct `<name>_item`: it shares the namespace of params and textures.
        for (const std::string& taker : {it.key(), it.key() + "_item"})
            if (!taken.insert(taker).second)
                error(
                    errors, ptr, "name \"" + taker + "\" is used twice",
                    "Buffer, param and texture names share one namespace (a buffer also takes <name>_item, the type of "
                    "its elements).");
        layout_buffer(buffer);
        m.buffers.push_back(std::move(buffer));
    }
}

void parse_images(const Json& doc, MaterialDef& m, std::vector<MaterialIssue>& errors, std::set<std::string>& taken,
                  const CheckName& checkName) {
    auto is = doc.find("images");
    if (is == doc.end()) return;
    if (!is->is_object()) {
        error(errors, "/images", "expected an object, got " + describe_json_value(*is),
              "Write \"images\": {\"field\": {\"format\": \"rgba8\", \"size\": [256, 256]}}.");
        return;
    }
    if (int(is->size()) > kComputeMaxMaterialImages)
        error(errors, "/images",
              std::to_string(is->size()) + " images, at most " + std::to_string(kComputeMaxMaterialImages) +
                  " (the storage image bindings every GPU with compute guarantees to one shader)",
              "Pack the channels that are written together into one rgba image, or use a second material.");
    static const std::vector<std::string> keys = {"doc", "format", "access", "size"};
    for (auto it = is->begin(); it != is->end(); ++it) {
        const std::string ptr = "/images/" + escape_token(it.key());
        const bool nameOk = checkName(ptr, it.key(), "image");
        MaterialImage image;
        image.name = it.key();
        const Json& b = it.value();
        if (!b.is_object()) {
            error(errors, ptr, "expected an object, got " + describe_json_value(b),
                  "Write \"" + it.key() + "\": {\"format\": \"rgba8\", \"access\": \"write\", \"size\": [256, 256]}.");
            continue;
        }
        for (auto k = b.begin(); k != b.end(); ++k)
            if (std::find(keys.begin(), keys.end(), k.key()) == keys.end())
                error(errors, ptr + "/" + escape_token(k.key()), "unknown key \"" + k.key() + "\"",
                      did_you_mean(k.key(), keys));
        if (auto d = b.find("doc"); d != b.end()) {
            if (d->is_string())
                image.doc = d->get<std::string>();
            else
                error(errors, ptr + "/doc", "expected a string, got " + describe_json_value(*d),
                      "Write \"doc\": \"...\".");
        }
        if (auto f = b.find("format"); f != b.end()) {
            if (!f->is_string() ||
                std::find(kImageFormats.begin(), kImageFormats.end(), f->get<std::string>()) == kImageFormats.end())
                error(errors, ptr + "/format",
                      std::string("unknown image format ") +
                          (f->is_string() ? "\"" + f->get<std::string>() + "\"" : describe_json_value(*f)),
                      f->is_string() ? did_you_mean(f->get<std::string>(), kImageFormats) +
                                           " Formats: " + join(kImageFormats, ", ") + "."
                                     : "Use one of: " + join(kImageFormats, ", ") + ".");
            else
                image.format = f->get<std::string>();
        }
        if (auto a = b.find("access"); a != b.end()) {
            if (a->is_string() && a->get<std::string>() == "read")
                error(errors, ptr + "/access",
                      "a storage image cannot be read-only (the shader compiler refuses a readonly image2D)",
                      "To only read an image, declare it a texture of the material (\"textures\") and use "
                      "texelFetch/texture; use \"write\" (imageStore) or \"readWrite\" (imageStore and imageLoad).");
            else if (!a->is_string() ||
                     std::find(kImageAccess.begin(), kImageAccess.end(), a->get<std::string>()) == kImageAccess.end())
                error(errors, ptr + "/access",
                      std::string("unknown access ") +
                          (a->is_string() ? "\"" + a->get<std::string>() + "\"" : describe_json_value(*a)),
                      a->is_string()
                          ? did_you_mean(a->get<std::string>(), kImageAccess)
                          : "Use \"write\" (the default; imageStore) or \"readWrite\" (imageStore and imageLoad).");
            else
                image.access = a->get<std::string>();
        }
        if (auto s = b.find("size"); s != b.end()) {
            const char* hint = "Write \"size\": [256, 256] (width, height in pixels) or [512] for a square image.";
            if (!s->is_array() || s->empty() || s->size() > 2) {
                error(errors, ptr + "/size", "expected an array of 1 or 2 integers, got " + describe_json_value(*s),
                      hint);
            } else {
                int dims[2] = {0, 0};
                for (std::size_t i = 0; i < s->size(); ++i) {
                    const Json& v = (*s)[i];
                    const bool whole = v.is_number() && std::floor(v.get<double>()) == v.get<double>();
                    if (!whole || v.get<double>() < 1 || v.get<double>() > kComputeMaxImageSize)
                        error(errors, ptr + "/size/" + std::to_string(i),
                              "expected a whole number from 1 to " + std::to_string(kComputeMaxImageSize) + ", got " +
                                  describe_json_value(v),
                              hint);
                    else
                        dims[i] = int(v.get<double>());
                }
                if (dims[0] > 0 && (s->size() == 1 || dims[1] > 0)) {
                    image.width = dims[0];
                    image.height = s->size() == 1 ? dims[0] : dims[1];
                }
            }
        }
        if (!nameOk) continue;
        if (!taken.insert(it.key()).second)
            error(errors, ptr, "name \"" + it.key() + "\" is used twice",
                  "Image, buffer, param and texture names share one namespace.");
        m.images.push_back(std::move(image));
    }
}

}  // namespace

void parse_compute_fields(const Json& doc, MaterialDef& m, std::vector<MaterialIssue>& errors,
                          std::set<std::string>& taken, const CheckName& checkName) {
    if (m.kind != "compute") {
        for (const char* key : {"workgroupSize", "buffers", "images"})
            if (doc.contains(key))
                error(errors, std::string("/") + key, std::string("\"") + key + "\" belongs to compute materials",
                      "Add \"kind\": \"compute\", or remove \"" + std::string(key) + "\".");
        return;
    }
    for (const char* key : {"lighting", "alphaMode", "doubleSided"})
        if (doc.contains(key))
            error(errors, std::string("/") + key, std::string("\"") + key + "\" does not apply to a compute material",
                  "A compute material draws nothing: remove \"" + std::string(key) + "\".");
    parse_workgroup(doc, m, errors);
    parse_buffers(doc, m, errors, taken, checkName);
    parse_images(doc, m, errors, taken, checkName);
    std::sort(m.buffers.begin(), m.buffers.end(),
              [](const MaterialBuffer& a, const MaterialBuffer& b) { return a.name < b.name; });
    for (std::size_t i = 0; i < m.buffers.size(); ++i) m.buffers[i].binding = int(i);
    std::sort(m.images.begin(), m.images.end(),
              [](const MaterialImage& a, const MaterialImage& b) { return a.name < b.name; });
    for (std::size_t i = 0; i < m.images.size(); ++i) m.images[i].binding = int(m.buffers.size() + i);
}

bool defines_compute_entry(const std::string& strippedSnippet) {
    static const std::regex entry(R"(\bvoid\s+compute\s*\()");
    return std::regex_search(strippedSnippet, entry);
}

Json compute_twin_fields(const MaterialDef& m) {
    Json buffers = Json::array();
    for (const MaterialBuffer& b : m.buffers) {
        Json fields = Json::array();
        for (const MaterialBufferField& f : b.fields)
            fields.push_back(Json::object({{"name", f.name}, {"type", f.type}, {"offset", f.offset}}));
        buffers.push_back(Json::object({{"name", b.name},
                                        {"binding", b.binding},
                                        {"stride", b.stride},
                                        {"access", b.access},
                                        {"fields", fields}}));
    }
    Json images = Json::array();
    for (const MaterialImage& im : m.images)
        images.push_back(Json::object({{"name", im.name},
                                       {"binding", im.binding},
                                       {"format", im.format},
                                       {"access", im.access},
                                       {"width", im.width},
                                       {"height", im.height}}));
    Json out =
        Json::object({{"workgroupSize", Json::array({m.workgroupSize[0], m.workgroupSize[1], m.workgroupSize[2]})},
                      {"buffers", buffers}});
    if (!images.empty()) out["images"] = images;  // a material without images keeps the twin it always had
    return out;
}

}  // namespace shaders_detail

std::vector<std::string> shader_dialects_of_kind(const std::string& kind) {
    std::vector<std::string> out = shader_dialects();
    if (kind == "compute") std::erase(out, "glsl300es");
    return out;
}

std::vector<std::string> shader_platforms_of_kind(const std::string& kind) {
    std::vector<std::string> out = shader_platforms();
    if (kind == "compute") {
        std::erase(out, "android");
        std::erase(out, "web");
    }
    return out;
}

GeneratedShader generate_compute_shader(const MaterialDef& material, std::string_view snippetText) {
    GeneratedShader g;
    g.kind = "compute";
    const std::string src = shaders_detail::normalize_snippet(snippetText);
    g.hasCompute = shaders_detail::defines_compute_entry(shaders_detail::blank_comments(src));

    auto generated = [&](const std::string& text) {
        g.top += text;
        for (char c : text)
            if (c == '\n') g.snippetLine.push_back(0);
    };
    generated("@module fa_mat\n@block fa_user\n");
    // One uniform block (binding 0, the compute stage), the storage buffers from binding 0, the storage images, then the
    // textures: their views bind after the images (sokol numbers every view slot of a shader once) and their samplers from 0.
    if (!material.params.empty()) {
        std::string block = "layout(binding=0) uniform fa_material {\n";
        int pad = 0;
        for (const MaterialParam& p : material.params) {
            const int n = p.components();
            block += "    " + std::string(n == 1 ? "float" : "vec" + std::to_string(n)) + " " + p.name + ";";
            for (int i = n; i < 4; ++i) block += " float fa_pad" + std::to_string(pad++) + ";";
            block += "\n";
        }
        generated(block + "};\n");
    }
    for (const MaterialBuffer& b : material.buffers) {
        std::string s = "struct " + b.name + "_item {";
        for (const MaterialBufferField& f : b.fields) s += " " + f.type + " " + f.name + ";";
        s += " };\nlayout(binding=" + std::to_string(b.binding) + ")" + (b.access == "read" ? " readonly" : "") +
             " buffer fa_" + b.name + "_buf { " + b.name + "_item data[]; } " + b.name + ";\n";
        generated(s);
    }
    // A storage image is a view slot after the buffers (layout(binding) is the slot; sokol-shdc numbers the GLSL image units itself).
    for (const MaterialImage& im : material.images)
        generated("layout(binding=" + std::to_string(im.binding) + ", " + im.format + ")" + " uniform " +
                  (im.access == "write" ? "writeonly " : "") + "image2D " + im.name + ";\n");
    int view = int(material.buffers.size() + material.images.size()), sampler = 0;
    for (const MaterialTexture& tex : material.textures)
        generated("layout(binding=" + std::to_string(view++) + ") uniform texture2D " + tex.name +
                  ";\nlayout(binding=" + std::to_string(sampler++) + ") uniform sampler " + tex.name + "_smp;\n");
    generated("layout(local_size_x=" + std::to_string(material.workgroupSize[0]) +
              ", local_size_y=" + std::to_string(material.workgroupSize[1]) +
              ", local_size_z=" + std::to_string(material.workgroupSize[2]) + ") in;\n");
    // The snippet, line by line, remembering the lines.
    int line = 1;
    for (std::size_t i = 0; i < src.size();) {
        const std::size_t nl = src.find('\n', i);
        const std::size_t stop = nl == std::string::npos ? src.size() : nl;
        g.top.append(src, i, stop - i);
        g.top += '\n';
        g.snippetLine.push_back(line++);
        i = stop + 1;
    }
    generated("@end\n@include compute_common.glsl\n@program compute fa_cs\n");
    g.programs = {"compute"};
    return g;
}

}  // namespace fa
