// assets.pack_atlas: packs a folder of images into one PNG and writes the frame table (rectangle and pivot of each frame) that a
// Sprite's `region` reads. Packing again keeps the frames whose size did not change where they were, so a diff of the atlas and of
// the table shows only what you touched, and scenes that copied a rect keep drawing the same picture.
#include <algorithm>
#include <format>
#include <map>
#include <set>
#include <tuple>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "export_internal.h"  // blit_extruded and the padding of the export's atlas packer
#include "fa/core/strings.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr int kBlock = 4;  // pages are a whole number of 4x4 blocks, like the export's atlas pages (compressed textures need it)
constexpr int kMinSide = 64;
constexpr int kMaxSideLimit = 16384;

struct R {
    int x = 0, y = 0, w = 0, h = 0;
    bool intersects(const R& o) const { return x < o.x + o.w && o.x < x + w && y < o.y + o.h && o.y < y + h; }
    bool contains(const R& o) const { return o.x >= x && o.y >= y && o.x + o.w <= x + w && o.y + o.h <= y + h; }
};

struct Frame {
    std::string name;
    Image image;
    R rect;  // inside the page, padding excluded
    bool kept = false;
};

// The free space of a page: rectangles that may overlap, none inside another (the MaxRects scheme).
struct FreeSpace {
    std::vector<R> free;
    explicit FreeSpace(int side) : free{{0, 0, side, side}} {}
    void occupy(const R& o) {
        std::vector<R> next;
        for (const R& f : free) {
            if (!f.intersects(o)) {
                next.push_back(f);
                continue;
            }
            if (o.x > f.x) next.push_back({f.x, f.y, o.x - f.x, f.h});
            if (o.x + o.w < f.x + f.w) next.push_back({o.x + o.w, f.y, f.x + f.w - o.x - o.w, f.h});
            if (o.y > f.y) next.push_back({f.x, f.y, f.w, o.y - f.y});
            if (o.y + o.h < f.y + f.h) next.push_back({f.x, o.y + o.h, f.w, f.y + f.h - o.y - o.h});
        }
        free.clear();
        for (std::size_t i = 0; i < next.size(); ++i) {
            bool inside = false;
            for (std::size_t j = 0; j < next.size() && !inside; ++j)
                inside = i != j && next[j].contains(next[i]) && (!next[i].contains(next[j]) || j < i);
            if (!inside) free.push_back(next[i]);
        }
    }
    // The free rectangle that leaves the least room on its shorter side (top-left first on a tie).
    const R* best(int w, int h) const {
        const R* found = nullptr;
        long bestShort = 0;
        for (const R& f : free) {
            if (f.w < w || f.h < h) continue;
            const long s = std::min(f.w - w, f.h - h);
            if (!found || s < bestShort || (s == bestShort && std::tie(f.y, f.x) < std::tie(found->y, found->x))) {
                found = &f;
                bestShort = s;
            }
        }
        return found;
    }
};

bool is_image_file(const std::string& name) {
    const std::string ext = to_lower(fs::extension(name));
    return ext == ".png" || ext == ".jpg" || ext == ".jpeg" || ext == ".tga" || ext == ".bmp";
}

Json read_table(const stdfs::path& file) {
    const auto text = tooling_detail::read_file(file);
    if (!text) return Json();
    auto parsed = parse_json(*text, file.generic_string());
    return parsed.ok() && parsed->is_object() ? *parsed : Json();
}

