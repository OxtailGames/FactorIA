// fa::fs::resolve_for_write: the one function through which a path that a caller gives to a command that writes is
// confined to the project, the save folder or the export folder (docs/ARCHITECTURE.md, "Files: fa::fs").
#include <doctest.h>

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/fs.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A scratch project with an "outside" folder next to it. Restores the project, save and export folders when it goes.
struct Confined {
    stdfs::path base;
    stdfs::path proj;     // as spelled (on macOS under /var, a link to /private/var)
    stdfs::path outside;  // a folder next to the project
    stdfs::path oldRoot, oldUser;
    Confined() {
        oldUser = fs::user_dir();  // before the root moves: user_dir() fixes its default on the first call
        oldRoot = fs::project_root();
        base = stdfs::temp_directory_path() /
               ("fa_test_confine_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        std::error_code ec;
        stdfs::remove_all(base, ec);
        proj = base / "proj";
        outside = base / "outside";
        stdfs::create_directories(proj);
        stdfs::create_directories(outside);
        fs::set_project_root(proj);
        fs::set_user_dir(proj / ".factoria" / "save");
        fs::set_export_dir({});
    }
    ~Confined() {
        fs::set_export_dir({});
        fs::set_user_dir(oldUser);
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(base, ec);
    }
    // The canonical spelling of a path below the project: what resolve_for_write answers.
    stdfs::path canon(const stdfs::path& rel = {}) const {
        std::error_code ec;
        stdfs::path c = stdfs::weakly_canonical(proj, ec);
        return rel.empty() ? c : stdfs::weakly_canonical(c / rel, ec);
    }
};

std::string text_of(const char8_t* u8) { return std::string(reinterpret_cast<const char*>(u8)); }

// Makes a symlink to a folder or file; false (with a MESSAGE) where the system or the user may not create links.
bool make_link(const stdfs::path& target, const stdfs::path& link, bool dir) {
    std::error_code ec;
    if (dir) stdfs::create_directory_symlink(target, link, ec);
    else stdfs::create_symlink(target, link, ec);
    if (ec) MESSAGE("symlinks cannot be created here (" << ec.message() << "): the link cases are skipped");
    return !ec;
}

std::string code_of(const Result<stdfs::path>& r) { return std::string(fs::path_error_code(r.error())); }

}  // namespace

TEST_CASE("resolve_for_write: a relative path stays in the project and comes back canonical") {
    Confined c;
    for (const char* ok : {"a/b.png", "./a//b.png", "a\\b.png", "a/./b.png", "x/../a/b.png"}) {
        CAPTURE(ok);
        auto r = fs::resolve_for_write(ok, fs::WriteRoot::Project, false);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r.value() == c.canon("a/b.png"));
    }
    // "a/../b" is fine as long as it stays inside; the project itself too.
    CHECK(fs::resolve_for_write("a/../b.png", fs::WriteRoot::Project, false).value() == c.canon("b.png"));
    CHECK(fs::resolve_for_write("a/b/../../c/d.txt", fs::WriteRoot::Project, false).value() == c.canon("c/d.txt"));
    CHECK(fs::resolve_for_write(".", fs::WriteRoot::Project, false).value() == c.canon());
    CHECK(fs::resolve_for_write("", fs::WriteRoot::Project, false).value() == c.canon());
    CHECK(fs::resolve_for_write("a/..", fs::WriteRoot::Project, false).value() == c.canon());
    // Folders that do not exist yet are fine, and nothing is created.
    CHECK_FALSE(stdfs::exists(c.proj / "a"));
}

