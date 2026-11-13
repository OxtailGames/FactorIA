// Helpers and fixtures shared by the sections of the editor autotest (autotest_common.h).
#include <algorithm>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iterator>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "sokol_app.h"
#include "imgui_internal.h"

namespace fa::editor::at_support {

namespace stdfs = std::filesystem;

// Sections U, E2 and E4: where a panel is now. Floating panels have no dock node; a docked one names its node.
ImGuiWindow* panel_window(const char* name) { return ImGui::FindWindowByName(name); }
bool panel_floating(const char* name) {
    const ImGuiWindow* w = panel_window(name);
    return w && !w->DockIsActive && w->DockNode == nullptr;
}
ImGuiID panel_node(const char* name) {
    const ImGuiWindow* w = panel_window(name);
    return w && w->DockNode ? w->DockNode->ID : 0;
}
float panel_width(const char* name) {
    const ImGuiWindow* w = panel_window(name);
    return w ? w->Size.x : 0.0f;
}

// The value at a JSON pointer of a file the test parsed, or null when the file is not an object or does not say it. (A const Json's
// operator[] on a key that is missing is undefined: the checks of a file that may lack a section go through here.)
Json json_at(const Json& file, const char* pointer) {
    const Json::json_pointer p(pointer);
    return file.is_object() && file.contains(p) ? file.at(p) : Json();
}

void write_file(const std::string& path, const std::string& bytes) {
    std::error_code ec;
    stdfs::create_directories(stdfs::path(path).parent_path(), ec);
    std::ofstream(path, std::ios::binary) << bytes;
}

std::string read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

std::string silence_wav() {  // 0.1 s of silence, 16-bit mono PCM
    const std::uint32_t n = 4410;
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char((v >> (8 * i)) & 0xff)); };
    auto u16 = [&](std::uint16_t v) { b.push_back(char(v & 0xff)); b.push_back(char(v >> 8)); };
    b += "RIFF"; u32(36 + n * 2); b += "WAVEfmt "; u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16);
    b += "data"; u32(n * 2);
    b.append(std::size_t(n) * 2, '\0');
    return b;
}

// The scene the second half of the autotest works on. The first half runs on whatever the 2d-platformer template ships; from here on
// the checks must not depend on the template's entities, positions or levels, so the project's main scene is replaced by this fixture:
// a camera at the origin looking at 1280 x 720 world units, a few shapes, a player, three coins. No scripts, no physics, no tags that
// scene.import_ascii would treat as its own (`tilemap:<id>`), so importing a level into it cannot remove any of these entities.
const char* const kFixtureScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "name": "Main Camera",
      "components": { "Transform": { "position": [0, 0, 0] }, "Camera": { "clearColor": [0.35, 0.55, 0.85, 1], "primary": true } } },
    { "id": "ground", "name": "Ground",
      "components": { "Transform": { "position": [0, -320, 0] }, "Shape2D": { "size": [3000, 80], "color": [0.25, 0.6, 0.3, 1] } } },
    { "id": "platform_1", "name": "Platform 1",
      "components": { "Transform": { "position": [250, -200, 0] }, "Shape2D": { "size": [220, 24], "color": [0.55, 0.4, 0.25, 1] } } },
    { "id": "player", "name": "Player", "tags": ["player"],
      "components": { "Transform": { "position": [-300, -250, 0] }, "Shape2D": { "size": [32, 48], "color": [0.95, 0.35, 0.3, 1], "layer": 2 } } },
    { "id": "coin_1", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [-100, -266, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } },
    { "id": "coin_2", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [250, -160, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } },
    { "id": "coin_3", "name": "Coin", "tags": ["coin"],
      "components": { "Transform": { "position": [420, -266, 0] }, "Shape2D": { "shape": "circle", "size": [24, 24], "color": [1, 0.85, 0.2, 1], "layer": 1 } } }
  ]
})";

}  // namespace fa::editor::at_support
