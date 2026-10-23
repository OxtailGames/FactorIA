// The tooling side of the Apple backend (docs/PLATFORM.md, "Apple"): the plugin manifest the exports read, the entitlements
// and StoreKit configuration they write, the plugin template, and platform.add_backend {"backend": "apple"}.
#include <doctest.h>

#include <filesystem>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/services/platform.h"
#include "fa/tooling/plugin_manifest.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/storekit_config.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kFullManifest = R"json({
  "frameworks": ["StoreKit", "GameKit", "StoreKit"],
  "swift": true,
  "entitlements": {
    "com.apple.developer.game-center": true,
    "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)",
    "com.apple.security.application-groups": ["group.com.example.game"],
    "com.example.level": 3
  }
})json";

PlatformCatalog catalog_of(const char* json) {
    auto parsed = parse_platform_catalog(Json::parse(json));
    REQUIRE(parsed.issues.empty());
    return parsed.catalog;
}

}  // namespace

TEST_CASE("plugin manifest: frameworks, swift and entitlements") {
    auto m = parse_plugin_manifest(kFullManifest, "plugins/apple/ios/plugin.json");
    REQUIRE_MESSAGE(m.ok(), (m.ok() ? "" : m.error().to_string()));
    CHECK(m->frameworks == std::vector<std::string>{"StoreKit", "GameKit"});  // listed twice, linked once
    CHECK(m->swift);
    CHECK(m->entitlements.size() == 4);
    CHECK(m->entitlements["com.apple.developer.game-center"] == true);
    CHECK(m->entitlements["com.example.level"] == 3);
    CHECK_FALSE(m->empty());

    // Every key is optional: {} is a plugin that needs nothing.
    auto none = parse_plugin_manifest("{}", "plugin.json");
    REQUIRE(none.ok());
    CHECK(none->empty());
}

TEST_CASE("plugin manifest: every mistake names the file and the JSON pointer and says how to fix it") {
    auto bad = [](const char* text) {
        auto m = parse_plugin_manifest(text, "apple/ios/plugin.json");
        REQUIRE_FALSE(m.ok());
        return m.error();
    };
    Error e = bad(R"({"framworks": ["StoreKit"]})");
    CHECK(e.message.find("apple/ios/plugin.json#/framworks") != std::string::npos);
    CHECK(e.hint.find("Did you mean 'frameworks'?") != std::string::npos);
    CHECK(e.hint.find("entitlements") != std::string::npos);  // the list of keys

    e = bad(R"({"frameworks": "StoreKit"})");
    CHECK(e.message.find("#/frameworks") != std::string::npos);
    CHECK(e.hint.find("[\"StoreKit\"") != std::string::npos);

    e = bad(R"({"frameworks": ["StoreKit", "Game Kit.framework"]})");
    CHECK(e.message.find("#/frameworks/1") != std::string::npos);
    CHECK(e.message.find("Game Kit.framework") != std::string::npos);
    CHECK(e.hint.find(".framework") != std::string::npos);

    e = bad(R"({"swift": "yes"})");
    CHECK(e.message.find("#/swift") != std::string::npos);

    e = bad(R"({"entitlements": ["com.apple.developer.game-center"]})");
    CHECK(e.message.find("#/entitlements") != std::string::npos);

    e = bad(R"({"entitlements": {"game center": true}})");
    CHECK(e.message.find("#/entitlements/game center") != std::string::npos);

    e = bad(R"({"entitlements": {"com.apple.developer.game-center": {"on": true}}})");
    CHECK(e.message.find("#/entitlements/com.apple.developer.game-center") != std::string::npos);

    e = bad("[1, 2]");
    CHECK(e.message.find("JSON object") != std::string::npos);

    e = bad(R"({"swift": true,)");  // not JSON at all: the parser's own message, with the file
    CHECK(e.message.find("apple/ios/plugin.json") != std::string::npos);
}