TEST_CASE("resolve_for_write: a relative path into a managed folder is refused unless the command opts in") {
    Confined c;
    for (const char* bad : {".factoria/screenshots/s.png", ".git/config", ".git", ".factoria", "a/../.factoria/x.json", ".factoria/tmpx/a"}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(bad, fs::WriteRoot::Project, false);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "managed_path_denied");
        CHECK(r.error().hint.find(".factoria/tmp/") != std::string::npos);
        // allowAnywhere does not open them, and the opt-in does.
        CHECK(code_of(fs::resolve_for_write(bad, fs::WriteRoot::Project, true)) == "managed_path_denied");
        CHECK(fs::resolve_for_write(bad, fs::WriteRoot::Project, false, fs::ManagedFolders::Allow).ok());
        CHECK(fs::resolve_for_write_in(c.proj, fs::WriteRoot::Project, bad, false, fs::ManagedFolders::Allow).ok());
        CHECK(code_of(fs::resolve_for_write_in(c.proj, fs::WriteRoot::Project, bad, false)) == "managed_path_denied");
    }
    for (const char* ok : {".factoria/tmp/a.json", ".factoria/tmp", ".gitignore", ".factoria_x/a", "scenes/.factoria/a"}) {
        CAPTURE(ok);
        CHECK(fs::resolve_for_write(ok, fs::WriteRoot::Project, false).ok());
    }
    // Save and Export roots are what a command writes on purpose, even when they sit inside .factoria.
    CHECK(fs::resolve_for_write("slot.json", fs::WriteRoot::Save, false).ok());
    // A link into a managed folder counts (judged on the canonical path).
    stdfs::create_directories(c.proj / ".factoria" / "save");
    if (make_link(c.proj / ".factoria", c.proj / "meta", true)) {
        CHECK(code_of(fs::resolve_for_write("meta/x.json", fs::WriteRoot::Project, false)) == "managed_path_denied");
        CHECK(fs::resolve_for_write("meta/x.json", fs::WriteRoot::Project, false, fs::ManagedFolders::Allow).ok());
    }
    // Case variants are refused on every system: a Linux folder may sit on a volume that ignores case (WSL /mnt/c, ext4
    // casefold, SMB), and a project has to be portable.
    CHECK(code_of(fs::resolve_for_write(".GIT/config", fs::WriteRoot::Project, false)) == "managed_path_denied");
    CHECK(code_of(fs::resolve_for_write(".Factoria/x.json", fs::WriteRoot::Project, false)) == "managed_path_denied");
    CHECK(fs::resolve_for_write(".Factoria/TMP/x.json", fs::WriteRoot::Project, false).ok());
}

TEST_CASE("resolve_for_write: names Windows cannot create are invalid_path on every system") {
    Confined c;
    for (const char* bad : {"con", "CON.txt", "assets/nul.png", "Aux", "prn.tar.gz", "COM1", "lpt9.txt", "com5 .x", "name.", "dir /f.txt",
                            "assets/name ", "a./b.txt", "x/..."}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(bad, fs::WriteRoot::Project, false);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "invalid_path");
        CHECK_FALSE(r.error().hint.empty());
        CHECK(code_of(fs::resolve_for_write(bad, fs::WriteRoot::Project, true)) == "invalid_path");
    }
    for (const char* ok : {"console.txt", "com10.txt", "com0", "comx", "lpt.txt", "auxiliary/a.txt", "a.b/c", ".hidden", "..hidden", "nul_x.png"}) {
        CAPTURE(ok);
        CHECK(fs::resolve_for_write(ok, fs::WriteRoot::Project, false).ok());
    }
}

TEST_CASE("resolve_for_write: COM and LPT with a superscript digit are device names too") {
    Confined c;
    for (const char8_t* bad : {u8"COM¹", u8"com².txt", u8"assets/LPT³", u8"lpt¹.tar.gz", u8"CONIN$", u8"conout$.txt"}) {
        const std::string name = text_of(bad);
        CAPTURE(name);
        CHECK(code_of(fs::resolve_for_write(name, fs::WriteRoot::Project, false)) == "invalid_path");
    }
    for (const char8_t* ok : {u8"COM´", u8"com¹¹.txt", u8"comx¹"}) CHECK(fs::resolve_for_write(text_of(ok), fs::WriteRoot::Project, false).ok());
}

