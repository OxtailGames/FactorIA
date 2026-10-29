// The Animation panel's logic (anim_model.h): rows, key selections, the arguments of the anim.* commands a drag / paste / delete
// builds, and the keys record mode writes. GPU-free; the panel itself is covered by the editor autotest (sections B2 and C2).
#include <algorithm>
#include <cmath>

#include "anim_model.h"
#include "doctest.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

using namespace fa;
using namespace fa::editor;

namespace {

std::shared_ptr<const ClipAsset> make_clip() {
    ensure_builtin_components();
    const char* text = R"({"format":"factoria.anim/1","duration":1,"loop":true,"tracks":[
        {"path":"arm","field":"rotation.z","keys":[{"t":0,"value":0},{"t":0.5,"value":40,"interp":"quadOut"},{"t":1,"value":0,"interp":"bezier","in":10,"out":-10}]},
        {"path":"arm","field":"position.x","keys":[{"t":0.25,"value":3}]},
        {"field":"flipX","component":"Sprite","keys":[{"t":0,"value":true},{"t":0.5,"value":false}]}]})";
    auto r = parse_anim_clip(Json::parse(text), "t.anim.json");
    const std::string err = r.ok() ? std::string() : r.error().to_string();
    INFO(err);
    REQUIRE(r.ok());
    return *r;
}

}  // namespace

TEST_CASE("anim model: frames snap, keys are told apart by 0.1 ms, tracks group by part") {
    CHECK(snap_to_frames(0.26, 12) == doctest::Approx(0.25));
    CHECK(snap_to_frames(0.26, 0) == doctest::Approx(0.26));
    CHECK(make_key_id(1, 0.50001) == make_key_id(1, 0.5));
    CHECK(!(make_key_id(1, 0.5) == make_key_id(2, 0.5)));
    auto clip = make_clip();
    const auto groups = group_tracks(*clip);
    REQUIRE(groups.size() == 2);
    CHECK(groups[0].part == "arm");
    CHECK(groups[0].tracks == std::vector<int>{0, 1});
    CHECK(groups[1].title == "(the entity)");
    CHECK(track_title(clip->tracks[0]) == "rotation.z");
    CHECK(track_title(clip->tracks[2]) == "Sprite.flipX");
    CHECK(unique_name({"clip", "clip2"}, "clip") == "clip3");
    CHECK(unique_name({}, "clip") == "clip");
}

TEST_CASE("anim model: a key is written back the way the file keeps it") {
    auto clip = make_clip();
    const ClipTrack& rot = clip->tracks[0];
    CHECK(key_interp_name(rot.keys[1]) == "quadOut");
    CHECK(key_interp_name(rot.keys[0]) == "linear");
    const Json eased = key_json(rot, rot.keys[1], 0.5);
    CHECK(eased["interp"] == "quadOut");
    CHECK(eased["value"].get<double>() == doctest::Approx(40));
    const Json bez = key_json(rot, rot.keys[2], 1.0);
    CHECK(bez["interp"] == "bezier");
    CHECK(bez["in"].get<double>() == doctest::Approx(10));
    CHECK(!key_json(rot, rot.keys[0], 0).contains("interp"));
    CHECK(key_json(clip->tracks[2], clip->tracks[2].keys[1], 0.5)["value"] == false);
    CHECK(track_ref_json(clip->tracks[0]) == Json::parse(R"({"path":"arm","field":"rotation.z"})"));
    CHECK(track_ref_json(clip->tracks[2]) == Json::parse(R"({"component":"Sprite","field":"flipX"})"));
    CHECK(value_at(rot, 0.25).get<double>() > 0.0);
}

TEST_CASE("anim model: dragging keys: the offset stays inside the clip, snaps to frames, and is one move_keys call") {
    KeySet sel{make_key_id(0, 0.2), make_key_id(1, 0.4)};
    CHECK(earliest_time(sel) == doctest::Approx(0.2));
    CHECK(latest_time(sel) == doctest::Approx(0.4));
    CHECK(clamp_move_offset(sel, -1.0) == doctest::Approx(-0.2));
    CHECK(snapped_move_offset(sel, 0.13, 10) == doctest::Approx(0.1));  // 0.2 + 0.13 = 0.33 -> 0.3
    CHECK(snapped_move_offset(sel, -5.0, 10) == doctest::Approx(-0.2));
    CHECK(snapped_scale(sel, 2.0, 10) == doctest::Approx(2.0));         // the latest key goes from 0.4 to 0.6: a frame
    CHECK(snapped_scale(sel, 0.0, 0) == doctest::Approx(0.05));
    const KeySet after = moved_keys(sel, 0.1, 2.0);
    CHECK(after.count(make_key_id(0, 0.3)) == 1);
    CHECK(after.count(make_key_id(1, 0.7)) == 1);
    const ModelCall call = move_keys_call("anim/a.anim.json", sel, 0.1, 2.0);
    CHECK(call.first == "anim.move_keys");
    CHECK(call.second["offset"].get<double>() == doctest::Approx(0.1));
    CHECK(call.second["scale"].get<double>() == doctest::Approx(2.0));
    CHECK(call.second["keys"].size() == 2);
    CHECK(call.second["extendDuration"] == true);
    CHECK(!move_keys_call("p", sel, 0.1, 1.0).second.contains("scale"));
}

