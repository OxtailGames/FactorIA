# Rendering, the ray tracing kernels (M79)

M79 adds **inline ray query only**: compute kernels that call `RayQuery::TraceRayInline` on D3D12 (DXR 1.1, DXIL shader model 6.5),
Vulkan (SPIR-V with `SPV_KHR_ray_query`) and Metal (MSL 2.4 `intersection_query`). No ray tracing pipelines, no shader binding
tables. This page is the shader side: what language the kernels are written in, how they become DXIL, SPIR-V and MSL, where DXC
comes from, and what CI checks. (The acceleration structures, the passes that dispatch the kernels and the backends'
ray-query capability bits are other packages of the milestone; the entry page of the architecture lists them.)
Page limit: every page of `docs/design/` stays under 60 KB.

## Decision: HLSL through DXC, MSL by hand

*Question O1.* The engine's shaders are GLSL through sokol-shdc (`tools/shaders/compile_shaders.sh`). Can the same path take a ray query
kernel, so that there is still one source language?

**No.** Evidence (the spike of this package, 2026-11-26):

- sokol-shdc (the pinned commit `b975d564...`) embeds glslang and SPIRV-Cross and compiles every shader as `#version 450`, while
  glslang declares `rayQueryEXT` only from `#version 460`: `#extension GL_EXT_ray_query : require` does not get through it, for
  any of the dialects (`spirv_vk`, `metal_macos`, `hlsl5`). The same kernel at `#version 460` does compile with glslang alone
  (`--target-env vulkan1.1` and `vulkan1.2` both made SPIR-V), but that would be a second tool for Vulkan only, with D3D12 and Metal
  still without a source.
- **DXC 1.9.2609** compiles one HLSL kernel (`RaytracingAccelerationStructure`, `RWTexture2D`, `ConstantBuffer`,
  `RayQuery<RAY_FLAG_FORCE_OPAQUE>`) to both targets: `dxc -T cs_6_5 -E main` gives a signed DXIL container (4280 bytes for the
  probe, `dxv` validates it) and `dxc -spirv -fspv-target-env=vulkan1.2 -fspv-extension=SPV_KHR_ray_query -T cs_6_5 -E main` gives a
  SPIR-V module with `OpCapability RayQueryKHR` (2328 bytes). The `[[vk::binding(n, 0)]]` and `[[vk::image_format("r32f")]]`
  attributes carry the Vulkan numbers; DXC ignores them for DXIL (`-Wno-ignored-attributes`).
- **Metal** is not reached by DXC (it writes DXIL and SPIR-V), and `xcrun metal` needs the Metal Toolchain download that a Mac
  does not always have. MSL 2.4 compiled at run time with `newLibraryWithSource` (`languageVersion 2_4`) needs nothing installed: the
  probe kernel's MSL compiled and ran this way on an Apple M5 (`supportsRaytracing` = 1).

**Chosen (option B):** one **HLSL** source per kernel, `engine/render/shaders/rt/<name>.hlsl`, through DXC to DXIL and to SPIR-V;
the **MSL** twin `engine/render/shaders/rt/<name>.metal` is written by hand with the same algorithm and the same binding contract
(documented at the top of the HLSL), and compiled at run time by the Metal backend. Not chosen: GLSL 460 + glslang for Vulkan and
HLSL for D3D12 (two sources for two backends, and the Metal one anyway); shipping DXC in the players (13 to 31 MB for something a build does ahead of time).

The three outputs are **committed**: `engine/render/src/shaders/rt/<name>.rt.h` (generated, `fa::rt_kernels`: `kRtProbeDxil[]`,
`kRtProbeSpirv[]`, `kRtProbeMsl[]` as byte arrays, the MSL NUL-terminated, plus the hashes of the sources they come from) and
`engine/render/src/rt_kernels.h` (the table of kernels: `all_rt_kernels()`, `find_rt_kernel(name)`). A normal build, a game and a
player never need DXC, the Metal toolchain or a network. A new kernel is `<name>.hlsl` + `<name>.metal` + a row in `rt_kernels.h`.
The probe kernel `rt_probe` (one primary ray per pixel, writes the committed hit distance, 1000 for a miss) is the first one.

## DXC and DXIL

*Question O2: does the Linux build sign DXIL?* **Yes.** The Linux tarball (`linux_dxc_2026_09_28.x86_x64.tar.gz`) holds `bin/dxc`
(RUNPATH `$ORIGIN/../lib`), `lib/libdxcompiler.so` and `lib/libdxil.so`, the validator that signs the DXIL container; without
the signer DXC writes unsigned DXIL that no driver accepts, so `setup dxc` refuses an archive without it and `find_dxc` ignores an
install that lacks it. Measured: the DXIL and the SPIR-V from Linux (run in WSL on the Windows development PC) and from Windows are
**the same bytes** (SHA-256 `85d520f9...` for the DXIL, `b7dd3a8a...` for the SPIR-V of the probe); two runs on one host are equal.
That makes the committed blobs independent of who regenerates them.

