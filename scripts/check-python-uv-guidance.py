#!/usr/bin/env python3
"""Validate shared setup-python-uv contract and guidance examples.

The checks are intentionally text-based and dependency-free so they can run in
the repository self-test without installing Python packages.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_contains(text: str, needle: str, label: str) -> None:
    require(needle in text, f"{label} missing {needle!r}")


def check_composite() -> None:
    action = read(".github/actions/setup-python-uv/action.yml")

    require_contains(action, "sync-args:", "setup-python-uv action")
    require(
        re.search(r"sync-args:\n(?:    .+\n)*?    default: \"--all-groups\"", action) is not None,
        "sync-args compatibility default must remain --all-groups",
    )
    require_contains(action, "sync-enabled:", "setup-python-uv action")
    require(
        re.search(r"sync-enabled:\n(?:    .+\n)*?    default: \"true\"", action) is not None,
        "sync-enabled must default to the string true",
    )
    require_contains(action, "if: ${{ inputs.sync-enabled != 'false' }}", "Sync dependencies step")
    require_contains(action, "uv sync ${UV_SYNC_ARGS}", "Sync dependencies step")


def check_guidance_docs() -> None:
    for relative in ("README.md", "docs/ci-standard.md"):
        text = read(relative)
        require_contains(text, "--only-group lint --frozen", relative)
        require_contains(text, "--all-groups --frozen", relative)
        require_contains(text, 'sync-enabled: "false"', relative)
        require_contains(text, "compatibility default", relative)
        require_contains(text, "repo-owned", relative)


def check_example_workflow() -> None:
    example = read("examples/pokeedge-python/ci.yml")
    uses_count = example.count(".github/actions/setup-python-uv@")
    sync_args_count = example.count("sync-args:")
    require(uses_count == 3, f"expected 3 setup-python-uv example uses, got {uses_count}")
    require(
        sync_args_count == uses_count,
        f"each setup-python-uv example use must set explicit sync-args ({sync_args_count}/{uses_count})",
    )
    require_contains(example, "--only-group lint --frozen", "examples/pokeedge-python/ci.yml")
    require_contains(example, "--all-groups --frozen", "examples/pokeedge-python/ci.yml")
    require_contains(example, "group names are app-owned", "examples/pokeedge-python/ci.yml")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--composite-only",
        action="store_true",
        help="Validate only action metadata; used while docs/examples are still being updated.",
    )
    args = parser.parse_args()

    try:
        check_composite()
        if not args.composite_only:
            check_guidance_docs()
            check_example_workflow()
    except AssertionError as error:
        print(f"python uv guidance check failed: {error}", file=sys.stderr)
        return 1

    scope = "composite" if args.composite_only else "composite/docs/examples"
    print(f"python uv guidance check passed: {scope}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
