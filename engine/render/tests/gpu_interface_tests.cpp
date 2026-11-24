// The GPU interface (src/gpu/): the types against sokol's, RecordingDevice's checks and recorded stream (no GPU), the
// factory, and a SokolDevice round trip on the test GPU (skipped without one).
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <climits>
#include <initializer_list>
#include <string>
#include <thread>
#include <vector>

#include "gpu/device.h"
#include "gpu/recording_device.h"
#include "fa/platform/app.h"
#include "gpu/sokol_context.h"
#include "gpu/sokol_device.h"
#include "gpu/sokol_shaders.h"
#include "fullscreen_gpu.h"
#include "gpu_types.h"
#include "render_internal.h"
#include "render_features.h"
#include "shaders/blit.glsl.h"
#include "test_util.h"
#include "ui_painter_internal.h"

using namespace fa::gpu;

namespace {

bool contains(const std::string& s, const std::string& part) { return s.find(part) != std::string::npos; }

// Whether one of `errors` contains every part.
bool has_error(const std::vector<std::string>& errors, std::initializer_list<const char*> parts) {
    for (const std::string& e : errors) {
        bool all = true;
        for (const char* p : parts) all = all && contains(e, p);
        if (all) return true;
    }
    return false;
}

std::string joined(const std::vector<std::string>& errors) {
    std::string s;
    for (const std::string& e : errors) s += e + "\n";
    return s;
}

// A render shader like the generated headers describe: vertex attribute 0, a 32-byte std140 block 0 (vertex), a
// filterable 2D texture in view slot 0 sampled with the filtering sampler 0 (fragment).
ShaderDesc textured_shader(const char* label = "textured") {
    ShaderDesc d;
    d.vertexFunc.source = "vs";
    d.fragmentFunc.source = "fs";
    d.attrs[0].baseType = ShaderAttrBaseType::Float;
    d.uniformBlocks[0].stage = ShaderStage::Vertex;
    d.uniformBlocks[0].size = 32;
    d.uniformBlocks[0].layout = UniformLayout::Std140;
    d.views[0].texture.stage = ShaderStage::Fragment;
    d.views[0].texture.imageType = ImageType::Tex2d;
    d.views[0].texture.sampleType = ImageSampleType::Float;
    d.samplers[0].stage = ShaderStage::Fragment;
    d.samplers[0].samplerType = SamplerType::Filtering;
    d.textureSamplerPairs[0].stage = ShaderStage::Fragment;
    d.textureSamplerPairs[0].viewSlot = 0;
    d.textureSamplerPairs[0].samplerSlot = 0;
    d.label = label;
    return d;
}

// Everything a textured draw into a 64x64 RGBA8 + depth target needs, made on a RecordingDevice.
struct Scene {
    RecordingDevice& dev;
    Buffer vertices, transientVerts;
    Image target, depthImage, texture;
    View color, depth, textureView;
    Sampler sampler;
    Shader shader;
    Pipeline pipeline;

    explicit Scene(RecordingDevice& d) : dev(d) {
        BufferDesc vb;
        vb.size = 64;
        vb.usage.vertexBuffer = true;
        vb.label = "vertices";
        vertices = dev.make_buffer(vb);
        ImageDesc ti;
        ti.width = ti.height = 64;
        ti.usage.colorAttachment = true;
        ti.pixelFormat = PixelFormat::Rgba8;
        ti.label = "target";
        target = dev.make_image(ti);
        ImageDesc di;
        di.width = di.height = 64;
        di.usage.depthStencilAttachment = true;
        di.pixelFormat = PixelFormat::DepthStencil;
        di.label = "depth";
        depthImage = dev.make_image(di);
        ImageDesc tex;
        tex.width = tex.height = 8;
        tex.pixelFormat = PixelFormat::Rgba8;
        tex.label = "albedo";
        texture = dev.make_image(tex);
        ViewDesc cv;
        cv.colorAttachment.image = target;
        cv.label = "target color";
        color = dev.make_view(cv);
        ViewDesc dv;
        dv.depthStencilAttachment.image = depthImage;
        dv.label = "target depth";
        depth = dev.make_view(dv);
        ViewDesc tv;
        tv.texture.image = texture;
        tv.label = "albedo tex";
        textureView = dev.make_view(tv);
        SamplerDesc sd;
        sd.minFilter = sd.magFilter = Filter::Linear;
        sd.label = "linear";
        sampler = dev.make_sampler(sd);
        shader = dev.make_shader(textured_shader());
        PipelineDesc pd;
        pd.shader = shader;
        pd.layout.attrs[0].format = VertexFormat::Float2;
        pd.colors[0].pixelFormat = PixelFormat::Rgba8;
        pd.depth.pixelFormat = PixelFormat::DepthStencil;
        pd.sampleCount = 1;
        pd.label = "textured";
        pipeline = dev.make_pipeline(pd);
    }

    PassDesc pass(const char* label = "main") const {
        PassDesc p;
        p.label = label;
        p.color = color;
        p.depth = depth;
        p.format.color = PixelFormat::Rgba8;
        p.format.depth = PixelFormat::DepthStencil;
        p.format.samples = 1;
        p.colorLoad = LoadAction::Clear;
        return p;
    }

    Bindings bindings() const {
        Bindings b;
        b.vertexBuffers[0] = vertices;
        b.views[0] = textureView;
        b.samplers[0] = sampler;
        return b;
    }
};

const float kUniforms[8] = {};

// begin_pass + set_pipeline + set_bindings + set_uniforms: ready to draw.
void ready(CommandList& cl, const Scene& s) {
    cl.begin_pass(s.pass());
    cl.set_pipeline(s.pipeline);
    cl.set_bindings(s.bindings());
    cl.set_uniforms(0, Range{kUniforms, sizeof(kUniforms)});
}

}  // namespace

TEST_CASE("gpu interface: handles, enums and descs convert to sokol unchanged") {
    // The same id names the same resource (sokol_device.cpp static_asserts every enum value).
    CHECK(to_sg(Image{0x10005u}).id == 0x10005u);
    CHECK(from_sg(sg_pipeline{42}).id == 42u);
    CHECK(to_sg(PixelFormat::Rgba16F) == SG_PIXELFORMAT_RGBA16F);
    CHECK(to_sg(PixelFormat::DepthStencil) == SG_PIXELFORMAT_DEPTH_STENCIL);
    CHECK(from_sg(SG_PIXELFORMAT_BC7_SRGBA) == PixelFormat::Bc7Srgba);
    CHECK(to_sg(LoadAction::Clear) == SG_LOADACTION_CLEAR);
    CHECK(std::string(pixel_format_name(PixelFormat::Rgba16F)) == "RGBA16F");
    CHECK(std::string(pixel_format_name(PixelFormat::Count)) == "?");
    CHECK(pixel_format_bytes(PixelFormat::Rgba16F) == 8);
    CHECK(pixel_format_depth(PixelFormat::Depth));
    CHECK(pixel_format_compressed(PixelFormat::Astc4x4Rgba));
    CHECK(backend_from_sg(SG_BACKEND_D3D11) == Backend::D3d11);
    CHECK(backend_from_sg(SG_BACKEND_METAL_IOS) == Backend::Metal);
    CHECK(metal_target_from_sg(SG_BACKEND_METAL_SIMULATOR) == MetalTarget::Simulator);
    CHECK(backend_from_sg(SG_BACKEND_DUMMY) == Backend::Recording);

    BufferDesc bd;
    bd.size = 256;
    bd.usage.indexBuffer = true;
    bd.usage.writeTransient = true;
    bd.label = "indices";
    const sg_buffer_desc sb = to_sg(bd);
    CHECK(sb.size == 256);
    CHECK(sb.usage.index_buffer);
    CHECK(sb.usage.write_transient);
    CHECK(!sb.usage.vertex_buffer);
    CHECK(std::string(sb.label) == "indices");

    // A pipeline desc the renderer builds survives the round trip through the interface's desc.
    sg_pipeline_desc pd{};
    pd.shader = sg_shader{7};
    pd.layout.buffers[0].stride = 20;
    pd.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT3;
    pd.layout.attrs[1].format = SG_VERTEXFORMAT_UBYTE4N;
    pd.layout.attrs[1].offset = 12;
    pd.depth.pixel_format = SG_PIXELFORMAT_DEPTH;
    pd.depth.compare = SG_COMPAREFUNC_LESS_EQUAL;
    pd.depth.write_enabled = true;
    pd.color_count = 2;
    pd.colors[0].pixel_format = SG_PIXELFORMAT_RGBA16F;
    pd.colors[0].blend.enabled = true;
    pd.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
    pd.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    pd.colors[1].pixel_format = SG_PIXELFORMAT_RG16F;
    pd.colors[1].write_mask = SG_COLORMASK_RG;
    pd.index_type = SG_INDEXTYPE_UINT32;
    pd.cull_mode = SG_CULLMODE_BACK;
    pd.sample_count = 4;
    pd.label = "lit";
    const PipelineDesc gp = from_sg(pd);
    CHECK(gp.shader.id == 7u);
    CHECK(gp.colorCount == 2);
    CHECK(gp.colors[0].blend.srcFactorRgb == BlendFactor::SrcAlpha);
    const sg_pipeline_desc back = to_sg(gp);
    CHECK(back.shader.id == 7u);
    CHECK(back.layout.buffers[0].stride == 20);
    CHECK(back.layout.attrs[1].format == SG_VERTEXFORMAT_UBYTE4N);
    CHECK(back.layout.attrs[1].offset == 12);
    CHECK(back.depth.pixel_format == SG_PIXELFORMAT_DEPTH);
    CHECK(back.depth.compare == SG_COMPAREFUNC_LESS_EQUAL);
    CHECK(back.depth.write_enabled);
    CHECK(back.color_count == 2);
    CHECK(back.colors[0].blend.enabled);
    CHECK(back.colors[0].blend.dst_factor_rgb == SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA);
    CHECK(back.colors[1].write_mask == SG_COLORMASK_RG);
    CHECK(back.index_type == SG_INDEXTYPE_UINT32);
    CHECK(back.cull_mode == SG_CULLMODE_BACK);
    CHECK(back.sample_count == 4);
    CHECK(std::string(back.label) == "lit");

    // The generated shader headers' desc reaches the interface with its reflection.
    // (The header holds the backends this build compiles shaders for: take the first one it has.)
    const sg_shader_desc* blit = nullptr;
    for (sg_backend b : {SG_BACKEND_GLCORE, SG_BACKEND_GLES3, SG_BACKEND_D3D11, SG_BACKEND_METAL_MACOS})
        if (!blit) blit = blit_blit_shader_desc(b);
    REQUIRE(blit != nullptr);
    const ShaderDesc sd = from_sg(*blit);
    CHECK(sd.vertexFunc.source == blit->vertex_func.source);
    CHECK(sd.uniformBlocks[UB_blit_blit_vs_params].size == blit->uniform_blocks[UB_blit_blit_vs_params].size);
    CHECK(sd.views[VIEW_blit_tex].type() == ViewType::Texture);
    CHECK(sd.samplers[SMP_blit_smp].stage != ShaderStage::None);
    const sg_shader_desc sback = to_sg(sd);
    CHECK(sback.vertex_func.source == blit->vertex_func.source);
    CHECK(sback.attrs[ATTR_blit_blit_pos].base_type == blit->attrs[ATTR_blit_blit_pos].base_type);
    CHECK(sback.texture_sampler_pairs[0].view_slot == blit->texture_sampler_pairs[0].view_slot);
}

