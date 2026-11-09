# AGENTS.md

Shared instructions for AI agents and contributors working in this Scoop
bucket. Read this before adding, updating, or removing a manifest.

## Repository layout

| Path | Purpose |
| --- | --- |
| `bucket/*.json` | Installable Scoop manifests |
| `deprecated/` | Retired manifests, kept for history |
| `bin/` | Thin wrappers around `$(scoop prefix scoop)/bin` |
| `.github/workflows/ci.yml` | Schema and Pester checks |
| `.github/workflows/excavator.yml` | Runs `checkver -Update` every 4 hours |
| `.github/workflows/pull_request.yml` | PR verification |

This is a colocated jj/git repository. Read-only inspection is always fine.
Do not commit, amend, describe, rebase, move bookmarks, or push unless the user
explicitly asks. When in doubt, stop and ask.

## Hard rules

1. Investigate the application before writing the manifest: read the upstream
   docs, release/packaging scripts, and source to learn how it runs and where
   it stores state. Do not infer behavior from the release page alone.
2. Do not modify existing manifests unless the task explicitly requires it.
   Template/workflow alignment must not touch `bucket/*.json`.
3. Never guess a URL, version, hash, license, or extraction directory. Verify
   from the upstream release, repository, or documentation.
4. Keep manifests minimal, factual, and consistent with the existing files.
5. Never put secrets, tokens, or personal paths in a manifest, script, or log.
6. Report what you verified and what you could not verify. Do not claim a test
   passed unless you ran it.

## Adding a manifest

### 1. Investigate the application (required)

Do not write a manifest from the release page alone. Browse the project and
understand how it works first.

- Read the official documentation, FAQ, release notes, and packaging scripts.
- Confirm whether upstream publishes a portable/archive build or documents a
  portable mode. Prefer the official portable archive over an installer.
- Identify the latest stable release. Do not use a prerelease unless the user
  asks for it.
- Check every supported architecture (usually `64bit` and `arm64`).
- Check runtime prerequisites, administrator/UAC requirements, external data
  locations, and the license.
- Trace state and configuration in the source: look for
  `Environment.SpecialFolder`, `ApplicationData`, `LocalApplicationData`,
  `ProgramData`, `AppContext.BaseDirectory`, and registry APIs such as
  `Registry.CurrentUser` / `Registry.LocalMachine`.
- If the upstream documentation says portable mode is not supported, stop and
  discuss options before writing a manifest.

If only an EXE installer exists, verify with 7-Zip that it can be extracted
(`#/dl.7z`) and that removing `$PLUGINSDIR`, `Uninstall*.exe`, and similar
installer junk is safe. Do not assume; inspect the archive.

### 2. Portable mode and state

Classify the application before deciding `persist`, `env_*`, or `notes`:

1. **Native portable build/mode** - upstream ships an archive and the app keeps
   its state inside the extracted folder or a documented sibling config. Use
   the archive and persist the user-state paths that live inside `$dir`.
2. **Portable archive, non-portable state** - the archive runs without an
   installer, but the app writes to `%APPDATA%`, `%LOCALAPPDATA%`,
   `%PROGRAMDATA%`, the registry, a user-selected workspace, or another
   location outside `$dir`. Do **not** add a fake `persist`; document the paths
   and consequences in `notes`.
3. **Installer-only** - no portable archive. Extract the installer only if
   verified; otherwise discuss alternatives before writing a manifest.

#### Portable signals

A build is truly portable only if all of these hold:

- Upstream publishes a standalone archive, not only an installer.
- The docs describe it as portable/green ("extract and run").
- The app does not require a service, driver, or scheduled task.
- The app stores state next to the executable or in a config path inside the
  extracted folder.
- It does not write registry keys or files outside that folder.

If any of these fail, it is still an archive build but not fully portable;
document the exceptions in `notes`.

When possible, run the application in a clean environment and inspect what it
creates outside `$dir`. Reading the source is acceptable when a clean run is
not practical, but say what you could not verify.

A practical check is to extract the archive to a temporary folder, run the app
once, and compare `%APPDATA%`, `%LOCALAPPDATA%`, `%PROGRAMDATA%`, and relevant
`HKCU`/`HKLM` keys before and after. Record everything created outside the
extraction folder.

#### What belongs in `persist`

- User settings, profiles, databases, scripts, and downloaded data that live
  inside the installed `$dir` and must survive `scoop update`.
- Directories or files only; never paths outside `$dir`.
- Do not persist versioned assets, caches that can be regenerated, or bundled
  resources that should change with the version.
- If the archive ships default user data, Scoop moves it into the persist store
  on first install; verify the result.

#### What must not be persisted

