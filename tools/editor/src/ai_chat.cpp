#include "ai_chat.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <iterator>

#include "fa/core/strings.h"
#include "fa/core/utf8.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

// Paths in the editor are UTF-8 strings (sokol hands out dropped files that way). std::filesystem::path(std::string)
// would read them in the Windows ANSI code page, so build the path from a u8string.
stdfs::path utf8_path(const std::string& s) {
    return stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(s.data()), s.size()));
}
std::string utf8_string(const stdfs::path& p) {
    const std::u8string u = p.u8string();
    return std::string(reinterpret_cast<const char*>(u.data()), u.size());
}

std::tm local_tm(i64 epoch, bool* ok) {
    std::time_t t = static_cast<std::time_t>(epoch);
    std::tm tm{};
#ifdef _WIN32
    const bool good = localtime_s(&tm, &t) == 0;
#else
    const bool good = localtime_r(&t, &tm) != nullptr;
#endif
    if (ok) *ok = good;
    return tm;
}

// fa::load_json_file would read the path in the Windows ANSI code page
std::optional<Json> read_json(const std::string& path) {
    std::ifstream in(utf8_path(path), std::ios::binary);
    if (!in) return std::nullopt;
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    Json j = Json::parse(text, nullptr, false);
    if (j.is_discarded() || !j.is_object()) return std::nullopt;
    return j;
}

bool write_json(const std::string& path, const Json& j) {
    std::error_code ec;
    stdfs::create_directories(utf8_path(path).parent_path(), ec);
    std::ofstream out(utf8_path(path), std::ios::binary | std::ios::trunc);
    if (out) out << j.dump(1, ' ', false, Json::error_handler_t::replace) << "\n";
    return static_cast<bool>(out);
}

