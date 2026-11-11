#!/usr/bin/env python3
"""What a Claude Code session and its subagents really cost. See docs/BUILDING.md, "What the agents cost".

    python3 scripts/agent-usage.py                 # the 5 sessions of this checkout that changed last
    python3 scripts/agent-usage.py -n 20           # the last 20
    python3 scripts/agent-usage.py 085261c6        # one session (an id or the start of one); several ids are fine
    python3 scripts/agent-usage.py --agents <id>   # plus one line per subagent, the most expensive first

It reads the transcripts Claude Code keeps in ~/.claude/projects/<checkout path with dashes>/ (--dir names another
folder) and adds up the token usage of every model call: the main session's and each subagent's
(<session>/subagents/agent-*.jsonl). Nothing is sent anywhere.

A model call sends the whole context again, so a session costs its calls times its context, not the tokens it wrote:
the number the Agent tool reports for a subagent is not its cost. "units" turns one call's usage into input tokens of
its model: input + 1.25 x cache writes (2 x for the one-hour cache) + 0.1 x cache reads + 5 x output. A unit of a
bigger model costs more than a unit of a smaller one, so compare rows of the same model.

Columns: calls (model calls, one per turn of the agent), ctx (the context of a call: median and largest), compact (how
many times the context was summarized because it filled up: each one loses details and writes the cache again),
rewrites (calls that wrote most of their context to the cache again: after a summary, or after a pause longer than
the cache keeps it).
"""
import argparse
import datetime
import glob
import json
import os
import re
import sys


def parse_time(text):
    try:
        return datetime.datetime.fromisoformat(text.replace("Z", "+00:00"))
    except (AttributeError, ValueError):
        return None


def read_transcript(path):
    """Returns (calls, title): calls are (time, model, usage) of each model call, in order.

    A streamed answer is written as several lines with the same message id; the last one carries the final usage.
    """
    calls, order, title = {}, [], ""
    try:
        handle = open(path, encoding="utf-8", errors="replace")
    except OSError:
        return [], ""
    with handle:
        for line in handle:
            if '"usage"' not in line and "Title" not in line:
                continue
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if not isinstance(entry, dict):
                continue
            title = entry.get("customTitle") or entry.get("aiTitle") or title
            message = entry.get("message")
            if entry.get("type") != "assistant" or not isinstance(message, dict) or not message.get("usage"):
                continue
            if message.get("model") == "<synthetic>":
                continue
            key = message.get("id") or entry.get("uuid")
            if key not in calls:
                order.append(key)
            calls[key] = (parse_time(entry.get("timestamp")), message.get("model") or "?", message["usage"])
    return [calls[key] for key in order], title


def context_of(usage):
    return (usage.get("input_tokens") or 0) + (usage.get("cache_creation_input_tokens") or 0) \
        + (usage.get("cache_read_input_tokens") or 0)


def summarize(calls):
    total = {"calls": len(calls), "in": 0, "write": 0, "read": 0, "out": 0, "units": 0.0, "compact": 0, "rewrites": 0,
             "contexts": [], "minutes": 0.0}
    previous = 0
    for _, _, usage in calls:
        fresh = usage.get("input_tokens") or 0
        write = usage.get("cache_creation_input_tokens") or 0
        read = usage.get("cache_read_input_tokens") or 0
        out = usage.get("output_tokens") or 0
        split = usage.get("cache_creation") or {}
        hour = min(split.get("ephemeral_1h_input_tokens") or 0, write)
        context = fresh + write + read
        total["in"] += fresh
        total["write"] += write
        total["read"] += read
        total["out"] += out
        total["units"] += fresh + 1.25 * (write - hour) + 2.0 * hour + 0.1 * read + 5.0 * out
        total["contexts"].append(context)
        if previous > 50000 and context < previous * 0.6:
            total["compact"] += 1
        if write > 40000 and write > context * 0.5:
            total["rewrites"] += 1
        previous = context
    times = [time for time, _, _ in calls if time]
    if len(times) > 1:
        total["minutes"] = (max(times) - min(times)).total_seconds() / 60.0
    return total


def add(total, other):
    for key in ("calls", "in", "write", "read", "out", "units", "compact", "rewrites", "minutes"):
        total[key] += other[key]
    total["contexts"] += other["contexts"]


def short(count):
    if count >= 999500:
        return "%.1fM" % (count / 1e6)
    if count >= 1000:
        return "%.0fk" % (count / 1e3)
    return "%d" % count


