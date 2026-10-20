// assets.draw_icon: draws the game's icon (and the Android adaptive-icon foreground) from a short description of shapes and
// text, on the CPU, with no image provider. Every shape is a signed distance function, so edges are anti-aliased exactly
// and the output is identical on every machine.
#include <algorithm>
#include <cmath>
#include <format>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/render/fonts.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/export_settings.h"
#include "util.h"

namespace fa::assets_detail {

void arg_error(const char* command, const std::string& pointer, const std::string& what, const std::string& hint) {
    fail("invalid_argument", std::format("{} {}: {}", command, pointer.empty() ? "arguments" : pointer, what), hint);
}

void check_arg_keys(const char* command, const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed) {
    for (auto it = obj.begin(); it != obj.end(); ++it)
        if (std::find(allowed.begin(), allowed.end(), it.key()) == allowed.end())
            arg_error(command, pointer + "/" + it.key(), "unknown key '" + it.key() + "'.", did_you_mean(it.key(), allowed));
}

Color colour_arg(const char* command, const Json& v, const std::string& pointer) {
    Color c;
    std::string err;
    if (!json_to(v, c, &err)) arg_error(command, pointer, err, "Colours are \"#rrggbb\", \"#rrggbbaa\", a name like \"white\" or [r, g, b] in 0..1.");
    return c;
}

namespace {

constexpr int kIconSize = 1024;
constexpr int kForegroundSize = 432;                 // 108dp at xxxhdpi
constexpr double kSafeZone = 66.0 / 108.0;           // the part of the layer an adaptive icon always shows
constexpr double kSpace = 100.0;                     // the drawing space is 0..100 on both axes

struct Pt {
    double x, y;
};

struct Layer {
    std::string type;
    std::string pointer;  // "/layers/2", for messages
    double x = 0, y = 0, w = 0, h = 0, radius = 0, rx = 0, ry = 0, size = 0, outlineWidth = 2, softness = 0;
    std::vector<Pt> points;
    std::string text, font;
    Color fill{0, 0, 0, 0}, fillBottom{0, 0, 0, 0}, outline{0, 0, 0, 0};
    bool hasFill = false, hasGradient = false, hasOutline = false, inForeground = true;
};

struct Spec {
    std::string shape = "square";
    Color color{0, 0, 0, 1}, colorBottom{0, 0, 0, 1};
    bool gradient = false;
    std::vector<Layer> layers;
};

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) { arg_error("assets.draw_icon", pointer, what, hint); }

void check_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed) { check_arg_keys("assets.draw_icon", obj, pointer, allowed); }

double number(const Json& obj, const std::string& pointer, const char* key, bool required, double def = 0) {
    auto it = obj.find(key);
    if (it == obj.end()) {
        if (required) bad(pointer, std::string("missing '") + key + "'.", "Add a number: " + std::string(key) + " is in drawing units (0..100 across the icon).");
        return def;
    }
    if (!it->is_number()) bad(pointer + "/" + key, "expected a number.", "Write it as a plain number such as 12.5.");
    return it->get<double>();
}

Color colour(const Json& v, const std::string& pointer) { return colour_arg("assets.draw_icon", v, pointer); }

bool optional_colour(const Json& obj, const std::string& pointer, const char* key, Color& out) {
    auto it = obj.find(key);
    if (it == obj.end()) return false;
    out = colour(*it, pointer + "/" + key);
    return true;
}

