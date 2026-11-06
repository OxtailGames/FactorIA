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
#include "fa/scene/model_uv.h"
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
    Json document;                // a layered image document to save (and bake) once the files are written; null = none
    std::string documentPath;     // where: project-relative, ending in .image.json; it bakes to files[0]
};

struct ImportRequest {
    stdfs::path source;  // absolute path of the file to import
    std::string dest;    // project-relative path of files[0] (the folder of the sidecars)
    int columns = 0;     // aseprite: columns of the sheet (0 = ceil(sqrt(frames)))
    bool flat = false;   // aseprite: one PNG sprite sheet and its `sheet` entry, no image document
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
    bool loop = true;
    std::optional<std::array<double, 2>> pivot;  // [x, y] in 0..1 of the frame: this clip's own pivot (overrides the sheet's)
};

// The `sheet` entry of assets.json (schemas/assets.schema.json) for a grid of `frames` frames. `padding` is the transparent
// gutter around every cell (written only when above 0); `pivot` the pivot of every frame (written only when given).
Json sheet_entry(int columns, int rows, int frameWidth, int frameHeight, int frames, const std::vector<SheetClip>& clips,
                 int padding = 0, std::optional<std::array<double, 2>> pivot = std::nullopt);
// How to play `sheet` (a sheet_entry) from the image `texture`: the Sprite and SpriteAnimator settings, one line each.
std::vector<std::string> sheet_next_steps(const std::string& texture, const Json& sheet, double fps);

// The colour of the four corners of `image` when they are all the same fully opaque colour (to within a few levels,
// which a JPEG-era solid background has): the sign of a background that should be transparent.
std::optional<std::array<std::uint8_t, 3>> opaque_corner_color(const Image& image);

// ---- rasterizing SVG text (assets_svg.cpp) ---------------------------------------------------------------

struct SvgRaster {
    Image image;           // straight-alpha RGBA, transparent where nothing is drawn
    double svgWidth = 0;   // the size the SVG declares
    double svgHeight = 0;
};
// The picture of the SVG `text` in a `w` x `h` image (the SVG fitted inside, aspect kept, centred; a 0 side follows the
// SVG's proportions, both 0 is the SVG's own size), then the painterly `style` ("none" or one of image_style_names()) at
// `styleStrength` with `seed`. The core of assets.rasterize_svg and assets.animate_svg. Warnings (features nanosvg does not
// draw) are appended to `warnings`. Throws CommandError for text that is not a drawable SVG.
SvgRaster rasterize_svg_text(const std::string& text, int w, int h, const std::string& style, double styleStrength, std::uint32_t seed,
                             std::vector<std::string>& warnings);

// ---- procedural textures (assets_texture.cpp) -----------------------------------------------------------

// The picture of a texture whose `args` are the picture arguments of assets.generate_texture (preset, width, height, seed,
// color, accent, scale, roughness, tileable, vignette, vignetteWidth, angle and the planks fields; no path, overwrite, author
// or normalMap): straight-alpha RGBA. An image document's procedural layer calls this. Errors (CommandError, code
// invalid_argument) read "<command> <pointer>/<key>: <what>"; the arguments the preset ignores are added to `warnings`.
Image procedural_texture_image(const Json& args, const std::string& command, const std::string& pointer, std::vector<std::string>& warnings);
// Only the checks of procedural_texture_image, without painting (used when a document is loaded).
void check_procedural_texture_args(const Json& args, const std::string& command, const std::string& pointer);

