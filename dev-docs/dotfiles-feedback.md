# Feedback from dotfiles utilities

Issues and improvement candidates discovered while building bash utilities
in the [dotfiles](https://github.com/uhop/dotfiles) project.

---

## `ansi::err` returns 1 — footgun with `set -e`

`ansi::err()` in `ansi-utils.sh` always returns 1. All dotfiles utilities
use `set -euCo pipefail`, so any `ansi::err` call that isn't the last
statement before `exit` kills the script unexpectedly.

**Symptom:** Multi-line error messages (several `ansi::err` calls before
`exit 1`) only print the first line — the second call triggers `set -e`.

**Workaround:** `ansi::err "message" || true` or group with
`{ ...; } || true`.

**Possible fixes:**
- Add `ansi::warn` (or similar) that prints to stderr but returns 0.
  Reserve `ansi::err` for the "print and signal failure" use case.
- Add an option/flag to suppress the return code.
- Change `ansi::err` to return 0 by default (breaking change — would need
  to audit callers that rely on the return 1 behavior).

**Note:** `ansi::err` accepts multiline strings, which reduces multi-call
sequences to one call. But the `|| true` is still needed if there's code
after the call.

---

## `args::parse` corrupts positional arguments containing spaces

In `args.sh`, `args::parse` escapes non-flag positional arguments with
`printf '%q'` before passing to `getopt` (lines 160-167). The output is
then processed with `eval set -- "$parsed"` (line 183). The round-trip
doesn't work for strings with spaces:

1. `printf '%q' "echo hello"` → `echo\ hello`
2. `getopt` wraps it in single quotes: `'echo\ hello'`
3. `eval set --` processes the single quotes, but single quotes don't
   interpret backslash escapes, so the result is literally `echo\ hello`

**Minimal repro:**

```bash
source bootstrap.sh
args::program "test" "1.0" "test"
args::option "-h, --help" "help"
args::parse "echo hello from periodic"
echo "${args_cleaned[0]}"
# Expected: echo hello from periodic
# Actual:   echo\ hello\ from\ periodic
```

**Workaround:** `"${2//\\ / }"` to strip `\ ` → ` ` in the caller.

**Possible fix:** In `args::parse`, don't `printf '%q'` the positional
arguments before `getopt`. The escaping was likely added to protect
arguments from `eval set --`, but `getopt` already single-quotes them in
its output, so the extra escaping creates a double-quoting problem.
