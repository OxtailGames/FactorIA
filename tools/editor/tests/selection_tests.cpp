// The selection set and the undo entries (selection.h, undo_stack.h): plain data, no window, no engine.
#include "doctest.h"
#include "selection.h"
#include "undo_stack.h"

#include <algorithm>
#include <map>
#include <string>

using namespace fa;
using namespace fa::editor;

namespace {
using Ids = std::vector<std::string>;
const Ids kOrder = {"a", "b", "c", "d", "e"};
}  // namespace

TEST_CASE("Selection: replace and clear keep one primary") {
    Selection s;
    CHECK(s.empty());
    CHECK(s.primary().empty());
    s.replace("a");
    s.replace("b");
    CHECK(s.ids() == Ids{"b"});
    CHECK(s.primary() == "b");
    s.replace("");  // an empty id clears, like select_id("") always did
    CHECK(s.empty());
    CHECK(s.primary().empty());
    s.add("a");
    s.clear();
    CHECK(s.empty());
    CHECK(s.primary().empty());
}

TEST_CASE("Selection: add keeps selection order and the last added is the primary") {
    Selection s;
    s.add("c");
    s.add("a");
    s.add("b");
    CHECK(s.ids() == Ids{"c", "a", "b"});
    CHECK(s.primary() == "b");
    s.add("c");  // already in: no duplicate, but it becomes the primary
    CHECK(s.ids() == Ids{"c", "a", "b"});
    CHECK(s.primary() == "c");
    s.add("");
    CHECK(s.size() == 3);
    CHECK(s.contains("a"));
    CHECK_FALSE(s.contains("z"));
}

TEST_CASE("Selection: set replaces the ids in order and keeps the primary asked for") {
    Selection s;
    s.add("old");
    s.set({"a", "", "b", "a", "c"}, "b");
    CHECK(s.ids() == Ids{"a", "b", "c"});
    CHECK(s.primary() == "b");
    s.set({"x", "y"}, "not there");  // a primary that is not in the list: the last id
    CHECK(s.ids() == Ids{"x", "y"});
    CHECK(s.primary() == "y");
    s.set({}, "x");
    CHECK(s.empty());
    CHECK(s.primary().empty());
}

TEST_CASE("Selection: toggle adds, removes, and promotes the last remaining id when it removes the primary") {
    Selection s;
    s.toggle("a");
    s.toggle("b");
    s.toggle("c");
    CHECK(s.ids() == Ids{"a", "b", "c"});
    CHECK(s.primary() == "c");
    s.toggle("a");  // not the primary: the primary stays
    CHECK(s.ids() == Ids{"b", "c"});
    CHECK(s.primary() == "c");
    s.toggle("c");  // the primary: the last remaining one takes over
    CHECK(s.ids() == Ids{"b"});
    CHECK(s.primary() == "b");
    s.toggle("b");
    CHECK(s.empty());
    CHECK(s.primary().empty());
}

TEST_CASE("Selection: range selects between two ids in either direction and ends on the clicked one") {
    Selection s;
    CHECK(s.range("b", "d", kOrder));
    CHECK(s.ids() == Ids{"b", "c", "d"});
    CHECK(s.primary() == "d");
    CHECK(s.range("e", "c", kOrder));  // backwards, replacing
    CHECK(s.ids() == Ids{"c", "d", "e"});
    CHECK(s.primary() == "c");
    s.replace("a");
    CHECK(s.range("c", "d", kOrder, true));  // additive keeps "a"
    CHECK(s.ids() == Ids{"a", "c", "d"});
    CHECK(s.primary() == "d");
    CHECK(s.range("d", "d", kOrder));
    CHECK(s.ids() == Ids{"d"});
    // an id that is not in the list changes nothing
    CHECK_FALSE(s.range("a", "zzz", kOrder));
    CHECK_FALSE(s.range("zzz", "a", kOrder));
    CHECK(s.ids() == Ids{"d"});
    CHECK(s.primary() == "d");
}