void register_slice_sheet_command(CommandRegistry& registry, const std::string& projectDir);
void register_pack_atlas_command(CommandRegistry& registry, const std::string& projectDir);
void register_draw_icon_command(CommandRegistry& registry, const std::string& projectDir);
void register_draw_capsules_command(CommandRegistry& registry, const std::string& projectDir);
void register_synth_sound_command(CommandRegistry& registry, const std::string& projectDir);
void register_sfx_commands(CommandRegistry& registry, const std::string& projectDir);  // sfx.render, sfx.bake, sfx.tweak, sfx.family, sfx.preset, sfx.info (assets_sfx.cpp)
void register_vfx_commands(CommandRegistry& registry, const std::string& projectDir);  // vfx.create, vfx.edit (assets_vfx.cpp, docs/PARTICLES.md)
void register_texture_command(CommandRegistry& registry, const std::string& projectDir);  // assets.generate_texture
void register_svg_command(CommandRegistry& registry, const std::string& projectDir);      // assets.rasterize_svg
void register_animate_svg_command(CommandRegistry& registry, const std::string& projectDir);  // assets.animate_svg
void register_preview_sheet_command(CommandRegistry& registry, const std::string& projectDir);  // assets.preview_sheet
void register_check_art_command(CommandRegistry& registry, const std::string& projectDir);  // assets.check_art
void register_bake_sheet_command(CommandRegistry& registry, const std::string& projectDir);  // assets.bake_sheet
void register_contact_sheet_command(CommandRegistry& registry, const std::string& projectDir);  // assets.contact_sheet
void register_preview_scene_command(CommandRegistry& registry, const std::string& projectDir);  // assets.preview_in_scene
void register_music_commands(CommandRegistry& registry, const std::string& projectDir);  // music.* (assets_music.cpp, assets_music_edit.cpp, docs/MUSIC.md)
void register_audio_doc_commands(CommandRegistry& registry, const std::string& projectDir);  // audio.info, audio.render, audio.bake, audio.create, audio.edit (assets_audio_doc.cpp)
void register_model_commands(CommandRegistry& registry, const std::string& projectDir);  // model.info, model.bake, model.create, model.edit (assets_model.cpp)
void register_rig_commands(CommandRegistry& registry, const std::string& projectDir);  // rig.templates, rig.info, rig.create, rig.fit, rig.bake (assets_rig.cpp, docs/RIGGING.md)
void register_skin3d_commands(CommandRegistry& registry, const std::string& projectDir);  // skin3d.info, auto, set, add, smooth, normalize, limit, mirror, clear, preview (assets_skin3d.cpp, docs/RIGGING.md)
void register_anim3d_commands(CommandRegistry& registry, const std::string& projectDir);  // anim3d.* and ik3d.* (assets_anim3d.cpp, docs/ANIMATION.md)
void register_model_uv_command(CommandRegistry& registry, const std::string& projectDir);  // model.uv (assets_model_uv.cpp)
void register_model_texture_commands(CommandRegistry& registry, const std::string& projectDir);  // model.texture, model.decal, model.palette, model.bake_maps (assets_model_texture.cpp)
void register_model_eyes_commands(CommandRegistry& registry, const std::string& projectDir);  // model.preview, model.check (assets_model_preview.cpp)
void register_model_import_clean_command(CommandRegistry& registry, const std::string& projectDir);  // model.import_clean (assets_model_import.cpp)
Json model_uv_report_json(const ModelUvReport& report);  // the measurements of a uv section as JSON (model.uv, and `uv` in the model.* measurements)
void register_audio_commands(CommandRegistry& registry, const std::string& projectDir);  // assets.generate_loop, assets.convert_audio
void register_subset_font_command(CommandRegistry& registry, const std::string& projectDir);
void register_image_commands(CommandRegistry& registry, const std::string& projectDir);  // image.bake, image.save (image_doc_commands.cpp)
void register_vector_commands(CommandRegistry& registry, const std::string& projectDir);  // vector.* (vector_commands.cpp, docs/VECTOR.md)
void register_vector_rig_command(CommandRegistry& registry, const std::string& projectDir);  // vector.to_rig (vector_rig.cpp)
void register_vector_edit_commands(CommandRegistry& registry, const std::string& projectDir);  // vector.add, nodes, set... (vector_edit_commands.cpp)

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
// The `args` of a recipe from the arguments the command was called with: a copy of `a` without `overwrite` (assets.regenerate
// sets it itself) and with `set` applied on top (the normalized project-relative paths and the values the command chose: the
// seed actually used, the default path from factoria.json). A null value in `set` removes the key.
Json recipe_args(const Json& a, std::initializer_list<std::pair<const char*, Json>> set);
// `rel` as the project-relative path a recipe records (forward slashes, no "./"); `rel` itself when it is not a project path.
std::string recipe_path(const std::string& rel);

