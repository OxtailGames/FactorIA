// The vendor upscaler seam of M78 (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)", "Vendor providers"): what DLSS (NVIDIA,
// through Streamline), XeSS (Intel) and FidelityFX Super Resolution 3.1 (AMD) plug into. Private to fa_render.
//
// No vendor header or binary is in the engine. Each SDK is reached through the engine's own declarations of its C ABI and a function
// table loaded at run time from its library (the way pack_direct_storage loads dstorage.dll), found in this order:
//   1. the folder $FA_STREAMLINE_DIR / $FA_XESS_DIR / $FA_FIDELITYFX_DIR names (an explicit choice: when it is set and the library is not
//      there, the library is missing, the other places are not tried);
//   2. the folder of the executable (an exported game carries the libraries next to it);
//   3. the newest version folder of <factoria_home>/tools/<setup id>/<version>/ (`factoria setup <id>` installs it; factoria_home is
//      $FACTORIA_HOME, else ~/.factoria).
// Windows only (D3D12, Vulkan; D3D11 for DLSS Super Resolution and XeSS): everywhere else the modes exist and report unavailable, with the
// reason. A provider that cannot draw a frame returns false from upscale() and the renderer draws the temporal upscaler instead, and
// stays off that provider for the rest of the run (the rule of MetalFX: "fail once, stay off", Renderer::Impl::vendor_fail).
#pragma once

#include <array>
#include <filesystem>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/render/upscaler.h"

#include "gpu/device.h"
#include "render_upscale.h"

