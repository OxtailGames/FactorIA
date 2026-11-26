// RecordingDevice: the GPU interface without a GPU (see recording_device.h). The checks follow sokol's validation
// layer where sokol has one (so a call this device accepts is one sokol accepts) and add what the explicit APIs need.
#include "gpu/recording_device.h"

#include <algorithm>
#include <cmath>
#include <climits>
#include <cstdint>
#include <optional>
#include <utility>

namespace fa::gpu {

const char* command_kind_name(CommandKind kind) {
    switch (kind) {
        case CommandKind::BeginPass: return "begin_pass";
        case CommandKind::BeginComputePass: return "begin_compute_pass";
        case CommandKind::EndPass: return "end_pass";
        case CommandKind::SetPipeline: return "set_pipeline";
        case CommandKind::SetBindings: return "set_bindings";
        case CommandKind::SetUniforms: return "set_uniforms";
        case CommandKind::SetViewport: return "set_viewport";
        case CommandKind::SetScissor: return "set_scissor";
        case CommandKind::Draw: return "draw";
        case CommandKind::Dispatch: return "dispatch";
        case CommandKind::WriteBuffer: return "write_buffer";
        case CommandKind::WriteImage: return "write_image";
        case CommandKind::CopyBufferToBuffer: return "copy_buffer_to_buffer";
        case CommandKind::CopyBufferToImage: return "copy_buffer_to_image";
        case CommandKind::PushDebugGroup: return "push_debug_group";
        case CommandKind::PopDebugGroup: return "pop_debug_group";
        case CommandKind::BeginTimedScope: return "begin_timed_scope";
        case CommandKind::EndTimedScope: return "end_timed_scope";
        case CommandKind::Commit: return "commit";
        case CommandKind::ReadImage: return "read_image";
        case CommandKind::ReadBuffer: return "read_buffer";
        case CommandKind::Signal: return "signal";
        case CommandKind::WaitList: return "wait_list";
        case CommandKind::WaitQueue: return "wait_queue";
        case CommandKind::Handoff: return "handoff";
        case CommandKind::BuildBlas: return "build_blas";
        case CommandKind::BuildTlas: return "build_tlas";
        case CommandKind::QueryCompactedSize: return "query_compacted_size";
        case CommandKind::CopyAccelStructure: return "copy_accel_structure";
    }
    return "?";
}

namespace {

std::string quoted(const std::string& s) { return "'" + s + "'"; }
std::string str(const char* s) { return s ? s : ""; }

// Whether [at, at + count) lies inside [0, limit): computed in 64 bits, so a start and a size near INT_MAX cannot wrap
// around into a range that looks valid.
bool span_fits(int at, int count, int limit) {
    return at >= 0 && count > 0 && std::int64_t(at) + std::int64_t(count) <= std::int64_t(limit);
}
// The last index of [at, at + count), for a message (64 bits, as span_fits).
std::string span_last(int at, int count) { return std::to_string(std::int64_t(at) + std::int64_t(count) - 1); }

// The pixel formats of a desktop GPU (D3D11 feature level 11 / GL 4.3 / Metal on Apple silicon, the common subset).
PixelFormatCaps desktop_caps(PixelFormat f, bool compute) {
    PixelFormatCaps c;
    if (f == PixelFormat::Default || f == PixelFormat::None || f >= PixelFormat::Count) return c;
    c.bytesPerPixel = pixel_format_bytes(f);
    if (pixel_format_compressed(f)) {
        c.compressed = true;
        // BC is everywhere on the desktop; ETC2/EAC and ASTC are not (Apple silicon has them, D3D11 does not).
        c.sample = c.filter = f <= PixelFormat::Bc7Srgba;
        return c;
    }
    if (pixel_format_depth(f)) {
        c.sample = c.render = c.msaa = c.depth = true;
        return c;
    }
    const bool integer = pixel_format_integer(f);
    const bool float32 = f == PixelFormat::R32F || f == PixelFormat::Rg32F || f == PixelFormat::Rgba32F;
    c.sample = true;
    c.filter = !integer && !float32;
    c.render = f != PixelFormat::Rgb9E5 && !pixel_format_signed_normalized(f);
    c.blend = c.render && !integer;
    c.msaa = c.render && !integer && !float32;
    if (compute) {
        switch (f) {
            case PixelFormat::Rgba8:
            case PixelFormat::Rgba8Sn:
            case PixelFormat::Rgba8Ui:
            case PixelFormat::Rgba8Si:
            case PixelFormat::Rgba16Ui:
            case PixelFormat::Rgba16Si:
            case PixelFormat::Rgba16F:
            case PixelFormat::R32Ui:
            case PixelFormat::R32Si:
            case PixelFormat::R32F:
            case PixelFormat::Rg32Ui:
            case PixelFormat::Rg32Si:
            case PixelFormat::Rg32F:
            case PixelFormat::Rgba32Ui:
            case PixelFormat::Rgba32Si:
            case PixelFormat::Rgba32F: c.read = c.write = true; break;
            default: break;
        }
    }
    return c;
}

Features desktop_features() {
    Features f;
    f.imageClampToBorder = true;
    f.mrtIndependentBlendState = true;
    f.mrtIndependentWriteMask = true;
    f.compute = true;
    f.msaaTextureBindings = true;
    f.drawBaseVertex = true;
    f.drawBaseInstance = true;
    f.dualSourceBlending = true;
    f.vertexFormatInt10N2 = true;
    f.copyBufferToImageRelaxedBufferType = true;
    f.copyBufferToImageRelaxedBytesPerRow = true;
    f.asyncCompute = true;
    f.multiThreadRecording = true;
    return f;
}

// What DeviceInit::recordingRayTracing adds: a desktop GPU with DXR 1.1 / VK_KHR_ray_query. The limits are the order of
// magnitude of today's GPUs, and far from anything a test builds.
void add_ray_tracing(Features& f, Limits& l) {
    f.rayQuery = true;
    f.accelerationStructure = true;
    f.bufferDeviceAddress = true;
    l.maxAccelInstances = 1u << 20;
    l.maxAccelGeometries = 4096;
    l.maxAccelPrimitives = std::uint64_t(1) << 28;
}

Limits desktop_limits() {
    Limits l;
    l.maxImageSize2d = 16384;
    l.maxImageSizeCube = 16384;
    l.maxImageSize3d = 2048;
    l.maxImageSizeArray = 16384;
    l.maxImageArrayLayers = 2048;
    l.maxVertexAttrs = kMaxVertexAttributes;
    l.maxColorAttachments = kMaxColorAttachments;
    l.maxTextureBindingsPerStage = 16;
    l.maxStorageBufferBindingsPerStage = 8;
    l.maxStorageImageBindingsPerStage = 4;
    return l;
}

// ---- resource pools -------------------------------------------------------------------------------------------------
// A handle is (generation << 16) | slot; slot 0 is never used, so id 0 stays the invalid handle. Destroying a resource
// bumps its slot's generation: the old handle no longer names anything, even after the slot is reused (until the
// generation wraps after 65535 reuses of the same slot).

struct BufferInfo {
    std::size_t size = 0;
    BufferUsage usage{};
    QueueKind owner = QueueKind::Graphics;  // the queue that may use it (QueueHandoff moves it)
    SyncToken handed{};                     // the handoff token the new owner must still wait for (none: settled)
    bool vertex() const {
        return usage.vertexBuffer ||
               (!usage.indexBuffer && !usage.storageBuffer && !usage.stagingBuffer && !usage.stagingIndexBuffer);
    }
};

struct ImageInfo {
    ImageType type = ImageType::Tex2d;
    ImageUsage usage{};
    int width = 0, height = 0, slices = 1, mips = 1, samples = 1;
    PixelFormat format = PixelFormat::Rgba8;
    QueueKind owner = QueueKind::Graphics;  // the queue that may use it (QueueHandoff moves it)
    SyncToken handed{};                     // the handoff token the new owner must still wait for (none: settled)
};

struct ViewInfo {
    ViewType type = ViewType::Invalid;
    std::uint32_t resource = 0;  // the image's or the buffer's id
    PixelFormat format = PixelFormat::None;
    int samples = 1;
};

struct SamplerInfo {
    bool comparison = false;
    bool filtering = false;
};

struct ShaderInfo {
    bool compute = false;
    std::uint32_t uniformSize[kMaxUniformBlocks]{};  // 0 = not declared
    ViewType views[kMaxViews]{};
    ImageSampleType sampleType[kMaxViews]{};
    bool multisampled[kMaxViews]{};
    bool samplerDeclared[kMaxSamplers]{};
    SamplerType samplerType[kMaxSamplers]{};
    bool attrDeclared[kMaxVertexAttributes]{};
    bool accelDeclared[kMaxAccelStructureBindings]{};  // a TLAS slot the kernel traces against
    bool usesRayQuery = false;
};

// An acceleration structure (M79): what the build and bind checks need.
struct AccelInfo {
    AccelKind kind = AccelKind::Blas;
    std::uint64_t size = 0;  // bytes it was made with
    bool built = false;
    bool allowUpdate = false;  // the flags of the build that wrote it
    bool allowCompaction = false;
    std::uint32_t geometries = 0;  // BLAS: what the build had (a refit must match)
    std::uint64_t primitives = 0;
    std::uint32_t instances = 0;  // TLAS
};

struct PipelineInfo {
    std::uint32_t shader = 0;
    std::string shaderLabel;
    ShaderInfo reflection{};
    bool compute = false;
    int colorCount = 1;
    PixelFormat colors[kMaxColorAttachments]{};
    PixelFormat depth = PixelFormat::None;
    int samples = 1;
    IndexType indexType = IndexType::None;
    std::uint32_t vertexBufferMask = 0;
    std::uint32_t requiredUniforms = 0;
    bool needsBindings = false;
};

template <class Info>
struct Pool {
    struct Entry {
        std::uint16_t generation = 1;
        bool alive = false;
        ResourceState state = ResourceState::Invalid;
        std::string label;
        Info info{};
    };

    const char* kind = "";
    std::size_t capacity = 0;
    std::vector<Entry> entries = std::vector<Entry>(1);  // entries[0] is never handed out
    std::vector<std::uint32_t> freeSlots;
    ResourceTotals totals{};

    static std::uint32_t slot_of(std::uint32_t id) { return id & 0xFFFFu; }
    static std::uint16_t generation_of(std::uint32_t id) { return std::uint16_t(id >> 16); }

    // The new resource's id, or 0 when the pool is full.
    std::uint32_t add(const char* label, ResourceState state, Info info) {
        std::uint32_t slot = 0;
        if (!freeSlots.empty()) {
            slot = freeSlots.back();
            freeSlots.pop_back();
        } else {
            if (entries.size() > capacity) return 0;
            slot = std::uint32_t(entries.size());
            entries.emplace_back();
        }
        Entry& e = entries[slot];
        e.alive = true;
        e.state = state;
        e.label = str(label);
        e.info = std::move(info);
        ++totals.allocated;
        ++totals.inited;
        ++totals.alive;
        return (std::uint32_t(e.generation) << 16) | slot;
    }

    // The same, to change the owner of a resource.
    Entry* live(std::uint32_t id) { return const_cast<Entry*>(std::as_const(*this).live(id)); }
    // The live resource `id` names, or nullptr (never made, destroyed, or 0).
    const Entry* live(std::uint32_t id) const {
        const std::uint32_t slot = slot_of(id);
        if (id == 0 || slot == 0 || slot >= entries.size()) return nullptr;
        const Entry& e = entries[slot];
        return e.alive && e.generation == generation_of(id) ? &e : nullptr;
    }

    // "buffer 'vertices'" for a live one; what is wrong with `id` otherwise.
    std::string describe(std::uint32_t id) const {
        if (const Entry* e = live(id)) return std::string(kind) + " " + quoted(e->label);
        const std::uint32_t slot = slot_of(id);
        if (id == 0) return std::string("no ") + kind + " (id 0)";
        if (slot == 0 || slot >= entries.size())
            return std::string("unknown ") + kind + " (id " + std::to_string(id) + ", never made by this device)";
        const Entry& e = entries[slot];
        const auto prev = std::uint16_t(e.generation == 1 ? 0xFFFF : e.generation - 1);
        if (!e.alive && prev == generation_of(id))
            return std::string("destroyed ") + kind + " " + quoted(e.label) + " (id " + std::to_string(id) + ")";
        return std::string("destroyed ") + kind + " (id " + std::to_string(id) + "; its slot was reused since)";
    }

    // Destroys `id`; false when it is not a live resource.
    bool remove(std::uint32_t id) {
        if (!live(id)) return false;
        Entry& e = entries[slot_of(id)];
        e.alive = false;
        e.state = ResourceState::Invalid;
        e.generation = std::uint16_t(e.generation == 0xFFFF ? 1 : e.generation + 1);
        freeSlots.push_back(slot_of(id));
        ++totals.deallocated;
        ++totals.uninited;
        --totals.alive;
        return true;
    }

    ResourceState state(std::uint32_t id) const {
        const Entry* e = live(id);
        return e ? e->state : ResourceState::Invalid;
    }

    ResourceTotals stats() const {
        ResourceTotals t = totals;
        t.free = std::uint32_t(capacity - std::min<std::size_t>(capacity, totals.alive));
        return t;
    }
};

std::size_t clamp_pool(int size) { return std::size_t(std::clamp(size, 1, 0xFFFF)); }

}  // namespace

struct RecordingDevice::State {
    Pool<BufferInfo> buffers;
    Pool<ImageInfo> images;
    Pool<ViewInfo> views;
    Pool<SamplerInfo> samplers;
    Pool<ShaderInfo> shaders;
    Pool<PipelineInfo> pipelines;
    Pool<AccelInfo> accels;
    // What query_compacted_size wrote (buffer id, byte offset, value): read_buffer answers it (the model has no GPU to run the query).
    struct CompactedAnswer {
        std::uint32_t buffer = 0;
        std::size_t offset = 0;
        std::uint64_t value = 0;
    };
    std::vector<CompactedAnswer> compactedAnswers;
    std::vector<RecordedCommand> stream;
    std::vector<std::string> errors;
    std::vector<std::pair<void (*)(void*), void*>> listeners;
    std::uint64_t frames = 0;
    // The label of the last list submitted with commands since the last commit() (a read now would not see its work).
    std::optional<std::string> uncommitted;
    bool statsEnabled = false;
    std::uint64_t issued[kQueueKinds]{};  // the last token handed out per queue
    std::uint64_t queueWaited[kQueueKinds]
                             [kQueueKinds]{};  // [waiting queue][token's queue]: the newest wait_queue() value
};

// ---------------------------------------------------------------------------------------------------------------------
// RecordingDevice
// ---------------------------------------------------------------------------------------------------------------------
RecordingDevice::RecordingDevice(const DeviceInit& init) : state_(std::make_unique<State>()) {
    info_.backend = Backend::Recording;
    info_.name = backend_name(Backend::Recording);
    features_ = init.recordingDefaultCaps ? desktop_features() : init.recordingFeatures;
    limits_ = init.recordingDefaultCaps ? desktop_limits() : init.recordingLimits;
    if (init.recordingDefaultCaps && init.recordingRayTracing) add_ray_tracing(features_, limits_);
    defaults_ = init.environment.defaults;
    if (defaults_.colorFormat == PixelFormat::Default) defaults_.colorFormat = PixelFormat::Rgba8;
    if (defaults_.depthFormat == PixelFormat::Default) defaults_.depthFormat = PixelFormat::DepthStencil;
    if (defaults_.sampleCount <= 0) defaults_.sampleCount = 1;
    State& s = *state_;
    s.buffers.kind = "buffer";
    s.images.kind = "image";
    s.views.kind = "view";
    s.samplers.kind = "sampler";
    s.shaders.kind = "shader";
    s.pipelines.kind = "pipeline";
    s.accels.kind = "acceleration structure";
    s.accels.capacity = clamp_pool(init.bufferPoolSize);
    s.buffers.capacity = clamp_pool(init.bufferPoolSize);
    s.images.capacity = clamp_pool(init.imagePoolSize);
    s.views.capacity = clamp_pool(init.viewPoolSize);
    s.samplers.capacity = clamp_pool(init.samplerPoolSize);
    s.shaders.capacity = clamp_pool(init.shaderPoolSize);
    s.pipelines.capacity = clamp_pool(init.pipelinePoolSize);
}

RecordingDevice::~RecordingDevice() = default;

void RecordingDevice::report_locked(std::string message) { state_->errors.push_back(std::move(message)); }

void RecordingDevice::fail_locked(const char* call, const char* label, const std::string& what,
                                  const std::string& fix) {
    std::string m = std::string("gpu: ") + call;
    if (label && *label) m += " " + quoted(label);
    report_locked(m + ": " + what + ". Fix: " + fix);
}

std::vector<std::string> RecordingDevice::errors() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->errors;
}

