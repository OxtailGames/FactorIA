#include "script_internal.h"
namespace fa {
Json ScriptSystem::Impl::api_manifest() const { return Json::object(); }
std::string ScriptSystem::Impl::typescript_declarations() const { return ""; }
}  // namespace fa
