// The commands that look at the picture: game.screenshot (whole view, a magnified region, a filmstrip of frames),
// render.inspect (luminance profile along a line and the hard steps in it) and render.pick (what draws a pixel).
#include <optional>
#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <format>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/image_tools.h"
#include "fa/core/profiler.h"
#include "fa/core/strings.h"
#include "fa/platform/hdr_output.h"
#include "fa/render/renderer.h"
#include "fa/scene/bounds.h"
#include "fa/scene/camera_mask.h"
#include "fa/scene/ui_rect.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

std::string abs_path(const std::string& p) {
    if (fs::is_absolute(p)) return p;
    return fs::resolve(p).generic_string();
}

constexpr int kMaxFilmstripTiles = 64;
constexpr int kMaxFilmstripFrames = 2000;
constexpr int kMaxSheetSide = 8192;
constexpr double kAutoSheetWidth = 2048;  // a filmstrip without `zoom` is drawn to be about this wide

Vec2 need_vec2(const Json& a, const char* key) {
    if (!a.contains(key))
        throw CommandError("invalid_argument", std::string("Missing '") + key + "'.",
                           std::string("Pass ") + key + " as [x, y] in design pixels (origin top-left).");
    Vec2 v;
    std::string err;
    if (!json_to(a[key], v, &err))
        throw CommandError("invalid_argument", std::string(key) + ": " + err, "Use [x, y] in design pixels.");
    return v;
}

void check_args_known(const Json& a, std::initializer_list<const char*> known, const char* command) {
    if (!a.is_object()) return;
    std::vector<std::string> names;
    for (const char* k : known) names.push_back(k);
    for (auto it = a.begin(); it != a.end(); ++it)
        if (std::find(names.begin(), names.end(), it.key()) == names.end())
            throw CommandError("invalid_argument",
                               std::string(command) + ": unknown argument '" + it.key() + "'. " +
                                   did_you_mean(it.key(), names),
                               "The arguments are: " + join(names, ", ") + ".");
}

}  // namespace

