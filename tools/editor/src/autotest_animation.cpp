// Autotest sections Y to C2: recipes, sprite sheets, the Animation panel and the bone tools.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <memory>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "fa/core/date.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/net.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

}  // namespace

void Editor::at_section_Y(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------------------------------------------------ Y. Recipes
    // A made asset (assets.rasterize_svg records a recipe): the Project panel shows a stale badge when its source changed on
    // disk, a banner offers Regenerate / Not now (quiet after Not now), the toolbar Regenerate makes the selected asset again
    // (different pixels, up to date), the banner's Regenerate makes every stale one again, and a deleted source turns the badge
    // into "no src" with Regenerate off.
    {
        struct Recipes {
            std::string manifest, firstPng;
            bool hadManifest = false;
        };
        auto ry = std::make_shared<Recipes>();
        const std::string png = "assets/ay_coin.png", svg = "assets/ay_src.svg", tile = "proj:file:assets/ay_coin.png";
        auto svg_text = [](const char* fill, int size) {
            return std::string("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\"><circle cx=\"32\" "
                               "cy=\"32\" r=\"") +
                   std::to_string(size) + "\" fill=\"" + fill + "\"/></svg>";
        };
        step(2, [this, ry, project_file, svg_text, png, svg] {
            stop();
            select_id("");
            ry->hadManifest = stdfs::exists(project_file("assets.json"));
            ry->manifest = ry->hadManifest ? read_file(project_file("assets.json")) : std::string();
            write_file(project_file(svg), svg_text("#e03030", 20));
            std::string err;
            CommandResult r =
                edit_command("at:y:make", "assets.rasterize_svg",
                             Json::object({{"path", png}, {"source", svg}, {"width", 32}, {"height", 32}}), &err);
            at_check(r.ok, "assets.rasterize_svg made a picture with a recipe: " + err);
            ry->firstPng = read_file(project_file(png));
            showProject_ = true;
            projBrowser_.selected.clear();
            projBrowser_.offeredStale.clear();
            focus_window("Project");
        });
        step(1, [this, tile] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, tile] { return at_visible(tile); };
        });
        step(3, [this, png] {
            const AssetRecipeStatus* st = recipe_of_file(projBrowser_.listing, png);
            at_check(st && !st->stale() && st->missing.empty() && st->command == "assets.rasterize_svg",
                     "the made picture has a recipe and is up to date");
            at_check(!at_visible("recipe:notice"), "no banner while everything is up to date");
        });
        // The source is saved, one byte shorter: the watcher compares size and file time, and on Windows a file's time moves in
        // steps of 1/64 s, so a save of the same size a few fast frames after the first one could leave both unchanged.
        step(2, [project_file, svg, svg_text] { write_file(project_file(svg), svg_text("#3060e0", 8)); });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("recipe:notice"); };  // the watcher looks once a second
        });
        step(3, [this, png] {
            const std::vector<std::string> stale = stale_assets(projBrowser_.listing);
            at_check(stale == std::vector<std::string>{png}, "the saved source makes the picture stale");
            at_check(at_visible("recipe:regenerate") && at_visible("recipe:notnow"),
                     "the banner offers Regenerate and Not now");
        });
        snap("editor_recipe_stale.png");
        click("recipe:notnow");
        step(2, [this] { projBrowser_.inputsPolled = -100; });
        step(40, [this] { at_check(!at_visible("recipe:notice"), "Not now hides the banner and it stays quiet"); });
        step(2, [this, png] {
            projBrowser_.selected = png;
            at_check(at_enabled("proj:regenerate"), "the toolbar Regenerate is on for the selected made picture");
        });
        click("proj:regenerate");
        step(6, [this, ry, project_file, png] {
            at_check(read_file(project_file(png)) != ry->firstPng,
                     "Regenerate drew the picture again from the new source");
            const AssetRecipeStatus* st = recipe_of_file(projBrowser_.listing, png);
            at_check(st && !st->stale(), "...and it is up to date again");
            at_check(stale_assets(projBrowser_.listing).empty(), "...so nothing is stale");
        });
        step(2, [this, project_file, svg, svg_text] {
            write_file(project_file(svg), svg_text("#30c060", 14));
            projBrowser_.offeredStale.clear();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("recipe:notice"); };
        });
        click("recipe:regenerate");
        step(6, [this, png] {
            at_check(stale_assets(projBrowser_.listing).empty(),
                     "the banner's Regenerate made the stale picture again");
            at_check(!at_visible("recipe:notice"), "...and the banner is gone");
        });
        step(2, [this, project_file, svg] {
            std::error_code ec;
            stdfs::remove(project_file(svg), ec);
            projBrowser_.recipesDirty = true;
            projBrowser_.stale = true;
            projBrowser_.inputsPolled = -100;
        });
        step(30, [this, png] {
            const AssetRecipeStatus* st = recipe_of_file(projBrowser_.listing, png);
            at_check(st && !st->missing.empty(), "a deleted source is a missing input");
            at_check(!at_enabled("proj:regenerate"), "...and Regenerate is off (it cannot be made again)");
        });
        step(2, [this, ry, project_file, png, svg] {  // put the project back
            std::error_code ec;
            stdfs::remove(project_file(png), ec);
            stdfs::remove(project_file(svg), ec);
            if (ry->hadManifest)
                write_file(project_file("assets.json"), ry->manifest);
            else
                stdfs::remove(project_file("assets.json"), ec);
            projBrowser_.selected.clear();
            projBrowser_.offeredStale.clear();
            project_files_changed();
        });
    }
}