std::vector<std::string> RecordingDevice::take_errors() {
    std::lock_guard<std::mutex> lock(mutex_);
    return std::exchange(state_->errors, {});
}

std::vector<RecordedCommand> RecordingDevice::commands() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->stream;
}

std::string RecordingDevice::stream_text() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::string out;
    for (const RecordedCommand& c : state_->stream) {
        out += "frame " + std::to_string(c.frame) + " ";
        if (c.kind != CommandKind::Commit && c.kind != CommandKind::ReadImage && c.kind != CommandKind::ReadBuffer &&
            c.kind != CommandKind::WaitQueue)
            out += "[" + c.list + "] ";
        out += c.text;
        out += '\n';
    }
    return out;
}

void RecordingDevice::clear_commands() {
    std::lock_guard<std::mutex> lock(mutex_);
    state_->stream.clear();
}

PixelFormatCaps RecordingDevice::pixel_format_caps(PixelFormat format) const {
    return desktop_caps(format, features_.compute);
}

// ---- resources ------------------------------------------------------------------------------------------------------
namespace {

// Appends "; " between the problems of one desc.
void add(std::string& what, const std::string& problem) {
    if (!what.empty()) what += "; ";
    what += problem;
}

}  // namespace

void RecordingDevice::fail_next_make_buffer(const std::string& label, int count) {
    std::lock_guard<std::mutex> lock(mutex_);
    failBufferLabel_ = label;
    failBufferCount_ = std::max(0, count);
}

Buffer RecordingDevice::make_buffer(const BufferDesc& d) {
    std::lock_guard<std::mutex> lock(mutex_);
    std::string what;
    if (failBufferCount_ > 0 && (failBufferLabel_.empty() || (d.label && failBufferLabel_ == d.label))) {
        --failBufferCount_;
        add(what, "injected fault (RecordingDevice::fail_next_make_buffer): the device is out of memory");
    }
    if (d.size == 0) add(what, "BufferDesc::size is 0");
    if (d.data.ptr && d.data.size > d.size)
        add(what,
            "BufferDesc::data has " + std::to_string(d.data.size) + " bytes, more than size " + std::to_string(d.size));
    if (d.usage.storageBuffer && !features_.compute)
        add(what, "usage.storageBuffer on a device without compute (Features::compute is false)");
    const int kinds = int(d.usage.vertexBuffer) + int(d.usage.indexBuffer) + int(d.usage.storageBuffer) +
                      int(d.usage.stagingBuffer) + int(d.usage.stagingIndexBuffer);
    if (kinds > 1 && features_.separateBufferTypes)
        add(what, "more than one of vertexBuffer/indexBuffer/storageBuffer/staging on a device with separate buffer "
                  "types (WebGL2)");
    if (d.usage.accelBuildInput || d.usage.accelStorage || d.usage.accelScratch) {
        if (!features_.accelerationStructure)
            add(what, "usage.accelBuildInput, accelStorage or accelScratch on a device without acceleration structures "
                      "(Features::accelerationStructure is false: " +
                          accel_unavailable_reason(Backend::Recording) + ")");
    }
    BufferInfo info{d.size, d.usage};
    const ResourceState st = what.empty() ? ResourceState::Valid : ResourceState::Failed;
    if (!what.empty())
        fail_locked("make_buffer", d.label, what,
                    "give a size above 0, initial data no larger than it, and one buffer kind the device supports");
    const std::uint32_t id = state_->buffers.add(d.label, st, info);
    if (!id)
        fail_locked("make_buffer", d.label,
                    "the buffer pool is full (" + std::to_string(state_->buffers.capacity) + ")",
                    "destroy buffers no longer used, or raise DeviceInit::bufferPoolSize");
    return Buffer{id};
}

Image RecordingDevice::make_image(const ImageDesc& d) {
    std::lock_guard<std::mutex> lock(mutex_);
    ImageInfo info;
    info.type = d.type == ImageType::Default ? ImageType::Tex2d : d.type;
    info.usage = d.usage;
    info.width = d.width;
    info.height = d.height;
    info.slices = d.numSlices > 0 ? d.numSlices : (info.type == ImageType::Cube ? 6 : 1);
    info.mips = d.numMipmaps > 0 ? d.numMipmaps : 1;
    info.samples = d.sampleCount > 0 ? d.sampleCount : 1;
    info.format = d.pixelFormat;
    if (info.format == PixelFormat::Default)
        info.format = d.usage.depthStencilAttachment                           ? defaults_.depthFormat
                      : (d.usage.colorAttachment || d.usage.resolveAttachment) ? defaults_.colorFormat
                                                                               : PixelFormat::Rgba8;
    const PixelFormatCaps caps = pixel_format_caps(info.format);
    const bool attachment = d.usage.colorAttachment || d.usage.resolveAttachment || d.usage.depthStencilAttachment;
    std::string what;
    if (d.width <= 0 || d.height <= 0)
        add(what, "the size is " + std::to_string(d.width) + "x" + std::to_string(d.height));
    const int maxSize = info.type == ImageType::Cube    ? limits_.maxImageSizeCube
                        : info.type == ImageType::Tex3d ? limits_.maxImageSize3d
                        : info.type == ImageType::Array ? limits_.maxImageSizeArray
                                                        : limits_.maxImageSize2d;
    if (maxSize > 0 && (d.width > maxSize || d.height > maxSize))
        add(what, "the size " + std::to_string(d.width) + "x" + std::to_string(d.height) + " is above the limit " +
                      std::to_string(maxSize));
    if (info.mips > kMaxMipmaps) add(what, "numMipmaps " + std::to_string(info.mips) + " is above 16");
    if (info.type == ImageType::Cube && info.slices != 6) add(what, "a cube image has 6 slices");
    if (limits_.maxImageArrayLayers > 0 && info.type == ImageType::Array && info.slices > limits_.maxImageArrayLayers)
        add(what, "numSlices " + std::to_string(info.slices) + " is above the limit " +
                      std::to_string(limits_.maxImageArrayLayers));
    if (info.format == PixelFormat::None || info.format >= PixelFormat::Count)
        add(what, std::string("pixelFormat ") + pixel_format_name(info.format) + " is not an image format");
    if (d.usage.depthStencilAttachment && !pixel_format_depth(info.format))
        add(what,
            std::string("a depth-stencil attachment needs a depth format, not ") + pixel_format_name(info.format));
    if ((d.usage.colorAttachment || d.usage.resolveAttachment) && (!caps.render || caps.depth))
        add(what, std::string("pixelFormat ") + pixel_format_name(info.format) + " cannot be a colour attachment");
    if (d.usage.storageImage && !caps.write)
        add(what, std::string("pixelFormat ") + pixel_format_name(info.format) +
                      " cannot be a storage image on this device (PixelFormatCaps::write)");
    if (info.samples > 1 && !attachment) add(what, "sampleCount above 1 needs an attachment usage");
    if (info.samples > 1 && !caps.msaa)
        add(what, std::string("pixelFormat ") + pixel_format_name(info.format) + " cannot be multisampled");
    if (info.samples > 1 && info.mips > 1) add(what, "a multisampled image has one mip level");
    if (!caps.sample && !attachment && !d.usage.storageImage)
        add(what, std::string("pixelFormat ") + pixel_format_name(info.format) + " cannot be sampled on this device");
    const ResourceState st = what.empty() ? ResourceState::Valid : ResourceState::Failed;
    if (!what.empty())
        fail_locked("make_image", d.label, what,
                    "check the size, the format against Device::pixel_format_caps and the usage flags");
    const std::uint32_t id = state_->images.add(d.label, st, info);
    if (!id)
        fail_locked("make_image", d.label, "the image pool is full (" + std::to_string(state_->images.capacity) + ")",
                    "destroy images no longer used, or raise DeviceInit::imagePoolSize");
    return Image{id};
}

View RecordingDevice::make_view(const ViewDesc& d) {
    std::lock_guard<std::mutex> lock(mutex_);
    State& s = *state_;
    ViewInfo info;
    info.type = d.type();
    std::string what;
    std::string fix = "set exactly one member of ViewDesc to a live resource made with the matching usage";
    if (d.resource_count() != 1) {
        add(what, "ViewDesc names " + std::to_string(d.resource_count()) + " resources; a view names exactly one");
    } else if (info.type == ViewType::StorageBuffer) {
        info.resource = d.storageBuffer.buffer.id;
        const auto* b = s.buffers.live(info.resource);
        if (!b || b->state != ResourceState::Valid)
            add(what, "its buffer is " + s.buffers.describe(info.resource) + (b ? " (Failed)" : ""));
        else if (!b->info.usage.storageBuffer)
            add(what, "buffer " + quoted(b->label) + " was not made with usage.storageBuffer");
        else if (d.storageBuffer.offset < 0 || std::size_t(d.storageBuffer.offset) >= b->info.size)
            add(what, "offset " + std::to_string(d.storageBuffer.offset) + " is outside the buffer (" +
                          std::to_string(b->info.size) + " bytes)");
    } else {
        const ViewDesc::ImageView* iv = info.type == ViewType::StorageImage             ? &d.storageImage
                                        : info.type == ViewType::ColorAttachment        ? &d.colorAttachment
                                        : info.type == ViewType::ResolveAttachment      ? &d.resolveAttachment
                                        : info.type == ViewType::DepthStencilAttachment ? &d.depthStencilAttachment
                                                                                        : nullptr;
        info.resource = iv ? iv->image.id : d.texture.image.id;
        const auto* img = s.images.live(info.resource);
        if (!img || img->state != ResourceState::Valid) {
            add(what, "its image is " + s.images.describe(info.resource) + (img ? " (Failed)" : ""));
        } else {
            const ImageInfo& ii = img->info;
            info.format = ii.format;
            info.samples = ii.samples;
            const char* need = nullptr;
            if (info.type == ViewType::StorageImage && !ii.usage.storageImage) need = "usage.storageImage";
            if (info.type == ViewType::ColorAttachment && !ii.usage.colorAttachment) need = "usage.colorAttachment";
            if (info.type == ViewType::ResolveAttachment && !ii.usage.resolveAttachment)
                need = "usage.resolveAttachment";
            if (info.type == ViewType::DepthStencilAttachment && !ii.usage.depthStencilAttachment)
                need = "usage.depthStencilAttachment";
            if (need) add(what, "image " + quoted(img->label) + " was not made with " + need);
            const int mip = iv ? iv->mipLevel : d.texture.mipLevels.base;
            const int mipCount = iv ? 1 : (d.texture.mipLevels.count > 0 ? d.texture.mipLevels.count : ii.mips - mip);
            if (!span_fits(mip, mipCount, ii.mips))
                add(what, "mip levels " + std::to_string(mip) + ".." + span_last(mip, mipCount) +
                              " are outside image " + quoted(img->label) + " (" + std::to_string(ii.mips) + " levels)");
            const int depthOrSlices = ii.slices;
            const int slice = iv ? iv->slice : d.texture.slices.base;
            const int sliceCount =
                iv ? 1 : (d.texture.slices.count > 0 ? d.texture.slices.count : depthOrSlices - slice);
            if (!span_fits(slice, sliceCount, depthOrSlices))
                add(what, "slices " + std::to_string(slice) + ".." + span_last(slice, sliceCount) +
                              " are outside image " + quoted(img->label) + " (" + std::to_string(depthOrSlices) +
                              " slices)");
            if (info.type == ViewType::ResolveAttachment && ii.samples != 1)
                add(what, "a resolve attachment has one sample, image " + quoted(img->label) + " has " +
                              std::to_string(ii.samples));
        }
    }
    const ResourceState st = what.empty() ? ResourceState::Valid : ResourceState::Failed;
    if (!what.empty()) fail_locked("make_view", d.label, what, fix);
    const std::uint32_t id = s.views.add(d.label, st, info);
    if (!id)
        fail_locked("make_view", d.label, "the view pool is full (" + std::to_string(s.views.capacity) + ")",
                    "destroy views no longer used, or raise DeviceInit::viewPoolSize");
    return View{id};
}

Sampler RecordingDevice::make_sampler(const SamplerDesc& d) {
    std::lock_guard<std::mutex> lock(mutex_);
    SamplerInfo info;
    info.comparison = d.compare != CompareFunc::Default && d.compare != CompareFunc::Never;
    info.filtering = d.minFilter == Filter::Linear || d.magFilter == Filter::Linear || d.mipmapFilter == Filter::Linear;
    std::string what;
    const bool border =
        d.wrapU == Wrap::ClampToBorder || d.wrapV == Wrap::ClampToBorder || d.wrapW == Wrap::ClampToBorder;
    if (border && !features_.imageClampToBorder)
        add(what, "Wrap::ClampToBorder on a device without it (Features::imageClampToBorder is false)");
    if (d.maxAnisotropy > 16) add(what, "maxAnisotropy " + std::to_string(d.maxAnisotropy) + " is above 16");
    if (d.maxLod != 0.0f && d.maxLod < d.minLod) add(what, "maxLod is below minLod");
    const ResourceState st = what.empty() ? ResourceState::Valid : ResourceState::Failed;
    if (!what.empty())
        fail_locked("make_sampler", d.label, what,
                    "use ClampToEdge where the device has no border colour, and "
                    "maxAnisotropy 1..16");
    const std::uint32_t id = state_->samplers.add(d.label, st, info);
    if (!id)
        fail_locked("make_sampler", d.label,
                    "the sampler pool is full (" + std::to_string(state_->samplers.capacity) + ")",
                    "share samplers (they are state only), or raise DeviceInit::samplerPoolSize");
    return Sampler{id};
}

