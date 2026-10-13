#include "fa/script/script.h"
namespace fa {
struct ScriptSystem::Impl {
    std::vector<ScriptError> errors;
};
std::string ScriptError::to_string() const { return file + ": " + message; }
Json TestReport::to_json() const { return Json::object(); }
std::string TestReport::summary() const { return ""; }
ScriptSystem::ScriptSystem() : impl_(std::make_unique<Impl>()) {}
ScriptSystem::~ScriptSystem() = default;
bool ScriptSystem::init(ScriptHost&, std::string*) { return true; }
void ScriptSystem::shutdown() {}
void ScriptSystem::on_scene_loaded() {}
void ScriptSystem::update(float) {}
void ScriptSystem::fixed_update(float) {}
void ScriptSystem::late_update(float) {}
void ScriptSystem::dispatch_events() {}
Result<Json> ScriptSystem::eval(std::string_view) { return Json(); }
Result<void> ScriptSystem::check_syntax(std::string_view) { return {}; }
TestReport ScriptSystem::run_tests(const std::vector<std::string>&, std::string_view) { return {}; }
const std::vector<ScriptError>& ScriptSystem::errors() const { return impl_->errors; }
void ScriptSystem::clear_errors() { impl_->errors.clear(); }
void ScriptSystem::reload_module(std::string_view) {}
Json ScriptSystem::api_manifest() const { return Json::object(); }
std::string ScriptSystem::typescript_declarations() const { return ""; }
Json ScriptSystem::stats() const { return Json::object(); }
}  // namespace fa
