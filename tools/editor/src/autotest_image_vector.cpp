// Autotest sections I2, L3 and J2: the Image and Vector panels.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
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

void Editor::at_section_I2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Image panel (docs/EDITOR.md, "Image panel"): a document made with image.create opens in the panel; a pixels layer is added from
    // the layer list, a red stroke is painted with the mouse, a rectangle is selected, its pixels are moved with the Transform tool, a
    // brightness adjustment is added and changed, Ctrl+Z / Ctrl+Y walk the steps back and forth through the editor's own undo stack, and
    // Save bakes the PNG whose pixels are checked. Every wait counts frames.
    {
        struct Is {
            size_t undo = 0;
            int mark = 0;
        };
        auto is = std::make_shared<Is>();
        const std::string docPath = "assets/at-image.image.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        // A drag on the canvas between two image positions (the mouse goes through the middle on the way).
        auto drag_image = [this, &step](float x0, float y0, float x1, float y1) {
            step(2, [this, x0, y0] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, image_screen_pos(x0, y0)); });
            step(2, [this, x0, y0] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, image_screen_pos(x0, y0)); });
            step(2, [this, x0, y0, x1, y1] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, image_screen_pos((x0 + x1) / 2, (y0 + y1) / 2)); });
            step(2, [this, x1, y1] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, image_screen_pos(x1, y1)); });
            step(4, [this, x1, y1] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, image_screen_pos(x1, y1)); });
        };
        auto pixel = [this](int x, int y) -> Color {
            ImageModel& m = *image_.model;
            return m.picture().pixel(x, y);
        };
        auto is_rgb = [](const Color& c, float r, float g, float b) {
            return std::fabs(c.r - r) < 0.02f && std::fabs(c.g - g) < 0.02f && std::fabs(c.b - b) < 0.02f && c.a > 0.98f;
        };
        step(2, [this, is, docPath] {
            std::error_code ec;
            stdfs::remove(projectDir_ + "/" + docPath, ec);   // a leftover of an earlier run
            Json args = Json::object({{"path", docPath}, {"width", 32}, {"height", 32},
                                      {"layers", Json::array({Json::object({{"kind", "fill"}, {"name", "background"}, {"color", "#ffffff"}})})}});
            const CommandResult r = engine_->commands().call("image.create", args);
            at_check(r.ok, "image.create made the document: " + (r.ok ? std::string() : command_error_text(r.error)));
            after_command("image.create", args, r);
            is->undo = undo_depth();
            open_image_document(docPath);
            image_.brush.color = Color{1, 0, 0, 1};
            image_.brush.size = 4;
            image_.tool = ImageTool::Brush;
        });
        wait_until([this] { return at_visible("img:canvas") && at_visible("img:layer:add"); });
        step(3, [this] {
            at_check(image_.model && image_.model->is_open() && image_.model->valid(), "the panel opened the document");
            at_check(image_.model->layer_rows().size() == 1, "...which lists the background layer");
            at_check(image_.canvasW > 40 && image_.canvasH > 40 && image_.zoom >= 1.0f, "...and the canvas shows it at a zoom of 100% or more");
            at_check(at_visible("img:save") && at_visible("img:tool:brush") && at_visible("img:tool:magic-wand"), "...with its toolbar and tools");
        });
        snap("editor_image_panel.png");

        // ---- add a pixels layer
        click_widget("img:layer:add");
        wait_until([this] { return at_visible("img:layer:add:pixels"); });
        click_widget("img:layer:add:pixels");
        step(4, [this, is] {
            ImageModel& m = *image_.model;
            at_check(m.layer_rows().size() == 2, "Add > pixels made a second layer");
            const ImageLayer* L = m.layer(m.selected_layer());
            at_check(L && L->kind == ImageLayerKind::Pixels, "...which is selected");
            at_check(undo_depth() == is->undo + 1, "...as ONE undo step of the editor's stack");
        });

        // ---- paint a red stroke
        drag_image(6.0f, 8.0f, 20.0f, 8.0f);
        step(4, [this, is, pixel, is_rgb] {
            at_check(is_rgb(pixel(14, 8), 1, 0, 0) && is_rgb(pixel(14, 7), 1, 0, 0), "a drag with the Brush paints red where the mouse went");
            at_check(is_rgb(pixel(14, 20), 1, 1, 1), "...and nothing elsewhere (the white background shows)");
            at_check(undo_depth() == is->undo + 2, "...the whole stroke is ONE undo step");
            at_check(!image_.model->stroking(), "...and the stroke is finished");
        });
        snap("editor_image_paint.png");

        // ---- select a rectangle
        click_widget("img:tool:rectangle");
        drag_image(4.0f, 4.0f, 12.0f, 12.0f);
        step(4, [this, is] {
            ImageModel& m = *image_.model;
            int x = 0, y = 0, w = 0, h = 0;
            at_check(m.has_selection() && m.selection_bounds(x, y, w, h) && x == 4 && y == 4 && w == 8 && h == 8, "the Rectangle tool selected 4,4 8x8");
            at_check(undo_depth() == is->undo + 3, "...as one undo step");
        });

        // ---- move the selected pixels with the Transform tool
        click_widget("img:tool:transform");
        wait_until([this] { return image_.model->transforming() && at_visible("img:tf:apply"); });
        drag_image(8.0f, 8.0f, 8.0f, 16.0f);
        step(3, [this] {
            const ImageModel::TransformState& t = image_.model->transform();
            at_check(t.active && std::abs(t.dy - 8) <= 1 && std::abs(t.dx) <= 1, "dragging inside the transform box moved it 8 pixels down");
        });
        snap("editor_image_transform.png");
        click_widget("img:tf:apply");
        step(4, [this, is, pixel, is_rgb] {
            at_check(!image_.model->transforming(), "Apply ended the transform");
            at_check(is_rgb(pixel(8, 16), 1, 0, 0), "...the selected red pixels are now 8 rows lower");
            at_check(is_rgb(pixel(8, 8), 1, 1, 1), "...and the old place shows the background again");
            at_check(is_rgb(pixel(16, 8), 1, 0, 0), "...while the red outside the selection stayed");
            at_check(undo_depth() == is->undo + 4, "...as one undo step");
        });

        // ---- an edit from the inspector (Visible) reloads the document in the middle of the frame that draws the inspector: the
        // rest of that frame (the other fields, the adjustment and effect lists) must not read the layer that was freed. Under ASan
        // this is the use-after-free check; the Visible toggle is taken back with Undo so the counts below stay the same.
        click_widget("img:insp:visible");
        step(4, [this, is] {
            const ImageLayer* L = image_.model->layer(image_.model->selected_layer());
            at_check(L && !L->visible, "the Visible box hid the layer");
            at_check(undo_depth() == is->undo + 5, "...as one undo step");
        });
        step(2, [this] { undo(); });
        step(3, [this, is] {
            const ImageLayer* L = image_.model->layer(image_.model->selected_layer());
            at_check(L && L->visible && undo_depth() == is->undo + 4, "Undo showed the layer again and left the stack where it was");
        });

        // ---- an adjustment: add it, then change it the way a slider does (a live preview, then one kept step)
        click_widget("img:op:add");
        wait_until([this] { return at_visible("img:op:add:brightness"); });
        click_widget("img:op:add:brightness");
        step(4, [this, is] {
            const ImageLayer* L = image_.model->layer(image_.model->selected_layer());
            at_check(L && L->adjustments.size() == 1 && L->adjustments[0].value("type", "") == "brightness", "Add > brightness put an adjustment on the layer");
            at_check(undo_depth() == is->undo + 5, "...as one undo step");
        });
        step(2, [this] {
            ImageModel& m = *image_.model;
            m.preview_operation(m.selected_layer(), false, 0, Json::object({{"amount", -1.0}}));
        });
        step(3, [this, is, pixel, is_rgb] {
            at_check(is_rgb(pixel(16, 8), 0, 0, 0), "the live preview of amount -1 darkens the layer on the canvas at once");
            at_check(undo_depth() == is->undo + 5, "...and a preview is not an undo step yet");
        });
        step(2, [this] { image_edited(image_.model->commit_operation_preview("Change brightness")); });
        step(3, [this, is, pixel, is_rgb] {
            at_check(undo_depth() == is->undo + 6, "letting go keeps it as ONE undo step");
            at_check(is_rgb(pixel(16, 8), 0, 0, 0) && is_rgb(pixel(8, 16), 0, 0, 0), "...and the picture stays dark");
        });
        snap("editor_image_adjustment.png");

        // ---- undo and redo go through the editor's stack
        step(2, [this] { undo(); });
        step(3, [this, pixel, is_rgb] { at_check(is_rgb(pixel(16, 8), 1, 0.2f, 0.2f), "Undo put the brightness back to its default (+0.2: a lighter red)"); });
        step(2, [this] { redo(); });
        step(3, [this, pixel, is_rgb] { at_check(is_rgb(pixel(16, 8), 0, 0, 0), "Redo darkened it again"); });
        for (int i = 0; i < 6; ++i) step(2, [this] { undo(); });
        step(4, [this, is, pixel, is_rgb] {
            at_check(undo_depth() == is->undo, "six Undos took back every image edit and left the stack where it was");
            at_check(image_.model->layer_rows().size() == 1 && !image_.model->has_selection(), "...the document is back to the background layer, with no selection");
            at_check(is_rgb(pixel(14, 8), 1, 1, 1), "...and the canvas is plain white");
        });
        for (int i = 0; i < 6; ++i) step(2, [this] { redo(); });
        step(4, [this, is, pixel, is_rgb] {
            at_check(undo_depth() == is->undo + 6, "six Redos brought them all back");
            at_check(is_rgb(pixel(16, 8), 0, 0, 0) && is_rgb(pixel(8, 16), 0, 0, 0) && is_rgb(pixel(8, 8), 1, 1, 1), "...with the same picture");
        });

        // ---- save bakes the PNG
        step(2, [this] { at_check(image_.model->bake_status().state != ImageBakeState::Fresh, "before Save the PNG is not baked from this document"); });
        click_widget("img:save");
        step(6, [this] {
            const ImageBakeStatus b = image_.model->bake_status();
            at_check(b.state == ImageBakeState::Fresh, "Save baked the PNG (the badge says baked)");
            auto img = load_image(projectDir_ + "/" + b.output);
            at_check(img.ok(), "...the baked PNG loads: " + b.output);
            if (img.ok()) {
                const Color dark = img->pixel(16, 8), moved = img->pixel(8, 16), old = img->pixel(8, 8);
                at_check(dark.r < 0.02f && dark.g < 0.02f && dark.b < 0.02f, "...with the stroke outside the selection darkened by the adjustment");
                at_check(moved.r < 0.02f && moved.g < 0.02f && moved.b < 0.02f, "...and the moved pixels in their new place");
                at_check(old.r > 0.98f && old.g > 0.98f && old.b > 0.98f, "...and white where they were");
            }
            const ImageDocument& d = image_.model->doc();
            at_check(d.layers.size() == 2, "...and the saved document has the two layers");
        });
        step(2, [this] {
            ImageModel& m = *image_.model;
            at_check(m.last_composite_ms() >= 0.0 && m.composites() > 0, "the panel measured its composites");
            FA_INFO("autotest", "image panel: {} composites, last {:.2f} ms", m.composites(), m.last_composite_ms());
        });

        // ---- a picture from the (fake) image provider: Inpaint selection... adds a provider layer, masked by the selection
        step(2, [this] {
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                atSavedConfig_ = aiConfig_;
                aiConfig_ = ai::default_config();
                aiConfig_.assets["image"] = ai::AssetRoute{"fake", "", ""};
            }
            image_.providerChecked = ~std::uint64_t(0);
            showImage_ = true;
            ImageModel& m = *image_.model;
            image_.layersBefore = int(m.layer_rows().size());
            image_edited(m.select_rect(4, 4, 12, 12, SelectOp::Replace));
        });
        wait_until([this] { return at_visible("img:provider:inpaint") && image_.noInpaint.empty(); });
        step(2, [this, is] {
            at_check(image_.noInpaint.empty() && image_.noGenerate.empty(), "with a provider that can inpaint, both provider actions are on");
            image_.providerUndo = undo_depth();
            image_.providerPrompt = "a round window";   // before the popup: the text box keeps its own copy while it has the focus
        });
        click_widget("img:provider:inpaint");
        wait_until([this] { return at_visible("img:provider:prompt") && at_visible("img:provider:go"); });
        click_widget("img:provider:go");
        wait_until([this] { return !image_.job && image_.model->layer_rows().size() == std::size_t(image_.layersBefore + 1); });
        step(3, [this] {
            ImageModel& m = *image_.model;
            const ImageLayer* L = m.layer(m.selected_layer());
            at_check(L && L->kind == ImageLayerKind::Provider && L->provenance.value("provider", "") == "fake",
                     "Inpaint selection... added a provider layer whose provenance names the provider");
            at_check(L && L->provenance.value("prompt", "") == "a round window", "...and the prompt");
            at_check(L && L->masks.size() == 1, "...masked by the selection");
            at_check(undo_depth() == image_.providerUndo + 1, "...as ONE undo step");
            at_check(image_.providerError.empty(), "...with no error shown");
        });
        step(2, [this] { undo(); });
        step(3, [this] {
            at_check(image_.model->layer_rows().size() == std::size_t(image_.layersBefore), "Undo took the provider layer away again");
        });
        // ---- the price of the popup's "Make it" has three states, each worked out on a thread: pending, ready, failed
        step(2, [this] {
            image_.providerInpaint = true;
            image_provider_estimate(*image_.model);   // (the popup polls it; the section polls it itself)
            at_check(image_.estimate && image_.providerEstimate.empty() && image_.providerEstimateError.empty(),
                     "the estimate starts pending: a thread is working it out and the popup has no sentence yet");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                image_provider_estimate_poll(*image_.model);
                return !image_.estimate;
            };
        });
        step(2, [this] {
            at_check(!image_.providerEstimate.empty() && image_.providerEstimateError.empty(), "...ready: a sentence about the price (" + image_.providerEstimate + ")");
            at_check(image_.providerEstimate.find("Free") == 0, "...and the fake provider's is free");
            image_edited(image_.model->deselect());
            image_provider_estimate(*image_.model);   // inpainting needs a selection: the same request would fail
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                image_provider_estimate_poll(*image_.model);
                return !image_.estimate;
            };
        });
        step(2, [this] {
            at_check(image_.providerEstimate.empty() && !image_.providerEstimateError.empty(), "...failed: no sentence, the reason instead (" + image_.providerEstimateError + ")");
            // "Make it" plans on the job's thread too: a request that cannot be planned comes back as the job's failure, nothing is added
            image_.providerPrompt = "a round window";
            image_provider_start(*image_.model);
            at_check(image_.job != nullptr, "Make it only starts the job's thread (the planning is not done on the UI thread)");
        });
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                image_provider_poll(*image_.model);
                return !image_.job;
            };
        });
        step(2, [this] {
            at_check(image_.providerError.find("failed") != std::string::npos && image_.model->layer_rows().size() == std::size_t(image_.layersBefore),
                     "...and a request that cannot be planned is reported as a failure of the job, with no layer added: " + image_.providerError);
            image_.providerError.clear();
            std::lock_guard<std::mutex> lock(aiMu_);
            if (atSavedConfig_) aiConfig_ = std::move(*atSavedConfig_);
            atSavedConfig_.reset();
            image_.providerChecked = ~std::uint64_t(0);
            showImage_ = false;
        });
    }
}