Shader RecordingDevice::make_shader(const ShaderDesc& d) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto present = [](const ShaderFunction& f) { return f.source != nullptr || f.bytecode.ptr != nullptr; };
    ShaderInfo info;
    info.compute = d.compute();
    std::string what;
    if (info.compute && (present(d.vertexFunc) || present(d.fragmentFunc)))
        add(what, "a compute shader has only computeFunc (vertexFunc or fragmentFunc is set too)");
    if (!info.compute && (!present(d.vertexFunc) || !present(d.fragmentFunc)))
        add(what, "a render shader needs vertexFunc and fragmentFunc (source or bytecode)");
    if (info.compute && !features_.compute) add(what, "a compute shader on a device without compute");
    auto stage_ok = [&](ShaderStage st, const std::string& where) {
        if (st == ShaderStage::None) return;
        if (info.compute != (st == ShaderStage::Compute))
            add(what, where + " has stage " + (st == ShaderStage::Compute ? "Compute" : "Vertex/Fragment") +
                          (info.compute ? " in a compute shader" : " in a render shader"));
    };
    for (int i = 0; i < kMaxUniformBlocks; ++i) {
        const ShaderUniformBlock& u = d.uniformBlocks[i];
        if (u.stage == ShaderStage::None) continue;
        stage_ok(u.stage, "uniform block " + std::to_string(i));
        if (u.size == 0) add(what, "uniform block " + std::to_string(i) + " has size 0");
        if (u.layout == UniformLayout::Std140 && u.size % 16 != 0)
            add(what, "uniform block " + std::to_string(i) + " is std140 but its size " + std::to_string(u.size) +
                          " is not a multiple of 16");
        info.uniformSize[i] = u.size;
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const ShaderView& v = d.views[i];
        const int declared = int(v.texture.stage != ShaderStage::None) +
                             int(v.storageBuffer.stage != ShaderStage::None) +
                             int(v.storageImage.stage != ShaderStage::None);
        if (declared > 1) add(what, "view slot " + std::to_string(i) + " declares more than one kind of view");
        stage_ok(v.stage(), "view slot " + std::to_string(i));
        info.views[i] = v.type();
        info.sampleType[i] =
            v.texture.sampleType == ImageSampleType::Default ? ImageSampleType::Float : v.texture.sampleType;
        info.multisampled[i] = v.texture.multisampled;
        if (v.storageImage.stage != ShaderStage::None && !pixel_format_caps(v.storageImage.accessFormat).write)
            add(what, "view slot " + std::to_string(i) + ": storage image format " +
                          pixel_format_name(v.storageImage.accessFormat) + " is not a storage format here");
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const ShaderSampler& m = d.samplers[i];
        if (m.stage == ShaderStage::None) continue;
        stage_ok(m.stage, "sampler slot " + std::to_string(i));
        info.samplerDeclared[i] = true;
        info.samplerType[i] = m.samplerType == SamplerType::Default ? SamplerType::Filtering : m.samplerType;
    }
    for (int i = 0; i < kMaxTextureSamplerPairs; ++i) {
        const ShaderTextureSamplerPair& p = d.textureSamplerPairs[i];
        if (p.stage == ShaderStage::None) continue;
        if (p.viewSlot >= kMaxViews || info.views[p.viewSlot] != ViewType::Texture)
            add(what, "texture-sampler pair " + std::to_string(i) + " names view slot " + std::to_string(p.viewSlot) +
                          ", which is not a texture");
        if (p.samplerSlot >= kMaxSamplers || !info.samplerDeclared[p.samplerSlot])
            add(what, "texture-sampler pair " + std::to_string(i) + " names sampler slot " +
                          std::to_string(p.samplerSlot) + ", which is not declared");
    }
    for (int i = 0; i < kMaxVertexAttributes; ++i)
        info.attrDeclared[i] = d.attrs[i].baseType != ShaderAttrBaseType::Undefined;
    if (d.usesRayQuery) {
        info.usesRayQuery = true;
        if (!info.compute)
            add(what, "usesRayQuery on a render shader: ray queries run in compute shaders (a kernel keeps "
                      "ShaderStage::Compute; there are no ray tracing pipelines)");
        if (!features_.rayQuery)
            add(what, "usesRayQuery on a device without ray query (Features::rayQuery is false: " +
                          accel_unavailable_reason(Backend::Recording) + ")");
    }
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        const ShaderAccelStructure& a = d.accelStructures[i];
        if (a.stage == ShaderStage::None) continue;
        const std::string where = "accelStructures[" + std::to_string(i) + "]";
        if (a.stage != ShaderStage::Compute)
            add(what, where + " has a stage other than Compute: only a compute shader traces rays");
        if (!d.usesRayQuery) add(what, where + " is declared but usesRayQuery is false: set it on a ray-query kernel");
        if (!features_.accelerationStructure)
            add(what,
                where + " on a device without acceleration structures (Features::accelerationStructure is false)");
        info.accelDeclared[i] = true;
    }
    const ResourceState st = what.empty() ? ResourceState::Valid : ResourceState::Failed;
    if (!what.empty())
        fail_locked("make_shader", d.label, what,
                    "use the desc the generated shader header returns (tools/shaders/compile_shaders.sh) unchanged");
    const std::uint32_t id = state_->shaders.add(d.label, st, info);
    if (!id)
        fail_locked("make_shader", d.label,
                    "the shader pool is full (" + std::to_string(state_->shaders.capacity) + ")",
                    "destroy shaders no longer used, or raise DeviceInit::shaderPoolSize");
    return Shader{id};
}

Pipeline RecordingDevice::make_pipeline(const PipelineDesc& d) {
    std::lock_guard<std::mutex> lock(mutex_);
    State& s = *state_;
    PipelineInfo info;
    info.compute = d.compute;
    info.shader = d.shader.id;
    std::string what;
    const auto* shd = s.shaders.live(d.shader.id);
    if (d.compute && rejectCompute_) {
        add(what, "a test made the device refuse compute pipelines (inject_faults)");
    } else if (!shd || shd->state != ResourceState::Valid) {
        add(what, "its shader is " + s.shaders.describe(d.shader.id) + (shd ? " (Failed)" : ""));
    } else {
        info.shaderLabel = shd->label;
        info.reflection = shd->info;
        if (shd->info.compute != d.compute)
            add(what, d.compute
                          ? "PipelineDesc::compute is true but shader " + quoted(shd->label) + " is a render shader"
                          : "shader " + quoted(shd->label) + " is a compute shader; set PipelineDesc::compute");
    }
    for (int i = 0; i < kMaxUniformBlocks; ++i)
        if (info.reflection.uniformSize[i]) info.requiredUniforms |= 1u << i;
    bool anyBinding = false;
    for (int i = 0; i < kMaxViews; ++i) anyBinding |= info.reflection.views[i] != ViewType::Invalid;
    for (int i = 0; i < kMaxSamplers; ++i) anyBinding |= info.reflection.samplerDeclared[i];
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) anyBinding |= info.reflection.accelDeclared[i];
    if (!d.compute) {
        for (int i = 0; i < kMaxVertexAttributes; ++i) {
            const VertexAttr& a = d.layout.attrs[i];
            if (a.format == VertexFormat::Invalid) {
                if (info.reflection.attrDeclared[i])
                    add(what, "the shader reads vertex attribute " + std::to_string(i) +
                                  " but PipelineDesc::layout.attrs[" + std::to_string(i) + "] has no format");
                continue;
            }
            if (a.bufferIndex < 0 || a.bufferIndex >= kMaxVertexBuffers) {
                add(what, "layout.attrs[" + std::to_string(i) + "].bufferIndex " + std::to_string(a.bufferIndex) +
                              " is outside 0..7");
                continue;
            }
            if (limits_.maxVertexAttrs > 0 && i >= limits_.maxVertexAttrs)
                add(what, "vertex attribute " + std::to_string(i) + " is above the limit " +
                              std::to_string(limits_.maxVertexAttrs));
            if ((a.format == VertexFormat::Int10N2 || a.format == VertexFormat::Uint10N2) &&
                !features_.vertexFormatInt10N2)
                add(what, "vertex attribute " + std::to_string(i) + " uses a 10-10-10-2 format the device lacks");
            info.vertexBufferMask |= 1u << a.bufferIndex;
        }
        info.indexType = d.indexType == IndexType::Default ? IndexType::None : d.indexType;
        info.samples = d.sampleCount > 0 ? d.sampleCount : defaults_.sampleCount;
        info.depth = d.depth.pixelFormat == PixelFormat::Default ? defaults_.depthFormat : d.depth.pixelFormat;
        if (info.depth != PixelFormat::None && !pixel_format_depth(info.depth))
            add(what, std::string("depth.pixelFormat ") + pixel_format_name(info.depth) + " is not a depth format");
        if (d.colors[0].pixelFormat == PixelFormat::None)
            info.colorCount = 0;
        else
            info.colorCount = d.colorCount > 0 ? std::min(d.colorCount, kMaxColorAttachments) : 1;
        if (limits_.maxColorAttachments > 0 && info.colorCount > limits_.maxColorAttachments)
            add(what, "colorCount " + std::to_string(info.colorCount) + " is above the limit " +
                          std::to_string(limits_.maxColorAttachments));
        for (int i = 0; i < info.colorCount; ++i) {
            const ColorTargetState& c = d.colors[i];
            info.colors[i] = c.pixelFormat == PixelFormat::Default ? defaults_.colorFormat : c.pixelFormat;
            const PixelFormatCaps caps = pixel_format_caps(info.colors[i]);
            if (!caps.render || caps.depth)
                add(what, "colors[" + std::to_string(i) + "] format " + pixel_format_name(info.colors[i]) +
                              " cannot be a colour attachment");
            else if (c.blend.enabled && !caps.blend)
                add(what, "colors[" + std::to_string(i) + "] blends on " + pixel_format_name(info.colors[i]) +
                              ", which cannot blend");
            if (info.samples > 1 && !caps.msaa)
                add(what, "colors[" + std::to_string(i) + "] format " + pixel_format_name(info.colors[i]) +
                              " cannot be multisampled");
        }
        info.needsBindings = anyBinding || info.vertexBufferMask != 0 || info.indexType != IndexType::None;
    } else {
        info.colorCount = 0;
        info.needsBindings = anyBinding;
    }
    const ResourceState st = what.empty() ? ResourceState::Valid : ResourceState::Failed;
    if (!what.empty())
        fail_locked("make_pipeline", d.label, what,
                    "make the pipeline from a live shader of the same kind, with a vertex layout for every attribute "
                    "the shader reads and formats the device can render to");
    const std::uint32_t id = s.pipelines.add(d.label, st, std::move(info));
    if (!id)
        fail_locked("make_pipeline", d.label,
                    "the pipeline pool is full (" + std::to_string(s.pipelines.capacity) + ")",
                    "cache pipelines by state (Gpu::find_or_make), or raise DeviceInit::pipelinePoolSize");
    return Pipeline{id};
}

namespace {

template <class P>
void destroy_in(RecordingDevice& device, P& pool, std::uint32_t id, const char* call,
                void (RecordingDevice::*fail)(const char*, const char*, const std::string&, const std::string&)) {
    if (id == 0) return;  // destroying the invalid handle does nothing
    const std::string described = pool.describe(id);
    if (!pool.remove(id))
        (device.*fail)(call, nullptr,
                       std::string("it is ") + described +
                           " (a double destroy, or a handle of "
                           "another device)",
                       "destroy each resource once, and set the handle to {} after destroying it");
}

}  // namespace

void RecordingDevice::destroy_buffer(Buffer b) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->buffers, b.id, "destroy_buffer", &RecordingDevice::fail_locked);
}
void RecordingDevice::destroy_image(Image i) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->images, i.id, "destroy_image", &RecordingDevice::fail_locked);
}
void RecordingDevice::destroy_view(View v) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->views, v.id, "destroy_view", &RecordingDevice::fail_locked);
}
void RecordingDevice::destroy_sampler(Sampler s) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->samplers, s.id, "destroy_sampler", &RecordingDevice::fail_locked);
}
void RecordingDevice::destroy_shader(Shader s) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->shaders, s.id, "destroy_shader", &RecordingDevice::fail_locked);
}
void RecordingDevice::destroy_pipeline(Pipeline p) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->pipelines, p.id, "destroy_pipeline", &RecordingDevice::fail_locked);
}

ResourceState RecordingDevice::state(Buffer b) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->buffers.state(b.id);
}
ResourceState RecordingDevice::state(Image i) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->images.state(i.id);
}
ResourceState RecordingDevice::state(View v) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->views.state(v.id);
}
ResourceState RecordingDevice::state(Sampler s) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->samplers.state(s.id);
}
ResourceState RecordingDevice::state(Shader s) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->shaders.state(s.id);
}
ResourceState RecordingDevice::state(Pipeline p) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->pipelines.state(p.id);
}

// ---- the frame ------------------------------------------------------------------------------------------------------
CommandList& RecordingDevice::begin_commands(const char* label) { return begin_commands(label, QueueKind::Graphics); }

QueueKind RecordingDevice::resolve_queue(QueueKind asked) const {
    return features_.asyncCompute && std::size_t(asked) < std::size_t(kQueueKinds) ? asked : QueueKind::Graphics;
}

CommandList& RecordingDevice::begin_commands(const char* label, QueueKind queue) {
    std::lock_guard<std::mutex> lock(mutex_);
    const QueueKind resolved = resolve_queue(queue);
    for (auto& l : lists_) {
        if (!l->open_) {
            l->reset(label, resolved);
            return *l;
        }
    }
    lists_.push_back(std::make_unique<RecordingCommandList>(*this));
    lists_.back()->reset(label, resolved);
    return *lists_.back();
}

void RecordingDevice::submit(CommandList& list) {
    std::lock_guard<std::mutex> lock(mutex_);
    submit_locked(list, false, {});
}

SyncToken RecordingDevice::submit_token(CommandList& list, std::span<const QueueHandoff> handoffs) {
    std::lock_guard<std::mutex> lock(mutex_);
    return submit_locked(list, true, handoffs);
}

SyncToken RecordingDevice::submit_locked(CommandList& list, bool signal, std::span<const QueueHandoff> handoffs) {
    RecordingCommandList* mine = nullptr;
    for (auto& l : lists_)
        if (l.get() == &list) mine = l.get();
    if (!mine) {
        fail_locked("submit", nullptr, "the command list is not one of this device's",
                    "submit a list to the device whose begin_commands() returned it");
        return {};
    }
    if (!mine->open_) {
        fail_locked("submit", mine->label_.c_str(), "the list was submitted already",
                    "call begin_commands() for a new list each time; a list is not used after submit()");
        return {};
    }
    if (mine->passState_ != PassState::None)
        fail_locked("submit", mine->label_.c_str(), "pass " + quoted(mine->passLabel_) + " is still open",
                    "end_pass() before submit()");
    if (mine->debugDepth_ != 0)
        fail_locked("submit", mine->label_.c_str(),
                    std::to_string(mine->debugDepth_) + " debug group(s) are still open",
                    "pop_debug_group() once for every push_debug_group() of the list");
    if (mine->timedScopeOpen_)
        fail_locked("submit", mine->label_.c_str(), "a timed scope is still open", "end_timed_scope() before submit()");
    if (!mine->commands_.empty()) state_->uncommitted = mine->label_;
    if (features_.asyncCompute) check_uses_locked(*mine);
    for (RecordedCommand& c : mine->waits_) {
        c.frame = state_->frames;
        state_->stream.push_back(std::move(c));
    }
    for (RecordedCommand& c : mine->commands_) {
        c.frame = state_->frames;
        state_->stream.push_back(std::move(c));
    }
    SyncToken token;
    if (signal) {
        token.queue = mine->queue_;
        token.value = ++state_->issued[int(mine->queue_)];
        if (features_.asyncCompute) apply_handoffs_locked(*mine, token, handoffs);
        RecordedCommand c;
        c.kind = CommandKind::Signal;
        c.frame = state_->frames;
        c.list = mine->label_;
        c.queue = mine->queue_;
        c.args[0] = int(token.queue);
        c.args[1] = int(std::min<std::uint64_t>(token.value, INT_MAX));
        c.text = std::string("signal ") + queue_name(token.queue) + " " + std::to_string(token.value);
        state_->stream.push_back(std::move(c));
    }
    mine->commands_.clear();
    mine->waits_.clear();
    mine->waitTokens_.clear();
    mine->uses_.clear();
    mine->open_ = false;
    return token;
}

void RecordingDevice::check_uses_locked(RecordingCommandList& list) {
    auto check = [&](const char* kind, QueueKind& owner, SyncToken& handed, const std::string& label) {
        const std::string what = std::string(kind) + " " + quoted(label);
        if (owner != list.queue_) {
            fail_locked("submit", list.label_.c_str(),
                        what + " belongs to the " + queue_name(owner) + " queue, but the list runs on the " +
                            queue_name(list.queue_) + " queue",
                        std::string("hand it over first: submit_token(<a list of the ") + queue_name(owner) +
                            " queue>, {QueueHandoff{" + kind + ", to = QueueKind::" +
                            (list.queue_ == QueueKind::Compute    ? "Compute"
                             : list.queue_ == QueueKind::Transfer ? "Transfer"
                                                                  : "Graphics") +
                            "}}), then wait_list() for that token before this list uses it");
            return;
        }
        if (!handed.valid()) return;
        bool waited = state_->queueWaited[int(list.queue_)][int(handed.queue)] >= handed.value;
        for (const SyncToken& t : list.waitTokens_)
            waited = waited || (t.queue == handed.queue && t.value >= handed.value);
        if (!waited) {
            fail_locked("submit", list.label_.c_str(),
                        what + " was handed to the " + queue_name(owner) + " queue by token (" +
                            queue_name(handed.queue) + " " + std::to_string(handed.value) +
                            ") and the list did not wait for it",
                        "wait_list(list, token) with the token submit_token() returned for the handoff (or "
                        "wait_queue() before this submit), then use the resource");
            return;
        }
        handed = {};  // settled: the owner queue's order covers every later list
    };
    for (const RecordingCommandList::Use& u : list.uses_) {
        if (u.image) {
            if (auto* e = state_->images.live(u.id)) check("image", e->info.owner, e->info.handed, e->label);
        } else if (auto* e = state_->buffers.live(u.id)) {
            check("buffer", e->info.owner, e->info.handed, e->label);
        }
    }
}