TEST_CASE("plugin manifest: read from a folder, and merged over several plugins") {
    testing::TempDir tmp;
    const stdfs::path dir = tmp.sub("ios");
    auto missing = read_plugin_manifest(dir);
    REQUIRE(missing.ok());  // no plugin.json: nothing needed
    CHECK(missing->empty());

    testing::write_all(dir / "plugin.json", kFullManifest);
    auto read = read_plugin_manifest(dir);
    REQUIRE(read.ok());
    CHECK(read->swift);

    PluginManifest a;
    a.frameworks = {"StoreKit", "GameKit"};
    a.entitlements = Json::parse(R"({"com.apple.developer.game-center": true})");
    PluginManifest b;
    b.frameworks = {"GameKit", "AuthenticationServices"};
    b.swift = true;
    b.entitlements = Json::parse(R"({"com.apple.developer.game-center": true, "com.apple.developer.applesignin": ["Default"]})");
    auto merged = merge_plugin_manifests({{"apple", a}, {"login", b}});
    REQUIRE_MESSAGE(merged.ok(), (merged.ok() ? "" : merged.error().to_string()));
    CHECK(merged->frameworks == std::vector<std::string>{"StoreKit", "GameKit", "AuthenticationServices"});
    CHECK(merged->swift);
    CHECK(merged->entitlements.size() == 2);

    // The same entitlement with another value is a conflict between two plugins: the error names both.
    PluginManifest c;
    c.entitlements = Json::parse(R"({"com.apple.developer.game-center": false})");
    auto clash = merge_plugin_manifests({{"apple", a}, {"other", c}});
    REQUIRE_FALSE(clash.ok());
    CHECK(clash.error().message.find("'apple' and 'other'") != std::string::npos);
    CHECK(clash.error().message.find("com.apple.developer.game-center") != std::string::npos);
    CHECK_FALSE(clash.error().hint.empty());
}

TEST_CASE("entitlements_plist writes a property list codesign and Xcode read") {
    const std::string plist = entitlements_plist(Json::parse(R"({
      "com.apple.developer.game-center": true,
      "com.example.off": false,
      "com.example.level": 3,
      "com.example.team": "A&B <1>",
      "com.apple.security.application-groups": ["group.com.example.game"]})"));
    CHECK(plist.rfind("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", 0) == 0);
    CHECK(plist.find("<plist version=\"1.0\">\n<dict>") != std::string::npos);
    CHECK(plist.find("<key>com.apple.developer.game-center</key>\n\t<true/>") != std::string::npos);
    CHECK(plist.find("<key>com.example.off</key>\n\t<false/>") != std::string::npos);
    CHECK(plist.find("<integer>3</integer>") != std::string::npos);
    CHECK(plist.find("<string>A&amp;B &lt;1&gt;</string>") != std::string::npos);
    CHECK(plist.find("<array>\n\t\t<string>group.com.example.game</string>\n\t</array>") != std::string::npos);
    // The keys keep the order of the manifest.
    CHECK(plist.find("game-center") < plist.find("com.example.off"));
    CHECK(plist.find("com.example.off") < plist.find("application-groups"));
    CHECK(plist.find("</dict>\n</plist>\n") != std::string::npos);
    CHECK(entitlements_plist(Json::object()).find("<dict>\n</dict>") != std::string::npos);
}

