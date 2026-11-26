#include "command_capture.h"

#include <algorithm>
#include <cstring>

#include "fa/core/types.h"

namespace fa::render {

std::uint32_t CommandCapture::add_label(const char* label) {
    labels_.emplace_back(label ? label : "");
    return std::uint32_t(labels_.size() - 1);
}

std::size_t CommandCapture::add_bytes(const void* data, std::size_t size) {
    // 16-byte aligned (as the vector's storage is): a replayed uniform block or write may be read as floats or vec4.
    const std::size_t at = (bytes_.size() + 15) & ~std::size_t(15);
    if (size == 0 || !data) return at;
    bytes_.resize(at + size);
    std::memcpy(bytes_.data() + at, data, size);
    return at;
}

void CommandCapture::begin_pass(const gpu::PassDesc& pass) {
    FA_ASSERT(state_ == gpu::PassState::None, "CommandCapture::begin_pass inside a pass");
    // The desc is stored by value and replayed later: a pass into the window points at a Swapchain that is not owned and
    // is valid only for begin_pass, so a captured list never draws to the window.
    FA_ASSERT(!pass.swapchain, "CommandCapture::begin_pass: a captured pass cannot draw into the swapchain");
    Call c;
    c.op = Op::BeginPass;
    c.index = std::uint32_t(passes_.size());
    c.id = add_label(pass.label);
    passes_.push_back(pass);
    calls_.push_back(c);
    state_ = gpu::PassState::Render;
}

void CommandCapture::begin_compute_pass(const char* label) {
    FA_ASSERT(state_ == gpu::PassState::None, "CommandCapture::begin_compute_pass inside a pass");
    Call c;
    c.op = Op::BeginComputePass;
    c.index = add_label(label);
    calls_.push_back(c);
    state_ = gpu::PassState::Compute;
}

void CommandCapture::end_pass() {
    Call c;
    c.op = Op::EndPass;
    calls_.push_back(c);
    state_ = gpu::PassState::None;
}

void CommandCapture::set_pipeline(gpu::Pipeline pipeline) {
    Call c;
    c.op = Op::SetPipeline;
    c.id = pipeline.id;
    calls_.push_back(c);
}

void CommandCapture::set_bindings(const gpu::Bindings& bindings) {
    Call c;
    c.op = Op::SetBindings;
    c.index = std::uint32_t(bindings_.size());
    bindings_.push_back(bindings);
    calls_.push_back(c);
}

void CommandCapture::set_uniforms(int slot, gpu::Range data) {
    Call c;
    c.op = Op::SetUniforms;
    c.i[0] = slot;
    c.size = data.ptr ? data.size : 0;
    c.offset = add_bytes(data.ptr, c.size);
    calls_.push_back(c);
}

void CommandCapture::set_viewport(int x, int y, int width, int height, bool originTopLeft) {
    Call c;
    c.op = Op::SetViewport;
    c.i[0] = x;
    c.i[1] = y;
    c.i[2] = width;
    c.i[3] = height;
    c.i[4] = originTopLeft ? 1 : 0;
    calls_.push_back(c);
}

void CommandCapture::set_viewport_f(float x, float y, float width, float height, bool originTopLeft) {
    Call c;
    c.op = Op::SetViewportF;
    c.f[0] = x;
    c.f[1] = y;
    c.f[2] = width;
    c.f[3] = height;
    c.i[4] = originTopLeft ? 1 : 0;
    calls_.push_back(c);
}

void CommandCapture::set_scissor(int x, int y, int width, int height, bool originTopLeft) {
    Call c;
    c.op = Op::SetScissor;
    c.i[0] = x;
    c.i[1] = y;
    c.i[2] = width;
    c.i[3] = height;
    c.i[4] = originTopLeft ? 1 : 0;
    calls_.push_back(c);
}

void CommandCapture::draw(int base, int count, int instances) {
    Call c;
    c.op = Op::Draw;
    c.i[0] = base;
    c.i[1] = count;
    c.i[2] = instances;
    calls_.push_back(c);
}

void CommandCapture::draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) {
    Call c;
    c.op = Op::DrawEx;
    c.i[0] = base;
    c.i[1] = count;
    c.i[2] = instances;
    c.i[3] = baseVertex;
    c.i[4] = baseInstance;
    calls_.push_back(c);
}

