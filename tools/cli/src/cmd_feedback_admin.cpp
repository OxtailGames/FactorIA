// feedback pull|quarantine|ban|unban|bans|delete|stats|fixed: the engine developer's side of feedback sharing.
#include <filesystem>
#include <iostream>

#include "common.h"
#include "feedback_admin.h"
#include "fa/core/strings.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_fixed.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

const FlagSpec kOutFlag{"out", "DIR", "The inbox folder (default: feedback-inbox next to your ai.json, outside any repository)."};
const FlagSpec kJsonFlag{"json", "", "Machine-readable output."};

// Where the inbox is: --out (any folder, also inside a git checkout) or the default one.
std::string inbox_of(const Context& ctx) {
    return ctx.args.has("out") ? absolute_path(ctx.args.str("out")) : default_feedback_inbox(feedback_admin_env().env);
}

Result<FeedbackAdminConfig> admin_config(const FeedbackAdminEnv& e) { return load_feedback_admin_config(feedback_admin_config_path(e.env)); }

void print_tree(std::ostream& out, const Json& j, int indent) {
    const std::string pad(static_cast<std::size_t>(indent) * 2, ' ');
    if (j.is_object()) {
        for (auto it = j.begin(); it != j.end(); ++it) {
            if (indent == 0 && it.key() == "ok") continue;
            if (it.value().is_object() || it.value().is_array()) {
                out << pad << it.key() << ":\n";
                print_tree(out, it.value(), indent + 1);
            } else {
                out << pad << it.key() << ": " << (it.value().is_string() ? it.value().get<std::string>() : dump_json(it.value())) << "\n";
            }
        }
    } else if (j.is_array()) {
        for (const auto& v : j) {
            if (v.is_object() || v.is_array()) {
                out << pad << "-\n";
                print_tree(out, v, indent + 1);
            } else {
                out << pad << "- " << (v.is_string() ? v.get<std::string>() : dump_json(v)) << "\n";
            }
        }
    } else {
        out << pad << dump_json(j) << "\n";
    }
}

Command pull_command() {
    Command c;
    c.name = "pull";
    c.summary = "Download the feedback users shared into an inbox, one ENGINE_FEEDBACK.json per installation (engine developer).";
    c.usage = "[--out DIR] [--full] [--classify | --no-classify] [--json]";
    c.details =
        "Reads feedback-admin.json (endpoint, adminToken, cursor) from the folder of your ai.json; tools/feedback-server/deploy.sh writes it.\n"
        "New reports since the saved cursor go to <inbox>/<installKey>/ENGINE_FEEDBACK.json (project install-<installKey>); a report\n"
        "pulled again is recognised by its shareId and only its occurrences are updated. The inbox is never inside a git checkout unless\n"
        "you name it with --out. The cursor is saved after the files are written.\n"
        "A report that users send again only raises its 'occurrences' on the server and keeps its place in the arrival order, so an\n"
        "incremental pull never sees the new count: run --full now and then (it ignores the cursor, reads everything and updates the\n"
        "occurrences of the entries already in the inbox by shareId).\n"
        "Classification: when the 'fast' role of ai.json has a usable provider, each new report is judged valid, doubtful or junk, ten per\n"
        "model call. Junk goes to <inbox>/quarantine/ (see 'feedback quarantine'), a doubtful entry gets a note. Without an AI, pull works\n"
        "and says classification was skipped. Collect the inbox with: factoria feedback collect <inbox> --out roadmap.md";
    c.flags = {kOutFlag, {"full", "", "Ignore the saved cursor: read every report again and update the occurrences of known ones."},
               {"classify", "", "Judge the new reports with the AI; an error when no AI is configured."},
               {"no-classify", "", "Do not judge the new reports."}, kJsonFlag};
    c.examples = {"factoria feedback pull", "factoria feedback pull --full", "factoria feedback pull --no-classify --out ~/inbox"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.has("classify") && a.has("no-classify")) throw UsageError("--classify and --no-classify contradict each other.", "Pass only one.");
        PullOptions po;
        po.outExplicit = a.has("out");
        if (po.outExplicit) po.out = absolute_path(a.str("out"));
        po.full = a.has("full");
        po.classify = a.has("classify") ? ClassifyMode::On : a.has("no-classify") ? ClassifyMode::Off : ClassifyMode::Auto;
        auto r = feedback_pull(po, feedback_admin_env());
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        if (a.has("json")) {
            print_json(ctx.out, r->to_json());
            return 0;
        }
        for (const auto& w : r->warnings) ctx.err << "warning: " << w << "\n";
        ctx.out << "Fetched " << r->fetched << " report(s) in " << r->pages << " page(s): " << r->added << " new, " << r->updated << " with more occurrences, "
                << r->known << " already known" << (r->invalid ? ", " + std::to_string(r->invalid) + " unreadable" : "") << ".\n";
        ctx.out << "Inbox: " << r->inbox << "\n";
        if (!r->installations.empty()) {
            ctx.out << "Written for " << r->installations.size() << " installation(s):";
            for (const auto& k : r->installations) ctx.out << " " << k;
            ctx.out << "\n";
        }
        ctx.out << "Classification: " << r->classification << "\n";
        if (!po.full)
            ctx.out << "Counts of reports users sent again are only updated by `factoria feedback pull --full`.\n";
        if (r->junk > 0) ctx.out << r->junk << " junk report(s) went to the quarantine: factoria feedback quarantine list\n";
        ctx.out << "Next: factoria feedback collect \"" << r->inbox << "\" --out roadmap.md\n";
        return 0;
    };
    return c;
}

