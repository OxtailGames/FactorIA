// TypedArray (core/typed_array.h) and the reflected array fields (FieldKind::ArrayI32 / ArrayF32 / ArrayU8).
#include <doctest.h>

#include <limits>
#include <utility>

#include "fa/core/reflect.h"
#include "fa/core/typed_array.h"

using namespace fa;

namespace {
struct ArrayProbe {
    ArrayI32 ids;
    ArrayF32 weights;
    ArrayU8 mask;
    ArrayI32 small;  // range(0, 3)
    int other = 1;
};

// A test-only component: registered on the process-wide registry under a name no engine type uses.
const TypeInfo& array_probe_type() {
    static const TypeInfo* t = [] {
        auto& reg = TypeRegistry::global();
        if (!reg.of<ArrayProbe>()) {
            reg.add<ArrayProbe>("TestArrayProbe", "A test component with array fields.", "Test")
                .field("ids", &ArrayProbe::ids, "Integer ids.")
                .field("weights", &ArrayProbe::weights, "Weights.")
                .field("mask", &ArrayProbe::mask, "Bytes 0..255.")
                .field("small", &ArrayProbe::small, "Values 0..3.")
                .range(0, 3)
                .field("other", &ArrayProbe::other, "Another field.");
        }
        return reg.of<ArrayProbe>();
    }();
    return *t;
}

std::string error_text(const Result<void>& r) { return r.ok() ? std::string() : r.error().message + " " + r.error().hint; }
}  // namespace

namespace {
// One consumer of an array: what it last read. take() says what was written since (and moves it forward).
struct Reader {
    std::uint64_t seen = 0;
    bool known = true;  // false: the array could not say (look at everything)
    std::size_t begin = 0, end = 0;
    template <class A>
    void take(const A& a) {
        known = a.dirty_since(seen, begin, end);
        seen = a.version();
    }
    template <class A>
    void sync_to(const A& a) {
        seen = a.version();
    }
};
}  // namespace

TEST_CASE("typed array: reads never bump the version, writes do") {
    ArrayI32 a{1, 2, 3, 4, 5, 6, 7, 8};
    Reader r;
    r.sync_to(a);
    const std::uint64_t v0 = a.version();
    const ArrayI32& c = a;
    CHECK(c[2] == 3);
    CHECK(c.data()[3] == 4);
    CHECK(std::as_const(a).cdata() == c.data());
    CHECK(c.span().size() == 8);
    int sum = 0;
    for (int x : c) sum += x;
    CHECK(sum == 36);
    CHECK(a.version() == v0);
    r.take(a);
    CHECK(r.known);
    CHECK(r.end == 0);

    a[5] = 60;  // a mutable operator[] counts as a write of that index
    CHECK(a.version() == v0 + 1);
    r.take(a);
    CHECK(r.known);
    CHECK(r.begin == 5);
    CHECK(r.end == 6);
    a[1] = 20;
    a[5] = 61;
    r.take(a);  // the range covers every write since the last look
    CHECK(r.begin == 1);
    CHECK(r.end == 6);
    CHECK(c[5] == 61);

    r.take(a);  // asking again changes nothing
    CHECK(r.known);
    CHECK(r.end == 0);
    CHECK(a.version() == v0 + 3);

    a.data();  // a mutable pointer counts as a write of everything
    r.take(a);
    CHECK(r.begin == 0);
    CHECK(r.end == 8);
}

TEST_CASE("typed array: NaN is always a change, -0.0 is not, and a mutable data() of an empty array is no write") {
    ArrayF32 a{1.0f, 2.0f};
    const std::uint64_t v0 = a.version();
    const float nan[] = {1.0f, std::numeric_limits<float>::quiet_NaN()};
    a.assign(nan, 2);
    CHECK(a.version() == v0 + 1);
    a.assign(nan, 2);  // NaN != NaN: counts again
    CHECK(a.version() == v0 + 2);
    ArrayF32 z{0.0f};
    const float negZero[] = {-0.0f};
    z.assign(negZero, 1);  // -0.0 == +0.0: nothing changes
    CHECK(z.version() == 0);
    ArrayF32 empty;
    static_cast<void>(empty.data());
    CHECK(empty.version() == 0);
}