void CommandCapture::dispatch(int x, int y, int z) {
    Call c;
    c.op = Op::Dispatch;
    c.i[0] = x;
    c.i[1] = y;
    c.i[2] = z;
    calls_.push_back(c);
}

void CommandCapture::write_buffer(const gpu::BufferWrite& write) {
    // The bytes the write reads (BufferWrite: `size` from data.ptr + srcOffset, 0 = the rest of `data`) are copied; the
    // replayed write reads them from offset 0 of the copy.
    gpu::BufferWrite w = write;
    const std::size_t avail = write.data.size > write.srcOffset ? write.data.size - write.srcOffset : 0;
    const std::size_t n = write.size ? std::min(write.size, avail) : avail;
    Call c;
    c.op = Op::WriteBuffer;
    c.index = std::uint32_t(writes_.size());
    c.size = write.data.ptr ? n : 0;  // no source: nothing copied, so the replay reads nothing past the copy
    c.offset = add_bytes(write.data.ptr ? static_cast<const unsigned char*>(write.data.ptr) + write.srcOffset : nullptr,
                         c.size);
    w.srcOffset = 0;
    w.size = write.size ? n : 0;
    writes_.push_back(w);
    calls_.push_back(c);
}

void CommandCapture::write_image(const gpu::ImageWrite& write) {
    gpu::ImageWrite w = write;
    const std::size_t avail = write.data.size > write.srcOffset ? write.data.size - write.srcOffset : 0;
    Call c;
    c.op = Op::WriteImage;
    c.index = std::uint32_t(imageWrites_.size());
    c.size = write.data.ptr ? avail : 0;
    c.offset = add_bytes(write.data.ptr ? static_cast<const unsigned char*>(write.data.ptr) + write.srcOffset : nullptr,
                         c.size);
    w.srcOffset = 0;
    imageWrites_.push_back(w);
    calls_.push_back(c);
}

void CommandCapture::copy_buffer_to_buffer(const gpu::BufferCopy& copy) {
    Call c;
    c.op = Op::CopyBufferToBuffer;
    c.index = std::uint32_t(bufferCopies_.size());
    bufferCopies_.push_back(copy);
    calls_.push_back(c);
}

void CommandCapture::copy_buffer_to_image(const gpu::BufferImageCopy& copy) {
    Call c;
    c.op = Op::CopyBufferToImage;
    c.index = std::uint32_t(imageCopies_.size());
    imageCopies_.push_back(copy);
    calls_.push_back(c);
}

void CommandCapture::push_debug_group(const char* name) {
    Call c;
    c.op = Op::PushDebugGroup;
    c.index = add_label(name);
    calls_.push_back(c);
}

void CommandCapture::pop_debug_group() {
    Call c;
    c.op = Op::PopDebugGroup;
    calls_.push_back(c);
}

void CommandCapture::begin_timed_scope(const char* name) {
    Call c;
    c.op = Op::BeginTimedScope;
    c.index = add_label(name);
    calls_.push_back(c);
}

void CommandCapture::end_timed_scope() {
    Call c;
    c.op = Op::EndTimedScope;
    calls_.push_back(c);
}

Result<gpu::NativeCommands> CommandCapture::begin_native(std::span<const gpu::NativeUse>) {
    return make_error("gpu: CommandList::begin_native on a CommandCapture: a capture records no native commands",
                      "it is replayed later on a job thread: open the native section on the real list (the one "
                      "replay() records on), outside the capture");
}

