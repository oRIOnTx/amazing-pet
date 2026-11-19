# Changelog

All notable changes to Amazing Pet are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Only changes that affect the app are listed here. Docs, CI and tooling changes are not.

## [Unreleased]

### Added
- Every animal now has its own home: a basket for the cat, a kennel for the dog, a den for the fox, a burrow with a carrot for the rabbit, a cage with a wheel for the hamster, a birdhouse for the bird, an aquarium for the fish and a rock pile for the turtle.
- Every animal now plays in its own way, picked by CPU load: the dog chews a bone, plays fetch and chases its tail; the fox sniffs around, pounces into the snow and chases a falling leaf; the rabbit nibbles a carrot, hops and does binkies; the hamster stuffs its cheeks, rolls in a ball and runs in its wheel; the bird pecks grain, flutters and flies; the fish blows bubbles, catches food flakes and darts around; the turtle munches lettuce, strolls and races to a strawberry. The cat keeps its yarn ball, toy mouse and laser.
- The toy menu lists your animal's own toys, and a chosen toy carries over to the matching one when you switch animals.
- New screen games: your pet climbs up the side of a window and slides down, sits on a window edge with its legs dangling, and knocks a flower pot off a window.

### Changed
- The memory indicator follows the macOS memory pressure level: at the warning level the pet calmly hides at home, and only at the critical level does the home shake with a blinking `!`. It no longer uses a box, and the fish stays in water.

### Fixed
- Screen play no longer gets stuck in one place: the yarn ball, toy mouse, laser dot and butterfly now appear on the window your pet is standing on, fall off edges, and lead it across all your windows instead of along the bottom of the screen.
- The pet no longer gets stuck on a window that touches the edge of the screen.
- During screen play the pet respects which window is in front: it no longer walks along edges covered by another window, and standing on a window it is hidden only by the windows in front of that one, not by every window on screen.

## [1.0.0] - 2026-11-18

The first public release.

### Added
- An animated pixel pet that lives in the macOS menu bar.
- Eight animals (cat, dog, fox, rabbit, hamster, bird, fish and turtle), each with its own colors, gait and speed, plus four eye colors.
- A pixel-styled window to create and customize your pet, shown on first launch and available from **Customize pet…** (⌘,).
- An Auto mode where the toy follows CPU load (nap, yarn ball, toy mouse, laser pointer) and the pet speeds up as the Mac gets busier, plus manual toy selection.
- Smart indicators for overheating (thermometer), high memory pressure (a box that's too small) and low battery (an empty bowl).
- Live CPU, memory and battery percentages in the menu.
- Pet your pet from the menu (⌘P) to see it purr with hearts.
- Screen play while you're away: after 1, 3, 5 or 10 minutes idle, or on demand with **Play now**, the pet jumps out of the menu bar, explores your windows, hides behind them, hunts the cursor, gets the zoomies, chases a butterfly and naps on the highest window. It returns as soon as you move the mouse, and it never starts during video, calls or presentations.
- English and Ukrainian, switchable instantly from the menu.
- Launch at login, enabled automatically on first launch from Applications.

[Unreleased]: https://github.com/oRIOnTx/amazing-pet/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/oRIOnTx/amazing-pet/releases/tag/v1.0.0
