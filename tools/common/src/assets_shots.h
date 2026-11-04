// Private helpers of assets.contact_sheet and assets.preview_in_scene (assets_contact_sheet.cpp, assets_preview_scene.cpp):
// resizing and text on CPU pictures, the temporary picture the commands return, and the child process that runs a command
// which needs a graphics device of its own.
#pragma once

#include <string>

#include "assets_internal.h"

namespace fa::assets_detail {

struct Rgb8 {
    std::uint8_t r = 0, g = 0, b = 0;
};

// `src` at w x h: where it shrinks, each pixel is the average of the source pixels it covers (premultiplied by alpha, so a
// transparent edge does not darken it); where it grows, nearest-neighbour (a pixel stays a hard block). Deterministic.
Image resize_area(const Image& src, int w, int h);
// The pixels of `src` as greyscale (Rec. 709 luminance of the sRGB bytes), alpha kept.
Image to_greyscale(const Image& src);
// `bg` filled with an opaque colour, then `src` over it (straight alpha) at (x, y); parts outside `bg` are cut.
void fill_rect_rgb(Image& dst, int x, int y, int w, int h, Rgb8 c);
void draw_over(Image& dst, const Image& src, int x, int y);
// A line of text in the engine's built-in font (DejaVu Sans) with its top-left corner at (x, y); returns the pixel width.
// text_width() measures without drawing.
int draw_text(Image& dst, int x, int y, const std::string& text, float px, Rgb8 c);
int text_width(const std::string& text, float px);
// "#rrggbb" for the colour.
std::string hex_colour(const Color& c);

// Writes `picture` as a temporary screenshot of the project (.factoria/screenshots/frame_<n>_<tag>.png, the name the engine's
// own screenshots use, so the MCP server deletes it after attaching it) and returns its path; throws CommandError("failed").
stdfs::path write_temporary_picture(const std::string& projectDir, const Image& picture, const char* tag);
// The "$image" member of a result for a file written by write_temporary_picture (`temporary`) or at a path the caller chose.
Json image_member(const stdfs::path& file, bool temporary);

// A process has one graphics device. When this one already has it (the editor, a session with graphics) the command runs again
// in a child `factoria call` process, which has its own; its result (or its error, rethrown) comes back. Throws CommandError.
Json call_in_child(const std::string& projectDir, const char* command, const Json& args);

// A precise "no graphics device" error when `message` (from Engine::init or capture) says there is no renderer.
[[noreturn]] void no_gpu_error(const char* command, const std::string& message, const char* alternative);

}  // namespace fa::assets_detail
