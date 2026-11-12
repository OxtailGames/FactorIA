#!/usr/bin/env bash
#
# Runs the libFuzzer targets of a build made with -DFA_FUZZ=ON (Clang), each for a number of seconds, over a copy of its
# corpus. The CI job `linux-fuzz` and a developer use the same script.
#
#   tools/fuzz/run.sh <build-dir> [seconds-per-target] [target...]
#
#   tools/fuzz/run.sh build/fuzz 60            # every target, one minute each
#   tools/fuzz/run.sh build/fuzz 600 pak json  # two targets, ten minutes each
#
# New inputs go to <build-dir>/fuzz-work/<target>/ (the repository's corpus is never written: copy a find you want to keep
# there yourself, tools/fuzz/README.md). A crash, a timeout or a sanitizer report leaves its input in
# <build-dir>/fuzz-crashes/ as crash-*, timeout-*, oom-* or leak-*; the script runs the other targets anyway and exits 1 at
# the end. Reproduce one with: <build-dir>/tools/fuzz/fa_fuzz_<target> <file>
set -uo pipefail

build="${1:?usage: tools/fuzz/run.sh <build-dir> [seconds-per-target] [target...]}"
seconds="${2:-60}"
shift 2 2>/dev/null || shift $#
root="$(cd "$(dirname "$0")/../.." && pwd)"
build="$(cd "$build" && pwd)"
work="$build/fuzz-work"
crashes="$build/fuzz-crashes"
mkdir -p "$work" "$crashes"

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
    for exe in "$build"/tools/fuzz/fa_fuzz_*; do
        [[ -f "$exe" && -x "$exe" ]] && targets+=("$(basename "$exe" | sed 's/^fa_fuzz_//')")
    done
fi
if [[ ${#targets[@]} -eq 0 ]]; then
    echo "run.sh: no fa_fuzz_* program in $build/tools/fuzz (configure with -DFA_FUZZ=ON and build the target fa_fuzz_all)" >&2
    exit 2
fi

# The targets read schemas/ relative to the repository root.
cd "$root"
export ASAN_OPTIONS="${ASAN_OPTIONS:-abort_on_error=0:detect_stack_use_after_return=1:strict_string_checks=1}"
export UBSAN_OPTIONS="${UBSAN_OPTIONS:-print_stacktrace=1:halt_on_error=1}"

failed=()
for t in "${targets[@]}"; do
    exe="$build/tools/fuzz/fa_fuzz_$t"
    corpus="$root/tools/fuzz/corpus/$t"
    if [[ ! -x "$exe" || ! -d "$corpus" ]]; then
        echo "run.sh: unknown target '$t' (no $exe or no $corpus)" >&2
        failed+=("$t")
        continue
    fi
    mkdir -p "$work/$t"
    echo "::group::fuzz $t (${seconds} s)"
    "$exe" "$work/$t" "$corpus" -max_total_time="$seconds" -timeout=20 -rss_limit_mb=4096 -max_len=65536 \
        -artifact_prefix="$crashes/$t-" -print_final_stats=1
    status=$?
    echo "::endgroup::"
    if [[ $status -ne 0 ]]; then
        echo "run.sh: $t failed (exit $status); the input is in $crashes" >&2
        failed+=("$t")
    fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
    echo "run.sh: failed: ${failed[*]}" >&2
    exit 1
fi
echo "run.sh: ${#targets[@]} target(s) ran ${seconds} s each without a finding"