Command quarantine_command() {
    Command c;
    c.name = "quarantine";
    c.summary = "List, restore or clear the reports `feedback pull` judged junk.";
    c.usage = "[list | restore <shareId> | clear] [--out DIR] [--json]";
    c.maxPositional = 2;
    c.details = "The quarantine is <inbox>/quarantine/quarantine.json. 'restore' moves a report to its installation's ENGINE_FEEDBACK.json with a\n"
                "new id; 'clear' forgets all of them on this machine (the server keeps them: use 'feedback delete' or 'feedback ban' for that).";
    c.flags = {kOutFlag, kJsonFlag};
    c.examples = {"factoria feedback quarantine", "factoria feedback quarantine restore r_8f3k2m", "factoria feedback quarantine clear"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        const std::string action = a.pos(0, "list"), inbox = inbox_of(ctx);
        if (action == "list") {
            Json items = quarantine_list(inbox);
            if (a.has("json")) {
                print_json(ctx.out, items);
                return 0;
            }
            if (items.empty()) ctx.out << "The quarantine is empty.\n";
            for (const auto& it : items) {
                const Json& en = it["entry"];
                ctx.out << it.value("shareId", std::string()) << "  " << it.value("installKey", std::string()) << "  [" << en.value("category", std::string()) << "] "
                        << en.value("title", std::string()) << "\n    judged junk on " << it.value("date", std::string()) << ": " << it.value("reason", std::string()) << "\n";
            }
            return 0;
        }
        if (action == "restore") {
            if (a.positional().size() < 2) throw UsageError("Missing the shareId to restore.", "Usage: factoria feedback quarantine restore <shareId> (see 'quarantine list').");
            auto r = quarantine_restore(inbox, a.pos(1), feedback_admin_today(feedback_admin_env()));
            if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
            if (a.has("json")) print_json(ctx.out, *r);
            else ctx.out << "Restored " << a.pos(1) << " as " << r->value("id", std::string()) << " in " << (*r)["remote"].value("installKey", std::string()) << ".\n";
            return 0;
        }
        if (action == "clear") {
            auto r = quarantine_clear(inbox);
            if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
            if (a.has("json")) print_json(ctx.out, Json::object({{"cleared", *r}}));
            else ctx.out << "Cleared " << *r << " quarantined report(s).\n";
            return 0;
        }
        throw UsageError("Unknown quarantine action '" + action + "'.", "Use list, restore <shareId> or clear.");
    };
    return c;
}

// Runs one admin request with the configured server; prints the failure, or leaves the answer in `result`.
int admin_run(Context& ctx, const std::string& method, const std::string& path, const Json* body, Json& result) {
    auto cfg = admin_config(feedback_admin_env());
    if (!cfg.ok()) return report_failure(ctx, cfg.error().message, cfg.error().hint);
    auto r = feedback_admin_request(*cfg, feedback_admin_env().transport, method, path, body);
    if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
    result = *r;
    return 0;
}

KeyKind forced_kind(const Args& a) {
    if (a.has("install") && a.has("reporter")) throw UsageError("--install and --reporter contradict each other.", "A key is one or the other.");
    return a.has("install") ? KeyKind::Install : a.has("reporter") ? KeyKind::Reporter : KeyKind::Unknown;
}