#ifndef _WIN32
TEST_CASE("resolve_for_write: a name Windows cannot create is only refused where this call would create it") {
    Confined c;
    // Files made on Linux: they can be read and deleted (resolve_project_path and fs.delete resolve them with this function).
    stdfs::create_directories(c.proj / "odd.");
    for (const char* name : {"CON.txt", "trail.", "odd./inner.txt"}) {
        std::ofstream(c.proj / name) << "x";
    }
    for (const char* existing : {"CON.txt", "trail.", "odd.", "odd./inner.txt"}) {
        CAPTURE(existing);
        CHECK(fs::resolve_for_write(existing, fs::WriteRoot::Project, false).ok());
        CHECK(fs::resolve_for_write(existing, fs::WriteRoot::Project, false, fs::ManagedFolders::Allow).ok());
    }
    // A new name next to them is still refused, and so is a new file below the odd folder when its own name is odd.
    CHECK(code_of(fs::resolve_for_write("NUL.txt", fs::WriteRoot::Project, false)) == "invalid_path");
    CHECK(code_of(fs::resolve_for_write("odd./aux.txt", fs::WriteRoot::Project, false)) == "invalid_path");
    CHECK(code_of(fs::resolve_for_write("newdir./f.txt", fs::WriteRoot::Project, false, fs::ManagedFolders::Allow)) == "invalid_path");
    CHECK(fs::resolve_for_write("odd./fine.txt", fs::WriteRoot::Project, false).ok());
}
#endif

TEST_CASE("resolve_for_write: a managed folder is refused by its spelling too, not only by where it leads") {
    Confined c;
    // Windows strips a trailing dot or space: these are the version-control folder and .factoria/ there.
    for (const char* bad : {".git./config", ".git /config", ".factoria./x.json", "a/../.GIT./x", ".Factoria/x.json", ".GIT/x"}) {
        CAPTURE(bad);
        const std::string code = code_of(fs::resolve_for_write(bad, fs::WriteRoot::Project, false));
        CHECK((code == "managed_path_denied" || code == "invalid_path"));
        CHECK(code_of(fs::resolve_for_write(bad, fs::WriteRoot::Project, true)) == code);
    }
    CHECK(code_of(fs::resolve_for_write(".git./config", fs::WriteRoot::Project, false)) == "managed_path_denied");
    CHECK(fs::resolve_for_write(".factoria/tmp/x.json", fs::WriteRoot::Project, false).ok());
    // A link `.factoria -> data` leads to a normal folder, but the caller named .factoria: refused. The link the other way
    // (meta -> .factoria) is refused by where it leads.
    stdfs::create_directories(c.proj / "data");
    if (make_link(c.proj / "data", c.proj / ".factoria", true)) {
        CHECK(code_of(fs::resolve_for_write(".factoria/x.json", fs::WriteRoot::Project, false)) == "managed_path_denied");
        CHECK(code_of(fs::resolve_for_write(".factoria/x.json", fs::WriteRoot::Project, true)) == "managed_path_denied");
        CHECK(code_of(fs::resolve_for_write(fs::path_to_utf8(c.proj / ".factoria" / "x.json"), fs::WriteRoot::Project, true)) == "managed_path_denied");
        CHECK(fs::resolve_for_write(".factoria/x.json", fs::WriteRoot::Project, false, fs::ManagedFolders::Allow).ok());
        CHECK(fs::resolve_for_write("data/x.json", fs::WriteRoot::Project, false).ok());
    }
}

TEST_CASE("resolve_for_write: NUL bytes, drives and streams in a relative path are invalid_path") {
    Confined c;
    using namespace std::string_literals;
    for (const std::string& bad : std::vector<std::string>{"a\0b.png"s, "\0"s, "a/../C:/x"s, "a/../D:"s, "x/../z:y/f"s}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(bad, fs::WriteRoot::Project, false);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "invalid_path");
        CHECK_FALSE(r.error().hint.empty());
        CHECK(code_of(fs::resolve_for_write(bad, fs::WriteRoot::Project, true)) == "invalid_path");
    }
    CHECK(code_of(fs::resolve_for_write("/tmp/a\0b"s, fs::WriteRoot::Project, true)) == "invalid_path");
    // A colon after the first segment is a valid name on POSIX.
#ifndef _WIN32
    CHECK(fs::resolve_for_write("a/b:c.txt", fs::WriteRoot::Project, false).ok());
#else
    CHECK(code_of(fs::resolve_for_write("a/b:stream", fs::WriteRoot::Project, false)) == "invalid_path");
#endif
}

