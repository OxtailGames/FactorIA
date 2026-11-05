// feedback init|add|list|validate|collect, docs list|read|search
#include <filesystem>
#include <fstream>
#include <iostream>

#include "common.h"
#include "feedback_admin.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_check.h"
#include "fa/tooling/feedback_share.h"

namespace fa::cli {

void add_feedback_share_commands(Command& group);  // cmd_feedback_share.cpp

namespace fsys = std::filesystem;

namespace {

std::string project_name(const std::string& dir) {
    auto ps = load_project(dir);
    return ps.ok() ? ps->name : fsys::path(dir).filename().string();
}

Command project_flag_cmd(std::string name, std::string summary) {
    Command c;
    c.name = std::move(name);
    c.summary = std::move(summary);
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."}};
    return c;
}

void write_text_file(const std::string& path, const std::string& text) {
    std::error_code ec;
    if (fsys::path(path).has_parent_path()) fsys::create_directories(fsys::path(path).parent_path(), ec);
    std::ofstream f(path, std::ios::binary);
    if (!f) throw CliError("Cannot write '" + path + "'.");
    f << text;
}

std::vector<std::string> split_list(const std::vector<std::string>& values) {
    std::vector<std::string> out;
    for (const auto& v : values)
        for (auto& part : split(v, ',')) out.emplace_back(trim(part));
    return out;
}

}  // namespace

Command make_feedback_command() {
    Command g;
    g.name = "feedback";
    g.summary = "Manage ENGINE_FEEDBACK.json: what the engine lacked and the workarounds used.";
    g.details = "Game-making AIs record engine gaps here; engine developers aggregate many projects with 'feedback collect'.\nSee: factoria docs read engine-feedback";
    g.maxPositional = -1;

    Command init = project_flag_cmd("init", "Create ENGINE_FEEDBACK.json if the project has none.");
    init.usage = "[project]";
    init.flags.push_back({"force", "", "Overwrite an existing file (drops its entries)."});
    init.examples = {"factoria feedback init"};
    init.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        std::string path = feedback_path(dir);
        std::error_code ec;
        if (fsys::exists(path, ec) && !ctx.args.has("force")) {
            ctx.out << path << " already exists.\n";
            return 0;
        }
        auto r = save_feedback(path, create_empty_feedback(project_name(dir)));
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        ctx.out << "Created " << path << "\n";
        return 0;
    };

