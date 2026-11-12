#!/usr/bin/env bash
# Sourced by scripts/format.sh and scripts/tidy-changed.sh. Pins the clang-format and clang-tidy versions
# below; fa_lint_tool gives their path from a Python venv in build/lint-venv (pip wheels: the same on macOS, Linux and
# Windows, nothing installed system wide), created on first use. Change a version here only: the scripts and CI use this
# file.
FA_CLANG_FORMAT_VERSION=23.1.5
FA_CLANG_TIDY_VERSION=23.1.4

fa_lint_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# fa_lint_tool <format|tidy>: prints the path of the tool, installing the venv when needed.
fa_lint_tool() {
    local name="clang-$1" version venv="$fa_lint_root/build/lint-venv"
    if [ "$1" = format ]; then version="$FA_CLANG_FORMAT_VERSION"; else version="$FA_CLANG_TIDY_VERSION"; fi
    local bin="$venv/bin/$name"
    [ -x "$bin" ] || bin="$venv/Scripts/$name.exe"
    if [ -x "$bin" ] && [ "$("$bin" --version 2>&1 | grep -c "$version")" -ge 1 ]; then echo "$bin"; return 0; fi
    local py
    py="$(command -v python3 || command -v python)" || { echo "error: python3 is needed to install $name" >&2; return 1; }
    echo "Installing clang-format $FA_CLANG_FORMAT_VERSION and clang-tidy $FA_CLANG_TIDY_VERSION into build/lint-venv ..." >&2
    "$py" -m venv "$venv" >&2 &&
        "$venv/bin/python" -m pip install --quiet "clang-format==$FA_CLANG_FORMAT_VERSION" \
            "clang-tidy==$FA_CLANG_TIDY_VERSION" >&2 ||
        "$venv/Scripts/python.exe" -m pip install --quiet "clang-format==$FA_CLANG_FORMAT_VERSION" \
            "clang-tidy==$FA_CLANG_TIDY_VERSION" >&2 ||
        { echo "error: pip could not install $name $version. Hint: python3 -m venv build/lint-venv && build/lint-venv/bin/pip install clang-format==$FA_CLANG_FORMAT_VERSION clang-tidy==$FA_CLANG_TIDY_VERSION" >&2; return 1; }
    bin="$venv/bin/$name"
    [ -x "$bin" ] || bin="$venv/Scripts/$name.exe"
    echo "$bin"
}

# fa_lint_files <base|"">: first-party C and C++ files (tracked, not deleted) under the roots below, all of them or
# only those changed against <base> (three-dot: what the branch adds to the merge base). One path per line.
fa_lint_roots="engine tools player platforms examples templates"
fa_lint_files() {
    local base="$1" list
    if [ -n "$base" ]; then
        list="$(git -C "$fa_lint_root" diff --name-only --diff-filter=d "$base"...HEAD -- $fa_lint_roots)" || return 1
        # plus the uncommitted changes, so the script is useful before the commit as well
        list="$list"$'\n'"$(git -C "$fa_lint_root" diff --name-only --diff-filter=d HEAD -- $fa_lint_roots)"
    else
        list="$(git -C "$fa_lint_root" ls-files -- $fa_lint_roots)"
    fi
    printf '%s\n' "$list" | sort -u | grep -E "$FA_LINT_EXT" || true
}