TEST_CASE("gpu interface: to_sg(PassDesc) maps both colour attachments, the actions and a swapchain") {
    PassDesc off;
    off.label = "subsurface";
    off.color = View{3};
    off.color1 = View{4};
    off.resolve = View{5};
    off.depth = View{6};
    off.format.color = PixelFormat::Rgba16F;
    off.format.color1 = PixelFormat::Rg16F;
    off.format.depth = PixelFormat::DepthStencil;
    off.format.samples = 4;
    off.colorLoad = LoadAction::Clear;
    off.colorStore = StoreAction::DontCare;
    off.clearColor = Color{0.25f, 0.5f, 0.75f, 1.0f};
    off.clearColor1 = Color{-1.0f, 2.0f, 0.0f, 0.0f};
    off.depthLoad = LoadAction::Clear;
    off.clearDepth = 0.0f;
    off.stencilLoad = LoadAction::Clear;
    off.depthStore = StoreAction::Store;
    off.stencilStore = StoreAction::DontCare;
    const sg_pass p = to_sg(off);
    for (int i = 0; i < 2; ++i) {
        CHECK(p.action.colors[i].load_action == SG_LOADACTION_CLEAR);
        CHECK(p.action.colors[i].store_action == SG_STOREACTION_DONTCARE);
    }
    CHECK(p.action.colors[0].clear_value.g == doctest::Approx(0.5f));
    CHECK(p.action.colors[1].clear_value.r == doctest::Approx(-1.0f));
    CHECK(p.action.colors[1].clear_value.g == doctest::Approx(2.0f));
    CHECK(p.attachments.colors[0].id == 3);
    CHECK(p.attachments.colors[1].id == 4);
    CHECK(p.attachments.resolves[0].id == 5);
    CHECK(p.attachments.depth_stencil.id == 6);
    CHECK(p.action.depth.load_action == SG_LOADACTION_CLEAR);
    CHECK(p.action.depth.clear_value == 0.0f);
    CHECK(p.action.depth.store_action == SG_STOREACTION_STORE);
    CHECK(p.action.stencil.load_action == SG_LOADACTION_CLEAR);
    CHECK(p.action.stencil.store_action == SG_STOREACTION_DONTCARE);
    CHECK(std::string(p.label) == "subsurface");

    sg_swapchain sc{};
    sc.width = 1280;
    sc.height = 720;
    sc.sample_count = 1;
    sc.color_format = SG_PIXELFORMAT_BGRA8;
    sc.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    sg_environment_defaults defaults{};
    defaults.color_format = SG_PIXELFORMAT_BGRA8;
    defaults.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    defaults.sample_count = 1;
    const Swapchain converted = from_sg(sc);
    PassDesc win = PassDesc::for_swapchain(converted, from_sg(defaults));
    win.label = "present";
    win.colorLoad = LoadAction::Clear;
    REQUIRE(win.swapchain == &converted);
    CHECK(converted.width == 1280);
    const sg_pass q = to_sg(win);
    CHECK(q.swapchain.width == 1280);
    CHECK(q.swapchain.height == 720);
    CHECK(q.swapchain.color_format == SG_PIXELFORMAT_BGRA8);
    CHECK(q.attachments.colors[0].id == 0);
    CHECK(q.action.colors[0].load_action == SG_LOADACTION_CLEAR);
    CHECK(win.format == TargetFormat{PixelFormat::Bgra8, PixelFormat::DepthStencil, 1});
}

TEST_CASE("Target: made on a RecordingDevice, its handles are the device's and a pass into it records cleanly") {
    RecordingDevice dev;
    fa::render::TargetDesc d;
    d.label = "unit";
    d.width = 32;
    d.height = 16;
    d.colorFormat = PixelFormat::Rgba8;
    d.depthFormat = PixelFormat::DepthStencil;
    d.samples = 4;
    d.resolveAsColor = true;
    fa::render::Target t = fa::render::make_target(dev, d);
    INFO(joined(dev.errors()));
    REQUIRE(t.valid(dev));
    CHECK(t.format == TargetFormat{PixelFormat::Rgba8, PixelFormat::DepthStencil, 4});
    for (const Image i : {t.color, t.resolve, t.depth}) CHECK(dev.state(i) == ResourceState::Valid);
    for (const View v : {t.colorAtt, t.resolveAtt, t.resolveColorAtt, t.depthAtt, t.texView})
        CHECK(dev.state(v) == ResourceState::Valid);
    CHECK(t.texture_image().id == t.resolve.id);  // a multisampled target is sampled through its resolve image

    PassDesc p = fa::render::pass_into(t, "unit-pass");
    CHECK(p.color.id == t.colorAtt.id);
    CHECK(p.resolve.id == t.resolveAtt.id);
    CHECK(p.depth.id == t.depthAtt.id);
    p.colorLoad = LoadAction::Clear;
    CommandList& cl = dev.begin_commands("main");
    cl.begin_pass(p);
    cl.end_pass();
    dev.submit(cl);
    CHECK(dev.errors().empty());
    CHECK(dev.stream_text() == "frame 0 [main] begin_pass 'unit-pass' color=RGBA8 depth=DEPTH_STENCIL samples=4\n"
                               "frame 0 [main] end_pass\n");
    const auto cmds = dev.commands();
    REQUIRE(cmds.size() == 2);
    CHECK(cmds[0].kind == CommandKind::BeginPass);

    fa::render::destroy_target(dev, t);
    CHECK(t.color.id == 0);
    CHECK(!t.valid(dev));
    CHECK(dev.take_errors().empty());
    // A pass into the freed views is reported by the device that made them (the handles were its own).
    CommandList& stale = dev.begin_commands("stale");
    stale.begin_pass(p);
    stale.end_pass();
    dev.submit(stale);
    CHECK(has_error(dev.errors(), {"PassDesc::color"}));
}

TEST_CASE("RecordingDevice: handles carry a generation, and a stale handle is named in the error") {
    RecordingDevice dev;
    BufferDesc d;
    d.size = 16;
    d.label = "a";
    const Buffer a = dev.make_buffer(d);
    REQUIRE(a.valid());
    CHECK(dev.state(a) == ResourceState::Valid);
    dev.destroy_buffer(a);
    CHECK(dev.state(a) == ResourceState::Invalid);
    d.label = "b";
    const Buffer b = dev.make_buffer(d);
    CHECK((b.id & 0xFFFFu) == (a.id & 0xFFFFu));  // the slot is reused...
    CHECK(b.id != a.id);                          // ...with a new generation
    CHECK(dev.state(a) == ResourceState::Invalid);
    CHECK(dev.state(b) == ResourceState::Valid);
    CHECK(dev.errors().empty());

    dev.destroy_buffer(b);
    dev.destroy_buffer(b);
    const auto errors = dev.take_errors();
    REQUIRE(errors.size() == 1);
    CHECK(has_error(errors, {"destroy_buffer", "destroyed buffer 'b'", "double destroy", "Fix:"}));
    dev.destroy_buffer(Buffer{});  // the invalid handle: nothing to do, no error
    CHECK(dev.errors().empty());

    const TotalStats t = dev.total_stats();
    CHECK(t.buffers.alive == 0);
    CHECK(t.buffers.allocated == 2);
    CHECK(t.buffers.deallocated == 2);
}

TEST_CASE("RecordingDevice: a full pool gives the invalid handle, a bad desc a Failed one") {
    DeviceInit init;
    init.samplerPoolSize = 2;
    RecordingDevice dev(init);
    SamplerDesc sd;
    CHECK(dev.make_sampler(sd).valid());
    CHECK(dev.make_sampler(sd).valid());
    const Sampler third = dev.make_sampler(sd);
    CHECK(!third.valid());
    CHECK(has_error(dev.take_errors(), {"make_sampler", "pool is full (2)", "samplerPoolSize"}));

    BufferDesc empty;
    empty.label = "empty";
    const Buffer b = dev.make_buffer(empty);
    CHECK(b.valid());
    CHECK(dev.state(b) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"make_buffer 'empty'", "size is 0"}));

    ImageDesc msaa;
    msaa.width = msaa.height = 16;
    msaa.sampleCount = 4;
    msaa.label = "msaa";
    CHECK(dev.state(dev.make_image(msaa)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"make_image 'msaa'", "sampleCount above 1 needs an attachment usage"}));

    ImageDesc tex;
    tex.width = tex.height = 16;
    tex.label = "plain";
    const Image plain = dev.make_image(tex);
    ViewDesc v;
    v.colorAttachment.image = plain;
    v.label = "bad view";
    CHECK(dev.state(dev.make_view(v)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"make_view 'bad view'", "image 'plain'", "usage.colorAttachment"}));

    ShaderDesc sh = textured_shader("odd block");
    sh.uniformBlocks[0].size = 20;
    CHECK(dev.state(dev.make_shader(sh)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"make_shader 'odd block'", "std140", "multiple of 16"}));

    const Shader good = dev.make_shader(textured_shader());
    PipelineDesc pd;
    pd.shader = good;
    pd.label = "no layout";
    CHECK(dev.state(dev.make_pipeline(pd)) == ResourceState::Failed);
    CHECK(has_error(dev.take_errors(), {"make_pipeline 'no layout'", "vertex attribute 0", "has no format"}));
}

TEST_CASE("RecordingDevice: a correct frame records no error and a readable stream") {
    RecordingDevice dev;
    Scene s(dev);
    REQUIRE(dev.errors().empty());
    CommandList& cl = dev.begin_commands("main");
    cl.push_debug_group("opaque");
    ready(cl, s);
    cl.set_viewport(0, 0, 64, 64, true);
    cl.draw(0, 36, 1);
    cl.end_pass();
    cl.pop_debug_group();
    dev.submit(cl);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    CHECK(dev.frame_index() == 1);
    CHECK(dev.stream_text() == "frame 0 [main] push_debug_group 'opaque'\n"
                               "frame 0 [main] begin_pass 'main' color=RGBA8 depth=DEPTH_STENCIL samples=1\n"
                               "frame 0 [main] set_pipeline 'textured'\n"
                               "frame 0 [main] set_bindings vb=1 views=1 samplers=1\n"
                               "frame 0 [main] set_uniforms 0 32B\n"
                               "frame 0 [main] set_viewport 0 0 64 64\n"
                               "frame 0 [main] draw 0 36 1\n"
                               "frame 0 [main] end_pass\n"
                               "frame 0 [main] pop_debug_group\n"
                               "frame 0 commit\n");
    const auto cmds = dev.commands();
    REQUIRE(cmds.size() == 10);
    CHECK(cmds[6].kind == CommandKind::Draw);
    CHECK(cmds[6].id == s.pipeline.id);
    CHECK(cmds[6].args[1] == 36);
    CHECK(std::string(command_kind_name(cmds[6].kind)) == "draw");

    // A compute frame: storage buffer written by a dispatch.
    BufferDesc sb;
    sb.size = 1024;
    sb.usage.storageBuffer = true;
    sb.label = "particles";
    const Buffer particles = dev.make_buffer(sb);
    ViewDesc sv;
    sv.storageBuffer.buffer = particles;
    const View particlesView = dev.make_view(sv);
    ShaderDesc cd;
    cd.computeFunc.source = "cs";
    cd.views[0].storageBuffer.stage = ShaderStage::Compute;
    cd.label = "simulate";
    PipelineDesc cp;
    cp.compute = true;
    cp.shader = dev.make_shader(cd);
    cp.label = "simulate";
    const Pipeline sim = dev.make_pipeline(cp);
    dev.clear_commands();
    CommandList& c2 = dev.begin_commands("compute");
    c2.begin_compute_pass("simulate");
    c2.set_pipeline(sim);
    Bindings cb;
    cb.views[0] = particlesView;
    c2.set_bindings(cb);
    c2.dispatch(4, 1, 1);
    c2.end_pass();
    dev.submit(c2);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    CHECK(dev.stream_text() == "frame 1 [compute] begin_compute_pass 'simulate'\n"
                               "frame 1 [compute] set_pipeline 'simulate'\n"
                               "frame 1 [compute] set_bindings vb=0 views=1 samplers=0\n"
                               "frame 1 [compute] dispatch 4 1 1\n"
                               "frame 1 [compute] end_pass\n"
                               "frame 1 commit\n");
}

