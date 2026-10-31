// feedback sharing|share|signin|signout: the commands a PERSON types to decide and run what is sent to the engine developer
// (fa/tooling/feedback_share.h). They have no command-registry twin on purpose: an AI cannot change the mode.
#include <filesystem>
#include <iostream>

#include "common.h"
#include "fa/core/strings.h"
#include "fa/tooling/feedback_share.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

void print_status(Context& ctx) {
    const Json s = share_status(share_env());
    if (ctx.args.has("json")) {
        print_json(ctx.out, s);
        return;
    }
    ctx.out << "Sharing feedback with the engine developer: " << s.value("mode", std::string("unset")) << "\n";
    if (!s.value("available", false)) ctx.out << "  Not available: " << s.value("howToFix", std::string()) << "\n";
    else ctx.out << "  Server: " << s.value("endpoint", std::string()) << "\n";
    ctx.out << "  Signed in with GitHub: " << (s.value("signedIn", false) ? s.value("login", std::string("yes")) : std::string("no (anonymous)")) << "\n";
    const Json& box = s["outbox"];
    ctx.out << "  Outbox: " << box.value("queued", 0) << " queued, " << box.value("waitingForConfirmation", 0) << " waiting for your confirmation\n";
    for (const Json& f : box["failed"])
        ctx.out << "    " << f.value("id", std::string()) << ": " << f.value("error", std::string()) << " (attempt " << f.value("attempts", 0)
                << ", retried in " << f.value("retryInSeconds", 0) << " s)\n";
    if (s.contains("lastSend")) ctx.out << "  Last attempt: " << s["lastSend"].value("message", std::string()) << "\n";
    if (s.contains("warning")) ctx.out << "  Warning: " << s.value("warning", std::string()) << "\n";
    if (s.value("mode", std::string()) == "unset")
        ctx.out << "\nNothing is sent until you choose: factoria feedback sharing always | ask | never\n"
                   "See: factoria docs read engine-feedback\n";
}

std::string project_for_share(const Context& ctx) { return find_project_dir_or_empty(ctx, 0); }

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
        for (const ShareEntryReport& r : queued->entries) ctx.out << "  " << r.id << ": " << r.status << (r.reason.empty() ? "" : " - " + r.reason) << "\n";
    if (flushed) ctx.out << flushed->message << "\n";
}

}  // namespace

