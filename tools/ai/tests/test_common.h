// Shared test helpers.
#pragma once

#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>
#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

#include "fa/ai/anthropic.h"
#include "fa/ai/config.h"
#include "fa/ai/provider.h"
#include "fa/ai/session.h"
#include "fa/core/command.h"

namespace fa::ai::test {

inline int getpid_() {
#ifdef _WIN32
    return _getpid();
#else
    return static_cast<int>(::getpid());
#endif
}

inline std::string read_file(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    REQUIRE_MESSAGE(f.good(), "cannot open " << path);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}
inline std::string fixture(const std::string& name) { return read_file(std::string(FA_AI_FIXTURES) + "/" + name); }
inline Json fixture_json(const std::string& name) {
    Json j = Json::parse(fixture(name), nullptr, false);
    REQUIRE_FALSE(j.is_discarded());
    return j;
}

// Unique empty temp directory, removed on destruction.
struct TempDir {
    std::filesystem::path path;
    TempDir() {
        static int n = 0;
        path = std::filesystem::temp_directory_path() / ("fa_test_ai_" + std::to_string(getpid_()) + "_" + std::to_string(n++));
        std::filesystem::remove_all(path);
        std::filesystem::create_directories(path);
    }
    ~TempDir() {
        std::error_code ec;
        std::filesystem::remove_all(path, ec);
    }
    std::string str() const { return path.string(); }
};

inline EnvLookup fake_env(std::map<std::string, std::string> vars) {
    return [vars = std::move(vars)](const std::string& n) {
        auto it = vars.find(n);
        return it == vars.end() ? std::string() : it->second;
    };
}

// A registry with a few deterministic commands.
inline CommandRegistry make_registry() {
    CommandRegistry r;
    CommandInfo list;
    list.name = "scene.list_entities";
    list.summary = "List entities.";
    list.inputSchema = Json::parse(R"({"type":"object","properties":{"limit":{"type":"integer","default":10},"filter":{"type":"string"}}})");
    r.add(list, [](const Json& a) { return Json::object({{"count", 2}, {"limit", a.value("limit", 0)}}); });
    CommandInfo val;
    val.name = "project.validate";
    val.summary = "Validate the project.";
    r.add(val, [](const Json&) -> Json { throw CommandError("failed", "scene main is broken", "Fix scenes/main.scene.json"); });
    CommandInfo shot;
    shot.name = "game.screenshot";
    shot.summary = "Screenshot.";
    r.add(shot, [](const Json&) { return Json::object({{"image", Json::object({{"mediaType", "image/png"}, {"data", "QUJD"}})}, {"w", 4}}); });
    CommandInfo ai;
    ai.name = "ai.run";
    ai.summary = "must be hidden from the model";
    r.add(ai, [](const Json&) { return Json::object(); });
    return r;
}

// Scripted provider: returns queued responses, records every request.
class FakeProvider : public ChatProvider {
public:
    std::string name() const override { return "fake"; }
    Result<ChatResponse> chat(const ChatRequest& req, const ChatHooks& hooks, const CancelFlag*) override {
        requests.push_back(req);
        if (calls >= static_cast<int>(script.size())) return make_error("script exhausted");
        ChatResponse r = script[static_cast<std::size_t>(calls++)];
        if (hooks.onText && !r.message.text.empty()) hooks.onText(r.message.text);
        return r;
    }
    std::vector<ChatResponse> script;
    std::vector<ChatRequest> requests;
    int calls = 0;
};

inline ChatResponse text_response(const std::string& text, StopReason stop = StopReason::EndTurn) {
    ChatResponse r;
    r.message.role = Role::Assistant;
    r.message.text = text;
    r.message.raw = Json::array({Json::object({{"type", "text"}, {"text", text}})});
    r.stopReason = stop;
    r.rawStopReason = stop_reason_name(stop);
    r.usage.inputTokens = 100;
    r.usage.outputTokens = 10;
    return r;
}

inline ChatResponse tool_response(std::vector<ToolCall> calls, const std::string& text = "") {
    ChatResponse r;
    r.message.role = Role::Assistant;
    r.message.text = text;
    r.message.toolCalls = calls;
    Json raw = Json::array({Json::object({{"type", "thinking"}, {"thinking", "hmm"}, {"signature", "sig"}})});
    if (!text.empty()) raw.push_back(Json::object({{"type", "text"}, {"text", text}}));
    for (auto& c : calls) raw.push_back(Json::object({{"type", "tool_use"}, {"id", c.id}, {"name", c.name}, {"input", c.input}}));
    r.message.raw = raw;
    r.stopReason = StopReason::ToolUse;
    r.rawStopReason = "tool_use";
    r.usage.inputTokens = 100;
    r.usage.outputTokens = 10;
    return r;
}

}  // namespace fa::ai::test
