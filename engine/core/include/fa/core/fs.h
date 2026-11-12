// Virtual file system.
//
// Game code and data refer to files with PROJECT-RELATIVE paths using forward
// slashes: "assets/player.png", "scenes/main.scene.json". The VFS maps them to
// the platform location:
//   desktop  -> <project root>/<path>, or the game pack (fa/core/pack.h) once one is mounted: see mount_pack
//   android  -> APK assets (AAssetManager), read-only
//   ios      -> app bundle resources, read-only
// Absolute paths are accepted on desktop (tools use them); on mobile they fail. They never come from a pack.
// Writes are for tools and save games; game data on mobile and in a pack is read-only.
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <functional>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

#include "fa/core/types.h"

namespace fa::fs {

void set_project_root(const std::filesystem::path& root);
const std::filesystem::path& project_root();

// Writable per-user directory for save games / settings (created on demand):
//   desktop: <project>/.factoria/save  (dev) or OS app-data dir (shipped player)
//   mobile : app documents directory
void set_user_dir(const std::filesystem::path& dir);
const std::filesystem::path& user_dir();

// Per-user folder for files the engine can always rebuild (compiled shaders: fa/core/blob_cache.h). Never the game folder and
// never the save folder: a cache is private to the machine, may be deleted at any time, and is not backed up. Empty = no disk
// cache (the web build, or a mobile player before it called set_cache_dir). Default on desktop: macOS ~/Library/Caches/FactorIA,
// Windows %LOCALAPPDATA%\FactorIA\Cache, Linux $XDG_CACHE_HOME/factoria or ~/.cache/factoria. The environment variable
// FA_CACHE_DIR overrides it for a process (tests and CI point it at a scratch folder). Not created here: the writer creates it.
void set_cache_dir(const std::filesystem::path& dir);
// Returned by value: another thread may call set_cache_dir.
std::filesystem::path cache_dir();
// Forgets set_cache_dir: the next cache_dir() reads FA_CACHE_DIR and the platform default again (tests).
void reset_cache_dir();

// Tell the platform that the game wrote something in user_dir() (a save game). Does nothing on desktop and mobile, where
// the folder is on disk. On the web the folder lives in browser memory: this schedules copying it to the browser's
// IndexedDB (a few writes in a row become one copy, and a closing tab flushes it), so saves survive a reload.
void user_dir_changed();
// Copies the save folder to the browser's IndexedDB now, without waiting for the half-second timer user_dir_changed()
// schedules. The web player calls it right after the suspend, resume and quit handlers have run, so a save made inside
// one is kept when the tab goes away. Does nothing on desktop and mobile.
void flush_user_dir();
#if defined(__EMSCRIPTEN__)
// Web only, once before the game starts: mounts the browser's IndexedDB at `dir`, loads what an earlier run saved there and
// then calls done() (the load is asynchronous; main() returns and done() starts the game). A browser that has no
// IndexedDB (private windows of some browsers) still calls done(): saves then last until the tab closes, with a warning.
void restore_user_dir(const std::filesystem::path& dir, void (*done)());
#endif

// The system's temporary folder as an absolute path, resolved here and not by std::filesystem::temp_directory_path, which on
// Windows (both STLs) fails when the folder does not exist yet. Linux and macOS: TMPDIR, TMP, TEMP, TEMPDIR, else the
// platform's default (/tmp). Windows: GetTempPath2W where it exists, else GetTempPathW (TMP, TEMP, USERPROFILE), kept in
// UTF-16. The folder may not exist (make_temp_dir makes it). Linux and macOS: a RELATIVE variable (TMPDIR=tmp) is refused with
// an error, not resolved against the working directory, which can change. Windows: GetTempPath itself makes a relative TMP
// absolute, against the working directory of that call, so the answer is always absolute (and follows a later chdir only
// when the next call is made); an answer that still is not absolute is refused the same way.
Result<std::filesystem::path> temp_base();

// Creates a fresh, empty scratch directory under temp_base(), named <prefix>_<process id>_<n>. Unique per
// process and call, so concurrent processes (parallel test runs, several agents building and testing at once) never
// share one. The caller removes it when done. The folder is always created by this call (a name that exists is never
// reused: it gets a random suffix, also when a FILE has that name), and on Linux and macOS it is owner-only (0700) and checked to be a real directory
// of this user, so a shared /tmp cannot hand a program a folder someone else prepared. A temporary folder that does not
// exist yet is made. The error says why (full or read-only temp folder, a file system that ignores modes) and how to fix it.
Result<std::filesystem::path> make_temp_dir(std::string_view prefix);

// Game pack (a `--release` desktop export is one archive, docs/EXPORTING.md). While a pack is mounted, every PROJECT-RELATIVE
// path read_bytes, read_text, exists, is_directory, file_size, modified_time and list are given is answered by the pack
// alone: a file that is not in it is "not found" (with a "did you mean" from the pack's index), whatever lies in the
// project folder. Absolute paths are not affected, and neither are writes: write_text and write_bytes still go to
// <project root>/<path> on disk, where save games and other files the game makes live. One pack at a time; mounting again
// replaces the mounted one. `packFile` is opened and its index read now (errors say what is wrong with the file).
Result<void> mount_pack(const std::filesystem::path& packFile);
void unmount_pack();
bool pack_mounted();

// Platform backends (called once by fa_platform at startup on mobile).
void set_android_asset_manager(void* aassetManager);

// Normalizes "./a\\b/../c" -> "a/c". Rejects paths escaping the root ("../x")
// for project-relative input.
// Returns "" if a project-relative path escapes the root; use normalize_checked
// when you want the explanation.
std::string normalize(std::string_view path);
// Same, but the error says why and how to fix it.
Result<std::string> normalize_checked(std::string_view path);
bool is_absolute(std::string_view path);
std::filesystem::path resolve(std::string_view path);  // absolute host path (desktop); `path` is UTF-8 text
// UTF-8 text <-> host path. On Windows std::filesystem::path(std::string) and path::string()/generic_string() go through the
// ANSI code page and mangle accents (and can put bytes that are not UTF-8 into JSON); these two never do. path_to_utf8 gives the
// forward-slash form. path_from_utf8 never throws: on Windows text that is not valid UTF-8 is read in the ANSI code page,
// the form path::string() gives, so a caller that still builds its text that way finds the same file.
std::filesystem::path path_from_utf8(std::string_view text);
std::string path_to_utf8(const std::filesystem::path& p);

// The form of a host path to hand to the OS. On Windows a path of 248 characters or more (MAX_PATH, 260, minus room for
// an 8.3 file name: the folder limit) comes back absolute, with backslashes and the \\?\ prefix, which lifts the limit
// whether or not long paths are enabled on the machine; elsewhere, and for shorter paths, `p` as it is. For file system
// calls only: show users the path itself.
std::filesystem::path os_path(const std::filesystem::path& p);
// std::filesystem::remove_all that also deletes files deeper than MAX_PATH: on Windows it always goes through the
// \\?\ form of `dir`, since remove_all on a short folder path stops at its first long child, and a read-only file in it
// (copy_file keeps the attribute) loses the attribute and is deleted too. Same result and error otherwise.
// Under the Windows rules (below) a file inside that is open through ReadStream stays, the rest is deleted and `ec` is a
// sharing violation, as remove_all does on Windows. An empty path is refused (invalid_argument, nothing is touched): it
// would be the working directory or, on Windows, the root of the drive.
std::uintmax_t remove_tree(const std::filesystem::path& dir, std::error_code& ec);
// Whether Windows would refuse to delete `file` because something holds it. On Windows: an open that asks for delete
// access and shares everything fails (a handle that did not allow deleting), or marking the file for deletion fails (an
// exe or a library that is running, a mapped file), and keeps failing for about a second (a scanner that lets go sooner
// does not count). The mark is taken back before the probe's handle closes, so the file stays; should Windows refuse to
// take it back, the file is deleted when that handle closes: then `markLost` (when given) is set and the answer is true.
// A file open with delete shared (a fa::PackReader that reads without mapping) is not held: a delete goes through. A
// read-only file is probed too where Windows can ignore the attribute (Windows 10 1809 and later); before that it is not
// held. Under Wine an exclusive open probes instead: any open handle holds the file. A file this process may not delete
// is not held (remove_tree's error says so). Under the Windows rules emulation: a file open through ReadStream or read_bytes, or a
// mapped fa::PackReader; elsewhere never (macOS and Linux delete open files).
bool file_in_use(const std::filesystem::path& file, bool* markLost = nullptr);
// The first file under `dir` (or `dir` itself when it is a file) for which file_in_use is true, in directory order; empty
// when there is none. `which` (optional) picks what to look at by path relative to `dir`: for a folder, false skips all
// of it; for a file, false skips the file. Call it before remove_tree when a half-deleted folder would be worse than an
// error; it reads the folder and opens files, so never on a UI thread. It looks at `maxFiles` files at most (a
// deterministic count, not a time: what lies past it is not looked at). `markLost`: as for file_in_use, for the file returned.
std::filesystem::path find_file_in_use(const std::filesystem::path& dir,
                                       const std::function<bool(const std::filesystem::path& rel, bool folder)>& which = {},
                                       std::size_t maxFiles = 100000, bool* markLost = nullptr);

// ---- Windows file rules ------------------------------------------------------------------------------------------
// Some file bugs only happen on Windows, so only a Windows CI run found them. Two rules cause most of them:
//   1. A file that is open for reading cannot be replaced, renamed or deleted: every std::ifstream opens without
//      FILE_SHARE_DELETE, so a rename onto it (the atomic write of write_bytes) or a remove fails with a sharing
//      violation until the reader closes it. POSIX allows both.
//   2. A file's modification time moves in steps of about 15.6 ms (1/64 s), not in nanoseconds: two writes within a step
//      keep the same time, and a change detector that compares times alone misses the second one.
// The "Windows file rules" mode makes fa::fs follow both rules on macOS and Linux, so a test run there finds those bugs.
// Windows always follows them (nothing is emulated there). The mode is off by default and costs one atomic load per
// guarded call when it is off. It is on for a process when FA_FS_WINDOWS_RULES is set to anything but 0 / false / off / no;
// when that variable is not set, FA_FS_WINDOWS_RULES_DEFAULT is read the same way (ctest sets it on for every test, so
// `FA_FS_WINDOWS_RULES=0 ctest` turns the mode off for one run). set_windows_rules overrides both (tests).
//
// What it covers: files opened through ReadStream or fs::read_bytes / read_text (the registry only knows those: a file
// opened with a bare std::ifstream, or by another process, is invisible to it), and a game pack while a fa::PackReader has
// it open (Windows refuses to replace an open file, mapped or not, and to delete a mapped one: an export over a running
// game; an unmapped pack shares delete, so a delete of it goes through); replace_file, remove_file, remove_tree and
// write_bytes against them; modified_time. What it does not: files held open for writing or
// mapped by anything else, other processes, reserved names (CON, NUL), the 260-character limit, text/binary newline translation.
bool windows_rules();             // true when file operations follow Windows rules: on Windows always, elsewhere when the mode is on
void set_windows_rules(bool on);  // turns the emulation on or off for the rest of the process (tests); a no-op on Windows
// The size of one step of a file's modification time under the Windows rules, in nanoseconds (15.625 ms = 1/64 s).
constexpr std::int64_t kWindowsTimeStepNs = 15'625'000;

// An input file stream that the "Windows file rules" mode knows about: while it is open, replace_file, remove_file,
// remove_tree and write_bytes on that file fail like they do on Windows (sharing violation). Use it instead of
// std::ifstream for any file another thread or process may write or delete while it is read (watchers, pollers, panels,
// stores); it is a std::ifstream otherwise, with the same constructors and members. With the mode off it adds nothing.
class ReadStream : public std::ifstream {
public:
    ReadStream() = default;
    explicit ReadStream(const std::filesystem::path& file, std::ios_base::openmode mode = std::ios_base::in);
    ~ReadStream();
    ReadStream(const ReadStream&) = delete;
    ReadStream& operator=(const ReadStream&) = delete;
    // Same as std::ifstream::open / close, and they keep the registry right.
    void open(const std::filesystem::path& file, std::ios_base::openmode mode = std::ios_base::in);
    void close();

private:
    std::string registered_;  // the registry key of the open file; empty when it is not registered
    void unregister();
};

// True when `ec` says the file is held open by someone else: ERROR_ACCESS_DENIED (5), ERROR_SHARING_VIOLATION (32),
// ERROR_LOCK_VIOLATION (33) or ERROR_USER_MAPPED_FILE (1224) on Windows, the error the emulation returns elsewhere.
// Anything else is false (on POSIX, 5, 32, 33 and 1224 are other errors).
bool is_sharing_violation(const std::error_code& ec);
// std::filesystem::rename(from, to) that replaces an existing `to`, and waits for readers: while a sharing violation says
// `to` is open somewhere else (another thread polling it, an antivirus scan) it tries again for up to about a second, since
// such readers let go within milliseconds. `ec` is the last error (a sharing violation after the last try). Under the Windows
// rules a file open through ReadStream counts as such a reader, `from` as well.
void replace_file(const std::filesystem::path& from, const std::filesystem::path& to, std::error_code& ec);
// std::filesystem::remove(file) with the same waiting. Returns true when the file was deleted (false: it was not there or
// `ec` says why not).
bool remove_file(const std::filesystem::path& file, std::error_code& ec);

// ---- Reading ahead (scene.preload, assets.preload) ---------------------------------------------------------------
// warm(path) reads the file now and keeps its bytes; the next read_bytes / read_text of that path answers from memory
// (no disk read), as often as it is asked, until unwarm / unwarm_all drops it. A file whose modification time changed since
// it was warmed is read from disk again (and forgotten). Thread-safe.
// `text` / `size` (optional) receive the file's text (BOM removed) and its size in bytes, also when it was warm already.
Result<void> warm(std::string_view path, std::string* text = nullptr, std::uint64_t* size = nullptr);
bool is_warm(std::string_view path);
void unwarm(std::string_view path);
void unwarm_all();
std::uint64_t warm_bytes();  // bytes held by warm files
// Files read from disk (or from a pack) by read_bytes / read_text / warm since the process started. A read served from
// a warm file does not count. Tests compare two values to prove a load read nothing.
std::uint64_t disk_reads();

Result<std::string> read_text(std::string_view path);
Result<std::vector<std::uint8_t>> read_bytes(std::string_view path);

// The bytes of a file without a copy where that is possible: a file of a memory-mapped game pack stored as it is (the
// view points into the mapping and keeps the pack mapped while it lives, also after unmount_pack), a warm file (the view
// shares the warm bytes), an APK asset on Android (AAsset_getBuffer; the asset stays open while the view lives). In every
// other case (loose files on disk, a compressed file of a pack, a pack read without a mapping) the view owns a buffer
// with the bytes, as read_bytes returns them. Read-only, immutable, and safe to pass to and read from any thread.
class FileView {
public:
    FileView() = default;
    explicit FileView(std::vector<std::uint8_t> bytes);  // owns the bytes
    // Borrows `size` bytes at `data`, which stay valid while `owner` lives. `mapped` says they are not a copy.
    FileView(std::shared_ptr<const void> owner, const std::uint8_t* data, std::size_t size, bool mapped);