TEST_CASE("storekit configuration: the catalog's products, as Xcode sells them") {
    const PlatformCatalog catalog = catalog_of(R"({"products": [
      {"id": "gems_100", "type": "consumable", "title": "100 gems", "description": "A pile of gems", "price": 0.99,
       "ids": {"apple": "com.example.gems100", "steam": "7001"}},
      {"id": "no_ads", "type": "nonConsumable", "title": "No ads", "price": 4.5},
      {"id": "vip", "type": "subscription", "title": "VIP", "price": 2.99},
      {"id": "vip_plus", "type": "subscription", "title": "VIP+", "price": 5}]})");
    const Json config = storekit_configuration(catalog, "apple", "Space Dodge", "com.example.spacedodge");

    CHECK(config["version"]["major"] == 3);
    REQUIRE(config["products"].size() == 2);
    const Json& gems = config["products"][0];
    CHECK(gems["productID"] == "com.example.gems100");  // the id Apple knows it by, not the catalog's
    CHECK(gems["type"] == "Consumable");
    CHECK(gems["displayPrice"] == "0.99");
    CHECK(gems["localizations"][0]["displayName"] == "100 gems");
    CHECK(gems["localizations"][0]["description"] == "A pile of gems");
    const Json& ads = config["products"][1];
    CHECK(ads["productID"] == "no_ads");
    CHECK(ads["type"] == "NonConsumable");
    CHECK(ads["displayPrice"] == "4.50");
    CHECK(ads["localizations"][0]["description"] == "No ads");  // no description: the title stands in

    // Subscriptions live in one group, one level each.
    REQUIRE(config["subscriptionGroups"].size() == 1);
    const Json& group = config["subscriptionGroups"][0];
    CHECK(group["name"] == "Space Dodge");
    REQUIRE(group["subscriptions"].size() == 2);
    CHECK(group["subscriptions"][0]["productID"] == "vip");
    CHECK(group["subscriptions"][0]["type"] == "RecurringSubscription");
    CHECK(group["subscriptions"][0]["recurringSubscriptionPeriod"] == "P1M");
    CHECK(group["subscriptions"][0]["groupNumber"] == 1);
    CHECK(group["subscriptions"][1]["groupNumber"] == 2);
    CHECK(group["subscriptions"][0]["subscriptionGroupID"] == group["id"]);

    // Stable: exporting twice writes the same file (a diff-friendly project), another game another identifiers.
    CHECK(storekit_configuration(catalog, "apple", "Space Dodge", "com.example.spacedodge") == config);
    CHECK(storekit_configuration(catalog, "apple", "Space Dodge", "com.example.other")["identifier"] != config["identifier"]);

    // No products: an empty but valid file. No subscription: no group.
    const Json empty = storekit_configuration(PlatformCatalog(), "apple", "Game", "id");
    CHECK(empty["products"].empty());
    CHECK(empty["subscriptionGroups"].empty());
    const PlatformCatalog one = catalog_of(R"({"products": [{"id": "a", "type": "consumable", "title": "A", "price": 1}]})");
    CHECK(storekit_configuration(one, "apple", "Game", "id")["subscriptionGroups"].empty());
}

TEST_CASE("storekit configuration: the storefront follows the currency of the catalog") {
    auto locale = [](const char* currency) {
        const PlatformCatalog c = catalog_of((std::string(R"({"products": [{"id": "a", "type": "consumable", "title": "A", "price": 1, "currency": ")") +
                                              currency + "\"}]}").c_str());
        return storekit_configuration(c, "apple", "G", "id")["settings"];
    };
    CHECK(locale("USD")["_storefront"] == "USA");
    CHECK(locale("EUR")["_storefront"] == "DEU");
    CHECK(locale("EUR")["_locale"] == "de_DE");
    CHECK(locale("JPY")["_storefront"] == "JPN");
    CHECK(locale("XXX")["_storefront"] == "USA");  // a currency the table does not know: the default
}

