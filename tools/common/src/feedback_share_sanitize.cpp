// The sanitizer of feedback sharing (fa/tooling/feedback_share.h): deterministic, no AI, no network.
#include <algorithm>
#include <cctype>
#include <cstring>
#include <optional>
#include <filesystem>
#include <map>
#include <set>
#include <unordered_map>

#include "fa/core/reflect.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/feedback_share.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

bool is_ascii_alpha(unsigned char c) { return std::isalpha(c) != 0; }
bool is_word_char(unsigned char c) { return std::isalnum(c) || c == '_' || c >= 0x80; }
bool is_space(unsigned char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

std::string ascii_lower(std::string_view s) {
    std::string out(s);
    for (char& c : out)
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
    return out;
}

std::string shorten(std::string_view s, std::size_t max = 60) {
    std::string t(trim(s));
    if (t.size() <= max) return t;
    std::size_t cut = max;
    while (cut > 0 && (static_cast<unsigned char>(t[cut]) & 0xC0) == 0x80) --cut;  // not inside a UTF-8 sequence
    return t.substr(0, cut) + "...";
}

// Code points of a UTF-8 string (invalid bytes count one each).
std::size_t code_points(std::string_view s) {
    std::size_t n = 0;
    for (unsigned char c : s)
        if ((c & 0xC0) != 0x80) ++n;
    return n;
}

bool identifier_like(std::string_view s) {
    if (s.empty()) return false;
    if (!(is_ascii_alpha(static_cast<unsigned char>(s[0])) || s[0] == '_')) return false;
    for (unsigned char c : s)
        if (!(std::isalnum(c) || c == '_')) return false;
    return true;
}

// Words that say nothing about a game: never removed as "the project's names" (an entity called "Player" does not make the
// word "player" secret).
const std::set<std::string>& generic_words() {
    static const std::set<std::string> w = {
        "main", "index", "icon", "game", "scene", "scenes", "level", "levels", "player", "players", "enemy", "enemies",
        "menu", "title", "button", "text", "image", "images", "sound", "sounds", "music", "audio", "sprite", "sprites",
        "camera", "light", "lights", "hud", "background", "test", "tests", "script", "scripts", "asset", "assets",
        "data", "config", "settings", "start", "end", "world", "map", "maps", "item", "items", "ground", "wall",
        "walls", "door", "doors", "floor", "root", "none", "default", "empty", "new", "untitled", "example", "demo",
        "sample", "prefab", "prefabs", "entity", "entities", "body", "bodies", "shape", "label", "panel", "bar",
        "score", "lives", "life", "health", "timer", "coin", "coins", "goal", "spawn", "spawner", "manager", "controller",
        "state", "input", "effect", "effects", "particle", "particles", "collider", "trigger", "platform", "platforms",
        "tile", "tiles", "tilemap", "layer", "layers", "bullet", "bullets", "target", "box", "boxes", "ball", "name",
        "id", "type", "value", "values", "list", "page", "pages", "screen", "view", "window", "dialog", "popup", "intro",
        "outro", "credits", "options", "pause", "resume", "quit", "play", "load", "save", "back", "next", "yes", "no"};
    return w;
}

// -------------------------------------------------------------------------------------------------------------------- tokens

const std::set<std::string>& strong_extensions() {
    static const std::set<std::string> e = {
        "js", "mjs", "cjs", "ts", "tsx", "jsx", "json", "json5", "yaml", "yml", "toml", "xml", "html", "htm", "css", "md",
        "txt", "csv", "tsv", "ini", "cfg", "conf", "png", "jpg", "jpeg", "gif", "bmp", "tga", "webp", "svg", "ico", "psd",
        "ase", "aseprite", "wav", "ogg", "mp3", "flac", "qoa", "mp4", "webm", "mov", "avi", "glb", "gltf", "obj", "fbx",
        "mtl", "blend", "ttf", "otf", "woff", "woff2", "zip", "tar", "gz", "7z", "rar", "exe", "dll", "dylib", "dmg",
        "msi", "apk", "aab", "ipa", "pck", "cpp", "hpp", "mm", "py", "rb", "sh", "bat", "ps1", "lua", "java", "kt",
        "swift", "pdf", "docx", "xlsx", "pptx", "tmx", "atlas", "sqlite", "sav"};
    return e;
}
// Real file extensions that are also ordinary words or names of engine members ("console.log", "Body.mat"): flagged only
// when the part before the dot is not an engine name.
const std::set<std::string>& weak_extensions() {
    static const std::set<std::string> e = {"log", "doc", "app", "bin", "dat", "mat", "db", "lock", "go", "so", "cc", "c",
                                            "h", "rs", "cmd", "cs", "scene", "prefab", "material", "xls", "ppt"};
    return e;
}
const std::set<std::string>& domain_endings() {
    static const std::set<std::string> e = {"com", "org", "net", "io", "dev", "gg", "xyz", "info"};
    return e;
}

// "and/or" style pairs and fractions are prose, not paths.
bool prose_slash(std::string_view core) {
    static const std::set<std::string> pairs = {"and/or", "true/false", "on/off", "x/y", "input/output", "read/write",
                                                "yes/no", "either/or", "he/she", "s/he", "w/o", "km/h", "i/o", "up/down",
                                                "left/right", "min/max", "start/stop", "in/out", "pass/fail", "w/h",
                                                "r/g/b", "x/y/z", "r/g/b/a", "width/height", "begin/end", "on/off/auto"};
    const std::string lc = ascii_lower(core);
    if (pairs.count(lc)) return true;
    // 16/9, 60/30, 24/7
    std::size_t slash = lc.find('/');
    if (slash != std::string::npos && lc.find('/', slash + 1) == std::string::npos) {
        auto digits = [](std::string_view p) { return !p.empty() && std::all_of(p.begin(), p.end(), [](unsigned char c) { return std::isdigit(c); }); };
        if (digits(std::string_view(lc).substr(0, slash)) && digits(std::string_view(lc).substr(slash + 1))) return true;
    }
    return false;
}

struct Cleaner {
    const EngineNames& engine;
    std::string field;
    std::vector<Removal>& removed;
    bool controlNoted = false;

    void note(const std::string& kind, std::string_view text) { removed.push_back({field, kind, shorten(text)}); }
};

bool trivial_word(std::string_view w) {
    static const std::set<std::string> t = {"bool", "boolean", "int", "float", "string", "number", "true", "false", "null",
                                            "undefined", "object", "array", "void", "vec2", "vec3", "vec4", "color"};
    if (w.empty()) return true;
    if (t.count(ascii_lower(w))) return true;
    return std::all_of(w.begin(), w.end(), [](unsigned char c) { return std::isdigit(c) || c == '.' || c == '-' || c == '+'; });
}

// A quoted text that the engine itself defines: every word is an engine name (or a plain type word), and at least one is.
bool engine_phrase(std::string_view inner, const EngineNames& engine) {
    inner = trim(inner);
    if (inner.empty() || inner.size() > 80) return false;
    bool anyEngine = false;
    std::size_t i = 0;
    while (i < inner.size()) {
        while (i < inner.size() && is_space(static_cast<unsigned char>(inner[i]))) ++i;
        std::size_t j = i;
        while (j < inner.size() && !is_space(static_cast<unsigned char>(inner[j]))) ++j;
        std::string word(inner.substr(i, j - i));
        i = j;
        std::size_t b = 0, e = word.size();
        while (b < e && std::strchr(",;:()[]{}<>", word[b])) ++b;
        while (e > b && std::strchr(",;:()[]{}<>.", word[e - 1])) --e;
        word = word.substr(b, e - b);
        if (word.empty()) continue;
        if (engine.token_ok(word)) { anyEngine = true; continue; }
        if (trivial_word(word)) continue;
        return false;
    }
    return anyEngine;
}

// Step: control characters and invisible marks.
std::string strip_control(std::string_view s, Cleaner& cx) {
    std::string out;
    out.reserve(s.size());
    auto drop = [&](std::size_t n, std::size_t& i) {
        if (!cx.controlNoted) {
            cx.note("control", "control or invisible characters");
            cx.controlNoted = true;
        }
        i += n;
    };
    for (std::size_t i = 0; i < s.size();) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        if (c == '\n' || c == '\r' || c == '\t') { out += ' '; ++i; continue; }
        if (c < 0x20 || c == 0x7f) { drop(1, i); continue; }
        if (c == 0xC2 && i + 1 < s.size() && static_cast<unsigned char>(s[i + 1]) >= 0x80 && static_cast<unsigned char>(s[i + 1]) <= 0x9F) { drop(2, i); continue; }
        if (c == 0xE2 && i + 2 < s.size()) {
            const unsigned char d = static_cast<unsigned char>(s[i + 1]), e = static_cast<unsigned char>(s[i + 2]);
            if (d == 0x80 && ((e >= 0x8B && e <= 0x8F) || (e >= 0xA8 && e <= 0xAE))) { drop(3, i); continue; }  // zero width, bidi marks
            if (d == 0x81 && e >= 0xA0 && e <= 0xAF) { drop(3, i); continue; }
        }
        if (c == 0xEF && i + 2 < s.size() && static_cast<unsigned char>(s[i + 1]) == 0xBB && static_cast<unsigned char>(s[i + 2]) == 0xBF) { drop(3, i); continue; }
        out += static_cast<char>(c);
        ++i;
    }
    return out;
}