void RecordingDevice::apply_handoffs_locked(RecordingCommandList& list, SyncToken token,
                                            std::span<const QueueHandoff> handoffs) {
    for (const QueueHandoff& h : handoffs) {
        const char* call = "submit_token";
        if ((h.image.id != 0) == (h.buffer.id != 0)) {
            fail_locked(call, list.label_.c_str(), "a QueueHandoff must name exactly one image or one buffer",
                        "set QueueHandoff::image or QueueHandoff::buffer, not both and not neither");
            continue;
        }
        if (std::size_t(h.to) >= std::size_t(kQueueKinds)) {
            fail_locked(call, list.label_.c_str(), "a QueueHandoff names a queue that does not exist",
                        "set QueueHandoff::to to Graphics, Compute or Transfer");
            continue;
        }
        const QueueKind to = resolve_queue(h.to);
        QueueKind* owner = nullptr;
        SyncToken* handed = nullptr;
        std::string what;
        std::uint32_t id = h.image.id ? h.image.id : h.buffer.id;
        if (h.image.id) {
            auto* e = state_->images.live(h.image.id);
            if (e)
                owner = &e->info.owner, handed = &e->info.handed, what = "image " + quoted(e->label);
            else
                what = state_->images.describe(h.image.id);
        } else {
            auto* e = state_->buffers.live(h.buffer.id);
            if (e)
                owner = &e->info.owner, handed = &e->info.handed, what = "buffer " + quoted(e->label);
            else
                what = state_->buffers.describe(h.buffer.id);
        }
        if (!owner) {
            fail_locked(call, list.label_.c_str(), "the handoff names " + what, "hand over a live resource");
            continue;
        }
        if (*owner != list.queue_) {
            fail_locked(call, list.label_.c_str(),
                        what + " belongs to the " + queue_name(*owner) + " queue, not to the " +
                            queue_name(list.queue_) + " queue of this list, so this list cannot hand it over",
                        "submit the handoff from a list of the queue that owns the resource");
            continue;
        }
        if (to == *owner) continue;  // already there: nothing to hand over
        RecordedCommand c;
        c.kind = CommandKind::Handoff;
        c.frame = state_->frames;
        c.list = list.label_;
        c.queue = list.queue_;
        c.id = id;
        c.args[0] = int(*owner);
        c.args[1] = int(to);
        c.args[2] = int(std::min<std::uint64_t>(token.value, INT_MAX));
        c.text = "handoff " + what + " " + queue_name(*owner) + " -> " + queue_name(to) + " (token " +
                 queue_name(token.queue) + " " + std::to_string(token.value) + ")";
        state_->stream.push_back(std::move(c));
        *owner = to;
        *handed = token;
    }
}

bool RecordingDevice::check_token_locked(const char* call, const char* label, SyncToken token) {
    if (std::size_t(token.queue) >= std::size_t(kQueueKinds)) {
        fail_locked(call, label, "the sync token names a queue that does not exist",
                    "pass the token submit_token() returned, unchanged");
        return false;
    }
    if (token.value > state_->issued[int(token.queue)]) {
        fail_locked(call, label,
                    std::string("the sync token (") + queue_name(token.queue) + " " + std::to_string(token.value) +
                        ") was never returned by submit_token() (the last one is " +
                        std::to_string(state_->issued[int(token.queue)]) + ")",
                    "a wait can only name work already submitted with submit_token(): signal the producer's list "
                    "first, then record the wait");
        return false;
    }
    return true;
}

void RecordingDevice::wait_list(CommandList& list, SyncToken token) {
    std::lock_guard<std::mutex> lock(mutex_);
    RecordingCommandList* mine = nullptr;
    for (auto& l : lists_)
        if (l.get() == &list) mine = l.get();
    if (!mine || !mine->open_) {
        fail_locked("wait_list", mine ? mine->label_.c_str() : nullptr,
                    mine ? "the list was submitted already" : "the command list is not one of this device's",
                    "wait before submit(), on a list begin_commands() returned");
        return;
    }
    if (!token.valid() || !check_token_locked("wait_list", mine->label_.c_str(), token)) return;
    RecordedCommand c;
    c.kind = CommandKind::WaitList;
    c.list = mine->label_;
    c.queue = mine->queue_;
    c.args[0] = int(token.queue);
    c.args[1] = int(std::min<std::uint64_t>(token.value, INT_MAX));
    c.text = std::string("wait_list ") + queue_name(token.queue) + " " + std::to_string(token.value);
    if (token.queue == mine->queue_) c.text += " (same queue: no wait)";
    mine->waits_.push_back(std::move(c));
    mine->waitTokens_.push_back(token);
}

void RecordingDevice::wait_queue(QueueKind queue, SyncToken token) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!token.valid() || !check_token_locked("wait_queue", nullptr, token)) return;
    const QueueKind resolved = resolve_queue(queue);
    RecordedCommand c;
    c.kind = CommandKind::WaitQueue;
    c.frame = state_->frames;
    c.queue = resolved;
    c.args[0] = int(token.queue);
    c.args[1] = int(std::min<std::uint64_t>(token.value, INT_MAX));
    c.text = std::string("wait_queue ") + queue_name(resolved) + " <- " + queue_name(token.queue) + " " +
             std::to_string(token.value);
    if (token.queue == resolved) c.text += " (same queue: no wait)";
    state_->stream.push_back(std::move(c));
    std::uint64_t& waited = state_->queueWaited[int(resolved)][int(token.queue)];
    waited = std::max(waited, token.value);
}

std::uint32_t RecordingDevice::bindless_index(View view) const {
    if (!features_.bindless) return kNoBindlessIndex;
    std::lock_guard<std::mutex> lock(mutex_);
    const auto* e = state_->views.live(view.id);
    if (!e || e->state != ResourceState::Valid) return kNoBindlessIndex;
    if (e->info.type != ViewType::Texture && e->info.type != ViewType::StorageImage &&
        e->info.type != ViewType::StorageBuffer)
        return kNoBindlessIndex;
    return Pool<ViewInfo>::slot_of(view.id) - 1;
}

void RecordingDevice::commit() {
    std::vector<std::pair<void (*)(void*), void*>> listeners;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        for (auto& l : lists_)
            if (l->open_)
                fail_locked("commit", nullptr, "command list " + quoted(l->label_) + " was not submitted",
                            "submit() every list of the frame before commit()");
        RecordedCommand c;
        c.kind = CommandKind::Commit;
        c.frame = state_->frames;
        c.text = "commit";
        state_->stream.push_back(std::move(c));
        ++state_->frames;
        state_->uncommitted.reset();
        listeners = state_->listeners;
    }
    // Outside the lock: a listener may call the device.
    for (const auto& [func, user] : listeners) func(user);
}

std::uint64_t RecordingDevice::frame_index() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->frames;
}

bool RecordingDevice::add_commit_listener(void (*func)(void* user), void* user) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!func) return false;
    for (const auto& l : state_->listeners)
        if (l.first == func && l.second == user) return false;
    state_->listeners.emplace_back(func, user);
    return true;
}

bool RecordingDevice::remove_commit_listener(void (*func)(void* user), void* user) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto& ls = state_->listeners;
    const auto it = std::find(ls.begin(), ls.end(), std::make_pair(func, user));
    if (it == ls.end()) return false;
    ls.erase(it);
    return true;
}

void RecordingDevice::enable_stats(bool on) {
    std::lock_guard<std::mutex> lock(mutex_);
    state_->statsEnabled = on;
}

bool RecordingDevice::stats_enabled() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->statsEnabled;
}

TotalStats RecordingDevice::total_stats() const {
    std::lock_guard<std::mutex> lock(mutex_);
    TotalStats t;
    t.buffers = state_->buffers.stats();
    t.images = state_->images.stats();
    t.samplers = state_->samplers.stats();
    t.views = state_->views.stats();
    t.shaders = state_->shaders.stats();
    t.pipelines = state_->pipelines.stats();
    return t;
}

bool RecordingDevice::timer_supported(std::string* why) const {
    if (why) *why = "the recording device has no GPU to time (it checks and records the commands only)";
    return false;
}

// ---- readbacks ------------------------------------------------------------------------------------------------------
// The reads a real device would accept answer zeros (there is no GPU memory) and are recorded; the ones it would refuse
// fail with the same teaching error on every run.
namespace {

Error refused(const char* call, const std::string& what, const std::string& fix) {
    return make_error(std::string("gpu: ") + call + ": " + what, fix);
}

int clamp_int(std::size_t v) { return int(std::min<std::size_t>(v, std::size_t(INT_MAX))); }

bool storage_format(PixelFormat f) {
    return f == PixelFormat::Rgba8 || f == PixelFormat::Rgba16F || f == PixelFormat::R32F || f == PixelFormat::Rgba32F;
}

}  // namespace

void RecordingDevice::check_committed_locked(const char* call) {
    if (state_->uncommitted) {
        fail_locked(call, nullptr,
                    "command list " + quoted(*state_->uncommitted) +
                        " was submitted but not committed: a GPU would not have run it yet, so the read would see the "
                        "contents from before it",
                    "commit() after the last submit() and before the read (the read waits for the committed work)");
        return;
    }
    for (const auto& l : lists_)
        if (l->open_ && !l->commands_.empty()) {
            fail_locked(call, nullptr,
                        "command list " + quoted(l->label_) +
                            " is still recording: its work is not on "
                            "the GPU yet",
                        "submit() the list and commit() before the read");
            return;
        }
}

Result<void> RecordingDevice::read_image_locked(const char* call, Image image, PixelFormat format, bool storage, int x,
                                                int y, int width, int height) {
    State& s = *state_;
    const auto* e = s.images.live(image.id);
    const std::string name = s.images.describe(image.id);
    if (!e || e->state != ResourceState::Valid)
        return refused(call, "the image is " + name + (e ? " (Failed)" : ""), "read back a live image of this device");
    const ImageInfo& info = e->info;
    if (info.type != ImageType::Tex2d)
        return refused(call, name + " is not a 2D image", "read back a 2D image (attachment or storage image)");
    if (info.samples > 1)
        return refused(call, name + " is multisampled (" + std::to_string(info.samples) + " samples)",
                       "read the single-sample image it resolves into");
    if (storage) {
        if (!features_.compute)
            return refused(call, "this device has no storage images (features().compute is false)",
                           "read storage images only where Features::compute is true (not on GLES3 or WebGL2)");
        if (!info.usage.storageImage)
            return refused(call, name + " is not a storage image",
                           "make it with usage.storageImage, or read an attachment with read_image_rgba8 / "
                           "read_image_rgba16f");
        if (format != info.format || pixel_format_bytes(format) <= 0)
            return refused(call,
                           std::string("the format ") + pixel_format_name(format) + " is not the image's own (" +
                               pixel_format_name(info.format) + ")",
                           std::string("pass the image's format, ") + pixel_format_name(info.format));
    } else if (format == PixelFormat::None) {  // read_image_rgba8
        if (info.format != PixelFormat::Rgba8 && info.format != PixelFormat::Srgb8A8)
            return refused(call, name + " is " + pixel_format_name(info.format) + ", not RGBA8",
                           info.format == PixelFormat::Rgba16F ? "read it with read_image_rgba16f"
                                                               : "read an RGBA8 (or SRGB8A8) image with it");
    } else if (info.format != format) {  // read_image_rgba16f
        return refused(call, name + " is " + pixel_format_name(info.format) + ", not " + pixel_format_name(format),
                       info.format == PixelFormat::Rgba8 || info.format == PixelFormat::Srgb8A8
                           ? "read it with read_image_rgba8"
                           : "read an RGBA16F image with it");
    }
    if (!span_fits(x, width, info.width) || !span_fits(y, height, info.height))
        return refused(call,
                       "the rectangle at (" + std::to_string(x) + ", " + std::to_string(y) + ") of " +
                           std::to_string(width) + "x" + std::to_string(height) + " is not inside " + name + " (" +
                           std::to_string(info.width) + "x" + std::to_string(info.height) + ")",
                       "read a rectangle of at least 1x1 inside the image");
    check_committed_locked(call);
    RecordedCommand c;
    c.kind = CommandKind::ReadImage;
    c.frame = s.frames;
    c.id = image.id;
    c.args[0] = x;
    c.args[1] = y;
    c.args[2] = width;
    c.args[3] = height;
    c.text = std::string(call) + " " + name + " " + std::to_string(x) + " " + std::to_string(y) + " " +
             std::to_string(width) + "x" + std::to_string(height);
    s.stream.push_back(std::move(c));
    return {};
}

Result<void> RecordingDevice::read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    Result<void> r = read_image_locked("read_image_rgba8", image, PixelFormat::None, false, 0, 0, width, height);
    if (!r.ok()) return r;
    out.assign(std::size_t(width) * std::size_t(height) * 4u, std::uint8_t(0));
    return {};
}

Result<void> RecordingDevice::read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    Result<void> r = read_image_locked("read_image_rgba16f", image, PixelFormat::Rgba16F, false, 0, 0, width, height);
    if (!r.ok()) return r;
    out.assign(std::size_t(width) * std::size_t(height) * 4u, 0.0f);
    return {};
}

Result<void> RecordingDevice::read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                                 std::vector<std::uint8_t>& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    Result<void> r = read_image_locked("read_storage_image", image, format, true, x, y, width, height);
    if (!r.ok()) return r;
    out.assign(std::size_t(width) * std::size_t(height) * std::size_t(pixel_format_bytes(format)), std::uint8_t(0));
    return {};
}

Result<void> RecordingDevice::read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                                          std::vector<std::uint8_t>& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    const char* call = "read_buffer";
    State& s = *state_;
    const auto* e = s.buffers.live(buffer.id);
    const std::string name = s.buffers.describe(buffer.id);
    if (!e || e->state != ResourceState::Valid)
        return refused(call, "the buffer is " + name + (e ? " (Failed)" : ""),
                       "read back a live storage buffer of this device");
    if (!features_.compute)
        return refused(call, "this device has no storage buffers (features().compute is false)",
                       "read buffers only where Features::compute is true (not on GLES3 or WebGL2)");
    if (!e->info.usage.storageBuffer)
        return refused(call, name + " is not a storage buffer",
                       "make it with usage.storageBuffer: only those are read");
    if (offset > e->info.size || bytes > e->info.size - offset)
        return refused(call,
                       "offset " + std::to_string(offset) + " + bytes " + std::to_string(bytes) +
                           " is past the end of " + name + " (" + std::to_string(e->info.size) + " bytes)",
                       "read a range inside the buffer");
    check_committed_locked(call);
    RecordedCommand c;
    c.kind = CommandKind::ReadBuffer;
    c.frame = s.frames;
    c.id = buffer.id;
    c.args[0] = clamp_int(offset);
    c.args[1] = clamp_int(bytes);
    c.text = std::string(call) + " " + name + " " + std::to_string(offset) + " " + std::to_string(bytes);
    s.stream.push_back(std::move(c));
    out.assign(bytes, std::uint8_t(0));
    for (const State::CompactedAnswer& ans : s.compactedAnswers)  // what query_compacted_size wrote into this range
        if (ans.buffer == buffer.id && ans.offset >= offset && ans.offset + 8 <= offset + bytes)
            for (int i = 0; i < 8; ++i) out[ans.offset - offset + std::size_t(i)] = std::uint8_t(ans.value >> (8 * i));
    return {};
}

bool RecordingDevice::storage_image_loadable(PixelFormat format, std::string* why) const {
    if (why) why->clear();
    if (!features_.compute) {
        if (why)
            *why = "the recording device was made without compute (features().compute is false): no storage images";
        return false;
    }
    if (storage_format(format)) return true;
    if (why)
        *why =
            std::string(pixel_format_name(format)) + " is not a storage image format (RGBA8, RGBA16F, R32F, RGBA32F)";
    return false;
}

Result<ReadTicket> RecordingDevice::request_buffer_read(Buffer buffer, std::size_t, std::size_t) {
    std::lock_guard<std::mutex> lock(mutex_);
    return refused("request_buffer_read",
                   state_->buffers.describe(buffer.id) +
                       " cannot be read in the background: the recording device has no frames in flight "
                       "(async_read_supported() is false)",
                   "read it with read_buffer() (a deterministic answer of zeros), or on a SokolDevice "
                   "(make_device(built_sokol_backend()))");
}

