// The Review window's model (review_model.h).
#include "review_model.h"

#include <algorithm>
#include <cmath>
#include <set>

#include "fa/core/fs.h"
#include "fa/tooling/review.h"

namespace fa::editor {

namespace {

std::string str_of(const Json& j, const char* key) {
    if (!j.is_object()) return {};
    const auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// A whole number of the manifest, clamped before it is narrowed (a hand-edited manifest may hold anything).
int int_of(const Json& j, const char* key, int fallback = 0) {
    if (!j.is_object()) return fallback;
    const auto it = j.find(key);
    if (it == j.end() || !it->is_number()) return fallback;
    const double v = it->get<double>();
    if (!std::isfinite(v)) return fallback;
    return int(std::clamp(v, -2147483647.0, 2147483647.0));
}

bool bool_of(const Json& j, const char* key, bool fallback) {
    if (!j.is_object()) return fallback;
    const auto it = j.find(key);
    return it != j.end() && it->is_boolean() ? it->get<bool>() : fallback;
}

const Json& member(const Json& j, const char* key) {
    static const Json kNull;
    if (!j.is_object()) return kNull;
    const auto it = j.find(key);
    return it != j.end() ? *it : kNull;
}

}  // namespace

int ReviewSheetView::picked_n() const { return is_picked() ? std::max(0, int_of(picked, "n")) : 0; }

const ReviewItemView* ReviewSheetView::item(int n) const {
    for (const ReviewItemView& it : items)
        if (it.n == n) return &it;
    return nullptr;
}

ReviewSheetView review_sheet_view(const Json& m) {
    ReviewSheetView s;
    s.id = str_of(m, "id");
    s.label = str_of(m, "label");
    s.createdAt = str_of(m, "createdAt");
    s.dropDir = str_of(m, "dropDir");
    if (s.dropDir.empty()) s.dropDir = kReviewDropDir;
    const Json& pic = member(m, "picture");
    s.picture = str_of(pic, "path");
    if (s.picture.empty()) s.picture = std::string(kReviewDir) + "/" + s.id + "/sheet.png";
    s.width = std::max(0, int_of(pic, "width"));
    s.height = std::max(0, int_of(pic, "height"));
    s.columns = std::max(1, int_of(m, "columns", 1));
    s.rows = std::max(1, int_of(m, "rows", 1));
    const Json& items = member(m, "items");
    if (items.is_array()) {
        int index = 0;
        for (const Json& item : items) {
            ++index;
            if (!item.is_object()) continue;
            ReviewItemView v;
            v.n = int_of(item, "n", index);
            v.type = str_of(item, "type");
            v.label = str_of(item, "label");
            v.source = str_of(item, "source");
            v.info = str_of(item, "info");
            v.thumb = str_of(item, "thumb");
            v.error = str_of(item, "error");
            v.ok = bool_of(item, "ok", true);
            v.candidate = bool_of(item, "candidate", false);
            const Json& rect = member(item, "picture").is_object() ? member(item, "picture") : member(item, "cell");
            v.x = std::max(0, int_of(rect, "x"));
            v.y = std::max(0, int_of(rect, "y"));
            v.w = std::max(0, int_of(rect, "w"));
            v.h = std::max(0, int_of(rect, "h"));
            s.items.push_back(std::move(v));
        }
    }
    if (const Json& meta = member(m, "meta"); meta.is_object()) s.meta = meta;
    s.kind = str_of(s.meta, "kind");
    s.slot = str_of(s.meta, "slot");
    if (const Json& p = member(m, "picked"); p.is_object()) s.picked = p;
    if (const Json& w = member(m, "warnings"); w.is_array())
        for (const Json& line : w)
            if (line.is_string()) s.warnings.push_back(line.get<std::string>());
    return s;
}

std::vector<ReviewListRow> review_rows(const Json& listValue) {
    std::vector<ReviewListRow> rows;
    const Json& sheets = member(listValue, "sheets");
    if (!sheets.is_array()) return rows;
    for (const Json& s : sheets) {
        if (!s.is_object()) continue;
        ReviewListRow r;
        r.id = str_of(s, "id");
        if (r.id.empty()) continue;
        r.label = str_of(s, "label");
        r.createdAt = str_of(s, "createdAt");
        r.count = std::max(0, int_of(s, "count"));
        r.picked = std::max(0, int_of(s, "picked"));
        r.pickedLabel = str_of(s, "pickedLabel");
        r.kind = str_of(member(s, "meta"), "kind");
        rows.push_back(std::move(r));
    }
    // Waiting for an answer first; newest first in each group (the ISO time sorts as text; the id breaks a tie: sheet-0010 > sheet-0009).
    std::stable_sort(rows.begin(), rows.end(), [](const ReviewListRow& a, const ReviewListRow& b) {
        if ((a.picked == 0) != (b.picked == 0)) return a.picked == 0;
        if (a.createdAt != b.createdAt) return a.createdAt > b.createdAt;
        return a.id > b.id;
    });
    return rows;
}

int review_move_selection(int current, int count, int columns, ReviewMove move) {
    if (count < 1) return 0;
    if (current < 1 || current > count) return 1;
    columns = std::clamp(columns, 1, count);
    int next = current;
    switch (move) {
        case ReviewMove::Left: next = current - 1; break;
        case ReviewMove::Right: next = current + 1; break;
        case ReviewMove::Up: next = current - columns; break;
        case ReviewMove::Down: next = current + columns; break;
    }
    // Left and right stop at the ends; up and down stay in place at the top and bottom rows (the last row may be short).
    if (next < 1 || next > count) return current;
    return next;
}

int review_digit_selection(int digit, int count) { return digit >= 1 && digit <= 9 && digit <= count ? digit : 0; }

float review_fit_scale(int w, int h, float availW, float availH, float maxScale) {
    if (w <= 0 || h <= 0) return 1.0f;
    const float s = std::min(std::max(availW, 1.0f) / float(w), std::max(availH, 1.0f) / float(h));
    return std::clamp(s, 0.01f, maxScale);
}

void review_upload_size(int w, int h, int maxSide, int& outW, int& outH) {
    outW = std::max(0, w);
    outH = std::max(0, h);
    if (outW == 0 || outH == 0 || maxSide < 1) return;
    const int side = std::max(outW, outH);
    if (side <= maxSide) return;
    const double s = double(maxSide) / double(side);
    outW = std::max(1, int(std::lround(double(outW) * s)));
    outH = std::max(1, int(std::lround(double(outH) * s)));
    outW = std::min(outW, maxSide);
    outH = std::min(outH, maxSide);
}

std::optional<std::pair<int, int>> review_png_size(const std::uint8_t* d, std::size_t size) {
    static const std::uint8_t sig[8] = {0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n'};
    if (!d || size < 24 || !std::equal(sig, sig + 8, d) || d[12] != 'I' || d[13] != 'H' || d[14] != 'D' || d[15] != 'R') return std::nullopt;
    auto be32 = [&](std::size_t at) {
        return (std::uint32_t(d[at]) << 24) | (std::uint32_t(d[at + 1]) << 16) | (std::uint32_t(d[at + 2]) << 8) | std::uint32_t(d[at + 3]);
    };
    const std::uint32_t w = be32(16), h = be32(20);
    if (w == 0 || h == 0 || w > 0x7fffffffu || h > 0x7fffffffu) return std::nullopt;
    return std::make_pair(int(w), int(h));
}

ReviewPickPlan review_pick_plan(const ReviewSheetView& s, int n, bool drop, const std::string& note) {
    ReviewPickPlan plan;
    const bool candidates = s.kind == "assetCandidates";
    plan.command = candidates ? "assets.pick" : "review.pick";
    plan.canKeepFiles = !candidates;
    if (s.is_picked()) {
        plan.error = s.id + " was already answered: number " + std::to_string(s.picked_n()) + " was picked. A choice is final; make a new sheet to choose again.";
        return plan;
    }
    const ReviewItemView* chosen = s.item(n);
    if (!chosen) {
        plan.error = "Number " + std::to_string(n) + " is not on " + s.id + "; its numbers go from 1 to " + std::to_string(s.items.size()) + ".";
        return plan;
    }
    if (!chosen->ok) {
        plan.error = "Item " + std::to_string(n) + " failed to render" + (chosen->error.empty() ? std::string() : " (" + chosen->error + ")") + ", so it cannot be picked.";
        return plan;
    }
    if (candidates && s.slot.empty()) {
        plan.error = "This sheet of asset candidates has no slot in its meta, so assets.pick does not know where the picked file goes.";
        return plan;
    }
    plan.args = Json::object({{"sheet", s.id}, {"n", n}});
    if (candidates) plan.args["slot"] = s.slot;
    else plan.args["drop"] = drop;
    if (!note.empty()) plan.args["note"] = note.size() > 500 ? note.substr(0, 500) : note;
    if (!drop && !candidates) return plan;
    // The files the pick moves: the same rule as review_pick (other candidates with a file; each file once; never the picked one's).
    std::set<std::string> taken;
    const std::string chosenKey = chosen->source.empty() ? std::string() : review_path_key(chosen->source);
    for (const ReviewItemView& it : s.items) {
        if (!it.candidate || it.n == n || it.source.empty()) continue;
        const std::string key = review_path_key(it.source);
        if (key == chosenKey || !taken.insert(key).second) continue;
        std::string from = fs::normalize(it.source);
        if (from.empty()) from = it.source;
        plan.moves.push_back({it.n, it.label, from, s.dropDir + "/" + s.id + "/" + review_drop_file_name(it.n, from)});
    }
    return plan;
}

std::optional<ReviewHistoryRow> review_history_row(const Json& m) {
    const Json& p = member(m, "picked");
    if (!p.is_object()) return std::nullopt;
    ReviewHistoryRow r;
    r.id = str_of(m, "id");
    r.label = str_of(m, "label");
    r.kind = str_of(member(m, "meta"), "kind");
    r.count = member(m, "items").is_array() ? int(std::min<std::size_t>(member(m, "items").size(), 100000)) : 0;
    r.n = std::max(0, int_of(p, "n"));
    r.at = str_of(p, "at");
    r.who = str_of(p, "who");
    r.note = str_of(p, "note");
    r.pickedLabel = str_of(p, "label");
    if (const Json& at = member(p, "atUnix"); at.is_number()) {
        const double v = at.get<double>();
        r.atUnix = std::isfinite(v) ? std::int64_t(std::clamp(v, 0.0, 9.0e15)) : 0;
    }
    if (r.pickedLabel.empty())
        if (const Json& items = member(m, "items"); items.is_array() && r.n >= 1 && std::size_t(r.n) <= items.size())
            r.pickedLabel = str_of(items[std::size_t(r.n - 1)], "label");
    if (const Json& dropped = member(p, "dropped"); dropped.is_array())
        for (const Json& d : dropped) {
            if (!d.is_object()) continue;
            ReviewDroppedLine line;
            line.n = std::max(0, int_of(d, "n"));
            line.label = str_of(d, "label");
            line.from = str_of(d, "from");
            line.to = str_of(d, "to");
            line.status = str_of(d, "status");
            if (line.status.empty()) line.status = "moved";
            r.dropped.push_back(std::move(line));
        }
    return r;
}

void review_sort_history(std::vector<ReviewHistoryRow>& rows) {
    std::stable_sort(rows.begin(), rows.end(), [](const ReviewHistoryRow& a, const ReviewHistoryRow& b) {
        if (a.atUnix != b.atUnix) return a.atUnix > b.atUnix;
        if (a.at != b.at) return a.at > b.at;
        return a.id > b.id;
    });
}

Result<Json> review_level_seeds_args(const LevelGenOptions& o, int count, const std::string& sampleScene) {
    Result<Json> level = level_gen_arguments(o);
    if (!level.ok()) return level.error();
    if (count < kReviewSeedsMin || count > kReviewSeedsMax)
        return Error{"A sheet of seeds shows " + std::to_string(kReviewSeedsMin) + " to " + std::to_string(kReviewSeedsMax) + " levels, not " +
                         std::to_string(count) + ".",
                     "Set \"Seeds on a sheet\" to a number in that range; four to nine is what a person compares well."};
    if (o.width > kReviewLevelMaxSide || o.height > kReviewLevelMaxSide)
        return Error{"A level of " + std::to_string(o.width) + " x " + std::to_string(o.height) + " cells is too big for a review sheet.",
                     "A sheet draws levels up to " + std::to_string(kReviewLevelMaxSide) + " cells a side: make the Size smaller to compare seeds, then "
                     "generate the chosen seed at full size."};
    Json args = level.value();
    args.erase("seed");
    Json seeds = Json::array();
    std::int64_t seed = std::clamp<std::int64_t>(o.seed, 0, kLevelGenMaxSeed);
    for (int i = 0; i < count; ++i) {
        seeds.push_back(seed);
        seed = seed < kLevelGenMaxSeed ? seed + 1 : 0;
    }
    Json item = Json::object({{"level", args}, {"seeds", seeds}});
    Json meta = Json::object({{"kind", "levelSeeds"}, {"size", Json::array({o.width, o.height})}});
    if (o.sampleFile.empty()) {
        if (sampleScene.empty())
            return Error{"The sample is the entity '" + o.sampleEntity + "', and the scene it is in has no file yet.",
                         "Save the scene first (the sheet is made from the project as saved on disk), or use a level file as the sample."};
        item["sampleScene"] = sampleScene;
        meta["sampleEntity"] = o.sampleEntity;
        meta["sampleScene"] = sampleScene;
    } else {
        meta["sampleFile"] = o.sampleFile;
    }
    const std::string sampleName = o.sampleFile.empty() ? o.sampleEntity : o.sampleFile;
    return Json::object({{"label", "Which level? (" + sampleName + ", " + std::to_string(o.width) + " x " + std::to_string(o.height) + ")"},
                         {"items", Json::array({item})},
                         {"meta", meta}});
}

std::optional<std::int64_t> review_picked_level_seed(const Json& picked) {
    const Json& level = member(member(picked, "spec"), "level");
    const Json& seed = member(level, "seed");
    if (!seed.is_number_integer() && !seed.is_number_unsigned()) return std::nullopt;
    const std::int64_t s = seed.is_number_unsigned() ? std::int64_t(std::min<std::uint64_t>(seed.get<std::uint64_t>(), std::uint64_t(kLevelGenMaxSeed)))
                                                     : seed.get<std::int64_t>();
    if (s < 0 || s > kLevelGenMaxSeed) return std::nullopt;
    return s;
}

bool review_level_options_from_pick(const Json& picked, const Json& meta, LevelGenOptions& o) {
    const std::optional<std::int64_t> seed = review_picked_level_seed(picked);
    if (!seed || str_of(meta, "kind") != "levelSeeds") return false;
    const Json& level = member(member(picked, "spec"), "level");
    LevelGenOptions next = o;
    const std::string file = str_of(meta, "sampleFile"), entity = str_of(meta, "sampleEntity");
    if (!file.empty()) {
        next.sampleFile = file;
    } else if (!entity.empty()) {
        next.sampleFile.clear();
        next.sampleEntity = entity;
    } else {
        return false;
    }
    const Json& size = member(level, "size");
    if (size.is_array() && size.size() == 2 && size[0].is_number() && size[1].is_number()) {
        next.width = int(std::clamp(size[0].get<double>(), 1.0, 2048.0));
        next.height = int(std::clamp(size[1].get<double>(), 1.0, 2048.0));
    }
    next.seed = *seed;
    if (const std::string model = str_of(level, "model"); model == "overlapping" || model == "tiled") next.model = model;
    next.n = std::clamp(int_of(level, "n", next.n), 2, 5);
    const int sym = int_of(level, "symmetry", 1);
    next.symmetry = (sym == 2 || sym == 4 || sym == 8) ? sym : 1;
    next.periodic = bool_of(level, "periodic", false);
    Json extra = Json::object();
    if (level.is_object())
        for (auto it = level.begin(); it != level.end(); ++it) {
            const std::string& k = it.key();
            if (k == "sample" || k == "legend" || k == "size" || k == "seed" || k == "model" || k == "n" || k == "symmetry" || k == "periodic") continue;
            extra[k] = it.value();
        }
    next.extra = extra.empty() ? std::string() : extra.dump();
    o = next;
    return true;
}

}  // namespace fa::editor
