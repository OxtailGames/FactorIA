#!/usr/bin/env python3
"""Runs one shard of a ctest preset, so a slow suite can be split across CI machines.

    python scripts/ctest_shard.py --preset windows-release --shard 1 --of 3 [-- <more ctest arguments>]
    python scripts/ctest_shard.py --self-test

Every machine lists the same tests (`ctest --show-only=json-v1`) and splits them the same way, so each test runs in
exactly one shard, a new test included (the script checks that before it runs anything). The split balances the expected
time of each shard: the longest tests are placed first, each into the shard with the least time so far. The times are in
the tables below, one per preset, measured on GitHub's runners. A test that is not listed counts DEFAULT_SECONDS: the
split stays balanced enough, and an update of a table is only needed when a shard becomes much slower than the others.
A DISABLED test (an example test in a Debug build) runs nothing and counts 0.

`--self-test` needs no build: it splits a made-up list (the tables' tests, unlisted and disabled ones) into 1 to 6 shards
and fails unless every split is disjoint, complete and the same on every call. The lint job runs it.

A preset that lists no test, or a shard that gets none (more shards than tests), is an error: a machine that ran nothing
must not be green. A table that names a test the suite does not have (renamed, removed) gets a warning.

ctest adds the setup and cleanup tests of a selected test's fixtures by itself (FIXTURES_REQUIRED), as with any -R.
"""

import argparse
import json
import re
import subprocess
import sys

DEFAULT_SECONDS = 2.0

# Seconds per test, from the green CI run 43625236861 (main at 0fbeb5c1, 2026-11-14), tests of 5 s or more. Refresh them from
# the "Test #n: name ... Passed x sec" lines of a newer green run when a shard gets much slower than the others.

# ESTIMATES: the green run measured `tooling` as one test (230.1 s on Windows, 1135.1 s under ASan). It is now five ctest
# entries (tools/common/CMakeLists.txt), each with its share of that time, the shares measured on a Mac (19.7, 19.6, 19.6,
# 20.0 and 19.8 s of 98.7 s per entry). tooling_split_check takes under a second and counts the default. The next green CI run
# of this split gives the real numbers: replace tooling_1 ... tooling_5 with them.

# Preset windows-release: the three `Windows (... tests n/3)` jobs, one test at a time (a plain sum is the time of a shard).
WINDOWS_SECONDS = {
    "editor_autotest_5": 161.0,
    "mcp": 129.0,
    "editor_autotest_3": 95.1,
    "physics": 94.7,
    "editor_autotest_1": 80.1,
    "example_larkspur-lodge_test": 67.0,
    "editor_autotest_4": 52.9,
    "example_burrow-brigade_test": 48.1,
    "tooling_4": 46.6,
    "tooling_5": 46.2,
    "tooling_1": 45.9,
    "tooling_2": 45.7,
    "tooling_3": 45.7,
    "example_tidewater-market_test": 45.3,
    "example_clockwork-courier_test": 42.5,
    "editor_autotest_2": 40.3,
    "example_larkspur-lodge_perf": 36.6,
    "runtime": 34.5,
    "ltc_tables_up_to_date": 30.2,
    "scene": 27.5,
    "audio": 24.6,
    "script": 23.7,
    "authoring": 20.0,  # ESTIMATE (new test, split from runtime): replace from the next green run
    "editor": 19.6,
    "example_kindlewatch_perf": 16.6,
    "core": 15.2,
    "ai": 12.2,
    "cli_integration": 11.2,
    "example_clockwork-courier_graphics_same_hash": 10.6,
    "example_tidewater-market_perf": 10.4,
    "example_burrow-brigade_perf": 9.1,
    "cli": 8.1,
    # ESTIMATE (M79 P1d, WARP DXR with the debug layer), still no measurement: no Windows CI run has timed this test yet (the
    # shard summary of the first green windows-release run names its seconds; copy them here and drop this note). The shards
    # stay balanced within a few seconds whatever it takes, so a wrong estimate costs nothing but a slightly uneven split.
    "render_d3d12_raytracing": 8.0,
    "render": 7.8,
    "example_tidewater-market-title_perf": 7.1,
    "example_kindlewatch_test": 7.0,
    "example_tidewater-market-game_perf": 6.3,
    "cli_mcp_update": 5.8,
    "example_tidewater-market_graphics_same_hash": 5.7,
    "editor_autotest_welcome": 5.3,
}

