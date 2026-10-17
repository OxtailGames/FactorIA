// platform.add_backend {"backend": "apple"}: the App Store, Game Center and iCloud backend (docs/PLATFORM.md, "Apple").
// Writes the plugin from its template, builds its three libraries with the Xcode toolchain (macOS, iOS device, iOS
// Simulator) and lists the App Store Connect steps only a person can do.
#include <algorithm>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/services/platform.h"
#include "platform_setup.h"

namespace fa::platform_setup {

namespace stdfs = std::filesystem;

namespace {

const std::vector<std::string>& all_slices() {
    static const std::vector<std::string> slices = {"macos", "iphoneos", "iphonesimulator"};
    return slices;
}

// Where the template's CMakeLists.txt puts each slice, relative to the plugin's folder.
std::string slice_library(const std::string& slice, const std::string& name) {
    if (slice == "macos") return "macos/lib" + name + ".dylib";
    return "ios/" + slice + "/lib" + name + ".a";
}

std::string quoted_list(const std::vector<std::string>& ids) {
    std::string out;
    for (const std::string& id : ids) out += (out.empty() ? "" : ", ") + std::string("\"") + id + "\"";
    return out;
}

}  // namespace

Backend apple_backend() {
    Backend b;
    b.name = "apple";
    b.summary = "the StoreKit 2, Game Center and iCloud plugin for iOS and macOS (Swift: it builds on a Mac with Xcode).";
    b.properties = Json::object(
        {{"appleSlices",
          Json::object({{"type", "array"},
                        {"items", Json::object({{"type", "string"}, {"enum", Json::array({"macos", "iphoneos", "iphonesimulator"})}})},
                        {"description", "apple: which libraries to build: macos (the .dylib of a Mac app), iphoneos (an iPhone or iPad) and "
                                        "iphonesimulator (the iOS Simulator). Default: all three."}})},
         {"appleBuild",
          Json::object({{"type", "boolean"},
                        {"default", true},
                        {"description", "apple: false only writes the plugin and declares it, without building (any computer); build it later on a "
                                        "Mac with Xcode: cmake -S plugins/apple -B plugins/apple/build && cmake --build plugins/apple/build."}})}});
    b.run = [](Context& ctx) {
        std::vector<std::string> slices = all_slices();
        if (ctx.args.contains("appleSlices") && ctx.args["appleSlices"].is_array() && !ctx.args["appleSlices"].empty()) {
            slices.clear();
            for (const Json& s : ctx.args["appleSlices"]) {
                const std::string name = s.is_string() ? s.get<std::string>() : std::string();
                if (std::find(all_slices().begin(), all_slices().end(), name) == all_slices().end())
                    throw CommandError("invalid_argument", "appleSlices: '" + name + "' is not a library of the Apple plugin",
                                       did_you_mean(name, all_slices()));
                if (std::find(slices.begin(), slices.end(), name) == slices.end()) slices.push_back(name);
            }
        }
        const bool build = !ctx.args.contains("appleBuild") || !ctx.args["appleBuild"].is_boolean() || ctx.args["appleBuild"].get<bool>();
        if (build && std::string(runtime_platform()) != "macos")
            throw CommandError("unavailable", "the Apple plugin builds on a Mac with Xcode, and this computer runs " + std::string(runtime_platform()),
                               "StoreKit and Game Center exist only in Apple's SDKs. Run platform.add_backend {\"backend\": \"apple\"} on a Mac, or "
                               "pass \"appleBuild\": false here to only write the plugin and declare it, then build it on a Mac "
                               "(cmake -S plugins/apple -B plugins/apple/build && cmake --build plugins/apple/build) and copy its macos/ and "
                               "ios/ folders back.");

        const std::string folder = ctx.ensure_plugin({"ios", "macos"});
        if (build) {
            ctx.run_cmake({"-S", folder, "-B", folder + "/build", "-DCMAKE_BUILD_TYPE=Release", "-DFA_APPLE_SLICES=" + join(slices, ";")},
                          "configure the apple plugin");
            ctx.run_cmake({"--build", folder + "/build"}, "build the apple plugin");
            Json libraries = Json::array();
            for (const std::string& slice : slices) {
                const std::string rel = slice_library(slice, ctx.backend);
                std::error_code ec;
                if (!stdfs::exists(stdfs::path(folder) / rel, ec))
                    throw CommandError("failed", "the build of the apple plugin left no " + folder + "/" + rel,
                                       "Look at the plugin's CMake output above; `cmake --build " + folder + "/build` repeats the build.");
                libraries.push_back(rel);
            }
            ctx.extra["libraries"] = libraries;
            ctx.done.push_back("built " + join(slices, ", ") + " with Xcode: " + libraries.dump());
        } else {
            ctx.done.push_back("did not build (appleBuild is false): on a Mac, cmake -S " + folder + " -B " + folder + "/build && cmake --build " +
                               folder + "/build");
        }

        // What the developer does by hand, with the ids of the game's own catalog.
        std::string bundleId = "com.example.game";
        if (auto project = load_project(ctx.projectDir); project.ok()) bundleId = project->id;
        std::vector<std::string> products, achievements, leaderboards;
        if (auto file = load_json_file(ctx.projectDir + "/" + kProjectFileName); file.ok() && file->is_object() && file->contains("platform")) {
            const PlatformCatalog catalog = parse_platform_catalog((*file)["platform"]).catalog;
            for (const PlatformProduct& p : catalog.products) products.push_back(p.store_id("apple"));
            for (const PlatformAchievement& a : catalog.achievements) achievements.push_back(a.store_id("apple"));
            for (const PlatformLeaderboard& l : catalog.leaderboards) leaderboards.push_back(l.store_id("apple"));
        }
        const std::string catalogText =
            products.empty() && achievements.empty() && leaderboards.empty()
                ? "Declare them in factoria.json's \"platform\" section first (docs/PLATFORM.md), then create each with the same id. "
                : "Create " +
                      std::string(products.empty() ? "" : "the products " + quoted_list(products) + " (Monetization > In-App Purchases)") +
                      std::string(!products.empty() && (!achievements.empty() || !leaderboards.empty()) ? ", " : "") +
                      std::string(achievements.empty() ? "" : "the achievements " + quoted_list(achievements) + " (Services > Game Center > Achievements)") +
                      std::string(!achievements.empty() && !leaderboards.empty() ? ", " : "") +
                      std::string(leaderboards.empty() ? "" : "the leaderboards " + quoted_list(leaderboards) + " (Services > Game Center > Leaderboards)") +
                      ", each with exactly that id (set platform.<section>[].ids.apple to use another). ";
        ctx.nextSteps = {
            "Apple Developer portal > Certificates, Identifiers & Profiles > Identifiers: the App ID " + bundleId +
                " (factoria.json \"id\") needs the capabilities Game Center, In-App Purchase and iCloud (key-value storage only).",
            "App Store Connect: add the app with that bundle id, accept the Paid Apps Agreement (Business > Agreements) and turn Game Center on "
            "for the app. " + catalogText,
            "Test with real accounts: create a sandbox tester (App Store Connect > Users and Access > Sandbox) and sign in with it under "
            "Settings > Developer > Sandbox Apple Account on a device. A development-signed build (an iPhone, or a Mac app signed with your "
            "certificate and provisioning profile) can then buy, unlock and save for real.",
            "Test purchases without any of that: `factoria export --platform ios` writes Products.storekit from your catalog and wires it "
            "into the Xcode scheme, so running the project from Xcode sells the products locally.",
            "Details, receipts (JWS) and what each method does: docs/PLATFORM.md, section Apple. In a running game the command apple.status "
            "(fa.call) lists what the device lacks."};
    };
    return b;
}

}  // namespace fa::platform_setup