// Step: quoted text other than engine names.
std::string remove_quotes(const std::string& s, Cleaner& cx) {
    struct Pair { const char* open; const char* close; };
    static const Pair pairs[] = {{"```", "```"}, {"\"", "\""}, {"`", "`"}, {"\xC2\xAB", "\xC2\xBB"},
                                 {"\xE2\x80\x9C", "\xE2\x80\x9D"}, {"\xE2\x80\x98", "\xE2\x80\x99"}, {"'", "'"}};
    std::string out;
    const std::size_t n = s.size();
    for (std::size_t i = 0; i < n;) {
        bool handled = false;
        for (const Pair& p : pairs) {
            const std::size_t olen = std::strlen(p.open);
            if (s.compare(i, olen, p.open) != 0) continue;
            std::size_t closeAt = std::string::npos;
            const std::size_t clen = std::strlen(p.close);
            if (p.open[0] == '\'' && olen == 1) {
                // An apostrophe opens a quote only after a space or an opening bracket, and closes before a non-word char.
                const bool opens = (i == 0 || std::strchr(" ([{<-:;,\"", s[i - 1])) && i + 1 < n && !is_space(static_cast<unsigned char>(s[i + 1]));
                if (!opens) continue;
                for (std::size_t j = i + 1; j < n; ++j)
                    if (s[j] == '\'' && !is_space(static_cast<unsigned char>(s[j - 1])) && (j + 1 == n || !is_word_char(static_cast<unsigned char>(s[j + 1])))) {
                        closeAt = j;
                        break;
                    }
            } else {
                closeAt = s.find(p.close, i + olen);
            }
            if (closeAt == std::string::npos) continue;
            const std::string inner = s.substr(i + olen, closeAt - (i + olen));
            const std::size_t endAt = closeAt + clen;
            if (engine_phrase(inner, cx.engine)) {
                out.append(s, i, endAt - i);  // an engine name: stays, quotes included
            } else {
                cx.note("quote", s.substr(i, endAt - i));
                out += ' ';
            }
            i = endAt;
            handled = true;
            break;
        }
        if (!handled) out += s[i++];
    }
    return out;
}