TEST_CASE("RecordingDevice: misuses inside a list name the list, the command and the fix") {
    RecordingDevice dev;
    Scene s(dev);
    REQUIRE(dev.errors().empty());

    SUBCASE("draw outside a pass, and with no pipeline") {
        CommandList& cl = dev.begin_commands("ui");
        cl.draw(0, 3, 1);
        cl.begin_pass(s.pass("hud"));
        cl.draw(0, 3, 1);
        cl.end_pass();
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(
            has_error(e, {"list 'ui'", "command #0 (draw)", "outside a pass", "Fix: record it between begin_pass()"}));
        CHECK(has_error(e, {"command #2 (draw) in pass 'hud'", "no pipeline is set", "set_pipeline() first"}));
    }
    SUBCASE("a draw without its bindings or uniforms") {
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(s.pass());
        cl.set_pipeline(s.pipeline);
        cl.draw(0, 3, 1);
        cl.end_pass();
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(has_error(e, {"(draw)", "set_bindings() was not called after set_pipeline()"}));
        CHECK(has_error(e, {"(draw)", "uniform block(s) 0 of pipeline 'textured' were not set"}));
    }
    SUBCASE("set_pipeline re-arms the bindings and the uniforms") {
        CommandList& cl = dev.begin_commands("main");
        ready(cl, s);
        cl.draw(0, 3, 1);
        cl.set_pipeline(s.pipeline);
        cl.draw(0, 3, 1);
        cl.end_pass();
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(e.size() == 2);
        CHECK(has_error(e, {"command #6 (draw)", "set_bindings() was not called"}));
    }
    SUBCASE("a pipeline whose formats are not the pass's") {
        ImageDesc hdr;
        hdr.width = hdr.height = 64;
        hdr.usage.colorAttachment = true;
        hdr.pixelFormat = PixelFormat::Rgba16F;
        ViewDesc hv;
        hv.colorAttachment.image = dev.make_image(hdr);
        PassDesc p = s.pass("hdr");
        p.color = dev.make_view(hv);
        p.format.color = PixelFormat::Rgba16F;
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(p);
        cl.set_pipeline(s.pipeline);
        cl.end_pass();
        dev.submit(cl);
        CHECK(has_error(dev.take_errors(), {"(set_pipeline) in pass 'hdr'", "pipeline 'textured' draws color=RGBA8",
                                            "the pass is color=RGBA16F", "TargetFormat"}));
    }
    SUBCASE("PassDesc::format that lies about an attachment") {
        PassDesc p = s.pass();
        p.format.depth = PixelFormat::Depth;
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(p);
        cl.end_pass();
        dev.submit(cl);
        CHECK(has_error(dev.take_errors(), {"(begin_pass)", "PassDesc::format says DEPTH for depth",
                                            "view 'target depth' is DEPTH_STENCIL"}));
    }
    SUBCASE("uniforms of the wrong size, a slot the shader does not declare") {
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(s.pass());
        cl.set_pipeline(s.pipeline);
        cl.set_bindings(s.bindings());
        cl.set_uniforms(0, Range{kUniforms, 16});
        cl.set_uniforms(3, Range{kUniforms, 32});
        cl.end_pass();
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(has_error(e, {"(set_uniforms)", "uniform block 0 is 32 bytes but 16 were passed"}));
        CHECK(has_error(e, {"(set_uniforms)", "uniform block 3 is not declared"}));
    }
    SUBCASE("bindings that do not match the shader's reflection") {
        SamplerDesc cmp;
        cmp.compare = CompareFunc::LessEqual;
        cmp.label = "shadow cmp";
        Bindings b = s.bindings();
        b.samplers[0] = dev.make_sampler(cmp);
        b.views[1] = s.textureView;
        b.vertexBuffers[0] = {};
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(s.pass());
        cl.set_pipeline(s.pipeline);
        cl.set_bindings(b);
        cl.end_pass();
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(has_error(e, {"vertex buffer slot 0", "pipeline 'textured' reads", "no buffer (id 0)"}));
        CHECK(has_error(e, {"view slot 1 is bound but shader 'textured' declares nothing there"}));
        CHECK(has_error(e, {"sampler slot 0: sampler 'shadow cmp' compares"}));
    }
    SUBCASE("a texture the shader's sample type cannot read") {
        ImageDesc ui;
        ui.width = ui.height = 8;
        ui.pixelFormat = PixelFormat::R32Ui;
        ViewDesc v;
        v.texture.image = dev.make_image(ui);
        v.label = "ids";
        Bindings b = s.bindings();
        b.views[0] = dev.make_view(v);
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(s.pass());
        cl.set_pipeline(s.pipeline);
        cl.set_bindings(b);
        cl.end_pass();
        dev.submit(cl);
        CHECK(has_error(dev.take_errors(), {"view slot 0: view 'ids' is R32UI", "sample type"}));
    }
    SUBCASE("a destroyed image in a view, a destroyed pipeline") {
        dev.destroy_image(s.texture);
        dev.destroy_pipeline(s.pipeline);
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(s.pass());
        cl.set_pipeline(s.pipeline);
        cl.end_pass();
        dev.submit(cl);
        CHECK(has_error(dev.take_errors(), {"(set_pipeline)", "destroyed pipeline 'textured'"}));
        Scene again(dev);
        CommandList& c2 = dev.begin_commands("main");
        c2.begin_pass(again.pass());
        c2.set_pipeline(again.pipeline);
        Bindings b = again.bindings();
        b.views[0] = s.textureView;  // the view of the destroyed image
        c2.set_bindings(b);
        c2.end_pass();
        dev.submit(c2);
        CHECK(
            has_error(dev.take_errors(), {"view slot 0: view 'albedo tex' is of destroyed image", "slot was reused"}));
    }
    SUBCASE("passes that nest, end twice, or stay open at submit") {
        CommandList& cl = dev.begin_commands("main");
        cl.begin_pass(s.pass("a"));
        cl.begin_pass(s.pass("b"));
        cl.end_pass();
        cl.end_pass();
        cl.begin_pass(s.pass("c"));
        cl.push_debug_group("x");
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(has_error(e, {"(begin_pass) in pass 'a'", "pass 'a' is still open; passes do not nest"}));
        CHECK(has_error(e, {"command #3 (end_pass)", "no pass is open"}));
        CHECK(has_error(e, {"submit 'main'", "pass 'c' is still open", "end_pass() before submit()"}));
        CHECK(has_error(e, {"submit 'main'", "debug group(s) are still open"}));
    }
    SUBCASE("commit with a list not submitted, submit twice, pop without a push") {
        CommandList& cl = dev.begin_commands("late");
        cl.pop_debug_group();
        dev.commit();
        dev.submit(cl);
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(has_error(e, {"(pop_debug_group)", "no debug group is open"}));
        CHECK(has_error(e, {"commit", "command list 'late' was not submitted"}));
        CHECK(has_error(e, {"submit 'late'", "submitted already"}));
    }
    SUBCASE("writes and copies against usage and bounds") {
        BufferDesc d;
        d.size = 64;
        d.usage.vertexBuffer = true;
        d.usage.writeTransient = true;
        d.usage.copySrc = true;
        d.label = "stream";
        const Buffer stream = dev.make_buffer(d);
        const unsigned char bytes[128] = {};
        CommandList& cl = dev.begin_commands("upload");
        BufferWrite w;
        w.buffer = s.vertices;
        w.data = Range{bytes, 16};
        w.size = 16;
        cl.write_buffer(w);
        w.buffer = stream;
        w.data = Range{bytes, sizeof(bytes)};
        w.size = 32;
        w.dstOffset = 48;
        cl.write_buffer(w);
        BufferCopy c;
        c.src = stream;
        c.dst = s.vertices;
        c.size = 16;
        cl.copy_buffer_to_buffer(c);
        cl.begin_pass(s.pass());
        cl.copy_buffer_to_buffer(c);
        cl.end_pass();
        dev.submit(cl);
        const auto e = dev.take_errors();
        CHECK(has_error(e, {"(write_buffer)", "buffer 'vertices' was not made with usage.writeTransient"}));
        CHECK(has_error(e, {"(write_buffer)", "32 bytes at offset 48 do not fit in buffer 'stream' (64 bytes)"}));
        CHECK(
            has_error(e, {"command #2 (copy_buffer_to_buffer)", "buffer 'vertices' was not made with usage.copyDst"}));
        CHECK(has_error(e, {"(copy_buffer_to_buffer) in pass 'main'", "inside a render pass; it goes outside a pass"}));
    }
    SUBCASE("a device without base vertex reports draw_ex's") {
        DeviceInit init;
        init.recordingDefaultCaps = false;  // nothing: like the oldest GLES3
        RecordingDevice small(init);
        Scene t(small);
        CommandList& cl = small.begin_commands("main");
        ready(cl, t);
        cl.draw_ex(0, 3, 1, 4, 0);
        cl.end_pass();
        small.submit(cl);
        CHECK(has_error(small.take_errors(), {"baseVertex is set on a device without it"}));
        CHECK(!small.pixel_format_caps(PixelFormat::Rgba8).write);  // no compute, no storage images
    }
}

TEST_CASE("RecordingDevice: a rectangle near INT_MAX does not wrap around into one that fits") {
    RecordingDevice dev;
    ImageDesc d;
    d.width = d.height = 64;
    d.usage.writeTransient = true;
    d.pixelFormat = PixelFormat::Rgba8;
    d.label = "video";
    const Image img = dev.make_image(d);
    REQUIRE(dev.state(img) == ResourceState::Valid);
    const std::uint8_t px[4] = {};
    CommandList& cl = dev.begin_commands("upload");
    ImageWrite w;
    w.data = Range{px, sizeof(px)};
    w.dst.image = img;
    w.dst.x = INT_MAX - 1;  // x + width wraps to a negative int in 32 bits, which is "inside" 64
    w.size.width = 8;
    w.size.height = 1;
    cl.write_image(w);
    w.dst.x = 0;
    w.dst.y = 0;
    w.size.width = 64;
    w.size.height = 64;
    cl.write_image(w);  // the whole image: fine
    dev.submit(cl);
    const auto e = dev.take_errors();
    CHECK(e.size() == 1);
    CHECK(has_error(e, {"command #0 (write_image)", "outside image 'video'"}));
}

