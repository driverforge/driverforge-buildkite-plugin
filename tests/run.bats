#!/usr/bin/env bats

# Flag-mapping unit tests — source the run lib and inspect the DRIVERFORGE_ARGS array
# it builds from the plugin config. (Each bats test runs in its own subshell, so
# exported config doesn't leak between tests.)

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/driverforge-run.bash"
}

@test "setup-only: no command yields empty args" {
  driverforge_build_args
  [ "${#DRIVERFORGE_ARGS[@]}" -eq 0 ]
}

@test "build maps configuration and increment" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_CONFIGURATION=release
  export BUILDKITE_PLUGIN_DRIVERFORGE_INCREMENT=patch
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --configuration release --increment=patch" ]
}

@test "increment=true emits a bare flag" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_INCREMENT=true
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --increment" ]
}

@test "boolean flags and project-dir" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_PROJECT_DIR=./driver
  export BUILDKITE_PLUGIN_DRIVERFORGE_SOURCEMAP=true
  export BUILDKITE_PLUGIN_DRIVERFORGE_UNPACK=true
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --project-dir ./driver --sourcemap --unpack" ]
}

@test "warnings-as-errors=true emits the bare flag" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_WARNINGS_AS_ERRORS=true
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --warnings-as-errors" ]
}

@test "warnings-as-errors=false emits nothing" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_WARNINGS_AS_ERRORS=false
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build" ]
}

@test "args escape hatch is appended verbatim" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_ARGS="--future-flag x"
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --future-flag x" ]
}

@test "driver-version maps to --version" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_DRIVER_VERSION=2026071501
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --version 2026071501" ]
}

@test "driver-version and increment are mutually exclusive" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_DRIVER_VERSION=2026071501
  export BUILDKITE_PLUGIN_DRIVERFORGE_INCREMENT=patch
  run driverforge_build_args
  [ "$status" -ne 0 ]
  [[ "$output" == *"mutually exclusive"* ]]
}

@test "no-suffix=true emits the bare flag" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_NO_SUFFIX=true
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --no-suffix" ]
}

@test "no-suffix=false forces suffixing back on" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_NO_SUFFIX=false
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --no-suffix=false" ]
}

@test "release build combines configuration, driver-version, encrypt, no-suffix" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_CONFIGURATION=prod
  export BUILDKITE_PLUGIN_DRIVERFORGE_DRIVER_VERSION=2026071501
  export BUILDKITE_PLUGIN_DRIVERFORGE_ENCRYPT=true
  export BUILDKITE_PLUGIN_DRIVERFORGE_NO_SUFFIX=true
  driverforge_build_args
  [ "${DRIVERFORGE_ARGS[*]}" = "build --configuration prod --version 2026071501 --encrypt --no-suffix" ]
}