#ifndef _WIN32
TEST_CASE("resolve_for_write: on a case-sensitive system names that are not UTF-8 stay different") {
#if !defined(__APPLE__)
    Confined c;
    // Two folders whose names differ in invalid bytes only: decoding both as U+FFFD would call them the same.
    const std::string a = "d\xff\xfe", b = "d\xfd\xfc";
    std::error_code ec;
    stdfs::create_directories(c.proj / a, ec);
    if (ec) {
        MESSAGE("this file system refuses names that are not UTF-8: skipped");
        return;
    }
    stdfs::create_directories(c.proj / b);
    // A path through folder a is not inside the root b.
    auto outside = fs::resolve_for_write_in(c.proj / b, fs::WriteRoot::Project, "../" + a + "/x.txt", false);
    CHECK(code_of(outside) == "path_outside_root");
    auto inside = fs::resolve_for_write_in(c.proj / b, fs::WriteRoot::Project, "x.txt", false);
    REQUIRE(inside.ok());
    CHECK(inside.value().parent_path().filename().native() == b);
    // The absolute path of a file in folder a, for a root that is b: not a path inside the root.
    auto denied = fs::resolve_for_write_in(c.proj / b, fs::WriteRoot::Project, (c.proj / a / "x.txt").generic_string(), false);
    REQUIRE_FALSE(denied.ok());
    CHECK(code_of(denied) == "absolute_path_denied");
    CHECK(denied.error().hint.find("is inside the project folder") == std::string::npos);
#endif
}

TEST_CASE("resolve_for_write: Windows forms of a network path are invalid_path on this system") {
    for (const char* foreign : {"\\\\server\\share\\x", "//server/share/x", "\\\\?\\UNC\\server\\share\\x", "//?/UNC/server/share/x"}) {
        CAPTURE(foreign);
        Confined c;
        auto b = fs::resolve_for_write(foreign, fs::WriteRoot::Project, true);
        REQUIRE_FALSE(b.ok());
        CHECK(code_of(b) == "invalid_path");
        CHECK(code_of(fs::resolve_for_write(foreign, fs::WriteRoot::Project, false)) == "absolute_path_denied");
    }
}
#endif

TEST_CASE("resolve_for_write: a '..' that leaves the root is path_outside_root and the error teaches") {
    Confined c;
    for (const char* bad : {"../x", "a/../../x", "a\\..\\..\\x", "..", "../outside/x.txt", "a/b/../../../x"}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(bad, fs::WriteRoot::Project, false);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "path_outside_root");
        CHECK(r.error().message.find(bad) != std::string::npos);                             // the given path
        CHECK(r.error().message.find("project folder") != std::string::npos);                // which root
        CHECK(r.error().message.find(fs::path_to_utf8(c.canon())) != std::string::npos);     // where it really is
        CHECK(r.error().hint.find("..") != std::string::npos);                               // the fix
    }
    // allowAnywhere does not loosen a relative path.
    CHECK_FALSE(fs::resolve_for_write("../x", fs::WriteRoot::Project, true).ok());
    // An error that is not a path error has no code.
    CHECK(fs::path_error_code(Error{"other", ""}).empty());
}

TEST_CASE("resolve_for_write: an absolute path is denied for a caller that may not write anywhere, in every form") {
    Confined c;
    const std::string insideAbs = fs::path_to_utf8(c.canon("scenes/a.json"));
    const std::string outsideAbs = fs::path_to_utf8(c.outside / "x.txt");
    for (const std::string& bad : std::vector<std::string>{
             "/etc/passwd", "/", "C:/Windows/x", "C:\\Windows\\x", "c:x", "C:", "\\\\server\\share\\x", "//server/share/x",
             "\\\\?\\C:\\x", "//?/C:/x", "\\\\.\\pipe\\x", "~", "~/x", "~\\x", "~user/x", "\\x", outsideAbs}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(bad, fs::WriteRoot::Project, false);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "absolute_path_denied");
        CHECK(r.error().message.find(bad) != std::string::npos);
        CHECK(r.error().message.find(fs::path_to_utf8(c.canon())) != std::string::npos);
        CHECK(r.error().hint.find("relative") != std::string::npos);
        CHECK(r.error().hint.find("command line") != std::string::npos);
    }
    // The form is named.
    CHECK(fs::resolve_for_write("C:x", fs::WriteRoot::Project, false).error().message.find("drive-relative") != std::string::npos);
    CHECK(fs::resolve_for_write("\\\\server\\share", fs::WriteRoot::Project, false).error().message.find("UNC") != std::string::npos);
    CHECK(fs::resolve_for_write("~/x", fs::WriteRoot::Project, false).error().message.find("~") != std::string::npos);
    // A path that lands inside the project says its relative spelling.
    auto inside = fs::resolve_for_write(insideAbs, fs::WriteRoot::Project, false);
    CHECK(inside.error().hint.find("\"scenes/a.json\"") != std::string::npos);
    // Nothing is created by a refusal.
    CHECK_FALSE(stdfs::exists(c.outside / "x.txt"));
}

