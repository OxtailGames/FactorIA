// The verdict of each style rule that a project sets (fa/tooling/art_check.h), and the style warnings of project.validate.
#include <algorithm>
#include <array>
#include <cmath>
#include <filesystem>
#include <format>
#include <set>

#include "fa/core/asset_manifest.h"
#include "fa/tooling/art_check.h"
#include "util.h"

namespace fa {

namespace {

using T = ArtThresholds;

std::string hex(std::uint8_t r, std::uint8_t g, std::uint8_t b) { return std::format("#{:02x}{:02x}{:02x}", r, g, b); }
std::string hex(const ArtColour& c) { return hex(c.r, c.g, c.b); }
std::string pct(double share) { return std::format("{:.0f}%", share * 100.0); }
std::string num(double v) { return std::format("{:.3g}", v); }

std::uint8_t byte(float v) { return std::uint8_t(std::clamp(std::lround(v * 255.0f), 0L, 255L)); }

double dist(const ArtColour& a, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    const double dr = double(a.r) - r, dg = double(a.g) - g, db = double(a.b) - b;
    return std::sqrt(dr * dr + dg * dg + db * db);
}

// ok up to `warn`, warn up to `fail`, fail beyond: for a distance past a limit.
Verdict grade_over(double excess, double warnAt, double failAt) { return excess <= warnAt ? Verdict::Ok : excess <= failAt ? Verdict::Warn : Verdict::Fail; }

ArtRule make(const char* id, double value, double threshold, std::optional<double> failThreshold, Verdict verdict, std::string message, std::string hint,
             Json detail = Json()) {
    ArtRule r;
    r.rule = id;
    r.value = value;
    r.threshold = threshold;
    r.failThreshold = failThreshold;
    r.verdict = verdict;
    r.message = std::move(message);
    r.hint = std::move(hint);
    r.detail = std::move(detail);
    return r;
}

const char* kIgnoreHint = " If this asset is meant to differ (UI, an effect), give it a role (assets.set_provenance role) or skip this rule with style.ignore.";

void outline_rules(const ArtMeasure& m, const StyleOutline& o, std::vector<ArtRule>& out) {
    if (m.ringPixels < 12) return;  // no silhouette: an opaque tile or a full-frame picture
    const std::uint8_t r = byte(o.color.r), g = byte(o.color.g), b = byte(o.color.b);
    std::uint64_t on = 0;
    for (const ArtColour& c : m.ringColours)
        if (dist(c, r, g, b) <= T::outlineColourDistance) on += c.count;
    const double share = std::min(1.0, double(on) / double(m.ringPixels));
    const ArtColour* dom = m.ringColours.empty() ? nullptr : &m.ringColours.front();
    const Verdict v = share >= T::outlineShareOk ? Verdict::Ok : share >= T::outlineShareWarn ? Verdict::Warn : Verdict::Fail;
    std::string message = std::format("{} of the {} edge pixels of the silhouette are the outline colour {}", pct(share), m.ringPixels, hex(r, g, b));
    if (dom) message += std::format("; the commonest edge colour is {} ({})", hex(*dom), pct(double(dom->count) / double(m.ringPixels)));
    message += ".";
    out.push_back(make("outline.color", share, T::outlineShareOk, T::outlineShareWarn, v, message,
                       std::format("Draw a {} outline of {} px around the silhouette: regenerate with assets.generate_image {{\"overwrite\": true}} (the style prompt asks for it) "
                                   "or repaint the edge.{}", hex(r, g, b), num(o.width), kIgnoreHint),
                       Json::object({{"edgePixels", m.ringPixels}, {"commonestEdgeColour", dom ? hex(*dom) : ""}})));
    if (dom && share >= T::outlineShareWarn && dist(*dom, r, g, b) <= T::outlineColourDistance && m.ringWidth > 0) {
        const double diff = std::fabs(m.ringWidth - o.width);
        const Verdict wv = diff < T::outlineWidthWarn ? Verdict::Ok : diff < T::outlineWidthFail ? Verdict::Warn : Verdict::Fail;
        out.push_back(make("outline.width", m.ringWidth, o.width, o.width + T::outlineWidthFail, wv,
                           std::format("The outline is {} px thick (median), the style asks for {} px.", num(m.ringWidth), num(o.width)),
                           std::format("Redraw the outline {} px thick. If the art is drawn at another scale than the style's, that is a texelsPerUnit difference: "
                                       "resize the picture, or change style.outline.width.{}", num(o.width), kIgnoreHint)));
    }
}

void range_rules(const char* name, double low, double high, const StyleRange& range, const char* what, std::vector<ArtRule>& out) {
    if (range.min) {
        const double delta = *range.min - low;
        out.push_back(make(name == std::string("value") ? "value.min" : "saturation.min", low, *range.min, *range.min - T::rangeFail,
                           grade_over(delta, T::rangeWarn, T::rangeFail),
                           std::format("{} is {} where the style asks for at least {}.", what, num(low), num(*range.min)),
                           name == std::string("value")
                               ? "Lift the darkest pixels (pure black outlines and shadows are the usual cause) to the style's minimum." + std::string(kIgnoreHint)
                               : "Use more saturated colours." + std::string(kIgnoreHint)));
    }
    if (range.max) {
        const double delta = high - *range.max;
        out.push_back(make(name == std::string("value") ? "value.max" : "saturation.max", high, *range.max, *range.max + T::rangeFail,
                           grade_over(delta, T::rangeWarn, T::rangeFail),
                           std::format("{} is {} where the style asks for at most {}.", what, num(high), num(*range.max)),
                           name == std::string("value")
                               ? "Tone down the lightest pixels (pure white highlights are the usual cause) to the style's maximum." + std::string(kIgnoreHint)
                               : "Use less saturated colours." + std::string(kIgnoreHint)));
    }
}

double angle_difference(double a, double b) {
    double d = std::fabs(std::fmod(a - b, 360.0));
    return d > 180 ? 360 - d : d;
}

void palette_rule(const ArtMeasure& m, const Palette& palette, bool pixelArt, std::vector<ArtRule>& out) {
    if (m.colours.empty() || palette.empty()) return;
    const double tolerance = pixelArt ? T::paletteDistancePixelArt : T::paletteDistance;
    std::uint64_t total = 0, off = 0;
    double sumDistance = 0;
    const ArtColour* worst = nullptr;
    std::array<std::uint8_t, 3> worstNearest{};
    double worstDistance = 0;
    for (const ArtColour& c : m.colours) {
        double best = 1e9;
        std::array<std::uint8_t, 3> nearest{};
        for (const auto& p : palette) {
            const double d = dist(c, p[0], p[1], p[2]);
            if (d < best) { best = d; nearest = p; }
        }
        total += c.count;
        sumDistance += best * c.count;
        if (best > tolerance) {
            off += c.count;
            if (best * std::sqrt(double(c.count)) > worstDistance) { worstDistance = best * std::sqrt(double(c.count)); worst = &c; worstNearest = nearest; }
        }
    }
    const double share = total ? double(off) / double(total) : 0.0;
    const double warnAt = pixelArt ? T::offShareWarnPixelArt : T::offShareWarn, failAt = pixelArt ? T::offShareFailPixelArt : T::offShareFail;
    const Verdict v = share <= warnAt ? Verdict::Ok : share <= failAt ? Verdict::Warn : Verdict::Fail;
    std::string message = std::format("{} of the pixels are more than {} away from every colour of the style palette ({} colours); on average a pixel is {} from its nearest palette colour.",
                                      pct(share), num(tolerance), palette.size(), num(total ? sumDistance / double(total) : 0.0));
    std::string hint = "Reduce the picture to the style palette: assets.generate_image does it for every image it makes (regenerate with {\"overwrite\": true}), or recolour the file.";
    if (worst) {
        message += std::format(" The most visible off-palette colour is {} (nearest palette colour {}).", hex(*worst), hex(worstNearest[0], worstNearest[1], worstNearest[2]));
        hint = std::format("Recolour {} to {}, or reduce the whole picture to the style palette (assets.generate_image does it for every image it makes; regenerate with {{\"overwrite\": true}}).", hex(*worst),
                           hex(worstNearest[0], worstNearest[1], worstNearest[2]));
    }
    hint += kIgnoreHint;
    out.push_back(make("palette.offShare", share, warnAt, failAt, v, message, hint,
                       Json::object({{"colours", m.distinct}, {"meanDistance", total ? sumDistance / double(total) : 0.0}, {"tolerance", tolerance}})));
}

}  // namespace

const char* verdict_name(Verdict v) { return v == Verdict::Ok ? "ok" : v == Verdict::Warn ? "warn" : "fail"; }

Json ArtRule::to_json() const {
    Json j = Json::object({{"rule", rule}, {"value", std::round(value * 10000.0) / 10000.0}, {"threshold", std::round(threshold * 10000.0) / 10000.0}});
    if (failThreshold) j["failThreshold"] = std::round(*failThreshold * 10000.0) / 10000.0;
    j["verdict"] = verdict_name(verdict);
    j["message"] = message;
    if (verdict != Verdict::Ok) j["hint"] = hint;
    if (detail.is_object() && !detail.empty()) j["detail"] = detail;
    return j;
}

std::vector<ArtRule> evaluate_style_rules(const ArtMeasure& m, const StyleGuide& style, const std::vector<const TextureUse*>& uses) {
    std::vector<ArtRule> out;
    if (m.visible == 0) return out;
    if (style.outline) outline_rules(m, *style.outline, out);
    if (style.value) range_rules("value", m.valueLow, m.valueHigh, *style.value, "The darkest/lightest pixels (1st/99th percentile)", out);
    if (style.value) {
        // the message of the two ends is clearer with the end it is about
        for (ArtRule& r : out) {
            if (r.rule == "value.min") r.message = std::format("The darkest pixels (1st percentile) have value {} where the style asks for at least {}.", num(r.value), num(r.threshold));
            if (r.rule == "value.max") r.message = std::format("The lightest pixels (99th percentile) have value {} where the style asks for at most {}.", num(r.value), num(r.threshold));
        }
    }
    if (style.saturation) range_rules("saturation", m.saturationMean, m.saturationMean, *style.saturation, "The mean saturation", out);
    if (style.lightDirection && m.lightStrength >= T::lightMinStrength) {
        const double diff = angle_difference(m.lightDegrees, *style.lightDirection);
        Verdict v = diff <= T::lightWarnDegrees ? Verdict::Ok : diff <= T::lightFailDegrees ? Verdict::Warn : Verdict::Fail;
        if (m.lightStrength < T::lightFullStrength && v == Verdict::Fail) v = Verdict::Warn;  // a faint lean is not proof
        const std::string want = style.lightDirectionName.empty() ? light_direction_label(*style.lightDirection) : style.lightDirectionName;
        out.push_back(make("lightDirection", diff, T::lightWarnDegrees, T::lightFailDegrees, v,
                           std::format("The shading leans towards {} ({} degrees, strength {}), {} degrees away from the style's {} ({} degrees).",
                                       light_direction_label(m.lightDegrees), num(m.lightDegrees), num(m.lightStrength), num(diff), want, num(*style.lightDirection)),
                           std::format("Repaint the highlights on the {} side and the shadows on the opposite side.{}", want, kIgnoreHint),
                           Json::object({{"measuredDegrees", m.lightDegrees}, {"strength", m.lightStrength}})));
    }
    if (style.pixelArt && *style.pixelArt) {
        out.push_back(make("pixelArt.edges", m.partialShare, T::pixelEdgeWarn, T::pixelEdgeFail,
                           m.partialShare <= T::pixelEdgeWarn ? Verdict::Ok : m.partialShare <= T::pixelEdgeFail ? Verdict::Warn : Verdict::Fail,
                           std::format("{} of the pixels that are not fully transparent are partly transparent: pixel art has hard edges.", pct(m.partialShare)),
                           "Remove the anti-aliasing: draw without smoothing, and do not scale the art with a smooth filter (assets.rasterize_svg draws smooth edges; "
                           "assets.draw_icon too). Quantize alpha to 0 or 255." + std::string(kIgnoreHint)));
        out.push_back(make("pixelArt.colours", m.distinct, T::pixelColoursWarn, T::pixelColoursFail,
                           m.distinct <= T::pixelColoursWarn ? Verdict::Ok : m.distinct <= T::pixelColoursFail ? Verdict::Warn : Verdict::Fail,
                           std::format("The picture has {} distinct colours; pixel art uses a small palette (up to {} here).", m.distinct, T::pixelColoursWarn),
                           "Reduce the colours: set style.palette so assets.generate_image locks every new image to it, or repaint with fewer shades." + std::string(kIgnoreHint)));
    }
    if (style.palette) palette_rule(m, *style.palette, style.pixelArt.value_or(false), out);
    if (style.texelsPerUnit) {
        const double have = median_texels_per_unit(uses);
        if (have > 0) {
            const double target = *style.texelsPerUnit, rel = std::fabs(have - target) / target;
            const TextureUse* first = nullptr;
            for (const TextureUse* u : uses)
                if (texels_per_unit(*u) > 0) { first = u; break; }
            std::string hint = std::format("Draw the sprite {:.4g} world units wide (Sprite.size [{:.4g}, {:.4g}], scene.set_component), or redraw the texture at {} pixels per unit.",
                                           first->framePx[0] / target, first->framePx[0] / target, first->framePx[1] / target, num(target));
            out.push_back(make("texelsPerUnit", have, target, target * (1 + T::texelsFail), grade_over(rel, T::texelsWarn, T::texelsFail),
                               std::format("The scenes draw this texture at {} texture pixels per world unit (median of {} use(s)); the style asks for {}.", num(have),
                                           uses.size(), num(target)),
                               hint + kIgnoreHint, Json::object({{"scene", first->scene}})));
        }
    }
    return out;
}

std::string style_role_of(const Json& manifest, const StyleGuide& style, const std::string& path, std::string* source) {
    if (manifest.is_object() && manifest.contains("assets") && manifest["assets"].is_object()) {
        const Json& assets = manifest["assets"];
        auto entry = assets.find(path);
        if (entry != assets.end() && entry->is_object() && entry->contains("provenance") && (*entry)["provenance"].is_object()) {
            const Json& p = (*entry)["provenance"];
            if (p.contains("role") && p["role"].is_string()) {
                if (source) *source = "provenance.role";
                return p["role"].get<std::string>();
            }
        }
    }
    for (const auto& [glob, role] : style.roles)
        if (style_path_matches(glob, path)) {
            if (source) *source = "style.roles " + glob;
            return role;
        }
    return "";
}

void apply_style_scope(const StyleGuide& style, const std::string& path, const std::string& role, const std::string& roleSource, std::vector<ArtRule>& rules,
                       std::vector<StyleSkip>& skipped) {
    const std::vector<std::string> roleOff = style_role_skips(role);
    std::vector<ArtRule> kept;
    for (ArtRule& r : rules) {
        std::string reason;
        for (const StyleIgnoreRule& e : style.ignoreRules) {
            if (!style_path_matches(e.path, path)) continue;
            for (const std::string& name : e.rules)
                if (style_rule_matches(name, r.rule)) { reason = "style.ignore entry '" + e.path + "' skips " + name; break; }
            if (!reason.empty()) break;
        }
        if (reason.empty())
            for (const std::string& name : roleOff)
                if (style_rule_matches(name, r.rule)) { reason = "role " + role + " (" + roleSource + ") does not ask for " + name; break; }
        if (reason.empty()) kept.push_back(std::move(r));
        else skipped.push_back({r.rule, std::move(reason)});
    }
    rules = std::move(kept);
}

void check_art_style(const std::string& projectDir, const std::set<std::string>& textures, const ProjectArtUse& use, std::vector<ValidationIssue>& warnings) {
    StyleParse parsed = load_style_guide(projectDir);
    const StyleGuide& style = parsed.guide;
    if (!style.has_art_rules()) return;
    const Json manifest = [&] {
        tooling_detail::ProjectRootScope root(projectDir);
        return assets::manifest();
    }();
    for (const std::string& rel : textures) {
        if (style.ignores(rel)) continue;
        std::error_code ec;
        if (!std::filesystem::is_regular_file(std::filesystem::path(projectDir) / rel, ec)) continue;
        auto measure = measure_art_file(projectDir, rel);
        if (!measure) continue;
        std::string roleSource;
        const std::string role = style_role_of(manifest, style, rel, &roleSource);
        std::vector<ArtRule> rules = evaluate_style_rules(*measure, style, use.of(rel));
        std::vector<StyleSkip> skipped;
        apply_style_scope(style, rel, role, roleSource, rules, skipped);  // assets.check_art reports what was skipped
        for (const ArtRule& r : rules)
            if (r.verdict == Verdict::Fail)
                warnings.push_back({rel, "", "Breaks the style rule '" + r.rule + "' (assets.json style): " + r.message, r.hint});
    }
}

}  // namespace fa
