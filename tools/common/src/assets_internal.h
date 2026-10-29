// Private declarations shared by the sources of assets.import and assets.slice_sheet (assets_*.cpp) and by the asset
// checks of project.validate (validate_assets.cpp). Nothing here is part of the fa_tooling API (that is
// fa/tooling/asset_import.h).
//
//   assets_import.cpp    the command assets.import: where a file goes, what is recorded, the plain copy of the formats
//                        the engine reads as they are
//   assets_aseprite.cpp  Aseprite -> sprite sheet PNG with clips          assets_obj.cpp  OBJ (+ MTL) -> glTF
//   assets_sheet.cpp     the command assets.slice_sheet                   assets_fbx.cpp  FBX -> glb through a converter
//   assets_video.cpp     mp4/mov/webm... -> MPEG-1 .mpg through ffmpeg
#pragma once

#include <array>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

namespace stdfs = std::filesystem;

// ---- what an importer produces ---------------------------------------------------------------------------

struct OutFile {
    std::string path;  // project-relative destination, forward slashes
    std::vector<std::uint8_t> bytes;
};

struct ImportOutput {
    std::vector<OutFile> files;   // files[0] is the asset itself, the others its sidecars (the textures of a model)
    Json sheet;                   // the `sheet` entry of files[0] (null = none)
    Json details;                 // importer-specific facts for the result
    std::vector<std::string> warnings;
    std::vector<std::string> nextSteps;
};

struct ImportRequest {
    stdfs::path source;  // absolute path of the file to import
    std::string dest;    // project-relative path of files[0] (the folder of the sidecars)
    int columns = 0;     // aseprite: columns of the sheet (0 = ceil(sqrt(frames)))
};

Result<ImportOutput> import_aseprite(const ImportRequest& request);
Result<ImportOutput> import_obj(const ImportRequest& request);
Result<ImportOutput> import_fbx(const ImportRequest& request);
Result<ImportOutput> import_video(const ImportRequest& request);

// ---- sprite sheets ---------------------------------------------------------------------------------------

struct SheetClip {
    std::string name;
    int firstFrame = 0;
    int lastFrame = 0;
    double fps = 10;
};

// The `sheet` entry of assets.json (schemas/assets.schema.json) for a grid of `frames` frames.
Json sheet_entry(int columns, int rows, int frameWidth, int frameHeight, int frames, const std::vector<SheetClip>& clips);
// How to play `sheet` (a sheet_entry) from the image `texture`: the Sprite and SpriteAnimator settings, one line each.
std::vector<std::string> sheet_next_steps(const std::string& texture, const Json& sheet, double fps);

// The colour of the four corners of `image` when they are all the same fully opaque colour (to within a few levels,
// which a JPEG-era solid background has): the sign of a background that should be transparent.
std::optional<std::array<std::uint8_t, 3>> opaque_corner_color(const Image& image);

void register_slice_sheet_command(CommandRegistry& registry, const std::string& projectDir);
void register_pack_atlas_command(CommandRegistry& registry, const std::string& projectDir);
void register_draw_icon_command(CommandRegistry& registry, const std::string& projectDir);
void register_draw_capsules_command(CommandRegistry& registry, const std::string& projectDir);
void register_synth_sound_command(CommandRegistry& registry, const std::string& projectDir);
void register_texture_command(CommandRegistry& registry, const std::string& projectDir);  // assets.generate_texture
void register_svg_command(CommandRegistry& registry, const std::string& projectDir);      // assets.rasterize_svg
void register_bake_sheet_command(CommandRegistry& registry, const std::string& projectDir);  // assets.bake_sheet
void register_audio_commands(CommandRegistry& registry, const std::string& projectDir);  // assets.generate_loop, assets.convert_audio
void register_subset_font_command(CommandRegistry& registry, const std::string& projectDir);

