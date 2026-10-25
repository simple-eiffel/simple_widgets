# Design Scan (diff mode): simple_widgets, since 086d3e8 (main 1c0abdc)

Subjects: src/sw_diagram.e (GW-23 layered layout, about 375 added lines); testing/sw_layered_diagram_assault.e.
Compared against: all of src/ (SW_ORG_CHART, SW_LANE_TIMELINE, SW_TREE, SW_GANTT, SW_MEDIA_TRANSPORT, SW_THEME) and the Sugiyama layered-drawing procedure.
Read-only scan: nothing compiled, nothing run. Line numbers are from src/sw_diagram.e at 1c0abdc unless stated.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Correctness | 11 | 2 | 5 | 4 |
| Abstraction / duplication | 2 | 0 | 2 | 0 |
| Tokens | 2 | 0 | 1 | 1 |
| Tests | 2 | 1 | 0 | 1 |
| Accessibility | 1 | 0 | 0 | 1 |
| **Total** | **18** | **3** | **8** | **7** |

Findings 1 to 18 below; the first three are HIGH.

Termination answer (asked explicitly): assign_layers (lines 521-546) cannot loop forever in normal use. connect forbids self-loops by contract (line 120) and break_cycles reverses every back edge, so relaxation runs on an acyclic graph. It makes at most (longest path length + 1) passes, so at most V passes, each O(E) with constant-time list access: O(V*E) worst case, reached when the edge list is in reverse topological order. It is paid only on a cache miss. Caveat: the guarantee rests on the connect contract; the class invariant (lines 736-739) does not forbid a self-loop, so edges written directly by a descendant could hang the draw loop (a self-loop is reversed, then head equals tail and the relaxation condition holds forever).

## Findings

| # | Sev | Category | Where | Finding |
|---|-----|----------|-------|---------|
| 1 | HIGH | correctness | 579-634, 681-715 | Edges that skip layers are ignored by ordering and drawn straight through intermediate nodes (no dummy nodes) |
| 2 | HIGH | tests | testing/sw_layered_diagram_assault.e, test_gw23_the_same_graph_lays_out_the_same | The determinism test compares two fresh diagrams; it proves neither the cache nor stability under re-render |
| 3 | HIGH | correctness | 414-434 | crossing_count counts only adjacent-layer pairs, so it can report 0 while long edges cross |
| 4 | MEDIUM | correctness | 414-434, 462-476 | crossing_count raises a precondition violation after connect and before the next render |
| 5 | MEDIUM | correctness | 681-715 | Reversed edges are drawn from the original tail's label end backwards across every layer between |
| 6 | MEDIUM | correctness | 437-455 | The layered_key cache misses label, endpoint, theme, font and shaping changes, and its arithmetic collides |
| 7 | MEDIUM | correctness | 636-679 | Horizontal overflow: layer positions ignore the widget width; no scroll, shrink or clip |
| 8 | MEDIUM | correctness | 667-679, 338 | Vertical overflow gives negative py; the title collides with the top row |
| 9 | MEDIUM | correctness | 548-577 | Four fixed barycenter sweeps, no best-so-far keep, no transpose |
| 10 | MEDIUM | abstraction | whole of sw_diagram.e (741 lines) | The layered algorithm is a pure graph computation inside a painting widget; extract a headless helper |
| 11 | MEDIUM | abstraction | 521-546 vs sw_org_chart.e 57, sw_lane_timeline.e 450-516 | Layering and row-stacking logic is re-implemented per class |
| 12 | MEDIUM | tokens | 307, 647, 690; sw_gantt.e 167; sw_media_transport.e 173; sw_org_chart.e 251 | Font size 11.5 hard-coded in six places; SW_THEME has no matching token |
| 13 | LOW | correctness | 521-546 | Longest-path layering pins every source to layer 1 and stretches its edges |
| 14 | LOW | correctness | 500-519 | visit recurses once per node on a chain and rescans all edges per call |
| 15 | LOW | correctness | 579-634 | Disconnected components share layer 1; a neighbor-less node's barycenter is wrong on the first sweep |
| 16 | LOW | correctness | 500-519, 681-715 | Duplicate and antiparallel edges draw on top of each other |
| 17 | LOW | tokens | 662-674, 692-715 | Layout literals 56.0, 8.0, 24.0, 1.6, 14.0, 20.0 and arrowhead sizes are local and must agree with each other |
| 18 | LOW | tests / accessibility | testing file; 281-345, 349-360 | Missing tests (long edge, relabel, overflow, repeat render); no keyboard or text path in layered mode |