TEST_CASE("Selection: remove and prune drop ids and give the primary to the last one left") {
    Selection s;
    s.add("a");
    s.add("b");
    s.add("c");
    s.remove("zzz");
    CHECK(s.size() == 3);
    s.remove("c");
    CHECK(s.ids() == Ids{"a", "b"});
    CHECK(s.primary() == "b");
    s.add("c");
    s.add("b");  // primary b, order a b c
    const int dropped = s.prune([](const std::string& id) { return id == "a"; });
    CHECK(dropped == 2);
    CHECK(s.ids() == Ids{"a"});
    CHECK(s.primary() == "a");
    CHECK(s.prune([](const std::string&) { return true; }) == 0);
    CHECK(s.prune([](const std::string&) { return false; }) == 1);
    CHECK(s.empty());
    CHECK(s.primary().empty());
}

namespace {
UndoEntry snap(int n) { return UndoEntry::snapshot(Json::object({{"n", n}})); }
std::vector<UndoCommand> one(const std::string& cmd, int v) { return {UndoCommand{cmd, Json::object({{"v", v}})}}; }
}  // namespace

TEST_CASE("UndoEntry: a raw Json is a special entry only when its key starts with '$'") {
    UndoEntry scene(Json::object({{"entities", Json::array()}}));
    CHECK(scene.kind == UndoEntry::Kind::Snapshot);
    CHECK_FALSE(scene.is_special("$clip"));
    UndoEntry clip(Json::object({{"$clip", Json::object({{"path", "a.clip.json"}})}}));
    CHECK(clip.kind == UndoEntry::Kind::Special);
    CHECK(clip.is_special("$clip"));
    CHECK_FALSE(clip.is_special("$image"));
    CHECK(clip.special_payload("$clip").value("path", "") == "a.clip.json");
    CHECK(clip.special_payload("$image").is_null());
    const Json& asJson = clip;  // loops that look for their own key keep reading entries as Json
    CHECK(asJson.contains("$clip"));
    UndoEntry cmd = UndoEntry::command(one("scene.set_component", 2), one("scene.set_component", 1));
    CHECK(cmd.kind == UndoEntry::Kind::Command);
    CHECK(cmd.data.is_null());
    CHECK(cmd.forward.size() == 1);
    CHECK(cmd.inverse.size() == 1);
    CHECK(cmd.bytes > 0);
}

TEST_CASE("UndoEntry: the size estimate grows with the content") {
    const Json small = Json::object({{"a", 1}});
    Json big = Json::object({{"text", std::string(10000, 'x')}, {"list", Json::array({1, 2, 3, 4, 5})}});
    CHECK(estimate_json_bytes(small) > 0);
    CHECK(estimate_json_bytes(big) > 10000);
    CHECK(estimate_json_bytes(big) > estimate_json_bytes(small));
    CHECK(UndoEntry::snapshot(big).bytes == estimate_json_bytes(big));
}

TEST_CASE("UndoStack: last in, first out, and the byte count follows pushes and pops") {
    UndoStack st;
    CHECK(st.empty());
    st.push_back(snap(1));
    st.push_back(snap(2));
    st.push_back(Json::object({{"n", 3}}));  // a raw Json converts
    CHECK(st.size() == 3);
    CHECK(st.bytes() == st[0].bytes + st[1].bytes + st[2].bytes);
    CHECK(st.back().data["n"] == 3);
    st.pop_back();
    CHECK(st.back().data["n"] == 2);
    UndoEntry e = st.take_back();
    CHECK(e.data["n"] == 2);
    CHECK(st.size() == 1);
    CHECK(st.bytes() == st[0].bytes);
    st.clear();
    CHECK(st.empty());
    CHECK(st.bytes() == 0);
}

