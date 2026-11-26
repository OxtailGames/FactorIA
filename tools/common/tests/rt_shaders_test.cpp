// The ray tracing kernels (engine/render/shaders/rt/*.hlsl + .metal) and their committed generated headers
// (engine/render/src/shaders/rt/*.rt.h, tools/shaders/compile_rt_shaders.sh). A Mac cannot make the DXIL and the SPIR-V (no DXC
// build), so what keeps a header honest is checked here, on every host, without DXC: the header records the SHA-256 of the sources
// its blobs come from and of each blob; a source edited without the Linux CI job's regeneration, a header edited by hand and a DXC
// pin that moved without a regeneration all fail with the command that fixes them.
#include <doctest.h>

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <filesystem>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/hash.h"
#include "fa/tooling/setup.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Blob {
    std::string label, sha256;
    std::size_t bytes = 0;
    std::string data;  // the array's bytes
    bool found = false;
};

std::string meta(const std::string& text, const std::string& key) {
    const std::string tag = "// " + key + ": ";
    const std::size_t at = text.find(tag);
    if (at == std::string::npos) return {};
    const std::size_t end = text.find('\n', at);
    return text.substr(at + tag.size(), end - at - tag.size());
}

Blob blob(const std::string& text, const std::string& label) {
    Blob b;
    b.label = label;
    const std::string begin = "// BEGIN " + label + " sha256=";
    const std::size_t at = text.find(begin);
    if (at == std::string::npos) return b;
    const std::size_t lineEnd = text.find('\n', at);
    std::istringstream header(text.substr(at + begin.size(), lineEnd - at - begin.size()));
    std::string bytes;
    header >> b.sha256 >> bytes;  // "<hash> bytes=<n>"
    if (bytes.rfind("bytes=", 0) == 0) b.bytes = std::stoull(bytes.substr(6));
    const std::size_t end = text.find("// END " + label + "\n", lineEnd);
    if (end == std::string::npos) return b;
    const std::string body = text.substr(lineEnd, end - lineEnd);
    for (std::size_t i = 0; i + 3 < body.size(); ++i)
        if (body[i] == '0' && body[i + 1] == 'x' && std::isxdigit(static_cast<unsigned char>(body[i + 2])) &&
            std::isxdigit(static_cast<unsigned char>(body[i + 3]))) {
            b.data.push_back(static_cast<char>(std::stoi(body.substr(i + 2, 2), nullptr, 16)));
            i += 3;
        }
    b.found = true;
    return b;
}

const char* kFix =
    " (regenerate: tools/shaders/compile_rt_shaders.sh; on a computer without DXC the Linux CI job does it and "
    "uploads the headers as the artifact rt-shader-headers)";

}  // namespace

