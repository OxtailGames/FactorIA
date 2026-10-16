#include "fa/tooling/notices.h"

#include "fa/tooling/bundle.h"

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
        {"Basis Universal", "https://github.com/BinomialLLC/basis_universal", "Apache-2.0", "external/basis_universal/LICENSE",
         "GPU texture compression: games decode KTX2 textures, `factoria export` encodes them", true},
        // Parts of the Basis Universal encoder, which only the developer tools contain.
        {"tinyexr (in the Basis Universal encoder)", "https://github.com/syoyo/tinyexr", "BSD-3-Clause",
         "external/basis_universal/LICENSES/BSD-3-clause.txt", "OpenEXR images in the texture encoder", false},
        {"qoi (in the Basis Universal encoder)", "https://github.com/phoboslab/qoi", "MIT",
         "external/basis_universal/LICENSES/MIT.txt", "QOI images in the texture encoder", false},
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

std::string third_party_notices(NoticeScope scope) {
    const std::string rule(78, '-');
    std::string out;
    out += "FactorIA " FA_ENGINE_VERSION " - license notices\n\n";
    out += scope == NoticeScope::Game
               ? "This game was made with FactorIA and contains its runtime. The runtime is FactorIA (MIT License) plus the\n"
                 "third-party software below; each part is used under the license that follows it.\n"
               : "The FactorIA engine and tools are FactorIA (MIT License) plus the third-party software below; each part is\n"
                 "used under the license that follows it. Games made with FactorIA ship the parts marked \"in games\".\n";
    for (const ThirdPartyComponent& c : third_party_components()) {
        if (scope == NoticeScope::Game && !c.inGames) continue;
        out += "\n" + rule + "\n" + c.name + " (" + c.usedFor + (scope == NoticeScope::All && c.inGames ? "; in games" : "") +
               ")\n" + c.url + "\nLicense: " + c.license + "\n\n";
        std::string text = bundled_read(c.licenseFile).value_or("");
        if (text.empty()) text = "[license text missing from this build: " + c.licenseFile + " in the FactorIA repository]";
        // Apache-2.0 section 4(d): a library that keeps a NOTICE file beside its LICENSE has that text reproduced too.
        if (auto notice = bundled_read(c.licenseFile.substr(0, c.licenseFile.rfind('/') + 1) + "NOTICE")) text += "\n\n" + *notice;
        while (!text.empty() && (text.back() == '\n' || text.back() == '\r' || text.back() == ' ')) text.pop_back();
        out += text + "\n";
    }
    return out;
}

}  // namespace fa
