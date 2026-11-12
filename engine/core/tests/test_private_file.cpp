// fa::fs::write_private / make_private: files only their owner can open.
#include <doctest.h>

#ifdef _WIN32
#include <windows.h>

#include <aclapi.h>
#else
#include <sys/stat.h>
#include <unistd.h>
#endif

#include <atomic>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/private_file.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempFolder {
    stdfs::path path = fs::make_temp_dir("privfile");
    ~TempFolder() {
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
};

int leftovers(const stdfs::path& dir) {
    int n = 0;
    for (const auto& e : stdfs::directory_iterator(dir))
        if (e.path().filename().string().find(".fa-tmp") != std::string::npos) ++n;
    return n;
}

#ifdef _WIN32
// Reads the DACL back: true when it is protected and holds exactly one entry, an allow entry of the current user.
bool owner_only_acl(const stdfs::path& file, std::string& why) {
    PSECURITY_DESCRIPTOR sd = nullptr;
    PACL dacl = nullptr;
    if (GetNamedSecurityInfoW(file.c_str(), SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, nullptr, nullptr, &dacl, nullptr, &sd) !=
        ERROR_SUCCESS) {
        why = "GetNamedSecurityInfoW failed";
        return false;
    }
    bool ok = false;
    SECURITY_DESCRIPTOR_CONTROL control = 0;
    DWORD revision = 0;
    HANDLE token = nullptr;
    if (!dacl) {
        why = "the file has no DACL (everybody has access)";
    } else if (!GetSecurityDescriptorControl(sd, &control, &revision) || !(control & SE_DACL_PROTECTED)) {
        why = "the DACL is not protected: it inherits the folder's entries";
    } else if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) {
        why = "OpenProcessToken failed";
    } else {
        DWORD size = 0;
        GetTokenInformation(token, TokenUser, nullptr, 0, &size);
        std::vector<char> user(size);
        ACL_SIZE_INFORMATION info{};
        void* ace = nullptr;
        if (!GetTokenInformation(token, TokenUser, user.data(), size, &size) ||
            !GetAclInformation(dacl, &info, sizeof info, AclSizeInformation)) {
            why = "cannot read the token or the ACL";
        } else if (info.AceCount != 1) {
            why = "the DACL has " + std::to_string(info.AceCount) + " entries, not 1";
        } else if (!GetAce(dacl, 0, &ace) || static_cast<ACE_HEADER*>(ace)->AceType != ACCESS_ALLOWED_ACE_TYPE) {
            why = "the entry is not an allow entry";
        } else {
            auto* allowed = static_cast<ACCESS_ALLOWED_ACE*>(ace);
            ok = EqualSid(reinterpret_cast<PSID>(&allowed->SidStart), reinterpret_cast<TOKEN_USER*>(user.data())->User.Sid) != 0;
            if (!ok) why = "the entry is not the current user's";
        }
    }
    if (token) CloseHandle(token);
    LocalFree(sd);
    return ok;
}
#else
bool owner_only_acl(const stdfs::path& file, std::string& why) {
    struct stat st {};
    if (::stat(file.c_str(), &st) != 0) {
        why = "stat failed";
        return false;
    }
    if ((st.st_mode & 0777) != 0600) {
        why = "mode is not 0600";
        return false;
    }
    return true;
}
#endif

}  // namespace

TEST_CASE("write_private: owner-only from the first byte, replaces the old file, leaves no temporary file") {
    TempFolder t;
    const stdfs::path file = t.path / "sub" / "secret.json";
    REQUIRE(fs::write_private(file.generic_string(), "one"));
    auto one = fs::read_text(file.generic_string());
    REQUIRE(one);
    CHECK(*one == "one");
    std::string why;
    CHECK_MESSAGE(owner_only_acl(file, why), why);

    REQUIRE(fs::write_private(file.generic_string(), std::string_view("two\0bytes", 9)));
    auto two = fs::read_text(file.generic_string());
    REQUIRE(two);
    CHECK(two->size() == 9);
    CHECK_MESSAGE(owner_only_acl(file, why), why);
    CHECK(leftovers(file.parent_path()) == 0);

    // a file that existed with the default permissions comes out private
    const stdfs::path open = t.path / "open.txt";
    {
        std::ofstream(open, std::ios::binary) << "old";
    }
    REQUIRE(fs::write_private(open.generic_string(), "new"));
    auto fresh = fs::read_text(open.generic_string());
    REQUIRE(fresh);
    CHECK(*fresh == "new");
    CHECK_MESSAGE(owner_only_acl(open, why), why);

    // an empty text is a file too; a missing folder is created
    REQUIRE(fs::write_private((t.path / "a" / "b" / "empty").generic_string(), ""));
    CHECK(stdfs::file_size(t.path / "a" / "b" / "empty") == 0);
}