void Editor::at_section_L3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Image panel's pixel-art tools (docs/EDITOR.md, "Pixel-art tools"): an indexed document opens with its palette bar; the pixel grid
    // is drawn at a high zoom and goes away with its toggle; the Tiled toggle draws the neighbour copies; "+" adds a palette colour as one
    // undo step; a right-click on a swatch picks the secondary colour and a right-button drag paints with it; Add makes a second frame, whose
    // onion skin ghosts the first; Play moves to the other frame; Save bakes the PNG. Every wait counts frames.
    {
        struct Ls {
            size_t undo = 0;
        };
        auto ls = std::make_shared<Ls>();
        const std::string docPath = "assets/at-pixel.image.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto right_click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name), 1); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name), 1); });
        };
        // The document is still the one this section opened (a result is never applied to another scene's panel).
        auto current = [this, docPath] { return image_.model && image_.model->is_open() && image_.model->path() == docPath; };
        auto pixel = [this](int x, int y) -> Color { return image_.model->picture().pixel(x, y); };
        auto is_rgb = [](const Color& c, float r, float g, float b) {
            return std::fabs(c.r - r) < 0.02f && std::fabs(c.g - g) < 0.02f && std::fabs(c.b - b) < 0.02f && c.a > 0.98f;
        };
        step(2, [this, ls, docPath] {
            std::error_code ec;
            stdfs::remove(projectDir_ + "/" + docPath, ec);
            Json args = Json::object({{"path", docPath}, {"width", 16}, {"height", 16},
                                      {"palette", Json::array({"#101018", "#ff0000", "#00ff00"})},
                                      {"layers", Json::array({Json::object({{"kind", "indexed"}, {"name", "sprite"}})})}});
            const CommandResult r = engine_->commands().call("image.create", args);
            at_check(r.ok, "image.create made the pixel-art document: " + (r.ok ? std::string() : command_error_text(r.error)));
            after_command("image.create", args, r);
            ls->undo = undo_depth();
            open_image_document(docPath);
            image_.tool = ImageTool::Brush;
            image_.brush.size = 1;
            image_.brush.paletteIndex = 1;
            image_.brush.color = Color{1, 0, 0, 1};
            image_.zoom = 16.0f;   // pixel-art zoom: the grid threshold is passed
        });
        wait_until([this] { return at_visible("img:canvas") && at_visible("img:palette:1") && at_visible("img:frame:add"); });
        step(3, [this, current] {
            at_check(current(), "the pixel-art document is open");
            at_check(image_.gridDrawn, "at a high zoom the pixel grid is drawn");
            at_check(at_visible("img:palette:2") && at_visible("img:palette:add") && at_visible("img:onion"), "...with the palette bar and the frame timeline");
        });
        snap("editor_image_pixelart.png");
        click_widget("img:grid");
        step(3, [this] { at_check(!image_.gridDrawn, "the Grid toggle turns the grid off"); });
        click_widget("img:grid");
        step(3, [this] { at_check(image_.gridDrawn, "...and on again"); });
        click_widget("img:tiled");
        step(3, [this] { at_check(image_.tiled && image_.tiledDrawn, "the Tiled toggle draws the neighbour copies"); });
        click_widget("img:tiled");
        step(3, [this] { at_check(!image_.tiled && !image_.tiledDrawn, "...and off again"); });

        // ---- the palette bar: a new colour is one undo step
        step(2, [this] { image_.paletteHex = "#0000ff"; image_.paletteName = "sea"; });
        click_widget("img:palette:add");
        wait_until([this] { return at_visible("img:palette:add:apply"); });
        step(2, [this] { image_.paletteHex = "#0000ff"; image_.paletteName = "sea"; });
        click_widget("img:palette:add:apply");
        step(4, [this, ls, current] {
            at_check(current() && image_.model->palette().size() == 4, "+ added a fourth colour to the palette");
            at_check(image_.model->palette().find_name("sea") == 3, "...named sea");
            at_check(undo_depth() == ls->undo + 1, "...as ONE undo step");
        });
        step(2, [this] { undo(); });
        step(3, [this, current] { at_check(current() && image_.model->palette().size() == 3, "Undo took the colour away"); });
        step(2, [this] { redo(); });
        step(3, [this, current] { at_check(current() && image_.model->palette().size() == 4, "Redo brought it back"); });

        // ---- primary and secondary colours
        click_widget("img:palette:1");
        right_click_widget("img:palette:2");
        step(3, [this] {
            at_check(image_.brush.paletteIndex == 1 && image_.secondaryIndex == 2, "a left click on a swatch is the primary colour and a right click the secondary");
        });
        // paint with the left button (red) and the right button (green)
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, image_screen_pos(3.5f, 3.5f)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, image_screen_pos(3.5f, 3.5f)); });
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, image_screen_pos(3.5f, 3.5f)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, image_screen_pos(8.5f, 3.5f)); });
        step(2, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, image_screen_pos(8.5f, 3.5f), 1); });
        step(4, [this] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, image_screen_pos(8.5f, 3.5f), 1); });
        step(3, [this, current, pixel, is_rgb] {
            at_check(current() && is_rgb(pixel(3, 3), 1, 0, 0), "the left button paints with the primary colour");
            at_check(is_rgb(pixel(8, 3), 0, 1, 0), "...and the right button with the secondary one");
        });

        // ---- frames and the onion skin
        click_widget("img:frame:add");
        step(4, [this, current] {
            at_check(current() && image_.model->frame_count() == 2 && image_.model->frame() == 1, "Add made a second frame and selected it");
            at_check(image_.model->picture().pixel(3, 3).a < 0.01f, "...which is empty");
        });
        click_widget("img:onion");
        step(4, [this, current, pixel] {
            at_check(current() && image_.model->onion(), "the Onion skin box turns the ghosts on");
            at_check(pixel(3, 3).a > 0.05f, "...and the first frame's pixel shows faintly in the second");
        });
        snap("editor_image_onion.png");
        step(2, [this] {
            ImageModel& m = *image_.model;
            ImageModel::OnionSettings o = m.onion_settings();
            o.before = 0;
            m.set_onion_settings(o);
        });
        step(3, [this, pixel] { at_check(pixel(3, 3).a < 0.01f, "with 0 frames before there is no ghost"); });
        step(2, [this] {
            ImageModel& m = *image_.model;
            ImageModel::OnionSettings o = m.onion_settings();
            o.before = 1;
            m.set_onion_settings(o);
            m.set_onion(false);
        });
        // play: the frames follow their durations
        step(2, [this, current] {
            if (current()) image_.model->set_frame(0);
        });
        click_widget("img:frame:play");
        wait_until([this] { return !image_.model || image_.model->frame() == 1 || !image_.playing; });
        step(3, [this, current] {
            at_check(current() && image_.model->frame() == 1, "Play moved on to the second frame");
            image_.playing = false;
        });

        // ---- Resize canvas: one undo step, and undo gives the document back
        // The size button in the toolbar opens the popup; the popup's Resize button is disabled while the size is the current one.
        struct ResizeState {
            size_t depth = 0;
            int w = 0, h = 0;
        };
        auto rs = std::make_shared<ResizeState>();
        step(2, [this, current, rs] {
            if (!current()) return;
            rs->depth = undo_depth();
            rs->w = image_.model->width();
            rs->h = image_.model->height();
        });
        click_widget("img:resize");
        wait_until([this] { return at_visible("img:resize:apply"); });
        step(3, [this, current, rs] {
            at_check(current() && image_.resizeWidth == rs->w && image_.resizeHeight == rs->h, "the Resize popup opens with the document's size");
            image_.resizeWidth = rs->w + 4;
            image_.resizeHeight = rs->h + 2;
            image_.resizeAnchor = 8;  // bottom-right
        });
        click_widget("img:resize:apply");
        step(4, [this, current, rs] {
            at_check(current() && image_.model->width() == rs->w + 4 && image_.model->height() == rs->h + 2,
                     "Resize in the popup makes the canvas bigger (" + std::to_string(image_.model->width()) + "x" + std::to_string(image_.model->height()) + ")");
            at_check(undo_depth() == rs->depth + 1, "...as ONE undo step of the editor's stack");
            at_check(!at_visible("img:resize:apply"), "...and the popup closes");
        });
        step(2, [this] { undo(); });
        step(4, [this, current, rs] {
            at_check(current() && image_.model->width() == rs->w && image_.model->height() == rs->h,
                     "Undo gives the old canvas back (" + std::to_string(image_.model->width()) + "x" + std::to_string(image_.model->height()) + ")");
        });
        // the popup does not offer a resize to the size the canvas already has: its button is disabled, and a click changes nothing
        click_widget("img:resize");
        wait_until([this] { return at_visible("img:resize:apply"); });
        click_widget("img:resize:apply");
        step(4, [this, current, rs] {
            at_check(current() && image_.model->width() == rs->w && image_.model->height() == rs->h && undo_depth() == rs->depth,
                     "Resize with the unchanged size does nothing");
            at_check(at_visible("img:resize:apply") && !at_enabled("img:resize:apply"), "...and the popup stays open with its Resize button disabled");
        });
        step(2, [this] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, SAPP_KEYCODE_ESCAPE); });
        step(4, [this] { inject_key(SAPP_EVENTTYPE_KEY_UP, SAPP_KEYCODE_ESCAPE); });
        // the one-line toolbar fits the panel: the right edge of its widest item is inside the panel, which is inside the window
        step(2, [this, current] {
            const float right = image_.toolbarRight, limit = image_.toolbarLimit, display = ImGui::GetMainViewport()->Size.x;
            at_check(current() && right > 0 && right <= limit && right <= display,
                     "the whole toolbar fits in the panel (right edge " + std::to_string(int(right)) + ", panel " + std::to_string(int(limit)) + ", window " + std::to_string(int(display)) + ")");
        });

        // ---- Save bakes
        click_widget("img:save");
        step(6, [this, current] {
            at_check(current(), "the document is still the one open");
            const ImageBakeStatus b = image_.model->bake_status();
            at_check(b.state == ImageBakeState::Fresh, "Save baked the PNG (the badge says baked)");
            auto img = load_image(projectDir_ + "/" + b.output);
            at_check(img.ok(), "...the baked PNG loads: " + b.output);
            if (img.ok()) {
                at_check(img->width >= 16 && img->height >= 16, "...at least the document's size");
            }
        });
        step(2, [this] { showImage_ = false; });
    }
}

