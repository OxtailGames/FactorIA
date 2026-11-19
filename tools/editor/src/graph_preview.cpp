// The Graph panel's live preview (graph_preview.h).
#include "graph_preview.h"

#include <algorithm>
#include <cmath>
#include <exception>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/render/renderer.h"
#include "fa/scene/components.h"
#include "fa/tooling/material_graph.h"
#include "fa/tooling/shaders.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

constexpr const char* kDir = ".factoria/material-preview/";
constexpr const char* kChecker = ".factoria/material-preview/checker.png";
constexpr int kAnimateEvery = 6;  // frames between two pictures of an animated preview

std::string abs_path(const std::string& projectDir, const std::string& rel) {
    return (stdfs::path(projectDir) / rel).generic_string();
}

std::string clip(std::string s) {
    if (s.size() > std::size_t(kPreviewMaxMessage)) s = s.substr(0, kPreviewMaxMessage) + "...";
    return s;
}

Json preview_material(const Json& doc, const char* snippetPath) {
    Json m = doc;
    m.erase("graph");
    m.erase("graphHash");
    m["shader"] = snippetPath;
    return m;
}

std::string kind_of(const Json& doc) {
    if (doc.is_object()) {
        auto k = doc.find("kind");
        if (k != doc.end() && k->is_string()) return k->get<std::string>();
    }
    return "mesh";
}

// How many numbers a param of this type takes (material "params": float, vec2, vec3, vec4, color).
int components_of(const std::string& type) {
    if (type == "float") return 1;
    if (type == "vec2") return 2;
    if (type == "vec3") return 3;
    return 4;
}

// The 64x64 grey checker a sprite material shows when it has no texture of its own.
Image checker_image() {
    Image img;
    img.width = img.height = 64;
    img.rgba.resize(std::size_t(64 * 64 * 4));
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) {
            const std::uint8_t v = ((x / 8 + y / 8) % 2 == 0) ? 205 : 120;
            std::uint8_t* p = &img.rgba[std::size_t((y * 64 + x) * 4)];
            p[0] = p[1] = p[2] = v;
            p[3] = 255;
        }
    return img;
}

}  // namespace

PreviewPlan preview_plan(const std::string& kind) {
    PreviewPlan plan;
    if (kind == "mesh") {
        plan.kind = PreviewKind::Mesh;
    } else if (kind == "sprite") {
        plan.kind = PreviewKind::Sprite;
    } else if (kind == "sky") {
        plan.kind = PreviewKind::None;
        plan.reason = "A sky material paints the background behind a scene (SceneSettings.skyMaterial) and needs that "
                      "scene around it, "
                      "so this preview cannot draw it. Pick it in View > Scene settings and look at the Scene view.";
    } else if (kind == "post") {
        plan.kind = PreviewKind::None;
        plan.reason = "A post material is a full-screen pass over a camera's finished picture, so there is nothing for "
                      "this preview "
                      "to draw it on. Run the game or the Scene view to see it.";
    } else if (kind == "compute") {
        plan.kind = PreviewKind::None;
        plan.reason =
            "A compute material draws nothing: it runs a dispatch over storage buffers (compute.dispatch). There is no "
            "picture to preview.";
    }
    return plan;
}

std::vector<PreviewNodeError> map_compile_errors(const std::vector<ShaderIssue>& issues,
                                                 const std::vector<std::string>& lineNodes) {
    std::vector<PreviewNodeError> out;
    for (const ShaderIssue& issue : issues) {
        if (issue.line <= 0) continue;  // an error of the material file, not of a generated line
        const std::string node = graph_node_at_line(lineNodes, issue.line);
        if (node.empty()) continue;
        bool seen = false;
        for (const PreviewNodeError& e : out) seen = seen || (e.node == node && e.line == issue.line);
        if (seen) continue;
        PreviewNodeError e;
        e.node = node;
        e.line = issue.line;
        e.message = "line " + std::to_string(issue.line) + ": " + issue.message;
        if (!issue.hint.empty()) e.message += " (" + issue.hint + ")";
        out.push_back(std::move(e));
    }
    return out;
}

struct GraphPreview::Job {
    std::atomic<bool> done{false};
    std::uint64_t revision = 0;
    std::uint64_t generation = 0;
    std::string dialect;
    std::string snippet;
    std::string stageText;  // the material the compile reads
    std::string liveText;   // the material the renderer reads
    std::string stageMaterial, stageSnippet;
    std::vector<std::string> lineNodes;
    bool ok = false;
    std::string error;
    std::vector<ShaderIssue> issues;
};

