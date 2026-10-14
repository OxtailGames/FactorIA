#include "ai_chat.h"

#include <algorithm>
#include <cctype>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <optional>

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

namespace {

std::string lowercase(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

const char* kind_name(ChatItem::Kind k) {
    switch (k) {
        case ChatItem::Kind::User: return "user";
        case ChatItem::Kind::Assistant: return "assistant";
        case ChatItem::Kind::Thinking: return "thinking";
        case ChatItem::Kind::Tool: return "tool";
        case ChatItem::Kind::Info: return "info";
        case ChatItem::Kind::Error: return "error";
    }
    return "info";
}

ChatItem::Kind kind_from(const std::string& s) {
    for (auto k : {ChatItem::Kind::User, ChatItem::Kind::Assistant, ChatItem::Kind::Thinking, ChatItem::Kind::Tool,
                   ChatItem::Kind::Info, ChatItem::Kind::Error}) {
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

Json usage_json(const ai::Usage& u) { return u.to_json(); }
ai::Usage usage_from(const Json& j) {
    ai::Usage u;
    u.inputTokens = static_cast<u64>(num_of(j, "inputTokens"));
    u.outputTokens = static_cast<u64>(num_of(j, "outputTokens"));
    u.cacheCreationTokens = static_cast<u64>(num_of(j, "cacheCreationTokens"));
    u.cacheReadTokens = static_cast<u64>(num_of(j, "cacheReadTokens"));
    return u;
}

std::string local_stamp(i64 now) {
    std::time_t t = static_cast<std::time_t>(now);
    std::tm tm{};
#ifdef _WIN32
    const bool ok = localtime_s(&tm, &t) == 0;
#else
    const bool ok = localtime_r(&t, &tm) != nullptr;
#endif
    char buf[32];
    if (!ok || std::strftime(buf, sizeof buf, "%Y%m%d-%H%M%S", &tm) == 0) return "chat-" + std::to_string(now);  // no clock: still unique
    return buf;
}

// JSON files at UTF-8 paths (fa::load_json_file would read the path in the Windows ANSI code page). nullopt when missing/bad.
std::optional<Json> read_json(const std::string& path) {
    std::ifstream in(utf8_path(path), std::ios::binary);
    if (!in) return std::nullopt;
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    Json j = Json::parse(text, nullptr, false);
    if (j.is_discarded() || !j.is_object()) return std::nullopt;
    return j;
}

void write_json(const std::string& path, const Json& j) {
    std::ofstream out(utf8_path(path), std::ios::binary | std::ios::trunc);
    if (out) out << j.dump(1, ' ', false, Json::error_handler_t::replace) << "\n";
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
                         {"provider", provider},
                         {"role", role},
                         {"conversation", conversation.to_json(false)},
                         {"usage", usage_json(usage)},
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
    c.provider = str_of(j, "provider");
    if (std::string r = str_of(j, "role"); !r.empty()) c.role = r;
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
AiChat blank_chat(const std::string& id, i64 now, const std::string& provider, const std::string& role) {
    AiChat c;
    c.id = id;
    c.created = c.updated = now;
    c.provider = provider;
    c.role = role;
    return c;
}
}  // namespace

AiChats::AiChats() {
    const i64 now = static_cast<i64>(std::time(nullptr));
    tabs.push_back(blank_chat(make_id(now), now, "", "orchestrator"));
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
    if (tabs.empty()) tabs.push_back(blank_chat(make_id(static_cast<i64>(std::time(nullptr))), static_cast<i64>(std::time(nullptr)), "", "orchestrator"));
    const int a = index_of(activeId);
    active = a >= 0 ? a : static_cast<int>(tabs.size()) - 1;
}

AiChat& AiChats::add(i64 now) {
    const AiChat& cur = current();
    AiChat c = blank_chat(make_id(now), now, cur.provider, cur.role);
    tabs.push_back(std::move(c));
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
    const std::string provider = tabs[static_cast<std::size_t>(index)].provider;
    const std::string role = tabs[static_cast<std::size_t>(index)].role;
    tabs.erase(tabs.begin() + index);
    if (tabs.empty()) {
        const i64 now = static_cast<i64>(std::time(nullptr));
        tabs.push_back(blank_chat(make_id(now), now, provider, role));
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
    c = blank_chat(c.id, static_cast<i64>(std::time(nullptr)), c.provider, c.role);
    save_open_list();
}

void AiChats::save(const AiChat& chat) const {
    if (dir.empty() || chat.empty()) return;
    std::error_code ec;
    stdfs::create_directories(utf8_path(dir), ec);
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
    stdfs::create_directories(utf8_path(dir), ec);
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
    std::size_t chars = 0;
    for (std::size_t i = 0; i < line.size(); ++i) {
        if ((static_cast<unsigned char>(line[i]) & 0xC0) == 0x80) continue;  // UTF-8 continuation byte
        if (chars++ == maxChars) return line.substr(0, i) + "...";
    }
    return line;
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
    std::string stem, ext = lowercase(utf8_string(given.extension()));
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
}

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
    return ChatAttachment{std::string(kAttachmentsRel) + "/" + name, name};
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
    return ChatAttachment{std::string(kAttachmentsRel) + "/" + name, name};
}

std::string selection_line(const std::string& entityName, const std::string& entityId) {
    if (entityId.empty()) return {};
    const std::string shown = entityName.empty() ? entityId : entityName;
    return "[Viewport selection: entity \"" + shown + "\" (id \"" + entityId +
           "\"). \"this\" and \"it\" in the request mean this entity.]";
}

// ---------------------------------------------------------------------------------------------------------------------

Image image_from_dib(const std::uint8_t* d, std::size_t size) {
    Image none;
    auto u16 = [&](std::size_t o) -> std::uint32_t { return std::uint32_t(d[o]) | std::uint32_t(d[o + 1]) << 8; };
    auto u32 = [&](std::size_t o) -> std::uint32_t { return u16(o) | u16(o + 2) << 16; };
    if (!d || size < 40) return none;
    const std::uint32_t headerSize = u32(0);
    if (headerSize < 40 || headerSize > size) return none;
    int w = static_cast<std::int32_t>(u32(4));
    int h = static_cast<std::int32_t>(u32(8));
    const bool topDown = h < 0;
    if (topDown) h = -h;
    const std::uint32_t planes = u16(12), bpp = u16(14), compression = u32(16), clrUsed = u32(32);
    const bool bitfields = compression == 3;
    if (w <= 0 || h <= 0 || w > 16384 || h > 16384 || planes != 1 || (bpp != 24 && bpp != 32) ||
        (compression != 0 && !bitfields)) {
        return none;
    }
    std::uint32_t mask[4] = {0x00FF0000u, 0x0000FF00u, 0x000000FFu, 0xFF000000u};  // R G B A of a 32-bit pixel
    std::size_t offset = headerSize;
    if (bitfields && bpp == 32) {
        if (headerSize >= 52) {  // V2+ headers carry the masks
            for (int i = 0; i < 3; ++i) mask[i] = u32(40 + 4 * static_cast<std::size_t>(i));
            mask[3] = headerSize >= 56 ? u32(52) : 0;
        } else {  // a 40-byte header is followed by the three masks
            if (size < offset + 12) return none;
            for (int i = 0; i < 3; ++i) mask[i] = u32(offset + 4 * static_cast<std::size_t>(i));
            mask[3] = 0;
            offset += 12;
        }
    }
    offset += static_cast<std::size_t>(clrUsed) * 4;
    const std::size_t stride = ((static_cast<std::size_t>(w) * bpp + 31) / 32) * 4;
    if (offset > size || size - offset < stride * static_cast<std::size_t>(h)) return none;
    auto shift_of = [](std::uint32_t m) { int s = 0; while (m && !(m & 1u)) { m >>= 1; ++s; } return s; };
    // Only plain 8-bit channels (every Windows screenshot tool); anything else is not worth guessing at.
    for (int i = 0; i < 3 && bpp == 32; ++i) {
        if ((mask[i] >> shift_of(mask[i])) != 0xFFu) return none;
    }
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(static_cast<std::size_t>(w) * static_cast<std::size_t>(h) * 4, 255);
    bool anyAlpha = false;
    for (int y = 0; y < h; ++y) {
        const std::uint8_t* row = d + offset + stride * static_cast<std::size_t>(topDown ? y : h - 1 - y);
        std::uint8_t* dst = &img.rgba[static_cast<std::size_t>(y) * static_cast<std::size_t>(w) * 4];
        for (int x = 0; x < w; ++x, dst += 4) {
            if (bpp == 24) {
                dst[0] = row[x * 3 + 2];
                dst[1] = row[x * 3 + 1];
                dst[2] = row[x * 3];
            } else {
                const std::uint32_t px = u32(static_cast<std::size_t>(row - d) + static_cast<std::size_t>(x) * 4);
                dst[0] = static_cast<std::uint8_t>((px & mask[0]) >> shift_of(mask[0]));
                dst[1] = static_cast<std::uint8_t>((px & mask[1]) >> shift_of(mask[1]));
                dst[2] = static_cast<std::uint8_t>((px & mask[2]) >> shift_of(mask[2]));
                if (mask[3]) {
                    dst[3] = static_cast<std::uint8_t>((px & mask[3]) >> shift_of(mask[3]));
                    anyAlpha = anyAlpha || dst[3] != 0;
                }
            }
        }
    }
    // Screenshot tools often leave the alpha byte of a 32-bit DIB at 0 for every pixel: that means "opaque", not invisible.
    if (bpp == 32 && !anyAlpha) {
        for (std::size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    }
    return img;
}

}  // namespace fa::editor
