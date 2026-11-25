#include "streamline_runtime.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cfloat>
#include <cstdlib>
#include <cstring>
#include <iterator>
#include <mutex>
#include <utility>

#include "fa/core/build_info.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <dxgi.h>
#endif

namespace fa::render {

namespace sl_abi {
namespace {

// The GUIDs and the versions of the structures (SL_STRUCT_BEGIN of sl_core_types.h, sl_consts.h, sl_dlss.h, sl_helpers_vk.h).
constexpr StructType kPreferencesType{0x1ca10965, 0xbf8e, 0x432b, {0x8d, 0xa1, 0x67, 0x16, 0xd8, 0x79, 0xfb, 0x14}};
constexpr StructType kViewportType{0x171b6435, 0x9b3c, 0x4fc8, {0x99, 0x94, 0xfb, 0xe5, 0x25, 0x69, 0xaa, 0xa4}};
constexpr StructType kRequirementsType{0x66714097, 0xac6d, 0x4bc6, {0x89, 0x15, 0x1e, 0x0f, 0x55, 0xa6, 0xb6, 0x1f}};
constexpr StructType kAdapterType{0x0677315f, 0xa746, 0x4492, {0x9f, 0x42, 0xcb, 0x61, 0x42, 0xc9, 0xc3, 0xd4}};
constexpr StructType kResourceType{0x3a9d70cf, 0x2418, 0x4b72, {0x83, 0x91, 0x13, 0xf8, 0x72, 0x1c, 0x72, 0x61}};
constexpr StructType kTagType{0x4c6a5aad, 0xb445, 0x496c, {0x87, 0xff, 0x1a, 0xf3, 0x84, 0x5b, 0xe6, 0x53}};
constexpr StructType kConstantsType{0xdcd35ad7, 0x4e4a, 0x4bad, {0xa9, 0x0c, 0xe0, 0xc4, 0x9e, 0xb2, 0x3a, 0xfe}};
constexpr StructType kDlssOptionsType{0x6ac826e4, 0x4c61, 0x4101, {0xa9, 0x2d, 0x63, 0x8d, 0x42, 0x10, 0x57, 0xb8}};
constexpr StructType kDlssOptimalType{0xef1d0957, 0xfd58, 0x4df7, {0xb5, 0x04, 0x8b, 0x69, 0xd8, 0xaa, 0x6b, 0x76}};
constexpr StructType kDlssdOptionsType{0x0ad87504, 0x774e, 0x4bf3, {0x96, 0x33, 0xa4, 0x4d, 0x1f, 0x7f, 0x9c, 0xb8}};
constexpr StructType kDlssdOptimalType{0xfbd0c637, 0xa28f, 0x41f2, {0xbc, 0x91, 0xb4, 0x21, 0xfa, 0xee, 0x8e, 0x1e}};
constexpr StructType kReflexOptionsType{0xf03af81a, 0x6d0b, 0x4902, {0xa6, 0x51, 0xc4, 0x96, 0x5e, 0x21, 0x54, 0x34}};
constexpr StructType kReflexReportType{0x0d569b37, 0xa1c8, 0x4453, {0xbe, 0x4d, 0x40, 0xf4, 0xde, 0x57, 0x95, 0x2b}};
constexpr StructType kReflexReport2Type{0x68bb0632, 0x5e1c, 0x402b, {0x89, 0x9d, 0xb4, 0x9f, 0x63, 0x3c, 0x56, 0xc2}};
constexpr StructType kReflexStateType{0xf0bb5985, 0xdaf9, 0x4728, {0xb2, 0xfd, 0xae, 0x80, 0xa2, 0xbd, 0x79, 0x89}};
constexpr StructType kDlssgOptionsType{0xfac5f1cb, 0x2dfd, 0x4f36, {0xa1, 0xe6, 0x3a, 0x9e, 0x86, 0x52, 0x56, 0xc5}};
constexpr StructType kDlssgStateType{0xcc8ac8e1, 0xa179, 0x44f5, {0x97, 0xfa, 0xe7, 0x41, 0x12, 0xf9, 0xbc, 0x61}};
constexpr StructType kVulkanInfoType{0x0eed6fd5, 0x82cd, 0x43a9, {0xbd, 0xb5, 0x47, 0xa5, 0xba, 0x2f, 0x45, 0xd6}};

void set_base(Base& b, const StructType& type, std::uint64_t version) {
    b.next = nullptr;
    b.type = type;
    b.version = version;
}

}  // namespace

void init_preferences(Preferences& p) {
    std::memset(&p, 0, sizeof p);
    set_base(p.base, kPreferencesType, 1);
    p.logLevel = 1;
}
void init_viewport(ViewportHandle& v, std::uint32_t id) {
    std::memset(&v, 0, sizeof v);
    set_base(v.base, kViewportType, 1);
    v.value = id;
}
void init_feature_requirements(FeatureRequirements& r) {
    std::memset(&r, 0, sizeof r);
    set_base(r.base, kRequirementsType, 2);
}
void init_adapter_info(AdapterInfo& a) {
    std::memset(&a, 0, sizeof a);
    set_base(a.base, kAdapterType, 1);
}
void init_resource(Resource& r) {
    std::memset(&r, 0, sizeof r);
    set_base(r.base, kResourceType, 1);
    r.type = kResourceTex2d;
    r.state = 0xFFFFFFFFu;  // UINT_MAX: the state is not given (the tag carries it for the frame)
}
void init_resource_tag(ResourceTag& t) {
    std::memset(&t, 0, sizeof t);
    set_base(t.base, kTagType, 1);
}
std::uint32_t streamline_application_id(const char* text) {
    if (!text || !*text) return 0;
    std::uint64_t v = 0;
    for (const char* p = text; *p; ++p) {
        if (*p < '0' || *p > '9') return 0;
        v = v * 10 + std::uint64_t(*p - '0');
        if (v > 0xFFFFFFFFull) return 0;
    }
    return static_cast<std::uint32_t>(v);
}
std::string streamline_project_id(const char* text) {
    // xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    bool guid = text && std::strlen(text) == 36;
    for (std::size_t i = 0; guid && i < 36; ++i) {
        const char ch = text[i];
        const bool dash = i == 8 || i == 13 || i == 18 || i == 23;
        guid = dash ? ch == '-' : (std::isxdigit(static_cast<unsigned char>(ch)) != 0);
    }
    return guid ? std::string(text) : std::string(kDefaultProjectId);
}
void init_constants(Constants& c) {
    std::memset(&c, 0, sizeof c);
    set_base(c.base, kConstantsType, 2);
    for (Float4x4* m :
         {&c.cameraViewToClip, &c.clipToCameraView, &c.clipToLensClip, &c.clipToPrevClip, &c.prevClipToClip}) {
        m->row[0] = {1, 0, 0, 0};
        m->row[1] = {0, 1, 0, 0};
        m->row[2] = {0, 0, 1, 0};
        m->row[3] = {0, 0, 0, 1};
    }
    // The header's own defaults for what a caller does not set: INVALID_FLOAT (FLT_MAX) for every vector and plane, eInvalid for the four flags
    // Streamline wants said (depthInverted, cameraMotionIncluded, motionVectors3d, reset) and eFalse for the three optional ones.
    const Float2 none2{FLT_MAX, FLT_MAX};
    const Float3 none3{FLT_MAX, FLT_MAX, FLT_MAX};
    c.jitterOffset = c.mvecScale = c.cameraPinholeOffset = none2;
    c.cameraPos = c.cameraUp = c.cameraRight = c.cameraFwd = none3;
    c.cameraNear = c.cameraFar = c.cameraFov = c.cameraAspectRatio = c.motionVectorsInvalidValue = FLT_MAX;
    c.depthInverted = c.cameraMotionIncluded = c.motionVectors3d = c.reset = kInvalid;
    c.orthographicProjection = c.motionVectorsDilated = c.motionVectorsJittered = kFalse;
    c.minRelativeLinearDepthObjectSeparation = 40.0f;
}
void init_dlss_options(DlssOptions& o) {
    std::memset(&o, 0, sizeof o);
    set_base(o.base, kDlssOptionsType, 3);
    o.outputWidth = o.outputHeight = 0xFFFFFFFFu;  // INVALID_UINT
    o.preExposure = o.exposureScale = 1.0f;
}
void init_dlss_optimal_settings(DlssOptimalSettings& s) {
    std::memset(&s, 0, sizeof s);
    set_base(s.base, kDlssOptimalType, 1);
}
void init_dlssd_options(DlssdOptions& o) {
    std::memset(&o, 0, sizeof o);
    set_base(o.base, kDlssdOptionsType, 3);
    o.outputWidth = o.outputHeight = 0xFFFFFFFFu;  // INVALID_UINT
    o.preExposure = o.exposureScale = 1.0f;
    o.colorBuffersHdr = kTrue;  // the header's default
    for (Float4x4* m : {&o.worldToCameraView, &o.cameraViewToWorld}) {
        m->row[0].x = 1.0f;
        m->row[1].y = 1.0f;
        m->row[2].z = 1.0f;
        m->row[3].w = 1.0f;
    }
}
void init_dlssd_optimal_settings(DlssdOptimalSettings& s) {
    std::memset(&s, 0, sizeof s);
    set_base(s.base, kDlssdOptimalType, 1);
}
void init_vulkan_info(VulkanInfo& v) {
    std::memset(&v, 0, sizeof v);
    set_base(v.base, kVulkanInfoType, 3);
}
void init_reflex_options(ReflexOptions& o) {
    std::memset(&o, 0, sizeof o);
    set_base(o.base, kReflexOptionsType, 1);
    o.mode = kReflexOff;
}
void init_reflex_state(ReflexState& s) {
    std::memset(&s, 0, sizeof s);
    set_base(s.base, kReflexStateType, 2);
    for (ReflexReport& r : s.frameReport) set_base(r.base, kReflexReportType, 1);
    for (ReflexReport2& r : s.frameReport2) set_base(r.base, kReflexReport2Type, 1);
}

void init_dlssg_options(DlssgOptions& o) {
    std::memset(&o, 0, sizeof o);
    set_base(o.base, kDlssgOptionsType, 5);
    o.mode = kDlssgOff;
    o.numFramesToGenerate = 1;
    o.bReserved15 = kInvalid;
    o.enableUserInterfaceRecomposition = kFalse;
}
void init_dlssg_state(DlssgState& s) {
    std::memset(&s, 0, sizeof s);
    set_base(s.base, kDlssgStateType, 4);
}

}  // namespace sl_abi

namespace {

using namespace sl_abi;

constexpr std::uint32_t kNvidiaVendorId = 0x10DE;
// kSDKVersion of sl.h: (major << 48) | (minor << 32) | (build << 16) | 0xfedc.
constexpr std::uint64_t kSdkVersion =
    (std::uint64_t(2) << 48) | (std::uint64_t(14) << 32) | (std::uint64_t(16) << 16) | 0xfedcu;
constexpr VendorLibrarySpec kStreamlineSpec{"streamline", "FA_STREAMLINE_DIR", "sl.interposer.dll"};

template <class Fn>
void bind(VendorLibrary& lib, const char* name, Fn& fn, std::string& missing) {
    void* address = lib.symbol(name);
    if (!address) {
        if (missing.empty()) missing = name;
        return;
    }
    fn = reinterpret_cast<Fn>(address);  // NOLINT: the export's address
}

void log_callback(std::uint32_t type, const char* message) {
    std::string text = message ? message : "";
    while (!text.empty() && (text.back() == '\n' || text.back() == '\r')) text.pop_back();
    if (type == kLogError)
        FA_ERROR("render", "Streamline: {}", text);
    else if (type == kLogWarn)
        FA_WARN("render", "Streamline: {}", text);
    else
        FA_DEBUG("render", "Streamline: {}", text);
}

constexpr const char* kResultNames[] = {
    "ok",
    "I/O error",
    "driver out of date",
    "OS out of date",
    "OS has hardware-accelerated GPU scheduling disabled",
    "device not created",
    "no supported adapter found",
    "adapter not supported",
    "no plugins found",
    "Vulkan API error",
    "DXGI API error",
    "D3D API error",
    "NRD API error",
    "NVAPI error",
    "Reflex API error",
    "NGX failed",
    "JSON parsing error",
    "missing proxy",
    "missing resource state",
    "invalid integration",
    "missing input parameter",
    "not initialized",
    "compute failed",
    "init not called",
    "exception handler",
    "invalid parameter",
    "missing constants",
    "duplicated constants",
    "missing or invalid API",
    "common constants missing",
    "unsupported interface",
    "feature missing",
    "feature not supported",
    "feature missing hooks",
    "feature failed to load",
    "feature wrong priority",
    "feature missing dependency",
    "feature manager invalid state",
    "invalid state",
    "out of VRAM (warning)",
};

const char* result_hint(Result r, std::uint32_t feature) {
    switch (r) {
        case kErrorDriverOutOfDate:
            return "Update the NVIDIA graphics driver (DLSS needs a recent Game Ready or Studio driver).";
        case kErrorOSOutOfDate: return "Update Windows.";
        case kErrorOSDisabledHWS:
            return "Turn on \"Hardware-accelerated GPU scheduling\" in Windows' graphics settings and restart.";
        case kErrorNoSupportedAdapterFound:
        case kErrorAdapterNotSupported:
        case kErrorFeatureNotSupported:
            switch (feature) {
                case kFeatureDlss:
                case kFeatureDlssRr:
                    return "DLSS needs an NVIDIA RTX GPU with a driver that supports it; for DLSS on any other GPU use "
                           "the XeSS, FSR or "
                           "temporal upscaler.";
                case kFeatureDlssG:
                    return "DLSS frame generation needs an NVIDIA RTX GPU with a driver that supports it (and Reflex); "
                           "for frame generation "
                           "on any other GPU use the FSR 3 or XeSS provider.";
                case kFeatureReflex:
                case kFeaturePcl:
                    return "Reflex needs an NVIDIA GeForce GTX 900 series or newer GPU with a driver that supports it; "
                           "on any other GPU "
                           "choose another render.latency mode (the engine's own pacing runs where Reflex cannot).";
                default: break;
            }
            return "DLSS needs an NVIDIA RTX GPU and Reflex a GeForce GTX 900 series or newer, with a driver that "
                   "supports it; "
                   "for DLSS on any other GPU use the XeSS, FSR or temporal upscaler.";
        case kErrorNoPlugins:
        case kErrorFeatureMissing:
        case kErrorFeatureFailedToLoad:
            return "A plugin library of Streamline (sl.dlss.dll, sl.dlss_g.dll, sl.reflex.dll, sl.pcl.dll, "
                   "sl.common.dll, "
                   "nvngx_dlss.dll, nvngx_dlssg.dll) is missing next to sl.interposer.dll: run `factoria setup "
                   "streamline` "
                   "to install the whole set again.";
        case kErrorFeatureMissingDependency:
        case kErrorMissingProxy:
            return "Streamline could not hook the graphics device: this is a bug in the engine's integration, please "
                   "report it.";
        default: return "";
    }
}

bool contains(const std::vector<std::string>& list, const std::string& name) {
    return std::find(list.begin(), list.end(), name) != list.end();
}
void add_unique(std::vector<std::string>& list, const std::string& name) {
    if (!contains(list, name)) list.push_back(name);
}
std::string join(const std::vector<std::string>& names) {
    std::string out;
    for (const std::string& n : names) out += (out.empty() ? "" : ", ") + n;
    return out;
}
std::vector<std::string> names_of(const char** names, std::uint32_t count) {
    std::vector<std::string> out;
    if (!names) return out;
    for (std::uint32_t i = 0; i < count && i < 256; ++i)
        if (names[i]) out.emplace_back(names[i]);
    return out;
}
std::string feature_label(std::uint32_t feature) {
    switch (feature) {
        case kFeatureDlss: return "DLSS";
        case kFeatureDlssRr: return "DLSS Ray Reconstruction";
        case kFeatureReflex: return "Reflex";
        case kFeaturePcl: return "PC latency";
        case kFeatureDlssG: return "DLSS frame generation";
        default: return "Streamline feature " + std::to_string(feature);
    }
}

// The member names of VkPhysicalDeviceVulkan12Features / Vulkan13Features, in the order of their VkBool32 members.
constexpr const char* kVulkan12Members[] = {"samplerMirrorClampToEdge",
                                            "drawIndirectCount",
                                            "storageBuffer8BitAccess",
                                            "uniformAndStorageBuffer8BitAccess",
                                            "storagePushConstant8",
                                            "shaderBufferInt64Atomics",
                                            "shaderSharedInt64Atomics",
                                            "shaderFloat16",
                                            "shaderInt8",
                                            "descriptorIndexing",
                                            "shaderInputAttachmentArrayDynamicIndexing",
                                            "shaderUniformTexelBufferArrayDynamicIndexing",
                                            "shaderStorageTexelBufferArrayDynamicIndexing",
                                            "shaderUniformBufferArrayNonUniformIndexing",
                                            "shaderSampledImageArrayNonUniformIndexing",
                                            "shaderStorageBufferArrayNonUniformIndexing",
                                            "shaderStorageImageArrayNonUniformIndexing",
                                            "shaderInputAttachmentArrayNonUniformIndexing",
                                            "shaderUniformTexelBufferArrayNonUniformIndexing",
                                            "shaderStorageTexelBufferArrayNonUniformIndexing",
                                            "descriptorBindingUniformBufferUpdateAfterBind",
                                            "descriptorBindingSampledImageUpdateAfterBind",
                                            "descriptorBindingStorageImageUpdateAfterBind",
                                            "descriptorBindingStorageBufferUpdateAfterBind",
                                            "descriptorBindingUniformTexelBufferUpdateAfterBind",
                                            "descriptorBindingStorageTexelBufferUpdateAfterBind",
                                            "descriptorBindingUpdateUnusedWhilePending",
                                            "descriptorBindingPartiallyBound",
                                            "descriptorBindingVariableDescriptorCount",
                                            "runtimeDescriptorArray",
                                            "samplerFilterMinmax",
                                            "scalarBlockLayout",
                                            "imagelessFramebuffer",
                                            "uniformBufferStandardLayout",
                                            "shaderSubgroupExtendedTypes",
                                            "separateDepthStencilLayouts",
                                            "hostQueryReset",
                                            "timelineSemaphore",
                                            "bufferDeviceAddress",
                                            "bufferDeviceAddressCaptureReplay",
                                            "bufferDeviceAddressMultiDevice",
                                            "vulkanMemoryModel",
                                            "vulkanMemoryModelDeviceScope",
                                            "vulkanMemoryModelAvailabilityVisibilityChains",
                                            "shaderOutputViewportIndex",
                                            "shaderOutputLayer",
                                            "subgroupBroadcastDynamicId"};
constexpr const char* kVulkan13Members[] = {"robustImageAccess",
                                            "inlineUniformBlock",
                                            "descriptorBindingInlineUniformBlockUpdateAfterBind",
                                            "pipelineCreationCacheControl",
                                            "privateData",
                                            "shaderDemoteToHelperInvocation",
                                            "shaderTerminateInvocation",
                                            "subgroupSizeControl",
                                            "computeFullSubgroups",
                                            "synchronization2",
                                            "textureCompressionASTC_HDR",
                                            "shaderZeroInitializeWorkgroupMemory",
                                            "dynamicRendering",
                                            "shaderIntegerDotProduct",
                                            "maintenance4"};

#if defined(_WIN32)
std::string utf8_of(const wchar_t* w) {
    if (!w || !*w) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return {};
    std::string out(static_cast<std::size_t>(n), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, out.data(), n, nullptr, nullptr);
    out.resize(static_cast<std::size_t>(n) - 1);
    return out;
}
#endif

// What a feature needs of a Vulkan device, from slGetFeatureRequirements.
struct FeatureNeeds {
    std::uint32_t feature = 0;
    std::vector<std::string> instanceExtensions, deviceExtensions, features12, features13;
    std::uint32_t graphicsQueues = 0, computeQueues = 0, opticalFlowQueues = 0;
};
struct FeatureState {
    std::uint32_t feature = 0;
    bool supported = false;
    std::string reason;  // when not supported
};
struct QueueRole {
    std::uint32_t kind = 0;  // VK_QUEUE_GRAPHICS_BIT / COMPUTE_BIT / OPTICAL_FLOW_BIT_NV
    std::uint32_t count = 0;
};
constexpr std::uint32_t kQueueGraphics = 0x1, kQueueCompute = 0x2, kQueueOpticalFlow = 0x100;

enum class Phase { Idle, Failed, Inited, Ready };

}  // namespace

// ---- the C ABI helpers -------------------------------------------------------------------------------------------------------------

std::string streamline_load_api(VendorLibrary& lib, gpu::Backend backend, StreamlineApi& api) {
    std::string missing;
    bind(lib, "slInit", api.init, missing);
    bind(lib, "slShutdown", api.shutdown, missing);
    bind(lib, "slIsFeatureSupported", api.isFeatureSupported, missing);
    bind(lib, "slSetTagForFrame", api.setTagForFrame, missing);
    bind(lib, "slSetConstants", api.setConstants, missing);
    bind(lib, "slGetFeatureRequirements", api.getFeatureRequirements, missing);
    bind(lib, "slAllocateResources", api.allocateResources, missing);
    bind(lib, "slFreeResources", api.freeResources, missing);
    bind(lib, "slEvaluateFeature", api.evaluateFeature, missing);
    bind(lib, "slGetFeatureFunction", api.getFeatureFunction, missing);
    bind(lib, "slGetNewFrameToken", api.getNewFrameToken, missing);
    if (backend == gpu::Backend::Vulkan) {
        bind(lib, "slSetVulkanInfo", api.setVulkanInfo, missing);
        bind(lib, "vkGetInstanceProcAddr", api.vkGetInstanceProcAddr, missing);
        bind(lib, "vkGetDeviceProcAddr", api.vkGetDeviceProcAddr, missing);
    } else {
        bind(lib, "slUpgradeInterface", api.upgradeInterface, missing);
        bind(lib, "slSetD3DDevice", api.setD3dDevice, missing);
    }
    return missing;
}

std::string streamline_result_text(sl_abi::Result result) {
    if (result >= 0 && std::size_t(result) < std::size(kResultNames)) return kResultNames[result];
    return "result " + std::to_string(result);
}

std::string streamline_refusal(const char* what, sl_abi::Result result, std::uint32_t feature) {
    std::string out =
        std::string(what) + " answered \"" + streamline_result_text(result) + "\" (" + std::to_string(result) + ").";
    if (const std::string hint = result_hint(result, feature); !hint.empty()) out += " " + hint;
    return out;
}

std::vector<std::uint8_t> streamline_vulkan_features(int core, const std::vector<std::string>& names,
                                                     std::vector<std::string>* unknown) {
    const char* const* members = core == 13 ? kVulkan13Members : kVulkan12Members;
    const std::size_t count = core == 13 ? std::size(kVulkan13Members) : std::size(kVulkan12Members);
    // sType, pNext, then one VkBool32 per member; the struct's size is rounded up to its 8-byte alignment.
    std::vector<std::uint8_t> bytes((16 + 4 * count + 7) / 8 * 8, 0);
    const std::uint32_t sType = core == 13 ? 53u : 51u;  // VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_{2,3}_FEATURES
    std::memcpy(bytes.data(), &sType, sizeof sType);
    const std::uint32_t on = 1;
    for (const std::string& name : names) {
        std::size_t at = count;
        for (std::size_t i = 0; i < count; ++i)
            if (name == members[i]) at = i;
        if (at == count) {
            if (unknown) unknown->push_back(name);
            continue;
        }
        std::memcpy(bytes.data() + 16 + 4 * at, &on, sizeof on);
    }
    return bytes;
}

StreamlineHost default_streamline_host() {
    StreamlineHost host;
#if defined(_WIN32)
    host.readAdapter = [](const void* adapter, StreamlineAdapter& out) {
        if (!adapter) return false;
        auto* a = static_cast<IDXGIAdapter1*>(const_cast<void*>(adapter));
        DXGI_ADAPTER_DESC1 desc{};
        if (FAILED(a->GetDesc1(&desc))) return false;
        out.vendorId = desc.VendorId;
        static_assert(sizeof(LUID) == 8);
        std::memcpy(out.luid, &desc.AdapterLuid, sizeof(LUID));
        out.hasLuid = true;
        out.name = utf8_of(desc.Description);
        return true;
    };
    host.releaseCom = [](void* object) {
        if (object) static_cast<IUnknown*>(object)->Release();
    };
#else
    host.readAdapter = [](const void*, StreamlineAdapter&) { return false; };
    host.releaseCom = [](void*) {};
#endif
    return host;
}

// ---- the runtime -------------------------------------------------------------------------------------------------------------------

struct StreamlineRuntime::Impl {
    Impl(std::vector<std::uint32_t> features, StreamlineHost host)
        : features_(std::move(features)), host_(std::move(host)) {}