GraphPreview::GraphPreview(std::string projectDir) : projectDir_(std::move(projectDir)) {
    cur_.stageMaterial = ".factoria/material-preview/stage.material.json";
    cur_.stageSnippet = ".factoria/material-preview/stage.surface.glsl";
    cur_.liveMaterial = ".factoria/material-preview/preview.material.json";
    cur_.liveSnippet = ".factoria/material-preview/preview.surface.glsl";
    saved_.stageMaterial = ".factoria/material-preview/saved-stage.material.json";
    saved_.stageSnippet = ".factoria/material-preview/saved-stage.surface.glsl";
    saved_.liveMaterial = ".factoria/material-preview/saved.material.json";
    saved_.liveSnippet = ".factoria/material-preview/saved.surface.glsl";
}

GraphPreview::~GraphPreview() {
    // A compile that is still running (sokol-shdc can take seconds) never blocks the UI thread: the worker only holds copies
    // (the project directory and the shared job), so it is let go and ends by itself.
    if (cur_.worker.joinable()) cur_.worker.detach();
    if (saved_.worker.joinable()) saved_.worker.detach();
}

Json GraphPreview::fitting_overrides(const Json& overrides, const Json& material) {
    Json out = Json::object();
    if (!overrides.is_object()) return out;
    const Json* params = nullptr;
    if (material.is_object()) {
        auto p = material.find("params");
        if (p != material.end() && p->is_object()) params = &*p;
    }
    if (!params) return out;
    for (auto it = overrides.begin(); it != overrides.end(); ++it) {
        auto decl = params->find(it.key());
        if (decl == params->end() || !decl->is_object()) continue;
        auto type = decl->find("type");
        if (type == decl->end() || !type->is_string()) continue;
        const int n = components_of(type->get<std::string>());
        const Json& v = it.value();
        bool fits = false;
        if (n == 1) {
            fits = v.is_number();
        } else if (v.is_array() && int(v.size()) == n) {
            fits = true;
            for (const Json& c : v) fits = fits && c.is_number();
        }
        if (fits) out[it.key()] = v;
    }
    return out;
}

void GraphPreview::drop_pictures() {
    for (Slot* s : {&cur_, &saved_}) {
        s->image = Image{};
        ++s->serial;
        s->shownRevision = 0;
        s->drawn = false;
        s->redraw = false;
        s->nodeErrors.clear();
    }
}

void GraphPreview::set_document(const Json& material, std::uint64_t revision, const std::string& path) {
    if (!path.empty() && path != path_) {  // another material: nothing of the last one carries over
        path_ = path;
        overrides_ = Json::object();
        drop_pictures();
        cur_.haveDoc = false;
        saved_.haveDoc = false;
        saved_.state = PreviewState::Empty;
        saved_.message.clear();
    }
    if (cur_.haveDoc && revision == cur_.revision) return;
    cur_.doc = material;
    cur_.revision = revision;
    cur_.haveDoc = true;
    cur_.pending = true;
    cur_.quiet = 0;
    cur_.nodeErrors.clear();
    overrides_ = fitting_overrides(overrides_, material);
    if (cur_.state != PreviewState::NoRenderer) cur_.state = PreviewState::Waiting;
}

void GraphPreview::clear() {
    for (Slot* s : {&cur_, &saved_}) {
        s->haveDoc = false;
        s->doc = Json();
        s->state = PreviewState::Empty;
        s->message.clear();
        s->image = Image{};
        ++s->serial;
        s->shownRevision = 0;
        s->pending = false;
        s->drawn = false;
        s->redraw = false;
        s->nodeErrors.clear();
    }
    ++generation_;  // a compile that is still running belongs to the document that was closed
    path_.clear();
    overrides_ = Json::object();
}

void GraphPreview::set_shape(PreviewShape newShape) {
    if (newShape == shape_) return;
    shape_ = newShape;
    cur_.redraw = saved_.redraw = true;
}

void GraphPreview::set_param(const std::string& name, const Json& value) {
    if (!overrides_.is_object()) overrides_ = Json::object();
    if (value.is_null()) {
        if (!overrides_.contains(name)) return;
        overrides_.erase(name);
    } else {
        if (overrides_.contains(name) && overrides_[name] == value) return;
        overrides_[name] = value;
    }
    cur_.redraw = saved_.redraw = true;
}

