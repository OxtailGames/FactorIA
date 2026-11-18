// The Graph panel's live preview (graph_preview.h).
#include "graph_preview.h"

#include <algorithm>
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
constexpr const char* kStageMaterial = ".factoria/material-preview/stage.material.json";
constexpr const char* kStageSnippet = ".factoria/material-preview/stage.surface.glsl";
constexpr const char* kLiveSnippet = ".factoria/material-preview/preview.surface.glsl";
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

}  // namespace

struct GraphPreview::Job {
    std::atomic<bool> done{false};
    std::uint64_t revision = 0;
    std::string dialect;
    std::string snippet;
    std::string stageText;  // the material the compile reads
    std::string liveText;   // the material the renderer reads
    bool ok = false;
    std::string error;
};

GraphPreview::GraphPreview(std::string projectDir) : projectDir_(std::move(projectDir)) {}

GraphPreview::~GraphPreview() {
    if (worker_.joinable()) worker_.join();
}

void GraphPreview::set_document(const Json& material, std::uint64_t revision) {
    if (haveDoc_ && revision == revision_) return;
    doc_ = material;
    revision_ = revision;
    haveDoc_ = true;
    quiet_ = 0;
    if (state_ != PreviewState::NoRenderer) state_ = PreviewState::Waiting;
}

void GraphPreview::clear() {
    haveDoc_ = false;
    doc_ = Json();
    state_ = PreviewState::Empty;
    message_.clear();
    image_ = Image{};
    ++serial_;
    shownRevision_ = 0;
    requested_ = 0;
    drawn_ = false;
}

void GraphPreview::set_shape(PreviewShape shape) {
    if (shape == shape_) return;
    shape_ = shape;
    shapeChanged_ = true;
}

void GraphPreview::build_world() {
    world_ = std::make_unique<World>();
    meshEntity_ = world_->create("preview-mesh");
    world_->add<Transform>(meshEntity_);
    world_->add<MeshRenderer>(meshEntity_);
    const Entity light = world_->create("preview-light");
    Transform& lt = world_->add<Transform>(light);
    lt.rotation = Vec3{-35.0f, 30.0f, 0.0f};
    Light& l = world_->add<Light>(light);
    l.type = LightType::Directional;
    l.intensity = 1.6f;
}

void GraphPreview::tick(Renderer* renderer) {
    if (!haveDoc_) return;
    if (!renderer || !renderer->initialized() || renderer->shader_dialect().empty()) {
        state_ = PreviewState::NoRenderer;
        message_ = "The editor has no GPU renderer here, so the preview cannot draw.";
        return;
    }
    if (state_ == PreviewState::NoRenderer) state_ = PreviewState::Waiting;
    // a finished compile
    if (job_ && job_->done.load(std::memory_order_acquire)) {
        if (worker_.joinable()) worker_.join();
        finish(renderer);
    }
    if (job_) return;  // one compile at a time: the newest document waits for it
    const bool newDoc = requested_ != revision_;
    if (newDoc) {
        ++quiet_;
        if (quiet_ >= kPreviewDebounceFrames || immediate_) start(renderer);
        return;
    }
    if (shapeChanged_ && drawn_) {
        shapeChanged_ = false;
        draw(renderer);
        return;
    }
    if (animated_ && drawn_ && state_ == PreviewState::Ready && ++animFrame_ % kAnimateEvery == 0) draw(renderer);
}