TEST_CASE("typed array: set, fill and assign only change what differs") {
    ArrayU8 a(10, 7);
    Reader r;
    r.sync_to(a);
    const std::uint64_t v0 = a.version();
    CHECK(a.set(3, 7));  // same value: no change
    CHECK(a.version() == v0);
    r.take(a);
    CHECK(r.end == 0);
    CHECK(a.set(3, 8));
    CHECK(a.version() == v0 + 1);
    r.take(a);
    CHECK(r.begin == 3);
    CHECK(r.end == 4);
    CHECK_FALSE(a.set(10, 1));  // out of range: ignored
    CHECK(a.version() == v0 + 1);

    a.fill(7);  // only index 3 differs
    r.take(a);
    CHECK(r.begin == 3);
    CHECK(r.end == 4);
    const std::uint64_t v1 = a.version();
    a.fill(7);  // nothing differs now
    CHECK(a.version() == v1);
    a.fill(9, 2, 5);
    r.take(a);
    CHECK(r.begin == 2);
    CHECK(r.end == 5);
    CHECK(a[1] == 7);
    CHECK(a[4] == 9);
    CHECK(a[5] == 7);

    const std::uint8_t same[10] = {7, 7, 9, 9, 9, 7, 7, 7, 7, 7};
    const std::uint64_t v2 = a.version();
    a.assign(same, 10);  // identical contents
    CHECK(a.version() == v2);
    const std::uint8_t other[10] = {7, 1, 9, 9, 9, 7, 7, 2, 7, 7};
    a.assign(other, 10);  // the span between the first and last difference
    r.take(a);
    CHECK(r.begin == 1);
    CHECK(r.end == 8);
}

TEST_CASE("typed array: a change of size covers everything, copies keep the contents") {
    ArrayI32 a{1, 2, 3};
    Reader r;
    r.sync_to(a);
    a.resize(5, 9);
    CHECK(a.size() == 5);
    CHECK(a[4] == 9);
    r.take(a);
    CHECK(r.begin == 0);
    CHECK(r.end == 5);
    a.resize(2);  // a shrink: the old tail is part of the change
    r.take(a);
    CHECK(r.begin == 0);
    CHECK(r.end == 5);
    a.push_back(4);
    CHECK(a.size() == 3);
    r.take(a);
    CHECK(r.end == 3);
    const std::uint64_t v = a.version();
    a.resize(3);  // same size: nothing
    CHECK(a.version() == v);
    a.clear();
    CHECK(a.empty());
    CHECK(a.version() == v + 1);

    ArrayI32 src{4, 5, 6};
    ArrayI32 copy = src;  // copy construction: same contents, a fresh array (new id, version 0)
    CHECK(copy == src);
    CHECK(copy.version() == 0);
    CHECK(copy.id() != src.id());
    ArrayI32 dst{4, 5, 0};
    Reader rd;
    rd.sync_to(dst);
    const std::uint64_t vd = dst.version();
    dst = src;  // copy assignment: only index 2 differs
    CHECK(dst == src);
    rd.take(dst);
    CHECK(rd.begin == 2);
    CHECK(rd.end == 3);
    CHECK(dst.version() == vd + 1);
    dst = src;  // identical: nothing
    CHECK(dst.version() == vd + 1);

    ArrayI32 moved = std::move(dst);  // a move keeps the version
    CHECK(moved == src);
    CHECK(moved.version() == vd + 1);
    rd.take(moved);
    CHECK(rd.known);
    CHECK(rd.end == 0);
    ArrayI32 target{1};
    target = std::move(moved);
    CHECK(target == src);
}

