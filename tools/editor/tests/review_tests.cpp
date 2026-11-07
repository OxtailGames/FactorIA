// The Review window's model (review_model.h), its reader thread (review_loader.h) and the child command job of the Level generator's
// sheet of seeds (child_command_job.h). GPU-free: the window itself is the autotest's section R4.
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <thread>

#include "child_command_job.h"
#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "review_loader.h"
#include "review_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

// A manifest as review.sheet writes it: `count` images in `columns` columns of 100 x 80 cells, every item a candidate file.
Json manifest(int count, int columns, const std::string& kind = "") {
    Json items = Json::array();
    for (int i = 1; i <= count; ++i) {
        const int x = ((i - 1) % columns) * 100, y = ((i - 1) / columns) * 80;
        items.push_back(Json::object({{"n", i},
                                      {"type", "image"},
                                      {"label", "hero_" + std::to_string(i)},
                                      {"source", "art/hero_" + std::to_string(i) + ".png"},
                                      {"info", "64 x 64"},
                                      {"thumb", "thumbs/" + std::to_string(i) + ".png"},
                                      {"ok", true},
                                      {"candidate", true},
                                      {"cell", Json::object({{"x", x}, {"y", y}, {"w", 100}, {"h", 80}})},
                                      {"picture", Json::object({{"x", x + 4}, {"y", y + 4}, {"w", 92}, {"h", 60}})}}));
    }
    const int rows = (count + columns - 1) / columns;
    Json m = Json::object({{"id", "sheet-0003"},
                           {"label", "Which hero?"},
                           {"createdAt", "2026-11-07T10:00:00Z"},
                           {"dropDir", ".factoria/review/dropped"},
                           {"columns", columns},
                           {"rows", rows},
                           {"picture", Json::object({{"path", ".factoria/review/sheet-0003/sheet.png"}, {"width", columns * 100}, {"height", rows * 80}})},
                           {"items", items}});
    if (!kind.empty()) m["meta"] = Json::object({{"kind", kind}, {"slot", "art/hero.png"}, {"command", "assets.generate_image"}});
    return m;
}

void set_env(const char* name, const char* value) {
#if defined(_WIN32)
    _putenv_s(name, value ? value : "");
#else
    if (value) setenv(name, value, 1);
    else unsetenv(name);
#endif
}

void write_png(const stdfs::path& file, int w, int h) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * std::size_t(h) * 4, 200);
    const std::vector<std::uint8_t> png = encode_png(img);
    std::ofstream f(file, std::ios::binary);
    f.write(reinterpret_cast<const char*>(png.data()), std::streamsize(png.size()));
}

}  // namespace

TEST_CASE("review_sheet_view: a manifest as the window draws it, and a broken one never throws") {
    const ReviewSheetView s = review_sheet_view(manifest(5, 3));
    CHECK(s.id == "sheet-0003");
    CHECK(s.picture == ".factoria/review/sheet-0003/sheet.png");
    CHECK(s.columns == 3);
    CHECK(s.rows == 2);
    CHECK(s.width == 300);
    CHECK(s.height == 160);
    REQUIRE(s.items.size() == 5);
    CHECK(s.items[4].n == 5);
    CHECK(s.items[4].x == 104);   // the item's picture rectangle wins over its cell
    CHECK(s.items[4].y == 84);
    CHECK(s.items[4].w == 92);
    CHECK_FALSE(s.is_picked());
    CHECK(s.picked_n() == 0);
    CHECK(s.item(0) == nullptr);
    CHECK(s.item(6) == nullptr);
    REQUIRE(s.item(2) != nullptr);
    CHECK(s.item(2)->label == "hero_2");

    // Wrong types, huge numbers, a string where an object goes: defaults, no exception.
    Json bad = Json::object({{"id", 7}, {"columns", 1e300}, {"items", Json::array({"x", Json::object({{"n", "two"}, {"cell", 3}})})},
                             {"picture", "sheet.png"}, {"meta", Json::array()}, {"picked", true}});
    ReviewSheetView b;
    CHECK_NOTHROW(b = review_sheet_view(bad));
    CHECK(b.id.empty());
    CHECK(b.columns >= 1);
    REQUIRE(b.items.size() == 1);
    CHECK(b.items[0].n == 2);     // the position when `n` is not a number
    CHECK_FALSE(b.is_picked());
    CHECK(b.picture == ".factoria/review//sheet.png");   // no id: the folder's sheet.png, which the reader then does not find
}

