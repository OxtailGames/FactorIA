// assets.subset_font: a font cut down to the characters a game shows. The characters are the ones the glyph check of project.validate
// asks a font for (the strings of locales/<language>.json, localization_tables.h), plus Latin, punctuation and `keep`. A variable font
// is pinned to one instance (HarfBuzz's instancer) and the shaping tables stay. Runs on HarfBuzz's subsetter (external/harfbuzz).
#include <hb-ot.h>
#include <hb-subset.h>

#include <algorithm>
#include <format>
#include <map>
#include <memory>
#include <set>

#include "assets_internal.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/runtime/project.h"
#include "localization_tables.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

// Punctuation and symbols line breaking and the kinsoku rule need, plus the ones strings of CJK games commonly use.
constexpr const char* kPunctuation =
    "、。，．·：；？！—…‥「」『』（）［］｛｝【】〈〉《》〔〕“”‘’※★☆♪←→↑↓＋－×÷＝％＄＃＆＊／＼｜«»¡¿\u00a0\u202f";

template <class T, void (*Destroy)(T*)>
struct HbDeleter {
    void operator()(T* p) const { Destroy(p); }
};
using Blob = std::unique_ptr<hb_blob_t, HbDeleter<hb_blob_t, hb_blob_destroy>>;
using Face = std::unique_ptr<hb_face_t, HbDeleter<hb_face_t, hb_face_destroy>>;
using Input = std::unique_ptr<hb_subset_input_t, HbDeleter<hb_subset_input_t, hb_subset_input_destroy>>;
using Set = std::unique_ptr<hb_set_t, HbDeleter<hb_set_t, hb_set_destroy>>;

std::string tag_name(hb_tag_t tag) {
    char s[5];
    hb_tag_to_string(tag, s);
    s[4] = 0;
    return s;
}

// Characters that are not drawn: asking the source for a glyph for them would be noise.
bool is_blank(char32_t cp) { return cp <= 0x20 || (cp >= 0x7F && cp <= 0xA0) || cp == 0x202F || cp == 0x3000 || (cp >= 0x2000 && cp <= 0x200F) || cp == 0x2028 || cp == 0x2029; }

std::string describe(const std::vector<char32_t>& cps, std::size_t limit = 12) {
    std::string out;
    for (std::size_t i = 0; i < cps.size() && i < limit; ++i) out += (i ? ", " : "") + localization_detail::describe_code_point(cps[i]);
    if (cps.size() > limit) out += std::format(" and {} more", cps.size() - limit);
    return out;
}

