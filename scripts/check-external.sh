#!/usr/bin/env bash
# check-external.sh — detect drift between vpinball's upstream build
# scripts and the inputs wired into this flake.
#
# Strategy: for each *_SHA / *_VERSION variable that vpinball's
# linux-x64/external.sh actually references (and the equivalent for the
# transitive libdmdutil/libdof/libzedmd configs), make sure flake.nix's
# update hooks also reference it. Any var that isn't referenced is a
# potential new upstream dependency that hasn't been wired into the
# flake yet.
#
# Platform is hard-coded to linux-x64 because that's the only system
# this flake supports. Vars declared in config.sh but unused on linux-x64
# (e.g. OPENXR_SHA, which is windows/android only) are intentionally
# ignored.
#
# Exit 0 on clean, 1 on drift detected, 2 on tool failure.

set -euo pipefail

FLAKE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_ROOT"

die() { echo "error: $*" >&2; exit 2; }

# Resolve a source path (from flake inputs or dynamically resolved sources).
input_path() {
  local name="$1"
  nix eval --raw --impure --expr \
    "let flake = builtins.getFlake (toString ./.); in (flake.inputs.${name}.outPath or flake.legacyPackages.x86_64-linux.sources.${name}.outPath)" \
    2>/dev/null || die "failed to resolve input '${name}'"
}

# Extract all *_SHA and *_VERSION assignment names from a config.sh.
extract_vars() {
  local file="$1"
  [[ -f "$file" ]] || { echo "warn: missing $file" >&2; return 0; }
  grep -oE '^[[:space:]]*[A-Z_][A-Z0-9_]*(_SHA|_VERSION)=' "$file" \
    | tr -d ' \t' | sed 's/=$//' | sort -u
}

# Extract *_SHA/*_VERSION variables actually referenced by a given
# external.sh (or any bash file). Used to restrict the audit to the
# Linux platform so Windows/Android-only deps (e.g. OPENXR_SHA) don't
# trigger false positives.
extract_refs() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -oE '\$\{?[A-Z_][A-Z0-9_]*(_SHA|_VERSION)\}?' "$file" \
    | tr -d '${}' | sort -u
}

# Intersection of "vars declared in config.sh" and "vars referenced by
# this platform's external.sh". The result is the set the platform
# actually cares about.
used_vars() {
  local config="$1" ext="$2"
  comm -12 <(extract_vars "$config") <(extract_refs "$ext")
}

# Extract all *_SHA / *_VERSION names referenced by upstream-sources.nix or flake.nix.
extract_known() {
  grep -h -oE '[A-Z_][A-Z0-9_]*(_SHA|_VERSION)' upstream-sources.nix flake.nix \
    | grep -v '^OLD_' | sort -u
}

VPINBALL_SRC="$(input_path vpinball)"
LIBDMDUTIL_SRC="$(input_path libdmdutil)"
LIBDOF_SRC="$(input_path libdof)"
LIBZEDMD_SRC="$(input_path libzedmd)"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

declared="$tmpdir/declared"
known="$tmpdir/known"

# vpinball uses platforms/linux-x64/external.sh; the PPUC/libdof family
# uses platforms/linux/x64/external.sh. Different layouts, same idea.
{
  used_vars "$VPINBALL_SRC/platforms/config.sh" \
            "$VPINBALL_SRC/platforms/linux-x64/external.sh"
  used_vars "$LIBDMDUTIL_SRC/platforms/config.sh" \
            "$LIBDMDUTIL_SRC/platforms/linux/x64/external.sh"
  used_vars "$LIBDOF_SRC/platforms/config.sh" \
            "$LIBDOF_SRC/platforms/linux/x64/external.sh"
  used_vars "$LIBZEDMD_SRC/platforms/config.sh" \
            "$LIBZEDMD_SRC/platforms/linux/x64/external.sh"
} | sort -u > "$declared"

extract_known > "$known"

# Vars declared upstream but not referenced by flake.nix update hooks.
missing="$(comm -23 "$declared" "$known")"

# Vars referenced by flake.nix but no longer declared upstream.
# Informational only — not an error; could be a rename or a dep that
# vpinball actually still needs but moved to a different file.
stale="$(comm -13 "$declared" "$known")"

echo "=== check-external.sh ==="
echo "upstream declares $(wc -l <"$declared") SHA/VERSION vars"
echo "flake.nix handles $(wc -l <"$known") SHA/VERSION vars"
echo

if [[ -n "$missing" ]]; then
  echo "DRIFT: upstream vars not wired into this flake:" >&2
  echo "$missing" | sed 's/^/  - /' >&2
  echo >&2
  echo "Each missing var likely corresponds to a new dependency that" >&2
  echo "vpinball has added upstream. Add a matching flake input in" >&2
  echo "flake.nix and a corresponding nix flake update ... line in the" >&2
  echo "updateDirectInputs or updateChildInputs shellHook." >&2
  exit 1
fi

if [[ -n "$stale" ]]; then
  echo "note: flake.nix references vars not currently declared upstream:"
  echo "$stale" | sed 's/^/  - /'
  echo "(not an error — could be a rename or transitive config file move)"
fi

echo "OK: no drift detected."
