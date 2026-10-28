// Reviews: the art critics (role artCritic) and the game reviewers (role reviewer) look at and play the current build
// and give their opinion with a score. They run ONLY when the user asks (the editor's review buttons, `factoria ai
// review`, the ai.review command): the orchestrator cannot start them. Each review is returned to the caller AND saved in
// <project>/.factoria/ai/reviews/<time>-<role>[-n].json, so the scores can be compared over time (ai.reviews lists them).
#pragma once

#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::ai {

// The most critics or reviewers one request starts.
inline constexpr int kMaxReviewers = 5;

// Who is looking. The first persona of each role is the all-rounder: a request for one reviewer always gets it, so the
// scores of successive builds stay comparable; the others notice different things (their brief goes in the system prompt).
struct ReviewPersona {
    std::string name;   // "all-rounder", "newcomer", ...
    std::string brief;  // what this reviewer pays attention to, and how they speak
};
const std::vector<ReviewPersona>& review_personas(std::string_view role);  // artCritic or reviewer: kMaxReviewers entries
// "artCritic" <-> "art", "reviewer" <-> "game" (the `kind` of ai.review and `factoria ai review`). "" for anything else.
std::string review_role_for_kind(std::string_view kind);
std::string review_kind_for_role(std::string_view role);
// The system prompt text for one persona (appended to the role prompt) and the task the reviewer gets.
std::string persona_prompt(const ReviewPersona& persona, int index, int count);
std::string review_task(std::string_view role, std::string_view focus);

struct Review {
    std::string id;        // file name without .json: "20261028-210301-reviewer", "...-reviewer-2"
    std::string path;      // absolute; "" until saved
    std::string role;      // artCritic | reviewer
    std::string persona;   // ReviewPersona::name
    std::string time;      // "2026-10-28T21:03:01" local time
    std::string engineVersion;
    std::string gameName, gameVersion;  // from factoria.json
    std::string provider, model;
    std::string focus;     // what the user asked to look at ("" = everything)
    std::string text;      // the report, without the closing json block
    std::string summary;   // one sentence (from the block)
    double score = -1;     // 0..10; < 0 = the reviewer gave none
    std::vector<std::pair<std::string, double>> subScores;
    double costUsd = 0;
    Json to_json() const;
    static Review from_json(const Json& j);
};

struct ParsedReport {
    std::string text;      // the report without the closing fenced json block
    std::string summary;
    double score = -1;     // clamped to 0..10; -1 when the block is missing or has no number
    std::vector<std::pair<std::string, double>> subScores;
};
// Splits a reviewer's final message into its text and the last fenced ```json block ({score, subScores, summary}).
ParsedReport parse_review_report(std::string_view finalText);

// The user message that hands a review to the orchestrator ("Send to orchestrator" in the editor): who wrote it, the score,
// the report and what to do with it. Nothing sends it by itself.
std::string review_as_message(const Review& review);

std::string reviews_dir(const std::string& projectDir);  // <project>/.factoria/ai/reviews
// Fills id, path, time, engine and game fields that are empty, then writes the file. Error: the file could not be written.
Result<Review> save_review(const std::string& projectDir, Review review);
// Saved reviews, newest first. `role` filters ("" = both); `limit` 0 = all. Files that are not reviews are skipped.
std::vector<Review> list_reviews(const std::string& projectDir, std::string_view role = {}, std::size_t limit = 0);

}  // namespace fa::ai
