# Sunny Acres: a cozy 3D farm game (Godot 4)

A small, touch-first low-poly farm game made with **Godot 4.7.2** (GDScript, Compatibility renderer).
It runs in phone browsers through GitHub Pages.

## Play
After every push to `main`, GitHub Actions builds the web version and publishes it to GitHub Pages.

## Open in Godot
1. Open Godot 4.7.2 and choose **Import**, then select `project.godot` in this folder.
2. Press **F5** to play. On PC, drag with the mouse to move the camera, use the wheel to zoom, and click to tap.

## Change the game numbers
Every price, timer, reward and limit lives in **`scripts/config.gd`**. Edit a value, save, and press Play.

## Project layout
| Path | What it is |
|---|---|
| `scripts/config.gd` | All tunable numbers (autoload `Config`) |
| `scripts/game.gd` | Game state, save/load, and real-time timers (autoload `Game`) |
| `scripts/main.gd` | Builds the farm world and handles taps |
| `scripts/camera_rig.gd` | Drag, pinch-zoom, mouse wheel, and tap detection |
| `scripts/plot.gd` | A farm plot with wheat growth stages |
| `scripts/mill.gd` | The windmill |
| `scripts/model_util.gd` | Loads Kenney models and applies the shared color palette |
| `scripts/ui/` | HUD (top bar, toasts, flying icons) and the glossy UI style |
| `tools/bake_icons.gd` | Re-renders the UI icons (`Godot --path . res://tools/bake_icons.tscn`) |
| `.github/workflows/deploy.yml` | Web export + GitHub Pages deploy |

## Saving
The game saves to `user://save.json` (IndexedDB in the browser) every few seconds and when the game is closed.
Crop timers use real clock time, so crops keep growing while the game is closed.

## Credits
See [CREDITS.md](CREDITS.md).
