// The AI Assistant's data model without a window: chat tabs (open / close / reopen / delete), the files they are saved in,
// the pictures a message carries, and the usage numbers the panel shows. The drawing is ai_panel.cpp and is covered by the
// windowed autotest.
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>

#include "ai_chat.h"
#include "ai_usage.h"
#include "doctest.h"
#include "fa/core/fs.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr i64 kNow = 1760000000;  // a real date: chat ids are made from the local time

struct TempDir {
    stdfs::path dir;
    explicit TempDir(const std::string& name) : dir(fs::make_temp_dir("fa_ai_chat_" + name)) {}
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    std::string str() const { return utf8_string(dir); }
    std::string chats() const { return utf8_string(dir / "chats"); }
};

void write_file(const stdfs::path& p, const std::string& bytes) {
    stdfs::create_directories(p.parent_path());
    std::ofstream out(p, std::ios::binary);
    out.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
}

std::string read_file(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

ChatItem user_item(const std::string& text) {
    ChatItem c;
    c.kind = ChatItem::Kind::User;
    c.text = text;
    return c;
}

// A chat with a message in it (an empty chat is never saved).
AiChat& say(AiChat& chat, const std::string& text, i64 updated) {
    chat.items.push_back(user_item(text));
    if (chat.title.empty()) chat.title = chat_title_from(text);
    chat.updated = updated;
    return chat;
}

}  // namespace

TEST_CASE("chat_title_from shortens the first message to about 24 characters") {
    CHECK(chat_title_from("Fix the jump") == "Fix the jump");
    CHECK(chat_title_from("Fix the player jump when the ground is wet") == "Fix the player jump when...");
    CHECK(chat_title_from("  several \t spaces\n and a second line  ") == "several spaces");
    CHECK(chat_title_from("\n\n  \nthe first line with text\nsecond") == "the first line with text");
    CHECK(chat_title_from("   \n  ").empty());
    CHECK(chat_title_from("twenty-four characters!!") == "twenty-four characters!!");  // exactly 24: not cut
    CHECK(chat_title_from(std::string(30, 'a'), 5) == "aaaaa...");
    // Multi-byte characters are never cut in half.
    std::string thirty, twentyFour;
    for (int i = 0; i < 30; ++i) thirty += "\xC3\xB1";  // n with tilde, two bytes each
    for (int i = 0; i < 24; ++i) twentyFour += "\xC3\xB1";
    CHECK(chat_title_from(thirty) == twentyFour + "...");
}

TEST_CASE("AiChats starts with one blank tab and keeps at least one") {
    AiChats chats;
    REQUIRE(chats.tabs.size() == 1);
    CHECK(chats.current().empty());
    CHECK_FALSE(chats.current().id.empty());

    chats.add(kNow);
    chats.add(kNow);  // same second: the id still differs
    REQUIRE(chats.tabs.size() == 3);
    CHECK(chats.active == 2);
    CHECK(chats.tabs[0].id != chats.tabs[1].id);
    CHECK(chats.tabs[1].id != chats.tabs[2].id);

    CHECK_FALSE(chats.close(7));
    CHECK(chats.close(2));
    CHECK(chats.tabs.size() == 2);
    CHECK(chats.active == 1);
    CHECK(chats.close(0));  // a tab before the active one: the active chat stays the same chat
    REQUIRE(chats.tabs.size() == 1);
    CHECK(chats.active == 0);
    CHECK(chats.close(0));  // the last tab is replaced by a blank one
    REQUIRE(chats.tabs.size() == 1);
    CHECK(chats.current().empty());
}

TEST_CASE("a new tab takes the provider and role of the active one") {
    AiChats chats;
    chats.current().provider = "claude";
    chats.current().role = "worker";
    const AiChat& fresh = chats.add(kNow);
    CHECK(fresh.provider == "claude");
    CHECK(fresh.role == "worker");
    CHECK(fresh.items.empty());
    CHECK(fresh.conversation.empty());
}