    Command add = project_flag_cmd("add", "Add an entry (similar open entries are merged).");
    add.usage = "--category C --severity S --title T --missing TEXT --workaround TEXT [options]";
    add.details =
        "category: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation, tooling,\n"
        "ai-integration, docs, platform, performance, networking, other.\n"
        "severity: blocker, major, minor, nice-to-have.";
    add.flags.insert(add.flags.end(), {{"category", "C", "Engine area."},
                                       {"severity", "S", "blocker | major | minor | nice-to-have."},
                                       {"title", "T", "Short noun phrase; reuse wording for the same gap."},
                                       {"missing", "TEXT", "What the engine lacks."},
                                       {"workaround", "TEXT", "What you did instead."},
                                       {"files", "A,B", "Workaround files (comma separated or repeated).", true},
                                       {"suggestion", "TEXT", "How the engine could fix it."},
                                       {"effort", "E", "small | medium | large."},
                                       {"reporter", "KIND", "ai or human (default human)."},
                                       {"agent", "NAME", "Reporter agent name (with --reporter ai)."},
                                       {"model", "MODEL", "Reporter model (with --reporter ai)."},
                                       {"share-title", "T", "For sharing: the title in engine terms only, nothing about the game (8-120 characters)."},
                                       {"share-missing", "TEXT", "For sharing: what the engine lacks, in engine terms only (20-1500 characters)."},
                                       {"share-suggestion", "TEXT", "For sharing: the engine change that would fix it."},
                                       {"share-workaround", "TEXT", "For sharing: the kind of workaround, without project details."},
                                       {"reviewed", "", "You checked against the docs that the gap is real and about the engine."},
                                       {"json", "JSON", "Entry as a JSON object instead of flags (same keys as the flags; `share` is {title, missing, suggestion?, workaround?}, `reviewed` a boolean)."}});
    add.examples = {"factoria feedback add --category physics --severity major --title \"No fluid simulation\" \\\n"
                    "    --missing \"There is no liquid solver\" --workaround \"scripts/water.js fakes a surface\" --files scripts/water.js",
                    "factoria feedback add --json '{\"category\":\"docs\",\"severity\":\"minor\",\"title\":\"...\",\"missing\":\"...\",\"workaround\":\"...\"}'"};
    add.run = [](Context& ctx) {
        const Args& a = ctx.args;
        std::string dir = resolve_project_dir(ctx, 0);
        Json src = Json::object();
        if (a.has("json")) {
            auto j = parse_json(a.str("json"), "--json");
            if (!j.ok() || !j->is_object())
                throw UsageError("--json must be a JSON object: " + (j.ok() ? std::string("got ") + describe_json_value(*j) : j.error().message));
            src = *j;
        }
        auto get = [&](const char* key) { return a.has(key) && std::string(key) != "json" ? a.str(key) : src.value(key, std::string()); };
        FeedbackInput in;
        in.category = get("category");
        in.severity = get("severity");
        in.title = get("title");
        in.missing = get("missing");
        in.workaround = get("workaround");
        in.suggestion = get("suggestion");
        in.effort = get("effort");
        in.workaroundFiles = split_list(a.all("files"));
        if (in.workaroundFiles.empty() && src.contains("workaroundFiles") && src["workaroundFiles"].is_array())
            for (const auto& f : src["workaroundFiles"]) in.workaroundFiles.push_back(f.get<std::string>());
        {
            Json share = src.contains("share") && src["share"].is_object() ? src["share"] : Json::object();
            for (const char* k : {"title", "missing", "suggestion", "workaround"})
                if (a.has(std::string("share-") + k)) share[k] = a.str(std::string("share-") + k);
            if (!share.empty()) in.share = share;
            if (a.has("reviewed")) in.reviewed = true;
            else if (src.contains("reviewed") && src["reviewed"].is_boolean()) in.reviewed = src["reviewed"].get<bool>();
        }
        std::vector<std::string> missing;
        for (auto [k, v] : {std::pair<const char*, const std::string*>{"category", &in.category}, {"severity", &in.severity}, {"title", &in.title},
                            {"missing", &in.missing}, {"workaround", &in.workaround}})
            if (v->empty()) missing.push_back(std::string("--") + k);
        if (!missing.empty())
            throw UsageError("Missing required " + join(missing, ", ") + ".", "Usage: factoria feedback add --category C --severity S --title T --missing TEXT --workaround TEXT");
        std::string kind = a.str("reporter", src.contains("reporter") && src["reporter"].is_object() ? src["reporter"].value("kind", std::string("human")) : "human");
        Json rep = Json::object({{"kind", kind}});
        if (a.has("agent")) rep["agent"] = a.str("agent");
        if (a.has("model")) rep["model"] = a.str("model");
        in.reporter = rep;
        // The check before filing: a report that calls missing something the engine has is refused (docs/ENGINE_FEEDBACK.md).
        ClaimInput claimIn{in.title, in.missing, in.suggestion};
        if (!in.share.is_null()) {
            claimIn.missing += ". " + in.share.value("missing", std::string());
            claimIn.suggestion += ". " + in.share.value("suggestion", std::string());
        }
        const ClaimResult claim = check_feedback_claim(claimIn, nullptr, 3);
        if (claim.refused()) return report_failure(ctx, claim.message(), claim.hint());
        auto r = add_feedback_entry_to_file(feedback_path(dir), in, project_name(dir));
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        ctx.out << (r->reopened ? "Reopened (fixed before, reported again) " : r->merged ? "Merged into " : "Added ") << r->id << " (occurrences: " << r->occurrences << ")\n";
        if (!claim.related.empty()) {
            ctx.out << "Related documentation (if it already covers the gap, close the entry with `feedback update " << r->id
                    << " --status rejected --reason TEXT`):\n";
            for (const Json& d : claim.related)
                ctx.out << "  " << d.value("path", std::string()) << ":" << d.value("line", 0) << "  " << d.value("heading", std::string()) << "\n";
        }
        if (!r->shareProblem.empty()) ctx.out << "The share text was not stored: " << r->shareProblem << ".\n";
        else if (!in.share.is_null()) {
            const Json summary = share_report_summary(share_env(), feedback_path(dir), dir, r->id, nullptr, true);
            if (summary.is_object()) ctx.out << summary.value("message", std::string()) << "\n";
        }
        return 0;
    };

