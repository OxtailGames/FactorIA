// The main() of a fuzz target built without FA_FUZZ (every compiler, MSVC included): it runs LLVMFuzzerTestOneInput once for
// every file it is given, so a target's corpus is a regression suite in the normal build and in ctest (label `fuzz`).
//
//   fa_fuzz_<name> [--mutate N] [--seed S] <file or directory>...
//
// Directories are walked recursively, files are run in sorted order. A crash, an assertion or a sanitizer report ends the
// program, and the line printed before each input names the file that did it. It fails when it finds no input at all (a
// corpus path that is wrong must not pass).
//
// `--mutate N` also runs N deterministic mutations of every input (bit flips, byte changes, inserts, deletes, copies of a
// chunk, a splice with another input; the same N and seed give the same inputs on every machine). It is not libFuzzer: no
// coverage feedback, so it finds the shallow bugs only. Where libFuzzer is not installed (Apple Clang), a build with
// -fsanitize=address,undefined and --mutate gives a quick look (docs/BUILDING.md, "Fuzzing").
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);

namespace {

namespace stdfs = std::filesystem;
using Bytes = std::vector<std::uint8_t>;

// xorshift64*: the same numbers everywhere (std::mt19937 distributions differ between standard libraries).
struct Rng {
    std::uint64_t s;
    std::uint64_t next() {
        s ^= s >> 12;
        s ^= s << 25;
        s ^= s >> 27;
        return s * 2685821657736338717ull;
    }
    std::size_t below(std::size_t n) { return n == 0 ? 0 : std::size_t(next() % n); }
};

bool read_file(const stdfs::path& p, Bytes& out) {
    std::ifstream in(p, std::ios::binary);
    if (!in) return false;
    out.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    return true;
}

Bytes mutate(const Bytes& input, const std::vector<Bytes>& all, Rng& rng) {
    constexpr std::size_t kMaxLen = 1 << 16;
    Bytes b = input;
    const int steps = 1 + int(rng.below(4));
    for (int i = 0; i < steps; ++i) {
        switch (rng.below(7)) {
            case 0:
                if (!b.empty()) b[rng.below(b.size())] ^= std::uint8_t(1u << rng.below(8));
                break;
            case 1:
                if (!b.empty()) b[rng.below(b.size())] = std::uint8_t(rng.next());
                break;
            case 2: b.insert(b.begin() + std::ptrdiff_t(rng.below(b.size() + 1)), std::uint8_t(rng.next())); break;
            case 3:
                if (!b.empty()) b.erase(b.begin() + std::ptrdiff_t(rng.below(b.size())));
                break;
            case 4:  // copy a chunk somewhere else
                if (!b.empty() && b.size() < kMaxLen) {
                    const std::size_t from = rng.below(b.size()),
                                      len = 1 + rng.below(std::min<std::size_t>(32, b.size() - from));
                    const Bytes chunk(b.begin() + std::ptrdiff_t(from), b.begin() + std::ptrdiff_t(from + len));
                    b.insert(b.begin() + std::ptrdiff_t(rng.below(b.size() + 1)), chunk.begin(), chunk.end());
                }
                break;
            case 5:  // overwrite four bytes with a number that is often a boundary (sizes, counts, offsets)
                if (b.size() >= 4) {
                    static const std::uint32_t kInteresting[] = {
                        0,      1,      0x7f,    0x80,       0xff,        0x100,       0x7fff,
                        0x8000, 0xffff, 0x10000, 0x7fffffff, 0x80000000u, 0xffffffffu, 0x40000000u};
                    const std::uint32_t v = kInteresting[rng.below(std::size(kInteresting))];
                    std::memcpy(&b[rng.below(b.size() - 3)], &v, 4);
                }
                break;
            default:  // splice: the start of this input and the end of another one
                if (!all.empty()) {
                    const Bytes& other = all[rng.below(all.size())];
                    b.resize(rng.below(b.size() + 1));
                    b.insert(b.end(), other.begin() + std::ptrdiff_t(rng.below(other.size() + 1)), other.end());
                }
                break;
        }
    }
    if (b.size() > kMaxLen) b.resize(kMaxLen);
    return b;
}

}  // namespace

int main(int argc, char** argv) {
    long mutations = 0;
    std::uint64_t seed = 1;
    std::vector<stdfs::path> files;
    for (int i = 1; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--mutate" && i + 1 < argc) {
            mutations = std::atol(argv[++i]);
        } else if (arg == "--seed" && i + 1 < argc) {
            seed = std::strtoull(argv[++i], nullptr, 10);
        } else {
            std::error_code ec;
            const stdfs::path p(arg);
            if (stdfs::is_directory(p, ec)) {
                for (stdfs::recursive_directory_iterator it(p, ec), end; !ec && it != end; it.increment(ec))
                    if (it->is_regular_file(ec)) files.push_back(it->path());
            } else if (stdfs::is_regular_file(p, ec)) {
                files.push_back(p);
            } else {
                std::fprintf(stderr, "fuzz replay: %s is not a file or a directory\n", arg.c_str());
                return 2;
            }
        }
    }
    std::sort(files.begin(), files.end());
    if (files.empty()) {
        std::fprintf(stderr, "fuzz replay: no input files (usage: %s [--mutate N] [--seed S] <file or directory>...)\n",
                     argv[0]);
        return 2;
    }

    std::vector<Bytes> inputs;
    for (const stdfs::path& f : files) {
        Bytes bytes;
        if (!read_file(f, bytes)) {
            std::fprintf(stderr, "fuzz replay: cannot read %s\n", f.generic_string().c_str());
            return 2;
        }
        std::fprintf(stderr, "replay %s (%zu bytes)\n", f.generic_string().c_str(), bytes.size());
        LLVMFuzzerTestOneInput(bytes.data(), bytes.size());
        inputs.push_back(std::move(bytes));
    }
    std::fprintf(stderr, "fuzz replay: %zu inputs ran\n", inputs.size());

    if (mutations > 0) {
        Rng rng{0x9E3779B97F4A7C15ull ^ (seed * 0xD1B54A32D192ED03ull)};
        for (std::size_t n = 0; n < inputs.size(); ++n)
            for (long k = 0; k < mutations; ++k) {
                const Bytes m = mutate(inputs[n], inputs, rng);
                // Written first, so the file a crash needs is on disk before the target runs.
                if (const char* dump = std::getenv("FA_FUZZ_LAST_INPUT"))
                    std::ofstream(dump, std::ios::binary | std::ios::trunc)
                        .write(reinterpret_cast<const char*>(m.data()), std::streamsize(m.size()));
                LLVMFuzzerTestOneInput(m.data(), m.size());
            }
        std::fprintf(stderr, "fuzz replay: %zu mutations ran\n", inputs.size() * std::size_t(mutations));
    }
    return 0;
}
