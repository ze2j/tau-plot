#!/usr/bin/env python3
"""Generate the addon README from the repository README.

    python3 tools/gen_addon_readme.py

The addon copy is the repository README minus the sections that only make sense
next to the repository. Paths under the addon folder are rebased on it, links
leaving it become GitHub URLs. Editing the repository README and running this
script is the only supported way to change the addon copy.

Only markdown link targets are absolutized. The one HTML block in the README is
the gallery, and the gallery is dropped.
"""

import os
import re
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_README = REPO_ROOT / "README.md"
ADDON_DIR = REPO_ROOT / "addons" / "tau-plot"
ADDON_README = ADDON_DIR / "README.md"

# The gallery images live outside the addon, and a reader of the addon copy
# already installed it.
DROPPED_SECTIONS = ("Gallery", "Installation")

ADDON_PATH_PREFIX = "addons/tau-plot/"

# The slash-less form survives the prefix rewrite and would ship a broken link.
STALE_PATH_MARKER = "addons/tau-plot"

# A target outside the addon folder has nothing to resolve against once shipped.
GITHUB_TREE_URL = "https://github.com/ze2j/tau-plot/tree/main/"

MARKDOWN_LINK = re.compile(r"\]\((?P<target>[^()\s]+)\)")

# Link targets of the generated file, resolved relative to the addon folder.
REQUIRED_ADDON_ENTRIES = ("LICENSE", "CHANGELOG.md", "examples", "tests")


def fail(message: str) -> None:
    print("gen_addon_readme: " + message, file=sys.stderr)
    raise SystemExit(1)


def heading_title(line: str) -> str | None:
    """Title of a level 2 heading, None for anything else."""
    if not line.startswith("## "):
        return None
    return line[3:].strip()


def drop_sections(lines: list[str], titles: tuple[str, ...]) -> tuple[list[str], set[str]]:
    """Remove each named section, from its heading up to the next level 2 heading."""
    kept: list[str] = []
    dropped: set[str] = set()
    dropping = False
    in_code_fence = False
    for line in lines:
        if line.startswith("```"):
            in_code_fence = not in_code_fence
        # GDScript doc comments open with ##, so headings only count outside a fence.
        title = None if in_code_fence else heading_title(line)
        if title is not None:
            dropping = title in titles
            if dropping:
                dropped.add(title)
        if not dropping:
            kept.append(line)
    return kept, dropped


def absolutize_outside_links(text: str) -> str:
    """Send targets the addon folder does not contain to GitHub, leave the rest alone."""

    def rewrite(match: re.Match) -> str:
        target = match.group("target")
        # A scheme is already resolvable from anywhere.
        if ":" in target:
            return match.group(0)
        # An anchor rides along with its target, or stands alone as a same page link.
        path = target.partition("#")[0]
        if not path or path.startswith(ADDON_PATH_PREFIX) or (ADDON_DIR / path).exists():
            return match.group(0)
        return "](%s%s)" % (GITHUB_TREE_URL, target)

    return MARKDOWN_LINK.sub(rewrite, text)


def build_addon_readme() -> str:
    lines = SOURCE_README.read_text(encoding="utf-8").splitlines(keepends=True)
    kept, dropped = drop_sections(lines, DROPPED_SECTIONS)

    missing_sections = [title for title in DROPPED_SECTIONS if title not in dropped]
    if missing_sections:
        fail("sections not found in %s: %s" % (SOURCE_README, ", ".join(missing_sections)))

    # Rebasing runs second, so the link pass still sees which targets are addon relative.
    text = absolutize_outside_links("".join(kept)).replace(ADDON_PATH_PREFIX, "")
    if STALE_PATH_MARKER in text:
        fail("%s path survived the rewrite, check its trailing slash" % STALE_PATH_MARKER)

    return text.rstrip("\n") + "\n"


def check_link_targets() -> None:
    missing_entries = [name for name in REQUIRED_ADDON_ENTRIES if not (ADDON_DIR / name).exists()]
    if missing_entries:
        fail("missing under %s: %s" % (ADDON_DIR, ", ".join(missing_entries)))


def main() -> None:
    text = build_addon_readme()
    check_link_targets()

    handle, temp_path = tempfile.mkstemp(dir=ADDON_README.parent, prefix=".gen_addon_readme.")
    try:
        with os.fdopen(handle, "w", encoding="utf-8", newline="\n") as temp_file:
            temp_file.write(text)
        # mkstemp creates owner-only, the committed file is world readable.
        os.chmod(temp_path, 0o644)
    except BaseException:
        os.unlink(temp_path)
        raise
    # Atomic within a filesystem, so the destination is never half written.
    os.replace(temp_path, ADDON_README)
    print("wrote %s" % ADDON_README.relative_to(REPO_ROOT))


main()
