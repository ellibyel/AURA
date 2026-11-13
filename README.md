# AURA

AURA is a relaxing light-reflection puzzle: place and turn mirrors on a grid to bend the light beam.

**Version 4.1** (Assignment 4) — Android APK and iOS build, 8 chapters.

## Team

- **Elmira** — mechanics & levels (beam reflection, undo, star rewards; level data `level_1/2.json`; demo: Chapter 1 → Chapter 2)
- **Diana** — interface & game flow (bigger buttons, contrast, pause; iPhone layout, settings, saving; demo: pause, restart, rotation)
- **Khalida** — visuals, animation & sound (editor animation, particles; sounds, music, Reduce animation; demo: animations, sound on silent)

## Requirements and opening

For running the project, Godot 4.7.2 (stable) is needed. Download the repository (Code → Download ZIP on GitHub, or git clone) and extract it. Open Godot, click Import and select the `GameProject/project.godot` file. Once the project opens, press F5 to run the game.

Auto-tests are located in the `tests/` folder. To run them, open `res://tests/verify.tscn` in Godot and press F6 (Run Current Scene), or run from the terminal:

```
godot --headless --path GameProject res://tests/verify.tscn
```

All 51 checks should print PASS.

Every level is checked by `tools/level_solver.py` (Python 3): `python3 tools/level_solver.py check-all` prints the minimum number of mirrors for each chapter.

To build the Android APK: Project → Export → Android → Export Project (debug keystore, Godot 4.7.2 Android templates).

To build the game for iPhone:

1. Open the project in Godot on a Mac and install the export templates for Godot 4.7.2 (Editor → Manage Export Templates).
2. Open Project → Export, select the iOS preset, and check the app details (bundle ID `com.mt2402.aura`, your Team ID).
3. Export the project and open the generated `AURA.xcodeproj` in Xcode. Under Signing & Capabilities, select your Apple team for code signing.
4. Connect your iPhone, select it in Xcode, and click Run.
5. On the iPhone, trust the developer once: Settings → General → VPN & Device Management.

## How to play

**Goal:** Your goal is to light up every star on the board with a single beam. Stone walls stop the light, and each chapter gives a limited number of mirrors.

**Gameplay loop:** Place a mirror → Rotate it → Watch the beam → Adjust → Light every star → Complete the chapter.

**Controls (touch):**

- Tap an empty cell — place a crystal mirror
- Tap a mirror — select it
- Round arrow icons (right side) — turn the selected mirror by 45°
- Undo / Delete / Reset icons (left side) — undo the last action, remove the selected mirror, clear the board
- Light bulb icon — hint (1 free per chapter; a demo "rewarded ad" gives one more)
- Pause icon — Resume, Restart, Chapters, Settings, Main menu
- Optional: Tilt to rotate (Settings) — tilt the phone left or right to turn the selected mirror

**3 stars:** Complete a chapter with the minimum number of mirrors (found by the level solver) and no hints. One extra mirror costs a star, using hints costs a star (minimum 1 star). Each chapter allows only one mirror more than the minimum.

## What changed since Assignment 2

After Assignment 2, we improved the game based on feedback and phone testing:

- Small buttons and text, purple text on a purple background → bigger buttons (100 px), text at least 22 px, dark text on light panels
- Three sound effects with unknown authors and licences → replaced with Kenney CC0 sounds (credited); own music made in GarageBand
- Unclear AI use; AI-made assets and code-drawn animation → animation moved to editor scenes (AnimationPlayer, sprite frames); AI use listed below
- Win panel covered the lit star, no pause after leaving the app, black side bars, no sound on silent mode → 1.5 s panel delay, pause on focus loss, full-width layout, Playback audio session

## What changed in Assignment 4

- Assignment 3 feedback (UI): the board now fills most of the screen; text buttons were replaced with round icon buttons on a layer over the board; the title, stars and mirror count are small chips; tips are short toasts.
- Assignment 3 feedback (difficulty): 8 chapters instead of 2, stone walls, a mirror limit and stricter stars. Every level is checked by a solver; most have one to four possible minimum solutions.
- Animated background (drifting scenery, glowing moon, fireflies), vibration feedback, optional tilt controls, chapter select with stars, demo rewarded ad, built-in performance test (Settings → Performance test).

