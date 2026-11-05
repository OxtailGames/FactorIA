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
    stdfs::path dir = fs::make_temp_dir("fa_ai_project_edit");
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

// The resolution of a project that has no settings file over `inherited`.
ai::ResolvedAiConfig resolve_plain(const TempProject& p, const ai::AiConfig& inherited) {
    auto r = ai::resolve_ai_config_over(p.dir.string(), inherited);
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
