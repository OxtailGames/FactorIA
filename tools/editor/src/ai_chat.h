// The AI Assistant's conversations, without any drawing: what a chat tab holds, how the tabs are opened, closed and
// reopened, and how a chat is saved to (and loaded from) <project>/.factoria/ai/chats/. ai_panel.cpp draws it; the tests
// in tools/editor/tests exercise it without a window.
//
// Files in <project>/.factoria/ai/chats/:
//   <id>.json   one conversation: title, times, provider/role, the CLI session id (Claude Code) or the message history
//               (API providers), the transcript, the token totals. Written after every run and when a tab closes.
//   open.json   which conversations are open as tabs (and which one is active), so the tabs come back with the project.
// Closing a tab only closes it: the file stays and the conversation is listed in History.
#pragma once

#include <ctime>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

#include "fa/ai/session.h"
#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::editor {

// Paths in the editor are UTF-8 strings (the OS dialogs and sokol hand them out that way); std::filesystem::path(std::string)
// would read them in the Windows ANSI code page.
std::filesystem::path utf8_path(const std::string& s);
std::string utf8_string(const std::filesystem::path& p);

// Local time of an epoch second; `ok` is false when the C library cannot convert it (a tiny epoch on Windows).
std::tm local_tm(i64 epoch, bool* ok = nullptr);
// JSON files at UTF-8 paths. read_json: nullopt when the file is missing or not a JSON object. write_json: creates the
// folders on the way; false when it cannot write.
std::optional<Json> read_json(const std::string& path);
bool write_json(const std::string& path, const Json& j);

struct ChatItem {
    enum class Kind { User, Assistant, Thinking, Tool, Info, Error };
    Kind kind = Kind::Info;
    std::string text;
    std::string tool;
    Json input;
    Json result;
    bool done = false;
    bool isError = false;
    int depth = 0;
    std::string role;
    std::vector<std::string> images;  // User: project-relative paths of the pictures sent with the message

    Json to_json() const;
    static ChatItem from_json(const Json& j);
};

// A picture waiting to be sent: already copied into <project>/.factoria/ai/attachments/.
struct ChatAttachment {
    std::string path;  // project-relative, forward slashes
    std::string name;  // file name, for tooltips
};

struct AiChat {
    std::string id;     // file name stem in the chats folder: "20261014-153012" (+ "-2"...)
    std::string title;  // the first message, shortened; "" until there is one
    i64 created = 0, updated = 0;  // epoch seconds
    std::string provider;          // "" = the role's provider
    std::string role = "orchestrator";
    ai::Conversation conversation;  // CLI session id / message history that carries the chat to the next message
    std::vector<ChatItem> items;    // the transcript
    ai::Usage usage;                // tokens of the finished runs
    double costUsd = 0;
    u64 contextTokens = 0, contextWindow = 0;

    // Not saved:
    ai::Usage runUsage;           // tokens of the run in progress
    double runCostUsd = 0;
    std::string input;            // the unsent text
    std::vector<ChatAttachment> pending;  // the unsent pictures
    bool scrollDown = false;

    bool empty() const { return items.empty(); }
    Json to_json() const;
    static AiChat from_json(const Json& j);
};

struct ChatHistoryEntry {
    std::string id, title;
    i64 updated = 0;
};

// The open chats (tabs) of a project and their files.
class AiChats {
public:
    std::vector<AiChat> tabs;  // never empty
    int active = 0;
    std::string dir;           // the chats folder; "" = nothing is saved (no project open)

    AiChats();  // one blank tab, nothing saved until open_dir()

    AiChat& current() { return tabs[static_cast<std::size_t>(active)]; }
    const AiChat& current() const { return tabs[static_cast<std::size_t>(active)]; }
    AiChat* find(const std::string& id);
    int index_of(const std::string& id) const;  // -1 when not open

    // Switches to the chats folder of a project (<project>/.factoria/ai/chats, "" for none): the tabs that were open
    // last time come back, or one blank tab. Nothing is saved here.
    void open_dir(const std::string& chatsDir);
    // A new blank tab (after the last one, now active) with the provider and role of the active one.
    AiChat& add(i64 now);
    void select(int index);
    // Saves the tab, then closes it. The last tab is replaced by a blank one. Returns false for a bad index.
    bool close(int index);
    // Opens a saved conversation as the active tab (or activates it when it is open). False when the file is missing/bad.
    bool reopen(const std::string& id);
    // Deletes a saved conversation (and closes its tab when open). Returns false when there is no such conversation.
    bool erase(const std::string& id);
    // Starts the active tab over: transcript, session and totals are gone (and its file).
    void clear();

    // Writes the chat (a chat without messages has nothing to save) and the open-tabs list.
    void save(const AiChat& chat) const;
    void save_open_list() const;
    // Every saved conversation, newest first. Reads each file's title: fine for hundreds of chats.
    // ponytail: parses each chat file; add an index file if a very long history makes the popup slow.
    std::vector<ChatHistoryEntry> history() const;

private:
    std::string path_of(const std::string& id) const;
    std::string make_id(i64 now) const;
};

// "Fix the player jump when the g..." : the first line of a message, whitespace collapsed, cut at `maxChars` characters
// (UTF-8 aware) with "..." when it was longer. "" for a blank message.
std::string chat_title_from(const std::string& text, std::size_t maxChars = 24);

// ---- pictures the user attaches ---------------------------------------------------------------------------------------

inline constexpr std::size_t kMaxAttachmentBytes = 20u << 20;

// "" when the file can be attached; otherwise why not, saying what to do ("'x.txt' is not an image the AI accepts ...").
std::string attachment_problem(const std::string& path);
// A file name for a new copy of `fileName` in `dir` that no file there has: "shot.png", then "shot-2.png", "shot-3.png"...
std::string unique_file_name(const std::string& dir, const std::string& fileName);
// Copies an image file into <projectDir>/.factoria/ai/attachments/ under a unique name (nothing already there is touched).
Result<ChatAttachment> attach_file(const std::string& projectDir, const std::string& source);
// Same for picture bytes that are not a file yet (the clipboard): `fileName` is "paste.png", made unique like the above.
Result<ChatAttachment> attach_bytes(const std::string& projectDir, const std::string& fileName, const std::vector<std::uint8_t>& bytes);

// `src` scaled down (box filter) so its long side is at most `maxSide`; unchanged when it already fits. Attached
// pictures go through it: a big screenshot is shrunk to what the model actually looks at.
Image shrink_image(const Image& src, int maxSide);

// The line that tells the AI which entity the user is pointing at ("" when nothing is selected).
std::string selection_line(const std::string& entityName, const std::string& entityId);

// RGBA image from a Windows clipboard DIB (BITMAPINFOHEADER / V4 / V5 + pixels, 24 or 32 bits per pixel). Empty image
// (width 0) for anything else. Portable code: the Windows clipboard calls are in folder_picker.cpp.
Image image_from_dib(const std::uint8_t* data, std::size_t size);

}  // namespace fa::editor