void GraphPreview::reset_params() {
    if (overrides_.is_object() && overrides_.empty()) return;
    overrides_ = Json::object();
    cur_.redraw = saved_.redraw = true;
}

void GraphPreview::set_compare(bool on) { compare_ = on; }

void GraphPreview::set_saved_document(const Json* material, std::uint64_t revision) {
    if (!material) {
        if (!saved_.haveDoc) return;
        saved_.haveDoc = false;
        saved_.doc = Json();
        saved_.state = PreviewState::Empty;
        saved_.message.clear();
        saved_.image = Image{};
        ++saved_.serial;
        saved_.pending = false;
        saved_.drawn = false;
        saved_.nodeErrors.clear();
        ++generation_;
        return;
    }
    if (saved_.haveDoc && revision == saved_.revision) return;
    saved_.doc = *material;
    saved_.revision = revision;
    saved_.haveDoc = true;
    saved_.pending = true;
    saved_.quiet = 0;
    saved_.nodeErrors.clear();
    if (saved_.state != PreviewState::NoRenderer) saved_.state = PreviewState::Waiting;
}

void GraphPreview::build_world(PreviewKind kind) {
    world_ = std::make_unique<World>();
    worldKind_ = kind;
    subject_ = world_->create("preview-subject");
    world_->add<Transform>(subject_);
    if (kind == PreviewKind::Sprite)
        world_->add<Sprite>(subject_);
    else
        world_->add<MeshRenderer>(subject_);
    const Entity light = world_->create("preview-light");
    Transform& lt = world_->add<Transform>(light);
    lt.rotation = Vec3{-35.0f, 30.0f, 0.0f};
    Light& l = world_->add<Light>(light);
    l.type = LightType::Directional;
    l.intensity = 1.6f;
}

void GraphPreview::tick(Renderer* renderer) {
    if (!cur_.haveDoc) return;
    if (!renderer || !renderer->initialized() || renderer->shader_dialect().empty()) {
        for (Slot* s : {&cur_, &saved_}) {
            if (!s->haveDoc) continue;
            s->state = PreviewState::NoRenderer;
            s->message = "The editor has no GPU renderer here, so the preview cannot draw.";
        }
        return;
    }
    if (animated_) ++animFrame_;
    tick_slot(cur_, renderer);
    if (compare_ && saved_.haveDoc) tick_slot(saved_, renderer);
}

void GraphPreview::tick_slot(Slot& s, Renderer* renderer) {
    if (s.state == PreviewState::NoRenderer) s.state = PreviewState::Waiting;
    // a finished compile
    if (s.job && s.job->done.load(std::memory_order_acquire)) {
        if (s.worker.joinable()) s.worker.join();
        finish(s, renderer);
    }
    if (s.job) return;  // one compile at a time: the newest document waits for it
    if (s.pending) {
        ++s.quiet;
        if (s.quiet >= kPreviewDebounceFrames || immediate_) start(s, renderer);
        return;
    }
    if (s.redraw) {
        s.redraw = false;
        // The last good picture again with the new shape or values: the state (an error that is still true) is not touched.
        if (s.drawn) draw(s, renderer, false);
        return;
    }
    if (animated_ && s.drawn && s.state == PreviewState::Ready && animFrame_ % kAnimateEvery == 0)
        draw(s, renderer, true);
}

void GraphPreview::note_unsupported(Slot& s, const std::string& why) {
    s.state = PreviewState::Unsupported;
    s.message = why;
    s.image = Image{};
    ++s.serial;
    s.drawn = false;
    s.shownRevision = 0;
}

