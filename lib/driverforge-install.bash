#!/bin/bash
# Install the Driverforge CLI onto the agent and export it onto PATH. Resolves "latest"
# through the release manifest, verifies the archive checksum, and caches the
# binary per-agent (keyed by version) so repeat builds don't re-download.
#
# LOCKSTEP: the detect / resolve / download / checksum logic here is kept
# identical to driverforge-github-action/scripts/install.sh. Change both together.

DRIVERFORGE_RELEASES_BASE="https://releases.driverforge.com/driverforge-releases/driverforge-cli"

driverforge__log() { printf '%s\n' "$*" >&2; }
driverforge__die() {
  printf 'driverforge plugin: %s\n' "$*" >&2
  exit 1
}

driverforge__detect_os() {
  case "$(uname -s)" in
    Linux) echo linux ;;
    Darwin) echo darwin ;;
    *) driverforge__die "unsupported OS: $(uname -s) (linux/macOS agents only for now)" ;;
  esac
}

driverforge__detect_arch() {
  case "$(uname -m)" in
    x86_64 | amd64) echo amd64 ;;
    aarch64 | arm64) echo arm64 ;;
    *) driverforge__die "unsupported arch: $(uname -m)" ;;
  esac
}

driverforge__sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

driverforge__resolve_version() {
  local want="${1:-latest}"
  want="${want#v}"
  if [ -n "$want" ] && [ "$want" != "latest" ]; then
    echo "$want"
    return
  fi
  local manifest
  manifest="$(curl -fsSL "${DRIVERFORGE_RELEASES_BASE}/latest/manifest.json")" \
    || driverforge__die "could not fetch latest manifest from ${DRIVERFORGE_RELEASES_BASE}/latest/manifest.json"
  local v
  if command -v jq >/dev/null 2>&1; then
    v="$(printf '%s' "$manifest" | jq -r '.version')"
  else
    v="$(printf '%s' "$manifest" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  fi
  if [ -z "$v" ] || [ "$v" = "null" ]; then
    driverforge__die "could not parse version from latest manifest"
  fi
  echo "$v"
}

driverforge_install() {
  local os arch version
  os="$(driverforge__detect_os)"
  arch="$(driverforge__detect_arch)"
  version="$(driverforge__resolve_version "${BUILDKITE_PLUGIN_DRIVERFORGE_VERSION:-latest}")"

  local base="${DRIVERFORGE_RELEASES_BASE}/v${version}"
  local archive="driverforge_${version}_${os}_${arch}.tar.gz"

  local cache_root="${BUILDKITE_PLUGIN_DRIVERFORGE_CACHE_DIR:-${HOME}/.cache/driverforge-buildkite}"
  local dest="${cache_root}/driverforge/${version}/${arch}"
  local bin="${dest}/driverforge"

  if [ ! -x "$bin" ]; then
    driverforge__log "Installing driverforge ${version} (${os}/${arch})"
    local tmp
    tmp="$(mktemp -d)"

    curl -fsSL -o "${tmp}/${archive}" "${base}/${archive}" \
      || driverforge__die "download failed: ${base}/${archive}"
    curl -fsSL -o "${tmp}/checksums.txt" "${base}/checksums.txt" \
      || driverforge__die "checksums download failed: ${base}/checksums.txt"

    local want got
    want="$(grep " ${archive}\$" "${tmp}/checksums.txt" | awk '{print $1}' | head -n1)"
    [ -n "$want" ] || driverforge__die "no checksum entry for ${archive} in checksums.txt"
    got="$(driverforge__sha256_of "${tmp}/${archive}")"
    [ "$want" = "$got" ] || driverforge__die "checksum mismatch for ${archive}: expected ${want}, got ${got}"

    tar -xzf "${tmp}/${archive}" -C "$tmp"
    [ -f "${tmp}/driverforge" ] || driverforge__die "archive did not contain a 'driverforge' binary"
    mkdir -p "$dest"
    install -m 0755 "${tmp}/driverforge" "$bin"
    rm -rf "$tmp"
  else
    driverforge__log "Reusing cached driverforge ${version} (${os}/${arch})"
  fi

  export PATH="${dest}:${PATH}"
  driverforge__log "driverforge ${version} ready on PATH"
}
