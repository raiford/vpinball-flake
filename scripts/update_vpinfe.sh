#!/usr/bin/env bash
# update_vpinfe — pin the vpinfe flake input to the latest GitHub release.
#
# Resolves the latest non-prerelease, non-draft release tag of
# superhac/vpinfe via the GitHub API, sets that tag as `ref` in the
# vpinfe input block of flake.nix, and runs `nix flake update vpinfe`
# to refresh the lock.
#
# Note: curl -L is required because the repository has been moved/renamed
# and the API responds with a redirect.
#
# Exit 0 on success, 2 on tool/network failure.

set -eu

FLAKE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_ROOT"

OWNER="superhac"
REPO="vpinfe"

die() { echo "error: $*" >&2; exit 2; }

command -v curl >/dev/null || die "curl not found"
command -v awk >/dev/null || die "awk not found"
command -v nix >/dev/null || die "nix not found"

# /releases/latest returns the newest non-prerelease, non-draft release.
# Extract "tag_name" from the JSON response with sed.
TAG="$(curl -sfL "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" \
  | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -n1)" || die "failed to resolve latest release tag for ${OWNER}/${REPO}"
[ -n "$TAG" ] || die "failed to resolve latest release tag for ${OWNER}/${REPO}"

echo "latest vpinfe release: ${TAG}"

# Set/replace `ref` in the vpinfe input block of flake.nix.
# - If a `ref = "..."` line exists in the block, replace its value in place.
# - Otherwise, insert `ref = "TAG";` before the closing `};`, matching the
#   indentation of the previous line.
grep -qE '^[[:space:]]*vpinfe[[:space:]]*=[[:space:]]*\{' flake.nix \
  || die "vpinfe input block not found in flake.nix"

tmp="$(mktemp)"
awk -v tag="$TAG" '
  !inblk && /^[[:space:]]*vpinfe[[:space:]]*=[[:space:]]*\{/ { inblk = 1 }
  inblk {
    if ($0 ~ /^[[:space:]]*ref[[:space:]]*=/) {
      hasref = 1
      indent = $0
      sub(/ref.*/, "", indent)
      printf "%sref = \"%s\";\n", indent, tag
      next
    }
    if ($0 ~ /^[[:space:]]*\};/) {
      if (!hasref) {
        indent = previndent
        if (indent == "") { indent = $0; sub(/[};].*/, "", indent) }
        printf "%sref = \"%s\";\n", indent, tag
      }
      print
      inblk = 0
      next
    }
    if ($0 !~ /^[[:space:]]*$/) {
      previndent = $0
      sub(/[^[:space:]].*$/, "", previndent)
    }
  }
  { print }
' flake.nix > "$tmp"
mv "$tmp" flake.nix
echo "flake.nix: vpinfe ref -> ${TAG}"

git diff --no-color flake.nix || true

nix flake update vpinfe

echo "✅ vpinfe pinned to ${TAG}"