TEST_CASE("UndoStack: the entry cap drops the oldest entries (100 by default)") {
    UndoStack st;
    CHECK(st.max_entries() == 100);
    for (int i = 0; i < 130; ++i) st.push_back(snap(i));
    CHECK(st.size() == 100);
    CHECK(st[0].data["n"] == 30);
    CHECK(st.back().data["n"] == 129);

    UndoStack small(3, UndoStack::kMaxBytes);
    for (int i = 0; i < 5; ++i) small.push_back(snap(i));
    CHECK(small.size() == 3);
    CHECK(small[0].data["n"] == 2);
}

TEST_CASE("UndoStack: lost() counts what the caps and clear() remove, not what Undo pops") {
    UndoStack st(3, UndoStack::kMaxBytes);
    for (int i = 0; i < 3; ++i) st.push_back(snap(i));
    CHECK(st.lost() == 0);
    st.pop_back();  // an Undo
    CHECK(st.lost() == 0);
    for (int i = 0; i < 4; ++i) st.push_back(snap(i));  // two entries + four pushes: three stay
    CHECK(st.lost() == 3);
    st.erase_if([](const UndoEntry& e) { return e.data["n"] == 3; });
    CHECK(st.lost() == 4);
    st.clear();
    CHECK(st.lost() == 6);
}

TEST_CASE("UndoStack: the byte cap drops the oldest entries but never the newest") {
    CHECK(UndoStack::kMaxBytes == size_t(256) << 20);
    const size_t one = snap(0).bytes;
    UndoStack st(100, one * 3 + one / 2);  // room for three
    for (int i = 0; i < 6; ++i) st.push_back(snap(i));
    CHECK(st.size() == 3);
    CHECK(st[0].data["n"] == 3);
    CHECK(st.bytes() <= st.max_bytes());
    // one entry bigger than the whole budget still stays (it is the step the user just made)
    UndoStack tiny(100, 10);
    tiny.push_back(snap(1));
    tiny.push_back(snap(2));
    CHECK(tiny.size() == 1);
    CHECK(tiny.back().data["n"] == 2);
}

TEST_CASE("UndoStack: erase_if recounts the bytes") {
    UndoStack st;
    st.push_back(UndoEntry(Json::object({{"$music", Json::object({{"step", 1}})}})));
    st.push_back(UndoEntry(Json::object({{"$music", Json::object({{"step", 2}})}})));
    st.push_back(snap(3));
    st.erase_if([](const UndoEntry& e) { return e.is_special("$music") && e.data["$music"].value("step", 0) == 1; });
    CHECK(st.size() == 2);
    CHECK(st.bytes() == st[0].bytes + st[1].bytes);
}

TEST_CASE("edit_coalesces: the same key within 0.8 s merges") {
    CHECK(edit_coalesces("k", "k", 1.5, 1.0));
    CHECK_FALSE(edit_coalesces("k", "k", 1.9, 1.0));
    CHECK_FALSE(edit_coalesces("k", "other", 1.1, 1.0));
    CHECK_FALSE(edit_coalesces("k", "", 1.1, 1.0));
}

TEST_CASE("UndoStack: push_command pushes, coalesces into a command entry and only then") {
    UndoStack st;
    CHECK(st.push_command(one("set", 2), one("set", 1), false));
    CHECK(st.size() == 1);
    // coalesced: Replace keeps the old inverse (the state before the drag) and takes the newest forward
    CHECK_FALSE(st.push_command(one("set", 5), one("set", 2), true));
    CHECK(st.size() == 1);
    CHECK(st.back().forward.size() == 1);
    CHECK(st.back().forward[0].args["v"] == 5);
    CHECK(st.back().inverse[0].args["v"] == 1);
    CHECK(st.bytes() == st.back().bytes);
    // Chain: forward runs old then new, inverse undoes the new one first
    CHECK_FALSE(st.push_command(one("move", 7), one("move", -7), true, CoalesceMode::Chain));
    CHECK(st.back().forward.size() == 2);
    CHECK(st.back().forward[1].cmd == "move");
    CHECK(st.back().inverse.size() == 2);
    CHECK(st.back().inverse[0].cmd == "move");
    CHECK(st.back().inverse[1].cmd == "set");
    // a snapshot on top is never merged into
    st.push_back(snap(9));
    CHECK(st.push_command(one("set", 8), one("set", 5), true));
    CHECK(st.size() == 3);
    // the entry cap applies to commands too
    UndoStack small(2, UndoStack::kMaxBytes);
    for (int i = 0; i < 4; ++i) small.push_command(one("set", i + 1), one("set", i), false);
    CHECK(small.size() == 2);
    CHECK(small[0].forward[0].args["v"] == 3);
}