TEST_CASE("resolve_for_write: an absolute path is accepted for a caller that may write anywhere") {
    Confined c;
    std::error_code ec;
    const stdfs::path outsideCanon = stdfs::weakly_canonical(c.outside, ec);
    const std::string abs = fs::path_to_utf8(c.outside / "sub" / "x.txt");
    auto r = fs::resolve_for_write(abs, fs::WriteRoot::Project, true);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r.value() == outsideCanon / "sub" / "x.txt");
    CHECK_FALSE(stdfs::exists(c.outside / "sub"));  // nothing is created
    // Dots are normalized away; a ".." cannot climb out of the drive.
    CHECK(fs::resolve_for_write(fs::path_to_utf8(c.outside) + "/a/../b/./x.txt", fs::WriteRoot::Project, true).value() ==
          outsideCanon / "b" / "x.txt");
    CHECK(fs::resolve_for_write(abs, fs::WriteRoot::Save, true).ok());
    CHECK(fs::resolve_for_write(abs, fs::WriteRoot::Export, true).ok());
    // Inside the project it is fine too, outside the managed folders.
    CHECK(fs::resolve_for_write(fs::path_to_utf8(c.proj / "scenes" / "a.json"), fs::WriteRoot::Project, true).value() ==
          c.canon("scenes/a.json"));
    // Forms that mean no single place are refused even then.
    for (const char* bad : {"C:x", "\\\\.\\pipe\\x", "~user/x", "\\\\?\\GLOBALROOT\\x"}) {
        CAPTURE(bad);
        auto b = fs::resolve_for_write(bad, fs::WriteRoot::Project, true);
        REQUIRE_FALSE(b.ok());
        CHECK(code_of(b) == "invalid_path");
        CHECK_FALSE(b.error().hint.empty());
    }
#ifndef _WIN32
    // Windows forms on a system that does not have them.
    for (const char* foreign : {"C:/x", "C:\\x", "\\\\?\\C:\\x"}) {
        CAPTURE(foreign);
        auto b = fs::resolve_for_write(foreign, fs::WriteRoot::Project, true);
        REQUIRE_FALSE(b.ok());
        CHECK(code_of(b) == "invalid_path");
    }
#endif
}

TEST_CASE("resolve_for_write: ~ is the home folder for a caller that may write anywhere") {
#ifndef _WIN32
    Confined c;
    const char* oldHome = std::getenv("HOME");
    const std::string saved = oldHome ? oldHome : "";
    ::setenv("HOME", c.outside.c_str(), 1);
    std::error_code ec;
    auto r = fs::resolve_for_write("~/notes/x.txt", fs::WriteRoot::Project, true);
    auto home = fs::resolve_for_write("~", fs::WriteRoot::Project, true);
    if (oldHome) ::setenv("HOME", saved.c_str(), 1);
    else ::unsetenv("HOME");
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r.value() == stdfs::weakly_canonical(c.outside, ec) / "notes" / "x.txt");
    REQUIRE(home.ok());
    CHECK(home.value() == stdfs::weakly_canonical(c.outside, ec));
#else
    MESSAGE("the ~ expansion test sets HOME: skipped on Windows (it reads USERPROFILE)");
#endif
}

