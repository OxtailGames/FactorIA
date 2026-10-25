// assets.draw_capsules: store page images (capsules, heroes, screenshots, covers) at the size each store asks for, cut from
// one piece of key art with an optional logo. The key art is cover-cropped around a focal point; the logo (an image, or
// title text drawn by the rasterizer of assets.draw_icon) is placed by the rule of each asset.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/tooling/asset_capsules.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

using StoreAsset = fa::StoreAsset;
using LogoMode = fa::StoreLogo;

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) { arg_error("assets.draw_capsules", pointer, what, hint); }
void check_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed) { check_arg_keys("assets.draw_capsules", obj, pointer, allowed); }
Color colour(const Json& v, const std::string& pointer) { return colour_arg("assets.draw_capsules", v, pointer); }

// `over` composited onto `dst` with its top-left corner at (x, y); both straight (not premultiplied) RGBA8.
void composite(Image& dst, const Image& over, int x0, int y0) {
    for (int y = 0; y < over.height; ++y) {
        const int dy = y0 + y;
        if (dy < 0 || dy >= dst.height) continue;
        for (int x = 0; x < over.width; ++x) {
            const int dx = x0 + x;
            if (dx < 0 || dx >= dst.width) continue;
            const std::uint8_t* s = &over.rgba[(std::size_t(y) * over.width + x) * 4];
            std::uint8_t* d = &dst.rgba[(std::size_t(dy) * dst.width + dx) * 4];
            const float sa = s[3] / 255.0f, da = d[3] / 255.0f, oa = sa + da * (1 - sa);
            if (oa <= 0) continue;
            for (int i = 0; i < 3; ++i) d[i] = std::uint8_t(std::lround((s[i] * sa + d[i] * da * (1 - sa)) / oa));
            d[3] = std::uint8_t(std::lround(oa * 255));
        }
    }
}

// `src` cut to the w x h window that covers the picture (the larger of the two scale factors), centred on `focus` (0..1
// of the source, clamped so the window stays inside), then resampled to exactly w x h.
Image cover_crop(const Image& src, int w, int h, double fx, double fy) {
    const double scale = std::max(double(w) / src.width, double(h) / src.height);
    const int cw = std::min(src.width, std::max(1, int(std::lround(w / scale))));
    const int ch = std::min(src.height, std::max(1, int(std::lround(h / scale))));
    const int x0 = std::clamp(int(std::lround(fx * src.width - cw / 2.0)), 0, src.width - cw);
    const int y0 = std::clamp(int(std::lround(fy * src.height - ch / 2.0)), 0, src.height - ch);
    Image crop;
    crop.width = cw;
    crop.height = ch;
    crop.rgba.resize(std::size_t(cw) * ch * 4);
    for (int y = 0; y < ch; ++y)
        std::copy_n(&src.rgba[(std::size_t(y0 + y) * src.width + x0) * 4], std::size_t(cw) * 4, &crop.rgba[std::size_t(y) * cw * 4]);
    Image out = resize_image(crop, w, h);
    for (std::size_t i = 0; i < out.rgba.size(); i += 4) {  // the art is opaque: flatten what is not over black
        const unsigned a = out.rgba[i + 3];
        if (a != 255)
            for (int k = 0; k < 3; ++k) out.rgba[i + k] = std::uint8_t(out.rgba[i + k] * a / 255);
        out.rgba[i + 3] = 255;
    }
    return out;
}

struct Logo {
    bool present = false;
    bool isText = false;
    std::string text, font;
    Color fill{1, 1, 1, 1}, outline{0, 0, 0, 0.85f};
    bool hasOutline = true;
    Image image;  // when !isText
};

// The logo scaled into box w x h (keeping its aspect), as an image.
Image logo_for_box(const Logo& logo, int boxW, int boxH) {
    if (logo.isText) return draw_title_logo(logo.text, logo.font, logo.fill, logo.hasOutline ? &logo.outline : nullptr, boxW, boxH);
    const double s = std::min(double(boxW) / logo.image.width, double(boxH) / logo.image.height);
    return resize_image(logo.image, std::max(1, int(std::lround(logo.image.width * s))), std::max(1, int(std::lround(logo.image.height * s))));
}

