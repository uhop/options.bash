# Feedback from dotfiles utilities

Issues and improvement candidates discovered while building bash utilities
in the [dotfiles](https://github.com/uhop/dotfiles) project.

---

## ~~`ansi::err` returns 1 — footgun with `set -e`~~ FIXED

Added `ansi::warn`, `string::warn`, and `box::warn` — identical to their
`::err` counterparts but return 0. Use `::warn` when you need to print to
stderr without triggering `set -e`. `::err` is unchanged (still returns 1)
for callers that rely on that behavior.

---

## ~~`args::parse` corrupts positional arguments containing spaces~~ FIXED

Removed the `printf '%q'` escaping of non-option arguments before `getopt`.
The escaping caused double-quoting: `printf '%q'` added backslashes, then
`getopt` wrapped the result in single quotes (which don't interpret
backslashes), producing `echo\ hello` instead of `echo hello`.

`getopt` already single-quotes its output correctly, so the extra escaping
was unnecessary. Test added: `tests/test-args.sh` "parse: positional arg
with spaces".

---

## ~~`args_program_footer` suppresses `args_program_url`~~ FIXED

Changed the `if footer … elif url` logic in `args-help.sh` to two
independent `if` blocks. When both `args_program_footer` and
`args_program_url` are set, the help screen now shows the footer first,
then the URL line. Test added: `tests/test-args-help.sh`.