void Editor::at_section_J2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Vector panel (docs/EDITOR.md, "Vector panel"): an SVG with two rectangles opens in the panel; a triangle with one curved corner
    // is drawn with the Pen (clicks, a drag, a click on the first node to close), a corner is moved with the Node tool and made smooth,
    // the two rectangles are picked with a marquee and merged with Union, Ctrl+Z / Ctrl+Y walk the steps through the editor's own undo
    // stack, and the file on disk is checked. Then an image document with an svg layer: the Image panel's "Edit in Vector panel" button
    // opens the layer, an ellipse drawn there is written into the document, Undo takes it out and Save bakes the PNG. Every wait counts
    // frames.
    {
        struct Js {
            size_t undo = 0;
            std::string original;
            std::string drawn;
            std::string docBefore;
        };
        auto js = std::make_shared<Js>();
        const std::string svgPath = "assets/at-vector.svg";
        const std::string docPath = "assets/at-vector.image.json";
        auto wait_until = [this, &step](std::function<bool()> cond) {
            step(1, [this, cond] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        // A click and a drag on the canvas, in the drawing's own units (the mouse goes through the middle on the way).
        auto click_vec = [this, &step](double x, double y) {
            step(2, [this, x, y] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, vector_screen_pos(x, y)); });
            step(2, [this, x, y] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, vector_screen_pos(x, y)); });
            step(4, [this, x, y] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, vector_screen_pos(x, y)); });
        };
        auto drag_vec = [this, &step](double x0, double y0, double x1, double y1) {
            step(2, [this, x0, y0] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, vector_screen_pos(x0, y0)); });
            step(2, [this, x0, y0] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, vector_screen_pos(x0, y0)); });
            step(2, [this, x0, y0, x1, y1] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, vector_screen_pos((x0 + x1) / 2, (y0 + y1) / 2)); });
            step(2, [this, x1, y1] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, vector_screen_pos(x1, y1)); });
            step(4, [this, x1, y1] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, vector_screen_pos(x1, y1)); });
        };
        auto item = [this](const std::string& ref) -> const VecItem* {
            const int i = vector_.model ? vector_.model->scene().find(ref) : -1;
            return i < 0 ? nullptr : &vector_.model->scene().items[std::size_t(i)];
        };
        auto read_text = [this](const std::string& rel) {
            std::ifstream in(projectDir_ + "/" + rel, std::ios::binary);
            return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        };
        step(2, [this, js, svgPath] {
            std::error_code ec;
            stdfs::remove(projectDir_ + "/" + svgPath, ec);   // a leftover of an earlier run
            stdfs::create_directories(projectDir_ + "/assets", ec);
            std::ofstream out(projectDir_ + "/" + svgPath, std::ios::binary);
            out << "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"100\" height=\"100\">"
                   "<rect id=\"a\" x=\"10\" y=\"10\" width=\"30\" height=\"30\" fill=\"#d04030\"/>"
                   "<rect id=\"b\" x=\"25\" y=\"25\" width=\"35\" height=\"35\" fill=\"#3050d0\"/></svg>";
            out.close();
            js->undo = undo_depth();
            open_vector_document(svgPath);
            vector_.model->style.useStroke = false;
        });
        wait_until([this] { return at_visible("vec:canvas") && at_visible("vec:tool:Pen"); });
        step(3, [this, js, svgPath, read_text] {
            VectorModel& m = *vector_.model;
            js->original = read_text(svgPath);
            at_check(m.is_open() && m.valid() && m.scene().items.size() == 2, "the panel opened the svg with its two rectangles");
            at_check(vector_.canvasW > 40 && vector_.canvasH > 40 && vector_.zoom > 0.5f, "...and the canvas shows the drawing");
            at_check(at_visible("vec:save") && at_visible("vec:act:union") && at_visible("vec:tool:Node"), "...with its toolbar, actions and tools");
        });
        snap("editor_vector_panel.png");

        // ---- the Pen: three clicks (the second one dragged into a curve) and a click on the first node to close
        click_widget("vec:tool:Pen");
        click_vec(70, 10);
        drag_vec(90, 10, 96, 18);
        click_vec(90, 40);
        step(3, [this] { at_check(vector_.model->pen().active && vector_.model->pen().path[0].nodes.size() == 3, "three Pen clicks made three nodes of a path being drawn"); });
        click_vec(70, 10);
        step(4, [this, js, item] {
            VectorModel& m = *vector_.model;
            at_check(!m.pen().active && m.scene().items.size() == 3, "a click on the first node closed the path and wrote it");
            at_check(m.selection().size() == 1, "...the new path is selected");
            const VecItem* it = m.selection().empty() ? nullptr : item(m.selection()[0]);
            at_check(it && it->closed && it->nodeCount == 3 && it->curves, "...closed, with three nodes and a curved corner");
            at_check(it && it->nodes[0].nodes[1].hasOut, "...the dragged node has its handles");
            at_check(undo_depth() == js->undo + 1, "...as ONE undo step of the editor's stack");
            js->drawn = m.selection().empty() ? std::string() : m.selection()[0];
        });
        snap("editor_vector_pen.png");

        // ---- the Node tool: move a corner, then make it smooth
        click_widget("vec:tool:Node");
        drag_vec(70, 10, 72, 22);
        step(4, [this, js, item] {
            const VecItem* it = item(js->drawn);
            at_check(it && std::abs(it->nodes[0].nodes[0].p.x - 72) < 1.0 && std::abs(it->nodes[0].nodes[0].p.y - 22) < 1.0, "dragging an anchor with the Node tool moved it to 72,22");
            at_check(undo_depth() == js->undo + 2, "...as one undo step");
        });
        click_widget("vec:node:smooth");
        step(4, [this, js, item] {
            const VecItem* it = item(js->drawn);
            at_check(it && it->nodes[0].nodes[0].hasIn && it->nodes[0].nodes[0].hasOut, "Make smooth gave the moved anchor its two handles");
            at_check(undo_depth() == js->undo + 3, "...as one undo step");
        });
        snap("editor_vector_nodes.png");

        // ---- a marquee picks the two rectangles, Union merges them
        click_widget("vec:tool:Select");
        drag_vec(5, 5, 65, 65);
        step(4, [this] { at_check(vector_.model->selection().size() == 2, "a marquee from left to right picked the two rectangles (not the triangle)"); });
        click_widget("vec:act:union");
        step(4, [this, js] {
            VectorModel& m = *vector_.model;
            at_check(m.scene().items.size() == 2 && m.selection().size() == 1, "Union made one shape of the two rectangles, and selected it");
            at_check(undo_depth() == js->undo + 4, "...as one undo step");
        });
        snap("editor_vector_union.png");

        // ---- undo and redo go through the editor's stack
        step(2, [this] { undo(); });
        step(4, [this] { at_check(vector_.model->scene().items.size() == 3 && vector_.model->scene().find("a") >= 0, "Undo brought the two rectangles back (a, b and the triangle)"); });
        step(2, [this] { redo(); });
        step(4, [this] { at_check(vector_.model->scene().items.size() == 2 && vector_.model->scene().find("b") < 0, "Redo merged them again (the union keeps the first shape's id)"); });
        for (int i = 0; i < 4; ++i) step(2, [this] { undo(); });
        step(4, [this, js, svgPath, read_text] {
            at_check(undo_depth() == js->undo, "four Undos took back every vector edit and left the stack where it was");
            at_check(read_text(svgPath) == js->original, "...and the file on disk is the SVG we started with, byte for byte");
            at_check(vector_.model->scene().items.size() == 2, "...the canvas shows the two rectangles");
        });
        for (int i = 0; i < 4; ++i) step(2, [this] { redo(); });
        step(4, [this, js, svgPath, read_text, item] {
            at_check(undo_depth() == js->undo + 4, "four Redos brought them all back");
            const std::string text = read_text(svgPath);
            at_check(text.find("id=\"" + js->drawn + "\"") != std::string::npos && text.find("<rect") == std::string::npos, "...the file has the triangle and the merged shape, and no rectangle");
            const VecItem* it = item(js->drawn);
            at_check(it && it->nodes[0].nodes[0].hasIn, "...the triangle kept its smooth corner");
        });
        click_widget("vec:save");
        step(3, [this] { at_check(vector_.model->status().find("already written") != std::string::npos, "Save on an svg file says every edit is already written"); });

        // ---- an svg layer of an image document, from the Image panel
        step(2, [this, js, docPath] {
            std::error_code ec;
            stdfs::remove(projectDir_ + "/" + docPath, ec);
            stdfs::remove(projectDir_ + "/assets/at-vector.png", ec);
            const std::string svg =
                "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" width=\"64\" height=\"64\"><rect id=\"box\" x=\"6\" y=\"6\" width=\"28\" height=\"28\" fill=\"#d04030\"/></svg>";
            Json args = Json::object({{"path", docPath}, {"width", 64}, {"height", 64},
                                      {"layers", Json::array({Json::object({{"kind", "fill"}, {"name", "bg"}, {"color", "#ffffff"}}),
                                                              Json::object({{"kind", "svg"}, {"name", "art"}, {"svg", svg}})})}});
            const CommandResult r = engine_->commands().call("image.create", args);
            at_check(r.ok, "image.create made a document with an svg layer: " + (r.ok ? std::string() : command_error_text(r.error)));
            after_command("image.create", args, r);
            js->undo = undo_depth();
            open_image_document(docPath);
            showVector_ = false;
        });
        wait_until([this] { return at_visible("img:canvas") && at_visible("img:layer:add"); });
        step(2, [this] { image_.model->select_layer("1"); });
        wait_until([this] { return at_visible("img:insp:edit_vector"); });
        click_widget("img:insp:edit_vector");
        wait_until([this] { return vector_.model && vector_.model->is_layer() && at_visible("vec:canvas") && at_visible("vec:tool:Ellipse"); });
        step(3, [this, docPath] {
            VectorModel& m = *vector_.model;
            at_check(m.valid() && m.path() == docPath && m.layer_path() == "1", "Edit in Vector panel opened the svg layer of the document");
            at_check(m.scene().items.size() == 1 && m.scene().find("box") >= 0, "...with its rectangle");
        });
        click_widget("vec:tool:Ellipse");
        drag_vec(40, 36, 60, 56);
        step(4, [this, js, docPath, read_text] {
            VectorModel& m = *vector_.model;
            js->docBefore = read_text(docPath);
            at_check(m.scene().items.size() == 2, "dragging with the Ellipse tool added a shape to the layer");
            at_check(js->docBefore.find("<circle") != std::string::npos && js->docBefore.find("id=\\\"box\\\"") != std::string::npos,
                     "...and it is in the image document's JSON, next to the rectangle with its id");
            at_check(undo_depth() == js->undo + 1, "...as one undo step");
        });
        // the Image panel reads the document again on its own (every 20 frames)
        wait_until([this] { return image_.model && image_.model->json().dump().find("<circle") != std::string::npos; });
        step(2, [this] { at_check(true, "the Image panel read the document again and has the new shape"); });
        step(2, [this] { undo(); });
        step(4, [this, js, docPath, read_text] {
            at_check(vector_.model->scene().items.size() == 1, "Undo took the ellipse out of the layer");
            at_check(read_text(docPath).find("<circle") == std::string::npos, "...and out of the document");
        });
        step(2, [this] { redo(); });
        click_widget("vec:save");
        step(8, [this] {
            const ImageBakeStatus b = image_.model ? image_.model->bake_status() : ImageBakeStatus{};
            auto img = load_image(projectDir_ + "/" + b.output);
            at_check(!b.output.empty() && img.ok(), "Save baked the document's PNG: " + b.output);
            if (img.ok()) {
                const Color box = img->pixel(15, 15), circle = img->pixel(50, 46), blank = img->pixel(60, 8);
                at_check(box.r > 0.7f && box.g < 0.4f, "...the rectangle of the svg layer is in it");
                at_check(circle.b > 0.8f && circle.r < 0.6f, "...and so is the ellipse drawn in the Vector panel (the default blue)");
                at_check(blank.r > 0.98f && blank.g > 0.98f && blank.b > 0.98f, "...on the white background");
            }
        });
        step(2, [this] {
            FA_INFO("autotest", "vector panel: scene read {:.2f} ms, last picture {:.2f} ms", vector_.model->last_scene_ms(), vector_.model->last_raster_ms());
            showVector_ = false;
            showImage_ = false;
        });
    }
}

}  // namespace fa::editor
