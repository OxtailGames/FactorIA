// Helpers for the asset tests: a game project in a temp folder with the assets.* commands registered, a scripted HTTP wire,
// and PNG helpers.
#pragma once

#include <set>

#include "fa/ai/commands.h"
#include "fa/core/image.h"
#include "test_common.h"

namespace fa::ai::test {

inline AiConfig config_from(const Json& json) {
    auto cfg = parse_config(json, "test");
    REQUIRE_MESSAGE(cfg.ok(), cfg.error().to_string());
    return *cfg;
}
inline AiConfig config_from(const char* json) { return config_from(Json::parse(json)); }

// Every kind of asset made by the fake provider.
inline AiConfig fake_config() {
    return config_from(R"({"assets":{"image":{"provider":"fake"},"sound":{"provider":"fake"},"music":{"provider":"fake"},
                           "voice":{"provider":"fake"},"model3d":{"provider":"fake"}}})");
}

// Answers the requests of a provider one after the other (the last answer repeats) and keeps them.
struct Wire {
    std::vector<HttpRequest> requests;
    std::vector<HttpResponse> replies;
    std::vector<double> sleeps;

    static HttpResponse reply(int status, std::string body) {
        HttpResponse r;
        r.status = status;
        r.body = std::move(body);
        return r;
    }
    ProviderRuntime runtime(std::map<std::string, std::string> env = {}) {
        ProviderRuntime rt;
        rt.transport = [this](const HttpRequest& req) {
            requests.push_back(req);
            REQUIRE_MESSAGE(!replies.empty(), "no reply scripted for " << req.url);
            return replies[std::min(requests.size(), replies.size()) - 1];
        };
        rt.env = fake_env(std::move(env));
        rt.sleep = [this](double seconds) { sleeps.push_back(seconds); };
        return rt;
    }
    static std::string header(const HttpRequest& req, const std::string& name) {
        for (const auto& [k, v] : req.headers) {
            if (k == name) return v;
        }
        return {};
    }
};

inline std::string png_bytes(int width, int height, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    Image img;
    img.width = width;
    img.height = height;
    for (int i = 0; i < width * height; ++i) img.rgba.insert(img.rgba.end(), {r, g, b, a});
    const auto png = encode_png(img);
    return std::string(png.begin(), png.end());
}

inline Image decode_png(const std::string& bytes) {
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes.data()), bytes.size());
    REQUIRE_MESSAGE(img.ok(), img.error().message);
    return *img;
}

// The distinct colours of the opaque and translucent pixels (0xRRGGBB).
inline std::set<std::uint32_t> colours_of(const Image& img) {
    std::set<std::uint32_t> out;
    for (std::size_t i = 0; i + 3 < img.rgba.size(); i += 4) {
        if (img.rgba[i + 3] == 0) continue;
        out.insert((std::uint32_t(img.rgba[i]) << 16) | (std::uint32_t(img.rgba[i + 1]) << 8) | img.rgba[i + 2]);
    }
    return out;
}

// A game project in a temp folder with the ai commands (assets.* among them) registered on `config`.
struct Game {
    TempDir dir;
    CommandRegistry registry;

    explicit Game(const AiConfig& config, ProviderRuntime runtime = {}) {
        AiCommandOptions opt;
        opt.loadConfig = [config] { return Result<AiConfig>(config); };
        opt.projectDir = [this] { return dir.str(); };
        opt.runtime = std::move(runtime);
        register_ai_commands(registry, std::move(opt));
    }
    CommandResult call(const char* name, const Json& args) { return registry.call(name, args); }
    // A call that must succeed.
    Json ok(const char* name, const Json& args) {
        auto r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, name << ": " << r.error.dump());
        return r.result;
    }
    void put(const std::string& rel, const std::string& bytes) {
        std::filesystem::create_directories((dir.path / rel).parent_path());
        std::ofstream(dir.path / rel, std::ios::binary) << bytes;
    }
    bool exists(const std::string& rel) const { return std::filesystem::exists(dir.path / rel); }
    std::string file(const std::string& rel) const { return read_file((dir.path / rel).string()); }
    Json manifest() const { return Json::parse(file("assets.json")); }
    Json provenance(const std::string& rel) const { return manifest()["assets"][rel]["provenance"]; }
};

}  // namespace fa::ai::test