Layer parse_layer(const Json& j, const std::string& pointer) {
    if (!j.is_object()) bad(pointer, "a layer is an object.", "Example: {\"type\":\"circle\",\"x\":50,\"y\":50,\"radius\":30,\"fill\":\"#ffcc44\"}.");
    static const std::vector<std::string> types = {"rect", "roundRect", "circle", "ellipse", "polygon", "text"};
    const auto t = j.find("type");
    if (t == j.end() || !t->is_string()) bad(pointer, "missing 'type'.", "Use one of: " + join(types, ", ") + ".");
    Layer l;
    l.type = t->get<std::string>();
    l.pointer = pointer;
    if (std::find(types.begin(), types.end(), l.type) == types.end())
        bad(pointer + "/type", "unknown layer type '" + l.type + "'.", did_you_mean(l.type, types));
    std::vector<std::string> allowed = {"type", "fill", "foreground"};
    if (l.type == "rect") allowed.insert(allowed.end(), {"x", "y", "w", "h"});
    if (l.type == "roundRect") allowed.insert(allowed.end(), {"x", "y", "w", "h", "radius"});
    if (l.type == "circle") allowed.insert(allowed.end(), {"x", "y", "radius"});
    if (l.type == "ellipse") allowed.insert(allowed.end(), {"x", "y", "rx", "ry"});
    if (l.type == "polygon") allowed.push_back("points");
    if (l.type == "text") allowed.insert(allowed.end(), {"x", "y", "size", "text", "font"});
    if (l.type != "text") allowed.insert(allowed.end(), {"fillBottom", "outline", "outlineWidth", "softness"});
    check_keys(j, pointer, allowed);
    if (l.type == "rect" || l.type == "roundRect") {
        l.x = number(j, pointer, "x", true);
        l.y = number(j, pointer, "y", true);
        l.w = number(j, pointer, "w", true);
        l.h = number(j, pointer, "h", true);
        l.radius = l.type == "roundRect" ? number(j, pointer, "radius", true) : 0;
    } else if (l.type == "circle") {
        l.x = number(j, pointer, "x", true);
        l.y = number(j, pointer, "y", true);
        l.rx = l.ry = number(j, pointer, "radius", true);
    } else if (l.type == "ellipse") {
        l.x = number(j, pointer, "x", true);
        l.y = number(j, pointer, "y", true);
        l.rx = number(j, pointer, "rx", true);
        l.ry = number(j, pointer, "ry", true);
    } else if (l.type == "polygon") {
        const auto p = j.find("points");
        if (p == j.end() || !p->is_array() || p->size() < 3)
            bad(pointer + "/points", "a polygon needs a 'points' list of at least 3 [x, y] pairs.", "Example: \"points\":[[10,10],[90,10],[50,80]].");
        for (std::size_t i = 0; i < p->size(); ++i) {
            const Json& q = (*p)[i];
            if (!q.is_array() || q.size() != 2 || !q[0].is_number() || !q[1].is_number())
                bad(pointer + "/points/" + std::to_string(i), "a point is [x, y] with two numbers.", "Example: [50, 20].");
            l.points.push_back({q[0].get<double>(), q[1].get<double>()});
        }
    } else {
        l.x = number(j, pointer, "x", true);
        l.y = number(j, pointer, "y", true);
        l.size = number(j, pointer, "size", true);
        if (l.size <= 0) bad(pointer + "/size", "must be above 0.", "The size is the height of the text's em in drawing units, e.g. 30.");
        const auto s = j.find("text");
        if (s == j.end() || !s->is_string() || s->get<std::string>().empty()) bad(pointer, "a text layer needs a non-empty 'text'.", "Example: \"text\":\"LK\".");
        l.text = s->get<std::string>();
        if (const auto f = j.find("font"); f != j.end()) {
            if (!f->is_string()) bad(pointer + "/font", "expected a string.", "A project .ttf path such as \"assets/fonts/My.ttf\", or leave it out for DejaVu Sans.");
            l.font = f->get<std::string>();
        }
    }
    l.hasFill = optional_colour(j, pointer, "fill", l.fill);
    l.hasGradient = optional_colour(j, pointer, "fillBottom", l.fillBottom);
    l.hasOutline = optional_colour(j, pointer, "outline", l.outline);
    if (l.hasGradient && !l.hasFill) bad(pointer + "/fillBottom", "a gradient needs 'fill' (its top colour) too.", "Add \"fill\".");
    if (l.type == "text" && !l.hasFill) bad(pointer, "a text layer needs a 'fill' colour.", "Example: \"fill\":\"#ffffff\".");
    if (l.type != "text" && !l.hasFill && !l.hasOutline) bad(pointer, "this layer draws nothing: it has neither 'fill' nor 'outline'.", "Add \"fill\" and/or \"outline\".");
    l.outlineWidth = number(j, pointer, "outlineWidth", false, 2);
    l.softness = number(j, pointer, "softness", false, 0);
    if (l.outlineWidth <= 0 || l.softness < 0) bad(pointer, "outlineWidth must be above 0 and softness 0 or more.", "Both are in drawing units.");
    if (const auto f = j.find("foreground"); f != j.end()) {
        if (!f->is_boolean()) bad(pointer + "/foreground", "expected true or false.", "false keeps this layer out of the Android foreground (backdrops).");
        l.inForeground = f->get<bool>();
    }
    return l;
}