void Editor::at_section_Z(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------------------- Z. Sprite sheets
    // Sprite sheets: the Project panel previews the sheet that is selected (its clips, played the way a SpriteAnimator plays
    // them, with a menu to change clip), and the Inspector of a SpriteAnimator lists the clips of its Sprite's texture, one click
    // sets `clip` (one undo step).
    {
        struct YState {
            size_t undo = 0;
        };
        auto y = std::make_shared<YState>();
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        step(2, [this, project_file, y] {
            stop();
            select_id("");
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            Image img;
            img.width = 24;
            img.height = 8;
            img.rgba.assign(size_t(24) * 8 * 4, 255);
            for (int x = 0; x < 24; ++x)
                for (int yy = 0; yy < 8; ++yy) {
                    std::uint8_t* px = &img.rgba[(size_t(yy) * 24 + x) * 4];
                    px[0] = std::uint8_t(x / 8 == 0 ? 255 : 40);
                    px[1] = std::uint8_t(x / 8 == 1 ? 255 : 40);
                    px[2] = std::uint8_t(x / 8 == 2 ? 255 : 40);
                }
            at_check(save_png(img, project_file("assets/autotest_sheet.png")).ok(),
                     "a sprite sheet was written for the sheet test");
            write_file(
                project_file("assets.json"),
                R"({"format": "factoria.assets/1", "assets": {"assets/autotest_sheet.png": {"sheet": {"columns": 3, "rows": 1,
                          "frameWidth": 8, "frameHeight": 8, "frames": 3, "clips": [
                          {"name": "run", "firstFrame": 0, "lastFrame": 1, "fps": 4, "loop": true},
                          {"name": "idle", "firstFrame": 2, "lastFrame": 2, "fps": 1, "loop": true}]}}}})");
            std::string err;
            CommandResult r = edit_command(
                "at:sheethero", "scene.spawn",
                Json::object({{"id", "sheethero"},
                              {"name", "Sheet Hero"},
                              {"components",
                               Json::object({{"Transform", Json::object({{"position", Json::array({300, 250, 0})}})},
                                             {"Sprite", Json::object({{"texture", "assets/autotest_sheet.png"}})},
                                             {"SpriteAnimator", Json::object()}})}}),
                &err);
            at_check(r.ok, "an entity with a Sprite and a SpriteAnimator was spawned: " + err);
            projBrowser_.stale = true;
            projBrowser_.query.search = "autotest_sheet";
            projBrowser_.selected = "assets/autotest_sheet.png";
            sheetPreviewPath_.clear();
            showProject_ = true;
            focus_window("Project");
            y->undo = undo_depth();
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return at_visible("sheet:clip") && sheetPreviewFrame_ >= 0; };
        });
        step(30, [this] {
            at_check(sheetPreviewChoice_ == "run", "the preview starts with the first clip of the sheet");
            at_check(sheetPreviewFrame_ == 0 || sheetPreviewFrame_ == 1, "...and shows one of its frames (0 or 1)");
        });
        snap("editor_sheet_preview.png");
        click_widget("sheet:clip");
        step(3, [] {});
        click_widget("sheet:choice:idle");
        step(6, [this] {
            at_check(sheetPreviewChoice_ == "idle", "choosing a clip in the menu plays that clip");
            at_check(sheetPreviewFrame_ == 2, "...the idle clip is the third frame of the sheet");
        });
        step(2, [this] {
            focus_window("Project");
            select_id("sheethero");
            inspScrollTo_ = "SpriteAnimator.clip";
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                return at_visible("insp:SpriteAnimator.clip:run") && at_visible("insp:SpriteAnimator.clip:idle");
            };
        });
        step(2, [this, y] {
            at_check(true, "the Inspector lists the clips of the Sprite's texture under SpriteAnimator.clip");
            y->undo = undo_depth();
        });
        click_widget("insp:SpriteAnimator.clip:idle");
        step(5, [this, y] {
            const SpriteAnimator* a = world().get<SpriteAnimator>(world().find_by_id("sheethero"));
            at_check(a && a->clip == "idle", "clicking a clip sets SpriteAnimator.clip");
            at_check(undo_depth() == y->undo + 1, "...as one undo step");
        });
        snap("editor_sheet_inspector.png");
        step(2, [this, project_file] {
            select_id("");
            projBrowser_.selected.clear();
            projBrowser_.query.search.clear();
            std::error_code ec;
            stdfs::remove(project_file("assets.json"), ec);
            stdfs::remove(project_file("assets/autotest_sheet.png"), ec);
            projBrowser_.stale = true;
        });
    }
}