TEST_CASE("a chat is saved and loaded with everything the next message needs") {
    TempDir tmp("roundtrip");
    AiChats chats;
    chats.open_dir(tmp.chats());
    AiChat& c = chats.current();
    c.provider = "claude";
    c.role = "fast";
    say(c, "Make the player jump higher", 5000);
    ChatItem img = user_item("with a picture");
    img.images = {".factoria/ai/attachments/shot.png"};
    c.items.push_back(img);
    ChatItem think;
    think.kind = ChatItem::Kind::Thinking;
    think.text = "secret reasoning";
    c.items.push_back(think);
    ChatItem tool;
    tool.kind = ChatItem::Kind::Tool;
    tool.tool = "scene.spawn";
    tool.input = Json::object({{"name", "Coin"}, {"blob", std::string(10000, 'x')}});
    tool.result = Json::object({{"ok", true}});
    tool.done = true;
    c.items.push_back(tool);
    c.conversation.key = "claude";
    c.conversation.cliSessionId = "6d0f1c2e-aaaa-bbbb-cccc-123456789abc";
    c.conversation.cliCostUsd = 0.25;
    c.usage.inputTokens = 100;
    c.usage.outputTokens = 50;
    c.usage.cacheReadTokens = 4000;
    c.costUsd = 0.25;
    c.contextTokens = 47000;
    c.contextWindow = 1000000;
    const std::string id = c.id;
    chats.save(c);
    chats.save_open_list();

    AiChats again;
    again.open_dir(tmp.chats());
    REQUIRE(again.tabs.size() == 1);
    const AiChat& r = again.current();
    CHECK(r.id == id);
    CHECK(r.title == "Make the player jump hig...");
    CHECK(r.updated == 5000);
    CHECK(r.provider == "claude");
    CHECK(r.role == "fast");
    CHECK(r.conversation.key == "claude");
    CHECK(r.conversation.cliSessionId == "6d0f1c2e-aaaa-bbbb-cccc-123456789abc");
    CHECK(r.conversation.cliCostUsd == doctest::Approx(0.25));
    CHECK(r.usage.inputTokens == 100);
    CHECK(r.usage.outputTokens == 50);
    CHECK(r.usage.cacheReadTokens == 4000);
    CHECK(r.costUsd == doctest::Approx(0.25));
    CHECK(r.contextTokens == 47000);
    CHECK(r.contextWindow == 1000000);
    REQUIRE(r.items.size() == 3);  // the reasoning text is not kept
    CHECK(r.items[0].text == "Make the player jump higher");
    CHECK(r.items[1].images == std::vector<std::string>{".factoria/ai/attachments/shot.png"});
    CHECK(r.items[2].kind == ChatItem::Kind::Tool);
    CHECK(r.items[2].done);
    CHECK(r.items[2].input.dump().size() < 4200);  // a file-sized argument is clipped
    CHECK(r.items[2].result.value("ok", false));
}

TEST_CASE("API chats keep their message history, without the picture bytes") {
    TempDir tmp("history");
    AiChats chats;
    chats.open_dir(tmp.chats());
    AiChat& c = chats.current();
    say(c, "hello", 10);
    c.conversation.key = "anthropic/claude-opus";
    ai::ImageData image;
    image.mediaType = "image/png";
    image.base64 = "AAAA";
    c.conversation.history.push_back(ai::Message::user("look at this", {image}));
    chats.save(c);

    AiChats again;
    again.open_dir(tmp.chats());
    REQUIRE(again.reopen(c.id));
    const AiChat* loaded = &again.current();
    REQUIRE(loaded->conversation.history.size() == 1);
    CHECK(loaded->conversation.history[0].images.empty());
    CHECK(loaded->conversation.history[0].text.find("look at this") != std::string::npos);
    CHECK(loaded->conversation.history[0].text.find("not kept") != std::string::npos);
}

