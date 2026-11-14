# Map — X-shaped village (4 players)

Built by `src/server/Services/MapService.luau` from `Config/Map.luau` + `Config/Plots.luau` every time a server starts.
Nothing to place by hand. Studio → **Play** to see it (the edit view stays empty).

```
              N  (Plot3)
        river \   |   / road
               \  |  /
   W (Plot2)    [BRIDGE + TOWN]    E (Plot4)
               /  |  \
         road /   |   \ river
              S  (Plot1)
```

| Part | How it's built | Size |
|---|---|---|
| Playable area | square, invisible solid walls on the edge, trees outside | **720 × 720 studs** (v1 was 480 × 480; ×1.5 on 14 Nov 2026) |
| Ground + river | **Terrain**: flat leafy-grass slab (no 3D grass blades), river carved NW → SE (swimmable, 1 stud below the bank) | river 48 wide, 8 deep |
| Road | asphalt strips SW → NE with dashed center line and lamps (lamps light up at night) | 28 wide |
| Bridge | plank deck over the river, 2 stone abutments + 2 piers, ramps at both ends, rails over the water | 72 × 64, deck 5 studs up |
| Town | 6 shophouses with signs (4 on the +Z strip, 2 on the −Z strip) + the **Warung** stall in the middle of the −Z strip | on the deck |
| Warung + NPCs | `Workspace.Warung` is the stall (scenery). The 4 shopkeepers are rigs in `Workspace.Npcs` (`NpcService`, positions in `Config/Npcs`): Pak Darmo behind the Warung counter, Bu Wati at Toko Bibit, Mas Joko at Toko Pancing, Mbok Minah at Pasar Ikan, Bang Tarno (haggle: buys crops at 0.7x, you bargain the price up) at Lapak Tarno. Each has one "Ngobrol" prompt → dialogue → shop | — |
| Fishing | 12 identical docks (both banks), each with an invisible spot and a small sign. **NW arm → `sungai`** (6 docks), **SE arm → `empang`** (6 docks) | — |
| Player land | 4 identical **green wedges** (blueprint 1 = S, 2 = W, 3 = N, 4 = E): ≥ 28 studs from both the river and road axes (v3; was 32), painted green (LeafyGrass) on sandy public ground, edged by a low bamboo fence (not solid). Each has a **rumah panggung**; ponds are dug by the player (Garap → Kolam) | v3: the land reaches 8 studs from the map wall (BACK_DISTANCE 352) → about **228 deep × up to ~600 wide** (front now 124 studs from the center, FRONT_Z 104); v2 was 180 × 568 ≈ 70.500 studs², v1 120 × 344 ≈ 27.000 studs² |
| Soil | **Terrain**, not parts: 8 × 8 grid tiles painted flat on the ground; dry = Ground, watered = Mud (edges are soft because Terrain blends materials). Details in `Phase12_Garap_NPC_Design.md` | — |
| Spawn | `TownSpawn` on the bridge; PlotService moves the player to their plot right after | — |

**Fish locations:** Lv1 *Sungai* (NW arm of the river), Lv4 *Empang* (SE arm, same river), Lv6 *Kolam* (ponds you dig on your own plot). Both arms are the same river with the same docks; only the sign and the fish table differ. The Empang spots are needed: Mujair, Bawal and Gurame only live there, and the Collection Book and orders expect them.

## Models from ForgeGUI (already generated)

