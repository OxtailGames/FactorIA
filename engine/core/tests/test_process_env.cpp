// The environment of a child process: ProcessOptions::inheritEnv (allow-list mode), base_child_env(), env_name_matches().
#include <doctest.h>

#include <cstdlib>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/process.h"

using namespace fa;

namespace {

// Sets (or, with nullptr, removes) a variable of THIS process for the length of a test.
struct ScopedVar {
    std::string name;
    ScopedVar(const char* n, const char* value) : name(n) {
#ifdef _WIN32
        _putenv_s(n, value);
#else
        ::setenv(n, value, 1);
#endif
    }
    ~ScopedVar() {
#ifdef _WIN32
        _putenv_s(name.c_str(), "");  // an empty value removes the variable
#else
        ::unsetenv(name.c_str());
#endif
    }
};

// The variables a child sees: runs the platform's "print the environment" program with `po`.
std::map<std::string, std::string> child_environment(ProcessOptions po) {
#ifdef _WIN32
    po.argv = {"cmd.exe", "/D", "/C", "set"};
#else
    po.argv = {"/usr/bin/env"};
#endif
    std::map<std::string, std::string> out;
    auto r = run_process(po);
    REQUIRE(r);
    std::istringstream lines(r->stdoutText);
    for (std::string line; std::getline(lines, line);) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        const auto eq = line.find('=', 1);
        if (eq != std::string::npos) out[line.substr(0, eq)] = line.substr(eq + 1);
    }
    return out;
}

bool has(const std::map<std::string, std::string>& env, const std::string& name) {
#ifdef _WIN32
    for (const auto& kv : env)
        if (env_name_matches(name, kv.first, true)) return true;
    return false;
#else
    return env.count(name) > 0;
#endif
}

}  // namespace

TEST_CASE("env_name_matches: exact names, a trailing * is a prefix, Windows ignores case") {
    CHECK(env_name_matches("PATH", "PATH", false));
    CHECK_FALSE(env_name_matches("PATH", "PATHEXT", false));
    CHECK_FALSE(env_name_matches("PATH", "Path", false));
    CHECK(env_name_matches("PATH", "Path", true));
    CHECK(env_name_matches("LC_*", "LC_ALL", false));
    CHECK(env_name_matches("LC_*", "LC_", false));
    CHECK_FALSE(env_name_matches("LC_*", "LANG", false));
    CHECK_FALSE(env_name_matches("LC_*", "lc_all", false));
    CHECK(env_name_matches("LC_*", "lc_all", true));
    CHECK(env_name_matches("ProgramFiles*", "ProgramFiles(x86)", false));
    CHECK_FALSE(env_name_matches("", "PATH", false));
    CHECK_FALSE(env_name_matches("PATH", "", false));
}

TEST_CASE("base_child_env: the common names, never a secret") {
    const auto& base = base_child_env();
    auto matches = [&](const std::string& name) {
        for (const auto& pattern : base)
            if (env_name_matches(pattern, name, false)) return true;
        return false;
    };
    for (const char* ok : {"PATH", "HOME", "LANG", "LC_ALL", "TERM", "TMPDIR", "FACTORIA_AI_CONFIG"})
        CHECK_MESSAGE(matches(ok), ok);
    for (const char* secret : {"FACTORIA_WINDOWS_PFX_PASSWORD", "FACTORIA_APPLE_APP_PASSWORD",
                               "FACTORIA_ANDROID_KEYSTORE_PASSWORD", "FACTORIA_ANDROID_KEY_PASSWORD",
                               "ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GITHUB_TOKEN", "AWS_SECRET_ACCESS_KEY"})
        CHECK_MESSAGE(!matches(secret), secret);

    const auto widened = child_env_allow({"AWS_PROFILE", "PATH", "", "AWS_PROFILE"});
    CHECK(widened.size() == base.size() + 1);  // the repeated and the empty names are dropped
    CHECK(widened.back() == "AWS_PROFILE");
}

