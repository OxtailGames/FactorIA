// The Particle panel's logic with no window: the key edits of the curve and gradient editors (particle_curve.h), the model whose every edit is a
// vfx.edit command and one undo step (particle_model.h) and the preview that plays the document by the engine's own timeline (particle_preview.h).
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/asset_import.h"
#include "particle_curve.h"
#include "particle_model.h"
#include "particle_preview.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kFx = "assets/vfx/t.vfx.json";

struct FxProject {
    stdfs::path dir;
    CommandRegistry registry;
    std::unique_ptr<ParticleModel> model;
    FxProject() {
        dir = fs::make_temp_dir("fa_particle_panel");
        register_asset_commands(registry, dir.string());
        model = std::make_unique<ParticleModel>(dir.string(), [this](const std::string& name, const Json& args) { return registry.call(name, args); });
    }
    ~FxProject() {
        model.reset();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void open() {
        const ParticleEditOutcome out = model->create(kFx);
        REQUIRE_MESSAGE(out.ok, out.error);
        REQUIRE_MESSAGE(model->is_open(), model->error());
        REQUIRE(model->valid());
    }
    Json file() const {
        std::ifstream in(dir / kFx, std::ios::binary);
        std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        return Json::parse(text);
    }
};

}  // namespace

TEST_CASE("particle curve helpers: a key goes where it was clicked, stays between its neighbours and the list stays sorted") {
    Curve c;
    CHECK(curve_add_key(c, 0.0f, 1.0f) == 0);
    CHECK(curve_add_key(c, 1.0f, 0.0f) == 1);
    CHECK(curve_add_key(c, 0.5f, 0.8f) == 1);
    REQUIRE(c.keys.size() == 3);
    CHECK(c.keys[1].t == doctest::Approx(0.5f));
    // dragged past its neighbour: it stops short of it, and keeps its index
    CHECK(curve_move_key(c, 1, 2.0f, 0.2f));
    CHECK(c.keys[1].t <= c.keys[2].t);
    CHECK(c.keys[1].value == doctest::Approx(0.2f));
    CHECK(curve_move_key(c, 1, -3.0f, 0.2f));
    CHECK(c.keys[1].t >= c.keys[0].t);
    CHECK_FALSE(curve_move_key(c, 7, 0.5f, 0.5f));
    CHECK(curve_remove_key(c, 1));
    CHECK(c.keys.size() == 2);
    CHECK_FALSE(curve_remove_key(c, 5));
    // full: no more keys
    Curve full;
    for (int i = 0; i < kMaxCurveKeys; ++i) CHECK(curve_add_key(full, float(i) / float(kMaxCurveKeys), 0.5f) >= 0);
    CHECK(curve_add_key(full, 0.999f, 0.5f) == -1);
    float lo, hi;
    Curve wide;
    curve_add_key(wide, 0.0f, -1.0f);
    curve_add_key(wide, 1.0f, 3.0f);
    curve_value_range(wide, lo, hi);
    CHECK(lo <= -1.0f);
    CHECK(hi >= 3.0f);
    curve_value_range(Curve{}, lo, hi);
    CHECK(lo == doctest::Approx(0.0f));
    CHECK(hi == doctest::Approx(1.0f));
}

TEST_CASE("particle gradient helpers: a new key has the colour the gradient already had there") {
    Gradient g;
    CHECK(gradient_add_key(g, 0.0f) == 0);
    CHECK(gradient_set_key_color(g, 0, Color{1, 0, 0, 1}));
    CHECK(gradient_add_key(g, 1.0f) == 1);
    CHECK(gradient_set_key_color(g, 1, Color{0, 0, 1, 0}));
    const Color before = g.eval(0.5f);
    const int mid = gradient_add_key(g, 0.5f);
    REQUIRE(mid == 1);
    CHECK(g.keys[1].color.r == doctest::Approx(before.r).epsilon(0.01));
    CHECK(g.keys[1].color.b == doctest::Approx(before.b).epsilon(0.01));
    CHECK(gradient_move_key(g, 1, 0.3f));
    CHECK(g.keys[1].t == doctest::Approx(0.3f));
    CHECK(gradient_remove_key(g, 1));
    CHECK(g.keys.size() == 2);
}

TEST_CASE("particle model: edits are vfx.edit commands, each is one step, and undo and redo put the file back") {
    FxProject p;
    p.open();
    const Json first = p.file();
    REQUIRE(first["parts"].size() == 1);
    const std::size_t steps0 = p.model->step_count();

    ParticleEditOutcome out = p.model->set_field("/parts/0/emitter/burst", 41, "Edit burst");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.step > 0);
    CHECK(p.file()["parts"][0]["emitter"]["burst"] == 41);
    CHECK(p.model->doc()->parts.size() == 1);
    const int burstStep = out.step;

    out = p.model->add_item("/parts", ParticleModel::starter_part("light"), -1, "Add light");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(p.file()["parts"].size() == 2);
    CHECK(p.model->parts().size() == 2);
    CHECK(p.model->parts()[1].type == "light");
    const int addStep = out.step;

    // the sound and the command starters are valid parts
    CHECK(ParticleModel::starter_part("sound", "assets/audio/a.wav")["clip"] == "assets/audio/a.wav");
    CHECK(ParticleModel::starter_part("command")["type"] == "command");

    CHECK(p.model->apply_step(addStep, false));
    CHECK(p.file()["parts"].size() == 1);
    CHECK(p.model->parts().size() == 1);
    CHECK(p.model->apply_step(addStep, true));
    CHECK(p.file()["parts"].size() == 2);
    CHECK(p.model->apply_step(addStep, false));
    CHECK(p.model->apply_step(burstStep, false));
    CHECK(p.file() == first);
    CHECK(p.model->step_count() > steps0);

    // steps nobody points to are dropped
    p.model->retain_steps({burstStep});
    CHECK(p.model->step(addStep) == nullptr);
    CHECK(p.model->step(burstStep) != nullptr);
}

