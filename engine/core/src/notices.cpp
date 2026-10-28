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
        {"Basis Universal", "https://github.com/BinomialLLC/basis_universal", "Apache-2.0", "external/basis_universal/LICENSE",
         "GPU texture compression: games decode KTX2 textures, `factoria export` encodes them", true},
        // Parts of the Basis Universal encoder, which only the developer tools contain.
        {"tinyexr (in the Basis Universal encoder)", "https://github.com/syoyo/tinyexr", "BSD-3-Clause",
         "external/basis_universal/LICENSES/BSD-3-clause.txt", "OpenEXR images in the texture encoder", false},
        {"qoi (in the Basis Universal encoder)", "https://github.com/phoboslab/qoi", "MIT",
         "external/basis_universal/LICENSES/MIT.txt", "QOI images in the texture encoder", false},
        {"HarfBuzz", "https://github.com/harfbuzz/harfbuzz", "MIT", "external/harfbuzz/COPYING", "text shaping (ligatures, kerning, Arabic, Hebrew and Indic scripts)", true},
        {"Microsoft USE data (in HarfBuzz)", "https://github.com/harfbuzz/harfbuzz", "MIT", "external/harfbuzz/src/ms-use/COPYING",
         "Universal Shaping Engine character data HarfBuzz's table is generated from", true},
        {"SheenBidi", "https://github.com/Tehreer/SheenBidi", "Apache-2.0", "external/sheenbidi/LICENSE",
         "Unicode bidirectional algorithm (right-to-left text)", true},
        {"dr_libs", "https://github.com/mackron/dr_libs", "MIT-0 OR Unlicense", "external/dr_libs/LICENSE",
         "WAV and MP3 decoding", true},
        {"acorn", "https://github.com/acornjs/acorn", "MIT", "external/acorn/LICENSE",
         "JavaScript parser of the script debugger", false},
        {"qoa", "https://github.com/phoboslab/qoa", "MIT", "external/qoa/LICENSE", "QOA audio files", true},
        {"pl_mpeg", "https://github.com/phoboslab/pl_mpeg", "MIT", "external/pl_mpeg/LICENSE",
         "MPEG-1 video and MP2 audio decoding (the Video component)", true},
        {"nlohmann/json", "https://github.com/nlohmann/json", "MIT", "external/nlohmann_json/LICENSE.MIT", "JSON", true},
        {"SDL_GameControllerDB", "https://github.com/mdqinc/SDL_GameControllerDB", "zlib",
         "external/sdl_gamecontrollerdb/LICENSE", "gamepad mappings (data)", true},
        {"DejaVu Sans", "https://dejavu-fonts.github.io", "Bitstream-Vera AND LicenseRef-Arev",
         "engine/render/assets/fonts/DejaVu-LICENSE.txt", "built-in font", true},
        {"Press Start 2P", "https://github.com/codeman38/PressStart2P", "OFL-1.1",
         "engine/render/assets/fonts/PressStart2P-OFL.txt", "built-in pixel font", true},
        // The fonts that ship in a game only when it names them (fa/render/builtin_fonts.h): the export copies the files and lists
        // the component in that game's notices.
        {"Crimson Text", "https://github.com/googlefonts/Crimson", "OFL-1.1", "engine/render/assets/fonts/extra/CrimsonText-OFL.txt",
         "built-in font builtin:serif, in games that use it", false, "builtin:serif"},
        {"Kalam", "https://fonts.google.com/specimen/Kalam", "OFL-1.1", "engine/render/assets/fonts/extra/Kalam-OFL.txt",
         "built-in font builtin:hand, in games that use it", false, "builtin:hand"},
        {"UnifrakturMaguntia", "https://fonts.google.com/specimen/UnifrakturMaguntia", "OFL-1.1",
         "engine/render/assets/fonts/extra/UnifrakturMaguntia-OFL.txt", "built-in font builtin:blackletter, in games that use it", false,
         "builtin:blackletter"},
        {"IM Fell English", "https://fonts.google.com/specimen/IM+Fell+English", "OFL-1.1",
         "engine/render/assets/fonts/extra/IMFellEnglish-OFL.txt", "built-in font builtin:display, in games that use it", false,
         "builtin:display"},
        {"Dear ImGui", "https://github.com/ocornut/imgui", "MIT", "external/imgui/LICENSE.txt", "the editor's UI", false},
        // gradlew, gradlew.bat and gradle-wrapper.jar are embedded in factoria and written into every Android export, so
        // that the project builds itself (platforms/android). They end up in the Gradle project, not in the game.
        {"Gradle wrapper", "https://github.com/gradle/gradle", "Apache-2.0", "platforms/licenses/gradle-wrapper-LICENSE.txt",
         "the Gradle wrapper that Android exports write into the Gradle project; not part of the game", false},
        // sokol-shdc, the shader cross-compiler of the developer tools: next to factoria in the release downloads, and what
        // `factoria setup shaders` installs. Built from sokol-tools commit be7a968 (docs/design/CUSTOM_SHADERS.md). It is not in
        // games. The versions are the submodule commits of that commit; the texts are in tools/shaders/licenses/.
        {"sokol-shdc (sokol-tools)", "https://github.com/floooh/sokol-tools", "MIT", "tools/shaders/licenses/sokol-tools-LICENSE.txt",
         "the shader compiler of custom materials, run by the developer tools; not part of the game", false},
        {"glslang (in sokol-shdc)", "https://github.com/KhronosGroup/glslang", "BSD-3-Clause AND the licenses listed in the text",
         "tools/shaders/licenses/glslang-LICENSE.txt", "GLSL front end of sokol-shdc", false},
        {"SPIRV-Cross (in sokol-shdc)", "https://github.com/KhronosGroup/SPIRV-Cross", "Apache-2.0",
         "tools/shaders/licenses/SPIRV-Cross-LICENSE.txt", "SPIR-V to GLSL, HLSL and Metal in sokol-shdc", false},
        {"SPIRV-Tools (in sokol-shdc)", "https://github.com/KhronosGroup/SPIRV-Tools", "Apache-2.0",
         "tools/shaders/licenses/SPIRV-Tools-LICENSE.txt", "SPIR-V validation and optimization in sokol-shdc", false},
        {"SPIRV-Headers (in sokol-shdc)", "https://github.com/KhronosGroup/SPIRV-Headers", "MIT",
         "tools/shaders/licenses/SPIRV-Headers-LICENSE.txt", "SPIR-V definitions in sokol-shdc", false},
        {"Tint (in sokol-shdc)", "https://github.com/floooh/tint-extract", "BSD-3-Clause", "tools/shaders/licenses/tint-LICENSE.txt",
         "SPIR-V to WGSL in sokol-shdc (a subset of Dawn's Tint)", false},
        {"{fmt} (in sokol-shdc)", "https://github.com/fmtlib/fmt", "MIT", "tools/shaders/licenses/fmt-LICENSE.txt",
         "text formatting in sokol-shdc", false},
        {"getopt (in sokol-shdc)", "https://github.com/wc-duck/getopt", "Zlib", "tools/shaders/licenses/getopt-LICENSE.txt",
         "command-line parsing in sokol-shdc", false},
        {"pystring (in sokol-shdc)", "https://github.com/imageworks/pystring", "BSD-3-Clause", "tools/shaders/licenses/pystring-LICENSE.txt",
         "string helpers in sokol-shdc", false},
    };
    return list;
}

}  // namespace fa
