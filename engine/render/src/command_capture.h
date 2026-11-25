// A command list that runs nothing: it keeps every call (and a copy of the bytes each call points at) so that replay()
// can record the same calls on a real list later, on another thread (M77-P10d, the parallel recording of the shadow
// views; docs/design/ARCHITECTURE_RENDERING_QUEUES.md, "Shadow views on job threads").
//
// Why a capture and not the draw loop itself on a job: the loop that decides a shadow view's draws reads and writes the
// renderer's own state (the pipeline cache makes pipelines, which is render-thread work on every device; the asset caches;
// the statistics). What a device spends its time on is the encoding of the calls (descriptor sets, the uniform ring,
// vkCmd* and the D3D12 command lists), and that is what replay() does on the job threads, each into a list of its own.
// The replay calls the list in the order the capture saw them, with the same arguments: the recorded list is the one the
// draw loop would have made.
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

#include "gpu/device.h"

namespace fa::render {

class CommandCapture final : public gpu::CommandList {
public:
    CommandCapture() = default;
    CommandCapture(const CommandCapture&) = delete;
    CommandCapture& operator=(const CommandCapture&) = delete;

    void begin_pass(const gpu::PassDesc& pass) override;
    void begin_compute_pass(const char* label) override;
    void end_pass() override;
    gpu::PassState pass_state() const override { return state_; }
    void set_pipeline(gpu::Pipeline pipeline) override;
    void set_bindings(const gpu::Bindings& bindings) override;
    void set_uniforms(int slot, gpu::Range data) override;
    void set_viewport(int x, int y, int width, int height, bool originTopLeft = true) override;
    void set_viewport_f(float x, float y, float width, float height, bool originTopLeft = true) override;
    void set_scissor(int x, int y, int width, int height, bool originTopLeft = true) override;
    void draw(int base, int count, int instances = 1) override;
    void draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) override;
    void dispatch(int x, int y, int z) override;
    void write_buffer(const gpu::BufferWrite& write) override;
    void write_image(const gpu::ImageWrite& write) override;
    void copy_buffer_to_buffer(const gpu::BufferCopy& copy) override;
    void copy_buffer_to_image(const gpu::BufferImageCopy& copy) override;
    void push_debug_group(const char* name) override;
    void pop_debug_group() override;
    void begin_timed_scope(const char* name) override;
    void end_timed_scope() override;
    // A capture is replayed later and on another thread: native commands cannot be kept (the answer names the capture).
    Result<gpu::NativeCommands> begin_native(std::span<const gpu::NativeUse> uses) override;

    // Records every captured call on `list`, in order. Reads only this capture (any thread, once the capture is done).
    void replay(gpu::CommandList& list) const;
    // How many calls were captured.
    std::size_t size() const { return calls_.size(); }
    // Forgets every call (the memory is kept for the next frame).
    void clear();

private:
    enum class Op : std::uint8_t {
        BeginPass,
        BeginComputePass,
        EndPass,
        SetPipeline,
        SetBindings,
        SetUniforms,
        SetViewport,
        SetViewportF,
        SetScissor,
        Draw,
        DrawEx,
        Dispatch,
        WriteBuffer,
        WriteImage,
        CopyBufferToBuffer,
        CopyBufferToImage,
        PushDebugGroup,
        PopDebugGroup,
        BeginTimedScope,
        EndTimedScope,
    };
    struct Call {
        Op op = Op::EndPass;
        std::uint32_t index =
            0;         // into passes_, bindings_, writes_, imageWrites_, bufferCopies_, imageCopies_ or labels_
        int i[5]{};    // the integer arguments (the slot of set_uniforms, the bool of a viewport as 0/1)
        float f[4]{};  // set_viewport_f
        std::size_t offset = 0, size = 0;  // the bytes of set_uniforms / a write in bytes_
        std::uint32_t id = 0;              // set_pipeline's pipeline
    };
    std::uint32_t add_label(const char* label);
    std::size_t add_bytes(const void* data, std::size_t size);

    gpu::PassState state_ = gpu::PassState::None;
    std::vector<Call> calls_;
    std::vector<gpu::PassDesc> passes_;  // `label` re-pointed at labels_ by replay()
    std::vector<gpu::Bindings> bindings_;
    std::vector<gpu::BufferWrite> writes_;      // `data` re-pointed at bytes_ by replay()
    std::vector<gpu::ImageWrite> imageWrites_;  // the same
    std::vector<gpu::BufferCopy> bufferCopies_;
    std::vector<gpu::BufferImageCopy> imageCopies_;
    std::vector<std::string> labels_;
    std::vector<unsigned char> bytes_;
};

}  // namespace fa::render