    // Guards the phase, the states and the frame token: the render thread (upscale, frame generation), the thread that answers
    // render.supports and the device hooks all call in. frame_token holds it across slGetNewFrameToken on purpose: the check "is this frame's
    // token already made" and the call that makes it must be one step, or two providers asking for the same frame (DLSS and Reflex) would
    // get two tokens and Streamline would see two frames.
    mutable std::mutex mu_;
    std::vector<std::uint32_t> features_;
    std::string projectId_;  // slInit's prefs point at it: it lives as long as Streamline may read it
    StreamlineHost host_;

    Phase phase_ = Phase::Idle;
    gpu::Backend backend_ = gpu::Backend::Recording;
    bool tried_ = false;
    std::string why_;
    std::uint64_t generation_ = 0;
    std::unique_ptr<VendorLibrary> lib_;
    StreamlineApi api_;
    std::vector<FeatureState> states_;
    std::vector<FeatureNeeds> needs_;
    std::vector<QueueRole> roles_;
    const void* instance_ = nullptr;
    std::atomic<std::uint64_t> presents_{0};
    // The token of the frame asked for last: a second ask of the same frame (DLSS and Reflex both) gets this one without a call.
    void* tokenValue_ = nullptr;
    std::uint32_t tokenFrame_ = 0;
    std::uint64_t tokenGeneration_ = 0;

