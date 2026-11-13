// vector.to_rig (docs/VECTOR.md, "Characters in parts"): an SVG whose named groups are the parts of a character becomes one atlas
// of part pictures, the pivots of the joints and a prefab with a Sprite and a Bone2D per part in the hierarchy of the drawing, so
// rotating a part turns it (and its children) about its joint and the rest pose is the SVG as drawn.
//
// The steps: choose the parts (id'd groups, or `parts`), draw each part alone (the SVG with every other shape taken out, so the
// transforms and inherited styles of its groups still apply), trim and pad it, find its pivot (a marker, an
// override, the overlap with its parent, else the top centre), build the hierarchy (nesting, `data-parent`/`parents`, then the
// names), pack the atlas, write the prefab (merging into the one that is there), and check the result by compositing the prefab's
// sprites back and comparing with the SVG drawn whole.
#include <algorithm>
#include <cmath>
#include <format>
#include <functional>
#include <map>
#include <regex>
#include <set>
#include <sstream>
#include <sstream>

#include "assets_internal.h"
#include "assets_shots.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/style_guide.h"
#include "util.h"
#include "vector_ops.h"

namespace fa::assets_detail {

namespace {

using namespace fa::vec;

constexpr const char* kCommand = "vector.to_rig";
constexpr int kMaxSide = 4096;
constexpr int kTolerance = 8;  // the rest pose "matches" when no pixel differs by more than this (of 255)

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }
double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

std::string lower_id(const std::string& s) { return to_lower(s); }

bool ends_with_any(const std::string& id, std::string& base) {
    const std::string l = lower_id(id);
    for (const char* suffix : {"-pivot", "_pivot"})
        if (l.size() > std::strlen(suffix) &&
            l.compare(l.size() - std::strlen(suffix), std::string::npos, suffix) == 0) {
            base = id.substr(0, id.size() - std::strlen(suffix));
            return true;
        }
    return false;
}

// Ids an editor makes up (g1234, path-12, layer1): not names a person gave, so they do not make a part by themselves.
bool auto_id(const std::string& id) {
    static const std::regex re(
        "^(g|path|rect|circle|ellipse|layer|svg|use|polygon|line|polyline|text|image|defs|group)[-_]?[0-9]+$",
        std::regex::icase);
    return std::regex_match(id, re);
}

struct Pt {
    double x = 0, y = 0;
};

struct IRect {
    int x = 0, y = 0, w = 0, h = 0;
    bool empty() const { return w <= 0 || h <= 0; }
};

struct Part {
    XNode* node = nullptr;
    std::string id, name;
    int docIndex = 0;          // position of the group in the document, for the order
    std::vector<XNode*> own;   // the shapes drawn by this part itself (not by a child part)
    int firstShape = 1 << 30;  // index (among the drawable shapes of the document) of its first own shape
    int parent = -1;           // index in the parts
    std::string parentFrom;    // "nesting", "data-parent", "parents", "name"
    std::vector<int> kids;
    // the art
    bool hasArt = false;
    Image art;     // the padded region, straight alpha
    IRect box;     // the padded region in canvas pixels (may reach past the canvas)
    IRect ink;     // the tight box of the visible pixels
    Image mask;    // the whole canvas' alpha of the part, only kept while pivots are found (cropped to `ink`)
    IRect extent;  // ink, or for a group with no art of its own the union of its children's
    // joint
    Pt pivotPx, pivotSvg;
    std::string pivotFrom;
    Pt world;  // pivot in world units from the rig's origin
    double boneLength = 0;
    int layer = 0;
    IRect atlasRect;  // where the region sits in the atlas
    std::optional<double> minAngle, maxAngle;
    std::string file;  // the part's own picture (layout "files")
};

struct Geometry {
    vec::Rect canvas;       // viewBox
    double scale = 1;       // pixels per drawing unit as asked
    double k = 1;           // pixels per drawing unit as drawn
    double tx = 0, ty = 0;  // pixel offset of the viewBox corner
    int w = 0, h = 0;
    Pt to_px(Pt s) const { return {tx + (s.x - canvas.x0) * k, ty + (s.y - canvas.y0) * k}; }
    Pt to_svg(Pt p) const { return {canvas.x0 + (p.x - tx) / k, canvas.y0 + (p.y - ty) / k}; }
};

std::string names_list(const std::vector<std::string>& v, std::size_t max = 12) {
    std::string out;
    for (std::size_t i = 0; i < v.size() && i < max; ++i) out += (i ? ", " : "") + v[i];
    if (v.size() > max) out += std::format(", ... ({} more)", v.size() - max);
    return out;
}

std::string clean_name(const std::string& id) {
    std::string n = id;
    for (char& c : n)
        if (c == '/' || c == '\\') c = '_';
    return n;
}

Image crop_padded(const Image& src, const IRect& r) {
    Image out;
    out.width = r.w;
    out.height = r.h;
    out.rgba.assign(std::size_t(r.w) * r.h * 4, 0);
    for (int y = 0; y < r.h; ++y) {
        const int sy = r.y + y;
        if (sy < 0 || sy >= src.height) continue;
        for (int x = 0; x < r.w; ++x) {
            const int sx = r.x + x;
            if (sx < 0 || sx >= src.width) continue;
            std::copy_n(&src.rgba[(std::size_t(sy) * src.width + sx) * 4], 4,
                        &out.rgba[(std::size_t(y) * r.w + x) * 4]);
        }
    }
    return out;
}

// The box of the pixels with any alpha.
IRect ink_box(const Image& img) {
    int x0 = img.width, y0 = img.height, x1 = -1, y1 = -1;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (img.rgba[(std::size_t(y) * img.width + x) * 4 + 3] != 0) {
                x0 = std::min(x0, x);
                y0 = std::min(y0, y);
                x1 = std::max(x1, x);
                y1 = std::max(y1, y);
            }
    if (x1 < 0) return {};
    return {x0, y0, x1 - x0 + 1, y1 - y0 + 1};
}

// ---- the SVG ------------------------------------------------------------------------------------------------------------

// A fresh copy of the normalized SVG with the elements whose document index is in `drop` taken out.
std::string text_without(const std::string& text, const std::set<int>& drop) {
    SvgDoc doc = SvgDoc::parse(text, "the SVG");
    const std::vector<XNode*> all = doc.all_elements();
    for (int i : drop)
        if (i >= 0 && i < int(all.size())) doc.remove(all[std::size_t(i)]);
    return doc.write();
}

Image draw_svg(const std::string& text, const Geometry& g, std::vector<std::string>& warnings) {
    SvgRaster r = rasterize_svg_text(text, g.w, g.h, "none", 0.0, 0, warnings);
    return std::move(r.image);
}

std::string checked_rel(const char* key, const std::string& value, const std::string& ext, bool underAssets,
                        const std::string& example) {
    auto norm = fs::normalize_checked(value);
    if (!norm.ok() || norm->empty())
        arg_error(kCommand, std::string("/") + key, std::format("'{}' is not a project path.", value),
                  "Use a project-relative path such as \"" + example + "\".");
    if (underAssets && !starts_with(*norm, "assets/"))
        arg_error(kCommand, std::string("/") + key, std::format("'{}' is not under assets/.", *norm),
                  "Pictures go under assets/, e.g. \"" + example + "\".");
    if (!ends_with(to_lower(*norm), ext))
        arg_error(kCommand, std::string("/") + key, std::format("'{}' does not end in {}.", *norm, ext),
                  "Use a path such as \"" + example + "\".");
    return *norm;
}

Json num_array(double a, double b) { return Json::array({round3(a), round3(b)}); }

bool point_arg(const Json& v, Pt& out) {
    if (!v.is_array() || v.size() != 2 || !v[0].is_number() || !v[1].is_number()) return false;
    out = {v[0].get<double>(), v[1].get<double>()};
    return std::isfinite(out.x) && std::isfinite(out.y);
}

std::vector<std::string> split_tokens(const std::string& id) {
    std::vector<std::string> t;
    std::string cur;
    for (char c : to_lower(id)) {
        if (c == '_' || c == '-' || c == ' ' || c == '.') {
            if (!cur.empty()) t.push_back(cur);
            cur.clear();
        } else {
            cur += c;
        }
    }
    if (!cur.empty()) t.push_back(cur);
    return t;
}

std::string join_tokens(const std::vector<std::string>& t) {
    std::string out;
    for (const std::string& s : t) out += (out.empty() ? "" : "_") + s;
    return out;
}

// ---- the prefab ---------------------------------------------------------------------------------------------------------

struct OldEntity {
    Json* node = nullptr;
    Json* parent = nullptr;  // the entity it hangs from (null for the root)
};

void index_entities(Json& node, Json* parent, std::map<std::string, OldEntity>& out) {
    if (!node.is_object()) return;
    const std::string name = node.value("name", std::string());
    if (!name.empty() && !out.count(name)) out[name] = {&node, parent};
    if (node.contains("children") && node["children"].is_array())
        for (Json& c : node["children"]) index_entities(c, &node, out);
}

bool draws_rig_texture(const Json& node, const std::string& texturePrefix) {
    if (!node.is_object() || !node.contains("components") || !node["components"].is_object()) return false;
    const Json& comps = node["components"];
    if (!comps.contains("Sprite") || !comps["Sprite"].is_object()) return false;
    const std::string tex = comps["Sprite"].value("texture", std::string());
    return !tex.empty() && starts_with(tex, texturePrefix);
}

// Takes the entities that are parts of the new rig out of `node`'s subtree (they are placed by the new hierarchy), keeping what
// else the user hung there. A removed part (it draws this rig's texture and is not in the SVG any more) goes with `prune`; its own
// children stay, one level up.
void strip_moved(Json& node, const std::set<std::string>& newParts, const std::string& texturePrefix, bool prune,
                 std::vector<std::string>& pruned) {
    if (!node.contains("children") || !node["children"].is_array()) return;
    Json kept = Json::array();
    for (Json& c : node["children"]) {
        const std::string name = c.is_object() ? c.value("name", std::string()) : std::string();
        if (newParts.count(name)) {
            // its non-part children are moved with it by the caller; parts below it are placed by the hierarchy
            continue;
        }
        strip_moved(c, newParts, texturePrefix, prune, pruned);
        if (prune && draws_rig_texture(c, texturePrefix)) {
            pruned.push_back(name);
            if (c.contains("children") && c["children"].is_array())
                for (Json& gc : c["children"]) kept.push_back(std::move(gc));
            continue;
        }
        kept.push_back(std::move(c));
    }
    node["children"] = std::move(kept);
}

// The extra children (not parts) of the old entity `name`, ready to hang from the new one.
Json extras_of(const Json& oldNode, const std::set<std::string>& newParts, const std::string& texturePrefix, bool prune,
               std::vector<std::string>& pruned) {
    Json copy = oldNode;
    strip_moved(copy, newParts, texturePrefix, prune, pruned);
    if (copy.contains("children") && copy["children"].is_array()) return copy["children"];
    return Json::array();
}

// ---- the check ----------------------------------------------------------------------------------------------------------

struct Placed {
    const Json* node;
    double x, y;  // world position
};

void collect_sprites(const Json& node, double px, double py, const std::string& texturePrefix, std::vector<Placed>& out,
                     std::vector<std::string>& notes) {
    if (!node.is_object()) return;
    double x = px, y = py;
    if (node.contains("components") && node["components"].is_object() && node["components"].contains("Transform")) {
        const Json& t = node["components"]["Transform"];
        if (t.contains("position") && t["position"].is_array() && t["position"].size() >= 2) {
            x += t["position"][0].get<double>();
            y += t["position"][1].get<double>();
        }
        if (t.contains("rotation") && t["rotation"].is_array() && t["rotation"].size() >= 3 &&
            std::abs(t["rotation"][2].get<double>()) > 1e-6)
            notes.push_back(std::format("'{}' has a rotation in the prefab; the rest-pose check ignores it.",
                                        node.value("name", std::string())));
        if (t.contains("scale") && t["scale"].is_array() && t["scale"].size() >= 2 &&
            (std::abs(t["scale"][0].get<double>() - 1) > 1e-6 || std::abs(t["scale"][1].get<double>() - 1) > 1e-6))
            notes.push_back(std::format("'{}' has a scale in the prefab; the rest-pose check ignores it.",
                                        node.value("name", std::string())));
    }
    if (draws_rig_texture(node, texturePrefix)) out.push_back({&node, x, y});
    if (node.contains("children") && node["children"].is_array())
        for (const Json& c : node["children"]) collect_sprites(c, x, y, texturePrefix, out, notes);
}

struct Diff {
    int maxDiff = 0;
    long differing = 0;
    long total = 0;
};

Diff compare_premultiplied(const Image& a, const Image& b) {
    Diff d;
    const int w = std::min(a.width, b.width), h = std::min(a.height, b.height);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            const std::uint8_t* p = &a.rgba[(std::size_t(y) * a.width + x) * 4];
            const std::uint8_t* q = &b.rgba[(std::size_t(y) * b.width + x) * 4];
            int worst = std::abs(int(p[3]) - int(q[3]));
            for (int c = 0; c < 3; ++c)
                worst = std::max(worst, std::abs(int(p[c]) * p[3] / 255 - int(q[c]) * q[3] / 255));
            d.maxDiff = std::max(d.maxDiff, worst);
            if (worst > kTolerance) ++d.differing;
            ++d.total;
        }
    return d;
}