// The margins of an image the logo stays out of, as fractions of its width (left, right) and height (top, bottom).
struct Margins {
    double left = 0.05, top = 0.05, right = 0.05, bottom = 0.05;
};

// How the logo is framed (logoAnchor, safeArea, focus): the arguments of draw_capsules that move it.
struct Framing {
    bool hasAnchor = false;
    double anchorX = 0.5, anchorY = 0.5;  // 0..1 over the safe area: the logo's edge touches the area's edge at 0 and 1
    bool hasSafe = false;
    Margins safeAll;                           // safeArea as one value or one set of sides: every capsule
    std::map<std::string, Margins> safeStore;  // safeArea per store (keys of store_ids())
    bool hasFocus = false;                     // `focus` was given: it also moves the logo when the art needs no crop
    double focusX = 0.5, focusY = 0.5;
};

// The safe area of an asset: what the arguments say, else 5% on every side and, for a Top asset, the bottom third that
// Microsoft overlays with text.
Margins safe_margins(const Framing& f, const std::string& storeId, const StoreAsset& a) {
    if (const auto it = f.safeStore.find(storeId); it != f.safeStore.end()) return it->second;
    if (f.hasSafe) return f.safeAll;
    Margins m;
    if (a.logo == LogoMode::Top) m.bottom = 1.0 / 3.0;
    return m;
}

Image render_asset(const Image& art, const Logo& logo, const StoreAsset& a, const std::string& storeId, int w, int h, const Framing& framing) {
    if (a.logo == LogoMode::Only) {  // a transparent PNG holding only the logo
        Image out;
        out.width = w;
        out.height = h;
        out.rgba.assign(std::size_t(w) * h * 4, 0);
        const Image l = logo_for_box(logo, int(w * a.widthFraction), int(h * a.heightFraction));
        composite(out, l, (w - l.width) / 2, (h - l.height) / 2);
        return out;
    }
    Image out = cover_crop(art, w, h, framing.focusX, framing.focusY);
    if (a.logo == LogoMode::None || !logo.present) return out;

    // The safe area: the logo fits inside it (its box is cut to the area) and is moved inside it.
    const Margins m = safe_margins(framing, storeId, a);
    const double sx = w * m.left, sy = h * m.top, sw = w * (1 - m.left - m.right), sh = h * (1 - m.top - m.bottom);
    const Image l = logo_for_box(logo, std::max(1, int(std::min(w * a.widthFraction, sw))), std::max(1, int(std::min(h * a.heightFraction, sh))));
    double x = (w - l.width) / 2.0, y = (h - l.height) / 2.0;
    switch (a.logo) {
        case LogoMode::Top: y = h * 0.30 - l.height / 2.0; break;  // the top two thirds: text overlays use the bottom third
        case LogoMode::Bottom: y = h * 0.92 - l.height; break;
        case LogoMode::BottomLeft: x = w * 0.05; y = h * 0.92 - l.height; break;
        default: break;
    }
    if (framing.hasAnchor) {
        x = sx + framing.anchorX * (sw - l.width);
        y = sy + framing.anchorY * (sh - l.height);
    }
    // `focus` decides the crop, and a crop of art with the capsule's own proportions has nothing to decide: there it moves the
    // logo instead, by how far the focus is from the middle (0.5, 0.5 leaves it where the rule or the anchor put it).
    const bool sameAspect = std::abs(double(art.width) / art.height / (double(w) / h) - 1.0) < 0.01;
    if (framing.hasFocus && sameAspect) {
        x += (framing.focusX - 0.5) * w;
        y += (framing.focusY - 0.5) * h;
    }
    x = std::clamp(x, sx, std::max(sx, sx + sw - l.width));
    y = std::clamp(y, sy, std::max(sy, sy + sh - l.height));
    composite(out, l, int(std::lround(x)), int(std::lround(y)));
    return out;
}