// What a token (without the punctuation around it) is, when it must go: "url" | "email" | "path" | "file" | "".
std::string classify_token(std::string_view core, const EngineNames& engine) {
    const std::string lc = ascii_lower(core);
    if (lc.find("://") != std::string::npos || lc.rfind("www.", 0) == 0 || lc.rfind("mailto:", 0) == 0) return "url";
    if (const std::size_t at = core.find('@'); at != std::string_view::npos && at > 0 && at + 1 < core.size() &&
                                              std::isalnum(static_cast<unsigned char>(core[at - 1])))
        return "email";
    if (engine.has(lc)) return "";
    if (core.find('/') != std::string_view::npos || core.find('\\') != std::string_view::npos || core[0] == '~') {
        std::vector<std::string> segs;
        std::string cur;
        for (char c : core) {
            if (c == '/' || c == '\\') { segs.push_back(cur); cur.clear(); }
            else cur += c;
        }
        segs.push_back(cur);
        bool all = !segs.empty() && core[0] != '/' && core[0] != '\\' && core[0] != '~';
        for (const std::string& seg : segs) all = all && !seg.empty() && engine.token_ok(seg);
        if (all) return "";
        if (core.find('\\') == std::string_view::npos && prose_slash(core)) return "";
        return "path";
    }
    const std::size_t dot = lc.rfind('.');
    if (dot != std::string::npos && dot + 1 < lc.size()) {
        const std::string ext = lc.substr(dot + 1);
        const std::string base = lc.substr(0, dot);
        if (dot == 0) return ext.size() >= 2 && std::all_of(ext.begin(), ext.end(), [](unsigned char c) { return std::isalpha(c); }) ? "file" : "";
        if (strong_extensions().count(ext)) return "file";
        if (weak_extensions().count(ext) && !engine.token_ok(core)) return "file";
        if (domain_endings().count(ext) && base.find_first_not_of("abcdefghijklmnopqrstuvwxyz0123456789-.") == std::string::npos) return "url";
    }
    return "";
}

