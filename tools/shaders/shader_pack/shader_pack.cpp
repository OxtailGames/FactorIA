// fa_shader_pack <header.glsl.h>...: rewrites generated shader headers (tools/shaders/compile_shaders.sh runs it after
// sokol-shdc) so the GLSL sources of the OpenGL backends are one zstd frame per header and dialect instead of hex text,
// made with the engine's own encoder (fa/core/compress.h). What the engine does with the frame: engine/render/src/shader_text.h.
//
// For each dialect (GLSL ES 3.00 for GLES3 and WebGL2, GLSL 4.30 for desktop GL) the tool
//   * reads every `static const uint8_t NAME_source_<dialect>[N] = { ... };` of the header (a text with its NUL),
//   * writes the texts one after the other as ONE frame (the variants of a program repeat most of their code, so one frame
//     is about half the size of one frame per text) in the place of the first array, and removes the others,
//   * replaces `(const char*)NAME_source_<dialect>` in the shader_desc function by `fa::shader_text::get(pack, offset)`,
//     which decodes the frame once and points into it,
//   * checks that the frame decodes to the original bytes before it writes anything,
//   * and, behind FA_SHADER_TEXT_CHECK, adds a table with the FNV-1a hash of every original text, which the render tests
//     decode and compare (engine/render/tests/shader_text_tests.cpp).
// A text no desc function uses (a variant of a template no program of the file calls) is dropped: nothing can read it, and the
// compiler dropped it from the binary anyway. The output is a function of the input and the engine's encoder: no clock, no
// randomness. A header with no such array (or one this tool already rewrote) is left as it is.
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/compress.h"
#include "shader_text.h"

namespace {

constexpr int kLevel = 19;

struct Dialect {
    std::string_view name;   // the suffix sokol-shdc gives the arrays: NAME_source_<name>
    std::string_view guard;  // the sokol backend macro that keeps the dialect out of the other backends' builds
};
constexpr Dialect kDialects[] = {{"glsl300es", "SOKOL_GLES3"}, {"glsl430", "SOKOL_GLCORE"}};

struct Text {
    std::string name;  // NAME_source_<dialect>
    std::size_t first = 0, last = 0;  // the lines of its `#if` .. `#endif`
    std::size_t offset = 0;
    std::vector<std::uint8_t> bytes;
    bool used = false;
};

bool starts_with(const std::string& s, std::string_view p) { return s.compare(0, p.size(), p) == 0; }

bool fail(const std::string& path, const std::string& what) {
    std::cerr << "fa_shader_pack: " << path << ": " << what << "\n";
    return false;
}

std::string hex64(std::uint64_t v) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "0x%016llxull", static_cast<unsigned long long>(v));
    return buf;
}

void write_bytes(std::ostringstream& out, const std::vector<std::uint8_t>& bytes) {
    char buf[8];
    for (std::size_t i = 0; i < bytes.size(); ++i) {
        if (i % 16 == 0) out << "    ";
        std::snprintf(buf, sizeof buf, "0x%02x,", bytes[i]);
        out << buf << (i % 16 == 15 || i + 1 == bytes.size() ? "\n" : "");
    }
}

// `static const uint8_t NAME_source_<dialect>[N] = {` after `#if defined(<guard>)`: the text at line `i`, or false.
bool array_at(const std::vector<std::string>& lines, std::size_t i, const Dialect& d, Text& t, std::size_t& size) {
    if (i + 1 >= lines.size() || lines[i] != "#if defined(" + std::string(d.guard) + ")") return false;
    const std::string& line = lines[i + 1];
    constexpr std::string_view head = "static const uint8_t ";
    if (!starts_with(line, head)) return false;
    const std::size_t open = line.find('[', head.size());
    if (open == std::string::npos) return false;
    const std::string name = line.substr(head.size(), open - head.size());
    const std::string suffix = "_source_" + std::string(d.name);
    if (name.size() <= suffix.size() || name.compare(name.size() - suffix.size(), suffix.size(), suffix) != 0) return false;
    const std::size_t close = line.find(']', open);
    if (close == std::string::npos || line.compare(close, std::string::npos, "] = {") != 0) return false;
    t.name = name;
    size = static_cast<std::size_t>(std::strtoull(line.c_str() + open + 1, nullptr, 10));
    return true;
}

