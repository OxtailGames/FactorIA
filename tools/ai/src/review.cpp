#include "fa/ai/review.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <ctime>
#include <filesystem>
#include <fstream>

#include "fa/ai/config.h"
#include "fa/core/fs.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

namespace {

std::vector<ReviewPersona> make_art_personas() {
    return {
        {"all-rounder",
         "You judge the whole look with the same weight on every point: direction, consistency, readability, polish. Balanced, "
         "precise, no pet peeves."},
        {"art director",
         "You think like the art director of a studio: visual identity, palette and mood, cohesion between scenes, whether "
         "every asset looks like it belongs to one game. You are strict about direction and drift, and say what the look "
         "should be rather than only what it is."},
        {"first impression",
         "You see the game for the first time, like a player scrolling a store page: what does the eye go to, can you tell "
         "what is what at a glance, does the first screen sell the game? You notice clutter, empty screens and unclear "
         "silhouettes before anything technical."},
        {"technical artist",
         "You look at the craft: texture and sprite resolution against the screen, scaling and filtering, aliasing and "
         "shimmering, inconsistent pixel sizes, seams in tiles, animation smoothness, lighting and effects cost, banding. "
         "You check numbers (sizes, render stats) as well as pictures."},
        {"UI and accessibility designer",
         "You look at the HUD, menus and text: typography, contrast, spacing and alignment, icon clarity, scaling to small and "
         "large windows, colour-blind safety (screenshots can simulate deuteranopia), feedback of buttons and states."},
    };
}

std::vector<ReviewPersona> make_game_personas() {
    return {
        {"all-rounder",
         "You review the game as a whole with equal attention to fun, feel, design, UX, stability, polish, art and audio. "
         "Balanced and fair, the reviewer a reader trusts."},
        {"genre veteran",
         "You have played hundreds of games of this genre and compare it with the best of them: what is original, what is "
         "borrowed badly, where the depth runs out. Demanding about the core loop and about what makes this game worth "
         "choosing over the classics."},
        {"newcomer",
         "You are a casual player with little patience: do you understand what to do in the first minute, is the onboarding "
         "clear, where do you get lost or frustrated, would you keep playing? Speak plainly."},
        {"QA tester",
         "You hunt bugs: odd inputs, repeated actions, edge cases, restarting and pausing at bad moments, scene changes, "
         "script errors and warnings in the logs, things that stay on screen. Every bug you report has steps to reproduce "
         "it and how bad it is."},
        {"design critic",
         "You examine the systems: rules, balance, difficulty curve, pacing, progression, player agency, risk and reward, "
         "how the parts reinforce each other. You say which decisions are interesting and which are noise."},
    };
}

std::string now_stamp(const char* fmt) {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    char buf[40];
    std::strftime(buf, sizeof buf, fmt, &tm);
    return buf;
}

}  // namespace

const std::vector<ReviewPersona>& review_personas(std::string_view role) {
    static const std::vector<ReviewPersona> art = make_art_personas();
    static const std::vector<ReviewPersona> game = make_game_personas();
    return role == kRoleArtCritic ? art : game;
}

std::string review_role_for_kind(std::string_view kind) {
    if (kind == "art") return kRoleArtCritic;
    if (kind == "game") return kRoleReviewer;
    return {};
}
std::string review_kind_for_role(std::string_view role) {
    if (role == kRoleArtCritic) return "art";
    if (role == kRoleReviewer) return "game";
    return {};
}

std::string persona_prompt(const ReviewPersona& persona, int index, int count) {
    std::string out = "# Your persona: " + persona.name + "\n" + persona.brief + "\n";
    if (count > 1) {
        out += "You are reviewer " + std::to_string(index + 1) + " of " + std::to_string(count) +
               ", each with a different persona and each working alone: write your own opinion, do not hedge toward an "
               "average.\n";
    }
    return out;
}

std::string review_task(std::string_view role, std::string_view focus) {
    std::string out = role == kRoleArtCritic
                          ? "Look at the current build of the game and write your art critique: play it and take screenshots of "
                            "every scene and state you can reach, then judge the art as your role describes."
                          : "Play the current build of the game and write your review: reach every scene and state you can, play "
                            "like a reviewer would, then judge the game as your role describes.";
    if (!focus.empty()) out += "\nThe user asks you to pay special attention to: " + std::string(focus);
    out += "\nEnd with the report's closing json block (score, subScores, summary) exactly as your role says.";
    return out;
}

Json Review::to_json() const {
    Json sub = Json::object();
    for (const auto& [k, v] : subScores) sub[k] = v;
    Json j = Json::object({{"id", id},
                           {"role", role},
                           {"persona", persona},
                           {"time", time},
                           {"engineVersion", engineVersion},
                           {"gameName", gameName},
                           {"gameVersion", gameVersion},
                           {"provider", provider},
                           {"model", model},
                           {"focus", focus},
                           {"score", score},
                           {"subScores", sub},
                           {"summary", summary},
                           {"costUsd", costUsd},
                           {"text", text}});
    if (!path.empty()) j["path"] = path;
    return j;
}

Review Review::from_json(const Json& j) {
    Review r;
    r.id = str(j, "id");
    r.path = str(j, "path");
    r.role = str(j, "role");
    r.persona = str(j, "persona");
    r.time = str(j, "time");
    r.engineVersion = str(j, "engineVersion");
    r.gameName = str(j, "gameName");
    r.gameVersion = str(j, "gameVersion");
    r.provider = str(j, "provider");
    r.model = str(j, "model");
    r.focus = str(j, "focus");
    r.text = str(j, "text");
    r.summary = str(j, "summary");
    r.score = num(j, "score", -1);
    r.costUsd = num(j, "costUsd");
    if (const Json* sub = child(j, "subScores"); sub && sub->is_object()) {
        for (auto it = sub->begin(); it != sub->end(); ++it)
            if (it.value().is_number()) r.subScores.emplace_back(it.key(), it.value().get<double>());
    }
    return r;
}

