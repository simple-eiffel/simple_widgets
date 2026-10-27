# Design Scan (diff mode): simple_widgets since 76b8f12
# Subjects: src/sw_cluster_math.e, src/sw_interlinear.e
# Compared against: all of src/. Read-only; nothing compiled.

## Summary

| Priority | Count |
|----------|-------|
| HIGH     | 1 (D1 drift) |
| MEDIUM   | 2 |
| LOW      | 2 |
| **Total**| **5** |

The raw-position crash question has a clean answer: zero HIGH findings from it. See "Answer 2" below.

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | SW_INTERLINEAR, SW_STACKED_ITEMS | wipe_out clears pending_scroll_token but not the inherited pending_scroll_item, so a stale scroll request survives a refill |
| 2 | MEDIUM | D1/A5 | SW_INTERLINEAR, SW_STACKED_ITEMS | scroll_to_token clears its own pending after an immediate scroll, while the ancestor request stays armed and re-scrolls at the next measure |
| 3 | MEDIUM | A5/A6 | SW_INTERLINEAR, SW_STACKED_ITEMS | Two pending-scroll mechanisms in series; fold the token-to-row resolution into the ancestor |
| 4 | LOW | A4 | SW_CLUSTER_MATH, SW_CHAT_THREAD | The within-run law is ensured only on cluster_x, not on its callers |
| 5 | LOW | design note | SW_CLUSTER_MATH | The clamp hides a left-of-origin mark's true position from every caller |

## Detailed Findings

### Finding 1: Stale scroll request survives wipe_out (drift between the two pending mechanisms)
**Priority:** HIGH (D1)
**Classes:** src/sw_interlinear.e, src/sw_stacked_items.e
**Description:** The two classes each remember a scroll request, and they reset differently. SW_INTERLINEAR.wipe_out (src/sw_interlinear.e:127-139) clears `pending_scroll_token` (line 133) and resets `scroll_y := 0.0` (line 134), but never clears the inherited `pending_scroll_item`. SW_STACKED_ITEMS.scroll_item_into_view sets `pending_scroll_item` unconditionally (src/sw_stacked_items.e:168), including after an immediate scroll. Sequence: the view is laid out, the host calls scroll_to_token (src/sw_interlinear.e:238-239, which calls scroll_item_into_view and so sets pending_scroll_item), then the host calls wipe_out and refills with a new chapter. At the next measure_stack, `pending_scroll_item > stack.count` is false when the new chapter has enough rows, so src/sw_stacked_items.e:255 scrolls to the OLD row, overriding the intended top-of-chapter reset. The comment at src/sw_stacked_items.e:164-165 says the request survives a refill on purpose, which is right for a request made after the refill and wrong for one made before wipe_out.
The other clients of the ancestor (src/sw_document_view.e:150, src/sw_paragraph_list.e:830, src/sw_parallel_text.e:304) have no wipe-time reset of pending_scroll_item either (grep: the name occurs only in src/sw_stacked_items.e), so the same stale-request path exists there.
**Evidence:**
- src/sw_interlinear.e:133 `pending_scroll_token := 0` (the only reset)
- src/sw_stacked_items.e:168 `pending_scroll_item := a_i` (always set)
- src/sw_stacked_items.e:251-256 meets or drops it only at measure_stack
**Copy that should win:** SW_INTERLINEAR's behavior (a wipe forgets the request). Proposal: SW_STACKED_ITEMS gains a `forget_pending_scroll`; wipe-like commands call it, and SW_INTERLINEAR.wipe_out calls it.
**Effort:** 1 feature in SW_STACKED_ITEMS, 1 call per wiping client.

### Finding 2: Immediate scroll leaves the ancestor request armed
**Priority:** MEDIUM (D1)
**Classes:** src/sw_interlinear.e:232-244, src/sw_stacked_items.e:157-171, 251-257
**Description:** In scroll_to_token, the already-laid-out branch scrolls and then sets `pending_scroll_token := 0` (src/sw_interlinear.e:240), meaning "done". But the call to scroll_item_into_view on line 239 has just set `pending_scroll_item := row` (src/sw_stacked_items.e:168), and it is cleared only at the next measure_stack when `height > 0.0` (line 254). If the user wheels or drags the bar between the call and the next measure, the view snaps back once. The Interlinear copy believes the request is met; the ancestor copy does not. The same shape applies to every other client of scroll_item_into_view.
**Evidence:** src/sw_interlinear.e:239-240; src/sw_stacked_items.e:158-171, 254-256.
**Suggested Action:** in scroll_item_into_view, set the pending request only when the immediate scroll did not happen (else clear it); the `remembered` postcondition at line 170 would become conditional.
**Effort:** 1 feature.