## Mobile interface

- **Buttons:** Large 100 px buttons in one row at the bottom; Rotate buttons on the right, under the thumb.
- **Pause:** Pause button in the top-right corner opens Resume, Restart, Settings and Main menu. The game pauses automatically when you leave the app.
- **Win panel:** Appears 1.5 s after the last star lights up and shows reward stars, mirrors used, and Try again / Main menu / Next chapter.
- **iPhone screen:** The layout is centred and the background fills the full width, so there are no black bars. Nothing goes under the Dynamic Island or the home bar.

## How it works

Light beam and reflections (file: `scripts/game_scene.gd`, function: `_recalculate_rays()`):

1. **Start the beam:** The beam starts at the sun and goes down.
2. **Find the nearest hit:** The code finds the closest mirror on the beam's path, or the board edge.
3. **Reflect:** The beam bounces off the mirror at a new angle and continues (max 64 bounces).
4. **Check the stars:** Every star the beam passes through lights up. When all stars are lit, the chapter is complete.

## Project structure

- `project.godot` — file used to open the project
- `scripts/` — code that manages the game
- `scenes/` — screens and core parts of the game
- `scenes/pieces/` — individual game items
- `levels/` — level data
- `assets/` — images, music and sounds
- `tests/` — automated checks
- `tools/level_solver.py` — level solver and generator

## Testing

- **Device:** iPhone 14 Pro, iOS 26.6
- **What we tested:** 16 checks on the real iPhone (mirrors, undo, hints, pause, app switch, rotation, saving, sound) + 34 automated checks in Godot
- **Found and fixed:** win panel hid the lit star → 1.5 s delay; no pause after leaving the app; black side bars; no sound on silent mode — all fixed and re-tested
- **What's left:** only 2 chapters; the development build must be reinstalled every 7 days

## Known limitations and unfinished work

- Currently, 2 chapters out of the planned 25 are ready.
- The iPhone application needs to be re-signed every seven days (the development build must be reinstalled every 7 days).

## Credits and licences

**Sounds** — Kenney (kenney.nl), licence CC0 1.0:

| File | Used for | Source |
|---|---|---|
| `glass_001.ogg` | placing a mirror | "Interface Sounds" — https://kenney.nl/assets/interface-sounds |
| `pluck_001.ogg` | rotating a mirror, volume buttons | "Interface Sounds" — https://kenney.nl/assets/interface-sounds |
| `jingles_STEEL00.ogg` | completing a chapter | "Music Jingles" — https://kenney.nl/assets/music-jingles |

**Music** — assembled by us in Apple GarageBand with the "Set Free Melodic Synth" loop and the Grand Piano instrument, used under the GarageBand licence.

**Art** — The lightkeeper (`assets/art/lightkeeper/`, 6 frames: idle, breath, blink, happy, jump, surprised) is our own elf-mage design from Assignment 2, where it was drawn from shapes in Godot code. For Assignment 4 the same shapes were rebuilt as layered Photoshop scripts (`tools/photoshop/`, one per pose) and the 6 frames were rendered from these shapes. The star icon was created using image generation in ChatGPT. The background and simple game figures were created programmatically using ChatGPT. Images were prepared in PNG format matching game dimensions. We did not draw these images manually in Photoshop.

**Engine and font** — The game is made in Godot. Engine licence — MIT: https://godotengine.org/license/ The standard Godot font is used.

**Inspiration** — We were inspired by the atmosphere of Frieren, the calm style of Monument Valley, and Portal puzzles. Their images, music, and other ready-made materials were not used in the project.

## Use of AI tools

- The Assignment 2 code was written with the help of ChatGPT/Codex.
- ChatGPT/Codex helped us identify potential risks, choose suitable iPhone test cases, and organize how to document them. We also used AI to review and assess our interface.
- Claude Code wrote the Photoshop shape scripts and rendered the lightkeeper frames for Assignment 4.
- Claude Code helped us learn Godot and its programming language, and supported code changes, the iOS build, and testing for Assignment 3.
- Diana created the interface and game flow.
- Khalida created the visuals, animations, and sound.
- Elmira designed the mechanics and levels.