void GraphPreview::start(Slot& s, Renderer* renderer) {
    s.pending = false;
    s.quiet = 0;
    s.nodeErrors.clear();
    const PreviewPlan plan = preview_plan(kind_of(s.doc));
    if (plan.kind == PreviewKind::None) {
        note_unsupported(s, plan.reason);
        return;
    }
    const MaterialGraphReport report = check_material_document(s.doc, projectDir_, "");
    if (!report.errors.empty()) {
        s.state = PreviewState::Error;
        s.message = clip(report.errors.front().pointer + ": " + report.errors.front().message +
                         (report.errors.front().hint.empty() ? std::string() : " " + report.errors.front().hint));
        return;
    }
    if (!report.hasGraph) {
        s.state = PreviewState::Error;
        s.message = "The material has no graph.";
        return;
    }
    if (plan.kind == PreviewKind::Unknown) {
        s.state = PreviewState::Error;
        s.message = "The preview draws mesh and sprite materials; this one is a \"" + report.kind + "\" material.";
        return;
    }
    s.drawKind = plan.kind;
    s.spriteTexture.clear();
    if (plan.kind == PreviewKind::Sprite) {
        // the quad shows the first texture the material declares a file for (they are alphabetical), else the grey checker
        for (const MaterialTexture& t : report.material.textures)
            if (!t.defaultPath.empty()) {
                s.spriteTexture = t.defaultPath;
                break;
            }
        if (s.spriteTexture.empty()) {
            const std::string checker = abs_path(projectDir_, kChecker);
            std::error_code ec;
            if (!checkerWritten_ || !stdfs::exists(stdfs::path(checker), ec)) {
                auto saved = save_png(checker_image(), checker);
                if (!saved.ok()) {
                    s.state = PreviewState::Error;
                    s.message = "Cannot write the preview's checker texture in " + std::string(kDir) + ": " +
                                saved.error().message + " " + saved.error().hint;
                    return;
                }
                checkerWritten_ = true;
            }
        }
    }
    auto job = std::make_shared<Job>();
    job->revision = s.revision;
    job->generation = generation_;
    job->dialect = renderer->shader_dialect();
    job->snippet = report.snippet;
    job->lineNodes = report.lineNodes;
    job->stageMaterial = s.stageMaterial;
    job->stageSnippet = s.stageSnippet;
    job->stageText = preview_material(s.doc, s.stageSnippet).dump(2) + "\n";
    job->liveText = preview_material(s.doc, s.liveSnippet).dump(2) + "\n";
    s.job = job;
    s.state = PreviewState::Compiling;
    s.message.clear();
    const std::string projectDir = projectDir_;
    auto run = [projectDir, job]() {
        // The material file and the snippet it names, then the compile of that material for this backend: the result goes to the
        // content-keyed cache (.factoria/shader-cache), so the renderer finds it when it loads the live copy.
        try {
            auto w1 = fs::write_text(abs_path(projectDir, job->stageSnippet), job->snippet);
            auto w2 = fs::write_text(abs_path(projectDir, job->stageMaterial), job->stageText);
            if (!w1.ok() || !w2.ok()) {
                const auto& e = w1.ok() ? w2.error() : w1.error();
                job->error = "Cannot write the preview files in " + std::string(kDir) + ": " + e.message + " " + e.hint;
            } else {
                ShaderCompileOptions opt;
                opt.dialects = {job->dialect};
                auto r = compile_material(projectDir, job->stageMaterial, opt);
                if (!r.ok()) {
                    job->error = r.error().message + (r.error().hint.empty() ? std::string() : " " + r.error().hint);
                } else if (!r->ok) {
                    job->issues = r->errors;
                    for (const ShaderIssue& issue : r->errors) job->error += issue.to_string() + "\n";
                    if (job->error.empty()) job->error = "The shader did not compile.";
                } else {
                    // compile_material keeps a twin it could not write to .factoria/shader-cache in memory only. The renderer reads the
                    // cache, so without the file it would run sokol-shdc itself on the editor's thread: report it here instead.
                    std::error_code ec;
                    const std::string cache = shader_cache_path(projectDir, r->generated, job->snippet, job->dialect);
                    if (stdfs::exists(stdfs::path(cache), ec)) {
                        job->ok = true;
                    } else {
                        job->error = "The shader compiled, but its result could not be saved in .factoria/shader-cache "
                                     "(a full disk, a "
                                     "read-only folder or a file open elsewhere), and the preview never compiles on "
                                     "the editor's thread. "
                                     "Free the space or the folder, then edit the graph again.";
                    }
                }
            }
        } catch (const std::exception& e) {  // a worker thread never lets an exception reach std::terminate
            job->ok = false;
            job->error = std::string("The preview compile failed: ") + e.what();
        } catch (...) {
            job->ok = false;
            job->error = "The preview compile failed with an unknown error.";
        }
        job->done.store(true, std::memory_order_release);
    };
    if (immediate_) {
        run();
        finish(s, renderer);
    } else {
        s.worker = std::thread(run);
    }
}