TEST_CASE("typed array: independent consumers each see every write, in any interleaving") {
    ArrayF32 a(100, 0.0f);
    Reader x, y;
    x.sync_to(a);
    y.sync_to(a);
    a.set(10, 1.0f);
    x.take(a);  // x reads between the two writes; y does not
    CHECK(x.known);
    CHECK(x.begin == 10);
    CHECK(x.end == 11);
    a.set(60, 2.0f);
    y.take(a);  // y sees both
    CHECK(y.known);
    CHECK(y.begin == 10);
    CHECK(y.end == 61);
    x.take(a);  // x sees only the second: reading never took anything from y
    CHECK(x.begin == 60);
    CHECK(x.end == 61);
    y.take(a);
    CHECK(y.end == 0);
    a.set(5, 3.0f);
    a.set(95, 3.0f);
    y.take(a);
    x.take(a);
    CHECK((y.begin == 5 && y.end == 96));
    CHECK((x.begin == 5 && x.end == 96));
    // A reader that looks at the array twice in a row between writes gets nothing the second time, and the others still
    // get their ranges.
    Reader z;
    z.sync_to(a);
    a.set(1, 9.0f);
    z.take(a);
    z.take(a);
    CHECK(z.end == 0);
    x.take(a);
    CHECK(x.begin == 1);
    CHECK(x.end == 2);
}

TEST_CASE("typed array: more writes than the history holds say 'look at everything'") {
    ArrayI32 a(64, 0);
    Reader r;
    r.sync_to(a);
    for (std::size_t i = 0; i < ArrayI32::kHistory; ++i) a.set(i, 1);  // exactly kHistory writes: still known
    r.take(a);
    CHECK(r.known);
    CHECK(r.begin == 0);
    CHECK(r.end == ArrayI32::kHistory);
    for (std::size_t i = 0; i < ArrayI32::kHistory + 1; ++i) a.set(20 + i, 2);  // one more than the history holds
    r.take(a);
    CHECK_FALSE(r.known);
    r.take(a);  // the next look starts from the new version
    CHECK(r.known);
    CHECK(r.end == 0);
    // A version from the future (another array's) is not trusted either.
    std::size_t b = 0, e = 0;
    CHECK_FALSE(a.dirty_since(a.version() + 5, b, e));
    // Wrapping the history many times keeps the ranges right.
    for (int round = 0; round < 40; ++round) {
        a.set(std::size_t(round), 100 + round);
        r.take(a);
        CHECK(r.known);
        CHECK(r.begin == std::size_t(round));
        CHECK(r.end == std::size_t(round) + 1);
    }
}

TEST_CASE("typed array: id() tells objects apart where version() cannot (copies start again at version 0)") {
    ArrayI32 a{1, 2, 3};
    ArrayI32 b{1, 2, 3};
    CHECK(a.id() != 0);
    CHECK(a.id() != b.id());  // equal contents and equal version 0, different objects
    CHECK(a.version() == b.version());

    const std::uint64_t id = a.id();
    a[0] = 5;
    a.set(1, 9);
    CHECK(a.id() == id);  // writes keep the identity

    ArrayI32 copy = a;
    CHECK(copy.id() != id);  // a copy is a new object, at version 0
    CHECK(copy.version() == 0);

    ArrayI32 dst{0};
    const std::uint64_t dstId = dst.id();
    dst = a;  // assignment keeps the destination's identity
    CHECK(dst.id() == dstId);
    dst = std::move(copy);
    CHECK(dst.id() == dstId);

    ArrayI32 moved = std::move(a);  // a move construction keeps it (a pool relocating a component)
    CHECK(moved.id() == id);
    CHECK(a.id() != id);  // NOLINT: the moved-from array is another object now
}