Command ban_command() {
    Command c;
    c.name = "ban";
    c.summary = "Ban an installation or a reporter on the feedback server (engine developer).";
    c.usage = "<installKey|reporterKey|shareId> [--install | --reporter] [--purge] [--reason TEXT] [--out DIR] [--json]";
    c.maxPositional = 1;
    c.details = "From now on the server refuses everything that key sends. Both kinds of key look alike, so say which with --install or\n"
                "--reporter (or write install:KEY / reporter:KEY). Without a flag the key is taken as an installKey when it is a folder of the\n"
                "inbox, or when it is the shareId of a pulled report (then its installation is banned). --purge also deletes the reports the\n"
                "key already sent. 'feedback unban' undoes the ban (not the purge).";
    c.flags = {{"install", "", "The key is an installKey."}, {"reporter", "", "The key is a reporterKey."},
               {"purge", "", "Also delete this key's stored reports."}, {"reason", "TEXT", "Why (kept with the ban)."}, kOutFlag, kJsonFlag};
    c.examples = {"factoria feedback ban 3kF9aQ2xLm7Zp0Vt --install --purge --reason \"spam\"", "factoria feedback ban r_8f3k2m"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Missing the key to ban.", "Usage: factoria feedback ban <installKey|reporterKey|shareId> [--install | --reporter]");
        auto key = resolve_ban_key(a.pos(0), forced_kind(a), inbox_of(ctx));
        if (!key.ok()) throw UsageError(key.error().message, key.error().hint);
        Json body = Json::object({{key->first == KeyKind::Install ? "installKey" : "reporterKey", key->second},
                                  {"reason", a.has("reason") ? a.str("reason") : std::string("banned by the engine developer")}});
        if (a.has("purge")) body["purge"] = true;
        Json res;
        if (int rc = admin_run(ctx, "POST", "/v1/admin/ban", &body, res)) return rc;
        if (a.has("json")) {
            print_json(ctx.out, res);
            return 0;
        }
        const char* kind = key->first == KeyKind::Install ? "installation" : "reporter";
        ctx.out << "Banned " << kind << " " << key->second << (a.has("purge") ? " and purged its reports" : "") << ".\n";
        if (res.contains("purged")) ctx.out << "Reports deleted on the server: " << dump_json(res["purged"]) << "\n";
        ctx.out << "Undo with: factoria feedback unban " << key->second << (key->first == KeyKind::Install ? " --install" : " --reporter") << "\n";
        return 0;
    };
    return c;
}

Command unban_command() {
    Command c;
    c.name = "unban";
    c.summary = "Lift a ban on the feedback server (engine developer).";
    c.usage = "<installKey|reporterKey> [--install | --reporter] [--out DIR] [--json]";
    c.maxPositional = 1;
    c.flags = {{"install", "", "The key is an installKey."}, {"reporter", "", "The key is a reporterKey."}, kOutFlag, kJsonFlag};
    c.examples = {"factoria feedback unban 3kF9aQ2xLm7Zp0Vt --install", "factoria feedback bans"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Missing the key to unban.", "See the keys with 'factoria feedback bans'.");
        auto key = resolve_ban_key(a.pos(0), forced_kind(a), inbox_of(ctx));
        if (!key.ok()) throw UsageError(key.error().message, key.error().hint);
        Json body = Json::object({{key->first == KeyKind::Install ? "installKey" : "reporterKey", key->second}});
        Json res;
        if (int rc = admin_run(ctx, "POST", "/v1/admin/unban", &body, res)) return rc;
        if (a.has("json")) print_json(ctx.out, res);
        else if (res.value("removed", true)) ctx.out << "Unbanned " << key->second << ".\n";
        else ctx.out << key->second << " was not banned (nothing to undo). See: factoria feedback bans\n";
        return 0;
    };
    return c;
}

Command bans_command() {
    Command c;
    c.name = "bans";
    c.summary = "List the bans on the feedback server (engine developer).";
    c.usage = "[--json]";
    c.flags = {kJsonFlag};
    c.run = [](Context& ctx) {
        Json res;
        if (int rc = admin_run(ctx, "GET", "/v1/admin/bans", nullptr, res)) return rc;
        if (ctx.args.has("json")) {
            print_json(ctx.out, res);
            return 0;
        }
        const Json& list = res.contains("bans") ? res["bans"] : res;
        if (!list.is_array()) print_tree(ctx.out, list, 0);
        else if (list.empty()) ctx.out << "No bans.\n";
        else
            for (const Json& b : list) {
                if (!b.is_object()) continue;
                const std::string kind = b.value("kind", std::string("?")), reason = b.value("reason", std::string());
                ctx.out << (kind == "reporter" ? "reporter " : kind == "install" ? "install  " : kind + " ") << b.value("key", std::string("?"))
                        << "  " << b.value("createdAt", std::string()).substr(0, 10) << (reason.empty() ? "" : "  " + reason) << "\n";
            }
        return 0;
    };
    return c;
}

