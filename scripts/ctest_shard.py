#!/usr/bin/env python3
"""Runs one shard of a ctest preset, so a slow suite can be split across CI machines.

    python scripts/ctest_shard.py --preset windows-release --shard 1 --of 3 [-- <more ctest arguments>]

Every machine lists the same tests (`ctest --show-only=json-v1`) and splits them the same way, so each test runs in
exactly one shard, a new test included. The split balances the expected time of each shard: the longest tests are
placed first, each into the shard with the least time so far. The times below were measured on GitHub's windows-2022
runner (CI run 42291047442, one test at a time). A test that is not listed counts DEFAULT_SECONDS: the split stays
balanced enough, and an update of the table is only needed when a shard becomes much slower than the others.

ctest adds the setup and cleanup tests of a selected test's fixtures by itself (FIXTURES_REQUIRED), as with any -R.
"""

import argparse
import json
import re
import subprocess
import sys

DEFAULT_SECONDS = 2.0

SECONDS = {
    "tooling": 232.4,
    "runtime": 191.0,
    "editor_autotest_5": 163.7,
    "example_larkspur-lodge_test": 156.9,
    "editor_autotest_1": 112.8,
    "editor_autotest_3": 92.4,
    "example_clockwork-courier_test": 89.0,
    "example_tidewater-market_test": 77.0,
    "example_burrow-brigade_test": 66.1,
    "editor_autotest_4": 62.1,
    "audio": 61.9,
    "cli_integration": 60.6,
    "editor_autotest_2": 48.0,
    "editor": 47.4,
    "example_larkspur-lodge_perf": 44.2,
    "scene": 32.8,
    "example_kindlewatch_perf": 28.0,
    "example_kindlewatch_test": 23.8,
    "cli": 23.7,
    "script": 21.9,
    "example_tidewater-market_perf": 12.4,
    "example_burrow-brigade_perf": 11.5,
    "example_lantern-keep_test": 11.3,
    "ai": 8.7,
    "example_tidewater-market-title_perf": 7.9,
    "render": 7.7,
    "example_gem-roller_perf": 7.5,
    "example_tidewater-market-game_perf": 7.1,
    "cli_mcp_update": 6.7,
    "editor_autotest_welcome": 6.1,
}


def list_tests(preset):
    out = subprocess.run(["ctest", "--preset", preset, "--show-only=json-v1"], check=True, capture_output=True, text=True)
    return [t["name"] for t in json.loads(out.stdout)["tests"]]


def split(names, count):
    shards = [[] for _ in range(count)]
    totals = [0.0] * count
    for name in sorted(names, key=lambda n: (-SECONDS.get(n, DEFAULT_SECONDS), n)):
        i = min(range(count), key=lambda k: (totals[k], k))
        shards[i].append(name)
        totals[i] += SECONDS.get(name, DEFAULT_SECONDS)
    return shards, totals


def exact_regex(names):
    # CMake regular expressions: escape every character that is not a letter, digit, '_' or '-'.
    return "^(" + "|".join(re.sub(r"([^A-Za-z0-9_-])", r"\\\1", n) for n in names) + ")$"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--preset", required=True, help="the ctest preset (CMakePresets.json)")
    parser.add_argument("--shard", type=int, required=True, help="which shard to run, 1 to --of")
    parser.add_argument("--of", type=int, required=True, help="how many shards the suite is split into")
    parser.add_argument("ctest_args", nargs=argparse.REMAINDER, help="more ctest arguments, after --")
    args = parser.parse_args()
    if args.of < 1 or not 1 <= args.shard <= args.of:
        parser.error(f"--shard must be between 1 and --of ({args.of}); got {args.shard}")
    extra = args.ctest_args[1:] if args.ctest_args[:1] == ["--"] else args.ctest_args

    names = list_tests(args.preset)
    shards, totals = split(names, args.of)
    for i, (tests, total) in enumerate(zip(shards, totals), start=1):
        mark = "  <- this machine" if i == args.shard else ""
        print(f"shard {i}/{args.of}: {len(tests)} tests, about {total / 60:.1f} min{mark}")
    mine = shards[args.shard - 1]
    if not mine:
        print(f"shard {args.shard} has no test: the suite has only {len(names)}")
        return 0
    print("tests: " + " ".join(mine), flush=True)
    return subprocess.run(["ctest", "--preset", args.preset, "-R", exact_regex(mine)] + extra).returncode


if __name__ == "__main__":
    sys.exit(main())