Spec parse_spec(const Json& a) {
    check_keys(a, "", {"background", "layers", "path", "foreground"});
    Spec s;
    if (const auto b = a.find("background"); b != a.end()) {
        if (!b->is_object()) bad("/background", "expected an object.", "Example: {\"color\":\"#141428\",\"shape\":\"rounded\"}.");
        check_keys(*b, "/background", {"color", "colorBottom", "shape"});
        if (const auto sh = b->find("shape"); sh != b->end()) {
            static const std::vector<std::string> shapes = {"square", "rounded", "circle", "transparent"};
            s.shape = sh->is_string() ? sh->get<std::string>() : "";
            if (std::find(shapes.begin(), shapes.end(), s.shape) == shapes.end())
                bad("/background/shape", "unknown shape " + sh->dump() + ".", did_you_mean(s.shape, shapes));
        }
        if (const auto c = b->find("color"); c != b->end()) s.color = colour(*c, "/background/color");
        else if (s.shape != "transparent") bad("/background", "missing 'color'.", "Add \"color\":\"#rrggbb\", or \"shape\":\"transparent\".");
        s.gradient = optional_colour(*b, "/background", "colorBottom", s.colorBottom);
    } else {
        bad("/background", "missing 'background'.", "Example: \"background\":{\"color\":\"#141428\"}.");
    }
    const auto ls = a.find("layers");
    if (ls == a.end() || !ls->is_array()) bad("/layers", "missing 'layers' (a list, may be empty).", "Example: \"layers\":[{\"type\":\"circle\",\"x\":50,\"y\":50,\"radius\":30,\"fill\":\"#ffcc44\"}].");
    for (std::size_t i = 0; i < ls->size(); ++i) s.layers.push_back(parse_layer((*ls)[i], "/layers/" + std::to_string(i)));
    return s;
}

// ---- drawing ---------------------------------------------------------------------------------------------------

struct Canvas {
    int width, height;
    std::vector<float> px;  // straight (not premultiplied) RGBA
    explicit Canvas(int n) : Canvas(n, n) {}
    Canvas(int w, int h) : width(w), height(h), px(std::size_t(w) * h * 4, 0.0f) {}

    void over(int x, int y, const Color& c, float cover) {
        const float a = c.a * std::clamp(cover, 0.0f, 1.0f);
        if (a <= 0) return;
        float* p = &px[(std::size_t(y) * width + x) * 4];
        const float outA = a + p[3] * (1 - a);
        for (int i = 0; i < 3; ++i) p[i] = ((&c.r)[i] * a + p[i] * p[3] * (1 - a)) / outA;
        p[3] = outA;
    }
    Image image() const {
        Image img;
        img.width = width;
        img.height = height;
        img.rgba.resize(px.size());
        for (std::size_t i = 0; i < px.size(); ++i) img.rgba[i] = std::uint8_t(std::lround(std::clamp(px[i], 0.0f, 1.0f) * 255));
        return img;
    }
};

struct Mapping {
    double k, ox, oy;  // pixel = o + unit * k
};

double length(double x, double y) { return std::sqrt(x * x + y * y); }

