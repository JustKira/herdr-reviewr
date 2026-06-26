# Diff viewer — visual polish backlog

Tuning and polish within the current stack (ratatui + syntect/two-face + Catppuccin). Not design changes — knobs and small additions. Fold into milestone 2 or a dedicated polish pass. ⭐ marks high niceness-per-effort.

## Structural palette (constants in `src/ui.rs`)

- ⭐ Retune the add/remove row tints (`DEL_BG`, `INS_BG`) — current values read muddy; align to Catppuccin diff conventions so changes pop without shouting. Tune live.
- ⭐ Emphasize the current line's number (brighter/bold), the way editors do.
- Swap/tune the change-bar colors, cursor-line bg (surface1), selection bg (surface0).
- Dim unchanged context slightly, or brighten changes, so the eye lands on the diff.

## Chrome / borders

- ⭐ Rounded borders (`BorderType::Rounded`) instead of square.
- Border + title colors in Catppuccin tones (focused vs unfocused); inner padding; a subtle header bar (mantle/crust) instead of the bright cyan.

## Nerd Font glyphs (terminal already uses JetBrainsMono Nerd Font)

- ⭐⭐ File-type icons (devicons) in the file list — a small extension→glyph map.
- Git branch glyph on the scope chip; a comment glyph in the gutter on commented lines; a nicer fold chevron.

## Gutter & extras

- ⭐ A subtle scrollbar / position rail on the diff (ratatui `Scrollbar`), optionally marking comment positions (mini-minimap).
- Thin separator between gutter and code; a small left margin so code doesn't hug the border.
- Dual old|new number columns even in unified view (currently single).

## Approach

Color values are see-it-live decisions — wire a batch, push to the pane, tune by eye ("warmer / dimmer / more contrast") rather than guessing hex in the abstract.

## All files — deferred from the UX-review pass (2026-06-26)

The UX review of the All files tab fixed the high-value items (A–H); these were consciously deferred.

- **Git-blob/diff-side read cap.** `set_file_view` now checks on-disk size before reading (`app.rs`), but the diff path (`git::file_content` → full `git show` stdout; `worktree_content` on the new side) still reads before `build`'s budget trips. Mirror the metadata guard with `git cat-file -s` on the blob side. Pre-existing, less acute than the one-keystroke File-view path.
- **File-view per-frame height/wrap recompute.** `diff_row_heights` re-wraps every visible row each frame; the File view disables folding, so `visible` is the whole file (up to the 50k-line cap), making `j`-scroll on a big file laggy. Memoize heights by `(content-hash, width, wrap)`, or measure only the scroll window. Same class as the M5-deferred "single measure+paint pass".
- **`set_scope` reveals the cursor.** A scope switch sets `reveal_files = true`, which can yank a wheel-scrolled All files viewport back to the cursor, against file-list.md's "scroll holds". Minor; only after a wheel scroll.
- **Header count vs. visible markers.** The count is the changeset (e.g. `3 changed`) while a deletion in that set has no row in the worktree tree, so the number can exceed the marked rows. Spec-sanctioned; no change.
- **Symlinks render target content.** `worktree_content`'s `fs::read` follows links. Acceptable; a broken symlink reads empty → "empty file".
- **Dropped: prune `reveal_path`'s folded-prefix toggles.** Considered, not done — those toggles encode "the seed revealed this path", so on a later unfold keeping the path expanded keeps the seeded file visible (correct), not a surprise.