// `src` over `dst` (both straight alpha, `dst` may be transparent) at (x, y).
void over(Image& dst, const Image& src, int x0, int y0) {
    for (int y = 0; y < src.height; ++y) {
        const int dy = y0 + y;
        if (dy < 0 || dy >= dst.height) continue;
        for (int x = 0; x < src.width; ++x) {
            const int dx = x0 + x;
            if (dx < 0 || dx >= dst.width) continue;
            const std::uint8_t* s = &src.rgba[(std::size_t(y) * src.width + x) * 4];
            std::uint8_t* d = &dst.rgba[(std::size_t(dy) * dst.width + dx) * 4];
            const double sa = s[3] / 255.0, da = d[3] / 255.0, oa = sa + da * (1 - sa);
            if (oa <= 0) continue;
            for (int c = 0; c < 3; ++c)
                d[c] = std::uint8_t(std::clamp(std::lround((s[c] * sa + d[c] * da * (1 - sa)) / oa), 0L, 255L));
            d[3] = std::uint8_t(std::clamp(std::lround(oa * 255.0), 0L, 255L));
        }
    }
}

void cross(Image& img, int cx, int cy, int r, Rgb8 c) {
    for (int d = -r; d <= r; ++d) {
        for (const auto& [x, y] : {std::pair{cx + d, cy}, std::pair{cx, cy + d}}) {
            if (x < 0 || y < 0 || x >= img.width || y >= img.height) continue;
            std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
            p[0] = c.r;
            p[1] = c.g;
            p[2] = c.b;
            p[3] = 255;
        }
    }
}

// ---- the command --------------------------------------------------------------------------------------------------------

