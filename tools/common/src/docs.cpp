#include "fa/tooling/docs.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <iterator>
#include <set>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/notices.h"
#include "util.h"

namespace fa {

namespace {

std::string doc_name_from_path(std::string_view path) {
    std::string stem(path.substr(path.rfind('/') == std::string_view::npos ? 0 : path.rfind('/') + 1));
    if (ends_with(stem, ".md")) stem.resize(stem.size() - 3);
    for (char& c : stem) c = c == '_' ? '-' : static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return stem;
}

std::string first_heading(const std::string& text) {
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line))
        if (line.rfind("# ", 0) == 0) return std::string(trim(line.substr(2)));
    return {};
}

std::vector<std::string> lines_of(const std::string& text) {
    std::vector<std::string> out;
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line)) out.push_back(line);
    return out;
}


// A heading line of the page ("## 9.23 Art" -> level 2, title "9.23 Art"), found outside code fences.
struct DocHeading {
    int level = 0;
    std::string title;
    size_t line = 0;  // 1-based
};

std::vector<DocHeading> headings_of(const std::vector<std::string>& lines) {
    std::vector<DocHeading> out;
    bool inFence = false;
    for (size_t i = 0; i < lines.size(); ++i) {
        const std::string& l = lines[i];
        if (l.rfind("```", 0) == 0 || l.rfind("~~~", 0) == 0) { inFence = !inFence; continue; }
        if (inFence || l.empty() || l[0] != '#') continue;
        size_t n = 0;
        while (n < l.size() && l[n] == '#') ++n;
        if (n > 6 || n >= l.size() || l[n] != ' ') continue;
        out.push_back({int(n), std::string(trim(l.substr(n))), i + 1});
    }
    return out;
}

// Cuts `s` to at most `n` bytes without splitting a UTF-8 character.
std::string cut_utf8(const std::string& s, size_t n) {
    if (s.size() <= n) return s;
    while (n > 0 && (static_cast<unsigned char>(s[n]) & 0xC0) == 0x80) --n;
    return s.substr(0, n);
}

// The table of contents of a page that was cut: headings with their line numbers, as many levels as fit in `budget` bytes.
std::string contents_text(const std::vector<DocHeading>& heads, size_t budget) {
    for (int maxLevel = 6; maxLevel >= 1; --maxLevel) {
        std::string out;
        for (const DocHeading& h : heads) {
            if (h.level > maxLevel) continue;
            out += std::string(size_t(h.level - 1) * 2, ' ') + "- " + h.title + " (line " + std::to_string(h.line) + ")\n";
        }
        if (out.size() <= budget || maxLevel == 1) return cut_utf8(out, budget);
    }
    return {};
}

constexpr long kDocReadDefaultBytes = 40000;  // ~10k tokens: an MCP tool result is capped near 25k tokens
constexpr long kDocReadMaxBytes = 90000;

}  // namespace

std::vector<DocInfo> list_docs() {
    std::vector<DocInfo> out;
    for (const auto& p : bundled_list("docs/")) {
        if (!ends_with(p, ".md")) continue;
        auto text = bundled_read(p);
        if (!text) continue;
        out.push_back({doc_name_from_path(p), p, first_heading(*text), text->size()});
    }
    return out;
}

Result<std::string> read_doc(std::string_view nameOrPath) {
    std::string q(trim(nameOrPath));
    if (q.rfind("factoria://docs/", 0) == 0) q = q.substr(16);
    if (q.rfind("docs/", 0) == 0 || q.rfind("schemas/", 0) == 0) {
        if (auto t = bundled_read(q)) return *t;
    }
    std::string want = doc_name_from_path(q);
    std::vector<std::string> names;
    for (const auto& d : list_docs()) {
        if (d.name == want) {
            if (auto t = bundled_read(d.path)) return *t;
        }
        names.push_back(d.name);
    }
    if (want == "components") return export_components_markdown();
    if (want == "licenses" || want == "license" || want == "notices" || want == "third-party-notices")
        return third_party_notices(NoticeScope::All);
    if (want == "schemas" || want == "schema") {
        std::string all;
        for (const auto& p : bundled_list("schemas/")) all += "## " + p + "\n\n```json\n" + bundled_read(p).value_or("") + "\n```\n\n";
        return all;
    }
    names.push_back("components");
    names.push_back("licenses");
    return make_error("No document named '" + q + "'. " + did_you_mean(want, names), "Use docs.list to see all documents.");
}

