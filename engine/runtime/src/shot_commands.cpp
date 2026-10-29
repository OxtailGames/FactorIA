// The commands that look at the picture: game.screenshot (whole view, a magnified region, a filmstrip of frames),
// render.inspect (luminance profile along a line and the hard steps in it) and render.pick (what draws a pixel).
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/image_tools.h"
#include "fa/core/strings.h"
#include "fa/scene/bounds.h"
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
        throw CommandError("invalid_argument", std::string("Missing '") + key + "'.", std::string("Pass ") + key + " as [x, y] in design pixels (origin top-left).");
    Vec2 v;
    std::string err;
    if (!json_to(a[key], v, &err)) throw CommandError("invalid_argument", std::string(key) + ": " + err, "Use [x, y] in design pixels.");
    return v;
}

void check_args_known(const Json& a, std::initializer_list<const char*> known, const char* command) {
    if (!a.is_object()) return;
    std::vector<std::string> names;
    for (const char* k : known) names.push_back(k);
    for (auto it = a.begin(); it != a.end(); ++it)
        if (std::find(names.begin(), names.end(), it.key()) == names.end())
            throw CommandError("invalid_argument", std::string(command) + ": unknown argument '" + it.key() + "'. " + did_you_mean(it.key(), names),
                               "The arguments are: " + join(names, ", ") + ".");
}

}  // namespace