void register_shot_commands(Engine& engine, Engine::Impl& I) {
    I.commands.add(
        {"game.screenshot",
         "Capture the game view as a PNG and show it: whole, a magnified region, or a filmstrip of frames.",
         "Draws the game view as it is now (design resolution) and returns it; clients display the image. "
         "Scripts only run when frames are stepped: step the game first so the picture shows what you "
         "expect.\n"
         "WITHOUT `path` the picture is temporary: the result is {width, height, frame, temporary: true, "
         "$image: {path, mimeType, temporary: true}}, the MCP server and the AI assistant attach the image "
         "to the message and then DELETE the file, so do not keep or read that path later. (`factoria "
         "call` only prints the result and leaves the file; the engine removes engine-named files "
         "`.factoria/screenshots/frame_<n>*.png` older than 3 days or beyond the newest 200 when a project "
         "opens.) WITH `path` the file is written there and kept, and the result has `path`. Use `path` "
         "when your client cannot show images (then open the file yourself) or when you want to compare "
         "pictures later.\n"
         "\n"
         "Examples: game.screenshot {\"path\":\"shots/start.png\",\"scale\":1.5}; game.screenshot "
         "{\"region\":[600,0,80,720],\"zoom\":8}; game.screenshot "
         "{\"frames\":48,\"everyFrames\":4,\"region\":[400,200,480,300]}" FA_COMMAND_DETAILS
         "`scale` (0.25 to 4, default 1) draws the same frame into an image scale times larger, sharp and "
         "not upscaled, for store screenshots: HUD, camera and visible area stay the same, so a 1280x720 "
         "game at scale 1.5 gives a 1920x1080 PNG.\n"
         "A PNG holds 8 bits, at most paper white. In a window on an HDR display the frame is drawn with "
         "the HDR tonemap and what it puts above white is clipped, so the brightest areas look flatter "
         "than on the screen; a run without a window draws in the standard range, the SDR look (see "
         "docs/RENDERING.md, \"HDR output\").\n"
         "`region` [x, y, width, height] (design pixels, origin top-left) with `zoom` (0.25 to 32) shows "
         "only that part magnified: use it to look at a seam, a join, a gradient end or a one-pixel gap "
         "that is invisible in the whole view. Up to zoom 4 the frame is drawn again at that render scale "
         "and cropped (lines, text and shapes are sharp, the HUD is included); above 4 the 4x picture is "
         "enlarged with nearest-neighbour sampling (hard pixel blocks, nothing blurred). The result is "
         "round(width * zoom) x round(height * zoom), at most 8192 px a side; the region is clamped to the "
         "view. `zoom` without `region` magnifies the whole view the same way.\n"
         "`frames` makes a FILMSTRIP: one PNG with a grid of pictures, each labelled with its frame number "
         "(\"f130 +4\" = game frame 130, 4 frames after the start). The first picture is the game now, "
         "then the game is STEPPED `everyFrames` frames (default 1) and captured again until `frames` "
         "frames have passed, so frames 48 and everyFrames 4 give 13 tiles and leave the game 48 frames "
         "further. At most 64 tiles. `region` and `zoom` apply to every tile (the same region each time); "
         "without `zoom` the tiles are sized so the sheet is about 2048 px wide (never enlarged). "
         "`columns` sets the grid width (default: nearly square). Use it to see a whole transition or "
         "animation at once. A tween or script keeps running while it steps: it shows what the game does, "
         "it does not freeze anything. The result adds `tiles` [{frame, offset}], `columns`, `rows`, "
         "`tileWidth`, `tileHeight` and `zoom`.\n"
         "`simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the picture to what a "
         "colour-blind viewer sees (Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in "
         "linear light; greyscale = Rec. 709 luminance) without changing what the player sees: use it to "
         "check that hazards, pickups and buttons read without their colour. Needs graphics.\n"
         "`forceTouch` true shows the touch interface first (the touch-only TouchStick and TouchButton, which a "
         "desktop hides): "
         "it is set just before the picture and put back afterwards (ui.force_touch {\"enabled\":true} keeps it on).",
         parse_schema(R"({"type":"object","properties":{
               "path":{"type":"string","x-fa-path":"write","description":"Output PNG, inside the project (needs the writeProject capability; absolute paths need writeAnywhere, and the managed folders are refused). Given: the file is kept. Omitted: a temporary picture that the client deletes after reading it."},
               "scale":{"type":"number","minimum":0.25,"maximum":4,"description":"Render scale of the whole view (default 1): image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080. Not together with zoom."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[x, y, width, height] in design pixels (origin top-left): only this part of the view is captured, magnified by zoom."},
               "zoom":{"type":"number","minimum":0.25,"maximum":32,"description":"Magnification of the region (or of the whole view): up to 4 a native sharp re-render, above 4 nearest-neighbour enlargement of the 4x picture. Default 1 (a filmstrip without zoom: sized to a sheet about 2048 px wide)."},
               "frames":{"type":"integer","minimum":1,"maximum":2000,"description":"Filmstrip: the game advances this many frames in total, captured every everyFrames, into one labelled grid PNG."},
               "everyFrames":{"type":"integer","minimum":1,"description":"Filmstrip: frames between two pictures (default 1). frames / everyFrames + 1 pictures, at most 64."},
               "columns":{"type":"integer","minimum":1,"maximum":64,"description":"Filmstrip: tiles per row (default: the grid closest to square)."},
               "simulate":{"type":"string","enum":["none","greyscale","protanopia","deuteranopia","tritanopia"],"default":"none","description":"Convert the picture to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged."},
               "forceTouch":{"type":"boolean","description":"true: show the touch interface (the touch-only TouchStick and TouchButton) before the picture; false: the real last input. Only for this call: the previous setting is restored afterwards (ui.force_touch keeps it)."}}})"),
         false, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(
                a, {"path", "scale", "region", "zoom", "frames", "everyFrames", "columns", "simulate", "forceTouch"},
                "game.screenshot");
            std::optional<bool> forceTouch;
            if (a.contains("forceTouch")) {
                if (!a["forceTouch"].is_boolean())
                    throw CommandError("invalid_argument", "forceTouch must be true or false.",
                                       "Example: game.screenshot {\"forceTouch\":true}");
                forceTouch = a["forceTouch"].get<bool>();
            }
            std::string given =
                a.contains("path") && a["path"].is_string() ? a["path"].get<std::string>() : std::string();
            const bool temporary = given.empty();
            // A `path` is a file the caller names: it needs writeProject and stays inside the project. Without it the picture
            // goes under .factoria/screenshots/ (the engine's own records), which needs no more than {read, state}.
            if (!temporary) given = resolve_caller_write_path(given, "game.screenshot");
            if (a.contains("scale") && a.contains("zoom"))
                throw CommandError("invalid_argument", "scale and zoom were both given.",
                                   "Use `scale` for a whole-view render scale (store screenshots) or `zoom` (with "
                                   "`region`) to magnify; zoom without a region magnifies the whole view.");
            const double scale = a.value("scale", 1.0);
            if (!(scale >= 0.25 && scale <= 4.0))
                throw CommandError("invalid_argument", "scale " + std::to_string(scale) + " is out of range.",
                                   "scale must be between 0.25 and 4: the image is design size * scale. Example: 1.5 "
                                   "on a 1280x720 game gives 1920x1080.");
            const std::string simulate = a.value("simulate", std::string("none"));
            auto sim = parse_color_simulation(simulate);
            if (!sim.ok()) throw CommandError("invalid_argument", sim.error().message, sim.error().hint);

            Rect region{};  // w = 0: the whole view
            if (a.contains("region")) {
                std::string err;
                if (!json_to(a["region"], region, &err))
                    throw CommandError("invalid_argument", "region: " + err,
                                       "Use [x, y, width, height] in design pixels, e.g. [600, 0, 80, 720].");
                if (!(region.w > 0 && region.h > 0))
                    throw CommandError("invalid_argument", "region has no area (width and height must be above 0).",
                                       "Use [x, y, width, height] in design pixels, e.g. [600, 0, 80, 720].");
            }
            const bool filmstrip = a.contains("frames");
            if (!filmstrip && (a.contains("everyFrames") || a.contains("columns")))
                throw CommandError(
                    "invalid_argument", "everyFrames and columns belong to a filmstrip.",
                    "Add `frames` (the number of frames to cover), e.g. {\"frames\":48,\"everyFrames\":4}.");
            if (!I.renderer)  // the same message as before: no renderer, no picture
                throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.",
                                   "Screenshots need graphics (headless needs Mesa/EGL).");
            // Applied only now that every argument is valid, and put back when the call ends (this command is read-only).
            struct ForceTouchScope {
                Engine& engine;
                bool previous;
                bool changed;
                ~ForceTouchScope() {
                    if (changed) engine.set_force_touch(previous);
                }
            } touchScope{engine, engine.input().force_touch(), forceTouch.has_value()};
            if (forceTouch) engine.set_force_touch(*forceTouch);
            const Vec2 view{float(I.renderer->target_width()), float(I.renderer->target_height())};
            std::string err;
            Image img;
            Json tiles = Json::array();
            Json extra = Json::object();
            std::string kind;
            if (!filmstrip) {
                const double zoom = a.contains("zoom") ? a.value("zoom", 1.0) : scale;
                const auto plan = Engine::plan_region(view, region, zoom);
                if (!plan.error.empty())
                    throw CommandError("invalid_argument", plan.error,
                                       "See the `region` and `zoom` arguments of game.screenshot.");
                if (region.w <= 0 && !a.contains("zoom")) {
                    // The whole view at a render scale: the old path (kept for its limits and messages).
                    if (!engine.capture_scaled(img, scale, &err))
                        throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                } else {
                    if (!engine.capture_region(img, region, zoom, &err))
                        throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                }
                if (region.w > 0 || a.contains("zoom")) kind = "_region";
            } else {
                kind = "_sheet";
                const int frames = a.value("frames", 1);
                const int every = a.value("everyFrames", 1);
                if (frames < 1 || frames > kMaxFilmstripFrames)
                    throw CommandError(
                        "invalid_argument",
                        "frames " + std::to_string(frames) + " is out of range (1 to " +
                            std::to_string(kMaxFilmstripFrames) + ").",
                        "A filmstrip covers a transition: ask for the frames it takes, e.g. frames 48 every 4.");
                if (every < 1)
                    throw CommandError("invalid_argument", "everyFrames must be at least 1.",
                                       "everyFrames is the number of game frames between two pictures.");
                const int count = frames / every + 1;
                if (count > kMaxFilmstripTiles)
                    throw CommandError("invalid_argument",
                                       std::to_string(count) + " pictures (frames " + std::to_string(frames) +
                                           " / everyFrames " + std::to_string(every) +
                                           " + 1) is more than the 64 a sheet can hold.",
                                       "Raise everyFrames or lower frames: e.g. frames " + std::to_string(frames) +
                                           " with everyFrames " + std::to_string((frames + 62) / 63) + ".");
                const int wanted = a.value("columns", 0);
                // Tile size in design pixels (the clamped region) and the zoom.
                const auto at1 = Engine::plan_region(view, region, 1.0);
                if (!at1.error.empty())
                    throw CommandError("invalid_argument", at1.error, "See the `region` argument of game.screenshot.");
                double zoom = 1.0;
                if (a.contains("zoom")) {
                    zoom = a.value("zoom", 1.0);
                } else if (a.contains("scale")) {
                    zoom = scale;
                } else {
                    const SheetLayout l1 = sheet_layout(count, wanted, at1.width, at1.height);
                    zoom = std::clamp(kAutoSheetWidth / std::max(1, l1.width), 0.25, 1.0);
                }
                const auto plan = Engine::plan_region(view, region, zoom);
                if (!plan.error.empty())
                    throw CommandError("invalid_argument", plan.error,
                                       "See the `region` and `zoom` arguments of game.screenshot.");
                const SheetLayout predicted = sheet_layout(count, wanted, plan.width, plan.height);
                if (predicted.width > kMaxSheetSide || predicted.height > kMaxSheetSide)
                    throw CommandError(
                        "invalid_argument",
                        "The sheet would be " + std::to_string(predicted.width) + "x" +
                            std::to_string(predicted.height) + " px (" + std::to_string(count) + " tiles of " +
                            std::to_string(plan.width) + "x" + std::to_string(plan.height) +
                            "), over the 8192 px limit per side.",
                        "Use a smaller zoom or region, more columns, or fewer pictures (a larger everyFrames).");
                std::vector<Image> shots;
                std::vector<std::string> labels;
                const std::uint64_t startFrame = I.frame;
                for (int i = 0; i < count; ++i) {
                    if (i > 0) engine.step(every);
                    Image tile;
                    if (!engine.capture_region(tile, region, zoom, &err))
                        throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                    simulate_color_vision(tile, *sim);
                    const int offset = static_cast<int>(std::min<std::uint64_t>(I.frame - startFrame, 1000000));
                    labels.push_back("f" + std::to_string(I.frame) + (offset > 0 ? " +" + std::to_string(offset) : ""));
                    tiles.push_back(Json::object({{"frame", I.frame}, {"offset", offset}}));
                    shots.push_back(std::move(tile));
                }
                SheetLayout l;
                img = contact_sheet(shots, labels, wanted, -1, &l);
                extra["tiles"] = tiles;
                extra["columns"] = l.columns;
                extra["rows"] = l.rows;
                extra["tileWidth"] = l.tileWidth;
                extra["tileHeight"] = l.tileHeight;
                extra["zoom"] = zoom;
            }
            if (!filmstrip) simulate_color_vision(img, *sim);
            const std::string path =
                temporary ? ".factoria/screenshots/frame_" + std::to_string(I.frame) + kind + ".png" : given;
            auto saved = save_png(img, path);
            if (!saved.ok())
                throw CommandError("unavailable", saved.error().message,
                                   saved.error().hint.empty() ? "Check the path is inside a writable folder."
                                                              : saved.error().hint);
            const std::string abs = abs_path(path);
            Json j = Json::object();
            if (!temporary) j["path"] = abs;
            j["width"] = img.width;
            j["height"] = img.height;
            j["frame"] = I.frame;
            for (auto it = extra.begin(); it != extra.end(); ++it) j[it.key()] = *it;
            Json image = Json::object({{"path", abs}, {"mimeType", "image/png"}});
            if (temporary) {
                j["temporary"] = true;
                j["note"] = "Temporary picture: whoever shows it deletes the file. Pass `path` to keep a screenshot.";
                image["temporary"] = true;
            }
            j["$image"] = image;
            return j;
        });

    I.commands.add(
        {"render.inspect",
         "Luminance profile of the current picture along a line, with the hard steps (seams, bands) in it.",
         "Draws the picture as it is now and reads the pixels along the segment `from` -> `to` (design pixels, origin "
         "top-left): "
         "one sample per pixel along the longer axis, as a value 0..255 of the sRGB bytes (`channel`: luminance with "
         "Rec. 709 "
         "weights, or red, green, blue). It lists every STEP: a change of at least `threshold` (default 8 levels) "
         "within "
         "`window` samples (default 2), which is how a bright seam, a gap between two sprites or the edge of a "
         "gradient band "
         "shows in the numbers while the eye misses it. A smooth ramp has no steps; a staircase (Mach bands: two "
         "overlapping "
         "gradients) has one per riser. The edge of a sprite or a shape is a step too: find what draws it with "
         "render.pick at "
         "the step's `at`. Result: {from, to, channel, scale, count, samples: [values], min, max, steps: [{index, at: "
         "[x, y] "
         "(design pixels, the middle of the jump), width, from, to, delta}], stepCount, frame}; at most 200 steps and "
         "4096 "
         "samples. `scale` (0.25 to 4, default 1) samples a render at that scale, so at 4 there are four samples per "
         "design "
         "pixel and a sub-pixel gap shows. Look at the area with game.screenshot {region, zoom} first, then measure "
         "it. Needs "
         "graphics. Example: render.inspect {\"from\":[600,360],\"to\":[680,360],\"threshold\":6}",
         parse_schema(R"({"type":"object","properties":{
               "from":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"Start of the line, [x, y] in design pixels (origin top-left)."},
               "to":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"End of the line, [x, y] in design pixels."},
               "threshold":{"type":"number","default":8,"exclusiveMinimum":0,"maximum":255,"description":"Smallest change (0..255) that counts as a step."},
               "window":{"type":"integer","default":2,"minimum":1,"maximum":32,"description":"A step is a change of at least threshold within this many samples."},
               "channel":{"type":"string","enum":["luminance","red","green","blue"],"default":"luminance","description":"What to measure: Rec. 709 luminance or one colour channel of the sRGB bytes."},
               "scale":{"type":"number","default":1,"minimum":0.25,"maximum":4,"description":"Render scale to sample at; higher finds finer gaps."}},
               "required":["from","to"]})"),
         true, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"from", "to", "threshold", "window", "channel", "scale"}, "render.inspect");
            if (!I.renderer)
                throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.",
                                   "Screenshots need graphics (headless needs Mesa/EGL).");
            const Vec2 from = need_vec2(a, "from"), to = need_vec2(a, "to");
            const double threshold = a.value("threshold", 8.0);
            if (!(threshold > 0 && threshold <= 255))
                throw CommandError("invalid_argument", "threshold " + std::to_string(threshold) + " is out of range.",
                                   "threshold is a change in levels, above 0 and at most 255. Try 6 to 12.");
            const int window = a.value("window", 2);
            if (window < 1 || window > 32)
                throw CommandError("invalid_argument", "window must be between 1 and 32 samples.",
                                   "The default 2 finds jumps within two pixels.");
            const double scale = a.value("scale", 1.0);
            if (!(scale >= 0.25 && scale <= 4.0))
                throw CommandError("invalid_argument", "scale " + std::to_string(scale) + " is out of range.",
                                   "scale must be between 0.25 and 4.");
            auto channel = parse_profile_channel(a.value("channel", std::string("luminance")));
            if (!channel.ok()) throw CommandError("invalid_argument", channel.error().message, channel.error().hint);
            const Vec2 view{float(I.renderer->target_width()), float(I.renderer->target_height())};
            for (const Vec2& p : {from, to})
                if (!(p.x >= 0 && p.y >= 0 && p.x <= view.x && p.y <= view.y))
                    throw CommandError("invalid_argument",
                                       std::format("point [{}, {}] is outside the game view ({}x{} design pixels).",
                                                   p.x, p.y, int(view.x), int(view.y)),
                                       "Both ends must be inside the view, origin top-left.");
            const Vec2 a2{from.x * float(scale), from.y * float(scale)}, b2{to.x * float(scale), to.y * float(scale)};
            if (std::max(std::fabs(b2.x - a2.x), std::fabs(b2.y - a2.y)) + 1 > 4096)
                throw CommandError("invalid_argument", "The line would have more than 4096 samples.",
                                   "Shorten the line or lower `scale`; inspect a stretch at a time.");
            Image img;
            std::string err;
            if (!engine.capture_scaled(img, scale, &err))
                throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
            std::vector<Vec2> points;
            const std::vector<float> values = profile_line(img, a2, b2, *channel, &points);
            const std::vector<ProfileStep> steps = find_steps(values, float(threshold), window);
            Json samples = Json::array();
            float lo = 255, hi = 0;
            for (float v : values) {
                samples.push_back(int(std::lround(v)));
                lo = std::min(lo, v);
                hi = std::max(hi, v);
            }
            auto design = [&](Vec2 p) {
                return Json::array(
                    {std::round(p.x / float(scale) * 100) / 100, std::round(p.y / float(scale) * 100) / 100});
            };
            Json stepList = Json::array();
            for (const ProfileStep& s : steps) {
                // Samples read the pixel under their point, so the change starts with the sample after `index`: the middle of the
                // points from there to the end of the jump is where the edge lies (an edge between pixels 109 and 110 is at 110).
                const Vec2 mid = (points[std::size_t(s.index + 1)] + points[std::size_t(s.index + s.width)]) * 0.5f;
                stepList.push_back(Json::object({{"index", s.index},
                                                 {"at", design(mid)},
                                                 {"width", s.width},
                                                 {"from", std::round(s.from * 10) / 10},
                                                 {"to", std::round(s.to * 10) / 10},
                                                 {"delta", std::round(s.delta * 10) / 10}}));
            }
            Json j = Json::object();
            j["from"] = Json::array({from.x, from.y});
            j["to"] = Json::array({to.x, to.y});
            j["channel"] = a.value("channel", std::string("luminance"));
            j["scale"] = scale;
            j["count"] = values.size();
            j["samples"] = samples;
            j["min"] = values.empty() ? 0.0 : std::round(lo * 10) / 10;
            j["max"] = values.empty() ? 0.0 : std::round(hi * 10) / 10;
            j["steps"] = stepList;
            j["stepCount"] = steps.size();
            j["frame"] = I.frame;
            return j;
        });

    I.commands.add(
        {"render.pick", "Which entities draw a design-space pixel of the picture, topmost first.",
         "Lists the 2D visuals (Sprite, Shape2D, Text, Tilemap, UI widgets) whose drawn box covers "
         "`position` (design pixels, origin top-left), topmost first: screen-space UI above the world, "
         "then the higher `layer`, then (world Sprites) the lower world y, then the one drawn later "
         "(component order Tilemap, Sprite, Shape2D, Text; then creation order). Each hit is {entity, "
         "name, component, layer, space: \"world\"|\"screen\"}. Use it to find which shape or sprite "
         "causes a visible artefact (a seam, a dark band) after game.screenshot {region, zoom} or "
         "render.inspect located it. The test is the oriented BOX of the visual (the same footprint as "
         "entity.bounds() and the editor's picking): a transparent corner of a sprite, the corners outside "
         "a circle and the parts of a gradient that fade out still count; an alpha-0 colour is skipped; "
         "inactive entities are skipped, and so are world visuals the camera at that pixel does not draw "
         "(Camera.showTags / hideTags). The world point is found through the primary camera; `world` in "
         "the result is that point. Example: render.pick {\"position\":[640,360]}" FA_COMMAND_DETAILS
         "`widget` is the widget a click there would reach, through the same path the mouse takes: a "
         "screen widget, else a world-space Interactable, and over a mesh that shows a render target "
         "(Camera.renderTarget) the Interactable of that page under the point, or null. `via` ({mesh, "
         "target}: the MeshRenderer entity and the target camera's) is present when the point is over such "
         "a mesh (`hits` still lists what the main camera draws there: the mesh, not the page behind it). "
         "Needs graphics (the camera is the renderer's).",
         parse_schema(R"({"type":"object","properties":{
               "position":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"[x, y] in design pixels (origin top-left)."},
               "max":{"type":"integer","default":20,"minimum":1,"maximum":200,"description":"At most this many hits."}},
               "required":["position"]})"),
         true, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"position", "max"}, "render.pick");
            (void)engine;
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "render.pick needs the renderer's camera to turn the pixel into a world point.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            const Vec2 p = need_vec2(a, "position");
            const int maxHits = std::clamp(a.value("max", 20), 1, 200);
            const Vec2 design{float(I.renderer->target_width()), float(I.renderer->target_height())};
            const Vec3 w3 = I.renderer->screen_to_world(p);
            const Vec2 world{w3.x, w3.y};
            const VisualMeasure measure = I.measure();
            struct Hit {
                Entity e;
                std::string component;
                int layer;
                bool screen;
                float secondary;
                int seq;
            };
            std::vector<Hit> hits;
            const CameraMask mask = CameraMask::of(
                I.world, I.renderer->camera_at(p));  // world visuals this camera does not draw cannot be hit
            int entityIndex = 0;
            for (Entity e : I.world.entities()) {
                ++entityIndex;
                if (!I.world.active_in_hierarchy(e)) continue;
                for (const VisualFootprint& part : visual_footprints(I.world, e, measure, true)) {
                    const bool screen = part.space == RenderSpace::Screen;
                    if (!screen && !mask.draws(I.world, e)) continue;
                    if (!footprint_hit(I.world, e, part, design, screen ? p : world)) continue;
                    const std::string kind = part.component;
                    // A colour with no alpha draws nothing.
                    float alpha = 1;
                    if (kind == "Sprite") {
                        if (const Sprite* s = I.world.get<Sprite>(e)) alpha = s->color.a;
                    } else if (kind == "Shape2D") {
                        if (const Shape2D* s = I.world.get<Shape2D>(e))
                            alpha = s->gradient != ShapeGradient::None ? std::max(s->color.a, s->color2.a) : s->color.a;
                    } else if (kind == "Text") {
                        if (const Text* t = I.world.get<Text>(e)) alpha = t->color.a;
                    }
                    if (alpha <= 0) continue;
                    static const char* const kOrder[] = {"Tilemap", "Sprite", "Shape2D", "Text"};
                    int rank = 4;
                    for (int i = 0; i < 4; ++i)
                        if (kind == kOrder[i]) rank = i;
                    // The renderer sorts world Sprites by their world y (lower y on top); other visuals have no secondary key.
                    const float secondary =
                        !screen && kind == "Sprite" ? I.world.world_matrix(e).translation().y : 0.0f;
                    hits.push_back({e, kind, int(part.layer), screen, secondary, entityIndex * 8 + rank});
                }
            }
            // Draw order ascending = bottom to top; the answer is topmost first.
            std::stable_sort(hits.begin(), hits.end(), [](const Hit& x, const Hit& y) {
                if (x.screen != y.screen) return x.screen;
                if (x.layer != y.layer) return x.layer > y.layer;
                if (x.secondary != y.secondary) return x.secondary < y.secondary;
                return x.seq > y.seq;
            });
            Json list = Json::array();
            for (const Hit& h : hits) {
                if (int(list.size()) >= maxHits) break;
                list.push_back(Json::object({{"entity", I.world.id_of(h.e)},
                                             {"name", I.world.info(h.e).name},
                                             {"component", h.component},
                                             {"layer", h.layer},
                                             {"space", h.screen ? "screen" : "world"}}));
            }
            Json j = Json::object();
            j["position"] = Json::array({p.x, p.y});
            j["world"] = Json::array({w3.x, w3.y});
            j["hits"] = list;
            j["hitCount"] = hits.size();
            if (hits.size() > list.size()) j["truncated"] = true;
            const Entity under = I.ui.widget_at(I.world, design, p, measure);
            j["widget"] = under != kNullEntity && I.world.alive(under) ? Json(I.world.id_of(under)) : Json();
            if (const std::optional<UiSurface> page = I.ui.page_at(p);
                page && page->pin.mesh && I.world.alive(page->pin.mesh) &&
                !(under != kNullEntity && ui_kind(I.world, under) != UiKind::None))
                j["via"] = Json::object(
                    {{"mesh", I.world.id_of(page->pin.mesh)},
                     {"target",
                      page->camera && I.world.alive(page->camera) ? Json(I.world.id_of(page->camera)) : Json()}});
            j["frame"] = I.frame;
            return j;
        });

    I.commands.add(
        {"render.frame_graph",
         "Where the last frame's time went, pass by pass: the frame graph with the CPU and GPU time of every pass.",
         "Returns the frame graph of the last frame the renderer drew and what each of its passes cost, so you can see "
         "which job and which pass makes a frame slow. Result: {source, backend, frame, profileFrames, graph, "
         "passTimes, jobTimes, gpu, postProcess}. "
         "`passTimes` has one {name, job, cpuMs, gpuMs} per pass that ran, in order (cpuMs: time to record the pass on "
         "the CPU; gpuMs: GPU time, or -1 when not measured: D3D11 and desktop OpenGL only, while the profiler is "
         "on); `jobTimes` adds them per job; `gpu` says whether GPU times exist and why not. Compare passes with "
         "each other, not the decimals. Draws a frame first when none is current. The GPU times need the profiler: "
         "with `profileFrames` (default 8, 0 to 60) this command switches it on for the call when it is off and the "
         "backend can time the GPU, draws the current state up to that many times until the GPU times arrive, and "
         "puts the profiler back; `profileFrames: 0` is the call that only reads: it neither switches the profiler "
         "on nor draws a frame again (gpuMs is then -1 unless a profile or the editor's Profiler panel already runs). "
         "Example: render.frame_graph {\"profileFrames\":8}" FA_COMMAND_DETAILS
         "`frame` is the engine's frame counter (the same number as game.state's `frame`) when the graph was read: "
         "the graph itself is the one of the last frame drawn. `profileFrames` is how many frames this call drew "
         "with the profiler switched on to get the GPU times (0 when it did not need to: the profiler was already "
         "on, or profileFrames was 0, or the backend has no GPU timer; `gpu.reason` says which). "
         "`source` is \"frame\" (a normal frame) or \"capture\" (the last graph was the picture of one entity's "
         "subtree, "
         "not a frame of the game: the next frame shows the game's own). `backend` is the graphics backend (metal, "
         "d3d11, "
         "glcore, gles3, dummy). READ `graph` like this: a JOB is one picture the frame draws: `camera:<i>` (a camera "
         "of the "
         "frame, in depth order), `screen` (the screen-space items of a split frame), `view:<n>` (a CameraView's "
         "image), "
         "`target:<name>` (a Camera.renderTarget texture) or `capture`; a PASS is named `<job>/<pass>` (`game` draws "
         "the world, "
         "`light-buffer` the 2D lights, `shadow` the shadow map, `bloom-*` the glow, `hud-over-bloom`, `color-filter`, "
         "`flip`). "
         "graph.resources are the images the passes read and write: `imported` ones are owned by the renderer and "
         "persist "
         "(the game image, a view's image, the light buffer, the shadow map); `transient` ones exist only inside the "
         "frame "
         "(the bloom levels) and share a physical target when their lifetimes do not overlap (`aliasSlot`, listed in "
         "graph.aliasSlots; `firstUse` and `lastUse` are positions in `order`). graph.passes lists every declared pass "
         "with "
         "what it reads and writes; a pass is `culled` when nothing reads what it writes and it has no side effect, so "
         "it did "
         "not run (graph.culled names them) and it has no time. graph.order is the order the live passes ran. "
         "graph.cycleBreaks lists passes that ran before a pass they waited for because two render targets show each "
         "other: "
         "the one that went first shows the other's picture of the PREVIOUS frame (empty is normal). "
         "`passTimes` has one entry per pass that ran, in `order`: {name, job, cpuMs, gpuMs}. cpuMs is the wall-clock "
         "time the "
         "pass took to record its GPU commands on the CPU (a pass that is cheap here can still be slow on the GPU). "
         "gpuMs is "
         "the GPU time of that pass in a recent frame (timer queries are read a few frames late and never waited for), "
         "or "
         "-1 when it was not measured; the numbers jitter from frame to frame, so compare passes against each other "
         "rather "
         "than reading the decimals. `jobTimes` adds the passes of each job: {job, passes, cpuMs, gpuMs} (gpuMs is -1 "
         "when no "
         "pass of the job has one). `gpu` says whether GPU times exist: {supported, measuring, reason, "
         "maxTimedPasses}: "
         "they exist on Direct3D 11 (Windows) and desktop OpenGL (Linux), only while the profiler is on (this "
         "command's profileFrames, perf.profile, play.report's profile, the editor's Profiler panel), and at most "
         "maxTimedPasses passes per frame are timed; "
         "`reason` "
         "says why there are none (Metal, GLES3 and WebGL2 have no timer queries here). `postProcess` is the "
         "post-processing alone: {passes: [{name, job, cpuMs, gpuMs}], cpuMs, gpuMs, gpuStatus, gpuReason, "
         "gpuPassesTimed, gpuPartial, note}, the "
         "passes named bloom-*, exposure-*, post and the other effect passes (prepass and sprite-coverage are not in "
         "it), with their summed times. `gpuMs` is null, `gpuStatus` \"unavailable\" and `gpuReason` the reason "
         "(the `gpu.reason` text, which says when the profiler is off, or that the frame has no post pass) when no GPU "
         "time exists, never 0. "
         "When only some passes came back with a time, `gpuMs` is their sum, `gpuPassesTimed` counts them and "
         "`gpuPartial` is true: "
         "a lower bound, not the whole cost. The effects "
         "folded into the single `post` pass (vignette, grain, grading, sharpen, outline...) are not timed one by "
         "one: `post` is their total, and no per-effect estimate is made. The same pass times are in "
         "the profiler's `zones`. Like game.render_stats it draws a frame first when none was drawn since the last "
         "change (a headless run draws on demand). Errors: `unavailable` without graphics, or when no frame could be "
         "drawn, and `invalid_argument` for a profileFrames that is not an integer from 0 to 60. Example: "
         "render.frame_graph {\"profileFrames\":8}",
         parse_schema(R"({"type":"object","properties":{
               "profileFrames":{"type":"integer","default":8,"minimum":0,"maximum":60,"description":"GPU times need the profiler: when it is off and the backend can time the GPU, switch it on for this call and draw the current state up to this many times, stopping as soon as GPU times arrive; then put it back. 0 = read what is there (gpuMs -1 unless the profiler is already on)."}}})"),
         true, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"profileFrames"}, "render.frame_graph");
            constexpr long long kMaxProfileFrames = 60;
            long long profileFrames = 8;
            if (a.is_object() && a.contains("profileFrames")) {
                const Json& v = a["profileFrames"];
                if (!v.is_number_integer() || v.get<long long>() < 0 || v.get<long long>() > kMaxProfileFrames)
                    throw CommandError("invalid_argument",
                                       "profileFrames: " + describe_json_value(v) + " is not an integer from 0 to 60.",
                                       "Use 0 to read what is there, or 8 (the default) to 60 frames to wait for the "
                                       "GPU times; the answers of the timer queries come a few frames late.");
                profileFrames = v.get<long long>();
            }
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no frame graph exists.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            engine.render_now();  // an on-demand run may not have drawn the current state yet
            // The GPU timers only run while the profiler is on and answer a few frames late: switch it on for this call
            // (an already running profiler is left alone and not fed extra frames) and put it back when the call ends.
            struct ProfilerRestore {
                bool on = false;
                ~ProfilerRestore() {
                    if (on) Profiler::get().set_enabled(false);
                }
            } restore;
            int drawn = 0;
            if (profileFrames > 0 && !Profiler::on() && I.renderer->gpu_timing_supported()) {
                Profiler::get().set_enabled(true);
                restore.on = true;
                auto has_gpu = [&] {
                    for (const RenderStats::PassTime& p : I.renderer->stats().passes)
                        if (p.gpuMs >= 0.0) return true;
                    return false;
                };
                while (drawn < profileFrames) {
                    engine.redraw(1);
                    ++drawn;
                    if (has_gpu()) break;
                }
            }
            Json j = I.renderer->frame_graph_report();  // before the profiler goes back: it says "measuring" while on
            if (j.is_null())
                throw CommandError("unavailable", "No frame has been drawn yet, so there is no frame graph to show.",
                                   "Load a scene and step at least one frame (game.step), or take a game.screenshot, "
                                   "then call render.frame_graph again.");
            j["frame"] = I.frame;
            j["profileFrames"] = drawn;
            return j;
        });

    I.commands.add(
        {"render.probes",
         "The reflection probes the renderer keeps: the atlas, each probe's tile, state and last capture.",
         "Reads the state of the reflection probes (ReflectionProbe components, "
         "docs/design/ARCHITECTURE_PROBES.md) after drawing a frame "
         "when none is current. Result: {atlas: {size, format (\"RGBA16F\" or \"RGBA8\"), tiles, "
         "usedTexels, reservedTexels, "
         "capacityTexels, created}, sky: {state, tile, writtenFrame}, faceBudget, frame, passes, overLimit, "
         "probes: [{entity, mode, "
         "update, state, message?, resolution, importance, tile: {x, y, resolution} or null, captures, "
         "lastFrame, facesDone | bakedMap, "
         "hash?}]}. `state` is \"ready\", \"pending\", \"capturing\", \"noRoom\", \"noBake\" or \"failed\". "
         "The lit meshes sample the atlas (the sky is its entry 0, `sky`). The result is "
         "{probes: [], atlas: null} while no ReflectionProbe has been drawn. With `entity` (a mesh), the result also "
         "has `mesh: {probes: [{entity, share}], sky}`: which probes that mesh reflected in the last frame and "
         "how much of its reflection each holds (0..1, steps of 1/32; the probes and the sky add up to 1). "
         "Errors: `unavailable` without graphics; `invalid_argument` for an `entity` that is not a string or has no "
         "MeshRenderer. "
         "Example: render.probes {} or render.probes {\"entity\": \"sphere\"}. What each state means: "
         "docs/rendering/RENDERING_PROBES.md, the render.probes item." FA_COMMAND_DETAILS
         "The first ask for a mesh draws one more frame (the renderer keeps the picks of that one mesh only): the "
         "debug-draw lines queued since the last draw are consumed and a time-sliced capture moves on by a frame. "
         "An ask without `entity` ends that watch.\n\n"
         "`state`: \"ready\"; \"pending\" (waiting for its first capture); \"capturing\" (facesDone of 6 faces drawn); "
         "\"noRoom\" (the atlas has no tile for it: `message` says why); \"noBake\" (a baked probe with no readable "
         "bakedMap: run probe.bake); \"failed\" (retried after 30 frames). `overLimit` counts the active probes beyond "
         "the 256 the renderer keeps (those with the smallest importance): they have no entry in `probes`. A capture "
         "is "
         "asked again with render.probe_refresh. `lastFrame` counts the frames that had probes. A mesh no probe "
         "reaches "
         "reflects the sky. "
         "The atlas of the realtime and baked probes is one image 1024 texels wide (1024 x 1024, 8 MB as RGBA16F, "
         "unless "
         "a RealtimeGI makes it taller); "
         "`usedTexels` is what the tiles cover and "
         "`reservedTexels` what their shelves hold, so a large gap means fragmentation by resolution.",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"A mesh entity (id or name): the result also says which probes it reflects."}}})"),
         true, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"entity"}, "render.probes");
            const bool one = a.is_object() && a.contains("entity") && !a["entity"].is_null();
            if (one && !a["entity"].is_string())
                throw CommandError(
                    "invalid_argument",
                    std::string("render.probes: `entity` is a string (the mesh's id or name), got ") +
                        a["entity"].type_name() + ".",
                    "Pass \"entity\": \"sphere\", or leave `entity` out. scene.list_entities shows the ids.");
            const Entity named = one ? need_entity(I.world, a, "entity") : kNullEntity;
            if (one && !I.world.get<MeshRenderer>(named))
                throw CommandError("invalid_argument",
                                   "/entity: '" + I.world.id_of(named) + "' has no MeshRenderer component.",
                                   "Name the entity that draws the mesh whose reflections you want to see.");
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no probes are captured.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            // The renderer keeps the picks of one mesh only (the one asked about); the first ask for a mesh draws a frame that keeps them.
            if (!I.renderer->probe_watch_mesh(named) && one)  // no `entity`: the watch of an earlier ask ends
                engine.redraw(1);
            else
                engine.render_now();
            Json j = I.renderer->probe_report();
            if (j.empty()) j = Json::object({{"probes", Json::array()}, {"atlas", Json()}});
            if (one) j["mesh"] = I.renderer->probe_mesh_report(named);
            return j;
        });

    I.commands.add(
        {"render.gi_grid",
         "The realtime GI's probe grids: probe count, update progress, memory and the probes that are inside geometry.",
         "Reads the state of the RealtimeGI grids after drawing a frame when none is current. Result: {frame, "
         "captures, capturesPerFrame (last 64 frames), probeLimit, atlas: {width, height, format, bytes, "
         "blocksUsed}, grids: [{entity, state, message?, probes, dimensions, spacing, origin, resolution, "
         "probesPerFrame, captured, progress (0..1), cycles, framesPerCycle, bytes, notCaptured, invalidProbes, "
         "invalid: [{index, position}] (up to 64)}]}. `state` is \"updating\" (probes not captured yet), \"ready\", "
         "\"invalid\" (`message` names the field and the fix), \"noRoom\" (more than `probeLimit` probes), "
         "\"failed\" (a capture could not be made: it is retried after 30 frames, and `state` and `message` stay "
         "until the next capture succeeds) or \"unsupported\" (no RGBA16F blending). `invalidProbes` counts "
         "the probes inside a mesh (back faces hit beyond `backfaceTolerance`), found by one atlas readback: call "
         "this to look, not every frame. `meshesRead` is true when the lit meshes read the grid (it is ready and the "
         "renderer supports it). {grids: [], atlas: null} "
         "while no RealtimeGI was drawn. Errors: `unavailable` without graphics. Example: render.gi_grid {} "
         "See docs/rendering/RENDERING_LIGHT_PROBES.md, \"Realtime global illumination\"." FA_COMMAND_DETAILS
         "Other result fields: passes, probesPerFrameLimit, capturesLastFrame, firstBlock. A grid costs `probes` x "
         "10 x 11 texels x 8 bytes of the probe atlas (1760 bytes for two probes) and `probesPerFrame` x 6 faces "
         "of `resolution` x `resolution` texels a frame; the atlas grows by 132 rows (about 1 MB) while any "
         "RealtimeGI exists. `ready` means every probe was captured once; the others are refreshed in turn, "
         "`framesPerCycle` frames for all.",
         parse_schema(R"({"type":"object","properties":{}})"), true, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {}, "render.gi_grid");
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no GI probes are captured.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            engine.render_now();
            Json j = I.renderer->gi_report();
            if (j.empty()) return Json::object({{"grids", Json::array()}, {"atlas", Json()}});
            return j;
        });

    I.commands.add(
        {"render.gi2d_field",
         "The 2D global illumination field of the last frame: its size, texel size and world rectangle, what fills "
         "it and its cascades; optionally the images as PNGs.",
         "Draws a frame when none is current and reports the field that a GlobalIllumination2D makes for each 2D "
         "camera job "
         "(docs/design/ARCHITECTURE_RENDERING_GI2D.md, \"2D GI field: what P3b reads\"): an emission image, an "
         "occluder/albedo "
         "image (alpha = occupancy) and a jump-flooding distance field, RGBA16F, covering the view plus `range` on "
         "every "
         "side at `resolutionScale`, and the radiance cascades that turn it into the irradiance the lit 2D visuals "
         "receive (docs/rendering/RENDERING_2D_GI.md). With `save` it also writes the images as PNGs. Errors: "
         "`unavailable` "
         "without graphics. Example: render.gi2d_field {\"save\": \".factoria/tmp/gi\"}. See "
         "docs/design/ARCHITECTURE_RENDERING_GI2D.md, \"2D GI field: what P3b reads\"." FA_COMMAND_DETAILS
         "Result: {enabled, supported, message? (why not supported: the backend and "
         "render.supports \"2dGlobalIllumination\"), fieldLimit, maxSize, format, settings: {quality, intensity, "
         "bounce, range, "
         "resolutionScale}, bytes, fields: [{slot, job, ready, width, height, texelSize, worldRect: {x, y, width, "
         "height}, capped, "
         "bytes, passes, cascades: {cascades, probeSpacing, raysPerProbe, steps, reachTexels, irradianceWidth, "
         "irradianceHeight, primed}, emitters: {sprites, tiles, lights}, occluders: {solidTiles, boxes, polygons, "
         "spriteAlpha, "
         "skipped}, "
         "dropped}]}. `fields` is empty without an enabled GlobalIllumination2D, on a 3D camera, or where the GPU has "
         "no "
         "RGBA16F render targets (then `supported` is false and `message` says what to do). With `save` (a path "
         "without "
         "extension) the images of the field of `job` (default: the first) are written as <save>-emission.png, "
         "<save>-occluders.png and <save>-distance.png and, once a frame of cascades has run, <save>-irradiance.png "
         "(one pixel a probe of cascade 0, rgb the light that reaches the probe, alpha 1 where the probe is free and 0 "
         "inside an occluder or an emitter); row 0 of a file is the largest world y; they are listed in `files`; "
         "a "
         "failure is in `error`. `cascades.primed` is true when the last frame had no history of the bounce and ran "
         "the priming chain (the first frame, a new size, a camera that moved by more than the field). Errors: "
         "`unavailable` without graphics; `invalid_argument` for a `save` or `job` that "
         "is "
         "not a string, and for a `save` that ends in .png or in a folder separator (it is a prefix: the command adds "
         "the names).\n"
         "The distance image holds the nearest occluder texel's coordinates in r and g (exact), the distance to it in "
         "field texels in b (a half float: about 3 significant digits) and 1 in a where an occluder exists (b is 65504 "
         "and "
         "a is 0 for a field without occluders; a texel with a = 0 holds -1 in r and g). The `save` PNG of the "
         "distance is grey: black at an occluder, white "
         "at "
         "the farthest distance of the field (white everywhere without occluders). `save` reads the GPU back: look, do "
         "not "
         "call it every frame. `save` needs the writeProject capability.",
         parse_schema(R"({"type":"object","properties":{
               "save":{"type":"string","x-fa-path":"write","description":"Path prefix without extension (inside the project; absolute paths need writeAnywhere): the images are written as <save>-emission.png, <save>-occluders.png, <save>-distance.png and <save>-irradiance.png (never end it in .png or in a folder separator). Omitted: nothing is written."},
               "job":{"type":"string","description":"The camera job whose field `save` writes (the \"job\" of fields[], e.g. \"camera:0\"). Default: the first field that is ready."}}})"),
         false, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"save", "job"}, "render.gi2d_field");
            for (const char* key : {"save", "job"})
                if (a.is_object() && a.contains(key) && !a[key].is_null() && !a[key].is_string())
                    throw CommandError("invalid_argument",
                                       std::string("render.gi2d_field: `") + key + "` is a string, got " +
                                           a[key].type_name() + ".",
                                       std::string("Pass \"") + key + "\": \"...\" or leave it out.");
            // The path is judged first: a bad one is refused whether or not there is a renderer.
            std::string save = a.is_object() && a.contains("save") && a["save"].is_string()
                                   ? a["save"].get<std::string>()
                                   : std::string();
            if (!save.empty()) {
                // `save` is a prefix: the command adds "-emission.png" and the rest. A file name or a folder would give "x.png-emission.png"
                // or "dir/-emission.png", which is never what the caller meant.
                std::string lower = save;
                std::transform(lower.begin(), lower.end(), lower.begin(),
                               [](unsigned char c) { return char(std::tolower(c)); });
                const bool png = lower.size() >= 4 && lower.compare(lower.size() - 4, 4, ".png") == 0;
                const bool folder = save.back() == '/' || save.back() == '\\';
                if (png || folder)
                    throw CommandError(
                        "invalid_argument",
                        std::string("render.gi2d_field: `save` is a path PREFIX without extension, but it is \"") +
                            save + (png ? "\" (a .png file name)." : "\" (it ends in a folder separator)."),
                        std::string(
                            "The command writes <save>-emission.png, <save>-occluders.png, <save>-distance.png and "
                            "<save>-irradiance.png: pass \"") +
                            (png ? save.substr(0, save.size() - 4) : save + "gi") + "\".");
                save = resolve_caller_write_path(save, "render.gi2d_field");
            }
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no 2D GI field is drawn.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            const std::string job = a.is_object() && a.contains("job") && a["job"].is_string()
                                        ? a["job"].get<std::string>()
                                        : std::string();
            engine.render_now();
            return I.renderer->gi2d_field(save, job);
        });

    I.commands.add(
        {"render.occlusion",
         "The occlusion culling of the last frame (CPU Occluders and the GPU depth pyramid): Occluders rasterised, "
         "meshes "
         "tested and hidden; optionally the depth picture as a PNG.",
         "Draws a frame when none is current and reports what the CPU occlusion culling did for the last camera that "
         "had "
         "an enabled Occluder (docs/BIG_WORLDS_LOD.md, \"Occlusion\"), and in `gpu` what the depth pyramid did "
         "(SceneSettings.occlusionMode \"gpu\" or \"auto\" on a backend with compute shaders): the size of its depth "
         "buffer, the Occluders and "
         "triangles rasterised, the meshes tested against it and the ones it proved hidden (they are in "
         "renderStats.meshesOccluded too). With `save` it also writes the depth buffer as a grey PNG (black = no "
         "occluder, the nearer an occluder the brighter) so you can see what hides what; render.debug_view "
         "{\"view\":\"occlusion\"} draws the boxes over the game picture. Errors: `unavailable` without graphics; "
         "`invalid_argument` for a `save` that is not a string or does not end in .png. Example: render.occlusion "
         "{\"save\": \".factoria/tmp/occlusion.png\"}" FA_COMMAND_DETAILS
         "Result: {supported, debugView, active, limits: {width, trianglesPerOccluder, trianglesPerCamera}, camera, "
         "width, "
         "height, occluders, triangles, coveredCells, tests, hidden, file?, error?, gpu: {mode, supported, why?, "
         "active, "
         "limits, camera?, cameras?, usableCameras?, width?, height?, levels?, coveredCells?, ageFrames?, tests?, "
         "hidden?, "
         "testResults?: {hidden, visible, noPyramid, cut, behindNear, outsideView, tooMuchMotion, noOccluder}, "
         "drewEverythingBecause?, reducePasses?, level?, file?, error?, message?}}. `active` is false when no camera "
         "of the last frame had an enabled Occluder (then only `message`, `limits` and `gpu` follow). In `gpu`, "
         "`ageFrames` is how old the depth picture was (1 is the frame before) and `testResults` counts the meshes "
         "tested by "
         "why they were or were not culled. With `save` and no Occluder buffer, the file is the pyramid's `level` "
         "(0 = 256 cells across). `width` x `height` "
         "is the buffer without its one-cell guard ring (256 across; 256 / aspect down). `save` needs the writeProject "
         "capability.",
         parse_schema(R"({"type":"object","properties":{
               "save":{"type":"string","x-fa-path":"write","description":"A .png path (inside the project; absolute paths need writeAnywhere) for the depth buffer as a grey picture. Omitted: nothing is written."},
               "level":{"type":"integer","minimum":0,"maximum":16,"description":"Which mip of the GPU depth pyramid `save` writes when no Occluder buffer exists (0 = the finest, 256 cells across; each level halves it). Default 0."}}})"),
         false, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"save", "level"}, "render.occlusion");
            int level = 0;
            if (a.is_object() && a.contains("level") && !a["level"].is_null()) {
                if (!a["level"].is_number_integer() || a["level"].get<long long>() < 0 ||
                    a["level"].get<long long>() > 16)
                    throw CommandError(
                        "invalid_argument", "render.occlusion: `level` is a whole number from 0 to 16.",
                        "Pass \"level\": 0 for the finest level of the depth pyramid, 2 for 64 cells across.");
                level = int(a["level"].get<long long>());
            }
            std::string save;
            if (a.is_object() && a.contains("save") && !a["save"].is_null()) {
                if (!a["save"].is_string())
                    throw CommandError("invalid_argument",
                                       std::string("render.occlusion: `save` is a path, got ") + a["save"].type_name() +
                                           ".",
                                       "Pass \"save\": \".factoria/tmp/occlusion.png\" or leave it out.");
                save = a["save"].get<std::string>();
                std::string lower = save;
                std::transform(lower.begin(), lower.end(), lower.begin(),
                               [](unsigned char c) { return char(std::tolower(c)); });
                if (lower.size() < 4 || lower.compare(lower.size() - 4, 4, ".png") != 0)
                    throw CommandError("invalid_argument",
                                       "render.occlusion: `save` is \"" + save + "\", which is not a .png file name.",
                                       "Pass a path that ends in .png, e.g. \".factoria/tmp/occlusion.png\".");
                save = resolve_caller_write_path(save, "render.occlusion");
            }
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no occlusion culling is done.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            engine.render_now();
            return I.renderer->occlusion_report(save, level);
        });

    I.commands.add(
        {"render.probe_refresh",
         "Capture a realtime reflection probe again (or every realtime probe) as soon as the frame budget allows.",
         "Queues one more capture of the ReflectionProbe `entity` (or of every realtime probe when `entity` is left "
         "out): "
         "the one that an `onDemand` probe waits for, and a way to refresh a `timeSliced` or `everyFrame` probe after "
         "the "
         "scene around it changed. The capture is made in the next frames, a few cube faces each "
         "(render.probes shows `facesDone` and `captures`; the faces per frame are the renderer's budget, 2 by "
         "default), "
         "so draw a few frames before reading it. Result: {refreshed: [entity ids], skipped: [{entity, reason}]}. "
         "Without `entity`, a probe that has no tile yet is listed in `skipped` with the reason; with `entity` it is "
         "an "
         "error. Example: render.probe_refresh {\"entity\": \"lobby\"}" FA_COMMAND_DETAILS
         "Errors: `invalid_arguments` for an `entity` that is not a string; `not_found` for an `entity` that does not "
         "exist; `invalid_argument` when the named entity has no ReflectionProbe or is a baked one; "
         "`unavailable` without graphics (graphics=false) or when the named probe has no tile in the atlas. The same "
         "is "
         "Renderer::probe_refresh in C++.",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"The probe's entity (id or name). Default: every realtime probe."}}})"),
         false, "game"},
        [&engine, &I](const Json& a) {
            check_args_known(a, {"entity"}, "render.probe_refresh");
            const bool one = a.is_object() && a.contains("entity") && !a["entity"].is_null();
            if (one && !a["entity"].is_string())
                throw CommandError(
                    "invalid_arguments",
                    std::string("render.probe_refresh: `entity` is a string (the probe's id or name), got ") +
                        a["entity"].type_name() + ".",
                    "Pass the probe as \"entity\": \"lobby\", or leave `entity` out to refresh every "
                    "realtime probe. scene.list_entities shows the ids.");
            const Entity named = one ? need_entity(I.world, a, "entity") : kNullEntity;
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no probes are captured.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            std::vector<Entity> targets;
            if (one) {
                const std::string name = I.world.id_of(named);
                const ReflectionProbe* rp = I.world.get<ReflectionProbe>(named);
                if (!rp)
                    throw CommandError("invalid_argument", "/entity: '" + name + "' has no ReflectionProbe component.",
                                       "Add one first: scene.set_component {\"id\":\"" + name +
                                           "\",\"component\":\"ReflectionProbe\"}.");
                if (rp->mode != ProbeMode::Realtime)
                    throw CommandError("invalid_argument",
                                       "/entity: '" + name + "' is a baked probe: nothing is captured at run time.",
                                       "Bake it again with probe.bake, or set ReflectionProbe.mode to realtime.");
                targets.push_back(named);
            } else {
                I.world.each<ReflectionProbe>([&](Entity e, ReflectionProbe& rp) {
                    if (rp.mode == ProbeMode::Realtime) targets.push_back(e);
                });
            }
            engine.render_now();  // a probe added since the last frame is known to the renderer now
            Json refreshed = Json::array(), skipped = Json::array();
            for (Entity e : targets) {
                const std::string name = I.world.id_of(e);
                if (I.renderer->probe_refresh(e)) {
                    refreshed.push_back(name);
                } else if (one) {
                    throw CommandError(
                        "unavailable",
                        "The probe '" + name + "' has no tile in the atlas, so there is nothing to refresh.",
                        "render.probes says why (noRoom: the atlas is full of probes that matter more; failed: "
                        "see its message). An inactive entity is not captured.");
                } else {
                    skipped.push_back(Json::object(
                        {{"entity", name},
                         {"reason", "no tile in the atlas (inactive, noRoom or failed: render.probes says which)"}}));
                }
            }
            return Json::object({{"refreshed", refreshed}, {"skipped", skipped}});
        });

    I.commands.add(
        {"render.supports",
         "What this renderer can do on this graphics backend and GPU: float targets, linear colour, HDR output, post "
         "effects.",
         "Answers from the renderer's table per backend (GL, GLES3, WebGL2, D3D11, Metal, headless) and from what the "
         "GPU reports, so a game or a tool can ask before it relies on a feature. Without `feature`: {backend, "
         "backendLabel, features: [{name, kind, supported, status, doc, backends}]}; with `feature`: {feature, "
         "backend, "
         "supported, status}. A feature the renderer does not draw is false with the status \"planned (<milestone>)\" "
         "(the lighting of M73 is, until each part lands): this command never claims what is not drawn. Example: "
         "render.supports "
         "{\"feature\":\"floatTargets\"}" FA_COMMAND_DETAILS
         "`kind` is capability (a fact of the GPU: floatTargets, r11g11b10, sampledDepth, computeShaders, "
         "float32Targets), engine "
         "(linearColor, hdrOutput, and the lighting rows of M73: clusteredLights, areaLights, lightCookies, "
         "iesProfiles, "
         "cascadedShadows, pointShadows, spotShadows, contactShadows, environmentMap, reflectionProbes, physicalSky, "
         "lightmaps, lightProbes, volumetricFog, decals, subsurface, realtimeGI, clearCoat, sheen, anisotropy, "
         "transmission, and the 2D rows of M74: 2dSoftShadows, 2dShadowCasters, 2dEmission, 2dLightLayers, "
         "2dLightCookies, 2dRimLight, 2dGeneratedNormals, 2dGlobalIllumination, 2dWater, spriteSceneColor, and the "
         "big-world rows of M75: lodCrossFade, hlod, "
         "impostors, occlusionCpu, occlusionPortals, occlusionGpu, terrain, foliage, and the upscaling rows of M76, "
         "all planned: motionVectors, spatialUpscaler, temporalUpscaler, metalfx (Metal only), dynamicResolution; "
         "temporalAA is the effect row of the same name) or effect "
         "(one per PostProcess effect: ssao, ssr, fog, sunShafts, exposure, "
         "depthOfField, motionBlur, radialBlur, lensDistortion, chromaticAberration, bloom, tonemap, colorGrading, "
         "vignette, sharpen, outline, pixelate, posterize, filmGrain, colorFilter, and temporalAA, planned for M76); "
         "`backends` says on which backends "
         "the feature can ever run. `status` is \"supported\", \"planned (<milestone>)\" for an engine feature or "
         "effect the "
         "renderer does not draw (the M73 lighting rows until their step lands; clusteredLights, areaLights, "
         "lightCookies, iesProfiles, lightmaps, lightProbes, reflectionProbes, volumetricFog, subsurface and "
         "transmission are drawn), or one "
         "sentence that names the backend or the missing "
         "GPU capability. "
         "hdrOutput "
         "is true when the display the window showed its last frame on can show HDR in an encoding the renderer writes "
         "(EDR on Metal, scRGB or HDR10 on D3D11), whatever the scene asks; its status otherwise says why (the "
         "display or the OS setting); render.output says what the window shows. The headless dummy backend (no "
         "GPU) answers false to everything; a headless run with Mesa/EGL is a GL or GLES3 "
         "backend like any other. Errors: `invalid_argument` for a `feature` that is not in the list (with a "
         "did-you-mean); `unavailable` without graphics (graphics=false). The same answer is Renderer::supports(name) "
         "in C++. The whole list also has `limits` {maxTextureSize, maxArrayLayers, maxArrayTextureSize}: the sizes "
         "this "
         "GPU reports (the Terrain's heightmap, layers, splat maps and holes must fit them).",
         parse_schema(R"({"type":"object","properties":{
               "feature":{"type":"string","description":"One feature name (floatTargets, r11g11b10, sampledDepth, computeShaders, float32Targets, linearColor, hdrOutput, a lighting feature of M73 such as cascadedShadows, or a post effect such as bloom or ssao). Omitted: every feature."}}})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"feature"}, "render.supports");
            std::string feature;
            const bool one = a.is_object() && a.contains("feature");
            if (one) {
                if (!a["feature"].is_string())
                    throw CommandError(
                        "invalid_argument", "feature: " + describe_json_value(a["feature"]) + " is not a string.",
                        "Pass one feature name, e.g. \"floatTargets\" or \"bloom\"; leave it out for the whole list.");
                feature = a["feature"].get<std::string>();
                const std::vector<std::string> names = Renderer::feature_names();
                if (std::find(names.begin(), names.end(), feature) == names.end())
                    throw CommandError("invalid_argument",
                                       "feature: unknown feature '" + feature + "'. " + did_you_mean(feature, names),
                                       "Leave `feature` out to list every name with its status.");
            }
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so there is no GPU to ask.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            Json report = I.renderer->supports_report();
            if (!one) return report;
            for (const Json& f : report["features"])
                if (f["name"] == feature)
                    return Json::object({{"feature", feature},
                                         {"backend", report["backend"]},
                                         {"supported", f["supported"]},
                                         {"status", f["status"]}});
            throw CommandError("unavailable", "The renderer reported no feature '" + feature + "'.");
        });

    I.commands.add(
        {"render.material_cost",
         "What the material of a mesh entity costs the renderer: its extra passes, its phase and the features that "
         "only add "
         "shader work.",
         "The one list the Inspector's cost view shows: for the MeshRenderer of entity `id` it says which features are "
         "on and "
         "what each adds to the frame. Returns {id, extraPasses, phase, summary, features: [{name, field, active, "
         "cost, "
         "extraPasses, note}]}. `phase` is \"opaque\" or \"blended\" (blended meshes are drawn after the opaque ones, "
         "far to "
         "near, without writing depth; a transmissive mesh is one of them). `cost` of a feature is \"extraPass\" "
         "(transmission copies the opaque picture once per camera that sees such a mesh: a pass for each reduced half, "
         "one "
         "that writes the atlas and the second half of the main pass; a full-shader material draws the mesh once per "
         "pass), "
         "\"phase\" (blended: no pass, a different place in the frame) or \"shader\" (clear coat, sheen, anisotropy: "
         "more work "
         "per pixel, no pass). `extraPasses` counts the passes of an active feature (0 when it is off), and the "
         "top-level "
         "one adds them up; the pass count of transmission follows the size of the picture (a small one has fewer "
         "halves). "
         "The decision is the renderer's own (a MeshRenderer field replaces the model's, a full-shader material gets "
         "no "
         "layers and no transmission). Example: render.material_cost {\"id\":\"window\"}" FA_COMMAND_DETAILS
         "Errors: `not_found` for an `id` that is not in the scene, `invalid_argument` when the entity has no "
         "MeshRenderer, "
         "`unavailable` without graphics (graphics=false). It loads the entity's mesh and material when they are not "
         "loaded "
         "yet. The same answer is Renderer::material_cost in C++.",
         parse_schema(R"({"type":"object","properties":{
               "id":{"type":"string","description":"The id of an entity with a MeshRenderer."}},"required":["id"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"id"}, "render.material_cost");
            if (!a.is_object() || !a.contains("id") || !a["id"].is_string())
                throw CommandError(
                    "invalid_argument",
                    "id: " +
                        (a.is_object() && a.contains("id") ? describe_json_value(a["id"]) : std::string("missing")) +
                        " is not an entity id string.",
                    "Pass the id of an entity with a MeshRenderer, e.g. {\"id\":\"window\"}.");
            const std::string id = a["id"].get<std::string>();
            const Entity e = I.world.find_by_id(id);
            if (e == kNullEntity)
                throw CommandError(
                    "not_found", "id: no entity '" + id + "' in the scene.",
                    "List the entities with scene.list_entities, or pass the id of the entity you mean.");
            const MeshRenderer* mr = I.world.get<MeshRenderer>(e);
            if (!mr)
                throw CommandError("invalid_argument", "id: entity '" + id + "' has no MeshRenderer.",
                                   "Add one with scene.add_component, or pass the id of a mesh entity.");
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no frame is drawn to cost.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            Json report = I.renderer->material_cost(*mr);
            report["id"] = id;
            return report;
        });

    I.commands.add(
        {"render.light_probes", "The baked light probes of the scene and the light a MeshRenderer receives from them.",
         "Light probes (M73.4d) are the LightProbeGroup components baked by lightmap.bake into the .probes file of the "
         "scene's lightmap manifest "
         "(SceneSettings.lightmaps): a mesh without a lightmap (a moving object, lightmapScale 0, a skinned mesh) "
         "receives their spherical "
         "harmonics in place of the sky's ambient, interpolated at the centre of its bounds (or at "
         "MeshRenderer.probeAnchor). Without `entity`: "
         "{lightmaps, baked, probes, invalid, groups: [{id, kind: \"grid\" | \"points\", count, invalid, stale}], "
         "unbaked: [ids]}; `invalid` "
         "probes sit inside geometry and are "
         "skipped. With `entity` (a MeshRenderer): also {entity: {id, name, source: \"probes\" | \"lightmap\" | "
         "\"sky\" | \"none\", position, "
         "coverage (0..1: how much of the light comes from the probes, the rest from the sky), probesUsed, sh (nine "
         "[r, g, b] coefficients), "
         "ambient: {up, down, east, west, north, south} (the diffuse light a surface facing that way gets), note}}; "
         "`sky` means no probe reaches "
         "it. Floats are rounded to 3 digits. Needs graphics. Example: render.light_probes "
         "{\"entity\":\"Player\"}" FA_COMMAND_DETAILS
         "A group is `stale` when its LightProbeGroup was edited (moved, resized, other spacing or points) since the "
         "bake; `unbaked` lists the scene's groups the baked file does not hold (added or edited since): bake again "
         "for both. Both are left out when the scene has no baked probes. "
         "Errors: `invalid_argument` for an `entity` that is not a string; `not_found` for an entity that does not "
         "exist; `unavailable` "
         "without graphics (graphics=false). The same is Renderer::light_probes_report in C++.",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"The MeshRenderer entity (id or name) whose received light to report. Default: only the scene's probes."}}})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"entity"}, "render.light_probes");
            const bool one = a.is_object() && a.contains("entity") && !a["entity"].is_null();
            if (one && !a["entity"].is_string())
                throw CommandError(
                    "invalid_argument",
                    std::string("render.light_probes: `entity` is a string (the entity's id or name), got ") +
                        a["entity"].type_name() + ".",
                    "Pass \"entity\": \"Player\", or leave `entity` out. scene.list_entities shows the ids.");
            const Entity e = one ? need_entity(I.world, a, "entity") : kNullEntity;
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no probe is read.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            return I.renderer->light_probes_report(I.world, e);
        });

    I.commands.add(
        {"render.upscaler",
         "Reads or changes the upscaler setting: how a picture drawn at a lower resolution reaches the screen.",
         "The engine-wide upscaler of M76 (docs/UPSCALING.md): `mode` (stretch, spatial, temporal, metalfx, auto), "
         "`quality` (native, quality, balanced, performance, ultraPerformance) and `sharpness` (0 to 1). With no "
         "argument it returns the setting; with any of the three it changes those and keeps the rest. Returns "
         "{mode, quality, sharpness, effectiveMode, scale, changed}: effectiveMode is the mode the renderer really "
         "draws with and scale the share of the output's width and height the quality draws. Example: render.upscaler "
         "{\"mode\":\"auto\",\"quality\":\"balanced\"}" FA_COMMAND_DETAILS
         "It only stores and reports: the renderer draws every mode as \"stretch\" (effectiveMode) until the packages "
         "that draw the others land, so the picture does not change yet. The start value is factoria.json "
         "\"render\": {\"upscaler\": {...}}; window.upscaler in scripts is the same setting. A wrong name or number "
         "fails with `invalid_argument`, the valid values and a \"did you mean\", and changes nothing. Works with "
         "graphics=false too (the value is only remembered).",
         parse_schema(R"({"type":"object","properties":{
               "mode":{"type":"string","enum":["stretch","spatial","temporal","metalfx","auto"],"description":"stretch (the plain blit), spatial (edge-adaptive upscale + sharpen), temporal (jittered frames accumulated), metalfx (Apple, Metal only), auto (the best this GPU can draw)."},
               "quality":{"type":"string","enum":["native","quality","balanced","performance","ultraPerformance"],"description":"How much smaller than the output the frame is drawn: 1, 1/1.5, 1/1.7, 1/2, 1/3 of its width and height."},
               "sharpness":{"type":"number","minimum":0,"maximum":1,"description":"Contrast-adaptive sharpen strength of the spatial and temporal modes, 0..1."}}})"),
         false, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"mode", "quality", "sharpness"}, "render.upscaler");
            const render::UpscalerSettings before = I.self->upscaler();
            bool changed = false;
            if (a.is_object() && !a.empty()) {
                const std::string err = I.self->set_upscaler(a);
                if (!err.empty())
                    throw CommandError("invalid_argument", err,
                                       "Call render.upscaler with no argument to read the setting.");
                changed = I.self->upscaler() != before;
            }
            const render::UpscalerSettings now = I.self->upscaler();
            Json out = render::upscaler_to_json(now);
            out["effectiveMode"] = std::string(render::upscaler_mode_name(render::effective_upscaler_mode(now)));
            out["scale"] = std::round(double(render::upscaler_quality_scale(now.quality)) * 1000.0) / 1000.0;
            out["changed"] = changed;
            return out;
        });

    // graphics.preset and graphics.detect: the names, arguments and docs are fixed here (M76-P0); the package that builds them (P6a)
    // replaces the handler and keeps the rest. Until then each fails with `not_built` and changes nothing (the M75 pattern).
    for (const char* name : {"graphics.preset", "graphics.detect"}) {
        const bool preset = std::string_view(name) == "graphics.preset";
        const std::string cmd = name;
        I.commands.add(
            {name,
             preset ? "Apply a graphics preset (low, medium, high, ultra) to the render settings of the game."
                    : "Measure this device and pick the graphics preset that suits it.",
             preset ? std::string("Will set the settings a graphics options menu offers (render scale, upscaler, "
                                  "shadows, ambient occlusion, "
                                  "antialiasing ...) to the values of the preset `name`: low, medium, high or ultra "
                                  "(custom = what the game "
                                  "set itself; it cannot be applied). Result: {preset, changes}. Example: "
                                  "graphics.preset {\"name\":\"high\"}")
                    : std::string("Will read the device (game.device: GPU backend, memory, tier) and answer the preset "
                                  "that suits it, "
                                  "without changing anything. Result: {preset, reason}. Example: graphics.detect {}"),
             preset ? parse_schema(R"({"type":"object","properties":{
               "name":{"type":"string","enum":["low","medium","high","ultra"],"description":"The preset to apply (case does not matter)."}},"required":["name"]})")
                    : parse_schema(R"({"type":"object","properties":{}})"),
             !preset, "game"},
            [cmd](const Json&) -> Json {
                throw CommandError("not_built", cmd + " is not built yet: it is planned for M76.",
                                   "The graphics presets are built by M76 (docs/UPSCALING.md). Until then set the "
                                   "settings one by one: "
                                   "window.renderScale, window.upscaler or render.upscaler, and the PostProcess "
                                   "fields. Nothing was changed.");
            });
    }

    I.commands.add(
        {"render.output",
         "What the game window shows: the standard range or HDR, in which encoding, and what the display can do.",
         "The window's swapchain switches to HDR when SceneSettings.hdrOutput is \"auto\", the display the window is "
         "on "
         "can show HDR and the renderer writes that encoding (docs/RENDERING.md, \"HDR output\"); this command says "
         "what "
         "happened and why. Returns {hdrActive, encoding, swapchainFormat, requested, paperWhiteNits, maxNits, "
         "headroom, "
         "status, display}. Example: render.output {}" FA_COMMAND_DETAILS
         "`encoding` is \"sdr\" (8-bit sRGB), \"edr\" (macOS and iOS: 16-bit float in extended linear sRGB, 1.0 = "
         "the display's white), \"scRGB\" (Windows: 16-bit float, linear, 1.0 = 80 nits) or \"hdr10\" (Windows: "
         "10-bit ST 2084 PQ in Rec.2020). Only the tonemap of a PostProcess goes above paper white; while the picture "
         "stays within it (no exposure or tonemap, a colour filter, an 8-bit GPU) `status` says so. `swapchainFormat` "
         "is "
         "\"BGRA8\", \"RGBA16F\" or \"RGB10A2\" (\"\" without a window or before the first frame). `requested`: the "
         "current scene's hdrOutput is auto. `headroom`: how many times brighter than paper white the output can go "
         "now (the screen's current EDR "
         "headroom; maxNits / paperWhiteNits in scRGB and HDR10; 1 in sdr), rounded to 2 decimals. `status`: one "
         "sentence, what is shown or why the window stays in the standard range (hdrOutput off, Windows' HDR switch "
         "off, a screen without EDR, the editor, a platform without HDR output). `display`: {known, hdr, name, offers: "
         "[encodings], maxNits, minNits, maxFullFrameNits, maxHeadroom, headroom, why}; nits are 0 where the platform "
         "does not report them (macOS, iOS), headrooms are 1 outside Apple. The answer is the one of the last frame "
         "the "
         "window presented (the display is asked once per frame: moving the window to another monitor or switching HDR "
         "in the OS settings shows on the next one). Headless runs, graphics=false, Linux, Android and the web answer "
         "sdr with display.known false or the platform's reason. The same answer is Renderer::output_info() in C++.",
         parse_schema(R"({"type":"object","properties":{}})"), true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {}, "render.output");
            const HdrOutputInfo info = I.renderer ? I.renderer->output_info() : app_hdr_output();
            const SceneSettings& settings = I.world.settings();
            const float paperWhite =
                std::isfinite(settings.paperWhiteNits)
                    ? std::round(std::clamp(settings.paperWhiteNits, 80.0f, 1000.0f) * 100.0f) / 100.0f
                    : 200.0f;
            auto offers = [](unsigned bits) {
                Json list = Json::array();
                for (int i = 0; i < kHdrEncodingCount; ++i)
                    if (bits & hdr_encoding_bit(HdrEncoding(i))) list.push_back(hdr_encoding_name(HdrEncoding(i)));
                return list;
            };
            const HdrDisplay& d = info.display;
            Json display = Json::object({{"known", d.known},
                                         {"hdr", d.hdr},
                                         {"name", d.name},
                                         {"offers", offers(d.offers)},
                                         {"maxNits", d.maxNits},
                                         {"minNits", d.minNits},
                                         {"maxFullFrameNits", d.maxFullFrameNits},
                                         {"maxHeadroom", d.maxHeadroom},
                                         {"headroom", d.headroom},
                                         {"why", d.why}});
            return Json::object({{"hdrActive", info.active},
                                 {"encoding", hdr_encoding_name(info.encoding)},
                                 {"swapchainFormat", info.swapchainFormat},
                                 {"requested", settings.hdrOutput == HdrOutput::Auto},
                                 {"paperWhiteNits", paperWhite},
                                 {"maxNits", info.maxNits},
                                 {"headroom", info.headroom},
                                 {"status", info.status},
                                 {"display", std::move(display)}});
        });

    I.commands.add(
        {"render.debug_view",
         "Show the depth or the normals of the depth and normal prepass, the ambient occlusion, the cascades of the "
         "sun's shadow or the occlusion culling, instead of the game picture, or report which view is on.",
         "A way to look at the data the depth-based post effects (ssao, depth of field, fog...) read: `depth` paints "
         "the "
         "prepass depth as a grey (10 / (10 + distance), white next to the camera), `normals` the view-space normal as "
         "colours (a surface that faces the camera is blue), black where no opaque mesh was drawn; `ao` paints the "
         "ambient occlusion alone as a grey (white = open or no mesh, dark = occluded) over the camera's rectangle, "
         "with the camera's own "
         "PostProcess ssao settings or, when it has none, the defaults; `cascades` tints every mesh by the cascade of "
         "the directional light's shadow it falls in (red, green, blue, yellow for the first to the fourth, grey past "
         "the last or with no shadow); `none` shows the game "
         "again. It is a look at the data for a person or an AI checking a scene, not an effect: it is not saved and a "
         "game does not set it. Without `view` it only reports the current one. Result: {view, previous}. The view "
         "shows from the next frame (game.step, then game.screenshot). Example: render.debug_view "
         "{\"view\":\"depth\"}" FA_COMMAND_DETAILS
         "`occlusion` keeps the game picture and draws the Occluder boxes green and "
         "the boxes of the meshes the occlusion culling left out red, with a line of counts (docs/BIG_WORLDS_LOD.md, "
         "\"Occlusion\"; render.occlusion saves its depth buffer). "
         "The environment variable FA_RENDER_DEBUG_VIEW sets the first view "
         "at start. The picture changes only on a frame "
         "that draws the prepass (a post effect that reads the depth is on, see docs/RENDERING.md, \"Depth and "
         "normals\"; `cascades` needs only a directional light with castShadows). Errors: `invalid_arguments` for a "
         "`view` that is not none, depth, normals, ao, cascades or occlusion (with a "
         "did-you-mean); "
         "`unavailable` without graphics (graphics=false). The same is Renderer::set_debug_view in C++.",
         parse_schema(R"({"type":"object","properties":{
               "view":{"type":"string","enum":["none","depth","normals","ao","cascades","occlusion"],"description":"none (the game picture), depth, normals, ao (the ambient occlusion), cascades (the meshes tinted by the cascade of the sun's shadow they fall in) or occlusion (wire boxes: Occluders green, meshes the occlusion culling hid red). Omitted: report the current view."}}})"),
         false, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"view"}, "render.debug_view");
            auto name_of = [](DebugView v) {
                return v == DebugView::Depth       ? "depth"
                       : v == DebugView::Normals   ? "normals"
                       : v == DebugView::Ao        ? "ao"
                       : v == DebugView::Cascades  ? "cascades"
                       : v == DebugView::Occlusion ? "occlusion"
                                                   : "none";
            };
            // The schema (enum) already turned a value that is not a string, or not one of the three, into an
            // invalid_arguments error with a did-you-mean hint before this runs.
            const bool set = a.is_object() && a.contains("view");
            const std::string wanted = set ? a["view"].get<std::string>() : std::string();
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so there is nothing to show.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            const DebugView previous = I.renderer->debug_view();
            if (set)
                I.renderer->set_debug_view(wanted == "depth"       ? DebugView::Depth
                                           : wanted == "normals"   ? DebugView::Normals
                                           : wanted == "ao"        ? DebugView::Ao
                                           : wanted == "cascades"  ? DebugView::Cascades
                                           : wanted == "occlusion" ? DebugView::Occlusion
                                                                   : DebugView::None);
            return Json::object({{"view", name_of(I.renderer->debug_view())}, {"previous", name_of(previous)}});
        });

    I.commands.add(
        {"render.reset_post_history",
         "Start again the history of the custom post passes that read their own output of the frame before "
         "(fa_history).",
         "A custom post material whose snippet calls fa_history(uv) (trails, feedback, accumulation; "
         "docs/shaders/SHADERS_POST.md, \"History\") keeps its output of the frame before. This forgets it for one "
         "camera "
         "(`entity`) or every camera: from the next frame fa_history_valid is false and fa_history(uv) gives the "
         "picture, so the "
         "effect starts clean. The renderer already does it by itself in the first frame, after a resize or a change "
         "of render "
         "scale, when a camera was not drawn in the frame before, and when the scene or the world's clock jumps; call "
         "it at a cut "
         "the renderer cannot see (a camera switch inside one scene). Nothing is freed: the images stay for the next "
         "frame. "
         "Result: {reset: \"all\" or the camera}. Example: render.reset_post_history {}" FA_COMMAND_DETAILS
         "A camera without such passes is accepted and nothing changes. Errors: `invalid_arguments` for an `entity` "
         "that is not a string; `not_found` for an `entity` that does not "
         "exist; `unavailable` without graphics (graphics=false). The same is Renderer::reset_post_history in C++.",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"The camera (id or name). Default: every camera."}}})"),
         false, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"entity"}, "render.reset_post_history");
            const bool one = a.is_object() && a.contains("entity") && !a["entity"].is_null();
            if (one &&
                !a["entity"].is_string())  // never a get<string> on another type: it would throw out of the handler
                throw CommandError("invalid_arguments",
                                   std::string("render.reset_post_history: `entity` is a string (the camera's id or "
                                               "name), got ") +
                                       a["entity"].type_name() + ".",
                                   "Pass the camera as \"entity\": \"Main Camera\", or leave `entity` out to reset "
                                   "every camera. scene.list_entities shows the ids.");
            const Entity camera = one ? need_entity(I.world, a, "entity") : kNullEntity;
            const std::string cameraName = one ? a["entity"].get<std::string>() : std::string("all");
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable",
                                   "No renderer: the engine runs with graphics=false, so no pass keeps a history.",
                                   "Run with graphics (headless needs Mesa/EGL on Linux), not graphics=false.");
            I.renderer->reset_post_history(one ? camera.bits() : 0);
            return Json::object({{"reset", cameraName}});
        });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
                                                 {"render.output", capability_sets::reads()},
                                                 {"render.reset_post_history", capability_sets::changes_state()},
                                                 {"render.supports", capability_sets::reads()},
                                                 {"render.upscaler", capability_sets::changes_state()},
                                                 {"graphics.preset", capability_sets::changes_state()},
                                                 {"graphics.detect", capability_sets::reads()},
                                                 {"render.material_cost", capability_sets::reads()},
                                                 {"render.probes", capability_sets::reads()},
                                                 {"render.gi_grid", capability_sets::reads()},
                                                 {"render.gi2d_field", capability_sets::changes_state()},
                                                 {"render.occlusion", capability_sets::changes_state()},
                                                 {"render.probe_refresh", capability_sets::changes_state()},
                                                 {"render.light_probes", capability_sets::reads()},
                                                 {"render.debug_view", capability_sets::changes_state()},
                                                 {"game.screenshot", capability_sets::changes_state()},
                                                 {"render.inspect", capability_sets::reads()},
                                                 {"render.pick", capability_sets::reads()},
                                                 {"render.frame_graph", capability_sets::reads()},
                                             });
}

}  // namespace fa