TEST_CASE("resolve_for_write: the managed folders stay closed to an absolute path, even for a caller that may write anywhere") {
    Confined c;
    // The project may be spelled through a link (macOS /var -> /private/var): the check works on canonical paths.
    const std::string proj = fs::path_to_utf8(c.proj);
    for (const char* bad : {".git", ".git/config", ".factoria", ".factoria/save/slot1.json", ".factoria/screenshots/s.png",
                            ".factoria/tmpx/a.json", ".factoria/tmp2", "scenes/../.factoria/x"}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(proj + "/" + bad, fs::WriteRoot::Project, true);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "managed_path_denied");
        CHECK(r.error().hint.find(".factoria/tmp/") != std::string::npos);  // names what is allowed
    }
    for (const char* ok : {".factoria/tmp", ".factoria/tmp/a.json", ".factoria/tmp/deep/er/a.json", ".factoria_not/x", ".gitignore",
                           "scenes/a.json", "scenes/../.factoria/tmp/a.json"}) {
        CAPTURE(ok);
        auto r = fs::resolve_for_write(proj + "/" + ok, fs::WriteRoot::Project, true);
        CHECK_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    }
    // The same files outside the project are not managed.
    CHECK(fs::resolve_for_write(fs::path_to_utf8(c.outside / ".git" / "config"), fs::WriteRoot::Project, true).ok());
    CHECK(fs::resolve_for_write(fs::path_to_utf8(c.outside / ".factoria" / "x"), fs::WriteRoot::Project, true).ok());
    // Case variants count on every system (see the relative-path test).
    for (const char* bad : {".GIT/config", ".Factoria/save/a.json", ".FACTORIA/x"}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(proj + "/" + bad, fs::WriteRoot::Project, true);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "managed_path_denied");
    }
    CHECK(code_of(fs::resolve_for_write(proj + "/.FACTORIA/TMP2/x", fs::WriteRoot::Project, true)) == "managed_path_denied");
    CHECK(fs::resolve_for_write(proj + "/.Factoria/Tmp/x", fs::WriteRoot::Project, true).ok());
}

TEST_CASE("resolve_for_write: the project folder is found whatever the case of its spelling (Windows and macOS)") {
#if defined(_WIN32) || defined(__APPLE__)
    Confined c;
    std::string upper = fs::path_to_utf8(c.proj);
    std::transform(upper.begin(), upper.end(), upper.begin(), [](unsigned char ch) { return char(std::toupper(ch)); });
    std::error_code ec;
    if (!stdfs::exists(stdfs::path(upper), ec)) {
        MESSAGE("this volume is case-sensitive: the case-variant spelling of the project does not exist, case skipped");
        return;
    }
    auto r = fs::resolve_for_write(upper + "/.git/config", fs::WriteRoot::Project, true);
    REQUIRE_FALSE(r.ok());
    CHECK(code_of(r) == "managed_path_denied");
    // A relative path is joined to the root as it is, so it cannot depend on how the user cases the root.
    CHECK(fs::resolve_for_write("A/B.png", fs::WriteRoot::Project, false).ok());
#else
    MESSAGE("Linux volumes are case-sensitive: nothing to check");
    CHECK(fs::resolve_for_write("a/b.png", fs::WriteRoot::Project, false).value() != fs::resolve_for_write("A/b.png", fs::WriteRoot::Project, false).value());
#endif
}

