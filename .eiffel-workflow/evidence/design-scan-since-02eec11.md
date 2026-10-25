# Design Scan (diff mode): simple_widgets, since 02eec11
# Head: c16649e (GW-14a, 0.32.0). Read-only; nothing compiled or run.
# Subjects: src/sw_theme.e, src/sw_skeleton.e, src/sw_progress.e, src/sw_window.e, testing/sw_reduced_motion_assault.e, testing/sw_test_appearance.e, testing/test_app.e

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Correctness / drift (1, 2, 3, 6, 9) | 5 | 1 | 3 | 1 |
| Unhonored motion (4, 5) | 2 | 0 | 2 | 0 |
| Abstraction / cleanup (8, 10, 11) | 3 | 0 | 0 | 3 |
| Tests (7) | 1 | 0 | 1 | 0 |
| **Total** | **11** | **1** | **6** | **4** |

## Findings

| # | Priority | Topic |
|---|----------|-------|
| 1 | HIGH | Event 57 updates only the worn theme; the other member of the pair stays stale and is worn by the next light/dark flip (event 53) |
| 2 | MEDIUM | The window overwrites the application's own `reduces_motion` choice on both application-owned themes |
| 3 | MEDIUM | Application-owned themes are mutated in place; a theme shared with another window changes under it |
| 4 | MEDIUM | SW_DIAGRAM runs `relax_step` on every draw and ignores `reduces_motion` |
| 5 | MEDIUM | A window using `set_theme` (not following Windows) never learns the animation setting; motion is a separate axis from theme |
| 6 | MEDIUM | Windows setting read up to three times in one routine, against the library's own "read once" rule |
| 7 | MEDIUM | Tests do not cover the pair staleness, the 53 path, an application preference, or the observer |
| 8 | LOW | Three different "re-read Windows and apply" recipes (53, 56, 57) |
| 9 | LOW | Event 57 does not call `on_theme_changed` |
| 10 | LOW | `t.reduces_motion` tested four times in SW_SKELETON.draw; the heartbeat repaints unconditionally even when nothing can move |
| 11 | LOW | Frame-comparison helper lives only in the new assault class |

## Detailed Findings

### Finding 1: Stale partner theme after event 57 (D1, drift between copies)
**Priority:** HIGH
**Category:** correctness, drift against the GW-16 and GW-27 paths
**Where:** src/sw_window.e:629-632 (event 57 handler), :615-623 (event 53 handler; line 621 is `wear_system_theme (a_x = 1)`), :755-762 (the only place both members get the flag).
**Description:** `wear_system_appearance` sets the flag on BOTH followed themes (:756-761). The event 57 handler sets it only on `theme`, the worn one (:631). The event 53 handler (light/dark flip, no contrast) calls `wear_system_theme` directly (:621), which wears the chosen member without touching its flag.
**Failure scenario:** Windows animations are off at start, so both light and dark carry true. The user turns Animation effects ON: event 57 clears the flag on the worn light theme only; the dark theme still says true. The user then flips Windows to dark: event 53 wears the dark theme, which holds still although animations are on, and `on_theme_changed` is told that theme. The reverse order (animations turned off while light is worn, then a flip to dark) leaves the newly worn dark theme moving although the user asked for stillness: an accessibility failure, not only a cosmetic one. While a contrast theme is worn the hole is closed, because contrast changes re-wear through `wear_system_appearance`.
**Suggested fix:** One routine `apply_motion_preference` (reads `system_reduces_motion` once into a local, sets it on light, dark and the worn theme), called from the 57 handler and at the top of `wear_system_theme`; or route 53 and 57 through `wear_system_appearance` like 56. Add the regression test of Finding 7.
**Effort:** one routine, two call sites.