# Preset linux-asan: the job `Linux (Clang, ASan + UBSan)` with `ctest --parallel 4`, so these are wall times of tests that
# shared the 4 vCPUs with others (more than a test takes alone), and a shard's time is about its sum / 4, never below its
# longest test (JOBS).
ASAN_SECONDS = {
    "runtime": 315.4,
    "editor_autotest_5": 233.3,
    "tooling_4": 230.0,
    "tooling_5": 227.7,
    "tooling_1": 226.6,
    "tooling_2": 225.4,
    "tooling_3": 225.4,
    "editor_autotest_1": 171.3,
    "audio": 165.5,
    "editor_autotest_3": 153.2,
    "authoring": 100.0,  # ESTIMATE (new test, split from runtime): replace from the next green run
    "editor": 137.1,
    "editor_autotest_2": 135.6,
    "scene": 122.2,
    "cli_integration": 110.5,
    "editor_autotest_4": 85.8,
    "core": 65.2,
    "cli": 63.9,
    "script": 61.9,
    "ai": 51.4,
    "physics": 49.2,
    "render": 34.9,
    "agent_cost_script": 18.8,
    "mcp": 15.9,
    "cli_larkspur_ship": 12.9,
    "cli_mcp_update": 11.6,
    "cli_dap": 9.5,
    "cli_plugin": 7.3,
    "example_kindlewatch_validate": 6.7,
    "cli_player_replay": 6.4,
    "editor_autotest_welcome": 5.2,
    "example_clockwork-courier_validate": 5.0,
}

# The table of a preset and how many of its tests run at once. A preset that is not here counts DEFAULT_SECONDS per test.
SECONDS = {"windows-release": WINDOWS_SECONDS, "linux-asan": ASAN_SECONDS}
JOBS = {"windows-release": 1, "linux-asan": 4}


def list_tests(preset):
    """The tests of a ctest preset as [(name, disabled)]."""
    out = subprocess.run(["ctest", "--preset", preset, "--show-only=json-v1"], check=True, capture_output=True, text=True)
    tests = []
    for t in json.loads(out.stdout)["tests"]:
        disabled = any(p.get("name") == "DISABLED" and p.get("value") in (True, "ON", "1", "TRUE", "true")
                       for p in t.get("properties", []))
        tests.append((t["name"], disabled))
    return tests


def cost(name, seconds, disabled):
    return 0.0 if name in disabled else seconds.get(name, DEFAULT_SECONDS)


def split(names, count, seconds, disabled=frozenset()):
    """Shards (lists of names) and their summed costs: the longest first, each into the shard with the least so far."""
    shards = [[] for _ in range(count)]
    totals = [0.0] * count
    for name in sorted(names, key=lambda n: (-cost(n, seconds, disabled), n)):
        i = min(range(count), key=lambda k: (totals[k], k))
        shards[i].append(name)
        totals[i] += cost(name, seconds, disabled)
    return shards, totals


def estimate(tests, seconds, disabled, jobs):
    """Expected minutes of a shard that runs `jobs` tests at once: its sum over jobs, never below its longest test."""
    costs = [cost(n, seconds, disabled) for n in tests]
    return max(sum(costs) / jobs, max(costs, default=0.0)) / 60


def check_partition(names, shards):
    """Raises ValueError unless the shards are disjoint and together hold exactly `names`."""
    seen = {}
    for i, shard in enumerate(shards, start=1):
        for n in shard:
            if n in seen:
                raise ValueError(f"test {n!r} is in shard {seen[n]} and in shard {i}")
            seen[n] = i
    missing = sorted(set(names) - set(seen))
    extra = sorted(set(seen) - set(names))
    if missing or extra:
        raise ValueError(f"the shards miss {missing} and add {extra}")
    if len(seen) != len(names):
        raise ValueError("the test list has a name twice")


def exact_regex(names):
    # CMake regular expressions: escape every character that is not a letter, digit, '_' or '-'.
    return "^(" + "|".join(re.sub(r"([^A-Za-z0-9_-])", r"\\\1", n) for n in names) + ")$"


def stale_names(names, seconds):
    """The names of a table that the suite does not have: a renamed or removed test, whose time no shard counts."""
    return sorted(set(seconds) - set(names))