TEST_CASE("resolve_for_write: the three roots") {
    Confined c;
    std::error_code ec;
    // Save: the default is <project>/.factoria/save (a managed folder, but it is the root here).
    {
        auto r = fs::resolve_for_write("slot1.json", fs::WriteRoot::Save, false);
        REQUIRE(r.ok());
        CHECK(r.value() == c.canon(".factoria/save/slot1.json"));
        auto esc = fs::resolve_for_write("../screenshots/s.png", fs::WriteRoot::Save, false);
        REQUIRE_FALSE(esc.ok());
        CHECK(code_of(esc) == "path_outside_root");
        CHECK(esc.error().message.find("save folder") != std::string::npos);
        // An absolute path inside the save folder is fine for a caller that may write anywhere; the rest of .factoria is not.
        CHECK(fs::resolve_for_write(fs::path_to_utf8(c.proj / ".factoria" / "save" / "a.json"), fs::WriteRoot::Save, true).ok());
        CHECK(code_of(fs::resolve_for_write(fs::path_to_utf8(c.proj / ".factoria" / "save" / "a.json"), fs::WriteRoot::Project, true)) ==
              "managed_path_denied");
        CHECK(code_of(fs::resolve_for_write(fs::path_to_utf8(c.proj / ".factoria" / "other" / "a.json"), fs::WriteRoot::Save, true)) ==
              "managed_path_denied");
        // A save folder somewhere else.
        fs::set_user_dir(c.outside / "saves");
        auto moved = fs::resolve_for_write("a/slot.json", fs::WriteRoot::Save, false);
        REQUIRE(moved.ok());
        CHECK(moved.value() == stdfs::weakly_canonical(c.outside, ec) / "saves" / "a" / "slot.json");
    }
    // Export: <project>/build/export until set_export_dir.
    {
        CHECK(fs::export_dir() == fs::project_root() / "build" / "export");
        auto r = fs::resolve_for_write("game.zip", fs::WriteRoot::Export, false);
        REQUIRE(r.ok());
        CHECK(r.value() == c.canon("build/export/game.zip"));
        CHECK_FALSE(stdfs::exists(c.proj / "build"));  // nothing is created until a write
        auto esc = fs::resolve_for_write("../../x", fs::WriteRoot::Export, false);
        REQUIRE_FALSE(esc.ok());
        CHECK(esc.error().message.find("export folder") != std::string::npos);
        CHECK(code_of(fs::resolve_for_write("/x", fs::WriteRoot::Export, false)) == "absolute_path_denied");

        fs::set_export_dir(c.outside / "out");
        CHECK(fs::export_dir() == c.outside / "out");
        auto moved = fs::resolve_for_write("game.zip", fs::WriteRoot::Export, false);
        REQUIRE(moved.ok());
        CHECK(moved.value() == stdfs::weakly_canonical(c.outside, ec) / "out" / "game.zip");
        CHECK(code_of(fs::resolve_for_write("../x", fs::WriteRoot::Export, false)) == "path_outside_root");
        fs::set_export_dir({});
        CHECK(fs::export_dir() == fs::project_root() / "build" / "export");
    }
    // Project is the project; the same relative path lands in three places.
    CHECK(fs::resolve_for_write("a.txt", fs::WriteRoot::Project, false).value() == c.canon("a.txt"));
    CHECK(fs::resolve_for_write_in(c.outside, fs::WriteRoot::Project, "a.txt", false).value() ==
          stdfs::weakly_canonical(c.outside, ec) / "a.txt");
    CHECK_FALSE(stdfs::exists(c.outside / "a.txt"));
}

TEST_CASE("resolve_for_write: a symbolic link that leaves the root is refused") {
    Confined c;
    std::error_code ec;
    {
        std::ofstream(c.outside / "secret.txt") << "x";
    }
    if (!make_link(c.outside, c.proj / "link", true)) return;
    for (const char* bad : {"link", "link/secret.txt", "link/new.txt", "link/deep/er.txt", "a/../link/new.txt"}) {
        CAPTURE(bad);
        auto r = fs::resolve_for_write(bad, fs::WriteRoot::Project, false);
        REQUIRE_FALSE(r.ok());
        CHECK(code_of(r) == "path_outside_root");
        CHECK(r.error().message.find("symbolic link") != std::string::npos);
        CHECK(r.error().hint.find("link") != std::string::npos);
    }
    // A link in the middle of a relative path is judged where it leads, not where it is written.
    CHECK_FALSE(stdfs::exists(c.outside / "new.txt"));

    // A link pointing nowhere would create its target on a write.
    REQUIRE(make_link(c.outside / "not-there.txt", c.proj / "dangling.txt", false));
    auto d = fs::resolve_for_write("dangling.txt", fs::WriteRoot::Project, false);
    REQUIRE_FALSE(d.ok());
    CHECK(code_of(d) == "path_outside_root");
    CHECK(d.error().message.find("symbolic link") != std::string::npos);
    auto below = fs::resolve_for_write("dangling.txt/x", fs::WriteRoot::Project, false);
    CHECK_FALSE(below.ok());

    // A link that stays inside the root is fine, and the answer is the real place.
    stdfs::create_directories(c.proj / "real");
    REQUIRE(make_link(c.proj / "real", c.proj / "inlink", true));
    auto in = fs::resolve_for_write("inlink/x.txt", fs::WriteRoot::Project, false);
    REQUIRE_MESSAGE(in.ok(), (in.ok() ? "" : in.error().to_string()));
    CHECK(in.value() == c.canon("real/x.txt"));
    // The links are judged for Save and Export roots the same way.
    fs::set_export_dir(c.proj / "exp");
    stdfs::create_directories(c.proj / "exp");
    REQUIRE(make_link(c.outside, c.proj / "exp" / "esc", true));
    CHECK(code_of(fs::resolve_for_write("esc/x.zip", fs::WriteRoot::Export, false)) == "path_outside_root");
    // A caller that may write anywhere gets an absolute path through a link as it leads (the link is the user's own).
    auto any = fs::resolve_for_write(fs::path_to_utf8(c.proj / "link" / "new.txt"), fs::WriteRoot::Project, true);
    REQUIRE(any.ok());
    CHECK(any.value() == stdfs::weakly_canonical(c.outside, ec) / "new.txt");
}

