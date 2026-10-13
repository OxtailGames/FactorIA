#include "fa/tooling/docs.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
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
    if (want == "schemas" || want == "schema") {
        std::string all;
        for (const auto& p : bundled_list("schemas/")) all += "## " + p + "\n\n```json\n" + bundled_read(p).value_or("") + "\n```\n\n";
        return all;
    }
    names.push_back("components");
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
    if (hits.size() > maxResults) hits.resize(maxResults);
    return hits;
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
            return Json::object({{"docs", arr}});
        });
    }
    {
        CommandInfo info;
        info.name = "docs.read";
        info.category = "docs";
        info.summary = "Read a documentation page (Markdown).";
        info.description = "Example: {\"name\":\"scripting\"}. Long pages can be read in slices with startLine/maxLines. "
                           "Names: see docs.list (e.g. ai-guide, architecture, scripting, components).";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"name", Json::object({{"type", "string"}, {"description", "Doc name (\"scripting\") or path (\"docs/SCRIPTING.md\")."}})},
                                         {"startLine", Json::object({{"type", "integer"}, {"minimum", 1}, {"default", 1}, {"description", "First line to return (1-based)."}})},
                                         {"maxLines", Json::object({{"type", "integer"}, {"minimum", 1}, {"default", 2000}, {"description", "Maximum number of lines."}})}})},
            {"required", Json::array({"name"})}});
        registry.add(info, [](const Json& args) {
            std::string name = tooling_detail::arg_string(args, "name", true);
            auto text = read_doc(name);
            if (!text.ok()) throw CommandError("not_found", text.error().message, text.error().hint);
            auto lines = lines_of(*text);
            long start = std::max<long>(1, tooling_detail::arg_int(args, "startLine", 1));
            long maxLines = std::max<long>(1, tooling_detail::arg_int(args, "maxLines", 2000));
            std::string out;
            long last = std::min<long>(long(lines.size()), start - 1 + maxLines);
            for (long i = start - 1; i < last; ++i) out += lines[size_t(i)] + "\n";
            return Json::object({{"name", name}, {"content", out}, {"startLine", start}, {"endLine", last},
                                 {"totalLines", lines.size()}, {"truncated", last < long(lines.size())}});
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