TEST_CASE("pixel formats: one table row per format answers the kind, the size and the name") {
    CHECK(pixel_format_integer(PixelFormat::R8Ui));
    CHECK(pixel_format_integer(PixelFormat::Rgba32Si));
    CHECK_FALSE(pixel_format_integer(PixelFormat::Rgba16F));
    CHECK_FALSE(pixel_format_integer(PixelFormat::Bc6hRgbUf));  // compressed, not an integer format
    CHECK(pixel_format_signed_normalized(PixelFormat::Rgba16Sn));
    CHECK_FALSE(pixel_format_signed_normalized(PixelFormat::Bc4RSn));  // its name ends in SN; its kind is compressed
    CHECK_FALSE(pixel_format_signed_normalized(PixelFormat::Rgba8));
    CHECK(pixel_format_compressed(PixelFormat::Bc1Rgba));
    CHECK(pixel_format_compressed(PixelFormat::Astc4x4Srgba));
    CHECK_FALSE(pixel_format_compressed(PixelFormat::DepthStencil));
    CHECK(pixel_format_depth(PixelFormat::DepthStencil));
    CHECK(pixel_format_bytes(PixelFormat::Rgba16F) == 8);
    CHECK(pixel_format_bytes(PixelFormat::Rgba32F) == 16);
    CHECK(pixel_format_bytes(PixelFormat::Bc7Rgba) == 0);
    CHECK(std::string(pixel_format_name(PixelFormat::Rg11B10F)) == "RG11B10F");
    CHECK(std::string(pixel_format_name(PixelFormat::Count)) == "?");
    CHECK_FALSE(pixel_format_integer(PixelFormat::Count));  // past the table: the None row
    // Every uncompressed colour format is exactly one of: integer, signed normalized, or neither (filterable).
    int integer = 0, snorm = 0;
    for (std::uint32_t i = 0; i < std::uint32_t(PixelFormat::Count); ++i) {
        const auto f = PixelFormat(i);
        CHECK_FALSE((pixel_format_integer(f) && pixel_format_signed_normalized(f)));
        integer += pixel_format_integer(f);
        snorm += pixel_format_signed_normalized(f);
    }
    CHECK(integer == 18);  // R8, R16, RG8, R32, RG16, RGBA8, RG32, RGBA16, RGBA32: UI and SI each
    CHECK(snorm == 6);     // R8, R16, RG8, RG16, RGBA8, RGBA16
}

TEST_CASE("features: feature_env_from_device reads the device's formats, features and limits") {
    RecordingDevice dev;
    const fa::render::FeatureEnv env = fa::render::feature_env_from_device(dev);
    CHECK(env.backend == fa::render::FeatureBackend::Headless);  // Recording draws nothing
    CHECK(env.maxTextureSize == dev.limits().maxImageSize2d);
    CHECK(env.compute == dev.features().compute);
    CHECK(env.halfTargets ==
          (dev.pixel_format_caps(PixelFormat::Rgba16F).render && dev.pixel_format_caps(PixelFormat::Rgba16F).blend &&
           dev.pixel_format_caps(PixelFormat::Rgba16F).filter));
    CHECK_FALSE(env.metalfx);
    CHECK(fa::render::feature_backend_of(Backend::Gl) == fa::render::FeatureBackend::Gl);
    CHECK(fa::render::feature_backend_of(Backend::WebGl2) == fa::render::FeatureBackend::WebGl2);
    CHECK(fa::render::feature_backend_of(Backend::Metal) == fa::render::FeatureBackend::Metal);
    CHECK(fa::render::feature_backend_of(Backend::Vulkan) == fa::render::FeatureBackend::Headless);
}

TEST_CASE("RecordingDevice: lists record on several threads and join the stream at submit") {
    RecordingDevice dev;
    Scene s(dev);
    CommandList& shadows = dev.begin_commands("shadows");
    CommandList& opaque = dev.begin_commands("opaque");
    auto record = [&](CommandList& cl, int draws) {
        ready(cl, s);
        for (int i = 0; i < draws; ++i) cl.draw(i, 3, 1);
        cl.end_pass();
    };
    std::thread a([&] { record(shadows, 50); });
    std::thread b([&] { record(opaque, 30); });
    a.join();
    b.join();
    dev.submit(opaque);
    dev.submit(shadows);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    const auto cmds = dev.commands();
    REQUIRE(cmds.size() == 5 + 30 + 5 + 50 + 1);
    CHECK(cmds.front().list == "opaque");  // submit order, not record order
    CHECK(cmds[35].list == "shadows");
    CHECK(cmds.back().kind == CommandKind::Commit);
    // Lists are reused after submit.
    CommandList* next = &dev.begin_commands("next");
    CHECK((next == &opaque || next == &shadows));
}

TEST_CASE("RecordingDevice: a dead handle is not read, background reads and timers say there is no GPU") {
    RecordingDevice dev;
    std::vector<std::uint8_t> out;
    const auto r = dev.read_buffer(Buffer{}, 0, 4, out);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "no buffer (id 0)"));
    CHECK(contains(r.error().hint, "live storage buffer"));
    const auto ticket = dev.request_buffer_read(Buffer{}, 0, 4);
    REQUIRE(!ticket);
    CHECK(contains(ticket.error().message, "async_read_supported() is false"));
    CHECK(contains(ticket.error().hint, "read_buffer()"));
    CHECK(dev.commands().empty());
    std::string why;
    CHECK(!dev.timer_supported(&why));
    CHECK(contains(why, "no GPU"));
    CHECK(!dev.async_read_supported());
    int calls = 0;
    auto listener = [](void* user) { ++*static_cast<int*>(user); };
    CHECK(dev.add_commit_listener(listener, &calls));
    CHECK(!dev.add_commit_listener(listener, &calls));
    dev.commit();
    dev.commit();
    CHECK(calls == 2);
    CHECK(dev.remove_commit_listener(listener, &calls));
    dev.commit();
    CHECK(calls == 2);
}

namespace {

Image color_image(Device& dev, PixelFormat format, int w, int h, const char* label, bool storage = false) {
    ImageDesc d;
    d.usage.colorAttachment = !storage;
    d.usage.storageImage = storage;
    d.width = w;
    d.height = h;
    d.pixelFormat = format;
    d.sampleCount = 1;
    d.label = label;
    return dev.make_image(d);
}

}  // namespace

TEST_CASE("RecordingDevice: accepted reads answer zeros of the asked size and are recorded") {
    RecordingDevice dev;
    const Image ldr = color_image(dev, PixelFormat::Rgba8, 16, 8, "ldr");
    const Image hdr = color_image(dev, PixelFormat::Rgba16F, 4, 4, "hdr");
    const Image depth = color_image(dev, PixelFormat::R32F, 8, 8, "mfx depth", true);
    BufferDesc bd;
    bd.size = 64;
    bd.usage.storageBuffer = true;
    bd.label = "hiz out";
    const Buffer buf = dev.make_buffer(bd);
    REQUIRE(dev.errors().empty());

    std::vector<std::uint8_t> bytes(3, 7);
    REQUIRE(dev.read_image_rgba8(ldr, 16, 8, bytes).ok());
    CHECK(bytes.size() == 16u * 8u * 4u);
    CHECK(std::all_of(bytes.begin(), bytes.end(), [](std::uint8_t b) { return b == 0; }));
    std::vector<float> floats(1, 1.0f);
    REQUIRE(dev.read_image_rgba16f(hdr, 4, 4, floats).ok());
    CHECK(floats.size() == 4u * 4u * 4u);
    CHECK(std::all_of(floats.begin(), floats.end(), [](float f) { return f == 0.0f; }));
    REQUIRE(dev.read_storage_image(depth, PixelFormat::R32F, 3, 2, 1, 1, bytes).ok());
    CHECK(bytes.size() == 4u);
    REQUIRE(dev.read_buffer(buf, 8, 16, bytes).ok());
    CHECK(bytes.size() == 16u);
    REQUIRE(dev.read_buffer(buf, 64, 0, bytes).ok());  // an empty range at the end is a read of nothing
    CHECK(bytes.empty());
    dev.commit();

    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    CHECK(dev.stream_text() == "frame 0 read_image_rgba8 image 'ldr' 0 0 16x8\n"
                               "frame 0 read_image_rgba16f image 'hdr' 0 0 4x4\n"
                               "frame 0 read_storage_image image 'mfx depth' 3 2 1x1\n"
                               "frame 0 read_buffer buffer 'hiz out' 8 16\n"
                               "frame 0 read_buffer buffer 'hiz out' 64 0\n"
                               "frame 0 commit\n");
    const auto cmds = dev.commands();
    REQUIRE(cmds.size() == 6);
    CHECK(cmds[0].kind == CommandKind::ReadImage);
    CHECK(cmds[0].id == ldr.id);
    CHECK(cmds[0].list.empty());
    CHECK(cmds[2].args[0] == 3);
    CHECK(cmds[2].args[1] == 2);
    CHECK(cmds[3].kind == CommandKind::ReadBuffer);
    CHECK(cmds[3].id == buf.id);
    CHECK(cmds[3].args[0] == 8);
    CHECK(cmds[3].args[1] == 16);
    CHECK(std::string(command_kind_name(CommandKind::ReadImage)) == "read_image");
    CHECK(std::string(command_kind_name(CommandKind::ReadBuffer)) == "read_buffer");

    // The same reads on a second device answer the same: the answer does not depend on anything but the call.
    RecordingDevice twin;
    const Image ldr2 = color_image(twin, PixelFormat::Rgba8, 16, 8, "ldr");
    std::vector<std::uint8_t> again;
    REQUIRE(twin.read_image_rgba8(ldr2, 16, 8, again).ok());
    CHECK(again == std::vector<std::uint8_t>(16u * 8u * 4u, 0));
}

