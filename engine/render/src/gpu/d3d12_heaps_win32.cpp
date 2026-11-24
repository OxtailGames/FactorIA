// The D3D12 backend's descriptor heaps (CPU heaps with free lists, the shader-visible per-frame rings) and its upload
// ring (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include <string>
#include <utility>

#include "gpu/d3d12_device.h"

namespace fa::gpu::d3d12 {

namespace {

Result<Com<ID3D12DescriptorHeap>> make_heap(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, std::uint32_t n,
                                            bool shaderVisible, const char* name) {
    D3D12_DESCRIPTOR_HEAP_DESC d{};
    d.Type = type;
    d.NumDescriptors = n;
    d.Flags = shaderVisible ? D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE : D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
    Com<ID3D12DescriptorHeap> heap;
    const HRESULT hr = device->CreateDescriptorHeap(&d, __uuidof(ID3D12DescriptorHeap), heap.put_void());
    if (FAILED(hr) || !heap)
        return make_error(std::string("gpu d3d12: CreateDescriptorHeap (") + name + ", " + std::to_string(n) +
                              " descriptors" + (shaderVisible ? ", shader-visible" : "") + ") failed with " +
                              hr_text(hr),
                          "lower the D3d12Options descriptor counts, or the device was lost");
    heap->SetName(widen(name).c_str());
    return heap;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// CpuDescriptorHeap
// ---------------------------------------------------------------------------------------------------------------------

Result<void> CpuDescriptorHeap::init(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, std::uint32_t capacity,
                                     const char* name) {
    auto heap = make_heap(device, type, capacity, false, name);
    if (!heap) return heap.error();
    std::lock_guard<std::mutex> lock(mutex_);
    heap_ = heap.value();
    start_ = heap_->GetCPUDescriptorHandleForHeapStart();
    increment_ = device->GetDescriptorHandleIncrementSize(type);
    capacity_ = capacity;
    next_ = 0;
    used_ = 0;
    free_.clear();
    name_ = name;
    return {};
}

std::uint32_t CpuDescriptorHeap::alloc() {
    std::lock_guard<std::mutex> lock(mutex_);
    std::uint32_t i = kNoDescriptor;
    if (!free_.empty()) {
        i = free_.back();
        free_.pop_back();
    } else if (next_ < capacity_) {
        i = next_++;
    } else {
        return kNoDescriptor;
    }
    ++used_;
    return i;
}

void CpuDescriptorHeap::free(std::uint32_t index) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (index >= next_) return;
    free_.push_back(index);
    --used_;
}

D3D12_CPU_DESCRIPTOR_HANDLE CpuDescriptorHeap::cpu(std::uint32_t index) const {
    D3D12_CPU_DESCRIPTOR_HANDLE h = start_;
    h.ptr += SIZE_T(index) * SIZE_T(increment_);
    return h;
}

std::uint32_t CpuDescriptorHeap::used() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return used_;
}

// ---------------------------------------------------------------------------------------------------------------------
// ShaderVisibleHeap
// ---------------------------------------------------------------------------------------------------------------------

Result<void> ShaderVisibleHeap::init(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, std::uint32_t reserved,
                                     std::uint32_t perFrame, int frames, const char* name) {
    auto heap = make_heap(device, type, reserved + perFrame * std::uint32_t(frames), true, name);
    if (!heap) return heap.error();
    std::lock_guard<std::mutex> lock(mutex_);
    heap_ = heap.value();
    cpuStart_ = heap_->GetCPUDescriptorHandleForHeapStart();
    gpuStart_ = heap_->GetGPUDescriptorHandleForHeapStart();
    increment_ = device->GetDescriptorHandleIncrementSize(type);
    reserved_ = reserved;
    perFrame_ = perFrame;
    slot_ = 0;
    used_ = 0;
    return {};
}

ShaderVisibleHeap::Span ShaderVisibleHeap::span(std::uint32_t index, std::uint32_t count) const {
    Span s;
    s.index = index;
    s.count = count;
    s.cpu = cpuStart_;
    s.cpu.ptr += SIZE_T(index) * SIZE_T(increment_);
    s.gpu = gpuStart_;
    s.gpu.ptr += UINT64(index) * UINT64(increment_);
    return s;
}

ShaderVisibleHeap::Span ShaderVisibleHeap::alloc(std::uint32_t count) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (count == 0 || !heap_ || count > perFrame_ - used_) return {};
    const std::uint32_t index = reserved_ + std::uint32_t(slot_) * perFrame_ + used_;
    used_ += count;
    return span(index, count);
}