TEST_CASE("anim model: delete, interpolation and tangents build the commands an AI would call") {
    auto clip = make_clip();
    KeySet sel{make_key_id(0, 0.5), make_key_id(0, 1.0), make_key_id(2, 0.0)};
    const auto del = delete_keys_calls("c.anim.json", *clip, sel);
    REQUIRE(del.size() == 2);
    CHECK(del[0].first == "anim.remove_keys");
    CHECK(del[0].second["times"].size() == 2);
    CHECK(del[1].second["track"]["component"] == "Sprite");
    const ModelCall ease = set_interp_call("c.anim.json", sel, "backInOut");
    CHECK(ease.first == "anim.set_interp");
    CHECK(ease.second["interp"] == "backInOut");
    const ClipTrack& rot = clip->tracks[0];
    const ModelCall tan = set_tangent_call("c.anim.json", rot, rot.keys[2], 0, 0, true, 25.0f);
    CHECK(tan.second["interp"] == "bezier");
    CHECK(tan.second["out"].get<double>() == doctest::Approx(25.0));
    CHECK(!tan.second.contains("in"));
}

TEST_CASE("anim model: copy and paste keep the spacing, and the pasted keys are the new selection") {
    auto clip = make_clip();
    KeySet sel{make_key_id(0, 0.5), make_key_id(0, 1.0), make_key_id(1, 0.25)};
    const KeyClipboard cb = copy_keys(*clip, sel);
    REQUIRE(cb.keys.size() == 3);
    double minRel = 1e9;  // the position key at 0.25 is the earliest: it sits at 0
    for (const ClipboardKey& k : cb.keys) minRel = std::min(minRel, k.rel);
    CHECK(minRel == doctest::Approx(0.0));
    const auto calls = paste_keys_calls("c.anim.json", cb, 2.0);
    REQUIRE(calls.size() == 2);
    CHECK(calls[0].first == "anim.set_keys");
    CHECK(calls[0].second["extendDuration"] == true);
    const KeySet pasted = pasted_selection(*clip, cb, 2.0);
    CHECK(pasted.count(make_key_id(1, 2.0)) == 1);
    CHECK(pasted.count(make_key_id(0, 2.25)) == 1);
    CHECK(pasted.count(make_key_id(0, 2.75)) == 1);
    CHECK(copy_keys(*clip, KeySet{}).empty());
}

TEST_CASE("anim model: record mode writes one key per changed channel, and keeps what the part had before") {
    auto clip = make_clip();
    World world;
    const Entity body = world.create("body");
    const Entity arm = world.create("arm");
    world.set_parent(arm, body);
    CHECK(part_path_of(world, body, arm) == std::optional<std::string>("arm"));
    CHECK(part_path_of(world, body, body) == std::optional<std::string>(""));
    CHECK(!part_path_of(world, arm, body));
    const Entity twin = world.create("arm");
    world.set_parent(twin, body);
    CHECK(!part_path_of(world, body, twin));  // the clip would find the first "arm"

    const TypeInfo* tt = TypeRegistry::global().find("Transform");
    REQUIRE(tt);
    const FieldInfo* pos = tt->field("position");
    REQUIRE(pos);
    const Transform live;
    const auto none = record_changes(*tt, *pos, &live, Json::array({0, 0, 0}));
    CHECK(none.empty());
    const auto changes = record_changes(*tt, *pos, &live, Json::array({5, 0, 7}));
    REQUIRE(changes.size() == 2);
    CHECK(changes[0].field == "position.x");
    CHECK(changes[1].field == "position.z");
    CHECK(changes[1].value.get<double>() == doctest::Approx(7));

    // The clip has position.x on "arm" with a key at 0.25: a key there is replaced, any other time adds one.
    const auto calls = record_calls("c.anim.json", *clip, "arm", changes, 0.25);
    REQUIRE(calls.size() == 2);
    CHECK(calls[0].second["track"]["field"] == "position.x");
    CHECK(calls[0].second["keys"].size() == 1);
    CHECK(calls[0].second["keys"][0]["value"].get<double>() == doctest::Approx(5));
    // position.z is a new track and the playhead is later than 0: it starts from the old value at 0.
    CHECK(calls[1].second["keys"].size() == 2);
    CHECK(calls[1].second["keys"][0]["t"].get<double>() == doctest::Approx(0));
    CHECK(calls[1].second["keys"][0]["value"].get<double>() == doctest::Approx(0));
    const auto atZero = record_calls("c.anim.json", *clip, "arm", changes, 0.0);
    CHECK(atZero[1].second["keys"].size() == 1);

    // A stepping field records the whole value; a key that exists keeps its interpolation.
    const TypeInfo* st = TypeRegistry::global().find("Sprite");
    REQUIRE(st);
    const FieldInfo* vis = st->field("flipX");
    REQUIRE(vis);
    {
        const Sprite sprite;
        const auto flip = record_changes(*st, *vis, &sprite, Json(!sprite.flipX));
        REQUIRE(flip.size() == 1);
        const auto c2 = record_calls("c.anim.json", *clip, "", flip, 0.5);
        CHECK(c2[0].second["track"]["component"] == "Sprite");
        CHECK(c2[0].second["keys"][0]["value"] == flip[0].value);
    }
    // An asset steps, so it records; a Json field cannot be animated and records nothing.
    const FieldInfo* texture = st->field("texture");
    REQUIRE(texture);
    const Sprite plain;
    CHECK(record_changes(*st, *texture, &plain, "x.png").size() == 1);
    const TypeInfo* at = TypeRegistry::global().find("Animator");
    REQUIRE(at);
    const FieldInfo* clips = at->field("clips");
    REQUIRE(clips);
    const Animator animator;
    CHECK(record_changes(*at, *clips, &animator, Json::object({{"a", "b"}})).empty());
}
