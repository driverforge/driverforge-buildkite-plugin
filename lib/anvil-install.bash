#!/bin/bash
# Install the Driverforge CLI onto the agent and export it onto PATH. Resolves "latest"
# through the release manifest, verifies the archive checksum, and caches the
# binary per-agent (keyed by version) so repeat builds don't re-download.
#
# LOCKSTEP: the detect / resolve / download / checksum logic here is kept
# identical to anvil-github-action/scripts/install.sh. Change both together.

DRIVERFORGE_RELEASES_BASE="https://releases.driverforge.com/driverforge-releases/driverforge-cli"

anvil__log() { printf '%s\n' "$*" >&2; }
anvil__die() {
  printf 'anvil plugin: %s\n' "$*" >&2
  exit 1
}

anvil__detect_os() {
  case "$(uname -s)" in
    Linux) echo linux ;;
    Darwin) echo darwin ;;
    *) anvil__die "unsupported OS: $(uname -s) (linux/macOS agents only for now)" ;;
  esac
}

anvil__detect_arch() {
  case "$(uname -m)" in
    x86_64 | amd64) echo amd64 ;;
    aarch64 | arm64) echo arm64 ;;
    *) anvil__die "unsupported arch: $(uname -m)" ;;
  esac
}

anvil__sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

anvil__resolve_version() {
  local want="${1:-latest}"
  want="${want#v}"
  if [ -n "$want" ] && [ "$want" != "latest" ]; then
    echo "$want"
    return
  fi
  local manifest
  manifest="$(curl -fsSL "${DRIVERFORGE_RELEASES_BASE}/latest/manifest.json")" \
    || anvil__die "could not fetch latest manifest from ${DRIVERFORGE_RELEASES_BASE}/latest/manifest.json"
  local v
  if command -v jq >/dev/null 2>&1; then
    v="$(printf '%s' "$manifest" | jq -r '.version')"
  else
    v="$(printf '%s' "$manifest" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  fi
  if [ -z "$v" ] || [ "$v" = "null" ]; then
    anvil__die "could not parse version from latest manifest"
  fi
  echo "$v"
}

anvil_install() {
  local os arch version
  os="$(anvil__detect_os)"
  arch="$(anvil__detect_arch)"
  version="$(anvil__resolve_version "${BUILDKITE_PLUGIN_ANVIL_VERSION:-latest}")"

  local base="${DRIVERFORGE_RELEASES_BASE}/v${version}"
  local archive="driverforge_${version}_${os}_${arch}.tar.gz"

  local cache_root="${BUILDKITE_PLUGIN_ANVIL_CACHE_DIR:-${HOME}/.cache/driverforge-buildkite}"
  local dest="${cache_root}/driverforge/${version}/${arch}"
  local bin="${dest}/driverforge"

  if [ ! -x "$bin" ]; then
    anvil__log "Installing driverforge ${version} (${os}/${arch})"
    local tmp
    tmp="$(mktemp -d)"

    curl -fsSL -o "${tmp}/${archive}" "${base}/${archive}" \
      || anvil__die "download failed: ${base}/${archive}"
    curl -fsSL -o "${tmp}/checksums.txt" "${base}/checksums.txt" \
      || anvil__die "checksums download failed: ${base}/checksums.txt"

    local want got
    want="$(grep " ${archive}\$" "${tmp}/checksums.txt" | awk '{print $1}' | head -n1)"
    [ -n "$want" ] || anvil__die "no checksum entry for ${archive} in checksums.txt"
    got="$(anvil__sha256_of "${tmp}/${archive}")"
    [ "$want" = "$got" ] || anvil__die "checksum mismatch for ${archive}: expected ${want}, got ${got}"

    tar -xzf "${tmp}/${archive}" -C "$tmp"
    [ -f "${tmp}/driverforge" ] || anvil__die "archive did not contain a 'driverforge' binary"
    mkdir -p "$dest"
    install -m 0755 "${tmp}/driverforge" "$bin"
    rm -rf "$tmp"
  else
    anvil__log "Reusing cached driverforge ${version} (${os}/${arch})"
  fi

  export PATH="${dest}:${PATH}"
  anvil__log "driverforge ${version} ready on PATH"
}
