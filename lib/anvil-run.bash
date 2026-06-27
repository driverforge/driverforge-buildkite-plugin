#!/bin/bash
# Map the plugin's BUILDKITE_PLUGIN_ANVIL_* config to an `anvil <command>` argv
# (into the ANVIL_ARGS array) and run it.
#
# LOCKSTEP: the flag mapping here is kept identical to
# anvil-github-action/scripts/run.sh. Change both together.

anvil__is_true() { case "${1:-}" in true | yes | 1) return 0 ;; *) return 1 ;; esac }

# Populates the global ANVIL_ARGS array from the plugin config.
anvil_build_args() {
  ANVIL_ARGS=()

  local cmd="${BUILDKITE_PLUGIN_ANVIL_COMMAND:-}"
  if [ -n "$cmd" ]; then ANVIL_ARGS+=("$cmd"); fi

  if [ -n "${BUILDKITE_PLUGIN_ANVIL_PROJECT_DIR:-}" ]; then
    ANVIL_ARGS+=(--project-dir "${BUILDKITE_PLUGIN_ANVIL_PROJECT_DIR}")
  fi
  if [ -n "${BUILDKITE_PLUGIN_ANVIL_CONFIGURATION:-}" ]; then
    ANVIL_ARGS+=(--configuration "${BUILDKITE_PLUGIN_ANVIL_CONFIGURATION}")
  fi

  # increment: "true" -> bare flag (CLI default bump); a value -> --increment=<value>
  case "${BUILDKITE_PLUGIN_ANVIL_INCREMENT:-}" in
    "" | false | no) : ;;
    true | yes) ANVIL_ARGS+=(--increment) ;;
    *) ANVIL_ARGS+=("--increment=${BUILDKITE_PLUGIN_ANVIL_INCREMENT}") ;;
  esac

  # encrypt: omit = leave driver.xml as authored; true = force on; false = force off.
  # The CLI's --encrypt is a boolean (--encrypt / --encrypt=false), not a mode value.
  case "${BUILDKITE_PLUGIN_ANVIL_ENCRYPT:-}" in
    "") : ;;
    true | yes | 1) ANVIL_ARGS+=(--encrypt) ;;
    false | no | 0) ANVIL_ARGS+=(--encrypt=false) ;;
    *)
      printf 'anvil plugin: %s\n' "encrypt must be true or false (got '${BUILDKITE_PLUGIN_ANVIL_ENCRYPT}')" >&2
      exit 1
      ;;
  esac

  if anvil__is_true "${BUILDKITE_PLUGIN_ANVIL_SOURCEMAP:-}"; then ANVIL_ARGS+=(--sourcemap); fi
  if anvil__is_true "${BUILDKITE_PLUGIN_ANVIL_UNPACK:-}"; then ANVIL_ARGS+=(--unpack); fi
  if anvil__is_true "${BUILDKITE_PLUGIN_ANVIL_DEPLOY:-}"; then ANVIL_ARGS+=(--deploy); fi
  if anvil__is_true "${BUILDKITE_PLUGIN_ANVIL_SYNC:-}"; then ANVIL_ARGS+=(--sync); fi

  if anvil__is_true "${BUILDKITE_PLUGIN_ANVIL_DEPLOY:-}" && anvil__is_true "${BUILDKITE_PLUGIN_ANVIL_SYNC:-}"; then
    printf 'anvil plugin: %s\n' "deploy and sync are mutually exclusive" >&2
    exit 1
  fi

  # args escape hatch: appended verbatim (intentional word-split).
  if [ -n "${BUILDKITE_PLUGIN_ANVIL_ARGS:-}" ]; then
    # shellcheck disable=SC2206
    local extra=(${BUILDKITE_PLUGIN_ANVIL_ARGS})
    ANVIL_ARGS+=("${extra[@]}")
  fi
}

anvil_run() {
  anvil_build_args
  printf '+ anvil %s\n' "${ANVIL_ARGS[*]}" >&2
  exec anvil "${ANVIL_ARGS[@]}"
}
