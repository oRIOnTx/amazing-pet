<p align="center">
  <img src="docs/images/banner.png" alt="Amazing Pet" width="100%">
</p>

<p align="center">
  <a href="../../actions/workflows/release.yml"><img src="../../actions/workflows/release.yml/badge.svg" alt="Build"></a>
  <a href="../../releases/latest"><img src="https://img.shields.io/badge/download-latest-F4A04A" alt="Download"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-1E1B2E?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.10%2B-F4A04A?logo=swift&logoColor=white" alt="Swift 5.10+">
  <img src="https://img.shields.io/badge/license-Apache%202.0-5DBB63" alt="Apache 2.0 License">
  <img src="https://img.shields.io/badge/vibe--coded-with%20Claude%20Code-D97757" alt="Vibe-coded with Claude Code">
</p>

**Amazing Pet** is a tiny, animated pixel-art pet that lives in your macOS menu bar. It plays with different toys depending on what your Mac is doing, warns you when something is wrong with cute little props, and — when you step away from the keyboard — jumps out of the menu bar to explore your windows, play hide and seek and hunt your cursor.

> [!NOTE]
> ### 🤖 This is a vibe-coded project
> Amazing Pet was built end to end by chatting with [Claude Code](https://claude.com/claude-code), Anthropic's AI coding agent. A human described what they wanted (often in Ukrainian, in a few sentences at a time) and Claude wrote the Swift code, drew every sprite as ASCII pixel art, wrote the tests, generated the screenshots below and wrote this README. Commits are co-authored by Claude.
>
> It's a fun experiment in what "describe it and let the AI build it" looks like for a real, polished app. Issues and PRs are welcome — vibe-coded or not.

---

## ✨ Features

### 🧶 A pet that reacts to your Mac

<p align="center"><img src="docs/images/menubar.gif" alt="Menu bar animation" width="560"></p>

In **Auto** mode what your pet does follows your CPU load, and the busier your Mac gets, the faster it moves. Below 4% CPU, or when you're idle, every pet naps 💤. Above that, each animal has its own way to play:

<p align="center"><img src="docs/images/toys.gif" alt="Every animal at low, medium and high load" width="520"></p>

| Animal | < 20% CPU | < 50% CPU | ≥ 50% CPU |
|---|---|---|---|
| 🐱 Cat | 🧶 Yarn ball | 🐭 Toy mouse | 🔴 Laser pointer |
| 🐶 Dog | 🦴 Chews a bone | 🎾 Plays fetch | 🌀 Chases its tail until dizzy |
| 🦊 Fox | 👃 Sniffs around | ❄️ Pounces into the snow | 🍂 Chases a falling leaf |
| 🐰 Rabbit | 🥕 Nibbles a carrot | 🐇 Hops around | ✨ Happy binkies with a mid-air twist |
| 🐹 Hamster | 🌻 Stuffs its cheeks with seeds | 🔵 Rolls in a hamster ball | 🎡 Runs in the wheel |
| 🐦 Bird | 🌾 Pecks at grain | 🪶 Flutters about | 🕊 Flies back and forth |
| 🐟 Fish | 🫧 Blows bubbles | 🍤 Catches sinking food flakes | 💨 Darts around |
| 🐢 Turtle | 🥬 Munches lettuce | 🐢 Takes a slow stroll | 🍓 Races to a strawberry |

You can also pick a toy manually from the menu: it lists the toys of your animal. If you switch animals, the toy for the same load level is picked for you.

### 🚨 Smart indicators

Your pet tells you when something needs attention, before the toys:

| Situation | What you see |
|---|---|
| 🌡 Mac is overheating (`thermalState` serious or critical) | Lying next to a thermometer, sweating |
| 🏠 Memory pressure is elevated (warning) | Hides in its own home, a little uneasy: a basket for the cat, a kennel for the dog, a den for the fox, a burrow with a carrot for the rabbit, a cage with a wheel for the hamster, a birdhouse for the bird, an aquarium for the fish and a rock pile for the turtle |
| 🚨 Memory pressure is critical | Barely fits at home: the house shakes, with a blinking `!` |
| 🐟 Battery below 15% and not charging | Sitting by an empty bowl, dreaming of fish |

The menu also shows live **CPU, memory and battery** percentages.

### 🖥 Screen play while you're away

<p align="center"><img src="docs/images/roam.gif" alt="Pet playing across the screen" width="600"></p>

Turn on **Play on screen when I'm away** (after 1, 3, 5 or 10 minutes), or try **Play now**. Your pet jumps out of the menu bar and lives on your whole screen:

- 🧗 **Explores your windows**: walks along their top edges, leaps between them and drops down. It knows which window is in front, so it only walks on edges you can see.
- 💻 **Reacts to your apps**: on a terminal or code editor it "types" with 0s and 1s floating up, on Music or Spotify it dances with notes, on a chat or mail app it shows a typing bubble. Apps are recognized by their bundle ID only; no window titles or contents are read.
- 🙈 **Hide and seek**: hides *behind* your windows and peeks out from the edge.
- 🖱 **Cursor hunt**: runs to where you left the mouse pointer and pounces at it.
- 🧗 **Window climbing**: climbs up the side of a window, crosses its top and slides down the other side.
- 🪟 **Ledge sitting**: sits on the edge of a window with its legs dangling.
- 🪴 **Mischief**: pushes a flower pot off a window and watches it fall, or nibbles a window corner and lets the crumbs drop.
- 🔎 **Treasure hunt**: its favorite toy is hidden behind one of your windows; it sniffs behind them one by one, finds it, knocks it out and plays with it.
- 👀 **Pop-up peeking**: ducks behind the top edge of a window and pops its head up here and there.
- 🙃 **Ceiling hang**: leaps up from a high window, hangs upside down from the menu bar and swings along it before dropping down.
- 💨 **Zoomies**, 🦋 **butterfly chasing**, plus your animal's own toys. Toys live on the window your pet stands on: the yarn ball rolls off the edge and your pet jumps down after it.
- 😴 **Window nap**: after 15 minutes it climbs onto your highest window and falls asleep.

Move the mouse or press any key and it's instantly back in the menu bar. It never starts while a video, call or presentation is keeping your display awake, and clicks always pass straight through it.

#### 🍪 Optional: icons to play with

If you want, your pet can also hop onto your desktop icons and pretend to nibble your desktop and Dock icons, leaving teeth marks that fade away and a few crumbs. It's only drawn on the pet's own transparent layer; nothing is opened, moved or changed. This needs a permission that Amazing Pet never asks for on its own. Grant it from **Permissions** in the menu, or from Terminal:

| What | Permission | Menu item | Command |
|---|---|---|---|
| Dock icons | Accessibility (to read where the Dock icons are) | **Permissions → Nibble Dock icons (Accessibility)…** | `open -n /Applications/AmazingPet.app --args --grant-dock-access` |
| Desktop icons | Automation of Finder (to ask where the desktop icons are) | **Permissions → Play with desktop icons (Finder)…** | `open -n /Applications/AmazingPet.app --args --grant-desktop-access` |

A checkmark in the menu shows what's granted. To take a permission back, switch it off in **System Settings → Privacy & Security → Accessibility** or **→ Automation**. Use `open` as shown rather than running the binary directly, otherwise macOS asks on behalf of Terminal. Because builds are ad-hoc signed, macOS may forget the Accessibility permission after an update; just turn it off and on again.

### 🐾 Build your own pet

<p align="center"><img src="docs/images/builder.png" alt="Pet builder window" width="400"></p>

On first launch a pixel-styled window lets you create your pet. You can reopen it any time from **Customize pet…** (⌘,).

- **8 animals**: cat, dog, fox, rabbit, hamster, bird, fish and turtle. Each has its own art, gait and speed: the turtle is slow, the fox and the rabbit are fast.
- **Colors per animal**: ginger, gray, black, white, siamese and calico cats; golden, brown and dalmatian dogs; blue, yellow, green and red birds; and more.
- **4 eye colors** and a **name**.

<p align="center"><img src="docs/images/species.png" alt="All species and colors" width="100%"></p>

### 🌍 English and Ukrainian

Switch the language from the menu (**Language → System default / English / Українська**). The change applies instantly, no restart needed.

### 🪶 Lightweight

- Sprites are rendered once. Each frame only moves a few Core Animation layers, so there is no per-frame drawing.
- 4–15 fps depending on the activity, and everything pauses when the display sleeps.
- About **0.1% CPU and ~13 MB of RAM** on Apple silicon.
- No network access and no analytics. By default no special permissions: screen play reads only window *frames* and the owning app's bundle ID, never window titles or contents. Icon play is optional and uses a permission only after you grant it.

---

## 📦 Install

### Download

Grab the latest **`AmazingPet-x.y.z.dmg`** from [**Releases**](../../releases/latest), open it and drag **AmazingPet** into **Applications**. Builds are universal, so they run natively on both Apple silicon and Intel.

- **Stable**: every `v*` tag becomes a release.
- **Nightly**: the [`nightly`](../../releases/tag/nightly) pre-release is rebuilt automatically on every push to `main`. It is labeled with the upcoming version, for example `1.1.0-nightly.4` (4 commits after `v1.0.0`), and its notes list the unreleased changes.

See [`CHANGELOG.md`](CHANGELOG.md) for what changed in each version.

On first launch from Applications the app registers itself as a login item, so it starts automatically. You can turn that off from the menu with **Launch at login**.

> [!IMPORTANT]
> Builds are ad-hoc signed and not notarized, so macOS will block the first launch. Allow it in **System Settings → Privacy & Security → Open Anyway**, or run:
> ```sh
> xattr -dr com.apple.quarantine /Applications/AmazingPet.app
> ```

### Build from source

All you need is the Xcode Command Line Tools; the full Xcode isn't required.

```sh
xcode-select --install   # if you don't have the command line tools yet
git clone https://github.com/oRIOnTx/amazing-pet.git
cd amazing-pet
./install.sh
```

`install.sh` builds the app, copies it to `/Applications` (or `~/Applications`) and launches it.

**Requirements:** macOS 14 Sonoma or newer, on Apple silicon or Intel.

---

## 🛠 Development

```sh
swift test           # run the test suite (90+ tests)
./build.sh           # build build/AmazingPet.app
```

Render any part of the app to PNG or GIF for a visual check, without launching it:

```sh
BIN=$(swift build --show-bin-path)/AmazingPet
$BIN --export-docs docs/images      # regenerate every image in this README
$BIN --export-species species.png   # all animals and colors
$BIN --export-preview scenes.png    # menu bar scenes on light and dark backgrounds
$BIN --export-roam roam.png         # on-screen games
$BIN --export-builder builder.png -language uk
```

### 🚀 Releases

Two GitHub Actions workflows live in [`.github/workflows`](.github/workflows):

| Workflow | Runs on | What it does |
|---|---|---|
| `ci.yml` | every pull request | `swift test` plus an app build |
| `release.yml` | push to `main` | tests, then builds a universal app and republishes the **`nightly`** pre-release with a `.dmg`, a `.zip` and `SHA256SUMS.txt` |
| `release.yml` | tag `v*` | the same, but publishes a versioned release with generated notes |

Pushes that only touch docs (`*.md`, `docs/**`, `LICENSE`, `NOTICE`) don't trigger builds, since they don't change the app.

To cut a release:

```sh
git tag v1.0.0
git push origin v1.0.0
```

You can build the same artifacts locally with `VERSION=1.0.0 ./package.sh`, which writes them to `dist/`.

Releases are ad-hoc signed and not notarized, so users need the Gatekeeper step described in [Install](#-install). `build.sh` and `package.sh` already support Developer ID signing (`SIGN_IDENTITY`) and notarization (`APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`) for local builds, if a paid Apple Developer account is ever added.

The workflows use only GitHub's own `checkout` action and the preinstalled `gh` CLI, with no third-party actions.

### Architecture

```
Sources/
├── AmazingPetCore/      Pure Swift, no AppKit, fully unit-tested
│   ├── Species*.swift   Pixel art (ASCII rows) and color palettes for every animal
│   ├── Sprites.swift    Toys, props and effects; sprite → CGImage rendering
│   ├── Pet.swift        Position, walking, jumping, clinging to walls; Fall.swift: gravity with platform landing
│   ├── Behaviors.swift  One strategy per activity: yarn, mouse, laser, zoomies, butterfly, alerts…
│   ├── WorldBehaviors   Navigator plus explore, hide-and-seek, cursor hunt and window nap
│   ├── WindowGames      Climbing, ledges, flower pot, treasure hunt, pop-up peeking, ceiling hang, nibbling
│   ├── SpeciesBehaviors Snacks, wandering, hops, fetch, tail chase, flying, hamster ball and wheel
│   ├── World.swift      Window tops as platforms, ledges, climbable walls, hiding spots
│   ├── ActivityPolicy   What to play given CPU, thermal state, memory and battery
│   ├── Roam.swift       When to leave the menu bar, when to come back, which game is next
│   └── SystemSampler    CPU ticks, memory pages, thermal state, battery, idle time
└── AmazingPet/          Thin AppKit and SwiftUI layer
    ├── PetController    Timers; drives the menu bar simulation
    ├── RoamController   Transparent click-through overlay for screen play
    ├── WindowScanner    Window frames via CGWindowList → platforms and occlusion mask
    ├── PetView          Core Animation renderer (nearest-neighbor, backing-aligned)
    ├── PetBuilder*      Pixel-styled SwiftUI customization window
    ├── PixelUI.swift    Pixel UI kit: aliased text, notched panels, pixel buttons
    └── L10n.swift       Every user-facing string, English by default
```

Every animal is just a set of 16×12 ASCII rows such as `"..KOK.....KOK..."`. Letters map to palette slots (`K` outline, `O` fur, `D` pattern, `W` belly, `P` nose and ears, `E` eyes), so a new color is only a new palette.

### Contributing

- **Add an animal**: add its art to `SpeciesArt.swift`, its palettes, pace, home and three toys to `Species.swift`, and a name in `L10n.swift` plus `uk.lproj`. The tests check frame sizes, palette letters, room for effects and staying on screen.
- **Add a language**: create `Resources/<code>.lproj/Localizable.strings`, add the code to `AppLanguage` and `CFBundleLocalizations`, and include it in `LocalizationTests`. The tests fail if any key or placeholder is missing.
- Code style: no comments, small focused types, logic in `AmazingPetCore` with tests. See [`CLAUDE.md`](CLAUDE.md), the same rules the AI followed.

---

## 📄 License

[Apache License 2.0](LICENSE), see also [`NOTICE`](NOTICE). Made with 🧡 by a human and Claude.
