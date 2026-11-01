// A hook written in JavaScript: a module of the project's hooks/ folder, run in a QuickJS runtime of its own (docs/HOOKS.md, "JavaScript
// hooks"). The runtime has the language and `console` and nothing else: no engine bindings, no files, no network, no timers, no way
// to start a program. It has a time limit per call and a memory limit, which is why it needs no trust. Private to fa_ai.
#pragma once

#include <string>
#include <vector>

#include "fa/ai/hooks.h"

namespace fa::ai {

struct JsHookResult {
    bool ok = true;        // the module ran (a module that handles nothing for the event is ok with handled false)
    bool handled = true;   // the module has a function for this event
    bool timedOut = false;
    Json value;            // what the function returned (undefined and null come back as null)
    std::string error;     // not ok: file:line, what is wrong, how to fix it
    std::vector<std::string> logs;  // console.log / warn / error lines
};

// Calls the module's handler for `event` with `input` (the same JSON a program gets on stdin). `moduleRel` is project-relative and
// must pass hook_module_problem().
JsHookResult run_js_hook(const std::string& projectDir, const std::string& moduleRel, HookEvent event, const Json& input,
                         double timeoutSeconds);

}  // namespace fa::ai