**`factoria setup dxc`** (`tools/common/src/setup_dxc.cpp`, a component like `directstorage` and `ffmpeg`): downloads the release
asset of `github.com/microsoft/DirectXShaderCompiler` for this computer, checks the SHA-256 pinned in
`tools/common/include/fa/tooling/setup.h` (`kSetupDxcVersion`, `kSetupDxcRelease`, `kSetupDxcBuilds`: Windows x64 and arm64 share
`dxc_2026_09_29.zip`, Linux x86_64 is the tarball above) and installs into `<home>/tools/dxc/<version>/`: `bin/` (the compiler and
`dxv`; the DLLs beside `dxc.exe` on Windows), `lib/` on Linux, and the licence files of the release (LLVM's NCSA/Apache-2.0 with LLVM
exceptions, Microsoft's), which stay with the compiler. Older versions are removed. `$FA_DXC_DIR` points at a DXC of your own
(`bin/dxc` or `dxc` in that folder) and wins over the install. **macOS and Linux Arm are `unsupported`**: Microsoft publishes
no build; the status says so without a red problem, and the install refuses with where the DXIL comes from instead. Tests inject
the downloader (`tools/common/tests/dxc_setup_test.cpp`) and unpack a hand-made archive; nothing downloads.

**`tools/shaders/compile_rt_shaders.sh`** reads the version from `setup.h`, finds DXC (`$FA_DXC_DIR`, else the install of that exact
version; any other `dxc` is ignored so a contributor's bytes equal CI's), compiles every `engine/render/shaders/rt/*.hlsl` and
writes the headers. `--check` writes nothing and exits 1 when a committed header differs. **Without DXC (a Mac)** the script keeps the
`dxil` and `spirv` blobs of the committed header, regenerates the `msl` blob, and reports a `.hlsl` that changed since those blobs
were made as `STALE` (`--check` exits 2). So a Mac never fails for lack of DXC: you edit the HLSL and the MSL, commit, and the Linux
job below hands back the blobs. The header records `dxc-version`, `hlsl-sha256` and `msl-sha256` and each blob's own SHA-256; the
tooling test `rt_shaders_test.cpp` (it needs no DXC, so it runs on every host) fails when an `.hlsl` or `.metal` changed without its
header, when a blob was edited by hand, and when the DXC pin moved without a regeneration. `tools/shaders/compile_rt_shaders.sh`
is the only writer of the headers; `scripts/ci-preflight.sh` reminds you when a kernel changed.

## What CI runs

- **Linux job** (`.github/workflows/ci.yml`): after the tests, installs the pinned DXC with `factoria setup dxc` (the folder is
  cached under `dxc-<os>-<version>-<sha12 of the Linux asset>`, so the download happens when the pin moves), runs
  `compile_rt_shaders.sh` and **fails when `git status` shows a change under `engine/render/src/shaders/rt`**, with an error that says what
  to do and the regenerated headers uploaded as the artifact `rt-shader-headers` (commit them over the old ones). It runs after the tests
  so that a stale header does not hide what the tests found; seconds of work, the job's 90 minutes are untouched.
- **Lavapipe's ray tracing** (question O3, Linux job): `vulkan-tools` is installed with the Vulkan CPU driver, and a step prints as
  an annotation (never a failure) the Mesa package version, the device name, whether the device lists `VK_KHR_ray_query` and
  `VK_KHR_acceleration_structure` and whether the `rayQuery` feature is true. The runner installs Mesa 25.2 from noble-updates, whose
  lavapipe offers them, so the test step sets `FA_VULKAN_REQUIRE_RT=1` and the Vulkan ray tracing tests
  (`render_vulkan_raytracing`) fail instead of skipping on a device without them; the annotation says why when they do.
- **Windows job, every shard** (WARP's DXR tier, question O3): `tools/ci/probes/d3d12_rt_probe.cpp` (compiled with `cl` in the step,
  standalone) creates a WARP device and prints `D3D12_FEATURE_DATA_D3D12_OPTIONS5.RaytracingTier` (11 = tier 1.1, what inline ray
  queries need), the highest shader model and the version of the `d3d10warp.dll` D3D12 loaded. When the OS's WARP reports less than
  11, the step downloads the NuGet package **Microsoft.Direct3D.WARP 1.0.22** (pinned by SHA-256 in the step, cached), copies its x64
  `d3d10warp.dll` beside the probe (D3D12 loads the WARP DLL from the program's folder), prints the tier it gives, and exports
  `FA_WARP_DIR` for `render_d3d12_raytracing`, which the Test step's `FA_D3D12_REQUIRE_RT=1` fails when its WARP has no tier
  1.1 (scripts/ctest_shard.py may put that test on any shard). The package's licence permits testing only and forbids
  redistribution: it is CI-only and nothing in a game, the editor or a release ever carries it. Measured on the Windows 11 development PC: the OS's WARP reports tier 11;
  the NuGet WARP 1.0.22 reports tier 12. The `windows-2022` runner's own tier is the number this step adds to every run.
  By hand (never in CI), `FA_D3D12_RT_HARDWARE=1 FA_D3D12_REQUIRE_RT=1` makes `render_d3d12_raytracing` trace on the machine's hardware adapter instead of WARP.

## What a contributor does

1. Edit `<name>.hlsl` and `<name>.metal` together (same algorithm, same bindings).
2. On Windows or Linux x86_64: `factoria setup dxc`, `tools/shaders/compile_rt_shaders.sh`, commit the header. On a Mac: run the
   script anyway (the MSL blob is regenerated), commit, and take the headers from the artifact `rt-shader-headers` of the red Linux job
   (or run `scripts/ci-local.sh linux` where Docker is usable; never on a Mac).
3. `ctest -R tooling` checks the header against the sources on any host.
