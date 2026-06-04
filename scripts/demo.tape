# VHS tape — records media/demo.gif of the one-command install.
# Render with:  vhs scripts/demo.tape   (install: brew install vhs)
# Docs: https://github.com/charmbracelet/vhs
#
# Recorded with --dry-run (a safe preview that changes nothing) and into a temp
# dir (CLAUDE_GUIDE_DIR) so recording never touches your real setup. Drop the
# `--dry-run` to actually install.

Output media/demo.gif

Set Shell "bash"
Set FontSize 16
Set Width 1240
Set Height 860
Set Theme "Catppuccin Mocha"
Set Padding 26
Set TypingSpeed 45ms

Env CLAUDE_GUIDE_DIR "/tmp/ccg-demo"

Type "# The whole stack in one command (safe preview — drop --dry-run to install):"
Enter
Sleep 1500ms

Type "curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash -s -- --dry-run"
Enter
Sleep 9s