// logoAnchor: a name or a point [x, y] (0..1 over the safe area; the logo's edge touches the area's edge at 0 and 1).
void parse_logo_anchor(const Json& v, Framing& f) {
    static const std::vector<std::pair<std::string, std::pair<double, double>>> names = {
        {"center", {0.5, 0.5}}, {"top", {0.5, 0}}, {"bottom", {0.5, 1}}, {"left", {0, 0.5}}, {"right", {1, 0.5}},
        {"topLeft", {0, 0}}, {"topRight", {1, 0}}, {"bottomLeft", {0, 1}}, {"bottomRight", {1, 1}}};
    const std::string hint = "A name (center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight) or a point [x, y] of the "
                             "safe area: [0, 0] is its top-left corner, [1, 1] its bottom-right one, [0.5, 0.5] the middle.";
    f.hasAnchor = true;
    if (v.is_string()) {
        const std::string s = v.get<std::string>();
        for (const auto& [name, p] : names)
            if (s == name) {
                f.anchorX = p.first;
                f.anchorY = p.second;
                return;
            }
        std::vector<std::string> ids;
        for (const auto& n : names) ids.push_back(n.first);
        bad("/logoAnchor", "unknown anchor " + v.dump() + ".", did_you_mean(s, ids) + " " + hint);
    }
    if (!v.is_array() || v.size() != 2 || !v[0].is_number() || !v[1].is_number()) bad("/logoAnchor", "expected a name or [x, y].", hint);
    f.anchorX = v[0].get<double>();
    f.anchorY = v[1].get<double>();
    if (f.anchorX < 0 || f.anchorX > 1 || f.anchorY < 0 || f.anchorY > 1) bad("/logoAnchor", "x and y must be between 0 and 1.", hint);
}

Margins parse_margins(const Json& v, const std::string& pointer, const Margins& base) {
    const std::string hint = "A fraction of the image kept free of the logo: 0.05 on every side, or {\"left\":0.05,\"top\":0.05,\"right\":0.05,\"bottom\":0.3}.";
    Margins m = base;
    const auto check = [&](double x, const std::string& at) {
        if (x < 0 || x > 0.45) bad(at, "a margin must be between 0 and 0.45 (a fraction of the image).", hint);
        return x;
    };
    if (v.is_number()) {
        m.left = m.top = m.right = m.bottom = check(v.get<double>(), pointer);
        return m;
    }
    if (!v.is_object()) bad(pointer, "expected a number or {left, top, right, bottom}.", hint);
    check_keys(v, pointer, {"left", "top", "right", "bottom"});
    for (const auto& [key, field] : {std::pair<const char*, double Margins::*>{"left", &Margins::left}, {"top", &Margins::top},
                                     {"right", &Margins::right}, {"bottom", &Margins::bottom}})
        if (const auto it = v.find(key); it != v.end()) {
            if (!it->is_number()) bad(pointer + "/" + key, "expected a number.", hint);
            m.*field = check(it->get<double>(), pointer + "/" + key);
        }
    if (m.left + m.right >= 0.9 || m.top + m.bottom >= 0.9) bad(pointer, "the margins leave no room for the logo (two opposite sides must add up to less than 0.9).", hint);
    return m;
}

// safeArea: one value or one set of sides for every capsule, or {"default": ..., "<store>": ...} to differ per store.
void parse_safe_area(const Json& v, Framing& f) {
    const std::vector<std::string> sides = {"left", "top", "right", "bottom"};
    const bool perStore = v.is_object() && !v.empty() &&
                          std::none_of(sides.begin(), sides.end(), [&](const std::string& s) { return v.contains(s); });
    if (!perStore) {
        f.hasSafe = true;
        f.safeAll = parse_margins(v, "/safeArea", Margins{});
        return;
    }
    std::vector<std::string> allowed = store_ids();
    allowed.push_back("default");
    check_keys(v, "/safeArea", allowed);
    if (v.contains("default")) {
        f.hasSafe = true;
        f.safeAll = parse_margins(v["default"], "/safeArea/default", Margins{});
    }  // without "default" the stores it does not name keep each asset's own default
    for (auto it = v.begin(); it != v.end(); ++it)
        if (it.key() != "default") f.safeStore[it.key()] = parse_margins(it.value(), "/safeArea/" + it.key(), f.hasSafe ? f.safeAll : Margins{});
}