namespace {
Error capture_accel_refusal(const char* call) {
    return Error{std::string("gpu: CommandList::") + call +
                     " on a CommandCapture: a capture records no acceleration structure commands",
                 "it is replayed later on a job thread: build, compact and copy acceleration structures on the real "
                 "list (the one replay() records on), outside the capture"};
}
}  // namespace

Result<void> CommandCapture::build_blas(const gpu::BlasBuild&) { return capture_accel_refusal("build_blas"); }
Result<void> CommandCapture::build_tlas(const gpu::TlasBuild&) { return capture_accel_refusal("build_tlas"); }
Result<void> CommandCapture::query_compacted_size(gpu::AccelStructure, gpu::Buffer, std::size_t) {
    return capture_accel_refusal("query_compacted_size");
}
Result<void> CommandCapture::copy_accel_structure(gpu::AccelStructure, gpu::AccelStructure, gpu::AccelCopyMode) {
    return capture_accel_refusal("copy_accel_structure");
}

void CommandCapture::replay(gpu::CommandList& list) const {
    for (const Call& c : calls_) {
        switch (c.op) {
            case Op::BeginPass: {
                gpu::PassDesc p = passes_[c.index];
                p.label = labels_[c.id].c_str();
                list.begin_pass(p);
                break;
            }
            case Op::BeginComputePass: list.begin_compute_pass(labels_[c.index].c_str()); break;
            case Op::EndPass: list.end_pass(); break;
            case Op::SetPipeline: list.set_pipeline(gpu::Pipeline{c.id}); break;
            case Op::SetBindings: list.set_bindings(bindings_[c.index]); break;
            case Op::SetUniforms:
                list.set_uniforms(c.i[0], gpu::Range{c.size ? bytes_.data() + c.offset : nullptr, c.size});
                break;
            case Op::SetViewport: list.set_viewport(c.i[0], c.i[1], c.i[2], c.i[3], c.i[4] != 0); break;
            case Op::SetViewportF: list.set_viewport_f(c.f[0], c.f[1], c.f[2], c.f[3], c.i[4] != 0); break;
            case Op::SetScissor: list.set_scissor(c.i[0], c.i[1], c.i[2], c.i[3], c.i[4] != 0); break;
            case Op::Draw: list.draw(c.i[0], c.i[1], c.i[2]); break;
            case Op::DrawEx: list.draw_ex(c.i[0], c.i[1], c.i[2], c.i[3], c.i[4]); break;
            case Op::Dispatch: list.dispatch(c.i[0], c.i[1], c.i[2]); break;
            case Op::WriteBuffer: {
                gpu::BufferWrite w = writes_[c.index];
                w.data = gpu::Range{c.size ? bytes_.data() + c.offset : nullptr, c.size};
                list.write_buffer(w);
                break;
            }
            case Op::WriteImage: {
                gpu::ImageWrite w = imageWrites_[c.index];
                w.data = gpu::Range{c.size ? bytes_.data() + c.offset : nullptr, c.size};
                list.write_image(w);
                break;
            }
            case Op::CopyBufferToBuffer: list.copy_buffer_to_buffer(bufferCopies_[c.index]); break;
            case Op::CopyBufferToImage: list.copy_buffer_to_image(imageCopies_[c.index]); break;
            case Op::PushDebugGroup: list.push_debug_group(labels_[c.index].c_str()); break;
            case Op::PopDebugGroup: list.pop_debug_group(); break;
            case Op::BeginTimedScope: list.begin_timed_scope(labels_[c.index].c_str()); break;
            case Op::EndTimedScope: list.end_timed_scope(); break;
        }
    }
}

void CommandCapture::clear() {
    state_ = gpu::PassState::None;
    calls_.clear();
    passes_.clear();
    bindings_.clear();
    writes_.clear();
    imageWrites_.clear();
    bufferCopies_.clear();
    imageCopies_.clear();
    labels_.clear();
    bytes_.clear();
}

}  // namespace fa::render