void register_shot_commands(Engine& engine, Engine::Impl& I) {
    I.commands.add({"game.screenshot", "Capture the game view as a PNG and show it: whole, a magnified region, or a filmstrip of frames.",
           "Draws the game view as it is now (design resolution) and returns it; clients display the image. Scripts only run "
           "when frames are stepped: step the game first so the picture shows what you expect.\n"
           "WITHOUT `path` the picture is temporary: the result is {width, height, frame, temporary: true, $image: {path, "
           "mimeType, temporary: true}}, the MCP server and the AI assistant attach the image to the message and then DELETE "
           "the file, so do not keep or read that path later. (`factoria call` only prints the result and leaves the file; the "
           "engine removes engine-named files `.factoria/screenshots/frame_<n>*.png` older than 3 days or beyond the newest 200 "
           "when a project opens.) WITH `path` the file is written there and kept, and the result has `path`. Use `path` when your "
           "client cannot show images (then open the file yourself) or when you want to compare pictures later.\n"
           "`scale` (0.25 to 4, default 1) draws the same frame into an image scale times larger, sharp and not upscaled, for store "
           "screenshots: HUD, camera and visible area stay the same, so a 1280x720 game at scale 1.5 gives a 1920x1080 PNG.\n"
           "`region` [x, y, width, height] (design pixels, origin top-left) with `zoom` (0.25 to 32) shows only that part magnified: "
           "use it to look at a seam, a join, a gradient end or a one-pixel gap that is invisible in the whole view. Up to zoom 4 "
           "the frame is drawn again at that render scale and cropped (lines, text and shapes are sharp, the HUD is included); above "
           "4 the 4x picture is enlarged with nearest-neighbour sampling (hard pixel blocks, nothing blurred). The result is "
           "round(width * zoom) x round(height * zoom), at most 8192 px a side; the region is clamped to the view. "
           "`zoom` without `region` magnifies the whole view the same way.\n"
           "`frames` makes a FILMSTRIP: one PNG with a grid of pictures, each labelled with its frame number (\"f130 +4\" = game "
           "frame 130, 4 frames after the start). The first picture is the game now, then the game is STEPPED `everyFrames` "
           "frames (default 1) and captured again until `frames` frames have passed, so frames 48 and everyFrames 4 give 13 "
           "tiles and leave the game 48 frames further. At most 64 tiles. `region` and `zoom` apply to every tile (the same "
           "region each time); without `zoom` the tiles are sized so the sheet is about 2048 px wide (never enlarged). `columns` "
           "sets the grid width (default: nearly square). Use it to see a whole transition or animation at once. A tween or "
           "script keeps running while it steps: it shows what the game does, it does not freeze anything. The result adds "
           "`tiles` [{frame, offset}], `columns`, `rows`, `tileWidth`, `tileHeight` and `zoom`.\n"
           "`simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the picture to what a colour-blind viewer sees "
           "(Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in linear light; greyscale = Rec. 709 luminance) "
           "without changing what the player sees: use it to check that hazards, pickups and buttons read without their colour. "
           "Needs graphics. Examples: game.screenshot {\"path\":\"shots/start.png\",\"scale\":1.5}; "
           "game.screenshot {\"region\":[600,0,80,720],\"zoom\":8}; game.screenshot {\"frames\":48,\"everyFrames\":4,\"region\":[400,200,480,300]}",
           parse_schema(R"({"type":"object","properties":{
               "path":{"type":"string","description":"Output PNG (project-relative or absolute). Given: the file is kept. Omitted: a temporary picture that the client deletes after reading it."},
               "scale":{"type":"number","minimum":0.25,"maximum":4,"description":"Render scale of the whole view (default 1): image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080. Not together with zoom."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[x, y, width, height] in design pixels (origin top-left): only this part of the view is captured, magnified by zoom."},
               "zoom":{"type":"number","minimum":0.25,"maximum":32,"description":"Magnification of the region (or of the whole view): up to 4 a native sharp re-render, above 4 nearest-neighbour enlargement of the 4x picture. Default 1 (a filmstrip without zoom: sized to a sheet about 2048 px wide)."},
               "frames":{"type":"integer","minimum":1,"maximum":2000,"description":"Filmstrip: the game advances this many frames in total, captured every everyFrames, into one labelled grid PNG."},
               "everyFrames":{"type":"integer","minimum":1,"description":"Filmstrip: frames between two pictures (default 1). frames / everyFrames + 1 pictures, at most 64."},
               "columns":{"type":"integer","minimum":1,"maximum":64,"description":"Filmstrip: tiles per row (default: the grid closest to square)."},
               "simulate":{"type":"string","enum":["none","greyscale","protanopia","deuteranopia","tritanopia"],"default":"none","description":"Convert the picture to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged."}}})"),
           true, "game"},
          [&engine, &I](const Json& a) {
              check_args_known(a, {"path", "scale", "region", "zoom", "frames", "everyFrames", "columns", "simulate"}, "game.screenshot");
              const std::string given = a.contains("path") && a["path"].is_string() ? a["path"].get<std::string>() : std::string();
              const bool temporary = given.empty();
              if (a.contains("scale") && a.contains("zoom"))
                  throw CommandError("invalid_argument", "scale and zoom were both given.",
                                     "Use `scale` for a whole-view render scale (store screenshots) or `zoom` (with `region`) to magnify; zoom without a region magnifies the whole view.");
              const double scale = a.value("scale", 1.0);
              if (!(scale >= 0.25 && scale <= 4.0))
                  throw CommandError("invalid_argument", "scale " + std::to_string(scale) + " is out of range.",
                                     "scale must be between 0.25 and 4: the image is design size * scale. Example: 1.5 on a 1280x720 game gives 1920x1080.");
              const std::string simulate = a.value("simulate", std::string("none"));
              auto sim = parse_color_simulation(simulate);
              if (!sim.ok()) throw CommandError("invalid_argument", sim.error().message, sim.error().hint);

              Rect region{};  // w = 0: the whole view
              if (a.contains("region")) {
                  std::string err;
                  if (!json_to(a["region"], region, &err))
                      throw CommandError("invalid_argument", "region: " + err, "Use [x, y, width, height] in design pixels, e.g. [600, 0, 80, 720].");
                  if (!(region.w > 0 && region.h > 0))
                      throw CommandError("invalid_argument", "region has no area (width and height must be above 0).",
                                         "Use [x, y, width, height] in design pixels, e.g. [600, 0, 80, 720].");
              }
              const bool filmstrip = a.contains("frames");
              if (!filmstrip && (a.contains("everyFrames") || a.contains("columns")))
                  throw CommandError("invalid_argument", "everyFrames and columns belong to a filmstrip.", "Add `frames` (the number of frames to cover), e.g. {\"frames\":48,\"everyFrames\":4}.");
              if (!I.renderer)  // the same message as before: no renderer, no picture
                  throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.", "Screenshots need graphics (headless needs Mesa/EGL).");
              const Vec2 view{float(I.renderer->target_width()), float(I.renderer->target_height())};
              std::string err;
              Image img;
              Json tiles = Json::array();
              Json extra = Json::object();
              std::string kind;
              if (!filmstrip) {
                  const double zoom = a.contains("zoom") ? a.value("zoom", 1.0) : scale;
                  const auto plan = Engine::plan_region(view, region, zoom);
                  if (!plan.error.empty()) throw CommandError("invalid_argument", plan.error, "See the `region` and `zoom` arguments of game.screenshot.");
                  if (region.w <= 0 && !a.contains("zoom")) {
                      // The whole view at a render scale: the old path (kept for its limits and messages).
                      if (!engine.capture_scaled(img, scale, &err)) throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                  } else {
                      if (!engine.capture_region(img, region, zoom, &err)) throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                  }
                  if (region.w > 0 || a.contains("zoom")) kind = "_region";
              } else {
                  kind = "_sheet";
                  const int frames = a.value("frames", 1);
                  const int every = a.value("everyFrames", 1);
                  if (frames < 1 || frames > kMaxFilmstripFrames)
                      throw CommandError("invalid_argument", "frames " + std::to_string(frames) + " is out of range (1 to " + std::to_string(kMaxFilmstripFrames) + ").",
                                         "A filmstrip covers a transition: ask for the frames it takes, e.g. frames 48 every 4.");
                  if (every < 1)
                      throw CommandError("invalid_argument", "everyFrames must be at least 1.", "everyFrames is the number of game frames between two pictures.");
                  const int count = frames / every + 1;
                  if (count > kMaxFilmstripTiles)
                      throw CommandError("invalid_argument", std::to_string(count) + " pictures (frames " + std::to_string(frames) + " / everyFrames " + std::to_string(every) +
                                                                  " + 1) is more than the 64 a sheet can hold.",
                                         "Raise everyFrames or lower frames: e.g. frames " + std::to_string(frames) + " with everyFrames " + std::to_string((frames + 62) / 63) + ".");
                  const int wanted = a.value("columns", 0);
                  // Tile size in design pixels (the clamped region) and the zoom.
                  const auto at1 = Engine::plan_region(view, region, 1.0);
                  if (!at1.error.empty()) throw CommandError("invalid_argument", at1.error, "See the `region` argument of game.screenshot.");
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
                  if (!plan.error.empty()) throw CommandError("invalid_argument", plan.error, "See the `region` and `zoom` arguments of game.screenshot.");
                  const SheetLayout predicted = sheet_layout(count, wanted, plan.width, plan.height);
                  if (predicted.width > kMaxSheetSide || predicted.height > kMaxSheetSide)
                      throw CommandError("invalid_argument",
                                         "The sheet would be " + std::to_string(predicted.width) + "x" + std::to_string(predicted.height) + " px (" + std::to_string(count) +
                                             " tiles of " + std::to_string(plan.width) + "x" + std::to_string(plan.height) + "), over the 8192 px limit per side.",
                                         "Use a smaller zoom or region, more columns, or fewer pictures (a larger everyFrames).");
                  std::vector<Image> shots;
                  std::vector<std::string> labels;
                  const int startFrame = I.frame;
                  for (int i = 0; i < count; ++i) {
                      if (i > 0) engine.step(every);
                      Image tile;
                      if (!engine.capture_region(tile, region, zoom, &err)) throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                      simulate_color_vision(tile, *sim);
                      const int offset = I.frame - startFrame;
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
              const std::string path = temporary ? ".factoria/screenshots/frame_" + std::to_string(I.frame) + kind + ".png" : given;
              auto saved = save_png(img, path);
              if (!saved.ok()) throw CommandError("unavailable", saved.error().message, saved.error().hint.empty() ? "Check the path is inside a writable folder." : saved.error().hint);
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

    I.commands.add({"render.inspect", "Luminance profile of the current picture along a line, with the hard steps (seams, bands) in it.",
           "Draws the picture as it is now and reads the pixels along the segment `from` -> `to` (design pixels, origin top-left): "
           "one sample per pixel along the longer axis, as a value 0..255 of the sRGB bytes (`channel`: luminance with Rec. 709 "
           "weights, or red, green, blue). It lists every STEP: a change of at least `threshold` (default 8 levels) within "
           "`window` samples (default 2), which is how a bright seam, a gap between two sprites or the edge of a gradient band "
           "shows in the numbers while the eye misses it. A smooth ramp has no steps; a staircase (Mach bands: two overlapping "
           "gradients) has one per riser. The edge of a sprite or a shape is a step too: find what draws it with render.pick at "
           "the step's `at`. Result: {from, to, channel, scale, count, samples: [values], min, max, steps: [{index, at: [x, y] "
           "(design pixels, the middle of the jump), width, from, to, delta}], stepCount, frame}; at most 200 steps and 4096 "
           "samples. `scale` (0.25 to 4, default 1) samples a render at that scale, so at 4 there are four samples per design "
           "pixel and a sub-pixel gap shows. Look at the area with game.screenshot {region, zoom} first, then measure it. Needs "
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
                  throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.", "Screenshots need graphics (headless needs Mesa/EGL).");
              const Vec2 from = need_vec2(a, "from"), to = need_vec2(a, "to");
              const double threshold = a.value("threshold", 8.0);
              if (!(threshold > 0 && threshold <= 255))
                  throw CommandError("invalid_argument", "threshold " + std::to_string(threshold) + " is out of range.", "threshold is a change in levels, above 0 and at most 255. Try 6 to 12.");
              const int window = a.value("window", 2);
              if (window < 1 || window > 32) throw CommandError("invalid_argument", "window must be between 1 and 32 samples.", "The default 2 finds jumps within two pixels.");
              const double scale = a.value("scale", 1.0);
              if (!(scale >= 0.25 && scale <= 4.0))
                  throw CommandError("invalid_argument", "scale " + std::to_string(scale) + " is out of range.", "scale must be between 0.25 and 4.");
              auto channel = parse_profile_channel(a.value("channel", std::string("luminance")));
              if (!channel.ok()) throw CommandError("invalid_argument", channel.error().message, channel.error().hint);
              const Vec2 view{float(I.renderer->target_width()), float(I.renderer->target_height())};
              for (const Vec2& p : {from, to})
                  if (!(p.x >= 0 && p.y >= 0 && p.x <= view.x && p.y <= view.y))
                      throw CommandError("invalid_argument", std::format("point [{}, {}] is outside the game view ({}x{} design pixels).", p.x, p.y, int(view.x), int(view.y)),
                                         "Both ends must be inside the view, origin top-left.");
              const Vec2 a2{from.x * float(scale), from.y * float(scale)}, b2{to.x * float(scale), to.y * float(scale)};
              if (std::max(std::fabs(b2.x - a2.x), std::fabs(b2.y - a2.y)) + 1 > 4096)
                  throw CommandError("invalid_argument", "The line would have more than 4096 samples.", "Shorten the line or lower `scale`; inspect a stretch at a time.");
              Image img;
              std::string err;
              if (!engine.capture_scaled(img, scale, &err)) throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
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
              auto design = [&](Vec2 p) { return Json::array({std::round(p.x / float(scale) * 100) / 100, std::round(p.y / float(scale) * 100) / 100}); };
              Json stepList = Json::array();
              for (const ProfileStep& s : steps) {
                  // Samples read the pixel under their point, so the change starts with the sample after `index`: the middle of the
                  // points from there to the end of the jump is where the edge lies (an edge between pixels 109 and 110 is at 110).
                  const Vec2 mid = (points[std::size_t(s.index + 1)] + points[std::size_t(s.index + s.width)]) * 0.5f;
                  stepList.push_back(Json::object({{"index", s.index}, {"at", design(mid)}, {"width", s.width},
                                                   {"from", std::round(s.from * 10) / 10}, {"to", std::round(s.to * 10) / 10},
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

    I.commands.add({"render.pick", "Which entities draw a design-space pixel of the picture, topmost first.",
           "Lists the 2D visuals (Sprite, Shape2D, Text, Tilemap, UI widgets) whose drawn box covers `position` (design pixels, "
           "origin top-left), topmost first: screen-space UI above the world, then the higher `layer`, then (world Sprites) the "
           "lower world y, then the one drawn later (component order Tilemap, Sprite, Shape2D, Text; then creation order). Each "
           "hit is {entity, name, component, layer, space: \"world\"|\"screen\"}. Use it to find which shape or sprite causes a "
           "visible artefact (a seam, a dark band) after game.screenshot {region, zoom} or render.inspect located it. The test "
           "is the oriented BOX of the visual (the same footprint as entity.bounds() and the editor's picking): a transparent "
           "corner of a sprite, the corners outside a circle and the parts of a gradient that fade out still count; an "
           "alpha-0 colour is skipped; inactive entities are skipped. The world point is found through the primary camera; "
           "`world` in the result is that point. `widget` is the UI widget a click there would reach (ui_widget_at), or null. "
           "Needs graphics (the camera is the renderer's). Example: render.pick {\"position\":[640,360]}",
           parse_schema(R"({"type":"object","properties":{
               "position":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"[x, y] in design pixels (origin top-left)."},
               "max":{"type":"integer","default":20,"minimum":1,"maximum":200,"description":"At most this many hits."}},
               "required":["position"]})"),
           true, "game"},
          [&engine, &I](const Json& a) {
              check_args_known(a, {"position", "max"}, "render.pick");
              (void)engine;
              if (!I.renderer || !I.renderer->initialized())
                  throw CommandError("unavailable", "render.pick needs the renderer's camera to turn the pixel into a world point.",
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
              int entityIndex = 0;
              for (Entity e : I.world.entities()) {
                  ++entityIndex;
                  if (!I.world.active_in_hierarchy(e)) continue;
                  for (const VisualFootprint& part : visual_footprints(I.world, e, measure, true)) {
                      const bool screen = part.space == RenderSpace::Screen;
                      if (!footprint_hit(I.world, e, part, design, screen ? p : world)) continue;
                      const std::string kind = part.component;
                      // A colour with no alpha draws nothing.
                      float alpha = 1;
                      if (kind == "Sprite") { if (const Sprite* s = I.world.get<Sprite>(e)) alpha = s->color.a; }
                      else if (kind == "Shape2D") {
                          if (const Shape2D* s = I.world.get<Shape2D>(e))
                              alpha = s->gradient != ShapeGradient::None ? std::max(s->color.a, s->color2.a) : s->color.a;
                      } else if (kind == "Text") { if (const Text* t = I.world.get<Text>(e)) alpha = t->color.a; }
                      if (alpha <= 0) continue;
                      static const char* const kOrder[] = {"Tilemap", "Sprite", "Shape2D", "Text"};
                      int rank = 4;
                      for (int i = 0; i < 4; ++i)
                          if (kind == kOrder[i]) rank = i;
                      // The renderer sorts world Sprites by their world y (lower y on top); other visuals have no secondary key.
                      const float secondary = !screen && kind == "Sprite" ? I.world.world_matrix(e).translation().y : 0.0f;
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
                  list.push_back(Json::object({{"entity", I.world.id_of(h.e)}, {"name", I.world.info(h.e).name}, {"component", h.component},
                                               {"layer", h.layer}, {"space", h.screen ? "screen" : "world"}}));
              }
              Json j = Json::object();
              j["position"] = Json::array({p.x, p.y});
              j["world"] = Json::array({w3.x, w3.y});
              j["hits"] = list;
              j["hitCount"] = hits.size();
              if (hits.size() > list.size()) j["truncated"] = true;
              const Entity under = I.ui.widget_at(I.world, design, p, measure);
              j["widget"] = under != kNullEntity && I.world.alive(under) ? Json(I.world.id_of(under)) : Json();
              j["frame"] = I.frame;
              return j;
          });
}

}  // namespace fa