// What became of the files a recipe read, now: the paths whose hash differs from the recipe's (`changed`) and the ones that
// no longer exist or cannot be read (`missing`). An asset is stale when any input changed.
struct RecipeCheck {
    std::vector<std::string> changed;
    std::vector<std::string> missing;
    bool stale() const { return !changed.empty(); }
    bool ok() const { return changed.empty() && missing.empty(); }
};
// A recipe can also record `context`: values read from assets.json rather than from a file. Today `styleMusicLufs`, the loudness the style
// guide asked of music when a song was rendered with `mixer.master.loudness: "style"` (null: it set none). check_recipe reports it in
// `changed` as "assets.json (style.audio.loudnessLufs.music)" when the style guide says something else now. `styleTexelsPerUnit` is the same for the
// texel density a model document's `uv` section took from the style guide ("assets.json (style.texelsPerUnit)").
RecipeCheck check_recipe(const std::string& projectDir, const Json& recipe);
// style.audio.loudnessLufs.music of the project's assets.json, if the style guide sets it.
std::optional<double> style_music_loudness(const std::string& projectDir);
// Records `target` (null: none) as recipe.context.styleMusicLufs.
void add_style_loudness_context(Json& recipe, const std::optional<double>& target);
// style.texelsPerUnit of the project's assets.json, if the style guide sets it (a model document's `uv` section uses it as its density).
std::optional<double> style_texels_per_unit(const std::string& projectDir);
// Records `value` (null: none) as recipe.context.styleTexelsPerUnit; check_recipe reports "assets.json (style.texelsPerUnit)" in `changed` when the
// style guide says something else now.
void add_style_texels_context(Json& recipe, const std::optional<double>& value);
// style.palette of the project's assets.json as colours (empty when the style guide has none): the "style" palette of a model document's
// `vertexColors` section.
std::vector<Vec4> style_palette_colors(const std::string& projectDir);
// Records the palette (as "#rrggbb" strings; an empty one as null) as recipe.context.stylePalette; check_recipe reports "assets.json (style.palette)" in
// `changed` when the style guide has another palette now.
void add_style_palette_context(Json& recipe, const std::vector<Vec4>& palette);
// The recipe of an assets.json entry (`provenance.recipe`), or null when it has none or it is malformed (no command).
Json recipe_of(const Json& entry);

// assets.regenerate (assets_regenerate.cpp): re-runs the recipe of a made asset through the registry, whatever the command.
void register_regenerate_command(CommandRegistry& registry, const std::string& projectDir);
// project.validate: the warnings for assets whose recipe inputs changed (stale) or went missing, with the regenerate command.
void check_recipes(const std::string& projectDir, std::vector<ValidationIssue>& warnings);
// project.validate: every *.image.json that does not load is an error (file, JSON pointer, fix); one never baked, or whose PNG
// assets.json does not record as its bake, is a warning with the image.bake command. (A stale bake is check_recipes' warning.)
void check_image_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings);
// project.validate: every *.audio.json that does not load (or would overwrite its own source) is an error with its JSON pointer and fix; one never
// baked, or whose sound assets.json does not record as its bake, is a warning with the audio.bake command. (A stale bake is check_recipes' warning.)
void check_audio_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings);
// project.validate: every *.model.json that does not load is an error (file, JSON pointer, fix); one never baked, or whose .glb assets.json does not record as its
// bake, is a warning with the model.bake command. (A stale bake is check_recipes' warning.)
void check_model_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings);
// project.validate: every *.rig.json that does not load or fit is an error (file, JSON pointer, fix); one never baked, or whose .glb assets.json does not
// record as its bake, is a warning with the rig.bake command.
void check_rig_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings);
// project.validate: every *.vfx.json anywhere in the project (not in hidden folders, node_modules or build/) that does not load is an error (file,
// JSON pointer, fix), so is a sound clip it names that is not in the project; the parser's warnings (a rate that never emits, too many live
// particles) are warnings. `referenced`: the files the scenes and prefabs name in a Vfx.effect, checked too when their name does not end in .vfx.json
// (a file that does not exist is the asset check's to report).
void check_vfx_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings,
                         const std::set<std::string>& referenced = {});
// project.validate: every *.song.json that does not parse is an error (file, JSON pointer, line and column inside note text, fix), so is an
// instrument or drum-kit file it names that is missing or not a sound patch; the findings of the music checks that need no render (off-key
// notes, clashes, mud, a track that never plays...) are warnings (docs/MUSIC.md).
void check_song_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings);

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