### Finding 3: Two pending-scroll mechanisms in series
**Priority:** MEDIUM (A5/A6)
**Classes:** SW_INTERLINEAR, SW_STACKED_ITEMS
**Description:** 0.45.0 added `pending_scroll_token` (src/sw_interlinear.e:246) beside the inherited `pending_scroll_item` (src/sw_stacked_items.e:173). They are not a pure duplicate: a token cannot become a row index before layout, since token_rows is filled by flow (src/sw_interlinear.e:501-523), so a token-level memory is genuinely needed. But the same protocol (remember, resolve at measure, drop when the count no longer reaches it) is written twice with two drop tests (src/sw_interlinear.e:435 and src/sw_stacked_items.e:251) and two reset rules (Finding 1). A single ancestor-owned request with a deferred resolver (for example `stacked_item_for_request (a_request): INTEGER`, 0 when unresolvable) would give one remember, meet, drop law, with SW_INTERLINEAR supplying only token-to-row. This belongs in SW_STACKED_ITEMS.
**Evidence:** src/sw_interlinear.e:232-246, 433-441; src/sw_stacked_items.e:157-173, 251-257.
**Effort:** about 3 features moved up. Do Findings 1 and 2 first (they are the drift); extraction only on Larry's word.

### Finding 4: The within-run law is stated only on cluster_x
**Priority:** LOW
**Classes:** src/sw_cluster_math.e, src/sw_chat_thread.e
**Description:** cluster_x now ensures `within_run` (src/sw_cluster_math.e:92), but char_left_x and char_right_x ensure only `non_negative` (around lines 41-42 and 63-64), and SW_CHAT_THREAD.run_boundary_x (src/sw_chat_thread.e:1838-1857) ensures only non_negative. Adding `Result <= a_run.advance_width` to those three would make the new law checkable at every consumer (src/sw_shaped_text.e:171-172, src/sw_text_geometry.e:756-757, src/sw_chat_thread.e:1821 and 1915-1916). Not a defect today: the IMAGE_RUN branch answers 0 or the whole advance, and the GLYPH_RUN branch goes through cluster_x.
**Effort:** 3 postcondition clauses.

### Finding 5: The clamp loses the true mark position
**Priority:** LOW (design note)
**Classes:** src/sw_cluster_math.e:85-89
**Description:** A cluster whose first glyph is a mark left of the origin now reports 0.0 as its left edge, and a mark past the end reports advance_width. Caret and selection edges for that character are therefore the base letter's edge, which is the right visual answer. Recorded only so a future painter that needs the raw offset does not look here for it.

## Answer 1: Does pending_scroll_token duplicate pending_scroll_item, and do they drift?
Partly a duplicate (Finding 3), and they do drift: the reset on wipe_out (Finding 1, HIGH) and the clearing after an immediate scroll (Finding 2). The drop-when-rows-vanish rule exists in both (src/sw_interlinear.e:435-436, src/sw_stacked_items.e:251-253), each in its own units (token rows versus stack items), so that particular rule does not drift.

## Answer 2: Other code reading GLYPH_RUN x_positions or x_offsets raw?
None. `grep -rn "x_positions\|x_offsets" src` finds executable reads only at src/sw_cluster_math.e:87-88 (the clamped one). Other hits are comments (src/sw_chat_thread.e:73 and 1790; src/sw_cluster_math.e:18; src/sw_shaped_text.e:144). `cluster_map` has no executable use outside src/sw_cluster_math.e. Every consumer goes through char_left_x, char_right_x or cluster_x:
- src/sw_shaped_text.e:171-172
- src/sw_text_geometry.e:756-757
- src/sw_chat_thread.e:1821 (run_boundary_x, which calls cluster_x at 1849 and 1851) and 1915-1916
No file in src/ paints glyphs from raw positions (src/sw_painter.e and src/sw_doc_units.e use only advance_width, for example src/sw_doc_units.e:672-683). So there are no HIGH crash-risk findings. Residual risk outside this scan: code in simple_shaping or client applications that reads GLYPH_RUN.x_positions directly.

## Recommended Order
1. Finding 1 (stale request after wipe_out)
2. Finding 2 (armed request after immediate scroll)
3. Finding 3 (one ancestor mechanism), only on Larry's word
4. Findings 4 and 5 as opportunistic cleanup
