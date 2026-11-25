// The NVIDIA Streamline runtime core of M78 (docs/design/ARCHITECTURE_RENDERING_HOOKS.md, "Streamline runtime core"): one object that loads
// sl.interposer.dll, takes part in making the engine's D3D12 and Vulkan devices (it is a gpu::DeviceHook, so slInit runs before the device
// is made), and hands the features built on it (DLSS Super Resolution and Reflex now; DLSS frame generation later) a frame token per
// frame, the function table and the answer "is this feature usable on this machine, and if not, why". Private to fa_render.
//
// No NVIDIA header or binary is in the engine (decision D1 and D2 of M78). The structures and functions of the Streamline C ABI the engine
// calls are declared below in `sl_abi`, written field by field from the public headers of Streamline 2.14.16 (MIT license; sl_core_types.h,
// sl_consts.h, sl_core_api.h, sl_dlss.h, sl_reflex.h, sl_pcl.h, sl_helpers_vk.h), and every function is taken from the loaded library through VendorLibrary::symbol.
// A struct whose size differs from the one the headers give is a crash, so the sizes are checked at build time (64-bit).
//
// Where it runs: Windows, Direct3D 12 and Vulkan (the device hooks are called on those two backends only), on an NVIDIA GPU. Everywhere else,
// and when the library is not installed, the GPU is not NVIDIA, the driver is too old or slInit fails, the RUNTIME is unavailable with
// Streamline's own reason: never the device (a hook degrades, it never fails the device).
//
// Manual hooking (Streamline's ProgrammingGuideManualHooking.md): slInit runs with eUseManualHooking and eUseFrameBasedResourceTagging before
// any hooked API; D3D12 then upgrades the factory and the device (slUpgradeInterface) as soon as the device exists and gives
// slSetD3DDevice the native device; Vulkan asks slGetFeatureRequirements before the instance for the instance extensions, then for the device
// extensions, features and queues, loads Streamline's vkGetInstanceProcAddr / vkGetDeviceProcAddr through DeviceHook::vulkan_resolve and tells
// slSetVulkanInfo the device and the queues it was given once the device exists.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/types.h"

#include "gpu/device_hooks.h"
#include "render_upscale_vendor.h"

