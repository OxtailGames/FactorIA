// Array fields (ArrayI32 / ArrayF32 / ArrayU8) from a script: reads give typed arrays, writes validate every element.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
struct ScriptArrays {
    ArrayI32 ids;
    ArrayF32 weights;
    ArrayU8 mask;
    ArrayI32 small;  // range(0, 3)
    ArrayF32 ratios;  // range(0.1, 0.3)
    ArrayF32 tiny;    // range(0.00001, 0.5)
};

// A test-only component; registered before the script system starts so scripts see its fields.
void register_script_arrays() {
    ensure_builtin_components();
    auto& reg = TypeRegistry::global();
    if (reg.of<ScriptArrays>()) return;
    reg.add<ScriptArrays>("TestScriptArrays", "A test component with array fields.", "Test")
        .field("ids", &ScriptArrays::ids, "Integer ids.")
        .field("weights", &ScriptArrays::weights, "Weights.")
        .field("mask", &ScriptArrays::mask, "Bytes.")
        .field("small", &ScriptArrays::small, "Values 0..3.")
        .range(0, 3)
        .field("ratios", &ScriptArrays::ratios, "Ratios 0.1..0.3.")
        .range(0.1, 0.3)
        .field("tiny", &ScriptArrays::tiny, "Values 0.00001..0.5.")
        .range(0.00001, 0.5);
}

Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}

std::string eval_error(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(!r.ok(), code);
    return r.error().to_string();
}

struct Fixture {
    TestHost h;
    Entity e;
    explicit Fixture(const char* tag) : h((register_script_arrays(), tag)) {
        e = h.w.create("probe", "probe");
        auto& a = h.w.add<ScriptArrays>(e);
        a.ids.assign(std::vector<std::int32_t>{10, -20, 30}.data(), 3);
        a.mask.assign(std::vector<std::uint8_t>{0, 128, 255}.data(), 3);
        REQUIRE(h.start());
    }
    ScriptArrays& arrays() { return *h.w.get<ScriptArrays>(e); }
};
}  // namespace

TEST_CASE("script arrays: a read is a typed array of the field's element type") {
    Fixture f("arr_read");
    CHECK(eval_ok(f.h, "world.find('probe').get('TestScriptArrays').ids instanceof Int32Array").get<bool>());
    CHECK(eval_ok(f.h, "world.find('probe').get('TestScriptArrays').weights instanceof Float32Array").get<bool>());
    CHECK(eval_ok(f.h, "world.find('probe').get('TestScriptArrays').mask instanceof Uint8Array").get<bool>());
    CHECK(eval_ok(f.h, "Array.from(world.find('probe').get('TestScriptArrays').ids).join(',')") == "10,-20,30");
    CHECK(eval_ok(f.h, "Array.from(world.find('probe').get('TestScriptArrays').mask).join(',')") == "0,128,255");
    CHECK(eval_ok(f.h, "world.find('probe').get('TestScriptArrays').weights.length").get<int>() == 0);
    // The read is a copy: writing into it changes nothing.
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').ids[0] = 99; 0");
    CHECK(std::as_const(f.arrays().ids)[0] == 10);
}

TEST_CASE("script arrays: a write takes a typed array or a plain array and replaces the whole field") {
    Fixture f("arr_write");
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').ids = new Int32Array([1, 2, 3, 4]); 0");
    CHECK(f.arrays().ids.size() == 4);
    CHECK(std::as_const(f.arrays().ids)[3] == 4);
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').weights = [0.5, -1.25]; 0");
    CHECK(f.arrays().weights.size() == 2);
    CHECK(std::as_const(f.arrays().weights)[1] == -1.25f);
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').mask = new Uint8Array([9, 8]); 0");
    CHECK(f.arrays().mask == ArrayU8{9, 8});
    // Another typed array type and a plain array of whole numbers are read element by element.
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').ids = new Float64Array([5, 6]); 0");
    CHECK(f.arrays().ids == ArrayI32{5, 6});
    // Round trip: what a read gives, a write takes.
    eval_ok(f.h, "const c = world.find('probe').get('TestScriptArrays'); c.ids = c.ids.map(x => x * 2); 0");
    CHECK(f.arrays().ids == ArrayI32{10, 12});
    // An empty array empties the field.
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').ids = []; 0");
    CHECK(f.arrays().ids.empty());
    // Writing the contents it already has is not a change.
    const std::uint64_t v = f.arrays().mask.version();
    eval_ok(f.h, "world.find('probe').get('TestScriptArrays').mask = [9, 8]; 0");
    CHECK(f.arrays().mask.version() == v);
    // e.set goes through the JSON path: typed arrays become flat arrays there.
    eval_ok(f.h, "world.find('probe').set('TestScriptArrays', { ids: new Int32Array([7, 8, 9]), mask: [1] }); 0");
    CHECK(f.arrays().ids == ArrayI32{7, 8, 9});
    CHECK(f.arrays().mask == ArrayU8{1});
}