TEST_CASE("resolve_for_write: accents and spaces in the UTF-8 path and in the root") {
    Confined c;
    const std::string folder = text_of(u8"carpeta \u00f1and\u00fa");
    const std::string file = text_of(u8"\u00e9\u00e0 caf\u00e9 \u65e5\u672c.png");
    auto r = fs::resolve_for_write(folder + "/" + file, fs::WriteRoot::Project, false);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r.value() == c.canon(fs::path_from_utf8(folder) / fs::path_from_utf8(file)));
    CHECK(fs::path_to_utf8(r.value()).find(folder + "/" + file) != std::string::npos);
    // The message repeats the UTF-8 text unchanged.
    auto bad = fs::resolve_for_write("../" + file, fs::WriteRoot::Project, false);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find(file) != std::string::npos);

    // A project folder with accents.
    const stdfs::path accented = c.base / stdfs::path(u8"juego-Adri\u00e0");
    stdfs::create_directories(accented);
    fs::set_project_root(accented);
    auto inAccented = fs::resolve_for_write("out/" + file, fs::WriteRoot::Project, false);
    REQUIRE_MESSAGE(inAccented.ok(), (inAccented.ok() ? "" : inAccented.error().to_string()));
    std::error_code ec;
    CHECK(inAccented.value() == stdfs::weakly_canonical(accented, ec) / "out" / fs::path_from_utf8(file));
    auto esc = fs::resolve_for_write("../x", fs::WriteRoot::Project, false);
    REQUIRE_FALSE(esc.ok());
    CHECK(esc.error().message.find(text_of(u8"juego-Adri\u00e0")) != std::string::npos);
    // Case variants of accented letters are the same name on Windows and macOS.
#if defined(_WIN32) || defined(__APPLE__)
    std::string upper = fs::path_to_utf8(accented);
    const std::string lowerName = text_of(u8"juego-Adri\u00e0");
    const std::size_t at = upper.find(lowerName);
    REQUIRE(at != std::string::npos);
    upper.replace(at, lowerName.size(), text_of(u8"JUEGO-ADRI\u00c0"));
    if (stdfs::exists(fs::path_from_utf8(upper), ec)) {
        auto m = fs::resolve_for_write(upper + "/.git/config", fs::WriteRoot::Project, true);
        REQUIRE_FALSE(m.ok());
        CHECK(code_of(m) == "managed_path_denied");
    } else {
        MESSAGE("this volume does not fold accented letters: case skipped");
    }
#endif
}

#ifdef _WIN32
TEST_CASE("resolve_for_write: Windows long paths and drive paths") {
    Confined c;
    std::error_code ec;
    const stdfs::path outsideCanon = stdfs::weakly_canonical(c.outside, ec);
    // The \\?\ form of a local path is the path itself, and its ".." is resolved here, not left to the system.
    const std::wstring longForm = L"\\\\?\\" + c.outside.wstring() + L"\\a\\..\\x.txt";
    auto r = fs::resolve_for_write(fs::path_to_utf8(stdfs::path(longForm)), fs::WriteRoot::Project, true);
    // path_to_utf8 turns the backslashes into slashes: both spellings reach the same place.
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r.value() == outsideCanon / "x.txt");
    auto raw = fs::resolve_for_write(std::string("\\\\?\\") + fs::path_to_utf8(c.outside).substr(0) + "\\y.txt", fs::WriteRoot::Project, true);
    CHECK(raw.ok());
    // The drive path of the project, with either separator, in upper and lower case.
    std::string lower = fs::path_to_utf8(c.proj);
    for (char& ch : lower) ch = char(std::tolower(static_cast<unsigned char>(ch)));
    CHECK(code_of(fs::resolve_for_write(lower + "/.git/config", fs::WriteRoot::Project, true)) == "managed_path_denied");
    // Denied forms never touch the network.
    CHECK(code_of(fs::resolve_for_write("\\\\no-such-server\\share\\x", fs::WriteRoot::Project, false)) == "absolute_path_denied");
}
#endif