TEST_CASE("closing a tab only closes it: the chat stays in History and reopens ready to resume") {
    TempDir tmp("reopen");
    AiChats chats;
    chats.open_dir(tmp.chats());
    AiChat& first = chats.current();
    say(first, "first chat", 100);
    first.conversation.key = "claude";
    first.conversation.cliSessionId = "session-one";
    const std::string firstId = first.id;
    chats.add(kNow);
    say(chats.current(), "second chat", 200);
    chats.save(chats.current());  // a chat is saved after each answer
    const std::string secondId = chats.current().id;
    REQUIRE(chats.tabs.size() == 2);

    CHECK(chats.close(0));
    CHECK(chats.index_of(firstId) < 0);
    REQUIRE(chats.tabs.size() == 1);
    CHECK(chats.current().id == secondId);
    CHECK(stdfs::exists(utf8_path(tmp.chats()) / (firstId + ".json")));

    const auto history = chats.history();
    REQUIRE(history.size() == 2);
    CHECK(history[0].id == secondId);  // newest first
    CHECK(history[1].id == firstId);
    CHECK(history[1].title == "first chat");

    CHECK(chats.reopen(firstId));
    REQUIRE(chats.tabs.size() == 2);
    CHECK(chats.current().id == firstId);
    CHECK(chats.current().conversation.cliSessionId == "session-one");
    CHECK(chats.current().items.size() == 1);

    CHECK(chats.reopen(secondId));  // already open: just switches to it
    CHECK(chats.tabs.size() == 2);
    CHECK(chats.current().id == secondId);
    CHECK_FALSE(chats.reopen("no-such-chat"));
    CHECK(chats.tabs.size() == 2);
}

TEST_CASE("the open tabs come back with the project") {
    TempDir tmp("tabs");
    std::string a, b, c;
    {
        AiChats chats;
        chats.open_dir(tmp.chats());
        say(chats.current(), "alpha", 10);
        a = chats.current().id;
        chats.add(kNow);
        say(chats.current(), "beta", 20);
        b = chats.current().id;
        chats.add(kNow);
        say(chats.current(), "gamma", 30);
        c = chats.current().id;
        for (const auto& t : chats.tabs) chats.save(t);
        chats.close(2);   // gamma is closed: not restored
        chats.add(kNow);  // a blank tab that was never used: not restored either
        chats.select(1);  // the middle one is in front when the editor closes
        chats.save_open_list();
    }
    AiChats again;
    again.open_dir(tmp.chats());
    REQUIRE(again.tabs.size() == 2);
    CHECK(again.tabs[0].id == a);
    CHECK(again.tabs[1].id == b);
    CHECK(again.current().id == b);
    CHECK(again.index_of(c) < 0);
    CHECK(again.history().size() == 3);  // gamma is still in History
}

TEST_CASE("a project that never used the AI gets no files") {
    TempDir tmp("unused");
    AiChats chats;
    chats.open_dir(tmp.chats());
    chats.add(kNow);
    chats.select(0);
    chats.close(1);
    chats.save(chats.current());
    chats.save_open_list();
    CHECK_FALSE(stdfs::exists(utf8_path(tmp.chats())));
    CHECK(chats.history().empty());
}

TEST_CASE("deleting a chat from History removes its file and closes its tab") {
    TempDir tmp("erase");
    AiChats chats;
    chats.open_dir(tmp.chats());
    say(chats.current(), "keep me", 10);
    const std::string keep = chats.current().id;
    chats.add(kNow);
    say(chats.current(), "delete me", 20);
    const std::string doomed = chats.current().id;
    for (const auto& t : chats.tabs) chats.save(t);

    CHECK(chats.erase(doomed));
    CHECK(chats.index_of(doomed) < 0);
    CHECK_FALSE(stdfs::exists(utf8_path(tmp.chats()) / (doomed + ".json")));
    REQUIRE(chats.history().size() == 1);
    CHECK(chats.history()[0].id == keep);
    CHECK_FALSE(chats.erase(doomed));  // already gone

    AiChats again;
    again.open_dir(tmp.chats());
    CHECK(again.index_of(doomed) < 0);
    CHECK(again.index_of(keep) >= 0);
}

TEST_CASE("History lists the newest chat first and survives damaged files") {
    TempDir tmp("order");
    AiChats chats;
    chats.open_dir(tmp.chats());
    AiChat old;
    old.id = "old";
    say(old, "old one", 1000);
    AiChat fresh;
    fresh.id = "fresh";
    say(fresh, "fresh one", 3000);
    AiChat middle;
    middle.id = "middle";
    say(middle, "middle one", 2000);
    chats.save(old);
    chats.save(fresh);
    chats.save(middle);
    write_file(utf8_path(tmp.chats()) / "broken.json", "{ this is not json");
    write_file(utf8_path(tmp.chats()) / "notes.txt", "not a chat");

    const auto history = chats.history();
    REQUIRE(history.size() == 3);
    CHECK(history[0].id == "fresh");
    CHECK(history[1].id == "middle");
    CHECK(history[2].id == "old");
    CHECK(history[0].updated == 3000);
}

