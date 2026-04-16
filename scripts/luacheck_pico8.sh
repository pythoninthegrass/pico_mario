#!/usr/bin/env bash

set -euo pipefail

# Wrapper around luacheck for PICO-8 Lua dialect.
# Converts != to ~= (PICO-8 not-equal syntax) in temp copies before linting.

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/luacheck.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

exit_code=0

for file in "$@"; do
	tmp="$tmpdir/$(basename "$file")"
	sed 's/!=/~=/g' "$file" > "$tmp"
	luacheck --no-color --filename "$file" "$tmp" || exit_code=$?
done

exit "$exit_code"