TEST_CASE("the apple plugin template carries its sources, manifests and build, and substitutes the name") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    auto r = reg.call("project.new_plugin", Json::parse(R"({"name": "apple", "template": "apple", "platforms": ["ios", "macos"]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const stdfs::path plugin = stdfs::path(dir) / "plugins/apple";
    for (const char* f : {"CMakeLists.txt", "README.md", "src/Plugin.swift", "src/Purchases.swift", "src/GameCenter.swift", "src/CloudSave.swift",
                          "src/Common.swift", "src/Errors.swift", "src/entry.c", "include/module.modulemap", "include/fa_plugin.h",
                          "ios/plugin.json", "macos/plugin.json"})
        CHECK_MESSAGE(stdfs::exists(plugin / f), f);

    // The manifests the exports read are valid, and say what the Swift sources need.
    auto ios = read_plugin_manifest(plugin / "ios");
    REQUIRE_MESSAGE(ios.ok(), (ios.ok() ? "" : ios.error().to_string()));
    CHECK(ios->swift);
    CHECK(ios->frameworks == std::vector<std::string>{"StoreKit", "GameKit"});
    CHECK(ios->entitlements.contains("com.apple.developer.game-center"));
    CHECK(ios->entitlements.contains("com.apple.developer.ubiquity-kvstore-identifier"));
    auto mac = read_plugin_manifest(plugin / "macos");
    REQUIRE_MESSAGE(mac.ok(), (mac.ok() ? "" : mac.error().to_string()));
    CHECK(mac->entitlements.size() == 2);

    // {{NAME}} is replaced everywhere, in the build and in the readme.
    const std::string cmake = testing::read_all(plugin / "CMakeLists.txt");
    CHECK(cmake.find("{{NAME}}") == std::string::npos);
    CHECK(cmake.find("project(apple NONE)") != std::string::npos);
    CHECK(cmake.find("macos/libapple.dylib") != std::string::npos);
    CHECK(cmake.find("ios/iphonesimulator/libapple.a") != std::string::npos);
    CHECK(testing::read_all(plugin / "README.md").find("{{NAME}}") == std::string::npos);

    // The ABI header is the engine's, with the platform backend API the Swift sources register through.
    CHECK(testing::read_all(plugin / "include/fa_plugin.h").find("add_backend") != std::string::npos);
    CHECK(testing::read_all(plugin / "include/module.modulemap").find("module CFaPlugin") != std::string::npos);
    // It registers the backend "apple" (the key of the catalog's ids) and offers no stats and no presence.
    const std::string source = testing::read_all(plugin / "src/Plugin.swift");
    CHECK(source.find("\"apple\".withCString") != std::string::npos);
    CHECK(source.find("\\\"cloudSave\\\"") != std::string::npos);
    CHECK(source.find("\\\"stats\\\"") == std::string::npos);
    CHECK(source.find("\\\"presence\\\"") == std::string::npos);
}

TEST_CASE("platform.add_backend apple: writes the plugin for iOS and macOS and lists the App Store Connect steps") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    ScaffoldOptions so;
    so.name = "Space Dodge";
    so.id = "com.example.spacedodge";
    REQUIRE(create_project(dir, "2d-empty", so).ok());
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["platform"] = Json::parse(R"({
      "achievements": [{"id": "first_win", "name": "First win"}, {"id": "perfect", "name": "Perfect", "ids": {"apple": "grp.perfect"}}],
      "leaderboards": [{"id": "high_score", "name": "High score"}],
      "products": [{"id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99, "ids": {"apple": "com.example.gems100"}}]})");
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);

    const CommandInfo* info = reg.info("platform.add_backend");
    REQUIRE(info != nullptr);
    const Json& props = info->inputSchema["properties"];
    REQUIRE(props.contains("appleSlices"));
    REQUIRE(props.contains("appleBuild"));
    CHECK(props["appleBuild"]["default"] == true);
    CHECK_FALSE(props["appleSlices"].value("description", std::string()).empty());
    CHECK(info->description.find("apple:") != std::string::npos);
    CHECK(info->description.find("apple: the StoreKit 2, Game Center and iCloud plugin") != std::string::npos);

    SUBCASE("a library that does not exist is refused before anything is written") {
        auto bad = reg.call("platform.add_backend", Json::parse(R"({"backend": "apple", "appleSlices": ["macos", "iphonesim"]})"));
        REQUIRE_FALSE(bad.ok);
        CHECK(bad.error["message"].get<std::string>().find("iphonesim") != std::string::npos);
        CHECK(bad.error["hint"].get<std::string>().find("iphonesimulator") != std::string::npos);
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/apple"));
    }
#if !defined(__APPLE__)
    SUBCASE("building needs a Mac with Xcode, and the error says how to go on") {
        auto bad = reg.call("platform.add_backend", Json::parse(R"({"backend": "apple"})"));
        REQUIRE_FALSE(bad.ok);
        CHECK(bad.error["message"].get<std::string>().find("Mac with Xcode") != std::string::npos);
        CHECK(bad.error["hint"].get<std::string>().find("appleBuild") != std::string::npos);
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/apple"));  // nothing half-done
    }
#endif
    SUBCASE("appleBuild false writes and declares the plugin without building") {
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "apple", "appleBuild": false})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["backend"] == "apple");
        CHECK(stdfs::exists(stdfs::path(dir) / "plugins/apple/src/Plugin.swift"));
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/apple/build"));
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/apple/macos/libapple.dylib"));

        auto settings = load_project(dir);
        REQUIRE(settings.ok());
        REQUIRE(settings->plugins.size() == 1);
        CHECK(settings->plugins[0].name == "apple");
        CHECK(settings->plugins[0].platforms == std::vector<std::string>{"ios", "macos"});

        std::string done;
        for (const Json& d : r.result["done"]) done += d.get<std::string>() + "\n";
        CHECK(done.find("created the plugin 'apple'") != std::string::npos);
        CHECK(done.find("did not build") != std::string::npos);

        // The next steps use the game's own bundle id and the ids Apple will know its catalog by.
        std::string steps;
        for (const Json& s : r.result["nextSteps"]) steps += s.get<std::string>() + "\n";
        CHECK(steps.find("com.example.spacedodge") != std::string::npos);
        CHECK(steps.find("Game Center, In-App Purchase and iCloud") != std::string::npos);
        CHECK(steps.find("\"com.example.gems100\"") != std::string::npos);
        CHECK(steps.find("\"first_win\"") != std::string::npos);
        CHECK(steps.find("\"grp.perfect\"") != std::string::npos);
        CHECK(steps.find("\"high_score\"") != std::string::npos);
        CHECK(steps.find("Paid Apps Agreement") != std::string::npos);
        CHECK(steps.find("sandbox") != std::string::npos);
        CHECK(steps.find("Products.storekit") != std::string::npos);

        // Again: it keeps what is there.
        auto again = reg.call("platform.add_backend", Json::parse(R"({"backend": "apple", "appleBuild": false})"));
        REQUIRE_MESSAGE(again.ok, again.error.dump());
        std::string keptDone;
        for (const Json& d : again.result["done"]) keptDone += d.get<std::string>() + "\n";
        CHECK(keptDone.find("kept the plugin 'apple'") != std::string::npos);
        CHECK(load_project(dir)->plugins.size() == 1);
    }
}

