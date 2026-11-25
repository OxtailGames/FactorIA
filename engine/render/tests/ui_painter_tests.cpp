// The 2D painter (fa/render/ui_painter.h) on a RecordingDevice, without a GPU: which sampler a picture is drawn with.
// The call order of a whole frame is in gpu_interface_tests.cpp.
#include "test_util.h"

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "gpu/device.h"
#include "gpu/recording_device.h"
#include "ui_painter_internal.h"

using namespace fa::gpu;

namespace {

// A colour-only window-like target: a pass of RGBA8 with no depth.
struct Target {
    RecordingDevice& dev;
    Image image;
    View view;
    explicit Target(RecordingDevice& d) : dev(d) {
        ImageDesc id;
        id.width = id.height = 32;
        id.usage.colorAttachment = true;
        id.pixelFormat = PixelFormat::Rgba8;
        id.label = "ui target";
        image = dev.make_image(id);
        ViewDesc vd;
        vd.colorAttachment.image = image;
        vd.label = "ui target color";
        view = dev.make_view(vd);
    }
    PassDesc pass() const {
        PassDesc p;
        p.label = "ui";
        p.color = view;
        p.format = TargetFormat{PixelFormat::Rgba8, PixelFormat::None, 1};
        p.colorLoad = LoadAction::Clear;
        return p;
    }
};

}  // namespace

TEST_CASE("UiPainter: a picture whose format the device cannot filter is drawn with the nearest sampler") {
    fa::test::Gfx& g = fa::test::gfx();  // the painter's shader comes from the open context's generated descs
    REQUIRE(g.ok);
    RecordingDevice dev;
    std::string error;
    std::unique_ptr<fa::render::UiPainter> painter = fa::render::make_ui_painter_on(dev, &error);
    REQUIRE_MESSAGE(painter != nullptr, error);
    fa::render::UiPainterImpl& impl = fa::render::UiPainterAccess::impl(*painter);
    REQUIRE(impl.linear.valid());
    REQUIRE(impl.nearest.valid());
    REQUIRE(impl.linear.id != impl.nearest.id);

    const std::vector<std::uint8_t> pixels(4 * 4 * 4, 255);
    const fa::render::UiTexture rgba8 = painter->make_texture(4, 4, pixels.data(), &error);
    REQUIRE(rgba8.valid());
    // The painter's own pictures are RGBA8, which every device filters: smoothed unless the command asks for nearest.
    fa::render::UiDrawCommand cmd;
    cmd.view = rgba8.view;
    CHECK(impl.sampler_for(cmd).id == impl.linear.id);
    cmd.nearest = true;
    CHECK(impl.sampler_for(cmd).id == impl.nearest.id);

    // 32-bit float pictures are not filterable on this device (the recording device describes a desktop GPU, where
    // RGBA32F is not): linear is refused for them, so they are drawn with the nearest sampler whatever the command says.
    REQUIRE_FALSE(dev.pixel_format_caps(PixelFormat::Rgba32F).filter);
    const fa::render::UiTexture other = painter->make_texture(4, 4, pixels.data(), &error);
    REQUIRE(other.valid());
    impl.note_view_format(other.view, PixelFormat::Rgba32F);
    fa::render::UiDrawCommand floatCmd;
    floatCmd.view = other.view;
    floatCmd.nearest = false;
    CHECK(impl.sampler_for(floatCmd).id == impl.nearest.id);
    CHECK(impl.sampler_for(cmd).id == impl.nearest.id);
    cmd.nearest = false;
    CHECK(impl.sampler_for(cmd).id == impl.linear.id);  // the other picture is not affected

    // Told it is a format that filters, it is smoothed again; a destroyed picture forgets the note.
    impl.note_view_format(other.view, PixelFormat::Rgba8);
    CHECK(impl.sampler_for(floatCmd).id == impl.linear.id);
    impl.note_view_format(other.view, PixelFormat::Rgba32F);
    painter->destroy_texture(other);
    CHECK(impl.unfilterableViews.count(other.view) == 0);

    // A frame that draws both: two different bindings, and the device finds nothing wrong.
    const fa::render::UiTexture third = painter->make_texture(4, 4, pixels.data(), &error);
    REQUIRE(third.valid());
    impl.note_view_format(third.view, PixelFormat::Rgba32F);
    fa::render::UiVertex vertices[4];
    for (int i = 0; i < 4; ++i) {
        vertices[i].x = float(i % 2) * 16.0f;
        vertices[i].y = float(i / 2) * 16.0f;
    }
    const std::uint16_t indices[6] = {0, 1, 2, 2, 1, 3};
    // [0] and [1] name the same picture and differ only in the sampler; [2] is another picture, nearest because of its
    // format; [3] asks for nearest on it too, which changes nothing.
    fa::render::UiDrawCommand commands[4];
    commands[0].view = rgba8.view;
    commands[0].clipMaxX = commands[0].clipMaxY = 32.0f;
    commands[0].indexCount = 3;
    commands[1] = commands[0];
    commands[1].nearest = true;
    commands[1].indexOffset = 3;
    commands[2] = commands[0];
    commands[2].view = third.view;  // not nearest in the command, nearest because of its format
    commands[3] = commands[2];
    commands[3].nearest = true;
    fa::render::UiDrawList list;
    list.vertices = vertices;
    list.vertexCount = 4;
    list.indices = indices;
    list.indexCount = 6;
    list.commands = commands;
    list.commandCount = 4;
    fa::render::UiFrame frame;
    frame.displayWidth = frame.displayHeight = 32.0f;
    frame.lists = &list;
    frame.listCount = 1;

    Target target(dev);
    CommandList& cl = dev.begin_commands("ui");
    CHECK(impl.upload(cl, frame, &error));
    cl.begin_pass(target.pass());
    impl.draw(cl, target.pass().format, frame);
    cl.end_pass();
    dev.submit(cl);
    INFO(dev.stream_text());
    CHECK(dev.errors().empty());
    int bindings = 0, draws = 0;
    for (const RecordedCommand& c : dev.commands()) {
        bindings += c.kind == CommandKind::SetBindings ? 1 : 0;
        draws += c.kind == CommandKind::Draw ? 1 : 0;
    }
    // 0 -> 1: the same picture, only the sampler changed, so the bindings are set again; 1 -> 2: another picture;
    // 2 -> 3: the same picture and the same (forced) nearest sampler, so no new bindings.
    CHECK(bindings == 3);
    CHECK(draws == 4);
    painter->destroy_texture(rgba8);
    painter->destroy_texture(third);
}