std::vector<DocHit> search_docs(std::string_view query, std::size_t maxResults) {
    std::vector<std::string> terms;
    for (const auto& t : split(to_lower(query), ' ')) terms.push_back(t);
    std::vector<DocHit> hits;
    if (terms.empty()) return hits;
    for (const auto& d : list_docs()) {
        auto text = bundled_read(d.path);
        if (!text) continue;
        auto lines = lines_of(*text);
        // Sections split at headings.
        size_t start = 0;
        std::string heading = d.title;
        auto flush = [&](size_t end) {
            double score = 0;
            int bestLine = -1;
            double bestLineScore = 0;
            std::string lowerHeading = to_lower(heading);
            for (const auto& t : terms)
                if (lowerHeading.find(t) != std::string::npos) score += 6;
            if (to_lower(d.name).find(to_lower(terms[0])) != std::string::npos) score += 1;
            size_t termsMatched = 0;
            std::vector<bool> matched(terms.size(), false);
            for (size_t i = start; i < end; ++i) {
                std::string l = to_lower(lines[i]);
                double ls = 0;
                for (size_t k = 0; k < terms.size(); ++k) {
                    size_t pos = 0, n = 0;
                    while ((pos = l.find(terms[k], pos)) != std::string::npos) { ++n; pos += terms[k].size(); }
                    if (n) { ls += 1 + 0.25 * double(n - 1); matched[k] = true; }
                }
                score += ls;
                if (ls > bestLineScore) { bestLineScore = ls; bestLine = int(i); }
            }
            for (bool m : matched) termsMatched += m;
            if (bestLine < 0 || termsMatched == 0) return;
            score *= 1.0 + double(termsMatched) / double(terms.size());  // reward covering all terms
            DocHit h;
            h.doc = d.name;
            h.path = d.path;
            h.heading = heading;
            h.line = bestLine + 1;
            h.score = score;
            size_t from = size_t(std::max<int>(int(start), bestLine - 1));
            size_t to = std::min(end, size_t(bestLine) + 4);
            std::string snip;
            for (size_t i = from; i < to; ++i) snip += lines[i] + "\n";
            if (snip.size() > 500) snip = snip.substr(0, 500) + "...";
            h.snippet = std::move(snip);
            hits.push_back(std::move(h));
        };
        bool inFence = false;
        for (size_t i = 0; i < lines.size(); ++i) {
            if (lines[i].rfind("```", 0) == 0) inFence = !inFence;
            if (!inFence && lines[i].rfind("#", 0) == 0 && i > start) {
                flush(i);
                start = i;
                heading = std::string(trim(lines[i].substr(lines[i].find_first_not_of('#'))));
            } else if (!inFence && lines[i].rfind("#", 0) == 0) {
                heading = std::string(trim(lines[i].substr(lines[i].find_first_not_of('#'))));
            }
        }
        flush(lines.size());
    }
    std::stable_sort(hits.begin(), hits.end(), [](const DocHit& a, const DocHit& b) { return a.score > b.score; });
    // Diverse top: each doc's best section first (by score), then every other section by score. Nothing is dropped; a
    // query for an API name no longer returns eight sections of one guide ahead of the reference. An explicit loop, not
    // std::stable_partition: libstdc++ copies the predicate, so a "seen" set inside it loses docs already counted.
    std::set<std::string> seen;
    std::vector<DocHit> ordered, rest;
    for (auto& h : hits) (seen.insert(h.doc).second ? ordered : rest).push_back(std::move(h));
    ordered.insert(ordered.end(), std::make_move_iterator(rest.begin()), std::make_move_iterator(rest.end()));
    if (ordered.size() > maxResults) ordered.resize(maxResults);
    return ordered;
}