void add_feedback_share_commands(Command& group) {
    Command sharing;
    sharing.name = "sharing";
    sharing.summary = "Choose whether feedback is shared with the engine developer (always, ask, never); without an argument, show the status.";
    sharing.usage = "[always|ask|never] [--json]";
    sharing.maxPositional = 1;
    sharing.flags = {{"json", "", "Machine-readable status."}};
    sharing.details =
        "Entries of ENGINE_FEEDBACK.json that carry a `share` (a generic copy in engine terms only) can be sent to the engine "
        "developer so that the gaps of every game reach the roadmap. Nothing about your game is sent: no names, paths, file names or "
        "quoted text; `factoria feedback share --preview` shows exactly what would go.\n"
        "  always  send new shareable entries as they are recorded\n"
        "  ask     queue them and send only what you confirm (`factoria feedback share`)\n"
        "  never   send nothing; the outbox is emptied\n"
        "Only you can change this: no engine command does. See: factoria docs read engine-feedback";
    sharing.examples = {"factoria feedback sharing", "factoria feedback sharing ask", "factoria feedback sharing never"};
    sharing.run = [](Context& ctx) {
        if (ctx.args.positional().empty()) {
            print_status(ctx);
            return 0;
        }
        const std::string word = ctx.args.pos(0);
        auto mode = parse_share_mode(word);
        if (!mode || *mode == ShareMode::Unset)
            throw UsageError("Unknown sharing mode '" + word + "'.", "Use always, ask or never. " + did_you_mean(word, std::vector<std::string>{"always", "ask", "never"}));
        auto r = set_share_mode(share_env(), *mode);
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, share_status(share_env()));
            return 0;
        }
        ctx.out << "Sharing is now '" << share_mode_name(*mode) << "'.\n";
        if (*mode == ShareMode::Always) ctx.out << "New feedback with a `share` is sent as soon as it is recorded. Preview: factoria feedback share --preview\n";
        if (*mode == ShareMode::Ask) ctx.out << "New feedback with a `share` waits for you: run `factoria feedback share` to see it and confirm.\n";
        if (*mode == ShareMode::Never) ctx.out << "Nothing is sent and the outbox was emptied.\n";
        if (*mode != ShareMode::Never && share_endpoint(share_env(), load_share_settings(share_env())).empty())
            ctx.out << "Note: " << share_unavailable_message() << "\n";
        return 0;
    };

    Command share;
    share.name = "share";
    share.summary = "Send the queued feedback to the engine developer now; with --preview, show exactly what would be sent.";
    share.usage = "[project] [--preview] [--yes] [--json]";
    share.maxPositional = 1;
    share.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
                   {"preview", "", "Show what would be sent and what the sanitizer removed; send nothing."},
                   {"yes", "", "With mode ask: confirm every waiting entry without asking."},
                   {"json", "", "Machine-readable output."}};
    share.details =
        "Queues the shareable entries of the project (open, with a `share`), then sends the outbox: one request of up to 20 entries "
        "at a time. With mode ask it first shows what waits and asks for your confirmation. Needs the mode always or ask "
        "(`factoria feedback sharing`).";
    share.examples = {"factoria feedback share --preview", "factoria feedback share", "factoria feedback share --yes"};
    share.run = [](Context& ctx) {
        const ShareEnv& env = share_env();
        const std::string dir = project_for_share(ctx);
        std::string file;
        if (!dir.empty()) {
            file = feedback_path(dir);
            std::error_code ec;
            if (!fsys::exists(file, ec)) file.clear();
        }
        const EngineNames engine = collect_engine_names();
        if (ctx.args.has("preview")) {
            if (file.empty()) return report_failure(ctx, "No ENGINE_FEEDBACK.json to preview.", "Run inside a project, or pass its folder.");
            const Json pv = share_preview(env, file, dir, engine);
            if (ctx.args.has("json")) {
                print_json(ctx.out, pv);
                return 0;
            }
            ctx.out << "Sharing mode: " << pv.value("mode", std::string()) << " (a preview sends nothing)\n";
            if (pv["entries"].empty()) ctx.out << "No entry has a `share` waiting to go.\n";
            for (const Json& e : pv["entries"]) {
                ctx.out << "\n" << e.value("id", std::string()) << (e.value("ok", false) ? ": would be sent as\n" : ": NOT sent - " + e.value("reason", std::string()) + "\n");
                if (e.contains("sent")) ctx.out << dump_json(e["sent"]) << "\n";
                for (const Json& r : e["removed"])
                    ctx.out << "  removed (" << r.value("kind", std::string()) << ", " << r.value("field", std::string()) << "): " << r.value("text", std::string()) << "\n";
            }
            return 0;
        }
        const ShareSettings settings = load_share_settings(env);
        if (settings.mode != ShareMode::Always && settings.mode != ShareMode::Ask) {
            const FlushResult off = share_flush(env);
            print_report(ctx, nullptr, &off, nullptr);
            return settings.mode == ShareMode::Unset ? 1 : 0;
        }
        if (share_endpoint(env, settings).empty()) return report_failure(ctx, share_unavailable_message());
        QueueResult queued;
        if (!file.empty()) {
            auto q = share_queue(env, file, dir, engine);
            if (!q.ok()) return report_failure(ctx, q.error().message, q.error().hint);
            queued = std::move(q.value());
        }
        if (settings.mode == ShareMode::Ask) {
            const std::vector<OutboxItem> waiting = share_waiting(env);
            if (waiting.empty()) {
                ctx.out << "Nothing waits for your confirmation.\n";
                print_report(ctx, &queued, nullptr, nullptr);
                return 0;
            }
            bool yes = ctx.args.has("yes");
            if (!yes && !ctx.args.has("json")) {
                ctx.out << waiting.size() << " entr" << (waiting.size() == 1 ? "y waits" : "ies wait") << " to be sent to the engine developer:\n";
                for (const OutboxItem& it : waiting) ctx.out << "\n" << it.localId << ":\n" << dump_json(it.entry) << "\n";
                ctx.out << "\nSend " << (waiting.size() == 1 ? "it" : "them") << "? [y/N] " << std::flush;
                std::string answer;
                std::getline(ctx.in, answer);
                yes = !answer.empty() && (answer[0] == 'y' || answer[0] == 'Y');
                if (!yes) {
                    ctx.out << "Nothing was sent. The entries stay waiting.\n";
                    return 0;
                }
            }
            if (!yes) {
                Json arr = Json::array();
                for (const OutboxItem& it : waiting) arr.push_back(Json::object({{"id", it.localId}, {"entry", it.entry}}));
                print_json(ctx.out, Json::object({{"waiting", arr}, {"note", "Run again with --yes to send them."}}));
                return 0;
            }
            share_confirm(env);
        }
        FlushOptions fo;
        fo.force = true;
        fo.oneBatch = false;
        fo.timeoutSec = 15.0;
        const FlushResult flushed = share_flush(env, fo);
        print_report(ctx, &queued, &flushed, nullptr);
        return flushed.outcome == "failed" || flushed.outcome == "unavailable" ? 1 : 0;
    };

    Command signin;
    signin.name = "signin";
    signin.summary = "Sign in with GitHub so the engine developer can tell your reports from anonymous ones (optional).";
    signin.usage = "github";
    signin.maxPositional = 1;
    signin.details =
        "Uses GitHub's device flow: you get a code to type at github.com/login/device. No GitHub permission is requested (only your "
        "public profile). The GitHub token is sent once to the feedback server, which answers a credential; the token is not kept. "
        "Reports are accepted without signing in.";
    signin.examples = {"factoria feedback signin github"};
    signin.run = [](Context& ctx) {
        if (ctx.args.pos(0) != "github") throw UsageError("Unknown sign-in provider '" + ctx.args.pos(0) + "'.", "Use: factoria feedback signin github");
        auto r = github_sign_in(share_env(), [&](const DeviceCode& code) {
            ctx.out << "Open " << code.verificationUri << " and enter the code: " << code.userCode << "\nWaiting for you to authorize (about "
                    << code.expiresIn / 60 << " minutes)...\n" << std::flush;
        });
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        ctx.out << "Signed in" << (r->login.empty() ? "" : " as " + r->login) << ". Your reports now count as verified. `factoria feedback signout` undoes it.\n";
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