    // Marks the set-up failed with `why`: Streamline is shut down when it was started. The reason says what is wrong and what to do; `warn`
    // logs it as a warning (a machine that should have DLSS and does not), else as information (no NVIDIA GPU, not installed).
    std::string fail(std::string why, gpu::Backend backend, bool shutdown, bool warn) {
        if (shutdown && api_.shutdown) api_.shutdown();
        phase_ = Phase::Failed;
        backend_ = backend;
        tried_ = true;
        why_ = std::move(why);
        states_.clear();
        needs_.clear();
        roles_.clear();
        if (warn)
            FA_WARN("render", "NVIDIA Streamline is off: {}", why_);
        else
            FA_INFO("render", "NVIDIA Streamline is off: {}", why_);
        return why_;
    }

    // Shuts Streamline down when it runs and forgets the device it served.
    void reset() {
        if ((phase_ == Phase::Inited || phase_ == Phase::Ready) && api_.shutdown) api_.shutdown();
        phase_ = Phase::Idle;
        tried_ = false;
        why_.clear();
        states_.clear();
        needs_.clear();
        roles_.clear();
        instance_ = nullptr;
        tokenValue_ = nullptr;
    }

    // Finds the library, takes its functions and calls slInit for `backend`. "" when it runs; else the reason, and `warn` tells whether the
    // library was there (a failure to report) or not (the machine simply has no DLSS).
    std::string init_sl(gpu::Backend backend, bool& warn) {
        warn = false;
        std::string why;
        const std::filesystem::path found = vendor_loader().find(kStreamlineSpec, &why);
        if (found.empty())
            return "NVIDIA Streamline (DLSS, Reflex) is not installed: run `factoria setup streamline` (" + why + ").";
        warn = true;
        std::unique_ptr<VendorLibrary> lib = vendor_loader().load(found, &why);
        if (!lib)
            return "NVIDIA Streamline's library " + fa::fs::path_to_utf8(found) + " could not be loaded: " + why +
                   ". Run `factoria setup streamline` to install it again.";
        StreamlineApi api;
        if (const std::string missing = streamline_load_api(*lib, backend, api); !missing.empty())
            return "NVIDIA Streamline's library " + lib->path() + " has no export " + missing +
                   " (it is not Streamline 2.x): run `factoria setup streamline` to install the version FactorIA was "
                   "tested with.";
        Preferences prefs;
        init_preferences(prefs);
        prefs.flags = kPrefDisableClStateTracking | kPrefDisableDebugText | kPrefUseManualHooking |
                      kPrefUseFrameBasedResourceTagging;
        prefs.logMessageCallback = &log_callback;
        prefs.featuresToLoad = features_.data();
        prefs.numFeaturesToLoad = static_cast<std::uint32_t>(features_.size());
        // NVIDIA's registration of a game gives it an application id; without one it is 0 (Streamline runs, NVIDIA's per-title overrides do not
        // apply). The project id is the GUID of the game (a custom engine must give one): FactorIA's own unless the game sets its own.
        prefs.applicationId = streamline_application_id(std::getenv("FA_STREAMLINE_APP_ID"));
        projectId_ = streamline_project_id(std::getenv("FA_STREAMLINE_PROJECT_ID"));
        prefs.engine = 0;  // eCustom
        prefs.engineVersion = fa::engine_version();
        prefs.projectId = projectId_.c_str();
        prefs.renderApi = backend == gpu::Backend::Vulkan ? kRenderApiVulkan : kRenderApiD3d12;
        if (const Result r = api.init(&prefs, kSdkVersion); r != kOk) return streamline_refusal("slInit", r);
        lib_ = std::move(lib);
        api_ = api;
        phase_ = Phase::Inited;
        backend_ = backend;
        tried_ = true;
        why_.clear();
        return {};
    }

