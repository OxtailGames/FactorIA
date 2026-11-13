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
    REQUIRE_MESSAGE(d.ok(), (d.ok() ? std::string() : d.error().message));
    return d.value();
}

// One burst of `n` particles of size `size` that live `life` seconds and do not move, so the counts are exact.
std::string burst(int n, double size, double life, int cap) {
    return R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"puff","emitter":{"burst":)" +
           std::to_string(n) + R"(,"rate":0,"lifetime":)" + std::to_string(life) +
           R"(,"lifetimeVariance":0,"startSize":)" + std::to_string(size) + R"(,"endSize":)" + std::to_string(size) +
           R"(,"speed":0,"speedVariance":0,"maxParticles":)" + std::to_string(cap) + R"(}}]})";
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
    const auto d = doc_of(
        R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","emitter":{"burst":30,"rate":40,"lifetime":0.6,"speed":80,"speedVariance":0.5,"maxParticles":200},"duration":0.5}]})");
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

namespace {
// `count` identical bursts, each its own part.
std::string many_bursts(int count, int n, double size, double life, int cap) {
    std::string parts;
    for (int i = 0; i < count; ++i) {
        if (i) parts += ",";
        parts += R"({"type":"emitter","name":"e)" + std::to_string(i) + R"(","emitter":{"burst":)" + std::to_string(n) +
                 R"(,"rate":0,"lifetime":)" + std::to_string(life) + R"(,"lifetimeVariance":0,"startSize":)" +
                 std::to_string(size) + R"(,"endSize":)" + std::to_string(size) +
                 R"(,"speed":0,"speedVariance":0,"maxParticles":)" + std::to_string(cap) + "}}";
    }
    return R"({"format":"factoria.vfx/1","parts":[)" + parts + "]}";
}
}  // namespace

TEST_CASE("vfx_measure: the overdraw is compared as printed (two decimals), not as measured") {
    // One particle of 1176 px in a 1280x720 view covers 1.5005 screens: it prints as 1.50, which is the phone limit, so it is no finding.
    const auto d = doc_of(many_bursts(1, 1, 1176.0, 0.5, 10));
    const VfxBudget b = vfx_measure(*d);
    CHECK(b.peakOverdraw == doctest::Approx(1.5).epsilon(0.0001));
    for (const VfxBudgetFinding& f : b.findings) CHECK(f.kind != "overdraw");
}

TEST_CASE("vfx_measure: a fix that would leave nothing of the effect is not offered") {
    SUBCASE("particles: the other emitters already hold the budget") {
        const auto d = doc_of(
            many_bursts(4, 100, 4.0, 1.0, 200));  // 400 live; the biggest holds 100; 100 over, so its cap would be 0
        const VfxBudget b = vfx_measure(*d);
        REQUIRE(b.peakParticles == 400);
        const VfxBudgetFinding* f = nullptr;
        for (const VfxBudgetFinding& x : b.findings)
            if (x.kind == "particles") f = &x;
        REQUIRE(f);
        CHECK(f->fix.is_null());
        CHECK(f->hint.find("no single edit") != std::string::npos);
    }
    SUBCASE("overdraw: the other emitters already cover the budget") {
        const auto d = doc_of(
            many_bursts(4, 4, 356.0, 0.5, 20));  // 4 emitters of 0.55 screens: 2.2 together, the others alone 1.65
        const VfxBudget b = vfx_measure(*d);
        const VfxBudgetFinding* f = nullptr;
        for (const VfxBudgetFinding& x : b.findings)
            if (x.kind == "overdraw") f = &x;
        REQUIRE(f);
        CHECK(f->fix.is_null());
        CHECK(f->hint.find("no single edit") != std::string::npos);
    }
    SUBCASE("overdraw: when the biggest emitter can do it alone, its size takes what the others cover into account") {
        // big: 8 * 360^2 / 921600 = 1.125 screens; small: 4 * 322^2 / 921600 = 0.45; together 1.575, over the 1.5 of a phone.
        const auto d = doc_of(R"({"format":"factoria.vfx/1","parts":[
            {"type":"emitter","name":"big","emitter":{"burst":8,"rate":0,"lifetime":0.5,"lifetimeVariance":0,"startSize":360,"endSize":360,"speed":0,"maxParticles":20}},
            {"type":"emitter","name":"small","emitter":{"burst":4,"rate":0,"lifetime":0.5,"lifetimeVariance":0,"startSize":322,"endSize":322,"speed":0,"maxParticles":20}}]})");
        const VfxBudget b = vfx_measure(*d);
        const VfxBudgetFinding* f = nullptr;
        for (const VfxBudgetFinding& x : b.findings)
            if (x.kind == "overdraw") f = &x;
        REQUIRE(b.perEmitter.size() == 2);  // a one-step effect (duration 0) still tells its emitters apart
        REQUIRE(f);
        CHECK(f->pointer == "/parts/0/emitter/startSize");
        REQUIRE(f->fix.is_object());
        // room for big = 1.5 - 0.45 = 1.05: 360 * sqrt(1.05 / 1.125) = 347.8 (shrinking everything by the same share would give 351.4)
        const double v = f->fix["args"]["value"].get<double>();
        CHECK(v > 345.0);
        CHECK(v < 349.0);
    }
}