// ---------------------------------------------------------------------------------------------------------------------
// RecordingCommandList. Every method holds the device's mutex: the resource tables are shared by all lists.
// ---------------------------------------------------------------------------------------------------------------------
namespace {

const char* pass_state_name(PassState s) {
    switch (s) {
        case PassState::None: return "outside a pass";
        case PassState::Render: return "inside a render pass";
        case PassState::Compute: return "inside a compute pass";
    }
    return "?";
}

std::string format_text(const TargetFormat& f) {
    std::string t = std::string("color=") + pixel_format_name(f.color);
    if (f.color1 != PixelFormat::None) t += std::string(" color1=") + pixel_format_name(f.color1);
    t += std::string(" depth=") + pixel_format_name(f.depth) + " samples=" + std::to_string(f.samples);
    return t;
}

}  // namespace

void RecordingCommandList::reset(const char* label, QueueKind onQueue) {
    label_ = str(label);
    open_ = true;
    queue_ = onQueue;
    commands_.clear();
    waits_.clear();
    waitTokens_.clear();
    uses_.clear();
    passState_ = PassState::None;
    passLabel_.clear();
    passFormat_ = {};
    pipeline_ = {};
    bindingsApplied_ = false;
    uniformsApplied_ = 0;
    debugDepth_ = 0;
    timedScopeOpen_ = false;
}

void RecordingCommandList::use_buffer(Buffer buffer) {
    if (!buffer.id) return;
    for (const Use& u : uses_)
        if (!u.image && u.id == buffer.id) return;
    uses_.push_back(Use{false, buffer.id});
}

void RecordingCommandList::use_image(Image image) {
    if (!image.id) return;
    for (const Use& u : uses_)
        if (u.image && u.id == image.id) return;
    uses_.push_back(Use{true, image.id});
}

void RecordingCommandList::use_view(View view) {
    const auto* e = device_.state_->views.live(view.id);
    if (!e) return;
    if (e->info.type == ViewType::StorageBuffer)
        use_buffer(Buffer{e->info.resource});
    else
        use_image(Image{e->info.resource});
}

void RecordingCommandList::record(CommandKind kind, std::uint32_t id, std::initializer_list<int> args,
                                  std::string text) {
    RecordedCommand c;
    c.kind = kind;
    c.list = label_;
    c.queue = queue_;
    c.id = id;
    int i = 0;
    for (int a : args)
        if (i < 5) c.args[i++] = a;
    c.text = std::move(text);
    commands_.push_back(std::move(c));
}

void RecordingCommandList::fail(const char* command, const std::string& what, const std::string& fix) {
    std::string m =
        "gpu: list " + quoted(label_) + ", command #" + std::to_string(commands_.size()) + " (" + command + ")";
    if (passState_ != PassState::None) m += " in pass " + quoted(passLabel_);
    if (!open_) m += " after submit()";
    device_.report_locked(m + ": " + what + ". Fix: " + fix);
}

bool RecordingCommandList::require_pass(const char* command, PassState want) {
    if (passState_ == want) return true;
    const char* need = want == PassState::None     ? "outside a pass"
                       : want == PassState::Render ? "inside a render pass (begin_pass)"
                                                   : "inside a compute pass (begin_compute_pass)";
    fail(command, std::string("called ") + pass_state_name(passState_) + "; it goes " + need,
         want == PassState::None
             ? "end_pass() first, or record it before begin_pass()"
             : std::string("record it between ") +
                   (want == PassState::Render ? "begin_pass()" : "begin_compute_pass()") + " and end_pass()");
    return false;
}

bool RecordingCommandList::require_pipeline(const char* command) {
    if (pipeline_.id) return true;
    fail(command, "no pipeline is set in this pass", "set_pipeline() first (a pass starts with none)");
    return false;
}

void RecordingCommandList::check_ready_to_run(const char* command) {
    if (pipeline_.needsBindings && !bindingsApplied_)
        fail(command,
             "pipeline " + quoted(pipeline_.label) +
                 " reads buffers, views or samplers, and set_bindings() "
                 "was not called after set_pipeline()",
             "call set_bindings() after every set_pipeline()");
    const std::uint32_t missing = pipeline_.requiredUniforms & ~uniformsApplied_;
    if (missing) {
        std::string slots;
        for (int i = 0; i < kMaxUniformBlocks; ++i)
            if (missing & (1u << i)) slots += (slots.empty() ? "" : ", ") + std::to_string(i);
        fail(command,
             "uniform block(s) " + slots + " of pipeline " + quoted(pipeline_.label) +
                 " were not set after set_pipeline()",
             "call set_uniforms() for every uniform block the shader declares, after every set_pipeline()");
    }
}

void RecordingCommandList::begin_pass(const PassDesc& p) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "begin_pass";
    if (queue_ != QueueKind::Graphics)
        fail(cmd, std::string("the list runs on the ") + queue_name(queue_) + " queue, which has no render passes",
             "record render passes on a QueueKind::Graphics list");
    if (passState_ != PassState::None) {
        fail(cmd, "pass " + quoted(passLabel_) + " is still open; passes do not nest",
             "end_pass() before the next begin_pass()");
    }
    const bool attachments = p.color.id || p.color1.id || p.resolve.id || p.depth.id;
    use_view(p.color);
    use_view(p.color1);
    use_view(p.resolve);
    use_view(p.depth);
    if (p.swapchain && attachments)
        fail(cmd, "the pass names both the swapchain and attachments",
             "a pass draws into the window (swapchain) or into views, not both");
    if (!p.swapchain && !attachments)
        fail(cmd, "the pass has no swapchain and no attachment", "set PassDesc::swapchain or the attachment views");
    if (p.color1.id && !p.color.id)
        fail(cmd, "colour attachment 1 is set without colour attachment 0", "set PassDesc::color first");
    auto check = [&](View v, ViewType want, const char* field, PixelFormat expect, bool checkSamples) {
        if (!v.id) return;
        const auto* e = s.views.live(v.id);
        if (!e || e->state != ResourceState::Valid) {
            fail(cmd, std::string("PassDesc::") + field + " is " + s.views.describe(v.id) + (e ? " (Failed)" : ""),
                 "make the attachment views again after the images change (Gpu::resize does)");
            return;
        }
        if (e->info.type != want) {
            fail(cmd, std::string("PassDesc::") + field + " is view " + quoted(e->label) + " of the wrong kind",
                 std::string("make it with ViewDesc::") + (want == ViewType::ColorAttachment ? "colorAttachment"
                                                           : want == ViewType::ResolveAttachment
                                                               ? "resolveAttachment"
                                                               : "depthStencilAttachment"));
            return;
        }
        if (!s.images.live(e->info.resource)) {
            fail(cmd,
                 std::string("PassDesc::") + field + " is view " + quoted(e->label) + " of " +
                     s.images.describe(e->info.resource),
                 "destroy a view with its image, and make it again with the new image");
            return;
        }
        if (e->info.format != expect)
            fail(cmd,
                 std::string("PassDesc::format says ") + pixel_format_name(expect) + " for " + field + " but view " +
                     quoted(e->label) + " is " + pixel_format_name(e->info.format),
                 "fill PassDesc::format from the attachments (render::make_pass_desc does)");
        if (checkSamples && e->info.samples != p.format.samples)
            fail(cmd,
                 "PassDesc::format.samples is " + std::to_string(p.format.samples) + " but view " + quoted(e->label) +
                     " has " + std::to_string(e->info.samples),
                 "set PassDesc::format.samples to the attachments' sample count");
    };
    check(p.color, ViewType::ColorAttachment, "color", p.format.color, true);
    check(p.color1, ViewType::ColorAttachment, "color1", p.format.color1, true);
    check(p.depth, ViewType::DepthStencilAttachment, "depth", p.format.depth, true);
    if (p.resolve.id) {
        if (p.format.samples <= 1)
            fail(cmd, "a resolve attachment is set on a pass with one sample",
                 "resolve only a multisampled pass (PassDesc::format.samples above 1)");
        check(p.resolve, ViewType::ResolveAttachment, "resolve", p.format.color, false);
    }
    if (p.swapchain && p.format.color == PixelFormat::None && p.format.depth == PixelFormat::None)
        fail(cmd, "the swapchain pass has an empty PassDesc::format, so no pipeline can match it",
             "make the pass with PassDesc::for_swapchain(swapchain, device.environment_defaults())");
    passState_ = PassState::Render;
    passLabel_ = str(p.label);
    passFormat_ = p.format;
    pipeline_ = {};
    bindingsApplied_ = false;
    uniformsApplied_ = 0;
    record(CommandKind::BeginPass, p.color.id, {},
           "begin_pass " + quoted(passLabel_) + (p.swapchain ? " swapchain " : " ") + format_text(p.format));
}

void RecordingCommandList::begin_compute_pass(const char* label) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    if (passState_ != PassState::None)
        fail("begin_compute_pass", "pass " + quoted(passLabel_) + " is still open; passes do not nest",
             "end_pass() before the next begin_compute_pass()");
    if (queue_ == QueueKind::Transfer)
        fail("begin_compute_pass", "the list runs on the transfer queue, which has no compute passes",
             "record compute passes on a QueueKind::Compute (or Graphics) list");
    if (!device_.features_.compute)
        fail("begin_compute_pass", "the device has no compute (Features::compute is false)",
             "check Device::features().compute and take the CPU path where it is false");
    passState_ = PassState::Compute;
    passLabel_ = str(label);
    passFormat_ = {};
    pipeline_ = {};
    bindingsApplied_ = false;
    uniformsApplied_ = 0;
    record(CommandKind::BeginComputePass, 0, {}, "begin_compute_pass " + quoted(passLabel_));
}

void RecordingCommandList::end_pass() {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    if (passState_ == PassState::None) {
        fail("end_pass", "no pass is open", "call end_pass() once for each begin_pass() / begin_compute_pass()");
        return;
    }
    record(CommandKind::EndPass, 0, {}, "end_pass");
    passState_ = PassState::None;
    passLabel_.clear();
    pipeline_ = {};
}

void RecordingCommandList::set_pipeline(Pipeline pipeline) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "set_pipeline";
    pipeline_ = {};
    bindingsApplied_ = false;
    uniformsApplied_ = 0;
    if (passState_ == PassState::None) {
        require_pass(cmd, PassState::Render);
        record(CommandKind::SetPipeline, pipeline.id, {}, "set_pipeline " + s.pipelines.describe(pipeline.id));
        return;
    }
    const auto* e = s.pipelines.live(pipeline.id);
    if (!e || e->state != ResourceState::Valid) {
        fail(cmd, "it is " + s.pipelines.describe(pipeline.id) + (e ? " (Failed: see its make_pipeline error)" : ""),
             "set a live pipeline (make it again if its shader changed)");
        record(CommandKind::SetPipeline, pipeline.id, {}, "set_pipeline " + s.pipelines.describe(pipeline.id));
        return;
    }
    const PipelineInfo& pi = e->info;
    if (!s.shaders.live(pi.shader))
        fail(cmd, "the shader of pipeline " + quoted(e->label) + " is " + s.shaders.describe(pi.shader),
             "destroy a pipeline before its shader, and make both again");
    if (pi.compute != (passState_ == PassState::Compute)) {
        fail(cmd,
             std::string(pi.compute ? "compute" : "render") + " pipeline " + quoted(e->label) + " is set " +
                 pass_state_name(passState_),
             pi.compute ? "set compute pipelines inside begin_compute_pass()"
                        : "set render pipelines inside begin_pass()");
    } else if (!pi.compute) {
        const TargetFormat& f = passFormat_;
        const int passColors = int(f.color != PixelFormat::None) + int(f.color1 != PixelFormat::None);
        TargetFormat got;
        got.color = pi.colorCount > 0 ? pi.colors[0] : PixelFormat::None;
        got.color1 = pi.colorCount > 1 ? pi.colors[1] : PixelFormat::None;
        got.depth = pi.depth;
        got.samples = pi.samples;
        if (pi.colorCount != passColors || got.color != f.color || got.color1 != f.color1 || got.depth != f.depth ||
            got.samples != f.samples)
            fail(cmd,
                 "pipeline " + quoted(e->label) + " draws " + format_text(got) + " (" + std::to_string(pi.colorCount) +
                     " colour targets) but the pass is " + format_text(f) + " (" + std::to_string(passColors) + ")",
                 "make the pipeline for this pass's TargetFormat (Gpu::find_or_make keys pipelines by it)");
    }
    pipeline_.id = pipeline.id;
    pipeline_.label = e->label;
    pipeline_.compute = pi.compute;
    pipeline_.requiredUniforms = pi.requiredUniforms;
    pipeline_.needsBindings = pi.needsBindings;
    record(CommandKind::SetPipeline, pipeline.id, {}, "set_pipeline " + quoted(e->label));
}