TEST_CASE("clear starts the active tab over and deletes its file") {
    TempDir tmp("clear");
    AiChats chats;
    chats.open_dir(tmp.chats());
    say(chats.current(), "forget this", 10);
    chats.current().conversation.cliSessionId = "s";
    chats.save(chats.current());
    const std::string id = chats.current().id;
    REQUIRE(stdfs::exists(utf8_path(tmp.chats()) / (id + ".json")));
    chats.clear();
    CHECK(chats.current().empty());
    CHECK(chats.current().conversation.empty());
    CHECK(chats.current().id == id);
    CHECK_FALSE(stdfs::exists(utf8_path(tmp.chats()) / (id + ".json")));
}

// ---- pictures -----------------------------------------------------------------------------------------------------------

TEST_CASE("only png, jpg, jpeg, gif and webp files can be attached") {
    TempDir tmp("types");
    for (const char* name : {"a.png", "b.jpg", "c.jpeg", "d.gif", "e.webp", "F.PNG"}) {
        write_file(tmp.dir / name, "x");
        CHECK_MESSAGE(attachment_problem(utf8_string(tmp.dir / name)).empty(), name);
    }
    for (const char* name : {"notes.txt", "scene.json", "icon.svg", "photo.bmp", "noext"}) {
        write_file(tmp.dir / name, "x");
        const std::string why = attachment_problem(utf8_string(tmp.dir / name));
        CHECK_MESSAGE(!why.empty(), name);
        CHECK_MESSAGE(why.find("png, jpg, jpeg, gif or webp") != std::string::npos, why);  // says what to use instead
    }
    CHECK(attachment_problem(utf8_string(tmp.dir / "missing.png")).find("not a file") != std::string::npos);
    CHECK(attachment_problem(utf8_string(tmp.dir)).find("not a file") != std::string::npos);  // a folder
    write_file(tmp.dir / "empty.png", "");
    CHECK(attachment_problem(utf8_string(tmp.dir / "empty.png")).find("empty") != std::string::npos);
    write_file(tmp.dir / "huge.png", "x");
    std::error_code ec;
    stdfs::resize_file(tmp.dir / "huge.png", kMaxAttachmentBytes + 1, ec);
    REQUIRE_FALSE(ec);
    CHECK(attachment_problem(utf8_string(tmp.dir / "huge.png")).find("too large") != std::string::npos);
}

TEST_CASE("unique_file_name never reuses a name and keeps names plain ASCII") {
    TempDir tmp("names");
    CHECK(unique_file_name(tmp.str(), "shot.png") == "shot.png");
    write_file(tmp.dir / "shot.png", "x");
    CHECK(unique_file_name(tmp.str(), "shot.png") == "shot-2.png");
    write_file(tmp.dir / "shot-2.png", "x");
    CHECK(unique_file_name(tmp.str(), "shot.png") == "shot-3.png");
    CHECK(unique_file_name(tmp.str(), "my shot (1).PNG") == "my_shot__1_.png");
    CHECK(unique_file_name(tmp.str(), "\xC3\xB1" "and\xC3\xBA.jpg") == "__and__.jpg");
}

TEST_CASE("attaching copies the picture into the project, never touching what is there") {
    TempDir project("attach_project");
    TempDir elsewhere("attach_source");
    write_file(elsewhere.dir / "screenshot.png", "PNGDATA-1");
    const std::string source = utf8_string(elsewhere.dir / "screenshot.png");

    auto first = attach_file(project.str(), source);
    REQUIRE(first);
    CHECK(first->path == ".factoria/ai/attachments/screenshot.png");
    CHECK(first->name == "screenshot.png");
    CHECK(read_file(project.dir / ".factoria" / "ai" / "attachments" / "screenshot.png") == "PNGDATA-1");

    write_file(elsewhere.dir / "screenshot.png", "PNGDATA-2");  // another picture with the same name
    auto second = attach_file(project.str(), source);
    REQUIRE(second);
    CHECK(second->path == ".factoria/ai/attachments/screenshot-2.png");
    CHECK(read_file(project.dir / ".factoria" / "ai" / "attachments" / "screenshot.png") == "PNGDATA-1");
    CHECK(read_file(project.dir / ".factoria" / "ai" / "attachments" / "screenshot-2.png") == "PNGDATA-2");

    write_file(elsewhere.dir / "notes.txt", "hello");
    auto rejected = attach_file(project.str(), utf8_string(elsewhere.dir / "notes.txt"));
    REQUIRE_FALSE(rejected);
    CHECK(rejected.error().message.find("notes.txt") != std::string::npos);
    CHECK_FALSE(stdfs::exists(project.dir / ".factoria" / "ai" / "attachments" / "notes.txt"));
}