TEST_CASE("RecordingDevice: reads a GPU would refuse fail with a teaching error and record nothing") {
    RecordingDevice dev;
    const Image ldr = color_image(dev, PixelFormat::Rgba8, 16, 8, "ldr");
    const Image hdr = color_image(dev, PixelFormat::Rgba16F, 4, 4, "hdr");
    const Image depth = color_image(dev, PixelFormat::R32F, 8, 8, "mfx depth", true);
    BufferDesc bd;
    bd.size = 64;
    bd.usage.storageBuffer = true;
    bd.label = "hiz out";
    const Buffer buf = dev.make_buffer(bd);
    BufferDesc vd;
    vd.size = 64;
    vd.usage.vertexBuffer = true;
    vd.label = "verts";
    const Buffer verts = dev.make_buffer(vd);
    REQUIRE(dev.errors().empty());

    std::vector<std::uint8_t> bytes;
    std::vector<float> floats;
    auto fails = [](const fa::Result<void>& r, const char* what, const char* fix) {
        REQUIRE(!r.ok());
        INFO(r.error().to_string());
        CHECK(contains(r.error().message, what));
        CHECK(contains(r.error().hint, fix));
    };
    fails(dev.read_image_rgba8(hdr, 4, 4, bytes), "is RGBA16F, not RGBA8", "read_image_rgba16f");
    fails(dev.read_image_rgba16f(ldr, 16, 8, floats), "is RGBA8, not RGBA16F", "read_image_rgba8");
    fails(dev.read_image_rgba8(ldr, 17, 8, bytes), "is not inside image 'ldr' (16x8)", "inside the image");
    fails(dev.read_image_rgba8(ldr, 0, 8, bytes), "of 0x8", "at least 1x1");
    fails(dev.read_storage_image(ldr, PixelFormat::Rgba8, 0, 0, 1, 1, bytes), "is not a storage image",
          "usage.storageImage");
    fails(dev.read_storage_image(depth, PixelFormat::Rg16F, 0, 0, 1, 1, bytes), "RG16F is not the image's own (R32F)",
          "R32F");
    fails(dev.read_storage_image(depth, PixelFormat::R32F, 7, 0, 2, 1, bytes), "at (7, 0) of 2x1", "inside");
    fails(dev.read_storage_image(depth, PixelFormat::R32F, INT_MAX, 0, 2, 1, bytes), "is not inside", "inside");
    fails(dev.read_buffer(buf, 60, 8, bytes), "offset 60 + bytes 8 is past the end of buffer 'hiz out' (64 bytes)",
          "inside the buffer");
    fails(dev.read_buffer(buf, 65, 0, bytes), "past the end", "inside the buffer");
    fails(dev.read_buffer(buf, 8, SIZE_MAX, bytes), "past the end", "inside the buffer");
    fails(dev.read_buffer(verts, 0, 4, bytes), "is not a storage buffer", "usage.storageBuffer");

    const Image gone = color_image(dev, PixelFormat::Rgba8, 4, 4, "gone");
    dev.destroy_image(gone);
    fails(dev.read_image_rgba8(gone, 4, 4, bytes), "'gone'", "live image");

    CHECK(dev.commands().empty());
    CHECK(dev.errors().empty());  // a refused read is its Result, not a misuse report

    // A device without compute (GLES3-like) has no storage reads.
    DeviceInit init;
    init.recordingDefaultCaps = false;
    RecordingDevice gles(init);
    const Image img = color_image(gles, PixelFormat::Rgba8, 4, 4, "img");
    fails(gles.read_storage_image(img, PixelFormat::Rgba8, 0, 0, 1, 1, bytes), "no storage images",
          "Features::compute");
}

TEST_CASE("RecordingDevice: a read before commit() reports that a GPU would not have run the work yet") {
    RecordingDevice dev;
    Scene s(dev);
    const Image ldr = color_image(dev, PixelFormat::Rgba8, 4, 4, "ldr");
    std::vector<std::uint8_t> bytes;

    CommandList& cl = dev.begin_commands("main");
    ready(cl, s);
    cl.draw(0, 36, 1);
    cl.end_pass();
    // Still recording.
    REQUIRE(dev.read_image_rgba8(ldr, 4, 4, bytes).ok());  // the read still answers
    CHECK(has_error(dev.take_errors(), {"read_image_rgba8", "'main' is still recording", "submit()"}));
    dev.submit(cl);
    // Submitted, not committed.
    REQUIRE(dev.read_image_rgba8(ldr, 4, 4, bytes).ok());
    CHECK(has_error(dev.take_errors(), {"read_image_rgba8", "'main' was submitted but not committed", "commit()"}));
    dev.commit();
    REQUIRE(dev.read_image_rgba8(ldr, 4, 4, bytes).ok());
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    // An empty list submitted (nothing to wait for) is no reason to report.
    CommandList& empty = dev.begin_commands("empty");
    dev.submit(empty);
    REQUIRE(dev.read_image_rgba8(ldr, 4, 4, bytes).ok());
    CHECK(dev.errors().empty());
}

TEST_CASE("storage_image_loadable: RecordingDevice answers per format and compute; the Device default teaches") {
    RecordingDevice dev;
    std::string why = "stale";
    CHECK(dev.storage_image_loadable(PixelFormat::Rgba16F, &why));
    CHECK(why.empty());
    for (PixelFormat f : {PixelFormat::Rgba8, PixelFormat::R32F, PixelFormat::Rgba32F})
        CHECK(dev.storage_image_loadable(f, nullptr));
    CHECK(!dev.storage_image_loadable(PixelFormat::Rg16F, &why));
    CHECK(contains(why, "RG16F is not a storage image format"));

    DeviceInit init;
    init.recordingDefaultCaps = false;
    RecordingDevice gles(init);
    CHECK(!gles.storage_image_loadable(PixelFormat::Rgba16F, &why));
    CHECK(contains(why, "features().compute is false"));

    // The base class's answer, for a backend that has not implemented it (every backend does today: this is what a new one
    // answers until it does).
    CHECK(!dev.Device::storage_image_loadable(PixelFormat::Rgba16F, &why));
    CHECK(contains(why, "not implemented on the recording device"));
    CHECK(contains(why, "\"access\": \"write\""));
}

TEST_CASE("make_device: Recording, the built sokol backend, and teaching errors for the rest") {
    auto rec = make_device(Backend::Recording);
    REQUIRE(rec);
    CHECK(rec.value()->backend() == Backend::Recording);
    CHECK(rec.value()->features().compute);

    auto d3d12 = make_device(Backend::D3d12);
    REQUIRE(!d3d12);
    CHECK(contains(d3d12.error().message, "d3d12 backend is not built yet"));
    CHECK(contains(d3d12.error().hint, "M77.2"));
    auto vk = make_device(Backend::Vulkan);
    REQUIRE(!vk);
    CHECK(contains(vk.error().hint, "M77.3"));

    const Backend built = built_sokol_backend();
    const Backend other = built == Backend::D3d11 ? Backend::Metal : Backend::D3d11;
    auto wrong = make_device(other);
    REQUIRE(!wrong);
    CHECK(contains(wrong.error().message, std::string("built with the ") + backend_name(built)));
}

TEST_CASE("SokolDevice: a buffer, an image, a pipeline and a cleared pass on the test GPU") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the SokolDevice round trip is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    CHECK(dev.backend() == backend_from_sg(sg_query_backend()));
    CHECK(dev.pixel_format_caps(PixelFormat::Rgba8).render);
    CHECK(dev.environment_defaults().colorFormat != PixelFormat::Default);

    const float tri[6] = {-1.0f, -1.0f, 3.0f, -1.0f, -1.0f, 3.0f};
    BufferDesc bd;
    bd.size = sizeof(tri);
    bd.usage.vertexBuffer = true;
    bd.data = Range{tri, sizeof(tri)};
    bd.label = "gpu_interface tri";
    const Buffer vb = dev.make_buffer(bd);
    CHECK(dev.state(vb) == ResourceState::Valid);
    CHECK(sg_query_buffer_state(to_sg(vb)) == SG_RESOURCESTATE_VALID);  // the same id names the sokol buffer

    ImageDesc id;
    id.width = id.height = 16;
    id.usage.colorAttachment = true;
    id.pixelFormat = PixelFormat::Rgba8;
    id.label = "gpu_interface target";
    const Image target = dev.make_image(id);
    CHECK(dev.state(target) == ResourceState::Valid);
    ViewDesc cv;
    cv.colorAttachment.image = target;
    const View color = dev.make_view(cv);
    CHECK(dev.state(color) == ResourceState::Valid);

    const Shader shader = dev.make_shader(from_sg(*blit_blit_shader_desc(sg_query_backend())));
    CHECK(dev.state(shader) == ResourceState::Valid);
    PipelineDesc pd;
    pd.shader = shader;
    pd.layout.attrs[ATTR_blit_blit_pos].format = VertexFormat::Float2;
    pd.colors[0].pixelFormat = PixelFormat::Rgba8;
    pd.depth.pixelFormat = PixelFormat::None;
    pd.sampleCount = 1;
    pd.label = "gpu_interface blit";
    const Pipeline pipeline = dev.make_pipeline(pd);
    CHECK(dev.state(pipeline) == ResourceState::Valid);

    CommandList& cl = dev.begin_commands("gpu_interface");
    PassDesc p;
    p.label = "gpu_interface clear";
    p.color = color;
    p.format.color = PixelFormat::Rgba8;
    p.format.depth = PixelFormat::None;
    p.colorLoad = LoadAction::Clear;
    p.clearColor = Color{1.0f, 0.0f, 0.0f, 1.0f};
    cl.begin_pass(p);
    CHECK(cl.pass_state() == PassState::Render);
    cl.set_pipeline(pipeline);
    cl.end_pass();
    CHECK(cl.pass_state() == PassState::None);
    dev.submit(cl);
    const std::uint64_t frame = dev.frame_index();
    dev.commit();
    CHECK(dev.frame_index() == frame + 1);

    std::vector<std::uint8_t> px;
    const auto read = dev.read_image_rgba8(target, 16, 16, px);
    REQUIRE_MESSAGE(read, (read ? "" : read.error().message));
    REQUIRE(px.size() == 16u * 16u * 4u);
    CHECK(px[0] == 255);
    CHECK(px[1] == 0);
    CHECK(px[2] == 0);
    CHECK(px[3] == 255);

    const TotalStats before = dev.total_stats();
    dev.destroy_pipeline(pipeline);
    dev.destroy_shader(shader);
    dev.destroy_view(color);
    dev.destroy_image(target);
    dev.destroy_buffer(vb);
    CHECK(dev.state(target) == ResourceState::Invalid);
    CHECK(dev.total_stats().images.alive + 1 == before.images.alive);
    dev.reset_state_cache();  // the renderer's next frame starts from a clean sokol state
}

// gpu/sokol_context.h: what the renderer asks while no Device exists (the context lifecycle, the window pass,
// native_window_handles) answers the same as the SokolDevice made on that context.
TEST_CASE(
    "sokol context: the open context answers like a SokolDevice; swapchain_of and generated_shader_desc convert") {
    // swapchain_of reads the opaque copy the platform layer hands over.
    sg_swapchain raw{};
    raw.width = 64;
    raw.height = 32;
    raw.sample_count = 4;
    raw.color_format = SG_PIXELFORMAT_BGRA8;
    raw.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    fa::GfxSwapchain opaque{};
    static_assert(sizeof(raw) <= sizeof(opaque.storage));
    std::memcpy(opaque.storage, &raw, sizeof(raw));
    const Swapchain sc = swapchain_of(opaque);
    CHECK(sc.width == 64);
    CHECK(sc.height == 32);
    CHECK(sc.sampleCount == 4);
    CHECK(sc.colorFormat == PixelFormat::Bgra8);
    CHECK(sc.depthFormat == PixelFormat::DepthStencil);

    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the open-context half is skipped");
        return;
    }
    REQUIRE(context_open());
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    CHECK(context_backend() == dev.backend());
    CHECK(context_backend() == built_sokol_backend());
    const NativeDevice a = context_native();
    const NativeDevice b = dev.native();
    CHECK(a.device == b.device);
    CHECK(a.context == b.context);
    CHECK(a.commandQueue == b.commandQueue);
    if (context_backend() == Backend::Metal || context_backend() == Backend::D3d11) CHECK(a.device != nullptr);
    const EnvironmentDefaults d = context_defaults();
    CHECK(d.colorFormat == dev.environment_defaults().colorFormat);
    CHECK(d.depthFormat == dev.environment_defaults().depthFormat);
    CHECK(d.sampleCount == dev.environment_defaults().sampleCount);
    CHECK(d.colorFormat != PixelFormat::Default);

    // The generated header's desc for this backend, in the interface's types: a shader the device makes.
    const ShaderDesc desc = generated_shader_desc(&blit_blit_shader_desc);
    const Shader shader = dev.make_shader(desc);
    CHECK(dev.state(shader) == ResourceState::Valid);
    dev.destroy_shader(shader);
}

