// The non-UI half of the AI settings window's per-project editing (ai_project_edit.h): what a row says about its source, what the Roles and
// Assets tabs would write to the project's file, and what Save as my defaults writes to ai.json.
#include <filesystem>

#include "ai_project_edit.h"
#include "doctest.h"
#include "fa/core/fs.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

struct TempProject {
    stdfs::path dir = fs::make_temp_dir("fa_ai_project_edit").value();
    stdfs::path home = fs::make_temp_dir("fa_ai_project_edit_home").value();  // where ai.json and ai-trust.json would be: never the real ~/.factoria
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
        stdfs::remove_all(home, ec);
    }
    std::string aiConfigPath() const { return (home / "ai.json").string(); }
};

// The resolution of a project that has no settings file over `inherited`.
ai::ResolvedAiConfig resolve_plain(const TempProject& p, const ai::AiConfig& inherited) {
    auto r = ai::resolve_ai_config_over(p.dir.string(), inherited, p.aiConfigPath());
    if (!r) FAIL(r.error().to_string());
    return std::move(*r);
}

ai::AiConfig user_with_image_route() {
    ai::AiConfig cfg = ai::default_config();
    cfg.assets["image"] = ai::AssetRoute{"openai", "", ""};
    return cfg;
}

}  // namespace

TEST_CASE("the AI settings window's title says which settings it edits") {
    CHECK(ai_settings_title(true, "Space Cats") == "AI settings - This project: Space Cats");
    CHECK(ai_settings_title(true, "") == "AI settings - This project: (unnamed)");
    CHECK(ai_settings_title(false, "Space Cats") == "AI settings - Your defaults");
}

TEST_CASE("a row's source label") {
    CHECK(std::string(ai_source_label(ai::SettingSource::Project)) == "This project");
    CHECK(std::string(ai_source_label(ai::SettingSource::You)) == "Your defaults");
    CHECK(std::string(ai_source_label(ai::SettingSource::Default)) == "Built in");
}

TEST_CASE("a group is the project's when the project sets any value in it") {
    ai::ResolvedAiConfig r;
    r.sources["/roles/worker/model"] = ai::SettingSource::Project;
    r.sources["/roles/worker/provider"] = ai::SettingSource::You;
    r.sources["/roles/artist/model"] = ai::SettingSource::You;
    r.sources["/roles/artist/provider"] = ai::SettingSource::Default;
    r.sources["/roles/reviewer/model"] = ai::SettingSource::Default;
    CHECK(ai_group_source(r, "/roles/worker") == ai::SettingSource::Project);
    CHECK(ai_group_source(r, "/roles") == ai::SettingSource::Project);
    CHECK(ai_group_source(r, "/roles/worker/provider") == ai::SettingSource::You);
    CHECK(ai_group_source(r, "/roles/artist") == ai::SettingSource::You);
    CHECK(ai_group_source(r, "/roles/reviewer") == ai::SettingSource::Default);
    // "/roles/work" is not a prefix of "/roles/worker": a pointer names whole path segments.
    CHECK(ai_group_source(r, "/roles/work") != ai::SettingSource::Project);
}

TEST_CASE("edits are laid over a config: the orchestrator stays on, an empty route is no route") {
    ai::AiConfig base = user_with_image_route();
    std::map<std::string, ai::RoleConfig> roles;
    roles["orchestrator"] = base.role("orchestrator");
    roles["orchestrator"].enabled = false;
    roles["worker"] = base.role("worker");
    roles["worker"].model = "w-model";
    std::map<std::string, ai::AssetRoute> routes;
    routes["image"] = {};  // None
    routes["sound"] = {"elevenlabs", "m", ""};
    const ai::AiConfig out = ai_apply_edits(base, &roles, &routes, nullptr);
    CHECK(out.role("orchestrator").enabled);
    CHECK(out.role("worker").model == "w-model");
    CHECK(!out.assets.count("image"));
    CHECK(out.assets.at("sound").provider == "elevenlabs");
    // A null part stays as the base has it.
    const ai::AiConfig same = ai_apply_edits(base, nullptr, nullptr, nullptr);
    CHECK(same.assets.at("image").provider == "openai");
}

TEST_CASE("the project's file gets only what differs from the user's defaults") {
    TempProject p;
    const ai::AiConfig user = ai::default_config();
    const ai::ResolvedAiConfig r = resolve_plain(p, user);
    std::map<std::string, ai::RoleConfig> roles;
    for (const char* name : ai::kAllRoles) roles[name] = r.config.role(name);
    auto none = ai_project_overrides_for(r, &roles, nullptr, nullptr);
    REQUIRE(bool(none));
    CHECK((none->is_null() || none->empty()));  // nothing differs: nothing to write

    roles["worker"].model = "project-model";
    auto one = ai_project_overrides_for(r, &roles, nullptr, nullptr);
    REQUIRE(bool(one));
    REQUIRE(one->contains("roles"));
    CHECK((*one)["roles"]["worker"]["model"] == "project-model");
    CHECK(!(*one)["roles"].contains("orchestrator"));
    CHECK(!one->contains("assets"));
}

