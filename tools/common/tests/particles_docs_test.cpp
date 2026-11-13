// docs/PARTICLES.md: every worked example ("Example `name`:" followed by a fenced JSON block) is a ParticleEmitter that the loader
// accepts, whose checks find nothing wrong, and that runs: it spawns particles and reports no problem while it simulates.
#include <doctest.h>

#include <filesystem>
#include <regex>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/scene/particles.h"
#include "fa/scene/vfx.h"
#include "fa/scene/world.h"
#include "fa/core/reflect.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Example {
    std::string name, text;
};

// `label` is "Example" (a ParticleEmitter) or "Effect" (a *.vfx.json document).
std::vector<Example> examples(const std::string& kind = "Example") {
    std::istringstream in(testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / "PARTICLES.md"));
    const std::regex label("^" + kind + R"( `([^`]+)`:\s*$)");
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

TEST_CASE("docs/PARTICLES.md: the worked effect documents parse without a problem and play") {
    const auto all = examples("Effect");
    REQUIRE(all.size() >= 1);
    ensure_builtin_components();
    for (const Example& ex : all) {
        INFO("effect " << ex.name);
        auto json = parse_json(ex.text, ex.name);
        REQUIRE(json);
        std::vector<VfxIssue> issues;
        auto doc = parse_vfx(*json, ex.name + ".vfx.json", &issues);
        if (!doc) FAIL(doc.error().to_string());
        for (const VfxIssue& i : issues) FAIL_CHECK(i.pointer << ": " << i.message);
        // Play it from a file: the parts happen, the sound is asked for once and the entity goes when it is over.
        const stdfs::path dir = fs::make_temp_dir("fa-vfx-docs-").value();
        const std::string file = (dir / "doc.vfx.json").generic_string();
        REQUIRE(fs::write_text(file, ex.text));
        World world;
        int sounds = 0;
        VfxHost host;
        host.play_sound = [&](const std::string&, float, float, const std::string&) {
            ++sounds;
            return true;
        };
        auto played = vfx_play(world, file);
        REQUIRE(played);
        std::size_t children = 0;
        for (int step = 0; step < 90; ++step) {
            update_vfx(world, 1.0f / 60.0f, host);
            if (world.alive(*played)) children = std::max(children, world.children(*played).size());
        }
        CHECK(children >= 2);  // the emitter and the light of the example
        CHECK(sounds == 1);
        CHECK_FALSE(vfx_playing_count(world) > 0);
        std::error_code ec;
        stdfs::remove_all(dir, ec);
        clear_vfx_cache();
    }
}
