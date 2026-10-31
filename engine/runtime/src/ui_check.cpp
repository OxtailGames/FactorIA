// ui.check_layout: loads each screen (scene) in each language and text size, plus a pseudo-localized pass, and lists the texts that
// do not fit. The test for "does not fit" is the engine's own (ui.state's `overflowed`, fa/scene/text_fit.h), not a second one;
// this file adds the loop, the overlap and off-screen checks and the report. docs/LOCALIZATION.md says when to run it.
#include <algorithm>
#include <map>
#include <set>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/ui/ui.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

// The localization key of the text an entity shows ("" when it has none: a script wrote the text).
std::string key_of(const World& w, Entity e) {
    if (const Text* c = w.get<Text>(e); c && !c->key.empty()) return c->key;
    if (const Button* c = w.get<Button>(e); c && !c->key.empty()) return c->key;
    if (const Toggle* c = w.get<Toggle>(e); c && !c->key.empty()) return c->key;
    if (const Slider* c = w.get<Slider>(e); c && !c->key.empty()) return c->key;
    if (const TouchButton* c = w.get<TouchButton>(e); c && !c->key.empty()) return c->key;
    return {};
}

// "Menu/Options/Back": the names of the entity and its ancestors (the id when an entity has no name).
std::string path_of(const World& w, Entity e) {
    std::vector<std::string> parts;
    for (Entity cur = e; cur != kNullEntity && w.alive(cur); cur = w.parent(cur)) {
        const EntityInfo* info = w.get<EntityInfo>(cur);
        parts.push_back(info && !info->name.empty() ? info->name : w.id_of(cur));
    }
    std::reverse(parts.begin(), parts.end());
    std::string out;
    for (const std::string& p : parts) out += (out.empty() ? "" : "/") + p;
    return out;
}

bool is_ancestor(const World& w, Entity ancestor, Entity e) {
    for (Entity cur = w.parent(e); cur != kNullEntity && w.alive(cur); cur = w.parent(cur))
        if (cur == ancestor) return true;
    return false;
}

struct Item {
    std::string id, kind, text;
    Rect rect;
    bool overflowed = false;
};

struct Issue {
    std::string scene, kind, id, otherId;
    Json info, otherInfo;  // {entity, path, key, text, rect} as first seen
    Json cases = Json::array();
};

}  // namespace

