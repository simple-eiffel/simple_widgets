# Design Scan (diff mode): simple_widgets, since 7b79425
# Date: 2026-10-26
# Subjects: src/sw_stacked_items.e (pending_scroll_item, 0.41.1); testing/sw_parallel_assault.e and testing/test_app.e also changed
# Compared against: the whole of src/ (descendants sw_paragraph_list, sw_doc_units, sw_document_view, sw_interlinear, sw_parallel_text; and sw_list)

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction | 3 | 0 | 1 | 2 |
| MI | 0 | 0 | 0 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **3** | **0** | **1** | **2** |

Nothing is HIGH. The new code is not a copy of anything: it lives in the shared ancestor, which is where the fix belongs.

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | MEDIUM | A4 | SW_STACKED_ITEMS | The pending request is never cancelled and its contract is loose |
| 2 | LOW | A1/A4 | SW_PARALLEL_TEXT, SW_PARAGRAPH_LIST, SW_DOCUMENT_VIEW, SW_INTERLINEAR | Four delegations to scroll_item_into_view, only one with a postcondition |
| 3 | LOW | A5 | SW_LIST, SW_STACKED_ITEMS | A second "bring row into view" outside the shared ancestor |

## Detailed Findings

### Finding 1: Pending scroll is never cancelled
**Priority:** MEDIUM. **Category:** A4 (contract gap) with a latent defect.
**Evidence:**
- sw_stacked_items.e:156-170: `scroll_item_into_view` scrolls at once when laid out and then ALWAYS sets `pending_scroll_item := a_i`, even when the immediate scroll just succeeded. The postcondition `remembered` only states the attribute was set.
- sw_stacked_items.e:250-253: `measure_stack` meets the request only when it is within `stack.count` and `height > 0.0`; otherwise it is kept. A request past the end of a refilled, shorter list stays set and fires later when rows grow, moving the view with no new request.
- sw_parallel_text.e:251-259 `wipe_out` resets `scroll_y := 0.0` but does not touch the pending item. A search of src/ for `pending_scroll` finds it only in sw_stacked_items.e, so no descendant resets it.
- The invariant (line 289) says nothing about the pending item.
**Proposal:** (a) in `scroll_item_into_view`, set the pending item only when the immediate scroll was not possible (not laid out, zero height, or item past `stack.count`); (b) add the invariant `pending_not_negative: pending_scroll_item >= 0` and a postcondition saying that when the scroll could be done at once the pending item is 0; (c) add a `cancel_pending_scroll` that the wheel and thumb-drag paths of SW_VSCROLLING call, so a stale request never overrides the reader. Effort: 1 feature changed, 1 invariant, 1 optional command.
**Test idea (not HIGH, for the record):** fill 60 rows, `scroll_to_row (40)`, render; wipe to 10 rows and render; refill to 60 and render. Assert `scroll_y = 0.0` (a stale request of 40 left over would move it).

### Finding 2: Delegations with uneven contracts
**Priority:** LOW. **Category:** A1 / A4.
**Evidence:** sw_parallel_text.e:288-294 `scroll_to_row`, sw_paragraph_list.e:825-834 `scroll_to_item`, sw_document_view.e:145-151 `scroll_to_block`, and the direct call at sw_interlinear.e:237. Each delegates to `scroll_item_into_view`. Only sw_paragraph_list.e:832-833 states `visible_once_laid_out`; the others carry no such postcondition, so the guarantee depends on the name a client calls. The names differ (row, item, block) because each speaks its own domain; keep them.
**Proposal:** move the `visible_once_laid_out` postcondition into `scroll_item_into_view`, so every wrapper inherits it.

### Finding 3: SW_LIST has its own scroll-into-view
**Priority:** LOW. **Category:** A5.
**Evidence:** sw_list.e:263-281 `scroll_to_row` implements the same law (move the least amount that shows the row) with fixed `row_height` arithmetic, a different before-layout rule ("top the list at that row", lines 268-270), no pinned band, and no request kept for the next layout. SW_LIST has fixed-height rows so it cannot inherit SW_STACKED_ITEMS, but a refilled SW_LIST that asks for a row before layout does not get the 0.41.1 "wait for new rows" behavior.
**Proposal:** only if a client reports the refill case for SW_LIST. The shared piece would be a small deferred scroll-request mixin (pending item plus a `meet_pending` feature) that SW_STACKED_ITEMS and SW_LIST inherit side by side. Not worth doing now.

## Test coverage note
testing/sw_parallel_assault.e:199-222 `test_gw06_scroll_to_row_waits_for_new_rows` covers the refill path for SW_PARALLEL_TEXT only. No test covers the stale or out-of-range request of Finding 1, nor the other three descendants.

## Recommended Order
1. Finding 1 (tighten the new feature before more clients rely on it).
2. Finding 2 (one contract moved).
3. Finding 3 only on demand.
