// Autotest section G3: the Graph panel. Split from the other autotest files: an Editor::at_section_G3(AtScript&) that adds its steps to the
// script, called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
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
                const Vec2 a = graph_node_screen(fromNode, fromPort, true), b = graph_node_screen(toNode, toPort, false);
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
            at_check(m.path() == rel && m.node_count() == 1 && m.link_count() == 0, "the material opens with its one output node");
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
        wait_until([this] { return at_visible("gr:add:noise.fbm") && graph_.filter == "noise"; }, "the palette to list noise.fbm");
        step(3, [this] {
            const std::vector<const GraphNodeType*> list = graph_.model->palette(graph_.filter);
            at_check(!list.empty() && !at_visible("gr:add:math.add"), "the search narrows the palette: noise nodes stay, math.add goes");
        });
        click_widget("gr:add:noise.fbm");
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 2 && m.node_index("noise_fbm") >= 0, "a click in the palette adds the node (noise_fbm)");
            at_check(undo_depth() == gs->undo + 1, "...as one undo step");
        });
        right_click_graph(0.0f, 200.0f);
        wait_until([this] { return at_visible("gr:add:param"); }, "the palette to list the param node");
        click_widget("gr:add:param");
        right_click_graph(220.0f, 60.0f);
        wait_until([this] { return at_visible("gr:add:dissolve"); }, "the palette to list the dissolve node");
        click_widget("gr:add:dissolve");
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 4 && m.node_index("param") >= 0 && m.node_index("dissolve") >= 0, "the param and dissolve nodes are added too");
            const Json node = m.graph()["nodes"][std::size_t(m.node_index("param"))];
            at_check(node.value("param", std::string()) == "dissolve", "...the param node names the material's one param");
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
                return graph_.preview->shown_revision() == graph_.model->revision() || s == PreviewState::Error || s == PreviewState::NoRenderer;
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
                const bool noShdc = msg.find("shdc") != std::string::npos || msg.find("shader compiler") != std::string::npos;
                const char* required = std::getenv("FA_REQUIRE_SHDC");
                if (noShdc && !(required && std::string(required) == "1")) {
                    gs->skip = true;
                    atLog_.push_back("SKIP Graph preview (no sokol-shdc? set SOKOL_SHDC): " + msg);
                    return;
                }
                at_check(false, "the preview compiled the dissolve graph: " + msg);
                return;
            }
            at_check(pv.state() == PreviewState::Ready && !pv.image().empty(), "the preview compiled the graph and drew a picture");
            int covered = 0;
            for (std::size_t i = 3; i < pv.image().rgba.size(); i += 4)
                if (pv.image().rgba[i] > 0) ++covered;
            at_check(covered > 2000, "...the sphere is in it (" + std::to_string(covered) + " pixels drawn)");
            at_check(at_visible("gr:preview"), "...and the panel shows it");
            gs->compiles = pv.compiles();
        });
        snap("editor_graph_panel.png");

        // ---- a graph with an error: the preview says why and keeps the last picture
        step(3, [this, gs] {
            GraphModel& m = *graph_.model;
            // a node whose type does not exist cannot be added by the panel; a link the checker refuses is refused by the model
            const GraphEditOutcome bad = m.connect("dissolve.emission", "noise_fbm.scale");
            at_check(!bad.ok && !bad.error.empty(), "a link of the wrong type is refused with the checker's sentence: " + bad.error);
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
            at_check(!text.empty() && text.find("dissolve") != std::string::npos, "...and the shader snippet next to it");
            at_check(!m.dirty() && m.snippet_state() == "in_sync", "...the panel says the snippet is in sync");
            gs->saved = text;
        });

        // ---- a snippet edited by hand is not overwritten without the question
        step(3, [this, gs, snippet, read_text] {
            std::ofstream(stdfs::path(projectDir_) / snippet, std::ios::binary | std::ios::app) << "\n// edited by hand\n";
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
            at_check(read_text(snippet).find("edited by hand") != std::string::npos && graph_.model->dirty(), "Cancel keeps the hand edit and the unsaved graph");
        });
        click_widget("gr:save");
        wait_until([this] { return at_visible("gr:force"); }, "the question before overwriting a hand-edited snippet");
        click_widget("gr:force");
        step(3, [this, snippet, read_text] {
            at_check(read_text(snippet).find("edited by hand") == std::string::npos && !graph_.model->dirty(),
                     "Overwrite writes the snippet from the graph again");
        });

        // ---- Undo and Redo through the editor's stack
        step(3, [this, gs] {
            while (undo_depth() > gs->undo) undo();
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 1 && m.link_count() == 0, "Undo walks every edit back to the one-node graph");
        });
        step(3, [this, gs] {
            for (int i = 0; i < 40; ++i) redo();
            GraphModel& m = *graph_.model;
            at_check(m.node_count() == 4 && m.link_count() == 4 && !m.has_errors(), "Redo brings the dissolve graph back");
            at_check(undo_depth() > gs->undo, "...on the editor's undo stack");
        });

        step(2, [this, dir] {
            showGraph_ = false;
            graph_close_document();
            std::error_code ec;
            stdfs::remove_all(stdfs::path(projectDir_) / dir, ec);
            std::error_code ec2;
            stdfs::remove_all(stdfs::path(projectDir_) / ".factoria/material-preview", ec2);
            project_files_changed();
        });
    }
}

}  // namespace fa::editor