- `%APPDATA%`, `%LOCALAPPDATA%`, `%PROGRAMDATA%`, registry keys,
  user-selected workspaces, and anything outside `$dir`. Add a warning in
  `notes` instead.
- Do not delete or migrate these locations automatically without explicit user
  consent.

#### Registry and system integration

- Scoop does not sandbox the registry. If the app writes `HKCU`/`HKLM` keys,
  installs services, scheduled tasks, drivers, or firewall rules, say so in
  `notes`.
- Only add cleanup scripts when the change is safe, reversible, and fully
  understood; never remove user data as part of uninstall.

#### Environment variables and launch arguments

- Add `env_set` / `env_add_path` only when the app genuinely requires them.
- If portable mode is enabled by a flag or config, put the flag in `shortcuts`
  and/or `bin` arguments instead of polluting global environment variables.
- Do not invent an environment variable to force portable mode; only use
  variables documented by upstream.
- Do not override `HOME`, `APPDATA`, `LOCALAPPDATA`, or similar global variables
  to redirect state; that affects other applications.
- If an environment variable is required, document it in `notes`; avoid
  overriding user values unexpectedly.

#### Warnings to include in `notes`

- UAC/admin requirement.
- External state paths that Scoop does not manage.
- Registry keys, services, scheduled tasks, or drivers.
- Required runtimes or prerequisites.
- Disabled or removed self-updater.
- Any behavior that makes uninstall/update incomplete.

#### Examples in this bucket

- `bettergi`: stores state in `<install>\User`, `log`, and `Repos`; those are
  persisted. It requires UAC and its bundled updater is removed.
- `tiny11builder`: stores state in `%LOCALAPPDATA%\Tiny11Builder` and defaults
  its workspace to `C:\tiny11`; there is no `persist` entry, and both locations
  are documented in `notes`.

If any of these cannot be determined, stop and ask rather than guessing.

### 3. Build the manifest

Start from `bucket/app-name.json.template` and keep fields in the same style as
the existing manifests.

- The manifest filename becomes the package name. Use a lowercase, hyphenated
  name that matches the app's common product name, and do not rename existing
  manifests without a reason.
- `version`: the value Scoop should show. This may differ from the Git tag
  (for example a tag `winui-v0.1.2` usually means version `0.1.2`).
- `description`: one concise sentence describing what the app does.
- `homepage`: official site or repository.
- `license`: verify the actual license. Use an SPDX identifier when known.
  If the upstream has no license file, use `"Unknown"`; never guess `MIT`.
- `architecture`: include only architectures that upstream actually publishes.
  Put `url`, `hash`, and any per-architecture `extract_dir` inside each entry.
- `url`: exact release asset URL for that architecture.
- `hash`: SHA-256 of the asset. GitHub release API `digest` is authoritative;
  an upstream `.sha256` asset is also acceptable. Never reuse a hash from a
  different version or architecture.
- `extract_dir`: required when the archive contains a top-level directory.
  Verify the structure from the packaging script or `7z l`; never infer it.
  If the directory name contains the version, add `extract_dir` to
  `autoupdate` with `$version` so future updates stay correct.
- `shortcuts`: the executable must exist at the path after extraction.
- `bin`, `env_set`, `env_add_path`: add only when the app is genuinely usable
  from a terminal without a shortcut.
- `persist`: only in-`$dir` user state identified in section 2. Do not invent
  a persistence entry for `%LOCALAPPDATA%`, `$HOME`, a user-selected workspace,
  or anything outside `$dir`.
- `notes`: include the warnings listed in section 2, such as UAC/admin
  requirements, external state paths, registry/system integration,
  prerequisites, and a disabled self-updater.

### 4. Handle self-updaters carefully

Some apps ship an updater that conflicts with Scoop's version management. Before
removing it, verify in the source that it is only launched for updates and that
a missing file produces a handled error. If so, remove it in `post_install` and
mention the alternative in `notes`:

```json
"post_install": "Remove-Item \"$dir\\AppUpdate.exe\" -Force -ErrorAction SilentlyContinue"
```

Do not delete files that are required for startup, and do not use ACL tricks to
block execution; an existence check followed by an unhandled exception is worse.

### 5. checkver and autoupdate are mandatory

Every manifest must be automatically maintainable by the excavator workflow.

- Prefer `"checkver": { "github": "https://github.com/owner/repo" }`.
- If the tag does not match the asset version, add a `regex` that extracts the
  version and verify the result both with and without a GitHub token.
- Be aware that `checkver` uses `releases/latest`. If the repository mixes
  unrelated tag schemes, `releases/latest` can point at a non-matching release;
  test the regex against the real response.
- `autoupdate` must update every architecture URL and every version-dependent
  field, including `extract_dir`. Use `$version` substitutions.