// Distance from p to the segment ab.
double seg_distance(Pt p, Pt a, Pt b) {
    const double dx = b.x - a.x, dy = b.y - a.y, len2 = dx * dx + dy * dy;
    const double t = len2 > 0 ? std::clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / len2, 0.0, 1.0) : 0.0;
    return length(p.x - (a.x + t * dx), p.y - (a.y + t * dy));
}

// Signed distance to a shape in pixels: negative inside. `pts` is only for polygons.
struct Sdf {
    std::string type;
    double cx = 0, cy = 0, hx = 0, hy = 0, r = 0;  // box / ellipse
    std::vector<Pt> pts;

    double operator()(double px, double py) const {
        if (type == "polygon") {
            double best = 1e30;
            bool inside = false;
            for (std::size_t i = 0, j = pts.size() - 1; i < pts.size(); j = i++) {
                best = std::min(best, seg_distance({px, py}, pts[j], pts[i]));
                if ((pts[i].y > py) != (pts[j].y > py) && px < (pts[j].x - pts[i].x) * (py - pts[i].y) / (pts[j].y - pts[i].y) + pts[i].x)
                    inside = !inside;
            }
            return inside ? -best : best;
        }
        if (type == "ellipse") {  // an approximation that is exact for circles
            return (length((px - cx) / hx, (py - cy) / hy) - 1.0) * std::min(hx, hy);
        }
        const double qx = std::abs(px - cx) - (hx - r), qy = std::abs(py - cy) - (hy - r);
        return length(std::max(qx, 0.0), std::max(qy, 0.0)) + std::min(std::max(qx, qy), 0.0) - r;
    }
};

float coverage(double d, double soft) {
    if (soft <= 1.0) return float(std::clamp(0.5 - d, 0.0, 1.0));
    const double t = std::clamp(0.5 - d / (2 * soft), 0.0, 1.0);  // glow: a smooth fall-off over about 2*soft px
    return float(t * t * (3 - 2 * t));
}

Color mix(const Color& a, const Color& b, double t) {
    return {float(a.r + (b.r - a.r) * t), float(a.g + (b.g - a.g) * t), float(a.b + (b.b - a.b) * t), float(a.a + (b.a - a.a) * t)};
}

void draw_sdf(Canvas& c, const Sdf& sdf, const Mapping& m, const Layer& l, double x0, double y0, double x1, double y1) {
    const double soft = l.softness * m.k;
    const double ow = l.outlineWidth * m.k;
    const double pad = std::max(soft * 2, l.hasOutline ? ow : 0.0) + 2;
    const int ix0 = std::max(0, int(std::floor(x0 - pad))), iy0 = std::max(0, int(std::floor(y0 - pad)));
    const int ix1 = std::min(c.width - 1, int(std::ceil(x1 + pad))), iy1 = std::min(c.height - 1, int(std::ceil(y1 + pad)));
    for (int y = iy0; y <= iy1; ++y)
        for (int x = ix0; x <= ix1; ++x) {
            const double d = sdf(x + 0.5, y + 0.5);
            if (l.hasFill) {
                const Color col = l.hasGradient ? mix(l.fill, l.fillBottom, (y + 0.5) / c.height) : l.fill;
                c.over(x, y, col, coverage(d, soft));
            }
            if (l.hasOutline) c.over(x, y, l.outline, coverage(std::abs(d) - ow / 2, 0));
        }
}