namespace {

const char* kind_name(ChatItem::Kind k) {
    switch (k) {
        case ChatItem::Kind::User: return "user";
        case ChatItem::Kind::Assistant: return "assistant";
        case ChatItem::Kind::Thinking: return "thinking";
        case ChatItem::Kind::Tool: return "tool";
        case ChatItem::Kind::Info: return "info";
        case ChatItem::Kind::Error: return "error";
        case ChatItem::Kind::Run: return "run";
        case ChatItem::Kind::Revert: return "revert";
    }
    return "info";
}

ChatItem::Kind kind_from(const std::string& s) {
    for (auto k : {ChatItem::Kind::User, ChatItem::Kind::Assistant, ChatItem::Kind::Thinking, ChatItem::Kind::Tool,
                   ChatItem::Kind::Info, ChatItem::Kind::Error, ChatItem::Kind::Run, ChatItem::Kind::Revert}) {
        if (s == kind_name(k)) return k;
    }
    return ChatItem::Kind::Info;
}

std::string str_of(const Json& j, const char* key) {
    auto it = j.find(key);
    return (j.is_object() && it != j.end() && it->is_string()) ? it->get<std::string>() : std::string();
}
double num_of(const Json& j, const char* key) {
    auto it = j.find(key);
    return (j.is_object() && it != j.end() && it->is_number()) ? it->get<double>() : 0.0;
}

// A tool's arguments or result can be a whole file: a saved chat keeps the start of it.
Json clipped(const Json& j) {
    constexpr std::size_t kMax = 4000;
    if (j.is_null()) return j;
    std::string text = j.dump(-1, ' ', false, Json::error_handler_t::replace);
    if (text.size() <= kMax) return j;
    return j.is_string() ? Json(j.get<std::string>().substr(0, kMax) + "...") : Json(text.substr(0, kMax) + "...");
}

ai::Usage usage_from(const Json& j) {
    ai::Usage u;
    u.inputTokens = static_cast<u64>(num_of(j, "inputTokens"));
    u.outputTokens = static_cast<u64>(num_of(j, "outputTokens"));
    u.cacheCreationTokens = static_cast<u64>(num_of(j, "cacheCreationTokens"));
    u.cacheReadTokens = static_cast<u64>(num_of(j, "cacheReadTokens"));
    return u;
}

std::string local_stamp(i64 now) {
    bool ok = false;
    const std::tm tm = local_tm(now, &ok);
    char buf[32];
    if (!ok || std::strftime(buf, sizeof buf, "%Y%m%d-%H%M%S", &tm) == 0) return "chat-" + std::to_string(now);  // no clock: still unique
    return buf;
}

constexpr const char* kChatFormat = "factoria.ai_chat/1";
constexpr const char* kOpenFormat = "factoria.ai_chats_open/1";
constexpr const char* kOpenFile = "open";

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// ChatItem / AiChat <-> JSON

Json ChatItem::to_json() const {
    Json j = Json::object({{"kind", kind_name(kind)}});
    if (!text.empty()) j["text"] = text;
    if (!tool.empty()) j["tool"] = tool;
    if (!input.is_null()) j["input"] = clipped(input);
    if (!result.is_null()) j["result"] = clipped(result);
    if (done) j["done"] = true;
    if (isError) j["isError"] = true;
    if (depth) j["depth"] = depth;
    if (!role.empty()) j["role"] = role;
    if (!images.empty()) j["images"] = images;
    if (!checkpointId.empty()) j["checkpoint"] = checkpointId;
    if (!modified.empty()) j["modified"] = modified;
    if (!added.empty()) j["added"] = added;
    if (!deleted.empty()) j["deleted"] = deleted;
    if (omitted) j["omitted"] = omitted;
    if (sceneChanged) j["sceneChanged"] = true;
    if (!revertedBy.empty()) j["revertedBy"] = revertedBy;
    if (!safetyId.empty()) j["safety"] = safetyId;
    if (undone) j["undone"] = true;
    if (isUndo) j["isUndo"] = true;
    return j;
}

ChatItem ChatItem::from_json(const Json& j) {
    ChatItem c;
    c.kind = kind_from(str_of(j, "kind"));
    c.text = str_of(j, "text");
    c.tool = str_of(j, "tool");
    if (j.contains("input")) c.input = j["input"];
    if (j.contains("result")) c.result = j["result"];
    c.done = j.value("done", false);
    c.isError = j.value("isError", false);
    c.depth = j.value("depth", 0);
    c.role = str_of(j, "role");
    if (j.contains("images") && j["images"].is_array()) {
        for (const auto& i : j["images"]) {
            if (i.is_string()) c.images.push_back(i.get<std::string>());
        }
    }
    auto strings = [&](const char* key, std::vector<std::string>& out) {
        if (!j.contains(key) || !j[key].is_array()) return;
        for (const auto& v : j[key]) {
            if (v.is_string()) out.push_back(v.get<std::string>());
        }
    };
    strings("modified", c.modified);
    strings("added", c.added);
    strings("deleted", c.deleted);
    c.checkpointId = str_of(j, "checkpoint");
    c.omitted = j.value("omitted", 0);
    c.sceneChanged = j.value("sceneChanged", false);
    c.revertedBy = str_of(j, "revertedBy");
    c.safetyId = str_of(j, "safety");
    c.undone = j.value("undone", false);
    c.isUndo = j.value("isUndo", false);
    return c;
}

Json AiChat::to_json() const {
    Json its = Json::array();
    for (const auto& it : items) {
        if (it.kind != ChatItem::Kind::Thinking) its.push_back(it.to_json());  // reasoning text is bulky and not worth keeping
    }
    return Json::object({{"format", kChatFormat},
                         {"id", id},
                         {"title", title},
                         {"created", created},
                         {"updated", updated},
                         {"conversation", conversation.to_json()},
                         {"usage", usage.to_json()},
                         {"costUsd", costUsd},
                         {"contextTokens", contextTokens},
                         {"contextWindow", contextWindow},
                         {"items", its}});
}

AiChat AiChat::from_json(const Json& j) {
    AiChat c;
    c.id = str_of(j, "id");
    c.title = str_of(j, "title");
    c.created = static_cast<i64>(num_of(j, "created"));
    c.updated = static_cast<i64>(num_of(j, "updated"));
    if (j.contains("conversation") && j["conversation"].is_object()) c.conversation = ai::Conversation::from_json(j["conversation"]);
    if (j.contains("usage")) c.usage = usage_from(j["usage"]);
    c.costUsd = num_of(j, "costUsd");
    c.contextTokens = static_cast<u64>(num_of(j, "contextTokens"));
    c.contextWindow = static_cast<u64>(num_of(j, "contextWindow"));
    if (j.contains("items") && j["items"].is_array()) {
        for (const auto& it : j["items"]) c.items.push_back(ChatItem::from_json(it));
    }
    return c;
}

// ---------------------------------------------------------------------------------------------------------------------
// AiChats

std::string AiChats::path_of(const std::string& id) const { return utf8_string(utf8_path(dir) / (id + ".json")); }

std::string AiChats::make_id(i64 now) const {
    const std::string base = local_stamp(now);
    std::string id = base;
    for (int n = 2; index_of(id) >= 0 || (!dir.empty() && stdfs::exists(utf8_path(path_of(id)))); ++n) id = base + "-" + std::to_string(n);
    return id;
}

AiChat* AiChats::find(const std::string& id) {
    const int i = index_of(id);
    return i < 0 ? nullptr : &tabs[static_cast<std::size_t>(i)];
}

int AiChats::index_of(const std::string& id) const {
    for (std::size_t i = 0; i < tabs.size(); ++i) {
        if (tabs[i].id == id) return static_cast<int>(i);
    }
    return -1;
}

namespace {
// Tabs need an id from the start (it keys the widgets and the running chat), so a blank chat gets one when it is made.
AiChat blank_chat(const std::string& id, i64 now) {
    AiChat c;
    c.id = id;
    c.created = c.updated = now;
    return c;
}
}  // namespace

AiChats::AiChats() {
    const i64 now = static_cast<i64>(std::time(nullptr));
    tabs.push_back(blank_chat(make_id(now), now));
}

void AiChats::open_dir(const std::string& chatsDir) {
    dir = chatsDir;
    tabs.clear();
    active = 0;
    std::string activeId;
    if (!dir.empty()) {
        if (auto open = read_json(path_of(kOpenFile)); open && open->contains("open") && (*open)["open"].is_array()) {
            for (const auto& id : (*open)["open"]) {
                if (!id.is_string() || index_of(id.get<std::string>()) >= 0) continue;
                auto chat = read_json(path_of(id.get<std::string>()));
                if (!chat) continue;
                AiChat c = AiChat::from_json(*chat);
                c.id = id.get<std::string>();  // the file name is the id
                tabs.push_back(std::move(c));
            }
            activeId = str_of(*open, "active");
        }
    }
    if (tabs.empty()) {
        const i64 now = static_cast<i64>(std::time(nullptr));
        tabs.push_back(blank_chat(make_id(now), now));
    }
    const int a = index_of(activeId);
    active = a >= 0 ? a : static_cast<int>(tabs.size()) - 1;
}

AiChat& AiChats::add(i64 now) {
    tabs.push_back(blank_chat(make_id(now), now));
    active = static_cast<int>(tabs.size()) - 1;
    return tabs.back();
}

void AiChats::select(int index) {
    if (index < 0 || index >= static_cast<int>(tabs.size()) || index == active) return;
    active = index;
    save_open_list();
}

bool AiChats::close(int index) {
    if (index < 0 || index >= static_cast<int>(tabs.size())) return false;
    save(tabs[static_cast<std::size_t>(index)]);
    tabs.erase(tabs.begin() + index);
    if (tabs.empty()) {
        const i64 now = static_cast<i64>(std::time(nullptr));
        tabs.push_back(blank_chat(make_id(now), now));
        active = 0;
    } else {
        if (index < active) --active;  // the neighbour that moved into this slot becomes active when it was the active one
        active = std::min(active, static_cast<int>(tabs.size()) - 1);
    }
    save_open_list();
    return true;
}

bool AiChats::reopen(const std::string& id) {
    if (const int i = index_of(id); i >= 0) {
        active = i;
        save_open_list();
        return true;
    }
    if (dir.empty()) return false;
    auto chat = read_json(path_of(id));
    if (!chat) return false;
    AiChat c = AiChat::from_json(*chat);
    c.id = id;
    tabs.push_back(std::move(c));
    active = static_cast<int>(tabs.size()) - 1;
    save_open_list();
    return true;
}

bool AiChats::erase(const std::string& id) {
    bool existed = false;
    if (!dir.empty()) {
        std::error_code ec;
        existed = stdfs::remove(utf8_path(path_of(id)), ec);
    }
    const int i = index_of(id);
    if (i >= 0) {
        tabs[static_cast<std::size_t>(i)].items.clear();  // nothing left to save: close() writes no file
        close(i);
        existed = true;
    }
    save_open_list();
    return existed;
}

void AiChats::clear() {
    AiChat& c = current();
    if (!dir.empty()) {
        std::error_code ec;
        stdfs::remove(utf8_path(path_of(c.id)), ec);
    }
    c = blank_chat(c.id, static_cast<i64>(std::time(nullptr)));
    save_open_list();
}

void AiChats::save(const AiChat& chat) const {
    if (dir.empty() || chat.empty()) return;
    write_json(path_of(chat.id), chat.to_json());
}

void AiChats::save_open_list() const {
    if (dir.empty()) return;
    Json ids = Json::array();
    for (const auto& t : tabs) {
        if (!t.empty()) ids.push_back(t.id);
    }
    std::error_code ec;
    if (ids.empty() && !stdfs::exists(utf8_path(path_of(kOpenFile)), ec)) return;  // never used the AI here: write nothing
    const AiChat& a = current();
    write_json(path_of(kOpenFile), Json::object({{"format", kOpenFormat}, {"open", ids}, {"active", a.empty() ? "" : a.id}}));
}

std::vector<ChatHistoryEntry> AiChats::history() const {
    std::vector<ChatHistoryEntry> out;
    if (dir.empty()) return out;
    std::error_code ec;
    for (stdfs::directory_iterator it(utf8_path(dir), ec), end; !ec && it != end; it.increment(ec)) {
        const stdfs::path& p = it->path();
        if (p.extension() != ".json" || p.stem() == kOpenFile) continue;
        auto chat = read_json(utf8_string(p));
        if (!chat) continue;
        ChatHistoryEntry e;
        e.id = utf8_string(p.stem());
        e.title = str_of(*chat, "title");
        e.updated = static_cast<i64>(num_of(*chat, "updated"));
        out.push_back(std::move(e));
    }
    std::sort(out.begin(), out.end(), [](const ChatHistoryEntry& a, const ChatHistoryEntry& b) {
        return a.updated != b.updated ? a.updated > b.updated : a.id > b.id;
    });
    return out;
}

// ---------------------------------------------------------------------------------------------------------------------

std::string chat_title_from(const std::string& text, std::size_t maxChars) {
    std::size_t pos = 0;
    std::string line;
    while (pos <= text.size() && line.empty()) {  // the first line with something on it
        std::size_t nl = text.find('\n', pos);
        if (nl == std::string::npos) nl = text.size();
        std::string raw = text.substr(pos, nl - pos);
        pos = nl + 1;
        bool space = true;  // collapse whitespace runs, trim both ends
        for (char c : raw) {
            if (std::isspace(static_cast<unsigned char>(c))) {
                space = true;
            } else {
                if (space && !line.empty()) line += ' ';
                line += c;
                space = false;
            }
        }
    }
    std::size_t end = 0;  // after the first maxChars characters
    for (std::size_t chars = 0; chars < maxChars && end < line.size(); ++chars) utf8_next(line, end);
    return end < line.size() ? line.substr(0, end) + "..." : line;
}

// ---------------------------------------------------------------------------------------------------------------------
// Pictures

std::string attachment_problem(const std::string& path) {
    const stdfs::path p = utf8_path(path);
    const std::string name = utf8_string(p.filename());
    std::error_code ec;
    if (!stdfs::is_regular_file(p, ec)) return "'" + name + "' is not a file. Drop or pick an image file (png, jpg, jpeg, gif, webp).";
    if (ai::image_media_type_for_path(name).empty()) {
        return "'" + name + "' is not an image the AI accepts. Use a png, jpg, jpeg, gif or webp file.";
    }
    const auto size = stdfs::file_size(p, ec);
    if (ec || size == 0) return "'" + name + "' is empty. Attach a different image.";
    if (size > kMaxAttachmentBytes) {
        return "'" + name + "' is too large (" + std::to_string(size >> 20) + " MB; the limit is " +
               std::to_string(kMaxAttachmentBytes >> 20) + " MB). Shrink the image and attach it again.";
    }
    return {};
}

std::string unique_file_name(const std::string& dir, const std::string& fileName) {
    const stdfs::path given = utf8_path(fileName);
    std::string stem, ext = to_lower(utf8_string(given.extension()));
    for (char c : utf8_string(given.stem())) {  // ASCII only: the name goes into prompts and onto every OS
        stem += (std::isalnum(static_cast<unsigned char>(c)) || c == '-' || c == '_') ? c : '_';
    }
    if (stem.empty()) stem = "image";
    std::string name = stem + ext;
    std::error_code ec;
    for (int n = 2; stdfs::exists(utf8_path(dir) / utf8_path(name), ec); ++n) name = stem + "-" + std::to_string(n) + ext;
    return name;
}

namespace {
constexpr const char* kAttachmentsRel = ".factoria/ai/attachments";

// `src` scaled down (box filter) so its long side is at most `maxSide`; unchanged when it already fits.
Image shrink_image(const Image& src, int maxSide) {
    const int side = std::max(src.width, src.height);
    if (src.empty() || side <= maxSide) return src;
    Image out;
    out.width = std::max(1, static_cast<int>(static_cast<long long>(src.width) * maxSide / side));
    out.height = std::max(1, static_cast<int>(static_cast<long long>(src.height) * maxSide / side));
    out.rgba.resize(static_cast<std::size_t>(out.width) * out.height * 4);
    for (int y = 0; y < out.height; ++y) {
        const int y0 = y * src.height / out.height, y1 = std::max(y0 + 1, (y + 1) * src.height / out.height);
        for (int x = 0; x < out.width; ++x) {
            const int x0 = x * src.width / out.width, x1 = std::max(x0 + 1, (x + 1) * src.width / out.width);
            unsigned sum[4] = {0, 0, 0, 0};
            for (int sy = y0; sy < y1; ++sy)
                for (int sx = x0; sx < x1; ++sx)
                    for (int c = 0; c < 4; ++c) sum[c] += src.rgba[(static_cast<std::size_t>(sy) * src.width + sx) * 4 + c];
            const unsigned n = static_cast<unsigned>((y1 - y0) * (x1 - x0));
            for (int c = 0; c < 4; ++c)
                out.rgba[(static_cast<std::size_t>(y) * out.width + x) * 4 + c] = static_cast<std::uint8_t>(sum[c] / n);
        }
    }
    return out;
}

// Claude scales a picture down to 1568 px on its long side anyway, and the API refuses one over 5 MB (base64 makes
// 3.5 MB of PNG about 4.7 MB). A big screenshot is shrunk here: the model sees the same picture, for fewer tokens and
// with no refusal. A file that does not decode (webp, a broken file) is left as it is.
constexpr int kMaxImageSide = 1568;
constexpr std::size_t kMaxSentImageBytes = 3500u << 10;

Result<std::string> fit_for_ai(const stdfs::path& dir, const std::string& name) {
    std::ifstream in(dir / utf8_path(name), std::ios::binary);
    const std::vector<std::uint8_t> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    in.close();
    auto img = decode_image(bytes.data(), bytes.size());
    if (!img || (std::max(img->width, img->height) <= kMaxImageSide && bytes.size() <= kMaxSentImageBytes)) return name;
    Image small = shrink_image(*img, kMaxImageSide);
    std::vector<std::uint8_t> png = encode_png(small);
    while (png.size() > kMaxSentImageBytes && std::max(small.width, small.height) > 64) {
        small = shrink_image(small, std::max(small.width, small.height) * 3 / 4);
        png = encode_png(small);
    }
    std::error_code ec;
    stdfs::remove(dir / utf8_path(name), ec);  // the copy made a moment ago; the user's own file is untouched
    const std::string shrunk = unique_file_name(utf8_string(dir), utf8_string(utf8_path(name).stem()) + ".png");
    std::ofstream out(dir / utf8_path(shrunk), std::ios::binary | std::ios::trunc);
    if (out) out.write(reinterpret_cast<const char*>(png.data()), static_cast<std::streamsize>(png.size()));
    if (!out) return make_error("Cannot write " + std::string(kAttachmentsRel) + "/" + shrunk, "Is the project folder writable?");
    return shrunk;
}
}  // namespace

Result<ChatAttachment> attach_file(const std::string& projectDir, const std::string& source) {
    if (std::string problem = attachment_problem(source); !problem.empty()) return make_error(problem);
    const stdfs::path dir = utf8_path(projectDir) / kAttachmentsRel;
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    const std::string name = unique_file_name(utf8_string(dir), utf8_string(utf8_path(source).filename()));
    stdfs::copy_file(utf8_path(source), dir / name, stdfs::copy_options::none, ec);
    if (ec) {
        return make_error("Cannot copy '" + source + "' into the project: " + ec.message(),
                          "Is the project folder writable? The copy goes to " + std::string(kAttachmentsRel) + "/.");
    }
    auto fitted = fit_for_ai(dir, name);
    if (!fitted) return fitted.error();
    return ChatAttachment{std::string(kAttachmentsRel) + "/" + *fitted, *fitted};
}

Result<ChatAttachment> attach_bytes(const std::string& projectDir, const std::string& fileName, const std::vector<std::uint8_t>& bytes) {
    if (bytes.empty()) return make_error("The picture is empty", "Copy the image again.");
    const stdfs::path dir = utf8_path(projectDir) / kAttachmentsRel;
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    const std::string name = unique_file_name(utf8_string(dir), fileName);
    std::ofstream out(dir / name, std::ios::binary | std::ios::trunc);
    if (out) out.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    if (!out) {
        return make_error("Cannot write " + std::string(kAttachmentsRel) + "/" + name,
                          "Is the project folder writable?");
    }
    out.close();
    auto fitted = fit_for_ai(dir, name);
    if (!fitted) return fitted.error();
    return ChatAttachment{std::string(kAttachmentsRel) + "/" + *fitted, *fitted};
}

std::string selection_line(const std::string& entityName, const std::string& entityId) {
    if (entityId.empty()) return {};
    const std::string shown = entityName.empty() ? entityId : entityName;
    return "[Viewport selection: entity \"" + shown + "\" (id \"" + entityId +
           "\"). \"this\" and \"it\" in the request mean this entity.]";
}

// ---------------------------------------------------------------------------------------------------------------------

namespace {
// "a.js, b.js and 3 more" (names capped so a revert of a big run stays a readable line).
std::string names_line(const std::vector<std::string>& names) {
    constexpr std::size_t kShown = 8;
    std::string out;
    for (std::size_t i = 0; i < names.size() && i < kShown; ++i) out += (i ? ", " : "") + names[i];
    if (names.size() > kShown) out += " and " + std::to_string(names.size() - kShown) + " more";
    return out;
}
}  // namespace

std::string revert_line(const std::vector<ChatItem>& items) {
    std::size_t from = items.size();
    while (from > 0 && items[from - 1].kind != ChatItem::Kind::User) --from;
    std::vector<const ChatItem*> net;  // the reverts in force, in order; an Undo revert removes the one it takes back
    for (std::size_t i = from; i < items.size(); ++i) {
        const ChatItem& it = items[i];
        if (it.kind != ChatItem::Kind::Revert) continue;
        if (!it.isUndo) {
            net.push_back(&it);
            continue;
        }
        auto match = std::find_if(net.begin(), net.end(), [&](const ChatItem* r) { return !r->isUndo && r->safetyId == it.safetyId; });
        if (match != net.end()) net.erase(match);
        else net.push_back(&it);  // it takes back a revert the model was told about earlier
    }
    if (net.empty()) return {};
    std::string out = "[The user changed the project since your last message with the editor's Revert button, outside your control.";
    for (const ChatItem* r : net) {
        out += r->isUndo ? " They took back an earlier revert, so these files are again as your run left them: "
                         : " They reverted your previous run; the project went back to how it was before it. Files restored to their earlier content: ";
        std::vector<std::string> back = r->modified;
        back.insert(back.end(), r->deleted.begin(), r->deleted.end());
        out += back.empty() ? "none" : names_line(back);
        if (!r->added.empty()) out += (r->isUndo ? "; files removed again: " : "; files deleted (you had created them): ") + names_line(r->added);
        if (r->omitted) out += " (and " + std::to_string(r->omitted) + " more)";
        out += ".";
        if (r->sceneChanged) out += " The open scene went back too.";
    }
    out += " Do not assume your earlier changes are still there: read the files again before you edit them.]";
    return out;
}

// ---------------------------------------------------------------------------------------------------------------------

Image image_from_dib(const std::uint8_t* d, std::size_t size) {
    if (!d || size < 40) return {};
    auto u32 = [&](std::size_t o) { return std::uint32_t(d[o]) | std::uint32_t(d[o + 1]) << 8 | std::uint32_t(d[o + 2]) << 16 | std::uint32_t(d[o + 3]) << 24; };
    const std::uint32_t header = u32(0), compression = u32(16);
    const std::int64_t w = static_cast<std::int32_t>(u32(4)), h = std::abs(static_cast<std::int32_t>(u32(8))), bpp = u32(12) >> 16;
    // the pixels follow the header, the three masks of a plain BITFIELDS header and the palette
    const std::int64_t pixels = header + (header == 40 && compression == 3 ? 12 : 0) + std::int64_t(u32(32)) * 4;
    // stb_image reads .bmp files and does not notice truncated pixels: check them here (no RLE either)
    if (w <= 0 || h == 0 || w > 16384 || h > 16384 || (compression != 0 && compression != 3) ||
        std::int64_t(size) < pixels + (w * bpp + 31) / 32 * 4 * h) {
        return {};
    }
    std::vector<std::uint8_t> bmp(14 + size);  // the 14-byte file header: "BM", file size, 0, pixel offset
    bmp[0] = 'B';
    bmp[1] = 'M';
    for (int i = 0; i < 4; ++i) {
        bmp[2 + i] = std::uint8_t((14 + size) >> (8 * i));
        bmp[10 + i] = std::uint8_t((14 + pixels) >> (8 * i));
    }
    std::copy(d, d + size, bmp.begin() + 14);
    auto img = decode_image(bmp.data(), bmp.size());  // 32-bit bitmaps whose alpha bytes are all 0 come out opaque
    return img ? std::move(*img) : Image{};
}

}  // namespace fa::editor