// One dialect of one header: the texts, their frame, and the rewritten lines (`lines` is replaced).
bool pack_dialect(const std::string& path, const std::string& base, const Dialect& d, std::vector<std::string>& lines,
                  bool stats) {
    std::vector<Text> texts;
    for (std::size_t i = 0; i < lines.size(); ++i) {
        Text t;
        std::size_t size = 0;
        if (!array_at(lines, i, d, t, size)) continue;
        std::size_t j = i + 2;
        for (; j < lines.size() && lines[j] != "};"; ++j) {
            for (std::size_t p = lines[j].find("0x"); p != std::string::npos; p = lines[j].find("0x", p + 2))
                t.bytes.push_back(static_cast<std::uint8_t>(std::strtoul(lines[j].substr(p + 2, 2).c_str(), nullptr, 16)));
        }
        if (j + 1 >= lines.size() || t.bytes.size() != size || t.bytes.empty() || t.bytes.back() != 0 ||
            lines[j + 1].rfind("#endif", 0) != 0)
            return fail(path, t.name + " is not a NUL-terminated array of " + std::to_string(size) +
                                  " bytes closed by #endif (sokol-shdc changed its output?)");
        t.first = i;
        t.last = j + 1;
        texts.push_back(std::move(t));
        i = j + 1;
    }
    if (texts.empty()) return true;

    // Which texts a desc function reads, and the lines that do.
    const std::string pack = base + "_" + std::string(d.name) + "_pack";
    std::vector<std::uint8_t> all;
    std::vector<Text*> kept;
    for (Text& t : texts) {
        const std::string use = "(const char*)" + t.name + ";";
        for (const std::string& line : lines) t.used = t.used || line.find(use) != std::string::npos;
        if (!t.used) continue;
        t.offset = all.size();
        all.insert(all.end(), t.bytes.begin(), t.bytes.end());
        kept.push_back(&t);
    }
    if (kept.empty()) return fail(path, "no desc function reads a " + std::string(d.name) + " text");
    fa::CompressOptions options;
    options.codec = fa::Codec::Zstd;
    options.level = kLevel;
    auto frame = fa::compress(all, options);
    if (!frame) return fail(path, frame.error().to_string());
    auto back = fa::decompress(fa::Codec::Zstd, *frame, all.size());
    if (!back || *back != all) return fail(path, "the " + std::string(d.name) + " frame does not decode to the original texts");
    std::size_t before = 0;
    for (const Text& t : texts) before += t.bytes.size();
    std::cerr << path << ": " << d.name << " " << kept.size() << " of " << texts.size() << " texts, " << before << " -> "
              << frame->size() << " bytes\n";

    const std::string guard = "defined(" + std::string(d.guard) + ") || defined(FA_SHADER_TEXT_CHECK)";
    std::ostringstream out;
    bool placed = false;
    for (std::size_t i = 0; i < lines.size(); ++i) {
        const Text* here = nullptr;
        for (const Text& t : texts)
            if (t.first == i) here = &t;
        if (here) {
            if (!placed) {
                placed = true;
                out << "#if " << guard << "\n#include \"../shader_text.h\"\n";
                out << "/* The " << d.name << " texts of this file (" << all.size() << " bytes, NUL after each) as one zstd frame: "
                    << "tools/shaders/shader_pack, engine/render/src/shader_text.h. */\n";
                out << "static const uint8_t " << pack << "_z[" << frame->size() << "] = {\n";
                write_bytes(out, *frame);
                out << "};\nstatic const fa::shader_text::Pack " << pack << " = {" << pack << "_z, sizeof(" << pack << "_z), "
                    << all.size() << "};\n#endif\n";
            }
            i = here->last;
            continue;
        }
        std::string line = lines[i];
        for (const Text* t : kept) {
            const std::string use = "(const char*)" + t->name + ";";
            const std::size_t at = line.find(use);
            if (at != std::string::npos)
                line.replace(at, use.size(), "fa::shader_text::get(" + pack + ", " + std::to_string(t->offset) + ");");
        }
        out << line << "\n";
    }
    out << "#if defined(FA_SHADER_TEXT_CHECK)\n";
    out << "static const fa::shader_text::Entry " << pack << "_entries[] = {\n";
    for (const Text* t : kept)
        out << "    {\"" << t->name << "\", " << t->offset << ", " << t->bytes.size() << ", "
            << hex64(fa::shader_text::fnv1a64(reinterpret_cast<const char*>(t->bytes.data()), t->bytes.size())) << "},\n";
    out << "};\nstatic const fa::shader_text::Texts " << pack << "_texts = {\"" << base << "." << d.name << "\", &" << pack << ", "
        << pack << "_entries, sizeof(" << pack << "_entries) / sizeof(" << pack << "_entries[0])};\n#endif\n";
    (void)stats;
    std::vector<std::string> next;
    std::istringstream split(out.str());
    for (std::string line; std::getline(split, line);) next.push_back(std::move(line));
    lines = std::move(next);
    return true;
}

bool process(const std::string& path, bool stats) {
    std::ifstream in(path, std::ios::binary);
    if (!in) return fail(path, "cannot read it");
    std::vector<std::string> lines;
    for (std::string line; std::getline(in, line);) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        lines.push_back(std::move(line));
    }
    in.close();
    const std::size_t slash = path.find_last_of("/\\");
    const std::string file = slash == std::string::npos ? path : path.substr(slash + 1);
    const std::string base = file.substr(0, file.find('.'));
    for (const std::string& line : lines)
        if (line.find("fa::shader_text::") != std::string::npos) return true;  // already packed
    for (const Dialect& d : kDialects)
        if (!pack_dialect(path, base, d, lines, stats)) return false;
    if (stats) return true;
    const std::string tmp = path + ".pack";
    {
        std::ofstream o(tmp, std::ios::binary | std::ios::trunc);
        for (const std::string& line : lines) o << line << "\n";
        o.flush();
        if (!o) return fail(tmp, "cannot write it");
    }
    std::remove(path.c_str());
    if (std::rename(tmp.c_str(), path.c_str()) != 0) return fail(path, "cannot replace it with " + tmp);
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    bool stats = false, ok = true;
    int files = 0;
    for (int i = 1; i < argc; ++i) {
        if (std::string_view(argv[i]) == "--stats") {
            stats = true;
            continue;
        }
        ++files;
        ok = process(argv[i], stats) && ok;
    }
    if (files == 0) {
        std::cerr << "usage: fa_shader_pack [--stats] <header.glsl.h>...\n";
        return 2;
    }
    return ok ? 0 : 1;
}