void RecordingCommandList::set_bindings(const Bindings& b) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "set_bindings";
    int vbs = 0, views = 0, samplers = 0;
    for (const Buffer& v : b.vertexBuffers) vbs += v.id != 0;
    for (const View& v : b.views) views += v.id != 0;
    for (const Sampler& v : b.samplers) samplers += v.id != 0;
    for (const Buffer& v : b.vertexBuffers) use_buffer(v);
    use_buffer(b.indexBuffer);
    for (const View& v : b.views) use_view(v);
    record(CommandKind::SetBindings, b.indexBuffer.id, {vbs, views, samplers},
           "set_bindings vb=" + std::to_string(vbs) + " views=" + std::to_string(views) +
               " samplers=" + std::to_string(samplers) + (b.indexBuffer.id ? " index" : ""));
    if (passState_ == PassState::None) {
        require_pass(cmd, PassState::Render);
        return;
    }
    if (!pipeline_.id) {
        fail(cmd, "no pipeline is set", "set_pipeline() before set_bindings(): the bindings are checked against it");
        return;
    }
    const auto* pe = s.pipelines.live(pipeline_.id);
    if (!pe) {
        fail(cmd, "the current pipeline " + quoted(pipeline_.label) + " was destroyed since set_pipeline()",
             "keep a pipeline alive until the lists that use it are submitted");
        return;
    }
    bindingsApplied_ = true;
    const PipelineInfo& pi = pe->info;
    const ShaderInfo& r = pi.reflection;
    const std::string pip = "pipeline " + quoted(pipeline_.label);
    for (int i = 0; i < kMaxVertexBuffers; ++i) {
        const std::uint32_t id = b.vertexBuffers[i].id;
        const bool used = (pi.vertexBufferMask >> i) & 1u;
        if (!used) {
            if (id && pi.compute)
                fail(cmd, "vertex buffer slot " + std::to_string(i) + " is set in a compute pass",
                     "bind only views and samplers in a compute pass");
            continue;
        }
        const auto* e = s.buffers.live(id);
        if (!e || e->state != ResourceState::Valid)
            fail(cmd,
                 "vertex buffer slot " + std::to_string(i) + ", which " + pip + " reads, is " + s.buffers.describe(id),
                 "bind a live vertex buffer in every slot the pipeline's layout uses");
        else if (!e->info.vertex())
            fail(cmd,
                 "buffer " + quoted(e->label) + " in vertex buffer slot " + std::to_string(i) +
                     " was not made with usage.vertexBuffer",
                 "make vertex buffers with usage.vertexBuffer");
    }
    if (pi.indexType == IndexType::None) {
        if (b.indexBuffer.id)
            fail(cmd, "an index buffer is bound but " + pip + " has IndexType::None",
                 "drop the index buffer, or make the pipeline with indexType Uint16/Uint32");
    } else {
        const auto* e = s.buffers.live(b.indexBuffer.id);
        if (!e || e->state != ResourceState::Valid)
            fail(cmd, pip + " draws indexed but the index buffer is " + s.buffers.describe(b.indexBuffer.id),
                 "bind the index buffer (Bindings::indexBuffer)");
        else if (!e->info.usage.indexBuffer)
            fail(cmd,
                 "buffer " + quoted(e->label) +
                     " is bound as the index buffer but was not made with "
                     "usage.indexBuffer",
                 "make index buffers with usage.indexBuffer");
    }
    for (int i = 0; i < kMaxViews; ++i) {
        const std::uint32_t id = b.views[i].id;
        const ViewType want = r.views[i];
        const std::string slot = "view slot " + std::to_string(i);
        if (want == ViewType::Invalid) {
            if (id)
                fail(cmd, slot + " is bound but shader " + quoted(pi.shaderLabel) + " declares nothing there",
                     "leave the slots the shader does not declare empty (the generated header names each slot)");
            continue;
        }
        const char* wantName = want == ViewType::Texture         ? "a texture view"
                               : want == ViewType::StorageBuffer ? "a storage buffer view"
                                                                 : "a storage image view";
        const auto* e = s.views.live(id);
        if (!e || e->state != ResourceState::Valid) {
            fail(cmd,
                 slot + " needs " + wantName + " (shader " + quoted(pi.shaderLabel) + ") but it is " +
                     s.views.describe(id),
                 "bind a live view in every slot the shader declares");
            continue;
        }
        if (e->info.type != want) {
            fail(cmd, slot + " needs " + wantName + " but view " + quoted(e->label) + " is another kind",
                 "make the view with the ViewDesc member the shader slot expects");
            continue;
        }
        const bool resourceAlive = want == ViewType::StorageBuffer ? s.buffers.live(e->info.resource) != nullptr
                                                                   : s.images.live(e->info.resource) != nullptr;
        if (!resourceAlive) {
            fail(cmd,
                 slot + ": view " + quoted(e->label) + " is of " +
                     (want == ViewType::StorageBuffer ? s.buffers.describe(e->info.resource)
                                                      : s.images.describe(e->info.resource)),
                 "destroy a view with its resource, and make it again with the new one");
            continue;
        }
        if (want == ViewType::Texture) {
            const bool ms = e->info.samples > 1;
            if (ms != r.multisampled[i])
                fail(cmd,
                     slot + ": view " + quoted(e->label) + (ms ? " is" : " is not") +
                         " multisampled but the shader's texture" + (r.multisampled[i] ? " is" : " is not"),
                     "bind a resolved image to a plain texture slot, a multisampled one to a multisampled slot");
            const PixelFormat f = e->info.format;
            const PixelFormatCaps caps = device_.pixel_format_caps(f);
            const ImageSampleType st = r.sampleType[i];
            const bool depth = pixel_format_depth(f), integer = pixel_format_integer(f);
            const bool ok = st == ImageSampleType::Depth               ? depth
                            : st == ImageSampleType::Float             ? (!depth && !integer && caps.filter)
                            : st == ImageSampleType::UnfilterableFloat ? (!integer)
                                                                       : integer;
            if (!ok)
                fail(cmd,
                     slot + ": view " + quoted(e->label) + " is " + pixel_format_name(f) +
                         ", which the shader's sample type cannot read",
                     "declare the texture with the matching sample type (depth, sint/uint, or unfilterable-float "
                     "for formats that cannot filter)");
        }
    }
    for (int i = 0; i < kMaxSamplers; ++i) {
        const std::uint32_t id = b.samplers[i].id;
        const std::string slot = "sampler slot " + std::to_string(i);
        if (!r.samplerDeclared[i]) {
            if (id)
                fail(cmd, slot + " is bound but shader " + quoted(pi.shaderLabel) + " declares no sampler there",
                     "leave the sampler slots the shader does not declare empty");
            continue;
        }
        const auto* e = s.samplers.live(id);
        if (!e || e->state != ResourceState::Valid) {
            fail(cmd, slot + " (shader " + quoted(pi.shaderLabel) + ") is " + s.samplers.describe(id),
                 "bind a live sampler in every slot the shader declares");
            continue;
        }
        const SamplerType st = r.samplerType[i];
        if ((st == SamplerType::Comparison) != e->info.comparison)
            fail(cmd,
                 slot + ": sampler " + quoted(e->label) + (e->info.comparison ? " compares" : " does not compare") +
                     " but the shader's sampler" + (st == SamplerType::Comparison ? " does" : " does not"),
                 "a comparison (shadow) slot takes a sampler with SamplerDesc::compare set, any other slot one "
                 "without");
        else if (st == SamplerType::Nonfiltering && e->info.filtering)
            fail(cmd, slot + ": sampler " + quoted(e->label) + " filters linearly in a non-filtering slot",
                 "use Filter::Nearest for every filter of a sampler in a non-filtering slot");
    }
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        const std::uint32_t id = b.accelStructures[i].id;
        const std::string slot = "accelStructures[" + std::to_string(i) + "]";
        if (!r.accelDeclared[i]) {
            if (id)
                fail(cmd,
                     slot + " is bound but shader " + quoted(pi.shaderLabel) +
                         " declares no acceleration structure there",
                     "leave the acceleration structure slots the shader does not declare empty");
            continue;
        }
        const auto* e = s.accels.live(id);
        if (!e || e->state != ResourceState::Valid) {
            fail(cmd, slot + " (shader " + quoted(pi.shaderLabel) + ") is " + s.accels.describe(id),
                 "bind a live, built TLAS in every acceleration structure slot the shader declares");
        } else if (e->info.kind != AccelKind::Tlas) {
            fail(cmd, slot + " is the BLAS " + quoted(e->label) + ", but a ray query traces against a TLAS",
                 "build a TLAS over it with build_tlas (one instance with the identity transform will do) and bind "
                 "that");
        } else if (!e->info.built) {
            fail(cmd, slot + " is the TLAS " + quoted(e->label) + ", which build_tlas has not built yet",
                 "record build_tlas on the structure before the dispatch that traces it");
        }
    }
}

void RecordingCommandList::set_uniforms(int slot, Range data) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    const char* cmd = "set_uniforms";
    record(CommandKind::SetUniforms, 0, {slot, int(std::min<std::size_t>(data.size, std::size_t(INT32_MAX)))},
           "set_uniforms " + std::to_string(slot) + " " + std::to_string(data.size) + "B");
    if (passState_ == PassState::None) {
        require_pass(cmd, PassState::Render);
        return;
    }
    if (!require_pipeline(cmd)) return;
    const auto* pe = device_.state_->pipelines.live(pipeline_.id);
    if (slot < 0 || slot >= kMaxUniformBlocks || !pe || !pe->info.reflection.uniformSize[slot]) {
        fail(cmd,
             "uniform block " + std::to_string(slot) + " is not declared by the shader of pipeline " +
                 quoted(pipeline_.label),
             "use the slot the generated shader header names (UB_<block>)");
        return;
    }
    const std::uint32_t want = pe->info.reflection.uniformSize[slot];
    if (data.size != want) {
        fail(cmd,
             "uniform block " + std::to_string(slot) + " is " + std::to_string(want) + " bytes but " +
                 std::to_string(data.size) + " were passed",
             "pass exactly the block's struct (sizeof the generated <block>_t)");
        return;
    }
    if (!data.ptr) {
        fail(cmd, "the data pointer is null", "pass the block's struct");
        return;
    }
    uniformsApplied_ |= 1u << slot;
}

void RecordingCommandList::set_viewport(int x, int y, int width, int height, bool) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    record(CommandKind::SetViewport, 0, {x, y, width, height},
           "set_viewport " + std::to_string(x) + " " + std::to_string(y) + " " + std::to_string(width) + " " +
               std::to_string(height));
    require_pass("set_viewport", PassState::Render);
}

void RecordingCommandList::set_viewport_f(float x, float y, float width, float height, bool) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto r = [](float v) { return int(std::lround(std::clamp(v, -1.0e9f, 1.0e9f))); };
    record(CommandKind::SetViewport, 0, {r(x), r(y), r(width), r(height)},
           "set_viewport " + std::to_string(r(x)) + " " + std::to_string(r(y)) + " " + std::to_string(r(width)) + " " +
               std::to_string(r(height)));
    require_pass("set_viewport_f", PassState::Render);
}

void RecordingCommandList::set_scissor(int x, int y, int width, int height, bool) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    record(CommandKind::SetScissor, 0, {x, y, width, height},
           "set_scissor " + std::to_string(x) + " " + std::to_string(y) + " " + std::to_string(width) + " " +
               std::to_string(height));
    require_pass("set_scissor", PassState::Render);
}

void RecordingCommandList::draw(int base, int count, int instances) { draw_ex(base, count, instances, 0, 0); }

void RecordingCommandList::draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    const char* cmd = "draw";
    std::string text = "draw " + std::to_string(base) + " " + std::to_string(count) + " " + std::to_string(instances);
    if (baseVertex || baseInstance) text += " " + std::to_string(baseVertex) + " " + std::to_string(baseInstance);
    // Checked before recording, so the message names this draw's index.
    if (require_pass(cmd, PassState::Render) && require_pipeline(cmd)) {
        check_ready_to_run(cmd);
        if (base < 0 || count < 0 || instances < 0)
            fail(cmd, "base, count and instances must not be negative", "pass the vertex/index range and count");
        if (baseVertex != 0 && !device_.features_.drawBaseVertex)
            fail(cmd, "baseVertex is set on a device without it (Features::drawBaseVertex)",
                 "offset the indices on the CPU, or check the feature first");
        if (baseInstance != 0 && !device_.features_.drawBaseInstance)
            fail(cmd, "baseInstance is set on a device without it (Features::drawBaseInstance)",
                 "pass the instance offset as a uniform, or check the feature first");
    }
    record(CommandKind::Draw, pipeline_.id, {base, count, instances, baseVertex, baseInstance}, std::move(text));
}

void RecordingCommandList::dispatch(int x, int y, int z) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    const char* cmd = "dispatch";
    if (require_pass(cmd, PassState::Compute) && require_pipeline(cmd)) {
        check_ready_to_run(cmd);
        if (x < 0 || y < 0 || z < 0) fail(cmd, "a group count is negative", "pass the thread-group counts (0 or more)");
    }
    record(CommandKind::Dispatch, pipeline_.id, {x, y, z},
           "dispatch " + std::to_string(x) + " " + std::to_string(y) + " " + std::to_string(z));
}

namespace {

// clamp_int: with the readbacks above.

// Whether [offset, offset + size) fits in `total` bytes (no overflow).
bool fits(std::size_t offset, std::size_t size, std::size_t total) { return size <= total && offset <= total - size; }

// The size of mip `mip` of a dimension.
int mip_size(int size, int mip) { return std::max(1, size >> std::clamp(mip, 0, 30)); }

}  // namespace

void RecordingCommandList::write_buffer(const BufferWrite& w) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "write_buffer";
    use_buffer(w.buffer);
    const auto* e = s.buffers.live(w.buffer.id);
    if (!e || e->state != ResourceState::Valid) {
        fail(cmd, "the buffer is " + s.buffers.describe(w.buffer.id), "write into a live buffer");
    } else {
        if (!e->info.usage.writeTransient)
            fail(cmd, "buffer " + quoted(e->label) + " was not made with usage.writeTransient",
                 "make buffers that are rewritten each frame with usage.writeTransient");
        if (!fits(w.dstOffset, w.size, e->info.size))
            fail(cmd,
                 std::to_string(w.size) + " bytes at offset " + std::to_string(w.dstOffset) + " do not fit in buffer " +
                     quoted(e->label) + " (" + std::to_string(e->info.size) + " bytes)",
                 "write inside the buffer, or make it larger");
        if (!w.data.ptr || !fits(w.srcOffset, w.size, w.data.size))
            fail(cmd,
                 "the source has " + std::to_string(w.data.size) + " bytes, fewer than offset " +
                     std::to_string(w.srcOffset) + " + size " + std::to_string(w.size),
                 "pass a source range that holds the bytes written");
    }
    record(CommandKind::WriteBuffer, w.buffer.id, {clamp_int(w.size)},
           "write_buffer " + s.buffers.describe(w.buffer.id) + " " + std::to_string(w.size) + "B");
}

void RecordingCommandList::write_image(const ImageWrite& w) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "write_image";
    use_image(w.dst.image);
    const auto* e = s.images.live(w.dst.image.id);
    if (!e || e->state != ResourceState::Valid) {
        fail(cmd, "the image is " + s.images.describe(w.dst.image.id), "write into a live image");
    } else {
        const ImageInfo& ii = e->info;
        if (!ii.usage.writeTransient)
            fail(cmd, "image " + quoted(e->label) + " was not made with usage.writeTransient",
                 "make images rewritten after creation with usage.writeTransient");
        const int slices = w.size.numSlices > 0 ? w.size.numSlices : 1;
        if (w.dst.mipLevel < 0 || w.dst.mipLevel >= ii.mips ||
            !span_fits(w.dst.x, w.size.width, mip_size(ii.width, w.dst.mipLevel)) ||
            !span_fits(w.dst.y, w.size.height, mip_size(ii.height, w.dst.mipLevel)) ||
            !span_fits(w.dst.slice, slices, ii.slices))
            fail(cmd,
                 "the rectangle " + std::to_string(w.size.width) + "x" + std::to_string(w.size.height) + " at (" +
                     std::to_string(w.dst.x) + ", " + std::to_string(w.dst.y) + ") of mip " +
                     std::to_string(w.dst.mipLevel) + " is outside image " + quoted(e->label),
                 "write inside the mip level's size");
        if (!w.data.ptr) fail(cmd, "the source data is null", "pass the pixels to write");
    }
    record(CommandKind::WriteImage, w.dst.image.id, {w.size.width, w.size.height},
           "write_image " + s.images.describe(w.dst.image.id) + " " + std::to_string(w.size.width) + "x" +
               std::to_string(w.size.height));
}

void RecordingCommandList::copy_buffer_to_buffer(const BufferCopy& c) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "copy_buffer_to_buffer";
    use_buffer(c.src);
    use_buffer(c.dst);
    if (require_pass(cmd, PassState::None)) {
        const auto* src = s.buffers.live(c.src.id);
        const auto* dst = s.buffers.live(c.dst.id);
        if (!src || !dst) {
            fail(cmd,
                 "the source is " + s.buffers.describe(c.src.id) + " and the destination " +
                     s.buffers.describe(c.dst.id),
                 "copy between live buffers");
        } else {
            if (!src->info.usage.copySrc)
                fail(cmd, "source buffer " + quoted(src->label) + " was not made with usage.copySrc",
                     "add usage.copySrc to the source");
            if (!dst->info.usage.copyDst)
                fail(cmd, "destination buffer " + quoted(dst->label) + " was not made with usage.copyDst",
                     "add usage.copyDst to the destination");
            if (!fits(c.srcOffset, c.size, src->info.size) || !fits(c.dstOffset, c.size, dst->info.size))
                fail(cmd, std::to_string(c.size) + " bytes do not fit in the source or the destination at the offsets",
                     "copy inside both buffers");
        }
    }
    record(CommandKind::CopyBufferToBuffer, c.dst.id, {clamp_int(c.size)},
           "copy_buffer_to_buffer " + s.buffers.describe(c.src.id) + " -> " + s.buffers.describe(c.dst.id) + " " +
               std::to_string(c.size) + "B");
}

void RecordingCommandList::copy_buffer_to_image(const BufferImageCopy& c) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    const char* cmd = "copy_buffer_to_image";
    use_buffer(c.src);
    use_image(c.dst.image);
    if (require_pass(cmd, PassState::None)) {
        const auto* src = s.buffers.live(c.src.id);
        const auto* dst = s.images.live(c.dst.image.id);
        if (!src || !dst) {
            fail(cmd,
                 "the source is " + s.buffers.describe(c.src.id) + " and the destination " +
                     s.images.describe(c.dst.image.id),
                 "copy from a live buffer into a live image");
        } else {
            if (!src->info.usage.copySrc && !device_.features_.copyBufferToImageRelaxedBufferType)
                fail(cmd, "source buffer " + quoted(src->label) + " was not made with usage.copySrc",
                     "add usage.copySrc to the source");
            if (!dst->info.usage.copyDst)
                fail(cmd, "destination image " + quoted(dst->label) + " was not made with usage.copyDst",
                     "add usage.copyDst to the image");
            const ImageInfo& ii = dst->info;
            if (c.dst.mipLevel < 0 || c.dst.mipLevel >= ii.mips ||
                !span_fits(c.dst.x, c.size.width, mip_size(ii.width, c.dst.mipLevel)) ||
                !span_fits(c.dst.y, c.size.height, mip_size(ii.height, c.dst.mipLevel)) ||
                !span_fits(c.dst.slice, c.size.numSlices > 0 ? c.size.numSlices : 1, ii.slices))
                fail(cmd, "the rectangle is outside image " + quoted(dst->label), "copy inside the mip level's size");
        }
    }
    record(CommandKind::CopyBufferToImage, c.dst.image.id, {c.size.width, c.size.height},
           "copy_buffer_to_image " + s.buffers.describe(c.src.id) + " -> " + s.images.describe(c.dst.image.id) + " " +
               std::to_string(c.size.width) + "x" + std::to_string(c.size.height));
}