namespace fa::render {

// ---- the run-time library loader --------------------------------------------------------------------------------------------------

// One library an SDK is reached through.
struct VendorLibrarySpec {
    const char*
        setupId;  // "streamline", "xess", "fidelityfx": the `factoria setup` id and the folder under <factoria_home>/tools
    const char* dirEnv;    // "FA_STREAMLINE_DIR", "FA_XESS_DIR", "FA_FIDELITYFX_DIR"
    const char* fileName;  // the library's file name, e.g. "sl.interposer.dll"
};

// A loaded library: a symbol table. Never unloaded while the process runs (an SDK keeps threads), so the object only forgets the handle.
class VendorLibrary {
public:
    virtual ~VendorLibrary() = default;
    virtual void* symbol(const char* name) = 0;  // null when the library has no such export
    virtual const std::string& path() const = 0;
};

// The folders the search looks in (find_vendor_library): empty = not set.
struct VendorSearchRoots {
    std::filesystem::path envDir;  // the folder the spec's dirEnv names
    std::filesystem::path exeDir;  // the executable's folder
    std::filesystem::path home;    // factoria_home
};
// The search of the three places above, on the disk. Returns the path of the library, or an empty path and `why` (when given) a sentence that
// says where it looked. The version folders compare as dotted numbers ("2.10.0" is newer than "2.9.1"; a name that is not numbers sorts
// before every number and among its kind alphabetically), and the library is directly in the version folder.
std::filesystem::path find_vendor_library(const VendorLibrarySpec& spec, const VendorSearchRoots& roots,
                                          std::string* why = nullptr);
// The roots of this process: the environment ($FACTORIA_HOME, else the user's home + "/.factoria"; the spec's dirEnv) and the executable.
VendorSearchRoots vendor_search_roots(const VendorLibrarySpec& spec);

// Finds and opens libraries. The default one searches the disk with vendor_search_roots and loads with LoadLibraryExW (Windows; on every
// other system load() says the SDKs need Windows). A test puts a fake in with set_vendor_loader_for_test.
class VendorLoader {
public:
    virtual ~VendorLoader() = default;
    virtual std::filesystem::path find(const VendorLibrarySpec& spec, std::string* why) = 0;
    // Null and `why` (when given) the system's reason when the file cannot be loaded.
    virtual std::unique_ptr<VendorLibrary> load(const std::filesystem::path& path, std::string* why) = 0;
    // A module the GPU driver already loaded into the process (AMD's amdxc64.dll, which Anti-Lag 2 is reached through: it is part of the driver,
    // never in a folder of the game). Null and `why` (when given) the reason when it is not loaded; nothing is loaded by this call. Not
    // abstract: a loader that has no such modules (a test's fake that does not care) says there is none.
    virtual std::unique_ptr<VendorLibrary> open_loaded(const char* moduleName, std::string* why) {
        (void)moduleName;
        if (why) *why = "this loader has no modules of the driver";
        return nullptr;
    }
};
VendorLoader& vendor_loader();                        // the fake of a test, else the process's
void set_vendor_loader_for_test(VendorLoader* fake);  // null puts the process's back

// ---- the providers ----------------------------------------------------------------------------------------------------------------

// What a provider's probe is told about the machine it runs on.
struct VendorEnv {
    gpu::Backend backend = gpu::Backend::Recording;
    GpuVendor vendor = GpuVendor::None;
    // The device the provider will draw on (null in a test that only fills in the fields below): an SDK reads its native objects (the
    // Vulkan instance and physical device, the API version) to answer for this GPU.
    const gpu::Device* device = nullptr;
    // Vulkan: the instance and device extensions the creation hooks enabled when the device was made (vendor_env_of fills them from the XeSS
    // hook's grant, render_upscale_xess.h). A test that builds the environment by hand sets them.
    std::vector<std::string> vulkanInstanceExtensions, vulkanDeviceExtensions;
#if defined(_WIN32)
    bool windows = true;
#else
    bool windows = false;
#endif
};

// Whether a provider can draw here; `reason` is empty when it can, else a sentence that says what is missing and what to do.
struct VendorProbe {
    bool available = false;
    std::string reason;
};

// What a provider draws a frame from. The images are the frame's: `color` at the render size (before the sharpen, exposed: see
// UpscaleInput::exposure), `depth` and `velocity` and `reactive` when the frame has them (null images when not), `output` at the output
// size. `list` is the upscale pass's own command list: a provider records into it (a native record with resource-state declaration comes
// with M78-P2a). `error` is set by a provider that returns false.
struct VendorFrame {
    gpu::Device* device = nullptr;
    gpu::CommandList* list = nullptr;
    gpu::Image color{}, depth{}, velocity{}, reactive{}, output{};
    // DLSS Ray Reconstruction's guides (UpscaleInput::normalRoughness, diffuseAlbedo, specularAlbedo), null when the frame has none.
    gpu::Image normalRoughness{}, diffuseAlbedo{}, specularAlbedo{};
    gpu::Image
        rrDepth{};  // the hardware depth of the camera's projection that Ray Reconstruction reads in place of `depth`
    gpu::Image hitDistance{};  // M79-P4b-2, optional: UpscaleInput::hitDistance's image (null when the frame has none)
    gpu::PixelFormat colorFormat = gpu::PixelFormat::None, outputFormat = gpu::PixelFormat::None;
    std::string error;
    // Set by upscale(): whether the frame was drawn with Ray Reconstruction; and, when UpscaleInput::rayReconstruction asked for it and the
    // provider drew with Super Resolution instead, the sentence that says why (the renderer logs it once and stops asking).
    bool usedRayReconstruction = false;
    std::string rayReconstructionFallback;
};

// One vendor SDK.
class VendorUpscaler {
public:
    virtual ~VendorUpscaler() = default;
    virtual std::string_view name() const = 0;      // "DLSS", "XeSS", "FSR 3.1+"
    virtual std::string_view mode() const = 0;      // the render.upscaler mode name: "dlss", "xess", "fsr"
    virtual std::string_view setup_id() const = 0;  // "streamline", "xess", "fidelityfx"
    virtual unsigned backends() const = 0;          // the bits (1 << gpu::Backend) of the backends it can draw on
    // Whether this provider can draw on `env` (the backend, the GPU's maker, the library installed and usable). Cheap enough to ask once per
    // renderer, never per frame; the renderer keeps the answer.
    virtual VendorProbe probe(const VendorEnv& env) = 0;
    // Whether it can draw with its denoiser-upscaler too (DLSS Ray Reconstruction, M78-P4c): what probe() asks plus that denoiser's own
    // requirements. The others have none.
    virtual VendorProbe probe_ray_reconstruction(const VendorEnv& env) {
        (void)env;
        VendorProbe p;
        p.reason = std::string(name()) + " has no ray reconstruction.";
        return p;
    }
    // Draws `in` into frame.output; false (and frame.error) when it cannot, and the renderer draws the temporal upscaler instead.
    virtual bool upscale(const UpscaleInput& in, VendorFrame& frame) = 0;
    // Whether the output image of a frame it draws needs storage usage (an SDK that writes it from a compute shader). Asked when the
    // renderer decides the frame's images, before upscale().
    virtual bool needs_output_storage() const { return false; }
    // Whether the depth image it reads is the reversed depth of an infinite far plane (near / distance: 1 at the near plane, 0 for the sky;
    // FSR's inverted and infinite flags) instead of the 0..1 depth that grows with the distance (d / (d + 1)) the other SDKs read.
    virtual bool wants_reversed_depth() const { return false; }
    // Gives back what the provider made on `device` (a context of the SDK): the renderer calls it when it shuts down, before the device
    // goes. The provider is a process-wide singleton, so it is also called for a device that never drew with it (nothing to do then).
    virtual void release(gpu::Device& device) { (void)device; }
};

// The provider of vendor index 0 (dlss), 1 (xess), 2 (fsr): the registered one, or the fake of a test.
VendorUpscaler& vendor_provider(int index);
void set_vendor_provider_for_test(int index, VendorUpscaler* fake);  // null puts the registered one back

// The maker of the GPU of `device`, and its probe environment.
GpuVendor gpu_vendor_of(const gpu::Device& device);
// The maker of the GPU an API identified: Nvidia, Amd, Intel and Apple by their PCI vendor id (gpu::gpu_vendor_from_pci), None for no
// identity at all (no vendor id and an unknown maker), Other for the rest (Microsoft's WARP, Mesa's rasterisers, Arm, Qualcomm).
GpuVendor gpu_vendor_from_identity(const gpu::GpuIdentity& identity);
VendorEnv vendor_env_of(const gpu::Device& device);

// How the refusals name a backend ("D3D12", "Vulkan") and a maker ("an Intel GPU"); a provider's own sentences use the same words.
const char* vendor_backend_label(gpu::Backend backend);
std::string vendor_describe_gpu(GpuVendor vendor);

// The sentence of a provider refused by `env`'s backend, GPU maker or system ("" when none refuses it): the checks every provider shares,
// in the order backend, system. The GPU maker check of DLSS is its own.
std::string vendor_environment_problem(const VendorUpscaler& provider, const VendorEnv& env);
// The same for any SDK: its name and the backends (bits of 1 << gpu::Backend) it can run on (the low-latency providers use it).
std::string vendor_environment_problem(std::string_view name, unsigned backends, const VendorEnv& env);

}  // namespace fa::render