TEST_CASE("review_rows: unanswered first, newest first in each group") {
    Json list = Json::object({{"sheets", Json::array({
                                             Json::object({{"id", "sheet-0001"}, {"createdAt", "2026-11-01T00:00:00Z"}, {"count", 4}}),
                                             Json::object({{"id", "sheet-0002"}, {"createdAt", "2026-11-02T00:00:00Z"}, {"count", 4}, {"picked", 2}}),
                                             Json::object({{"id", "sheet-0003"}, {"createdAt", "2026-11-03T00:00:00Z"}, {"count", 6},
                                                           {"meta", Json::object({{"kind", "levelSeeds"}})}}),
                                             Json::object({{"id", "sheet-0004"}, {"createdAt", "2026-11-04T00:00:00Z"}, {"picked", 1}}),
                                             Json::object({{"label", "no id"}}),
                                         })}});
    const std::vector<ReviewListRow> rows = review_rows(list);
    REQUIRE(rows.size() == 4);
    CHECK(rows[0].id == "sheet-0003");
    CHECK(rows[0].kind == "levelSeeds");
    CHECK(rows[1].id == "sheet-0001");
    CHECK(rows[2].id == "sheet-0004");
    CHECK(rows[3].id == "sheet-0002");
    CHECK(rows[3].picked == 2);
    CHECK(review_rows(Json::array()).empty());
}

TEST_CASE("review keys: digits and arrows over the grid") {
    // 1 2 3
    // 4 5
    CHECK(review_move_selection(0, 5, 3, ReviewMove::Right) == 1);   // nothing selected: the first
    CHECK(review_move_selection(1, 5, 3, ReviewMove::Right) == 2);
    CHECK(review_move_selection(1, 5, 3, ReviewMove::Left) == 1);    // stops at the start
    CHECK(review_move_selection(5, 5, 3, ReviewMove::Right) == 5);   // and at the end
    CHECK(review_move_selection(2, 5, 3, ReviewMove::Down) == 5);
    CHECK(review_move_selection(3, 5, 3, ReviewMove::Down) == 3);    // nothing under it in the short last row
    CHECK(review_move_selection(4, 5, 3, ReviewMove::Up) == 1);
    CHECK(review_move_selection(1, 5, 3, ReviewMove::Up) == 1);
    CHECK(review_move_selection(3, 0, 3, ReviewMove::Down) == 0);
    CHECK(review_move_selection(2, 5, 0, ReviewMove::Down) == 3);    // a broken column count acts as one column
    CHECK(review_digit_selection(3, 5) == 3);
    CHECK(review_digit_selection(6, 5) == 0);
    CHECK(review_digit_selection(0, 5) == 0);
    CHECK(review_digit_selection(10, 20) == 0);
}

TEST_CASE("review sizes: fit, upload and the PNG header") {
    CHECK(review_fit_scale(1000, 500, 500, 500) == doctest::Approx(0.5));
    CHECK(review_fit_scale(10, 10, 500, 500) == doctest::Approx(2.0));        // capped
    CHECK(review_fit_scale(0, 10, 500, 500) == doctest::Approx(1.0));
    int w = 0, h = 0;
    review_upload_size(8192, 4096, kReviewSheetMaxSide, w, h);
    CHECK(w == 4096);
    CHECK(h == 2048);
    review_upload_size(8192, 3, 512, w, h);
    CHECK(w == 512);
    CHECK(h == 1);                                                            // never 0
    review_upload_size(300, 200, 512, w, h);
    CHECK(w == 300);
    CHECK(h == 200);

    Image img;
    img.width = 7;
    img.height = 3;
    img.rgba.assign(7 * 3 * 4, 255);
    const std::vector<std::uint8_t> png = encode_png(img);
    const auto size = review_png_size(png.data(), png.size());
    REQUIRE(size.has_value());
    CHECK(size->first == 7);
    CHECK(size->second == 3);
    CHECK_FALSE(review_png_size(png.data(), 20).has_value());
    const std::uint8_t junk[24] = {1, 2, 3};
    CHECK_FALSE(review_png_size(junk, sizeof(junk)).has_value());
}