Files in `assets/models/` (each ≈ 4.5k triangles, 1 mesh, PBR textures; well under Roblox's limit):

| File | Used for | Placed at |
|---|---|---|
| `Warung.glb` | the selling stall | `Workspace.Warung` (height 11 studs) |
| `TokoKota.glb` | the 6 shophouses on the bridge | each shop (height 14 studs; same model, copied 6×) |
| `RumahPanggung.glb` | the house on every plot | each plot (height 13 studs) |

**Import (once, in Studio):**
1. **Asset Manager → Bulk Import → Import 3D** (or File → Import 3D), pick the 3 `.glb` files, and import. Each lands as a Model with 1 MeshPart.
2. In **ServerStorage** create a Folder named exactly `MapModels`; move the 3 imported models into it and rename them exactly **`Warung`**, **`TokoKota`**, **`RumahPanggung`**.
3. Press Play. The placeholders are replaced automatically (scaled to the heights above).
4. Wrong way round? Select the model in `MapModels`, add a number attribute **`FrontYaw`** (degrees: 90, 180 or 270) so its front faces the road/plot front. No code change.

Importing runs in your own Studio; nothing is published to Roblox from here (ForgeGUI has no Roblox connection set up).

## Test checklist (Studio → Play)

0. **Garap** (new): press **Garap** (left edge) → move the mouse over your green land: a green square follows the grid (red = not allowed, e.g. on the house, pond, decor, outside the green, or tile cap reached). Click/tap → the cell becomes brown soil (flat terrain paint). **Ratakan** removes an empty bed. Tap a soil tile (outside Garap mode) → seed picker → plant → water → harvest. Rejoin: soil and crops are still there.
1. You spawn on the bridge, then are moved to your plot (Plot1, south). The plot's front (sign side) faces the town.
2. Walk the road to the bridge: ramps are smooth, no gap or step.
3. Walk up to an NPC and press **E** ("Ngobrol"): the dialogue shows two choices, **Jual / Beli** (opens that NPC's shop) and **Sampai jumpa**. Pak Darmo: buy seeds / upgrades, sell crops. Bu Wati: unggul seeds (grow 10% faster, 1.5× price). Mas Joko: rods + bait. Mbok Minah: sell and buy fish. Walk away: dialogue and shop close; server refuses trades beyond 25 studs.
4. Dock on the NW arm → **Mancing**; catch a fish. Go to a dock on the SE arm (sign says Empang · Lv 4) and catch an empang fish.
5. Jump in the river: you swim and can climb out. You can't leave the map edge.
6. Night (`!time malam`): lamps along the road, on the bridge, and the Warung lantern glow.
7. **Test → 2–4 players:** each gets a different plot; Mampir (Warga panel) and Suka work between plots.

## Knobs (all in `Config/Map.luau` / `Config/Plots.luau`)

River width/depth, road width, bridge size, dock positions and their location (`RIVER_DOCKS`), house position (`HOUSE`), land shape (`LAND.SETBACK`, `LAND.BACK_DISTANCE`) and the plot anchor (`Plots.DISTANCE`, `Plots.FRONT_Z`). `DISTANCE`, `FRONT_Z` and `DISTANCE − BACK_DISTANCE` must be multiples of 4 (terrain cells). The river, road, bridge and town were NOT scaled with the map; only the map, the land and the plot distance were. `tools/` geometry checks live in the session scratch (see Land.luau header for the rules).

## Terrain facts (measured in Studio, all encoded in `Modules/Land.luau` and `MapService`)

- The visible terrain surface is **2 studs above the top of a filled block**, so `MapService` lowers every block by 2 to get a ground at **y = 0**. (Water is the exception: its surface is exactly the block top.) Before this fix the whole terrain sat at y = 2, which buried the road, the plot slab and half of every dock.
- Terrain cells are **4 studs, edges at multiples of 4**. A block paints a cell's material when the cell's **center** is inside the block, so paint blocks are 0.5 smaller than the cells they fill.
- A thin raised "bed" on top of the ground does not show; repainting the top cells' material does, so soil is flat paint.
- Studio's own selection outline (a thin box around the plot model when you hover/select it) is not game code; it looked like a yellow plot border.

## Tested in Studio (Play, 14 Nov 2026)

Verified by running the game: land is green at all four plots, public ground sand, road continuous with dashes and lamps, river surface at y = −1 and banks at 0, Garap preview (green / red / amber), till, level, plant, water (soil turns Mud), harvest (soil dry again), decor rejected on soil and accepted on free grass, and a stop/start cycle kept every tile, crop and soil state.
Not yet tested: 2+ players, mobile touch, the Warung NPC panel, fishing from the new docks.

## Known limits / next steps

- **Not tested in Studio yet** — Studio tools were off this session. Geometry was checked with a script (plot clearance, docks, lamps, trees, ramp heights) and the project builds with Rojo, but Luau syntax/visuals need your first Play.
- Terrain edges on the diagonal are voxel-soft (4 studs); bank docks hide most of it. A designed riverbank (rocks, reeds) is a UI/art pass for you.
- Shopkeeper is a plain colored rig; swap for your designed NPC (anchored, facing the stall's +Z).
- Existing saves with decor inside the new house area get it back in stock automatically on join.
- `Max Players` must be **4** in Game Settings.