// Step: URLs, e-mail addresses, paths and file names, token by token.
std::string remove_tokens(const std::string& s, Cleaner& cx) {
    std::string out;
    const std::size_t n = s.size();
    for (std::size_t i = 0; i < n;) {
        if (is_space(static_cast<unsigned char>(s[i]))) { out += s[i++]; continue; }
        std::size_t j = i;
        while (j < n && !is_space(static_cast<unsigned char>(s[j]))) ++j;
        const std::string tok = s.substr(i, j - i);
        i = j;
        std::size_t b = 0, e = tok.size();
        while (b < e && std::strchr("([{<\"'`", tok[b])) ++b;
        while (e > b && std::strchr(")]}>,;:!?.\"'`", tok[e - 1])) --e;
        const std::string core = tok.substr(b, e - b);
        const std::string kind = core.empty() ? std::string() : classify_token(core, cx.engine);
        if (kind.empty()) { out += tok; continue; }
        cx.note(kind, core);
        for (std::size_t k = e; k < tok.size(); ++k)
            if (std::strchr(".,;:!?", tok[k])) out += tok[k];  // the sentence punctuation after it stays
        out += ' ';
    }
    return out;
}

// The patterns of the project's names, lower case, longest first, without what must never be removed.
struct NamePatterns {
    std::unordered_map<char, std::vector<std::string>> byFirst;
};

void add_pattern(std::set<std::string>& set, const std::string& name, const EngineNames& engine) {
    std::string lc = ascii_lower(trim(name));
    if (lc.size() < 3) return;
    if (std::all_of(lc.begin(), lc.end(), [](unsigned char c) { return std::isdigit(c) || c == '.' || c == '-' || c == '_'; })) return;
    if (engine.has(lc) || generic_words().count(lc)) return;
    set.insert(lc);
}

NamePatterns build_patterns(const ProjectNames& project, const EngineNames& engine) {
    std::set<std::string> set;
    for (const std::string& name : project.names) {
        add_pattern(set, name, engine);
        // "boss_arena" and "boss-arena" also written "boss arena"; "BossArena" too.
        std::string spaced, camel;
        for (std::size_t k = 0; k < name.size(); ++k) {
            const char c = name[k];
            if (c == '_' || c == '-') spaced += ' ';
            else {
                if (k > 0 && std::isupper(static_cast<unsigned char>(c)) && std::islower(static_cast<unsigned char>(name[k - 1]))) camel += ' ';
                camel += c;
                spaced += c;
            }
        }
        if (spaced != name) add_pattern(set, spaced, engine);
        if (camel != name && camel != spaced) add_pattern(set, camel, engine);
        // Each long word of a multi-word name ("Lantern Keep" -> "Lantern") is part of the name too.
        if (name.find(' ') != std::string::npos)
            for (const std::string& word : split(name, ' '))
                if (word.size() >= 5) add_pattern(set, word, engine);
    }
    NamePatterns out;
    for (const std::string& p : set) out.byFirst[p[0]].push_back(p);
    for (auto& [k, v] : out.byFirst)
        std::sort(v.begin(), v.end(), [](const std::string& a, const std::string& b) { return a.size() != b.size() ? a.size() > b.size() : a < b; });
    return out;
}

