#!/usr/bin/env python3
"""Measures the size of factoria_player on one platform, compares it with tools/size/player_size_budget.json and says what
each library adds. Standard library only, so it runs on every CI runner (use scripts/player-size.sh to find the interpreter).

    player-size.py measure --platform macos-arm64 [--build-dir build/macos-release] [--config Release]
                           [--budget FILE] [--out-dir DIR] [--file PATH ...] [--map FILE]
    player-size.py update player-size-<platform>.json ... [--budget FILE] [--percent 10]
    player-size.py validate [--budget FILE]
    player-size.py self-test

measure   Measures what the budget names for the platform: the stripped copy of each shipped file (a Release build; a Debug
          player's size means nothing), or the sum of the static archives for iOS. Writes player-size-<platform>.json and
          player-size-<platform>.md to --out-dir, appends the markdown to $GITHUB_STEP_SUMMARY, and exits 1 when the size is
          over maxBytes (2 when it could not measure). maxBytes null: reports only, exits 0.
          The per-library numbers come from the link map the build wrote (CMake option FA_PLAYER_LINK_MAP=ON: GNU ld, lld,
          ld64 and MSVC formats are read), else from the sizes of the archives the player links (player/player_libs-*.txt,
          the same option; the web player has no map), else there are none and the report says so.
update    Writes the numbers of the given reports into the budget as the new baseline and sets maxBytes to the baseline plus
          --percent (default 10): what to run when growth is intended, or to fill a platform from the first CI run.
validate  Checks the budget file's schema (the ctest test player_size_script does it too).
"""

import argparse
import difflib
import fnmatch
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

BUDGET_SCHEMA = "factoria.size-budget/1"
REPORT_SCHEMA = "factoria.player-size/1"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DEFAULT_BUDGET = os.path.join(REPO_ROOT, "tools", "size", "player_size_budget.json")
BUDGET_REL = "tools/size/player_size_budget.json"
STRIP_MODES = ("none", "gnu", "apple", "llvm")
KINDS = ("binary", "archives")
DEFAULT_PERCENT = 10
SHRINK_NOTICE = 0.05  # a player 5% under its baseline: say that the budget could be lowered


class SizeError(Exception):
    """A problem the person running the script can fix: the message teaches how."""


# ---------------------------------------------------------------------------------------------------------------------
# Budget file


def load_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        raise SizeError(f"{path}: no such file")
    except ValueError as e:
        raise SizeError(f"{path}: not valid JSON: {e}")


def is_int(v):
    return isinstance(v, int) and not isinstance(v, bool)


def validate_budget(doc):
    """Returns a list of "<JSON pointer>: what is wrong, how to fix it" (empty when the file is fine)."""
    errs = []
    if not isinstance(doc, dict):
        return ["/: the budget file must be a JSON object"]
    known_top = {"schema", "note", "platforms"}
    for k in doc:
        if k not in known_top:
            near = difflib.get_close_matches(k, known_top, 1)
            errs.append(f"/{k}: unknown key" + (f" (did you mean \"{near[0]}\"?)" if near else ""))
    if doc.get("schema") != BUDGET_SCHEMA:
        errs.append(f"/schema: must be \"{BUDGET_SCHEMA}\"")
    if not isinstance(doc.get("note"), str) or not doc.get("note"):
        errs.append("/note: a string saying how to update the budgets")
    plats = doc.get("platforms")
    if not isinstance(plats, dict) or not plats:
        errs.append("/platforms: an object with one entry per platform")
        return errs
    known = {"description", "kind", "preset", "files", "globs", "exclude", "map", "maxBytes", "baselineBytes",
             "baselineLibraries", "note"}
    for name, e in plats.items():
        p = f"/platforms/{name}"
        if not re.fullmatch(r"[a-z0-9][a-z0-9_.-]*", name):
            errs.append(f"{p}: the platform key must be lower-case letters, digits, '-', '_' or '.'")
        if not isinstance(e, dict):
            errs.append(f"{p}: must be an object")
            continue
        for k in e:
            if k not in known:
                near = difflib.get_close_matches(k, known, 1)
                errs.append(f"{p}/{k}: unknown key" + (f" (did you mean \"{near[0]}\"?)" if near else ""))
        for k in ("description", "preset", "note"):
            if not isinstance(e.get(k), str) or not e.get(k):
                errs.append(f"{p}/{k}: a non-empty string")
        kind = e.get("kind")
        if kind not in KINDS:
            errs.append(f"{p}/kind: one of {', '.join(KINDS)}")
        if kind == "binary":
            files = e.get("files")
            if not isinstance(files, list) or not files:
                errs.append(f"{p}/files: a non-empty list of {{\"path\", \"strip\"}}")
            else:
                for i, f in enumerate(files):
                    fp = f"{p}/files/{i}"
                    if not isinstance(f, dict) or not isinstance(f.get("path"), str) or not f.get("path"):
                        errs.append(f"{fp}/path: a path relative to the build directory ({{config}} = the build configuration)")
                    if not isinstance(f, dict) or f.get("strip") not in STRIP_MODES:
                        errs.append(f"{fp}/strip: one of {', '.join(STRIP_MODES)}")
        elif kind == "archives":
            g = e.get("globs")
            if not isinstance(g, list) or not g or not all(isinstance(x, str) and x for x in g):
                errs.append(f"{p}/globs: a non-empty list of glob patterns relative to the build directory")
            ex = e.get("exclude", [])
            if not isinstance(ex, list) or not all(isinstance(x, str) for x in ex):
                errs.append(f"{p}/exclude: a list of glob patterns")
        if "map" in e and (not isinstance(e["map"], str) or not e["map"]):
            errs.append(f"{p}/map: a path relative to the build directory")
        for k in ("maxBytes", "baselineBytes"):
            v = e.get(k, "missing")
            if v == "missing":
                errs.append(f"{p}/{k}: required (null = not set yet)")
            elif v is not None and (not is_int(v) or v <= 0):
                errs.append(f"{p}/{k}: a positive integer number of bytes, or null")
        mx, base = e.get("maxBytes"), e.get("baselineBytes")
        if is_int(mx) and not is_int(base):
            errs.append(f"{p}/baselineBytes: required when maxBytes is set (run `scripts/player-size.sh update`)")
        if is_int(mx) and is_int(base) and mx < base:
            errs.append(f"{p}/maxBytes: {mx} is below baselineBytes {base}: the player would fail its own baseline")
        bl = e.get("baselineLibraries")
        if bl is not None:
            if not isinstance(bl, dict) or not all(is_int(v) and v >= 0 for v in bl.values()):
                errs.append(f"{p}/baselineLibraries: an object library name -> bytes")
    return errs


