# Amazing Pet

macOS menu bar app with an animated pixel pet (8 species). Swift Package, AppKit + SwiftUI, no Xcode project. Licensed under Apache-2.0.

This is an openly vibe-coded project: most of the code is written by Claude Code under human direction and review. Keep this stated in the README.

## Workflow
- Work in small steps: one feature or fix per change. For anything touching more than a few files, propose a short plan first.
- Ask before adding dependencies, changing `Package.swift`, `Info.plist`, `build.sh` or `install.sh`, or removing features.
- Never weaken or delete tests to make them pass. If a test is wrong, say so and explain why.
- Commit only when asked. Commits made with Claude end with `Co-Authored-By: Claude <noreply@anthropic.com>` (Claude co-authorship is welcome).
- Before every commit, re-check the Versioning and Changelog sections below: pick the Conventional Commit type that matches the user-visible impact, and update `CHANGELOG.md` in the same commit when users will notice the change.

## Definition of done
- `swift test` passes.
- `./build.sh` builds `build/AmazingPet.app` without warnings.
- New user-facing strings go through `L10n.swift` and are added to every existing `.lproj`.
- After visual changes, README images are regenerated with `AmazingPet --export-docs docs/images`.
- User-visible change: a line is added under `## [Unreleased]` in `CHANGELOG.md`. Non-app change: no entry.
- The final message of every change states the version impact: `MAJOR`, `MINOR`, `PATCH` or `none`, with a one-line reason.

## Code
- No comments in code. Names and small functions must explain intent.
- Small types with one responsibility and clear patterns: strategy per activity, pure logic separated from AppKit.
- All logic lives in `AmazingPetCore` and is covered by tests. AppKit glue in `AmazingPet` stays thin.
- Keep it light: no per-frame drawing, pre-rendered sprites, low timer rates, no extra dependencies.
- No network access, analytics or telemetry. The app reads only what it needs locally (CPU, memory, window frames).

## Localization
- All user-facing text lives in `Sources/AmazingPet/L10n.swift`. Never hardcode UI strings elsewhere.
- English is the default (inline values). Translations go to `Resources/<lang>.lproj/Localizable.strings`.

## Assets and licensing
- All sprites and palettes are original and generated in code. Do not add third-party art, fonts or code unless its license is compatible with Apache-2.0, and credit the source in the README.

## Docs
- Docs, commit messages and code identifiers are in English.
- `README.md` covers: what it is, GIF, install from GitHub Releases (including the Gatekeeper "Open Anyway" / `xattr` step for the unsigned build), build from source, the vibe-coded note, license.

## Layout
- `Sources/AmazingPetCore`: sprites, species art and palettes, simulation, auto-mode and away (roam) policies, world physics (window platforms, hiding spots), CPU and memory math. Testable, no AppKit.
- `Sources/AmazingPet`: status item, Core Animation view, menu, login item, on-screen roam overlay (window scanner + occlusion mask), pet builder window (SwiftUI, pixel UI kit in `PixelUI.swift`), image export.
- `Tests/AmazingPetCoreTests`: unit tests (Swift Testing; with Command Line Tools only, the package passes the CLT macro plugin path to the test target, with Xcode it does not).
- `Resources`: `Info.plist` and localizations.
- `docs/images`: generated README images (banner, GIFs, screenshots).
- `CHANGELOG.md`: user-facing version history.
- `.github/workflows`: CI and release automation.

## Commands
- `swift test`: run tests.
- `./build.sh`: build `build/AmazingPet.app`.
- `./install.sh`: build, install to Applications, launch (registers launch at login).
- `VERSION=1.2.3 ./package.sh`: build (signed and notarized when the env is set) and write `.dmg`, `.zip` and `SHA256SUMS.txt` to `dist/`. `ARCHS="arm64 x86_64"` builds a universal binary.
- `AmazingPet --export-docs <dir>`: regenerate all README images and GIFs.
- `AmazingPet --export-preview|--export-species|--export-roam|--export-builder|--export-icon <path>`: render menu bar scenes, all species, on-screen roam games, builder window or iconset to PNG for visual checks.