void GraphPreview::finish(Slot& s, Renderer* renderer) {
    std::shared_ptr<Job> job = std::move(s.job);
    s.job.reset();
    if (&s == &cur_) ++compiles_;
    if (!job) return;
    if (job->revision != s.revision ||
        job->generation != generation_) {  // edited while it compiled: the newer document is next
        if (s.haveDoc) s.state = PreviewState::Waiting;
        return;
    }
    if (!job->ok) {
        s.state = PreviewState::Error;
        s.message = clip(job->error);
        s.nodeErrors = map_compile_errors(job->issues, job->lineNodes);
        return;
    }
    auto a = fs::write_text(abs_path(projectDir_, s.liveSnippet), job->snippet);
    auto b = fs::write_text(abs_path(projectDir_, s.liveMaterial), job->liveText);
    if (!a.ok() || !b.ok()) {
        const auto& e = a.ok() ? b.error() : a.error();
        s.state = PreviewState::Error;
        s.message = "Cannot write the preview files in " + std::string(kDir) + ": " + e.message + " " + e.hint;
        return;
    }
    renderer->reload_asset(s.liveSnippet);
    renderer->reload_asset(s.liveMaterial);
    s.shownRevision = job->revision;
    s.nodeErrors.clear();
    draw(s, renderer, true);
}

void GraphPreview::draw(Slot& s, Renderer* renderer, bool markReady) {
    if (!world_ || worldKind_ != s.drawKind) build_world(s.drawKind);
    Transform* t = world_->get<Transform>(subject_);
    if (!t) return;
    // Animate: the shape turns (a quad sways so it never goes edge-on), so the lighting on it changes from picture to picture
    const float spin = animated_ ? std::fmod(float(animFrame_) * 1.5f, 360.0f) : 0.0f;
    // the saved version of the graph may not have every param the current one has
    const Json params = &s == &saved_ ? fitting_overrides(overrides_, s.doc) : overrides_;
    if (s.drawKind == PreviewKind::Sprite) {
        Sprite* sp = world_->get<Sprite>(subject_);
        if (!sp) return;
        sp->material = s.liveMaterial;
        sp->materialParams = params;
        sp->texture = s.spriteTexture.empty() ? std::string(kChecker) : s.spriteTexture;
        sp->size = Vec2{200, 200};
        sp->pixelArt = s.spriteTexture.empty();
        t->rotation = Vec3{0, 0, 0};
        t->scale = Vec3{1, 1, 1};
    } else {
        MeshRenderer* mr = world_->get<MeshRenderer>(subject_);
        if (!mr) return;
        mr->material = s.liveMaterial;
        mr->materialParams = params;
        switch (shape_) {
            case PreviewShape::Sphere:
                mr->mesh = "sphere";
                t->rotation = Vec3{0, spin, 0};
                t->scale = Vec3{190, 190, 190};
                break;
            case PreviewShape::Cube:
                mr->mesh = "cube";
                t->rotation = Vec3{-28.0f, 38.0f + spin, 0.0f};
                t->scale = Vec3{110, 110, 110};
                break;
            case PreviewShape::Quad:
                mr->mesh = "quad";
                t->rotation = Vec3{0, 40.0f * std::sin(spin * 0.0174533f), 0};
                t->scale = Vec3{200, 200, 1};
                break;
        }
    }
    Renderer::WorldCapture spec;
    spec.rect = Rect{-0.5f * kPreviewSide, -0.5f * kPreviewSide, float(kPreviewSide), float(kPreviewSide)};
    spec.scale = 1.0f;
    Image img;
    std::string err;
    if (!renderer->capture_world(*world_, spec, img, &err)) {
        s.state = PreviewState::Error;
        s.message = clip("The preview could not draw: " + err);
        return;
    }
    s.drawn = true;
    // a material the renderer could not build is drawn magenta: say why, from the renderer's own report
    const Json report = renderer->asset_report();
    if (report.contains("materials") && report["materials"].is_array())
        for (const Json& m : report["materials"])
            if (m.is_object() && m.value("material", std::string()) == s.liveMaterial && !m.value("ok", true)) {
                s.state = PreviewState::Error;
                s.message = clip("The renderer could not build the material: " +
                                 m.value("error", std::string("unknown error")));
                s.image = std::move(img);
                ++s.serial;
                return;
            }
    s.image = std::move(img);
    ++s.serial;
    if (markReady) {
        s.state = PreviewState::Ready;
        s.message.clear();
    }
}

}  // namespace fa::editor