TEST_CASE("review_pick_plan: the command, its arguments and the files it moves") {
    ReviewSheetView s = review_sheet_view(manifest(4, 2));
    ReviewPickPlan p = review_pick_plan(s, 3, true, "the brightest");
    CHECK(p.error.empty());
    CHECK(p.command == "review.pick");
    CHECK(p.canKeepFiles);
    CHECK(p.args["sheet"] == "sheet-0003");
    CHECK(p.args["n"] == 3);
    CHECK(p.args["drop"] == true);
    CHECK(p.args["note"] == "the brightest");
    REQUIRE(p.moves.size() == 3);
    CHECK(p.moves[0].n == 1);
    CHECK(p.moves[0].from == "art/hero_1.png");
    CHECK(p.moves[0].to.rfind(".factoria/review/dropped/sheet-0003/", 0) == 0);

    // Keep the other files: drop false, nothing moves.
    p = review_pick_plan(s, 3, false, "");
    CHECK(p.args["drop"] == false);
    CHECK_FALSE(p.args.contains("note"));
    CHECK(p.moves.empty());

    // A file shared by two items moves once; the picked item's own file never moves.
    Json m = manifest(4, 2);
    m["items"][1]["source"] = "art/hero_1.png";
    m["items"][3]["source"] = "art/hero_3.png";
    s = review_sheet_view(m);
    p = review_pick_plan(s, 3, true, "");
    REQUIRE(p.moves.size() == 1);
    CHECK(p.moves[0].n == 1);

    // What cannot be asked.
    CHECK_FALSE(review_pick_plan(s, 9, true, "").error.empty());
    m["items"][1]["ok"] = false;
    CHECK(review_pick_plan(review_sheet_view(m), 2, true, "").error.find("failed") != std::string::npos);
    m["picked"] = Json::object({{"n", 1}});
    const ReviewPickPlan answered = review_pick_plan(review_sheet_view(m), 2, true, "");
    CHECK(answered.error.find("already answered") != std::string::npos);

    // A long note is cut to what review.pick takes.
    CHECK(review_pick_plan(review_sheet_view(manifest(2, 2)), 1, true, std::string(900, 'x')).args["note"].get<std::string>().size() == 500);
}

TEST_CASE("review_pick_plan: a sheet of asset candidates is answered by assets.pick with its slot") {
    ReviewSheetView s = review_sheet_view(manifest(3, 3, "assetCandidates"));
    CHECK(s.kind == "assetCandidates");
    CHECK(s.slot == "art/hero.png");
    const ReviewPickPlan p = review_pick_plan(s, 2, true, "warm colours");
    CHECK(p.error.empty());
    CHECK(p.command == "assets.pick");
    CHECK_FALSE(p.canKeepFiles);
    CHECK(p.args["slot"] == "art/hero.png");
    CHECK(p.args["n"] == 2);
    CHECK(p.args["note"] == "warm colours");
    CHECK_FALSE(p.args.contains("drop"));
    s.slot.clear();
    CHECK(review_pick_plan(s, 2, true, "").error.find("slot") != std::string::npos);
}

TEST_CASE("review_superseded_by: only the newest sheet of candidates of a slot can be picked") {
    const auto row = [](const char* id, const char* at, const char* kind, const char* slot, int picked) {
        Json meta = Json::object({{"kind", kind}});
        if (*slot) meta["slot"] = slot;
        return Json::object({{"id", id}, {"createdAt", at}, {"count", 3}, {"picked", picked}, {"meta", meta}});
    };
    const Json list = Json::object({{"sheets", Json::array({
                                                   row("sheet-0001", "2026-11-01T00:00:00Z", "assetCandidates", "art/hero.png", 0),
                                                   row("sheet-0002", "2026-11-02T00:00:00Z", "assetCandidates", "art/hero.png", 0),
                                                   row("sheet-0003", "2026-11-03T00:00:00Z", "assetCandidates", "art/tree.png", 0),
                                                   row("sheet-0004", "2026-11-04T00:00:00Z", "levelSeeds", "", 0),
                                                   row("sheet-0005", "2026-11-02T00:00:00Z", "assetCandidates", "art/hero.png", 0),
                                               })}});
    const std::vector<ReviewListRow> rows = review_rows(list);
    REQUIRE(rows.size() == 5);
    CHECK(rows[0].slot.empty());
    const auto view = [&](const char* id) {
        ReviewSheetView s;
        for (const ReviewListRow& r : rows)
            if (r.id == id) {
                s.id = r.id;
                s.createdAt = r.createdAt;
                s.kind = r.kind;
                s.slot = r.slot;
            }
        return s;
    };
    // sheet-0005 was made in the same second as sheet-0002: the id breaks the tie, so 0005 is the newest of art/hero.png.
    CHECK(review_superseded_by(rows, view("sheet-0001")) == "sheet-0005");
    CHECK(review_superseded_by(rows, view("sheet-0002")) == "sheet-0005");
    CHECK(review_superseded_by(rows, view("sheet-0005")).empty());
    CHECK(review_superseded_by(rows, view("sheet-0003")).empty());   // another slot
    CHECK(review_superseded_by(rows, view("sheet-0004")).empty());   // not candidates
    ReviewSheetView answered = view("sheet-0001");
    answered.picked = Json::object({{"n", 1}});
    CHECK(review_superseded_by(rows, answered).empty());              // an answered sheet is read-only anyway
}