Json subset_font(const std::string& projectDir, const Json& a) {
    const std::string sourceArg = tooling_detail::arg_string(a, "source", true);
    const std::string outArg = tooling_detail::arg_string(a, "out", true);
    if (sourceArg.find("://") != std::string::npos)
        fail("invalid_argument", "assets.subset_font reads files on this machine, and '" + sourceArg + "' is a URL.", "Download the font first, then pass its local path.");
    auto out = fs::normalize_checked(outArg);
    const std::string ext = out.ok() ? to_lower(fs::extension(*out)) : std::string();
    if (!out.ok() || out->empty() || !starts_with(*out, "assets/") || (ext != ".ttf" && ext != ".otf"))
        fail("invalid_argument", "`out` must be a project-relative .ttf or .otf path under assets/ (got '" + outArg + "').", "For example \"assets/fonts/NotoSansSC-Regular-subset.ttf\".");
    if (auto c = fs::check_writable(*out); !c.ok()) fail("invalid_argument", c.error().message, c.error().hint);

    const stdfs::path source = stdfs::path(sourceArg).is_absolute() ? stdfs::path(sourceArg) : project_file(projectDir, sourceArg);
    std::error_code ec;
    if (!stdfs::is_regular_file(source, ec))
        fail("not_found", "The font '" + sourceArg + "' does not exist.", "Pass the absolute path of the .ttf/.otf, or a path relative to the project folder.");
    auto bytes = read_bytes(source);
    if (!bytes.ok()) fail("failed", bytes.error().message, bytes.error().hint);

    ProjectRootGuard guard(projectDir);

    // ---- the languages whose tables give the characters ----
    std::vector<std::string> languages;
    if (a.contains("locales")) {
        if (!a["locales"].is_array() || !std::all_of(a["locales"].begin(), a["locales"].end(), [](const Json& l) { return l.is_string(); }))
            fail("invalid_argument", "`locales` must be an array of language tags.", "For example [\"zh-Hans\"]; leave it out for every language of factoria.json's localization.languages.");
        languages = a["locales"].get<std::vector<std::string>>();
    } else if (auto project = load_json_file("factoria.json"); project.ok() && project->is_object() && project->contains("localization")) {
        languages = parse_localization((*project)["localization"]).settings.languages;
    }
    std::set<char32_t> wanted;   // the characters the strings (and `keep`) need: these are reported when the source lacks one
    for (const std::string& language : languages) {
        const localization_detail::TableFile table = localization_detail::read_table(language);
        if (!table.table) {
            if (!table.exists) fail("not_found", table.message, table.hint);
            fail("invalid_argument", table.file + ": " + table.message, table.hint);
        }
        for (char32_t cp : localization_detail::table_code_points(table)) wanted.insert(cp);
    }
    const std::string keepText = tooling_detail::arg_string(a, "keep", false);
    for (char32_t cp : utf8_decode(keepText)) wanted.insert(cp);
    if (languages.empty() && keepText.empty())
        fail("invalid_argument", "There are no characters to keep: no `locales` were given and factoria.json has no localization.languages.",
             "Pass `locales` (for example [\"zh-Hans\"]) to keep the characters of locales/<language>.json, and/or `keep` with the characters to keep.");

    // ---- the axes of a variable font ----
    std::map<std::string, double> pins;
    if (a.contains("axes")) {
        if (!a["axes"].is_object()) fail("invalid_argument", "`axes` must be an object of axis tag to value.", "For example {\"wght\": 400}.");
        for (const auto& [tag, value] : a["axes"].items()) {
            if (tag.size() != 4 || !value.is_number())
                fail("invalid_argument", "`axes` has '" + tag + "': an axis is a four-letter tag with a number.", "For example {\"wght\": 400, \"wdth\": 100}.");
            pins[tag] = value.get<double>();
        }
    } else {
        pins["wght"] = 400;
    }

    Blob blob(hb_blob_create(reinterpret_cast<const char*>(bytes->data()), unsigned(bytes->size()), HB_MEMORY_MODE_READONLY, nullptr, nullptr));
    Face face(hb_face_create(blob.get(), 0));
    if (hb_face_get_glyph_count(face.get()) == 0)
        fail("invalid_argument", "'" + sourceArg + "' is not a font HarfBuzz can read (no glyphs).", "Pass a TrueType or OpenType file (.ttf/.otf); a .ttc collection and .woff are not read.");

    Set have(hb_set_create());
    hb_face_collect_unicodes(face.get(), have.get());
    std::vector<char32_t> missing;
    for (char32_t cp : wanted)
        if (!is_blank(cp) && !hb_set_has(have.get(), hb_codepoint_t(cp))) missing.push_back(cp);

    Input input(hb_subset_input_create_or_fail());
    if (!input) fail("failed", "HarfBuzz could not create the subset request (out of memory).");
    hb_set_t* unicodes = hb_subset_input_unicode_set(input.get());
    for (char32_t cp = 0x20; cp < 0x7F; ++cp) hb_set_add(unicodes, hb_codepoint_t(cp));
    for (char32_t cp = 0xA0; cp < 0x100; ++cp) hb_set_add(unicodes, hb_codepoint_t(cp));      // Latin-1: the Spanish and French letters
    for (char32_t cp = 0xFF01; cp < 0xFF5F; ++cp) hb_set_add(unicodes, hb_codepoint_t(cp));   // full-width forms
    for (char32_t cp : utf8_decode(kPunctuation)) hb_set_add(unicodes, hb_codepoint_t(cp));
    for (char32_t cp : wanted) hb_set_add(unicodes, hb_codepoint_t(cp));
    // Keep every shaping feature, script and name (the license strings): the "empty set, inverted" is HarfBuzz's "all".
    for (hb_subset_sets_t which : {HB_SUBSET_SETS_LAYOUT_FEATURE_TAG, HB_SUBSET_SETS_LAYOUT_SCRIPT_TAG, HB_SUBSET_SETS_NAME_ID, HB_SUBSET_SETS_NAME_LANG_ID}) {
        hb_set_t* set = hb_subset_input_set(input.get(), which);
        hb_set_clear(set);
        hb_set_invert(set);
    }
    hb_subset_input_set_flags(input.get(), HB_SUBSET_FLAGS_NOTDEF_OUTLINE | HB_SUBSET_FLAGS_NO_HINTING);

    Json axesOut = Json::object();
    unsigned axisCount = hb_ot_var_get_axis_infos(face.get(), 0, nullptr, nullptr);
    std::vector<hb_ot_var_axis_info_t> axes(axisCount);
    if (axisCount) hb_ot_var_get_axis_infos(face.get(), 0, &axisCount, axes.data());
    std::set<std::string> known;
    for (const hb_ot_var_axis_info_t& axis : axes) {
        const std::string tag = tag_name(axis.tag);
        known.insert(tag);
        const auto pin = pins.find(tag);
        const double value = pin == pins.end() ? double(axis.default_value) : pin->second;
        if (value < axis.min_value || value > axis.max_value)
            fail("invalid_argument", std::format("The font's '{}' axis runs from {} to {}, and `axes` asks for {}.", tag, axis.min_value, axis.max_value, value),
                 "Pick a value inside that range.");
        const bool ok = pin == pins.end() ? hb_subset_input_pin_axis_to_default(input.get(), face.get(), axis.tag)
                                          : hb_subset_input_pin_axis_location(input.get(), face.get(), axis.tag, float(value));
        if (!ok) fail("failed", "HarfBuzz could not pin the '" + tag + "' axis to " + std::to_string(value) + ".");
        axesOut[tag] = value;
    }
    for (const auto& [tag, _] : pins)
        if (!known.contains(tag) && a.contains("axes"))
            fail("invalid_argument", "`axes` names '" + tag + "', and the font " + (known.empty() ? "is not a variable font." : "has the axes " + join(std::vector<std::string>(known.begin(), known.end()), ", ") + "."),
                 known.empty() ? "Leave `axes` out for a static font." : "Use one of its axes.");

    Face result(hb_subset_or_fail(face.get(), input.get()));
    if (!result) fail("failed", "HarfBuzz could not subset '" + sourceArg + "'.", "The file may be damaged or use a table layout HarfBuzz refuses; try another copy of the font.");
    Blob data(hb_face_reference_blob(result.get()));
    unsigned length = 0;
    const char* raw = hb_blob_get_data(data.get(), &length);
    const std::string newBytes(raw, length);

    const stdfs::path outFile = project_file(projectDir, *out);
    const auto oldText = tooling_detail::read_file(outFile);
    const bool changed = !oldText || *oldText != newBytes;
    std::string err;
    if (changed && !tooling_detail::write_file(outFile, newBytes, &err)) fail("failed", err);

    Set kept(hb_set_create());
    hb_face_collect_unicodes(result.get(), kept.get());
    Json r = Json::object({{"out", *out}, {"sourceBytes", std::int64_t(bytes->size())}, {"bytes", std::int64_t(length)},
                           {"glyphs", int(hb_face_get_glyph_count(result.get()))}, {"characters", int(hb_set_get_population(kept.get()))},
                           {"fromLocales", int(wanted.size())}, {"languages", languages}, {"axes", axesOut}, {"written", changed}});
    Json warnings = Json::array();
    if (!missing.empty()) {
        std::vector<std::string> list;
        for (char32_t cp : missing) list.push_back(utf8_encode(cp));
        r["missing"] = list;
        warnings.push_back(std::format("{} character(s) of the strings are not in the source font and stay missing: {}. `factoria validate` fails on them until a fallback font has them.",
                                       missing.size(), describe(missing)));
    }
    if (!warnings.empty()) r["warnings"] = warnings;
    r["nextSteps"] = Json::array({"List the font in the Text components' `font` (or localization.languageFonts / fallbackFonts), then run `factoria validate`: it checks that every string has a glyph.",
                                  "Run this command again whenever a string of locales/ changes; nothing is written when the result is the same bytes."});
    return r;
}

}  // namespace

