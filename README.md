# anvil-buildkite-plugin

Install the [Anvil CLI](https://github.com/driverforge/anvil-cli) onto a Buildkite agent and
optionally run a target (`build`, …). The customer-facing way to build and package Control4
drivers in a Buildkite pipeline.

**Model:** the `environment` hook always installs `anvil` onto `PATH`; the `command` hook
then either runs a configured target or your step's own command.

## Usage

### Environment setup only

`anvil` is put on `PATH`; the step's own `command:` does the work:

```yaml
steps:
  - command: anvil build -c release
    plugins:
      - driverforge/anvil#v1.0.0:
          version: '1.4.0'        # pinned, or 'latest'
```

### Run a target directly (one-step packaging)

```yaml
steps:
  - plugins:
      - driverforge/anvil#v1.0.0:
          command: build
          configuration: release
          increment: patch
```

## Configuration

| Option | Type | Description |
| --- | --- | --- |
| `version` | string | CLI version — pinned (`1.4.0`) or `latest` (default) |
| `command` | string | Target to run after install (e.g. `build`). Omit for setup-only |
| `project-dir` | string | Driver project path (`--project-dir` / `-p`) |
| `configuration` | string | Build configuration (`--configuration` / `-c`) |
| `increment` | string | Version bump: `major` \| `minor` \| `patch` |
| `encrypt` | bool | Force encryption on (`true`) or off (`false`); omit to keep the driver's setting |
| `sourcemap` | bool | Emit a sourcemap (`--sourcemap` / `-s`) |
| `unpack` | bool | Keep unpacked output (`--unpack` / `-u`) |
| `deploy` | bool | Deploy after build. Mutually exclusive with `sync` |
| `sync` | bool | Hot-sync after build. Mutually exclusive with `deploy` |
| `args` | string | Extra raw args appended to the invocation (escape hatch) |
| `cache-dir` | string | Per-agent download cache dir (default `~/.cache/anvil-buildkite`) |

## How it works

The `environment` hook detects OS/arch → downloads the pinned release archive from
`releases.driverforge.com` → **verifies the SHA-256 checksum** → caches it per-agent
(`<cache-dir>/anvil/<version>/<arch>`) so repeat builds don't re-download → exports it onto
`PATH`.

The `command` hook replaces the step's command phase. With `command:` configured it runs
`anvil <command>` with the mapped flags; otherwise it re-runs the step's own `command:`
(with `anvil` already on `PATH`). Supported agents: Linux and macOS (`amd64` / `arm64`).

## Developing

```bash
shellcheck hooks/* lib/*.bash
docker run --rm -v "$PWD:/plugin:ro" buildkite/plugin-linter --id driverforge/anvil
docker run --rm -v "$PWD:/plugin:ro" buildkite/plugin-tester    # BATS hook tests
```

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). This repo is a public mirror of a private monorepo, so accepted PRs land via an upstream import and show as **closed** (not merged) with your authorship preserved; the linked guide explains why. Please also read the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Report vulnerabilities privately — see [SECURITY.md](SECURITY.md). Please don't open public issues for security reports.

## License

MIT — see [LICENSE](LICENSE).
