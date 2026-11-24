# Kampoeng Tedoeh — notes for Claude

Roblox farming game in Luau, built with Rojo. Owner plays it and gives feedback; Claude writes all code and docs.

## Start here
- Branch: `feat/v.7`. Build for release is not set up yet.
- Read `docs/Home.md` first (map of all docs). Read only the section you need: grep the headings first (`grep -n "^## " docs/<file>.md`), never load all of `docs/01_GDD…` at once.
- Status source of truth: `docs/06_Roadmap.md`, the **Status** and **Commit** columns. Start each session at its **Handoff** block.

## Checks (run before every commit)
- `selene src`: 0 errors. Warning baseline is **85**; it must not go up.
- `rojo build default.project.json -o "$TEMP/kt_check.rbxl"`: exit 0.

## Rules
- One task = one commit: `<type>(<id>): <short>`, e.g. `fix(T0): …`.
- Docs that describe the changed behavior are updated in the same commit (GDD, GUI 05, Quest 03, 09 checklist, Roadmap).
- Never mark a task VERIFIED without a Play run. Say how it was run (Studio, which steps). Anything the UI could not do is labelled "remote path, not UI" and stays NOT verified.
- After each task, update the Handoff block in `docs/06_Roadmap.md`.

## Tutorial GUI rules (LOCKED, from owner playtests)
- Spotlight dim only for first-time steps that target a fixed HUD button: one overlay with a hole, never blocks the joystick, releases after 25 s.
- Floating GUI and world targets: yellow outline only, first time only.
- Repeat steps: toast only.
- One instruction surface per step.
- One toast system in one place under the Koin/Bunga bar (GUI 4.2). No module makes its own hint label.
- Aksi-slot buttons are one round component.

## Working with the repo
- Ignore `kmpgtdh/` (not ours; do not stage or delete it).
- Obsidian per-machine files in `docs/.obsidian/` stay ignored; only `app.json` is tracked.
- Owner decisions are logged in `docs/02_Audit_Perbaikan.md` (Bab 3 K-nn). Add a K-nn there, not in code comments.
