# Bootstrap file for options.bash utilities.
#
# Save as ~/.local/libs/bootstrap.sh and source from your scripts:
#   . ~/.local/libs/bootstrap.sh
#
# Auto-updates the library on each invocation (requires git).
# Sources core modules so scripts start with full functionality.

# auto-update
command -v git &> /dev/null && git -C ~/.local/share/libs/scripts pull > /dev/null || true

# core modules
. ~/.local/share/libs/scripts/ansi.sh
. ~/.local/share/libs/scripts/args.sh
. ~/.local/share/libs/scripts/args-version.sh
. ~/.local/share/libs/scripts/args-help.sh
. ~/.local/share/libs/scripts/args-completion.sh

# echo the first argument and run
echoRun() {
  ansi::out "${CYAN}$@${RESET_ALL}"
  eval "$@"
}

echoRunBold() {
  ansi::out "${BOLD}${CYAN}$@${RESET_ALL}"
  eval "$@"
}
