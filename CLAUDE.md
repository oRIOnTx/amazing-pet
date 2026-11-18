# Amazing Pet

macOS menu bar app with an animated pixel pet (8 species). Swift Package, AppKit + SwiftUI, no Xcode project. Licensed under Apache-2.0.

This is an openly vibe-coded project: most of the code is written by Claude Code under human direction and review. Keep this stated in the README.

## Workflow
- Work in small steps: one feature or fix per change. For anything touching more than a few files, propose a short plan first.
- Ask before adding dependencies, changing `Package.swift`, `Info.plist`, `build.sh` or `install.sh`, or removing features.
- Never weaken or delete tests to make them pass. If a test is wrong, say so and explain why.
- Commit only when asked. Commits made with Claude end with `Co-Authored-By: Claude <noreply@anthropic.com>` (Claude co-authorship is welcome).

## Definition of done
- `swift test` passes.
- `./build.sh` builds `build/AmazingPet.app` without warnings.
- New user-facing strings go through `L10n.swift` and are added to every existing `.lproj`.
- After visual changes, README images are regenerated with `AmazingPet --export-docs docs/images`.

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
- `.github/workflows`: CI and release automation.

## Commands
- `swift test`: run tests.
- `./build.sh`: build `build/AmazingPet.app`.
- `./install.sh`: build, install to Applications, launch (registers launch at login).
- `VERSION=1.2.3 ./package.sh`: build (signed and notarized when the env is set) and write `.dmg`, `.zip` and `SHA256SUMS.txt` to `dist/`. `ARCHS="arm64 x86_64"` builds a universal binary.
- `AmazingPet --export-docs <dir>`: regenerate all README images and GIFs.
- `AmazingPet --export-preview|--export-species|--export-roam|--export-builder|--export-icon <path>`: render menu bar scenes, all species, on-screen roam games, builder window or iconset to PNG for visual checks.

## CI / Releases
- `.github/workflows/ci.yml`: tests and build on pull requests and pushes to `main`.
- `.github/workflows/release.yml`: a push to `main` republishes the `nightly` pre-release; a `v*` tag publishes a versioned release. Signing and notarization run only when the Developer ID secrets are set.
- Use only first-party GitHub actions and the `gh` CLI, no third-party actions.
