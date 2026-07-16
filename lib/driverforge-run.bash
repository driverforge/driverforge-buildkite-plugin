#!/bin/bash
# Map the plugin's BUILDKITE_PLUGIN_DRIVERFORGE_* config to an `driverforge <command>` argv
# (into the DRIVERFORGE_ARGS array) and run it.
#
# LOCKSTEP: the flag mapping here is kept identical to
# driverforge-github-action/scripts/run.sh. Change both together.

driverforge__is_true() { case "${1:-}" in true | yes | 1) return 0 ;; *) return 1 ;; esac }

# Populates the global DRIVERFORGE_ARGS array from the plugin config.
driverforge_build_args() {
  DRIVERFORGE_ARGS=()

  local cmd="${BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND:-}"
  if [ -n "$cmd" ]; then DRIVERFORGE_ARGS+=("$cmd"); fi

  if [ -n "${BUILDKITE_PLUGIN_DRIVERFORGE_PROJECT_DIR:-}" ]; then
    DRIVERFORGE_ARGS+=(--project-dir "${BUILDKITE_PLUGIN_DRIVERFORGE_PROJECT_DIR}")
  fi
  if [ -n "${BUILDKITE_PLUGIN_DRIVERFORGE_CONFIGURATION:-}" ]; then
    DRIVERFORGE_ARGS+=(--configuration "${BUILDKITE_PLUGIN_DRIVERFORGE_CONFIGURATION}")
  fi

  # increment: "true" -> bare flag (CLI default bump); a value -> --increment=<value>
  case "${BUILDKITE_PLUGIN_DRIVERFORGE_INCREMENT:-}" in
    "" | false | no) : ;;
    true | yes) DRIVERFORGE_ARGS+=(--increment) ;;
    *) DRIVERFORGE_ARGS+=("--increment=${BUILDKITE_PLUGIN_DRIVERFORGE_INCREMENT}") ;;
  esac

  # driver-version: stamp an absolute <version> (driverforge build --version) —
  # mutually exclusive with increment, mirroring the CLI.
  if [ -n "${BUILDKITE_PLUGIN_DRIVERFORGE_DRIVER_VERSION:-}" ]; then
    case "${BUILDKITE_PLUGIN_DRIVERFORGE_INCREMENT:-}" in
      "" | false | no) : ;;
      *)
        printf 'driverforge plugin: %s\n' "increment and driver-version are mutually exclusive" >&2
        exit 1
        ;;
    esac
    DRIVERFORGE_ARGS+=(--version "${BUILDKITE_PLUGIN_DRIVERFORGE_DRIVER_VERSION}")
  fi

  # encrypt: omit = leave driver.xml as authored; true = force on; false = force off.
  # The CLI's --encrypt is a boolean (--encrypt / --encrypt=false), not a mode value.
  case "${BUILDKITE_PLUGIN_DRIVERFORGE_ENCRYPT:-}" in
    "") : ;;
    true | yes | 1) DRIVERFORGE_ARGS+=(--encrypt) ;;
    false | no | 0) DRIVERFORGE_ARGS+=(--encrypt=false) ;;
    *)
      printf 'driverforge plugin: %s\n' "encrypt must be true or false (got '${BUILDKITE_PLUGIN_DRIVERFORGE_ENCRYPT}')" >&2
      exit 1
      ;;
  esac

  # no-suffix: omit = suffix named configurations as usual; true = build under the
  # naked driver name; false = force suffixing back on (boolean, like --encrypt).
  case "${BUILDKITE_PLUGIN_DRIVERFORGE_NO_SUFFIX:-}" in
    "") : ;;
    true | yes | 1) DRIVERFORGE_ARGS+=(--no-suffix) ;;
    false | no | 0) DRIVERFORGE_ARGS+=(--no-suffix=false) ;;
    *)
      printf 'driverforge plugin: %s\n' "no-suffix must be true or false (got '${BUILDKITE_PLUGIN_DRIVERFORGE_NO_SUFFIX}')" >&2
      exit 1
      ;;
  esac

  if driverforge__is_true "${BUILDKITE_PLUGIN_DRIVERFORGE_SOURCEMAP:-}"; then DRIVERFORGE_ARGS+=(--sourcemap); fi
  if driverforge__is_true "${BUILDKITE_PLUGIN_DRIVERFORGE_UNPACK:-}"; then DRIVERFORGE_ARGS+=(--unpack); fi

  # args escape hatch: appended verbatim (intentional word-split).
  if [ -n "${BUILDKITE_PLUGIN_DRIVERFORGE_ARGS:-}" ]; then
    # shellcheck disable=SC2206
    local extra=(${BUILDKITE_PLUGIN_DRIVERFORGE_ARGS})
    DRIVERFORGE_ARGS+=("${extra[@]}")
  fi
}

driverforge_run() {
  driverforge_build_args
  printf '+ driverforge %s\n' "${DRIVERFORGE_ARGS[*]}" >&2
  exec driverforge "${DRIVERFORGE_ARGS[@]}"
}
