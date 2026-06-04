# VHS tape — records media/demo.gif of the setup.sh bootstrap.
# Render with:  vhs scripts/demo.tape   (install: brew install vhs)
# Docs: https://github.com/charmbracelet/vhs

Output media/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 760
Set Theme "Catppuccin Mocha"
Set Padding 24
Set TypingSpeed 60ms

Type "# One command. Fresh Mac → Claude Code + Ghostty, fully configured."
Enter
Sleep 1500ms

Type "./setup.sh --dry-run"
Enter
Sleep 5s

Type "# --check validates an existing environment anytime"
Enter
Sleep 1200ms

Type "./setup.sh --check"
Enter
Sleep 3s