    std::span<const std::uint8_t> bytes() const { return {data_, size_}; }
    const std::uint8_t* data() const { return data_; }
    std::size_t size() const { return size_; }
    bool empty() const { return size_ == 0; }
    // True when the bytes were not copied for this view (a mapped pack, a warm file, an APK buffer).
    bool mapped() const { return mapped_; }
    std::vector<std::uint8_t> to_vector() const { return {data_, data_ + size_}; }
    std::string_view text() const;  // the bytes as UTF-8 text, a UTF-8 BOM skipped

private:
    std::shared_ptr<const void> owner_;
    const std::uint8_t* data_ = nullptr;
    std::size_t size_ = 0;
    bool mapped_ = false;
};
// Like read_bytes (same paths, same pack, same errors, counts in disk_reads), but answers a FileView.
Result<FileView> read_view(std::string_view path);
Result<void> write_text(std::string_view path, std::string_view text);  // creates parent dirs
Result<void> write_bytes(std::string_view path, const void* data, std::size_t size);
bool exists(std::string_view path);
bool is_directory(std::string_view path);
std::int64_t file_size(std::string_view path);      // bytes; -1 if missing or not a file
// -1 if missing; nanoseconds since 1970 (file_time_ns; a file of a pack: the pack's time). Under the Windows rules a file's time is rounded down to
// steps of 15.625 ms: compare it for "changed" only together with something else (size, content), or read once more after a change.
std::int64_t modified_time(std::string_view path);
// The modification time of a file given as a host path (no pack, no project root), in the unit and with the rounding of
// modified_time; -1 if missing. A change detector for a file outside what fs:: reads (editor state, tool stores) uses this
// instead of std::filesystem::last_write_time, so the Windows rules cover it too.
std::int64_t host_modified_time(const std::filesystem::path& file);
// A std::filesystem file time as nanoseconds since 1970. Use it instead of the raw time_since_epoch().count(): each
// standard library puts that clock's epoch elsewhere (libstdc++ in 2174, so a file written today counts negative and reads
// as "missing"; MSVC in 1601).
std::int64_t file_time_ns(std::filesystem::file_time_type time);

// Lists files (project-relative paths, sorted). `extension` like ".png" filters.
std::vector<std::string> list(std::string_view dir, bool recursive = true, std::string_view extension = {});

std::string extension(std::string_view path);  // ".png" (lowercase)
std::string filename(std::string_view path);   // "player.png"
std::string stem(std::string_view path);       // "player"
std::string parent(std::string_view path);     // "assets"
std::string join(std::string_view a, std::string_view b);

// ---- Write policy of the project folder -------------------------------------------------------------------------
// The VCS folder and `.factoria/` belong to tools: the engine and the editor keep screenshots, save games, AI
// transcripts and editor state in `.factoria/`. Commands that write or delete a file whose path comes from the caller
// (scene.save, scene.import_ascii with `path`, fs.write, fs.edit, fs.delete) refuse to touch them, with ONE exception:
// the scratch folder `.factoria/tmp/` is the place for throw-away files (generated inputs, test output). Everything in
// it may be created, overwritten and deleted by those commands; like the rest of `.factoria/` it is not committed.
constexpr const char* kScratchDir = ".factoria/tmp";

// `relativePath` is project-relative and normalized (forward slashes, no "." or ".." segments).
bool is_scratch_path(std::string_view relativePath);  // ".factoria/tmp" or anything below it
bool is_managed_path(std::string_view relativePath);  // the VCS folder, ".factoria" or below, except the scratch folder
// Ok when a command may write or delete `path` (project-relative, or absolute: then only paths inside the project root
// are judged). The error names the folder that is allowed (`.factoria/tmp/`).
// This is the managed-folder rule ONLY: it confines nothing. A path that comes from a caller (a command argument) goes
// through resolve_for_write first, which keeps it inside a root; check_writable is the second step for a command that lets
// its caller name any project path.
Result<void> check_writable(std::string_view path);

// ---- Paths that a caller gives to a command that writes ----------------------------------------------------------
// A command that writes a file whose path comes from its caller (game.screenshot, input.record, scene.save, fs.write...)
// resolves that path with resolve_for_write, never with resolve(), which accepts any absolute path. The three roots a
// write can be confined to:
//   Project  project_root(), the game's folder.
//   Save     user_dir(), the game's save folder.
//   Export   export_dir(), the folder export artifacts go to (set_export_dir; default <project>/build/export).
enum class WriteRoot { Project, Save, Export };
// Whether a path that lands in a managed folder of the project (the version-control folder, `.factoria/` except its scratch
// folder `.factoria/tmp`) is refused. Refuse is the default: a path a caller names does not touch them. Allow is for a
// command that chooses such a target itself (selections, previews and review files under `.factoria/`).
enum class ManagedFolders { Refuse, Allow };

// Sets the export folder (absolute); an empty path goes back to the default. Nothing is created: the writer creates the
// folder when it writes.
void set_export_dir(const std::filesystem::path& dir);
// The export folder: set_export_dir's, else <project_root()>/build/export (where project.export puts its output). Returned by value (another thread may set it).
std::filesystem::path export_dir();
// Whether set_export_dir named a folder (false: export_dir() is the default <project_root()>/build/export). A tooling command that
// knows its own project folder asks this instead of comparing paths.
bool export_dir_is_set();

// Resolves `path` (UTF-8 text; / and \ both separate) for a write below `root`. Gives the absolute, canonical host path to
// write, or an error that says which form of path was given, what this root accepts, where the root really is, and the fix.
//  - A relative path is joined to the root. "." segments are dropped and "a/../b" is "b"; a ".." that would leave the root
//    is `path_outside_root`. Symlinks of the existing part are resolved and the result must still be inside the root: a
//    link pointing out is `path_outside_root`, and so is a link pointing nowhere (writing through it would create its
//    target). The result is the canonical spelling: write to it, compare with it.
//  - An absolute path (/x, C:\x, C:/x, \\server\share, \\?\C:\x, and ~ or ~/x for the home folder) is
//    `absolute_path_denied` unless `allowAnywhere` (the command-line user, who owns the machine; never an agent or a script
//    that calls through the engine). When allowed it is normalized (".." cannot climb above the drive or share) and
//    returned, EXCEPT that the managed folders of the project stay closed to it (`managed_path_denied`: check_writable's
//    rule, so ".git" and ".factoria/" but not ".factoria/tmp/"), unless the path is inside the Save or Export root itself.
//    A drive-relative path (C:name), a device path (\\.\) and the ~user form are always `invalid_path`; the Windows forms
//    are `invalid_path` on other systems.
//  - Names compare without regard to case on Windows and macOS (their default volumes), never on Linux. A case-sensitive
//    macOS volume counts as case-insensitive for the "is it inside the root" test.
//  - With WriteRoot::Project, a path that lands in a managed folder of the project is `managed_path_denied`, judged on the
//    canonical path AND on the normalized spelling (refused when either is managed; names fold case and lose a trailing
//    dot or space), unless `managed` is ManagedFolders::Allow. A relative path never CREATES a name Windows cannot
//    (CON, NUL, COM1-9, COM/LPT with a superscript digit, a trailing dot or space: `invalid_path`); a name that already
//    exists as a regular file, a folder or a link is left alone on Linux and macOS, so such a file can still be read and
//    deleted. On Windows nothing is left alone: such a file cannot be there (NUL exists in every folder, `scenes.` is `scenes`).
//    That holds for a relative path and for an absolute one. The Save and Export roots are what a command writes to on
//    purpose, so a relative path in them is not judged. A command that lets its caller name any project path keeps calling
//    check_writable on the result too: that is the same rule, with its error.
//  - A name with a NUL byte is `invalid_path`, and so is a relative path with a drive in its first segment (`a/../C:/x`) or,
//    on Windows, a ':' in any segment (an alternate data stream). A network path needs a server and a share (Windows); on
//    other systems \\server\share and \\?\UNC\... are `invalid_path`.
// The check and the write are two steps: a link made in between is not seen. Nothing is created or opened here.
// The error's code is the end of its message, "(code: path_outside_root)"; path_error_code reads it. Codes:
// path_outside_root, absolute_path_denied, managed_path_denied, invalid_path, path_unresolvable.
Result<std::filesystem::path> resolve_for_write(std::string_view path, WriteRoot root, bool allowAnywhere,
                                                ManagedFolders managed = ManagedFolders::Refuse);
// The same against an explicit root folder (`root` only chooses the wording and the managed-folder exemption). For code that
// holds its own project folder (the tooling commands get it when they are registered, not from project_root()).
Result<std::filesystem::path> resolve_for_write_in(const std::filesystem::path& rootDir, WriteRoot root, std::string_view path,
                                                   bool allowAnywhere, ManagedFolders managed = ManagedFolders::Refuse);
// The spelling of a path that resolve_for_write returned for the project: relative to the project folder (forward slashes, ""
// for the folder itself) when it lies inside it, else the absolute path. The form the rest of this API (read_text, exists,
// write_text...) takes for a project file, so a command keeps its own bookkeeping (watched files, undo records) in it.
std::string project_spelling(const std::filesystem::path& resolved);
// The code of an error that resolve_for_write gave ("path_outside_root"...), or "" for any other error.
std::string_view path_error_code(const Error& error);

// Polling file watcher for hot reload (desktop only; no-op on mobile).
class Watcher {
public:
    using Callback = std::function<void(const std::string& path)>;
    int watch(std::string path, Callback onChange);  // returns id
    void unwatch(int id);
    void poll();  // call ~4 times per second; fires callbacks for changed files

private:
    struct Entry {
        int id;
        std::string path;
        std::int64_t mtime;
        Callback cb;
    };
    std::vector<Entry> entries_;
    int nextId_ = 1;
};

}  // namespace fa::fs
