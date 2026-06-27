# Show gitignored files + reviewr config — Delivery Plan

**Specs:** ../../../specs/ — the living reference this plan delivers

## Milestone Map

1. **Config + keep in Changes** — *done*; `config.toml`/`keep` loads, and opted-in ignored paths show in `Changes` across all three scopes.
2. **All files shows ignored** — *done*; `All files` lists every file (ignored dimmed), wholly-ignored dirs as lazy collapsed placeholders that load children on expand.

The split is the plan's named replan trigger firing: `file_list::build()` flattens a complete
`&[Entry]` eagerly and derives directories from file paths, so a wholly-ignored dir cannot be a
collapsed row that fetches children on expand without a model change. That change is isolated to
milestone 2; milestone 1 delivers the core need (opted-in ignored paths reviewable) on the
existing model.

## Goal

A user sees every file in `All files` (ignored dimmed, build dirs lazy) and opts specific ignored paths — like `docs/plans/` — into the `Changes` tab via a `keep` list in reviewr's config, without committing anything to the repo.

## Definition of Done

- `All files` lists tracked, untracked, and ignored entries; ignored rows render dimmed; `.git` is absent; a wholly-ignored dir (`target/`) is one collapsed row whose contents load on expand.
- A `keep` glob in `config.toml` makes a matching ignored path appear in `Changes` as an untracked addition across all three scopes; an unmatched ignored path (build output) never appears.
- `config.toml` loads from `$HERDR_PLUGIN_CONFIG_DIR`; editing it and pressing `r` reflects the change; a missing or malformed file falls back to defaults with a status notice.
- `cargo test` passes, covering keep-matching across scopes, `all_files` including ignored, and dimmed rendering.

## Exit State

- `Config` carries `keep: Vec<String>`, loaded from `$HERDR_PLUGIN_CONFIG_DIR/config.toml` (top-level `keep` array) and re-read on `r`. New deps: `toml`, `serde` (derive).
- `git::changed_files` lists kept ignored paths as `Untracked` for `uncommitted` and `branch`; `git::snapshot_worktree` force-includes kept paths so `last-turn` shows them too.
- `git::all_files` returns every entry including ignored, wholly-ignored dirs as single entries, `.git` excluded.
- `file_list::Entry`/`Row` carry an `ignored` flag; ignored rows render dimmed (`ui.rs`); an ignored dir's children fetch on first expand.
- README documents `config.toml`/`keep` and drops the "ignored paths never appear" limitation.
- Not built: `.reviewrkeep`; any `theme`/`keys`/poll config key; a glob crate (gitignore matching is delegated to git's `--exclude-from`).

## Specs Touched

| Spec | What this plan realizes | At the gate |
| --- | --- | --- |
| `config.md` | the whole config home + `keep` list | Draft → Current |
| `file-list.md` | the whole `All files`-shows-ignored + dim + lazy-dir behavior | Draft → Current |
| `review-model.md` | the Ignored-paths section only | stays Draft → branch-scope plan |

## Out of Scope

- A committed per-repo `.reviewrkeep` that merges over `keep` — designed-in, deferred (`config.md`).
- `theme` / `keys` / poll-and-base config keys — the schema's growth path, not built (`config.md`).

## Likely Files

- `Cargo.toml` — add `toml`, `serde` (derive).
- `src/config.rs` — `keep` field; load `config.toml` from `$HERDR_PLUGIN_CONFIG_DIR`.
- `src/git.rs` — `all_files` includes ignored + lazy dirs; `changed_files` honors `keep`; `snapshot_worktree` force-includes kept paths.
- `src/file_list.rs` — `ignored` on `Entry`/`Row`; on-demand child load for ignored dirs.
- `src/app.rs` — wire config load + `r` re-read; trigger ignored-dir child fetch on expand.
- `src/ui.rs` — dim style for ignored rows.
- `tests/git_repo.rs`, `tests/render.rs` — keep-matching, `all_files`, dim rendering.
- `README.md` — "Configuration" adds `config.toml`/`keep`; "Limitations" drops the ignored-paths line.

## Execution Plan

1. Add `toml` + `serde` derive; extend `Config` with `keep`, loaded from `$HERDR_PLUGIN_CONFIG_DIR/config.toml`, re-read on `r`. Test missing/malformed → defaults.
2. Keep-in-Changes: write `keep` to a temp exclude file, list kept paths with `git ls-files -z --others --ignored --exclude-from=<tmp>`, append as `Untracked` in `changed_files` for `uncommitted` and `branch`. Test.
3. last-turn: force-add kept paths into the temp index after `add -A` in `snapshot_worktree`, so `changed_against_tree` surfaces kept changes. Test.
4. Spike the navigator first: confirm `build()` can render a wholly-ignored dir as a collapsed row and load its children on expand; if it needs an `Entry`/`build()` redesign, fire the replan trigger. Then have `all_files` include ignored entries (`git status --ignored`, dirs collapsed) minus `.git`, carrying the `ignored` flag.
5. Dim ignored rows in `ui.rs`; fetch an ignored dir's children on first expand. Test in `render.rs`.
6. Update the README; promote `config.md` and `file-list.md` to Current.

## Verification

- **Done:** `cargo test` green — keep paths show in all three scopes, build output never does, `all_files` lists ignored, ignored rows dim; live: add `docs/plans/` to `keep`, press `r`, the plan appears in `Changes`.
- **Tight:** the diff equals Exit State — only `keep`, the `ignored` flag, and the git-query changes; no `.reviewrkeep`, no theme/keys keys, no glob crate.
- **Invariants upheld:** reviewr never writes config or the worktree (read-only git plus a temp index) — asserted by `git_access_never_mutates_the_repo` and `snapshot_worktree_never_mutates_the_repo`; `forbid(unsafe)` unaffected.

## Replan Triggers

- If lazy ignored-dir expansion needs an `Entry`/`build()` redesign that balloons scope, split `All files` (steps 4–5) into its own milestone.
- If `toml`/`serde` trip `cargo-deny`, hand-parse the `keep` array instead of adding the deps.
- If `git ls-files --exclude-from` diverges from gitignore semantics on nested patterns, switch to `git check-ignore`-based matching.

## Replan Log

- 2026-06-26: initial plan from approved contract.
- 2026-06-26: split into two milestones. M1 (config + keep in Changes) built and green — `config.toml`/`keep`, kept paths surfaced across uncommitted/branch/last-turn, `toml`+`serde` added. The All-files spike confirmed the navigator needs an `Entry`/`build()` change for lazy ignored-dir expansion, so it becomes M2. `config.md` is fully realized; `file-list.md` stays Draft for M2.
- 2026-06-26: M2 (All files shows ignored) built and green. `git::all_files` returns `WorktreeEntry{path,ignored,is_dir}` with `git status --ignored` collapsing wholly-ignored dirs; `git::list_ignored_dir` reads one level on expand; `file_list` carries `ignored` on entries/rows and directory placeholders; `app::all_files_entries` loads expanded ignored dirs lazily (re-derived each reload, so poll-safe); `ui` dims ignored rows. `file-list.md` fully realized. All four feature specs (`config.md`, `file-list.md`, `review-model.md`) ready to promote at merge.
