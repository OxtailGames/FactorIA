// The GPU interface (src/gpu/): the types against sokol's, RecordingDevice's checks and recorded stream (no GPU), the
// factory, and a SokolDevice round trip on the test GPU (skipped without one).
#include <doctest.h>

#include <cstdint>
#include <cstring>
#include <climits>
#include <initializer_list>
#include <string>
#include <thread>
#include <vector>

#include "gpu/device.h"
#include "gpu/recording_device.h"
#include "gpu/sokol_device.h"
#include "gpu_types.h"
#include "render_internal.h"
#include "render_features.h"
#include "shaders/blit.glsl.h"
#include "test_util.h"

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

TEST_CASE("RecordingDevice: readbacks and timers say there is no GPU") {
    RecordingDevice dev;
    std::vector<std::uint8_t> out;
    const auto r = dev.read_buffer(Buffer{}, 0, 4, out);
    REQUIRE(!r);
    CHECK(contains(r.error().message, "no buffer (id 0)"));
    CHECK(contains(r.error().hint, "SokolDevice"));
    CHECK(!dev.request_buffer_read(Buffer{}, 0, 4));
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
