#include "fa/core/notices.h"

namespace fa {

const std::vector<ThirdPartyComponent>& third_party_components() {
    // Keep in step with external/VERSIONS.md and the fonts embedded by engine/render (CMakeLists.txt).
    static const std::vector<ThirdPartyComponent> list = {
        {"FactorIA", "https://github.com/OxtailGames/FactorIA", "MIT", "LICENSE", "the engine and its tools", true},
        {"sokol", "https://github.com/floooh/sokol", "zlib", "external/sokol/LICENSE",
         "window, graphics, audio output and timing", true},
        {"QuickJS-ng", "https://github.com/quickjs-ng/quickjs", "MIT", "external/quickjs/LICENSE", "JavaScript engine", true},
        {"Box2D", "https://github.com/erincatto/box2d", "MIT", "external/box2d/LICENSE", "2D physics", true},
        {"stb", "https://github.com/nothings/stb", "MIT OR Unlicense", "external/stb/LICENSE",
         "image decoding and encoding, TrueType fonts, rectangle packing, Ogg Vorbis", true},
        {"cgltf", "https://github.com/jkuhlmann/cgltf", "MIT", "external/cgltf/LICENSE", "glTF 2.0 models", true},
        {"dr_libs", "https://github.com/mackron/dr_libs", "MIT-0 OR Unlicense", "external/dr_libs/LICENSE",
         "WAV and MP3 decoding", true},
        {"nlohmann/json", "https://github.com/nlohmann/json", "MIT", "external/nlohmann_json/LICENSE.MIT", "JSON", true},
        {"SDL_GameControllerDB", "https://github.com/mdqinc/SDL_GameControllerDB", "zlib",
         "external/sdl_gamecontrollerdb/LICENSE", "gamepad mappings (data)", true},
        {"DejaVu Sans", "https://dejavu-fonts.github.io", "Bitstream-Vera AND LicenseRef-Arev",
         "engine/render/assets/fonts/DejaVu-LICENSE.txt", "built-in font", true},
        {"Press Start 2P", "https://github.com/codeman38/PressStart2P", "OFL-1.1",
         "engine/render/assets/fonts/PressStart2P-OFL.txt", "built-in pixel font", true},
        {"Dear ImGui", "https://github.com/ocornut/imgui", "MIT", "external/imgui/LICENSE.txt", "the editor's UI", false},
        // gradlew, gradlew.bat and gradle-wrapper.jar are embedded in factoria and written into every Android export, so
        // that the project builds itself (platforms/android). They end up in the Gradle project, not in the game.
        {"Gradle wrapper", "https://github.com/gradle/gradle", "Apache-2.0", "platforms/licenses/gradle-wrapper-LICENSE.txt",
         "the Gradle wrapper that Android exports write into the Gradle project; not part of the game", false},
    };
    return list;
}

}  // namespace fa