Json draw_capsules(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.draw_capsules expects an object.", "See the description of the command for the fields.");
    check_keys(a, "", {"keyArt", "focus", "logo", "logoAnchor", "safeArea", "stores", "name", "orientation", "overwrite"});

    const std::string keyArt = tooling_detail::arg_string(a, "keyArt", true);
    Framing framing;
    double& fx = framing.focusX;
    double& fy = framing.focusY;
    if (const auto f = a.find("focus"); f != a.end()) {
        framing.hasFocus = true;
        if (!f->is_array() || f->size() != 2 || !(*f)[0].is_number() || !(*f)[1].is_number())
            bad("/focus", "expected [x, y] with two numbers.", "The focal point as a fraction of the key art: [0.5, 0.5] is the middle, [0.2, 0.7] left and low.");
        fx = (*f)[0].get<double>();
        fy = (*f)[1].get<double>();
        if (fx < 0 || fx > 1 || fy < 0 || fy > 1) bad("/focus", "x and y must be between 0 and 1.", "Fractions of the image: [0, 0] top-left, [1, 1] bottom-right.");
    }
    if (const auto v = a.find("logoAnchor"); v != a.end()) parse_logo_anchor(*v, framing);
    if (const auto v = a.find("safeArea"); v != a.end()) parse_safe_area(*v, framing);
    bool portrait = false;
    if (const auto o = a.find("orientation"); o != a.end()) {
        const std::string v = o->is_string() ? o->get<std::string>() : "";
        if (v != "landscape" && v != "portrait") bad("/orientation", "expected \"landscape\" or \"portrait\".", "It turns the phone and tablet screenshot sizes of Google Play and the App Store; default landscape.");
        portrait = v == "portrait";
    }

    std::vector<std::string> stores;
    if (const auto s = a.find("stores"); s != a.end()) {
        if (!s->is_array()) bad("/stores", "expected a list of store names.", "Example: [\"steam\", \"itch\"]. Leave it out for all stores.");
        for (std::size_t i = 0; i < s->size(); ++i) {
            if (!(*s)[i].is_string() || !find_store_assets((*s)[i].get<std::string>()))
                bad("/stores/" + std::to_string(i), "unknown store " + (*s)[i].dump() + ".", did_you_mean((*s)[i].is_string() ? (*s)[i].get<std::string>() : "", store_ids()));
            stores.push_back((*s)[i].get<std::string>());
        }
    } else {
        stores = store_ids();
    }

    std::string name = tooling_detail::arg_string(a, "name", false);
    if (name.empty()) {
        if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / "factoria.json"))
            if (auto parsed = parse_json(*text, "factoria.json"); parsed.ok() && parsed->is_object() && parsed->value("name", std::string()).size())
                name = parsed->value("name", std::string());
    }
    name = safe_file_name(tooling_detail::slugify(name, '-'), "game");
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", true);

    Logo logo;
    ProjectRootGuard root(projectDir);  // a text logo's font file is read from the project
    if (const auto l = a.find("logo"); l != a.end()) {
        if (!l->is_object()) bad("/logo", "expected an object.", "Example: {\"text\":\"My Game\"} or {\"image\":\"assets/logo.png\"}.");
        check_keys(*l, "/logo", {"image", "text", "font", "fill", "outline"});
        const bool hasImage = l->contains("image"), hasText = l->contains("text");
        if (hasImage == hasText) bad("/logo", "give either 'image' (a transparent PNG) or 'text' (the title to draw), not both and not neither.", "Example: {\"text\":\"My Game\"}.");
        logo.present = true;
        if (hasImage) {
            if (!(*l)["image"].is_string()) bad("/logo/image", "expected a project path.", "Example: \"assets/logo.png\".");
            auto img = load_image(project_file(projectDir, (*l)["image"].get<std::string>()));
            if (!img.ok()) bad("/logo/image", img.error().message, "Use a PNG inside the project, ideally with a transparent background.");
            logo.image = std::move(*img);
        } else {
            if (!(*l)["text"].is_string() || (*l)["text"].get<std::string>().empty()) bad("/logo/text", "expected a non-empty string.", "The game's title, one line.");
            logo.isText = true;
            logo.text = (*l)["text"].get<std::string>();
            if (const auto f = l->find("font"); f != l->end()) {
                if (!f->is_string()) bad("/logo/font", "expected a string.", "A project .ttf path, or leave it out for DejaVu Sans.");
                logo.font = f->get<std::string>();
            }
            if (const auto f = l->find("fill"); f != l->end()) logo.fill = colour(*f, "/logo/fill");
            if (const auto f = l->find("outline"); f != l->end()) {
                if (f->is_boolean() && !f->get<bool>()) logo.hasOutline = false;
                else logo.outline = colour(*f, "/logo/outline");
            }
        }
    }

    auto art = load_image(project_file(projectDir, keyArt));
    if (!art.ok())
        bad("/keyArt", art.error().message, "Name an image inside the project, e.g. a screenshot: factoria run --headless --screenshot-at 60 --render-scale 1.5 --screenshot-pattern store/keyart.png.");
    if (art->width < 64 || art->height < 64) bad("/keyArt", "the image is only " + std::to_string(art->width) + "x" + std::to_string(art->height) + " px.", "Use key art of at least the size of the biggest asset you need (1920x1080 or more).");

    Json written = Json::array(), skipped = Json::array(), warnings = Json::array();
    for (const std::string& storeId : stores) {
        std::set<std::string> done;  // sizes already drawn for this store: several assets share a size and a rule
        std::vector<std::pair<std::string, Json>> entries;
        for (const StoreAsset& as : *find_store_assets(storeId)) {
            int w = as.width, h = as.height;
            if (portrait && as.deviceShot) std::swap(w, h);
            const std::string rel = std::format("store/capsules/{}/{}_{}x{}.png", storeId, name, w, h);
            if (as.logo == LogoMode::Only && !logo.present) {
                skipped.push_back(Json::object({{"store", storeId}, {"asset", as.asset}, {"reason", "it is only the logo and no logo was given"}}));
                continue;
            }
            if (!done.insert(rel).second) {
                for (auto& [path, e] : entries)
                    if (path == rel) e["assets"].push_back(as.asset);
                continue;
            }
            const stdfs::path file = project_file(projectDir, rel);
            if (!overwrite && stdfs::exists(file)) {
                skipped.push_back(Json::object({{"store", storeId}, {"asset", as.asset}, {"reason", rel + " exists and overwrite is false"}}));
                continue;
            }
            const Image img = render_asset(*art, logo, as, storeId, w, h, framing);
            bool opaque = true;
            for (std::size_t i = 3; i < img.rgba.size() && opaque; i += 4) opaque = img.rgba[i] == 255;
            const std::vector<std::uint8_t> png = opaque ? encode_png_rgb(img) : encode_png(img);
            std::string err;
            if (!tooling_detail::write_file(file, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err)) fail("failed", err);
            entries.push_back({rel, Json::object({{"store", storeId}, {"assets", Json::array({as.asset})}, {"path", rel},
                                                  {"size", Json::array({w, h})}, {"logo", as.logo != LogoMode::None && as.logo != LogoMode::Only && logo.present}})});
            if (!as.verified) entries.back().second["sizeNote"] = "unverified: the store does not publish this size openly (see docs/EXPORTING.md#store-page-material)";
        }
        for (auto& [path, e] : entries) written.push_back(std::move(e));
    }

    Json result = Json::object({{"written", written}, {"count", written.size()}});
    if (!skipped.empty()) result["skipped"] = skipped;
    Json next = Json::array();
    if (!logo.present) next.push_back("No logo was given: the capsules are the bare art and the logo-only assets (Steam library logo, Epic logo) were skipped. Pass logo {text} or {image}.");
    next.push_back("Look at the PNGs before uploading; change focus or the logo and call assets.draw_capsules again (it replaces the files). Screenshots for the store page are not capsules: take them with game.screenshot {scale} or factoria run --render-scale.");
    result["nextSteps"] = next;
    return result;
}

}  // namespace

