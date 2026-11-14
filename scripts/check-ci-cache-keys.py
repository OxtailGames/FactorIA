#!/usr/bin/env python3
"""Fails when one job's cache restore prefix also matches the key of ANOTHER job's cache.

    python3 scripts/check-ci-cache-keys.py [--workflows <dir>]      (default: .github/workflows)

GitHub's restore-keys is a prefix match that hands out the NEWEST cache whose key starts with the prefix. A job that
restores `ccache-Linux-linux-` therefore also gets the caches saved under `ccache-Linux-linux-asan-`, `-tsan-`, `-fuzz-`
and `-coverage-` (other compilers, other flags: 2% hits and a 55-minute build instead of 10). The rule checked here, for
every workflow file:

  - a "written" cache is an `actions/cache` or `actions/cache/save` step; its prefix is the key up to
    `${{ github.run_id }}` (a key without a run id is taken whole);
  - every restore-keys line of an `actions/cache` or `actions/cache/restore` step is a "restore prefix";
  - a restore prefix may EQUAL a written prefix (two jobs that share one cache on purpose: `bench` reads what `linux`
    saves), but it must not be a PROPER prefix of one: that is the collision.

`${{ runner.os }}` and `${{ matrix.<key> }}` are expanded for every combination of the job's matrix (flow or block
`include:` entries and `key: [a, b]` axes), `runs-on` included; anything else (`${{ env.X }}`...) counts as a wildcard `*`.
No dependency but Python 3: it runs in the `lint` job before anything is installed.
"""

import argparse
import itertools
import re
import sys
from pathlib import Path

RUN_ID = "\x00"  # stands for ${{ github.run_id }} while a key is expanded


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def is_blank_or_comment(line):
    s = line.strip()
    return not s or s.startswith("#")


def strip_comment(text):
    # YAML comments start at a '#' after a space; none of the values here contains one inside quotes.
    return re.sub(r"\s+#.*$", "", text).strip()


def unquote(text):
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] and text[0] in "'\"":
        return text[1:-1]
    return text


def parse_flow_map(text):
    """`{ os: linux, runner: ubuntu-24.04 }` -> dict (values with no commas or braces, which is all a matrix here uses)."""
    result = {}
    for part in text.strip().strip("{}").split(","):
        if ":" in part:
            key, value = part.split(":", 1)
            result[key.strip()] = unquote(strip_comment(value))
    return result


def parse_flow_list(text):
    return [unquote(p.strip()) for p in text.strip().strip("[]").split(",") if p.strip()]


class Job:
    def __init__(self, name, start, end):
        self.name, self.start, self.end = name, start, end
        self.runs_on = ""
        self.axes = {}  # key -> [values]
        self.includes = []  # [dict]


def find_jobs(lines):
    jobs, in_jobs = [], False
    for i, line in enumerate(lines):
        if re.match(r"^jobs:\s*$", line):
            in_jobs = True
            continue
        if in_jobs and re.match(r"^\S", line) and not is_blank_or_comment(line):
            in_jobs = False
        m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line) if in_jobs else None
        if m:
            if jobs:
                jobs[-1].end = i
            jobs.append(Job(m.group(1), i, len(lines)))
    return jobs


def parse_job(lines, job):
    block = range(job.start + 1, job.end)
    for i in block:
        m = re.match(r"^    runs-on:\s*(.+)$", lines[i])
        if m:
            job.runs_on = unquote(strip_comment(m.group(1)))
    # strategy.matrix, indent 6: `include:` list and `key: [a, b]` axes.
    for i in block:
        if not re.match(r"^      matrix:\s*$", lines[i]):
            continue
        j = i + 1
        while j < job.end and (is_blank_or_comment(lines[j]) or indent_of(lines[j]) > 6):
            line = lines[j]
            if is_blank_or_comment(line):
                j += 1
                continue
            ind = indent_of(line)
            if ind == 8 and re.match(r"^\s+include:\s*$", line):
                j += 1
                entry = None
                while j < job.end and (is_blank_or_comment(lines[j]) or indent_of(lines[j]) > 8):
                    item = lines[j]
                    if is_blank_or_comment(item):
                        j += 1
                        continue
                    dash = re.match(r"^\s+- (.*)$", item)
                    if dash and indent_of(item) == 10:
                        rest = dash.group(1).strip()
                        if rest.startswith("{"):
                            job.includes.append(parse_flow_map(rest.split("}")[0] + "}"))
                            entry = None
                        else:
                            entry = {}
                            job.includes.append(entry)
                            kv = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", rest)
                            if kv:
                                entry[kv.group(1)] = unquote(strip_comment(kv.group(2)))
                    elif entry is not None:
                        kv = re.match(r"^\s+([A-Za-z0-9_-]+):\s*(.*)$", item)
                        if kv:
                            entry[kv.group(1)] = unquote(strip_comment(kv.group(2)))
                    j += 1
                continue
            axis = re.match(r"^\s+([A-Za-z0-9_-]+):\s*(\[.*\])\s*(#.*)?$", line) if ind == 8 else None
            if axis:
                job.axes[axis.group(1)] = parse_flow_list(axis.group(2))
            j += 1
        break


def combinations(job):
    if job.axes:
        keys = sorted(job.axes)
        combos = [dict(zip(keys, values)) for values in itertools.product(*(job.axes[k] for k in keys))]
        return combos + [dict(inc) for inc in job.includes]
    return [dict(inc) for inc in job.includes] or [{}]


def os_name(runs_on, combo):
    runs_on = expand_text(runs_on, combo, "*")
    if runs_on.startswith("ubuntu"):
        return "Linux"
    if runs_on.startswith("windows"):
        return "Windows"
    if runs_on.startswith("macos"):
        return "macOS"
    return "*"