def columns(total):
    contexts = sorted(total["contexts"]) or [0]
    return "calls %5d  ctx %4s/%4s  in %5s  write %6s  read %6s  out %5s  units %6s  compact %2d  rewrites %2d" % (
        total["calls"], short(contexts[len(contexts) // 2]), short(contexts[-1]), short(total["in"]),
        short(total["write"]), short(total["read"]), short(total["out"]), short(total["units"]), total["compact"],
        total["rewrites"])


def main_model(calls):
    counts = {}
    for _, model, _ in calls:
        counts[model] = counts.get(model, 0) + 1
    return max(counts, key=counts.get) if counts else "?"


def report(folder, session, show_agents):
    calls, title = read_transcript(os.path.join(folder, session + ".jsonl"))
    if not calls:
        return False
    times = [time for time, _, _ in calls if time]
    span = ""
    if times:
        span = "%s -> %s" % (min(times).astimezone().strftime("%Y-%m-%d %H:%M"),
                             max(times).astimezone().strftime("%Y-%m-%d %H:%M"))
    print("%s  %s  %s" % (session, span, title))
    main = summarize(calls)
    print("  %-42s %s" % ("main  " + main_model(calls), columns(main)))

    agents = []
    for path in sorted(glob.glob(os.path.join(folder, session, "subagents", "agent-*.jsonl"))):
        agent_calls, _ = read_transcript(path)
        if not agent_calls:
            continue
        meta = {}
        try:
            with open(path[:-len(".jsonl")] + ".meta.json", encoding="utf-8") as handle:
                meta = json.load(handle)
        except (OSError, ValueError):
            pass
        agents.append((summarize(agent_calls), str(meta.get("agentType") or "?"), main_model(agent_calls),
                       str(meta.get("description") or "")))
    if not agents:
        print()
        return True

    everything = summarize([])
    groups = {}
    for total, kind, model, _ in agents:
        add(everything, total)
        group = groups.setdefault((kind, model), summarize([]))
        add(group, total)
        group["count"] = group.get("count", 0) + 1
    share = 100.0 * everything["units"] / max(1.0, everything["units"] + main["units"])
    print("  %-42s %s" % ("subagents (%d, %.0f%% of the units)" % (len(agents), share), columns(everything)))
    for (kind, model), total in sorted(groups.items(), key=lambda item: -item[1]["units"]):
        print("    %-40s %s" % ("%d x %s  %s" % (total["count"], kind, model), columns(total)))
    if show_agents:
        print("  each subagent:")
        for total, kind, model, description in sorted(agents, key=lambda agent: -agent[0]["units"]):
            print("    %-40s %s  %4.0f min  %s" % ("%s  %s" % (kind, model), columns(total), total["minutes"],
                                                 description[:60]))
    print()
    return True


def main():
    parser = argparse.ArgumentParser(description="Token usage of Claude Code sessions and their subagents.",
                                     epilog="Columns and units: the comment at the top of this file.")
    parser.add_argument("sessions", nargs="*", help="session ids, or the start of one (default: the last sessions)")
    parser.add_argument("-n", type=int, default=5, help="how many of the last sessions to show (default 5)")
    parser.add_argument("--agents", action="store_true", help="one line per subagent, the most expensive first")
    parser.add_argument("--dir", help="the folder with the transcripts (default: this checkout's, in ~/.claude)")
    args = parser.parse_args()

    folder = args.dir
    if not folder:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        home = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
        folder = os.path.join(home, "projects", re.sub(r"[^A-Za-z0-9]", "-", root))
    if not os.path.isdir(folder):
        print("error: no transcripts folder at %s" % folder, file=sys.stderr)
        print("hint: Claude Code names it after the folder a session was started in; pass it with --dir "
              "(ls ~/.claude/projects)", file=sys.stderr)
        return 2

    known = sorted(glob.glob(os.path.join(folder, "*.jsonl")), key=os.path.getmtime, reverse=True)
    known = [os.path.basename(path)[:-len(".jsonl")] for path in known]
    if args.sessions:
        chosen = []
        for wanted in args.sessions:
            found = [session for session in known if session.startswith(wanted)]
            if len(found) != 1:
                print("error: %s session starts with '%s' in %s" % ("more than one" if found else "no", wanted, folder),
                      file=sys.stderr)
                print("hint: the last ones: %s" % ", ".join(session[:8] for session in known[:8]), file=sys.stderr)
                return 2
            chosen.append(found[0])
    else:
        chosen = known[:max(1, args.n)]
    shown = 0
    for session in chosen:
        shown += report(folder, session, args.agents)
    if not shown:
        print("error: no model call found in the chosen transcripts of %s" % folder, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
