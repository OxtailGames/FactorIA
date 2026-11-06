// Pictures from an image provider inside an image document: image.inpaint and image.generate_layer (docs/IMAGES.md, "Pictures from a
// provider"). The work is split in three steps so a caller that must not block (the editor's Image panel) can run the provider call on
// a worker thread and do the rest on the main thread:
//
//   plan_image_edit    reads the document, the selection and the configuration; resolves the provider; builds the request.
//                      Everything that can be wrong with the call is found here, before anything is paid for. Main thread.
//   run_image_edit     the provider call (HTTP or a local program). Touches no project file: any thread.
//   store_image_edit   turns the answer into the picture of a layer, writes it with its provenance and returns the arguments of
//                      image.layer.add_provider. Main thread.
//
// register_image_provider_commands wires them into image.inpaint and image.generate_layer (done by register_ai_commands).
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/ai/asset_cost.h"
#include "fa/ai/assets.h"
#include "fa/core/command.h"
#include "fa/tooling/image_provider.h"

namespace fa::ai {

struct ImageEditEnv {
    std::function<Result<AiConfig>()> load;   // ai.json (the editor: its settings)
    std::string projectDir;
    ProviderRuntime runtime;
};

struct ImageEditPlan {
    bool inpaint = false;                 // true: image.inpaint, false: image.generate_layer
    std::string command;                  // "image.inpaint" / "image.generate_layer"
    std::string doc;                      // the document
    std::string layerName;                // the name of the layer that will be added
    std::string selection;                // the stored selection that masks the layer ("" = none)
    ProviderConfig provider;
    AssetRequest request;
    int canvasWidth = 0, canvasHeight = 0;
    int layerWidth = 0, layerHeight = 0;  // the size of the layer's picture
    int x = 0, y = 0;                     // where the layer's top-left corner sits on the canvas
    int sendScale = 1;                    // inpaint: the picture and mask are sent magnified by this whole factor
    bool quantize = false;                // the result is reduced to the document's palette
    std::vector<std::array<std::uint8_t, 3>> colours;   // that palette
    std::vector<std::string> referencePaths;
    std::vector<std::string> warnings;
    Json args;                            // the call, for author and overwrite details
    Json estimate;                        // what would be sent and what it may cost (dryRun returns it)
    AssetEstimate cost;                   // the price of the call (estimate_asset_cost): `estimate` carries it as text and numbers
    Limits limits;                        // limits.maxAssetCostUsd and askAboveUsd of the project at the time of the plan
};

// Throws CommandError with a fix. The error for a missing provider says how to configure one and the offline route.
ImageEditPlan plan_image_edit(const ImageEditEnv& env, bool inpaint, const Json& args);

// Before the provider is called: the price against the limits (this run, today) and the user's yes. Throws CommandError like
// AssetCostGuard::begin. `approved`: the user said yes to this call (the argument, or a button that showed the estimate). When go()
// of the guard is false return needs_approval() and call nothing. Commit the guard when the provider answered; a guard that is
// dropped gives the money back. Takes the cross-process lock of the user folder: not for the editor's UI thread.
AssetCostGuard begin_image_edit_cost(const ImageEditPlan& plan, const ImageEditEnv& env, bool approved, const CancelFlag* cancel = nullptr);

// Calls the provider. Errors say what to check.
Result<AssetResult> run_image_edit(const ImageEditPlan& plan, const ProviderRuntime& runtime, const CancelFlag* cancel = nullptr);

struct ImageEditStored {
    Json addArgs;                         // for image.layer.add_provider
    std::vector<std::string> warnings;
    Json details;                         // size, notes, provenance: merged into the command's result
};
// Writes the layer's PNG into <document>.layers/ and its provenance into assets.json. Throws CommandError. It does not change the
// document: call image.layer.add_provider with `addArgs`.
ImageEditStored store_image_edit(const ImageEditEnv& env, const ImageEditPlan& plan, const AssetResult& made);

void register_image_provider_commands(CommandRegistry& registry, std::function<Result<AiConfig>()> load,
                                      std::function<std::string()> projectDir, ProviderRuntime runtime, const CancelFlag* cancel,
                                      std::string runKey = {});

}  // namespace fa::ai
