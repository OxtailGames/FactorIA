// TypedArray (core/typed_array.h) and the reflected array fields (FieldKind::ArrayI32 / ArrayF32 / ArrayU8).
#include <doctest.h>

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

TEST_CASE("typed array: reads never bump the version, writes do") {
    ArrayI32 a{1, 2, 3, 4, 5, 6, 7, 8};
    a.acknowledge();
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
    CHECK(!a.has_dirty());

    a[5] = 60;  // a mutable operator[] counts as a write of that index
    CHECK(a.version() == v0 + 1);
    CHECK(a.dirty_begin() == 5);
    CHECK(a.dirty_end() == 6);
    a[1] = 20;
    CHECK(a.dirty_begin() == 1);
    CHECK(a.dirty_end() == 6);
    CHECK(c[5] == 60);

    a.acknowledge();
    CHECK(!a.has_dirty());
    CHECK(a.dirty_begin() == 0);
    CHECK(a.dirty_end() == 0);
    CHECK(a.version() == v0 + 2);  // acknowledging keeps the version

    a.data();  // a mutable pointer counts as a write of everything
    CHECK(a.dirty_begin() == 0);
    CHECK(a.dirty_end() == 8);
}

TEST_CASE("typed array: set, fill and assign only change what differs") {
    ArrayU8 a(10, 7);
    a.acknowledge();
    const std::uint64_t v0 = a.version();
    CHECK(a.set(3, 7));  // same value: no change
    CHECK(a.version() == v0);
    CHECK(!a.has_dirty());
    CHECK(a.set(3, 8));
    CHECK(a.version() == v0 + 1);
    CHECK(a.dirty_begin() == 3);
    CHECK(a.dirty_end() == 4);
    CHECK_FALSE(a.set(10, 1));  // out of range: ignored
    CHECK(a.version() == v0 + 1);

    a.acknowledge();
    a.fill(7);  // only index 3 differs
    CHECK(a.dirty_begin() == 3);
    CHECK(a.dirty_end() == 4);
    a.acknowledge();
    const std::uint64_t v1 = a.version();
    a.fill(7);  // nothing differs now
    CHECK(a.version() == v1);
    a.fill(9, 2, 5);
    CHECK(a.dirty_begin() == 2);
    CHECK(a.dirty_end() == 5);
    CHECK(a[1] == 7);
    CHECK(a[4] == 9);
    CHECK(a[5] == 7);

    a.acknowledge();
    const std::uint8_t same[10] = {7, 7, 9, 9, 9, 7, 7, 7, 7, 7};
    const std::uint64_t v2 = a.version();
    a.assign(same, 10);  // identical contents
    CHECK(a.version() == v2);
    const std::uint8_t other[10] = {7, 1, 9, 9, 9, 7, 7, 2, 7, 7};
    a.assign(other, 10);  // the span between the first and last difference
    CHECK(a.dirty_begin() == 1);
    CHECK(a.dirty_end() == 8);
}

TEST_CASE("typed array: a change of size dirties everything, copies keep the contents") {
    ArrayI32 a{1, 2, 3};
    a.acknowledge();
    a.resize(5, 9);
    CHECK(a.size() == 5);
    CHECK(a[4] == 9);
    CHECK(a.dirty_begin() == 0);
    CHECK(a.dirty_end() == 5);
    a.acknowledge();
    a.resize(2);  // a shrink: the old tail is part of the change
    CHECK(a.dirty_begin() == 0);
    CHECK(a.dirty_end() == 5);
    a.acknowledge();
    a.push_back(4);
    CHECK(a.size() == 3);
    CHECK(a.dirty_end() == 3);
    a.acknowledge();
    const std::uint64_t v = a.version();
    a.resize(3);  // same size: nothing
    CHECK(a.version() == v);
    a.clear();
    CHECK(a.empty());
    CHECK(a.version() == v + 1);

    ArrayI32 src{4, 5, 6};
    ArrayI32 copy = src;  // copy construction: same contents, a fresh array that was never read
    CHECK(copy == src);
    CHECK(copy.has_dirty());
    CHECK(copy.dirty_end() == 3);
    ArrayI32 dst{4, 5, 0};
    dst.acknowledge();
    const std::uint64_t vd = dst.version();
    dst = src;  // copy assignment: only index 2 differs
    CHECK(dst == src);
    CHECK(dst.dirty_begin() == 2);
    CHECK(dst.dirty_end() == 3);
    CHECK(dst.version() == vd + 1);
    dst.acknowledge();
    dst = src;  // identical: nothing
    CHECK(dst.version() == vd + 1);
    CHECK(!dst.has_dirty());

    ArrayI32 moved = std::move(dst);  // a move keeps the version and the (empty) dirty range
    CHECK(moved == src);
    CHECK(moved.version() == vd + 1);
    CHECK(!moved.has_dirty());
    ArrayI32 target{1};
    target = std::move(moved);
    CHECK(target == src);
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
    p.ids.acknowledge();
    const std::uint64_t v = p.ids.version();
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"other": 5})")).ok());
    CHECK(p.other == 5);
    CHECK(p.ids.version() == v);
    CHECK_FALSE(p.ids.has_dirty());
    // The same array again: no change either.
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"ids": [1, 2, 3, 4]})")).ok());
    CHECK(p.ids.version() == v);
    // One element differs: only it is dirty.
    REQUIRE(object_patch_from_json(t, &p, Json::parse(R"({"ids": [1, 2, 9, 4]})")).ok());
    CHECK(p.ids.version() == v + 1);
    CHECK(p.ids.dirty_begin() == 2);
    CHECK(p.ids.dirty_end() == 3);
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