void register_docs_commands(CommandRegistry& registry) {
    {
        CommandInfo info;
        info.name = "docs.list";
        info.category = "docs";
        info.summary = "List the engine documentation available offline.";
        info.description = "Start here. Returns name, title and size of each document; read one with docs.read. "
                           "The document 'ai-guide' explains how to build games with FactorIA.";
        registry.add(info, [](const Json&) {
            Json arr = Json::array();
            for (const auto& d : list_docs())
                arr.push_back(Json::object({{"name", d.name}, {"title", d.title}, {"path", d.path}, {"bytes", d.bytes}}));
            arr.push_back(Json::object({{"name", "components"}, {"title", "Components reference (generated)"}, {"path", ""}, {"bytes", 0}}));
            arr.push_back(Json::object({{"name", "licenses"}, {"title", "License notices: FactorIA and the third-party code inside it (generated)"}, {"path", ""}, {"bytes", 0}}));
            return Json::object({{"docs", arr}});
        });
    }
    {
        CommandInfo info;
        info.name = "docs.read";
        info.category = "docs";
        info.summary = "Read a documentation page (Markdown), a section or a line range; long pages come in parts.";
        info.description =
            "Example: {\"name\":\"scripting\"}. A result is at most `maxBytes` (default 40000, about 10k tokens; an MCP client refuses "
            "much more), so a long page is cut and the result then carries `contents` (the headings with their line numbers) and "
            "`next`, the exact call that continues. Read one section by heading: {\"name\":\"ai-guide\",\"heading\":\"Platformer character\"} "
            "(case-insensitive; an exact title wins, else a part of a title; several matches list them), or a range with "
            "startLine/maxLines. Names: see docs.list (e.g. ai-guide, architecture, scripting, components, licenses). "
            "To find where something is, docs.search returns sections with their line numbers.";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"name", Json::object({{"type", "string"}, {"description", "Doc name (\"scripting\") or path (\"docs/SCRIPTING.md\")."}})},
                                         {"heading", Json::object({{"type", "string"}, {"description", "Read only the section with this heading (and its subsections), e.g. \"Pause menu\". See `contents` of a cut read."}})},
                                         {"startLine", Json::object({{"type", "integer"}, {"minimum", 1}, {"description", "First line to return (1-based, default 1). With `heading`: the line to continue a long section from."}})},
                                         {"maxLines", Json::object({{"type", "integer"}, {"minimum", 1}, {"default", 2000}, {"description", "Maximum number of lines."}})},
                                         {"maxBytes", Json::object({{"type", "integer"}, {"minimum", 1000}, {"maximum", kDocReadMaxBytes}, {"default", kDocReadDefaultBytes}, {"description", "Maximum size of `content` in bytes; the read stops at a line boundary."}})}})},
            {"required", Json::array({"name"})}});
        registry.add(info, [](const Json& args) {
            const std::string name = tooling_detail::arg_string(args, "name", true);
            auto text = read_doc(name);
            if (!text.ok()) throw CommandError("not_found", text.error().message, text.error().hint);
            const auto lines = lines_of(*text);
            const long total = long(lines.size());
            const std::vector<DocHeading> heads = headings_of(lines);
            long start = std::max<long>(1, tooling_detail::arg_int(args, "startLine", 1));
            long end = total;  // last line (1-based) the read may reach
            const std::string wanted = tooling_detail::arg_string(args, "heading", false);
            std::string sectionTitle;
            if (!wanted.empty()) {
                const std::string w = to_lower(std::string(trim(wanted)));
                std::vector<const DocHeading*> exact, partial;
                for (const DocHeading& h : heads) {
                    const std::string t = to_lower(h.title);
                    if (t == w) exact.push_back(&h);
                    else if (t.find(w) != std::string::npos) partial.push_back(&h);
                }
                const std::vector<const DocHeading*>& found = !exact.empty() ? exact : partial;
                if (found.empty()) {
                    std::vector<std::string> titles;
                    for (const DocHeading& h : heads) titles.push_back(h.title);
                    throw CommandError("not_found", "Doc '" + name + "' has no heading matching '" + wanted + "'. " + did_you_mean(wanted, titles),
                                       "Read the page without `heading` to get its contents (headings with line numbers), or docs.search {\"query\":\"...\"}.");
                }
                if (found.size() > 1 && exact.empty()) {
                    std::string list;
                    for (size_t i = 0; i < found.size() && i < 12; ++i)
                        list += "\n  - \"" + found[i]->title + "\" (line " + std::to_string(found[i]->line) + ")";
                    throw CommandError("invalid_argument", "'" + wanted + "' matches " + std::to_string(found.size()) + " headings of '" + name + "':" + list,
                                       "Repeat the call with the full title of one of them, or with startLine.");
                }
                const DocHeading* h = found.front();
                sectionTitle = h->title;
                long sectionEnd = total;
                for (const DocHeading& n : heads)
                    if (n.line > h->line && n.level <= h->level) { sectionEnd = long(n.line) - 1; break; }
                if (!args.contains("startLine")) start = long(h->line);
                end = sectionEnd;
            }
            const long maxLines = std::max<long>(1, tooling_detail::arg_int(args, "maxLines", 2000));
            const long maxBytes = std::clamp<long>(tooling_detail::arg_int(args, "maxBytes", kDocReadDefaultBytes), 1000, kDocReadMaxBytes);
            std::string out;
            long last = start - 1;  // last line included
            for (long i = start - 1; i < end && i - (start - 1) < maxLines; ++i) {
                const std::string& l = lines[size_t(i)];
                if (long(out.size() + l.size() + 1) > maxBytes) {
                    if (out.empty()) {  // one line longer than the budget: return its start
                        out = cut_utf8(l, size_t(maxBytes)) + "\n";
                        last = i + 1;
                    }
                    break;
                }
                out += l + "\n";
                last = i + 1;
            }
            const bool truncated = last < end;
            Json r = Json::object({{"name", name}, {"content", out}, {"startLine", start}, {"endLine", last}, {"totalLines", total},
                                   {"truncated", truncated}});
            if (!sectionTitle.empty()) r["heading"] = sectionTitle;
            if (truncated) {
                {
                    r["nextStartLine"] = last + 1;
                    Json call = Json::object({{"name", name}, {"startLine", last + 1}});
                    if (!sectionTitle.empty()) call["heading"] = sectionTitle;
                    r["next"] = "docs.read " + call.dump() + " continues from line " + std::to_string(last + 1) + " of " + std::to_string(total) + ".";
                }
                r["contents"] = contents_text(heads, 8000);
                r["readSection"] = "docs.read {\"name\":\"" + name + "\",\"heading\":\"<a heading of `contents`>\"} reads one section; "
                                   "startLine/maxLines read a range of the lines numbered in `contents`.";
            }
            return r;
        });
    }
    {
        CommandInfo info;
        info.name = "docs.search";
        info.category = "docs";
        info.summary = "Search the documentation by keywords.";
        info.description = "Case-insensitive; every word counts, headings weigh more. Returns best sections with a snippet. "
                           "Example: {\"query\":\"input actions\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"query", Json::object({{"type", "string"}, {"description", "Keywords."}})},
                                         {"limit", Json::object({{"type", "integer"}, {"minimum", 1}, {"maximum", 50}, {"default", 8}, {"description", "Max results."}})}})},
            {"required", Json::array({"query"})}});
        registry.add(info, [](const Json& args) {
            auto hits = search_docs(tooling_detail::arg_string(args, "query", true), size_t(tooling_detail::arg_int(args, "limit", 8)));
            Json arr = Json::array();
            for (const auto& h : hits)
                arr.push_back(Json::object({{"doc", h.doc}, {"heading", h.heading}, {"line", h.line},
                                            {"score", std::round(h.score * 100) / 100}, {"snippet", h.snippet}}));
            return Json::object({{"count", arr.size()}, {"results", arr}});
        });
    }
}

}  // namespace fa