void draw_layer(Canvas& c, const Layer& l, const Mapping& m, const std::string& pointer) {
    const auto X = [&](double v) { return m.ox + v * m.k; };
    const auto Y = [&](double v) { return m.oy + v * m.k; };
    if (l.type == "text") {
        auto bmp = rasterize_text(l.text, l.font, float(l.size * m.k));
        if (!bmp.ok()) bad(pointer + "/font", bmp.error().message, bmp.error().hint);
        const int left = int(std::lround(X(l.x) - bmp->width / 2.0)), top = int(std::lround(Y(l.y) - bmp->height / 2.0));
        for (int y = 0; y < bmp->height; ++y)
            for (int x = 0; x < bmp->width; ++x) {
                const int px = left + x, py = top + y;
                if (px >= 0 && py >= 0 && px < c.width && py < c.height)
                    c.over(px, py, l.fill, bmp->coverage[std::size_t(y) * bmp->width + x] / 255.0f);
            }
        return;
    }
    Sdf sdf;
    sdf.type = l.type;
    double x0, y0, x1, y1;
    if (l.type == "polygon") {
        x0 = y0 = 1e30;
        x1 = y1 = -1e30;
        for (const Pt& p : l.points) {
            sdf.pts.push_back({X(p.x), Y(p.y)});
            x0 = std::min(x0, sdf.pts.back().x);
            x1 = std::max(x1, sdf.pts.back().x);
            y0 = std::min(y0, sdf.pts.back().y);
            y1 = std::max(y1, sdf.pts.back().y);
        }
    } else if (l.type == "ellipse" || l.type == "circle") {
        sdf.type = "ellipse";
        sdf.cx = X(l.x);
        sdf.cy = Y(l.y);
        sdf.hx = std::max(l.rx * m.k, 1e-6);
        sdf.hy = std::max(l.ry * m.k, 1e-6);
        x0 = sdf.cx - sdf.hx; x1 = sdf.cx + sdf.hx; y0 = sdf.cy - sdf.hy; y1 = sdf.cy + sdf.hy;
    } else {  // box: x, y is the top-left corner
        sdf.hx = std::abs(l.w) * m.k / 2;
        sdf.hy = std::abs(l.h) * m.k / 2;
        sdf.cx = X(l.x) + (l.w * m.k) / 2;
        sdf.cy = Y(l.y) + (l.h * m.k) / 2;
        sdf.r = std::clamp(l.radius * m.k, 0.0, std::min(sdf.hx, sdf.hy));
        x0 = sdf.cx - sdf.hx; x1 = sdf.cx + sdf.hx; y0 = sdf.cy - sdf.hy; y1 = sdf.cy + sdf.hy;
    }
    draw_sdf(c, sdf, m, l, x0, y0, x1, y1);
}

Image render(const Spec& s, int size, const Mapping& m, bool foreground) {
    Canvas c(size);
    if (!foreground && s.shape != "transparent") {
        Layer bg;
        bg.hasFill = true;
        bg.fill = s.color;
        bg.fillBottom = s.colorBottom;
        bg.hasGradient = s.gradient;
        if (s.shape == "square") {  // fills the whole canvas, no edge fade at the border
            for (int y = 0; y < size; ++y)
                for (int x = 0; x < size; ++x)
                    c.over(x, y, s.gradient ? mix(s.color, s.colorBottom, (y + 0.5) / size) : s.color, 1.0f);
        } else {
            Sdf sdf;
            sdf.type = s.shape == "circle" ? "ellipse" : "box";
            sdf.cx = sdf.cy = sdf.hx = sdf.hy = size / 2.0;
            sdf.r = s.shape == "rounded" ? size * 0.22 : 0;
            draw_sdf(c, sdf, m, bg, 0, 0, size, size);
        }
    }
    for (const Layer& l : s.layers)
        if (!foreground || l.inForeground) draw_layer(c, l, m, l.pointer);
    return c.image();
}

std::string hex_of(const Color& c) {
    const auto b = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255)); };
    return std::format("#{:02x}{:02x}{:02x}", b(c.r), b(c.g), b(c.b));
}

