// feedback sharing|share|signin|signout: the commands a PERSON types to decide and run what is sent to the engine developer
// (fa/tooling/feedback_share.h). They have no command-registry twin on purpose: an AI cannot change the mode.
#include <filesystem>
#include <iostream>

#include "common.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/feedback_share.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

void print_status(Context& ctx, const std::string& projectDir) {
    const Json s = share_status(share_env(), projectDir);
    if (ctx.args.has("json")) {
        print_json(ctx.out, s);
        return;
    }
    ctx.out << "Sharing feedback with the engine developer. Your default: " << s.value("default", std::string("unset"))
            << "\n";
    if (s.contains("project")) {
        const Json& p = s["project"];
        ctx.out << "  This project (" << p.value("name", std::string()) << ", " << p.value("dir", std::string())
                << "): " << s.value("mode", std::string("unset")) << " ("
                << (p.value("source", std::string()) == "project" ? "its own choice" : "follows your default") << ")\n";
    }
    if (!s.value("available", false))
        ctx.out << "  Not available: " << s.value("howToFix", std::string()) << "\n";
    else
        ctx.out << "  Server: " << s.value("endpoint", std::string()) << "\n";
    ctx.out << "  Signed in with GitHub: "
            << (s.value("signedIn", false) ? s.value("login", std::string("yes")) : std::string("no (anonymous)"))
            << "\n";
    const Json& box = s["outbox"];
    ctx.out << "  Outbox: " << box.value("queued", 0) << " queued, " << box.value("waitingForConfirmation", 0)
            << " waiting for your confirmation\n";
    if (box.value("blocked", 0) > 0)
        ctx.out << "    " << box.value("blocked", 0) << " not sent: their project's mode is never (or not set up)\n";
    for (const Json& f : box["failed"])
        ctx.out << "    " << f.value("id", std::string()) << ": " << f.value("error", std::string()) << " (attempt "
                << f.value("attempts", 0) << ", retried in " << f.value("retryInSeconds", 0) << " s)\n";
    if (s.contains("lastSend")) ctx.out << "  Last attempt: " << s["lastSend"].value("message", std::string()) << "\n";
    if (s.contains("warning")) ctx.out << "  Warning: " << s.value("warning", std::string()) << "\n";
    if (s.value("mode", std::string()) == "unset")
        ctx.out << "\nNothing is sent until you choose: factoria feedback sharing always | ask | never\n"
                   "See: factoria docs read engine-feedback\n";
}

// The project a sharing command is about: the folder given (--project, or the positional of `share`) resolved to the folder that
// holds factoria.json, itself or the nearest one above it; without one, the project around the current directory; "" = none.
// A folder that does not exist or is not inside a project is an error (a typo must not fall back to another project).
std::string resolve_share_project(const Context& ctx, std::size_t posIndex) {
    std::string given = ctx.args.pos(posIndex);
    if (given.empty()) given = ctx.args.str("project");
    if (given.empty()) {
        std::error_code ec;
        return find_project_root(fsys::current_path(ec).string());
    }
    const std::string abs = absolute_path(given);
    std::error_code ec;
    if (!fsys::is_directory(abs, ec))
        throw CliError("'" + given + "' is not a folder (looked for " + abs + ").",
                       "Pass the project folder: the one that contains " + std::string(kProjectFileName) +
                           ", for example --project ../my-game, or --project . inside the project.");
    const std::string root = find_project_root(abs);
    if (root.empty())
        throw CliError("'" + abs + "' is not inside a FactorIA project: there is no " + std::string(kProjectFileName) +
                           " in it or in any folder above it.",
                       "Pass --project <folder> with the folder that contains " + std::string(kProjectFileName) +
                           " (a folder inside the project works too), or run the command inside the project. Sharing "
                           "choices belong to projects, so it cannot guess.");
    return root;
}

std::string project_for_share(const Context& ctx) { return resolve_share_project(ctx, 0); }

