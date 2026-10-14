#include "fa/ai/types.h"

#include <filesystem>
#include <fstream>
#include <iterator>

#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;

Message Message::user(std::string text, std::vector<ImageData> images) {
    Message m;
    m.role = Role::User;
    m.text = std::move(text);
    m.images = std::move(images);
    return m;
}

std::string image_media_type_for_path(std::string_view path) {
    const std::size_t dot = path.rfind('.');
    if (dot == std::string_view::npos) return {};
    const std::string ext = lower(std::string(path.substr(dot + 1)));
    if (ext == "png") return "image/png";
    if (ext == "jpg" || ext == "jpeg") return "image/jpeg";
    if (ext == "gif") return "image/gif";
    if (ext == "webp") return "image/webp";
    return {};
}

Result<ImageData> load_image_data(const std::string& path) {
    const std::string mediaType = image_media_type_for_path(path);
    if (mediaType.empty()) {
        return make_error("'" + path + "' is not an image type the AI accepts",
                          "Use a .png, .jpg, .jpeg, .gif or .webp file.");
    }
    // The path is UTF-8 (the editor passes what the OS dialog gave it); path(std::string) would read it as ANSI on Windows.
    std::ifstream in(std::filesystem::path(std::u8string(reinterpret_cast<const char8_t*>(path.data()), path.size())), std::ios::binary);
    if (!in) return make_error("Cannot read the image '" + path + "'", "Does the file still exist, and can this user read it?");
    const std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (bytes.empty()) return make_error("The image '" + path + "' is empty", "Attach a different file.");
    return ImageData{mediaType, fa::base64_encode(bytes.data(), bytes.size())};
}

Json message_to_json(const Message& m, bool withImages) {
    Json j = Json::object({{"role", m.role == Role::User ? "user" : "assistant"}, {"text", m.text}});
    std::size_t droppedImages = m.images.size();
    if (withImages && !m.images.empty()) {
        Json imgs = Json::array();
        for (const auto& i : m.images) imgs.push_back(Json::object({{"mediaType", i.mediaType}, {"base64", i.base64}}));
        j["images"] = std::move(imgs);
        droppedImages = 0;
    }
    if (!m.toolCalls.empty()) {
        Json calls = Json::array();
        for (const auto& c : m.toolCalls) {
            Json cj = Json::object({{"id", c.id}, {"name", c.name}, {"input", c.input}});
            if (!c.inputError.empty()) cj["inputError"] = c.inputError;
            calls.push_back(std::move(cj));
        }
        j["toolCalls"] = std::move(calls);
    }
    if (!m.toolResults.empty()) {
        Json results = Json::array();
        for (const auto& r : m.toolResults) {
            std::string content = r.content;
            Json rj = Json::object({{"toolUseId", r.toolUseId}, {"isError", r.isError}});
            if (withImages && !r.images.empty()) {
                Json imgs = Json::array();
                for (const auto& i : r.images) imgs.push_back(Json::object({{"mediaType", i.mediaType}, {"base64", i.base64}}));
                rj["images"] = std::move(imgs);
            } else if (!r.images.empty()) {
                content += "\n[" + std::to_string(r.images.size()) + " image(s) returned here are not kept in the saved conversation]";
            }
            rj["content"] = std::move(content);
            results.push_back(std::move(rj));
        }
        j["toolResults"] = std::move(results);
    }
    if (!m.raw.is_null()) j["raw"] = m.raw;
    if (droppedImages > 0) {
        j["text"] = m.text + (m.text.empty() ? "" : "\n") + "[" + std::to_string(droppedImages) +
                    " image(s) attached here are not kept in the saved conversation]";
    }
    return j;
}

static std::vector<ImageData> images_from_json(const Json* arr) {
    std::vector<ImageData> out;
    if (!arr || !arr->is_array()) return out;
    for (const auto& i : *arr) out.push_back({str(i, "mediaType"), str(i, "base64")});
    return out;
}

Message message_from_json(const Json& j) {
    Message m;
    m.role = str(j, "role") == "assistant" ? Role::Assistant : Role::User;
    m.text = str(j, "text");
    m.images = images_from_json(child(j, "images"));
    if (const Json* calls = child(j, "toolCalls"); calls && calls->is_array()) {
        for (const auto& c : *calls) {
            ToolCall tc;
            tc.id = str(c, "id");
            tc.name = str(c, "name");
            if (const Json* in = child(c, "input")) tc.input = *in;
            tc.inputError = str(c, "inputError");
            m.toolCalls.push_back(std::move(tc));
        }
    }
    if (const Json* results = child(j, "toolResults"); results && results->is_array()) {
        for (const auto& r : *results) {
            ToolResult tr;
            tr.toolUseId = str(r, "toolUseId");
            tr.content = str(r, "content");
            tr.isError = flag(r, "isError");
            tr.images = images_from_json(child(r, "images"));
            m.toolResults.push_back(std::move(tr));
        }
    }
    if (const Json* raw = child(j, "raw")) m.raw = *raw;
    return m;
}

Message Message::tool_results(std::vector<ToolResult> results) {
    Message m;
    m.role = Role::User;
    m.toolResults = std::move(results);
    return m;
}

const char* stop_reason_name(StopReason r) {
    switch (r) {
        case StopReason::EndTurn: return "end_turn";
        case StopReason::ToolUse: return "tool_use";
        case StopReason::MaxTokens: return "max_tokens";
        case StopReason::PauseTurn: return "pause_turn";
        case StopReason::Refusal: return "refusal";
        case StopReason::Other: return "other";
    }
    return "other";
}

const char* event_type_name(AgentEvent::Type t) {
    switch (t) {
        case AgentEvent::Type::SessionStart: return "session_start";
        case AgentEvent::Type::TextDelta: return "text";
        case AgentEvent::Type::ThinkingDelta: return "thinking";
        case AgentEvent::Type::ToolStart: return "tool_start";
        case AgentEvent::Type::ToolEnd: return "tool_end";
        case AgentEvent::Type::Usage: return "usage";
        case AgentEvent::Type::Info: return "info";
        case AgentEvent::Type::Done: return "done";
        case AgentEvent::Type::Error: return "error";
    }
    return "info";
}

Usage& Usage::operator+=(const Usage& o) {
    inputTokens += o.inputTokens;
    outputTokens += o.outputTokens;
    cacheCreationTokens += o.cacheCreationTokens;
    cacheReadTokens += o.cacheReadTokens;
    return *this;
}

Json Usage::to_json() const {
    return Json::object({{"inputTokens", inputTokens},
                         {"outputTokens", outputTokens},
                         {"cacheCreationTokens", cacheCreationTokens},
                         {"cacheReadTokens", cacheReadTokens}});
}

// Prices are USD per 1M tokens for prompts <= 100K tokens (estimates only).
Pricing builtin_pricing(std::string_view model) {
    auto has = [&](std::string_view s) { return model.find(s) != std::string_view::npos; };
    if (has("opus-5")) return {4.0, 20.0, 0.20, 5.0, true};
    if (has("sonnet-5")) return {2.0, 10.0, 0.20, 2.5, true};
    if (has("haiku-5")) return {0.10, 0.50, 0.01, 0.125, true};
    return {};
}

double estimate_cost(const Usage& u, const Pricing& p) {
    if (!p.known) return 0;
    return (static_cast<double>(u.inputTokens) * p.input + static_cast<double>(u.outputTokens) * p.output +
            static_cast<double>(u.cacheReadTokens) * p.cacheRead +
            static_cast<double>(u.cacheCreationTokens) * p.cacheWrite) / 1e6;
}

}  // namespace fa::ai
