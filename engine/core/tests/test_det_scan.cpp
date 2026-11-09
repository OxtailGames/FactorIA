// M91.3: the simulation never calls the C library's transcendentals.
//
// The C library's sin, cos, exp, pow, log, ... (glibc, Apple's libm, the MSVC CRT, musl in wasm) are each accurate to about
// one ulp but round differently, so a step that calls them drifts apart between machines: the replay hashes, the lockstep
// netcode and `factoria test` results depend on the same bits everywhere. The simulation uses fa/core/det_math.h instead
// (fa::det::sin, exp, pow, ... for float; fa::det::f64::... for double). sqrt, floor, fmod, fabs, ldexp ... are exact in
// IEEE 754 and stay as they are.
//
// This test reads the SOURCE of the simulation and fails on `std::exp`, `std::pow`, `std::sin`, `std::cos` (and every
// other function of the list below) and on their unqualified and C forms (`pow(`, `sinf(`, `::cos(`). Comments and string
// literals are ignored.
//
// HOW TO ADD A FILE OR A DIRECTORY
//   * New simulation code in a directory that is already listed in kSimulationDirs is covered with no edit.
//   * Simulation code anywhere else (for example SpriteAnimator or the particle simulation once they move out of
//     engine/render into the simulation step, M91.1a): add its path (relative to the repository root, forward slashes) to
//     kSimulationFiles, or its directory to kSimulationDirs. Then make the test pass by using fa::det:: in that code.
//   * A file that really needs the C library (an asset importer, an audio mixer, a debug print) goes into kExempt with the
//     reason; it must not be simulation. Rendering, the editor, tools, tests and audio are not scanned at all.
//
// Known limit: an UNQUALIFIED `log(` is not flagged, because `fa::log(level, ...)` (the logger) is called that way all over
// the engine; write `std::log` if you mean the maths (this test flags it) and prefer `det::log`.
#include <doctest.h>

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <string_view>
#include <vector>

#include "fa_test_paths.h"

