// The sizes of the store page images, as of 2026-10. Sources (all checked 2026-10-20):
//   steam      partner.steamgames.com/doc/store/assets/standard and /libraryassets
//   epic       dev.epicgames.com/docs/epic-games-store/sales-and-marketing/marketing/storefront-media-guide
//   microsoft  learn.microsoft.com/windows/apps/publish/publish-your-app/msix/screenshots-and-images
//   googleplay support.google.com/googleplay/android-developer/answer/9866151
//   appstore   developer.apple.com/help/app-store-connect/reference/screenshot-specifications
//   gog        docs.gog.com/basic-game-assets: key art at least 1920x1080; the store images come from templates in the
//              developer portal, so the cover and background sizes are those of GOG's support article (not verified)
//   itch       the cover image upload form: recommended 630x500 (minimum 315x250); itch.io's docs do not state it
// The logo placements are FactorIA's choice unless the store has a rule (Steam library hero: no text; Steam library logo:
// transparent; Microsoft: the bottom third is overlaid; Xbox/Microsoft super hero art: no text).
#include "fa/tooling/asset_capsules.h"

#include <map>

namespace fa {

namespace {

using L = StoreLogo;

const std::map<std::string, std::vector<StoreAsset>>& table() {
    static const std::map<std::string, std::vector<StoreAsset>> t = {
        {"steam",
         {{"header capsule", 920, 430, L::Center, 0.70, 0.50, false, true},
          {"small capsule", 462, 174, L::Center, 0.90, 0.80, false, true},
          {"main capsule", 1232, 706, L::Center, 0.60, 0.45, false, true},
          {"vertical capsule", 748, 896, L::Center, 0.80, 0.35, false, true},
          {"page background", 1438, 810, L::None, 0, 0, false, true},
          {"library capsule", 600, 900, L::Bottom, 0.80, 0.30, false, true},
          {"library header", 920, 430, L::Center, 0.70, 0.50, false, true},
          {"library hero", 3840, 1240, L::None, 0, 0, false, true},
          {"library logo", 1280, 720, L::Only, 1.0, 1.0, false, true},
          {"screenshot", 1920, 1080, L::None, 0, 0, false, true}}},
        {"epic",
         {{"product logo", 960, 540, L::Only, 0.90, 0.90, false, true},
          {"offer image (landscape)", 2560, 1440, L::Center, 0.50, 0.30, false, true},
          {"offer image (portrait)", 1200, 1600, L::Center, 0.80, 0.25, false, true},
          {"social preview", 1200, 1200, L::Center, 0.70, 0.30, false, true},
          {"screenshot", 1920, 1080, L::None, 0, 0, false, true}}},
        {"gog",
         {{"key art", 1920, 1080, L::None, 0, 0, false, true},
          {"vertical cover", 342, 482, L::Bottom, 0.85, 0.30, false, false},
          {"background", 1600, 670, L::None, 0, 0, false, false}}},
        {"microsoft",
         {{"poster art (2:3)", 720, 1080, L::Top, 0.80, 0.25, false, true},
          {"box art (1:1)", 1080, 1080, L::Top, 0.80, 0.25, false, true},
          {"app tile icon", 300, 300, L::Center, 0.85, 0.40, false, true},
          {"super hero art (16:9)", 1920, 1080, L::None, 0, 0, false, true},
          {"screenshot / trailer thumbnail", 1920, 1080, L::None, 0, 0, false, true}}},
        {"googleplay",
         {{"feature graphic", 1024, 500, L::Center, 0.60, 0.50, false, true},
          {"app icon", 512, 512, L::Center, 0.85, 0.50, false, true},
          {"phone / tablet screenshot", 1920, 1080, L::None, 0, 0, true, true}}},
        {"appstore",
         {{"iPhone 6.9\" screenshot", 2868, 1320, L::None, 0, 0, true, true},
          {"iPhone 6.5\" screenshot", 2778, 1284, L::None, 0, 0, true, true},
          {"iPhone 6.3\" screenshot", 2622, 1206, L::None, 0, 0, true, true},
          {"iPad 13\" screenshot", 2752, 2064, L::None, 0, 0, true, true}}},
        {"itch",
         {{"cover image", 630, 500, L::Center, 0.80, 0.40, false, false}}},
    };
    return t;
}

}  // namespace

const std::vector<std::string>& store_ids() {
    static const std::vector<std::string> ids = {"steam", "epic", "gog", "microsoft", "googleplay", "appstore", "itch"};
    return ids;
}

const std::vector<StoreAsset>* find_store_assets(const std::string& store) {
    const auto it = table().find(store);
    return it == table().end() ? nullptr : &it->second;
}

}  // namespace fa