    // The first reason a feature of the list is refused with ("" when one is usable).
    std::string none_usable_reason() const {
        std::string first;
        for (const FeatureState& s : states_) {
            if (s.supported) return {};
            if (first.empty()) first = feature_label(s.feature) + ": " + s.reason;
        }
        return first.empty() ? "no Streamline feature was asked for" : first;
    }

    FeatureState* state_of(std::uint32_t feature) {
        for (FeatureState& s : states_)
            if (s.feature == feature) return &s;
        return nullptr;
    }

    // ---- D3D12 ---------------------------------------------------------------------------------------------------------------------

    void d3d12_before(const gpu::D3d12BeforeDevice& before) {
        if (phase_ == Phase::Inited) return;  // an adapter before this one made slInit already
        if (phase_ == Phase::Ready) reset();  // a device of an earlier run that never told us it went
        StreamlineAdapter adapter;
        const bool known = before.adapter && host_.readAdapter && host_.readAdapter(before.adapter, adapter);
        if (before.warp || (known && adapter.vendorId != kNvidiaVendorId)) {
            const std::string who = before.warp            ? "Microsoft's software adapter (WARP)"
                                    : adapter.name.empty() ? "this GPU"
                                                           : adapter.name;
            fail("DLSS needs an NVIDIA RTX GPU; the adapter " + who + " is not one.", gpu::Backend::D3d12, false,
                 false);
            return;
        }
        bool warn = false;
        const std::string err = init_sl(gpu::Backend::D3d12, warn);
        if (!err.empty()) fail(err, gpu::Backend::D3d12, false, warn);
    }