TEST_CASE("UndoStack: Merge replaces the command with the same target and adds the others") {
    auto call = [](const std::string& target, int v) {
        UndoCommand c;
        c.cmd = "set";
        c.target = target;
        c.args = Json::object({{"v", v}});
        return std::vector<UndoCommand>{c};
    };
    UndoStack st;
    CHECK(st.push_command(call("a", 1), call("a", 0), false, CoalesceMode::Merge));
    CHECK_FALSE(st.push_command(call("b", 11), call("b", 10), true, CoalesceMode::Merge));
    CHECK(st.back().forward.size() == 2);
    // a drag of both: every frame replaces its own entry, nothing grows
    for (int i = 2; i < 20; ++i) {
        st.push_command(call("a", i), call("a", -1), true, CoalesceMode::Merge);
        st.push_command(call("b", 10 + i), call("b", -1), true, CoalesceMode::Merge);
    }
    REQUIRE(st.back().forward.size() == 2);
    REQUIRE(st.back().inverse.size() == 2);
    CHECK(st.back().forward[0].args["v"] == 19);
    CHECK(st.back().forward[1].args["v"] == 29);
    CHECK(st.back().inverse[0].target == "b");  // undo runs in the reverse order
    CHECK(st.back().inverse[0].args["v"] == 10);
    CHECK(st.back().inverse[1].args["v"] == 0);
    CHECK(st.bytes() == st.back().bytes);
    // no target: it chains
    CHECK_FALSE(st.push_command(call("", 5), call("", 4), true, CoalesceMode::Merge));
    CHECK(st.back().forward.size() == 3);
}

TEST_CASE(
    "UndoStack: Merge with overlapping fields redoes to the newest value, Chain after Merge undoes to the start") {
    struct State {
        int pos = 0, scale = 0;
    };
    auto call = [](const std::string& target, int pos, int scale) {
        UndoCommand c;
        c.cmd = "set";
        c.target = target;
        c.args = Json::object({{"pos", pos}});
        if (scale >= 0) c.args["scale"] = scale;
        return std::vector<UndoCommand>{c};
    };
    auto run = [](State& s, const std::vector<UndoCommand>& cmds) {
        for (const UndoCommand& c : cmds) {
            s.pos = c.args["pos"].get<int>();
            if (c.args.contains("scale")) s.scale = c.args["scale"].get<int>();
        }
    };
    UndoStack st;
    st.push_command(call("A", 1, -1), call("A", 0, -1), false, CoalesceMode::Merge);  // pos 0 -> 1
    st.push_command(call("B", 2, 5), call("B", 1, 0), true, CoalesceMode::Merge);     // pos 1 -> 2, scale 0 -> 5
    st.push_command(call("A", 3, -1), call("A", 2, -1), true, CoalesceMode::Merge);   // pos 2 -> 3
    REQUIRE(st.back().forward.size() == 2);
    State s;
    run(s, st.back().forward);
    CHECK(s.pos == 3);  // the newest call wins
    CHECK(s.scale == 5);
    run(s, st.back().inverse);
    CHECK(s.pos == 0);
    CHECK(s.scale == 0);
    // a Chain call after the merges: undo goes back to the start, redo to the end
    State t;
    st.push_command(call("C", 4, -1), call("C", 3, -1), true, CoalesceMode::Chain);
    st.push_command(call("A", 6, -1), call("A", 4, -1), true,
                    CoalesceMode::Merge);  // chained entries merge by target too
    run(t, st.back().forward);
    CHECK(t.pos == 6);
    CHECK(t.scale == 5);
    run(t, st.back().inverse);
    CHECK(t.pos == 0);
    CHECK(t.scale == 0);
}