    Command list = project_flag_cmd("list", "List entries.");
    list.usage = "[project] [--status S] [--category C] [--severity V] [--archive] [--json]";
    list.details = "The file holds what is still open; closed entries live in ENGINE_FEEDBACK.archive.json (see 'feedback archive').";
    list.flags.insert(list.flags.end(), {{"status", "S", "open | fixed-in-engine | wont-fix | duplicate | rejected."},
                                         {"category", "C", "Filter by category."},
                                         {"severity", "V", "Filter by severity."},
                                         {"archive", "", "Also list the archived (closed) entries."},
                                         {"json", "", "Machine-readable output."}});
    list.examples = {"factoria feedback list --status open", "factoria feedback list --json"};
    list.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        auto doc = load_feedback(feedback_path(dir));
        if (!doc.ok()) return report_failure(ctx, doc.error().message, doc.error().hint.empty() ? "Create it with 'factoria feedback init'." : doc.error().hint);
        FeedbackFilter f{ctx.args.str("status"), ctx.args.str("category"), ctx.args.str("severity")};
        Json entries = list_feedback(*doc, f);
        if (ctx.args.has("archive"))
            for (auto e : list_archived_feedback(feedback_path(dir), f)) {
                e["archived"] = true;
                entries.push_back(std::move(e));
            }
        if (ctx.args.has("json")) {
            print_json(ctx.out, entries);
            return 0;
        }
        if (entries.empty()) ctx.out << "No entries.\n";
        for (const auto& e : entries)
            ctx.out << e.value("id", std::string()) << " [" << e.value("severity", std::string()) << "] " << e.value("category", std::string()) << " x"
                    << e.value("occurrences", 1) << " (" << e.value("status", std::string()) << (e.value("archived", false) ? ", archived" : "") << ") " << e.value("title", std::string()) << "\n";
        return 0;
    };

    Command update = project_flag_cmd("update", "Change an entry's status and/or engine issue reference (triage).");
    update.usage = "[project] <id> [--status S] [--reason TEXT] [--note TEXT] [--engine-issue REF] [--json]";
    update.maxPositional = 2;
    update.details = "The project folder is optional: 'factoria feedback update <id> --status fixed-in-engine' works inside a project.";
    update.flags.insert(update.flags.end(), {{"status", "S", "open | fixed-in-engine | wont-fix | duplicate | rejected (the gap does not exist: --reason is required)."},
                                             {"reason", "TEXT", "Why the entry got this status (statusReason): required for rejected, at most 500 characters."},
                                             {"note", "TEXT", "Triage note appended to the entry's notes."},
                                             {"engine-issue", "REF", "Engine issue/commit that handles it (stored as engineIssue)."},
                                             {"json", "", "Print the updated entry as JSON."}});
    update.examples = {"factoria feedback update games/my-game fb-001 --status fixed-in-engine --engine-issue \"abc123\"",
                       "factoria feedback update fb-002 --status wont-fix --note \"by design\"",
                       "factoria feedback update fb-003 --status rejected --reason \"The engine has it: see docs/reference/components/physics.md\""};
    update.run = [](Context& ctx) {
        const Args& a = ctx.args;
        const auto& pos = a.positional();
        if (pos.empty()) throw UsageError("Missing entry id.", "Usage: factoria feedback update [project] <id> --status S");
        std::string id = pos.back();
        std::string dir = pos.size() > 1 ? absolute_path(pos[0]) : resolve_project_dir(ctx, 99);
        if (!a.has("status") && !a.has("note") && !a.has("engine-issue") && !a.has("reason"))
            throw UsageError("Nothing to update.", "Pass --status, --reason, --note and/or --engine-issue.");
        auto r = update_feedback_file(feedback_path(dir), id, a.str("status"), a.str("engine-issue"), a.str("note"), a.str("reason"), "user");
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint.empty() ? "Create it with 'factoria feedback init'." : r.error().hint);
        if (a.has("json")) {
            print_json(ctx.out, *r);
            return 0;
        }
        ctx.out << "Updated " << id << ": status=" << r->value("status", std::string()) << "\n";
        if (r->value("status", std::string()) == "rejected")
            if (std::string offer = reject_offer(*r); !offer.empty())
                ctx.out << "A pulled report: tell the installation why (it shows the reason in its editor; this only closes the local copy):\n  " << offer << "\n";
        if (r->value("status", std::string()) == "fixed-in-engine")
            if (std::string offer = fixed_add_offer(*r); !offer.empty())
                ctx.out << "A pulled report: record the fix so every user's matching entry is closed when they update:\n  " << offer << "\n";
        return 0;
    };

    Command archive = project_flag_cmd("archive", "Move closed entries (fixed-in-engine, wont-fix, duplicate, rejected) to ENGINE_FEEDBACK.archive.json.");
    archive.usage = "[project] [--json]";
    archive.details = "ENGINE_FEEDBACK.json then only holds what is still open. Ids stay unique across both files, a new report that\n"
                      "matches an archived fixed-in-engine entry reopens it, and 'feedback collect' still counts the archive. The editor\n"
                      "runs this when it opens a project. Nothing closed: nothing changes.";
    archive.flags.push_back({"json", "", "Machine-readable output."});
    archive.examples = {"factoria feedback archive", "factoria feedback archive games/my-game --json"};
    archive.run = [](Context& ctx) {
        std::string path = feedback_path(resolve_project_dir(ctx, 0));
        auto r = archive_closed_feedback_file(path);
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint.empty() ? "Create it with 'factoria feedback init'." : r.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, Json::object({{"moved", r->moved}, {"ids", r->ids}, {"open", r->open}, {"archived", r->archived},
                                              {"file", path}, {"archiveFile", feedback_archive_path(path)}}));
            return 0;
        }
        if (r->moved == 0) ctx.out << "Nothing to archive: " << r->open << " open, " << r->archived << " archived.\n";
        else ctx.out << "Archived " << r->moved << " closed entr" << (r->moved == 1 ? "y" : "ies") << " to " << feedback_archive_path(path) << " ("
                     << r->open << " left open, " << r->archived << " archived).\n";
        return 0;
    };


    Command check = project_flag_cmd("check", "Does the engine already have what a report says it lacks? (before filing, or for the open entries)");
    check.usage = "[project] [--title T --missing TEXT [--suggestion TEXT]] [--entries [--reject]] [--json]";
    check.details = "With --title and --missing: the check `feedback add` runs, on its own (exit 1 when the engine already has it, with what exists\n"
                    "and where it is documented). With --entries: every OPEN entry of the project's ENGINE_FEEDBACK.json is checked; --reject also\n"
                    "closes the ones that fail it as rejected, with the explanation as the reason. Same as the command feedback.check.";
    check.flags.insert(check.flags.end(), {{"title", "T", "Title of the report to check."},
                                           {"missing", "TEXT", "What the report says the engine lacks."},
                                           {"suggestion", "TEXT", "The change the report asks for."},
                                           {"entries", "", "Check the open entries of the project instead."},
                                           {"reject", "", "With --entries: reject the entries that fail the check."},
                                           {"json", "", "Machine-readable output."}});
    check.examples = {"factoria feedback check --title \"No fluid simulation\" --missing \"There is no liquid solver\"",
                      "factoria feedback check --entries --reject"};
    check.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.has("entries")) {
            const std::string path = feedback_path(resolve_project_dir(ctx, 0));
            Json out = Json::object({{"file", path}, {"checked", 0}, {"refused", Json::array()}});
            auto doc = load_feedback(path);
            if (!doc.ok()) return report_failure(ctx, doc.error().message, doc.error().hint.empty() ? "Create it with 'factoria feedback init'." : doc.error().hint);
            Json refused = Json::array();
            int checked = 0;
            for (const Json& e : (*doc)["entries"]) {
                if (e.value("status", std::string("open")) != "open") continue;
                ++checked;
                const ClaimResult r = check_feedback_entry_claim(e);
                if (r.refused()) refused.push_back(Json::object({{"id", e.value("id", std::string())}, {"title", e.value("title", std::string())}, {"reason", r.reason()}}));
            }
            std::vector<std::string> rejected;
            if (a.has("reject") && !refused.empty()) {
                auto rr = reject_claimed_feedback_file(path);
                if (!rr.ok()) return report_failure(ctx, rr.error().message, rr.error().hint);
                rejected = *rr;
            }
            out["checked"] = checked;
            out["refused"] = refused;
            out["rejected"] = rejected;
            if (a.has("json")) {
                print_json(ctx.out, out);
                return refused.empty() ? 0 : 1;
            }
            ctx.out << "Checked " << checked << " open entr" << (checked == 1 ? "y" : "ies") << ": " << refused.size() << " claim" << (refused.size() == 1 ? "" : "s")
                    << " something the engine already has.\n";
            for (const Json& r : refused)
                ctx.out << "  " << r.value("id", std::string()) << " " << r.value("title", std::string()) << "\n    " << r.value("reason", std::string()) << "\n";
            if (!rejected.empty()) ctx.out << "Rejected: " << join(rejected, ", ") << ".\n";
            else if (!refused.empty()) ctx.out << "Run again with --reject to close them as rejected.\n";
            return refused.empty() ? 0 : 1;
        }
        if (!a.has("title") || !a.has("missing"))
            throw UsageError("Give --title and --missing, or --entries.", "Usage: factoria feedback check --title T --missing TEXT");
        const ClaimResult claim = check_feedback_claim({a.str("title"), a.str("missing"), a.str("suggestion")}, nullptr, 5);
        if (a.has("json")) {
            print_json(ctx.out, claim.to_json());
            return claim.refused() ? 1 : 0;
        }
        if (claim.refused()) {
            ctx.out << claim.message() << "\n" << claim.hint() << "\n";
            return 1;
        }
        ctx.out << "Nothing in the report names something the engine has: it can be filed.\n";
        for (const Json& d : claim.related) ctx.out << "  related: " << d.value("path", std::string()) << ":" << d.value("line", 0) << "  " << d.value("heading", std::string()) << "\n";
        return 0;
    };

    Command discard = project_flag_cmd("discard", "Delete a closed entry (rejected, wont-fix, duplicate, fixed) from the file and its archive.");
    discard.usage = "[project] <id> [--json]";
    discard.maxPositional = 2;
    discard.details = "Only a closed entry can go, or an open one the engine developer refused (rejected): an open entry is a question for the engine\n"
                      "developers. The id is not given again. What was already sent to the engine developer stays with them. (`feedback delete`\n"
                      "is the server-side delete of the engine developer.) Same as the command feedback.delete.";
    discard.flags.push_back({"json", "", "Machine-readable output."});
    discard.examples = {"factoria feedback discard FB-0004"};
    discard.run = [](Context& ctx) {
        const auto& pos = ctx.args.positional();
        if (pos.empty()) throw UsageError("Missing entry id.", "Usage: factoria feedback discard [project] <id>");
        const std::string id = pos.back();
        const std::string dir = pos.size() > 1 ? absolute_path(pos[0]) : resolve_project_dir(ctx, 99);
        const std::string path = feedback_path(dir);
        auto r = delete_feedback_file(path, id);
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        share_discard(share_env(), path, {id});
        if (ctx.args.has("json")) print_json(ctx.out, Json::object({{"deleted", id}, {"title", r->value("title", std::string())}}));
        else ctx.out << "Deleted " << id << ": " << r->value("title", std::string()) << "\n";
        return 0;
    };

    Command validate = project_flag_cmd("validate", "Check ENGINE_FEEDBACK.json against the schema.");
    validate.usage = "[project] [--json]";
    validate.flags.push_back({"json", "", "Machine-readable output."});
    validate.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        std::string path = feedback_path(dir);
        auto doc = load_feedback(path);
        std::vector<SchemaError> errs;
        if (!doc.ok()) {
            errs.push_back({"", doc.error().message, doc.error().hint});
        } else {
            errs = validate_feedback(*doc);
        }
        if (ctx.args.has("json")) {
            Json arr = Json::array();
            for (const auto& e : errs) arr.push_back(Json::object({{"pointer", e.pointer}, {"message", e.message}, {"hint", e.hint}}));
            print_json(ctx.out, Json::object({{"ok", errs.empty()}, {"file", path}, {"errors", arr}}));
        } else if (errs.empty()) {
            ctx.out << "OK: " << path << "\n";
        } else {
            for (const auto& e : errs) ctx.out << path << e.pointer << ": " << e.message << (e.hint.empty() ? "" : " (hint: " + e.hint + ")") << "\n";
        }
        return errs.empty() ? 0 : 1;
    };

    Command collect;
    collect.name = "collect";
    collect.summary = "Aggregate many projects' feedback into a ranked roadmap (engine developers).";
    collect.usage = "<dirs-or-files...> [--out report.md|report.json]";
    collect.details = "Similar titles are grouped and ranked by occurrences x severity weight. Only open entries count unless --include-closed (which also reads the ENGINE_FEEDBACK.archive.json next to each file).";
    collect.maxPositional = -1;
    collect.flags = {{"out", "FILE", "Write the report here (.json => JSON, otherwise Markdown). Default: Markdown on stdout."},
                     {"format", "md|json", "Output format when not writing to a file with a clear extension."},
                     {"include-closed", "", "Also aggregate fixed/wont-fix/duplicate entries."},
                     {"similarity", "0..1", "Title similarity threshold for grouping (default 0.7)."}};
    collect.examples = {"factoria feedback collect examples/ --out roadmap.md", "factoria feedback collect games/a games/b/ENGINE_FEEDBACK.json --format json"};
    collect.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Give at least one project folder or ENGINE_FEEDBACK.json.", "Usage: factoria feedback collect <dirs...> --out report.md");
        std::vector<std::string> paths;
        for (const auto& p : a.positional()) paths.push_back(absolute_path(p));
        CollectOptions co;
        co.includeClosed = a.has("include-closed");
        co.similarity = a.number("similarity", co.similarity);
        auto rep = collect_feedback(paths, co);
        if (!rep.ok()) return report_failure(ctx, rep.error().message, rep.error().hint);
        std::string out = a.has("out") ? absolute_path(a.str("out")) : "";
        std::string fmt = a.str("format");
        if (fmt.empty()) fmt = ends_with(to_lower(out), ".json") ? "json" : "md";
        if (fmt != "md" && fmt != "json") throw UsageError("Unknown format '" + fmt + "'.", "Valid: md, json.");
        std::string text = fmt == "json" ? dump_json(rep->json) : rep->markdown();
        if (out.empty()) {
            ctx.out << text;
        } else {
            write_text_file(out, text);
            ctx.out << "Wrote " << out << " (" << rep->json.value("totalEntries", 0) << " entries from " << paths.size() << " source(s))\n";
        }
        return 0;
    };

    g.subs = {init, add, list, update, archive, check, discard, validate, collect};
    add_feedback_share_commands(g);
    for (auto& sub : make_feedback_admin_commands()) g.subs.push_back(std::move(sub));  // the engine developer's side
    return g;
}