### Finding 2: Application preference overwritten
**Priority:** MEDIUM
**Where:** src/sw_window.e:750, 757-761; sw_theme.e:338-340 (documents the flag as "Set by the application, or live by a window following Windows").
**Description:** Following Windows copies the Windows value over the application's, in both directions. An application that set its own themes to reduce motion (a "calm mode" of its own) loses that as soon as `follow_system_theme` runs while Windows animations are on.
**Failure scenario:** The application sets `reduces_motion` true on both themes and calls `follow_system_theme`; Windows animations are on; both themes now animate.
**Suggested fix:** Keep two facts, the application's preference and the system's, and let the effective value be their OR. For example the window holds `system_motion_reduced`, the theme keeps the application's flag, and the painter answers one query (`holds_still`) that every animated widget and every application animation asks.

### Finding 3: Mutating objects the application owns
**Priority:** MEDIUM
**Where:** src/sw_window.e:757-761, 631.
**Description:** `system_light` and `system_dark` are the caller's objects (`follow_system_theme (a_light, a_dark)`, :354-365). The window writes into them. Side effects: (a) a second window using the same theme object, following or not, changes motion with no render request, so it repaints only at its next heartbeat; (b) after `set_theme` stops following (:189-202) the flag stays at whatever Windows said last, which nobody chose; (c) two windows with different `system_appearance` sources fight over one object (tests, or an application driving two sources).
**Suggested fix:** As Finding 2: keep the system value on the window or painter and leave application themes alone. If mutation stays, say so in the `follow_system_theme` header comment, which today understates that the unworn partner is written too.

### Finding 4: SW_DIAGRAM ignores reduces_motion
**Priority:** MEDIUM
**Category:** unhonored motion
**Where:** src/sw_diagram.e:223 (`relax_step` inside `draw`), :144 (physics), class note :5 ("one relax per heartbeat").
**Description:** Every repaint relaxes the force layout one step, so nodes drift on the heartbeat clock until settled, and a drag or a new node restarts it. Nothing consults the theme.
**Failure scenario:** A user with animations off opens a diagram; nodes slide for several seconds.
**Suggested fix:** When the theme reduces motion, run `relax_step` in a bounded loop before the first draw (and after a drag or an added node), then draw without stepping.

### Finding 5: Not following the theme means not following the motion setting
**Priority:** MEDIUM
**Where:** src/sw_window.e:629 (`and then is_following_system_theme`), :189-202.
**Description:** The animation preference is independent of light and dark. An application with its own branded theme (the common case) gets the shimmer and the marquee regardless of Windows. Nothing reads the setting at window construction either, only inside `follow_system_theme`.
**Suggested fix:** A separate `follow_system_motion` switch (default on), handled in the 57 branch and at construction, setting the system value held on the window (Finding 2).

### Finding 6: Several reads against the "read ONCE" rule
**Priority:** MEDIUM
**Where:** src/sw_window.e:757 and 760 (one `system_reduces_motion` call per member), plus :631 and :750.
**Description:** The comment at :742-746 cites scan 10: a second read could see a flip and promise one answer while wearing another. The new code reads the setting up to three times in one pass, and the SW_TEST_APPEARANCE double has no `flips_on_read` equivalent for motion, so the rule cannot be tested for it.
**Suggested fix:** `l_motion := system_appearance.system_reduces_motion` once at the top of `wear_system_appearance`.

### Finding 7: Tests do not reach the failures
**Priority:** MEDIUM
**Category:** tests
**Where:** testing/sw_reduced_motion_assault.e:50-72 (window follows) and :14-48 (frames).
**Description:** `test_gw14_window_follows_the_animation_setting` checks `w.theme` after each event but never flips light/dark after a 57, so Finding 1 passes. Missing: the 53 path; an application-set flag surviving (Finding 2); two windows sharing a theme (Finding 3); `on_theme_changed` seeing the flag; SW_DIAGRAM.
**Suggested tests:** (1) follow with fake motion true, dispatch 57 with false, set the fake dark, dispatch 53, assert `w.theme.reduces_motion` is false. (2) The same with `on_theme_changed` recording the flag. (3) Two windows, one theme object. (4) Application sets true, Windows says false, assert the effective value is still still (after Finding 2 is decided).
**Robustness of what exists:** the frame test's positive control (the first assertion, shimmer moves) is the right design: without it the held-still case would pass on a blank frame. `widget_image` draws the live widget and so advances its phase as a side effect of exporting; the helper relies on that, and if exports ever stop drawing the live widget the positive control fails loudly, which is correct. `same_frames` compares size, stride and bytes after `flush`, fine. Surfaces are not destroyed if an earlier assertion aborts the test (minor).