namespace fa::render {

// ---- the engine's declarations of the Streamline C ABI --------------------------------------------------------------------------------
namespace sl_abi {

// sl::StructType, sl::BaseStructure: every structure starts with these 32 bytes (next, GUID, version).
struct StructType {
    std::uint32_t data1;
    std::uint16_t data2, data3;
    std::uint8_t data4[8];
};
struct Base {
    void* next;
    StructType type;
    std::uint64_t version;  // size_t
};

// sl::Result (an enum class of int).
using Result = std::int32_t;
inline constexpr Result kOk = 0;
inline constexpr Result kErrorIO = 1, kErrorDriverOutOfDate = 2, kErrorOSOutOfDate = 3, kErrorOSDisabledHWS = 4;
inline constexpr Result kErrorNoSupportedAdapterFound = 6, kErrorAdapterNotSupported = 7, kErrorNoPlugins = 8;
inline constexpr Result kErrorMissingProxy = 17, kErrorFeatureMissing = 31, kErrorFeatureNotSupported = 32,
                        kErrorFeatureFailedToLoad = 34, kErrorFeatureMissingDependency = 36, kErrorInvalidState = 38;
inline constexpr Result kWarnOutOfVram = 39;

// sl::Feature
inline constexpr std::uint32_t kFeatureDlss = 0, kFeatureReflex = 3, kFeaturePcl = 4, kFeatureDlssG = 1000;
// sl::RenderAPI
inline constexpr std::uint32_t kRenderApiD3d11 = 0, kRenderApiD3d12 = 1, kRenderApiVulkan = 2;
// sl::PreferenceFlags (64-bit)
inline constexpr std::uint64_t kPrefDisableClStateTracking = 1u << 0, kPrefDisableDebugText = 1u << 1,
                               kPrefUseManualHooking = 1u << 2, kPrefUseFrameBasedResourceTagging = 1u << 7;
// sl::BufferType
inline constexpr std::uint32_t kBufferDepth = 0, kBufferMotionVectors = 1, kBufferScalingInputColor = 3,
                               kBufferScalingOutputColor = 4, kBufferExposure = 13;
// sl::ResourceLifecycle
inline constexpr std::uint32_t kOnlyValidNow = 0;
// sl::ResourceType (a char)
inline constexpr std::uint8_t kResourceTex2d = 0;
// sl::Boolean (a char)
inline constexpr char kFalse = 0, kTrue = 1, kInvalid = 2;
// sl::FeatureRequirementFlags
inline constexpr std::uint32_t kReqD3d12 = 1u << 1, kReqVulkan = 1u << 2;
// sl::LogType
inline constexpr std::uint32_t kLogInfo = 0, kLogWarn = 1, kLogError = 2;

struct Extent {  // sl::Extent: top, left, width, height
    std::uint32_t top, left, width, height;
};
struct Version {  // sl::Version
    std::uint32_t major, minor, build;
};
struct Float2 {
    float x, y;
};
struct Float3 {
    float x, y, z;
};
struct Float4 {
    float x, y, z, w;
};
struct Float4x4 {
    Float4 row[4];
};

// sl::Preferences
struct Preferences {
    Base base;
    bool showConsole;
    std::uint32_t logLevel;  // sl::LogLevel: 0 off, 1 default, 2 verbose
    const wchar_t** pathsToPlugins;
    std::uint32_t numPathsToPlugins;
    const wchar_t* pathToLogsAndData;
    void* allocateCallback;
    void* releaseCallback;
    void (*logMessageCallback)(std::uint32_t type, const char* message);
    std::uint64_t flags;
    const std::uint32_t* featuresToLoad;
    std::uint32_t numFeaturesToLoad;
    std::uint32_t applicationId;
    std::uint32_t engine;  // sl::EngineType: 0 custom
    const char* engineVersion;
    const char* projectId;
    std::uint32_t renderApi;
};
// sl::ViewportHandle
struct ViewportHandle {
    Base base;
    std::uint32_t value;
};
// sl::FeatureRequirements
struct FeatureRequirements {
    Base base;
    std::uint32_t flags;
    std::uint32_t maxNumCpuThreads;
    std::uint32_t maxNumViewports;
    std::uint32_t numRequiredTags;
    const std::uint32_t* requiredTags;
    Version osVersionDetected, osVersionRequired, driverVersionDetected, driverVersionRequired;
    std::uint32_t vkNumComputeQueuesRequired;
    std::uint32_t vkNumGraphicsQueuesRequired;
    std::uint32_t vkNumDeviceExtensions;
    const char** vkDeviceExtensions;
    std::uint32_t vkNumInstanceExtensions;
    const char** vkInstanceExtensions;
    std::uint32_t vkNumFeatures12;
    const char** vkFeatures12;
    std::uint32_t vkNumFeatures13;
    const char** vkFeatures13;
    std::uint32_t vkNumOpticalFlowQueuesRequired;
};
// sl::AdapterInfo
struct AdapterInfo {
    Base base;
    std::uint8_t* deviceLuid;
    std::uint32_t deviceLuidSizeInBytes;
    void* vkPhysicalDevice;
};
// sl::Resource
struct Resource {
    Base base;
    std::uint8_t type;  // sl::ResourceType (a char)
    void* native;       // ID3D12Resource* / VkImage
    void* memory;
    void* view;           // VkImageView
    std::uint32_t state;  // D3D12_RESOURCE_STATES / VkImageLayout
    std::uint32_t width, height, nativeFormat, mipLevels, arrayLayers;
    std::uint64_t gpuVirtualAddress;
    std::uint32_t flags;  // VkImageCreateFlags
    std::uint32_t usage;  // VkImageUsageFlags
    std::uint16_t internalFlags, reserved;
};
// sl::ResourceTag
struct ResourceTag {
    Base base;
    Resource* resource;
    std::uint32_t type;       // sl::BufferType
    std::uint32_t lifecycle;  // sl::ResourceLifecycle
    Extent extent;
};
// sl::Constants
struct Constants {
    Base base;
    Float4x4 cameraViewToClip, clipToCameraView, clipToLensClip, clipToPrevClip, prevClipToClip;
    Float2 jitterOffset, mvecScale, cameraPinholeOffset;
    Float3 cameraPos, cameraUp, cameraRight, cameraFwd;
    float cameraNear, cameraFar, cameraFov, cameraAspectRatio, motionVectorsInvalidValue;
    char depthInverted, cameraMotionIncluded, motionVectors3d, reset, orthographicProjection, motionVectorsDilated,
        motionVectorsJittered;
    float minRelativeLinearDepthObjectSeparation;
};
// sl::DLSSOptions (sl_dlss.h)
struct DlssOptions {
    Base base;
    std::uint32_t mode;  // sl::DLSSMode
    std::uint32_t outputWidth, outputHeight;
    float sharpness, preExposure, exposureScale;
    char colorBuffersHdr, indicatorInvertAxisX, indicatorInvertAxisY;
    std::uint32_t dlaaPreset, qualityPreset, balancedPreset, performancePreset, ultraPerformancePreset,
        ultraQualityPreset;
    char useAutoExposure, alphaUpscalingEnabled;
};
// sl::DLSSOptimalSettings
struct DlssOptimalSettings {
    Base base;
    std::uint32_t optimalRenderWidth, optimalRenderHeight;
    float optimalSharpness;
    std::uint32_t renderWidthMin, renderHeightMin, renderWidthMax, renderHeightMax;
};
// sl::VulkanInfo (sl_helpers_vk.h)
struct VulkanInfo {
    Base base;
    void* device;
    void* instance;
    void* physicalDevice;
    std::uint32_t computeQueueIndex, computeQueueFamily, graphicsQueueIndex, graphicsQueueFamily, opticalFlowQueueIndex,
        opticalFlowQueueFamily;
    bool useNativeOpticalFlowMode;
    std::uint32_t computeQueueCreateFlags, graphicsQueueCreateFlags, opticalFlowQueueCreateFlags;
};

// sl::ReflexOptions, ReflexReport, ReflexReport2, ReflexState (sl_reflex.h, Streamline 2.14.16): the options of Reflex and what it reports about
// the last frames. The structs the state holds in arrays carry their own base, as in the header.
struct ReflexOptions {
    Base base;
    std::uint32_t mode;  // sl::ReflexMode
    std::uint32_t frameLimitUs;
    bool useMarkersToOptimize;
    std::uint16_t virtualKey;
    std::uint32_t idThread;
};
struct ReflexReport {
    Base base;
    std::uint64_t frameId, inputSampleTime, simStartTime, simEndTime, renderSubmitStartTime, renderSubmitEndTime,
        presentStartTime, presentEndTime, driverStartTime, driverEndTime, osRenderQueueStartTime, osRenderQueueEndTime,
        gpuRenderStartTime,
        gpuRenderEndTime;  // microseconds of the driver's clock; 0 = not marked
    std::uint32_t gpuActiveRenderTimeUs, gpuFrameTimeUs;
};
struct ReflexReport2 {
    Base base;
    std::uint64_t cameraConstructedTime;
    std::uint32_t crossAdapterCopyTimeUs;
};
inline constexpr int kReflexFrameReportCount = 64;
struct ReflexState {
    Base base;
    bool lowLatencyAvailable;
    bool latencyReportAvailable;
    std::uint32_t statsWindowMessage;
    ReflexReport frameReport[kReflexFrameReportCount];
    bool flashIndicatorDriverControlled;
    ReflexReport2 frameReport2[kReflexFrameReportCount];  // kStructVersion2
};
// sl::ReflexMode
inline constexpr std::uint32_t kReflexOff = 0, kReflexLowLatency = 1, kReflexLowLatencyBoost = 2;
// sl::PCLMarker (sl_pcl.h; the value 6, eInputSample, is deprecated and never sent)
inline constexpr std::uint32_t kPclSimulationStart = 0, kPclSimulationEnd = 1, kPclRenderSubmitStart = 2,
                               kPclRenderSubmitEnd = 3, kPclPresentStart = 4, kPclPresentEnd = 5;

// sl::DLSSMode
inline constexpr std::uint32_t kDlssOff = 0, kDlssMaxPerformance = 1, kDlssBalanced = 2, kDlssMaxQuality = 3,
                               kDlssUltraPerformance = 4, kDlssUltraQuality = 5, kDlssDlaa = 6;

#if UINTPTR_MAX == 0xFFFFFFFFFFFFFFFFu
static_assert(sizeof(Base) == 32, "sl::BaseStructure");
static_assert(sizeof(Preferences) == 144, "sl::Preferences");
static_assert(sizeof(ViewportHandle) == 40, "sl::ViewportHandle");
static_assert(sizeof(FeatureRequirements) == 184, "sl::FeatureRequirements");
static_assert(sizeof(AdapterInfo) == 56, "sl::AdapterInfo");
static_assert(sizeof(Resource) == 112, "sl::Resource");
static_assert(sizeof(ResourceTag) == 64, "sl::ResourceTag");
static_assert(sizeof(Constants) == 456, "sl::Constants");
static_assert(sizeof(DlssOptions) == 88, "sl::DLSSOptions");
static_assert(sizeof(DlssOptimalSettings) == 64, "sl::DLSSOptimalSettings");
static_assert(sizeof(VulkanInfo) == 96, "sl::VulkanInfo");
static_assert(sizeof(ReflexOptions) == 48, "sl::ReflexOptions");
static_assert(sizeof(ReflexReport) == 152, "sl::ReflexReport");
static_assert(sizeof(ReflexReport2) == 48, "sl::ReflexReport2");
static_assert(sizeof(ReflexState) == 12848, "sl::ReflexState");
#endif

// The GUID and the version each structure is made with (the macros SL_STRUCT_BEGIN of the headers). Fills `base`.
void init_preferences(Preferences& p);
void init_viewport(ViewportHandle& v, std::uint32_t id);
void init_feature_requirements(FeatureRequirements& r);
void init_adapter_info(AdapterInfo& a);
void init_resource(Resource& r);
void init_resource_tag(ResourceTag& t);
void init_constants(Constants& c);  // also the "not set" values of the headers (INVALID_FLOAT, eInvalid)
void init_dlss_options(DlssOptions& o);
void init_dlss_optimal_settings(DlssOptimalSettings& s);
void init_vulkan_info(VulkanInfo& v);
void init_reflex_options(ReflexOptions& o);  // mode off, no limit
void init_reflex_state(ReflexState& s);      // zeroed, with the base of the state and of each report

// The functions, as the headers declare them (SL_API is the C calling convention; the C++ references are pointers).
using InitFn = Result (*)(const Preferences*, std::uint64_t sdkVersion);
using ShutdownFn = Result (*)();
using IsFeatureSupportedFn = Result (*)(std::uint32_t feature, const AdapterInfo*);
using SetTagForFrameFn = Result (*)(void* frame, const ViewportHandle*, const ResourceTag*, std::uint32_t count,
                                    void* commandBuffer);
using SetConstantsFn = Result (*)(const Constants*, void* frame, const ViewportHandle*);
using GetFeatureRequirementsFn = Result (*)(std::uint32_t feature, FeatureRequirements*);
using AllocateResourcesFn = Result (*)(void* commandBuffer, std::uint32_t feature, const ViewportHandle*);
using FreeResourcesFn = Result (*)(std::uint32_t feature, const ViewportHandle*);
using EvaluateFeatureFn = Result (*)(std::uint32_t feature, void* frame, const Base* const* inputs, std::uint32_t count,
                                     void* commandBuffer);
using UpgradeInterfaceFn = Result (*)(void** baseInterface);
using GetFeatureFunctionFn = Result (*)(std::uint32_t feature, const char* name, void** function);
using GetNewFrameTokenFn = Result (*)(void** token, const std::uint32_t* frameIndex);
using SetD3dDeviceFn = Result (*)(void* device);
using SetVulkanInfoFn = Result (*)(const VulkanInfo*);
using VkGetProcAddrFn = void* (*)(void* instanceOrDevice, const char* name);
// The DLSS functions slGetFeatureFunction gives (sl_dlss.h).
using DlssGetOptimalSettingsFn = Result (*)(const DlssOptions*, DlssOptimalSettings*);
using DlssSetOptionsFn = Result (*)(const ViewportHandle*, const DlssOptions*);
// The Reflex and PCL functions slGetFeatureFunction gives (sl_reflex.h, sl_pcl.h): slReflexSetOptions, slReflexGetState, slReflexSleep and
// slPCLSetMarker, with the C++ references of the headers as pointers. slReflexGetState and slReflexSetOptions are not thread safe.
using ReflexSetOptionsFn = Result (*)(const ReflexOptions*);
using ReflexGetStateFn = Result (*)(ReflexState*);
using ReflexSleepFn = Result (*)(void* frame);
using PclSetMarkerFn = Result (*)(std::uint32_t marker, void* frame);

}  // namespace sl_abi

// The functions of sl.interposer.dll the runtime and its features call. Null members are the ones another backend uses.
struct StreamlineApi {
    sl_abi::InitFn init = nullptr;
    sl_abi::ShutdownFn shutdown = nullptr;
    sl_abi::IsFeatureSupportedFn isFeatureSupported = nullptr;
    sl_abi::SetTagForFrameFn setTagForFrame = nullptr;
    sl_abi::SetConstantsFn setConstants = nullptr;
    sl_abi::GetFeatureRequirementsFn getFeatureRequirements = nullptr;
    sl_abi::AllocateResourcesFn allocateResources = nullptr;
    sl_abi::FreeResourcesFn freeResources = nullptr;
    sl_abi::EvaluateFeatureFn evaluateFeature = nullptr;
    sl_abi::UpgradeInterfaceFn upgradeInterface = nullptr;
    sl_abi::GetFeatureFunctionFn getFeatureFunction = nullptr;
    sl_abi::GetNewFrameTokenFn getNewFrameToken = nullptr;
    sl_abi::SetD3dDeviceFn setD3dDevice = nullptr;    // D3D12
    sl_abi::SetVulkanInfoFn setVulkanInfo = nullptr;  // Vulkan
    sl_abi::VkGetProcAddrFn vkGetInstanceProcAddr = nullptr;
    sl_abi::VkGetProcAddrFn vkGetDeviceProcAddr = nullptr;
};

// Takes the functions `backend` needs from `lib`. "" when all are there, else the name of the first missing export.
std::string streamline_load_api(VendorLibrary& lib, gpu::Backend backend, StreamlineApi& api);

// "ok", "driver out of date", ... for a sl::Result, then what to do about it where the cause is known. "result 99" for a code this build
// does not know.
std::string streamline_result_text(sl_abi::Result result);
// The sentence of a refusal of `feature` ("DLSS") with Streamline's own result: `what` answered "<text>" (<code>) and how to fix it.
std::string streamline_refusal(const char* what, sl_abi::Result result);

// The Vulkan feature structs Streamline asks for by member name (slGetFeatureRequirements::vkFeatures12 / vkFeatures13), as the bytes of a
// whole VkPhysicalDeviceVulkan12Features / VkPhysicalDeviceVulkan13Features with VK_TRUE in the named members (gpu::VulkanDeviceRequest::
// features). A name this build does not know is returned in `unknown`.
std::vector<std::uint8_t> streamline_vulkan_features(int core, const std::vector<std::string>& names,
                                                     std::vector<std::string>* unknown);

// What the runtime asks of the system, replaceable by a test.
struct StreamlineAdapter {
    std::uint32_t vendorId = 0;  // PCI vendor id; 0 = not known
    std::uint8_t luid[8]{};
    bool hasLuid = false;
    std::string name;
};
struct StreamlineHost {
    // Reads the IDXGIAdapter1* a D3D12 hook callback gives. False: the adapter could not be read (Streamline then decides alone).
    std::function<bool(const void* adapter, StreamlineAdapter& out)> readAdapter;
    // Releases one reference of a COM object (a replacement of the device or the factory that has to be undone).
    std::function<void(void* object)> releaseCom;
};
// The Windows one (DXGI, IUnknown::Release); elsewhere readAdapter reads nothing and releaseCom does nothing.
StreamlineHost default_streamline_host();

// What the runtime knows after the device was made (or failed to be).
struct StreamlineStatus {
    bool tried = false;  // a device was made (or tried) with this hook
    bool ready = false;  // slInit succeeded and the device is set up: the features can be used
    gpu::Backend backend = gpu::Backend::Recording;
    std::string reason;  // when tried and not ready: what is wrong and what to do
    std::uint64_t generation =
        0;  // grows with every successful set-up: a feature drops what it made for the previous one
};

class StreamlineRuntime final : public gpu::DeviceHook {
public:
    // `features`: the sl::Feature ids to load (slInit's featuresToLoad), in the order of their importance; the first decides whether the
    // runtime is worth starting (every one is asked slIsFeatureSupported). A feature built on this runtime adds its id here.
    explicit StreamlineRuntime(std::vector<std::uint32_t> features, StreamlineHost host = default_streamline_host());
    ~StreamlineRuntime() override;

