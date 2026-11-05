// docs/PARTICLES.md: every worked example ("Example `name`:" followed by a fenced JSON block) is a ParticleEmitter that the loader
// accepts, whose checks find nothing wrong, and that runs: it spawns particles and reports no problem while it simulates.
#include <doctest.h>

#include <filesystem>
#include <regex>
#include <sstream>

#include "fa/core/json.h"
#include "fa/scene/particles.h"
#include "fa/core/reflect.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Example {
    std::string name, text;
};

std::vector<Example> examples() {
    std::istringstream in(testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / "PARTICLES.md"));
    static const std::regex label(R"(^Example `([^`]+)`:\s*$)");
    std::vector<Example> out;
    std::string line, pending;
    bool inFence = false;
    Example cur;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (!inFence) {
            std::smatch m;
            if (line.rfind("```", 0) == 0) {
                inFence = true;
                cur = {pending, ""};
                pending.clear();
            } else if (std::regex_match(line, m, label)) {
                pending = m[1];
            } else if (!line.empty()) {
                pending.clear();
            }
        } else if (line.rfind("```", 0) == 0) {
            inFence = false;
            if (!cur.name.empty()) out.push_back(cur);
        } else {
            cur.text += line + "\n";
        }
    }
    return out;
}

}  // namespace

TEST_CASE("docs/PARTICLES.md: the worked examples are real emitters that run") {
    const auto all = examples();
    REQUIRE(all.size() >= 3);
    ensure_builtin_components();
    const TypeInfo* ti = TypeRegistry::global().of<ParticleEmitter>();
    REQUIRE(ti);
    for (const Example& ex : all) {
        INFO("example " << ex.name);
        auto parsed = parse_json(ex.text, ex.name);
        REQUIRE(parsed);
        ParticleEmitter em;
        auto patched = object_patch_from_json(*ti, &em, *parsed);
        if (!patched) FAIL(patched.error().to_string());
        for (const ParticleProblem& p : particle_emitter_problems(em)) FAIL_CHECK(p.pointer << ": " << p.message);
        ParticleSim sim;
        sim.seed(1);
        ParticleEnv env;
        int most = 0;
        for (int i = 0; i < 180; ++i) {
            sim.step(em, env, 1.0f / 60.0f);
            most = std::max(most, int(sim.particles.size()));
        }
        CHECK(most > 5);
        CHECK(sim.take_problems().empty());
    }
}