TEST_CASE("pasted picture bytes are saved as paste.png, paste-2.png...") {
    TempDir project("paste");
    const std::vector<std::uint8_t> bytes = {0x89, 'P', 'N', 'G', 1, 2, 3};
    auto one = attach_bytes(project.str(), "paste.png", bytes);
    auto two = attach_bytes(project.str(), "paste.png", bytes);
    REQUIRE(one);
    REQUIRE(two);
    CHECK(one->path == ".factoria/ai/attachments/paste.png");
    CHECK(two->path == ".factoria/ai/attachments/paste-2.png");
    CHECK(read_file(project.dir / ".factoria" / "ai" / "attachments" / "paste-2.png").size() == bytes.size());
    CHECK_FALSE(attach_bytes(project.str(), "paste.png", {}));
}

TEST_CASE("selection_line tells the AI which entity this and it mean") {
    CHECK(selection_line("Player", "").empty());
    const std::string line = selection_line("Player", "player_1");
    CHECK(line.find("\"Player\"") != std::string::npos);
    CHECK(line.find("\"player_1\"") != std::string::npos);
    CHECK(line.find('\n') == std::string::npos);  // one short line
    CHECK(selection_line("", "e7").find("\"e7\"") != std::string::npos);
}

namespace {
void put16(std::vector<std::uint8_t>& v, std::uint32_t x) { v.push_back(x & 0xFF); v.push_back((x >> 8) & 0xFF); }
void put32(std::vector<std::uint8_t>& v, std::uint32_t x) { put16(v, x & 0xFFFF); put16(v, x >> 16); }

// BITMAPINFOHEADER (40 bytes) + pixels. bottom-up rows unless height is given negative.
std::vector<std::uint8_t> dib(int w, int h, int bpp, std::uint32_t compression, const std::vector<std::uint8_t>& pixels) {
    std::vector<std::uint8_t> v;
    put32(v, 40);
    put32(v, static_cast<std::uint32_t>(w));
    put32(v, static_cast<std::uint32_t>(h));
    put16(v, 1);
    put16(v, static_cast<std::uint32_t>(bpp));
    put32(v, compression);
    put32(v, static_cast<std::uint32_t>(pixels.size()));
    for (int i = 0; i < 4; ++i) put32(v, 0);  // resolution, palette
    v.insert(v.end(), pixels.begin(), pixels.end());
    return v;
}
}  // namespace