# ---------------------------------------------------------------------------------------------------------------------
# Names


def normalize_lib(name):
    """libfa_runtime.a, fa_runtime.lib and /x/libfa_runtime.a all become fa_runtime."""
    base = re.split(r"[\\/]", name.strip())[-1]
    base = re.sub(r"\.(a|lib|dylib|tbd|so(\.\d+)*)$", "", base, flags=re.I)
    if base.startswith("lib") and len(base) > 3:
        base = base[3:]
    return base or name


def owner_of(path):
    """The library a linker map line belongs to: the archive of `x/libfoo.a(bar.o)`, a shared library by its name, and
    "(objects)" for a plain object file (the player's own sources, the C runtime startup files). The fa_render sources the
    Vulkan player compiles again (the object library fa_render_vulkan, engine/render/CMakeLists.txt) count as
    "fa_render_vulkan"."""
    path = path.strip()
    if re.search(r"[/\\]fa_render_vulkan\.dir[/\\]", path):
        return "fa_render_vulkan"
    m = re.search(r"([^/\\()]+)\(([^()]*)\)\s*$", path)
    if m:
        return normalize_lib(m.group(1))
    if re.search(r"\.(o|obj)$", path, re.I):
        return "(objects)"
    return normalize_lib(path)


# Zero-fill sections take no room in the file: .bss, .sbss (small data), .dynbss (copy relocations), .tbss (thread-local) and
# .lbss are skipped on purpose; the prefix match also covers `.bss.foo` and `.sbss2`.
SKIP_SECTION = re.compile(r"^(\.debug|\.comment|\.bss|\.dynbss|\.sbss|\.tbss|\.lbss|COMMON|\*fill\*|\.stab|\.symtab|\.strtab)")


# ---------------------------------------------------------------------------------------------------------------------
# Link maps. Each parser returns {library: bytes} counting what takes room in the file (no .bss, no debug sections).


def parse_gnu_map(text):
    libs = {}
    started = False
    pending = None
    for line in text.splitlines():
        if not started:
            started = line.startswith("Linker script and memory map")
            continue
        m = re.match(r"^ (\S+)\s*$", line)
        if m:
            pending = m.group(1)
            continue
        sec = size = obj = None
        m = re.match(r"^ (\S+)\s+0x[0-9a-fA-F]+\s+0x([0-9a-fA-F]+)\s+(\S.*?)\s*$", line)
        if m:
            sec, size, obj = m.group(1), m.group(2), m.group(3)
        elif pending:
            m = re.match(r"^\s{10,}0x[0-9a-fA-F]+\s+0x([0-9a-fA-F]+)\s+(\S.*?)\s*$", line)
            if m:
                sec, size, obj = pending, m.group(1), m.group(2)
        pending = None
        if sec is None or SKIP_SECTION.match(sec):
            continue
        n = int(size, 16)
        if n:
            owner = owner_of(obj)
            libs[owner] = libs.get(owner, 0) + n
    return libs


# The file of an input section line ends in .o, .obj, .lib or `.a(member)`: a demangled symbol line such as
# `fa::(anonymous namespace)::helper(int)` also reads `<text>:(<text>)` and must not count as an input section.
# Link-time optimization hands lld input sections that belong to no file (`<internal>`, `lto.tmp`, `/tmp/lto.o`): they are
# counted under "(lto)" so the per-library numbers still add up to the map's total.
LLD_LINE = re.compile(r"^\s*([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+(?:\d+\s+)?"
                      r"(\S.*?(?:\.(?:o|obj|lib)|\.a\([^()]*\))|<internal>|\S*lto[^\s:]*\.tmp):\(([^()\s]*)\)\s*$", re.I)


def parse_lld_map(text):
    """lld (ELF and COFF-less targets: Linux, Android) and wasm-ld: `VMA LMA Size Align Out In Symbol` / `Addr Off Size Out In
    Symbol`; the input section lines read `<file>:(<section>)`."""
    libs = {}
    for line in text.splitlines():
        m = LLD_LINE.match(line)
        if not m or SKIP_SECTION.match(m.group(5)):
            continue
        n = int(m.group(3), 16)
        if n:
            f = m.group(4)
            owner = "(lto)" if f == "<internal>" or f.lower().endswith(".tmp") else owner_of(f)
            libs[owner] = libs.get(owner, 0) + n
    return libs


def parse_ld64_map(text):
    files = {}
    zerofill = []
    libs = {}
    part = None
    for line in text.splitlines():
        if line.startswith("#"):
            low = line.lower()
            if low.startswith("# object files"):
                part = "objects"
            elif low.startswith("# sections"):
                part = "sections"
            elif low.startswith("# symbols"):
                part = "symbols"
            elif low.startswith("# dead stripped"):
                part = None
            continue
        if part == "objects":
            m = re.match(r"^\[\s*(\d+)\]\s+(.*)$", line)
            if m:
                files[int(m.group(1))] = "(linker)" if m.group(2).strip() == "linker synthesized" else owner_of(m.group(2))
        elif part == "sections":
            m = re.match(r"^0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)\s+(\S+)", line)
            if m and m.group(4) in ("__bss", "__common", "__thread_bss", "__huge"):
                start = int(m.group(1), 16)
                zerofill.append((start, start + int(m.group(2), 16)))
        elif part == "symbols":
            m = re.match(r"^0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+\[\s*(\d+)\]", line)
            if not m:
                continue
            addr, n, idx = int(m.group(1), 16), int(m.group(2), 16), int(m.group(3))
            if n and not any(a <= addr < b for a, b in zerofill):
                owner = files.get(idx, "(unknown)")
                libs[owner] = libs.get(owner, 0) + n
    return libs