    // "" when the device is set up, else the reason (the caller marks the hook unavailable).
    std::string d3d12_created(gpu::D3d12DeviceCreated& c) {
        if (phase_ != Phase::Inited)
            return why_.empty() ? "NVIDIA Streamline was not started before the device was made." : why_;
        Result r = kOk;
        if (api_.setD3dDevice && c.device && (r = api_.setD3dDevice(c.device)) != kOk)
            return fail(streamline_refusal("slSetD3DDevice", r), gpu::Backend::D3d12, true, true);
        void* device = c.device;
        void* factory = c.factory;
        if (device && (r = api_.upgradeInterface(&device)) != kOk)
            return fail(streamline_refusal("slUpgradeInterface (device)", r), gpu::Backend::D3d12, true, true);
        if (factory && (r = api_.upgradeInterface(&factory)) != kOk) {
            if (device != c.device && host_.releaseCom) host_.releaseCom(device);
            return fail(streamline_refusal("slUpgradeInterface (factory)", r), gpu::Backend::D3d12, true, true);
        }
        StreamlineAdapter adapter;
        const bool known = c.adapter && host_.readAdapter && host_.readAdapter(c.adapter, adapter);
        AdapterInfo info;
        init_adapter_info(info);
        if (known && adapter.hasLuid) {
            info.deviceLuid = adapter.luid;
            info.deviceLuidSizeInBytes = 8;
        }
        states_.clear();
        for (const std::uint32_t feature : features_) {
            FeatureState s;
            s.feature = feature;
            const Result supported = api_.isFeatureSupported(feature, &info);
            s.supported = supported == kOk;
            if (!s.supported) s.reason = streamline_refusal("slIsFeatureSupported", supported, feature);
            states_.push_back(std::move(s));
        }
        if (const std::string none = none_usable_reason(); !none.empty()) {
            // The replacements hold the originals: give them up, the engine keeps what it made.
            if (device != c.device && host_.releaseCom) host_.releaseCom(device);
            if (factory != c.factory && host_.releaseCom) host_.releaseCom(factory);
            const std::string reason = none;
            return fail(reason, gpu::Backend::D3d12, true, true);
        }
        c.device = device;
        c.factory = factory;
        phase_ = Phase::Ready;
        generation_++;
        return {};
    }

