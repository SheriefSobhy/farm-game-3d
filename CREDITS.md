# Credits

All third-party assets are free for commercial use.

| Asset | Author | License | Source | Used for |
|---|---|---|---|---|
| Nature Kit (2.1) | Kenney | CC0 1.0 (public domain) | https://kenney.nl/assets/nature-kit | Crops, soil rows, trees, bushes, flowers, rocks, fences, path, props |
| Fantasy Town Kit | Kenney | CC0 1.0 (public domain) | https://kenney.nl/assets/fantasy-town-kit | Mill walls, roof and windmill sails (plus spare wall/roof pieces for future buildings) |
| Food Kit | Kenney | CC0 1.0 (public domain) | https://kenney.nl/assets/food-kit | Bag and bread models (for future flour/bread) |
| Fredoka (variable font) | The Fredoka Project Authors | SIL Open Font License 1.1 | https://github.com/google/fonts/tree/main/ofl/fredoka | All UI text |
| Godot Engine 4.7.2 | Godot Engine contributors | MIT | https://godotengine.org | Game engine |

Notes:
- The original license files are kept next to the assets:
  `assets/models/nature/License.txt`, `assets/models/town/License.txt`,
  `assets/models/food/License.txt`, `assets/fonts/OFL.txt`.
- kenney.nl was blocked on the build PC's network, so the unmodified Kenney `.glb`
  files were taken from a public GitHub mirror of the same packs
  (`ConcordDev/concord-cognitive-engine`, folder `unity-client/Assets/Concordia/FreePacks/Kenney`).
- At runtime the game recolors the Nature Kit materials to one shared warm palette
  (see `scripts/model_util.gd`). CC0 allows this.
- The coin, gem, star and wheat-sheaf icons in `assets/icons/` were made for this
  project with `tools/bake_icons.gd` (simple shapes rendered in Godot). No third-party art.