TEST_CASE("review_history_row: who, when, the note and each dropped file's status") {
    CHECK_FALSE(review_history_row(manifest(3, 3)).has_value());
    Json m = manifest(3, 3);
    m["picked"] = Json::object({{"n", 2},
                                {"who", "person"},
                                {"at", "2026-11-07T11:00:00Z"},
                                {"atUnix", 1794049200},
                                {"note", "rounder"},
                                {"dropped", Json::array({Json::object({{"n", 1}, {"from", "art/hero_1.png"}, {"to", "x/1.png"}}),
                                                         Json::object({{"n", 3}, {"from", "art/hero_3.png"}, {"to", "x/3.png"}, {"status", "expired"}})})}});
    const auto h = review_history_row(m);
    REQUIRE(h.has_value());
    CHECK(h->n == 2);
    CHECK(h->who == "person");
    CHECK(h->note == "rounder");
    CHECK(h->pickedLabel == "hero_2");   // from the items when the pick has no label
    CHECK(h->count == 3);
    REQUIRE(h->dropped.size() == 2);
    CHECK(h->dropped[0].status == "moved");
    CHECK(h->dropped[1].status == "expired");

    std::vector<ReviewHistoryRow> rows(3);
    rows[0].id = "a";
    rows[0].atUnix = 10;
    rows[1].id = "b";
    rows[1].atUnix = 30;
    rows[2].id = "c";
    rows[2].atUnix = 20;
    review_sort_history(rows);
    CHECK(rows[0].id == "b");
    CHECK(rows[2].id == "a");
}

TEST_CASE("review_level_seeds_args: one level item with N seeds, and the pick brings the options back") {
    LevelGenOptions o;
    o.sampleFile = "levels/sample.json";
    o.width = 32;
    o.height = 18;
    o.seed = 41;
    o.extra = R"({"maxAttempts": 3})";
    auto args = review_level_seeds_args(o, 4, "");
    REQUIRE(args.ok());
    const Json& item = args.value()["items"][0];
    CHECK_FALSE(item["level"].contains("seed"));
    CHECK(item["seeds"] == Json::array({41, 42, 43, 44}));
    CHECK(item["level"]["maxAttempts"] == 3);
    CHECK(args.value()["meta"]["kind"] == "levelSeeds");
    CHECK(args.value()["meta"]["sampleFile"] == "levels/sample.json");

    // The seeds wrap after the largest one.
    o.seed = kLevelGenMaxSeed;
    args = review_level_seeds_args(o, 2, "");
    REQUIRE(args.ok());
    CHECK(args.value()["items"][0]["seeds"] == Json::array({kLevelGenMaxSeed, 0}));

    // What is refused.
    CHECK_FALSE(review_level_seeds_args(o, 1, "").ok());
    CHECK_FALSE(review_level_seeds_args(o, kReviewSeedsMax + 1, "").ok());
    LevelGenOptions big = o;
    big.width = kReviewLevelMaxSide + 1;
    CHECK_FALSE(review_level_seeds_args(big, 4, "").ok());
    LevelGenOptions entity;
    entity.sampleEntity = "drawn";
    CHECK_FALSE(review_level_seeds_args(entity, 4, "").ok());   // the scene it is in has no file yet
    auto withScene = review_level_seeds_args(entity, 4, "scenes/main.scene.json");
    REQUIRE(withScene.ok());
    CHECK(withScene.value()["items"][0]["sampleScene"] == "scenes/main.scene.json");
    CHECK(withScene.value()["meta"]["sampleEntity"] == "drawn");

    // The pick of the third thumbnail: its spec.level carries the seed and the options.
    Json level = Json::object({{"sample", "levels/sample.json"}, {"size", Json::array({32, 18})}, {"seed", 43}, {"model", "tiled"},
                               {"n", 2}, {"symmetry", 4}, {"periodic", true}, {"maxAttempts", 3}});
    const Json picked = Json::object({{"n", 3}, {"spec", Json::object({{"level", level}})}});
    CHECK(review_picked_level_seed(picked) == 43);
    LevelGenOptions back;
    back.sampleEntity = "other";
    REQUIRE(review_level_options_from_pick(picked, Json::object({{"kind", "levelSeeds"}, {"sampleFile", "levels/sample.json"}}), back));
    CHECK(back.sampleFile == "levels/sample.json");
    CHECK(back.seed == 43);
    CHECK(back.width == 32);
    CHECK(back.height == 18);
    CHECK(back.model == "tiled");
    CHECK(back.n == 2);
    CHECK(back.symmetry == 4);
    CHECK(back.periodic);
    CHECK(parse_json(back.extra, "extra").value() == Json::object({{"maxAttempts", 3}}));
    // Not a sheet of seeds, or not a level: untouched.
    LevelGenOptions same;
    CHECK_FALSE(review_level_options_from_pick(picked, Json::object(), same));
    CHECK_FALSE(review_level_options_from_pick(Json::object({{"n", 1}}), Json::object({{"kind", "levelSeeds"}, {"sampleFile", "a.json"}}), same));
    CHECK(same.seed == LevelGenOptions{}.seed);
}