std::string remove_project_names(const std::string& s, const NamePatterns& patterns, Cleaner& cx) {
    if (patterns.byFirst.empty()) return s;
    const std::string ls = ascii_lower(s);
    std::string out;
    const std::size_t n = s.size();
    for (std::size_t i = 0; i < n;) {
        const bool boundary = i == 0 || !is_word_char(static_cast<unsigned char>(s[i - 1]));
        if (boundary) {
            auto it = patterns.byFirst.find(ls[i]);
            bool hit = false;
            if (it != patterns.byFirst.end()) {
                for (const std::string& p : it->second) {
                    if (ls.compare(i, p.size(), p) != 0) continue;
                    const std::size_t end = i + p.size();
                    if (end < n && is_word_char(static_cast<unsigned char>(s[end]))) continue;
                    cx.note("project-name", s.substr(i, p.size()));
                    out += ' ';
                    i = end;
                    hit = true;
                    break;
                }
            }
            if (hit) continue;
        }
        out += s[i++];
    }
    return out;
}

// Step: whitespace, the brackets and quotes the removals emptied, space before punctuation.
std::string tidy(std::string s) {
    for (bool changed = true; changed;) {
        changed = false;
        // collapse whitespace
        std::string t;
        bool prevSpace = true;
        for (char c : s) {
            if (is_space(static_cast<unsigned char>(c))) {
                if (!prevSpace) t += ' ';
                prevSpace = true;
            } else {
                t += c;
                prevSpace = false;
            }
        }
        while (!t.empty() && t.back() == ' ') t.pop_back();
        // empty bracket pairs and quote pairs, with spaces inside
        std::string u;
        for (std::size_t i = 0; i < t.size(); ++i) {
            const char c = t[i];
            const char close = c == '(' ? ')' : c == '[' ? ']' : c == '{' ? '}' : c == '<' ? '>' : 0;
            if (close) {
                std::size_t k = i + 1;
                while (k < t.size() && t[k] == ' ') ++k;
                if (k < t.size() && t[k] == close) { i = k; changed = true; continue; }
            }
            if ((c == '"' || c == '`') && i + 1 < t.size() && t[i + 1] == c) { ++i; changed = true; continue; }
            u += c;
        }
        // space before , . ; : ! ?
        std::string v;
        for (std::size_t i = 0; i < u.size(); ++i) {
            if (u[i] == ' ' && i + 1 < u.size() && std::strchr(",.;:!?", u[i + 1])) { changed = true; continue; }
            v += u[i];
        }
        // ",," and ", ," -> ","
        std::string w;
        for (std::size_t i = 0; i < v.size(); ++i) {
            if (v[i] == ',' && !w.empty() && w.back() == ',') { changed = true; continue; }
            w += v[i];
        }
        // leading punctuation
        std::size_t lead = 0;
        while (lead < w.size() && (std::strchr(",;:", w[lead]) || w[lead] == ' ')) ++lead;
        if (lead) changed = true;
        s = w.substr(lead);
    }
    return s;
}