TEST_CASE("write_private: a folder in the way is an error that says so and leaves nothing behind") {
    TempFolder t;
    stdfs::create_directories(t.path / "dir");
    auto r = fs::write_private((t.path / "dir").generic_string(), "x");
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(r.error().message.empty());
    CHECK_FALSE(r.error().hint.empty());
    CHECK(leftovers(t.path) == 0);
}

TEST_CASE("write_private: writers at the same time never share a temporary file") {
    TempFolder t;
    const stdfs::path file = t.path / "secret.json";
    std::atomic<int> failed{0};
    std::vector<std::thread> writers;
    for (int w = 0; w < 4; ++w) {
        writers.emplace_back([&, w] {
            for (int i = 0; i < 10; ++i)
                if (!fs::write_private(file.generic_string(), "writer " + std::to_string(w) + " round " + std::to_string(i))) ++failed;
        });
    }
    for (auto& th : writers) th.join();
#ifndef _WIN32
    CHECK(failed == 0);  // on Windows a file another writer has open can refuse the replace: replace_file retries but gives up
#endif
    auto last = fs::read_text(file.generic_string());
    REQUIRE(last);  // the next lines read it
    CHECK(last->rfind("writer ", 0) == 0);
    CHECK(leftovers(t.path) == 0);
    std::string why;
    CHECK_MESSAGE(owner_only_acl(file, why), why);
}

TEST_CASE("make_private: restricts a file a tool created with the default permissions") {
    TempFolder t;
    const stdfs::path file = t.path / "release.keystore";
    {
        std::ofstream(file, std::ios::binary) << "keystore";
    }
    REQUIRE(fs::make_private(file.generic_string()));
    std::string why;
    CHECK_MESSAGE(owner_only_acl(file, why), why);
    auto kept = fs::read_text(file.generic_string());
    REQUIRE(kept);
    CHECK(*kept == "keystore");  // the owner still reads it

    auto missing = fs::make_private((t.path / "nothing").generic_string());
    REQUIRE_FALSE(missing.ok());
    CHECK_FALSE(missing.error().hint.empty());
}

TEST_CASE("make_temp_dir: a folder that already has the next name is never reused, and on POSIX the folder is owner-only") {
    const stdfs::path first = fs::make_temp_dir("fa_test_tmpdir");
    REQUIRE_FALSE(first.empty());
    REQUIRE(stdfs::is_directory(first));
    // Someone else prepared the name the next call would take (a shared /tmp), with a file inside.
    const std::string name = first.filename().string();
    const std::size_t us = name.rfind('_');
    REQUIRE(us != std::string::npos);
    const stdfs::path planted =
        first.parent_path() / (name.substr(0, us + 1) + std::to_string(std::stoul(name.substr(us + 1)) + 1));
    std::error_code ec;
    REQUIRE(stdfs::create_directory(planted, ec));
    {
        std::ofstream(planted / "planted.txt") << "x";
    }
    const stdfs::path second = fs::make_temp_dir("fa_test_tmpdir");
    REQUIRE_FALSE(second.empty());
    CHECK(second != planted);
    CHECK(second != first);
    CHECK(stdfs::is_directory(second));
    CHECK_FALSE(stdfs::exists(second / "planted.txt"));
    CHECK(stdfs::exists(planted / "planted.txt"));  // the planted folder is left alone
    CHECK(second.filename().string().rfind("fa_test_tmpdir_", 0) == 0);
#ifndef _WIN32
    for (const stdfs::path& dir : {first, second}) {
        struct stat st {};
        REQUIRE(::lstat(dir.c_str(), &st) == 0);
        CHECK(S_ISDIR(st.st_mode));
        CHECK((st.st_mode & 0777) == 0700);
        CHECK(st.st_uid == ::geteuid());
    }
#endif
    stdfs::remove_all(first, ec);
    stdfs::remove_all(second, ec);
    stdfs::remove_all(planted, ec);
}
