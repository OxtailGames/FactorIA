// feedback/fixed.json (`feedback fixed add|list`) and the trust-weighted ranking of `feedback collect` for pulled reports.
#include <doctest.h>

#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_fixed.h"
#include "test_helpers.h"
#include "fa_test_paths.h"

using namespace fa;

namespace {
FeedbackFix fix_of(const std::string& category, std::vector<std::string> titles, const std::string& version, const std::string& note = {}) {
    FeedbackFix f;
    f.category = category;
    f.titles = std::move(titles);
    f.fixedIn = version;
    f.note = note;
    return f;
}

// An inbox entry as `feedback pull` writes it.
Json pulled(const std::string& id, const std::string& title, const std::string& category, const std::string& severity, int occurrences,
            const std::string& trust, const std::string& shareId) {
    return Json::object({{"id", id}, {"date", "2026-10-01"}, {"category", category}, {"severity", severity}, {"title", title},
                         {"missing", "Engine lacks " + title}, {"workaround", "(not shared)"}, {"occurrences", occurrences}, {"status", "open"},
                         {"remote", Json::object({{"shareId", shareId}, {"installKey", "k"}, {"trust", trust}})}});
}
void write_install(const testing::TempDir& tmp, const std::string& key, std::vector<Json> entries) {
    Json doc = create_empty_feedback("install-" + key);
    for (auto& e : entries) doc["entries"].push_back(e);
    REQUIRE(save_feedback(tmp.sub(key + "/ENGINE_FEEDBACK.json"), doc).ok());
}
}  // namespace

TEST_CASE("feedback collect: an anonymous installation counts half, a verified one in full, and the report counts installations") {
    testing::TempDir tmp;
    write_install(tmp, "anon1", {pulled("FB-0001", "No one-way platforms", "physics", "major", 5, "anonymous", "r_1")});
    write_install(tmp, "anon2", {pulled("FB-0001", "One-way platforms missing", "physics", "major", 1, "anonymous", "r_2")});
    write_install(tmp, "ver1", {pulled("FB-0001", "No one-way platforms", "physics", "major", 2, "verified", "r_3")});
    write_install(tmp, "solo", {pulled("FB-0001", "Audio cannot loop a sub-range", "audio", "minor", 9, "anonymous", "r_4")});

    auto report = collect_feedback({tmp.str()});
    REQUIRE(report.ok());
    const Json& cl = report->json["clusters"];
    REQUIRE(cl.size() == 2);
    // one-way: anon1 4 x 0.5 x min(5,3) = 6, anon2 4 x 0.5 x 1 = 2, ver1 4 x 1 x 2 = 8 => 16
    CHECK(cl[0]["category"] == "physics");
    CHECK(cl[0]["score"] == 16);
    CHECK(cl[0]["installations"] == 3);
    CHECK(cl[0]["verifiedInstallations"] == 1);
    CHECK(cl[0]["totalOccurrences"] == 8);
    // audio: one anonymous installation, minor (2) x 0.5 x min(9,3) = 3
    CHECK(cl[1]["score"] == 3);
    CHECK(cl[1]["installations"] == 1);
    CHECK(cl[1]["verifiedInstallations"] == 0);

    std::string md = report->markdown();
    CHECK(md.find("**Installations:** 3 (1 verified)") != std::string::npos);
    // "(not shared)" is a placeholder, not a workaround worth showing.
    CHECK(md.find("(not shared)") == std::string::npos);
}

TEST_CASE("feedback collect: a half-trust score keeps its decimal") {
    testing::TempDir tmp;
    write_install(tmp, "a", {pulled("FB-0001", "Particles cannot collide", "particles", "nice-to-have", 1, "anonymous", "r_1")});
    auto report = collect_feedback({tmp.str()});
    REQUIRE(report.ok());
    CHECK(report->json["clusters"][0]["score"] == 0.5);
}

