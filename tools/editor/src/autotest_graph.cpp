// Autotest section G3: the Graph panel. Split from the other autotest files: an Editor::at_section_G3(AtScript&) that adds its steps to the
// script, called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>

#include "autotest_common.h"
#include "editor_internal.h"
#include "sokol_app.h"

namespace fa::editor {

using namespace at_support;

namespace stdfs = std::filesystem;

void Editor::at_section_G3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // The Graph panel (docs/EDITOR.md, "Graph panel"): a material with a one-node graph opens, three nodes are added from the palette (a right click
    // on the canvas; the search box for one), four links are dragged from port to port (ONE undo step each), the dissolve graph checks with no
    // problem and the live preview compiles it and draws a picture, Save writes the material and the snippet (one set of code with
    // material.graph.generate), a snippet edited by hand is only overwritten after the question, and Undo/Redo walk every edit back and forth
    // through the editor's stack. Every wait counts frames or state.
    {
        struct Gs {
            size_t undo = 0;
            std::string saved;
            bool skip = false;
            int compiles = 0;
            std::uint64_t serial = 0;  // a picture of the preview, to see it change
            std::string fileBefore;
            size_t undoParam = 0;
            size_t undoEntry = 0;  // the undo depth before the param is made in the panel
            std::string reader;    // the node that reads it
        };
        auto gs = std::make_shared<Gs>();
        const std::string dir = "assets/at-graph";
        const std::string rel = dir + "/dissolve.material.json";
        const std::string snippet = dir + "/dissolve.surface.glsl";
        auto wait_until = [this, &step](std::function<bool()> cond, const std::string& what) {
            step(1, [this, cond, what] {
                atWaitCount_ = 0;
                atWaitUntil_ = cond;
                atWaitWhat_ = what;
            });
        };
        auto click_widget = [this, &step](const std::string& name) {
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget(name)); });
            step(2, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget(name)); });
            step(4, [this, name] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget(name)); });
        };
        auto read_text = [this](const std::string& r) {
            std::ifstream in(stdfs::path(projectDir_) / r, std::ios::binary);
            return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        };
        // A right click without a drag on empty canvas opens the node palette there.
        auto right_click_graph = [this, &step](float gx, float gy) {
            step(2, [this, gx, gy] { inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, graph_screen_pos(gx, gy)); });
            step(2, [this, gx, gy] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, graph_screen_pos(gx, gy), 1); });
            step(3, [this, gx, gy] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, graph_screen_pos(gx, gy), 1); });
        };
        // The same, at graph y `wantedY` or as low as the canvas goes: at zoom 0.5 and pan 24 a fixed y can fall below the bottom of a short canvas (the
        // window of a 1024x642 display). The click is made at the clamped point; the check says so when there is no room below the first node.
        auto right_click_graph_low = [this, &step](float gx, float wantedY) {
            auto y = std::make_shared<float>(wantedY);
            step(2, [this, gx, y, wantedY] {
                *y = std::min(wantedY, (graph_.canvasH - 30.0f - graph_.panY) / graph_.zoom);
                at_check(*y > 260.0f, "the canvas is tall enough for an empty point below the noise node (canvas " +
                                          std::to_string(int(graph_.canvasH)) + " px high)");
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, graph_screen_pos(gx, *y));
            });
            step(2, [this, gx, y] { inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, graph_screen_pos(gx, *y), 1); });
            step(3, [this, gx, y] { inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, graph_screen_pos(gx, *y), 1); });
        };
        // Drag a link from an output port to an input port.
        auto link = [this, &step](const std::string& fromNode, const std::string& fromPort, const std::string& toNode,
                                  const std::string& toPort) {
            step(2, [this, fromNode, fromPort] {
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, graph_node_screen(fromNode, fromPort, true));
            });
            step(2, [this, fromNode, fromPort] {
                inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, graph_node_screen(fromNode, fromPort, true));
            });
            step(2, [this, fromNode, fromPort, toNode, toPort] {
                const Vec2 a = graph_node_screen(fromNode, fromPort, true),
                           b = graph_node_screen(toNode, toPort, false);
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, Vec2{(a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f});
            });
            step(2, [this, toNode, toPort] {
                inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, graph_node_screen(toNode, toPort, false));
            });
            step(4, [this, toNode, toPort] {
                inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, graph_node_screen(toNode, toPort, false));
            });
        };
        auto ready = [this] {
            return graph_.model && graph_.model->is_open() && at_visible("gr:canvas") && at_visible("gr:add") &&
                   graph_.canvasW > 150 && graph_.canvasH > 100;
        };

        // ---- a material with a graph of one output node, opened in the panel
        step(2, [this, gs, dir, rel] {
            std::error_code ec;
            stdfs::remove_all(stdfs::path(projectDir_) / dir, ec);  // a leftover of an earlier run
            stdfs::create_directories(stdfs::path(projectDir_) / dir, ec);
            const char* material = R"({
  "format": "factoria.material/1",
  "doc": "Dissolve: noise burns the surface away with a glowing edge.",
  "shader": "assets/at-graph/dissolve.surface.glsl",
  "alphaMode": "clip",
  "params": {
    "dissolve": { "type": "float", "default": 0.35, "min": 0.0, "max": 1.0, "doc": "0 shows the surface, 1 dissolves it all." }
  },
  "graph": {
    "nodes": [
      { "id": "out", "type": "output", "pos": [440, 60], "inputs": { "albedo": [0.6, 0.6, 0.65], "roughness": 0.7 } }
    ],
    "links": []
  }
})";
            std::ofstream(stdfs::path(projectDir_) / rel, std::ios::binary) << material;
            project_files_changed();
            gs->undo = undo_depth();
            showGraph_ = true;
            open_graph_document(rel, false, true);
            focus_window("Graph");
        });
        wait_until(ready, "the Graph panel to open the material");
        step(3, [this, gs, rel] {
            GraphModel& m = *graph_.model;
            at_check(m.path() == rel && m.node_count() == 1 && m.link_count() == 0,
                     "the material opens with its one output node");
            at_check(m.snippet_state() == "missing", "...its snippet has not been written yet (state \"missing\")");
            at_check(undo_depth() == gs->undo, "...and opening is not an undo step");
            // a fixed view, so the script knows where the graph is: half size, a little off the corner
            graph_.zoom = 0.5f;
            graph_.panX = 24.0f;
            graph_.panY = 24.0f;
        });
        step(3, [] {});

        // ---- nodes from the palette: a right click on the canvas opens it at the mouse
        right_click_graph(0.0f, 0.0f);
        wait_until([this] { return at_visible("gr:filter"); }, "the node palette (right click on the canvas)");
        step(3, [this] {
            // the search box has the keyboard: "noise" narrows the list
            for (char c : std::string("noise")) inject_char(unsigned(static_cast<unsigned char>(c)));
        });
        wait_until([this] { return at_visible("gr:add:noise.fbm") && graph_.filter == "noise"; },
                   "the palette to list noise.fbm");
        step(3, [this] {
            const std::vector<const GraphNodeType*> list = graph_.model->palette(graph_.filter);
            at_check(!list.empty() && !at_visible("gr:add:math.add"),
                     "the search narrows the palette: noise nodes stay, math.add goes");
        });
        click_widget("gr:add:noise.fbm");
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 2 && m.node_index("noise_fbm") >= 0,
                     "a click in the palette adds the node (noise_fbm)");
            at_check(undo_depth() == gs->undo + 1, "...as one undo step");
        });
        right_click_graph_low(0.0f,
                              300.0f);  // below the noise node (about 250 units tall at its default size): empty canvas
        wait_until([this] { return at_visible("gr:add:param"); }, "the palette to list the param node");
        click_widget("gr:add:param");
        right_click_graph(220.0f, 60.0f);
        wait_until([this] { return at_visible("gr:add:dissolve"); }, "the palette to list the dissolve node");
        click_widget("gr:add:dissolve");
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 4 && m.node_index("param") >= 0 && m.node_index("dissolve") >= 0,
                     "the param and dissolve nodes are added too");
            const Json node = m.graph()["nodes"][std::size_t(m.node_index("param"))];
            at_check(node.value("param", std::string()) == "dissolve",
                     "...the param node names the material's one param");
            at_check(undo_depth() == gs->undo + 3, "...three nodes, three undo steps");
        });

        // ---- links dragged from port to port
        link("noise_fbm", "value", "dissolve", "noise");
        step(3, [this, gs] {
            at_check(graph_.model->link_count() == 1 && graph_.model->link_index_into("dissolve", "noise") >= 0,
                     "dragging noise_fbm.value onto dissolve.noise makes a link");
            at_check(undo_depth() == gs->undo + 4, "...as one undo step");
        });
        link("param", "value", "dissolve", "threshold");
        link("dissolve", "alpha", "out", "alpha");
        link("dissolve", "emission", "out", "emission");
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            at_check(m.link_count() == 4, "four links in all");
            at_check(undo_depth() == gs->undo + 7, "...each one undo step");
            at_check(!m.has_errors(), "the dissolve graph checks with no error");
            at_check(m.dirty(), "...and is not saved yet");
            graph_edited(m.set_input("noise_fbm", "scale", Json(6.0)));
            graph_edited(m.set_input("dissolve", "edgeWidth", Json(0.06)));
            at_check(undo_depth() == gs->undo + 9, "a constant typed on a node is one undo step too");
        });

        // ---- the live preview compiles the graph as edited (not as saved)
        wait_until(
            [this] {
                const PreviewState s = graph_.preview->state();
                return graph_.preview->shown_revision() == graph_.model->revision() || s == PreviewState::Error ||
                       s == PreviewState::NoRenderer;
            },
            "the preview to compile the dissolve graph");
        step(3, [this, gs] {
            const GraphPreview& pv = *graph_.preview;
            const std::string msg = pv.message();
            if (pv.state() == PreviewState::NoRenderer) {
                gs->skip = true;
                atLog_.push_back("SKIP Graph preview (this window has no GPU renderer)");
                return;
            }
            if (pv.state() == PreviewState::Error) {
                // a machine without the shader compiler cannot compile any material; CI installs it and sets FA_REQUIRE_SHDC=1
                const bool noShdc =
                    msg.find("shdc") != std::string::npos || msg.find("shader compiler") != std::string::npos;
                const char* required = std::getenv("FA_REQUIRE_SHDC");
                if (noShdc && !(required && std::string(required) == "1")) {
                    gs->skip = true;
                    atLog_.push_back("SKIP Graph preview (no sokol-shdc? set SOKOL_SHDC): " + msg);
                    return;
                }
                at_check(false, "the preview compiled the dissolve graph: " + msg);
                return;
            }
            at_check(pv.state() == PreviewState::Ready && !pv.image().empty(),
                     "the preview compiled the graph and drew a picture");
            int covered = 0;
            for (std::size_t i = 3; i < pv.image().rgba.size(); i += 4)
                if (pv.image().rgba[i] > 0) ++covered;
            at_check(covered > 2000, "...the sphere is in it (" + std::to_string(covered) + " pixels drawn)");
            at_check(at_visible("gr:preview"), "...and the panel shows it");
            gs->compiles = pv.compiles();
        });
        snap("editor_graph_panel.png");

        // ---- a kind the preview cannot draw says why (a sky material needs the scene around it); nothing is compiled or drawn
        step(3, [this, gs] {
            if (gs->skip) return;
            GraphPreview sky(projectDir_);
            sky.set_immediate(true);
            sky.set_document(Json::parse(R"({"format":"factoria.material/1","kind":"sky","shader":"x.sky.glsl"})"), 1,
                             "x.material.json");
            sky.tick(engine_ ? engine_->renderer() : nullptr);
            at_check(
                sky.state() == PreviewState::Unsupported && sky.message().find("skyMaterial") != std::string::npos &&
                    sky.image().empty() && sky.compiles() == 0,
                "a sky material is not drawn wrongly: the preview says it needs the scene (" + sky.message() + ")");
        });

        // ---- params: a slider changes the preview only (the file is not touched, nothing compiles again) ...
        step(3, [this, gs, rel, read_text] {
            if (gs->skip) return;
            GraphPreview& pv = *graph_.preview;
            at_check(at_visible("gr:param:dissolve"), "the Params section lists the material's param with a slider");
            gs->serial = pv.image_serial();
            gs->fileBefore = read_text(rel);
            gs->compiles = pv.compiles();
            pv.set_param("dissolve", Json(0.8));  // what moving the slider does
        });
        wait_until(
            [this, gs] {
                return gs->skip || (graph_.preview->image_serial() != gs->serial &&
                                    at_visible("gr:param:default:dissolve") && at_visible("gr:param:reset:dissolve"));
            },
            "the preview to draw the overridden param and the panel to offer Reset and Set as default");
        step(3, [this, gs, rel, read_text] {
            if (gs->skip) return;
            GraphPreview& pv = *graph_.preview;
            at_check(pv.param_overrides().contains("dissolve") && pv.state() == PreviewState::Ready,
                     "the override is drawn: the preview stays up to date");
            at_check(read_text(rel) == gs->fileBefore, "...the file is not touched");
            at_check(pv.compiles() == gs->compiles, "...and the shader is not compiled again");
            gs->undoParam = undo_depth();
        });
        // ... "Set as default" writes the value into the file, as one undo step, and the unsaved graph stays unsaved
        click_widget("gr:param:default:dissolve");
        step(3, [this, gs, rel, read_text] {
            if (gs->skip) return;
            Json file = Json::parse(read_text(rel), nullptr, false);
            const double v = !file.is_discarded() && file.contains("params") && file["params"].contains("dissolve")
                                 ? file["params"]["dissolve"].value("default", -1.0)
                                 : -1.0;
            at_check(std::abs(v - 0.8) < 1e-9, "Set as default writes 0.8 as the param's default in the file");
            at_check(undo_depth() == gs->undoParam + 1, "...as one undo step");
            at_check(graph_.model->dirty() && graph_.model->node_count() == 4,
                     "...and the graph's unsaved edits stay unsaved");
            at_check(graph_.preview->param_overrides().empty(),
                     "...the override is gone: the default is the value now");
            undo();
        });
        step(3, [this, gs, rel, read_text] {
            if (gs->skip) return;
            Json file = Json::parse(read_text(rel), nullptr, false);
            const double v = !file.is_discarded() && file.contains("params") && file["params"].contains("dissolve")
                                 ? file["params"]["dissolve"].value("default", -1.0)
                                 : -1.0;
            at_check(std::abs(v - 0.35) < 1e-9, "Undo puts the old default back in the file");
            redo();
        });
        step(3, [this, gs, rel, read_text] {
            if (gs->skip) return;
            Json file = Json::parse(read_text(rel), nullptr, false);
            const double v = !file.is_discarded() && file.contains("params") && file["params"].contains("dissolve")
                                 ? file["params"]["dissolve"].value("default", -1.0)
                                 : -1.0;
            at_check(std::abs(v - 0.8) < 1e-9, "...and Redo writes 0.8 again");
        });
        wait_until(
            [this, gs] {
                const PreviewState s = graph_.preview->state();
                return gs->skip || graph_.preview->shown_revision() == graph_.model->revision() ||
                       s == PreviewState::Error;
            },
            "the preview to follow the new default");

        // ---- Compare: the last saved version (the one-node graph in the file) beside the current one
        click_widget("gr:compare");
        wait_until(
            [this, gs] {
                const PreviewState s = graph_.preview->saved_state();
                return gs->skip ||
                       (graph_.preview->compare() && (s == PreviewState::Ready || s == PreviewState::Error));
            },
            "the preview to draw the saved version");
        step(3, [this, gs] {
            if (gs->skip) return;
            const GraphPreview& pv = *graph_.preview;
            at_check(pv.has_saved() && pv.saved_state() == PreviewState::Ready && !pv.saved_image().empty(),
                     "Compare draws the saved version too: " + pv.saved_message());
            at_check(at_visible("gr:preview:saved") && at_visible("gr:preview"), "...both pictures are on the panel");
            at_check(pv.saved_image().rgba != pv.image().rgba, "...and they differ: the edits changed the picture");
            graph_.preview->set_compare(false);  // the Save below would compile the saved version again
        });

        // ---- a graph with an error: the preview says why and keeps the last picture
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            // a node whose type does not exist cannot be added by the panel; a link the checker refuses is refused by the model
            const GraphEditOutcome bad = m.connect("dissolve.emission", "noise_fbm.scale");
            at_check(!bad.ok && !bad.error.empty(),
                     "a link of the wrong type is refused with the checker's sentence: " + bad.error);
            at_check(m.link_count() == 4 && !m.has_errors(), "...and the graph stays as it was");
        });

        // ---- Save: the material and the snippet come from material.graph.generate
        click_widget("gr:save");
        step(3, [this, gs, rel, snippet, read_text] {
            GraphModel& m = *graph_.model;
            const Json file = Json::parse(read_text(rel), nullptr, false);
            at_check(!file.is_discarded() && file.contains("graphHash") && file["graph"]["links"].size() == 4,
                     "Save wrote the graph and its hash into the material");
            const std::string text = read_text(snippet);
            at_check(!text.empty() && text.find("dissolve") != std::string::npos,
                     "...and the shader snippet next to it");
            at_check(!m.dirty() && m.snippet_state() == "in_sync", "...the panel says the snippet is in sync");
            gs->saved = text;
        });

        // ---- a snippet edited by hand is not overwritten without the question
        step(3, [this, gs, snippet, read_text] {
            std::ofstream(stdfs::path(projectDir_) / snippet, std::ios::binary | std::ios::app)
                << "\n// edited by hand\n";
            GraphModel& m = *graph_.model;
            graph_edited(m.move_nodes({"out"}, 20.0f, 0.0f));
            at_check(read_text(snippet).find("edited by hand") != std::string::npos, "the snippet was edited by hand");
        });
        click_widget("gr:save");
        wait_until([this] { return at_visible("gr:force"); }, "the question before overwriting a hand-edited snippet");
        step(3, [this, snippet, read_text] {
            at_check(read_text(snippet).find("edited by hand") != std::string::npos,
                     "Save asked first: the hand edit is still in the file");
        });
        click_widget("gr:force:cancel");
        step(3, [this, snippet, read_text] {
            at_check(read_text(snippet).find("edited by hand") != std::string::npos && graph_.model->dirty(),
                     "Cancel keeps the hand edit and the unsaved graph");
        });
        click_widget("gr:save");
        wait_until([this] { return at_visible("gr:force"); }, "the question before overwriting a hand-edited snippet");
        click_widget("gr:force");
        step(3, [this, snippet, read_text] {
            at_check(read_text(snippet).find("edited by hand") == std::string::npos && !graph_.model->dirty(),
                     "Overwrite writes the snippet from the graph again");
        });

        // ---- a file that changed on disk behind the editor: Save asks before it replaces it
        step(3, [this, gs, rel, read_text] {
            GraphModel& m = *graph_.model;
            graph_edited(m.move_nodes({"out"}, 10.0f, 0.0f));
            gs->fileBefore =
                read_text(rel) + "\n";  // another size: the change is seen at once, whatever the file times do
            std::ofstream(stdfs::path(projectDir_) / rel, std::ios::binary) << gs->fileBefore;
            at_check(m.dirty(), "an unsaved move, and the file written by someone else");
        });
        click_widget("gr:save");
        wait_until([this] { return at_visible("gr:conflict:overwrite"); },
                   "the question before replacing a file that changed");
        step(3, [this, gs, rel, read_text] {
            at_check(read_text(rel) == gs->fileBefore, "Save asked first: the file is still the outside version");
        });
        click_widget("gr:conflict:cancel");
        step(3, [this, gs, rel, read_text] {
            at_check(read_text(rel) == gs->fileBefore && graph_.model->dirty() && graph_.model->external_conflict(),
                     "Cancel writes nothing and keeps the unsaved graph");
        });
        click_widget("gr:save");
        wait_until([this] { return at_visible("gr:conflict:overwrite"); }, "the question again");
        click_widget("gr:conflict:overwrite");
        step(3, [this, gs, rel, read_text] {
            at_check(read_text(rel) != gs->fileBefore && !graph_.model->dirty() && !graph_.model->external_conflict(),
                     "Overwrite writes the graph over the file");
        });

        // ---- Undo and Redo through the editor's stack
        step(3, [this, gs] {
            // every undo takes one entry off the stack, so the loop ends after as many calls as there were entries
            for (size_t left = undo_depth(); left > 0 && undo_depth() > gs->undo; --left) undo();
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 1 && m.link_count() == 0, "Undo walks every edit back to the one-node graph");
        });
        step(3, [this, gs] {
            for (size_t left = redo_.size(); left > 0 && !redo_.empty(); --left) redo();  // one entry per call
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 4 && m.link_count() == 4 && !m.has_errors(),
                     "Redo brings the dissolve graph back");
            at_check(undo_depth() > gs->undo, "...on the editor's undo stack");
        });

        // ---- a param made in the panel, used by a node, renamed and deleted without leaving the panel (every wait is on state)
        step(3, [this, gs, rel] {
            gs->undoEntry = undo_depth();
            gs->compiles = graph_.preview ? graph_.preview->compiles() : 0;
            at_check(graph_.model && graph_.model->path() == rel && at_visible("gr:params:add"),
                     "the Params section offers + Param");
        });
        click_widget("gr:params:add");
        wait_until([this] { return graph_.entryForm.open && at_visible("gr:entry:create"); }, "the new param form");
        step(3, [this] {
            // the name box has the keyboard when the form opens: the name is typed into it
            for (char c : std::string("glow")) inject_char(unsigned(static_cast<unsigned char>(c)));
        });
        wait_until([this] { return std::string(graph_.entryForm.name) == "glow"; }, "the name typed into the form");
        step(3, [this] {
            graph_.entryForm.ranged = true;  // the other fields are set directly: they are not text boxes
            graph_.entryForm.lo = 0.0f;
            graph_.entryForm.hi = 1.0f;
            graph_.entryForm.value[0] = 0.25f;
        });
        click_widget("gr:entry:create");
        wait_until(
            [this] {
                const Json& d = graph_.model->material_json();
                return d.contains("params") && d["params"].contains("glow") && !graph_.entryForm.open;
            },
            "the Create button to write the param glow");
        step(3, [this, gs, rel, read_text] {
            const Json file = Json::parse(read_text(rel), nullptr, false);
            at_check(!file.is_discarded() && file["params"].contains("glow") &&
                         std::abs(file["params"]["glow"].value("default", -1.0) - 0.25) < 1e-9 &&
                         file["params"]["glow"].value("max", 0.0) == 1.0,
                     "Create wrote the param glow (default 0.25, max 1) into the file");
            at_check(undo_depth() == gs->undoEntry + 1, "...as one undo step");
            at_check(at_visible("gr:param:glow"), "...and the Params list shows it");
            // a node that reads it: the combo of the node offers it at once (it lists the model's params)
            GraphModel& m = *graph_.model;
            const GraphEditOutcome added = m.add_node("param", Vec2{0.0f, 300.0f});
            graph_edited(added);
            const GraphEditOutcome ref = m.set_ref(added.id, "glow");
            graph_edited(ref);
            gs->reader = added.id;
            at_check(added.ok && ref.ok && m.entry_readers(false, "glow").size() == 1, "a param node reads glow");
            at_check(!m.has_errors(), "...and the graph still checks");
        });
        // the preview compiles the material with the new param (its uniforms changed)
        wait_until(
            [this] {
                const PreviewState s = graph_.preview->state();
                return graph_.preview->shown_revision() == graph_.model->revision() || s == PreviewState::Error ||
                       s == PreviewState::NoRenderer;
            },
            "the preview to follow the new param");
        step(3, [this, gs] {
            const GraphPreview& pv = *graph_.preview;
            if (!gs->skip && pv.state() != PreviewState::NoRenderer)
                at_check(pv.state() == PreviewState::Ready && pv.compiles() > gs->compiles,
                         "the preview compiled again with the new param: " + pv.message());
        });
        // rename through the row's buttons: the node follows
        click_widget("gr:param:rename:glow");
        wait_until([this] { return graph_.renaming == "glow" && at_visible("gr:param:rename:ok:glow"); },
                   "the rename box of glow");
        step(3, [this] {  // the box has the keyboard with its text selected: the new name replaces it
            for (char c : std::string("shine")) inject_char(unsigned(static_cast<unsigned char>(c)));
        });
        wait_until([this] { return std::string(graph_.renameBuf) == "shine"; },
                   "the new name typed into the rename box");
        click_widget("gr:param:rename:ok:glow");
        wait_until(
            [this] {
                const Json& d = graph_.model->material_json();
                return d.contains("params") && d["params"].contains("shine") && graph_.renaming.empty();
            },
            "the rename to reach the file");
        step(3, [this, gs, rel, read_text] {
            GraphModel& m = *graph_.model;
            const Json file = Json::parse(read_text(rel), nullptr, false);
            at_check(!file.is_discarded() && file["params"].contains("shine") && !file["params"].contains("glow"),
                     "Rename wrote the new name into the file");
            at_check(m.entry_readers(false, "shine").size() == 1 && !m.has_errors(),
                     "...and the node reads the new name");
            at_check(undo_depth() == gs->undoEntry + 4,
                     "...the create, the param node, its name and the rename are four undo steps in all");
        });
        // delete of a param a node reads is refused, naming and selecting the node
        click_widget("gr:param:delete:shine");
        wait_until([this] { return !graph_.entryMessage.empty(); }, "the refusal to delete a param nodes read");
        step(3, [this, gs, rel, read_text] {
            const Json file = Json::parse(read_text(rel), nullptr, false);
            at_check(!file.is_discarded() && file["params"].contains("shine"),
                     "Delete is refused while a node reads the param");
            at_check(!gs->reader.empty() && graph_.entryMessage.find(gs->reader) != std::string::npos &&
                         graph_.model->is_selected(gs->reader),
                     "...it names the node and selects it: " + graph_.entryMessage);
        });
        // back out: the three entries come off the stack, the file loses the param
        step(3, [this, gs, rel, read_text] {
            for (size_t left = undo_depth(); left > 0 && undo_depth() > gs->undoEntry; --left) undo();
            const Json file = Json::parse(read_text(rel), nullptr, false);
            at_check(!file.is_discarded() && !file["params"].contains("shine") && !file["params"].contains("glow"),
                     "Undo takes the param out of the file again");
            at_check(graph_.model->node_count() == 4, "...and the node with it");
        });

        // ---- a sprite graph: the kind next to New graph material makes one, 3D nodes are not offered, a noise node drives its alpha and
        // the preview draws it on the 2D quad (docs/EDITOR.md, "Graph panel")
        const std::string spriteRel = "assets/materials/sprite_graph.material.json";
        const std::string spriteSnippet = "shaders/sprite_graph.fragment.glsl";
        wait_until([this] { return !graph_.preview || !graph_.preview->busy(); },
                   "the mesh preview to finish compiling");
        step(2, [this] {
            graph_close_document();
            at_check(graph_.newKind == "mesh", "the kind box starts on Mesh");
        });
        wait_until([this] { return at_visible("gr:new") && at_visible("gr:newkind"); },
                   "the New graph material buttons");
        // the kind is chosen in the combo next to the button, as a user does
        click_widget("gr:newkind");
        wait_until([this] { return at_visible("gr:newkind:sprite") && at_visible("gr:newkind:post"); },
                   "the kinds of the New graph material combo (Mesh, Sprite and Post)");
        click_widget("gr:newkind:sprite");
        step(3, [this] {
            at_check(graph_.newKind == "sprite", "choosing Sprite in the combo sets the kind of the new material");
            at_check(at_visible("gr:new") && at_visible("gr:newkind"),
                     "the New graph material row (the combo too) stays on screen at this window's size");
        });
        click_widget("gr:new");
        wait_until(
            [this, spriteRel] {
                return graph_.model && graph_.model->is_open() && graph_.model->path() == spriteRel &&
                       at_visible("gr:canvas") && graph_.canvasW > 150 && graph_.canvasH > 100;
            },
            "the Graph panel to open the new sprite material");
        step(3, [this, gs, spriteRel, spriteSnippet, read_text] {
            GraphModel& m = *graph_.model;
            const Json file = Json::parse(read_text(spriteRel), nullptr, false);
            at_check(!file.is_discarded() && file.value("kind", std::string()) == "sprite" &&
                         file.value("shader", std::string()) == spriteSnippet && file.contains("graph"),
                     "New graph material with the kind Sprite wrote a sprite material with a graph");
            at_check(read_text(spriteSnippet).find("void fragment(in QuadInput i, inout QuadSurface s)") !=
                         std::string::npos,
                     "...and its snippet is the fragment() of the sprite template");
            at_check(m.report().kind == "sprite" && !m.has_errors() && m.node_count() == 1,
                     "...it checks, with the output node of a sprite");
            // the palette offers the nodes of a sprite and none of the 3D ones
            bool has2d = false, has3d = false;
            for (const GraphNodeType* t : m.palette("")) {
                has2d = has2d || t->type == "sprite.color";
                has3d = has3d || t->type == "fresnel" || t->type == "normal.world";
            }
            at_check(has2d && !has3d, "the palette lists sprite.color and not fresnel or normal.world");
            const GraphEditOutcome refused = m.add_node("fresnel", Vec2{0.0f, 0.0f});
            at_check(!refused.ok && refused.error.find("sprite") != std::string::npos && m.node_count() == 1,
                     "a 3D node cannot be added to a sprite graph: " + refused.error);
            const GraphEditOutcome added = m.add_node("noise.fbm", Vec2{0.0f, 0.0f});
            graph_edited(added);
            const GraphEditOutcome linked = added.ok ? m.connect(added.id + ".value", "out.alpha") : added;
            graph_edited(linked);
            at_check(added.ok && linked.ok && !m.has_errors() && m.link_count() == 1,
                     "a noise node is added and linked into the alpha of the output: " + linked.error);
            gs->compiles = graph_.preview ? graph_.preview->compiles() : 0;
        });
        wait_until(
            [this] {
                const PreviewState s = graph_.preview->state();
                return graph_.preview->shown_revision() == graph_.model->revision() || s == PreviewState::Error ||
                       s == PreviewState::NoRenderer;
            },
            "the preview to compile the sprite graph");
        step(3, [this, gs] {
            const GraphPreview& pv = *graph_.preview;
            if (pv.state() == PreviewState::NoRenderer) {
                atLog_.push_back("SKIP Sprite graph preview (this window has no GPU renderer)");
                return;
            }
            if (pv.state() == PreviewState::Error) {
                const std::string msg = pv.message();
                const bool noShdc =
                    msg.find("shdc") != std::string::npos || msg.find("shader compiler") != std::string::npos;
                const char* required = std::getenv("FA_REQUIRE_SHDC");
                if (noShdc && !(required && std::string(required) == "1")) {
                    atLog_.push_back("SKIP Sprite graph preview (no sokol-shdc? set SOKOL_SHDC): " + msg);
                    return;
                }
                at_check(false, "the preview compiled the sprite graph: " + msg);
                return;
            }
            at_check(pv.state() == PreviewState::Ready && !pv.image().empty() && pv.compiles() > gs->compiles,
                     "the preview compiled the sprite graph and drew a picture: " + pv.message());
            at_check(pv.drawing() == PreviewKind::Sprite, "...on the 2D quad, not on the sphere");
            int covered = 0;
            for (std::size_t i = 3; i < pv.image().rgba.size(); i += 4)
                if (pv.image().rgba[i] > 0) ++covered;
            at_check(covered > 0, "...the quad is in it (" + std::to_string(covered) + " pixels drawn)");
            at_check(at_visible("gr:preview"), "...and the panel shows it");
        });

        // ---- a post graph: the kind Post of the same combo makes one with post.scene linked to the output, the palette has the post nodes and
        // none of the 3D ones, a node is added, the snippet is the post() of the post template, and the preview says why it draws nothing
        const std::string postRel = "assets/materials/post_graph.material.json";
        const std::string postSnippet = "shaders/post_graph.post.glsl";
        wait_until([this] { return !graph_.preview || !graph_.preview->busy(); },
                   "the sprite preview to finish compiling");
        step(2, [this] { graph_close_document(); });
        wait_until([this] { return at_visible("gr:new") && at_visible("gr:newkind"); },
                   "the New graph material buttons");
        click_widget("gr:newkind");
        wait_until([this] { return at_visible("gr:newkind:post"); }, "the kinds of the New graph material combo");
        click_widget("gr:newkind:post");
        step(3, [this] {
            at_check(graph_.newKind == "post", "choosing Post in the combo sets the kind of the new material");
        });
        click_widget("gr:new");
        wait_until(
            [this, postRel] {
                return graph_.model && graph_.model->is_open() && graph_.model->path() == postRel &&
                       at_visible("gr:canvas") && graph_.canvasW > 150 && graph_.canvasH > 100;
            },
            "the Graph panel to open the new post material");
        step(3, [this, postRel, postSnippet, read_text] {
            GraphModel& m = *graph_.model;
            const Json file = Json::parse(read_text(postRel), nullptr, false);
            at_check(!file.is_discarded() && file.value("kind", std::string()) == "post" &&
                         file.value("shader", std::string()) == postSnippet && file.contains("graph"),
                     "New graph material with the kind Post wrote a post material with a graph");
            const std::string text = read_text(postSnippet);
            at_check(text.find("void post(in PostInput i, inout PostSurface s)") != std::string::npos &&
                         text.find("fa_scene_color(") != std::string::npos,
                     "...and its snippet is the post() of the post template, reading the picture");
            at_check(m.report().kind == "post" && !m.has_errors() && m.node_count() == 2 && m.link_count() == 1,
                     "...it checks: post.scene linked into the output of a post pass");
            bool hasPost = false, has3d = false;
            for (const GraphNodeType* t : m.palette("")) {
                hasPost = hasPost || t->type == "post.history";
                has3d = has3d || t->type == "fresnel" || t->type == "normal.world" || t->type == "sprite.color";
            }
            at_check(hasPost && !has3d, "the palette lists post.history and not fresnel, normal.world or sprite.color");
            const GraphEditOutcome refused = m.add_node("sprite.color", Vec2{0.0f, 0.0f});
            at_check(!refused.ok && refused.error.find("post") != std::string::npos && m.node_count() == 2,
                     "a sprite node cannot be added to a post graph: " + refused.error);
            const GraphEditOutcome added = m.add_node("noise.fbm", Vec2{0.0f, 0.0f});
            graph_edited(added);
            const GraphEditOutcome linked = added.ok ? m.connect(added.id + ".value", "out.rgb") : added;
            graph_edited(linked);
            at_check(added.ok && linked.ok && !m.has_errors() && m.node_count() == 3,
                     "a noise node is added and linked into the rgb of the output: " + linked.error);
        });
        wait_until([this] { return graph_.preview && graph_.preview->state() == PreviewState::Unsupported; },
                   "the preview to say it has no picture for a post material");
        step(3, [this] {
            at_check(graph_.preview->message().find("PostProcess.customPasses") != std::string::npos,
                     "the preview says why there is no picture and where to see the material: " +
                         graph_.preview->message());
        });
        click_widget("gr:save");  // Save generates the snippet again, now with the noise node in it
        step(4, [this, postRel, postSnippet, read_text] {
            const Json file = Json::parse(read_text(postRel), nullptr, false);
            at_check(!file.is_discarded() && file["graph"]["nodes"].size() == 3 && !graph_.model->dirty(),
                     "Save wrote the post graph with its three nodes");
            at_check(read_text(postSnippet).find("(noise.fbm)") != std::string::npos &&
                         graph_.model->snippet_state() == "in_sync",
                     "...and generated its post() with the noise node in it");
        });

        // the preview compiles on a worker thread: its files go only after it has finished
        wait_until([this] { return !graph_.preview || !graph_.preview->busy(); }, "the preview to finish compiling");
        step(2, [this, dir, spriteRel, spriteSnippet, postRel, postSnippet] {
            showGraph_ = false;
            graph_close_document();
            graph_.newKind = "mesh";
            std::error_code ec;
            stdfs::remove_all(stdfs::path(projectDir_) / dir, ec);
            stdfs::remove(stdfs::path(projectDir_) / spriteRel, ec);
            stdfs::remove(stdfs::path(projectDir_) / spriteSnippet, ec);
            stdfs::remove(stdfs::path(projectDir_) / postRel, ec);
            stdfs::remove(stdfs::path(projectDir_) / postSnippet, ec);
            std::error_code ec2;
            stdfs::remove_all(stdfs::path(projectDir_) / ".factoria/material-preview", ec2);
            project_files_changed();
        });
    }
}

}  // namespace fa::editor
