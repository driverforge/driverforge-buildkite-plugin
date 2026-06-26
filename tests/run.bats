#!/usr/bin/env bats

# Flag-mapping unit tests — source the run lib and inspect the ANVIL_ARGS array
# it builds from the plugin config. (Each bats test runs in its own subshell, so
# exported config doesn't leak between tests.)

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/anvil-run.bash"
}

@test "setup-only: no command yields empty args" {
  anvil_build_args
  [ "${#ANVIL_ARGS[@]}" -eq 0 ]
}

@test "build maps configuration and increment" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_CONFIGURATION=release
  export BUILDKITE_PLUGIN_ANVIL_INCREMENT=patch
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --configuration release --increment=patch" ]
}

@test "increment=true emits a bare flag" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_INCREMENT=true
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --increment" ]
}

@test "boolean flags and project-dir" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_PROJECT_DIR=./driver
  export BUILDKITE_PLUGIN_ANVIL_SOURCEMAP=true
  export BUILDKITE_PLUGIN_ANVIL_UNPACK=true
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --project-dir ./driver --sourcemap --unpack" ]
}

@test "args escape hatch is appended verbatim" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_ARGS="--future-flag x"
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --future-flag x" ]
}
