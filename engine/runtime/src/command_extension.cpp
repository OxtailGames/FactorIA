#include "fa/runtime/command_extension.h"

#include <functional>
#include <mutex>
#include <string>
#include <utility>

#include "fa/core/command.h"
#include "fa/core/log.h"
#include "fa/runtime/engine.h"

namespace fa {

namespace {

struct Extension {
    std::string name;
    CommandExtensionFn fn;
};

std::mutex& list_mutex() {
    static std::mutex m;
    return m;
}

std::vector<Extension>& extensions() {
    static std::vector<Extension> list;
    return list;
}

}  // namespace

bool register_command_extension(std::string_view name, CommandExtensionFn fn) {
    if (!fn) return false;
    std::lock_guard<std::mutex> lock(list_mutex());
    for (const Extension& e : extensions())
        if (e.name == name) return false;
    extensions().push_back({std::string(name), std::move(fn)});
    return true;
}

std::vector<std::string> command_extension_names() {
    std::lock_guard<std::mutex> lock(list_mutex());
    std::vector<std::string> out;
    for (const Extension& e : extensions()) out.push_back(e.name);
    return out;
}

void run_command_extensions(Engine& engine) {
    // Copy the functions out of the lock: an extension may register another one, or create an Engine.
    std::vector<Extension> fns;
    {
        std::lock_guard<std::mutex> lock(list_mutex());
        fns = extensions();
    }
    for (const Extension& ext : fns) {
        // CommandRegistry::add replaces a name silently; an extension that does it hides a command, so say so.
        const std::size_t replacedBefore = engine.commands().replaced_commands().size();
        ext.fn(engine);
        const std::vector<std::string>& replaced = engine.commands().replaced_commands();
        for (std::size_t i = replacedBefore; i < replaced.size(); ++i)
            FA_WARN("command",
                    "command extension '{}' replaced the command '{}' (names must be unique; the extension's "
                    "version wins)",
                    ext.name, replaced[i]);
    }
}

}  // namespace fa