Command delete_command() {
    Command c;
    c.name = "delete";
    c.summary = "Delete one report on the feedback server (engine developer).";
    c.usage = "<shareId> [--local] [--out DIR] [--json]";
    c.maxPositional = 1;
    c.details = "Deletes the stored report. --local also removes it from the inbox and the quarantine on this machine.";
    c.flags = {{"local", "", "Also remove the report from the inbox and the quarantine."}, kOutFlag, kJsonFlag};
    c.examples = {"factoria feedback delete r_8f3k2m --local"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Missing the shareId to delete.", "It is in the 'remote' field of an inbox entry, or in 'feedback quarantine list'.");
        const std::string id = a.pos(0);
        if (id.empty() || id.size() > 64 || id.find_first_not_of("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-") != std::string::npos)
            throw UsageError("'" + id + "' is not a shareId.", "A shareId is letters, digits, '_' and '-', like r_8f3k2m.");
        Json res;
        if (int rc = admin_run(ctx, "DELETE", "/v1/admin/reports/" + id, nullptr, res)) return rc;
        int local = a.has("local") ? remove_local_report(inbox_of(ctx), id) : 0;
        if (a.has("json")) {
            res["localRemoved"] = local;
            print_json(ctx.out, res);
        } else {
            ctx.out << "Deleted report " << id << " on the server" << (a.has("local") ? "; removed " + std::to_string(local) + " local entr" + (local == 1 ? "y" : "ies") : "") << ".\n";
        }
        return 0;
    };
    return c;
}

// Totals first, then one line per day that had any activity (the server sends every day of its window).
void print_stats(std::ostream& out, const Json& res) {
    const Json totals = res.value("totals", Json::object());
    auto num = [](const Json& o, const char* k) { return o.contains(k) && o[k].is_number() ? o[k].get<long long>() : 0LL; };
    out << "reports: " << num(totals, "reports") << "  installations: " << num(totals, "installations")
        << "  occurrences: " << num(totals, "occurrences") << "  bans: " << num(totals, "bans") << "\n";
    const Json days = res.value("days", Json::array());
    int shown = 0;
    for (const Json& d : days) {
        if (!d.is_object()) continue;
        const long long accepted = num(d, "accepted"), merged = num(d, "merged"), rejected = num(d, "rejected"),
                        limited = num(d, "rateLimited"), banned = num(d, "banned");
        if (accepted + merged + rejected + limited + banned == 0) continue;
        if (shown++ == 0) out << "\nDays with activity (UTC):\n";
        out << "  " << d.value("day", std::string("?")) << "  accepted " << accepted << ", merged " << merged << ", rejected "
            << rejected << ", rate-limited " << limited << ", banned " << banned;
        if (d.contains("rejections") && d["rejections"].is_object() && !d["rejections"].empty()) {
            std::string why;
            for (auto it = d["rejections"].begin(); it != d["rejections"].end(); ++it)
                why += (why.empty() ? "" : ", ") + it.key() + " " + std::to_string(it->is_number() ? it->get<long long>() : 0);
            out << " (" << why << ")";
        }
        out << "\n";
    }
    if (shown == 0) out << "No activity in the last " << days.size() << " days.\n";
}

Command stats_command() {
    Command c;
    c.name = "stats";
    c.summary = "Counts of reports, installations, rejections and rate-limit hits on the feedback server (engine developer).";
    c.usage = "[--json]";
    c.flags = {kJsonFlag};
    c.run = [](Context& ctx) {
        Json res;
        if (int rc = admin_run(ctx, "GET", "/v1/admin/stats", nullptr, res)) return rc;
        if (ctx.args.has("json")) {
            print_json(ctx.out, res);
            return 0;
        }
        print_stats(ctx.out, res);
        return 0;
    };
    return c;
}

// ---- feedback fixed ----------------------------------------------------------------------------------------------------
Result<std::string> fixed_file(const Context& ctx) {
    if (ctx.args.has("file")) return absolute_path(ctx.args.str("file"));
    return find_fixed_list_path(fsys::current_path().string());
}