void register_subset_font_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "assets.subset_font";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Cut a font down to the characters of the locale tables plus Latin and punctuation (a CJK font from 17 MB to a few hundred KB), pinning a variable font's axes.";
    info.description =
        "Reads the font `source` (an absolute path on this machine, or relative to the project) and writes `out` (under assets/) with only the "
        "glyphs for: every character of locales/<language>.json for the `locales` (default: factoria.json's localization.languages; the same "
        "characters the glyph check of `factoria validate` asks a font for), printable ASCII, Latin-1 (Spanish and French letters), the "
        "full-width forms, the CJK punctuation line breaking needs, and the characters of `keep`. The shaping tables (GSUB, GPOS, GDEF, "
        "kerning) and the name strings (the license) stay; hinting and glyph names are dropped. A variable font is pinned to one instance "
        "(`axes`, default {\"wght\":400}; its other axes go to their default), because the engine draws a variable font's default instance and a "
        "Thin default would draw hairlines. Runs HarfBuzz's subsetter: no Python or fontTools. The result has the sizes, the glyph and character "
        "counts, and `missing`: characters of the strings the source font does not have. Nothing is written when the result is the same bytes, "
        "so run it again whenever a string changes. Example: {\"source\":\"C:/fonts/NotoSansSC[wght].ttf\",\"locales\":[\"zh-Hans\"],"
        "\"out\":\"assets/fonts/NotoSansSC-Regular-subset.ttf\"}. Check the font's license allows modifying it (SIL OFL fonts do, but ask not to keep the "
        "Reserved Font Name; Noto has none) and keep its license file next to the result.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["source","out"],
      "properties":{
        "source":{"type":"string","description":"The font to cut: an absolute path on this machine, or a path relative to the project folder. A .ttf or .otf, static or variable."},
        "out":{"type":"string","description":"Project-relative .ttf or .otf under assets/ to write, e.g. \"assets/fonts/NotoSansSC-Regular-subset.ttf\". Replaced if it exists."},
        "locales":{"type":"array","items":{"type":"string"},"description":"Languages whose locales/<language>.json give the characters, e.g. [\"zh-Hans\"]. Default: every language of localization.languages in factoria.json."},
        "keep":{"type":"string","description":"Extra characters to keep, written out: e.g. the characters a script builds names from, or a whole alphabet."},
        "axes":{"type":"object","description":"Where to pin the variable font's axes, tag to value: {\"wght\":400}. Default {\"wght\":400}. An axis not listed goes to its default.","additionalProperties":{"type":"number"}}
      }})");
    registry.add(info, [projectDir](const Json& args) { return subset_font(projectDir, args); });
}

}  // namespace fa::assets_detail
