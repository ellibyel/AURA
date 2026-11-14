# AURA — Feedback log (Assignment 4, build 4.4)

Every change below is in build 4.4 (tag `v4.4`). "Checked" says how we tested it.

## Instructor feedback (Assignment 3) 

### 1. Replace the AI-generated character with our own image

- **Before:** the fairy on the main menu was made with ChatGPT image generation, and all six files showed the same pose.
- **What we changed:** we went back to our own elf-mage design from Assignment 2, where she was drawn from simple shapes in Godot code. We rebuilt the same shapes as Photoshop pictures. Each pic a 400×600 document in Photoshop with every body part on its own layer (hair, robe, arms, staff, ears, face, eyes, mouth, brooch). The game frames are rendered from the same shapes.
- **Result: 8 character frames** in `assets/art/lightkeeper/`: `idle_1`, `idle_2` (breath), `idle_blink`, `happy_1`, `happy_2` (jump), `idle_surprised`, `sad_1`, `sad_2` (tear).
- **Character animation** (in `scenes/lightkeeper.tscn`, editor-authored):
  - `idle`: breathing and blinking
  - `happy`, `sad` (falling tear), `surprised`
  - `float`: gentle up-and-down motion
  - `pop`: squash-and-bounce when tapped
- **Checked:** `verify.gd` "tapping the lightkeeper changes her emotion" — PASS. On iPhone 14 Pro the moods change on every tap (gameplay video, 1:18).

### 2. UI: icons instead of long text buttons, bigger board, less space for minor UI

- Round icon buttons sit on a layer over the board: rotate, undo, delete, reset, hint and pause.
- Title, stars and mirror count are small chips at the top, and tips are short toasts.
- **Checked:** `verify.gd` "in-game controls are icons, not long text buttons" — PASS.

### 3. Levels are too easy / add more levels

- There are now 8 chapters (was 2), with stone walls and a mirror limit.
- Stars are stricter: an extra mirror costs a star and a hint costs a star.
- `tools/level_solver.py` checks the minimum number of mirrors for every chapter.
- **Checked:** `python3 tools/level_solver.py check-all` — all 8 chapters match their par. `verify.gd`: every stored solution gives 3 stars and one extra mirror gives 2 stars.

### 4. Optional tilt control

- Settings → "Tilt to rotate" turns the selected mirror when the phone is tilted. It is off by default.
- **Not yet checked on a real phone.**

## Player feedback (our own playtests) [DATE, number of players]

### 5. Pause button on the left

- **Feedback:** players looked for the pause button in the top-left corner, not the top-right.
- **What we changed:** pause moved to the top-left corner, and hint stays top-right (`scripts/game_ui.gd`).
- The position respects the phone's safe area (Dynamic Island, camera cut-outs): `_safe_edges()`, `_safe_top()`.
- **Checked:** `verify.gd` "pause button sits in the top-left corner" — PASS. On iPhone 14 Pro the button is clear of the Dynamic Island (gameplay video).

### 6. Cells were still hard to hit

- **What we changed:** the board cells are bigger, from 52 px in Assignment 3 to 68 px and now 76 px. The board fills about 81% of the screen (`scripts/game_scene.gd`, `GRID_SIZE`).
- **Checked:** `verify.gd` "board fills more than 75% of the screen, cells 76 px" — PASS. We played chapters 1–5 on iPhone 14 Pro.

### 7. A nicer title font

- **Feedback:** players found the default title font plain.
- **What we changed:** the AURA title now uses **Cinzel** (SIL Open Font License 1.1, `assets/fonts/`), a wide serif.
- **Checked:** visible on the main menu (gameplay video, 1:18).

## Monetisation model (demo)

- **Model:** free game with an optional rewarded ad. Each chapter has one free hint. After that, the hint button shows "AD", and the player can watch a short ad to get one more hint. There are no forced ads and no paywall.
- **In build 4.4:** the ad is a **demo "house ad"**. It is our own screen promoting AURA ("Share AURA with a friend"), clearly marked "ADVERTISEMENT · DEMO", with a 5-second countdown before "Close and get hint".
  - No real ad network or SDK is included.
  - No player data is collected.
- **Where:** `scripts/game_ui.gd` (`offer_ad`, `_play_ad`, `AD_SECONDS`), `scripts/game_scene.gd` (`grant_hint`).
  - The ad slot is one function, so another ad (our own or a partner's) can be shown there.
  - Connecting a real ad network would need its SDK and a privacy notice, and we have not done this.
- **Checked:** `verify.gd`:
  - "after the free hint, the hint button offers the demo ad"
  - "demo ad reward is locked during the countdown"
  - "watching the ad grants a hint"
  - All three PASS. Also shown in the gameplay video, 1:12.
