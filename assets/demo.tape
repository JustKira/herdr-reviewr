# Demo recording for herdr-reviewr. Regenerate with:
#   herdr plugin install persiyanov/herdr-reviewr --yes && vhs assets/demo.tape
# Builds a throwaway git repo with an agent-style change, then drives the installed release through
# the review loop. Needs `git`, `herdr`, `jq`, and `vhs`, with `persiyanov.reviewr` installed.

Require git
Require herdr
Require jq

Output assets/demo.gif

Set Shell "bash"
Set FontSize 13
Set Width 1320
Set Height 820
Set Theme "Catppuccin Mocha"
Set Padding 16
Set TypingSpeed 45ms

# --- Hidden setup: a temp repo with a committed baseline + an uncommitted edit to review ---
Hide
Type "VERSION=$(awk -F'\"' '/^version = / {print $2; exit}' herdr-plugin.toml) && BIN=$(herdr plugin list --plugin persiyanov.reviewr --json | jq -er --arg version $VERSION '.result.plugins[] | select(.version == $version and .source.kind == \"github\") | .plugin_root + \"/bin/herdr-reviewr\"') && test -x \"$BIN\" && bash assets/demo-fixture.sh /tmp/herdr-reviewr-demo || exit 1" Enter
Type "bash /tmp/herdr-reviewr-demo/.git/reviewr-demo/demo-session $BIN || exit 1" Enter
Show

# --- The review loop ---
Sleep 2s

# Focus the diff and move into the changed region.
Tab
Sleep 700ms
Type "jjjj"
Sleep 900ms

# Select a line range...
Type "v"
Sleep 400ms
Type "jj"
Sleep 700ms

# ...and comment on it.
Type "c"
Sleep 600ms
Type "guard the empty value here too?"
Sleep 800ms
Enter
Sleep 1200ms

# Send the review. reviewr exports it to the agent input and confirms the handoff in the footer.
Type "s"
Sleep 2800ms