TEST_CASE("image_from_dib reads the bitmaps a Windows screenshot puts on the clipboard") {
    SUBCASE("24 bits per pixel, bottom-up, rows padded to 4 bytes") {
        // 2x2: bottom row first (BGR): blue, white | padding 2 bytes; top row: red, green
        const std::vector<std::uint8_t> px = {255, 0, 0, 255, 255, 255, 0, 0,   //
                                              0, 0, 255, 0, 255, 0, 0, 0};
        const auto bytes = dib(2, 2, 24, 0, px);
        const Image img = image_from_dib(bytes.data(), bytes.size());
        REQUIRE(img.width == 2);
        REQUIRE(img.height == 2);
        const auto at = [&](int x, int y) { return std::vector<int>{img.rgba[(y * 2 + x) * 4], img.rgba[(y * 2 + x) * 4 + 1], img.rgba[(y * 2 + x) * 4 + 2], img.rgba[(y * 2 + x) * 4 + 3]}; };
        CHECK(at(0, 0) == std::vector<int>{255, 0, 0, 255});      // top-left: red
        CHECK(at(1, 0) == std::vector<int>{0, 255, 0, 255});      // top-right: green
        CHECK(at(0, 1) == std::vector<int>{0, 0, 255, 255});      // bottom-left: blue
        CHECK(at(1, 1) == std::vector<int>{255, 255, 255, 255});  // bottom-right: white
    }
    SUBCASE("top-down (negative height)") {
        const std::vector<std::uint8_t> px = {0, 0, 255, 0, 255, 0, 0, 0,   // top row: red, green
                                              255, 0, 0, 255, 255, 255, 0, 0};
        const auto bytes = dib(2, -2, 24, 0, px);
        const Image img = image_from_dib(bytes.data(), bytes.size());
        REQUIRE(img.height == 2);
        CHECK(img.rgba[0] == 255);  // top-left red
        CHECK(img.rgba[1] == 0);
    }
    SUBCASE("32 bits per pixel with every alpha byte 0 means opaque") {
        const std::vector<std::uint8_t> px = {10, 20, 30, 0, 40, 50, 60, 0};  // B G R A, two pixels
        const auto bytes = dib(2, 1, 32, 0, px);
        const Image img = image_from_dib(bytes.data(), bytes.size());
        REQUIRE(img.width == 2);
        CHECK(img.rgba[0] == 30);
        CHECK(img.rgba[1] == 20);
        CHECK(img.rgba[2] == 10);
        CHECK(img.rgba[3] == 255);
        CHECK(img.rgba[7] == 255);
    }
    SUBCASE("32 bits per pixel keeps a real alpha channel") {
        const std::vector<std::uint8_t> px = {10, 20, 30, 128, 40, 50, 60, 255};
        const auto bytes = dib(2, 1, 32, 0, px);
        const Image img = image_from_dib(bytes.data(), bytes.size());
        REQUIRE(img.width == 2);
        CHECK(img.rgba[3] == 128);
        CHECK(img.rgba[7] == 255);
    }
    SUBCASE("anything it cannot read gives an empty image") {
        const std::vector<std::uint8_t> px = {1, 2, 3, 4};
        auto bytes = dib(2, 1, 16, 0, px);  // 16 bits per pixel
        CHECK(image_from_dib(bytes.data(), bytes.size()).width == 0);
        bytes = dib(2, 2, 24, 0, px);  // pixel data too short for 2x2
        CHECK(image_from_dib(bytes.data(), bytes.size()).width == 0);
        bytes = dib(2, 1, 24, 1, px);  // RLE compression
        CHECK(image_from_dib(bytes.data(), bytes.size()).width == 0);
        CHECK(image_from_dib(bytes.data(), 10).width == 0);
        CHECK(image_from_dib(nullptr, 0).width == 0);
    }
}

// ---- usage numbers -------------------------------------------------------------------------------------------------------

TEST_CASE("format_tokens and format_percent are short and honest") {
    CHECK(format_tokens(0) == "0");
    CHECK(format_tokens(950) == "950");
    CHECK(format_tokens(4700) == "4.7k");
    CHECK(format_tokens(5000) == "5k");
    CHECK(format_tokens(47000) == "47k");
    CHECK(format_tokens(470000) == "470k");
    CHECK(format_tokens(1000000) == "1M");
    CHECK(format_tokens(1200000) == "1.2M");
    CHECK(format_percent(0.06) == "6%");
    CHECK(format_percent(0.004) == "<1%");
    CHECK(format_percent(0) == "0%");
    CHECK(format_percent(1.0) == "100%");
    CHECK(format_percent(2.5) == "100%");
    CHECK(format_percent(-1).empty());
}

TEST_CASE("plan windows get readable names and a fixed order") {
    CHECK(limit_label("five_hour") == "Session (5h)");
    CHECK(limit_label("seven_day") == "Week");
    CHECK(limit_label("seven_day_opus") == "Week (opus)");
    CHECK(limit_label("monthly_credits") == "Monthly credits");

    ai::LimitWindow week{"seven_day", 0.2, 100};
    ai::LimitWindow session{"five_hour", 0.1, 50};
    ai::LimitWindow other{"zzz", 0.3, 10};
    ai::LimitWindow opus{"seven_day_opus", 0.3, 10};
    const auto sorted = sorted_limits({other, week, opus, session});
    REQUIRE(sorted.size() == 4);
    CHECK(sorted[0].name == "five_hour");
    CHECK(sorted[1].name == "seven_day");
    CHECK(sorted[2].name == "seven_day_opus");
    CHECK(sorted[3].name == "zzz");
}