def self_test():
    listed = sorted(set(WINDOWS_SECONDS) | set(ASAN_SECONDS))
    names = listed + [f"unlisted_{i}" for i in range(25)] + [f"example_disabled_{i}" for i in range(15)]
    disabled = frozenset(n for n in names if n.startswith("example_disabled_"))
    for preset, table in list(SECONDS.items()) + [("unknown-preset", {})]:
        for count in range(1, 7):
            shards, totals = split(names, count, table, disabled)
            check_partition(names, shards)
            again, _ = split(list(reversed(names)), count, table, disabled)
            if [sorted(s) for s in shards] != [sorted(s) for s in again]:
                raise ValueError(f"{preset}: the split of {count} shards depends on the order of the list")
            if abs(sum(totals) - sum(cost(n, table, disabled) for n in names)) > 1e-6:
                raise ValueError(f"{preset}: the shard times do not add up")
    # A test that is not in the table counts DEFAULT_SECONDS, a disabled one 0.
    if cost("unlisted_0", WINDOWS_SECONDS, disabled) != DEFAULT_SECONDS or cost("example_disabled_0", {}, disabled) != 0:
        raise ValueError("the cost of an unlisted or a disabled test is wrong")
    # The regex of a shard selects exactly its tests, also when a name has characters that mean something in a
    # regular expression: an unescaped '.' would select `a_b` for `a.b`, an unescaped '+' or '(' nothing at all.
    odd = ["a.b", "a_b", "a+b", "aab", "ab", "c(1)", "c1", "d[x]", "dx", "e*", "e", "f|g", "f", "g", "h$", "^h",
           "i\\j", "ij"]
    for all_names in (names, names + odd):
        shards, _ = split(all_names, 3, WINDOWS_SECONDS, disabled)
        check_partition(all_names, shards)
        for shard in shards:
            # Python reads `\x` for a punctuation character as CMake does: that character itself.
            rx = re.compile(exact_regex(shard))
            if sorted(n for n in all_names if rx.search(n)) != sorted(shard):
                raise ValueError("the regex of a shard does not select exactly its tests")
    if stale_names(["a", "b"], {"a": 1.0, "gone": 2.0}) != ["gone"] or stale_names(["a"], {}) != []:
        raise ValueError("stale_names does not name the table entries the suite lacks")
    try:
        check_partition(names, [names[:5], names[4:]])
    except ValueError:
        pass
    else:
        raise ValueError("check_partition accepts shards that share a test")
    print(f"ctest_shard self-test ok: {len(names)} tests, 1 to 6 shards, {len(SECONDS) + 1} tables")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--self-test", action="store_true", help="check the split on a made-up test list and exit")
    parser.add_argument("--preset", help="the ctest preset (CMakePresets.json)")
    parser.add_argument("--shard", type=int, help="which shard to run, 1 to --of")
    parser.add_argument("--of", type=int, help="how many shards the suite is split into")
    parser.add_argument("ctest_args", nargs=argparse.REMAINDER, help="more ctest arguments, after --")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if args.preset is None or args.shard is None or args.of is None:
        parser.error("--preset, --shard and --of are required")
    if args.of < 1 or not 1 <= args.shard <= args.of:
        parser.error(f"--shard must be between 1 and --of ({args.of}); got {args.shard}")
    extra = args.ctest_args[1:] if args.ctest_args[:1] == ["--"] else args.ctest_args

    tests = list_tests(args.preset)
    names = [n for n, _ in tests]
    if not names:
        print(f"error: `ctest --preset {args.preset} --show-only=json-v1` lists no test, so this machine would run "
              "nothing and report success. Configure the preset first (the tests are registered at configure time).",
              file=sys.stderr)
        return 1
    disabled = frozenset(n for n, d in tests if d)
    seconds = SECONDS.get(args.preset, {})
    jobs = JOBS.get(args.preset, 1)
    shards, _ = split(names, args.of, seconds, disabled)
    check_partition(names, shards)
    for i, tests_i in enumerate(shards, start=1):
        mark = "  <- this machine" if i == args.shard else ""
        print(f"shard {i}/{args.of}: {len(tests_i)} tests, about {estimate(tests_i, seconds, disabled, jobs):.1f} min{mark}")
    mine = shards[args.shard - 1]
    stale = stale_names(names, seconds)
    if stale:
        # Not an error: a pull request that renames or removes a test must still run. The split stays complete (the
        # new name counts DEFAULT_SECONDS), only less balanced.
        print(f"warning: the {args.preset} table of scripts/ctest_shard.py names tests the suite does not have: "
              f"{', '.join(stale)}. Remove them from the table, or rename them there if the tests were renamed.")
    if not mine:
        print(f"error: shard {args.shard} of {args.of} has no test: the suite has only {len(names)}. A machine that "
              "runs nothing must not report success: lower --of (and the job's matrix) to at most the number of tests.",
              file=sys.stderr)
        return 1
    print("tests: " + " ".join(mine), flush=True)
    return subprocess.run(["ctest", "--preset", args.preset, "-R", exact_regex(mine)] + extra).returncode


if __name__ == "__main__":
    sys.exit(main())
