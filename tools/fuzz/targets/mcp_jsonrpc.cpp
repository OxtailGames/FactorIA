// McpServer::handle_message: the JSON-RPC front of `factoria mcp` and of the editor's endpoint. Each line of the input is one
// message of one session (initialize, tools/list, tools/call, resources, prompts, batches, cancellations), so the fuzzer can
// build a handshake and then a call.
//
// Nothing here can write a file, start a program or open a socket: the server runs with the capabilities of
// `factoria mcp --read-only` ({read, state}; core/capability.h) over the tooling commands and two test commands. The project
// is an empty temporary folder, and, as in `factoria mcp --read-only`, only the commands of ai::is_read_only_tool are offered.
// A command that asks for more than {read, state} (every command that writes, starts a process
// or uses the network declares it) is refused by the dispatcher before it runs.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>

#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/ai/session.h"
#include "fa/mcp/server.h"
#include "fa/tooling/tooling.h"
#include "fuzz_support.h"

namespace {

struct Setup {
    std::string projectDir = fa::fs::path_to_utf8(fa::fuzz::empty_project());
    fa::CommandRegistry registry;
    std::unique_ptr<fa::SimpleMcpHost> host;

    Setup() {
        {
            fa::CommandInfo i;
            i.name = "test.echo_value";
            i.summary = "Echo the value.";
            i.description = "Example: {\"value\": 3}";
            i.inputSchema = fa::Json::parse(R"({"type":"object","properties":{"value":{"type":"integer"}},"required":["value"]})");
            registry.add(i, [](const fa::Json& a) { return fa::Json::object({{"echo", a["value"]}}); });
        }
        {
            fa::CommandInfo i;
            i.name = "test.fail";
            i.summary = "Always fails.";
            registry.add(i, [](const fa::Json&) -> fa::Json {
                throw fa::CommandError("not_found", "Entity 'x' not found.", "Use scene.list_entities.");
            });
        }
        fa::register_tooling_commands(registry, projectDir);
        host = std::make_unique<fa::SimpleMcpHost>(registry, projectDir);
    }
};

}  // namespace

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    static Setup setup;
    fa::McpServer server(*setup.host);
    server.set_capabilities(fa::capability_sets::mcp_read_only());
    // As `factoria mcp --read-only` does (cmd_mcp.cpp): only the commands a read-only role may use are offered and run.
    server.set_command_filter([](const fa::CommandInfo& info) { return fa::ai::is_read_only_tool(info); });
    server.set_result_cap(64 * 1024);

    std::string_view rest = fa::fuzz::as_text(data, size);
    for (int messages = 0; !rest.empty() && messages < 16; ++messages) {
        const std::size_t eol = rest.find('\n');
        const std::string_view line = rest.substr(0, eol);
        rest = eol == std::string_view::npos ? std::string_view() : rest.substr(eol + 1);
        if (line.empty()) continue;
        (void)fa::McpServer::is_cancel_notification(line);
        if (auto parsed = fa::parse_json(line)) (void)fa::McpServer::runnable_request_id(parsed.value());
        (void)server.handle_message(line);
    }
    (void)server.drain_outgoing();
    return 0;
}