TEST_CASE("UndoStack: Merge of two merge patches with one target redoes both (a drag of two params of one block)") {
    auto patch = [](const char* fields) {
        UndoCommand c;
        c.cmd = "scene.set_component";
        c.target = "scene.set_component|SceneSettings|skyMaterialParams,|merge";
        c.args = Json::object({{"component", "SceneSettings"}, {"fields", Json::parse(fields)}, {"merge", true}});
        return std::vector<UndoCommand>{c};
    };
    auto redo = [](const UndoStack& st) {
        Json state = Json::object({{"skyMaterialParams", Json::object()}});
        for (const UndoCommand& c : st.back().forward) state.merge_patch(c.args["fields"]);
        return state;
    };
    UndoStack st;
    // tint, then strength, then tint again, within one coalescing window
    st.push_command(patch(R"({"skyMaterialParams":{"tint":[1,0,0,1]}})"), patch(R"({"skyMaterialParams":{}})"), false,
                    CoalesceMode::Merge);
    st.push_command(patch(R"({"skyMaterialParams":{"strength":2}})"), patch(R"({"skyMaterialParams":{}})"), true,
                    CoalesceMode::Merge);
    st.push_command(patch(R"({"skyMaterialParams":{"tint":[0,1,0,1]}})"), patch(R"({"skyMaterialParams":{}})"), true,
                    CoalesceMode::Merge);
    REQUIRE(st.back().forward.size() == 1);  // one patch of one target, not a growing list
    CHECK(redo(st) == Json::parse(R"({"skyMaterialParams":{"tint":[0,1,0,1],"strength":2}})"));
    // a key deleted by the first patch and set by the second: the null goes (the second value wins), nested objects compose
    UndoStack st2;
    st2.push_command(patch(R"({"skyMaterialParams":{"a":null,"deep":{"x":1}}})"), patch(R"({"skyMaterialParams":{}})"),
                     false, CoalesceMode::Merge);
    st2.push_command(patch(R"({"skyMaterialParams":{"a":5,"deep":{"y":2}}})"), patch(R"({"skyMaterialParams":{}})"),
                     true, CoalesceMode::Merge);
    CHECK(st2.back().forward.size() == 1);
    CHECK(redo(st2) == Json::parse(R"({"skyMaterialParams":{"a":5,"deep":{"x":1,"y":2}}})"));
    // an object after a null cannot be one patch (it would merge into the value instead of replacing the deleted one): both stay
    UndoStack st3;
    st3.push_command(patch(R"({"skyMaterialParams":{"a":null}})"), patch(R"({"skyMaterialParams":{}})"), false,
                     CoalesceMode::Merge);
    st3.push_command(patch(R"({"skyMaterialParams":{"a":{"x":1}}})"), patch(R"({"skyMaterialParams":{}})"), true,
                     CoalesceMode::Merge);
    CHECK(st3.back().forward.size() == 2);
    CHECK(st3.back().inverse.size() == 2);
    CHECK(redo(st3) == Json::parse(R"({"skyMaterialParams":{"a":{"x":1}}})"));
    // the patches are of the same entity: another id is never composed
    auto other = patch(R"({"skyMaterialParams":{"z":1}})");
    other[0].args["id"] = "other";
    UndoStack st4;
    st4.push_command(patch(R"({"skyMaterialParams":{"y":1}})"), patch(R"({"skyMaterialParams":{}})"), false,
                     CoalesceMode::Merge);
    st4.push_command(other, patch(R"({"skyMaterialParams":{}})"), true, CoalesceMode::Merge);
    CHECK(st4.back().forward.size() == 2);
    CHECK(st4.bytes() == st4.back().bytes);
}