TEST_CASE("SokolDevice: a read ticket names one read: offset, a stale ticket, a reused slot") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the async read case is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    if (!dev.async_read_supported() || !dev.features().compute) {
        MESSAGE("this backend reads buffers back only by waiting: the async read case is skipped");
        return;
    }
    std::uint8_t bytes[16];
    for (int i = 0; i < 16; ++i) bytes[i] = std::uint8_t(i + 1);
    BufferDesc bd;
    bd.size = sizeof(bytes);
    bd.usage.storageBuffer = true;
    bd.data = Range{bytes, sizeof(bytes)};
    bd.label = "gpu_interface async";
    const Buffer buf = dev.make_buffer(bd);
    REQUIRE(dev.state(buf) == ResourceState::Valid);
    dev.commit();

    auto first = dev.request_buffer_read(buf, 4, 8);
    REQUIRE_MESSAGE(first, (first ? "" : first.error().message));
    const ReadTicket a = first.value();
    REQUIRE(a.valid());
    dev.commit();
    std::vector<std::uint8_t> out;
    REQUIRE(dev.poll_buffer_read(a, out, true));
    REQUIRE(out.size() == 8u);
    CHECK(out[0] == 5);  // the offset is dropped
    CHECK(out[7] == 12);
    CHECK_FALSE(dev.poll_buffer_read(a, out, true));  // already read: stale
    dev.release_buffer_read(a);                       // harmless on a stale ticket

    // A new read may reuse the slot: the old ticket does not name it.
    auto second = dev.request_buffer_read(buf, 0, 4);
    REQUIRE(second);
    const ReadTicket b = second.value();
    REQUIRE(b.valid());
    CHECK(b.generation != a.generation);
    ReadTicket old = a;
    old.slot = b.slot;
    CHECK_FALSE(dev.poll_buffer_read(old, out, false));
    dev.release_buffer_read(old);  // does not release b's read
    dev.commit();
    REQUIRE(dev.poll_buffer_read(b, out, true));
    CHECK(out.size() == 4u);
    CHECK(out[0] == 1);
    CHECK(!dev.request_buffer_read(buf, 1, 0));  // no bytes: an error
    dev.destroy_buffer(buf);
}

TEST_CASE("SokolDevice: reads in flight are not limited to four: eight cameras keep four each") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the async read case is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    if (!dev.async_read_supported() || !dev.features().compute) {
        MESSAGE("this backend reads buffers back only by waiting: the async read case is skipped");
        return;
    }
    std::uint8_t bytes[16];
    for (int i = 0; i < 16; ++i) bytes[i] = std::uint8_t(100 + i);
    BufferDesc bd;
    bd.size = sizeof(bytes);
    bd.usage.storageBuffer = true;
    bd.data = Range{bytes, sizeof(bytes)};
    bd.label = "gpu_interface async many";
    const Buffer buf = dev.make_buffer(bd);
    REQUIRE(dev.state(buf) == ResourceState::Valid);
    dev.commit();

    // 32 reads at once (eight rings of four slots), each with its own offset so a mixed-up ticket shows in the bytes.
    std::vector<ReadTicket> tickets;
    for (int i = 0; i < 32; ++i) {
        auto r = dev.request_buffer_read(buf, std::size_t(i % 8), 4);
        REQUIRE_MESSAGE(r, (r ? "" : r.error().message));
        REQUIRE_MESSAGE(r.value().valid(), "request " << i << " found no free slot");
        tickets.push_back(r.value());
    }
    for (std::size_t i = 0; i < tickets.size(); ++i)
        for (std::size_t j = i + 1; j < tickets.size(); ++j) CHECK(tickets[i].slot != tickets[j].slot);
    auto extra = dev.request_buffer_read(buf, 0, 4);
    REQUIRE(extra);
    CHECK_FALSE(extra.value().valid());  // every slot is in flight: ask again next frame, no error
    dev.commit();
    std::vector<std::uint8_t> out;
    for (int i = 0; i < 32; ++i) {
        REQUIRE(dev.poll_buffer_read(tickets[std::size_t(i)], out, true));
        REQUIRE(out.size() == 4u);
        CHECK(out[0] == std::uint8_t(100 + i % 8));
    }
    // A polled slot is free again.
    auto again = dev.request_buffer_read(buf, 0, 4);
    REQUIRE(again);
    CHECK(again.value().valid());
    dev.release_buffer_read(again.value());
    dev.destroy_buffer(buf);
}

TEST_CASE("SokolDevice: read tickets out of range name nothing, and a release in a later ring frees that slot") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the async read case is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    if (!dev.async_read_supported() || !dev.features().compute) {
        MESSAGE("this backend reads buffers back only by waiting: the async read case is skipped");
        return;
    }
    std::uint8_t bytes[16];
    for (int i = 0; i < 16; ++i) bytes[i] = std::uint8_t(50 + i);
    BufferDesc bd;
    bd.size = sizeof(bytes);
    bd.usage.storageBuffer = true;
    bd.data = Range{bytes, sizeof(bytes)};
    bd.label = "gpu_interface tickets";
    const Buffer buf = dev.make_buffer(bd);
    REQUIRE(dev.state(buf) == ResourceState::Valid);
    dev.commit();

    // A ticket that was never issued, however wrong its slot: not valid, not polled, not released, no crash.
    std::vector<std::uint8_t> out;
    for (const ReadTicket t : {ReadTicket{-1, 1}, ReadTicket{0, 0}, ReadTicket{31, 1}, ReadTicket{32, 1},
                               ReadTicket{4096, 1}, ReadTicket{INT_MAX, 1}}) {
        CHECK_FALSE(dev.poll_buffer_read(t, out, false));
        CHECK_FALSE(dev.poll_buffer_read(t, out, true));
        dev.release_buffer_read(t);
    }

    // Thirty-two reads fill every ring; releasing one of ring 5 frees its slot (the ring hands slots out in order).
    std::vector<ReadTicket> tickets;
    for (int i = 0; i < 32; ++i) {
        auto r = dev.request_buffer_read(buf, std::size_t(i % 4), 4);
        REQUIRE_MESSAGE(r, (r ? "" : r.error().message));
        REQUIRE(r.value().valid());
        tickets.push_back(r.value());
    }
    const ReadTicket released = tickets[21];
    dev.release_buffer_read(released);
    CHECK_FALSE(dev.poll_buffer_read(released, out, false));  // released: stale
    dev.commit();
    for (int i = 0; i < 32; ++i) {
        if (i == 21) continue;
        REQUIRE(dev.poll_buffer_read(tickets[std::size_t(i)], out, true));
        REQUIRE(out.size() == 4u);
        CHECK(out[0] == std::uint8_t(50 + i % 4));
    }
    CHECK_FALSE(dev.poll_buffer_read(released, out, true));  // the old ticket still names nothing
    // Every slot is free again, the released one included: 32 more reads find a slot, and none shares it with a live one.
    std::vector<ReadTicket> next;
    for (int i = 0; i < 32; ++i) {
        auto r = dev.request_buffer_read(buf, 0, 4);
        REQUIRE(r);
        CHECK_MESSAGE(r.value().valid(), "request " << i << " found no free slot");
        next.push_back(r.value());
    }
    for (const ReadTicket& t : next) dev.release_buffer_read(t);
    CHECK_FALSE(dev.poll_buffer_read(next[0], out, false));
    dev.destroy_buffer(buf);
}

TEST_CASE("SokolDevice: a poll that does not wait leaves the read in flight") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the async read case is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    if (!dev.async_read_supported() || !dev.features().compute) {
        MESSAGE("this backend reads buffers back only by waiting: the async read case is skipped");
        return;
    }
    std::uint8_t bytes[8];
    for (int i = 0; i < 8; ++i) bytes[i] = std::uint8_t(7 * i + 1);
    BufferDesc bd;
    bd.size = sizeof(bytes);
    bd.usage.storageBuffer = true;
    bd.data = Range{bytes, sizeof(bytes)};
    bd.label = "gpu_interface nowait";
    const Buffer buf = dev.make_buffer(bd);
    REQUIRE(dev.state(buf) == ResourceState::Valid);
    dev.commit();
    auto r = dev.request_buffer_read(buf, 0, 8);
    REQUIRE(r);
    const ReadTicket t = r.value();
    REQUIRE(t.valid());
    // Without wait the answer is "not yet" or the bytes (a GPU may be quick): either way the ticket is not spent by
    // a poll that said no, and the wait that follows gets the bytes.
    std::vector<std::uint8_t> out;
    bool got = dev.poll_buffer_read(t, out, false);
    if (!got) {
        dev.commit();
        got = dev.poll_buffer_read(t, out, true);
    }
    REQUIRE(got);
    REQUIRE(out.size() == 8u);
    for (int i = 0; i < 8; ++i) CHECK(out[std::size_t(i)] == bytes[i]);
    CHECK_FALSE(dev.poll_buffer_read(t, out, false));  // read to the end: stale
    dev.destroy_buffer(buf);
}

TEST_CASE("SokolDevice: a device destroyed with reads in flight leaves the context usable") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the async read case is skipped");
        return;
    }
    for (int round = 0; round < 2; ++round) {
        auto made = make_device(built_sokol_backend());
        REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
        Device& dev = *made.value();
        if (!dev.async_read_supported() || !dev.features().compute) {
            MESSAGE("this backend reads buffers back only by waiting: the async read case is skipped");
            return;
        }
        std::uint8_t bytes[16] = {};
        BufferDesc bd;
        bd.size = sizeof(bytes);
        bd.usage.storageBuffer = true;
        bd.data = Range{bytes, sizeof(bytes)};
        bd.label = "gpu_interface in flight";
        const Buffer buf = dev.make_buffer(bd);
        REQUIRE(dev.state(buf) == ResourceState::Valid);
        dev.commit();
        // Eleven reads over three rings; round 1 also commits them, round 0 does not. None is polled or released.
        for (int i = 0; i < 11; ++i) {
            auto r = dev.request_buffer_read(buf, 0, 16);
            REQUIRE(r);
            CHECK(r.value().valid());
        }
        if (round == 1) dev.commit();
        dev.destroy_buffer(buf);
        // `made` goes out of scope here: the staging buffers of the reads die with the device.
    }
    // The context is still the test's: another device works.
    auto again = make_device(built_sokol_backend());
    REQUIRE(again);
    CHECK(again.value()->async_read_supported());
}

