# bobh-scoop-bucket

[![Tests](https://github.com/BobH-Official/bobh-scoop-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/BobH-Official/bobh-scoop-bucket/actions/workflows/ci.yml)
[![Excavator](https://github.com/BobH-Official/bobh-scoop-bucket/actions/workflows/excavator.yml/badge.svg)](https://github.com/BobH-Official/bobh-scoop-bucket/actions/workflows/excavator.yml)

A personal [Scoop](https://scoop.sh) bucket for Windows.

## Install

```pwsh
scoop bucket add bobh-scoop-bucket https://github.com/BobH-Official/bobh-scoop-bucket
scoop install bobh-scoop-bucket/<manifest>
```

## Available manifests

| Manifest | Description |
| --- | --- |
| [`bun-canary`](bucket/bun-canary.json) | Incredibly fast JavaScript runtime, bundler, transpiler and package manager - all in one. |
| [`google-chrome-for-testing`](bucket/google-chrome-for-testing.json) | Google Chrome for Testing, a new Chrome flavor that specifically targets web app testing and automation use cases. |

## Uninstall

```pwsh
scoop uninstall <manifest>
scoop bucket rm bobh-scoop-bucket
```

## Contributing

Issues and pull requests are welcome. To add a new manifest or update an
existing one, please read the [Contributing
Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md)
and [App Manifests](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests)
wiki page.