namespace {

namespace fs = std::filesystem;

// Directories scanned recursively (.cpp .h .hpp .inl .mm are read). Relative to the repository root.
constexpr const char* kSimulationDirs[] = {
    "engine/core/include",      // math.h, det_math.h, ... : used by everything
    "engine/core/src",
    "engine/scene/src",         // components, feel, tweens, animation clips, vfx, particles, nav data, models, rigs
    "engine/scene/include",
    "engine/physics/src",       // physics 2D/3D, nav grid / flow / tiles, character controller
    "engine/physics/include",
    "engine/script/src",        // the script system and its natives
    "engine/script/include",
    "engine/runtime/src",       // the fixed step, commands, the engine loop
    "engine/runtime/include",
    "engine/ui/src",            // UI layout
    "engine/ui/include",
    "engine/services/src",
    "engine/services/include",
};

// Single files outside those directories. M91.1a: add the SpriteAnimator and particle simulation files that leave
// engine/render here (or their directory to kSimulationDirs).
const std::vector<std::string_view> kSimulationFiles = {
    // "engine/render/src/sprite_animator_sim.cpp",
};

struct Exempt { const char* path; const char* reason; };
constexpr Exempt kExempt[] = {
    {"engine/core/include/fa/core/det_math.h", "defines the deterministic functions (the names are its own)"},
    {"engine/core/src/image.cpp", "sRGB <-> linear of decoded images: asset import and screenshots, not the simulation step"},
};

// The functions whose results differ between C libraries.
constexpr std::string_view kNames[] = {
    "exp", "exp2", "expm1", "pow", "log", "log2", "log10", "log1p", "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
    "sinh", "cosh", "tanh", "asinh", "acosh", "atanh", "cbrt", "hypot", "sincos", "erf", "erfc", "tgamma", "lgamma",
};

bool is_ident(char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'; }

// `src` with comments, string literals and character literals blanked out (newlines kept, so line numbers stay).
std::string strip_comments_and_strings(std::string_view src) {
    std::string out(src);
    const std::size_t n = src.size();
    auto blank = [&](std::size_t from, std::size_t to) {
        for (std::size_t i = from; i < to && i < n; ++i)
            if (out[i] != '\n') out[i] = ' ';
    };
    std::size_t i = 0;
    while (i < n) {
        const char c = src[i];
        if (c == '/' && i + 1 < n && src[i + 1] == '/') {
            std::size_t e = i;
            while (e < n && src[e] != '\n') ++e;
            blank(i, e);
            i = e;
        } else if (c == '/' && i + 1 < n && src[i + 1] == '*') {
            std::size_t e = src.find("*/", i + 2);
            e = e == std::string_view::npos ? n : e + 2;
            blank(i, e);
            i = e;
        } else if (c == '"') {
            // A raw string R"delim( ... )delim" (the R is the previous character, maybe after u8 / L / u / U).
            const bool raw = i > 0 && src[i - 1] == 'R' && (i < 2 || !is_ident(src[i - 2]) || src[i - 2] == '8' || src[i - 2] == 'L' ||
                                                              src[i - 2] == 'u' || src[i - 2] == 'U');
            if (raw) {
                const std::size_t open = src.find('(', i);
                if (open == std::string_view::npos) { i = n; break; }
                const std::string close = ")" + std::string(src.substr(i + 1, open - i - 1)) + "\"";
                std::size_t e = src.find(close, open);
                e = e == std::string_view::npos ? n : e + close.size();
                blank(i, e);
                i = e;
            } else {
                std::size_t e = i + 1;
                while (e < n && src[e] != '"' && src[e] != '\n') e += src[e] == '\\' ? 2 : 1;
                blank(i, e + 1);
                i = e + 1;
            }
        } else if (c == '\'') {
            // A digit separator (1'000) is not a character literal.
            if (i > 0 && (std::isxdigit(static_cast<unsigned char>(src[i - 1])) != 0) && i + 1 < n &&
                (std::isxdigit(static_cast<unsigned char>(src[i + 1])) != 0)) {
                ++i;
                continue;
            }
            std::size_t e = i + 1;
            while (e < n && src[e] != '\'' && src[e] != '\n') e += src[e] == '\\' ? 2 : 1;
            blank(i, e + 1);
            i = e + 1;
        } else {
            ++i;
        }
    }
    return out;
}

struct Finding { int line; std::string text; };

bool is_keyword_before_call(std::string_view w) {
    return w == "return" || w == "case" || w == "else" || w == "throw" || w == "co_return" || w == "co_yield" || w == "do" ||
           w == "not" || w == "and" || w == "or" || w == "xor" || w == "sizeof" || w == "decltype" || w == "typeof";
}

// The libm uses in C++ source `code` (already stripped).
std::vector<Finding> find_libm_uses(std::string_view code) {
    std::vector<Finding> found;
    const std::size_t n = code.size();
    int line = 1;
    for (std::size_t i = 0; i < n;) {
        if (code[i] == '\n') { ++line; ++i; continue; }
        if (!is_ident(code[i])) { ++i; continue; }
        const std::size_t start = i;
        while (i < n && is_ident(code[i])) ++i;
        std::string_view word = code.substr(start, i - start);
        // Strip the C suffix: sinf, powl.
        std::string_view base = word;
        bool suffixed = false;
        if (base.size() > 1 && (base.back() == 'f' || base.back() == 'l')) {
            const std::string_view head = base.substr(0, base.size() - 1);
            if (std::find(std::begin(kNames), std::end(kNames), head) != std::end(kNames)) { base = head; suffixed = true; }
        }
        if (std::find(std::begin(kNames), std::end(kNames), base) == std::end(kNames)) continue;
        if (is_ident(code[start == 0 ? 0 : start - 1]) && start > 0) continue;  // (cannot happen: words are read whole)

        // What stands before: a qualifier, a member access, a type (a declaration), an operator.
        std::size_t b = start;
        while (b > 0 && (code[b - 1] == ' ' || code[b - 1] == '\t')) --b;
        std::string qualifier;
        bool qualified = false;
        if (b >= 2 && code[b - 1] == ':' && code[b - 2] == ':') {
            qualified = true;
            std::size_t q = b - 2;
            while (q > 0 && (code[q - 1] == ' ' || code[q - 1] == '\t')) --q;
            std::size_t qs = q;
            while (qs > 0 && is_ident(code[qs - 1])) --qs;
            qualifier = std::string(code.substr(qs, q - qs));
        } else if (b >= 1 && code[b - 1] == '.') {
            continue;  // a member: x.sin(...)
        } else if (b >= 2 && code[b - 1] == '>' && code[b - 2] == '-') {
            continue;  // a member: p->sin(...)
        }
        std::size_t a = i;
        while (a < n && (code[a] == ' ' || code[a] == '\t')) ++a;
        const bool call = a < n && code[a] == '(';

        bool flagged = false;
        if (qualified) {
            flagged = qualifier.empty() || qualifier == "std";  // ::sin, std::sin (a call, a pointer, anything)
        } else if (call) {
            // A declaration or definition (`float sin(float x)`): an identifier that is not a keyword stands before.
            bool declaration = false;
            if (b > 0 && is_ident(code[b - 1])) {
                std::size_t ws = b;
                while (ws > 0 && is_ident(code[ws - 1])) --ws;
                declaration = !is_keyword_before_call(code.substr(ws, b - ws));
            }
            // fa::log(level, ...) is the logger; see the known limit in the header comment.
            const bool logger = base == "log" && !suffixed;
            flagged = !declaration && !logger;
        }
        if (flagged) {
            std::size_t ls = start, le = i;
            while (ls > 0 && code[ls - 1] != '\n') --ls;
            while (le < n && code[le] != '\n') ++le;
            std::string text(code.substr(ls, le - ls));
            const std::size_t first = text.find_first_not_of(" \t");
            found.push_back({line, first == std::string::npos ? text : text.substr(first)});
        }
    }
    return found;
}

fs::path repo_root() {
    const char* r = FA_REPO_ROOT;
    return fs::path(std::u8string(reinterpret_cast<const char8_t*>(r)));  // UTF-8, never the ANSI code page
}

bool read_text(const fs::path& p, std::string& out) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return false;
    out.assign(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
    return true;
}

bool is_source(const fs::path& p) {
    const std::string ext = p.extension().string();
    return ext == ".cpp" || ext == ".h" || ext == ".hpp" || ext == ".inl" || ext == ".mm";
}

std::string rel_path(const fs::path& root, const fs::path& p) {
    const auto u = fs::relative(p, root).generic_u8string();
    return std::string(u.begin(), u.end());
}

bool exempt(const std::string& rel) {
    return std::any_of(std::begin(kExempt), std::end(kExempt), [&](const Exempt& e) { return rel == e.path; });
}

}  // namespace

TEST_CASE("det scan: the matcher flags the C library's forms and nothing else") {
    auto flagged = [](std::string_view src) { return find_libm_uses(strip_comments_and_strings(src)).size(); };
    CHECK(flagged("float a = std::exp(x);") == 1);
    CHECK(flagged("float a = std::pow(x, 2.0f);") == 1);
    CHECK(flagged("auto a = std::sin(x) + std::cos(y);") == 2);
    CHECK(flagged("double a = pow(x, y);") == 1);
    CHECK(flagged("float a = sinf(x) * cosf(y);") == 2);
    CHECK(flagged("float a = ::atan2(y, x);") == 1);
    CHECK(flagged("auto f = std::sin;") == 1);
    CHECK(flagged("transform(a, b, std::exp);") == 1);
    CHECK(flagged("return exp2(x);") == 1);
    CHECK(flagged("x = 2 * hypot(a, b);") == 1);
    CHECK(flagged("float a = std::log(x);") == 1);
    CHECK(flagged("float a = std::tanh(x);") == 1);
    // The deterministic functions, other namespaces and members.
    CHECK(flagged("float a = det::exp(x) + fa::det::pow(x, y) + det::f64::sin(z);") == 0);
    CHECK(flagged("float a = sfx_math::pow(x, y);") == 0);
    CHECK(flagged("float a = body.sin(x) + p->cos(y);") == 0);
    CHECK(flagged("fa::log(LogLevel::Warn, \"x\", msg); log(LogLevel::Info, \"x\", msg);") == 0);
    // Exact functions stay allowed.
    CHECK(flagged("float a = std::sqrt(x) + std::floor(y) + std::fmod(z, 2.0f) + std::fabs(w) + std::ldexp(v, 3);") == 0);
    // Declarations and definitions of something called like a libm function.
    CHECK(flagged("inline float sin(float x) { return 0; }") == 0);
    CHECK(flagged("std::vector<Vec3> tan(n);") == 1);  // after '>' it reads as a call: rename such a variable
    // Comments and strings.
    CHECK(flagged("// std::exp(x) in a comment\nint a;") == 0);
    CHECK(flagged("/* std::pow(x, y)\n   std::sin(x) */ int a;") == 0);
    CHECK(flagged("const char* s = \"std::cos(x) and pow(x, y)\";") == 0);
    CHECK(flagged("const char* s = R\"doc(\nstd::exp(x)\n)doc\"; int a = 1;") == 0);
    CHECK(flagged("char c = '\"'; float a = std::exp(x);") == 1);
    CHECK(flagged("int a = 1'000; float b = std::exp(x);") == 1);
    // Line numbers.
    const auto found = find_libm_uses(strip_comments_and_strings("int a;\n// c\nfloat b = std::pow(1, 2);\n"));
    REQUIRE(found.size() == 1);
    CHECK(found[0].line == 3);
}

TEST_CASE("det scan: the simulation sources call no libm transcendental") {
    const fs::path root = repo_root();
    std::vector<fs::path> files;
    for (const char* dir : kSimulationDirs) {
        const fs::path d = root / fs::path(std::u8string(reinterpret_cast<const char8_t*>(dir)));
        INFO("kSimulationDirs lists " << dir << ", which does not exist: a rename must update this test");
        REQUIRE(fs::is_directory(d));
        for (const auto& entry : fs::recursive_directory_iterator(d))
            if (entry.is_regular_file() && is_source(entry.path())) files.push_back(entry.path());
    }
    for (const std::string_view file : kSimulationFiles) {
        const fs::path p = root / fs::path(std::u8string(file.begin(), file.end()));
        std::error_code ec;
        if (fs::is_regular_file(p, ec)) files.push_back(p);  // a listed file that is not there (yet) is skipped
    }
    std::sort(files.begin(), files.end());
    files.erase(std::unique(files.begin(), files.end()), files.end());
    CHECK(files.size() > 150);  // the directories really were read

    int bad = 0;
    for (const fs::path& p : files) {
        const std::string rel = rel_path(root, p);
        if (exempt(rel)) continue;
        std::string text;
        REQUIRE_MESSAGE(read_text(p, text), "cannot read " << rel);
        for (const Finding& f : find_libm_uses(strip_comments_and_strings(text))) {
            ++bad;
            MESSAGE(rel << ":" << f.line << ": " << f.text
                        << "\n  -> use fa::det:: (fa/core/det_math.h; fa::det::f64:: for double), or list the file in kExempt "
                           "of engine/core/tests/test_det_scan.cpp if it is not simulation");
        }
    }
    CHECK(bad == 0);
}

TEST_CASE("det scan: the exempt files exist, so the list cannot rot") {
    const fs::path root = repo_root();
    for (const Exempt& e : kExempt) {
        INFO(e.path << " is in kExempt but does not exist");
        CHECK(fs::is_regular_file(root / fs::path(std::u8string(reinterpret_cast<const char8_t*>(e.path)))));
    }
}