TEST_CASE("make_triangle_pipeline: the full-screen pipeline takes the format of its pass and checks out on a device") {
    RecordingDevice dev;
    const Shader shader = dev.make_shader(textured_shader("triangle shader"));
    REQUIRE(dev.state(shader) == ResourceState::Valid);

    const fa::render::TargetFormat colorOnly{PixelFormat::Rgba8, PixelFormat::None, 1};
    const Pipeline a = fa::render::make_triangle_pipeline(dev, shader, colorOnly, "triangle color");
    CHECK(dev.state(a) == ResourceState::Valid);
    const fa::render::TargetFormat withDepth{PixelFormat::Rgba8, PixelFormat::DepthStencil, 1};
    const Pipeline b = fa::render::make_triangle_pipeline(dev, shader, withDepth, "triangle depth");
    CHECK(dev.state(b) == ResourceState::Valid);
    const Pipeline c = fa::render::make_triangle_pipeline(dev, shader, colorOnly, "triangle masked", 0, ColorMask::Rgb);
    CHECK(dev.state(c) == ResourceState::Valid);
    CHECK(a.id != b.id);
    CHECK(a.id != c.id);
    // The shader declares no attribute at location 1: a position there is a mistake the device reports and refuses.
    const Pipeline wrong = fa::render::make_triangle_pipeline(dev, shader, colorOnly, "triangle wrong attr", 1);
    CHECK(dev.state(wrong) == ResourceState::Failed);
    CHECK_FALSE(dev.take_errors().empty());

    // A pass of the same format draws with it; the whole stream is a clean one.
    Scene s(dev);
    PassDesc pass = s.pass();
    CommandList& list = dev.begin_commands("triangle");
    list.begin_pass(pass);
    list.set_pipeline(b);
    list.end_pass();
    dev.submit(list);
    CHECK(dev.errors().empty());
    dev.destroy_pipeline(a);
    dev.destroy_pipeline(b);
    dev.destroy_pipeline(c);
    dev.destroy_shader(shader);
}

// The 2D painter (render/ui_painter.h) on a RecordingDevice: the order of the calls of a frame, without a GPU.
TEST_CASE("UiPainter: a frame is a pipeline, bindings per texture change, and a scissor and a draw per command") {
    RecordingDevice dev;
    Scene s(dev);
    std::string error;
    std::unique_ptr<fa::render::UiPainter> painter = fa::render::make_ui_painter_on(dev, &error);
    REQUIRE_MESSAGE(painter != nullptr, error);
    REQUIRE(dev.errors().empty());

    const std::vector<std::uint8_t> pixels(4 * 4 * 4, 255);
    const fa::render::UiTexture a = painter->make_texture(4, 4, pixels.data(), &error);
    const fa::render::UiTexture b = painter->make_texture(4, 4, pixels.data(), &error);
    REQUIRE(a.valid());
    REQUIRE(b.valid());
    // An updatable picture (a glyph atlas) is filled by a queued update that upload() stages and copies.
    const fa::render::UiTexture atlas = painter->make_updatable_texture(8, 8, &error);
    REQUIRE(atlas.valid());
    CHECK(painter->update_texture(atlas, 2, 2, 4, 4, pixels.data(), 0, &error));
    CHECK_FALSE(painter->update_texture(fa::render::UiTexture{}, 0, 0, 1, 1, pixels.data(), 0, &error));
    CHECK_FALSE(error.empty());

    fa::render::UiVertex vertices[4];
    for (int i = 0; i < 4; ++i) {
        vertices[i].x = float(i % 2) * 32.0f;
        vertices[i].y = float(i / 2) * 32.0f;
    }
    const std::uint16_t indices[6] = {0, 1, 2, 2, 1, 3};
    fa::render::UiDrawCommand commands[5];
    commands[0].view = a.view;  // the whole window
    commands[0].clipMaxX = 64.0f;
    commands[0].clipMaxY = 64.0f;
    commands[0].indexOffset = 0;
    commands[0].indexCount = 3;
    commands[1] = commands[0];  // the same picture: no new bindings, only a smaller scissor
    commands[1].clipMinX = 8.0f;
    commands[1].clipMinY = 8.0f;
    commands[1].clipMaxX = 16.0f;
    commands[1].clipMaxY = 16.0f;
    commands[1].indexOffset = 3;
    commands[2] = commands[0];  // another picture, shown as it is, and a rectangle that sticks out of the window
    commands[2].view = b.view;
    commands[2].nearest = true;
    commands[2].clipMinX = -10.0f;
    commands[2].clipMaxX = 200.0f;
    commands[2].clipMaxY = 20.0f;
    commands[2].indexCount = 6;
    commands[3] = commands[2];  // entirely outside the window: skipped
    commands[3].clipMinX = 100.0f;
    commands[3].clipMaxX = 120.0f;
    commands[4] = commands[0];  // a picture with no view: skipped
    commands[4].view = 0;
    fa::render::UiDrawList list;
    list.vertices = vertices;
    list.vertexCount = 4;
    list.indices = indices;
    list.indexCount = 6;
    list.commands = commands;
    list.commandCount = 5;
    fa::render::UiFrame frame;
    frame.displayWidth = 64.0f;
    frame.displayHeight = 64.0f;
    frame.lists = &list;
    frame.listCount = 1;

    fa::render::UiPainterImpl& impl = fa::render::UiPainterAccess::impl(*painter);
    CommandList& cl = dev.begin_commands("ui");
    CHECK(impl.upload(cl, frame, &error));
    cl.begin_pass(s.pass());
    impl.draw(cl, s.pass().format, frame);
    cl.end_pass();
    dev.submit(cl);
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());

    std::vector<CommandKind> kinds;
    std::vector<RecordedCommand> scissors, draws;
    for (const RecordedCommand& c : dev.commands()) {
        kinds.push_back(c.kind);
        if (c.kind == CommandKind::SetScissor) scissors.push_back(c);
        if (c.kind == CommandKind::Draw) draws.push_back(c);
    }
    const std::vector<CommandKind> expected = {
        CommandKind::WriteBuffer,        // the staging buffer of the atlas update
        CommandKind::CopyBufferToImage,  // ...copied into the atlas
        CommandKind::WriteBuffer,        // the vertices
        CommandKind::WriteBuffer,        // the indices
        CommandKind::BeginPass,
        CommandKind::PushDebugGroup,
        CommandKind::SetPipeline,
        CommandKind::SetViewport,
        CommandKind::SetUniforms,
        CommandKind::SetBindings,  // picture a, smoothed
        CommandKind::SetScissor,
        CommandKind::Draw,
        CommandKind::SetScissor,  // command 1: the same bindings
        CommandKind::Draw,
        CommandKind::SetBindings,  // picture b, nearest
        CommandKind::SetScissor,
        CommandKind::Draw,
        CommandKind::SetScissor,  // back to the whole window
        CommandKind::PopDebugGroup,
        CommandKind::EndPass,
    };
    CHECK(kinds == expected);
    REQUIRE(scissors.size() == 4);
    CHECK(scissors[0].args[2] == 64);
    CHECK(scissors[1].args[0] == 8);
    CHECK(scissors[1].args[1] == 8);
    CHECK(scissors[1].args[2] == 8);
    CHECK(scissors[2].args[0] == 0);  // cut to the window: x from 0 to 64, y from 0 to 20
    CHECK(scissors[2].args[2] == 64);
    CHECK(scissors[2].args[3] == 20);
    CHECK(scissors[3].args[2] == 64);
    CHECK(scissors[3].args[3] == 64);
    REQUIRE(draws.size() == 3);
    CHECK(draws[0].args[0] == 0);
    CHECK(draws[0].args[1] == 3);
    CHECK(draws[1].args[0] == 3);
    CHECK(draws[2].args[1] == 6);

    // Destroying a picture with an update still queued drops the update; the next upload writes nothing for it.
    CHECK(painter->update_texture(atlas, 0, 0, 2, 2, pixels.data(), 0, &error));
    painter->destroy_texture(atlas);
    dev.clear_commands();
    CommandList& next = dev.begin_commands("ui2");
    CHECK(impl.upload(next, frame, &error));
    dev.submit(next);
    int copies = 0;
    for (const RecordedCommand& c : dev.commands()) copies += c.kind == CommandKind::CopyBufferToImage ? 1 : 0;
    CHECK(copies == 0);
    CHECK(dev.errors().empty());

    painter->destroy_texture(a);
    painter->destroy_texture(b);
}

// ---- queues, sync tokens, parallel recording and bindless (M77 P10a) -------------------------------------------------
namespace {

// A compute pass with no dispatch: the smallest work a compute-queue list can hold.
void empty_compute(CommandList& cl, const char* label) {
    cl.begin_compute_pass(label);
    cl.end_pass();
}

// A recording device that reports no async compute (and what compute needs), like a backend with one queue.
DeviceInit one_queue_init() {
    RecordingDevice probe;
    DeviceInit init;
    init.recordingDefaultCaps = false;
    init.recordingFeatures = probe.features();
    init.recordingFeatures.asyncCompute = false;
    init.recordingFeatures.multiThreadRecording = false;
    init.recordingLimits = probe.limits();
    return init;
}

std::vector<CommandKind> kinds_of(const RecordingDevice& dev) {
    std::vector<CommandKind> kinds;
    for (const RecordedCommand& c : dev.commands()) kinds.push_back(c.kind);
    return kinds;
}

}  // namespace

TEST_CASE("queues: a device without async compute runs every list on the graphics queue, in submission order") {
    RecordingDevice dev(one_queue_init());
    CHECK_FALSE(dev.features().asyncCompute);
    CHECK_FALSE(dev.features().multiThreadRecording);
    CHECK_FALSE(dev.features().bindless);

    CommandList& hiz = dev.begin_commands("hiz", QueueKind::Compute);
    CHECK(hiz.queue() == QueueKind::Graphics);  // the queue the list really runs on
    empty_compute(hiz, "reduce");
    const SyncToken a = dev.submit_token(hiz);
    CommandList& up = dev.begin_commands("upload", QueueKind::Transfer);
    CHECK(up.queue() == QueueKind::Graphics);
    const SyncToken b = dev.submit_token(up);
    CHECK(a.valid());
    CHECK(a.queue == QueueKind::Graphics);
    CHECK(a.value == 1);
    CHECK(b.queue == QueueKind::Graphics);
    CHECK(b.value == 2);  // complete in submission order

    // A wait for a token of the queue the list is on keeps the order and adds nothing to wait for.
    CommandList& gfx = dev.begin_commands("main");
    dev.wait_list(gfx, a);
    dev.wait_list(gfx, SyncToken{});  // the invalid token waits for nothing
    empty_compute(gfx, "after");
    dev.submit(gfx);
    dev.wait_queue(QueueKind::Compute, b);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());
    const std::string text = dev.stream_text();
    CHECK(contains(text, "wait_list graphics 1 (same queue: no wait)"));
    CHECK(contains(text, "wait_queue graphics <- graphics 2 (same queue: no wait)"));
    CHECK_FALSE(contains(text, "compute 1"));
    const std::vector<CommandKind> kinds = kinds_of(dev);
    const std::vector<CommandKind> expected = {
        CommandKind::BeginComputePass, CommandKind::EndPass,   CommandKind::Signal,
        CommandKind::Signal,           CommandKind::WaitList,  CommandKind::BeginComputePass,
        CommandKind::EndPass,          CommandKind::WaitQueue, CommandKind::Commit};
    CHECK(kinds == expected);
    for (const RecordedCommand& c : dev.commands()) CHECK(c.queue == QueueKind::Graphics);

    // The defaults of Device itself (what a backend that overrides none of them does): the same answers.
    Device& base = dev;
    CommandList& l1 = base.Device::begin_commands("d1", QueueKind::Compute);
    CHECK(l1.queue() == QueueKind::Graphics);
    const SyncToken t1 = base.Device::submit_token(l1);
    CommandList& l2 = base.Device::begin_commands("d2", QueueKind::Transfer);
    const SyncToken t2 = base.Device::submit_token(l2);
    CHECK(t1.queue == QueueKind::Graphics);
    CHECK(t1.value == 1);
    CHECK(t2.value == 2);
    CommandList& l3 = base.begin_commands("d3");
    const std::string before = dev.stream_text();
    base.Device::wait_list(l3, t2);
    base.Device::wait_queue(QueueKind::Graphics, t2);
    base.submit(l3);
    CHECK(dev.stream_text() == before);  // the defaults record nothing and wait for nothing
    CHECK(base.Device::bindless_index(View{1}) == kNoBindlessIndex);
}

