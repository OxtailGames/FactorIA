// vfx_measure (fa/scene/vfx_budget.h): the numbers an effect costs, the findings against a phone budget, and that it is repeatable.
#include <doctest.h>

#include <string>

#include "fa/scene/vfx_budget.h"

using namespace fa;

namespace {

std::shared_ptr<const VfxDoc> doc_of(const std::string& text, const char* path = "assets/vfx/test.vfx.json") {
    auto j = parse_json(text, "test");
    REQUIRE(j.ok());
    auto d = parse_vfx(j.value(), path);
    REQUIRE_MESSAGE(d.ok(), d.error().message);
    return d.value();
}

// One burst of `n` particles of size `size` that live `life` seconds and do not move, so the counts are exact.
std::string burst(int n, double size, double life, int cap) {
    return R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"puff","emitter":{"burst":)" + std::to_string(n) +
           R"(,"rate":0,"lifetime":)" + std::to_string(life) + R"(,"lifetimeVariance":0,"startSize":)" + std::to_string(size) + R"(,"endSize":)" +
           std::to_string(size) + R"(,"speed":0,"speedVariance":0,"maxParticles":)" + std::to_string(cap) + R"(}}]})";
}

}  // namespace

TEST_CASE("vfx_measure counts the particles and the screen they cover") {
    const auto d = doc_of(burst(40, 36.0, 0.5, 100));
    VfxBudgetOptions o;
    o.viewWidth = 360;
    o.viewHeight = 360;
    const VfxBudget b = vfx_measure(*d, o);
    CHECK(b.emitters == 1);
    CHECK(b.peakParticles == 40);
    CHECK(b.peakAt < 0.1);
    // 40 quads of 36 x 36 on a 360 x 360 view: 40 * 1296 / 129600 = 0.4 screens.
    CHECK(b.peakOverdraw == doctest::Approx(0.4).epsilon(0.05));
    CHECK(b.settledAt == doctest::Approx(0.5).epsilon(0.2));
    CHECK_FALSE(b.truncated);
    REQUIRE(b.perEmitter.size() == 1);
    CHECK(b.perEmitter[0].name == "puff");
    CHECK(b.perEmitter[0].peakParticles == 40);
    CHECK_FALSE(b.perEmitter[0].capped);
    CHECK(b.findings.empty());
    CHECK_FALSE(b.timeline.empty());
    CHECK(b.timeline.size() <= 24);
}

TEST_CASE("vfx_measure is repeatable and follows the seed's document, not the clock") {
    const auto d = doc_of(R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burst":30,"rate":40,"lifetime":0.6,"speed":80,"speedVariance":0.5,"maxParticles":200},"duration":0.5}]})");
    const VfxBudget a = vfx_measure(*d);
    const VfxBudget b = vfx_measure(*d);
    CHECK(a.peakParticles == b.peakParticles);
    CHECK(a.peakAt == b.peakAt);
    CHECK(a.peakOverdraw == b.peakOverdraw);
    CHECK(a.steps == b.steps);
    CHECK(a.timeline.size() == b.timeline.size());
    CHECK(a.peakParticles > 30);
}

TEST_CASE("vfx_measure: too many particles gives a finding with the field and a vfx.edit that fixes it") {
    const auto d = doc_of(burst(800, 4.0, 1.0, 1000), "assets/vfx/big.vfx.json");
    const VfxBudget phone = vfx_measure(*d);
    CHECK(phone.peakParticles == 800);
    REQUIRE(phone.findings.size() == 1);
    const VfxBudgetFinding& f = phone.findings[0];
    CHECK(f.kind == "particles");
    CHECK(f.pointer == "/parts/0/emitter/maxParticles");
    CHECK(f.message.find("800") != std::string::npos);
    CHECK(f.message.find("puff") != std::string::npos);
    CHECK(f.hint.find("300") != std::string::npos);
    REQUIRE(f.fix.is_object());
    CHECK(f.fix["command"] == "vfx.edit");
    CHECK(f.fix["args"]["path"] == "assets/vfx/big.vfx.json");
    CHECK(f.fix["args"]["pointer"] == "/parts/0/emitter/maxParticles");
    CHECK(f.fix["args"]["value"] == 300);
    // The same effect is fine on a desktop.
    VfxBudgetOptions o;
    o.preset = "desktop";
    CHECK(vfx_measure(*d, o).findings.empty());
}

TEST_CASE("vfx_measure: a screen full of big sprites is an overdraw finding that shrinks the particles") {
    const auto d = doc_of(burst(60, 400.0, 0.5, 100));
    VfxBudgetOptions o;
    o.viewWidth = 1280;
    o.viewHeight = 720;
    const VfxBudget b = vfx_measure(*d, o);
    // 60 * 400 * 400 / (1280 * 720) = 10.4 screens.
    CHECK(b.peakOverdraw == doctest::Approx(10.4).epsilon(0.05));
    bool found = false;
    for (const VfxBudgetFinding& f : b.findings)
        if (f.kind == "overdraw") {
            found = true;
            CHECK(f.pointer == "/parts/0/emitter/startSize");
            CHECK(f.fix["args"]["value"].get<double>() < 400.0);
            CHECK(f.fix["args"]["value"].get<double>() > 100.0);
        }
    CHECK(found);
}

TEST_CASE("vfx_measure: an emitter that reaches its cap says so") {
    const auto d = doc_of(burst(500, 4.0, 1.0, 120));
    const VfxBudget b = vfx_measure(*d);
    REQUIRE(b.perEmitter.size() == 1);
    CHECK(b.perEmitter[0].capped);
    CHECK(b.peakParticles == 120);
}

TEST_CASE("vfx_budget_limits: phone is the default") {
    CHECK(vfx_budget_limits("desktop").maxParticles > vfx_budget_limits("phone").maxParticles);
    CHECK(vfx_budget_limits("anything").name == "phone");
}