def expand_text(text, combo, runner_os):
    def sub(match):
        expr = match.group(1).strip()
        if expr == "runner.os":
            return runner_os
        if expr == "github.run_id":
            return RUN_ID
        m = re.fullmatch(r"matrix\.([A-Za-z0-9_-]+)", expr)
        if m and m.group(1) in combo:
            return combo[m.group(1)]
        return "*"

    return re.sub(r"\$\{\{(.*?)\}\}", sub, text)


def step_range(lines, uses_line, job):
    """First and last+1 line of the step that holds line `uses_line`."""
    start = uses_line
    while start > job.start and not re.match(r"^\s*- ", lines[start]):
        start -= 1
    dash = indent_of(lines[start])
    end = uses_line + 1
    while end < job.end and (is_blank_or_comment(lines[end]) or indent_of(lines[end]) > dash):
        end += 1
    return start, end


def collect(path, text):
    """-> (writers, readers): lists of (job, line number, prefix, source text)."""
    lines = text.splitlines()
    jobs = find_jobs(lines)
    for job in jobs:
        parse_job(lines, job)
    writers, readers = [], []
    for i, line in enumerate(lines):
        m = re.search(r"uses:\s*actions/cache(/save|/restore)?@", line)
        if not m or line.lstrip().startswith("#"):
            continue
        kind = (m.group(1) or "").strip("/")  # "", "save" or "restore"
        job = next((j for j in jobs if j.start < i < j.end), None)
        if job is None:
            continue
        start, end = step_range(lines, i, job)
        key_line, key_text, restore = None, None, []
        for k in range(start, end):
            km = re.match(r"^\s+key:\s*(.+)$", lines[k])
            if km and key_text is None:
                key_line, key_text = k, strip_comment(km.group(1))
            rm = re.match(r"^\s+restore-keys:\s*(.*)$", lines[k])
            if rm:
                inline = strip_comment(rm.group(1))
                if inline and inline not in ("|", ">", "|-", ">-"):
                    restore.append((k, inline))
                else:
                    k2 = k + 1
                    while k2 < end and indent_of(lines[k2]) > indent_of(lines[k]):
                        if not is_blank_or_comment(lines[k2]):
                            restore.append((k2, strip_comment(lines[k2])))
                        k2 += 1
        if key_text is None:
            continue
        for combo in combinations(job):
            runner_os = os_name(job.runs_on, combo)
            if kind in ("", "save"):
                prefix = expand_text(unquote(key_text), combo, runner_os).split(RUN_ID)[0]
                writers.append((job.name, key_line + 1, prefix, key_text))
            if kind in ("", "restore"):
                for k, text_ in restore:
                    prefix = expand_text(unquote(text_), combo, runner_os)
                    readers.append((job.name, k + 1, prefix, text_))
    return writers, readers


def could_be_prefix(prefix, key):
    """True when `prefix` can be the start of `key` ('*' in either one stands for any text)."""
    pattern = ".*".join(re.escape(part) for part in prefix.split("*"))
    return re.match(pattern, key) is not None or ("*" in key and re.match(re.escape(key.split("*")[0]), prefix) is not None)


def main():
    default_dir = Path(__file__).resolve().parent.parent / ".github" / "workflows"
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--workflows", type=Path, default=default_dir, help="the folder with the workflow files")
    args = parser.parse_args()

    files = sorted(args.workflows.glob("*.yml")) + sorted(args.workflows.glob("*.yaml"))
    if not files:
        print(f"error: no workflow file in {args.workflows}")
        return 2
    all_writers, all_readers = [], []
    for path in files:
        writers, readers = collect(path.name, path.read_text(encoding="utf-8"))
        all_writers += [(path.name,) + w for w in writers]
        all_readers += [(path.name,) + r for r in readers]
    if not all_writers:
        print(f"error: found no actions/cache step in {args.workflows}: has the layout of the workflows changed? Update this script.")
        return 2

    problems = {}  # (file, line, job, prefix, restore-keys text) of the reader -> the writers it would also match
    for rfile, rjob, rline, rprefix, rtext in all_readers:
        for wfile, wjob, wline, wprefix, wtext in all_writers:
            if wprefix == rprefix or not could_be_prefix(rprefix, wprefix):
                continue  # the same cache (shared on purpose), or no overlap
            problems.setdefault((rfile, rline, rjob, rprefix, rtext), set()).add((wfile, wline, wjob, wprefix))

    for (rfile, rline, rjob, rprefix, rtext), writers in sorted(problems.items()):
        print(f"{rfile}:{rline}: error: the job `{rjob}` restores caches by the prefix `{rprefix}` (restore-keys: {rtext}),")
        print("    which is also the start of the key of another job's cache:")
        for wfile, wline, wjob, wprefix in sorted(writers):
            print(f"      - `{wprefix}<run id>`, saved by the job `{wjob}` ({wfile}:{wline})")
        print("    GitHub gives restore-keys the NEWEST cache whose key starts with the prefix, so this job can restore one of those")
        print("    (another compiler or other flags: almost no hits and a cold build).")
        print("    Fix: rename one of the caches so that neither prefix starts with the other (ccache-<os>-gcc- next to")
        print("    ccache-<os>-linux-asan-, not ccache-<os>-linux- next to it), in the `key` AND the `restore-keys` of every job")
        print("    that uses it. Two jobs may share one cache only when their prefixes are identical.")
    if problems:
        print(f"\n{len(problems)} restore prefix(es) that match another cache.")
        return 1
    names = sorted({w[3] for w in all_writers})
    print(f"ok: {len(all_writers)} cache keys and {len(all_readers)} restore prefixes in {len(files)} workflow file(s), no restore prefix is the start of another cache's key")
    for name in names:
        print("    " + name.replace(RUN_ID, "<run id>"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