Json to_rig(const std::string& projectDir, const Json& a) {
    if (!a.is_object())
        fail("invalid_argument", "vector.to_rig expects an object.", "Example: {\"source\": \"assets/art/hero.svg\"}.");
    check_arg_keys(kCommand, a, "",
                   {"source",    "out",    "atlas",       "layout", "scale",  "pixelsPerUnit", "parts", "pivots",
                    "parents",   "naming", "padding",     "origin", "layer",  "name",          "prune", "pixelArt",
                    "overwrite", "dryRun", "previewSize", "ai",     "author", "license"});
    if (!a.contains("source") || !a["source"].is_string())
        arg_error(kCommand, "/source", "`source` is required: the project .svg whose groups are the parts.",
                  "Example: {\"source\": \"assets/art/hero.svg\"}.");
    const std::string sourceRel =
        checked_rel("source", a["source"].get<std::string>(), ".svg", false, "assets/art/hero.svg");
    const std::string stem = safe_file_name(fs::stem(sourceRel), "rig");
    const std::string layout = [&] {
        const std::string v = a.value("layout", std::string("atlas"));
        if (v != "atlas" && v != "files")
            arg_error(kCommand, "/layout", std::format("`layout` must be \"atlas\" or \"files\", got \"{}\".", v),
                      "atlas: one picture with a region per part (default). files: one picture per part.");
        return v;
    }();
    const bool atlasMode = layout == "atlas";
    const std::string prefabRel = checked_rel("out", a.value("out", "prefabs/" + stem + ".prefab.json"), ".prefab.json",
                                              false, "prefabs/hero.prefab.json");
    const std::string atlasRel = atlasMode ? checked_rel("atlas", a.value("atlas", "assets/art/" + stem + "_parts.png"),
                                                         ".png", true, "assets/art/hero_parts.png")
                                           : std::string();
    const std::string filesDir = atlasMode ? std::string() : [&] {
        std::string d = a.contains("atlas") ? a["atlas"].get<std::string>() : "assets/art/" + stem + "_parts";
        while (!d.empty() && (d.back() == '/' || d.back() == '\\')) d.pop_back();
        auto norm = fs::normalize_checked(d);
        if (!norm.ok() || norm->empty() || !starts_with(*norm, "assets/"))
            arg_error(
                kCommand, "/atlas",
                std::format(
                    "with layout \"files\" `atlas` is the folder of the part pictures, under assets/; '{}' is not.", d),
                "Example: \"assets/art/hero_parts\".");
        return *norm;
    }();
    // every file this command writes is checked now, before the SVG is read: the prefab and the atlas (or the part pictures)
    // must be inside the project and outside .git and .factoria, for every caller
    (void)project_write_file(projectDir, prefabRel);
    (void)project_write_file(projectDir, atlasMode ? atlasRel : filesDir + "/part.png");
    const std::string texturePrefix = atlasMode ? atlasRel : filesDir + "/";
    const bool dryRun = tooling_detail::arg_bool(a, "dryRun", false);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);
    const bool prune = tooling_detail::arg_bool(a, "prune", false);
    const bool naming = tooling_detail::arg_bool(a, "naming", true);
    int previewSize = 512;
    if (a.contains("previewSize")) {
        if (!a["previewSize"].is_number_integer() || a["previewSize"].get<long long>() < 32 ||
            a["previewSize"].get<long long>() > 2048)
            arg_error(kCommand, "/previewSize", "expected a whole number from 32 to 2048.",
                      "The longer side of each half of the side-by-side picture.");
        previewSize = int(a["previewSize"].get<long long>());
    }
    auto number = [&](const char* key, double lo, double hi, double def) {
        auto it = a.find(key);
        if (it == a.end() || it->is_null()) return def;
        if (!it->is_number() || !(it->get<double>() >= lo) || !(it->get<double>() <= hi))
            arg_error(
                kCommand, std::string("/") + key,
                std::format("`{}` must be a number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), "");
        return it->get<double>();
    };

    require_usable_manifest(projectDir);
    const stdfs::path srcAbs = project_file(projectDir, sourceRel);
    auto srcText = tooling_detail::read_file(srcAbs);
    if (!srcText)
        fail("not_found", std::format("{} /source: '{}' does not exist or cannot be read.", kCommand, sourceRel),
             "Check the path (project-relative).");

    std::vector<std::string> warnings;
    SvgDoc doc = SvgDoc::parse(*srcText, sourceRel);
    {
        const std::vector<std::string> dw = document_warnings(doc);
        warnings.insert(warnings.end(), dw.begin(), dw.end());
    }

    // ---- the style, the sizes ----
    StyleGuide style;
    {
        ProjectRootGuard root(projectDir);
        StyleParse sp = load_style_guide();
        style = sp.guide;
    }
    Geometry g;
    g.canvas = doc.canvas();
    if (g.canvas.empty() || g.canvas.width() <= 0 || g.canvas.height() <= 0)
        fail("invalid_svg", std::format("{} /source: '{}' has no drawing size.", kCommand, sourceRel),
             "Give the <svg> a viewBox (viewBox=\"0 0 200 300\") or width and height.");
    const P declared = doc.declared_size();
    g.scale = number("scale", 0.01, 64, declared.x > 0 ? declared.x / g.canvas.width() : 1.0);
    const bool pixelArt =
        a.contains("pixelArt") ? tooling_detail::arg_bool(a, "pixelArt", false) : style.pixelArt.value_or(false);
    const double ppu = number("pixelsPerUnit", 0.01, 4096, style.texelsPerUnit.value_or(g.scale));
    const int padding = int(number("padding", 0, 16, pixelArt ? 1 : 2));
    const int layerBase = int(number("layer", -10000, 10000, 0));
    const double wpx = g.canvas.width() * g.scale, hpx = g.canvas.height() * g.scale;
    if (wpx > kMaxSide || hpx > kMaxSide)
        arg_error(
            kCommand, "/scale",
            std::format("at scale {} the drawing is {}x{} pixels, over the {} px limit.", g.scale, int(std::ceil(wpx)),
                        int(std::ceil(hpx)), kMaxSide),
            std::format("Lower `scale` to at most {:.3f}.", kMaxSide / std::max(g.canvas.width(), g.canvas.height())));
    g.w = std::max(1, int(std::lround(wpx)));
    g.h = std::max(1, int(std::lround(hpx)));
    {
        const double s2 = std::min(g.w / wpx, g.h / hpx);
        g.k = g.scale * s2;
        g.tx = (g.w - wpx * s2) * 0.5;
        g.ty = (g.h - hpx * s2) * 0.5;
    }

    // Origin of the rig in the drawing.
    Pt originSvg{g.canvas.x0 + g.canvas.width() / 2, g.canvas.y1};
    if (a.contains("origin") && !a["origin"].is_null()) {
        const Json& o = a["origin"];
        if (o.is_string()) {
            const std::string v = o.get<std::string>();
            if (v == "bottom-center") {
            } else if (v == "center")
                originSvg = {g.canvas.x0 + g.canvas.width() / 2, g.canvas.y0 + g.canvas.height() / 2};
            else if (v == "top-left")
                originSvg = {g.canvas.x0, g.canvas.y0};
            else
                arg_error(kCommand, "/origin", std::format("'{}' is not an origin.", v),
                          did_you_mean(v, std::vector<std::string>{"bottom-center", "center", "top-left"}) +
                              " Or a point [x, y] in the drawing.");
        } else if (!point_arg(o, originSvg)) {
            arg_error(kCommand, "/origin",
                      "expected \"bottom-center\", \"center\", \"top-left\" or a point [x, y] in the drawing.",
                      "Example: [100, 280] for the soles of the feet.");
        }
    }
    const Pt originPx = g.to_px(originSvg);

    // The SVG as it is drawn: an explicit viewBox and the size of the picture, nothing else changed.
    {
        std::ostringstream vb;
        vb << format_number(g.canvas.x0, 6) << " " << format_number(g.canvas.y0, 6) << " "
           << format_number(g.canvas.width(), 6) << " " << format_number(g.canvas.height(), 6);
        doc.root()->set_attr("viewBox", vb.str());
        doc.root()->set_attr("width", format_number(wpx, 6));
        doc.root()->set_attr("height", format_number(hpx, 6));
    }
    const std::string normText = doc.write();
    SvgDoc norm = SvgDoc::parse(normText, sourceRel);
    const std::vector<XNode*> allEls = norm.all_elements();
    std::map<const XNode*, int> docIndex;
    for (std::size_t i = 0; i < allEls.size(); ++i) docIndex[allEls[i]] = int(i);

    // ---- the parts ----
    std::vector<XNode*> partNodes;
    std::set<XNode*> partSet;
    const bool explicitParts = a.contains("parts") && !a["parts"].is_null();
    if (explicitParts) {
        const Json& pj = a["parts"];
        std::vector<std::string> refs;
        if (pj.is_string())
            refs.push_back(pj.get<std::string>());
        else if (pj.is_array()) {
            for (const Json& e : pj) {
                if (!e.is_string())
                    arg_error(kCommand, "/parts",
                              "every entry must be a string (an SVG id or a selector), got " + describe_json_value(e) +
                                  ".",
                              "Example: [\"torso\", \"arm_upper_l\"].");
                refs.push_back(e.get<std::string>());
            }
        } else {
            arg_error(kCommand, "/parts",
                      "expected an SVG id, a selector, or a list of them, got " + describe_json_value(pj) + ".",
                      "Example: [\"torso\", \"arm_upper_l\"].");
        }
        if (refs.empty())
            arg_error(kCommand, "/parts", "the list is empty.",
                      "Name the groups that are parts, or leave `parts` out to use every group with an id.");
        for (std::size_t i = 0; i < refs.size(); ++i)
            for (XNode* n : select_elements(norm, refs[i], kCommand, std::format("/parts/{}", i)))
                if (n != norm.root() && partSet.insert(n).second) partNodes.push_back(n);
    } else {
        std::function<void(XNode*, bool)> walk = [&](XNode* n, bool inside) {
            for (XNode* k : n->elements()) {
                if (in_inert_subtree(*k)) continue;
                const std::string* idp = k->attr("id");
                const std::string id = idp ? *idp : std::string();
                std::string base;
                const bool marker = !id.empty() && ends_with_any(id, base);
                const bool named = !id.empty() && !marker && id[0] != '_' && !auto_id(id);
                if (k->local() == "g") {
                    const bool layer = k->attr_or("inkscape:groupmode") == "layer";
                    if (named && !layer) {
                        partNodes.push_back(k);
                        partSet.insert(k);
                        walk(k, true);
                    } else {
                        walk(k, inside);
                    }
                } else if (is_shape_element(*k) && !inside && named) {
                    partNodes.push_back(k);
                    partSet.insert(k);
                } else if (is_group_element(*k)) {
                    walk(k, inside);
                }
            }
        };
        walk(norm.root(), false);
    }
    if (partNodes.empty())
        fail("not_found",
             explicitParts
                 ? std::format("{} /parts: nothing matched.", kCommand)
                 : std::format("{} /source: '{}' has no group with an id to make a part of.", kCommand, sourceRel),
             "Wrap each part of the character in a group with a name, <g id=\"arm_upper_l\">...</g> (ids an editor "
             "makes up, such as g123, do not count), or list the ids in `parts`. vector.info lists the ids.");
    std::sort(partNodes.begin(), partNodes.end(), [&](XNode* p, XNode* q) { return docIndex[p] < docIndex[q]; });

    std::vector<Part> parts(partNodes.size());
    std::map<std::string, int> byId;
    std::map<const XNode*, int> byNode;
    for (std::size_t i = 0; i < partNodes.size(); ++i) {
        Part& p = parts[i];
        p.node = partNodes[i];
        p.docIndex = docIndex[p.node];
        const std::string* id = p.node->attr("id");
        if (!id || id->empty())
            arg_error(kCommand, "/parts",
                      std::format("{} has no id, and a part is named by its id.", describe_element(*p.node)),
                      "Give the element an id in the SVG.");
        p.id = *id;
        p.name = clean_name(*id);
        byId[p.id] = int(i);
        byNode[p.node] = int(i);
    }
    {
        std::set<std::string> seen;
        for (Part& p : parts)
            if (!seen.insert(p.name).second)
                fail("invalid_argument", std::format("{} /parts: two parts would be called '{}'.", kCommand, p.name),
                     "Give the groups different ids.");
    }

    // The pivot markers: an element called <part>-pivot or <part>_pivot; it is not art.
    std::map<int, XNode*> marker;
    std::set<int> markerIndex;
    for (XNode* n : allEls) {
        const std::string* id = n->attr("id");
        std::string base;
        if (!id || !ends_with_any(*id, base)) continue;
        auto it = byId.find(base);
        if (it == byId.end()) continue;
        if (n == parts[std::size_t(it->second)].node) continue;
        if (!marker.count(it->second)) marker[it->second] = n;
        for (XNode* s : [&] {
                 std::vector<XNode*> v;
                 if (is_shape_element(*n))
                     v.push_back(n);
                 else
                     shapes_under(*n, v);
                 return v;
             }())
            markerIndex.insert(docIndex[s]);
    }

    // Who draws what.
    std::vector<XNode*> shapes;
    shapes_under(*norm.root(), shapes);
    std::vector<int> ownerOfShape(shapes.size(), -1);
    std::vector<std::string> unowned;
    for (std::size_t i = 0; i < shapes.size(); ++i) {
        if (markerIndex.count(docIndex[shapes[i]])) continue;
        int owner = -1;
        for (XNode* n = shapes[i]; n; n = n->parent) {
            auto it = byNode.find(n);
            if (it != byNode.end()) {
                owner = it->second;
                break;
            }
        }
        ownerOfShape[i] = owner;
        if (owner >= 0) {
            parts[std::size_t(owner)].own.push_back(shapes[i]);
            parts[std::size_t(owner)].firstShape = std::min(parts[std::size_t(owner)].firstShape, int(i));
        } else {
            const std::string* id = shapes[i]->attr("id");
            unowned.push_back(id && !id->empty() ? *id : describe_element(*shapes[i]));
        }
    }
    if (!unowned.empty())
        warnings.push_back(std::format("{} shape(s) belong to no part and are not in the rig: {}. Put them in a part's "
                                       "group, or add the group to `parts`.",
                                       unowned.size(), names_list(unowned)));
    {  // a part drawn on both sides of a child part cannot be one sprite
        for (std::size_t pi = 0; pi < parts.size(); ++pi) {
            int first = -1, last = -1;
            for (std::size_t i = 0; i < shapes.size(); ++i)
                if (ownerOfShape[i] == int(pi)) {
                    if (first < 0) first = int(i);
                    last = int(i);
                }
            for (int i = first; i >= 0 && i <= last; ++i)
                if (ownerOfShape[std::size_t(i)] != int(pi) && !markerIndex.count(docIndex[shapes[std::size_t(i)]])) {
                    const int other = ownerOfShape[std::size_t(i)];
                    warnings.push_back(
                        std::format("'{}' is drawn on both sides of {} in the SVG, but it is one sprite: it was drawn "
                                    "at the place of its first shape. Put the shapes on top in a group of their own.",
                                    parts[pi].id,
                                    other >= 0 ? "'" + parts[std::size_t(other)].id + "'"
                                               : std::string("a shape outside every part")));
                    break;
                }
        }
    }

    // ---- draw every part alone ----
    const std::string markersGone = [&] { return text_without(normText, markerIndex); }();
    std::vector<std::string> drawWarnings;
    const Image whole = draw_svg(markersGone, g, drawWarnings);
    for (std::size_t pi = 0; pi < parts.size(); ++pi) {
        Part& p = parts[pi];
        if (p.own.empty()) continue;
        std::set<int> drop;
        std::set<const XNode*> keep(p.own.begin(), p.own.end());
        for (XNode* s : shapes)
            if (!keep.count(s)) drop.insert(docIndex[s]);
        for (int mi : markerIndex) drop.insert(mi);
        const std::string text = text_without(normText, drop);
        std::vector<std::string> w;
        Image full;
        try {
            full = draw_svg(text, g, w);
        } catch (const CommandError&) {
            warnings.push_back(std::format("'{}' draws nothing the rasterizer can show (shapes with no fill and no "
                                           "stroke?), so it is a joint without a picture.",
                                           p.id));
            continue;
        }
        for (const std::string& x : w)
            if (std::find(drawWarnings.begin(), drawWarnings.end(), x) == drawWarnings.end()) drawWarnings.push_back(x);
        const IRect ink = ink_box(full);
        if (ink.empty()) {
            warnings.push_back(
                std::format("'{}' draws nothing inside the drawing, so it is a joint without a picture.", p.id));
            continue;
        }
        p.hasArt = true;
        p.ink = ink;
        p.box = {ink.x - padding, ink.y - padding, ink.w + 2 * padding, ink.h + 2 * padding};
        p.art = crop_padded(full, p.box);
        p.mask = crop_padded(full, ink);  // only the ink; used to find the overlap with the parent
        p.extent = ink;
    }
    for (const std::string& w : drawWarnings) warnings.push_back(w);
    // A part with no picture and nothing below it is not a joint of anything.
    std::vector<bool> alive(parts.size(), false);
    for (std::size_t i = 0; i < parts.size(); ++i) alive[i] = parts[i].hasArt;
    for (std::size_t i = 0; i < parts.size(); ++i)
        if (alive[i])
            for (XNode* n = parts[i].node->parent; n; n = n->parent) {
                auto it = byNode.find(n);
                if (it != byNode.end()) alive[std::size_t(it->second)] = true;
            }
    // A part named in `parts`/the SVG with no shapes of its own and no children with art disappears.
    {
        std::vector<std::string> dropped;
        for (std::size_t i = 0; i < parts.size(); ++i)
            if (!alive[i]) dropped.push_back(parts[i].id);
        if (!dropped.empty() && dropped.size() < parts.size() + 1)
            warnings.push_back(std::format("{} part(s) have no picture and no child with one, and were left out: {}.",
                                           dropped.size(), names_list(dropped)));
        if (dropped.size() == parts.size())
            fail("empty_result", std::format("{}: no part draws anything.", kCommand),
                 "The groups must contain shapes with a fill or a stroke inside the viewBox. vector.info lists them; "
                 "assets.rasterize_svg shows the whole drawing.");
    }
    // Compact the list of parts.
    {
        std::vector<Part> kept;
        std::vector<int> remap(parts.size(), -1);
        for (std::size_t i = 0; i < parts.size(); ++i)
            if (alive[i]) {
                remap[i] = int(kept.size());
                kept.push_back(std::move(parts[i]));
            }
        parts = std::move(kept);
        byId.clear();
        byNode.clear();
        for (std::size_t i = 0; i < parts.size(); ++i) {
            byId[parts[i].id] = int(i);
            byNode[parts[i].node] = int(i);
        }
        std::map<int, XNode*> m2;
        for (auto& [k, v] : marker)
            if (remap[std::size_t(k)] >= 0) m2[remap[std::size_t(k)]] = v;
        marker = std::move(m2);
    }

    // ---- hierarchy ----
    auto part_named = [&](const std::string& id, const char* pointer, const char* what) {
        auto it = byId.find(id);
        if (it == byId.end()) {
            std::vector<std::string> ids;
            for (const Part& p : parts) ids.push_back(p.id);
            arg_error(kCommand, pointer, std::format("'{}' is not a part ({}).", id, what),
                      did_you_mean(id, ids) + " Parts: " + names_list(ids) + ".");
        }
        return it->second;
    };
    for (std::size_t i = 0; i < parts.size(); ++i) {
        for (XNode* n = parts[i].node->parent; n; n = n->parent) {
            auto it = byNode.find(n);
            if (it != byNode.end()) {
                parts[i].parent = it->second;
                parts[i].parentFrom = "nesting";
                break;
            }
        }
    }
    for (std::size_t i = 0; i < parts.size(); ++i) {  // data-parent
        const std::string dp = parts[i].node->attr_or("data-parent");
        if (dp.empty()) continue;
        const int pi = part_named(dp, "/source", ("`data-parent` of '" + parts[i].id + "'").c_str());
        parts[i].parent = pi;
        parts[i].parentFrom = "data-parent";
    }
    if (a.contains("parents") && !a["parents"].is_null()) {
        if (!a["parents"].is_object())
            arg_error(
                kCommand, "/parents", "expected an object {part: parent}.",
                "Example: {\"hand_l\": \"arm_lower_l\", \"shadow\": \"\"} (an empty parent is the root of the rig).");
        for (auto it = a["parents"].begin(); it != a["parents"].end(); ++it) {
            const int ci = part_named(it.key(), ("/parents/" + it.key()).c_str(), "a key of `parents`");
            if (!it.value().is_string())
                arg_error(kCommand, "/parents/" + it.key(), "expected the id of the parent part, or \"\" for the root.",
                          "");
            const std::string pv = it.value().get<std::string>();
            parts[std::size_t(ci)].parent =
                pv.empty() ? -1 : part_named(pv, ("/parents/" + it.key()).c_str(), "the value in `parents`");
            parts[std::size_t(ci)].parentFrom = pv.empty() ? "parents (root)" : "parents";
        }
    }
    if (naming) {
        std::map<std::string, int> byTokens;
        for (std::size_t i = 0; i < parts.size(); ++i) byTokens[join_tokens(split_tokens(parts[i].id))] = int(i);
        for (std::size_t i = 0; i < parts.size(); ++i) {
            if (parts[i].parent >= 0 || !parts[i].parentFrom.empty()) continue;
            std::vector<std::string> t = split_tokens(parts[i].id);
            for (std::size_t k = 0; k < t.size(); ++k)
                if (t[k] == "lower") {
                    std::vector<std::string> u = t;
                    u[k] = "upper";
                    auto it = byTokens.find(join_tokens(u));
                    if (it != byTokens.end() && it->second != int(i)) {
                        parts[i].parent = it->second;
                        parts[i].parentFrom = "name";
                    }
                    break;
                }
        }
        std::vector<int> roots;
        for (std::size_t i = 0; i < parts.size(); ++i)
            if (parts[i].parent < 0 && parts[i].parentFrom.empty()) roots.push_back(int(i));
        static const std::set<std::string> kBody = {"root", "body", "torso", "trunk", "hips", "hip", "pelvis", "chest"};
        std::vector<int> candidates;
        for (int r : roots)
            if (kBody.count(lower_id(parts[std::size_t(r)].id))) candidates.push_back(r);
        if (candidates.size() == 1 && roots.size() > 1)
            for (int r : roots)
                if (r != candidates[0]) {
                    parts[std::size_t(r)].parent = candidates[0];
                    parts[std::size_t(r)].parentFrom = "name";
                }
    }
    for (std::size_t i = 0; i < parts.size(); ++i) {  // cycles
        int hops = 0;
        for (int p = parts[i].parent; p >= 0; p = parts[std::size_t(p)].parent)
            if (++hops > int(parts.size()))
                fail("invalid_argument",
                     std::format("{} /parents: '{}' ends up its own ancestor.", kCommand, parts[i].id),
                     "Check `parents` and the `data-parent` attributes: a part cannot hang from one of its own "
                     "children.");
    }
    for (std::size_t i = 0; i < parts.size(); ++i)
        if (parts[i].parent >= 0) parts[std::size_t(parts[i].parent)].kids.push_back(int(i));

    // ---- draw order ----
    {
        std::vector<int> order(parts.size());
        for (std::size_t i = 0; i < order.size(); ++i) order[i] = int(i);
        std::stable_sort(order.begin(), order.end(), [&](int p, int q) {
            const int fp =
                parts[std::size_t(p)].hasArt ? parts[std::size_t(p)].firstShape : parts[std::size_t(p)].docIndex;
            const int fq =
                parts[std::size_t(q)].hasArt ? parts[std::size_t(q)].firstShape : parts[std::size_t(q)].docIndex;
            return fp < fq;
        });
        for (std::size_t r = 0; r < order.size(); ++r) parts[std::size_t(order[r])].layer = layerBase + int(r);
    }
    // The extent of a group with no picture is the union of what is under it.
    std::function<void(int)> fill_extent = [&](int i) {
        Part& p = parts[std::size_t(i)];
        for (int k : p.kids) fill_extent(k);
        if (p.hasArt) return;
        int x0 = 1 << 30, y0 = 1 << 30, x1 = -(1 << 30), y1 = -(1 << 30);
        for (int k : p.kids) {
            const IRect& e = parts[std::size_t(k)].extent;
            if (e.empty()) continue;
            x0 = std::min(x0, e.x);
            y0 = std::min(y0, e.y);
            x1 = std::max(x1, e.x + e.w);
            y1 = std::max(y1, e.y + e.h);
        }
        if (x1 > x0) p.extent = {x0, y0, x1 - x0, y1 - y0};
    };
    for (std::size_t i = 0; i < parts.size(); ++i)
        if (parts[i].parent < 0) fill_extent(int(i));

    // ---- pivots ----
    std::map<std::string, Pt> overrides;
    if (a.contains("pivots") && !a["pivots"].is_null()) {
        if (!a["pivots"].is_object())
            arg_error(kCommand, "/pivots", "expected an object {part: [x, y]} in the drawing's coordinates.",
                      "Example: {\"arm_upper_l\": [120, 80]}.");
        for (auto it = a["pivots"].begin(); it != a["pivots"].end(); ++it) {
            part_named(it.key(), ("/pivots/" + it.key()).c_str(), "a key of `pivots`");
            Pt pt;
            if (!point_arg(it.value(), pt))
                arg_error(kCommand, "/pivots/" + it.key(), "expected a point [x, y] in the drawing (viewBox units).",
                          "Example: [120, 80].");
            overrides[it.key()] = pt;
        }
    }
    for (std::size_t i = 0; i < parts.size(); ++i) {
        Part& p = parts[i];
        auto angle_attr = [&](const char* name, std::optional<double>& out) {
            const std::string v = p.node->attr_or(name);
            if (v.empty()) return;
            char* end = nullptr;
            const double d = std::strtod(v.c_str(), &end);
            if (end == v.c_str() || !std::isfinite(d)) {
                warnings.push_back(std::format("'{}' has {}=\"{}\", which is not a number of degrees; it was ignored.",
                                               p.id, name, v));
                return;
            }
            out = d;
        };
        angle_attr("data-min-angle", p.minAngle);
        angle_attr("data-max-angle", p.maxAngle);
        if (p.minAngle && p.maxAngle && *p.minAngle > *p.maxAngle) {
            warnings.push_back(
                std::format("'{}': data-min-angle {} is above data-max-angle {}; the limits were ignored.", p.id,
                            *p.minAngle, *p.maxAngle));
            p.minAngle.reset();
            p.maxAngle.reset();
        }
        if (auto ov = overrides.find(p.id); ov != overrides.end()) {
            p.pivotSvg = ov->second;
            p.pivotFrom = "pivots";
        } else if (auto mk = marker.find(int(i)); mk != marker.end()) {
            vec::Rect r;
            std::string why;
            if (unit_bounds(*mk->second, false, r, why)) {
                p.pivotSvg = {r.center().x, r.center().y};
                p.pivotFrom = "marker";
            } else {
                warnings.push_back(
                    std::format("The pivot marker of '{}' ({}) cannot be measured ({}); a default pivot was used.",
                                p.id, describe_element(*mk->second), why));
            }
        }
        if (p.pivotFrom.empty()) {
            const std::string dp = p.node->attr_or("data-pivot");
            if (!dp.empty()) {
                std::string cleaned = dp;
                for (char& c : cleaned)
                    if (c == ',') c = ' ';
                std::istringstream in(cleaned);
                double x, y;
                if (in >> x >> y) {
                    p.pivotSvg = {x, y};
                    p.pivotFrom = "data-pivot";
                } else {
                    warnings.push_back(std::format(
                        "'{}' has data-pivot=\"{}\", which is not \"x y\" in the drawing; a default pivot was used.",
                        p.id, dp));
                }
            }
        }
        if (!p.pivotFrom.empty()) {
            p.pivotPx = g.to_px(p.pivotSvg);
            continue;
        }
        // The joint: where the part overlaps the nearest ancestor that has a picture.
        int anc = p.parent;
        while (anc >= 0 && !parts[std::size_t(anc)].hasArt) anc = parts[std::size_t(anc)].parent;
        bool found = false;
        if (anc >= 0 && p.hasArt) {
            const Part& q = parts[std::size_t(anc)];
            const int x0 = std::max(p.ink.x, q.ink.x), y0 = std::max(p.ink.y, q.ink.y);
            const int x1 = std::min(p.ink.x + p.ink.w, q.ink.x + q.ink.w),
                      y1 = std::min(p.ink.y + p.ink.h, q.ink.y + q.ink.h);
            double sx = 0, sy = 0, n = 0;
            for (int y = y0; y < y1; ++y)
                for (int x = x0; x < x1; ++x) {
                    const int pa = p.mask.rgba[(std::size_t(y - p.ink.y) * p.mask.width + (x - p.ink.x)) * 4 + 3];
                    const int qa = q.mask.rgba[(std::size_t(y - q.ink.y) * q.mask.width + (x - q.ink.x)) * 4 + 3];
                    if (pa >= 128 && qa >= 128) {
                        sx += x + 0.5;
                        sy += y + 0.5;
                        n += 1;
                    }
                }
            if (n > 0) {
                p.pivotPx = {sx / n, sy / n};
                // A long part (an arm, a leg) is jointed at one of its ends: the end nearer the contact, on its own axis.
                const double w = p.ink.w, h = p.ink.h;
                if (h >= 1.3 * w) {
                    const double top = p.ink.y, bottom = p.ink.y + p.ink.h;
                    p.pivotPx = {p.ink.x + w / 2,
                                 std::abs(p.pivotPx.y - top) <= std::abs(bottom - p.pivotPx.y) ? top : bottom};
                } else if (w >= 1.3 * h) {
                    const double left = p.ink.x, right = p.ink.x + p.ink.w;
                    p.pivotPx = {std::abs(p.pivotPx.x - left) <= std::abs(right - p.pivotPx.x) ? left : right,
                                 p.ink.y + h / 2};
                }
                p.pivotFrom = "overlap";
                found = true;
            }
        }
        if (!found) {
            const IRect e = p.extent;
            p.pivotPx = {e.x + e.w / 2.0, double(e.y)};
            p.pivotFrom = "default";
        }
        p.pivotSvg = g.to_svg(p.pivotPx);
    }
    for (Part& p : parts) {
        p.world = {(p.pivotPx.x - originPx.x) / ppu, -(p.pivotPx.y - originPx.y) / ppu};
        p.world.x = round4(p.world.x);
        p.world.y = round4(p.world.y);
    }
    {
        std::vector<std::string> guessed;
        for (const Part& p : parts)
            if (p.pivotFrom == "default" || p.pivotFrom == "overlap")
                guessed.push_back(p.id + " (" + p.pivotFrom + ")");
        if (!guessed.empty())
            warnings.push_back(
                std::format("The joints of {} were guessed. Look at the crosses in the picture; put a small shape with "
                            "the id <part>-pivot in the part's place in the SVG, or pass `pivots`, where one is off.",
                            names_list(guessed)));
    }

    // ---- bones ----
    for (std::size_t i = 0; i < parts.size(); ++i) {
        Part& p = parts[i];
        double best = 0;
        for (int k : p.kids) {
            const double dx = parts[std::size_t(k)].world.x - p.world.x, dy = parts[std::size_t(k)].world.y - p.world.y;
            best = std::max(best, std::sqrt(dx * dx + dy * dy));
        }
        if (p.kids.empty() || best <= 0) {
            const IRect e = p.extent;
            const double cx = e.x + e.w / 2.0, cy = e.y + e.h / 2.0;
            const double dist =
                std::sqrt((cx - p.pivotPx.x) * (cx - p.pivotPx.x) + (cy - p.pivotPx.y) * (cy - p.pivotPx.y));
            best = std::max(2 * dist, 0.5 * std::max(e.w, e.h)) / ppu;
        }
        p.boneLength = std::max(0.01, round4(best));
    }

    // ---- the atlas ----
    Image atlas;
    if (atlasMode) {
        std::vector<int> order;
        for (std::size_t i = 0; i < parts.size(); ++i)
            if (parts[i].hasArt) order.push_back(int(i));
        std::stable_sort(order.begin(), order.end(),
                         [&](int p, int q) { return parts[std::size_t(p)].box.h > parts[std::size_t(q)].box.h; });
        long area = 0;
        int widest = 0;
        for (int i : order) {
            area += long(parts[std::size_t(i)].box.w + 1) * (parts[std::size_t(i)].box.h + 1);
            widest = std::max(widest, parts[std::size_t(i)].box.w + 1);
        }
        int width = 64;
        while (width < widest || double(width) * width < double(area) * 1.15) width *= 2;
        width = std::min(width, kMaxSide);
        int x = 0, y = 0, rowH = 0, usedW = 0;
        for (int i : order) {
            Part& p = parts[std::size_t(i)];
            if (x + p.box.w > width) {
                x = 0;
                y += rowH + 1;
                rowH = 0;
            }
            p.atlasRect = {x, y, p.box.w, p.box.h};
            x += p.box.w + 1;
            rowH = std::max(rowH, p.box.h);
            usedW = std::max(usedW, x - 1);
        }
        const int height = y + rowH;
        if (usedW > kMaxSide || height > kMaxSide || usedW < 1)
            fail("invalid_argument",
                 std::format("{} : the parts do not fit one {}-pixel atlas ({}x{} needed).", kCommand, kMaxSide, usedW,
                             height),
                 "Lower `scale`, or use layout \"files\" for a picture per part.");
        atlas.width = usedW;
        atlas.height = height;
        atlas.rgba.assign(std::size_t(atlas.width) * atlas.height * 4, 0);
        for (int i : order) {
            const Part& p = parts[std::size_t(i)];
            for (int row = 0; row < p.art.height; ++row)
                std::copy_n(&p.art.rgba[std::size_t(row) * p.art.width * 4], std::size_t(p.art.width) * 4,
                            &atlas.rgba[(std::size_t(p.atlasRect.y + row) * atlas.width + p.atlasRect.x) * 4]);
        }
    } else {
        std::set<std::string> used;
        for (Part& p : parts) {
            if (!p.hasArt) continue;
            std::string base = safe_file_name(p.name, "part"), f = base;
            for (int n = 2; used.count(to_lower(f)); ++n) f = base + "-" + std::to_string(n);
            used.insert(to_lower(f));
            p.file = filesDir + "/" + f + ".png";
        }
    }

    // ---- the prefab ----
    const stdfs::path prefabAbs = project_write_file(projectDir, prefabRel);
    Json oldDoc;
    bool prefabExisted = false;
    if (auto t = tooling_detail::read_file(prefabAbs)) {
        prefabExisted = true;
        auto parsed = parse_json(*t, prefabRel);
        if (!parsed.ok() || !parsed->is_object() || !parsed->contains("entity") || !(*parsed)["entity"].is_object())
            fail("invalid_argument",
                 std::format("{} /out: '{}' exists and is not a prefab ({}).", kCommand, prefabRel,
                             parsed.ok() ? "no `entity` object" : parsed.error().message),
                 "Choose another `out`, or fix the file (docs.read ARCHITECTURE).");
        oldDoc = std::move(*parsed);
    }
    std::set<std::string> newNames;
    for (const Part& p : parts) newNames.insert(p.name);
    std::map<std::string, OldEntity> oldIndex;
    if (prefabExisted) index_entities(oldDoc["entity"], nullptr, oldIndex);
    std::vector<std::string> removedParts;
    if (prefabExisted) {
        bool managed = false;
        for (auto& [name, e] : oldIndex) {
            if (!draws_rig_texture(*e.node, texturePrefix)) continue;
            managed = true;
            if (!newNames.count(name)) removedParts.push_back(name);
        }
        if (!managed && !overwrite)
            fail("exists",
                 std::format("'{}' already exists and none of its entities draws {}.", prefabRel,
                             atlasMode ? "'" + atlasRel + "'" : "a picture of '" + filesDir + "/'"),
                 "Pass overwrite: true to merge the rig into it, or choose another `out`.");
    }
    std::vector<std::string> pruned;

    std::function<Json(int)> build = [&](int i) -> Json {
        const Part& p = parts[std::size_t(i)];
        Json node = Json::object();
        auto old = oldIndex.find(p.name);
        const bool existed = old != oldIndex.end();
        if (existed) node = *old->second.node;
        node["name"] = p.name;
        if (!node.contains("components") || !node["components"].is_object()) node["components"] = Json::object();
        Json& comps = node["components"];
        if (!comps.contains("Transform") || !comps["Transform"].is_object()) comps["Transform"] = Json::object();
        const Pt up = p.parent >= 0 ? parts[std::size_t(p.parent)].world : Pt{0, 0};
        comps["Transform"]["position"] = Json::array({round4(p.world.x - up.x), round4(p.world.y - up.y), 0});
        if (p.hasArt) {
            Json& s = comps["Sprite"];
            if (!s.is_object()) s = Json::object();
            s["texture"] = atlasMode ? atlasRel : p.file;
            if (atlasMode)
                s["region"] = Json::array({p.atlasRect.x, p.atlasRect.y, p.atlasRect.w, p.atlasRect.h});
            else
                s.erase("region");
            s["size"] = Json::array({round4(p.box.w / ppu), round4(p.box.h / ppu)});
            s["pivot"] = Json::array(
                {round4((p.pivotPx.x - p.box.x) / p.box.w), round4(1.0 - (p.pivotPx.y - p.box.y) / p.box.h)});
            s["layer"] = p.layer;
            s["pixelArt"] = pixelArt;
        } else if (comps.contains("Sprite") && draws_rig_texture(node, texturePrefix)) {
            comps.erase("Sprite");
        }
        Json& b = comps["Bone2D"];
        if (!b.is_object()) b = Json::object();
        b["length"] = p.boneLength;
        if (p.minAngle) b["minAngle"] = *p.minAngle;
        if (p.maxAngle) b["maxAngle"] = *p.maxAngle;
        // components in a stable order: Transform, Sprite, Bone2D, then what the user added
        Json ordered = Json::object();
        for (const char* k : {"Transform", "Sprite", "Bone2D"})
            if (comps.contains(k)) ordered[k] = comps[k];
        for (auto it = comps.begin(); it != comps.end(); ++it)
            if (!ordered.contains(it.key())) ordered[it.key()] = it.value();
        node["components"] = std::move(ordered);
        Json kids = Json::array();
        for (int k : p.kids) kids.push_back(build(k));
        if (existed) {
            Json extras = extras_of(*old->second.node, newNames, texturePrefix, prune, pruned);
            for (Json& e : extras) kids.push_back(std::move(e));
        }
        if (kids.empty())
            node.erase("children");
        else
            node["children"] = std::move(kids);
        // name first, as in every prefab
        Json out = Json::object();
        out["name"] = node["name"];
        for (auto it = node.begin(); it != node.end(); ++it)
            if (it.key() != "name") out[it.key()] = it.value();
        return out;
    };

    Json root = Json::object();
    std::string rootName = stem;
    if (prefabExisted) {
        root = oldDoc["entity"];
        rootName = root.value("name", rootName);
    }
    if (a.contains("name") && a["name"].is_string() && !a["name"].get<std::string>().empty())
        rootName = a["name"].get<std::string>();
    root["name"] = rootName;
    if (!root.contains("components") || !root["components"].is_object())
        root["components"] = Json::object({{"Transform", Json::object({{"position", Json::array({0, 0, 0})}})}});
    Json rootKids = Json::array();
    for (std::size_t i = 0; i < parts.size(); ++i)
        if (parts[i].parent < 0) rootKids.push_back(build(int(i)));
    if (prefabExisted) {
        Json extras = extras_of(oldDoc["entity"], newNames, texturePrefix, prune, pruned);
        for (Json& e : extras) rootKids.push_back(std::move(e));
    }
    {
        Json out = Json::object();
        out["name"] = root["name"];
        for (auto it = root.begin(); it != root.end(); ++it)
            if (it.key() != "name" && it.key() != "children") out[it.key()] = it.value();
        if (!rootKids.empty()) out["children"] = std::move(rootKids);
        root = std::move(out);
    }
    Json prefab = Json::object({{"format", "factoria.prefab/1"}, {"entity", root}});

    // What a re-run did to the names.
    Json added = Json::array();
    for (const Part& p : parts)
        if (prefabExisted && !oldIndex.count(p.name)) added.push_back(p.name);
    if (prefabExisted && !removedParts.empty()) {
        std::vector<std::string> newList(newNames.begin(), newNames.end());
        std::vector<std::string> notes;
        for (const std::string& r : removedParts) {
            std::string hint = did_you_mean(r, newList);
            notes.push_back(r + (hint.empty() ? "" : " (" + hint + ")"));
        }
        warnings.push_back(std::format("{} part(s) of the previous rig are not in the SVG any more: {}. {}",
                                       removedParts.size(), join(notes, ", "),
                                       prune ? "They were removed from the prefab."
                                             : "They are still in the prefab, drawing a stale region; pass prune: true "
                                               "to remove them, or rename the group back if it was renamed."));
        // clips that name them
        std::vector<std::string> clips;
        ProjectRootGuard clipRoot(projectDir);
        for (const std::string& f : fs::list(".", true, ".json")) {
            if (!ends_with(f, ".anim.json") || starts_with(f, ".") || starts_with(f, "build/") ||
                f.find("node_modules/") != std::string::npos)
                continue;
            auto text = tooling_detail::read_file(stdfs::path(projectDir) / f);
            if (!text) continue;
            auto clip = parse_json(*text, f);
            if (!clip.ok() || !clip->is_object() || !clip->contains("tracks") || !(*clip)["tracks"].is_array())
                continue;
            for (const Json& t : (*clip)["tracks"]) {
                const std::string path = t.is_object() ? t.value("path", std::string()) : std::string();
                std::set<std::string> segs;
                std::size_t pos = 0;
                while (pos <= path.size()) {
                    const std::size_t e = path.find('/', pos);
                    segs.insert(path.substr(pos, e == std::string::npos ? std::string::npos : e - pos));
                    if (e == std::string::npos) break;
                    pos = e + 1;
                }
                for (const std::string& r : removedParts)
                    if (segs.count(r)) {
                        const std::string line = f + " (" + r + ")";
                        if (std::find(clips.begin(), clips.end(), line) == clips.end()) clips.push_back(line);
                    }
            }
        }
        if (!clips.empty())
            warnings.push_back(std::format("Clips with tracks on a part that is gone, which will stop finding it: {}. "
                                           "Rename the track paths (anim.list shows them) or the group in the SVG.",
                                           names_list(clips)));
    }

    // ---- the rest pose against the SVG ----
    std::vector<Placed> placed;
    std::vector<std::string> notes;
    collect_sprites(prefab["entity"], 0, 0, texturePrefix, placed, notes);
    for (const std::string& n : notes)
        if (std::find(warnings.begin(), warnings.end(), n) == warnings.end()) warnings.push_back(n);
    std::stable_sort(placed.begin(), placed.end(), [](const Placed& p, const Placed& q) {
        return (*p.node)["components"]["Sprite"].value("layer", 0) <
               (*q.node)["components"]["Sprite"].value("layer", 0);
    });
    Image rebuilt;
    rebuilt.width = g.w;
    rebuilt.height = g.h;
    rebuilt.rgba.assign(std::size_t(g.w) * g.h * 4, 0);
    for (const Placed& pl : placed) {
        const Json& s = (*pl.node)["components"]["Sprite"];
        const std::string name = pl.node->value("name", std::string());
        const Part* part = nullptr;
        for (const Part& p : parts)
            if (p.name == name) part = &p;
        if (!part || !part->hasArt) continue;
        const Json& size = s["size"];
        const Json& pivot = s["pivot"];
        const double left = originPx.x + (pl.x - pivot[0].get<double>() * size[0].get<double>()) * ppu;
        const double top = originPx.y - (pl.y + (1.0 - pivot[1].get<double>()) * size[1].get<double>()) * ppu;
        over(rebuilt, part->art, int(std::lround(left)), int(std::lround(top)));
    }
    const Diff diff = compare_premultiplied(whole, rebuilt);
    const bool matches = diff.maxDiff <= kTolerance;
    if (!matches)
        warnings.push_back(std::format("The rig at rest differs from the SVG: up to {} of 255 at {} pixel(s). Look at "
                                       "the picture: shapes outside every part, a part drawn on both sides of another, "
                                       "or an effect (a mask or clip shared across parts) the parts cannot carry.",
                                       diff.maxDiff, diff.differing));

    // The picture: the SVG, then the rig, with the joints marked.
    const auto fit = [&](const Image& im) {
        const int longer = std::max(im.width, im.height);
        if (longer <= previewSize) return im;
        const double k = double(previewSize) / longer;
        return resize_area(im, std::max(1, int(std::lround(im.width * k))),
                           std::max(1, int(std::lround(im.height * k))));
    };
    Image left = whole, right = rebuilt;
    for (const Part& p : parts)
        cross(right, int(std::lround(p.pivotPx.x)), int(std::lround(p.pivotPx.y)), std::max(2, std::min(g.w, g.h) / 80),
              {230, 40, 40});
    Image lf = fit(left), rf = fit(right);
    const int gap = 8;
    Image side;
    side.width = lf.width + gap + rf.width;
    side.height = std::max(lf.height, rf.height);
    side.rgba.assign(std::size_t(side.width) * side.height * 4, 255);
    fill_rect_rgb(side, 0, 0, side.width, side.height, {140, 140, 140});
    draw_over(side, lf, 0, 0);
    draw_over(side, rf, lf.width + gap, 0);

    // ---- write ----
    Json provenance;
    std::string provenanceNote;
    const bool ai = tooling_detail::arg_bool(a, "ai", true);
    const std::string author = tooling_detail::arg_string(a, "author", false, ai ? "" : "factoria");
    const std::string license = tooling_detail::arg_string(a, "license", false, "CC0-1.0");
    Json recipeSet = Json::object();
    {
        Json args = recipe_args(a, {{"source", sourceRel},
                                    {"out", prefabRel},
                                    {"atlas", atlasMode ? Json(atlasRel) : Json(filesDir)},
                                    {"layout", layout},
                                    {"dryRun", Json()},
                                    {"previewSize", Json()}});
        provenance = Json::object(
            {{"origin", ai ? "generated" : "original"},
             {"ai", ai},
             {"kind", "image"},
             {"provider", "factoria vector.to_rig"},
             {"license", license},
             {"notes",
              std::format("A part of the rig '{}' ({} parts), drawn from the SVG '{}' at {} px per drawing unit.",
                          prefabRel, parts.size(), sourceRel, g.k)},
             {"date", assets::today()},
             {"source", sourceRel}});
        if (!author.empty()) provenance["author"] = author;
        recipeSet = args;
    }
    std::vector<std::string> written;
    if (!dryRun) {
        // never replace a picture a person made
        std::vector<std::string> pictures;
        if (atlasMode)
            pictures.push_back(atlasRel);
        else
            for (const Part& p : parts)
                if (p.hasArt) pictures.push_back(p.file);
        auto manifestText = tooling_detail::read_file(stdfs::path(projectDir) / assets::kManifestFile);
        Json manifest =
            manifestText ? parse_json(*manifestText, assets::kManifestFile).value_or(Json::object()) : Json::object();
        for (const std::string& pic : pictures) {
            if (!stdfs::exists(project_file(projectDir, pic))) continue;
            const Json entry =
                manifest.contains("assets") && manifest["assets"].is_object() && manifest["assets"].contains(pic)
                    ? manifest["assets"][pic]
                    : Json();
            const Json recipe = recipe_of(entry);
            if (!overwrite && (recipe.is_null() || recipe.value("command", std::string()) != kCommand))
                fail("exists", std::format("'{}' already exists and was not made by {}.", pic, kCommand),
                     "Pass overwrite: true to replace it, or choose another `atlas`.");
        }
        auto put_png = [&](const std::string& rel, const Image& img) {
            const std::vector<std::uint8_t> png = encode_png(img);
            std::string err;
            if (!tooling_detail::write_file(project_write_file(projectDir, rel),
                                            std::string_view(reinterpret_cast<const char*>(png.data()), png.size()),
                                            &err))
                fail("failed", err);
            written.push_back(rel);
        };
        if (atlasMode)
            put_png(atlasRel, atlas);
        else
            for (const Part& p : parts)
                if (p.hasArt) put_png(p.file, p.art);
        std::string err;
        if (!tooling_detail::write_file(prefabAbs, dump_scene_json(prefab), &err)) fail("failed", err);
        written.push_back(prefabRel);
        const Json recipe = make_recipe(projectDir, kCommand, recipeSet, {sourceRel});
        ProjectRootGuard rootGuard(projectDir);
        for (const std::string& pic : pictures) {
            Json prov = provenance;
            prov["recipe"] = recipe;
            auto r = assets::update_entry(pic, [&](Json& e) {
                e.erase("analysis");
                e.erase("sheet");
                e["provenance"] = prov;
            });
            if (!r.ok())
                fail("failed", "The rig was written, but assets.json was not updated: " + r.error().message,
                     r.error().hint);
        }
    }

    // ---- the result ----
    Json list = Json::array();
    for (const Part& p : parts) {
        Json e = Json::object({{"name", p.name}, {"id", p.id}});
        e["parent"] = p.parent >= 0 ? Json(parts[std::size_t(p.parent)].name) : Json(nullptr);
        if (!p.parentFrom.empty()) e["parentFrom"] = p.parentFrom;
        e["layer"] = p.layer;
        e["hasPicture"] = p.hasArt;
        e["pivot"] = num_array(p.pivotSvg.x, p.pivotSvg.y);
        e["pivotFrom"] = p.pivotFrom;
        e["position"] = Json::array({p.world.x, p.world.y});
        e["boneLength"] = p.boneLength;
        if (p.hasArt) {
            const Pt a0 = g.to_svg({double(p.ink.x), double(p.ink.y)}),
                     a1 = g.to_svg({double(p.ink.x + p.ink.w), double(p.ink.y + p.ink.h)});
            e["bounds"] = Json::array({round3(a0.x), round3(a0.y), round3(a1.x - a0.x), round3(a1.y - a0.y)});
            if (atlasMode)
                e["region"] = Json::array({p.atlasRect.x, p.atlasRect.y, p.atlasRect.w, p.atlasRect.h});
            else
                e["file"] = p.file;
            e["size"] = Json::array({round4(p.box.w / ppu), round4(p.box.h / ppu)});
        }
        list.push_back(std::move(e));
    }
    Json result = Json::object({{"prefab", prefabRel}, {"root", rootName}, {"parts", list}, {"layout", layout}});
    if (atlasMode)
        result["atlas"] = Json::object({{"path", atlasRel}, {"width", atlas.width}, {"height", atlas.height}});
    result["pixelsPerUnit"] = ppu;
    result["scale"] = round4(g.k);
    result["origin"] = num_array(originSvg.x, originSvg.y);
    result["pixelArt"] = pixelArt;
    result["restPose"] = Json::object({{"matches", matches},
                                       {"maxDifference", diff.maxDiff},
                                       {"differingPixels", diff.differing},
                                       {"tolerance", kTolerance}});
    result["status"] = !prefabExisted ? "created" : "updated";
    if (prefabExisted) {
        result["added"] = added;
        result["removed"] = Json(removedParts);
        if (!pruned.empty()) result["pruned"] = Json(pruned);
    }
    result["written"] = Json(written);
    if (dryRun) result["dryRun"] = true;
    result["$image"] = image_member(write_temporary_picture(projectDir, side, "rig"), true);
    if (!warnings.empty()) result["warnings"] = warnings;
    result["nextSteps"] = Json::array(
        {"The picture shows the SVG on the left and the rig at rest on the right, a red cross at each joint. Move a "
         "joint with a `<part>-pivot` shape in the SVG or `pivots`, then run this again: it updates the prefab in "
         "place.",
         "Rotate a part with Transform.rotation.z (a clip: anim.create_clip, then the Animator on the prefab's root "
         "entity); its children turn with it about the joint. anim.pose and anim.filmstrip show the poses."});
    return result;
}

}  // namespace

