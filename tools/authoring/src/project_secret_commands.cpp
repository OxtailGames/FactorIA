// project.create_storage_secret: writes the random secret that storage.set(key, value, {encrypt: true}) derives its keys from
// into factoria.json ("storage": {"encryptionSecret"}). It lives here, not in the runtime, because it writes a project file:
// the player of an exported game never creates a secret (the one packed with the game is the one its saves were written with),
// and a game script cannot call it. The secret is never part of a result, a log line or an error message.
#include "authoring_internal.h"
#include "fa/core/crypto.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

std::string random_secret() {
    crypto::Bytes bytes(crypto::kKeySize);
    auto r = crypto::random_bytes(bytes);
    if (!r.ok())
        throw CommandError("internal", "the operating system's random source failed: " + r.error().message,
                           "Nothing was written. Try again; if it keeps failing the system cannot make secure keys.");
    static const char digits[] = "0123456789abcdef";
    std::string out;
    for (std::uint8_t b : bytes) {
        out.push_back(digits[b >> 4]);
        out.push_back(digits[b & 15]);
    }
    crypto::secure_zero(bytes.data(), bytes.size());
    return out;
}

}  // namespace

void register_project_secret_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"project.create_storage_secret",
         "Create the random secret that makes storage.set(..., {encrypt: true}) work, in factoria.json.",
         "Writes \"storage\": {\"encryptionSecret\": <64 random hex characters>} into factoria.json, once. Save "
         "encryption "
         "(storage.set(key, value, {encrypt: true}), the Slots kit's `encrypt` option) derives one key per storage key "
         "from "
         "it, so run this before the game's first encrypted save and keep the secret for the life of the game: saves "
         "written "
         "with another secret cannot be opened (they are set aside as damaged files). A project that already has one "
         "is left "
         "alone (`created: false`) unless `replace` is true, which makes every encrypted save written so far "
         "unreadable. The "
         "secret is never returned or logged; it ships inside the exported game, so encryption is tamper-evidence, not "
         "secrecy from a determined player (docs/scripting/SCRIPTING_UI_SCENES.md, \"Encrypted saves\"). Commit "
         "factoria.json. "
         "Result: {created, replaced, file}. Example: project.create_storage_secret {}",
         parse_schema(R"({"type":"object","properties":{
               "replace":{"type":"boolean","default":false,"description":"Make a new secret even when the project has one. Every save written with {encrypt: true} so far stops opening: use it only when the secret leaked and the saves can be lost."}}})"),
         false, "project"},
        [&I](const Json& a) {
            const bool replace = a.value("replace", false);
            auto text = fs::read_text("factoria.json");
            if (!text.ok())
                throw CommandError(
                    "not_found", "cannot read factoria.json: " + text.error().message,
                    "Run the command from a project folder (or pass --project <folder> to factoria call).");
            auto parsed = parse_json(text.value(), "factoria.json");
            if (!parsed.ok() || !parsed.value().is_object())
                throw CommandError("invalid_project",
                                   "factoria.json is not a JSON object: " +
                                       (parsed.ok() ? std::string("it is not an object") : parsed.error().message),
                                   "Fix factoria.json first; nothing was written.");
            Json project = parsed.value();
            const bool had = project.contains("storage") && project["storage"].is_object() &&
                             project["storage"].contains("encryptionSecret") &&
                             project["storage"]["encryptionSecret"].is_string() &&
                             !project["storage"]["encryptionSecret"].get<std::string>().empty();
            if (had && !replace)
                return Json::object({{"created", false}, {"replaced", false}, {"file", "factoria.json"}});
            if (project.contains("storage") && !project["storage"].is_object())
                throw CommandError("invalid_project", "factoria.json: \"storage\" is not an object",
                                   "Make it {} (or delete it) and run the command again; nothing was written.");
            const std::string secret = random_secret();
            if (!project.contains("storage")) project["storage"] = Json::object();
            project["storage"]["encryptionSecret"] = secret;
            auto written = fs::write_text("factoria.json", dump_json(project));
            if (!written.ok())
                throw CommandError(
                    "write_failed", "cannot write factoria.json: " + written.error().message,
                    "Nothing was changed. Check that the file is not read-only or open in another program.");
            // The running engine (the editor, `factoria run`) uses the new secret at once.
            Json& live = I.project.raw;
            if (!live.is_object()) live = Json::object();
            if (!live.contains("storage") || !live["storage"].is_object()) live["storage"] = Json::object();
            live["storage"]["encryptionSecret"] = secret;
            return Json::object({{"created", true}, {"replaced", had}, {"file", "factoria.json"}});
        });
    declare_command_capabilities(I.commands, {{"project.create_storage_secret", capability_sets::edits_project()}});
}

}  // namespace fa