void register_draw_capsules_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.draw_capsules";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo.";
    info.description =
        "Cover-crops `keyArt` (an image in the project, e.g. a screenshot taken with game.screenshot {scale}) around `focus` to "
        "every image size the `stores` ask for and writes store/capsules/<store>/<name>_<w>x<h>.png (folders are created, files "
        "replaced). Stores: steam, epic, gog, microsoft, googleplay, appstore, itch (default: all). The sizes are in one table "
        "(docs/EXPORTING.md#store-page-material, as of 2026-10); assets with the same size in one store are one file.\n"
        "The `logo` is placed by the rule of each asset: capsules and covers get it centred (Microsoft: in the upper part, the "
        "bottom third is overlaid; Steam library capsule: low), heroes, page backgrounds and screenshots get none (Steam's "
        "library hero must have no text), and the logo-only assets (Steam library logo 1280x720, Epic logo 960x540) are a "
        "transparent PNG with just the logo. `logo` is {\"image\": \"assets/logo.png\"} (transparent PNG) or {\"text\": \"My "
        "Game\", font, fill, outline} (title drawn like assets.draw_icon draws text; fill default white, outline default a dark "
        "one, false = none). Without a logo the art is cut without one and the logo-only assets are skipped.\n"
        "`safeArea` is the margin the logo keeps from the edges, as fractions of the image (default 0.05 on every side, and the "
        "bottom third on the Microsoft poster and box art, which the store overlays with text): a number, {left, top, right, "
        "bottom}, or {default, steam, ...} per store. The logo is cut to fit inside it and never leaves it. `logoAnchor` puts the "
        "logo somewhere else than the asset's rule does: center, top, bottom, left, right, topLeft, topRight, bottomLeft, "
        "bottomRight, or a point [x, y] of the safe area ([0, 0] its top-left corner, [1, 1] the bottom-right one). When the art "
        "already has the capsule's proportions (within 1%) the crop has nothing to choose, so a given `focus` moves the logo "
        "instead, by its distance from [0.5, 0.5] (0.2 of the width left of the middle moves it 0.3 of the width left), still "
        "inside the safe area.\n"
        "`orientation` (landscape, default; or portrait) turns the phone and tablet screenshot sizes of Google Play and the "
        "App Store. Capsules are not the store screenshots: take those at the stores' sizes with `--render-scale` (a 1280x720 "
        "game at 1.5 gives 1920x1080).\n"
        "Example: {\"keyArt\":\"store/keyart.png\",\"focus\":[0.5,0.4],\"logo\":{\"text\":\"Lantern Keep\"},\"stores\":[\"steam\"]}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["keyArt"],
      "properties":{
        "keyArt":{"type":"string","description":"The art to cut the capsules from: a project image path, 1920x1080 or bigger is best (a screenshot taken with --render-scale)."},
        "focus":{"type":"array","items":{"type":"number","minimum":0,"maximum":1},"minItems":2,"maxItems":2,"description":"The point of the art that must stay in view when it is cropped, as fractions [x, y]. Default [0.5, 0.5]."},
        "logo":{"type":"object","description":"The logo: give image or text.","properties":{
          "image":{"type":"string","description":"A project PNG, ideally with a transparent background."},
          "text":{"type":"string","description":"The title to draw, one line."},
          "font":{"type":"string","description":"text: a project .ttf path or \"builtin:pixel\"; default DejaVu Sans."},
          "fill":{"type":"string","description":"text: colour of the letters. Default white."},
          "outline":{"description":"text: outline colour (default a dark one), or false for none.","oneOf":[{"type":"string"},{"type":"boolean"}]}}},
        "logoAnchor":{"description":"Where the logo sits in the safe area instead of the asset's own rule: a name or a point [x, y] (0..1; [0, 0] touches the top-left corner of the safe area).","oneOf":[{"type":"string","enum":["center","top","bottom","left","right","topLeft","topRight","bottomLeft","bottomRight"]},{"type":"array","items":{"type":"number","minimum":0,"maximum":1},"minItems":2,"maxItems":2}]},
        "safeArea":{"description":"Margins the logo stays inside, as fractions of the image (0..0.45): a number for all sides, {left, top, right, bottom}, or per store {default, steam, epic, ...} each of those. Default 0.05, and the bottom third of the Microsoft poster and box art.","oneOf":[{"type":"number","minimum":0,"maximum":0.45},{"type":"object"}]},
        "stores":{"type":"array","items":{"type":"string","enum":["steam","epic","gog","microsoft","googleplay","appstore","itch"]},"description":"Which stores. Default all."},
        "name":{"type":"string","description":"File name prefix. Default: the project name."},
        "orientation":{"type":"string","enum":["landscape","portrait"],"description":"Phone and tablet screenshot sizes of Google Play and the App Store. Default landscape."},
        "overwrite":{"type":"boolean","default":true,"description":"Replace files that already exist."}
      }})");
    registry.add(info, [projectDir](const Json& args) { return draw_capsules(projectDir, args); });
}

}  // namespace fa::assets_detail