void write_png_file(const std::string& projectDir, const std::string& rel, const Image& img) {
    bool opaque = true;
    for (std::size_t i = 3; i < img.rgba.size(); i += 4) opaque = opaque && img.rgba[i] == 255;
    const std::vector<std::uint8_t> png = opaque ? encode_png_rgb(img) : encode_png(img);
    std::string err;
    if (!tooling_detail::write_file(project_file(projectDir, rel), std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err))
        fail("failed", err);
    ProjectRootGuard root(projectDir);
    auto r = assets::update_entry(rel, [&](Json& e) {
        e.erase("analysis");
        e.erase("sheet");
        Json prov = Json::object({{"origin", "original"}, {"ai", false}, {"kind", "image"}, {"date", assets::today()},
                                  {"notes", "Drawn from shapes and text by assets.draw_icon."}});
        for (const char* key : {"license", "author"})  // what a person recorded for this file stays
            if (e.contains("provenance") && e["provenance"].contains(key)) prov[key] = e["provenance"][key];
        e["provenance"] = prov;
    });
    if (!r.ok()) fail("failed", "'" + rel + "' was written, but assets.json was not updated: " + r.error().message, r.error().hint);
}

std::string target_path(std::string p, const std::string& configured, const char* fallback) {
    if (p.empty()) p = configured.empty() ? fallback : configured;
    if (p.size() < 5 || !iequals(std::string_view(p).substr(p.size() - 4), ".png"))
        fail("invalid_argument", std::format("assets.draw_icon writes PNG files, but '{}' does not end in .png.", p), "Use a path like \"assets/icon.png\".");
    return p;
}

Json draw_icon(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.draw_icon expects an object.", "See the description of the command for the fields.");
    const Spec spec = parse_spec(a);
    std::string wantFg;
    bool noForeground = false;
    if (const auto f = a.find("foreground"); f != a.end()) {
        if (f->is_boolean() && !f->get<bool>()) noForeground = true;
        else if (f->is_string()) wantFg = f->get<std::string>();
        else fail("invalid_argument", "assets.draw_icon 'foreground' is a path or false.", "Example: \"foreground\":\"assets/icon_fg.png\", or false for no Android foreground.");
    }
    std::vector<std::string> warnings;
    ProjectExportSettings settings;
    const bool hasProject = std::filesystem::exists(std::filesystem::path(projectDir) / "factoria.json");
    if (hasProject) {
        auto loaded = load_export_settings(projectDir);
        if (loaded.ok()) settings = *loaded;
        else warnings.push_back("factoria.json was not updated: " + loaded.error().message);
    }
    const std::string iconPath = target_path(tooling_detail::arg_string(a, "path", false), settings.icon, "assets/icon.png");
    std::string fgPath;
    if (!noForeground) fgPath = target_path(wantFg, settings.android.adaptiveIcon.foreground, "assets/icon_fg.png");
    require_usable_manifest(projectDir);

    Image icon, fg;
    {
        ProjectRootGuard root(projectDir);  // a text layer's font file is read from the project
        icon = render(spec, kIconSize, {kIconSize / kSpace, 0, 0}, false);
        if (!noForeground) {
            const double k = kForegroundSize * kSafeZone / kSpace, off = kForegroundSize * (1 - kSafeZone) / 2;
            fg = render(spec, kForegroundSize, {k, off, off}, true);
        }
    }
    write_png_file(projectDir, iconPath, icon);
    Json result = Json::object({{"icon", iconPath}, {"iconSize", Json::array({kIconSize, kIconSize})}});
    if (!noForeground) {
        write_png_file(projectDir, fgPath, fg);
        result["foreground"] = fgPath;
        result["foregroundSize"] = Json::array({kForegroundSize, kForegroundSize});
    }

    Json next = Json::array();
    if (hasProject && warnings.empty()) {
        ProjectExportSettings upd = settings;
        bool changed = upd.icon.empty();
        if (changed) upd.icon = iconPath;
        if (!noForeground && upd.android.adaptiveIcon.foreground.empty()) {
            upd.android.adaptiveIcon.foreground = fgPath;
            changed = true;
        }
        if (changed) {
            auto saved = save_export_settings(projectDir, upd);
            if (saved.ok()) result["factoriaJsonUpdated"] = true;
            else warnings.push_back("factoria.json was not updated: " + saved.error().message);
        }
        if (!noForeground && spec.shape != "transparent" && upd.android.adaptiveIcon.background == "#FFFFFF")
            next.push_back("Android: set export.android.adaptiveIcon.background to \"" + hex_of(spec.color) + "\" so the adaptive icon sits on the same colour.");
    }
    next.push_back("Look at the PNGs before shipping; change the description and call assets.draw_icon again (it replaces the files).");
    result["nextSteps"] = next;
    if (!warnings.empty()) result["warnings"] = warnings;
    return result;
}

}  // namespace

