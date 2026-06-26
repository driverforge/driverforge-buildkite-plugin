#!/usr/bin/env bats

# Command-hook dispatch tests. Stubs `anvil` (and the step command) so no real
# CLI or network is needed. Uses the plugin-tester's bundled bats helpers
# (assert/mock) via load.bash.

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"
}

teardown() {
  unstub anvil 2>/dev/null || true
}

@test "runs the anvil target when command is configured" {
  export BUILDKITE_PLUGIN_ANVIL_COMMAND=build
  export BUILDKITE_PLUGIN_ANVIL_CONFIGURATION=release

  stub anvil 'build --configuration release : echo ran-anvil-build'

  run "${BATS_TEST_DIRNAME}/../hooks/command"

  assert_success
  assert_output --partial ran-anvil-build
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