// Step: a character repeated more than 8 times is cut to 3.
std::string limit_runs(const std::string& s, Cleaner& cx) {
    std::string out;
    std::size_t i = 0;
    bool noted = false;
    while (i < s.size()) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        std::size_t len = c < 0x80 ? 1 : (c >= 0xF0 ? 4 : c >= 0xE0 ? 3 : c >= 0xC0 ? 2 : 1);
        len = std::min(len, s.size() - i);
        const std::string ch = s.substr(i, len);
        std::size_t run = 1;
        while (s.compare(i + run * len, len, ch) == 0 && i + (run + 1) * len <= s.size()) ++run;
        if (run > 8) {
            if (!noted) { cx.note("repeat", "a character repeated " + std::to_string(run) + " times"); noted = true; }
            for (int k = 0; k < 3; ++k) out += ch;
        } else {
            for (std::size_t k = 0; k < run; ++k) out += ch;
        }
        i += run * len;
    }
    return out;
}

std::string clean_field(Cleaner& cx, std::string_view text, const NamePatterns& patterns) {
    std::string s = strip_control(text, cx);
    s = remove_quotes(s, cx);
    s = remove_tokens(s, cx);
    s = remove_project_names(s, patterns, cx);
    s = tidy(std::move(s));
    s = limit_runs(s, cx);
    return std::string(trim(s));
}

double letter_ratio(std::string_view s) {
    std::size_t letters = 0, total = 0;
    for (unsigned char c : s) {
        if (is_space(c)) continue;
        ++total;
        if (is_ascii_alpha(c) || c >= 0x80) ++letters;
    }
    return total ? double(letters) / double(total) : 0.0;
}

std::size_t word_count(std::string_view s) {
    std::size_t n = 0;
    bool in = false;
    for (unsigned char c : s) {
        if (is_space(c)) in = false;
        else if (!in) { in = true; ++n; }
    }
    return n;
}

std::string removal_summary(const std::vector<Removal>& removed, const std::string& field) {
    std::map<std::string, int> counts;
    for (const Removal& r : removed)
        if (r.field == field) ++counts[r.kind];
    if (counts.empty()) return {};
    std::string out;
    for (const auto& [kind, n] : counts) out += (out.empty() ? "" : ", ") + std::to_string(n) + " " + kind + (n > 1 ? "s" : "");
    return " (removed: " + out + ")";
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------ EngineNames

bool EngineNames::has(std::string_view name) const { return lower.count(ascii_lower(name)) != 0; }

bool EngineNames::token_ok(std::string_view token) const {
    std::string t(token);
    while (t.size() > 2 && t.compare(t.size() - 2, 2, "()") == 0) t.resize(t.size() - 2);
    if (t.empty()) return false;
    if (has(t)) return true;
    const std::vector<std::string> parts = split(t, '.', false);
    if (parts.size() < 2) return false;
    bool all = true;
    for (const std::string& p : parts) all = all && !p.empty() && has(p);
    if (all) return true;
    if (!has(parts[0])) return false;  // "Collider2D.oneWay": a member the engine does not have (yet) of a type it has
    for (std::size_t i = 1; i < parts.size(); ++i)
        if (!identifier_like(parts[i])) return false;
    return true;
}

EngineNames collect_engine_names(const CommandRegistry* registry) {
    EngineNames names;
    auto add = [&](std::string_view n) {
        if (!n.empty()) names.lower.insert(ascii_lower(n));
    };
    auto add_dotted = [&](std::string_view full) {
        add(full);
        for (const std::string& part : split(full, '.')) add(part);
        add(replace_all(std::string(full), ".", "_"));
    };
    ensure_builtin_components();
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        add(t->name);
        for (const FieldInfo& f : t->fields) {
            add(f.name);
            add(t->name + "." + f.name);
            for (const std::string& e : f.enumNames) add(e);
        }
    }
    if (registry) {
        for (const CommandInfo* c : registry->list()) {
            add_dotted(c->name);
            if (c->inputSchema.is_object() && c->inputSchema.contains("properties") && c->inputSchema["properties"].is_object())
                for (auto it = c->inputSchema["properties"].begin(); it != c->inputSchema["properties"].end(); ++it) add(it.key());
        }
    }
    // What the engine has published: components, fields, commands and the scripting API (also the commands of a registry
    // this process does not have, e.g. `factoria feedback share` without a project).
    if (auto text = bundled_read(kApiSincePath)) {
        auto parsed = parse_json(*text, kApiSincePath);
        if (parsed.ok() && parsed->is_object())
            for (auto section = parsed->begin(); section != parsed->end(); ++section) {
                if (!section->is_object()) continue;
                for (auto it = section->begin(); it != section->end(); ++it) {
                    std::string key = it.key();
                    if (const std::size_t colon = key.find(':'); colon != std::string::npos) key = key.substr(colon + 1);
                    add_dotted(key);
                }
            }
    }
    return names;
}