TEST_CASE("a plan window whose reset time has passed shows as reset") {
    ai::LimitWindow w;
    w.name = "five_hour";
    w.usedFraction = 0.62;
    w.resetsAt = 10000;

    LimitView before = limit_view(w, 9000);
    CHECK(before.known);
    CHECK(before.used == doctest::Approx(0.62));
    CHECK_FALSE(before.wasReset);
    CHECK(before.label == "Session (5h)");

    LimitView after = limit_view(w, 10001);
    CHECK(after.known);
    CHECK(after.used == 0);
    CHECK(after.wasReset);

    ai::LimitWindow unknown;
    unknown.name = "seven_day";
    unknown.resetsAt = 20000;  // the CLI sent a reset time but no percentage
    LimitView u = limit_view(unknown, 100);
    CHECK_FALSE(u.known);
    CHECK_FALSE(u.wasReset);

    ai::LimitWindow over;
    over.name = "seven_day";
    over.usedFraction = 1.4;
    CHECK(limit_view(over, 100).used == 1.0);
}

TEST_CASE("reset times are shown in local time, shorter when they are close") {
    const auto at = [](int year, int month, int day, int hour, int minute) {
        std::tm tm{};
        tm.tm_year = year - 1900;
        tm.tm_mon = month - 1;
        tm.tm_mday = day;
        tm.tm_hour = hour;
        tm.tm_min = minute;
        tm.tm_isdst = -1;
        return static_cast<i64>(std::mktime(&tm));
    };
    const i64 now = at(2026, 10, 14, 12, 0);  // a Wednesday
    CHECK(format_clock(at(2026, 10, 14, 14, 30), now) == "14:30");
    CHECK(format_clock(at(2026, 10, 16, 18, 0), now) == "Fri 18:00");
    CHECK(format_clock(at(2026, 10, 28, 18, 0), now) == "Oct 28 18:00");
    CHECK(format_clock(0, now).empty());
    CHECK(format_date_time(at(2026, 10, 14, 15, 30)) == "2026-10-14 15:30");
    CHECK(format_date_time(0).empty());
}

TEST_CASE("the last known plan windows are kept per provider between runs") {
    TempDir tmp("limits");
    LimitsByProvider limits;
    limits["claude"].updated = 1234;
    limits["claude"].windows = {{"five_hour", 0.25, 5000}, {"seven_day", 0.5, 90000}};
    limits["codex"].updated = 99;
    limits["codex"].windows = {{"seven_day", -1, 777}};  // reset time only

    const std::string path = limits_path(tmp.str());
    CHECK(path == utf8_string(tmp.dir / ".factoria" / "ai_limits.json"));
    REQUIRE(save_limits(path, limits));

    const LimitsByProvider back = load_limits(path);
    REQUIRE(back.size() == 2);
    REQUIRE(back.count("claude") == 1);
    CHECK(back.at("claude").updated == 1234);
    REQUIRE(back.at("claude").windows.size() == 2);
    CHECK(back.at("claude").windows[0].name == "five_hour");
    CHECK(back.at("claude").windows[0].usedFraction == doctest::Approx(0.25));
    CHECK(back.at("claude").windows[0].resetsAt == 5000);
    CHECK(back.at("claude").windows[1].resetsAt == 90000);
    REQUIRE(back.count("codex") == 1);
    CHECK(back.at("codex").windows[0].usedFraction < 0);  // unknown stays unknown
    CHECK(back.at("codex").windows[0].resetsAt == 777);
}

TEST_CASE("a missing or damaged limits file is just empty") {
    TempDir tmp("limits_bad");
    CHECK(load_limits(utf8_string(tmp.dir / "none.json")).empty());
    write_file(tmp.dir / "bad.json", "{ not json");
    CHECK(load_limits(utf8_string(tmp.dir / "bad.json")).empty());
    write_file(tmp.dir / "odd.json", "[1, 2, 3]");
    CHECK(load_limits(utf8_string(tmp.dir / "odd.json")).empty());
    const Json half = Json::parse(
        "{\"providers\":{\"claude\":{\"windows\":[{\"name\":\"five_hour\",\"usedFraction\":0.5},{\"resetsAt\":5},3]},\"x\":7}}");
    const LimitsByProvider got = limits_from_json(half);
    REQUIRE(got.size() == 1);
    REQUIRE(got.at("claude").windows.size() == 1);  // the unreadable entries are left out
    CHECK(got.at("claude").windows[0].name == "five_hour");
    CHECK(limits_path("").empty());
}
