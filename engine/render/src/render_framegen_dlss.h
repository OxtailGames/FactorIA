// The NVIDIA DLSS frame generation provider of M78 (render_framegen.h; docs/FRAME_GENERATION.md, "NVIDIA DLSS frame generation"). Private to fa_render.
//
// DLSS frame generation (DLSS-G) is a Streamline feature: the engine tells Streamline the camera of each frame (slSetConstants), tags the depth,
// the motion vectors and the picture before the screen-space items (slSetTagForFrame) and switches generation on or off (slDLSSGSetOptions);
// Streamline then generates the frame between two rendered ones INSIDE Present, from the swapchain it hooked. There is no evaluate call and no
// pass of the engine's own to record: the provider's "dispatch" only hands Streamline the frame's inputs. No NVIDIA header or binary is in the
// engine (decisions D1 and D2 of M78): the two DLSS-G functions come from slGetFeatureFunction and the structures are declared in
// streamline_runtime.h (`sl_abi`), written from the public headers of Streamline 2.14.16 with their sizes checked at build time.
//
// What it needs, and what refuses it with a sentence that says how to fix it (probe):
//  - an NVIDIA GeForce RTX 40 series GPU or newer (Streamline's own answer to slIsFeatureSupported, which also says when the driver or Windows
//    is too old or "Hardware-accelerated GPU scheduling" is off), Direct3D 12 or Vulkan on Windows, and `factoria setup streamline` done;
//  - the feature in the list Streamline was started with: this provider adds it (device_hook) when a renderer asks for frame generation,
//    before that renderer's device is made. A device made without it cannot get it later (restart the game);
//  - NVIDIA Reflex on, with its markers sent every frame (DLSS-G reports eFailReflexNotDetectedAtRuntime without them): requires_reflex()
//    makes the renderer turn Reflex on while this provider runs, whatever the player's latency mode, and dispatch refuses a frame while
//    Reflex is not running (reflex_running). The Streamline plugins of Reflex and the PC latency markers must be usable too.
//
// Used from the thread that draws only (the engine's main thread): nothing here is locked, and slDLSSGSetOptions and slDLSSGGetState, which
// Streamline says are not thread safe, are called from it alone (GetState from generated_frames, once per rendered frame, so the provider is
// the only caller).
#pragma once

#include <memory>

#include "render_framegen.h"

namespace fa::render {

// The provider the DLSS slot of the table holds (render_framegen.cpp). Tests make their own to start from a clean state.
std::unique_ptr<FrameGenProvider> make_dlss_framegen_provider();

}  // namespace fa::render
