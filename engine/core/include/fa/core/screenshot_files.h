// The files game.screenshot leaves in `<project>/.factoria/screenshots`: which of them the engine may delete.
//
// A screenshot an agent takes WITHOUT a `path` is a temporary picture: the result is {"$image": {"path", "mimeType",
// "temporary": true}}, and whoever attaches the image to a message (the MCP server, the editor's AI assistant, the API
// providers) deletes the file once it has read it (discard_temporary_image). Callers that only print the result
// (`factoria call`) leave it, and prune_screenshots removes it later. Screenshots with an explicit `path`, the editor's
// Screenshot button (editor_<frame>.png), the pictures of F9 marks and `factoria run --screenshot-at` outputs with a
// pattern of the user's are never touched: only files the engine named itself are.
#pragma once

#include <cstddef>
#include <filesystem>
#include <string_view>

#include "fa/core/json.h"

namespace fa {

inline constexpr const char* kScreenshotDir = ".factoria/screenshots";
inline constexpr int kScreenshotMaxAgeDays = 3;       // prune_screenshots: older engine-named files are deleted
inline constexpr std::size_t kScreenshotMaxFiles = 200;  // prune_screenshots: at most this many engine-named files stay

// True for a file name the engine picks for a screenshot without a `path`: frame_<digits>.png, optionally followed by
// _<words> (frame_120_region.png, frame_120_sheet.png). Names the user chose (hall.png, editor_12.png) are not.
bool is_engine_named_screenshot(std::string_view fileName);

// Deletes the engine-named screenshots in `<projectDir>/.factoria/screenshots` that are older than `maxAgeDays`, then the
// oldest ones beyond `maxFiles`. Returns how many were deleted. Silent when the folder does not exist or a file cannot
// be removed. The engine calls it when a project opens; the MCP server does too (it opens the project).
std::size_t prune_screenshots(const std::filesystem::path& projectDir, int maxAgeDays = kScreenshotMaxAgeDays,
                              std::size_t maxFiles = kScreenshotMaxFiles);

// Called by a consumer after it has read the image into a message. When `imageSpec` (the `$image` object of a command
// result) says `temporary: true` and its `path` is an engine-named file inside `<projectDir>/.factoria/screenshots`,
// deletes the file and returns true. Anything else (no flag, an explicit path, a file elsewhere) is left alone: the flag
// alone never makes a file outside the screenshot folder deletable.
bool discard_temporary_image(const Json& imageSpec, const std::filesystem::path& projectDir);

}  // namespace fa
