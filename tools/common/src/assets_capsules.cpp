// assets.draw_capsules: store page images (capsules, heroes, screenshots, covers) at the size each store asks for, cut from
// one piece of key art with an optional logo. The key art is cover-cropped around a focal point; the logo (an image, or
// title text drawn by the rasterizer of assets.draw_icon) is placed by the rule of each asset.
#include <algorithm>
#include <cmath>
#include <format>
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

Image render_asset(const Image& art, const Logo& logo, const StoreAsset& a, int w, int h, double fx, double fy) {
    if (a.logo == LogoMode::Only) {  // a transparent PNG holding only the logo
        Image out;
        out.width = w;
        out.height = h;
        out.rgba.assign(std::size_t(w) * h * 4, 0);
        const Image l = logo_for_box(logo, int(w * a.widthFraction), int(h * a.heightFraction));
        composite(out, l, (w - l.width) / 2, (h - l.height) / 2);
        return out;
    }
    Image out = cover_crop(art, w, h, fx, fy);
    if (a.logo == LogoMode::None || !logo.present) return out;
    const Image l = logo_for_box(logo, int(w * a.widthFraction), int(h * a.heightFraction));
    int x = (w - l.width) / 2, y = (h - l.height) / 2;
    switch (a.logo) {
        case LogoMode::Top: y = int(h * 0.30 - l.height / 2.0); break;  // the top two thirds: text overlays use the bottom third
        case LogoMode::Bottom: y = int(h * 0.92) - l.height; break;
        case LogoMode::BottomLeft: x = int(w * 0.05); y = int(h * 0.92) - l.height; break;
        default: break;
    }
    composite(out, l, x, y);
    return out;
}

Json draw_capsules(const std::string& projectDir, const Json& a) {
    if (!a.is_object()) fail("invalid_argument", "assets.draw_capsules expects an object.", "See the description of the command for the fields.");
    check_keys(a, "", {"keyArt", "focus", "logo", "stores", "name", "orientation", "overwrite"});

    const std::string keyArt = tooling_detail::arg_string(a, "keyArt", true);
    double fx = 0.5, fy = 0.5;
    if (const auto f = a.find("focus"); f != a.end()) {
        if (!f->is_array() || f->size() != 2 || !(*f)[0].is_number() || !(*f)[1].is_number())
            bad("/focus", "expected [x, y] with two numbers.", "The focal point as a fraction of the key art: [0.5, 0.5] is the middle, [0.2, 0.7] left and low.");
        fx = (*f)[0].get<double>();
        fy = (*f)[1].get<double>();
        if (fx < 0 || fx > 1 || fy < 0 || fy > 1) bad("/focus", "x and y must be between 0 and 1.", "Fractions of the image: [0, 0] top-left, [1, 1] bottom-right.");
    }
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
            const Image img = render_asset(*art, logo, as, w, h, fx, fy);
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
        "stores":{"type":"array","items":{"type":"string","enum":["steam","epic","gog","microsoft","googleplay","appstore","itch"]},"description":"Which stores. Default all."},
        "name":{"type":"string","description":"File name prefix. Default: the project name."},
        "orientation":{"type":"string","enum":["landscape","portrait"],"description":"Phone and tablet screenshot sizes of Google Play and the App Store. Default landscape."},
        "overwrite":{"type":"boolean","default":true,"description":"Replace files that already exist."}
      }})");
    registry.add(info, [projectDir](const Json& args) { return draw_capsules(projectDir, args); });
}

}  // namespace fa::assets_detail