TEST_CASE("particle model: a bad edit is refused with the reason and the file stays as it was") {
    FxProject p;
    p.open();
    const Json before = p.file();
    const ParticleEditOutcome out = p.model->set_field("/parts/0/at", "later", "Edit at");
    CHECK_FALSE(out.ok);
    CHECK_FALSE(out.error.empty());
    CHECK(out.step == 0);
    CHECK(p.file() == before);
    CHECK(p.model->valid());
}

TEST_CASE("particle model: a drag is one edit, written when the mouse is released") {
    FxProject p;
    p.open();
    const Json before = p.file();
    const std::size_t steps0 = p.model->step_count();
    for (int v : {10, 20, 30}) p.model->preview_field("/parts/0/emitter/burst", v);
    CHECK(p.model->field_previewing());
    CHECK(p.model->shown_json()["parts"][0]["emitter"]["burst"] == 30);
    CHECK(p.file() == before);   // nothing written yet
    const ParticleEditOutcome out = p.model->commit_field("Edit burst");
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK_FALSE(p.model->field_previewing());
    CHECK(p.file()["parts"][0]["emitter"]["burst"] == 30);
    CHECK(p.model->step_count() == steps0 + 1);

    p.model->preview_field("/parts/0/emitter/burst", 99);
    p.model->cancel_field_preview();
    CHECK(p.model->shown_json()["parts"][0]["emitter"]["burst"] == 30);
}

TEST_CASE("particle model: a file changed behind the panel's back is read again") {
    FxProject p;
    p.open();
    Json j = p.file();
    j["doc"] = "changed outside";
    // the stamp is the time and size: make sure the size differs too
    std::ofstream(p.dir / kFx, std::ios::binary | std::ios::trunc) << j.dump(2) << "\n\n";
    CHECK(p.model->poll_external());
    CHECK(p.model->doc()->description == "changed outside");
    CHECK_FALSE(p.model->poll_external());
}

TEST_CASE("particle preview: the same seed and the same time show the same particles; a seek rebuilds from the start") {
    FxProject p;
    p.open();
    ParticlePreview a, b;
    a.set_seed(7);
    b.set_seed(7);
    a.set_document(p.model->doc());
    b.set_document(p.model->doc());
    a.seek(0.0);
    b.seek(0.0);
    for (int i = 0; i < 30; ++i) a.advance(1.0 / 60.0);   // played
    b.seek(a.time());                                      // scrubbed to the same moment
    REQUIRE(a.live_particles() > 0);
    REQUIRE(a.dots().size() == b.dots().size());
    for (std::size_t i = 0; i < a.dots().size(); ++i) {
        CHECK(a.dots()[i].x == doctest::Approx(b.dots()[i].x));
        CHECK(a.dots()[i].y == doctest::Approx(b.dots()[i].y));
        CHECK(a.dots()[i].size == doctest::Approx(b.dots()[i].size));
    }
    // another seed: other positions
    ParticlePreview c;
    c.set_seed(8);
    c.set_document(p.model->doc());
    c.seek(a.time());
    bool differs = c.dots().size() != a.dots().size();
    for (std::size_t i = 0; !differs && i < std::min(a.dots().size(), c.dots().size()); ++i)
        differs = std::abs(a.dots()[i].x - c.dots()[i].x) > 1e-4f || std::abs(a.dots()[i].y - c.dots()[i].y) > 1e-4f;
    CHECK(differs);
    // the end of the timeline has no particles left; going back brings them back
    a.seek(a.timeline_length());
    CHECK(a.live_particles() == 0);
    a.seek(0.2);
    CHECK(a.live_particles() > 0);
    CHECK(a.timeline_length() >= 0.25);
}

TEST_CASE("particle preview: lights glow while they last and sounds and commands are listed, not run") {
    FxProject p;
    p.open();
    REQUIRE(p.model->add_item("/parts", ParticleModel::starter_part("light"), -1, "Add light").ok);
    REQUIRE(p.model->add_item("/parts", ParticleModel::starter_part("command"), -1, "Add command").ok);
    ParticlePreview v;
    v.set_document(p.model->doc());
    v.seek(0.05);
    CHECK(v.lights().size() == 1);
    CHECK(v.lights()[0].intensity > 0.0f);
    v.seek(v.timeline_length());
    CHECK(v.lights().empty());
    v.seek(0.0);
    for (int i = 0; i < 90; ++i) v.advance(1.0 / 60.0);
    CHECK(v.fired().size() == 1);   // the command; it was not run
}
