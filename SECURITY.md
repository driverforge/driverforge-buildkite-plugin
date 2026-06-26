# Security Policy

## Reporting a vulnerability

Please report security issues **privately** — do not open a public issue.

- **Preferred:** GitHub's [private vulnerability reporting](https://docs.github.com/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository (**Security → Report a vulnerability**).
- **Or** email **oss@driverforge.com**.

Please include a description, reproduction steps, and the affected version where you can. We'll acknowledge your report and keep you posted on the fix.

## Scope

This policy covers the Anvil **Buildkite plugin** in this repository — the plugin that installs the `anvil` CLI onto a Buildkite agent and optionally runs it. The plugin ships **no credentials of its own**: it downloads a pinned, checksum-verified `anvil` release from Driverforge's public release storage and puts it on `PATH`. The `anvil` CLI itself, the Anvil backend/ingestion, and the agent are separate and out of scope here.

## Supported versions

We support the latest released `v1` of the plugin — please confirm the issue on the current release before reporting.