    // ---- Vulkan --------------------------------------------------------------------------------------------------------------------

    std::string vk_instance_request(gpu::VulkanInstanceRequest& request) {
        reset();  // a device of an earlier run that never told us it went
        bool warn = false;
        if (const std::string err = init_sl(gpu::Backend::Vulkan, warn); !err.empty())
            return fail(err, gpu::Backend::Vulkan, false, warn);
        states_.clear();
        needs_.clear();
        for (const std::uint32_t feature : features_) {
            FeatureState s;
            s.feature = feature;
            FeatureRequirements req;
            init_feature_requirements(req);
            const Result got = api_.getFeatureRequirements(feature, &req);
            if (got != kOk) {
                s.reason = streamline_refusal("slGetFeatureRequirements", got, feature);
            } else if ((req.flags & kReqVulkan) == 0) {
                s.reason = "Streamline says it does not support Vulkan for this feature: run the game on Direct3D 12.";
            } else {
                FeatureNeeds n;
                n.feature = feature;
                n.instanceExtensions = names_of(req.vkInstanceExtensions, req.vkNumInstanceExtensions);
                n.deviceExtensions = names_of(req.vkDeviceExtensions, req.vkNumDeviceExtensions);
                n.features12 = names_of(req.vkFeatures12, req.vkNumFeatures12);
                n.features13 = names_of(req.vkFeatures13, req.vkNumFeatures13);
                n.graphicsQueues = std::min<std::uint32_t>(req.vkNumGraphicsQueuesRequired, 8);
                n.computeQueues = std::min<std::uint32_t>(req.vkNumComputeQueuesRequired, 8);
                n.opticalFlowQueues = std::min<std::uint32_t>(req.vkNumOpticalFlowQueuesRequired, 8);
                std::vector<std::string> unknown;
                (void)streamline_vulkan_features(12, n.features12, &unknown);
                (void)streamline_vulkan_features(13, n.features13, &unknown);
                if (!unknown.empty()) {
                    s.reason = "Streamline asks for the Vulkan feature(s) " + join(unknown) +
                               " this build of FactorIA does not know: it was built for another Streamline version.";
                } else {
                    s.supported = true;
                    needs_.push_back(std::move(n));
                }
            }
            states_.push_back(std::move(s));
        }
        if (const std::string none = none_usable_reason(); !none.empty())
            return fail(none, gpu::Backend::Vulkan, true, true);
        for (const FeatureNeeds& n : needs_)
            for (const std::string& e : n.instanceExtensions) add_unique(request.extensions, e);
        return {};
    }