Command make_docs_command() {
    Command g;
    g.name = "docs";
    g.summary = "Read the engine documentation embedded in this binary (works offline).";
    g.usage = "[name]";
    g.details = "'factoria docs' lists documents; 'factoria docs <name>' prints one (same as 'docs read'). The same docs are MCP resources.";
    g.maxPositional = 1;
    g.flags = {{"json", "", "Machine-readable output (with no name: the list)."}};
    g.examples = {"factoria docs", "factoria docs scripting", "factoria docs search \"collision events\"", "factoria docs list --json"};
    g.run = [](Context& ctx) {
        if (ctx.args.positional().empty()) {
            Json arr = Json::array();
            for (const auto& d : list_docs()) arr.push_back(Json::object({{"name", d.name}, {"path", d.path}, {"title", d.title}, {"bytes", d.bytes}}));
            if (ctx.args.has("json")) {
                print_json(ctx.out, arr);
                return 0;
            }
            for (const auto& d : list_docs()) ctx.out << d.name << "  -  " << d.title << "\n";
            return 0;
        }
        auto t = read_doc(ctx.args.pos(0));
        if (!t.ok()) {
            std::vector<std::string> names;
            for (const auto& d : list_docs()) names.push_back(d.name);
            return report_failure(ctx, t.error().message, t.error().hint.empty() ? fa::did_you_mean(ctx.args.pos(0), names) : t.error().hint);
        }
        ctx.out << *t;
        if (t->empty() || t->back() != '\n') ctx.out << "\n";
        return 0;
    };

    Command list;
    list.name = "list";
    list.summary = "List the documents.";
    list.flags = {{"json", "", "Machine-readable output."}};
    list.run = g.run;

    Command read;
    read.name = "read";
    read.summary = "Print one document.";
    read.usage = "<name>";
    read.maxPositional = 1;
    read.examples = {"factoria docs read scripting"};
    read.run = [run = g.run](Context& ctx) {
        if (ctx.args.positional().empty()) throw UsageError("Missing document name.", "See 'factoria docs list'.");
        return run(ctx);
    };

    Command search;
    search.name = "search";
    search.summary = "Search all documents.";
    search.usage = "<query...> [--max N] [--json]";
    search.maxPositional = -1;
    search.flags = {{"max", "N", "Maximum hits (default 8)."}, {"json", "", "Machine-readable output."}};
    search.examples = {"factoria docs search \"one-way platform\""};
    search.run = [](Context& ctx) {
        if (ctx.args.positional().empty()) throw UsageError("Missing query.", "Usage: factoria docs search <query>");
        std::string q = join(ctx.args.positional(), " ");
        auto hits = search_docs(q, static_cast<std::size_t>(std::max(1, ctx.args.integer("max", 8))));
        if (ctx.args.has("json")) {
            Json arr = Json::array();
            for (const auto& h : hits)
                arr.push_back(Json::object({{"doc", h.doc}, {"path", h.path}, {"heading", h.heading}, {"line", h.line}, {"score", h.score}, {"snippet", h.snippet}}));
            print_json(ctx.out, arr);
            return 0;
        }
        if (hits.empty()) ctx.out << "No matches for '" << q << "'.\n";
        for (const auto& h : hits) ctx.out << h.doc << ":" << h.line << "  [" << h.heading << "]\n    " << h.snippet << "\n";
        return 0;
    };

    g.subs = {list, read, search};
    return g;
}

}  // namespace fa::cli