## CI / Releases
- `.github/workflows/ci.yml`: tests and build on pull requests. Pushes to `main` are tested by the release workflow, so CI does not run there too.
- `.github/workflows/release.yml`: a push to `main` republishes the `nightly` pre-release; a `v*` tag publishes a versioned release. Nightly builds get the next version from `.github/scripts/next-version.sh` (last `vX.Y.Z` tag plus Conventional Commits since) and are labeled `X.Y.Z-nightly.N`; their notes come from `## [Unreleased]`. A tag build fails unless `CHANGELOG.md` has a `## [X.Y.Z]` section, which becomes the release notes. Release builds are ad-hoc signed; there is no Developer ID signing or notarization in CI.
- Docs-only changes (`*.md`, `docs/**`, `LICENSE`, `NOTICE`) don't trigger CI or nightly builds; tag pushes always build.
- `.github/scripts/check-changelog.sh` warns in CI when app code (`Sources/`, `Resources/`) changes without a `CHANGELOG.md` update. It is a safety net, not a substitute for the rules above.
- Use only first-party GitHub actions and the `gh` CLI, no third-party actions.

## Security
- This is a public repository. Never commit secrets, certificates, `.env` files, tokens or local absolute paths. `.gitignore` blocks the common ones; check `git diff --cached` before every commit anyway.
- Pin every action to a full commit SHA with the version in a trailing comment (`uses: actions/checkout@<sha> # v7.0.1`). Dependabot keeps them up to date.
- Workflows default to `permissions: contents: read`; only the release job gets `contents: write`. Check out with `persist-credentials: false`.
- Never interpolate `${{ github.* }}` or other untrusted input directly into `run:` scripts; pass it through `env:`.
- Do not add `pull_request_target` or self-hosted runners.
- Vulnerability reports follow `SECURITY.md`.

## Versioning
- Semantic Versioning `MAJOR.MINOR.PATCH`. The single source of truth is the git tag `vX.Y.Z`; CI writes it into `CFBundleShortVersionString` and uses the run number as `CFBundleVersion`. Never hardcode a version in code or `Info.plist`.
- The first public release is `v1.0.0`.
- Commit messages follow Conventional Commits so the next version can be derived from history. Mark breaking changes with `!` (`feat!:`) or a `BREAKING CHANGE:` footer.
- Derive the bump from all commits since the last tag (`git log $(git describe --tags --abbrev=0)..HEAD`), taking the highest one:
  - MAJOR: anything that breaks users. Removing a feature, raising the minimum macOS, changing the bundle id, or renaming `UserDefaults` keys without a migration (users would lose their pet).
  - MINOR: a new user-visible capability. New species, coat, toy, game, indicator, setting, menu item or language.
  - PATCH: user-visible fixes and improvements without new capability, such as `fix:`, `perf:`, tweaks to sprites or timing, and translation fixes.
  - No release: only `docs:`, `test:`, `ci:`, `build:`, `chore:` or `refactor:` with no user-visible change.
- The version changes only when the app itself changes for users. Changes to the README, docs images, CI workflows, scripts, tests, `CLAUDE.md` or other tooling never bump the version and never get a changelog entry.
- When finishing a change, state which bump it implies. When asked to release, list the commits since the last tag, propose the version with a one-line reason per bump, and create an annotated tag only after confirmation. Pushing tags needs explicit approval, like any push.

## Changelog
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest version first, in English.
- Every user-visible change adds a short line under `## [Unreleased]` in the same commit, grouped as `Added`, `Changed`, `Fixed`, `Removed` or `Security`. Write it for users, not developers: what they will notice, not how it was coded.
- Changes that don't affect the app (see Versioning) get no entry.
- On release, rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`, add a fresh empty `## [Unreleased]` above it, update the compare links at the bottom, and commit this as `chore(release): vX.Y.Z` before tagging. The changelog section must agree with the bump: an `Added` entry means at least MINOR, a `Removed` entry or a breaking change means MAJOR.