## Detailed findings

### 1. HIGH: long edges bypass ordering and are drawn through nodes
Where: sort_layer (579-634), place_layers (636-679), draw_layered_edge (681-715).
Evidence: sort_layer gathers only neighbors in layer a_layer - 1 or a_layer + 1 (lines 596-603). place_layers gives every node of one layer one x (line 673). draw_layered_edge draws a single straight segment from the tail's label end to the head's ring (lines 694-706).
Failure scenario: edges 1->2, 2->3, 3->4 and 1->4. Node 4 sits in layer 4, node 1 in layer 1; the straight segment crosses the x range of layers 2 and 3. A layer holding one node is centered at height/2, exactly where a straight segment between two centered nodes runs, so the edge is drawn through the label of node 2 or 3. Sugiyama inserts a dummy node in each skipped layer so the edge becomes a chain of adjacent-layer segments that takes part in ordering and gets drawn as a bend. Here node 4 has no predecessor in layer 3, so its barycenter is undefined and it keeps its old slot (see 15).
Suggested fix: in the helper from finding 10, replace each edge spanning more than one layer with a chain of dummy slots (integer arrays only), order and count over the chained edges, and draw polylines through the dummy positions. Stopgap: route long edges above or below the layer stack and document it in the class note.

### 2. HIGH: the "same pixels" test does not prove what it names
Where: testing/sw_layered_diagram_assault.e, test_gw23_the_same_graph_lays_out_the_same.
Evidence: window_with renders each diagram once. The test then calls w1.request_render again and only afterwards compares d1 with d2. Both ran the same code from the same input, so equality shows two fresh runs agree. It never compares d1 against its own positions before the second render, never shows the cache hit skipped work, and never shows a forced relayout reproduces the old positions. The name says pixels but only node px and py are compared; edge geometry and arrowheads are not.
Failure scenario: a bug where order_of leftovers leak between layouts (order_layers wipes it at line 555, but sort_layer reads order_of at line 612) would pass here and fail in the field when a diagram is relaid out after a resize.
Suggested fix: snapshot positions after render one, force a relayout (resize and resize back, or set_layered False then True), render again, compare with the snapshot. Add a layout_pass_count query and assert it stays at 1 over a plain second render and rises to 2 after a size change. For the pixel claim, compare write_frame output of two fresh windows.

### 3. HIGH: crossing_count can report 0 while edges cross
Where: crossing_count (414-434).
Evidence: the condition at lines 424-426 requires both edges to span exactly layer k to layer k + 1. Edges spanning two or more layers are skipped.
Failure scenario: the public name and the evidence test's `crossing_count = 0` assertion read as "clean drawing". For the current fixture that is true (no edge skips a layer), but any outline with a long edge that crosses a short one still reports 0, and the same query would be the quality gate for findings 1 and 9.
Suggested fix: rename to adjacent_crossing_count and document it, or compute over the dummy chains from finding 1 so the number matches the drawing. Add a second query counting edges drawn through nodes and assert it is 0 in the evidence test. Cost note: the body is O(E squared), which is fine for a test query but too slow to drive the sweeps; use a linear accumulator there.

### 4. MEDIUM: stale-query precondition violation
Where: line 420 guards only layer_of.count and order_of.count against nodes.count; tail and head (462-476) read is_reversed.i_th.
Failure scenario: lay out, call connect (edges.count grows, is_reversed does not), then call crossing_count or tail without rendering: is_reversed.i_th gets an out-of-range index and the public query dies with a precondition violation. After add_node the guard returns 0 silently, a stale answer rather than a crash.
Suggested fix: add is_reversed.count = edges.count to the guard (draw_layered_edge already does this at line 700) or add a layout_is_current query used in guards and as a precondition on the queries.

### 5. MEDIUM: reversed edges are drawn backwards across the layout
Where: draw_layered_edge, lines 690-703.
Evidence: ax and ay use edges.i_th (a_edge).a, the original tail, whatever the reversal. For a reversed edge the original tail sits in a later layer than the original head, so the segment starts at the right end of the later label and runs left across every layer between, through intermediate nodes. Clause outlines with a refrain or chiasm will contain such edges.
Suggested fix: route back edges through the same dummy chain as finding 1, or as a dashed arc below the layers; keep the arrowhead at the written head.