TEST_CASE("rt shaders: every kernel has an HLSL, a Metal twin and a header that matches them and the DXC pin") {
    const stdfs::path root = stdfs::path(FA_REPO_ROOT);
    const stdfs::path sources = root / "engine" / "render" / "shaders" / "rt";
    const stdfs::path headers = root / "engine" / "render" / "src" / "shaders" / "rt";
    const std::string registry = testing::read_all(root / "engine" / "render" / "src" / "rt_kernels.h");
    int kernels = 0;
    for (const auto& entry : stdfs::directory_iterator(sources)) {
        if (entry.path().extension() != ".hlsl") continue;
        const std::string name = entry.path().stem().string();
        CAPTURE(name);
        ++kernels;
        const std::string hlsl = testing::read_all(entry.path());
        const std::string msl = testing::read_all(sources / (name + ".metal"));
        REQUIRE_MESSAGE(!msl.empty(), name << ".metal (the Metal twin of the HLSL) is missing");
        CHECK(hlsl.find('\r') == std::string::npos);  // .gitattributes: LF, the hashes below are of these bytes
        const std::string header = testing::read_all(headers / (name + ".rt.h"));
        REQUIRE_MESSAGE(!header.empty(), name << ".rt.h is missing" << kFix);
        CHECK_MESSAGE(registry.find("shaders/rt/" + name + ".rt.h") != std::string::npos,
                      "engine/render/src/rt_kernels.h does not include the header of " << name);

        CHECK_MESSAGE(meta(header, "msl-sha256") == sha256_hex(msl),
                      name << ".metal changed since its header was made" << kFix);
        CHECK_MESSAGE(meta(header, "hlsl-sha256") == sha256_hex(hlsl),
                      name << ".hlsl changed since the DXIL and SPIR-V of its header were made" << kFix);
        CHECK_MESSAGE(meta(header, "dxc-version") == kSetupDxcVersion,
                      "the blobs of " << name << ".rt.h come from DXC " << meta(header, "dxc-version")
                                      << ", the pin of setup.h is " << kSetupDxcVersion << kFix);

        for (const char* label : {"dxil", "spirv", "msl"}) {
            CAPTURE(label);
            const Blob b = blob(header, label);
            REQUIRE_MESSAGE(b.found,
                            "no `// BEGIN " << label << "` ... `// END " << label << "` in " << name << ".rt.h");
            if (std::string(label) == "msl") {
                REQUIRE(!b.data.empty());
                CHECK(b.data.back() == '\0');
                const std::string text = b.data.substr(0, b.data.size() - 1);
                CHECK(text == msl);  // exactly the .metal file, and the NUL after it
                CHECK(b.bytes == msl.size());
            } else {
                CHECK(b.bytes == b.data.size());
            }
            if (std::string(label) != "msl")
                CHECK_MESSAGE(sha256_hex(b.data) == b.sha256,
                              label << " blob of " << name << ".rt.h was edited by hand" << kFix);
            else
                CHECK(b.sha256 == meta(header, "msl-sha256"));
        }
        const Blob dxil = blob(header, "dxil"), spirv = blob(header, "spirv");
        CHECK(dxil.data.rfind("DXBC", 0) == 0);
        CHECK(spirv.data.size() > 20);
        CHECK(spirv.data.size() % 4 == 0);
        CHECK(static_cast<unsigned char>(spirv.data[0]) == 0x03);  // 0x07230203, little endian
        CHECK(static_cast<unsigned char>(spirv.data[3]) == 0x07);
    }
    CHECK(kernels >= 1);  // rt_probe: the kernel P0b commits
}

TEST_CASE(
    "rt shaders: compile_rt_shaders.sh reads the DXC version from setup.h and the CI job caches the pinned build") {
    const stdfs::path root = stdfs::path(FA_REPO_ROOT);
    const std::string script = testing::read_all(root / "tools" / "shaders" / "compile_rt_shaders.sh");
    REQUIRE(!script.empty());
    const std::string setupH = testing::read_all(root / "tools" / "common" / "include" / "fa" / "tooling" / "setup.h");
    // The script cuts the version out of this line with sed.
    CHECK(setupH.find(std::string("inline constexpr const char* kSetupDxcVersion = \"") + kSetupDxcVersion + "\";") !=
          std::string::npos);
    CHECK(script.find("kSetupDxcVersion") != std::string::npos);
    const std::string ci = testing::read_all(root / ".github" / "workflows" / "ci.yml");
    REQUIRE(!ci.empty());
    CHECK(ci.find("compile_rt_shaders.sh") != std::string::npos);
    CHECK(ci.find("rt-shader-headers") != std::string::npos);
    // The cache key of the DXC download carries the pinned version, so a new pin is a new download. It is written twice
    // (the restore step and the save step), and only the parts that matter are matched: the runner's OS and the pin the
    // `dxc-pin` step prints, with any spacing inside the `${{ }}` (a re-indented or re-quoted workflow still passes).
    size_t keys = 0;
    for (size_t at = ci.find("key: dxc-"); at != std::string::npos; at = ci.find("key: dxc-", at + 1)) {
        const size_t end = ci.find('\n', at);
        std::string line = ci.substr(at, end == std::string::npos ? std::string::npos : end - at);
        line.erase(std::remove_if(line.begin(), line.end(), [](char c) { return c == ' '; }), line.end());
        if (line.find("${{runner.os}}") != std::string::npos &&
            line.find("steps.dxc-pin.outputs.pin") != std::string::npos)
            ++keys;
    }
    CHECK_MESSAGE(keys >= 2, "ci.yml: the restore and the save of the DXC cache use a key with the pinned version");
}