    std::string vk_device_request(const gpu::VulkanPhysicalDevice& physical, gpu::VulkanDeviceRequest& request) {
        if (phase_ != Phase::Inited)
            return why_.empty() ? "NVIDIA Streamline was not started before the device was made." : why_;
        if (physical.vendorId != kNvidiaVendorId)
            return fail("DLSS needs an NVIDIA RTX GPU; the engine chose " +
                            (physical.name.empty() ? std::string("another GPU") : physical.name) +
                            ", which is not one.",
                        gpu::Backend::Vulkan, true, false);
        AdapterInfo info;
        init_adapter_info(info);
        info.vkPhysicalDevice = const_cast<void*>(physical.physicalDevice);
        for (FeatureState& s : states_) {
            if (!s.supported) continue;
            const Result r = api_.isFeatureSupported(s.feature, &info);
            if (r != kOk) {
                s.supported = false;
                s.reason = streamline_refusal("slIsFeatureSupported", r, s.feature);
            }
        }
        if (const std::string none = none_usable_reason(); !none.empty())
            return fail(none, gpu::Backend::Vulkan, true, true);
        std::vector<std::string> f12, f13;
        QueueRole graphics{kQueueGraphics, 0}, compute{kQueueCompute, 0}, opticalFlow{kQueueOpticalFlow, 0};
        for (const FeatureNeeds& n : needs_) {
            const FeatureState* s = state_of(n.feature);
            if (!s || !s->supported) continue;
            for (const std::string& e : n.deviceExtensions) add_unique(request.extensions, e);
            for (const std::string& f : n.features12) add_unique(f12, f);
            for (const std::string& f : n.features13) add_unique(f13, f);
            graphics.count += n.graphicsQueues;
            compute.count += n.computeQueues;
            opticalFlow.count += n.opticalFlowQueues;
        }
        if (!f12.empty()) request.features.push_back(streamline_vulkan_features(12, f12, nullptr));
        if (!f13.empty()) request.features.push_back(streamline_vulkan_features(13, f13, nullptr));
        roles_.clear();
        for (const QueueRole& role : {graphics, compute, opticalFlow}) {
            if (role.count == 0) continue;
            roles_.push_back(role);
            request.queues.push_back({role.kind, role.count});
        }
        return {};
    }

    std::string vk_created(const gpu::VulkanDeviceCreated& created) {
        if (phase_ != Phase::Inited)
            return why_.empty() ? "NVIDIA Streamline was not started before the device was made." : why_;
        VulkanInfo info;
        init_vulkan_info(info);
        info.device = const_cast<void*>(created.native.device);
        info.instance = const_cast<void*>(created.native.instance);
        info.physicalDevice = const_cast<void*>(created.native.physicalDevice);
        // The queues Streamline asked for; a role it did not ask for uses the engine's own queue of that kind.
        info.graphicsQueueFamily = created.native.graphicsFamily;
        info.graphicsQueueIndex = created.native.graphicsQueueIndex;
        info.computeQueueFamily = created.native.computeFamily;
        info.computeQueueIndex = created.native.computeQueueIndex;
        std::size_t at = 0;
        for (const QueueRole& role : roles_) {
            if (at < created.queues.size()) {
                const gpu::VulkanQueueGrant& g = created.queues[at];
                if (role.kind == kQueueGraphics) {
                    info.graphicsQueueFamily = g.family;
                    info.graphicsQueueIndex = g.index;
                } else if (role.kind == kQueueCompute) {
                    info.computeQueueFamily = g.family;
                    info.computeQueueIndex = g.index;
                } else {
                    info.opticalFlowQueueFamily = g.family;
                    info.opticalFlowQueueIndex = g.index;
                }
            }
            at += role.count;
        }
        if (const Result r = api_.setVulkanInfo(&info); r != kOk)
            return fail(streamline_refusal("slSetVulkanInfo", r), gpu::Backend::Vulkan, true, true);
        phase_ = Phase::Ready;
        generation_++;
        return {};
    }