### 6. MEDIUM: layered_key cache misses real changes
Where: lay_out_layers, lines 437-455.
Evidence: key = nodes.count * 100003 + edges.count * 31 + width * 7 + height (line 444). set_layered resets it (line 378), so a toggle is handled, and add_node or connect changes a count. Missed: a relabel (the label is stored in the node tuple; the layer width at line 664 changes but the key does not), edge endpoints changed with the count kept, a theme or font change, and attaching a shaping kit after first render (the same label measures wider). The sum also collides: (width + 1, height - 7) gives one key, and 3226 edges alias one node.
Failure scenario: Greek labels laid out before shaping is attached keep the narrow spacing and run into the next layer after shaping widens them.
Suggested fix: an explicit layout_stale flag set by every mutator plus a painter font-generation counter, or fold a label hash and that counter into the key. Do not use a lossy integer sum.

### 7. MEDIUM: horizontal overflow
Where: place_layers, lines 658-666.
Evidence: l_x grows by 56.0 + widest label + 2 * inset per layer and never reads width. The cache key includes width, so every resize recomputes an identical layout.
Failure scenario: the Romans fixture needs roughly 900 to 1000 pixels at 1100 wide; at 600 wide the later layers draw beyond the widget with no scroll, shrink or ellipsis.
Suggested fix: when the total exceeds width, shrink the slope gap to a floor, then truncate labels with an ellipsis using advance, or hold a horizontal scroll offset (SW_VSCROLLING is the precedent for a scroll mixin). Drop width from the key or use it.

### 8. MEDIUM: vertical overflow and title collision
Where: place_layers 667-679; title drawn at y + 16 (line 338).
Evidence: l_row is clamped below at text_extent * 1.6 (line 669). When l_most * l_row exceeds the height, (height - l_count * l_row) / 2 is negative and the top nodes get negative py (outside the widget). Even without overflow the title at y + 16 overlaps the first row of the fullest layer.
Suggested fix: subtract a title band from the available height and offset py by it; when rows still do not fit, scroll or clip visibly.

### 9. MEDIUM: ordering is four sweeps with no best-keep
Where: order_layers, lines 548-577.
Evidence: exactly four sweeps (down, up, down, up); the last result is kept even if an earlier one had fewer crossings. Common practice runs sweeps until crossings stop improving and keeps the best order, often with an adjacent-exchange (transpose) pass. Ties break by id, so determinism holds, but "to cut crossings" is not guaranteed.
Failure scenario: symmetric K2,2 shapes with equal barycenters finish on whichever half-step the fourth sweep leaves.
Suggested fix: count adjacent crossings linearly after each sweep, keep the best ordering, stop at no improvement or a sweep cap.

### 10. MEDIUM: extract the layered algorithm (A6 helper object, M4 monolith)
Evidence: break_cycles, visit, assign_layers, order_layers, sort_layer, crossing_count, tail and head (lines 414-634) touch only nodes.count, edges and four parallel arrays; only place_layers and draw_layered_edge need the painter. SW_DIAGRAM is 741 lines carrying force layout, layered layout, drawing, hit-testing and input; the GW-23 feature group adds about 20 features.
Proposal: a headless SW_LAYERED_LAYOUT helper (no painter, no widget) taking a node count and an edge list and producing layer_of, order_of, is_reversed and dummy chains. SW_DIAGRAM keeps placement and drawing. Benefits: the O(V*E) algorithms become unit-testable without a window (every current test needs an SW_WINDOW), findings 1, 3, 9 and 14 land once, and SW_ORG_CHART can share the engine. If several owners will share the surrounding protocol, a deferred ancestor inherited side by side with the force-layout parts and owning the helper follows the SW_VSCROLLBAR-inside-SW_VSCROLLING pattern.
Effort: about 8 features move, 2 stay.