### Finding 8: Three recipes for one job
**Priority:** LOW
**Category:** A5
**Where:** src/sw_window.e:615-623 (53 reads contrast and then picks), :624-628 (56 calls `wear_system_appearance`), :629-632 (57 sets one flag).
**Description:** GW-16 made `wear_system_appearance` the single door that reads Windows and wears the result. 53 half-bypasses it and 57 bypasses it entirely; Finding 1 is the consequence. Prefer one `apply_system_appearance` that reads dark, contrast and motion once, with all three events calling it.

### Finding 9: Event 57 is silent to `on_theme_changed`
**Priority:** LOW
**Where:** src/sw_window.e:629-632; contract text at :401-402 ("Told the new theme whenever following Windows swaps it").
**Description:** Applications that mirror the theme (caches, their own animated widgets) are told on 53 and 56 but not on 57, though the theme they were handed changed state. Decide whether a flag change counts, and document it either way. Ordering inside `wear_system_appearance` is right: the flag is set before `on_theme_changed` runs on both the contrast branch (:750-751) and the pair branch (:755-762), so the observer sees it, except on the 53 path (Finding 1).

### Finding 10: Cleanup in SW_SKELETON and the clock
**Priority:** LOW
**Where:** src/sw_skeleton.e:92, 98, 107, 127 (four tests of `t.reduces_motion`; one local removes the repetition); src/sw_window.e:2672-2676 (`age_toasts`: "the repaint is unconditional - the toolkit's ambient animation clock").
**Description:** With reduced motion and nothing moving, the heartbeat still repaints every 250 ms. A power cost, not a bug; after Findings 4 and 5 only a few widgets animate and the repaint could be skipped when none is on screen or all are held still.

### Finding 11: Helper candidates
**Priority:** LOW
**Where:** testing/sw_reduced_motion_assault.e:92-113 (`frames_differ`, `same_frames`).
**Description:** Offscreen frame comparison will be wanted by any later "moves or holds still" test; candidate home is SW_SHAPING_ASSAULT or a small test mixin inherited side by side. Note also that `adopt_metrics_from` now copies `reduces_motion` as a metric (sw_theme.e:473); that is deliberate, and it also makes the light export theme (sw_window.e:301-302) hold still for a reduced-motion user, a useful side effect worth a comment.

## Motion inventory (search of src/)
- Honors `reduces_motion`: SW_SKELETON (phase and shimmer), SW_PROGRESS indeterminate band (:84-95).
- Moves and does NOT honor it: SW_DIAGRAM relax per draw (Finding 4).
- Searched, no motion found: caret blinking (no blink state anywhere in src), carousel (paging by click only), toasts (they expire by count, no fade; sw_window.e:2672-2692), smooth scrolling (no easing or target-seeking offsets), hover card (appears and closes, no transition), dwell (a timer, not drawn motion), spinners and typing dots (none exist; chat thread streaming only appends text).
- Heartbeat consumers: `on_tick` is an application callback (sw_window.e:593); applications that animate their own widgets need a single `holds_still` query (Finding 2).

## Recommended Order
1. Finding 1 (live accessibility defect, small fix) with the first test of Finding 7
2. Findings 6 and 8 (same routine)
3. Findings 2, 3, 5 together (decide where the system value lives)
4. Finding 4
5. Findings 9, 10, 11