TEST_CASE("review_read_picture and ReviewLoader: a picture in a folder with accents, shrunk; a missing one is an error") {
    const stdfs::path dir = fs::make_temp_dir("fa_review_loader") / stdfs::path(u8"revisió");
    stdfs::create_directories(dir);
    const stdfs::path file = dir / stdfs::path(u8"càndid.png");
    write_png(file, 600, 300);

    auto img = review_read_picture(file, 200);
    REQUIRE(img.ok());
    CHECK(img->width == 200);
    CHECK(img->height == 100);
    CHECK_FALSE(review_read_picture(dir / "missing.png", 200).ok());
    {
        std::ofstream f(dir / "junk.png", std::ios::binary);
        f << "not a picture";
    }
    CHECK_FALSE(review_read_picture(dir / "junk.png", 200).ok());

    ReviewLoader loader;
    loader.request_picture("a", file, 128, true, 7);
    loader.request_picture("b", dir / "missing.png", 128, false, 7);
    std::vector<ReviewLoaded> got;
    const auto start = std::chrono::steady_clock::now();
    while (got.size() < 2 && std::chrono::steady_clock::now() - start < std::chrono::seconds(60)) {
        for (ReviewLoaded& r : loader.take()) got.push_back(std::move(r));
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    REQUIRE(got.size() == 2);
    for (const ReviewLoaded& r : got) {
        CHECK(r.gen == 7);
        CHECK(r.kind == ReviewLoaded::Kind::Picture);
        if (r.key == "a") {
            CHECK(r.error.empty());
            CHECK(r.picture.width == 128);
            CHECK(r.picture.height == 64);
        } else {
            CHECK_FALSE(r.error.empty());
        }
    }
    CHECK_FALSE(loader.reading_project_file());
    loader.stop();
    CHECK_FALSE(loader.busy());
    std::error_code ec;
    stdfs::remove_all(dir.parent_path(), ec);
}

TEST_CASE("child_command_outcome and ChildCommandJob: a result, a command error, garbage, a cancel, no factoria") {
    ProcessResult run;
    run.exitCode = 0;
    ChildCommandOutcome o = child_command_outcome(run, R"({"sheet":"sheet-0002","count":6})", "review.sheet");
    CHECK(o.ok);
    CHECK(o.value["sheet"] == "sheet-0002");
    o = child_command_outcome(run, R"({"ok":false,"error":{"code":"busy","message":"No sample.","hint":"Draw one."}})", "review.sheet");
    CHECK_FALSE(o.ok);
    CHECK(o.error == "No sample.");
    CHECK(o.hint == "Draw one.");
    CHECK(o.code == "busy");   // the window tells a file open elsewhere ("busy") and an older sheet ("superseded") apart
    o = child_command_outcome(run, R"({"ok":false,"error":{"message":5}})", "review.sheet");   // a wrong type is not an exception
    CHECK_FALSE(o.ok);
    CHECK(o.error == "review.sheet failed.");
    run.exitCode = 3;
    run.stderrText = "boom";
    o = child_command_outcome(run, "garbage", "review.sheet");
    CHECK_FALSE(o.ok);
    CHECK(o.error.find("boom") != std::string::npos);
    run.cancelled = true;
    CHECK(child_command_outcome(run, "", "review.sheet").cancelled);
    run.cancelled = false;
    run.timedOut = true;
    CHECK(child_command_outcome(run, "", "review.sheet").error.find("did not finish") != std::string::npos);

    const stdfs::path dir = fs::make_temp_dir("fa_child_command");
    set_env("FA_FACTORIA_EXE", (dir / "missing").string().c_str());   // ASCII temp path: getenv's native form
    ChildCommandJob job;
    CHECK(job.start(dir, "review.sheet", Json::object(), 60));
    auto out = job.take_result();
    REQUIRE(out.has_value());
    CHECK_FALSE(out->ok);
    CHECK(out->error.find("not found") != std::string::npos);
    CHECK_FALSE(job.take_result().has_value());
    set_env("FA_FACTORIA_EXE", nullptr);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}