- Do not hardcode the current version in `autoupdate`.
- For GitHub release assets, Scoop can obtain hashes from the API digest
  automatically. If upstream publishes `.sha256` files, an explicit hash URL is
  also fine.

### 6. Validate before finishing

Run from the repository root in PowerShell:

```powershell
# JSON syntax and Scoop schema (Test-Json requires PowerShell 7+)
Get-Content .\bucket\<app>.json -Raw | ConvertFrom-Json
Test-Json -Path .\bucket\<app>.json -SchemaFile (Join-Path (scoop prefix scoop) 'schema.json')

# Canonical formatting (4 spaces, CRLF)
.\bin\formatjson.ps1 <app>

# Read-only checks
.\bin\checkver.ps1 <app>
.\bin\checkurls.ps1 <app>

# Downloads each asset and verifies hashes (network required)
.\bin\checkhashes.ps1 <app>

# Full bucket test suite, when SCOOP_HOME/BuildHelpers/Pester are available
.\bin\test.ps1
```

Do not run `checkver -Update` or `checkhashes -Update` unless the user asks you
to modify the manifest.

If possible, install the manifest in a clean Scoop environment and launch it.
If you cannot test, say so explicitly and list what remains unverified.

### 7. Update the README

Add the app to the "Available manifests" table in `README.md` when it becomes
part of the bucket. Keep the description consistent with the manifest.

## Removing or deprecating a manifest

Use this when upstream is gone, the app is superseded, the manifest is broken
beyond repair, or the package should no longer be installable.

1. Prefer **deprecating** over deleting:
   - move `bucket/<app>.json` to `deprecated/<app>.json`;
   - add a `"##"` comment explaining why and when it was retired, for example
     `"##": "Deprecated 2026-10-18: upstream no longer publishes a portable build."`;
   - remove the entry from `README.md`.
2. Delete outright only when the manifest never worked, is malicious, or keeping
   it would be harmful. Do not delete unrelated files.
3. Check for references in scripts, documentation, and other manifests.
4. Run the same validation commands as for an addition.
5. Never delete user data (`persist` directories, `%LOCALAPPDATA%` state, or
   user workspaces) as part of a manifest removal. Mention cleanup in `notes` if
   it matters.

## Formatting and commit style

- Scoop manifests in `bucket/` use **4 spaces and CRLF**, as produced by
  `bin/formatjson.ps1`. `.editorconfig` is authoritative for these files.
  Do not reformat them with tools that produce 2 spaces or LF; that creates
  noisy diffs. In particular, do not run the repo's Biome formatter on
  `bucket/*.json` (it uses 2 spaces and LF).
- YAML files use 2 spaces.
- Use Conventional Commits for commit/description messages, for example
  `feat(bettergi): add manifest`, `fix(jan): correct shortcut target`, or
  `chore: format manifests`.
- Keep commits and working-copy changes scoped to the requested task.

## Known pitfalls in this bucket

- GitHub tags and asset names frequently disagree. `tiny11builder` uses the tag
  `winui-v0.1.2` but the assets and displayed version are `0.1.2`; extract only
  the version in `checkver` and rebuild the tag in `autoupdate`.
- A ZIP built with `ZipFile.CreateFromDirectory(..., includeBaseDirectory: true)`
  has a top-level folder. Add a per-architecture `extract_dir` and keep the
  `$version` substitution in `autoupdate`.
- A GitHub repository with no `LICENSE` file has no SPDX license; document it
  as `"Unknown"` instead of guessing.
- Apps that write state to `%LOCALAPPDATA%` cannot use Scoop `persist`; do not
  add a fake persist entry, and explain the external state in `notes`.
- Only remove a self-updater after checking the source. A missing updater must
  produce a handled error, not an unhandled exception at startup.

## Definition of done

- [ ] Upstream release and portable/archive mode verified.
- [ ] Version, URL, architecture, and SHA-256 verified against upstream.
- [ ] `extract_dir` verified from the actual archive structure.
- [ ] `shortcuts`/`bin` targets exist after extraction.
- [ ] Portable mode and state locations investigated (files, AppData,
  registry, services, workspace).
- [ ] `persist` contains only in-`$dir` user state; external locations are
  documented in `notes`.
- [ ] Environment variables and launch arguments added only when required.
- [ ] License verified; `Unknown` used when none exists.
- [ ] `checkver` and `autoupdate` tested.
- [ ] `notes` cover UAC, external state, prerequisites, and other surprises.
- [ ] Manifest formatted with `bin/formatjson.ps1`.
- [ ] Schema/JSON checks pass; full tests run when possible.
- [ ] README updated for additions and removals.
