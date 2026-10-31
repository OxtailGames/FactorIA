// The folder of the user-level settings files: ai.json (fa_ai), feedback-sharing.json and feedback-outbox.json
// (fa/tooling/feedback_share.h), feedback-admin.json (the engine developer's own).
//
// One rule in one place, so that fa_ai (which sits above fa_tooling) and the tools agree on it:
//   $FACTORIA_AI_CONFIG set   the folder of that file (a test or a second profile points the whole set elsewhere);
//   Windows                   %APPDATA%\factoria, else %USERPROFILE%\.factoria;
//   macOS and Linux           ~/.factoria;
//   nothing known             ".factoria" (relative to the current folder).
#pragma once

#include <functional>
#include <string>

namespace fa {

using UserConfigEnv = std::function<std::string(const std::string& name)>;  // "" when the variable is unset

// The process environment.
UserConfigEnv system_user_config_env();

// The folder described above (not created).
std::string user_config_dir(const UserConfigEnv& env = system_user_config_env());

}  // namespace fa