// Title text as a tightly cropped transparent image (assets_draw_icon.cpp: the rasterizer of assets.draw_icon's text
// layers), the largest that fits maxW x maxH; `outline` (or null) draws an outline around the letters. A project font is
// read from the VFS project root (hold a ProjectRootGuard). Throws CommandError for an unreadable font or empty text.
Image draw_title_logo(const std::string& text, const std::string& font, const Color& fill, const Color* outline, int maxW, int maxH);

// ---- project.validate (validate_assets.cpp) --------------------------------------------------------------

// Texture sizes, file weights and the store limits, over the files an export ships. Adds warnings.
void check_shipped_assets(const std::string& projectDir, std::vector<ValidationIssue>& warnings);
// Every glTF/glb under assets/ must find the textures and buffers its uris name: adds errors.
void check_model_files(const std::string& projectDir, std::vector<ValidationIssue>& errors);
// The textures Sprites draw (project-relative): fully transparent images, and backgrounds that should be transparent.
void check_sprite_textures(const std::string& projectDir, const std::set<std::string>& textures, std::vector<ValidationIssue>& warnings);

// ---- painterly styles (assets_style.cpp) -----------------------------------------------------------------

// The values of `style` of assets.rasterize_svg: "none", "watercolor", "ink", "inkwash", "paper".
const std::vector<std::string>& image_style_names();
// Paints the look of `style` onto a rasterized picture (straight-alpha RGBA): wobbling edges, pooled pigment, granulation,
// an ink line, paper tooth. `strength` is 0..1. Deterministic: the same pixels, style, strength and seed give the same result.
void apply_image_style(Image& image, const std::string& style, double strength, std::uint32_t seed);

// ---- recipes (assets_recipe.cpp) -------------------------------------------------------------------------

// The `provenance.recipe` of a made asset (schemas/assets.schema.json): `command`, the `args` that make the same bytes
// again (the caller makes paths project-relative and `seed` explicit) and the project files it read, `inputs`
// (project-relative), each with its SHA-256 now. Throws CommandError for an input that cannot be read.
Json make_recipe(const std::string& projectDir, const std::string& command, Json args, const std::vector<std::string>& inputs);

// ---- command helpers -------------------------------------------------------------------------------------

[[noreturn]] void fail(const char* code, const std::string& message, const std::string& hint = {});

// Argument errors of the drawing commands (assets_draw_icon.cpp): "<command> <JSON pointer>: <what>" with a hint; unknown
// keys get a "did you mean"; colours are "#rrggbb", "#rrggbbaa", a name or [r, g, b].
[[noreturn]] void arg_error(const char* command, const std::string& pointer, const std::string& what, const std::string& hint);
void check_arg_keys(const char* command, const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed);
Color colour_arg(const char* command, const Json& v, const std::string& pointer);

// The absolute path of the project-relative `rel` (sandboxed: it cannot leave the project), or a CommandError.
stdfs::path project_file(const std::string& projectDir, const std::string& rel);

// fa::assets works on the project of the VFS; this makes `projectDir` that project while it lives.
struct ProjectRootGuard {
    stdfs::path saved = fs::project_root();
    explicit ProjectRootGuard(const std::string& projectDir) { fs::set_project_root(projectDir); }
    ~ProjectRootGuard() { fs::set_project_root(saved); }
};

// Throws unless assets.json is absent or a JSON object: the assets.* commands edit it, and fa::assets::update_entry
// refuses a broken one, so they check before they write any file.
void require_usable_manifest(const std::string& projectDir);

// A file name that is safe in a path, a glTF uri and a JSON key on every OS: "My Hero (2)" -> "My_Hero__2_".
std::string safe_file_name(const std::string& name, const char* fallback);
Result<std::vector<std::uint8_t>> read_bytes(const stdfs::path& path);
// The pixels of an image file, or the error that says why they cannot be read.
Result<Image> load_image(const stdfs::path& file);

}  // namespace fa::assets_detail