// Title text as a transparent logo image, drawn with the same text rasterizer and Canvas as the icon's text layers: the
// largest size at which the text (and its outline) fits maxW x maxH, tightly cropped.
Image draw_title_logo(const std::string& text, const std::string& font, const Color& fill, const Color* outline, int maxW, int maxH) {
    auto ref = rasterize_text(text, font, 100.0f);
    if (!ref.ok()) fail("invalid_argument", "assets.draw_capsules logo text: " + ref.error().message, ref.error().hint);
    if (ref->width <= 0 || ref->height <= 0) fail("invalid_argument", "assets.draw_capsules logo text '" + text + "' has nothing to draw.", "Use a non-empty title.");
    const double fit = std::min(double(maxW) / ref->width, double(maxH) / ref->height) * (outline ? 0.9 : 1.0);
    const float em = float(std::max(4.0, 100.0 * fit));
    auto bmp = rasterize_text(text, font, em);
    if (!bmp.ok()) fail("invalid_argument", "assets.draw_capsules logo text: " + bmp.error().message, bmp.error().hint);
    const double ow = outline ? std::max(1.0, em * 0.05) : 0.0;
    const int pad = int(std::ceil(ow)) + 1;
    Canvas c(bmp->width + 2 * pad, bmp->height + 2 * pad);
    if (outline) {
        std::vector<float> ring(std::size_t(c.width) * c.height, 0.0f);  // widest coverage over the ring of offsets
        for (int k = 0; k < 24; ++k) {
            const int dx = int(std::lround(ow * std::cos(k * 6.2831853 / 24))), dy = int(std::lround(ow * std::sin(k * 6.2831853 / 24)));
            for (int y = 0; y < bmp->height; ++y)
                for (int x = 0; x < bmp->width; ++x) {
                    float& r = ring[std::size_t(y + pad + dy) * c.width + x + pad + dx];
                    r = std::max(r, bmp->coverage[std::size_t(y) * bmp->width + x] / 255.0f);
                }
        }
        for (int y = 0; y < c.height; ++y)
            for (int x = 0; x < c.width; ++x) c.over(x, y, *outline, ring[std::size_t(y) * c.width + x]);
    }
    for (int y = 0; y < bmp->height; ++y)
        for (int x = 0; x < bmp->width; ++x) c.over(x + pad, y + pad, fill, bmp->coverage[std::size_t(y) * bmp->width + x] / 255.0f);
    return c.image();
}