### 11. MEDIUM: layering and stacking re-implemented per class
Evidence: SW_ORG_CHART.depth_of (line 57) is longest-path layering specialized to a forest; SW_TREE.append_subtree (line 411) carries depth the same way; SW_LANE_TIMELINE stacks items into rows with its own free_block and row ends (lines 450-516, interval packing, a different algorithm); SW_DIAGRAM.assign_layers is DAG layering. The measure-and-stack arithmetic (Box_h + Gap_y in SW_ORG_CHART, l_row and 56.0 here, row_h in the timeline) is the same loop under three names (category A5).
Suggested fix: do not merge the timeline's interval packing (it is a distinct algorithm). Move SW_ORG_CHART.depth_of onto the helper from finding 10 when it exists, and expose gap and row-pitch tokens (finding 17).

### 12. MEDIUM: font size token drift (T1)
Evidence: 11.5 appears at SW_DIAGRAM 307, 647 and 690, SW_GANTT 167, SW_MEDIA_TRANSPORT 173 (mono role) and SW_ORG_CHART 251. SW_THEME has size_chip 11.0, size_label 13.0 and size_body 16.0 and nothing at 11.5. Same role (graph and chart node label), several owners, one literal that does not scale with the theme.
Suggested fix: add a size_node token (or accept size_chip) in SW_THEME and read it; it must scale with theme size. Also the font is set three times per frame and once per edge (draw_layered_edge line 690); set it once per draw and once per layout.

### 13. LOW: source-heavy layering
Longest-path layering puts every node without predecessors in layer 1 even if its only successor is deep, creating long edges (finding 1). A one-pass promotion (move a source right to just before its earliest successor) is O(V + E); network simplex is the full answer.

### 14. LOW: recursion depth and rescans in visit
visit (500-519) recurses once per node along a chain, so a chain of N nodes reaches depth N (safe into the low tens of thousands with small Eiffel frames on the default Windows stack, not unbounded), and each call rescans every edge: O(V*E) total. Cached, so paid on change only. Fix: build one adjacency index (edge indices per node), iterate it, and use an explicit stack if the helper becomes public.

### 15. LOW: disconnected components and neighbor-less barycenters
Every source sits in layer 1 ordered by id, so isolated nodes interleave with the main graph's first layer instead of forming their own band. In sort_layer a node with no neighbors on the sweep side keeps key order_of.i_th (v) (line 612) while others get fractional barycenters; on the first sweep order_of was just wiped to zeros (line 555), so every neighbor-less node gets key 0 and floats to the top. Such a node should hold its current slot while others move around it.

### 16. LOW: duplicate and antiparallel edges
connect has no uniqueness precondition. Identical edges draw twice on top of each other. An edge a->b plus b->a makes the second a reversed edge drawn dashed from b's label end back over the solid a->b, a thick line with a dash overlay. Fix: merge antiparallel pairs into one double-headed edge in the helper.

### 17. LOW: layout literals
56.0 (slope room, line 664), 8.0 (left margin, 662), 24.0 (vertical margin, 669), 1.6 (row factor), 14.0 (edge start offset in draw_layered_edge, 692, which silently has to equal the label offset 10.0 at line 332 plus ring clearance), 20.0 (minimum arrow length) and the arrowhead 8.0, 16.0, 4.0. Move to named constants at least (SW_ORG_CHART already does with Box_w, Gap_x, Gap_y) and derive the label offset from one constant so the edge start cannot drift from the label.

### 18. LOW: test gaps and accessibility
Tests cover left-to-right edges, uncrossing, one cycle and the evidence images. Missing: a long edge (finding 1), a single-node and an empty graph, a plain second render proving cache stability (2), a relabel after first render (6), a 40-node layer (8), a narrow window (7), antiparallel edges. The cycle test pins the reversed edge to node order, which is good; keep it.
Accessibility: layered mode has no keyboard traversal between nodes, no text outline of the clause structure, and dragging is silently disabled (line 360) while handle_click still sets drag_index (line 351). Reversed edges are marked by dashes, a non-color cue, which is good. Suggested: arrow-key navigation along layer_of and order_of plus a text description feature. Also set_layered(False) does not set is_at_rest False, so the force layout may start from a rigid grid it considers settled.

## Recommended order

1. Findings 10, then 1, 3, 5 together: one defect (no dummy nodes) that decides the shape of the helper; do the extraction first so the fix lands once, headless and testable.
2. Findings 2 and 18: a strong cache and determinism test before further layout changes.
3. Findings 6 and 4: one layout_is_current notion fixes the stale key and the stale-query crash.
4. Findings 7 and 8, then 12 and 17 token cleanup in the same pass.
5. Findings 9, 13, 15, 16: layout quality, after the above.
