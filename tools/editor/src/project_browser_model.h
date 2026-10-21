// Project panel model (project_browser_panel.cpp): the project's files as a cached listing, the folder tree, and the filter / sort
// that decide which files the list shows. No ImGui, no engine: tested in tools/editor/tests/project_browser_tests.cpp.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"

namespace fa::editor {

// The ImGui drag and drop payload type of a project file: the payload is the project-relative path, NUL terminated.
inline constexpr const char* kAssetPayload = "FA_ASSET";

struct BrowserFile {
    std::string path;      // project-relative, forward slashes
    std::string type;      // asset_type_of(path): texture, audio, font, mesh, script, scene, prefab, material, other
    std::uint64_t size = 0;
};

// What one walk of the disk found. The panel keeps it until a refresh is due: it never walks the disk per frame.
struct ProjectListing {
    std::vector<BrowserFile> files;     // sorted by path
    std::vector<std::string> folders;   // every folder walked (empty ones too), sorted
    bool truncated = false;             // more than the limit: the rest was left out
};

// Walks `projectDir` (the same skips as list_asset_files: hidden folders, build, node_modules, dist, export).
ProjectListing scan_project(const std::string& projectDir, std::size_t limit = 20000);

struct FolderNode {
    std::string name;                   // last path part ("Project" for the root)
    std::string path;                   // project-relative, "" for the root
    int fileCount = 0;                  // files in it and below
    std::vector<FolderNode> children;   // sorted by name, case-insensitive
};
FolderNode build_folder_tree(const ProjectListing& listing);

enum class BrowserSort { Name, Type, Size };
struct BrowserQuery {
    std::string folder;                 // "" = every file of the project; else only the files directly in that folder
    std::string type = "all";           // "all" or an asset type
    std::string search;                 // case-insensitive substring of the path; when set it looks through the whole project
    BrowserSort sort = BrowserSort::Name;
    bool descending = false;
};

// The type filter's choices in the order the combo shows them: all, texture, audio, font, mesh, script, scene, prefab, material.
const std::vector<std::string>& browser_type_filters();
// The indices into listing.files that the query shows, sorted (ties by path).
std::vector<std::size_t> query_files(const ProjectListing& listing, const BrowserQuery& q);

std::string folder_of(std::string_view path);        // "assets/a/b.png" -> "assets/a"; "b.png" -> ""
std::string file_name_of(std::string_view path);     // "assets/a/b.png" -> "b.png"
std::string size_text(std::uint64_t bytes);          // "812 B", "4.2 KB", "1.5 MB"
// The short label of a file icon with no thumbnail: "WAV", "JS", "SCN", "PFB"...
std::string type_badge(std::string_view path, std::string_view type);

// Where a prefab dropped on a 3D viewport lands: the point where the mouse ray meets the ground plane (y = 0) in front of the
// camera; when the ray misses it (parallel, pointing up, or farther than `maxDistance`) the point `fallbackDistance` along it.
Vec3 drop_point_3d(Vec3 rayOrigin, Vec3 rayDir, float fallbackDistance = 10.0f, float maxDistance = 1000.0f);

// The panel's state (kept by the editor for the whole run).
struct ProjectBrowser {
    ProjectListing listing;
    FolderNode tree;                    // build_folder_tree(listing), rebuilt with each scan
    BrowserQuery query;
    bool stale = true;                  // rescan before the next draw: set by Refresh, window focus, and the editor's own file writes
    bool scanned = false;
    std::string selected;               // the clicked file (path)
    std::string deleteAsk;              // file waiting for the Delete confirmation
    std::string error;                  // what the last drop or delete said when it failed
    std::string project;                // the project dir the listing is of
    int scans = 0;                      // how many times the disk was walked (tests, and a check that drawing does not rescan)
    bool windowFocused = false;         // the panel had focus last frame
};

}  // namespace fa::editor