    gpu::HookProcAddr vk_resolve(const char* name, const void* device, gpu::HookProcAddr resolved) {
        if (phase_ != Phase::Inited && phase_ != Phase::Ready) return nullptr;
        if (!instance_ || !name) return nullptr;
        void* fn = nullptr;
        if (device)
            fn = api_.vkGetDeviceProcAddr ? api_.vkGetDeviceProcAddr(const_cast<void*>(device), name) : nullptr;
        else
            fn = api_.vkGetInstanceProcAddr ? api_.vkGetInstanceProcAddr(const_cast<void*>(instance_), name) : nullptr;
        if (!fn || fn == reinterpret_cast<void*>(resolved)) return nullptr;  // NOLINT: a function address
        return reinterpret_cast<gpu::HookProcAddr>(fn);                      // NOLINT
    }
};

StreamlineRuntime::StreamlineRuntime(std::vector<std::uint32_t> features, StreamlineHost host)
    : impl_(std::make_unique<Impl>(std::move(features), std::move(host))) {}

StreamlineRuntime::~StreamlineRuntime() = default;

void StreamlineRuntime::vulkan_instance_request(gpu::VulkanInstanceRequest& request) {
    std::string err;
    {
        std::lock_guard lock(impl_->mu_);
        err = impl_->vk_instance_request(request);
    }
    if (!err.empty()) mark_unavailable(err);
}

void StreamlineRuntime::vulkan_instance_created(const void* instance, gpu::HookProcAddr) {
    std::lock_guard lock(impl_->mu_);
    impl_->instance_ = instance;
}

void StreamlineRuntime::vulkan_device_request(const gpu::VulkanPhysicalDevice& physical,
                                              gpu::VulkanDeviceRequest& request) {
    std::string err;
    {
        std::lock_guard lock(impl_->mu_);
        err = impl_->vk_device_request(physical, request);
    }
    if (!err.empty()) mark_unavailable(err);
}

gpu::HookProcAddr StreamlineRuntime::vulkan_resolve(const char* name, const void* device, gpu::HookProcAddr resolved) {
    std::lock_guard lock(impl_->mu_);
    return impl_->vk_resolve(name, device, resolved);
}

void StreamlineRuntime::vulkan_device_created(const gpu::VulkanDeviceCreated& created) {
    std::string err;
    {
        std::lock_guard lock(impl_->mu_);
        err = impl_->vk_created(created);
    }
    if (!err.empty()) mark_unavailable(err);
}

void StreamlineRuntime::d3d12_before_device(const gpu::D3d12BeforeDevice& before) {
    std::lock_guard lock(impl_->mu_);
    impl_->d3d12_before(before);
}

void StreamlineRuntime::d3d12_device_created(gpu::D3d12DeviceCreated& created) {
    std::string err;
    {
        std::lock_guard lock(impl_->mu_);
        err = impl_->d3d12_created(created);
    }
    if (!err.empty()) mark_unavailable(err);
}

void StreamlineRuntime::present_end(const gpu::PresentEvent& event) {
    // The count only grows, and a frame token asks for it: no lock (the render thread holds the lock while it asks Streamline).
    std::uint64_t seen = impl_->presents_.load();
    while (event.frame > seen && !impl_->presents_.compare_exchange_weak(seen, event.frame)) {
    }
}

void StreamlineRuntime::device_destroying() {
    std::lock_guard lock(impl_->mu_);
    impl_->reset();
    impl_->presents_ = 0;
}

void StreamlineRuntime::add_feature(std::uint32_t feature) {
    std::lock_guard lock(impl_->mu_);
    if (std::find(impl_->features_.begin(), impl_->features_.end(), feature) == impl_->features_.end())
        impl_->features_.push_back(feature);
}

bool StreamlineRuntime::feature_asked(std::uint32_t feature) const {
    std::lock_guard lock(impl_->mu_);
    for (const FeatureState& s : impl_->states_)
        if (s.feature == feature) return true;
    return false;
}

StreamlineStatus StreamlineRuntime::status() const {
    std::lock_guard lock(impl_->mu_);
    StreamlineStatus s;
    s.tried = impl_->tried_;
    s.ready = impl_->phase_ == Phase::Ready;
    s.backend = impl_->backend_;
    s.reason = impl_->phase_ == Phase::Failed ? impl_->why_ : std::string();
    s.generation = impl_->generation_;
    return s;
}

std::string StreamlineRuntime::feature_reason(std::uint32_t feature) const {
    std::lock_guard lock(impl_->mu_);
    for (const FeatureState& s : impl_->states_)
        if (s.feature == feature) return s.supported ? std::string() : s.reason;
    return feature_label(feature) + " was not asked of Streamline.";
}

const StreamlineApi* StreamlineRuntime::api() const {
    std::lock_guard lock(impl_->mu_);
    return impl_->phase_ == Phase::Ready ? &impl_->api_ : nullptr;
}

std::uint32_t StreamlineRuntime::frame_index() const { return static_cast<std::uint32_t>(impl_->presents_.load()); }

void* StreamlineRuntime::frame_token(std::uint32_t* index, std::string* why) const {
    std::lock_guard lock(impl_->mu_);
    if (impl_->phase_ != Phase::Ready || !impl_->api_.getNewFrameToken) {
        if (why) *why = "NVIDIA Streamline is not running on this device.";
        return nullptr;
    }
    std::uint32_t frame = static_cast<std::uint32_t>(impl_->presents_.load());
    if (impl_->tokenValue_ && impl_->tokenGeneration_ == impl_->generation_ && impl_->tokenFrame_ == frame) {
        if (index) *index = frame;
        return impl_->tokenValue_;
    }
    void* token = nullptr;
    const Result r = impl_->api_.getNewFrameToken(&token, &frame);
    if (r != kOk || !token) {
        if (why) *why = streamline_refusal("slGetNewFrameToken", r == kOk ? kErrorInvalidState : r);
        return nullptr;
    }
    impl_->tokenValue_ = token;
    impl_->tokenFrame_ = frame;
    impl_->tokenGeneration_ = impl_->generation_;
    if (index) *index = frame;
    return token;
}

std::uint64_t StreamlineRuntime::ready_generation() const {
    std::lock_guard lock(impl_->mu_);
    return impl_->phase_ == Phase::Ready ? impl_->generation_ : 0;
}

// ---- the process's runtime ---------------------------------------------------------------------------------------------------------

namespace {
std::atomic<StreamlineRuntime*> g_test_runtime{nullptr};

std::shared_ptr<StreamlineRuntime>& process_runtime() {
    // The features every device asks for. Reflex and the PC latency markers are always asked: the low-latency setting is chosen after the
    // device exists, and a plugin that is not installed only makes its feature unsupported (feature_reason says why) while DLSS and the
    // others run. DLSS frame generation is not here: a renderer that asks for frame generation adds it (add_feature) before its device is
    // made, so a game that never does is not asked for the extra Vulkan queues and extensions it needs. DLSS Ray Reconstruction (sl.dlss_d) is
    // added the same way when the project asks for it (Renderer::init, RendererDesc::rayReconstruction).
    static std::shared_ptr<StreamlineRuntime> runtime =
        std::make_shared<StreamlineRuntime>(std::vector<std::uint32_t>{kFeatureDlss, kFeatureReflex, kFeaturePcl});
    return runtime;
}
}  // namespace

StreamlineRuntime& streamline_runtime() {
    if (StreamlineRuntime* fake = g_test_runtime.load()) return *fake;
    return *process_runtime();
}

void register_streamline_runtime() {
#if defined(_WIN32)
    static std::once_flag once;
    std::call_once(once, [] { gpu::register_device_hook(process_runtime()); });
#endif
}

void set_streamline_runtime_for_test(StreamlineRuntime* runtime) { g_test_runtime.store(runtime); }

}  // namespace fa::render