// ---------------------------------------------------------------------------------------- clicks, ranges, the ancestor skip
namespace {
// A tree as the Hierarchy shows it (depth first):  root > (kidA > grand), kidB ; other
const Ids kTree = {"root", "kidA", "grand", "kidB", "other"};
std::string parent_in_tree(const std::string& id) {
    if (id == "kidA" || id == "kidB") return "root";
    if (id == "grand") return "kidA";
    return {};
}
}  // namespace

TEST_CASE("click_in_list: plain replaces, Ctrl toggles, Shift selects the rows between in the order shown") {
    Selection s;
    std::string anchor;
    click_in_list(s, "kidA", {}, anchor, kTree);
    CHECK(s.ids() == Ids{"kidA"});
    CHECK(anchor == "kidA");
    // Shift: the rows from the anchor to the clicked one, over the displayed tree order (grand sits between kidA and kidB)
    click_in_list(s, "kidB", SelectMods{false, true}, anchor, kTree);
    CHECK(s.ids() == Ids{"kidA", "grand", "kidB"});
    CHECK(s.primary() == "kidB");
    CHECK(anchor == "kidA");  // a Shift click keeps the anchor
    // Shift the other way round from the same anchor: replaces the range, it does not extend the old one
    click_in_list(s, "root", SelectMods{false, true}, anchor, kTree);
    CHECK(s.ids() == Ids{"root", "kidA"});
    // Ctrl+Shift adds a range to what is selected
    click_in_list(s, "other", SelectMods{false, false}, anchor, kTree);
    click_in_list(s, "kidA", SelectMods{true, false}, anchor, kTree);
    click_in_list(s, "kidB", SelectMods{true, true}, anchor, kTree);
    CHECK(s.ids() == Ids{"other", "kidA", "grand", "kidB"});
    // Ctrl toggles one row off again
    click_in_list(s, "grand", SelectMods{true, false}, anchor, kTree);
    CHECK_FALSE(s.contains("grand"));
    CHECK(anchor == "grand");
    // a plain click on one of several rows leaves that one only
    click_in_list(s, "other", {}, anchor, kTree);
    CHECK(s.ids() == Ids{"other"});
}

TEST_CASE("click_in_list: the anchor survives two Shift clicks in a row (A, Shift C, Shift B is A..B, not C..B)") {
    Selection s;
    std::string anchor;
    click_in_list(s, "root", {}, anchor, kTree);
    click_in_list(s, "kidB", SelectMods{false, true}, anchor, kTree);
    CHECK(s.ids() == Ids{"root", "kidA", "grand", "kidB"});
    CHECK(s.primary() == "kidB");
    click_in_list(s, "kidA", SelectMods{false, true}, anchor, kTree);
    CHECK(s.ids() == Ids{"root", "kidA"});
    CHECK(anchor == "root");
    CHECK(s.primary() == "kidA");
}

TEST_CASE("Selection: deleting the primary hands the primary to a live id, or leaves the selection empty") {
    Selection s;
    s.add("a");
    s.add("b");
    s.add("c");  // primary c
    CHECK(s.prune([](const std::string& id) { return id != "c"; }) == 1);
    CHECK(s.ids() == Ids{"a", "b"});
    CHECK(s.primary() == "b");
    CHECK(s.prune([](const std::string&) { return false; }) == 2);
    CHECK(s.empty());
    CHECK(s.primary().empty());
}

TEST_CASE("click_in_list: a Shift click with no usable anchor starts from the primary, then from the row itself") {
    Selection s;
    s.replace("kidB");
    std::string anchor = "gone";  // a row that is not shown (collapsed away, deleted)
    click_in_list(s, "root", SelectMods{false, true}, anchor, kTree);
    CHECK(s.ids() == Ids{"root", "kidA", "grand", "kidB"});
    Selection none;
    std::string empty;
    click_in_list(none, "other", SelectMods{false, true}, empty, kTree);
    CHECK(none.ids() == Ids{"other"});
    // a row that is not in the list is selected alone, and an empty id changes nothing
    click_in_list(none, "hidden", SelectMods{false, true}, empty, kTree);
    CHECK(none.ids() == Ids{"hidden"});
    click_in_list(none, "", {}, empty, kTree);
    CHECK(none.ids() == Ids{"hidden"});
}