void RecordingCommandList::push_debug_group(const char* name) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    ++debugDepth_;
    record(CommandKind::PushDebugGroup, 0, {}, "push_debug_group " + quoted(str(name)));
}

void RecordingCommandList::pop_debug_group() {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    if (debugDepth_ == 0)
        fail("pop_debug_group", "no debug group is open", "pop once for each push_debug_group()");
    else
        --debugDepth_;
    record(CommandKind::PopDebugGroup, 0, {}, "pop_debug_group");
}

void RecordingCommandList::begin_timed_scope(const char* name) {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    timedScopeOpen_ = true;  // a begin closes the scope still open
    // The transfer queue has no timestamps: the scope is accepted and measures nothing (recorded so a test can see it).
    const bool ignored = queue_ == QueueKind::Transfer;
    record(CommandKind::BeginTimedScope, 0, {ignored ? 1 : 0},
           "begin_timed_scope " + quoted(str(name)) +
               (ignored ? " (ignored: the transfer queue has no timestamps)" : ""));
}

void RecordingCommandList::end_timed_scope() {
    std::lock_guard<std::mutex> lock(device_.mutex_);
    if (!timedScopeOpen_) fail("end_timed_scope", "no timed scope is open", "call begin_timed_scope() first");
    timedScopeOpen_ = false;
    const bool ignored = queue_ == QueueKind::Transfer;
    record(CommandKind::EndTimedScope, 0, {ignored ? 1 : 0},
           ignored ? "end_timed_scope (ignored: the transfer queue has no timestamps)" : "end_timed_scope");
}

// ---------------------------------------------------------------------------------------------------------------------
// Ray tracing (M79): sizes, acceleration structures, builds
// ---------------------------------------------------------------------------------------------------------------------
namespace {

constexpr std::uint64_t kAccelAlign = 256;  // the alignment accel_alignment() and accel_scratch_alignment() answer
constexpr std::uint32_t kMaxCustomIndex = 0xFFFFFFu;
constexpr int kMaxReportedProblems = 4;  // a build of 100k bad instances reports the first few, not 100k lines

std::uint64_t round_up_accel(std::uint64_t v) { return (v + kAccelAlign - 1) / kAccelAlign * kAccelAlign; }

// The RecordingDevice's own sizes: deterministic functions of the counts, so a test can compute them (not a real GPU's).
AccelSizes model_blas_sizes(std::uint32_t geometries, std::uint64_t primitives, const AccelBuildFlags& f) {
    AccelSizes s;
    s.structure = round_up_accel(4096 + 64 * primitives + 128 * std::uint64_t(geometries) +
                                 (f.allowUpdate ? 16 * primitives : 0));
    s.buildScratch = round_up_accel(1024 + 32 * primitives);
    s.updateScratch = f.allowUpdate ? round_up_accel(512 + 16 * primitives) : 0;
    return s;
}

// What query_compacted_size answers for a built BLAS: about half of the model's size, rounded up (deterministic, never above the structure).
std::uint64_t model_compacted_size(std::uint32_t geometries, std::uint64_t primitives) {
    return round_up_accel(2048 + 40 * primitives + 64 * std::uint64_t(geometries));
}

AccelSizes model_tlas_sizes(std::uint32_t instances, const AccelBuildFlags& f) {
    AccelSizes s;
    s.structure =
        round_up_accel(4096 + 128 * std::uint64_t(instances) + (f.allowUpdate ? 32 * std::uint64_t(instances) : 0));
    s.buildScratch = round_up_accel(1024 + 64 * std::uint64_t(instances));
    s.updateScratch = f.allowUpdate ? round_up_accel(512 + 32 * std::uint64_t(instances)) : 0;
    return s;
}

std::string geometry_name(std::size_t i) { return "geometries[" + std::to_string(i) + "]"; }

// The checks of the geometry list that need no buffer (sizes and builds). Adds the problems to `what`.
void check_geometry_list(std::string& what, std::span<const AccelTriangles> geometries, const Limits& limits,
                         std::uint64_t& primitives) {
    primitives = 0;
    if (geometries.empty()) {
        add(what, "no geometries: a BLAS needs at least one triangle geometry");
        return;
    }
    if (limits.maxAccelGeometries > 0 && geometries.size() > limits.maxAccelGeometries)
        add(what, std::to_string(geometries.size()) + " geometries are more than this device's limit " +
                      std::to_string(limits.maxAccelGeometries) +
                      " (Limits::maxAccelGeometries): merge meshes into fewer geometries, or build several BLASes");
    int problems = 0;
    for (std::size_t i = 0; i < geometries.size(); ++i) {
        const AccelTriangles& g = geometries[i];
        primitives += g.primitive_count();
        if (problems >= kMaxReportedProblems) continue;
        const std::string n = geometry_name(i);
        const std::size_t before = what.size();
        if (g.vertexFormat != VertexFormat::Float3)
            add(what,
                n + ".vertexFormat is not Float3: three 32-bit floats are the one position format every backend takes");
        if (g.vertexStride < 12 || g.vertexStride % 4 != 0)
            add(what, n + ".vertexStride " + std::to_string(g.vertexStride) +
                          " is not a multiple of 4 that is at least 12 (the size of a Float3 position)");
        if (g.vertexOffset % 4 != 0)
            add(what, n + ".vertexOffset " + std::to_string(g.vertexOffset) +
                          " is not a multiple of 4 (every backend reads the position as 32-bit floats): move the "
                          "first vertex to a 4-byte aligned byte offset");
        if (g.indexBuffer.valid()) {
            if (g.indexType != IndexType::Uint16 && g.indexType != IndexType::Uint32)
                add(what, n + " has an index buffer but indexType is not Uint16 or Uint32");
            else if (g.indexOffset % (g.indexType == IndexType::Uint16 ? 2 : 4) != 0)
                add(what, n + ".indexOffset " + std::to_string(g.indexOffset) +
                              " is not a multiple of the index width (" +
                              (g.indexType == IndexType::Uint16 ? "2 bytes for Uint16" : "4 bytes for Uint32") +
                              "): start the indices at an aligned byte offset");
            if (g.indexCount % 3 != 0)
                add(what, n + ".indexCount " + std::to_string(g.indexCount) + " is not a multiple of 3");
        } else {
            if (g.indexType == IndexType::Uint16 || g.indexType == IndexType::Uint32)
                add(what, n + " names an indexType but no index buffer");
            if (g.vertexCount % 3 != 0)
                add(what, n + ".vertexCount " + std::to_string(g.vertexCount) +
                              " is not a multiple of 3 (a triangle list without an index buffer)");
        }
        if (g.primitive_count() == 0) add(what, n + " has no triangles");
        if (what.size() != before) ++problems;
    }
    if (limits.maxAccelPrimitives > 0 && primitives > limits.maxAccelPrimitives)
        add(what, std::to_string(primitives) + " triangles are more than this device's limit " +
                      std::to_string(limits.maxAccelPrimitives) + " (Limits::maxAccelPrimitives)");
}

}  // namespace

Result<AccelSizes> RecordingDevice::blas_sizes(std::span<const AccelTriangles> geometries,
                                               const AccelBuildFlags& flags) {
    if (!features_.accelerationStructure) return accel_refusal(Backend::Recording, "Device::blas_sizes");
    std::lock_guard<std::mutex> lock(mutex_);
    std::string what;
    std::uint64_t primitives = 0;
    check_geometry_list(what, geometries, limits_, primitives);
    if (!what.empty()) {
        const std::string fix = "give 1 to Limits::maxAccelGeometries triangle geometries (Float3 positions, a "
                                "multiple of 3 indices) with at most Limits::maxAccelPrimitives triangles in all";
        fail_locked("blas_sizes", nullptr, what, fix);
        return make_error("gpu: blas_sizes: " + what, fix);
    }
    return model_blas_sizes(std::uint32_t(geometries.size()), primitives, flags);
}

Result<AccelSizes> RecordingDevice::tlas_sizes(std::uint32_t instanceCount, const AccelBuildFlags& flags) {
    if (!features_.accelerationStructure) return accel_refusal(Backend::Recording, "Device::tlas_sizes");
    std::lock_guard<std::mutex> lock(mutex_);
    std::string what;
    if (instanceCount == 0) add(what, "0 instances: skip the TLAS build when the scene has no instances");
    if (limits_.maxAccelInstances > 0 && instanceCount > limits_.maxAccelInstances)
        add(what, std::to_string(instanceCount) + " instances are more than this device's limit " +
                      std::to_string(limits_.maxAccelInstances) +
                      " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
    if (!what.empty()) {
        const std::string fix = "ask for 1 to Limits::maxAccelInstances instances";
        fail_locked("tlas_sizes", nullptr, what, fix);
        return make_error("gpu: tlas_sizes: " + what, fix);
    }
    return model_tlas_sizes(instanceCount, flags);
}

Result<AccelStructure> RecordingDevice::make_accel_structure(const AccelStructureDesc& d) {
    if (!features_.accelerationStructure) return accel_refusal(Backend::Recording, "Device::make_accel_structure");
    std::lock_guard<std::mutex> lock(mutex_);
    State& s = *state_;
    std::string what;
    if (d.size == 0) add(what, "AccelStructureDesc::size is 0: take it from blas_sizes() / tlas_sizes()");
    if (d.storage.valid()) {
        const auto* e = s.buffers.live(d.storage.id);
        if (!e || e->state != ResourceState::Valid) {
            add(what, "storage is " + s.buffers.describe(d.storage.id));
        } else {
            if (!e->info.usage.accelStorage)
                add(what, "storage buffer " + quoted(e->label) + " was not made with usage.accelStorage");
            if (d.storageOffset % kAccelAlign != 0)
                add(what, "storageOffset " + std::to_string(d.storageOffset) + " is not a multiple of " +
                              std::to_string(kAccelAlign) + " (Device::accel_alignment())");
            if (!fits(d.storageOffset, std::size_t(d.size), e->info.size))
                add(what, std::to_string(d.size) + " bytes at offset " + std::to_string(d.storageOffset) +
                              " do not fit in buffer " + quoted(e->label) + " (" + std::to_string(e->info.size) +
                              " bytes)");
        }
    } else if (d.storageOffset != 0) {
        add(what, "storageOffset is set but storage is not");
    }
    if (!what.empty()) {
        const std::string fix = "size the structure from blas_sizes() / tlas_sizes(), and place it in a live buffer "
                                "with usage.accelStorage (or leave storage empty)";
        fail_locked("make_accel_structure", d.label, what, fix);
        return make_error("gpu: make_accel_structure: " + what, fix);
    }
    AccelInfo info;
    info.kind = d.kind;
    info.size = d.size;
    const std::uint32_t id = s.accels.add(d.label, ResourceState::Valid, info);
    if (!id) {
        const std::string msg = "the acceleration structure pool is full (" + std::to_string(s.accels.capacity) + ")";
        const std::string fix = "destroy structures no longer used, or raise DeviceInit::bufferPoolSize";
        fail_locked("make_accel_structure", d.label, msg, fix);
        return make_error("gpu: make_accel_structure: " + msg, fix);
    }
    return AccelStructure{id};
}

void RecordingDevice::destroy_accel_structure(AccelStructure a) {
    std::lock_guard<std::mutex> lock(mutex_);
    destroy_in(*this, state_->accels, a.id, "destroy_accel_structure", &RecordingDevice::fail_locked);
}

ResourceState RecordingDevice::accel_structure_state(AccelStructure a) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return state_->accels.state(a.id);
}

// ---- the list's calls -----------------------------------------------------------------------------------------------

Error RecordingCommandList::reject(const char* command, const std::string& what, const std::string& fix) {
    fail(command, what, fix);
    return make_error(std::string("gpu: ") + command + ": " + what, fix);
}

namespace {

// "acceleration structure 'rock'" for a live one with the kind; used in the messages of the builds.
std::string accel_label(const std::string& label, AccelKind kind) {
    return std::string(kind == AccelKind::Tlas ? "TLAS " : "BLAS ") + quoted(label);
}

}  // namespace

Result<void> RecordingCommandList::build_blas(const BlasBuild& b) {
    const char* cmd = "build_blas";
    if (!device_.features_.accelerationStructure) return accel_refusal(Backend::Recording, "CommandList::build_blas");
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    if (passState_ != PassState::None)
        return reject(cmd, std::string("called ") + pass_state_name(passState_) + "; it goes outside a pass",
                      "end_pass() first, or record the build before begin_pass()");
    if (queue_ == QueueKind::Transfer)
        return reject(cmd, "called on a Transfer list, which takes copies, writes and markers only",
                      "record builds on a Graphics or Compute list");
    std::string what;
    const auto* dst = s.accels.live(b.dst.id);
    if (!dst || dst->state != ResourceState::Valid)
        add(what, "dst is " + s.accels.describe(b.dst.id));
    else if (dst->info.kind != AccelKind::Blas)
        add(what, "dst " + accel_label(dst->label, dst->info.kind) +
                      " is a TLAS: build_blas writes a BLAS (build_tlas "
                      "builds a TLAS)");
    std::uint64_t primitives = 0;
    check_geometry_list(what, b.geometries, device_.limits_, primitives);
    int problems = 0;
    for (std::size_t i = 0; i < b.geometries.size() && problems < kMaxReportedProblems; ++i) {
        const AccelTriangles& g = b.geometries[i];
        const std::string n = geometry_name(i);
        const std::size_t before = what.size();
        const auto* vb = s.buffers.live(g.vertexBuffer.id);
        if (!vb || vb->state != ResourceState::Valid) {
            add(what, n + ".vertexBuffer is " + s.buffers.describe(g.vertexBuffer.id));
        } else {
            if (!vb->info.usage.accelBuildInput)
                add(what, n + ".vertexBuffer " + quoted(vb->label) + " was not made with usage.accelBuildInput");
            const std::uint64_t need = g.vertexCount == 0 ? 0
                                                          : std::uint64_t(g.vertexOffset) +
                                                                std::uint64_t(g.vertexCount - 1) * g.vertexStride + 12;
            if (need > vb->info.size)
                add(what, n + " reads " + std::to_string(g.vertexCount) + " vertices up to byte " +
                              std::to_string(need) + ", but vertex buffer " + quoted(vb->label) + " has " +
                              std::to_string(vb->info.size) + " bytes");
        }
        if (g.indexBuffer.valid()) {
            const auto* ib = s.buffers.live(g.indexBuffer.id);
            if (!ib || ib->state != ResourceState::Valid) {
                add(what, n + ".indexBuffer is " + s.buffers.describe(g.indexBuffer.id));
            } else {
                if (!ib->info.usage.accelBuildInput)
                    add(what, n + ".indexBuffer " + quoted(ib->label) + " was not made with usage.accelBuildInput");
                const std::uint64_t width = g.indexType == IndexType::Uint16 ? 2 : 4;
                const std::uint64_t need = std::uint64_t(g.indexOffset) + std::uint64_t(g.indexCount) * width;
                if (need > ib->info.size)
                    add(what, n + " reads " + std::to_string(g.indexCount) + " indices up to byte " +
                                  std::to_string(need) + ", but index buffer " + quoted(ib->label) + " has " +
                                  std::to_string(ib->info.size) + " bytes");
            }
        }
        if (what.size() != before) ++problems;
    }
    const AccelSizes need = model_blas_sizes(std::uint32_t(b.geometries.size()), primitives, b.flags);
    if (dst && dst->state == ResourceState::Valid && dst->info.kind == AccelKind::Blas &&
        dst->info.size < need.structure)
        add(what, "dst " + accel_label(dst->label, AccelKind::Blas) + " has " + std::to_string(dst->info.size) +
                      " bytes but these geometries need " + std::to_string(need.structure) +
                      " (AccelSizes::structure of blas_sizes with the same flags)");
    const std::uint64_t scratchNeed = b.update ? need.updateScratch : need.buildScratch;
    if (b.update) {
        const AccelStructure srcHandle = b.src.valid() ? b.src : b.dst;
        const auto* src = s.accels.live(srcHandle.id);
        if (!src || src->state != ResourceState::Valid) {
            add(what, "src is " + s.accels.describe(srcHandle.id));
        } else if (src->info.kind != AccelKind::Blas) {
            add(what, "src " + accel_label(src->label, src->info.kind) + " is a TLAS: a BLAS refits from a BLAS");
        } else if (!src->info.built) {
            add(what, "update of " + accel_label(src->label, AccelKind::Blas) + ", which was never built");
        } else if (!src->info.allowUpdate) {
            add(what, "update of " + accel_label(src->label, AccelKind::Blas) +
                          ", which was built without flags.allowUpdate");
        } else if (src->info.geometries != b.geometries.size() || src->info.primitives != primitives) {
            add(what, "update with " + std::to_string(b.geometries.size()) + " geometries and " +
                          std::to_string(primitives) + " triangles, but " + accel_label(src->label, AccelKind::Blas) +
                          " was built with " + std::to_string(src->info.geometries) + " and " +
                          std::to_string(src->info.primitives) + ": a refit keeps the topology");
        }
        if (!b.flags.allowUpdate)
            add(what, "update with flags.allowUpdate false (pass the flags the BLAS was built with)");
    }
    const auto* scratch = s.buffers.live(b.scratch.id);
    if (!scratch || scratch->state != ResourceState::Valid) {
        add(what, "scratch is " + s.buffers.describe(b.scratch.id));
    } else {
        if (!scratch->info.usage.accelScratch)
            add(what, "scratch buffer " + quoted(scratch->label) + " was not made with usage.accelScratch");
        if (b.scratchOffset % kAccelAlign != 0)
            add(what, "scratchOffset " + std::to_string(b.scratchOffset) + " is not a multiple of " +
                          std::to_string(kAccelAlign) + " (Device::accel_scratch_alignment())");
        if (b.scratchOffset > scratch->info.size || scratch->info.size - b.scratchOffset < scratchNeed)
            add(what,
                "scratch buffer " + quoted(scratch->label) + " has " +
                    std::to_string(scratch->info.size > b.scratchOffset ? scratch->info.size - b.scratchOffset : 0) +
                    " bytes from scratchOffset " + std::to_string(b.scratchOffset) + ", but this " +
                    (b.update ? "update" : "build") + " needs " + std::to_string(scratchNeed) +
                    " (AccelSizes::" + (b.update ? "updateScratch" : "buildScratch") + ")");
    }
    if (!what.empty())
        return reject(cmd, what,
                      "size the BLAS and the scratch buffer from blas_sizes() with the flags of the build, give "
                      "every geometry live buffers with usage.accelBuildInput, and refit only what was built with "
                      "allowUpdate");
    for (const AccelTriangles& g : b.geometries) {
        use_buffer(g.vertexBuffer);
        use_buffer(g.indexBuffer);
    }
    use_buffer(b.scratch);
    auto* d = s.accels.live(b.dst.id);
    d->info.built = true;
    d->info.allowUpdate = b.flags.allowUpdate;
    d->info.allowCompaction = b.flags.allowCompaction;
    d->info.geometries = std::uint32_t(b.geometries.size());
    d->info.primitives = primitives;
    record(CommandKind::BuildBlas, b.dst.id,
           {clamp_int(b.geometries.size()), clamp_int(std::size_t(primitives)), clamp_int(std::size_t(scratchNeed)),
            b.update ? 1 : 0},
           std::string("build_blas ") + accel_label(d->label, AccelKind::Blas) +
               " geometries=" + std::to_string(b.geometries.size()) + " triangles=" + std::to_string(primitives) +
               (b.update ? " update" : "") + " scratch=" + std::to_string(scratchNeed) + "B");
    return {};
}

