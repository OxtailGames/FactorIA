// The selection set and the undo entries (selection.h, undo_stack.h): plain data, no window, no engine.
#include "doctest.h"
#include "selection.h"
#include "undo_stack.h"

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