void register_ui_check_commands(Engine& engine, Engine::Impl& I) {
    I.commands.add(
        {"ui.check_layout", "Load each screen in each language and text size and list every text that overflows its box, overlaps another text or leaves the screen.",
         "For every scene (default: each scene with UI) and every case it loads the scene, switches the language, sets the text size, "
         "lets the scripts settle (a few frames) and reads ui.state. A text is reported when (1) `overflow`: it still does not fit "
         "its box at its effective size (the same test as ui.overflowed(id): after autoShrink and maxTextScale, see docs/TEXT.md), "
         "(2) `overlap`: two visible texts or labelled widgets (Text, Button, Toggle, Slider, TouchButton, neither the parent of the "
         "other) cover each other, (3) `offscreen`: its rectangle leaves the screen, or (4) `tooltip`: the `tooltip` of a visible widget is not a valid tooltip, or its box (the project's ui.tooltip style: maxWidth, font sizes, padding) is larger than the screen, so it cannot be placed inside it. The cases are every language x every text "
         "scale x every interface scale (`uiScales`, default: the current ui.scale), plus (with `pseudo`) a pseudo-localized pass in the default language where each translation is lengthened "
         "(\"[\" + vowels doubled + \"]\", at least 40 % longer) to show where an unknown, longer language would break. Returns "
         "{ok, checked: [{scene, cases}], skipped: [scenes with no UI], issueCount, issues: [{scene, kind, entity, path, key, text, "
         "rect, other?: {entity, path, key, text, rect}, cases: [{language, textScale, uiScale, pseudo}]}]}: one issue per problem with every "
         "case where it happens, so the fix is to the widget (autoSize, autoShrink + minFontSize, maxWidth, a bigger box, a shorter "
         "string). A widget inside a ScrollList is checked on the part the list shows (its rectangle intersected with the list's), so "
         "a row half scrolled out is not reported for the half that is clipped, and a row fully outside is skipped. `steps` runs "
         "actions per scene (clicks on widgets by name or id, keys, actions, frames) before the checks, with a layout pass between "
         "them, so a panel a click opens is checked too; the state they reach stays for every case of that scene. Only texts with a "
         "localization `key` follow the language and the pseudo pass; a text a script writes is checked at each text scale only "
         "(and in the state the steps reach). It RELOADS scenes: afterwards the running scene is loaded again and the language, text size, "
         "interface scale and pseudo mode are restored, but the game state is lost, so run it on a fresh game or session. Refused while a frame "
         "runs. The warnings, errors and scripts of each load behave as in scene.load. With `current: true` it does not load anything: it measures "
         "the scene that runs, with the panels a test or the player has opened, in every language, text size and interface scale of the cases (it "
         "steps a few frames per case so the layout settles, then puts the language, text size and scale back; the game state is kept), and "
         "`scenes` and `steps` are not allowed. A test calls it as game.checkLayout() after opening a panel. Example: ui.check_layout {\"textScales\":[1,2],\"uiScales\":[0.75,1,1.5],\"pseudo\":true}",
         parse_schema(R"({"type":"object","properties":{
             "scenes":{"type":"array","items":{"type":"string"},"description":"Project-relative scene paths to check, e.g. [\"scenes/menu.scene.json\"]. Default: every scene of the project that has UI (a widget or a screen-space Text)."},
             "languages":{"type":"array","items":{"type":"string"},"description":"Languages to check, as in factoria.json localization.languages. Default: all of them (the current one when the game has no localization)."},
             "textScales":{"type":"array","items":{"type":"number","minimum":0.5,"maximum":3},"description":"Text size options (ui.set_text_scale) to check. Default: [1, 2]."},
             "uiScales":{"type":"array","items":{"type":"number","minimum":0.5,"maximum":3},"description":"Interface scales (ui.set_scale) to check, every one with every language and text size. Default: the current ui.scale. List every size the Options menu offers."},
             "pseudo":{"type":"boolean","description":"Also run the pseudo-localized pass (default language, every text scale). Default: true."},
             "steps":{"type":"object","description":"Per scene (project-relative path, as in `scenes`), a list run once after the scene loads and settles, before the checks, to reach a panel or state that is not there at the start: {\"click\":\"widget name or id\"} (the centre of its laid-out rectangle; an error when it is hidden, clipped or has no area), {\"key\":\"Enter\"} (press and release), {\"action\":\"jump\"} (press and release an input action), {\"frames\":n} (step n frames). The UI is laid out between steps. Example: {\"scenes/menu.scene.json\":[{\"click\":\"options_button\"},{\"frames\":10}]}.","additionalProperties":{"type":"array","items":{"type":"object","properties":{"click":{"type":"string"},"key":{"type":"string"},"action":{"type":"string"},"frames":{"type":"integer","minimum":0,"maximum":1000}}}}},
             "current":{"type":"boolean","description":"Measure the running scene as it is now (the panels open, the state reached) instead of loading each scene: no reload, the game state is kept. Not with `scenes` or `steps`. Default: false."},
             "settleFrames":{"type":"integer","minimum":1,"maximum":120,"description":"Frames stepped after each change so scripts and layout settle. Default: 4."}}})"),
         false, "ui"},
        [&engine, &I](const Json& a) {
            if (I.inFrame) throw CommandError("invalid_state", "ui.check_layout cannot run while a frame runs.", "Call it from the CLI, the editor or a test, not from a script.");
            const int settle = a.value("settleFrames", 4);
            const bool current = a.value("current", false);
            if (current && (a.contains("scenes") || a.contains("steps")))
                throw CommandError("invalid_argument", "current: true measures the running scene as it is, so `scenes` and `steps` do not apply.",
                                   "Leave them out, or leave `current` out to load the scenes.");

            // Scenes.
            const std::vector<std::string> all = fs::list("scenes", true, ".json");
            std::vector<std::string> scenes;
            bool explicitScenes = false;
            if (current) {
                explicitScenes = true;
                scenes.push_back(I.currentScene.empty() ? std::string("(current scene)") : I.currentScene);
            } else if (a.contains("scenes") && a["scenes"].is_array() && !a["scenes"].empty()) {
                explicitScenes = true;
                for (const Json& s : a["scenes"]) {
                    std::string path = fs::normalize(s.get<std::string>());
                    if (std::find(all.begin(), all.end(), path) == all.end())
                        throw CommandError("not_found", "Scene '" + path + "' not found. " + did_you_mean(path, all), "Use project.info to list scenes.");
                    scenes.push_back(path);
                }
            } else {
                for (const std::string& f : all)
                    if (f.size() > 11 && f.compare(f.size() - 11, 11, ".scene.json") == 0) scenes.push_back(f);
            }

            Json stepLists = Json::object();
            if (a.contains("steps")) {
                if (!a["steps"].is_object())
                    throw CommandError("invalid_argument", "steps must be an object of scene path -> list of steps.", "Example: {\"steps\":{\"scenes/menu.scene.json\":[{\"click\":\"options_button\"}]}}");
                for (const auto& [k, v] : a["steps"].items()) {
                    const std::string path = fs::normalize(k);
                    if (std::find(all.begin(), all.end(), path) == all.end())
                        throw CommandError("not_found", "steps: scene '" + path + "' not found. " + did_you_mean(path, all), "Use project.info to list scenes.");
                    if (!v.is_array()) throw CommandError("invalid_argument", "steps['" + k + "'] must be a list of steps.", "Each step is {\"click\": name}, {\"key\": name}, {\"action\": name} or {\"frames\": n}.");
                    stepLists[path] = v;
                }
            }

            // Languages and text scales.
            std::vector<std::string> languages;
            if (a.contains("languages") && a["languages"].is_array() && !a["languages"].empty()) {
                for (const Json& l : a["languages"]) {
                    auto r = I.i18n.resolve_language(l.get<std::string>());
                    if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
                    languages.push_back(r.value());
                }
            } else if (I.i18n.enabled()) {
                languages = I.i18n.languages();
            } else {
                languages.push_back("");
            }
            std::vector<float> scales;
            if (a.contains("textScales") && a["textScales"].is_array() && !a["textScales"].empty())
                for (const Json& s : a["textScales"]) scales.push_back(s.get<float>());
            else
                scales = {1.0f, 2.0f};
            std::vector<float> uiScales;
            if (a.contains("uiScales") && a["uiScales"].is_array() && !a["uiScales"].empty())
                for (const Json& s : a["uiScales"]) uiScales.push_back(s.get<float>());
            else
                uiScales = {engine.ui_scale()};
            const bool pseudo = a.value("pseudo", true) && I.i18n.enabled();

            struct Case {
                std::string language;
                float scale;
                float uiScale;
                bool pseudo;
            };
            std::vector<Case> cases;
            for (const std::string& l : languages)
                for (float u : uiScales)
                    for (float s : scales) cases.push_back({l, s, u, false});
            if (pseudo)
                for (float u : uiScales)
                    for (float s : scales) cases.push_back({I.i18n.default_language(), s, u, true});

            const std::string startLanguage = I.i18n.language();
            const float startScale = engine.text_scale(), startUiScale = engine.ui_scale();
            const std::string startScene = I.currentScene;
            const Vec2 screen = I.design_size();

            std::vector<Issue> issues;
            Json checked = Json::array(), skipped = Json::array(), loadProblems = Json::array();
            std::map<std::string, Item> now;  // the visible items of the case being checked, by id
            auto describe = [&](const std::string& id) {
                Json j = Json::object({{"entity", id}});
                if (const Entity e = I.world.find_by_id(id); e != kNullEntity) {
                    j["path"] = path_of(I.world, e);
                    j["key"] = key_of(I.world, e);
                }
                if (const auto it = now.find(id); it != now.end()) {
                    j["text"] = it->second.text;
                    j["rect"] = Json::array({it->second.rect.x, it->second.rect.y, it->second.rect.w, it->second.rect.h});
                }
                return j;
            };
            auto add_issue = [&](const std::string& scene, const std::string& kind, const std::string& id, const std::string& other, const Case& c) {
                Issue* found = nullptr;
                for (Issue& i : issues)
                    if (i.scene == scene && i.kind == kind && i.id == id && i.otherId == other) found = &i;
                if (!found) {
                    issues.push_back({scene, kind, id, other, describe(id), other.empty() ? Json(nullptr) : describe(other), Json::array()});
                    found = &issues.back();
                }
                found->cases.push_back(Json::object({{"language", c.pseudo ? "pseudo" : c.language}, {"textScale", c.scale}, {"uiScale", c.uiScale}, {"pseudo", c.pseudo}}));
            };

            // One press and release over a frame each, like game.tapKey in tests.
            auto tap_named = [&](const std::string& name, const std::string& where) {
                std::string e;
                if (!I.inject_named(name, true, &e))
                    throw CommandError("invalid_argument", where + ": " + e, "Use a key name (Enter, Space, A...) or an input action of factoria.json.");
                engine.step(1);
                I.inject_named(name, false, &e);
                engine.step(1);
            };
            auto run_steps = [&](const std::string& scene) {
                if (!stepLists.contains(scene)) return;
                std::size_t index = 0;
                for (const Json& st : stepLists[scene]) {
                    const std::string where = "steps['" + scene + "'][" + std::to_string(index) + "]";
                    I.ui.layout(I.world, screen, I.measure(), false);
                    if (st.contains("click") && st["click"].is_string()) {
                        const std::string name = st["click"].get<std::string>();
                        const Entity e = I.world.find(name);
                        if (e == kNullEntity) {
                            std::vector<std::string> names;
                            for (Entity w : I.world.entities())
                                if (ui_kind(I.world, w) != UiKind::None) names.push_back(path_of(I.world, w));
                            throw CommandError("not_found", where + ": click: no entity '" + name + "' in " + scene + ". " + did_you_mean(name, names), "Name a widget (an entity id or name) that exists after the earlier steps.");
                        }
                        const std::optional<Rect> r = ui_rect(I.world, e, screen);
                        const std::optional<Rect> clip = ui_clip_rect(I.world, e, screen);
                        if (ui_kind(I.world, e) == UiKind::None || !I.world.active_in_hierarchy(e) || !r || !(r->w > 0) || !(r->h > 0) ||
                            (clip && (!(clip->w > 0) || !(clip->h > 0) || !clip->overlaps(*r))))
                            throw CommandError("invalid_state", where + ": click: '" + name + "' (" + path_of(I.world, e) + ") is not a visible widget at this point (no widget, inactive, no area or scrolled out of its ScrollList).", "Click the button that opens it first, or add {\"frames\": n} so a script has time to show it.");
                        const Rect box = clip ? ui_intersect(*r, *clip) : *r;
                        I.input.on_mouse_move({box.x + box.w / 2, box.y + box.h / 2});
                        I.input.on_mouse_button(MouseButton::Left, true);
                        engine.step(1);
                        I.input.on_mouse_button(MouseButton::Left, false);
                        engine.step(1);
                    } else if (st.contains("key") && st["key"].is_string()) {
                        tap_named(st["key"].get<std::string>(), where);
                    } else if (st.contains("action") && st["action"].is_string()) {
                        tap_named(st["action"].get<std::string>(), where);
                    } else if (st.contains("frames") && st["frames"].is_number_integer()) {
                        engine.step(st["frames"].get<int>());
                    } else {
                        throw CommandError("invalid_argument", where + ": a step is {\"click\": name}, {\"key\": name}, {\"action\": name} or {\"frames\": n}, got " + st.dump() + ".", "Example: {\"click\":\"options_button\"}");
                    }
                    ++index;
                }
                I.ui.layout(I.world, screen, I.measure(), false);
            };

            // A thrown step still has to put the game back, so the cleanup is one lambda.
            auto restore = [&] {
                I.i18n.set_pseudo(false);
                if (!startLanguage.empty()) I.switch_language(startLanguage);
                if (!startScene.empty() && !current) {
                    std::string e;
                    I.load_scene_impl(startScene, &e);
                }
                I.apply_localization();
                engine.set_text_scale(startScale);
                engine.set_ui_scale(startUiScale);
            };

            for (const std::string& scene : scenes) {
                if (!current) {
                    std::string err;
                    I.load_scene_impl(scene, &err);
                    if (!err.empty()) loadProblems.push_back(scene + ": " + err);
                    engine.step(settle);
                }
                try {
                    run_steps(scene);
                } catch (...) {
                    restore();
                    throw;
                }
                int uiItems = 0;
                Json caseList = Json::array();
                for (const Case& c : cases) {
                    I.i18n.set_pseudo(c.pseudo);
                    if (!c.language.empty()) I.switch_language(c.language);
                    I.apply_localization();
                    engine.set_text_scale(c.scale);
                    engine.set_ui_scale(c.uiScale);
                    engine.step(settle);
                    const Json state = I.ui.state(I.world, screen, I.measure());
                    std::vector<Item> items;
                    now.clear();
                    for (const Json& w : state["widgets"]) {
                        if (!w["visible"].get<bool>()) continue;
                        Item it;
                        it.id = w["id"].get<std::string>();
                        it.kind = w["kind"].get<std::string>();
                        it.text = w.value("text", std::string());
                        it.overflowed = w.value("overflowed", false);
                        const Json& r = w["rect"];
                        it.rect = Rect{r[0].get<float>(), r[1].get<float>(), r[2].get<float>(), r[3].get<float>()};
                        // A widget in a ScrollList counts for the part the list shows; a row fully outside was skipped above.
                        if (const Entity own = I.world.find_by_id(it.id); own != kNullEntity)
                            if (const std::optional<Rect> clip = ui_clip_rect(I.world, own, screen)) it.rect = ui_intersect(it.rect, *clip);
                        ++uiItems;
                        now[it.id] = it;
                        const bool labelled = it.kind == "Text" || it.kind == "Button" || it.kind == "Toggle" || it.kind == "Slider" || it.kind == "TouchButton";
                        // A Text faded out to nothing (an intro the script fades in) covers nothing.
                        const Entity ent = I.world.find_by_id(it.id);
                        const Text* faded = ent != kNullEntity ? I.world.get<Text>(ent) : nullptr;
                        if (labelled && !it.text.empty() && !(faded && faded->color.a < 0.02f)) items.push_back(it);
                    }
                    for (const auto& [id, it] : now)
                        if (it.overflowed) add_issue(scene, "overflow", id, "", c);
                    // The tooltip a widget carries (its `tooltip` field; a function's answer is not known here): in this language and
                    // text size it must be readable at all, and a box that cannot fit the screen cannot be placed inside it.
                    for (const auto& [id, it] : now) {
                        const Entity own = I.world.find_by_id(id);
                        const UiBox* box = own != kNullEntity ? ui_box(I.world, own) : nullptr;
                        if (!box || box->tooltip.is_null()) continue;
                        const std::optional<UiTooltipText> text = ui_tooltip_text(box->tooltip, &I.i18n);
                        if (!text) {
                            add_issue(scene, "tooltip", id, "", c);
                            continue;
                        }
                        if (text->empty()) continue;
                        const float k = ui_scale_clamped(I.world.ui_scale());
                        const Vec2 size = ui_tooltip_size(*text, I.world.ui_tooltip_settings().style, I.measure()) * k;
                        if (size.x > screen.x - 8.0f || size.y > screen.y - 8.0f) add_issue(scene, "tooltip", id, "", c);
                    }
                    for (const Item& it : items) {
                        if (it.rect.x < -0.5f || it.rect.y < -0.5f || it.rect.x + it.rect.w > screen.x + 0.5f || it.rect.y + it.rect.h > screen.y + 0.5f)
                            add_issue(scene, "offscreen", it.id, "", c);
                    }
                    for (std::size_t i = 0; i < items.size(); ++i)
                        for (std::size_t j = i + 1; j < items.size(); ++j) {
                            const Rect &p = items[i].rect, &q = items[j].rect;
                            if (!(p.x < q.x + q.w - 0.5f && q.x < p.x + p.w - 0.5f && p.y < q.y + q.h - 0.5f && q.y < p.y + p.h - 0.5f)) continue;
                            const Entity ea = I.world.find_by_id(items[i].id), eb = I.world.find_by_id(items[j].id);
                            if (ea != kNullEntity && eb != kNullEntity && (is_ancestor(I.world, ea, eb) || is_ancestor(I.world, eb, ea))) continue;
                            std::string x = items[i].id, y = items[j].id;
                            if (y < x) std::swap(x, y);
                            add_issue(scene, "overlap", x, y, c);
                        }
                    caseList.push_back(Json::object({{"language", c.pseudo ? "pseudo" : c.language}, {"textScale", c.scale}, {"uiScale", c.uiScale}, {"pseudo", c.pseudo}}));
                }
                if (uiItems == 0 && !explicitScenes) skipped.push_back(scene);
                else checked.push_back(Json::object({{"scene", scene}, {"cases", caseList}}));
            }

            // Back to how the game was.
            restore();

            Json out = Json::array();
            for (const Issue& i : issues) {
                Json j = i.info;
                j["scene"] = i.scene;
                j["kind"] = i.kind;
                if (!i.otherId.empty()) j["other"] = i.otherInfo;
                j["cases"] = i.cases;
                out.push_back(std::move(j));
            }
            Json result = Json::object({{"ok", out.empty()}, {"checked", checked}, {"skipped", skipped}, {"issueCount", out.size()}, {"issues", out}});
            if (!loadProblems.empty()) result["loadProblems"] = loadProblems;
            return result;
        });
}

}  // namespace fa