void Editor::at_section_B2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Animation panel (docs/EDITOR.md, "Animation panel"): a puppet with an Animator and a Sprite part. New clip makes the
    // clip; in record mode a gizmo drag on the part writes keys at the playhead instead of the rest position; a key is dragged
    // (one undo step) and its easing changed from the context menu; an event is added; a click on the ruler poses the entity
    // without touching the scene; the onion skin draws faded poses.
    {
        struct Bs {
            size_t undo = 0;
            Vec2 grab{}, cur{};
            float firstX = 0, secondX = 0;
        };
        auto b = std::make_shared<Bs>();
        auto click_widget = [this, &step](const std::string& name, int button = 0) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name, button] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), button); });
            step(4, [this, name, button] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), button); });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto clip_now = [this]() -> std::shared_ptr<const ClipAsset> {
            const std::string path = anim_clip_path();
            if (path.empty()) return nullptr;
            auto loaded = load_anim_clip(path);
            return loaded.ok() ? *loaded : nullptr;
        };
        auto position_track = [clip_now]() -> int {
            const auto clip = clip_now();
            if (!clip) return -1;
            for (std::size_t i = 0; i < clip->tracks.size(); ++i)
                if (clip->tracks[i].component == "Transform" && clip->tracks[i].field == "position") return int(i);
            return -1;
        };
        auto key_at = [clip_now, position_track](double t) -> const ClipKey* {
            const auto clip = clip_now();
            const int ti = position_track();
            if (!clip || ti < 0) return nullptr;
            for (const ClipKey& k : clip->tracks[std::size_t(ti)].keys)
                if (std::fabs(double(k.t) - t) < 0.0006) return &k;
            return nullptr;
        };
        auto body_x = [this] { return world().get<Transform>(world().find_by_id("puppet_body"))->position.x; };
        // One gizmo drag by (dx, dy) panel pixels on the X arrow, with the mouse over the viewport.
        auto drag_arrow = [this, &step, &wait_until, b](float dx) {
            step(2, [this, b] {
                b->grab = b->cur = at_widget("gizmo:move:x");
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->grab);
            });
            step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, b->grab); });
            wait_until([this] { return gizmoDrag_.active; });
            step(2, [this, b, dx] {
                b->cur = Vec2{b->grab.x + dx, b->grab.y};
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->cur);
            });
            wait_until([this] { return gizmoDrag_.wrote; });
            step(3, [] {});
            step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, b->cur); });
            wait_until([this] { return !gizmoDrag_.active; });
            step(4, [] {});
        };

        step(2, [this, project_file, b] {
            stop();
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            std::error_code ec;
            stdfs::remove(project_file("anim/clip.anim.json"), ec);
            std::string err;
            CommandResult r = edit_command(
                "at:puppet", "scene.spawn",
                Json::object({{"id", "puppet"},
                              {"name", "Puppet"},
                              {"components",
                               Json::object({{"Transform", Json::object({{"position", Json::array({300, 120, 0})}})},
                                             {"Animator", Json::object()}})}}),
                &err);
            at_check(r.ok, "a Puppet with an Animator was spawned: " + err);
            r = edit_command(
                "at:puppetbody", "scene.spawn",
                Json::object(
                    {{"id", "puppet_body"},
                     {"name", "Body"},
                     {"parent", "puppet"},
                     {"components",
                      Json::object({{"Transform", Json::object()},
                                    {"Sprite", Json::object({{"size", Json::array({60, 60})},
                                                             {"color", Json::array({0.9, 0.5, 0.2, 1})}})}})}}),
                &err);
            at_check(r.ok, "...with a Sprite part called Body: " + err);
            select_id("puppet_body");
            showAnimation_ = true;
            gizmoMode_ = GizmoMode::Move;
            focus_window("Animation");
            b->undo = undo_depth();
        });
        wait_until([this] { return at_visible("anim:newclip"); });
        step(2, [this] {
            at_check(anim_owner() == world().find_by_id("puppet"),
                     "selecting the Body part makes its parent's Animator the one the panel edits");
            at_check(!at_visible("anim:play"), "...and with no clip yet there is no transport");
        });
        click_widget("anim:newclip");
        wait_until([this] { return at_visible("anim:newclip:create"); });
        click_widget("anim:newclip:create");
        step(6, [this, b] {
            const Animator* a = world().get<Animator>(world().find_by_id("puppet"));
            at_check(a && a->clips.is_object() && a->clips.contains("clip"),
                     "New clip lists the clip in Animator.clips");
            at_check(stdfs::exists(projectDir_ + "/anim/clip.anim.json"), "...and writes anim/clip.anim.json");
            at_check(anim_.clipName == "clip", "...and the panel opens it");
            at_check(at_visible("anim:record") && at_visible("anim:play"), "...so the transport and Record are there");
            at_check(undo_depth() == b->undo + 2, "...as two undo steps: the clip file, then the Animator.clips entry");
            dirty_ =
                false;  // from here on the checks ask whether record mode, scrubbing and clip edits touch the scene
        });
        click_widget("anim:clips");
        step(3, [this] { at_check(at_visible("anim:clip:clip"), "the clip list names the new clip"); });
        click_widget("anim:clip:clip");
        snap("editor_animation_panel.png");

        // ---- record mode: a gizmo drag writes a key
        click_widget("anim:record");
        step(3, [this] {
            at_check(anim_.recording, "Record turns record mode on");
            select_id("puppet_body");
            anim_set_playhead(0.2);
            focus_window("Animation");
        });
        step(4, [this] {
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE,
                         Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f});
        });
        wait_until([this] { return at_visible("gizmo:move:x"); });
        step(2, [this, b, body_x] {
            b->undo = undo_depth();
            b->firstX = body_x();
        });
        drag_arrow(40);
        step(4, [this, b, key_at, position_track, body_x, clip_now] {
            const int ti = position_track();
            at_check(ti >= 0, "a Transform.position track was made for the Body part in record mode");
            const ClipKey* k = key_at(0.2);
            at_check(k != nullptr, "...with a key at the playhead (0.2 s)");
            if (k)
                at_check(k->value[0] > b->firstX + 10.0f,
                         "...holding the position the drag reached, not the rest position");
            if (k) b->secondX = k->value[0];
            at_check(anim_.recordedKeys >= 1, "the panel counts the keys record mode wrote");
            at_check(!dirty_, "record mode leaves the scene file unchanged (no unsaved changes)");
            at_check(undo_depth() == b->undo + 1, "the drag is ONE undo step");
            const auto clip = clip_now();
            at_check(clip && clip->tracks.size() >= 1, "the clip file has the track");
            at_check(std::fabs(body_x() - b->secondX) < 0.01f, "the entity shows the recorded pose");
        });
        snap("editor_animation_record.png");
        // a second key at 0.6 s
        step(2, [this] { anim_set_playhead(0.6); });
        step(4, [this] {
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE,
                         Vec2{vpImageMin_.x + vpImageSize_.x * 0.5f, vpImageMin_.y + vpImageSize_.y * 0.25f});
        });
        wait_until([this] { return at_visible("gizmo:move:x"); });
        drag_arrow(40);
        step(4, [this, key_at, clip_now, position_track, b] {
            const ClipKey* k = key_at(0.6);
            at_check(k != nullptr, "a second drag at 0.6 s writes a second key");
            if (k) at_check(k->value[0] > b->secondX + 10.0f, "...further along");
            const auto clip = clip_now();
            const int ti = position_track();
            at_check(
                clip && ti >= 0 && clip->tracks[std::size_t(ti)].keys.size() == 3,
                "the track has the rest key at 0 s (the part stays as it was until the first key) and the two recorded "
                "ones (" +
                    [&] {
                        std::string out;
                        if (clip && ti >= 0)
                            for (const ClipKey& k : clip->tracks[std::size_t(ti)].keys)
                                out += std::to_string(k.t) + ":" + std::to_string(k.value[0]) + " ";
                        return out;
                    }() +
                    ")");
            if (k) b->firstX = k->value[0];
            anim_.recording = false;
        });

        // ---- scrubbing poses the entity, the scene is not changed
        click_widget("anim:ruler");
        step(5, [this, b, body_x] {
            at_check(std::fabs(anim_.playhead - 0.5) < 0.05, "a click on the ruler puts the playhead there");
            const float expected = b->secondX + (b->firstX - b->secondX) * float((anim_.playhead - 0.2) / 0.4);
            at_check(std::fabs(body_x() - expected) < 0.5f, "...and poses the Body between the two keys");
            at_check(!dirty_, "scrubbing leaves the scene file unchanged");
            anim_unpose();
            at_check(std::fabs(body_x()) < 0.001f, "...the rest value is what the scene holds (unposed: Body at 0)");
            anim_.dirtyPose = true;
        });

        // ---- move a key, undo it
        // On a small window the dopesheet rows scroll: bring the Position track's keys into the visible part first.
        auto rows_point = [] {  // the visible bottom of the Animation window
            const ImGuiWindow* w = ImGui::FindWindowByName("Animation");
            if (!w) return Vec2{500, 500};
            const float bottom = std::min(w->Pos.y + w->Size.y, ImGui::GetIO().DisplaySize.y - 24.0f);
            return Vec2{w->Pos.x + w->Size.x * 0.5f, bottom - 12.0f};
        };
        scroll_until_at([position_track] { return "anim:key:" + std::to_string(position_track()) + ":600"; }, -6,
                        rows_point, 100000, -1e9f);
        step(3, [this, b, position_track] {
            b->undo = undo_depth();
            at_check(at_visible("anim:key:" + std::to_string(position_track()) + ":600"),
                     "the dopesheet shows the key at 600 ms");
        });
        step(2, [this, b, position_track] {
            b->grab = b->cur = at_widget("anim:key:" + std::to_string(position_track()) + ":600");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->grab);
        });
        step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, b->grab); });
        step(3, [this, b] {
            b->cur = Vec2{b->grab.x + float(anim_time_to_x(0.8) - anim_time_to_x(0.6)), b->grab.y};
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, b->cur);
        });
        step(3, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{b->cur.x + 0.5f, b->cur.y}); });
        step(2, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, b->cur); });
        step(5, [this, b, key_at] {
            at_check(key_at(0.6) == nullptr && key_at(0.8) != nullptr, "dragging the key moves it from 0.6 s to 0.8 s");
            at_check(undo_depth() == b->undo + 1, "...as ONE undo step");
            undo();
            at_check(key_at(0.6) != nullptr && key_at(0.8) == nullptr, "Undo puts the key back at 0.6 s");
            redo();
            at_check(key_at(0.8) != nullptr, "Redo moves it again");
            undo();
            at_check(!dirty_, "clip edits never mark the scene dirty");
        });

        // ---- easing from the context menu
        step(3, [this, position_track] {
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("anim:key:" + std::to_string(position_track()) + ":200"));
        });
        step(2, [this, b, position_track] {
            b->grab = at_widget("anim:key:" + std::to_string(position_track()) + ":200");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, b->grab, 1);
        });
        step(3, [this, b] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, b->grab, 1); });
        wait_until([this] { return at_visible("anim:menu:easing"); });
        click_widget("anim:menu:easing");
        wait_until([this] { return at_visible("anim:menu:ease:quadOut"); });
        step(2, [this, b] { b->undo = undo_depth(); });
        click_widget("anim:menu:ease:quadOut");
        step(5, [this, b, key_at] {
            const ClipKey* k = key_at(0.2);
            at_check(k && k->interp == ClipInterp::Ease && k->ease >= 0 &&
                         clip_ease_names()[std::size_t(k->ease)] == "quadOut",
                     "the context menu sets the easing of the key to quadOut");
            at_check(undo_depth() == b->undo + 1, "...as one undo step");
        });

        // ---- an event
        scroll_until_at([] { return std::string("anim:addevent"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:addevent");
        wait_until([this] { return at_visible("anim:event:ok"); });
        click_widget("anim:event:ok");
        step(5, [this, clip_now] {
            const auto clip = clip_now();
            at_check(clip && clip->events.size() == 1 && clip->events[0].name == "event",
                     "Add event writes a marker named 'event' into the clip");
            at_check(at_visible("anim:event:0"), "...and the ruler shows it");
        });

        // ---- the event popup says what is wrong inside the popup, and leaves the panel's own error line alone
        scroll_until_at([] { return std::string("anim:addevent"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:addevent");
        wait_until([this] { return at_visible("anim:event:ok"); });
        step(2, [this] { anim_.error = "panel message"; });
        for (
            int i = 0; i < 5;
            ++i) {  // the name box has the focus and holds "event": its own edit buffer, so it is emptied with the keys
            step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_BACKSPACE); });
            step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_BACKSPACE); });
        }
        step(2, [this] { at_check(anim_.eventName.empty(), "Backspace emptied the name box"); });
        click_widget("anim:event:ok");
        step(3, [this, clip_now] {
            at_check(anim_.eventError.find("name or game feel") != std::string::npos,
                     "an event with no name and no actions is refused inside the popup: " + anim_.eventError);
            at_check(anim_.error == "panel message", "...and the panel's own error line is not touched");
            const auto clip = clip_now();
            at_check(clip && clip->events.size() == 1, "...nothing was added");
            anim_.error.clear();
        });
        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ESCAPE); });
        step(4, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ESCAPE); });
        wait_until([this] { return !at_visible("anim:event:ok"); });

        // ---- an event that runs a game feel action: a preset button fills the box, the command checks it and the clip keeps it
        scroll_until_at([] { return std::string("anim:addevent"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:addevent");
        wait_until([this] { return at_visible("anim:event:fx:shake"); });
        click_widget("anim:event:fx:shake");
        click_widget("anim:event:ok");
        step(5, [this, clip_now] {
            const auto clip = clip_now();
            at_check(clip && clip->events.size() == 2, "a second event is added");
            bool found = false;
            if (clip)
                for (const ClipEvent& ev : clip->events)
                    found = found || (ev.feel.size() == 1 && ev.feel[0].value("action", std::string()) == "shake");
            at_check(found, "the Shake preset writes a game feel action into the event, which the clip loads");
        });

        // ---- onion skin
        scroll_until_at([] { return std::string("anim:onion"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:onion");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return anim_.onionDrawn > 0; };
        });
        step(3, [this] {
            at_check(anim_.onion && anim_.onionDrawn >= 2,
                     "the onion skin draws the poses before and after the playhead (" +
                         std::to_string(anim_.onionDrawn) + " ghosts)");
        });
        snap("editor_animation_onion.png");
        scroll_until_at([] { return std::string("anim:onion"); }, 6, rows_point, 100000, -1e9f);
        click_widget("anim:onion");
        step(4, [this, project_file] {
            at_check(!anim_.onion && anim_.onionDrawn == 0, "turning Onion off draws no ghosts");
            anim_unpose();
            at_check(!dirty_ && undo_depth() > 0,
                     "the whole session left the scene unchanged and the steps are on the undo stack");
            showAnimation_ = false;
            select_id("");
            std::error_code ec;
            stdfs::remove(project_file("anim/clip.anim.json"), ec);
        });
    }
}

void Editor::at_section_C2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The bone tools (docs/EDITOR.md, "Bone tools"): draw a chain with clicks, bind a sprite to it, paint weights with the brush
    // (one stroke = one undo step), drag an IK target, and the weight overlay follows the selected bone.
    {
        struct Cs {
            size_t undo = 0;
            Vec2 grab{}, cur{};
            Json weights;
            float targetX = 0, targetY = 0, rotBefore = 0;
        };
        auto c = std::make_shared<Cs>();
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        // The panel position of a world point (the fixture camera sits at the origin).
        auto panel_of = [this](float x, float y) {
            const Vec2 d = engine_->renderer()->world_to_screen(Vec3{x, y, 0});
            return Vec2{vpImageMin_.x + d.x / float(engine_->renderer()->target_width()) * vpImageSize_.x,
                        vpImageMin_.y + d.y / float(engine_->renderer()->target_height()) * vpImageSize_.y};
        };
        auto vp_click = [this, &step](std::function<Vec2()> where) {
            step(2, [this, where] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, where()); });
            step(2, [this, where] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, where()); });
            step(4, [this, where] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, where()); });
        };
        auto bone_named = [this](const char* name) {
            for (Entity e : world().entities_with(TypeRegistry::global().of<Bone2D>()))
                if (world().info(e).name == name) return e;
            return kNullEntity;
        };

        step(2, [this, project_file, c] {
            stop();
            write_file(project_file(scenePath_), kFixtureScene);
            reload_scene_from_disk();
            std::string err;
            CommandResult r = edit_command(
                "at:rig", "scene.spawn",
                Json::object(
                    {{"id", "rig"},
                     {"name", "Rig"},
                     {"components",
                      Json::object({{"Transform", Json::object({{"position", Json::array({-300, 50, 0})}})}})}}),
                &err);
            at_check(r.ok, "a Rig entity was spawned: " + err);
            r = edit_command(
                "at:limb", "scene.spawn",
                Json::object(
                    {{"id", "limb"},
                     {"name", "Limb"},
                     {"components",
                      Json::object({{"Transform", Json::object({{"position", Json::array({200, 100, 0})}})},
                                    {"Sprite", Json::object({{"size", Json::array({40, 120})},
                                                             {"color", Json::array({0.3, 0.7, 0.9, 1})}})}})}}),
                &err);
            at_check(r.ok, "...and a Limb sprite: " + err);
            r = edit_command(
                "at:iktarget", "scene.spawn",
                Json::object({{"id", "ik_target"},
                              {"name", "Target"},
                              {"components",
                               Json::object({{"Transform", Json::object({{"position", Json::array({-200, -20, 0})}})},
                                             {"Shape2D", Json::object({{"size", Json::array({10, 10})}})}})}}),
                &err);
            at_check(r.ok, "...and an IK target: " + err);
            select_id("rig");
            showBoneTools_ = true;
            focus_window("Bone tools");
            c->undo = undo_depth();
        });
        wait_until([this] { return at_visible("bone:tool:chain"); });
        click_widget("bone:tool:chain");
        step(3, [this] { at_check(bone_.tool == BoneTool::Chain, "Draw chain turns the tool on"); });

        // ---- draw a chain: three clicks, two bones
        vp_click([panel_of] { return panel_of(-300, 150); });
        vp_click([panel_of] { return panel_of(-300, 50); });
        vp_click([panel_of] { return panel_of(-300, -50); });
        step(3, [this, c] {
            at_check(bone_.chain.size() == 3, "three clicks in the viewport put three points on the chain");
            at_check(undo_depth() == c->undo, "...and nothing is made until the chain is finished");
            at_check(at_visible("bone:chain:finish") && at_enabled("bone:chain:finish"), "Finish chain is on");
        });
        snap("editor_bone_chain.png");
        click_widget("bone:chain:finish");
        step(5, [this, c, bone_named] {
            const Entity b1 = bone_named("bone_1"), b2 = bone_named("bone_2");
            at_check(!b1.is_null() && !b2.is_null(), "Finish chain makes bone_1 and bone_2");
            at_check(!b1.is_null() && world().parent(b1) == world().find_by_id("rig"),
                     "...the first hangs from the Rig");
            at_check(!b2.is_null() && world().parent(b2) == b1, "...the second from the first");
            at_check(undo_depth() == c->undo + 1, "the chain is ONE undo step");
            undo();
            at_check(bone_named("bone_1").is_null(), "Undo removes the bones");
            redo();
            at_check(!bone_named("bone_1").is_null(), "Redo brings them back");
            at_check(bone_.chain.empty(), "the chain on screen is cleared");
        });

        // ---- bind the sprite
        step(2, [this, bone_named, c] {
            select_id("limb");
            bone_.bindRoot = world().id_of(bone_named("bone_1"));
            bone_.meshColumns = 2;
            bone_.meshRows = 4;
            c->undo = undo_depth();
        });
        scroll_to("bone:bind", "Bone tools");
        click_widget("bone:bind");
        step(5, [this, c] {
            const SpriteSkin* skin = world().get<SpriteSkin>(world().find_by_id("limb"));
            at_check(skin != nullptr, "Bind sprite to bones adds a SpriteSkin to the Limb");
            at_check(skin && skin->bones.is_array() && skin->bones.size() == 2, "...with the two bones");
            const Sprite* sp = world().get<Sprite>(world().find_by_id("limb"));
            at_check(sp && sp->meshColumns == 2 && sp->meshRows == 4, "...and the 2 x 4 mesh");
            at_check(undo_depth() == c->undo + 1, "...as one undo step");
        });

        // ---- weights: the overlay, then a brush stroke
        scroll_to("bone:tool:weights", "Bone tools", 6);
        click_widget("bone:tool:weights");
        step(2, [this] { select_id("limb"); });
        step(5, [this] {
            at_check(bone_.tool == BoneTool::Weights && bone_.weightDots == 15,
                     "the weights tool draws a dot on each of the 15 mesh vertices (" +
                         std::to_string(bone_.weightDots) + ")");
        });
        scroll_to("bone:mode:set", "Bone tools");
        click_widget("bone:mode:set");
        step(3, [this, c] {
            at_check(bone_.mode == 1, "the Set brush mode is on");
            bone_.strength = 1.0f;
            bone_.radius = 40.0f;
            bone_.boneIndex = 0;
            c->undo = undo_depth();
            c->weights = world().get<SpriteSkin>(world().find_by_id("limb"))->weights;
            focus_window("###Viewport");
        });
        step(2, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_of(180, 160)); });
        step(2, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, panel_of(180, 160)); });
        step(3, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_of(180, 130)); });
        step(3, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, panel_of(180, 100)); });
        step(2, [this, panel_of] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, panel_of(180, 100)); });
        step(5, [this, c] {
            const SpriteSkin* skin = world().get<SpriteSkin>(world().find_by_id("limb"));
            at_check(skin && skin->weights.is_array() && skin->weights.size() == 15,
                     "painting writes explicit weights for the 15 vertices");
            bool full = false;
            if (skin && skin->weights.is_array() && !skin->weights.empty() && skin->weights[0].is_array() &&
                skin->weights[0].size() >= 2)
                full = skin->weights[0][0].get<int>() == 0 && skin->weights[0][1].get<float>() > 0.99f;
            at_check(full, "...the top-left vertex is fully bone_1's");
            at_check(bone_.strokes >= 2,
                     "...with more than one dab along the drag (" + std::to_string(bone_.strokes) + ")");
            at_check(undo_depth() == c->undo + 1, "the whole stroke is ONE undo step");
            undo();
            const SpriteSkin* after = world().get<SpriteSkin>(world().find_by_id("limb"));
            at_check(after && after->weights == c->weights, "Undo puts the weights back");
            redo();
        });
        snap("editor_bone_weights.png");

        // ---- the overlay follows the selected bone
        step(2, [this, bone_named] { select(bone_named("bone_2")); });
        step(4, [this] {
            at_check(bone_.boneIndex == 1, "selecting bone_2 in the Hierarchy picks it as the bone shown");
            at_check(bone_.weightDots == 15, "...the overlay is still on the Limb");
            at_check(bone_.bonesDrawn == 1,
                     "...and the viewport outlines the selected bone (" + std::to_string(bone_.bonesDrawn) + ")");
        });

        // ---- IK: a handle at the target
        step(2, [this, bone_named, c] {
            std::string err;
            const Entity b2 = bone_named("bone_2");
            const CommandResult r =
                edit_command("at:ik", "scene.set_component",
                             Json::object({{"id", world().id_of(b2)},
                                           {"component", "IK2D"},
                                           {"fields", Json::object({{"target", "ik_target"}, {"chainLength", 2}})}}),
                             &err);
            at_check(r.ok, "an IK2D on bone_2 targets the Target: " + err);
            select_id("rig");
        });
        scroll_to("bone:tool:ik", "Bone tools", 6);
        click_widget("bone:tool:ik");
        step(4, [this, c, bone_named] {
            at_check(bone_.tool == BoneTool::Ik && bone_.ikHandles == 1,
                     "the IK tool draws one handle for the one IK chain");
            c->undo = undo_depth();
            const Transform* t = world().get<Transform>(world().find_by_id("ik_target"));
            c->targetX = t->position.x;
            c->targetY = t->position.y;
            c->rotBefore = world().get<Transform>(bone_named("bone_1"))->rotation.z;
            focus_window("###Viewport");
        });
        step(2, [this, c] {
            c->grab = c->cur = at_widget("bone:ik:Target");
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, c->grab);
        });
        step(2, [this, c] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, c->grab); });
        step(3, [this, c] {
            c->cur = Vec2{c->grab.x + 40.0f, c->grab.y - 30.0f};
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, c->cur);
        });
        step(3, [this, c] {
            c->cur = Vec2{c->grab.x + 60.0f, c->grab.y - 50.0f};
            inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, c->cur);
        });
        step(2, [this, c] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, c->cur); });
        step(5, [this, c, bone_named] {
            const Transform* t = world().get<Transform>(world().find_by_id("ik_target"));
            at_check(t && t->position.x > c->targetX + 20.0f && t->position.y > c->targetY + 20.0f,
                     "dragging the handle moves the IK target");
            at_check(undo_depth() == c->undo + 1, "...as ONE undo step");
            at_check(std::fabs(world().get<Transform>(bone_named("bone_1"))->rotation.z - c->rotBefore) > 0.01f,
                     "...and the bones turned to follow it");
            undo();
            const Transform* back = world().get<Transform>(world().find_by_id("ik_target"));
            at_check(back && std::fabs(back->position.x - c->targetX) < 0.01f, "Undo puts the target back");
            at_check(std::fabs(world().get<Transform>(bone_named("bone_1"))->rotation.z - c->rotBefore) < 0.01f,
                     "...and the bones with it");
        });
        snap("editor_bone_ik.png");
        step(2, [this] {
            bone_.tool = BoneTool::Off;
            showBoneTools_ = false;
            select_id("");
        });
    }
}

}  // namespace fa::editor
