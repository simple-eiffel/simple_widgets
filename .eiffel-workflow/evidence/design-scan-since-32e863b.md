# Design Scan (diff mode): simple_widgets since 32e863b
# Date: 2026-10-26
# Subjects: src/sw_window.e (set_title, 0.42.0), testing/sw_chrome_assault.e, testing/test_app.e
# Compared against: all of src/ (grep for set_title, set_caption, title)
# Read-only scan: no source file was modified, nothing was compiled.

## Summary

| Severity | Findings |
|----------|----------|
| HIGH | 0 |
| MEDIUM | 1 |
| LOW | 2 |

Nothing is HIGH. The new code is eleven lines, and no other class in src/ repeats it.

## Findings

### Finding 1: MEDIUM - the live path of set_title has no test
**Evidence:**
- src/sw_window.e:2968-2975: `set_title` replaces `title` (line 105), then calls `set_caption` (inherited from SHELL_WINDOW, simple_shell src/shell_window.e:210).
- testing/sw_chrome_assault.e (the added test, `test_set_title_renames_the_window`) creates a window with `make` and never runs it, so it checks only that `title` changed. Its own comment says so: "before the native window opens, only the title changes".
- The behavior the release exists for (the caption of an open window changes at once) is proven only by simple_shell's header comment and by simple_bible using it.
**Proposal:** a live check once a headless window is available: open the window on a short timer, call `set_title`, read back the native caption through `GetWindowTextW` (`hwnd` is exposed by SHELL_WINDOW), then close. Until then, leave a dated note in the test that the live path is verified by hand.
**Effort:** one test.

### Finding 2: LOW - set_title sits in its own clause after an empty clause
**Evidence:** src/sw_window.e:2964 `feature {NONE} -- Hint internals` is now followed immediately by line 2966 `feature -- Title`; the Hint internals clause holds no feature. `title` itself is declared at line 105 under `feature -- Access`.
**Proposal:** move `set_title` beside the other window-level commands, or at least delete the empty clause if it is a leftover. No behavior change.

### Finding 3: LOW - name drift between set_title and set_caption
**Evidence:** SW_WINDOW.set_title (line 2968), SHELL_WINDOW.set_caption (simple_shell src/shell_window.e:210), SHELL_PANEL.set_title (simple_shell src/shell_panel.e:304), SW_RATING.set_caption (src/sw_rating.e:64, an unrelated label caption). The same idea has two names across the two libraries, and `set_title` here wraps `set_caption` there.
**Proposal:** none needed now; the SW name matches `title` and SHELL_PANEL. Record the pairing in the CHANGELOG so a reader of one library finds the other. Do not rename.

## Duplication check
- grep of `set_title` and `set_caption` across src/: no other copy of "store the title, then change the native caption". (grep matched only sw_window.e:2972 and sw_rating.e:64.)
- The contract is weaker than SHELL_PANEL.set_title's (no precondition, one postcondition on `title`); that is correct because the caption change is a no-op before `shell_run`.

## Recommended Order
1. Finding 1 when a live window test exists.
2. Findings 2 and 3 only if the file is touched anyway.
