#!/usr/bin/env bash
# Coverage report per module from a build configured with -DFA_COVERAGE=ON, after ctest ran (docs/BUILDING.md, "Coverage").
#
#   scripts/coverage-report.sh <build-dir> [out-dir]      out-dir defaults to <build-dir>/coverage/report
#
# Merges <build-dir>/coverage/raw/*.profraw (llvm-profdata), reads every fa_test_* program plus factoria and fa_editor_autotest
# of the build dir (llvm-cov export, one merged view), and writes to out-dir: coverage.md (table per module), coverage.json,
# html/index.html. Modules by path: engine/<m>/ and tools/<m>/ (tools/common is `tooling`); tests, external/ and generated
# files are not counted. Needs python3 and LLVM's llvm-cov + llvm-profdata (xcrun on macOS, llvm-cov-<ver> or llvm-cov on Linux;
# LLVM_COV / LLVM_PROFDATA override). With GITHUB_STEP_SUMMARY set, the table is appended to it too.
set -euo pipefail

build=${1:-}
[ -n "$build" ] && [ -d "$build" ] || { echo "usage: $0 <build-dir> [out-dir]  (the build dir of a -DFA_COVERAGE=ON build that ctest ran in)" >&2; exit 2; }
build=$(cd "$build" && pwd)
out=${2:-$build/coverage/report}
mkdir -p "$out"
out=$(cd "$out" && pwd)
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

find_llvm() {  # $1 = llvm-cov | llvm-profdata
    local tool=$1 c
    if [ "$(uname)" = Darwin ] && c=$(xcrun -f "$tool" 2>/dev/null); then echo "$c"; return; fi
    if command -v "$tool" >/dev/null 2>&1; then command -v "$tool"; return; fi
    c=$(ls /usr/bin/"$tool"-[0-9]* /usr/lib/llvm-*/bin/"$tool" 2>/dev/null | sort -V | tail -n 1 || true)
    if [ -n "$c" ]; then echo "$c"; fi
}
cov=${LLVM_COV:-$(find_llvm llvm-cov)}
prof=${LLVM_PROFDATA:-$(find_llvm llvm-profdata)}
if [ -z "$cov" ] || [ -z "$prof" ]; then
    echo "llvm-cov / llvm-profdata not found. Install LLVM (Linux: sudo apt-get install llvm; macOS: Xcode command line tools) or set LLVM_COV and LLVM_PROFDATA." >&2
    exit 2
fi

find "$build/coverage/raw" -name '*.profraw' -size +0 > "$out/profraw.list" 2>/dev/null || true
if [ ! -s "$out/profraw.list" ]; then
    echo "No .profraw files in $build/coverage/raw. Configure with -DFA_COVERAGE=ON, build, and run ctest in $build first." >&2
    exit 1
fi
"$prof" merge -sparse -f "$out/profraw.list" -o "$out/all.profdata"

# Programs that carry the engine: the test programs, the CLI and the editor autotest.
objs=()
while IFS= read -r f; do objs+=("$f"); done < <(find "$build" -type f \( -name 'fa_test_*' -o -name factoria -o -name fa_editor_autotest \) \
    -not -path '*/CMakeFiles/*' -not -name '*.*' | sort)
if [ ${#objs[@]} -eq 0 ]; then
    echo "No fa_test_* / factoria / fa_editor_autotest program in $build." >&2
    exit 1
fi
args=("${objs[0]}")
for ((i = 1; i < ${#objs[@]}; i++)); do args+=(-object "${objs[$i]}"); done

ignore='(/external/|/_deps/|/tests?/|/test_tools/|/tools/fuzz/|/tools/bench/|/usr/|/Applications/|/generated/)'
"$cov" export -instr-profile="$out/all.profdata" -ignore-filename-regex="$ignore" "${args[@]}" > "$out/llvm-export.json"
"$cov" show -format=html -output-dir="$out/html" -instr-profile="$out/all.profdata" -ignore-filename-regex="$ignore" \
    "${args[@]}" > /dev/null 2>&1 || echo "warning: the HTML report could not be written" >&2

python3 -I - "$out" "$root" <<'PY'
import json, os, re, sys
out, root = sys.argv[1], os.path.realpath(sys.argv[2])
order = ["core", "scene", "platform", "render", "physics", "audio", "ui", "services", "script", "runtime", "tooling", "mcp", "dap", "ai", "editor", "cli"]
kinds = ("lines", "functions", "regions")
acc = {m: {"files": 0, **{k: [0, 0] for k in kinds}} for m in order}
for f in json.load(open(os.path.join(out, "llvm-export.json")))["data"][0]["files"]:
    rel = os.path.relpath(os.path.realpath(f["filename"]), root).replace(os.sep, "/")
    m = re.match(r"engine/([^/]+)/", rel) or re.match(r"tools/([^/]+)/", rel)
    if not m:
        continue
    mod = "tooling" if m.group(1) == "common" else m.group(1)
    if mod not in acc:
        continue
    a = acc[mod]
    a["files"] += 1
    for k in kinds:
        a[k][0] += f["summary"][k]["covered"]
        a[k][1] += f["summary"][k]["count"]

def pct(c):
    return round(100.0 * c[0] / c[1], 1) if c[1] else None

def cell(c):
    return f"{pct(c):.1f}% ({c[0]}/{c[1]})" if c[1] else "-"

total = {k: [0, 0] for k in kinds}
res = {"modules": {}}
rows = ["| Module | Files | Lines | Functions | Regions |", "|---|---:|---:|---:|---:|"]
for m in order:
    a = acc[m]
    res["modules"][m] = {"files": a["files"], **{k: {"covered": a[k][0], "count": a[k][1], "percent": pct(a[k])} for k in kinds}}
    for k in kinds:
        total[k][0] += a[k][0]
        total[k][1] += a[k][1]
    rows.append(f"| {m} | {a['files']} | {cell(a['lines'])} | {cell(a['functions'])} | {cell(a['regions'])} |")
rows.append("| **total** | | " + " | ".join(f"**{cell(total[k])}**" for k in kinds) + " |")
res["total"] = {k: {"covered": v[0], "count": v[1], "percent": pct(v)} for k, v in total.items()}
table = "## Coverage per module\n\n" + "\n".join(rows) + "\n"
open(os.path.join(out, "coverage.md"), "w").write(table)
json.dump(res, open(os.path.join(out, "coverage.json"), "w"), indent=2)
print(table)
PY
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then cat "$out/coverage.md" >> "$GITHUB_STEP_SUMMARY"; fi
echo "Coverage report: $out (coverage.md, coverage.json, html/index.html)"