def parse_msvc_map(text):
    sections = {}  # section number -> (total length, name, class): a section has one "Start Length Name" line per contribution
    for m in re.finditer(r"^\s*([0-9a-fA-F]{4}):[0-9a-fA-F]{8}\s+([0-9a-fA-F]{8})H\s+(\S+)\s+(\S+)\s*$", text, re.M):
        idx = int(m.group(1), 16)
        old = sections.get(idx)
        sections[idx] = ((old[0] if old else 0) + int(m.group(2), 16), old[1] if old else m.group(3),
                         old[2] if old else m.group(4))
    pub = re.compile(r"^\s*([0-9a-fA-F]{4}):([0-9a-fA-F]{8})\s+(\S+)\s+([0-9a-fA-F]{8,16})\s+(?:[fi]\s+)*(\S+)\s*$")
    by_section = {}
    in_publics = False
    for line in text.splitlines():
        if "Publics by Value" in line:
            in_publics = True
            continue
        if not in_publics:
            continue
        m = pub.match(line)
        if m:
            by_section.setdefault(int(m.group(1), 16), []).append((int(m.group(2), 16), m.group(5)))
        elif "Static symbols" in line:
            break
    libs = {}
    for sec, items in by_section.items():
        length, name, cls = sections.get(sec, (None, "", ""))
        if cls.upper() == "BSS" or name.startswith(".bss"):
            continue
        items.sort(key=lambda x: x[0])
        for i, (off, who) in enumerate(items):
            end = items[i + 1][0] if i + 1 < len(items) else (length if length else off)
            n = max(0, end - off)
            m = re.match(r"^([^:\\/]{2,}):([^:]+)$", who)
            owner = normalize_lib(m.group(1)) if m else "(objects)"
            if n:
                libs[owner] = libs.get(owner, 0) + n
    return libs


def parse_link_map(text):
    """Picks the parser by what the file looks like. Returns ({library: bytes}, format name)."""
    head = text[:4000]
    if head.startswith("# Path:") or "# Object files:" in head:
        return parse_ld64_map(text), "ld64"
    if "Publics by Value" in text or "Rva+Base" in text:
        return parse_msvc_map(text), "msvc"
    if "Linker script and memory map" in text:
        return parse_gnu_map(text), "gnu-ld"
    if re.search(r"^\s*(VMA|Addr)\s+(LMA|Off)\s+Size", text, re.M):
        return parse_lld_map(text), "lld"
    raise SizeError("the link map is in a format this script does not read (GNU ld, lld, wasm-ld, ld64 and MSVC /MAP are)")


def read_text(path):
    with open(path, "rb") as f:
        return f.read().decode("utf-8", errors="replace")


# ---------------------------------------------------------------------------------------------------------------------
# Measuring


def find_tool(names, extra_dirs=()):
    for d in extra_dirs:
        for n in names:
            for c in sorted(glob.glob(os.path.join(d, n))) + sorted(glob.glob(os.path.join(d, n + ".exe"))):
                if os.path.isfile(c):
                    return c
    for n in names:
        p = shutil.which(n)
        if p:
            return p
    return None


