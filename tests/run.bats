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

@test "driver-version maps to --version" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_DRIVER_VERSION=2026071501
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --version 2026071501" ]
}

@test "driver-version and increment are mutually exclusive" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_DRIVER_VERSION=2026071501
  export BUILDKITE_PLUGIN_ANVIL_INCREMENT=patch
  run anvil_build_args
  [ "$status" -ne 0 ]
  [[ "$output" == *"mutually exclusive"* ]]
}

@test "no-suffix=true emits the bare flag" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_NO_SUFFIX=true
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --no-suffix" ]
}

@test "no-suffix=false forces suffixing back on" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_NO_SUFFIX=false
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --no-suffix=false" ]
}

@test "release build combines configuration, driver-version, encrypt, no-suffix" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_CONFIGURATION=prod
  export BUILDKITE_PLUGIN_ANVIL_DRIVER_VERSION=2026071501
  export BUILDKITE_PLUGIN_ANVIL_ENCRYPT=true
  export BUILDKITE_PLUGIN_ANVIL_NO_SUFFIX=true
  anvil_build_args
  [ "${ANVIL_ARGS[*]}" = "build --configuration prod --version 2026071501 --encrypt --no-suffix" ]
}