TEST_CASE("feedback fixed: add creates the file, validates, merges and lists") {
    testing::TempDir tmp;
    const std::string path = tmp.sub("feedback/fixed.json");

    auto first = add_fixed_to_file(path, fix_of("physics", {"No one-way platforms"}, "0.11.0", "Collider2D.oneWay"));
    REQUIRE(first.ok());
    CHECK(first->created);
    CHECK_FALSE(first->merged);
    CHECK(first->total == 1);

    auto doc = load_fixed_list_file(path);
    REQUIRE(doc.ok());
    CHECK((*doc)["format"] == kFeedbackFixedFormat);
    CHECK((*doc)["fixes"][0]["titles"][0] == "No one-way platforms");
    CHECK((*doc)["fixes"][0]["fixedIn"] == "0.11.0");
    CHECK((*doc)["fixes"][0]["note"] == "Collider2D.oneWay");
    // No keys beyond the contract: another worker embeds this file.
    CHECK((*doc)["fixes"][0].size() == 4);
    CHECK(doc->size() == 2);

    // Another wording of the same gap in the same version extends the fix.
    auto merged = add_fixed_to_file(path, fix_of("physics", {"no one-way platforms", "One-way platforms missing"}, "0.11.0"));
    REQUIRE(merged.ok());
    CHECK(merged->merged);
    CHECK(merged->total == 1);
    CHECK(merged->fix.titles.size() == 2);
    CHECK(merged->fix.note == "Collider2D.oneWay");  // kept when no new note is given

    // A different version is a different fix; no note leaves the key out.
    auto second = add_fixed_to_file(path, fix_of("audio", {"Audio cannot loop"}, "0.12.0"));
    REQUIRE(second.ok());
    CHECK_FALSE(second->created);
    CHECK(second->total == 2);

    auto list = parse_fixed_list(*load_fixed_list_file(path), path);
    REQUIRE(list.ok());
    REQUIRE(list->size() == 2);
    CHECK((*list)[1].category == "audio");
    CHECK((*list)[1].note.empty());
    CHECK_FALSE((*load_fixed_list_file(path))["fixes"][1].contains("note"));

    // The file ends with exactly one newline.
    std::string text = testing::read_all(path);
    REQUIRE(text.size() > 2);
    CHECK(text.back() == '\n');
    CHECK(text[text.size() - 2] != '\n');
}

TEST_CASE("feedback fixed: bad input teaches") {
    testing::TempDir tmp;
    const std::string path = tmp.sub("fixed.json");
    auto cat = add_fixed_to_file(path, fix_of("physic", {"x title"}, "0.11.0"));
    REQUIRE_FALSE(cat.ok());
    CHECK(cat.error().hint.find("physics") != std::string::npos);
    auto noTitle = add_fixed_to_file(path, fix_of("physics", {" "}, "0.11.0"));
    REQUIRE_FALSE(noTitle.ok());
    CHECK(noTitle.error().hint.find("--title") != std::string::npos);
    auto badVersion = add_fixed_to_file(path, fix_of("physics", {"A title"}, "next"));
    REQUIRE_FALSE(badVersion.ok());
    CHECK(badVersion.error().hint.find("0.11.0") != std::string::npos);
    CHECK_FALSE(std::filesystem::exists(path));  // nothing is created by a refused add

    testing::write_all(path, R"({"format": "other/1", "fixes": []})");
    auto wrongFormat = add_fixed_to_file(path, fix_of("physics", {"A title"}, "0.11.0"));
    REQUIRE_FALSE(wrongFormat.ok());
    CHECK(wrongFormat.error().message.find("format") != std::string::npos);
    CHECK(testing::read_all(path).find("other/1") != std::string::npos);  // the file was not touched

    auto missing = load_fixed_list_file(tmp.sub("nope.json"));
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().hint.find("fixed add") != std::string::npos);
}

TEST_CASE("feedback fixed: the file is found from inside the checkout") {
    testing::TempDir tmp;
    std::filesystem::create_directories(tmp.path / "repo" / ".git");
    std::filesystem::create_directories(tmp.path / "repo" / "feedback");
    std::filesystem::create_directories(tmp.path / "repo" / "tools" / "cli");
    auto found = find_fixed_list_path(tmp.sub("repo/tools/cli"));
    REQUIRE(found.ok());
    CHECK(std::filesystem::path(*found).filename() == "fixed.json");
    CHECK(std::filesystem::path(*found).parent_path().filename() == "feedback");

    std::filesystem::create_directories(tmp.path / "elsewhere");
    auto none = find_fixed_list_path(tmp.sub("elsewhere"));
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().hint.find("--file") != std::string::npos);
}

TEST_CASE("feedback fixed: the list in the repository is valid") {
    auto doc = load_fixed_list_file(std::string(FA_REPO_ROOT) + "/feedback/fixed.json");
    REQUIRE(doc.ok());
    CHECK(parse_fixed_list(*doc).ok());
}