Result<void> RecordingCommandList::build_tlas(const TlasBuild& b) {
    const char* cmd = "build_tlas";
    if (!device_.features_.accelerationStructure) return accel_refusal(Backend::Recording, "CommandList::build_tlas");
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    if (passState_ != PassState::None)
        return reject(cmd, std::string("called ") + pass_state_name(passState_) + "; it goes outside a pass",
                      "end_pass() first, or record the build before begin_pass()");
    if (queue_ == QueueKind::Transfer)
        return reject(cmd, "called on a Transfer list, which takes copies, writes and markers only",
                      "record builds on a Graphics or Compute list");
    if (device_.rejectTlas_)
        return reject(cmd, "a test made the device refuse top level builds (inject_faults)",
                      "none: a test injected it");
    std::string what;
    const auto* dst = s.accels.live(b.dst.id);
    if (!dst || dst->state != ResourceState::Valid)
        add(what, "dst is " + s.accels.describe(b.dst.id));
    else if (dst->info.kind != AccelKind::Tlas)
        add(what, "dst " + accel_label(dst->label, dst->info.kind) +
                      " is a BLAS: build_tlas writes a TLAS (build_blas "
                      "builds a BLAS)");
    const std::size_t n = b.instances.size();
    if (n == 0) add(what, "no instances: skip the TLAS build when the scene has none");
    if (device_.limits_.maxAccelInstances > 0 && n > device_.limits_.maxAccelInstances)
        add(what, std::to_string(n) + " instances are more than this device's limit " +
                      std::to_string(device_.limits_.maxAccelInstances) +
                      " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
    int problems = 0;
    for (std::size_t i = 0; i < n && problems < kMaxReportedProblems; ++i) {
        const AccelInstance& in = b.instances[i];
        const std::string name = "instances[" + std::to_string(i) + "]";
        const std::size_t before = what.size();
        const auto* blas = s.accels.live(in.blas.id);
        if (!blas || blas->state != ResourceState::Valid)
            add(what, name + ".blas is " + s.accels.describe(in.blas.id) +
                          ": destroy a BLAS only after the TLAS that names it is no longer built");
        else if (blas->info.kind != AccelKind::Blas)
            add(what, name + ".blas is the " + accel_label(blas->label, blas->info.kind) +
                          ": an instance names a BLAS (a TLAS cannot nest)");
        else if (!blas->info.built)
            add(what, name + ".blas " + accel_label(blas->label, AccelKind::Blas) +
                          " was never built: record build_blas before build_tlas");
        if (in.customIndex > kMaxCustomIndex)
            add(what, name + ".customIndex " + std::to_string(in.customIndex) + " does not fit in 24 bits (at most " +
                          std::to_string(kMaxCustomIndex) + ")");
        for (float v : in.transform)
            if (!std::isfinite(v)) {
                add(what, name + ".transform has a NaN or infinite value");
                break;
            }
        if (what.size() != before) ++problems;
    }
    const AccelSizes need = model_tlas_sizes(std::uint32_t(std::min<std::size_t>(n, 0xFFFFFFFFu)), b.flags);
    if (dst && dst->state == ResourceState::Valid && dst->info.kind == AccelKind::Tlas &&
        dst->info.size < need.structure)
        add(what, "dst " + accel_label(dst->label, AccelKind::Tlas) + " has " + std::to_string(dst->info.size) +
                      " bytes but " + std::to_string(n) + " instances need " + std::to_string(need.structure) +
                      " (AccelSizes::structure of tlas_sizes with the same flags)");
    const std::uint64_t scratchNeed = b.update ? need.updateScratch : need.buildScratch;
    if (b.update) {
        const AccelStructure srcHandle = b.src.valid() ? b.src : b.dst;
        const auto* src = s.accels.live(srcHandle.id);
        if (!src || src->state != ResourceState::Valid) {
            add(what, "src is " + s.accels.describe(srcHandle.id));
        } else if (src->info.kind != AccelKind::Tlas) {
            add(what, "src " + accel_label(src->label, src->info.kind) + " is a BLAS: a TLAS refits from a TLAS");
        } else if (!src->info.built) {
            add(what, "update of " + accel_label(src->label, AccelKind::Tlas) + ", which was never built");
        } else if (!src->info.allowUpdate) {
            add(what, "update of " + accel_label(src->label, AccelKind::Tlas) +
                          ", which was built without flags.allowUpdate");
        } else if (src->info.instances != n) {
            add(what, "update with " + std::to_string(n) + " instances, but " +
                          accel_label(src->label, AccelKind::Tlas) + " was built with " +
                          std::to_string(src->info.instances) + ": a refit keeps the count");
        }
        if (!b.flags.allowUpdate)
            add(what, "update with flags.allowUpdate false (pass the flags the TLAS was built with)");
    }
    const auto* scratch = s.buffers.live(b.scratch.id);
    if (!scratch || scratch->state != ResourceState::Valid) {
        add(what, "scratch is " + s.buffers.describe(b.scratch.id));
    } else {
        if (!scratch->info.usage.accelScratch)
            add(what, "scratch buffer " + quoted(scratch->label) + " was not made with usage.accelScratch");
        if (b.scratchOffset % kAccelAlign != 0)
            add(what, "scratchOffset " + std::to_string(b.scratchOffset) + " is not a multiple of " +
                          std::to_string(kAccelAlign) + " (Device::accel_scratch_alignment())");
        if (b.scratchOffset > scratch->info.size || scratch->info.size - b.scratchOffset < scratchNeed)
            add(what,
                "scratch buffer " + quoted(scratch->label) + " has " +
                    std::to_string(scratch->info.size > b.scratchOffset ? scratch->info.size - b.scratchOffset : 0) +
                    " bytes from scratchOffset " + std::to_string(b.scratchOffset) + ", but this " +
                    (b.update ? "update" : "build") + " needs " + std::to_string(scratchNeed) +
                    " (AccelSizes::" + (b.update ? "updateScratch" : "buildScratch") + ")");
    }
    if (!what.empty())
        return reject(cmd, what,
                      "build every BLAS the instances name first (and keep it alive), size the TLAS and the scratch "
                      "buffer from tlas_sizes() with the flags of the build, and keep the instance count within "
                      "Limits::maxAccelInstances");
    use_buffer(b.scratch);
    auto* d = s.accels.live(b.dst.id);
    d->info.built = true;
    d->info.allowUpdate = b.flags.allowUpdate;
    d->info.instances = std::uint32_t(n);
    record(CommandKind::BuildTlas, b.dst.id, {clamp_int(n), clamp_int(std::size_t(scratchNeed)), b.update ? 1 : 0},
           std::string("build_tlas ") + accel_label(d->label, AccelKind::Tlas) + " instances=" + std::to_string(n) +
               (b.update ? " update" : "") + " scratch=" + std::to_string(scratchNeed) + "B");
    return {};
}

Result<void> RecordingCommandList::query_compacted_size(AccelStructure blas, Buffer dstBuffer, std::size_t dstOffset) {
    const char* cmd = "query_compacted_size";
    if (!device_.features_.accelerationStructure)
        return accel_refusal(Backend::Recording, "CommandList::query_compacted_size");
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    if (passState_ != PassState::None)
        return reject(cmd, std::string("called ") + pass_state_name(passState_) + "; it goes outside a pass",
                      "end_pass() first");
    if (queue_ == QueueKind::Transfer)
        return reject(cmd, "called on a Transfer list", "record it on a Graphics or Compute list");
    std::string what;
    const auto* a = s.accels.live(blas.id);
    if (!a || a->state != ResourceState::Valid)
        add(what, "blas is " + s.accels.describe(blas.id));
    else if (a->info.kind != AccelKind::Blas)
        add(what, accel_label(a->label, a->info.kind) + " is a TLAS: only a BLAS is compacted");
    else if (!a->info.built)
        add(what, accel_label(a->label, AccelKind::Blas) + " was never built");
    else if (!a->info.allowCompaction)
        add(what, accel_label(a->label, AccelKind::Blas) + " was built without flags.allowCompaction");
    const auto* d = s.buffers.live(dstBuffer.id);
    if (!d || d->state != ResourceState::Valid) {
        add(what, "dst is " + s.buffers.describe(dstBuffer.id));
    } else {
        if (!d->info.usage.storageBuffer)
            add(what, "dst buffer " + quoted(d->label) + " was not made with usage.storageBuffer");
        if (dstOffset % 8 != 0) add(what, "dstOffset " + std::to_string(dstOffset) + " is not a multiple of 8");
        if (!fits(dstOffset, 8, d->info.size))
            add(what, "8 bytes at offset " + std::to_string(dstOffset) + " do not fit in buffer " + quoted(d->label) +
                          " (" + std::to_string(d->info.size) + " bytes)");
    }
    if (!what.empty())
        return reject(cmd, what,
                      "build the BLAS with flags.allowCompaction, and give a storage buffer with 8 bytes free at an "
                      "8-byte aligned offset");
    use_buffer(dstBuffer);
    {
        auto& answers = s.compactedAnswers;
        const std::uint64_t value = model_compacted_size(a->info.geometries, a->info.primitives);
        bool found = false;
        for (auto& ans : answers)
            if (ans.buffer == dstBuffer.id && ans.offset == dstOffset) {
                ans.value = value;
                found = true;
            }
        if (!found) answers.push_back({dstBuffer.id, dstOffset, value});
    }
    record(CommandKind::QueryCompactedSize, blas.id, {clamp_int(dstOffset)},
           "query_compacted_size " + accel_label(a->label, AccelKind::Blas) + " -> " +
               s.buffers.describe(dstBuffer.id) + " @" + std::to_string(dstOffset));
    return {};
}

Result<void> RecordingCommandList::copy_accel_structure(AccelStructure src, AccelStructure dst, AccelCopyMode mode) {
    const char* cmd = "copy_accel_structure";
    if (!device_.features_.accelerationStructure)
        return accel_refusal(Backend::Recording, "CommandList::copy_accel_structure");
    std::lock_guard<std::mutex> lock(device_.mutex_);
    auto& s = *device_.state_;
    if (passState_ != PassState::None)
        return reject(cmd, std::string("called ") + pass_state_name(passState_) + "; it goes outside a pass",
                      "end_pass() first");
    if (queue_ == QueueKind::Transfer)
        return reject(cmd, "called on a Transfer list", "record it on a Graphics or Compute list");
    std::string what;
    const auto* a = s.accels.live(src.id);
    const auto* b = s.accels.live(dst.id);
    if (!a || a->state != ResourceState::Valid) add(what, "src is " + s.accels.describe(src.id));
    if (!b || b->state != ResourceState::Valid) add(what, "dst is " + s.accels.describe(dst.id));
    if (a && b && a->state == ResourceState::Valid && b->state == ResourceState::Valid) {
        if (a->info.kind != b->info.kind)
            add(what, "src is a " + std::string(accel_kind_name(a->info.kind)) + " and dst a " +
                          accel_kind_name(b->info.kind));
        if (!a->info.built) add(what, accel_label(a->label, a->info.kind) + " was never built");
        if (mode == AccelCopyMode::Compact) {
            if (!a->info.allowCompaction)
                add(what, "Compact needs " + accel_label(a->label, a->info.kind) +
                              " built with flags.allowCompaction (it was not)");
            if (b->info.size > a->info.size)
                add(what, "Compact into " + accel_label(b->label, b->info.kind) + " of " +
                              std::to_string(b->info.size) + " bytes, larger than the source's " +
                              std::to_string(a->info.size) +
                              ": make the target with the size query_compacted_size answered");
        } else if (b->info.size < a->info.size) {
            add(what, "Clone into " + accel_label(b->label, b->info.kind) + " of " + std::to_string(b->info.size) +
                          " bytes, smaller than the source's " + std::to_string(a->info.size));
        }
    }
    if (!what.empty())
        return reject(cmd, what,
                      "copy a built structure into one of the same kind: Compact into a smaller one made with the "
                      "queried size (source built with allowCompaction), Clone into one at least as large");
    auto* d = s.accels.live(dst.id);
    d->info.built = true;
    d->info.allowUpdate = a->info.allowUpdate;
    d->info.allowCompaction = false;  // a compacted structure is not compacted again
    d->info.geometries = a->info.geometries;
    d->info.primitives = a->info.primitives;
    d->info.instances = a->info.instances;
    record(CommandKind::CopyAccelStructure, dst.id, {mode == AccelCopyMode::Compact ? 1 : 0},
           std::string("copy_accel_structure ") + accel_label(a->label, a->info.kind) + " -> " +
               accel_label(d->label, d->info.kind) + (mode == AccelCopyMode::Compact ? " compact" : " clone"));
    return {};
}

}  // namespace fa::gpu