def strip_copy(src, mode, tmpdir):
    """Returns the path of a copy of `src` as shipped: stripped of symbols, without touching the build's own file."""
    dst = os.path.join(tmpdir, os.path.basename(src))
    shutil.copyfile(src, dst)
    if mode == "none":
        return dst
    if mode == "gnu":
        tool, args = find_tool(["strip"]), ["--strip-all"]
    elif mode == "apple":
        tool, args = find_tool(["strip"]), ["-x"]
    else:
        ndk = os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK_LATEST_HOME") or ""
        tool = find_tool(["llvm-strip"], [os.path.join(ndk, "toolchains", "llvm", "prebuilt", "*", "bin")] if ndk else [])
        args = ["--strip-unneeded"]
    if not tool:
        raise SizeError(f"cannot strip {src}: no `strip` tool ('{mode}' mode) found in PATH"
                        + (" or in $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin" if mode == "llvm" else "")
                        + ". Install binutils (Linux) or the Xcode command line tools (macOS), or set ANDROID_NDK_HOME.")
    r = subprocess.run([tool] + args + [dst], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode != 0:
        raise SizeError(f"`{os.path.basename(tool)} {' '.join(args)} {src}` failed ({r.returncode}): {r.stdout.strip()}")
    return dst


def measure_files(entry, build_dir, config, override_files):
    """Returns [{"path", "rawBytes", "bytes"}] for the files the entry names."""
    out = []
    with tempfile.TemporaryDirectory(prefix="player-size-") as tmp:
        if override_files:
            specs = [{"path": p, "strip": "none", "_abs": True} for p in override_files]
        elif entry["kind"] == "binary":
            specs = entry["files"]
        else:
            specs = None
        if specs is not None:
            for i, spec in enumerate(specs):
                rel = spec["path"].replace("{config}", config)
                src = rel if spec.get("_abs") else os.path.join(build_dir, rel)
                if not os.path.isfile(src):
                    near = sorted(glob.glob(os.path.join(os.path.dirname(src), "*")))[:8]
                    raise SizeError(
                        f"{src}: the player was not built here. Build the Release player first (preset '{entry['preset']}', "
                        f"target factoria_player) or point --build-dir at its build directory (now '{build_dir}'; --config "
                        f"'{config}' replaces {{config}} in the path)."
                        + (f" Files next to it: {', '.join(os.path.basename(n) for n in near)}." if near else ""))
                sub = os.path.join(tmp, str(i))
                os.makedirs(sub)
                done = strip_copy(src, spec["strip"], sub)
                out.append({"path": rel, "rawBytes": os.path.getsize(src), "bytes": os.path.getsize(done)})
        else:
            seen = set()
            for pat in entry["globs"]:
                for f in sorted(glob.glob(os.path.join(build_dir, pat), recursive=True)):
                    rel = os.path.relpath(f, build_dir).replace(os.sep, "/")
                    if not os.path.isfile(f) or rel in seen:
                        continue
                    if any(fnmatch.fnmatch(rel, x) for x in entry.get("exclude", [])):
                        continue
                    seen.add(rel)
                    n = os.path.getsize(f)
                    out.append({"path": rel, "rawBytes": n, "bytes": n})
            if not out:
                raise SizeError(f"no static library matches {entry['globs']} under '{build_dir}': build the Release player "
                                f"archives first (preset '{entry['preset']}') or point --build-dir at their build directory.")
    return out


def find_libraries(entry, build_dir, config, map_override, files=()):
    """Returns (libraries or None, source description, mapTotalBytes or None, note). Never raises: the per-library table is
    a report, and a map this script cannot read must not fail a job whose only check is the size of the files. The reason
    goes in `note` and the numbers fall back to the archive list or to nothing."""
    note = ""
    if entry["kind"] == "archives":
        # The archives are the measured files themselves: the per-library numbers need no link map.
        libs = {}
        for f in files:
            libs[normalize_lib(f["path"])] = libs.get(normalize_lib(f["path"]), 0) + f["bytes"]
        if libs:
            return libs, "sizes of the archives measured (no link map: the archives are not linked into one file)", sum(
                libs.values()), None
        note = "no archive was measured"
    try:
        map_path = map_override or (os.path.join(build_dir, entry["map"]) if entry.get("map") else None)
        if map_path and os.path.isfile(map_path):
            try:
                libs, fmt = parse_link_map(read_text(map_path))
            except Exception as e:  # an unknown format, a binary file, a parser bug: a note, never a failed step
                libs, fmt = None, None
                note = f"the link map {map_path} could not be read ({type(e).__name__}: {e})"
            else:
                if libs:
                    return libs, f"link map ({fmt}): {map_path}", sum(libs.values()), None
                note = f"the link map {map_path} lists no input section"
        elif map_path:
            note = f"no link map at {map_path} (configure with -DFA_PLAYER_LINK_MAP=ON)"
        elif not note:
            note = "this platform writes no link map"
    except Exception as e:
        note = f"the per-library numbers failed ({type(e).__name__}: {e})"
    try:
        lists = sorted(glob.glob(os.path.join(build_dir, "player", "player_libs*.txt")))
        pref = [p for p in lists if config.lower() in os.path.basename(p).lower()]
        lists = pref or lists
        if lists:
            libs = {}
            for line in read_text(lists[0]).splitlines():
                line = line.strip()
                path = os.path.join(build_dir, line) if line else ""  # relative to the build directory (absolute stays)
                if path and os.path.isfile(path):
                    libs[normalize_lib(line)] = libs.get(normalize_lib(line), 0) + os.path.getsize(path)
            if libs:
                return (libs, f"sizes of the archives the player links ({os.path.basename(lists[0])}); {note}",
                        sum(libs.values()), note)
    except Exception as e:
        note += f"; the archive list could not be read either ({type(e).__name__}: {e})"
    return None, f"none: {note}, and no archive list (player/player_libs-*.txt)", None, note


def fmt_bytes(n):
    return f"{n:,} bytes ({n / 1048576:.2f} MiB)"


def fmt_delta(n):
    return f"{'+' if n >= 0 else '-'}{abs(n):,}"


def pct(a, b):
    return 0.0 if not b else round(100.0 * a / b, 1)


def growth(libs, baseline):
    """[(library, delta, now, before)] sorted by what grew most (libraries that shrank last)."""
    rows = []
    for k in set(libs) | set(baseline):
        now, before = libs.get(k, 0), baseline.get(k, 0)
        if now != before:
            rows.append((k, now - before, now, before))
    rows.sort(key=lambda r: (-r[1], r[0]))
    return rows


def evaluate(platform, entry, files, libs):
    size = sum(f["bytes"] for f in files)
    mx, base = entry.get("maxBytes"), entry.get("baselineBytes")
    if mx is None:
        status = "no-budget"
    elif size > mx:
        status = "over"
    else:
        status = "ok"
    return size, status


def over_message(platform, entry, files, size, libs, source):
    mx, base = entry["maxBytes"], entry.get("baselineBytes")
    lines = [f"error: the {platform} player is over its size budget",
             f"  platform: {platform} ({entry['description']})",
             "  file:     " + ", ".join(f["path"] for f in files) + (" (stripped copy)" if entry["kind"] == "binary" else ""),
             f"  size:     {fmt_bytes(size)}",
             f"  budget:   {fmt_bytes(mx)} (maxBytes, {size - mx:,} bytes over)"]
    if base:
        lines.append(f"  baseline: {fmt_bytes(base)}, {fmt_delta(size - base)} bytes ({pct(size - base, base):+.1f}%)")
    bl = entry.get("baselineLibraries")
    if libs and bl:
        rows = [r for r in growth(libs, bl) if r[1] > 0][:6]
        lines.append(f"  what grew most against the baseline ({source.split(':')[0]}):")
        for k, d, now, before in rows:
            lines.append(f"    {k}: {fmt_delta(d)} bytes ({now:,} now, {before:,} in the baseline)"
                         + ("  (new: not in the baseline)" if before == 0 else ""))
        if not rows:
            lines.append("    no library grew: the difference is in code the map does not attribute (startup files, "
                         "padding, compiler or linker changes). Compare the linker or toolchain version with the baseline's.")
    elif libs:
        lines.append(f"  no per-library baseline in the budget (baselineLibraries); the library table of the job summary "
                     f"shows what each one adds now: {', '.join(f'{k} {v:,}' for k, v in sorted(libs.items(), key=lambda x: -x[1])[:5])}")
    else:
        lines.append("  no per-library numbers: " + source)
    lines += [
        "  If the player should not have grown: find what the change pulled in (a module that moved into fa_runtime, a new",
        "    dependency, a header-only library now included by the player, an asset embedded in the binary).",
        "  If the growth is intended: download the artifact player-size-" + platform + " of this run and run",
        f"    scripts/player-size.sh update player-size-{platform}.json",
        f"    which sets the baseline to this size and maxBytes to the baseline plus {DEFAULT_PERCENT}%; commit {BUDGET_REL}",
        "    in the same change and say in the commit message why the player grew (docs/design/BUILDING_RELEASE.md, \"Player size budgets\").",
    ]
    return "\n".join(lines)


def markdown(platform, entry, files, size, status, libs, source, total):
    mx, base = entry.get("maxBytes"), entry.get("baselineBytes")
    verdict = {"ok": "within budget", "over": "**OVER BUDGET**", "no-budget": "no budget set yet (report only)"}[status]
    md = [f"### Player size: {platform} ({verdict})", "",
          f"{entry['description']}", "",
          "| | bytes | MiB |", "|---|---:|---:|",
          f"| size now | {size:,} | {size / 1048576:.2f} |"]
    if base:
        md.append(f"| baseline | {base:,} | {base / 1048576:.2f} |")
    if mx:
        md.append(f"| budget (max) | {mx:,} | {mx / 1048576:.2f} |")
    md += ["", "Measured: " + "; ".join(f"`{f['path']}` {f['bytes']:,}" for f in files) + "", ""]
    if libs:
        bl = entry.get("baselineLibraries") or {}
        md += [f"What each library adds (source: {source}):", "",
               "| library | bytes | share | baseline | change |", "|---|---:|---:|---:|---:|"]
        ordered = sorted(libs.items(), key=lambda x: (-x[1], x[0]))
        for k, v in ordered[:30]:
            b = bl.get(k)
            md.append(f"| {k} | {v:,} | {pct(v, total)}% | {'' if b is None else f'{b:,}'} | "
                      f"{'' if b is None else fmt_delta(v - b)} |")
        if len(ordered) > 30:
            rest = sum(v for _, v in ordered[30:])
            md.append(f"| ({len(ordered) - 30} more) | {rest:,} | {pct(rest, total)}% | | |")
        md += ["", f"The numbers add up to {total:,} bytes, which is not the file size: the map counts what the linker places, "
               "the file also holds headers, tables and padding." if source.startswith("link map") else
               f"These are archive file sizes ({total:,} bytes together): what the linker keeps of them is smaller."]
    else:
        md.append(f"No per-library numbers: {source}.")
    if mx is None:
        md += ["", f"The budget of {platform} is not set (maxBytes null in {BUDGET_REL}): nothing can fail yet. "
               f"Run `scripts/player-size.sh update player-size-{platform}.json` on this report and commit the file."]
    return "\n".join(md) + "\n"


def cmd_measure(args):
    doc = load_json(args.budget)
    errs = validate_budget(doc)
    if errs:
        raise SizeError(f"{args.budget} is not a valid size budget:\n  " + "\n  ".join(errs))
    plats = doc["platforms"]
    if args.platform not in plats:
        near = difflib.get_close_matches(args.platform, list(plats), 1)
        raise SizeError(f"no platform '{args.platform}' in {args.budget}. Known: {', '.join(plats)}."
                        + (f" Did you mean '{near[0]}'?" if near else "")
                        + " A new platform is a new entry there (copy one with the same kind).")
    entry = plats[args.platform]
    build_dir = args.build_dir or os.path.join("build", entry["preset"])
    files = measure_files(entry, build_dir, args.config, args.file)
    libs, source, total, note = find_libraries(entry, build_dir, args.config, args.map, files)
    size, status = evaluate(args.platform, entry, files, libs)

    report = {"schema": REPORT_SCHEMA, "platform": args.platform, "kind": entry["kind"], "status": status,
              "commit": os.environ.get("GITHUB_SHA", ""), "bytes": size, "maxBytes": entry.get("maxBytes"),
              "baselineBytes": entry.get("baselineBytes"), "files": files, "librariesSource": source,
              "librariesTotalBytes": total, "note": note,
              "libraries": dict(sorted(libs.items(), key=lambda x: (-x[1], x[0]))) if libs else None}
    os.makedirs(args.out_dir, exist_ok=True)
    jpath = os.path.join(args.out_dir, f"player-size-{args.platform}.json")
    with open(jpath, "w", encoding="utf-8", newline="\n") as f:
        json.dump(report, f, indent=2)
        f.write("\n")
    md = markdown(args.platform, entry, files, size, status, libs, source, total)
    with open(os.path.join(args.out_dir, f"player-size-{args.platform}.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(md)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8", newline="\n") as f:
            f.write(md + "\n")

    mx, base = entry.get("maxBytes"), entry.get("baselineBytes")
    print(f"player size {args.platform}: {fmt_bytes(size)}"
          + (f", baseline {base:,} ({pct(size - base, base):+.1f}%)" if base else "")
          + (f", budget {mx:,}" if mx else ", no budget") + f" -> {status}")
    print(f"per-library numbers: {source}")
    print(f"report: {jpath}")
    if status == "no-budget":
        print(f"notice: the size budget of {args.platform} is not set (maxBytes null in {BUDGET_REL}), so nothing is checked. "
              f"Fill it from this report: scripts/player-size.sh update {jpath}")
        return 0
    if status == "over":
        msg = over_message(args.platform, entry, files, size, libs, source)
        if os.environ.get("GITHUB_ACTIONS"):
            print("::error title=Player size over budget::" + msg.splitlines()[0][len("error: "):] + f" ({size:,} > {mx:,} bytes)")
        print(msg, file=sys.stderr)
        return 1
    if base and size < base * (1 - SHRINK_NOTICE):
        print(f"notice: the player is {pct(base - size, base)}% under its baseline. Keep the gain: run "
              f"`scripts/player-size.sh update {jpath}` and commit {BUDGET_REL} so growth back to the old size fails.")
    return 0


def cmd_update(args):
    doc = load_json(args.budget)
    errs = validate_budget(doc)
    if errs:
        raise SizeError(f"{args.budget} is not a valid size budget:\n  " + "\n  ".join(errs))
    if not isinstance(args.percent, int) or args.percent < 0:
        raise SizeError("--percent must be a whole number of at least 0")
    for rpath in args.reports:
        rep = load_json(rpath)
        if rep.get("schema") != REPORT_SCHEMA or rep.get("platform") not in doc["platforms"] or not is_int(rep.get("bytes")):
            raise SizeError(f"{rpath}: not a report of this script (schema {REPORT_SCHEMA}) for a platform of the budget: "
                            f"{', '.join(doc['platforms'])}")
        e = doc["platforms"][rep["platform"]]
        e["baselineBytes"] = rep["bytes"]
        e["maxBytes"] = (rep["bytes"] * (100 + args.percent) + 99) // 100
        if rep.get("libraries"):
            e["baselineLibraries"] = rep["libraries"]
        elif e.get("baselineLibraries"):
            # The old table came from another source (map, archives): comparing a later report with it would mislead.
            e.pop("baselineLibraries")
            print(f"warning: {rpath} has no per-library numbers: the old baselineLibraries of {rep['platform']} were dropped",
                  file=sys.stderr)
        print(f"{rep['platform']}: baseline {rep['bytes']:,}, maxBytes {e['maxBytes']:,} (+{args.percent}%)")
    with open(args.budget, "w", encoding="utf-8", newline="\n") as f:
        json.dump(doc, f, indent=2)
        f.write("\n")
    print(f"wrote {args.budget}: review the diff and commit it with the reason for the growth")
    return 0


def cmd_validate(args):
    errs = validate_budget(load_json(args.budget))
    for e in errs:
        print(f"{args.budget}{e}" if e.startswith("/") else e, file=sys.stderr)
    if not errs:
        print(f"{args.budget}: ok")
    return 1 if errs else 0


# ---------------------------------------------------------------------------------------------------------------------
# Self test (ctest: player_size_script)

GNU_MAP = """Archive member included to satisfy reference by file (symbol)

Discarded input sections

 .text          0x0000000000000000       0x99 /b/libgone.a(gone.o)

Linker script and memory map

.text           0x0000000000401000     0x3000
 .text          0x0000000000401000       0x40 /usr/lib/x86_64-linux-gnu/crt1.o
 .text._ZN2fa4coreEv
                0x0000000000401040      0x100 /b/engine/core/libfa_core.a(core.cpp.o)
                0x0000000000401040                fa::core()
 .text._ZN2fa6renderEv
                0x0000000000401140      0x200 /b/engine/render/libfa_render.a(render.cpp.o)
 .text          0x0000000000401340       0x20 CMakeFiles/factoria_player.dir/main.cpp.o
 *fill*         0x0000000000401360        0x4
.bss            0x0000000000500000      0x500
 .bss._ZL1x     0x0000000000500000      0x400 /b/engine/core/libfa_core.a(core.cpp.o)
.debug_info     0x0000000000000000     0x9000
 .debug_info    0x0000000000000000     0x9000 /b/engine/core/libfa_core.a(core.cpp.o)
"""

LLD_MAP = """             VMA              LMA     Size Align Out     In      Symbol
           200238           200238      3000     8 .text
           200238           200238       100     4         /b/engine/core/libfa_core.a(core.cpp.o):(.text._ZN2fa4coreEv)
           200238           200238       100     1                 _ZN2fa4coreEv
           200238           200238       100     1                 fa::(anonymous namespace)::helper(int)
           200338           200338        80     4         /b/engine/render/libfa_render.a(render.cpp.o):(.text._ZN2fa6renderEv)
           2003b8           2003b8        10     4         /b/player/CMakeFiles/factoria_player.dir/main.cpp.o:(.text.main)
           300000           300000       400     8 .bss
           300000           300000       400     8         /b/engine/core/libfa_core.a(core.cpp.o):(.bss._ZL1x)
"""

LD64_MAP = """# Path: /b/player/factoria_player
# Arch: arm64
# Object files:
[  0] linker synthesized
[  1] /b/player/CMakeFiles/factoria_player.dir/main.cpp.o
[  2] /b/engine/core/libfa_core.a(core.cpp.o)
[  3] /b/engine/render/libfa_render.a(render.cpp.o)
# Sections:
# Address\tSize    \tSegment\tSection
0x100000460\t0x00000800\t__TEXT\t__text
0x100001000\t0x00000400\t__DATA\t__bss
# Symbols:
# Address\tSize    \tFile  Name
0x100000460\t0x00000040\t[  1] _main
0x1000004A0\t0x00000100\t[  2] __ZN2fa4coreEv
0x1000005A0\t0x00000200\t[  3] __ZN2fa6renderEv
0x100001000\t0x00000400\t[  2] __ZL1x
0x100001400\t0x00000010\t[  0] dyld_private
# Dead Stripped Symbols:
#            \tSize    \tFile  Name
<<dead>>\t0x00000500\t[  2] __ZN2fa4deadEv
"""

MSVC_MAP = """ factoria_player

 Timestamp is 69b0c0de (Sat Nov 14 10:00:00 2026)

 Preferred load address is 0000000140000000

 Start         Length     Name                   Class
 0001:00000000 00000500H .text$mn                CODE
 0002:00000000 00000100H .data                   DATA
 0003:00000000 00000800H .bss                    BSS

  Address         Publics by Value              Rva+Base               Lib:Object

 0001:00000000       main                       0000000140001000 f   main.obj
 0001:00000100       ?core@fa@@YAXXZ            0000000140001100 f   fa_core:core.obj
 0001:00000300       ?render@fa@@YAXXZ          0000000140001300 f i fa_render.lib:render.obj
 0002:00000000       ?table@@3HA                0000000140003000     fa_core:core.obj
 0003:00000000       ?zero@@3HA                 0000000140004000     fa_core:core.obj

 entry point at        0001:00000000
"""


def self_test():
    failures = []

    def check(cond, what):
        if not cond:
            failures.append(what)

    # 1. The shipped budget file passes its own schema; broken ones are named by JSON pointer.
    shipped = validate_budget(load_json(DEFAULT_BUDGET))
    check(not shipped, f"the shipped budget has errors: {shipped}")
    good = {"schema": BUDGET_SCHEMA, "note": "n", "platforms": {"p": {
        "description": "d", "kind": "binary", "preset": "x", "files": [{"path": "a", "strip": "none"}],
        "maxBytes": 200, "baselineBytes": 100, "note": "n"}}}
    check(validate_budget(good) == [], "a valid budget was rejected")
    check(owner_of("engine/render/CMakeFiles/fa_render_vulkan.dir/src/renderer.cpp.o") == "fa_render_vulkan",
          "the Vulkan player's fa_render objects are not named")
    check(owner_of("player/CMakeFiles/factoria_player.dir/main.cpp.o") == "(objects)", "plain objects changed owner")
    bad = json.loads(json.dumps(good))
    bad["platforms"]["p"]["maxBytes"] = 50
    bad["platforms"]["p"]["files"][0]["strip"] = "gnuu"
    bad["platforms"]["p"]["maxByte"] = 3
    bad["schema"] = "x"
    msgs = " | ".join(validate_budget(bad))
    for needle in ("/schema", "/platforms/p/maxBytes", "/platforms/p/files/0/strip", "did you mean \"maxBytes\""):
        check(needle in msgs, f"the schema check does not name {needle}: {msgs}")
    nobase = json.loads(json.dumps(good))
    nobase["platforms"]["p"]["baselineBytes"] = None
    check("/platforms/p/baselineBytes" in " ".join(validate_budget(nobase)), "a maxBytes without a baseline is accepted")

    # 2. Link map parsers.
    exp = {
        "gnu-ld": (GNU_MAP, {"(objects)": 0x40 + 0x20, "fa_core": 0x100, "fa_render": 0x200}),
        "lld": (LLD_MAP, {"fa_core": 0x100, "fa_render": 0x80, "(objects)": 0x10}),
        "ld64": (LD64_MAP, {"(objects)": 0x40, "fa_core": 0x100, "fa_render": 0x200, "(linker)": 0x10}),
        "msvc": (MSVC_MAP, {"(objects)": 0x100, "fa_core": 0x200 + 0x100, "fa_render": 0x500 - 0x300}),
    }
    for fmt, (text, want) in exp.items():
        try:
            got, name = parse_link_map(text)
            check(name == fmt, f"{fmt}: detected as {name}")
            check(got == want, f"{fmt}: expected {want}, got {got}")
            crlf, _ = parse_link_map(text.replace("\n", "\r\n"))  # a map written on Windows
            check(crlf == want, f"{fmt}: the same map with CRLF line ends gives {crlf}")
        except SizeError as e:
            failures.append(f"{fmt}: {e}")
    check(normalize_lib("/x/libfa_runtime.a") == "fa_runtime" and normalize_lib("fa_core.lib") == "fa_core"
          and normalize_lib("C:\\x\\lib.lib") == "lib" and normalize_lib("libc++.a") == "c++", "normalize_lib")

    # 3. measure on a fake build: over, under and null budget; a missing file; the update command.
    with tempfile.TemporaryDirectory(prefix="player-size-test-") as tmp:
        build = os.path.join(tmp, "build")
        os.makedirs(os.path.join(build, "player"))
        with open(os.path.join(build, "player", "fake_player"), "wb") as f:
            f.write(b"\0" * 10000)
        with open(os.path.join(build, "player", "factoria_player.map"), "w", encoding="utf-8") as f:
            f.write(LLD_MAP)
        entry = {"description": "fake", "kind": "binary", "preset": "fake",
                 "files": [{"path": "player/fake_player", "strip": "none"}], "map": "player/factoria_player.map",
                 "maxBytes": None, "baselineBytes": None, "note": "n"}
        budget_path = os.path.join(tmp, "budget.json")

        def run(max_bytes, base, base_libs=None, extra=(), ent=None):
            e = dict(ent or entry, maxBytes=max_bytes, baselineBytes=base)
            if base_libs:
                e["baselineLibraries"] = base_libs
            with open(budget_path, "w", encoding="utf-8") as f:
                json.dump({"schema": BUDGET_SCHEMA, "note": "n", "platforms": {"fake-os": e}}, f)
            cmd = [sys.executable, "-I", os.path.abspath(__file__), "measure", "--platform", "fake-os", "--build-dir", build,
                   "--budget", budget_path, "--out-dir", os.path.join(tmp, "out")] + list(extra)
            env = dict(os.environ, GITHUB_STEP_SUMMARY=os.path.join(tmp, "summary.md"))
            env.pop("GITHUB_ACTIONS", None)
            return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)

        r = run(None, None)
        check(r.returncode == 0 and "not set" in r.stdout, f"null budget must report and pass: {r.returncode} {r.stdout} {r.stderr}")
        rep = load_json(os.path.join(tmp, "out", "player-size-fake-os.json"))
        check(rep["bytes"] == 10000 and rep["status"] == "no-budget" and rep["libraries"]["fa_core"] == 0x100,
              f"report of the null budget: {rep}")
        check(os.path.isfile(os.path.join(tmp, "out", "player-size-fake-os.md")), "the markdown file is missing")
        summary = read_text(os.path.join(tmp, "summary.md"))
        check("| fa_core |" in summary and "no budget set yet" in summary, f"the step summary lacks the table: {summary}")

        r = run(11000, 10000)
        check(r.returncode == 0 and "-> ok" in r.stdout, f"under budget must pass: {r.returncode} {r.stdout} {r.stderr}")
        r = run(10000, 10000)
        check(r.returncode == 0, "a size equal to maxBytes must pass")
        r = run(9000, 8000, {"fa_core": 0x40, "fa_render": 0x80})
        check(r.returncode == 1, f"over budget must fail with 1, got {r.returncode}")
        for needle in ("fake-os", "player/fake_player", "10,000", "9,000", "fa_core", "+192", "player-size.sh update"):
            check(needle in r.stderr, f"the over-budget message lacks '{needle}': {r.stderr}")
        r = run(11000, 10000, extra=["--platform", "fake-0s"])
        check(r.returncode == 2 and "did you mean" in r.stderr.lower(), f"unknown platform: {r.returncode} {r.stderr}")
        r = run(11000, 10000, extra=["--build-dir", os.path.join(tmp, "nowhere")])
        check(r.returncode == 2 and "was not built here" in r.stderr, f"missing file: {r.returncode} {r.stderr}")

        # update: a report becomes baseline and maxBytes + 10 %
        run(None, None)
        up = subprocess.run([sys.executable, "-I", os.path.abspath(__file__), "update",
                             os.path.join(tmp, "out", "player-size-fake-os.json"), "--budget", budget_path],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        after = load_json(budget_path)["platforms"]["fake-os"]
        check(up.returncode == 0 and after["baselineBytes"] == 10000 and after["maxBytes"] == 11000
              and after["baselineLibraries"]["fa_core"] == 0x100, f"update: {up.returncode} {up.stderr} {after}")

        # a map in no known format: the numbers fall back to "none" with a note, the size check still decides the exit code
        with open(os.path.join(build, "player", "factoria_player.map"), "w", encoding="utf-8") as f:
            f.write("this is not a link map\n")
        r = run(None, None)
        rep = load_json(os.path.join(tmp, "out", "player-size-fake-os.json"))
        check(r.returncode == 0 and rep["bytes"] == 10000 and rep["libraries"] is None
              and "could not be read" in (rep["note"] or ""),
              f"an unreadable map with a null budget must pass and say why in the note: {r.returncode} {r.stderr} {rep}")
        r = run(9000, 8000)
        check(r.returncode == 1 and "player-size.sh update" in r.stderr and "Traceback" not in r.stderr,
              f"an unreadable map must not hide an over-budget player: {r.returncode} {r.stderr}")
        with open(os.path.join(build, "player", "factoria_player.map"), "wb") as f:
            f.write(b"\xff\xfe\x00 binary \x80\x81")
        r = run(11000, 10000)
        check(r.returncode == 0 and "Traceback" not in r.stderr, f"a binary map must not fail the step: {r.returncode} {r.stderr}")

        # archive fallback: no map, the list of archives written by CMake
        os.remove(os.path.join(build, "player", "factoria_player.map"))
        with open(os.path.join(build, "libfa_core.a"), "wb") as f:
            f.write(b"\0" * 300)
        with open(os.path.join(build, "player", "player_libs-Release.txt"), "w", encoding="utf-8") as f:
            f.write("libfa_core.a\n")  # relative to the build directory, as CMake writes it
        libs, source, total, _ = find_libraries(entry, build, "Release", None)
        check(libs == {"fa_core": 300} and "archives" in source and total == 300, f"archive fallback: {libs} {source}")
        os.remove(os.path.join(build, "player", "player_libs-Release.txt"))
        libs, source, total, _ = find_libraries(entry, build, "Release", None)
        check(libs is None and "none" in source, f"no map, no list: {libs} {source}")

        # an archives entry sums the matching files and skips the excluded ones
        os.makedirs(os.path.join(build, "x", "Release-iphoneos"))
        os.makedirs(os.path.join(build, "x", "a.build", "Release-iphoneos"))
        for p, n in (("x/Release-iphoneos/liba.a", 100), ("x/Release-iphoneos/libb.a", 50), ("x/a.build/Release-iphoneos/liba.a", 7)):
            with open(os.path.join(build, p), "wb") as f:
                f.write(b"\0" * n)
        ios = {"description": "d", "kind": "archives", "preset": "ios", "globs": ["**/Release-iphoneos/*.a"],
               "exclude": ["*.build/*"], "maxBytes": None, "baselineBytes": None, "note": "n"}
        got = measure_files(ios, build, "Release", None)
        check(sum(g["bytes"] for g in got) == 150, f"archives entry: {got}")
        # ...and takes its per-library numbers from those archives (no link map, no archive list: iOS links no executable)
        libs, source, total, note = find_libraries(ios, build, "Release", None, got)
        check(libs == {"a": 100, "b": 50} and total == 150 and note is None, f"archives per-library numbers: {libs} {source}")
        r = run(None, None, ent=ios)
        rep = load_json(os.path.join(tmp, "out", "player-size-fake-os.json"))
        check(r.returncode == 0 and rep["libraries"] == {"a": 100, "b": 50} and rep["bytes"] == 150
              and "link map" not in rep["librariesSource"].replace("no link map", ""),
              f"measure of an archives entry: {r.returncode} {r.stderr} {rep}")

    # MSVC: a section has one line per contribution, its size is their sum (not the last line's); symbols of the same
    # section are measured to the end of that total
    msvc = ("Start         Length     Name                   Class\n"
            " 0001:00000000 00000100H .text$mn                CODE\n"
            " 0001:00000100 00000200H .text$x                 CODE\n"
            "  Address         Publics by Value              Rva+Base       Lib:Object\n"
            " 0001:00000000       a                  0000000140001000 f   liba.lib:a.obj\n"
            " 0001:00000100       b                  0000000140001100 f   libb.lib:b.obj\n"
            "  Static symbols\n")
    got = parse_msvc_map(msvc)
    check(got == {"a": 0x100, "b": 0x200}, f"msvc section sizes are summed: {got}")
    # lld: LTO input sections have no object file; they stay in the total under "(lto)"
    lld = ("             VMA              LMA     Size Align Out     In      Symbol\n"
           "            1000             1000      100    16 .text\n"
           "            1000             1000       40     4         /x/libfa_core.a(a.o):(.text.f)\n"
           "            1040             1040       30     4         <internal>:(.text)\n"
           "            1070             1070       20     4         /tmp/lto.tmp:(.text.g)\n"
           "            1090             1090       50     4         /x/libfa_core.a(a.o):(.bss.z)\n")
    got = parse_lld_map(lld)
    check(got == {"fa_core": 0x40, "(lto)": 0x50}, f"lld lto sections are counted: {got}")
    # GNU: zero-fill sections are skipped
    gnu = ("Linker script and memory map\n"
           " .text          0x0000000000001000       0x40 /x/libfa_core.a(a.o)\n"
           " .dynbss        0x0000000000002000       0x10 /x/libfa_core.a(a.o)\n"
           " .sbss          0x0000000000002010       0x10 /x/libfa_core.a(a.o)\n")
    got = parse_gnu_map(gnu)
    check(got == {"fa_core": 0x40}, f"gnu zero-fill sections are skipped: {got}")

    if failures:
        print("player-size self-test FAILED:", file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        return 1
    print("player-size self-test ok")
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("measure", help="measure, compare with the budget, write the report")
    m.add_argument("--platform", required=True, help="a key of platforms in the budget file")
    m.add_argument("--build-dir", help="the CMake build directory (default: build/<preset of the platform>)")
    m.add_argument("--config", default="Release", help="replaces {config} in a file path (Visual Studio: Release)")
    m.add_argument("--budget", default=DEFAULT_BUDGET)
    m.add_argument("--out-dir", default=".", help="where player-size-<platform>.json and .md go")
    m.add_argument("--file", action="append", help="measure this file as is instead of the budget's files (tests)")
    m.add_argument("--map", help="the link map to read instead of the budget's")
    u = sub.add_parser("update", help="take the numbers of reports as the new baseline and budget")
    u.add_argument("reports", nargs="+")
    u.add_argument("--budget", default=DEFAULT_BUDGET)
    u.add_argument("--percent", type=int, default=DEFAULT_PERCENT, help="maxBytes = baseline + this percent")
    v = sub.add_parser("validate", help="check the budget file")
    v.add_argument("--budget", default=DEFAULT_BUDGET)
    sub.add_parser("self-test", help="the checks of the ctest test")
    args = ap.parse_args(argv)
    try:
        if args.cmd == "self-test":
            return self_test()
        return {"measure": cmd_measure, "update": cmd_update, "validate": cmd_validate}[args.cmd](args)
    except SizeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