void ShaderVisibleHeap::begin_frame(int slot) {
    std::lock_guard<std::mutex> lock(mutex_);
    slot_ = slot;
    used_ = 0;
}

ShaderVisibleHeap::Span ShaderVisibleHeap::reserved() const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (reserved_ == 0) return {};
    return span(0, reserved_);
}

std::uint32_t ShaderVisibleHeap::frame_used() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return used_;
}

// ---------------------------------------------------------------------------------------------------------------------
// UploadRing
// ---------------------------------------------------------------------------------------------------------------------

Result<void> UploadRing::init(ID3D12Device* device, std::size_t bytes) {
    D3D12_HEAP_PROPERTIES hp{};
    hp.Type = D3D12_HEAP_TYPE_UPLOAD;
    hp.CreationNodeMask = 1;
    hp.VisibleNodeMask = 1;
    D3D12_RESOURCE_DESC d{};
    d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    d.Width = bytes;
    d.Height = 1;
    d.DepthOrArraySize = 1;
    d.MipLevels = 1;
    d.Format = DXGI_FORMAT_UNKNOWN;
    d.SampleDesc.Count = 1;
    d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    Com<ID3D12Resource> buffer;
    HRESULT hr = device->CreateCommittedResource(&hp, D3D12_HEAP_FLAG_NONE, &d, D3D12_RESOURCE_STATE_GENERIC_READ,
                                                 nullptr, __uuidof(ID3D12Resource), buffer.put_void());
    if (FAILED(hr) || !buffer)
        return make_error("gpu d3d12: the upload ring (" + std::to_string(bytes) +
                              " bytes): CreateCommittedResource failed with " + hr_text(hr),
                          "lower D3d12Options::uploadRingBytes, or the device was lost");
    buffer->SetName(L"fa-d3d12-upload-ring");
    void* p = nullptr;
    const D3D12_RANGE none{0, 0};  // the CPU never reads it
    hr = buffer->Map(0, &none, &p);
    if (FAILED(hr) || !p)
        return make_error("gpu d3d12: the upload ring: ID3D12Resource::Map failed with " + hr_text(hr),
                          "the process ran out of address space, or the device was lost");
    std::lock_guard<std::mutex> lock(mutex_);
    buffer_ = std::move(buffer);
    cpu_ = static_cast<std::uint8_t*>(p);
    gpu_ = buffer_->GetGPUVirtualAddress();
    size_ = bytes;
    head_ = tail_ = wraps_ = 0;
    frames_.clear();
    return {};
}

bool UploadRing::alloc(std::size_t size, std::size_t align, UploadAlloc& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!buffer_ || size == 0 || size > size_ || align == 0) return false;
    const std::uint64_t ring = size_;
    const std::uint64_t pos = head_ % ring;
    std::uint64_t start = head_ + ((align - pos % align) % align);  // aligned position (ring and align are powers of 2)
    if (start % ring + size > ring || start % ring < pos) {
        // No room before the end: the rest of the ring is skipped and the allocation starts at its beginning.
        start = head_ + (ring - pos);
        if (start + size - tail_ > ring) return false;
        ++wraps_;
    }
    if (start + size - tail_ > ring) return false;
    head_ = start + size;
    out.resource = buffer_.get();
    out.offset = start % ring;
    out.cpu = cpu_ + out.offset;
    out.gpu = gpu_ + out.offset;
    return true;
}

void UploadRing::end_frame(std::uint64_t frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frames_.emplace_back(frame, head_);
}

void UploadRing::frame_done(std::uint64_t frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    while (!frames_.empty() && frames_.front().first <= frame) {
        tail_ = frames_.front().second;
        frames_.pop_front();
    }
}

std::uint64_t UploadRing::wraps() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return wraps_;
}

std::size_t UploadRing::in_use() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return std::size_t(head_ - tail_);
}

}  // namespace fa::gpu::d3d12
