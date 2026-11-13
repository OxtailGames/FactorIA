#pragma once
// What the sections of the editor autotest (autotest_*.cpp) share. Editor::at_build_tools_script (autotest_tools.cpp) builds the
// AtScript and calls one Editor::at_section_<id>(AtScript&) per section, in the order of a full run (autotest_sections.h).
#include <functional>
#include <string>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "imgui_internal.h"

namespace fa::editor {

// The script being built. Its members are the small tools every section writes its steps with; Editor::at_build_tools_script sets
// them. A section starts with AT_SCRIPT_LOCALS(at), which gives it the names `step`, `click`, `snap`, `project_file`, `scroll_until`,
// `scroll_until_at`, `window_middle` and `scroll_to` as local variables.
struct AtScript {
    using Fn = std::function<void()>;
    bool keep =
        true;  // false while the script passes over a section FA_EDITOR_AUTOTEST_SECTIONS did not ask for: step() adds nothing
    std::function<void(int, Fn)> step;              // one step, then `wait` frames
    std::function<void(const std::string&)> click;  // move onto the widget, press, release (three steps)
    std::function<void(const std::string&)> snap;   // a window screenshot, file name inside the output folder
    std::function<std::string(const std::string&)> project_file;  // a path inside the autotest's project
    std::function<void(std::function<std::string()>, float, std::function<Vec2()>, float, float)> scroll_until_at;
    std::function<void(const std::string&, float, Vec2, float)> scroll_until;
    std::function<Vec2(const char*)> window_middle;  // the visible middle of a window
    std::function<void(const std::string&, const std::string&, float)>
        scroll_to;  // scroll a window until a widget is shown
};

// The names a section uses, as the locals they were when the whole script was one function (default arguments included).
#define AT_SCRIPT_LOCALS(at)                                                                                           \
    [[maybe_unused]] auto& step = (at).step;                                                                           \
    [[maybe_unused]] auto& click = (at).click;                                                                         \
    [[maybe_unused]] auto& snap = (at).snap;                                                                           \
    [[maybe_unused]] auto& project_file = (at).project_file;                                                           \
    [[maybe_unused]] auto& scroll_until = (at).scroll_until;                                                           \
    [[maybe_unused]] auto& window_middle = (at).window_middle;                                                         \
    [[maybe_unused]] auto scroll_until_at = [&at](std::function<std::string()> nameOf, float dy,                       \
                                                  std::function<Vec2()> where, float maxY, float minY = 120) {         \
        (at).scroll_until_at(std::move(nameOf), dy, std::move(where), maxY, minY);                                     \
    };                                                                                                                 \
    [[maybe_unused]] auto scroll_to = [&at](const std::string& name, const std::string& window, float dy = -6) {       \
        (at).scroll_to(name, window, dy);                                                                              \
    };

namespace at_support {

// Sections U (layout), E2 and E4: where a panel is now. Floating panels have no dock node; a docked one names its node.
ImGuiWindow* panel_window(const char* name);
bool panel_floating(const char* name);
ImGuiID panel_node(const char* name);
float panel_width(const char* name);

// The value at a JSON pointer of a file the test parsed, or null when the file is not an object or does not say it.
Json json_at(const Json& file, const char* pointer);
void write_file(const std::string& path, const std::string& bytes);
std::string read_file(const std::string& path);
std::string silence_wav();  // 0.1 s of silence, 16-bit mono PCM

// The scene the second half of the autotest works on (the project's main scene is replaced by it before every section).
extern const char* const kFixtureScene;

}  // namespace at_support

}  // namespace fa::editor