void register_vector_rig_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Turn an SVG whose named groups are the parts of a character into part pictures, joints and a "
                   "Bone2D prefab that animates in parts.";
    info.description =
        "Reads a project SVG and makes a character that animates in parts, with no other step. Every group "
        "with an id is a PART (a group nested in a group is a child part; ids an editor makes up, like g123, "
        "do not count; `parts` names the groups yourself). Each part is drawn alone (its own shapes only, "
        "with the transforms and styles of its groups), trimmed, padded and packed into ONE atlas picture "
        "(`layout: \"atlas\"`, default; \"files\" writes a picture per part). The prefab (default "
        "prefabs/<name>.prefab.json) has an entity per part, named by its id, in the hierarchy of the "
        "drawing, with a Sprite (region, size, pivot, layer from the SVG order, pixelArt from the style), a "
        "Transform at the joint and a Bone2D (length to the farthest child joint). Rotating a part "
        "(Transform.rotation.z, in a clip) turns it, and its children, about its joint. Example: "
        "{\"source\": \"assets/art/hero.svg\", \"pixelsPerUnit\": 4}. Docs: docs.read VECTOR (Characters in "
        "parts)." FA_COMMAND_DETAILS
        "JOINTS: a shape with the id <part>-pivot (or <part>_pivot) anywhere in the SVG marks the joint by "
        "its centre (it is not drawn); else `pivots` {part: [x, y]} in the drawing; else the `data-pivot=\"x "
        "y\"` attribute of the group; else the overlap with the nearest ancestor part that has a picture "
        "(its centre, moved to the nearer end of a long part such as an arm); else the top centre of the "
        "part. The result says which one was used (`pivotFrom`). HIERARCHY: nesting in the SVG, then the "
        "`data-parent` attribute and `parents` {part: parent, \"\" = root}, then names (`naming`): "
        "arm_lower_l hangs from arm_upper_l, and when one of root/body/torso/trunk/hips/pelvis/chest is left "
        "with no parent the other parentless parts hang from it. `data-min-angle` / `data-max-angle` on a "
        "group set Bone2D.minAngle / maxAngle. Running it again UPDATES the prefab in place: the entities "
        "keep their names and everything you added (an Animator, colliders, other children); only "
        "Transform.position, Sprite and Bone2D.length are rewritten, new parts are added, and parts that "
        "left the SVG are reported (with the clips that name them; `prune: true` removes them). Result: "
        "`parts` (parent, pivot, pivotFrom, bone length, region), the atlas, `restPose` {matches, "
        "maxDifference, differingPixels} from composing the prefab's sprites and comparing them with the SVG "
        "drawn whole, a side-by-side `$image` (SVG left, rig right with a cross at each joint) and "
        "`warnings`. The pictures get a provenance recipe in assets.json, so assets.regenerate and `factoria "
        "validate` find the rig stale when the SVG changes. SVG y points down, the engine's up: the prefab's "
        "y is flipped, and the rig's origin is the bottom centre of the drawing (`origin`).";
    const auto str = [](const char* d) { return Json::object({{"type", "string"}, {"description", d}}); };
    const auto num = [](const char* d, double lo, double hi) {
        return Json::object({{"type", "number"}, {"minimum", lo}, {"maximum", hi}, {"description", d}});
    };
    const auto boolean = [](const char* d, bool def) {
        return Json::object({{"type", "boolean"}, {"default", def}, {"description", d}});
    };
    const Json point = Json::object(
        {{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", 2}, {"maxItems", 2}});
    Json props = Json::object(
        {{"source", str("The project-relative .svg whose groups are the parts, e.g. \"assets/art/hero.svg\".")},
         {"out", str("The prefab to write or update, project-relative, ending in .prefab.json. Default prefabs/<name "
                     "of the svg>.prefab.json. An existing prefab is updated in place (it needs overwrite: true only "
                     "when none of its entities draws this rig's pictures).")},
         {"atlas", str("layout \"atlas\": the atlas picture, under assets/, ending in .png (default "
                       "assets/art/<name>_parts.png). layout \"files\": the folder of the part pictures (default "
                       "assets/art/<name>_parts).")},
         {"layout", Json::object({{"type", "string"},
                                  {"enum", Json::array({"atlas", "files"})},
                                  {"default", "atlas"},
                                  {"description", "atlas: one picture and a Sprite.region per part (one texture, fewer "
                                                  "draw calls). files: one picture per part."}})},
         {"scale", num("Pixels per drawing unit (viewBox unit) the parts are drawn at. Default: the size the SVG "
                       "declares over its viewBox (usually 1). More pixels = sharper parts.",
                       0.01, 64)},
         {"pixelsPerUnit",
          num("Texture pixels per world unit: the sprite and bone sizes are pixels / pixelsPerUnit. Default: the "
              "style's texelsPerUnit (assets.json), else `scale`, so one drawing unit is one world unit.",
              0.01, 4096)},
         {"parts",
          Json::object({{"description", "The groups (or shapes) that are parts: an SVG id, a selector or a list of "
                                        "them. Default: every group with an id (and every shape with an id that is "
                                        "outside all of them). A part nested in another is its child."},
                        {"oneOf", Json::array({Json::object({{"type", "string"}}),
                                               Json::object({{"type", "array"},
                                                             {"items", Json::object({{"type", "string"}})}})})}})},
         {"pivots",
          Json::object({{"type", "object"},
                        {"additionalProperties", point},
                        {"description", "Joints by part id, [x, y] in the drawing (viewBox units): {\"arm_upper_l\": "
                                        "[120, 80]}. They win over markers and guesses."}})},
         {"parents",
          Json::object({{"type", "object"},
                        {"additionalProperties", Json::object({{"type", "string"}})},
                        {"description", "Parent by part id, overriding the nesting and the names: {\"hand_l\": "
                                        "\"arm_lower_l\"}. \"\" makes the part a child of the rig's root."}})},
         {"naming", boolean("Use the names to complete the hierarchy: X_lower_Y under X_upper_Y, and a lone "
                            "root/body/torso/trunk/hips/pelvis/chest as the parent of the other parts that have none.",
                            true)},
         {"padding", Json::object({{"type", "integer"},
                                   {"minimum", 0},
                                   {"maximum", 16},
                                   {"description", "Transparent pixels around each part so filtering does not bleed "
                                                   "into the neighbour. Default 2 (1 for pixel art)."}})},
         {"origin",
          Json::object({{"description", "Where the rig's root sits in the drawing: \"bottom-center\" (default, the "
                                        "feet), \"center\", \"top-left\" or a point [x, y] in the drawing."},
                        {"oneOf", Json::array({Json::object({{"type", "string"}}), point})}})},
         {"layer",
          Json::object({{"type", "integer"},
                        {"default", 0},
                        {"description",
                         "Sprite.layer of the back-most part; the others follow the order of the SVG (+1 each)."}})},
         {"name", str("The name of the prefab's root entity (a prefab that exists keeps its own). Default: the name of "
                      "the svg.")},
         {"prune", boolean("Remove the entities of parts that are not in the SVG any more (they draw this rig's "
                           "pictures). Default false: they stay and a warning lists them.",
                           false)},
         {"pixelArt",
          boolean(
              "Sprite.pixelArt of the parts (nearest-neighbour filtering). Default: the style's pixelArt, else false.",
              false)},
         {"overwrite", boolean("Replace pictures not made by this command, and merge into a prefab that does not use "
                               "this rig's pictures.",
                               false)},
         {"dryRun", boolean("Compute everything and return the picture and the report; write nothing.", false)},
         {"previewSize", Json::object({{"type", "integer"},
                                       {"minimum", 32},
                                       {"maximum", 2048},
                                       {"default", 512},
                                       {"description", "The longer side of each half of the side-by-side picture."}})},
         {"ai",
          boolean(
              "Whether the SVG was written by an AI (the default); false for one a person drew, for the provenance.",
              true)},
         {"author", str("Who gets the credit in the provenance record.")},
         {"license", str("License of the pictures for the provenance record. Default CC0-1.0.")}});
    props["source"]["x-fa-path"] = "read";
    props["out"]["x-fa-path"] = "write";
    props["atlas"]["x-fa-path"] = "write";
    info.inputSchema = Json::object({{"type", "object"},
                                     {"required", Json::array({"source"})},
                                     {"additionalProperties", false},
                                     {"properties", props}});
    registry.add(info, [projectDir](const Json& args) { return to_rig(projectDir, args); });
    registry.declare_capabilities(kCommand, capability_sets::writes_project());
}

}  // namespace fa::assets_detail
