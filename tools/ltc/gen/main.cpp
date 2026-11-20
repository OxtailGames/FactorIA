// fa_ltc_gen: fits the LTC tables and writes the generated header (tools/ltc/generate_ltc.sh runs it).
//   fa_ltc_gen [--out <header>] [--check <header>] [--size N] [--samples N] [--iterations N] [--verbose]
// --check fits the table and compares it with the header: exit 0 when equal, 1 when not (the header is not touched).
#include <cstdio>
#include <cstdlib>
#include <string>
#include <string_view>

#include "fa/core/fs.h"
#include "fa/core/jobs.h"
#include "fa/ltc/ltc.h"

namespace {

int usage(const std::string& problem) {
    std::fprintf(stderr,
                 "fa_ltc_gen: %s\nusage: fa_ltc_gen [--out <header>] [--check <header>] [--size N] [--samples N] "
                 "[--iterations N] [--verbose]\n",
                 problem.c_str());
    return 2;
}

bool parse_int(const char* text, int& out) {
    char* end = nullptr;
    const long v = std::strtol(text, &end, 10);
    if (end == text || *end != '\0' || v < 1 || v > 1000000) return false;
    out = static_cast<int>(v);
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    std::string out, check;
    bool verbose = false;
    fa::ltc::TableConfig config;
    for (int i = 1; i < argc; ++i) {
        const std::string_view arg = argv[i];
        auto value = [&](std::string& dst) {
            if (i + 1 >= argc) return false;
            dst = argv[++i];
            return true;
        };
        if (arg == "--out") {
            if (!value(out)) return usage("--out needs a path");
        } else if (arg == "--check") {
            if (!value(check)) return usage("--check needs a path");
        } else if (arg == "--verbose") {
            verbose = true;
        } else if (arg == "--size" || arg == "--samples" || arg == "--iterations") {
            if (i + 1 >= argc || !parse_int(argv[i + 1], arg == "--size"      ? config.size
                                                         : arg == "--samples" ? config.fitSamples
                                                                              : config.iterations))
                return usage(std::string(arg) + " needs a whole number");
            ++i;
        } else {
            return usage("unknown argument '" + std::string(arg) + "'");
        }
    }
    if (out.empty() && check.empty()) return usage("give --out <header> or --check <header>");

    if (auto started = fa::jobs::start(fa::jobs::Settings::automatic()); !started) {
        std::fprintf(stderr, "fa_ltc_gen: %s\n", started.error().to_string().c_str());
        return 1;
    }
    std::printf("fitting a %dx%d table (%d samples per density)...\n", config.size, config.size, config.fitSamples);
    std::fflush(stdout);
    auto table = fa::ltc::fit_table(config);
    fa::jobs::stop();
    if (!table) {
        std::fprintf(stderr, "fa_ltc_gen: %s\n", table.error().to_string().c_str());
        return 1;
    }
    const std::string text = fa::ltc::write_header(table.value(), config);
    std::printf("table hash %016llx\n", static_cast<unsigned long long>(fa::ltc::table_hash(table.value())));
    {
        // How well the lobes fit: the L1 distance to the BRDF (0 = identical, 2 = disjoint) over the cells.
        double sum = 0.0, worst = 0.0;
        int worstCell = 0;
        for (std::size_t k = 0; k < table.value().error.size(); ++k) {
            const double e = static_cast<double>(table.value().error[k]);
            sum += e;
            if (e > worst) {
                worst = e;
                worstCell = static_cast<int>(k);
            }
        }
        std::printf("lobe error (L1): mean %.4f, worst %.4f at roughness cell %d, view cell %d\n",
                    sum / static_cast<double>(table.value().error.size()), worst, worstCell % config.size,
                    worstCell / config.size);
    }
    if (verbose) {  // the L1 error of each cell: a row per view cell, a column per roughness cell
        const auto& t = table.value();
        for (int j = 0; j < t.size; ++j) {
            for (int i = 0; i < t.size; ++i)
                std::printf(" %5.3f", static_cast<double>(t.error[static_cast<std::size_t>(j) * t.size + i]));
            std::printf("\n");
        }
    }
    if (!check.empty()) {
        auto existing = fa::fs::read_text(check);
        if (!existing) {
            std::fprintf(stderr, "fa_ltc_gen: %s\n", existing.error().to_string().c_str());
            return 1;
        }
        std::string have = existing.value();
        std::erase(have, '\r');
        if (have != text) {
            std::fprintf(stderr, "fa_ltc_gen: %s is not what the tool produces: run tools/ltc/generate_ltc.sh\n",
                         check.c_str());
            return 1;
        }
        std::printf("%s is up to date\n", check.c_str());
    }
    if (!out.empty()) {
        if (auto written = fa::fs::write_text(out, text); !written) {
            std::fprintf(stderr, "fa_ltc_gen: %s\n", written.error().to_string().c_str());
            return 1;
        }
        std::printf("wrote %s (%zu bytes)\n", out.c_str(), text.size());
    }
    return 0;
}