TEST_CASE("script arrays: a bad element or a wrong value names the field, the index and the value") {
    Fixture f("arr_errors");
    const std::string notInt = eval_error(f.h, "world.find('probe').get('TestScriptArrays').ids = [1, 2.5]; 0");
    CHECK(notInt.find("TestScriptArrays.ids[1] must be an integer") != std::string::npos);
    CHECK(notInt.find("2.5") != std::string::npos);
    const std::string text = eval_error(f.h, "world.find('probe').get('TestScriptArrays').weights = [1, 'x']; 0");
    CHECK(text.find("TestScriptArrays.weights[1] must be a finite number, got 'x'") != std::string::npos);
    const std::string big = eval_error(f.h, "world.find('probe').get('TestScriptArrays').mask = [1, 2, 300]; 0");
    CHECK(big.find("mask[2] must be an integer from 0 to 255, got 300") != std::string::npos);
    const std::string typedBig = eval_error(f.h, "world.find('probe').get('TestScriptArrays').mask = new Int32Array([-1]); 0");
    CHECK(typedBig.find("mask[0]") != std::string::npos);
    const std::string range = eval_error(f.h, "world.find('probe').get('TestScriptArrays').small = new Int32Array([0, 9]); 0");
    CHECK(range.find("small[1] must be an integer from 0 to 3, got 9") != std::string::npos);
    const std::string nan = eval_error(f.h, "world.find('probe').get('TestScriptArrays').weights = new Float32Array([NaN]); 0");
    CHECK(nan.find("weights[0]") != std::string::npos);
    const std::string hole = eval_error(f.h, "world.find('probe').get('TestScriptArrays').ids = [1, , 3]; 0");
    CHECK(hole.find("ids[1] must be an integer") != std::string::npos);
    CHECK(hole.find("undefined") != std::string::npos);
    const std::string notArray = eval_error(f.h, "world.find('probe').get('TestScriptArrays').ids = 5; 0");
    CHECK(notArray.find("expects an Int32Array or an array of integers") != std::string::npos);
    const std::string obj = eval_error(f.h, "world.find('probe').get('TestScriptArrays').mask = {0: 1, length: 1}; 0");
    CHECK(obj.find("expects a Uint8Array or an array of integers from 0 to 255") != std::string::npos);
    // The bounds of a float range read as the author wrote them, not as the float widened to a double (0.30000001192092896).
    const std::string ratio = eval_error(f.h, "world.find('probe').get('TestScriptArrays').ratios = [0.2, 0.5]; 0");
    CHECK(ratio.find("ratios[1] must be a number from 0.1 to 0.3, got 0.5") != std::string::npos);
    // A sparse array of the biggest size fails at its first hole, without allocating the 64 MiB it claims.
    const std::string sparse = eval_error(f.h, "world.find('probe').get('TestScriptArrays').ids = new Array(1 << 24); 0");
    CHECK(sparse.find("ids[0] must be an integer") != std::string::npos);
    CHECK(sparse.find("undefined") != std::string::npos);
    // None of the bad writes changed anything.
    CHECK(f.arrays().ids == ArrayI32{10, -20, 30});
    CHECK(f.arrays().mask == ArrayU8{0, 128, 255});
    CHECK(f.arrays().weights.empty());
}

TEST_CASE("script arrays: null is refused on an array field with a message that says what to pass") {
    Fixture f("arr_null");
    const std::string ints = eval_error(f.h, "world.find('probe').get('TestScriptArrays').ids = null; 0");
    CHECK(ints.find("TestScriptArrays.ids expects an Int32Array or an array of integers, got 'null'") !=
          std::string::npos);
    const std::string floats = eval_error(f.h, "world.find('probe').get('TestScriptArrays').weights = null; 0");
    CHECK(floats.find("TestScriptArrays.weights expects a Float32Array or an array of numbers, got 'null'") !=
          std::string::npos);
    CHECK(f.arrays().ids == ArrayI32{10, -20, 30});
}

TEST_CASE("script fields: a getter that throws while a vector is set is the error of the write, which changes nothing") {
    Fixture f("fset_getter");
    f.h.w.add<Sprite>(f.e).color = Color{0.1f, 0.2f, 0.3f, 1.0f};
    // An array passes through toFloats untouched, so its getter runs inside the native write.
    const std::string err = eval_error(f.h,
                                       "const a = [0.9, 0.9, 0.9, 0.9]; "
                                       "Object.defineProperty(a, 1, { get() { throw new Error('getter boom'); } }); "
                                       "world.find('probe').get('Sprite').color = a; 0");
    CHECK_MESSAGE(err.find("getter boom") != std::string::npos, err);
    CHECK(f.h.w.get<Sprite>(f.e)->color == Color{0.1f, 0.2f, 0.3f, 1.0f});
    // The next write works: no exception was left pending.
    eval_ok(f.h, "world.find('probe').get('Sprite').color = [0.4, 0.5, 0.6, 1]; 0");
    CHECK(f.h.w.get<Sprite>(f.e)->color.g == doctest::Approx(0.5f));
}

TEST_CASE("script arrays: a range bound shows every digit that matters") {
    Fixture f("arr_bound");
    // 0.00001 used to show as 0: the bound went through to_json, which rounds to 4 decimals.
    const std::string tiny = eval_error(f.h, "world.find('probe').get('TestScriptArrays').tiny = [0.7]; 0");
    CHECK_MESSAGE(tiny.find("tiny[0] must be a number from 0.00001 to 0.5, got 0.7") != std::string::npos, tiny);
}
