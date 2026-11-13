#!/usr/bin/env bash
# check-external.sh — detect drift between vpinball's upstream build
# scripts and the inputs wired into this flake.
#
# Strategy: for each *_SHA / *_VERSION variable that a linux-x64
# external.sh actually references, across every repo in the dependency
# tree that ships a platforms/config.sh (vpinball, libdmdutil, libdof,
# libzedmd, libserum, libvni, libpupdmd), make sure
# upstream-sources.nix (the pure Nix SHA parser) also references it.
# Any var that isn't referenced is a potential new upstream dependency
# that hasn't been wired into the flake yet.
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
  { grep -oE '^[[:space:]]*[A-Z_][A-Z0-9_]*(_SHA|_VERSION)=' "$file" || true; } \
    | tr -d ' \t' | sed 's/=$//' | sort -u
}

# Extract *_SHA/*_VERSION variables actually referenced by a given
# external.sh (or any bash file). Used to restrict the audit to the
# Linux platform so Windows/Android-only deps (e.g. OPENXR_SHA) don't
# trigger false positives.
extract_refs() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  { grep -oE '\$\{?[A-Z_][A-Z0-9_]*(_SHA|_VERSION)\}?' "$file" || true; } \
    | tr -d '${}' | sort -u
}

# Intersection of "vars declared in config.sh" and "vars referenced by
# this platform's external.sh" file(s). The result is the set the
# platform actually cares about. Some builds (libserum) pull shared
# fetch logic from external-common.sh, so extra files can be passed.
used_vars() {
  local config="$1"; shift
  comm -12 <(extract_vars "$config") \
           <(for f in "$@"; do extract_refs "$f"; done | sort -u)
}

# Extract all *_SHA / *_VERSION names referenced by upstream-sources.nix or flake.nix.
extract_known() {
  grep -h -oE '[A-Z_][A-Z0-9_]*(_SHA|_VERSION)' upstream-sources.nix flake.nix \
    | grep -v '^OLD_' | sort -u
}

# All *_SHA/*_VERSION vars referenced by any linux-* external.sh under a
# source tree. vpinball uses platforms/linux-<arch>/external.sh; the
# PPUC/libdof family uses platforms/linux/<arch>/external.sh. Used only
# for the informational "not used by any linux build" note.
linux_refs() {
  local src="$1" f
  for f in "$src"/platforms/linux-*/external.sh \
           "$src"/platforms/linux/*/external.sh \
           "$src"/platforms/external-common.sh; do
    [[ -f "$f" ]] || continue
    extract_refs "$f"
  done | sort -u
}

VPINBALL_SRC="$(input_path vpinball)"
LIBDMDUTIL_SRC="$(input_path libdmdutil)"
LIBDOF_SRC="$(input_path libdof)"
LIBZEDMD_SRC="$(input_path libzedmd)"
LIBSERUM_SRC="$(input_path libserum)"
LIBVNI_SRC="$(input_path libvni)"
LIBPUPDMD_SRC="$(input_path libpupdmd)"

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
  # Leaf DMD libs pin their own (header-only) libframeutil copy.
  # libserum's linux build pulls it in via external-common.sh.
  used_vars "$LIBSERUM_SRC/platforms/config.sh" \
            "$LIBSERUM_SRC/platforms/linux/x64/external.sh" \
            "$LIBSERUM_SRC/platforms/external-common.sh"
  used_vars "$LIBVNI_SRC/platforms/config.sh" \
            "$LIBVNI_SRC/platforms/linux/x64/external.sh"
  # The pinned libpupdmd revision has no config.sh yet; newer upstream
  # revisions do. Audit it when present so a future pin bump is covered.
  if [[ -f "$LIBPUPDMD_SRC/platforms/config.sh" ]]; then
    used_vars "$LIBPUPDMD_SRC/platforms/config.sh" \
              "$LIBPUPDMD_SRC/platforms/linux/x64/external.sh"
  fi
} | sort -u > "$declared"

extract_known > "$known"

# Vars declared upstream but not referenced by upstream-sources.nix.
missing="$(comm -23 "$declared" "$known")"

# Vars referenced by upstream-sources.nix/flake.nix but not used by the
# linux-x64 build this flake targets. Informational only — not an
# error; the flake may fetch them for other platforms or for data.
# Vars not referenced by any linux-* build are called out explicitly.
stale="$(comm -13 "$declared" "$known")"
all_linux_refs="$tmpdir/all_linux_refs"
{
  linux_refs "$VPINBALL_SRC"
  linux_refs "$LIBDMDUTIL_SRC"
  linux_refs "$LIBDOF_SRC"
  linux_refs "$LIBZEDMD_SRC"
  linux_refs "$LIBSERUM_SRC"
  linux_refs "$LIBVNI_SRC"
  linux_refs "$LIBPUPDMD_SRC"
} | sort -u > "$all_linux_refs"

echo "=== check-external.sh ==="
echo "upstream declares $(wc -l <"$declared") SHA/VERSION vars"
echo "upstream-sources.nix handles $(wc -l <"$known") SHA/VERSION vars"
echo

if [[ -n "$missing" ]]; then
  echo "DRIFT: upstream vars not wired into this flake:" >&2
  echo "$missing" | sed 's/^/  - /' >&2
  echo >&2
  echo "Each missing var likely corresponds to a new dependency that" >&2
  echo "vpinball has added upstream. To wire it in:" >&2
  echo "  1. Add a fetch line in upstream-sources.nix (fetchGithub or" >&2
  echo "     fetchGitSubmodules, keyed off the config var)." >&2
  echo "  2. Create pkgs/<name>/default.nix with a derivation for it." >&2
  echo "  3. Wire it into the vpinPkgs scope in flake.nix, and into" >&2
  echo "     pkgs/vpinball/default.nix buildInputs if vpinball links it." >&2
  exit 1
fi

if [[ -n "$stale" ]]; then
  echo "note: upstream-sources.nix references vars not used by the linux-x64 build:"
  while IFS= read -r v; do
    if ! grep -qx "$v" "$all_linux_refs"; then
      echo "  - $v (not used by any linux-* build)"
    else
      echo "  - $v"
    fi
  done <<< "$stale"
  echo "(informational only — may be fetched for other platforms or for data)"
fi

echo "OK: no drift detected."
