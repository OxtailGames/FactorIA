// The store page images assets.draw_capsules writes: one table of sizes per store (as of 2026-10; docs/EXPORTING.md
// "Store page material" lists the same table and where each size comes from).
#pragma once

#include <string>
#include <vector>

namespace fa {

// Where the logo goes on an asset.
enum class StoreLogo {
    None,        // art only (heroes, backgrounds, screenshots)
    Center,      // centred on the art
    Top,         // centred, in the upper part (Microsoft overlays the bottom third)
    Bottom,      // centred, low
    BottomLeft,  // low, at the left
    Only,        // a transparent PNG with just the logo (no art)
};

struct StoreAsset {
    const char* asset;         // "header capsule"
    int width, height;         // landscape for deviceShot assets
    StoreLogo logo;
    double widthFraction;      // the logo fits in widthFraction x heightFraction of the image
    double heightFraction;
    bool deviceShot;           // a phone or tablet screenshot: `orientation` portrait swaps width and height
    bool verified;             // the size is in the store's public documentation
};

// "steam", "epic", "gog", "microsoft", "googleplay", "appstore", "itch".
const std::vector<std::string>& store_ids();
// The assets of a store, or nullptr for an unknown id.
const std::vector<StoreAsset>* find_store_assets(const std::string& store);

}  // namespace fa
