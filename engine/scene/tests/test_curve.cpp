#include <doctest.h>

#include "fa/scene/curve.h"

using namespace fa;

TEST_CASE("curve: linear, smooth and step evaluation") {
    auto c = Curve::parse(Json::parse("[[0, 1], [0.5, 3], [1, 0]]"), "t");
    REQUIRE(c);
    CHECK(c->eval(0.0f) == doctest::Approx(1.0f));
    CHECK(c->eval(0.25f) == doctest::Approx(2.0f));
    CHECK(c->eval(0.5f) == doctest::Approx(3.0f));
    CHECK(c->eval(0.75f) == doctest::Approx(1.5f));
    CHECK(c->eval(1.0f) == doctest::Approx(0.0f));
    // Outside the keys the first and the last value hold.
    CHECK(c->eval(-4.0f) == doctest::Approx(1.0f));
    CHECK(c->eval(9.0f) == doctest::Approx(0.0f));

    auto s = Curve::parse(Json::parse(R"({"keys": [[0, 0], [1, 10]], "interp": "smooth"})"), "t");
    REQUIRE(s);
    CHECK(s->eval(0.5f) == doctest::Approx(5.0f));
    CHECK(s->eval(0.25f) < 2.5f);  // eases in
    CHECK(s->eval(0.75f) > 7.5f);  // eases out

    auto st = Curve::parse(Json::parse(R"({"keys": [[0, 1], [0.5, 2], [1, 3]], "interp": "step"})"), "t");
    REQUIRE(st);
    CHECK(st->eval(0.49f) == doctest::Approx(1.0f));
    CHECK(st->eval(0.5f) == doctest::Approx(2.0f));
    CHECK(st->eval(0.99f) == doctest::Approx(2.0f));
}

TEST_CASE("curve: a number is a constant, [] is empty, keys are sorted") {
    auto k = Curve::parse(Json(2.5), "t");
    REQUIRE(k);
    CHECK(k->eval(0.7f) == doctest::Approx(2.5f));
    auto e = Curve::parse(Json::array(), "t");
    REQUIRE(e);
    CHECK(e->empty());
    CHECK(e->eval(0.5f) == 0.0f);
    CHECK(e->eval_or(0.5f, 7.0f) == doctest::Approx(7.0f));
    auto u = Curve::parse(Json::parse("[[1, 0], [0, 4]]"), "t");
    REQUIRE(u);
    CHECK(u->keys.front().t == 0.0f);
    CHECK(u->eval(0.5f) == doctest::Approx(2.0f));
    CHECK(u->eval(std::nanf("")) == doctest::Approx(4.0f));  // a NaN position does not poison the result
}

TEST_CASE("curve: round trip through JSON") {
    auto s = Curve::parse(Json::parse(R"({"keys": [[0, 0], [1, 10]], "interp": "smooth"})"), "t");
    REQUIRE(s);
    auto again = Curve::parse(s->to_json(), "t");
    REQUIRE(again);
    CHECK(*again == *s);
    auto l = Curve::parse(Json::parse("[[0, 1], [1, 2]]"), "t");
    REQUIRE(l);
    CHECK(l->to_json() == Json::parse("[[0.0, 1.0], [1.0, 2.0]]"));
}

TEST_CASE("curve: errors name the field and show the form") {
    auto bad = Curve::parse(Json::parse("[[0, 1], [0.5]]"), "ParticleEmitter.sizeCurve");
    REQUIRE_FALSE(bad);
    CHECK(bad.error().message.find("ParticleEmitter.sizeCurve") != std::string::npos);
    CHECK(bad.error().message.find("key 1") != std::string::npos);
    CHECK(bad.error().hint.find("[[0, 1]") != std::string::npos);

    auto unk = Curve::parse(Json::parse(R"({"key": [[0, 1]]})"), "t");
    REQUIRE_FALSE(unk);
    CHECK(unk.error().hint.find("keys") != std::string::npos);

    auto interp = Curve::parse(Json::parse(R"({"keys": [[0, 1]], "interp": "cubic"})"), "t");
    REQUIRE_FALSE(interp);
    CHECK(interp.error().message.find("cubic") != std::string::npos);

    Json many = Json::array();
    for (int i = 0; i <= kMaxCurveKeys; ++i) many.push_back(Json::array({Json(i / 100.0), Json(1.0)}));
    auto tooMany = Curve::parse(many, "t");
    REQUIRE_FALSE(tooMany);
    CHECK(tooMany.error().message.find("at most 16") != std::string::npos);

    CHECK_FALSE(Curve::parse(Json("fast"), "t"));
}

TEST_CASE("gradient: keys blend in colour and alpha") {
    auto g = Gradient::parse(Json::parse(R"([[0, "#ff0000"], [0.5, [0, 1, 0, 1]], [1, "#0000ff00"]])"), "t");
    REQUIRE(g);
    CHECK(g->keys.size() == 3);
    Color a = g->eval(0.0f);
    CHECK(a.r == doctest::Approx(1.0f));
    CHECK(a.g == doctest::Approx(0.0f));
    Color m = g->eval(0.25f);
    CHECK(m.r == doctest::Approx(0.5f));
    CHECK(m.g == doctest::Approx(0.5f));
    Color z = g->eval(0.5f);
    CHECK(z.g == doctest::Approx(1.0f));
    Color e = g->eval(1.0f);
    CHECK(e.b == doctest::Approx(1.0f));
    CHECK(e.a == doctest::Approx(0.0f));
    Color h = g->eval(0.75f);
    CHECK(h.a == doctest::Approx(0.5f));
    CHECK(g->eval(5.0f).a == doctest::Approx(0.0f));

    Gradient empty;
    CHECK(empty.eval(0.5f).a == 0.0f);
    Color fb{0.1f, 0.2f, 0.3f, 0.4f};
    CHECK(empty.eval_or(0.5f, fb) == fb);
}

TEST_CASE("gradient: errors point at the key") {
    auto r = Gradient::parse(Json::parse(R"([[0, "#ff0000"], [1, "not-a-colour"]])"), "ParticleEmitter.colorGradient");
    REQUIRE_FALSE(r);
    CHECK(r.error().message.find("colorGradient") != std::string::npos);
    CHECK(r.error().message.find("key 1") != std::string::npos);
    CHECK_FALSE(Gradient::parse(Json::parse("{}"), "t"));
    CHECK_FALSE(Gradient::parse(Json::parse("[[0]]"), "t"));
    auto rt = Gradient::parse(Json::parse(R"([[0, "#ff0000"], [1, "#00ff00"]])"), "t");
    REQUIRE(rt);
    auto again = Gradient::parse(rt->to_json(), "t");
    REQUIRE(again);
    CHECK(*again == *rt);
}