TEST_CASE("vfx_measure stops at its particle update limit and says so") {
    // The limit is an option so that the test stays light (the default is 20 million): four emitters of 1000 particles that live 25 s are 4000
    // updates per step, so 200 000 is reached after about 50 of the 1500 steps, the same proportion as 40 000 per step against 20 million.
    CHECK(VfxBudgetOptions{}.maxParticleUpdates == 20'000'000);
    const auto d = doc_of(many_bursts(4, 1000, 2.0, 25.0, 1000));
    VfxBudgetOptions options;
    options.maxParticleUpdates = 200'000;
    const VfxBudget b = vfx_measure(*d, options);
    CHECK(b.truncated);
    CHECK(b.steps < 600);
    bool noted = false;
    for (const std::string& n : b.notes) noted = noted || n.find("particle updates") != std::string::npos;
    CHECK(noted);
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

TEST_CASE("vfx_measure: a 3D emitter counts its particles and says its overdraw is not measured") {
    const auto d = doc_of(
        R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"sparks","emitter":{"is3D":true,"burst":40,"lifetime":0.5,"startSize":500,"endSize":500}}]})");
    const VfxBudget b = vfx_measure(*d);
    CHECK(b.peakParticles == 40);
    CHECK(b.peakOverdraw == 0.0);
    REQUIRE(b.notes.size() == 1);
    CHECK(b.notes[0].find("sparks") != std::string::npos);
    CHECK(b.notes[0].find("3D") != std::string::npos);
    CHECK(b.notes[0].find("not measured") != std::string::npos);
    CHECK(b.findings.empty());
}

TEST_CASE("vfx_measure: with a camera a 3D emitter's quads are projected through it and counted as overdraw") {
    // One still particle of 5 units, 5 m in front of a 90 degree camera: the view is 10 units tall and 10 * 1280/720 wide, so the quad
    // covers 25 / (10 * 17.78) = 0.14 of the screen.
    const auto d = doc_of(
        R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"orb","emitter":{"is3D":true,"burst":1,"rate":0,"lifetime":0.5,
        "lifetimeVariance":0,"startSize":5,"endSize":5,"speed":0,"speedVariance":0,"maxParticles":4}}]})");
    VfxBudgetOptions o;
    o.camera = VfxBudgetCamera{};
    o.camera->fovDegrees = 90.0;
    const VfxBudget b = vfx_measure(*d, o);
    CHECK(b.camera3d);
    CHECK(b.peakParticles == 1);
    CHECK(b.peakOverdraw == doctest::Approx(0.14).epsilon(0.001));
    REQUIRE(b.notes.size() == 1);
    CHECK(b.notes[0].find("main camera") != std::string::npos);
    CHECK(b.notes[0].find("5.0 m") != std::string::npos);
    CHECK(b.notes[0].find("perspective") != std::string::npos);
    // Twice as far, a quarter of the area; a narrower lens covers more.
    o.cameraDistance = 10.0;
    CHECK(vfx_measure(*d, o).peakOverdraw == doctest::Approx(0.04).epsilon(0.03));
    o.cameraDistance = kVfxDefaultCameraDistance;
    o.camera->fovDegrees = 45.0;
    CHECK(vfx_measure(*d, o).peakOverdraw > b.peakOverdraw);
    // Repeatable, like the 2D numbers.
    CHECK(vfx_measure(*d, o).peakOverdraw == vfx_measure(*d, o).peakOverdraw);
    // An orthographic camera 4 units tall: the quad covers 25 / (4 * 7.11) screens, which is more than the whole view.
    VfxBudgetOptions ortho;
    ortho.camera = VfxBudgetCamera{};
    ortho.camera->perspective = false;
    ortho.camera->orthoHalfHeight = 2.0;
    const VfxBudget ob = vfx_measure(*d, ortho);
    CHECK(ob.camera3d);
    CHECK(ob.peakOverdraw == doctest::Approx(25.0 / (4.0 * 4.0 * 1280.0 / 720.0)).epsilon(0.01));
    CHECK(ob.notes[0].find("orthographic") != std::string::npos);
    // Behind the camera (or not past its near plane) nothing is drawn: no overdraw.
    VfxBudgetOptions behind = o;
    behind.cameraDistance = -3.0;
    CHECK(vfx_measure(*d, behind).peakOverdraw == 0.0);
    // Big, close quads are a finding like any other overdraw.
    const auto big = doc_of(
        R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"fog","emitter":{"is3D":true,"burst":6,"rate":0,"lifetime":0.5,
        "lifetimeVariance":0,"startSize":8,"endSize":8,"speed":0,"speedVariance":0,"maxParticles":8}}]})");
    const VfxBudget bb = vfx_measure(*big, o);
    REQUIRE(bb.findings.size() == 1);
    CHECK(bb.findings[0].kind == "overdraw");
    CHECK(vfx_measure(*big).findings.empty());  // without the camera there is nothing to compare
}

TEST_CASE("vfx_measure: without a camera the note says there is nothing to project through") {
    const auto d = doc_of(
        R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"sparks","emitter":{"is3D":true,"burst":3,"lifetime":0.5}}]})");
    const VfxBudget b = vfx_measure(*d);
    CHECK_FALSE(b.camera3d);
    REQUIRE(b.notes.size() == 1);
    CHECK(b.notes[0].find("no camera") != std::string::npos);
    CHECK(b.notes[0].find("primary Camera") != std::string::npos);
}