TEST_CASE("a project cannot turn a kind of asset the user has a provider for back to None") {
    TempProject p;
    const ai::ResolvedAiConfig r = resolve_plain(p, user_with_image_route());
    std::map<std::string, ai::AssetRoute> routes;
    routes["image"] = {};
    auto refused = ai_project_overrides_for(r, nullptr, &routes, nullptr);
    REQUIRE(!refused);
    CHECK(refused.error().message.find("image") != std::string::npos);
    CHECK(!refused.error().hint.empty());
    // Another provider for it is fine, and so are the other kinds.
    routes["image"] = {"anthropic", "", ""};
    CHECK(bool(ai_project_overrides_for(r, nullptr, &routes, nullptr)));
}

TEST_CASE("sites of the project's own go to its file") {
    TempProject p;
    const ai::ResolvedAiConfig r = resolve_plain(p, ai::default_config());
    ai::AssetSources sources = r.config.assetSources;
    sources.images.push_back({"opengameart.org", "CC0"});
    auto o = ai_project_overrides_for(r, nullptr, nullptr, &sources);
    REQUIRE(bool(o));
    REQUIRE(o->contains("assetSources"));
    CHECK((*o)["assetSources"]["images"].size() == 1);
}

TEST_CASE("Save as my defaults leaves out the roles that still follow the orchestrator and the worker") {
    const ai::AiConfig user = ai::default_config();
    std::map<std::string, ai::RoleConfig> edits;
    for (const char* name : ai::kAllRoles) edits[name] = user.role(name);
    edits["worker"].model = "w-model";
    const auto out = ai_roles_for_defaults(user, edits);
    CHECK(out.at("worker").model == "w-model");
    CHECK(out.count("orchestrator"));
    for (const char* extra : ai::kExtraRoles) CHECK(!out.count(extra));
    // One that was changed is kept.
    edits["artist"].model = "a-model";
    CHECK(ai_roles_for_defaults(user, edits).count("artist") == 1);
}

TEST_CASE("a reload keeps the role rows that were edited and takes the new value for the others") {
    ai::AiConfig shown = ai::default_config();
    ai::AiConfig now = shown;
    now.roles["worker"].model = "new-worker";
    now.roles["fast"].model = "new-fast";
    std::map<std::string, ai::RoleConfig> edits;
    for (const char* name : ai::kAllRoles) edits[name] = shown.role(name);
    CHECK(!ai_roles_edited(edits, shown));
    edits["worker"].model = "typed-worker";  // changed by the person, and by the file: the person's stays
    edits["orchestrator"].effort = "high";   // changed by the person only
    CHECK(ai_roles_edited(edits, shown));
    const auto out = ai_roles_keep_edits(edits, shown, now);
    CHECK(out.size() == std::size(ai::kAllRoles));
    CHECK(out.at("worker").model == "typed-worker");
    CHECK(out.at("orchestrator").effort == "high");
    CHECK(out.at("fast").model == "new-fast");  // not touched: shows the file's value
    // Turning a role off is an edit too.
    edits["artist"].enabled = false;
    CHECK(!ai_roles_keep_edits(edits, shown, now).at("artist").enabled);
}

TEST_CASE("a reload keeps the asset routes and the site lists that were edited, each on its own") {
    ai::AiConfig shown = ai::default_config();
    shown.assets["image"] = ai::AssetRoute{"openai", "", ""};
    shown.assetSources.images.push_back({"a.org", ""});
    ai::AiConfig now = shown;
    now.assets["image"].model = "file-model";
    now.assets["sound"] = ai::AssetRoute{"elevenlabs", "", ""};
    now.assetSources.images.push_back({"b.org", ""});
    now.assetSources.fonts.push_back({"fonts.org", ""});
    now.assetSources.onlyListed = true;

    std::map<std::string, ai::AssetRoute> routes;
    for (ai::MediaKind k : ai::kMediaKinds) {
        const auto it = shown.assets.find(ai::media_kind_name(k));
        routes[ai::media_kind_name(k)] = it == shown.assets.end() ? ai::AssetRoute{} : it->second;
    }
    routes["music"] = ai::AssetRoute{"openai", "typed", ""};  // typed by the person
    const auto keptRoutes = ai_routes_keep_edits(routes, shown, now);
    CHECK(keptRoutes.at("music").model == "typed");   // edited: stays
    CHECK(keptRoutes.at("image").model == "file-model");  // not edited: the file's value
    CHECK(keptRoutes.at("sound").provider == "elevenlabs");

    ai::AssetSources sources = shown.assetSources;
    sources.models.push_back({"typed.org", "note"});
    const ai::AssetSources keptSources = ai_sources_keep_edits(sources, shown, now);
    CHECK(keptSources.models.size() == 1);   // edited list stays
    CHECK(keptSources.images.size() == 2);   // untouched list: the file's
    CHECK(keptSources.fonts.size() == 1);
    CHECK(keptSources.onlyListed);           // the switch was not touched
    // The person switched "only these sites" on while the file (now) says off: theirs stays.
    ai::AiConfig fileOff = shown;
    sources.onlyListed = true;
    CHECK(ai_sources_keep_edits(sources, shown, fileOff).onlyListed);
}
