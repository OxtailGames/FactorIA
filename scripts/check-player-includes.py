#!/usr/bin/env python3
"""Fails when a file under player/ or templates/ includes `fa/runtime/internal/`.

    python3 scripts/check-player-includes.py [--root <repo>]

The player and the game templates are built against the public API of fa_runtime; its internal headers belong to the
engine and the developer tools (fa_authoring). Runs in the `lint` job and in `scripts/ci-preflight.sh --lint-only`.
No dependency but Python 3.
"""

import argparse
import re
import sys
from pathlib import Path

PATTERN = re.compile(r"""^\s*#\s*include\s*[<"]fa/runtime/internal/""")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    root = Path(ap.parse_args().root)
    bad = []
    for top in ("player", "templates"):
        base = root / top
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in (".h", ".hpp", ".c", ".cc", ".cpp", ".m", ".mm", ".inl"):
                continue
            for n, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                if PATTERN.match(line):
                    bad.append(f"{path.relative_to(root).as_posix()}:{n}: {line.strip()}")
    if bad:
        print("error: player/ and templates/ must not include fa/runtime/internal/ (it is for the engine and the developer "
              "tools; use the public headers of fa/runtime/ or move the code to tools/):", file=sys.stderr)
        for b in bad:
            print("  " + b, file=sys.stderr)
        return 1
    print("check-player-includes ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