Command fixed_command() {
    Command g;
    g.name = "fixed";
    g.summary = "Maintain feedback/fixed.json: the gaps engine releases fixed (engine developer).";
    g.details = "Users' open entries that match a fix are closed with the version that fixed it when their engine ships the list. Keep the\n"
                "format as it is: feedback/fixed.json is embedded in the binary.";
    g.maxPositional = -1;

    Command add;
    add.name = "add";
    add.summary = "Record that a release fixed a gap.";
    add.usage = "--category C --title T [--title T2] --version V [--note N] [--file PATH]";
    add.details = "--title is how the gap reads in users' reports; repeat it for other wordings. Entries match when their category (or family) and\n"
                  "title are alike (feedback_entry_similarity >= 0.7). Adding the same category, version and a title again extends that fix.\n"
                  "The file is <repo>/feedback/fixed.json (created with an empty list when missing); run it inside the engine checkout or pass --file.";
    add.flags = {{"category", "C", "Engine area (the categories of 'feedback add')."}, {"title", "T", "Title of the gap; repeatable.", true},
                 {"version", "V", "Engine version that ships the fix, like 0.11.0."}, {"note", "N", "What fixed it, for the notes of closed entries."},
                 {"file", "PATH", "The fixed.json to change (default: the checkout's feedback/fixed.json)."}, kJsonFlag};
    add.examples = {"factoria feedback fixed add --category physics --title \"No one-way platforms\" --version 0.11.0 --note \"Collider2D.oneWay\""};
    add.run = [](Context& ctx) {
        const Args& a = ctx.args;
        std::vector<std::string> missing;
        for (const char* k : {"category", "title", "version"})
            if (!a.has(k)) missing.push_back(std::string("--") + k);
        if (!missing.empty()) throw UsageError("Missing required " + join(missing, ", ") + ".", "Usage: factoria feedback fixed add --category C --title T --version V [--note N]");
        auto file = fixed_file(ctx);
        if (!file.ok()) return report_failure(ctx, file.error().message, file.error().hint);
        FeedbackFix fix;
        fix.category = a.str("category");
        fix.titles = a.all("title");
        fix.fixedIn = a.str("version");
        fix.note = a.str("note");
        auto r = add_fixed_to_file(*file, fix);
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        if (a.has("json")) {
            print_json(ctx.out, Json::object({{"file", *file}, {"created", r->created}, {"merged", r->merged}, {"total", r->total},
                                              {"fix", Json::object({{"category", r->fix.category}, {"titles", r->fix.titles}, {"fixedIn", r->fix.fixedIn}, {"note", r->fix.note}})}}));
            return 0;
        }
        ctx.out << (r->created ? "Created " + *file + " and added" : r->merged ? "Extended" : "Added") << " the fix of " << r->fix.category << " \"" << r->fix.titles.front()
                << "\" in " << r->fix.fixedIn << " (" << r->total << " fix" << (r->total == 1 ? "" : "es") << " in " << *file << ").\n";
        return 0;
    };

    Command list;
    list.name = "list";
    list.summary = "List the recorded fixes.";
    list.usage = "[--file PATH] [--json]";
    list.flags = {{"file", "PATH", "The fixed.json to read (default: the checkout's feedback/fixed.json)."}, kJsonFlag};
    list.run = [](Context& ctx) {
        auto file = fixed_file(ctx);
        if (!file.ok()) return report_failure(ctx, file.error().message, file.error().hint);
        auto doc = load_fixed_list_file(*file);
        if (!doc.ok()) return report_failure(ctx, doc.error().message, doc.error().hint);
        auto fixes = parse_fixed_list(*doc, *file);
        if (!fixes.ok()) return report_failure(ctx, fixes.error().message, fixes.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, *doc);
            return 0;
        }
        if (fixes->empty()) ctx.out << "No fixes recorded in " << *file << ".\n";
        for (const auto& f : *fixes) {
            ctx.out << f.fixedIn << "  [" << f.category << "]  " << join(f.titles, " | ");
            if (!f.note.empty()) ctx.out << "  - " << f.note;
            ctx.out << "\n";
        }
        return 0;
    };

    g.subs = {add, list};
    return g;
}

}  // namespace

std::vector<Command> make_feedback_admin_commands() {
    return {pull_command(), quarantine_command(), ban_command(), unban_command(), bans_command(), delete_command(), stats_command(), fixed_command()};
}

}  // namespace fa::cli