// ---------------------------------------------------------------------------------------------------------- ProjectNames

namespace {

void collect_entity_names(const Json& node, std::set<std::string>& out, int depth = 0) {
    if (depth > 64) return;
    if (node.is_object()) {
        const bool entity = node.contains("components") && node["components"].is_object();
        for (auto it = node.begin(); it != node.end(); ++it) {
            if (entity && (it.key() == "name" || it.key() == "id") && it->is_string()) out.insert(it->get<std::string>());
            else collect_entity_names(*it, out, depth + 1);
        }
    } else if (node.is_array()) {
        for (const Json& v : node) collect_entity_names(v, out, depth + 1);
    }
}

// Localization keys: the object keys, joined with dots down to the leaves (menu.play).
void collect_locale_keys(const Json& node, const std::string& prefix, std::set<std::string>& out, int depth = 0) {
    if (depth > 16 || !node.is_object()) return;
    for (auto it = node.begin(); it != node.end(); ++it) {
        const std::string key = prefix.empty() ? it.key() : prefix + "." + it.key();
        out.insert(key);
        if (it->is_object()) collect_locale_keys(*it, key, out, depth + 1);
    }
}

}  // namespace

ProjectNames collect_project_names(const std::string& projectDir) {
    std::set<std::string> names;
    std::error_code ec;
    const stdfs::path root(projectDir);
    if (projectDir.empty() || !stdfs::is_directory(root, ec)) return {};
    names.insert(stdfs::weakly_canonical(root, ec).filename().string());
    if (auto text = tooling_detail::read_file(root / "factoria.json")) {
        auto pj = parse_json(*text, "factoria.json");
        if (pj.ok() && pj->is_object()) {
            const std::string name = pj->value("name", std::string());
            const std::string id = pj->value("id", std::string());
            if (!name.empty() && name != "Untitled") names.insert(name);
            if (!id.empty() && id != "com.example.game") {
                names.insert(id);
                if (const std::size_t dot = id.rfind('.'); dot != std::string::npos) names.insert(id.substr(dot + 1));
            }
        }
    }
    static const std::set<std::string> skipDirs = {"build", "node_modules", "types", "dist", "export", "out", "external", "platforms"};
    static const std::set<std::string> skipFiles = {"factoria.json", "assets.json", "jsconfig.json", "readme", "agents", "claude",
                                                    "engine_feedback", "package", "tsconfig"};
    std::size_t files = 0;
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string fname = it->path().filename().string();
        if (it->is_directory(ec)) {
            if (fname.empty() || fname[0] == '.' || skipDirs.count(fname)) it.disable_recursion_pending();
            continue;
        }
        if (!it->is_regular_file(ec) || fname.empty() || fname[0] == '.') continue;
        if (++files > 20000) break;
        const std::string stem = fname.substr(0, fname.find('.'));
        if (!skipFiles.count(ascii_lower(stem))) names.insert(stem);
        const std::string lname = ascii_lower(fname);
        const bool scene = ends_with(lname, ".scene.json") || ends_with(lname, ".prefab.json");
        const std::string rel = it->path().lexically_relative(root).generic_string();
        const bool locale = rel.rfind("locales/", 0) == 0 && ends_with(lname, ".json");
        if (!scene && !locale) continue;
        if (it->file_size(ec) > 8u * 1024 * 1024) continue;
        auto text = tooling_detail::read_file(it->path());
        if (!text) continue;
        auto parsed = parse_json(*text, fname);
        if (!parsed.ok()) continue;
        if (scene) collect_entity_names(*parsed, names);
        else collect_locale_keys(*parsed, {}, names);
    }
    ProjectNames out;
    for (const std::string& n : names)
        if (!trim(n).empty()) out.names.push_back(n);
    std::sort(out.names.begin(), out.names.end(), [](const std::string& a, const std::string& b) { return a.size() != b.size() ? a.size() > b.size() : a < b; });
    return out;
}