void print_report(Context& ctx, const QueueResult* queued, const FlushResult* flushed, const Json* preview) {
    if (ctx.args.has("json")) {
        Json j = Json::object();
        if (preview) j["preview"] = *preview;
        if (queued) {
            Json arr = Json::array();
            for (const ShareEntryReport& r : queued->entries) {
                Json e = Json::object({{"id", r.id}, {"status", r.status}});
                if (!r.reason.empty()) e["reason"] = r.reason;
                arr.push_back(std::move(e));
            }
            j["entries"] = std::move(arr);
        }
        if (flushed) {
            j["outcome"] = flushed->outcome;
            j["message"] = flushed->message;
            j["results"] = flushed->results;
            j["sent"] = flushed->sent;
        }
        print_json(ctx.out, j);
        return;
    }
    if (queued)
        for (const ShareEntryReport& r : queued->entries)
            ctx.out << "  " << r.id << ": " << r.status << (r.reason.empty() ? "" : " - " + r.reason) << "\n";
    if (flushed) ctx.out << flushed->message << "\n";
}

}  // namespace

void add_feedback_share_commands(Command& group) {
    Command sharing;
    sharing.name = "sharing";
    sharing.summary = "Choose whether feedback is shared with the engine developer (always, ask, never), for you or "
                      "for one project; without an argument, show the status.";
    sharing.usage = "[always|ask|never|default] [--project DIR] [--clear] [--json]";
    sharing.maxPositional = 1;
    sharing.flags = {
        {"project", "DIR",
         "Set the mode of this project only (use . for the project you are in); `default` or --clear removes the "
         "project's own choice."},
        {"clear", "", "With --project: remove the project's own choice, so it follows your default again."},
        {"json", "", "Machine-readable status."}};
    sharing.details = "Entries of ENGINE_FEEDBACK.json that carry a `share` (a generic copy in engine terms only) can "
                      "be sent to the engine "
                      "developer so that the gaps of every game reach the roadmap. Nothing about your game is sent: no "
                      "names, paths, file names or "
                      "quoted text; `factoria feedback share --preview` shows exactly what would go.\n"
                      "  always  send new shareable entries as they are recorded\n"
                      "  ask     queue them and send only what you confirm (`factoria feedback share`)\n"
                      "  never   send nothing; what waits in the outbox is dropped (entries marked skipped)\n"
                      "Only you can change this: no engine command does. See: factoria docs read engine-feedback\n"
                      "Your mode is the default for every project that has no choice of its own: changing it moves "
                      "only the outbox items of those "
                      "projects. With --project a project can have its own (never for a game under NDA, always for one "
                      "you want to share): it is "
                      "kept in your own feedback-sharing.json, keyed by the project folder's path, never inside the "
                      "project, so a copy of the "
                      "project does not inherit the choice and follows your default; moving the folder drops it back "
                      "to your default. --project takes "
                      "the folder that contains factoria.json (or a folder inside it) and the command prints the "
                      "project it chose. When a project's "
                      "mode changes, its outbox items follow: never drops them, always confirms the ones waiting, ask "
                      "puts the queued ones back to "
                      "waiting for your yes. Without an argument the status shows your default and the effective mode "
                      "of the project you are in, with its source.";
    sharing.examples = {"factoria feedback sharing", "factoria feedback sharing ask", "factoria feedback sharing never",
                        "factoria feedback sharing never --project .",
                        "factoria feedback sharing default --project ../puzzle"};
    sharing.run = [](Context& ctx) {
        const bool perProject = ctx.args.has("project");
        const bool clear = ctx.args.has("clear");
        if (clear && !ctx.args.positional().empty() && ctx.args.pos(0) != "default")
            throw UsageError("--clear cannot be combined with a mode ('" + ctx.args.pos(0) +
                                 "'): --clear removes the project's own choice, a mode sets one.",
                             "Use `factoria feedback sharing --clear --project <dir>` to remove the choice, or "
                             "`factoria feedback sharing " +
                                 ctx.args.pos(0) + " --project <dir>` to set one.");
        const std::string projectDir = resolve_share_project(ctx, 99);  // position 0 is the mode word
        if (ctx.args.positional().empty() && !clear) {
            print_status(ctx, projectDir);
            return 0;
        }
        const std::string word = ctx.args.positional().empty() ? std::string("default") : ctx.args.pos(0);
        if (word == "default" || clear) {
            if (!perProject)
                throw UsageError("`default` and --clear remove a project's own choice: say which project.",
                                 "Add --project <dir> (--project . for the project you are in).");
            if (projectDir.empty()) return report_failure(ctx, "No project folder.", "Pass --project <dir>.");
            auto r = set_project_share_mode(share_env(), projectDir, std::nullopt);
            if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
            if (ctx.args.has("json"))
                print_json(ctx.out, share_status(share_env(), projectDir));
            else {
                const ShareSettings now = load_share_settings(share_env());
                ctx.out << "Project: " << projectDir << "\nThis project follows your default again ('"
                        << share_mode_name(now.mode) << "').\n";
                // Removing the choice is not a yes: what waited for your answer under `ask` keeps waiting, even if your default is `always`.
                const std::size_t waiting = share_waiting(share_env(), feedback_path(projectDir)).size();
                if (waiting > 0 && now.mode == ShareMode::Always)
                    ctx.out << waiting
                            << (waiting == 1 ? " entry of this project waits" : " entries of this project wait")
                            << " for your confirmation (they were queued while this project asked): they are not sent "
                               "until you say yes. "
                               "Run `factoria feedback share` to review and confirm "
                            << (waiting == 1 ? "it" : "them") << ".\n";
            }
            return 0;
        }
        auto mode = parse_share_mode(word);
        if (!mode || *mode == ShareMode::Unset)
            throw UsageError("Unknown sharing mode '" + word + "'.",
                             "Use always, ask or never" + std::string(perProject ? " (or default)" : "") + ". " +
                                 did_you_mean(word, std::vector<std::string>{"always", "ask", "never", "default"}));
        if (perProject) {
            if (projectDir.empty()) return report_failure(ctx, "No project folder.", "Pass --project <dir>.");
            auto r = set_project_share_mode(share_env(), projectDir, *mode);
            if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
            if (ctx.args.has("json")) {
                print_json(ctx.out, share_status(share_env(), projectDir));
                return 0;
            }
            ctx.out << "Project: " << projectDir << "\nSharing for this project is now '" << share_mode_name(*mode)
                    << "' (your default stays '" << share_mode_name(load_share_settings(share_env()).mode) << "').\n";
            if (*mode == ShareMode::Never)
                ctx.out << "Nothing of this project is sent and its outbox items were dropped (a batch that was "
                           "already being uploaded by a running editor finishes).\n";
            if (*mode == ShareMode::Ask)
                ctx.out << "Its items that were queued wait for your yes again: run `factoria feedback share` to "
                           "confirm them.\n";
            ctx.out << "The choice belongs to this folder's path: moving the project drops it back to your default.\n";
            return 0;
        }
        auto r = set_share_mode(share_env(), *mode);
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, share_status(share_env(), projectDir));
            return 0;
        }
        ctx.out << "Your default sharing is now '" << share_mode_name(*mode) << "'.\n";
        if (*mode == ShareMode::Always)
            ctx.out << "New feedback with a `share` is sent as soon as it is recorded. Preview: factoria feedback "
                       "share --preview\n";
        if (*mode == ShareMode::Ask)
            ctx.out
                << "New feedback with a `share` waits for you: run `factoria feedback share` to see it and confirm.\n";
        if (*mode == ShareMode::Never)
            ctx.out << "Nothing is sent and the outbox items of the projects that follow your default were dropped (a "
                       "batch that was already being uploaded by a running editor finishes).\n";
        if (*mode != ShareMode::Never && share_endpoint(share_env(), load_share_settings(share_env())).empty())
            ctx.out << "Note: " << share_unavailable_message() << "\n";
        return 0;
    };

    Command share;
    share.name = "share";
    share.summary =
        "Send the queued feedback to the engine developer now; with --preview, show exactly what would be sent.";
    share.usage = "[project] [--preview | --verdicts] [--yes] [--json]";
    share.maxPositional = 1;
    share.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
                   {"preview", "", "Show what would be sent and what the sanitizer removed; send nothing."},
                   {"verdicts", "",
                    "Send nothing: ask the server what the engine developers decided about the reports already sent."},
                   {"yes", "", "With mode ask: confirm every waiting entry of this project without asking."},
                   {"json", "", "Machine-readable output."}};
    share.details = "Queues the shareable entries of the project (open, with a `share`), then sends the outbox: one "
                    "request of up to 20 entries "
                    "at a time. With mode ask it first shows what waits and asks for your confirmation. Needs the mode "
                    "always or ask "
                    "(`factoria feedback sharing`). With --verdicts nothing is sent: it asks the server which of the "
                    "reports you already sent the engine "
                    "developers rejected (command feedback.verdicts); a rejected entry is closed here with their "
                    "reason, in plain text.";
    share.examples = {"factoria feedback share --verdicts", "factoria feedback share --preview",
                      "factoria feedback share", "factoria feedback share --yes"};
    share.run = [](Context& ctx) {
        const ShareEnv& env = share_env();
        const std::string dir = project_for_share(ctx);
        if (!dir.empty() && !ctx.args.has("json")) ctx.out << "Project: " << dir << "\n";
        // The project's feedback file: "" when the project has none (or there is no project). Without a file nothing is flushed:
        // share_flush reads an empty file as "every project", and this command is only about the project it was run for.
        std::string file;
        if (!dir.empty()) {
            file = feedback_path(dir);
            std::error_code ec;
            if (!fsys::exists(file, ec)) file.clear();
        }
        if (ctx.args.has("verdicts")) {
            if (file.empty())
                return report_failure(ctx, "No ENGINE_FEEDBACK.json to ask about.",
                                      "Run inside a project, or pass its folder.");
            const VerdictResult v = share_sync_verdicts(env, file, 15.0);
            if (ctx.args.has("json")) {
                print_json(ctx.out, Json::object({{"outcome", v.outcome},
                                                  {"message", v.message},
                                                  {"checked", v.checked},
                                                  {"declined", v.declined},
                                                  {"restored", v.restored},
                                                  {"changed", v.changed}}));
            } else {
                ctx.out << v.message << "\n";
                if (!v.changed.empty()) {
                    ctx.out << "Changed:";
                    for (const std::string& id : v.changed) ctx.out << " " << id;
                    ctx.out << "\n";
                }
            }
            return v.outcome == "failed" || v.outcome == "unavailable" ? 1 : 0;
        }
        const EngineNames engine = collect_engine_names();
        if (ctx.args.has("preview")) {
            if (file.empty())
                return report_failure(ctx, "No ENGINE_FEEDBACK.json to preview.",
                                      "Run inside a project, or pass its folder.");
            const Json pv = share_preview(env, file, dir, engine);
            if (ctx.args.has("json")) {
                print_json(ctx.out, pv);
                return 0;
            }
            ctx.out << "Sharing mode: " << pv.value("mode", std::string()) << " (a preview sends nothing)\n";
            if (pv["entries"].empty()) ctx.out << "No entry has a `share` waiting to go.\n";
            for (const Json& e : pv["entries"]) {
                ctx.out << "\n"
                        << e.value("id", std::string())
                        << (e.value("ok", false) ? ": would be sent as\n"
                                                 : ": NOT sent - " + e.value("reason", std::string()) + "\n");
                if (e.contains("sent")) ctx.out << dump_json(e["sent"]) << "\n";
                for (const Json& r : e["removed"])
                    ctx.out << "  removed (" << r.value("kind", std::string()) << ", "
                            << r.value("field", std::string()) << "): " << r.value("text", std::string()) << "\n";
            }
            return 0;
        }
        if (file.empty()) {
            if (dir.empty())
                return report_failure(ctx, "Not inside a FactorIA project, so there is no feedback to share.",
                                      "Run the command inside the project, or pass its folder: factoria feedback share "
                                      "<project>. Nothing was sent.");
            return report_failure(ctx,
                                  "No " + std::string(fsys::path(feedback_path(dir)).filename().string()) + " in " +
                                      dir + ": this project has no feedback to share.",
                                  "Record feedback first (the feedback.report command, or `factoria feedback add`), or "
                                  "pass the folder of the project that has it. Nothing was sent.");
        }
        const ShareSettings settings = load_share_settings(env);
        const ShareMode mode = effective_share_mode(settings, dir);
        if (mode != ShareMode::Always && mode != ShareMode::Ask) {
            // Off for this project: say so, and flush nothing (not even the other projects' items).
            const bool own = std::string(effective_share_source(settings, dir)) == "project";
            FlushResult off;
            off.outcome = "off";
            off.message = mode == ShareMode::Never
                              ? std::string("Sharing is off for this project") +
                                    (own ? " (your choice for it is never)" : " (your default is never)") +
                                    ": nothing is sent."
                              : "Sharing is not set up: nothing is sent. Choose with `factoria feedback sharing "
                                "always|ask|never` (add --project . to choose for this project only).";
            print_report(ctx, nullptr, &off, nullptr);
            return mode == ShareMode::Unset ? 1 : 0;
        }
        if (share_endpoint(env, settings).empty()) return report_failure(ctx, share_unavailable_message());
        auto q = share_queue(env, file, dir, engine);
        if (!q.ok()) return report_failure(ctx, q.error().message, q.error().hint);
        QueueResult queued = std::move(q.value());
        // Entries that wait for your answer: this project's only (another project has its own mode and its own answer to give).
        // Under `always` some can still wait (queued before the mode was always, or by an older version): queueing never answers yes
        // for them, so they are shown here like under `ask`.
        const std::vector<OutboxItem> waiting = share_waiting(env, file);
        if (waiting.empty() && mode == ShareMode::Ask) {
            ctx.out << "Nothing waits for your confirmation.\n";
            print_report(ctx, &queued, nullptr, nullptr);
            return 0;
        }
        if (!waiting.empty()) {
            bool yes = ctx.args.has("yes");
            if (!yes && !ctx.args.has("json")) {
                ctx.out << waiting.size() << " entr" << (waiting.size() == 1 ? "y waits" : "ies wait")
                        << " to be sent to the engine developer:\n";
                for (const OutboxItem& it : waiting)
                    ctx.out << "\n" << it.localId << ":\n" << dump_json(it.entry) << "\n";
                ctx.out << "\nSend " << (waiting.size() == 1 ? "it" : "them") << "? [y/N] " << std::flush;
                std::string answer;
                std::getline(ctx.in, answer);
                yes = !answer.empty() && (answer[0] == 'y' || answer[0] == 'Y');
                if (!yes) {
                    ctx.out << (mode == ShareMode::Ask ? "Nothing was sent. The entries stay waiting.\n"
                                                       : "Those entries were not sent and stay waiting.\n");
                    if (mode == ShareMode::Ask) return 0;  // under always the rest of the outbox still goes
                }
            } else if (!yes) {
                Json arr = Json::array();
                for (const OutboxItem& it : waiting)
                    arr.push_back(Json::object({{"id", it.localId}, {"entry", it.entry}}));
                print_json(ctx.out, Json::object({{"waiting", arr}, {"note", "Run again with --yes to send them."}}));
                return 0;
            }
            if (yes) {
                std::vector<std::string> keys;
                for (const OutboxItem& it : waiting) keys.push_back(it.key);
                // A busy lock or an unwritable outbox: nothing was confirmed, so nothing is sent (the entries stay waiting).
                if (auto confirmed = share_confirm(env, keys); !confirmed.ok())
                    return report_failure(ctx, "Could not confirm the entries: " + confirmed.error().message,
                                          confirmed.error().hint);
            }
        }
        FlushOptions fo;
        fo.file = file;  // this project's items only (the others follow their own mode and were not asked about)
        fo.force = true;
        fo.oneBatch = false;
        fo.timeoutSec = 15.0;
        const FlushResult flushed = share_flush(env, fo);
        print_report(ctx, &queued, &flushed, nullptr);
        return flushed.outcome == "failed" || flushed.outcome == "unavailable" ? 1 : 0;
    };

    Command signin;
    signin.name = "signin";
    signin.summary =
        "Sign in with GitHub so the engine developer can tell your reports from anonymous ones (optional).";
    signin.usage = "github";
    signin.maxPositional = 1;
    signin.details = "Uses GitHub's device flow: you get a code to type at github.com/login/device. No GitHub "
                     "permission is requested (only your "
                     "public profile). The GitHub token is sent once to the feedback server, which answers a "
                     "credential; the token is not kept. "
                     "Reports are accepted without signing in.";
    signin.examples = {"factoria feedback signin github"};
    signin.run = [](Context& ctx) {
        if (ctx.args.pos(0) != "github")
            throw UsageError("Unknown sign-in provider '" + ctx.args.pos(0) + "'.",
                             "Use: factoria feedback signin github");
        auto r = github_sign_in(share_env(), [&](const DeviceCode& code) {
            ctx.out << "Open " << code.verificationUri << " and enter the code: " << code.userCode
                    << "\nWaiting for you to authorize (about " << code.expiresIn / 60 << " minutes)...\n"
                    << std::flush;
        });
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        ctx.out << "Signed in" << (r->login.empty() ? "" : " as " + r->login)
                << ". Your reports now count as verified. `factoria feedback signout` undoes it.\n";
        return 0;
    };

    Command signout;
    signout.name = "signout";
    signout.summary = "Forget the GitHub sign-in; reports go anonymously again.";
    signout.examples = {"factoria feedback signout"};
    signout.run = [](Context& ctx) {
        auto r = share_sign_out(share_env());
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        ctx.out << "Signed out.\n";
        return 0;
    };

    group.subs.push_back(std::move(sharing));
    group.subs.push_back(std::move(share));
    group.subs.push_back(std::move(signin));
    group.subs.push_back(std::move(signout));
}

}  // namespace fa::cli