TEST_CASE("storekit configuration: one localization per language of the game, from the products' title and description keys") {
    const PlatformCatalog catalog = catalog_of(R"({"products": [
      {"id": "gems", "type": "consumable", "title": "100 gems", "titleKey": "shop.gems", "descriptionKey": "shop.gems.desc",
       "price": 0.99},
      {"id": "plain", "type": "nonConsumable", "title": "Plain", "price": 1},
      {"id": "vip", "type": "subscription", "title": "VIP", "titleKey": "shop.vip", "price": 2.99}]})");
    const std::vector<StoreKitLanguage> languages = {
        {"en", {{"shop.gems", "100 gems"}, {"shop.gems.desc", "A pile of gems"}, {"shop.vip", "VIP club"}}},
        {"es-ES", {{"shop.gems", "100 gemas"}, {"shop.gems.desc", "Un monton de gemas"}}}};  // no shop.vip: the plain title
    const Json config = storekit_configuration(catalog, "apple", "G", "id", languages);

    const Json& gems = config["products"][0]["localizations"];
    REQUIRE(gems.size() == 2);
    CHECK(gems[0]["locale"] == "en");
    CHECK(gems[0]["displayName"] == "100 gems");
    CHECK(gems[1]["locale"] == "es_ES");
    CHECK(gems[1]["displayName"] == "100 gemas");
    CHECK(gems[1]["description"] == "Un monton de gemas");
    const Json& plain = config["products"][1]["localizations"];  // no keys: the catalog's text in every language
    REQUIRE(plain.size() == 2);
    CHECK(plain[1]["displayName"] == "Plain");
    CHECK(plain[1]["description"] == "Plain");
    const Json& vip = config["subscriptionGroups"][0]["subscriptions"][0]["localizations"];
    REQUIRE(vip.size() == 2);
    CHECK(vip[0]["displayName"] == "VIP club");
    CHECK(vip[1]["displayName"] == "VIP");

    // No languages: the old single localization.
    CHECK(storekit_configuration(catalog, "apple", "G", "id")["products"][0]["localizations"].size() == 1);
}
