# Branch scope as a superset of uncommitted — Delivery Plan

**Specs:** ../../../specs/ — the living reference this plan delivers

## Milestone Map

1. **Branch spans the worktree** — single milestone; `branch` diffs the merge-base against the working tree (committed + uncommitted + untracked) instead of `merge-base...HEAD`.

## Goal

The `branch` scope shows every change the branch carries over its base — committed and uncommitted — so it is a superset of `uncommitted` and never goes empty while the agent's work is uncommitted (`review-model.md`, Scopes).

## Definition of Done

- In a repo whose only changes are uncommitted, `branch` lists those changes (it does not show empty).
- `branch` lists committed branch work, uncommitted edits, and untracked files together, with the merge-base as each diff's old side.
- `cargo test` passes, including a `git_repo.rs` test that asserts `branch ⊇ uncommitted`.

## Exit State

- `git::range` returns the merge-base commit for `Scope::Branch` (so `git diff <merge-base>` runs merge-base vs worktree), and `None` when no base ref resolves — branch stays empty in that case.
- `git::changed_files` includes untracked files for `Scope::Branch`, via the same `assemble(include_untracked)` path `Uncommitted` uses.
- `app::content_sides` resolves the `Branch` new side from the worktree; the old side stays the merge-base.
- No new types, scopes, fields, or flags — the `Scope` enum and `ChangedFile` are unchanged.

## Specs Touched

| Spec | What this plan realizes | At the gate |
| --- | --- | --- |
| `review-model.md` | the redefined `branch` scope and its superset relationship to `uncommitted` | Draft → Current |

## Out of Scope

- A separate committed-only / "PR" scope — deferred unless the clean-PR view is later wanted (`review-model.md` Decisions).

## Likely Files

- `src/git.rs` — `range` Branch arm → merge-base commit; `changed_files` Branch arm → `include_untracked = true`; refresh the `range`/`changed_files` comments that say `HEAD`.
- `src/app.rs` — `content_sides` Branch arm → new side from the worktree; refresh its doc comment.
- `tests/git_repo.rs` — reshape `branch_scope_diffs_against_base_not_working_tree` to the superset contract; keep `branch_scope_falls_back_to_master_when_main_is_absent`.
- `README.md` — one-line refresh to the `branch` row under "Diff scopes".

## Execution Plan

1. Change `range` so `Scope::Branch` resolves the merge-base commit (`merge_base(repo, base)`), keeping `None` → empty when no base resolves.
2. Set `include_untracked` true for `Scope::Branch` in `changed_files`.
3. Point the `content_sides` Branch new side at `worktree_content`; leave the old side on the merge-base.
4. Reshape the branch test: one repo with a committed change, an uncommitted edit, and an untracked file → all three appear in `branch`, and `branch` is a superset of `uncommitted`. Add the `HEAD == merge-base` case → `branch` equals `uncommitted` rather than empty.
5. Update the README "Diff scopes" `branch` line, the touched code comments, and promote `review-model.md` to Current.

## Verification

- **Done:** `cargo test` green; the reshaped `git_repo.rs` test asserts committed + uncommitted + untracked all show in `branch` and that `branch ⊇ uncommitted`.
- **Tight:** the diff equals Exit State — no new scope, type, field, flag, or export; only the three call sites, their comments, the test, and the README line change.
- **Invariants upheld:** read-only — the scope runs `git diff` / `git show` / `git status` only, asserted by the existing `git_access_never_mutates_the_repo` test; `forbid(unsafe)` unaffected.

## Replan Triggers

- If a one-arg `git diff <merge-base>` mis-reports renames or untracked stats versus the `Uncommitted` path, align the Branch arm with whatever `Uncommitted` does rather than adding scope-specific handling.

## Replan Log

- 2026-06-26: initial plan from approved contract.