TEST_CASE("run_process: inheritEnv passes the tool-path variables of base_child_env, not other variables") {
    const char* const names[] = {"SOKOL_SHDC",        "FACTORIA_EXPORT_CONFIG", "FACTORIA_FFMPEG", "FACTORIA_STEAMCMD",
                                 "FACTORIA_FASTLANE", "FACTORIA_XCRUN",         "FA_JOB_THREADS"};
    std::vector<std::unique_ptr<ScopedVar>> set;
    for (const char* n : names) set.push_back(std::make_unique<ScopedVar>(n, "value-of-it"));
    ScopedVar neighbour("FACTORIA_WINDOWS_PFX_PASSWORD", "hunter2");
    ProcessOptions po;
    po.inheritEnv = base_child_env();
    const auto env = child_environment(po);
    for (const char* n : names) {
        INFO(n);
        REQUIRE(has(env, n));
        CHECK(env.at(n) == "value-of-it");
    }
    CHECK_FALSE(has(env, "FACTORIA_WINDOWS_PFX_PASSWORD"));
}

TEST_CASE("run_process: inheritEnv drops what it does not name, keeps the base and the added variables") {
    ScopedVar secret("FA_TEST_ENV_SECRET", "hunter2");
    ScopedVar kept("FA_TEST_ENV_KEPT", "listed");
    ScopedVar pfxA("FA_TEST_ENV_PFX_A", "a");
    ScopedVar pfxB("FA_TEST_ENV_PFX_B", "b");

    ProcessOptions all;  // default: everything is inherited
    auto env = child_environment(all);
    CHECK(has(env, "FA_TEST_ENV_SECRET"));

    ProcessOptions po;
    po.inheritEnv = child_env_allow({"FA_TEST_ENV_KEPT", "FA_TEST_ENV_PFX_*"});
    po.env["FA_TEST_ENV_ADDED"] = "added";
    env = child_environment(po);
    CHECK_FALSE(has(env, "FA_TEST_ENV_SECRET"));
    CHECK(has(env, "PATH"));
    CHECK(env["FA_TEST_ENV_KEPT"] == "listed");
    CHECK(env["FA_TEST_ENV_PFX_A"] == "a");
    CHECK(env["FA_TEST_ENV_PFX_B"] == "b");
    CHECK(env["FA_TEST_ENV_ADDED"] == "added");

    // an override beats the inherited value, unsetEnv removes even a listed name
    po.env["FA_TEST_ENV_KEPT"] = "overridden";
    po.unsetEnv = {"FA_TEST_ENV_PFX_B"};
    env = child_environment(po);
    CHECK(env["FA_TEST_ENV_KEPT"] == "overridden");
    CHECK(env["FA_TEST_ENV_PFX_A"] == "a");
    CHECK_FALSE(has(env, "FA_TEST_ENV_PFX_B"));

    // an empty list is an empty environment (plus the overrides)
    ProcessOptions none;
    none.inheritEnv = std::vector<std::string>{};
    none.env["FA_TEST_ENV_ADDED"] = "only";
#ifndef _WIN32
    env = child_environment(none);  // /usr/bin/env needs no PATH; cmd.exe needs SystemRoot, so Windows skips this
    CHECK_FALSE(has(env, "PATH"));
    CHECK(env["FA_TEST_ENV_ADDED"] == "only");
#endif
}

#ifdef _WIN32
TEST_CASE("run_process: variable names are matched without regard to case on Windows") {
    ScopedVar kept("FA_TEST_ENV_CASE", "old");
    ProcessOptions po;
    po.inheritEnv = child_env_allow({"fa_test_env_case"});
    po.env["Fa_Test_Env_Added"] = "x";
    auto env = child_environment(po);
    CHECK(has(env, "FA_TEST_ENV_CASE"));  // listed in another case
    CHECK(has(env, "Path"));              // "PATH" in the base list, "Path" in the environment

    po.env["fa_test_env_case"] = "new";  // replaces the inherited one, it does not add a second
    env = child_environment(po);
    int n = 0;
    for (const auto& kv : env)
        if (env_name_matches("FA_TEST_ENV_CASE", kv.first, true)) {
            ++n;
            CHECK(kv.second == "new");
        }
    CHECK(n == 1);
}
#endif
