#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13,<3.14"
# dependencies = []
# [tool.uv]
# exclude-newer = "2026-04-30T00:00:00Z"
# ///

"""
Usage:
    uv run scripts/count_tokens.py [PATH]

Args:
    PATH: .p8 cartridge to analyze. Default: <repo>/mario.p8

Count PICO-8 code tokens following the rules documented in the manual:

  - Brackets and strings count as one token each.
  - Commas, periods, LOCAL, semi-colons, END, and comments are NOT counted.
  - Everything else (identifiers, numbers, operators, keywords) is one token.

This mirrors PICO-8's own counter closely enough for a CI sanity check
against the 8192 token hard limit. For authoritative counts, open the
cart in PICO-8 and read the bottom-right of the code editor.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

TOKEN_LIMIT = 8192

# Tokens that PICO-8 does NOT count (must match as whole words where applicable).
FREE_KEYWORDS = {"local", "end"}
# Single-char punctuation PICO-8 doesn't count.
FREE_PUNCT = {",", ".", ";"}


def strip_comments(src: str) -> str:
    """Remove PICO-8 lua comments: -- line and --[[ block ]]."""
    # Remove long-bracket block comments --[[ ... ]]
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.DOTALL)
    # Remove line comments: -- to end-of-line
    src = re.sub(r"--[^\n]*", "", src)
    return src


def extract_lua_section(cart_path: Path) -> str:
    """Return the concatenated __lua__ section of a .p8 cart."""
    text = cart_path.read_text()
    in_lua = False
    lines: list[str] = []
    for line in text.splitlines():
        if line.startswith("__lua__"):
            in_lua = True
            continue
        if in_lua and line.startswith("__") and line.endswith("__"):
            break
        if in_lua:
            lines.append(line)
    return "\n".join(lines)


# Token regex:
#   - strings (single/double quoted, with escapes)
#   - long-bracket strings [[...]]
#   - numbers (int, float, hex, binary)
#   - identifiers / keywords
#   - multi-char operators
#   - single-char punctuation/operators
TOKEN_RE = re.compile(
    r"""
    "(?:\\.|[^"\\])*"                     |  # double-quoted string
    '(?:\\.|[^'\\])*'                     |  # single-quoted string
    \[\[.*?\]\]                           |  # long-bracket string
    0x[0-9a-fA-F.]+                       |  # hex literal
    0b[01.]+                              |  # binary literal
    \d+\.?\d*                             |  # decimal / float
    \.\d+                                 |  # leading-dot float
    [A-Za-z_][A-Za-z_0-9]*                |  # identifier / keyword
    ==|~=|!=|<=|>=|\.\.|\.\.\.|::|<<|>>|\^\^|\+=|-=|\*=|/=|%=|\.\.= |  # multi-char ops
    [<>+\-*/%^#&|~?!:=(){}\[\]]           |  # single-char ops/brackets
    [,.;]                                    # free punctuation
    """,
    re.VERBOSE | re.DOTALL,
)


def count_tokens(src: str) -> int:
    src = strip_comments(src)
    count = 0
    for m in TOKEN_RE.finditer(src):
        tok = m.group(0)
        if tok in FREE_PUNCT:
            continue
        if tok.lower() in FREE_KEYWORDS:
            continue
        count += 1
    return count


def main() -> int:
    if len(sys.argv) > 1:
        cart = Path(sys.argv[1])
    else:
        cart = Path(__file__).resolve().parent.parent / "mario.p8"

    if not cart.exists():
        print(f"error: {cart} does not exist", file=sys.stderr)
        return 2

    lua = extract_lua_section(cart)
    tokens = count_tokens(lua)
    pct = 100.0 * tokens / TOKEN_LIMIT
    status = "OK" if tokens <= TOKEN_LIMIT else "OVER LIMIT"
    print(f"{cart.name}: {tokens} tokens / {TOKEN_LIMIT} ({pct:.1f}%) [{status}]")
    return 0 if tokens <= TOKEN_LIMIT else 1


if __name__ == "__main__":
    raise SystemExit(main())