void register_draw_icon_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.draw_icon";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Draw the game's icon (1024x1024 PNG) and the Android adaptive-icon foreground from shapes and text, no image provider needed.";
    info.description =
        "Draws on the CPU (anti-aliased, identical everywhere, works headless): a background plus layers drawn in order. Writes "
        "the 1024x1024 icon at `path` (default: factoria.json `icon`, else assets/icon.png) and the Android adaptive-icon foreground "
        "(432x432, transparent; the 0..100 drawing box is scaled into the 66/108 safe zone, so nothing inside it is cropped) at "
        "`foreground` (default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png; false = skip). An icon or "
        "foreground path factoria.json does not name yet is added to it. Files are replaced; assets.json gets provenance "
        "origin \"original\", ai false.\n"
        "Drawing space: x and y run 0..100 across the icon, origin top-left, y down; sizes and radii are in the same units "
        "(shapes may reach outside 0..100: the icon crops them). Layer types: rect {x,y,w,h} (x,y = top-left), roundRect "
        "{x,y,w,h,radius}, circle {x,y,radius} (x,y = centre), ellipse {x,y,rx,ry}, polygon {points:[[x,y],...]} and text "
        "{text,x,y,size,font}: x,y = centre of the text, size = em height, font = a project .ttf (default DejaVu Sans), one "
        "line, no shaping. Shapes take fill and/or outline (colours \"#rrggbb\"[aa] or names), fillBottom (vertical gradient "
        "from fill at the top of the icon to fillBottom at its bottom), outlineWidth (default 2), softness (feathers the edge: "
        "glows). Text takes fill. foreground: false on a layer keeps it out of the Android foreground (backdrops such as a "
        "ground or arch; the adaptive icon has its own background colour). Unknown keys and types are errors with suggestions.\n"
        "Example: {\"background\":{\"color\":\"#141428\",\"shape\":\"rounded\"},\"layers\":[{\"type\":\"circle\",\"x\":50,"
        "\"y\":50,\"radius\":28,\"fill\":\"#ffcc44\",\"outline\":\"#ffffff\"},{\"type\":\"text\",\"text\":\"K\",\"x\":50,\"y\":50,"
        "\"size\":34,\"fill\":\"#141428\"}]}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["background","layers"],
      "properties":{
        "background":{"type":"object","description":"The icon's backdrop.","properties":{
          "color":{"type":"string","description":"Colour of the backdrop (\"#rrggbb\" or a name). Required unless shape is transparent."},
          "colorBottom":{"type":"string","description":"Optional: a vertical gradient from color at the top to this colour at the bottom."},
          "shape":{"type":"string","enum":["square","rounded","circle","transparent"],"description":"square (default; fills the whole canvas, what the stores want), rounded (corner radius 22 percent), circle, or transparent (no backdrop)."}}},
        "layers":{"type":"array","description":"Drawn in order, later on top. Each has a `type` (rect, roundRect, circle, ellipse, polygon, text) and the fields listed in the command description.","items":{"type":"object","properties":{
          "type":{"type":"string","enum":["rect","roundRect","circle","ellipse","polygon","text"],"description":"Which shape."},
          "x":{"type":"number","description":"rect/roundRect: left edge. circle/ellipse/text: centre. Drawing units, 0..100 across the icon."},
          "y":{"type":"number","description":"rect/roundRect: top edge. circle/ellipse/text: centre. Drawing units, y down."},
          "w":{"type":"number","description":"rect/roundRect: width."},
          "h":{"type":"number","description":"rect/roundRect: height."},
          "radius":{"type":"number","description":"roundRect: corner radius. circle: radius."},
          "rx":{"type":"number","description":"ellipse: horizontal radius."},
          "ry":{"type":"number","description":"ellipse: vertical radius."},
          "points":{"type":"array","description":"polygon: three or more [x, y] points.","items":{"type":"array","items":{"type":"number"}}},
          "text":{"type":"string","description":"text: the string to draw (one line)."},
          "size":{"type":"number","description":"text: height of the em in drawing units."},
          "font":{"type":"string","description":"text: a project .ttf/.otf path or \"builtin:pixel\"; default DejaVu Sans."},
          "fill":{"type":"string","description":"Fill colour; the text colour for text."},
          "fillBottom":{"type":"string","description":"Gradient: fill at the top of the icon fading to this at the bottom."},
          "outline":{"type":"string","description":"Outline colour (centred on the edge)."},
          "outlineWidth":{"type":"number","description":"Outline thickness in drawing units. Default 2."},
          "softness":{"type":"number","description":"Feather of the edge in drawing units (0 = crisp); for glows."},
          "foreground":{"type":"boolean","description":"false keeps this layer out of the Android foreground. Default true."}}}},
        "path":{"type":"string","description":"PNG to write the icon to. Default: factoria.json `icon`, else assets/icon.png."},
        "foreground":{"description":"PNG for the Android adaptive-icon foreground, or false to skip it. Default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png.","oneOf":[{"type":"string"},{"type":"boolean"}]}
      }})");
    registry.add(info, [projectDir](const Json& args) { return draw_icon(projectDir, args); });
}

}  // namespace fa::assets_detail
