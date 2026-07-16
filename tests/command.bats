#!/usr/bin/env bats

# Command-hook dispatch tests. Stubs `driverforge` (and the step command) so no real
# CLI or network is needed. Uses the plugin-tester's bundled bats helpers
# (assert/mock) via load.bash.

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"
}

teardown() {
  unstub driverforge 2>/dev/null || true
}

@test "runs the driverforge target when command is configured" {
  export BUILDKITE_PLUGIN_DRIVERFORGE_COMMAND=build
  export BUILDKITE_PLUGIN_DRIVERFORGE_CONFIGURATION=release

  stub driverforge 'build --configuration release : echo ran-driverforge-build'

  run "${BATS_TEST_DIRNAME}/../hooks/command"

  assert_success
  assert_output --partial ran-driverforge-build
}

@test "setup-only: runs the step's own command" {
  export BUILDKITE_COMMAND='echo ran-step-command'

  run "${BATS_TEST_DIRNAME}/../hooks/command"

  assert_success
  assert_output --partial ran-step-command
}

@test "setup-only with no step command is a no-op" {
  run "${BATS_TEST_DIRNAME}/../hooks/command"

  assert_success
  assert_output --partial "nothing to run"
}