TEST_CASE("reflect arrays: JSON round trip, kinds and defaults") {
    const TypeInfo& t = array_probe_type();
    CHECK(std::string(field_kind_name(FieldKind::ArrayI32)) == "arrayI32");
    CHECK(t.field("ids")->kind == FieldKind::ArrayI32);
    CHECK(t.field("weights")->kind == FieldKind::ArrayF32);
    CHECK(t.field("mask")->kind == FieldKind::ArrayU8);

    ArrayProbe p;
    CHECK(object_to_json(t, &p)["ids"] == Json::array());
    auto r = object_patch_from_json(
        t, &p, Json::parse(R"({"ids": [1, -2, 2147483647], "weights": [0.5, 1, -3.25], "mask": [0, 255, 7], "small": [0, 3]})"));
    REQUIRE_MESSAGE(r.ok(), error_text(r));
    CHECK(p.ids.size() == 3);
    CHECK(p.ids[1] == -2);
    CHECK(p.ids[2] == 2147483647);
    CHECK(p.weights[0] == 0.5f);
    CHECK(p.weights[2] == -3.25f);
    CHECK(p.mask[1] == 255);
    CHECK(p.small[1] == 3);
    const Json out = object_to_json(t, &p);
    CHECK(out["ids"] == Json::parse("[1, -2, 2147483647]"));
    CHECK(out["weights"] == Json::parse("[0.5, 1, -3.25]"));
    CHECK(out["mask"] == Json::parse("[0, 255, 7]"));
    // The same JSON loads into a fresh object and comes out equal.
    ArrayProbe q;
    REQUIRE(object_patch_from_json(t, &q, out).ok());
    CHECK(object_to_json(t, &q) == out);
    // includeDefaults=false leaves out an empty array and keeps a filled one.
    const Json sparse = object_to_json(t, &p, false);
    CHECK(sparse.contains("ids"));
    ArrayProbe empty;
    CHECK_FALSE(object_to_json(t, &empty, false).contains("ids"));
    // A whole number written as 3.0 is accepted by the integer kinds.
    CHECK(field_from_json(*t.field("ids"), &q, Json::parse("[3.0, 4]")).ok());
    CHECK(q.ids[0] == 3);
}

TEST_CASE("reflect arrays: errors name the field, the element and the way out") {
    const TypeInfo& t = array_probe_type();
    ArrayProbe p;
    REQUIRE(field_from_json(*t.field("ids"), &p, Json::parse("[1, 2, 3]")).ok());

    auto notArray = field_from_json(*t.field("ids"), &p, Json(5));
    REQUIRE_FALSE(notArray.ok());
    CHECK(notArray.error().message.find("Field 'ids'") != std::string::npos);
    CHECK(notArray.error().message.find("expected an array") != std::string::npos);
    CHECK(notArray.error().hint.find("array of integers") != std::string::npos);

    // null is no array: refused on an integer and a float array, the field keeps its contents.
    for (const char* name : {"ids", "weights", "mask"}) {
        auto isNull = field_from_json(*t.field(name), &p, Json(nullptr));
        REQUIRE_FALSE(isNull.ok());
        CHECK(isNull.error().message.find(std::string("Field '") + name + "'") != std::string::npos);
        CHECK(isNull.error().message.find("expected an array of numbers, got null") != std::string::npos);
        CHECK_FALSE(isNull.error().hint.empty());
    }
    CHECK(p.ids.size() == 3);

    auto fraction = field_from_json(*t.field("ids"), &p, Json::parse("[1, 2.5]"));
    REQUIRE_FALSE(fraction.ok());
    CHECK(error_text(fraction).find("element 1 is 2.5, expected an integer") != std::string::npos);

    auto text = field_from_json(*t.field("weights"), &p, Json::parse("[1, \"x\"]"));
    REQUIRE_FALSE(text.ok());
    CHECK(error_text(text).find("element 1") != std::string::npos);
    CHECK(error_text(text).find("expected a number") != std::string::npos);

    auto big = field_from_json(*t.field("mask"), &p, Json::parse("[1, 2, 256]"));
    REQUIRE_FALSE(big.ok());
    CHECK(error_text(big).find("element 2 is 256") != std::string::npos);
    CHECK(error_text(big).find("0 to 255") != std::string::npos);
    CHECK(error_text(field_from_json(*t.field("mask"), &p, Json::parse("[-1]"))).find("element 0 is -1") !=
          std::string::npos);
    CHECK_FALSE(field_from_json(*t.field("ids"), &p, Json::parse("[4294967296]")).ok());
    CHECK_FALSE(field_from_json(*t.field("weights"), &p, Json::parse("[1e300]")).ok());

    auto range = field_from_json(*t.field("small"), &p, Json::parse("[0, 1, 4]"));
    REQUIRE_FALSE(range.ok());
    CHECK(error_text(range).find("element 2 (4) is outside the allowed range 0..3") != std::string::npos);

    // A rejected array leaves the field as it was (and its version).
    CHECK(p.ids.size() == 3);
    const std::uint64_t v = p.ids.version();
    CHECK_FALSE(field_from_json(*t.field("ids"), &p, Json::parse("[9, 9, 1.5]")).ok());
    CHECK(std::as_const(p.ids)[0] == 1);
    CHECK(p.ids.version() == v);
}