TEST_CASE("queues: RecordingDevice with async compute records each list's queue, its signals and its waits") {
    RecordingDevice dev;
    CHECK(dev.features().asyncCompute);
    CHECK(dev.features().multiThreadRecording);
    CHECK_FALSE(dev.features().bindless);
    Scene s(dev);

    CommandList& gfx = dev.begin_commands("main", QueueKind::Graphics);
    CommandList& hiz = dev.begin_commands("hiz", QueueKind::Compute);
    CommandList& up = dev.begin_commands("upload", QueueKind::Transfer);
    CHECK(gfx.queue() == QueueKind::Graphics);
    CHECK(hiz.queue() == QueueKind::Compute);
    CHECK(up.queue() == QueueKind::Transfer);

    empty_compute(hiz, "reduce");
    const SyncToken reduced = dev.submit_token(hiz);
    CHECK(reduced.queue == QueueKind::Compute);
    CHECK(reduced.value == 1);
    dev.submit(up);  // a plain submit hands out no token

    // The graphics list waits for the compute token; the wait is recorded late but holds before its first command.
    ready(gfx, s);
    gfx.draw(0, 3, 1);
    gfx.end_pass();
    dev.wait_list(gfx, reduced);
    dev.wait_list(gfx, SyncToken{});
    const SyncToken drawn = dev.submit_token(gfx);
    CHECK(drawn.queue == QueueKind::Graphics);
    CHECK(drawn.value == 1);                    // each queue counts for itself
    dev.wait_queue(QueueKind::Compute, drawn);  // the next compute work starts after the frame's graphics
    CommandList& hiz2 = dev.begin_commands("hiz2", QueueKind::Compute);
    empty_compute(hiz2, "reduce 2");
    CHECK(dev.submit_token(hiz2).value == 2);
    dev.commit();
    INFO(joined(dev.errors()));
    CHECK(dev.errors().empty());

    const auto cmds = dev.commands();
    // hiz (2 commands + its signal), then main: its wait first, then its commands.
    REQUIRE(cmds.size() >= 6);
    CHECK(cmds[0].queue == QueueKind::Compute);
    CHECK(cmds[2].kind == CommandKind::Signal);
    CHECK(cmds[2].text == "signal compute 1");
    CHECK(cmds[3].kind == CommandKind::WaitList);  // ahead of main's commands though it was recorded after them
    CHECK(cmds[3].list == "main");
    CHECK(cmds[3].queue == QueueKind::Graphics);
    CHECK(cmds[3].args[0] == int(QueueKind::Compute));
    CHECK(cmds[3].args[1] == 1);
    CHECK(cmds[3].text == "wait_list compute 1");
    CHECK(cmds[4].kind == CommandKind::BeginPass);
    CHECK(dev.stream_text().find("[main] wait_list compute 1") != std::string::npos);
    int waitQueues = 0;
    for (const RecordedCommand& c : cmds)
        if (c.kind == CommandKind::WaitQueue) {
            ++waitQueues;
            CHECK(c.queue == QueueKind::Compute);
            CHECK(c.text == "wait_queue compute <- graphics 1");
            CHECK(c.list.empty());
        }
    CHECK(waitQueues == 1);

    // A token of an earlier frame stays valid: waiting for it is allowed and raises no error.
    CommandList& next = dev.begin_commands("next frame");
    dev.wait_list(next, reduced);
    dev.submit(next);
    dev.commit();
    CHECK(dev.errors().empty());
}

TEST_CASE("queues: RecordingDevice reports a queue used for what it cannot do and a token nobody signalled") {
    RecordingDevice dev;
    CommandList& comp = dev.begin_commands("comp", QueueKind::Compute);
    PassDesc swap;
    const Swapchain sc;
    swap.swapchain = &sc;
    swap.label = "present";
    comp.begin_pass(swap);
    comp.end_pass();
    dev.submit(comp);
    CHECK(has_error(dev.errors(), {"begin_pass", "compute queue", "no render passes", "QueueKind::Graphics"}));
    dev.take_errors();

    CommandList& xfer = dev.begin_commands("xfer", QueueKind::Transfer);
    xfer.begin_compute_pass("nope");
    xfer.end_pass();
    dev.submit(xfer);
    CHECK(has_error(dev.errors(), {"begin_compute_pass", "transfer queue", "no compute passes"}));
    dev.take_errors();

    CommandList& g = dev.begin_commands("g");
    dev.wait_list(g, SyncToken{QueueKind::Compute, 7});
    CHECK(has_error(dev.errors(), {"wait_list", "'g'", "never returned by submit_token()", "compute 7"}));
    dev.take_errors();
    dev.wait_queue(QueueKind::Graphics, SyncToken{QueueKind::Compute, 7});
    CHECK(has_error(dev.errors(), {"wait_queue", "never returned by submit_token()"}));
    dev.take_errors();
    dev.submit(g);
    dev.wait_list(g, SyncToken{});  // submitted already
    CHECK(has_error(dev.errors(), {"wait_list", "submitted already"}));
    const std::string text = dev.stream_text();
    CHECK_FALSE(contains(text, "wait_list compute 7"));
    CHECK_FALSE(contains(text, "wait_queue graphics <- compute 7"));
}

TEST_CASE("threads: two threads begin and record a graphics and a compute list at once, submitted in a fixed order") {
    for (int round = 0; round < 20; ++round) {
        RecordingDevice dev;
        REQUIRE(dev.features().multiThreadRecording);
        Scene s(dev);
        CommandList* gfx = nullptr;
        CommandList* comp = nullptr;
        // begin_commands and the whole recording happen on the worker threads (Features::multiThreadRecording).
        std::thread a([&] {
            gfx = &dev.begin_commands("main", QueueKind::Graphics);
            ready(*gfx, s);
            for (int i = 0; i < 40; ++i) gfx->draw(i, 3, 1);
            gfx->end_pass();
        });
        std::thread b([&] {
            comp = &dev.begin_commands("hiz", QueueKind::Compute);
            for (int i = 0; i < 10; ++i) empty_compute(*comp, "reduce");
        });
        // The render thread reads the read-only queries meanwhile.
        for (int i = 0; i < 100; ++i) {
            CHECK(dev.features().compute);
            CHECK(dev.state(s.pipeline) == ResourceState::Valid);
            CHECK(dev.bindless_index(s.textureView) == kNoBindlessIndex);
        }
        a.join();
        b.join();
        REQUIRE(gfx != nullptr);
        REQUIRE(comp != nullptr);
        CHECK(gfx != comp);
        CHECK(gfx->queue() == QueueKind::Graphics);
        CHECK(comp->queue() == QueueKind::Compute);
        // The join is the happens-before edge; the render thread submits in the order it wants the queues to run.
        const SyncToken t = dev.submit_token(*comp);
        dev.wait_list(*gfx, t);
        dev.submit(*gfx);
        dev.commit();
        INFO(joined(dev.errors()));
        CHECK(dev.errors().empty());
        const auto cmds = dev.commands();
        REQUIRE(cmds.size() == 20 + 1 + 1 + (5 + 40) + 1);
        CHECK(cmds.front().list == "hiz");
        CHECK(cmds[20].kind == CommandKind::Signal);
        CHECK(cmds[21].kind == CommandKind::WaitList);
        CHECK(cmds[22].list == "main");
        CHECK(cmds.back().kind == CommandKind::Commit);
    }
}

TEST_CASE("bindless: Features::bindless gives a texture or storage view a stable index, nothing else has one") {
    {
        RecordingDevice dev;  // the default caps have no table
        Scene s(dev);
        CHECK(dev.bindless_index(s.textureView) == kNoBindlessIndex);
    }
    RecordingDevice probe;
    DeviceInit init;
    init.recordingDefaultCaps = false;
    init.recordingFeatures = probe.features();
    init.recordingFeatures.bindless = true;
    init.recordingLimits = probe.limits();
    RecordingDevice dev(init);
    REQUIRE(dev.features().bindless);
    Scene s(dev);
    const std::uint32_t index = dev.bindless_index(s.textureView);
    CHECK(index != kNoBindlessIndex);
    CHECK(dev.bindless_index(s.textureView) == index);       // never changes for a live view
    CHECK(dev.bindless_index(s.color) == kNoBindlessIndex);  // an attachment is not in the table
    CHECK(dev.bindless_index(View{}) == kNoBindlessIndex);
    ViewDesc tv;
    tv.texture.image = s.texture;
    tv.label = "second";
    const View second = dev.make_view(tv);
    CHECK(dev.bindless_index(second) != kNoBindlessIndex);
    CHECK(dev.bindless_index(second) != index);
    dev.destroy_view(second);
    CHECK(dev.bindless_index(second) == kNoBindlessIndex);  // a destroyed view has no slot
}

TEST_CASE("queues: SokolDevice has one queue, no async compute and no parallel recording") {
    auto& g = fa::test::gfx();
    if (!g.ok) {
        MESSAGE("no GPU here (" << g.error << "): the SokolDevice queue case is skipped");
        return;
    }
    auto made = make_device(built_sokol_backend());
    REQUIRE_MESSAGE(made, (made ? "" : made.error().message));
    Device& dev = *made.value();
    CHECK_FALSE(dev.features().asyncCompute);
    CHECK_FALSE(dev.features().multiThreadRecording);
    CHECK_FALSE(dev.features().bindless);
    CommandList& compute = dev.begin_commands("compute", QueueKind::Compute);
    CHECK(compute.queue() == QueueKind::Graphics);
    const SyncToken a = dev.submit_token(compute);
    CommandList& transfer = dev.begin_commands("transfer", QueueKind::Transfer);
    dev.wait_list(transfer, a);  // a no-op that keeps the order
    dev.wait_queue(QueueKind::Compute, a);
    const SyncToken b = dev.submit_token(transfer);
    CHECK(a.queue == QueueKind::Graphics);
    CHECK(a.value == 1);
    CHECK(b.value == 2);
    CommandList& plain = dev.begin_commands("plain");
    dev.submit(plain);
    CHECK(dev.bindless_index(View{1}) == kNoBindlessIndex);
}