Json pack_atlas(const std::string& projectDir, const Json& a) {
    const std::string folderArg = tooling_detail::arg_string(a, "folder", true);
    const std::string outArg = tooling_detail::arg_string(a, "out", true);
    const int maxSize = int(tooling_detail::arg_int(a, "maxSize", 2048));
    const int pad = int(tooling_detail::arg_int(a, "padding", export_detail::kAtlasPadding));
    if (maxSize < kMinSide || maxSize > kMaxSideLimit)
        fail("invalid_argument", "maxSize is " + std::to_string(maxSize) + ".",
             "Use " + std::to_string(kMinSide) + ".." + std::to_string(kMaxSideLimit) + "; 2048 is what every phone samples, 4096 what desktops do.");
    if (pad < 0 || pad > 32) fail("invalid_argument", "padding is " + std::to_string(pad) + ".", "Use 0..32 pixels (default 2: the edge pixels are repeated that far around each frame).");

    auto folder = fs::normalize_checked(folderArg);
    if (!folder.ok() || folder->empty()) fail("invalid_argument", "Invalid folder '" + folderArg + "'.", "Use a project-relative folder such as \"assets/src/frames\".");
    auto out = fs::normalize_checked(outArg);
    if (!out.ok() || out->empty() || to_lower(fs::extension(*out)) != ".png")
        fail("invalid_argument", "`out` must be a project-relative .png path.", "For example \"assets/atlas.png\".");
    const std::string tableArg = tooling_detail::arg_string(a, "table", false, out->substr(0, out->size() - 4) + ".json");
    auto table = fs::normalize_checked(tableArg);
    if (!table.ok() || table->empty() || to_lower(fs::extension(*table)) != ".json")
        fail("invalid_argument", "`table` must be a project-relative .json path.", "For example \"data/atlas.json\".");
    for (const std::string* w : {&*out, &*table})
        if (auto c = fs::check_writable(*w); !c.ok()) fail("invalid_argument", c.error().message, c.error().hint);

    const stdfs::path dir = project_file(projectDir, *folder);
    std::error_code ec;
    if (!stdfs::is_directory(dir, ec))
        fail("not_found", "The folder '" + *folder + "' does not exist.", "Put the frames (png, jpg, tga, bmp) in a folder of the project and give its path.");

    require_usable_manifest(projectDir);
    // ---- the frames: every image under the folder, named by its path without the extension ----
    const stdfs::path outFile = project_file(projectDir, *out);
    std::vector<std::string> files;
    for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec) || !is_image_file(it->path().filename().generic_string())) continue;
        if (stdfs::equivalent(it->path(), outFile, ec)) continue;  // the atlas itself, when it lives in the folder
        files.push_back(stdfs::relative(it->path(), dir, ec).generic_string());
    }
    std::sort(files.begin(), files.end());
    if (files.empty())
        fail("not_found", "The folder '" + *folder + "' has no images.", "Put the frames (png, jpg, tga, bmp) in it; subfolders are read too.");
    std::vector<Frame> frames;
    std::map<std::string, std::string> source;  // frame name -> file, to catch two files with the same name
    for (const std::string& rel : files) {
        Frame f;
        f.name = rel.substr(0, rel.size() - fs::extension(rel).size());
        if (auto dup = source.find(f.name); dup != source.end())
            fail("invalid_argument", "'" + dup->second + "' and '" + rel + "' would both be the frame '" + f.name + "'.", "Rename or remove one of them.");
        source[f.name] = rel;
        auto img = load_image(dir / rel);
        if (!img.ok()) fail("invalid_argument", *folder + "/" + rel + ": " + img.error().message, img.error().hint);
        f.image = std::move(*img);
        if (f.image.width + 2 * pad > maxSize || f.image.height + 2 * pad > maxSize)
            fail("invalid_argument",
                 std::format("{}/{} is {}x{} and, with {} px of padding, does not fit a page of {}x{}.", *folder, rel, f.image.width, f.image.height, pad, maxSize, maxSize),
                 "Raise maxSize (a 4096 atlas is fine on desktop), lower padding, or scale the picture down.");
        frames.push_back(std::move(f));
    }

    // ---- pivots: <folder>/pivots.json, { "frame name": [px, py] } (Sprite.pivot, +Y up); every other frame is [0.5, 0.5] ----
    Json warnings = Json::array();
    std::map<std::string, Json> pivots;
    const stdfs::path pivotFile = dir / "pivots.json";
    if (stdfs::is_regular_file(pivotFile, ec)) {
        auto parsed = parse_json(tooling_detail::read_file(pivotFile).value_or(""), *folder + "/pivots.json");
        if (!parsed.ok() || !parsed->is_object())
            fail("invalid_argument", *folder + "/pivots.json is not a JSON object: " + (parsed.ok() ? "it is " + std::string(parsed->type_name()) + "." : parsed.error().message),
                 "It maps a frame name to its pivot, for example {\"hero.0\": [0.5, 0]}.");
        for (const auto& [name, v] : parsed->items()) {
            if (!v.is_array() || v.size() != 2 || !v[0].is_number() || !v[1].is_number())
                fail("invalid_argument", *folder + "/pivots.json: the pivot of '" + name + "' must be [x, y] numbers, like Sprite.pivot.", "For example \"" + name + "\": [0.5, 0].");
            if (!source.contains(name)) {
                std::vector<std::string> names;
                for (const auto& [k, _] : source) names.push_back(k);
                const std::string guess = closest_match(name, names);
                warnings.push_back(*folder + "/pivots.json names '" + name + "', which is not a frame" + (guess.empty() ? "." : " (did you mean '" + guess + "'?)."));
                continue;
            }
            pivots[name] = v;
        }
    }

    // ---- the previous table: frames of the same size stay where they were ----
    const stdfs::path tableFile = project_file(projectDir, *table);
    const Json old = read_table(tableFile);
    std::map<std::string, R> oldRects;
    if (old.is_object() && old.value("texture", std::string()) == *out && old.contains("frames") && old["frames"].is_object())
        for (const auto& [name, fr] : old["frames"].items()) {
            if (!fr.is_object() || !fr.contains("rect") || !fr["rect"].is_array() || fr["rect"].size() != 4) continue;
            const Json& r = fr["rect"];
            if (!std::all_of(r.begin(), r.end(), [](const Json& n) { return n.is_number_integer(); })) continue;
            oldRects[name] = {r[0].get<int>(), r[1].get<int>(), r[2].get<int>(), r[3].get<int>()};
        }
    std::vector<R> occupied;  // padded rectangles of the kept frames
    for (Frame& f : frames) {
        auto it = oldRects.find(f.name);
        if (it == oldRects.end() || it->second.w != f.image.width || it->second.h != f.image.height) continue;
        const R r = it->second;
        const R padded{r.x - pad, r.y - pad, r.w + 2 * pad, r.h + 2 * pad};
        if (padded.x < 0 || padded.y < 0 || padded.x + padded.w > maxSize || padded.y + padded.h > maxSize) continue;
        if (std::any_of(occupied.begin(), occupied.end(), [&](const R& o) { return o.intersects(padded); })) continue;
        f.rect = r;
        f.kept = true;
        occupied.push_back(padded);
    }

    // ---- place the others, tallest first, in the smallest square page that holds them (kept frames never move) ----
    std::vector<Frame*> todo;
    for (Frame& f : frames)
        if (!f.kept) todo.push_back(&f);
    std::sort(todo.begin(), todo.end(), [](const Frame* l, const Frame* r) {
        return std::tie(r->image.height, r->image.width, l->name) < std::tie(l->image.height, l->image.width, r->name);
    });
    int keptExtent = 0;
    for (const R& o : occupied) keptExtent = std::max({keptExtent, o.x + o.w, o.y + o.h});
    std::vector<R> placed(todo.size());
    bool fits = todo.empty();
    for (int side = kMinSide; !fits; side *= 2) {
        side = std::min(side, maxSize);
        if (side >= keptExtent) {
            FreeSpace space(side);
            for (const R& o : occupied) space.occupy(o);
            fits = true;
            for (std::size_t i = 0; i < todo.size() && fits; ++i) {
                const int w = todo[i]->image.width + 2 * pad, h = todo[i]->image.height + 2 * pad;
                const R* spot = space.best(w, h);
                if (!spot) {
                    fits = false;
                    break;
                }
                const R box{spot->x, spot->y, w, h};
                placed[i] = {box.x + pad, box.y + pad, todo[i]->image.width, todo[i]->image.height};
                space.occupy(box);
            }
        }
        if (!fits && side >= maxSize) break;
    }
    if (!fits) {
        long area = 0;
        for (const Frame& f : frames) area += long(f.image.width + 2 * pad) * (f.image.height + 2 * pad);
        fail("failed",
             std::format("The {} frames of '{}' do not fit one {}x{} page (they need about {} pixels of {}).", frames.size(), *folder, maxSize, maxSize, area, long(maxSize) * maxSize),
             "Raise maxSize (up to 4096 on desktop), lower padding, scale pictures down, or pack the folder in two atlases (a subfolder each).");
    }
    for (std::size_t i = 0; i < todo.size(); ++i) todo[i]->rect = placed[i];

    // ---- draw the page and write the table ----
    int usedW = 0, usedH = 0;
    for (const Frame& f : frames) {
        usedW = std::max(usedW, f.rect.x + f.rect.w + pad);
        usedH = std::max(usedH, f.rect.y + f.rect.h + pad);
    }
    Image page;
    page.width = (usedW + kBlock - 1) / kBlock * kBlock;
    page.height = (usedH + kBlock - 1) / kBlock * kBlock;
    page.rgba.assign(std::size_t(page.width) * page.height * 4, 0);
    Json frameTable = Json::object();
    for (const Frame& f : frames) {
        export_detail::blit_extruded(page, f.image, f.rect.x, f.rect.y, pad);
        const Json pivot = pivots.contains(f.name) ? pivots[f.name] : Json::array({0.5, 0.5});
        frameTable[f.name] = Json::object({{"rect", Json::array({f.rect.x, f.rect.y, f.rect.w, f.rect.h})}, {"pivot", pivot}});
    }
    Json doc = old.is_object() ? old : Json::object();  // keys of your own (a road map, a comment) stay
    doc["texture"] = *out;
    doc["size"] = Json::array({page.width, page.height});
    doc["frames"] = frameTable;

    const auto png = encode_png(page);
    const std::string pngBytes(png.begin(), png.end());
    const std::string tableText = doc.dump(1) + "\n";
    std::string err;
    const bool pngChanged = tooling_detail::read_file(outFile).value_or("") != pngBytes;
    const bool tableChanged = tooling_detail::read_file(tableFile).value_or("") != tableText;
    if (pngChanged && !tooling_detail::write_file(outFile, pngBytes, &err)) fail("failed", err);
    if (tableChanged && !tooling_detail::write_file(tableFile, tableText, &err)) fail("failed", err);

    // The recipe: the frames and pivots.json it read. The previous table is not an input but it matters (frames keep their place),
    // and regenerating over the table this call wrote gives the same bytes. The atlas counts as AI-made when a frame's record says so.
    {
        std::vector<std::string> inputs;
        bool ai = false;
        ProjectRootGuard root(projectDir);
        for (const std::string& rel : files) {
            inputs.push_back(*folder + "/" + rel);
            if (assets::entry(inputs.back()).value("provenance", Json::object()).value("ai", false)) ai = true;
        }
        if (stdfs::is_regular_file(pivotFile, ec)) inputs.push_back(*folder + "/pivots.json");
        const Json recipe = make_recipe(projectDir, "assets.pack_atlas",
                                        recipe_args(a, {{"folder", *folder}, {"out", *out}, {"table", *table}, {"maxSize", maxSize}, {"padding", pad}}), inputs);
        auto r = assets::update_entry(*out, [&](Json& e) {
            e.erase("analysis");
            e["provenance"] = Json::object({{"origin", "original"}, {"ai", ai}, {"kind", "image"}, {"date", assets::today()},
                                            {"notes", "Packed from the images of " + *folder + " by assets.pack_atlas; the frame table is " + *table + "."},
                                            {"recipe", recipe}});
        });
        if (!r.ok()) fail("failed", "The atlas was written, but assets.json was not updated: " + r.error().message, r.error().hint);
    }

    Json added = Json::array(), moved = Json::array(), removed = Json::array();
    int kept = 0;
    for (const Frame& f : frames) {
        if (f.kept) {
            ++kept;
        } else if (oldRects.contains(f.name)) {
            moved.push_back(f.name);
        } else {
            added.push_back(f.name);
        }
    }
    for (const auto& [name, _] : oldRects)
        if (!source.contains(name)) removed.push_back(name);
    const Frame& first = frames.front();
    Json result = Json::object({{"out", *out}, {"table", *table}, {"size", Json::array({page.width, page.height})}, {"frames", int(frames.size())},
                                {"kept", kept}, {"added", added}, {"moved", moved}, {"removed", removed},
                                {"written", pngChanged || tableChanged}});
    if (!warnings.empty()) result["warnings"] = warnings;
    result["nextSteps"] = Json::array({std::format("Draw a frame with a Sprite: {{\"texture\":\"{}\",\"region\":[{},{},{},{}],\"pivot\":{}}} (the rect and pivot of '{}' in {}).",
                                                   *out, first.rect.x, first.rect.y, first.rect.w, first.rect.h, frameTable[first.name]["pivot"].dump(), first.name, *table),
                                       "Scripts read the table with an import: import atlas from \"../data/atlas.json\"; then atlas.frames[name].rect."});
    return result;
}

}  // namespace