// ------------------------------------------------------------------------------------------------------------- sanitizer

Json Removal::to_json() const { return Json::object({{"field", field}, {"kind", kind}, {"text", text}}); }

std::string SanitizedShare::reason() const {
    std::string out;
    for (const std::string& p : problems) out += (out.empty() ? "" : "; ") + p;
    return out;
}

Json SanitizedShare::fields() const {
    Json j = Json::object();
    j["title"] = title;
    j["missing"] = missing;
    if (!suggestion.empty()) j["suggestion"] = suggestion;
    if (!workaround.empty()) j["workaround"] = workaround;
    return j;
}

Json SanitizedShare::removed_json() const {
    Json arr = Json::array();
    for (const Removal& r : removed) arr.push_back(r.to_json());
    return arr;
}

std::string sanitize_text(std::string_view field, std::string_view text, const EngineNames& engine, const ProjectNames& project,
                          std::vector<Removal>& removed) {
    Cleaner cx{engine, std::string(field), removed};
    return clean_field(cx, text, build_patterns(project, engine));
}

SanitizedShare sanitize_share(const Json& share, const EngineNames& engine, const ProjectNames& project) {
    SanitizedShare out;
    if (!share.is_object()) {
        out.problems.push_back("share must be an object {title, missing, suggestion?, workaround?}");
        return out;
    }
    const NamePatterns patterns = build_patterns(project, engine);
    auto field_text = [&](const char* key, bool required) -> std::optional<std::string> {
        auto it = share.find(key);
        if (it == share.end() || it->is_null()) {
            if (required) out.problems.push_back(std::string("share.") + key + " is missing");
            return std::nullopt;
        }
        if (!it->is_string()) {
            out.problems.push_back(std::string("share.") + key + " must be a string");
            return std::nullopt;
        }
        return it->get<std::string>();
    };
    struct Spec { const char* key; bool required; int min, max; std::string* dest; };
    const Spec specs[] = {{"title", true, kShareTitleMin, kShareTitleMax, &out.title},
                          {"missing", true, kShareMissingMin, kShareMissingMax, &out.missing},
                          {"suggestion", false, 0, kShareSuggestionMax, &out.suggestion},
                          {"workaround", false, 0, kShareWorkaroundMax, &out.workaround}};
    for (const Spec& spec : specs) {
        auto raw = field_text(spec.key, spec.required);
        if (!raw) continue;
        Cleaner cx{engine, spec.key, out.removed};
        const std::size_t before = out.removed.size();
        (void)before;
        std::string cleaned = clean_field(cx, *raw, patterns);
        *spec.dest = cleaned;
        const std::size_t len = code_points(cleaned);
        const std::string summary = removal_summary(out.removed, spec.key);
        if (len > std::size_t(spec.max)) {
            out.problems.push_back(std::string(spec.key) + " is too long (" + std::to_string(len) + " characters, at most " +
                                   std::to_string(spec.max) + "): shorten it");
            continue;
        }
        if (len < std::size_t(spec.min)) {
            out.problems.push_back(std::string(spec.key) + " is too short after cleaning (" + std::to_string(len) + " characters, needs at least " +
                                   std::to_string(spec.min) + ")" + summary +
                                   ": say it in engine terms without names, paths or quotes from the game");
            continue;
        }
        if (len == 0) continue;
        if (letter_ratio(cleaned) < 0.6) {
            out.problems.push_back(std::string(spec.key) + " is not text (fewer than 60% letters)" + summary);
            continue;
        }
        if (std::string(spec.key) == "missing" && word_count(cleaned) < 4)
            out.problems.push_back("missing needs at least 4 words" + summary);
    }
    out.ok = out.problems.empty();
    return out;
}

}  // namespace fa
