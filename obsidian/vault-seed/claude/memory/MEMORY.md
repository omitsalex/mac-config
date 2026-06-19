# Memory Index

Local knowledge base for this machine. **Not** synced to iCloud — lives at
`~/Documents/Obsidian`. Back it up via git when ready; merge into the personal
vault with `rsync -a --ignore-existing` (same directory layout).

## Work Projects
<!-- work/{repo-name}/ — one folder per repo. Scaffold with project-skeleton. -->

## How this works
- Work projects live in `work/{repo-name}/` (mirrors the personal vault layout).
- Note types: `research/`, `decisions/`, `bugs/`, `patterns/`, `sessions/`.
- Each project has an `_index.md` — update it whenever you add or rename a note.
- Before researching any topic, check `research/` first — never redo captured work.
- **Merge path:** `rsync -a --ignore-existing ~/Documents/Obsidian/ <personal-vault>/`
  copies `work/` into the personal vault with no renames or conflicts.

*Seeded by mac-config (Nix). Safe to edit — Nix won't overwrite existing files.*