ParsedReport parse_review_report(std::string_view finalText) {
    ParsedReport out;
    out.text = std::string(finalText);
    // The last fenced block that parses as an object with a number "score".
    std::size_t searchEnd = finalText.size();
    while (searchEnd > 0) {
        const std::size_t close = finalText.rfind("```", searchEnd - 1);
        if (close == std::string_view::npos || close == 0) break;
        const std::size_t open = finalText.rfind("```", close - 1);
        if (open == std::string_view::npos) break;
        std::size_t bodyStart = open + 3;
        const std::size_t eol = finalText.find('\n', bodyStart);
        if (eol == std::string_view::npos || eol > close) break;
        bodyStart = eol + 1;  // skips the language tag line ("json")
        Json j = parse(finalText.substr(bodyStart, close - bodyStart));
        if (j.is_object() && j.contains("score") && j["score"].is_number()) {
            out.score = std::clamp(j["score"].get<double>(), 0.0, 10.0);
            out.summary = str(j, "summary");
            if (const Json* sub = child(j, "subScores"); sub && sub->is_object()) {
                for (auto it = sub->begin(); it != sub->end(); ++it)
                    if (it.value().is_number()) out.subScores.emplace_back(it.key(), std::clamp(it.value().get<double>(), 0.0, 10.0));
            }
            std::string text(finalText.substr(0, open));
            while (!text.empty() && std::isspace(static_cast<unsigned char>(text.back()))) text.pop_back();
            out.text = std::move(text);
            return out;
        }
        searchEnd = open;
    }
    return out;
}

std::string review_as_message(const Review& r) {
    const bool art = r.role == kRoleArtCritic;
    std::string out = std::string("Here is ") + (art ? "an art critique" : "a game review") + " of the current build that I asked for (" +
                      (r.persona.empty() ? std::string("reviewer") : r.persona) + ", ";
    if (r.score >= 0) {
        char buf[32];
        std::snprintf(buf, sizeof buf, "%.1f", r.score);
        out += std::string("score ") + buf + "/10";
        if (!r.subScores.empty()) {
            out += ": ";
            bool first = true;
            for (const auto& [name, value] : r.subScores) {
                std::snprintf(buf, sizeof buf, "%.1f", value);
                out += (first ? "" : ", ") + name + " " + buf;
                first = false;
            }
        }
    } else {
        out += "no score";
    }
    out += ").\n\n" + r.text;
    out += "\n\nGo through it with me: decide what is worth fixing, delegate the work (the artist for art, the audio role for sound, "
           "the worker for code), and tell me what you changed. The reviewer cannot be asked questions; do not start another review.";
    return out;
}

std::string reviews_dir(const std::string& projectDir) {
    return (fsys::path(projectDir) / ".factoria" / "ai" / "reviews").generic_string();
}

Result<Review> save_review(const std::string& projectDir, Review r) {
    if (projectDir.empty()) return make_error("No project is open, so the review cannot be saved", "Open a project first.");
    if (r.time.empty()) r.time = now_stamp("%Y-%m-%dT%H:%M:%S");
    if (r.engineVersion.empty()) {
#ifdef FA_ENGINE_VERSION
        r.engineVersion = FA_ENGINE_VERSION;
#endif
    }
    if (r.gameName.empty() || r.gameVersion.empty()) {
        if (auto text = fs::read_text((fsys::path(projectDir) / "factoria.json").string())) {
            Json manifest = parse(*text);
            if (r.gameName.empty()) r.gameName = str(manifest, "name");
            if (r.gameVersion.empty()) r.gameVersion = str(manifest, "version");
        }
    }
    const fsys::path dir = reviews_dir(projectDir);
    std::error_code ec;
    fsys::create_directories(dir, ec);
    const std::string stem = now_stamp("%Y%m%d-%H%M%S") + "-" + r.role;
    std::string id = stem;
    for (int n = 2; fsys::exists(dir / (id + ".json"), ec); ++n) id = stem + "-" + std::to_string(n);
    r.id = id;
    r.path = (dir / (id + ".json")).generic_string();
    if (auto w = fs::write_text(r.path, dump_pretty(r.to_json()) + "\n"); !w) return w.error();
    return r;
}

std::vector<Review> list_reviews(const std::string& projectDir, std::string_view role, std::size_t limit) {
    std::vector<Review> out;
    std::error_code ec;
    const fsys::path dir = reviews_dir(projectDir);
    if (projectDir.empty() || !fsys::is_directory(dir, ec)) return out;
    for (const auto& entry : fsys::directory_iterator(dir, ec)) {
        if (!entry.is_regular_file(ec) || entry.path().extension() != ".json") continue;
        auto text = fs::read_text(entry.path().string());
        if (!text) continue;
        Json j = parse(*text);
        if (!j.is_object() || str(j, "role").empty()) continue;
        Review r = Review::from_json(j);
        r.id = entry.path().stem().string();
        r.path = entry.path().generic_string();
        if (!role.empty() && r.role != role) continue;
        out.push_back(std::move(r));
    }
    std::sort(out.begin(), out.end(), [](const Review& a, const Review& b) { return a.id > b.id; });  // ids start with the time
    if (limit > 0 && out.size() > limit) out.resize(limit);
    return out;
}

}  // namespace fa::ai