TEST_CASE("click_in_space: plain replaces, Ctrl toggles, Shift adds") {
    Selection s;
    click_in_space(s, "a", {});
    click_in_space(s, "b", SelectMods{false, true});
    CHECK(s.ids() == Ids{"a", "b"});
    CHECK(s.primary() == "b");
    click_in_space(s, "a", SelectMods{true, false});
    CHECK(s.ids() == Ids{"b"});
    click_in_space(s, "c", {});
    CHECK(s.ids() == Ids{"c"});
}

TEST_CASE("apply_marquee: no modifier replaces (and an empty marquee clears), Shift adds, Ctrl toggles") {
    Selection s;
    s.add("a");
    s.add("b");
    apply_marquee(s, {"c", "d"}, {});
    CHECK(s.ids() == Ids{"c", "d"});
    CHECK(s.primary() == "d");
    apply_marquee(s, {"e", "c"}, SelectMods{false, true});
    CHECK(s.ids() == Ids{"c", "d", "e"});
    apply_marquee(s, {"d", "a"}, SelectMods{true, false});
    CHECK(s.ids() == Ids{"c", "e", "a"});
    apply_marquee(s, {}, SelectMods{true, false});  // Ctrl and nothing covered: unchanged
    CHECK(s.ids() == Ids{"c", "e", "a"});
    apply_marquee(s, {}, {});  // a click on empty space
    CHECK(s.empty());
}

TEST_CASE("without_selected_descendants keeps the order and drops what an ancestor in the set already carries") {
    CHECK(without_selected_descendants({"grand", "root", "other"}, parent_in_tree) == Ids{"root", "other"});
    CHECK(without_selected_descendants({"kidA", "grand"}, parent_in_tree) ==
          Ids{"kidA"});  // not only the direct parent
    CHECK(without_selected_descendants({"kidB", "kidA"}, parent_in_tree) == Ids{"kidB", "kidA"});  // siblings stay
    CHECK(without_selected_descendants({"grand"}, parent_in_tree) == Ids{"grand"});
    CHECK(without_selected_descendants({}, parent_in_tree).empty());
    // a parent_of that loops does not hang
    auto loop = [](const std::string& id) { return id == "x" ? std::string("y") : std::string("x"); };
    CHECK(without_selected_descendants({"x", "y"}, loop).size() <= 2);
}

TEST_CASE(
    "without_selected_descendants follows a reparent of the selection and its undo (the roots are never cached)") {
    // Drag "root" (selected with its subtree and "other") onto "other": hierarchy_reparent moves selection_roots() minus the
    // target, so only "root" moves; its subtree stays selected under it.
    std::map<std::string, std::string> parents = {{"kidA", "root"}, {"kidB", "root"}, {"grand", "kidA"}};
    auto parent_of = [&parents](const std::string& id) {
        const auto it = parents.find(id);
        return it == parents.end() ? std::string() : it->second;
    };
    const Ids selected = {"root", "kidA", "grand", "other"};
    Ids roots = without_selected_descendants(selected, parent_of);
    CHECK(roots == Ids{"root", "other"});
    Ids moving = roots;
    moving.erase(std::remove(moving.begin(), moving.end(), std::string("other")), moving.end());
    CHECK(moving == Ids{"root"});
    for (const std::string& id : moving) parents[id] = "other";
    CHECK(without_selected_descendants(selected, parent_of) ==
          Ids{"other"});                                     // the whole group hangs under "other" now
    for (const std::string& id : moving) parents.erase(id);  // Undo
    CHECK(without_selected_descendants(selected, parent_of) == roots);
    // A selected child dragged out of its selected parent becomes a root of its own.
    parents["grand"] = "";
    CHECK(without_selected_descendants(selected, parent_of) == Ids{"root", "grand", "other"});
}