TEST_CASE("reflect arrays: a patch of another field does not touch the arrays, a new value does") {
    const TypeInfo& t = array_probe_type();
    ArrayProbe p;
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"ids": [1, 2, 3, 4]})")).ok());
    const std::uint64_t v = p.ids.version();
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"other": 5})")).ok());
    CHECK(p.other == 5);
    CHECK(p.ids.version() == v);
    // The same array again: no change either.
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"ids": [1, 2, 3, 4]})")).ok());
    CHECK(p.ids.version() == v);
    // One element differs: only it is dirty.
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"ids": [1, 2, 9, 4]})")).ok());
    CHECK(p.ids.version() == v + 1);
    std::size_t b = 0, e = 0;
    CHECK(p.ids.dirty_since(v, b, e));
    CHECK(b == 2);
    CHECK(e == 3);
    // A bad value anywhere in the patch changes nothing.
    CHECK_FALSE(object_patch_from_json(t, &p, Json::parse(R"({"other": 7, "mask": [300]})")).ok());
    CHECK(p.other == 5);
    CHECK(p.mask.empty());
}

TEST_CASE("reflect arrays: schema and description") {
    const TypeInfo& t = array_probe_type();
    const Json s = type_json_schema(t);
    CHECK(s["properties"]["ids"]["type"] == "array");
    CHECK(s["properties"]["ids"]["items"]["type"] == "integer");
    CHECK(s["properties"]["ids"]["items"]["minimum"] == -2147483648LL);
    CHECK(s["properties"]["ids"]["items"]["maximum"] == 2147483647LL);
    CHECK(s["properties"]["ids"]["default"] == Json::array());
    CHECK(s["properties"]["ids"]["description"] == "Integer ids.");
    CHECK(s["properties"]["weights"]["items"]["type"] == "number");
    CHECK_FALSE(s["properties"]["weights"]["items"].contains("minimum"));
    CHECK(s["properties"]["mask"]["items"]["minimum"] == 0);
    CHECK(s["properties"]["mask"]["items"]["maximum"] == 255);
    // range() bounds the elements, not the array.
    CHECK(s["properties"]["small"]["items"]["minimum"] == 0);
    CHECK(s["properties"]["small"]["items"]["maximum"] == 3);
    CHECK_FALSE(s["properties"]["small"].contains("maximum"));

    const Json d = type_describe(t);
    bool saw = false;
    for (const Json& f : d["fields"])
        if (f["name"] == "mask") {
            saw = true;
            CHECK(f["kind"] == "arrayU8");
            CHECK(f["default"] == Json::array());
        }
    CHECK(saw);
}