    // gpu::DeviceHook
    std::string_view name() const override { return "NVIDIA Streamline"; }
    void vulkan_instance_request(gpu::VulkanInstanceRequest& request) override;
    void vulkan_instance_created(const void* instance, gpu::HookProcAddr getInstanceProcAddr) override;
    void vulkan_device_request(const gpu::VulkanPhysicalDevice& physical, gpu::VulkanDeviceRequest& request) override;
    gpu::HookProcAddr vulkan_resolve(const char* name, const void* device, gpu::HookProcAddr resolved) override;
    void vulkan_device_created(const gpu::VulkanDeviceCreated& created) override;
    void d3d12_before_device(const gpu::D3d12BeforeDevice& before) override;
    void d3d12_device_created(gpu::D3d12DeviceCreated& created) override;
    void present_end(const gpu::PresentEvent& event) override;
    void device_destroying() override;

    StreamlineStatus status() const;
    // "" when Streamline says `feature` runs on this machine, else its reason (slIsFeatureSupported's answer, with what to do). Meaningful
    // once status().ready.
    std::string feature_reason(std::uint32_t feature) const;
    // The function table of the loaded library; null until the runtime is ready. Valid until device_destroying().
    const StreamlineApi* api() const;

    // The generation of the set-up when it is ready (status().generation), else 0: one cheap call a feature makes before it calls Streamline, so
    // nothing is called after the device went (the functions of a shut-down Streamline are gone) or on the set-up of an earlier device.
    std::uint64_t ready_generation() const;