void GraphPreview::start(Renderer* renderer) {
    requested_ = revision_;
    quiet_ = 0;
    const MaterialGraphReport report = check_material_document(doc_, projectDir_, "");
    if (!report.errors.empty()) {
        state_ = PreviewState::Error;
        message_ = clip(report.errors.front().pointer + ": " + report.errors.front().message +
                        (report.errors.front().hint.empty() ? std::string() : " " + report.errors.front().hint));
        return;
    }
    if (!report.hasGraph) {
        state_ = PreviewState::Error;
        message_ = "The material has no graph.";
        return;
    }
    if (report.kind != "mesh") {
        state_ = PreviewState::Error;
        message_ = "The preview draws mesh materials; this one is a \"" + report.kind + "\" material.";
        return;
    }
    auto job = std::make_shared<Job>();
    job->revision = revision_;
    job->dialect = renderer->shader_dialect();
    job->snippet = report.snippet;
    job->stageText = preview_material(doc_, kStageSnippet).dump(2) + "\n";
    job->liveText = preview_material(doc_, kLiveSnippet).dump(2) + "\n";
    job_ = job;
    state_ = PreviewState::Compiling;
    message_.clear();
    const std::string projectDir = projectDir_;
    auto run = [projectDir, job]() {
        // The material file and the snippet it names, then the compile of that material for this backend: the result goes to the
        // content-keyed cache (.factoria/shader-cache), so the renderer finds it when it loads the live copy.
        auto w1 = fs::write_text(abs_path(projectDir, kStageSnippet), job->snippet);
        auto w2 = fs::write_text(abs_path(projectDir, kStageMaterial), job->stageText);
        if (!w1.ok() || !w2.ok()) {
            const auto& e = w1.ok() ? w2.error() : w1.error();
            job->error = "Cannot write the preview files in " + std::string(kDir) + ": " + e.message + " " + e.hint;
        } else {
            ShaderCompileOptions opt;
            opt.dialects = {job->dialect};
            auto r = compile_material(projectDir, kStageMaterial, opt);
            if (!r.ok()) {
                job->error = r.error().message + (r.error().hint.empty() ? std::string() : " " + r.error().hint);
            } else if (!r->ok) {
                for (const ShaderIssue& issue : r->errors) job->error += issue.to_string() + "\n";
                if (job->error.empty()) job->error = "The shader did not compile.";
            } else {
                job->ok = true;
            }
        }
        job->done.store(true, std::memory_order_release);
    };
    if (immediate_) {
        run();
        finish(renderer);
    } else {
        worker_ = std::thread(run);
    }
}

void GraphPreview::finish(Renderer* renderer) {
    std::shared_ptr<Job> job = std::move(job_);
    job_.reset();
    ++compiles_;
    if (!job) return;
    if (job->revision != revision_) {  // edited while it compiled: the newer document is next
        state_ = PreviewState::Waiting;
        return;
    }
    if (!job->ok) {
        state_ = PreviewState::Error;
        message_ = clip(job->error);
        return;
    }
    auto a = fs::write_text(abs_path(projectDir_, kLiveSnippet), job->snippet);
    auto b = fs::write_text(abs_path(projectDir_, material_path()), job->liveText);
    if (!a.ok() || !b.ok()) {
        const auto& e = a.ok() ? b.error() : a.error();
        state_ = PreviewState::Error;
        message_ = "Cannot write the preview files in " + std::string(kDir) + ": " + e.message + " " + e.hint;
        return;
    }
    renderer->reload_asset(kLiveSnippet);
    renderer->reload_asset(material_path());
    shownRevision_ = job->revision;
    draw(renderer);
}

void GraphPreview::draw(Renderer* renderer) {
    if (!world_) build_world();
    Transform* t = world_->get<Transform>(meshEntity_);
    MeshRenderer* mr = world_->get<MeshRenderer>(meshEntity_);
    if (!t || !mr) return;
    mr->material = material_path();
    switch (shape_) {
        case PreviewShape::Sphere:
            mr->mesh = "sphere";
            t->rotation = Vec3{0, 0, 0};
            t->scale = Vec3{190, 190, 190};
            break;
        case PreviewShape::Cube:
            mr->mesh = "cube";
            t->rotation = Vec3{-28.0f, 38.0f, 0.0f};
            t->scale = Vec3{110, 110, 110};
            break;
        case PreviewShape::Quad:
            mr->mesh = "quad";
            t->rotation = Vec3{0, 0, 0};
            t->scale = Vec3{200, 200, 1};
            break;
    }
    Renderer::WorldCapture spec;
    spec.rect = Rect{-0.5f * kPreviewSide, -0.5f * kPreviewSide, float(kPreviewSide), float(kPreviewSide)};
    spec.scale = 1.0f;
    Image img;
    std::string err;
    if (!renderer->capture_world(*world_, spec, img, &err)) {
        state_ = PreviewState::Error;
        message_ = clip("The preview could not draw: " + err);
        return;
    }
    drawn_ = true;
    // a material the renderer could not build is drawn magenta: say why, from the renderer's own report
    const Json report = renderer->asset_report();
    if (report.contains("materials") && report["materials"].is_array())
        for (const Json& m : report["materials"])
            if (m.is_object() && m.value("material", std::string()) == material_path() && !m.value("ok", true)) {
                state_ = PreviewState::Error;
                message_ = clip("The renderer could not build the material: " + m.value("error", std::string("unknown error")));
                image_ = std::move(img);
                ++serial_;
                return;
            }
    image_ = std::move(img);
    ++serial_;
    state_ = PreviewState::Ready;
    message_.clear();
}

}  // namespace fa::editor
