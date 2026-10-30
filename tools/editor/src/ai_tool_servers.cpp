// The "External tools" tab of the AI settings window: the tool servers (MCP) the user lets the AI use, such as Scenario or a
// program of their own. Save writes only "mcpServers" into the user's ai.json (ai::save_tool_servers: every other key of the
// file stays) and reloads it. docs/EDITOR.md ("AI settings"), docs/AI_PROVIDERS.md ("External tools (MCP servers)").
#include <algorithm>
#include <cfloat>

#include "editor_internal.h"
#include "fa/ai/assets.h"
#include "fa/ai/mcp_client.h"
#include "fa/core/strings.h"

namespace fa::editor {

namespace {

std::vector<std::string> lines_of(const std::string& text) {
    std::vector<std::string> out;
    std::string line;
    for (char c : text) {
        if (c == '\n') {
            out.push_back(line);
            line.clear();
        } else if (c != '\r') {
            line += c;
        }
    }
    out.push_back(line);
    return out;
}

bool is_default_roles(const std::vector<std::string>& roles) {
    std::set<std::string> have(roles.begin(), roles.end());
    std::set<std::string> def;
    for (const char* r : ai::kDefaultToolServerRoles) def.insert(r);
    return have == def;
}

// A name for a pasted single server: "mcp.scenario.com" -> "scenario", "npx" -> "npx".
std::string derive_name(const Json& entry) {
    std::string base;
    const std::string url = entry.value("url", std::string());
    if (!url.empty()) {
        std::string host = ai::asset_site_host(url);
        std::vector<std::string> labels = fa::split(host, '.');
        if (labels.size() > 2 && (labels[0] == "mcp" || labels[0] == "www" || labels[0] == "api")) labels.erase(labels.begin());
        base = labels.empty() ? std::string() : labels[0];
    } else {
        base = entry.value("command", std::string());
        if (const auto slash = base.find_last_of("/\\"); slash != std::string::npos) base = base.substr(slash + 1);
    }
    std::string out;
    for (char c : base) {
        if (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-') out += c;
    }
    return out;
}

std::string env_key_hint(const std::string& name) {
    std::string out;
    for (char c : name) out += std::isalnum(static_cast<unsigned char>(c)) ? static_cast<char>(std::toupper(static_cast<unsigned char>(c))) : '_';
    return (out.empty() ? std::string("MY_SERVER") : out) + "_API_KEY";
}

}  // namespace

void Editor::ai_tool_form_open(int index) {
    auto& t = aiSettings_.tools;
    t.editError.clear();
    t.showPaste = false;
    t.adding = index < 0 || index >= static_cast<int>(t.servers.size());
    t.editing = t.adding ? static_cast<int>(t.servers.size()) : index;
    t.edit = t.adding ? ai::ToolServer{} : t.servers[static_cast<std::size_t>(index)];
    if (t.adding) t.edit.type = "http";
    if (t.edit.roles.empty()) {
        for (const char* r : ai::kDefaultToolServerRoles) t.edit.roles.push_back(r);
    }
    t.editHeaders.clear();
    for (const auto& [k, v] : t.edit.headers) t.editHeaders += k + ": " + v + "\n";
    if (!t.editHeaders.empty()) t.editHeaders.pop_back();
    t.editArgs = ai::join_args(t.edit.args);
    t.editEnv.clear();
    for (const auto& [k, v] : t.edit.env) t.editEnv += k + "=" + v + "\n";
    if (!t.editEnv.empty()) t.editEnv.pop_back();
}

Result<ai::ToolServer> Editor::ai_tool_form_build() const {
    const auto& t = aiSettings_.tools;
    ai::ToolServer s = t.edit;
    s.name = std::string(trim(s.name));
    s.url = std::string(trim(s.url));
    s.command = std::string(trim(s.command));
    s.apiKeyEnv = std::string(trim(s.apiKeyEnv));
    s.apiKey = std::string(trim(s.apiKey));
    s.note = std::string(trim(s.note));
    if (const std::string problem = ai::tool_server_name_problem(s.name); !problem.empty()) {
        return make_error("The name '" + s.name + "' cannot be used: " + problem,
                          "The name is what the AI sees; use letters, digits, '_' or '-' (for example scenario).");
    }
    for (std::size_t i = 0; i < t.servers.size(); ++i) {
        if (static_cast<int>(i) != t.editing && t.servers[i].name == s.name) {
            return make_error("There is already a server named '" + s.name + "'", "Pick another name, or edit that one.");
        }
    }
    s.type = s.is_stdio() ? "stdio" : "http";
    s.headers.clear();
    s.args.clear();
    s.env.clear();
    if (s.is_stdio()) {
        s.url.clear();
        s.args = ai::split_args(t.editArgs);
        std::size_t n = 0;
        for (const std::string& raw : lines_of(t.editEnv)) {
            ++n;
            const std::string line(trim(raw));
            if (line.empty()) continue;
            const auto eq = line.find('=');
            if (eq == std::string::npos || eq == 0) {
                return make_error("Environment line " + std::to_string(n) + " ('" + line + "') is not NAME=value",
                                  "Write one variable per line, for example SCENARIO_TOKEN=${SCENARIO_TOKEN}.");
            }
            s.env[std::string(trim(line.substr(0, eq)))] = std::string(trim(line.substr(eq + 1)));
        }
    } else {
        s.command.clear();
        std::size_t n = 0;
        for (const std::string& raw : lines_of(t.editHeaders)) {
            ++n;
            const std::string line(trim(raw));
            if (line.empty()) continue;
            const auto colon = line.find(':');
            if (colon == std::string::npos || colon == 0) {
                return make_error("Header line " + std::to_string(n) + " ('" + line.substr(0, 30) + "') is not Name: value",
                                  "Write one header per line, for example Authorization: Basic {key}.");
            }
            s.headers.emplace_back(std::string(trim(line.substr(0, colon))), std::string(trim(line.substr(colon + 1))));
        }
    }
    if (is_default_roles(s.roles)) s.roles.clear();
    // The same checks ai.json gets when it loads (url shape, header names, roles...): their messages say how to fix it.
    auto parsed = ai::parse_tool_server(ai::tool_server_to_json(s, false), s.name, "the server '" + s.name + "'");
    if (!parsed) return parsed.error();
    return *parsed;
}

void Editor::ai_tool_test(const ai::ToolServer& server) {
    if (aiToolTestRunning_.load()) return;
    if (aiToolTestThread_.joinable()) aiToolTestThread_.join();
    auto tests = aiSettings_.tools.tests;
    {
        std::lock_guard<std::mutex> lock(tests->mu);
        tests->text[server.name] = "Testing...";
        tests->ok.erase(server.name);
    }
    aiToolTestRunning_ = true;
    aiToolTestThread_ = std::thread([this, tests, server, transport = aiToolTransport_] {
        std::string text;
        bool ok = false;
        auto resolved = ai::resolve_tool_server(server, ai::system_env());
        if (!resolved) {
            text = resolved.error().message + (resolved.error().hint.empty() ? "" : " " + resolved.error().hint);
        } else {
            ai::McpOptions mo;
            mo.transport = transport;
            mo.cancel = &tests->cancel;
            mo.connectTimeoutSeconds = 20;
            auto client = ai::McpClient::connect(*resolved, mo);
            if (!client) {
                text = client.error().message + (client.error().hint.empty() ? "" : " " + client.error().hint);
            } else {
                ok = true;
                const auto& tools = (*client)->tools();
                text = "Connected" + ((*client)->server_description().empty() ? std::string() : " to " + (*client)->server_description()) +
                       ": " + std::to_string(tools.size()) + (tools.size() == 1 ? " tool" : " tools");
                for (std::size_t i = 0; i < tools.size() && i < 12; ++i) text += (i == 0 ? " (" : ", ") + tools[i].name;
                if (!tools.empty()) text += tools.size() > 12 ? ", ...)" : ")";
            }
        }
        {
            std::lock_guard<std::mutex> lock(tests->mu);
            tests->text[server.name] = text;
            tests->ok[server.name] = ok;
        }
        aiToolTestRunning_ = false;
    });
}

void Editor::draw_ai_tools_tab(const ai::AiConfig& cfg, bool configReadable) {
    AiSettingsDraft& d = aiSettings_;
    auto& t = d.tools;
    const float em = ImGui::GetFontSize();
    const auto wrapped = [](const ImVec4& color, const std::string& text) {
        ImGui::PushStyleColor(ImGuiCol_Text, color);
        ImGui::TextWrapped("%s", text.c_str());
        ImGui::PopStyleColor();
    };

    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("Saved in %s, your own file outside any project. Only the tool servers are rewritten: your providers, roles and limits stay.",
                       d.path.c_str());
    ImGui::PopStyleColor();

    const float footerH = ImGui::GetFrameHeight() + ImGui::GetStyle().ItemSpacing.y * 3.0f + ImGui::GetTextLineHeightWithSpacing() * 2.0f;
    ImGui::BeginChild("##aitoolsbody", ImVec2(0, -footerH));
    ImGui::TextWrapped("Services and programs the AI may use when they help the game (an image generator such as Scenario, a tool of your own). "
                       "They are MCP servers, the same kind Claude Code uses. Claude Code and Codex connect to them themselves; the other providers "
                       "go through FactorIA. A tool can cost credits on the service's side: the AI is told to try one call before a batch.");

    AiSettingsDraft::ToolTests& tests = *t.tests;
    ai::AiConfig live;
    live.toolServers = t.servers;
    const std::vector<ai::ToolServerStatus> statuses = ai::tool_server_statuses(live);
    const bool testing = aiToolTestRunning_.load();

    ImGui::SeparatorText("Servers");
    if (t.servers.empty()) ImGui::TextDisabled("None yet. Add a server, or paste the JSON a service's documentation gives for Claude Code.");
    int remove = -1;
    int edit = -1;
    if (!t.servers.empty() && ImGui::BeginTable("##toolservers", 6, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings)) {
        ImGui::TableSetupColumn("On", ImGuiTableColumnFlags_WidthFixed, em * 2.5f);
        ImGui::TableSetupColumn("Name", ImGuiTableColumnFlags_WidthFixed, em * 8.0f);
        ImGui::TableSetupColumn("Where", ImGuiTableColumnFlags_WidthFixed, em * 15.0f);
        ImGui::TableSetupColumn("Roles", ImGuiTableColumnFlags_WidthFixed, em * 5.5f);
        ImGui::TableSetupColumn("Status", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("##actions", ImGuiTableColumnFlags_WidthFixed, em * 13.5f);
        ImGui::TableHeadersRow();
        for (std::size_t i = 0; i < t.servers.size(); ++i) {
            ai::ToolServer& s = t.servers[i];
            const ai::ToolServerStatus& st = statuses[i];
            ImGui::PushID(static_cast<int>(i));
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::Checkbox("##enabled", &s.enabled);
            at_track("aiset:tools:enabled:" + s.name);
            ImGui::SetItemTooltip("Off: the AI does not get this server's tools; its settings stay.");
            ImGui::TableNextColumn();
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted(s.name.c_str());
            ImGui::TableNextColumn();
            ImGui::TextDisabled("%s", s.is_stdio() ? "program" : "web");
            ImGui::SameLine();
            ImGui::TextUnformatted(st.target.c_str());
            ImGui::SetItemTooltip("%s", st.target.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(s.roles.empty() ? "default" : (std::to_string(s.roles.size()) + " roles").c_str());
            ImGui::SetItemTooltip("%s", ("Who gets it: " + fa::join(st.roles, ", ") +
                                         (s.roles.empty() ? ". The review roles (artCritic, reviewer) only get a server that lists them." : "."))
                                            .c_str());
            ImGui::TableNextColumn();
            std::string shown;
            bool good = false;
            {
                std::lock_guard<std::mutex> lock(tests.mu);
                const auto txt = tests.text.find(s.name);
                if (txt != tests.text.end()) {
                    shown = txt->second;
                    const auto ok = tests.ok.find(s.name);
                    good = ok != tests.ok.end() && ok->second;
                }
            }
            if (!shown.empty()) {
                wrapped(good ? kStatusReady : (shown == "Testing..." ? kStatusWarn : kStatusFailed), shown);
                ImGui::SetItemTooltip("%s", shown.c_str());
            } else if (!s.enabled) {
                ImGui::TextDisabled("Off");
            } else if (!st.problem.empty()) {
                wrapped(kStatusWarn, st.problem);
                ImGui::SetItemTooltip("%s", st.problem.c_str());
            } else {
                wrapped(kStatusReady, "Ready" + (st.keySource.empty() ? std::string() : " (key: " + st.keySource + ")"));
            }
            ImGui::TableNextColumn();
            ImGui::BeginDisabled(testing);
            if (ImGui::SmallButton("Test")) ai_tool_test(s);
            ImGui::EndDisabled();
            at_track("aiset:tools:test:" + s.name, !testing);
            ImGui::SetItemTooltip("Connects and lists the server's tools. No tool is called, nothing is spent.");
            ImGui::SameLine();
            if (ImGui::SmallButton("Edit")) edit = static_cast<int>(i);
            at_track("aiset:tools:edit:" + s.name);
            ImGui::SameLine();
            if (ImGui::SmallButton("Remove")) remove = static_cast<int>(i);
            at_track("aiset:tools:remove:" + s.name);
            ImGui::PopID();
        }
        ImGui::EndTable();
    }
    if (remove >= 0) {
        t.servers.erase(t.servers.begin() + remove);
        t.editing = -1;
    }
    if (edit >= 0) ai_tool_form_open(edit);

    if (ImGui::Button("Add server")) ai_tool_form_open(-1);
    at_track("aiset:tools:add");
    ImGui::SetItemTooltip("Add a web service (an address and, if it needs one, a key) or a program on this computer.");
    ImGui::SameLine();
    if (ImGui::Button("Paste JSON...")) {
        t.showPaste = !t.showPaste;
        t.editing = -1;
        t.pasteMessage.clear();
    }
    at_track("aiset:tools:paste");
    ImGui::SetItemTooltip("Import what a service's documentation gives for Claude Code: {\"mcpServers\": {...}} or a single server.");

    // ------------------------------------------------------------------------------------------------ paste
    if (t.showPaste) {
        ImGui::SeparatorText("Paste JSON");
        ImGui::InputTextMultiline("##paste", &t.pasteText, ImVec2(-FLT_MIN, em * 8.0f));
        at_track("aiset:tools:paste-text");
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Name");
        ImGui::SameLine(em * 5.0f);
        ImGui::SetNextItemWidth(em * 14.0f);
        ImGui::InputTextWithHint("##pastename", "only for a single server", &t.pasteName);
        at_track("aiset:tools:paste-name");
        ImGui::SetItemTooltip("A single server object has no name of its own: this is it. Left empty, one is made from its address or program.");
        ImGui::SameLine();
        if (ImGui::Button("Import")) {
            t.pasteFailed = true;
            Json j = Json::parse(t.pasteText, nullptr, false);
            if (j.is_discarded() || !j.is_object()) {
                t.pasteMessage = "That is not a JSON object. Paste {\"mcpServers\": {\"name\": {...}}} or one server such as {\"url\": \"https://...\"}.";
            } else {
                std::vector<std::string> ignored;
                Result<std::vector<ai::ToolServer>> got = make_error("nothing to import", "");
                if (!j.contains("mcpServers") && (j.contains("url") || j.contains("command"))) {
                    std::string name = std::string(trim(t.pasteName));
                    if (name.empty()) name = derive_name(j);
                    if (const std::string problem = ai::tool_server_name_problem(name); !problem.empty()) {
                        got = make_error("A single server needs a name: " + problem, "Type one in Name (for example scenario).");
                    } else if (auto one = ai::parse_tool_server(j, name, "the pasted server", &ignored)) {
                        got = std::vector<ai::ToolServer>{*one};
                    } else {
                        got = one.error();
                    }
                } else {
                    got = ai::parse_tool_servers(j, "the pasted JSON", &ignored);
                }
                if (!got) {
                    t.pasteMessage = got.error().to_string();
                } else if (got->empty()) {
                    t.pasteMessage = "No server in that JSON.";
                } else {
                    std::string names;
                    for (ai::ToolServer& s : *got) {
                        auto it = std::ranges::find(t.servers, s.name, &ai::ToolServer::name);
                        if (it != t.servers.end()) *it = s;
                        else t.servers.push_back(s);
                        names += (names.empty() ? "" : ", ") + s.name;
                    }
                    t.pasteMessage = "Imported " + names + ". Press Save to keep " + std::string(got->size() == 1 ? "it" : "them") + ".";
                    if (!ignored.empty()) t.pasteMessage += " Not used by FactorIA: " + fa::join(ignored, ", ") + ".";
                    t.pasteFailed = false;
                    t.pasteText.clear();
                }
            }
        }
        at_track("aiset:tools:import");
        if (!t.pasteMessage.empty()) {
            ImGui::PushStyleColor(ImGuiCol_Text, t.pasteFailed ? kStatusFailed : kStatusReady);
            ImGui::TextWrapped("%s", t.pasteMessage.c_str());
            ImGui::PopStyleColor();
        }
    }

    // ------------------------------------------------------------------------------------------------ the form
    if (t.editing >= 0) {
        ai::ToolServer& e = t.edit;
        ImGui::SeparatorText(t.adding ? "New server" : ("Edit " + e.name).c_str());
        const float labelW = em * 9.0f;
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Name");
        ImGui::SameLine(labelW);
        ImGui::SetNextItemWidth(em * 16.0f);
        ImGui::InputTextWithHint("##name", "scenario", &e.name);
        at_track("aiset:tools:name");
        ImGui::SetItemTooltip("What the AI calls it: letters, digits, '_' and '-'. Its tools show as <name>__<tool>.");
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Kind");
        ImGui::SameLine(labelW);
        if (ImGui::RadioButton("Web service (HTTP)", !e.is_stdio())) e.type = "http";
        at_track("aiset:tools:type-http");
        ImGui::SameLine();
        if (ImGui::RadioButton("Program on this computer", e.is_stdio())) e.type = "stdio";
        at_track("aiset:tools:type-program");
        if (!e.is_stdio()) {
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("Address");
            ImGui::SameLine(labelW);
            ImGui::SetNextItemWidth(-FLT_MIN);
            ImGui::InputTextWithHint("##url", "https://mcp.scenario.com/mcp", &e.url);
            at_track("aiset:tools:url");
            ImGui::SetItemTooltip("The MCP address of the service (Streamable HTTP). Use https unless it is a server on this computer.");
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("Headers");
            ImGui::SameLine(labelW);
            ImGui::InputTextMultiline("##headers", &t.editHeaders, ImVec2(-FLT_MIN, em * 3.6f));
            at_track("aiset:tools:headers");
            ImGui::SetItemTooltip("One per line, as Name: value. {key} is replaced by the key below and ${NAME} by an environment variable.\n"
                                  "Scenario: Authorization: Basic {key}   (the key is KEY:SECRET encoded in base64)");
        } else {
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("Program");
            ImGui::SameLine(labelW);
            ImGui::SetNextItemWidth(-FLT_MIN);
            ImGui::InputTextWithHint("##command", "npx", &e.command);
            at_track("aiset:tools:command");
            ImGui::SetItemTooltip("A name on the PATH or a full path. Leave out the arguments.");
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("Arguments");
            ImGui::SameLine(labelW);
            ImGui::SetNextItemWidth(-FLT_MIN);
            ImGui::InputTextWithHint("##args", "-y @scope/some-mcp-server --api-key {key}", &t.editArgs);
            at_track("aiset:tools:args");
            ImGui::SetItemTooltip("Separated by spaces; put \"double quotes\" around one that has spaces. {key} and ${NAME} work here too.");
            ImGui::AlignTextToFramePadding();
            ImGui::TextUnformatted("Environment");
            ImGui::SameLine(labelW);
            ImGui::InputTextMultiline("##env", &t.editEnv, ImVec2(-FLT_MIN, em * 3.6f));
            at_track("aiset:tools:env");
            ImGui::SetItemTooltip("One per line, as NAME=value, given to the program. {key} and ${NAME} work here too.");
        }
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Key");
        ImGui::SameLine(labelW);
        ImGui::SetNextItemWidth(em * 22.0f);
        ImGui::InputTextWithHint("##key", "paste the key (stored in ai.json)", &e.apiKey, ImGuiInputTextFlags_Password);
        at_track("aiset:tools:key");
        const std::string envName = e.apiKeyEnv.empty() ? env_key_hint(e.name) : e.apiKeyEnv;
        ImGui::SetItemTooltip("Replaces {key} above. Stored as mcpServers.%s.apiKey in %s: your own file outside any project, readable only by you.\n"
                              "An environment variable is safer: leave this empty and set %s, FactorIA reads it.",
                              e.name.empty() ? "<name>" : e.name.c_str(), d.path.c_str(), envName.c_str());
        ImGui::SameLine();
        ImGui::SetNextItemWidth(em * 14.0f);
        ImGui::InputTextWithHint("##keyenv", env_key_hint(e.name).c_str(), &e.apiKeyEnv);
        at_track("aiset:tools:keyenv");
        ImGui::SetItemTooltip("Or: the environment variable that holds the key (used before the key typed here). An environment variable keeps the\n"
                              "key out of every file.");
        ImGui::TextDisabled("Better than typing the key: set the environment variable %s and leave the box empty.", envName.c_str());
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Note");
        ImGui::SameLine(labelW);
        ImGui::InputTextMultiline("##note", &e.note, ImVec2(-FLT_MIN, em * 3.6f));
        at_track("aiset:tools:note");
        ImGui::SetItemTooltip("What this server is good for. The AI reads it, e.g. \"Makes pixel-art sprites; costs credits per image\".");
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Who may use it");
        ImGui::SameLine(labelW);
        for (const char* role : ai::kAllRoles) {
            const bool review = std::string_view(role) == ai::kRoleArtCritic || std::string_view(role) == ai::kRoleReviewer;
            const auto it = std::ranges::find(e.roles, std::string(role));
            bool on = it != e.roles.end();
            if (ImGui::Checkbox(role, &on)) {
                if (on) e.roles.push_back(role);
                else e.roles.erase(it);
            }
            at_track(std::string("aiset:tools:role:") + role);
            if (review) ImGui::SetItemTooltip("Reviewers only look at the game; a tool that makes things is not for them.");
            ImGui::SameLine();
        }
        ImGui::NewLine();
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("Wait per call");
        ImGui::SameLine(labelW);
        ImGui::SetNextItemWidth(em * 7.0f);
        ImGui::InputDouble("##timeout", &e.timeoutSeconds, 0, 0, "%.0f s");
        at_track("aiset:tools:timeout");
        ImGui::SetItemTooltip("How long one tool call may take before the AI gives up (generating an image takes a while).");
        if (e.timeoutSeconds < 1) e.timeoutSeconds = 1;

        if (ImGui::Button("Apply")) {
            auto built = ai_tool_form_build();
            if (!built) {
                t.editError = built.error().to_string();
            } else {
                t.editError.clear();
                {
                    std::lock_guard<std::mutex> lock(tests.mu);
                    tests.text.erase(built->name);
                    tests.ok.erase(built->name);
                }
                if (t.adding) t.servers.push_back(*built);
                else t.servers[static_cast<std::size_t>(t.editing)] = *built;
                t.editing = -1;
            }
        }
        at_track("aiset:tools:apply");
        ImGui::SetItemTooltip("Put the server in the list. Save writes the list to ai.json.");
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) t.editing = -1;
        at_track("aiset:tools:cancel");
        ImGui::SameLine();
        ImGui::BeginDisabled(testing);
        if (ImGui::Button("Test these settings")) {
            auto built = ai_tool_form_build();
            if (!built) t.editError = built.error().to_string();
            else {
                t.editError.clear();
                ai_tool_test(*built);
            }
        }
        ImGui::EndDisabled();
        at_track("aiset:tools:form-test", !testing);
        ImGui::SetItemTooltip("Connects with what is typed here and lists the tools. No tool is called, nothing is spent.");
        if (t.editing >= 0) {
            std::string result;
            bool good = false;
            {
                std::lock_guard<std::mutex> lock(tests.mu);
                const std::string key = std::string(trim(e.name));
                if (const auto txt = tests.text.find(key); txt != tests.text.end()) {
                    result = txt->second;
                    const auto ok = tests.ok.find(key);
                    good = ok != tests.ok.end() && ok->second;
                }
            }
            if (!result.empty()) ImGui::TextColored(good ? kStatusReady : (result == "Testing..." ? kStatusWarn : kStatusFailed), "%s", result.c_str());
        }
        if (!t.editError.empty()) {
            ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
            ImGui::TextWrapped("%s", t.editError.c_str());
            ImGui::PopStyleColor();
        }
    }
    ImGui::EndChild();

    // ------------------------------------------------------------------------------------------------ footer
    const auto dump = [](const std::vector<ai::ToolServer>& v) {
        Json arr = Json::array();
        for (const auto& s : v) arr.push_back(ai::tool_server_to_json(s, false));
        return arr.dump();
    };
    const bool dirty = dump(t.servers) != dump(cfg.toolServers);
    if (!t.saveError.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("%s", t.saveError.c_str());
        ImGui::PopStyleColor();
    } else if (dirty) {
        ImGui::TextColored(kStatusWarn, "Unsaved changes");
    } else {
        ImGui::TextDisabled("Saved. The next message to the AI uses these servers.");
    }
    ImGui::BeginDisabled(!configReadable);
    if (ImGui::Button("Save")) {
        t.saveError.clear();
        if (auto saved = ai::save_tool_servers(t.servers, d.path); !saved) {
            t.saveError = saved.error().to_string();
        } else {
            auto loaded = ai::load_config(d.path);
            {
                std::lock_guard<std::mutex> lock(aiMu_);
                if (loaded) aiConfig_ = *loaded;
                aiConfigError_ = loaded ? std::string() : loaded.error().to_string();
            }
            if (loaded) {
                ai_settings_load(*loaded, true, false);  // the Assets tab keeps what it had typed
                notify("Tool servers saved. The next message to the AI uses them.");
            } else {
                t.saveError = "Saved, but ai.json no longer loads: " + loaded.error().to_string();
            }
            if (!aiDetecting_.load()) ai_refresh_providers();
        }
    }
    ImGui::EndDisabled();
    at_track("aiset:tools:save", configReadable);
    ImGui::SameLine();
    if (ImGui::Button("Close")) {
        showAiSettings_ = false;
        ai_settings_discard();
    }
    at_track("aiset:tools:close");
}

}  // namespace fa::editor