    // The token of the frame being rendered, from slGetNewFrameToken with the index of the frame (the presents completed so far: the frame
    // between present k and present k + 1 is frame k, as Streamline counts them). `index` (when given) receives it. Null token and `why`
    // when the runtime is not ready or Streamline refuses. One token per frame: DLSS, Reflex and the features after them get the same pointer
    // (the first call of a frame asks Streamline, the others take that token) so the markers, the constants and the evaluation of a frame meet.
    void* frame_token(std::uint32_t* index, std::string* why) const;
    std::uint32_t frame_index() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

// The process's runtime, with the features of the engine today (DLSS Super Resolution, Reflex and the PC latency markers it needs). Created on
// first use. M78's later packages (DLSS frame generation) add their feature ids where it is made (streamline_runtime.cpp, process_runtime).
// The latency setting is chosen after the device exists, so Reflex and PCL are always asked of slInit: a plugin that is not installed makes
// that feature unsupported with its reason and the others run.
StreamlineRuntime& streamline_runtime();
// Registers it with gpu::register_device_hook, once, so every D3D12 and Vulkan device the process makes takes part (the renderer calls this
// before it makes its device; Windows only: elsewhere there is nothing to hook and it does nothing).
void register_streamline_runtime();
// A test's own runtime in place of the process's (null puts the process's back).
void set_streamline_runtime_for_test(StreamlineRuntime* runtime);

}  // namespace fa::render