void register_pack_atlas_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.pack_atlas";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Pack a folder of images into one atlas PNG and write the frame table (rect and pivot per frame) that a Sprite's `region` reads.";
    info.description =
        "Every image under `folder` (png, jpg, tga, bmp; subfolders too) is a frame named by its path without the extension "
        "(\"ship/0.png\" is \"ship/0\"). They are packed into the smallest square page up to maxSize (tallest first), each with `padding` "
        "pixels of its own edge repeated around it so bilinear filtering and mipmaps never bleed a neighbour (the same padding as the "
        "export's atlas groups). The page is written to `out`, and the table to `table` (default `out` with .json): "
        "{\"texture\":\"assets/atlas.png\",\"size\":[w,h],\"frames\":{\"ship/0\":{\"rect\":[x,y,w,h],\"pivot\":[px,py]}}}. rect is in "
        "texture pixels from the top-left, exactly Sprite.region; pivot is Sprite.pivot (+Y up). Pivots come from "
        "`<folder>/pivots.json` ({\"ship/0\":[0.5,0.2]}); a frame without one is [0.5, 0.5]. Keys of an existing table other than "
        "texture, size and frames are kept, so your own data can live in the same file.\n"
        "Packing again is stable: a frame whose size did not change keeps its rectangle (the page grows, never reshuffles), so a new "
        "picture changes the table by one line and a scene that copied a rect keeps drawing the same picture. Frames removed from the folder "
        "leave holes that new frames fill. Nothing is written when the result would be the same bytes. The result lists what was added, "
        "moved (changed size) and removed. Use this while developing, when many sprites must share one texture (a map of "
        "thousands of tiles, characters of one screen) and you want to pick frames by name; `factoria export` packs `atlas` groups "
        "by itself and Sprites keep naming the source PNGs (docs/ASSETS.md, \"Atlases\"). Example: "
        "{\"folder\":\"assets/src/frames\",\"out\":\"assets/atlas.png\",\"table\":\"data/atlas.json\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["folder","out"],
      "properties":{
        "folder":{"type":"string","description":"Project-relative folder of images; each image (subfolders too) is one frame named by its path without the extension. An optional pivots.json inside gives pivots."},
        "out":{"type":"string","description":"Project-relative .png to write, e.g. \"assets/atlas.png\". Replaced if it exists."},
        "table":{"type":"string","description":"Project-relative .json for the frame table. Default: out with the .json extension."},
        "maxSize":{"type":"integer","minimum":64,"maximum":16384,"description":"Largest side of the page in pixels. Default 2048 (what every phone samples); 4096 is fine on desktop. Frames that do not fit are an error."},
        "padding":{"type":"integer","minimum":0,"maximum":32,"description":"Pixels of the frame's own edge repeated around each frame. Default 2."}
      }})");
    registry.add(info, [projectDir](const Json& args) { return pack_atlas(projectDir, args); });
}

}  // namespace fa::assets_detail
