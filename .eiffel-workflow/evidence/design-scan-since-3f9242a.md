# Design Scan (diff mode): simple_widgets, since 3f9242a (main 086d3e8)
# Date: 2026-10-25
# Subjects: SW_MAP (changed), SW_REGION_GEOMETRY (new, generated), SW_THEME (mixed made public), tools/gen_region_geometry.py, GW-19 tests
# Compared against: the whole src/ (SW_WORLD_GEOMETRY, SW_PAINTER, SW_MAP's older code)
# Method: read-only. The Caspian finding was confirmed by an even-odd point test over the shipped land rings (the point 49.5 E, 41.5 N lies inside 1 land ring and 0 lake rings). Nothing was compiled.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Correctness | 8 | 2 | 4 | 2 |
| Abstraction / duplication / drift | 5 | 0 | 3 | 2 |
| Token drift | 1 | 0 | 0 | 1 |
| Performance | 3 | 0 | 2 | 1 |
| Accessibility | 2 | 0 | 1 | 1 |
| **Total** | **19** | **2** | **10** | **7** |

(Counts per category are approximate groupings; the totals by severity are exact: 2 HIGH, 10 MEDIUM, 7 LOW.)

## Findings

| # | Pri | Where | Short |
|---|-----|-------|-------|
| 1 | HIGH | gen_region_geometry.py rings_of; sw_map.e 700-720 | Holes dropped: the Caspian Sea (lon 47..50, inside the box) draws as land |
| 2 | HIGH | sw_map.e 713-717 | Hiding the lakes layer turns every lake into land |
| 3 | MEDIUM | gen_region_geometry.py clip_line | River pieces stop at the last inside vertex: gap at the box edge |
| 4 | MEDIUM | sw_map.e 700-715 | Box seam: fine coast inside, 110m coast outside, plus an antialiased hairline |
| 5 | MEDIUM | sw_map.e 104, 612 | Hover chip says land or sea from the 5-degree raster inside the drawn 1:10m region |
| 6 | MEDIUM | sw_map.e 559-570, 789-815 | Per-frame cost: world land and every region point projected even when off-view or covered |
| 7 | MEDIUM | sw_map.e 689-695, 723-745 | Per-frame allocation: a tuple per river or route point |
| 8 | MEDIUM | sw_map.e 522-546, 559-563 | coast_color is dead; land versus water separated only by a 20 percent tint |
| 9 | MEDIUM | sw_map.e 749-785 | Places are not hit-testable, hoverable or exposed to assistive technology |
| 10 | MEDIUM | sw_region_geometry.e 66-124 vs sw_world_geometry.e 32-100 | Two copies of one parser, already drifted |
| 11 | MEDIUM | sw_map.e 669-688 vs 789-815 | draw_ring_list vs draw_land: same fill loop |
| 12 | MEDIUM | sw_map.e 689-695 vs 723-745 | Stroked-ring branch vs draw_routes: same projected-points loop |
| 13 | LOW | sw_map.e 643-667 | Two buffers; the world one still silently skips a ring above 1,300 points |
| 14 | LOW | sw_map.e 749-785 vs 575-596 | Places vs markers: two dot lists, different radii and colors |
| 15 | LOW | sw_map.e 770-784 | Label placement: first-added wins; labels cut at the plot edge; off-view labels still measured |
| 16 | LOW | generator TOLERANCE | 0.012 degrees is about 3.4 pixels at zoom 128 |
| 17 | LOW | sw_map.e 131-132, 173 | Max_zoom 128 side effects and a stale comment |
| 18 | LOW | sw_map.e 559-563 | Water fill versus world land: checked, no defect beyond the seam |
| 19 | LOW | draw_places, draw_routes, draw_region | Hard-coded sizes and mix ratios belong in theme tokens |

## Detailed Findings

### Finding 1: Holes in land polygons are dropped; the Caspian Sea draws as land
**Priority:** HIGH
**Where:** tools/gen_region_geometry.py `rings_of` (keeps `coordinates[0]` of each polygon only); src/sw_map.e `draw_region` lines 700-720.
**Evidence:** Natural Earth 10m land carries the Caspian as an interior ring of the Eurasian polygon. The generator discards interior rings and the lakes data has no Caspian (the largest lake rings are Lake Nasser, 198 points, and Lake Van; none spans 47..50 E, 36..46 N). An even-odd test over the shipped land rings puts 49.5 E, 41.5 N inside one land ring and no lake ring. The Caspian shore inside the box (lon 47 to 50) therefore renders as solid land. The same applies to every interior ring (lake islands, inland seas, enclaves).
**Failure scenario:** zoom to 6 or more near Baku: the Caspian is the land color and Baku sits in the middle of land.
**Fix:** emit interior rings from the generator. Either write them as a `land_holes` list painted in the water color after land (same buffer, same loop), or tag rings and fill with even-odd. Add a test that a point in the Caspian is not covered by land.

### Finding 2: Lakes are an overlay, so hiding the lakes layer makes lakes land
**Priority:** HIGH (same root cause as 1)
**Where:** src/sw_map.e 713-717.
**Description:** because land has no holes, a lake is water painted over land. With `Layer_lakes` hidden, the Sea of Galilee, Dead Sea, Lake Van and Lake Nasser become land. A hidden layer should remove ink, not change geography. Lake islands (a land ring inside a lake) are submerged because lakes draw after all land.
**Fix:** as finding 1; with holes in the land, the toggle becomes honest.

### Finding 3: River clipping drops the crossing segment
**Priority:** MEDIUM
**Where:** tools/gen_region_geometry.py `clip_line`.
**Description:** vertices outside the box are dropped and pieces end at the last inside vertex. Ten-meter centerlines have segments of 0.05 to 0.5 degrees, so the Nile, Euphrates and Tigris stop up to one source segment short of the edge; at zoom 64 and above the gap is hundreds of pixels. A river that leaves and re-enters becomes two pieces with a gap between them. Pieces under `MIN_RIVER_LENGTH` (0.6 degrees) vanish silently.
**Fix:** clip per segment (Liang-Barsky) so a piece ends exactly on the edge; keep Douglas-Peucker after the clip.

### Finding 4: The box edge is a seam
**Priority:** MEDIUM
**Where:** src/sw_map.e 700-715; generator `clip_ring`.
**Description:** inside the box the coast is 1:10m; outside it is the 110m world, up to a few tenths of a degree apart. At zoom 6 (about 0.075 degrees per pixel) that is several pixels; at zoom 20 and above it is tens of pixels: a visible step in every coastline crossing lon 8, lon 50, lat 22 or lat 46 (Sardinia is cut at 8 E, the Persian Gulf coast crosses 50 E). The water rectangle is filled on fractional pixel edges after the coarse land, then the clipped land is filled to the same edge: two antialiased fills on one edge leave a faint line of water color over the outside land. Sutherland-Hodgman on the concave Afro-Eurasian ring also emits collinear bridge edges along the box edge between exit and re-entry; they enclose no area (the fill is correct) but antialiasing can draw them as hairlines. No ring was found that fills a sliver of sea as land through this mechanism: the data shows the large ring spans exactly 8..50 by 22..46.
**Fix:** (a) fill water and land inside one `push_clip` rectangle snapped to whole pixels; (b) stroke the coast with `coast_color` (see 8); (c) or extend the data a degree past the box and fade in; (d) state the seam in the class note.

### Finding 5: Hover chip uses the coarse raster inside the 1:10m region
**Priority:** MEDIUM
**Where:** src/sw_map.e 104 (`is_land`, 5-degree cells), caller at 612.
**Failure scenario:** zoomed on the Nile delta at zoom 128, the chip says Land over the drawn Mediterranean (or Sea over drawn Sinai), because a 5-degree cell decides. The drawn map and the answer disagree.
**Fix:** when the point is inside the region and the region is drawn, answer by point-in-ring over land (minus holes, finding 1) and lakes; keep the raster elsewhere. A bounding box per ring (finding 6) keeps it cheap.

### Finding 6: Culling and double painting
**Priority:** MEDIUM
**Where:** src/sw_map.e 559-570, `draw_land` 789-815, `draw_ring_list` 669-698.
**Description:** every frame at zoom 6 or more, all 237 land rings (5,479 points), 29 lakes (965) and 72 river lines (2,502) are projected and handed to the painter whether or not they touch the view; only the painter clip rejects them. At zoom 128 most rings lie far off-screen (coordinates up to about 100,000 pixels) yet each builds a path. `draw_land` projects the whole world first (4,964 points) and the box water fill then paints over it; when the view lies wholly inside the box the world land is wasted work.
**Fix:** emit a bounding box per ring (or compute once on load) and skip rings whose box misses the view and rings smaller than a pixel; skip `draw_land` when the view is inside the box and `is_region_drawn`.

### Finding 7: Per-frame allocation in stroked lists and routes
**Priority:** MEDIUM
**Where:** src/sw_map.e 689-695 and 723-745.
**Description:** the painter documents `polygon_fill_flat` as the zero-allocation path for big geometry; the rivers branch uses the allocating `polyline` (about 2,500 tuples and 72 lists per frame), `draw_routes` likewise. Per the project rule that timing trumps elegance in hot paths, this is the next thing to flatten.
**Fix:** a flat `polyline_flat (a_xy, a_count, a_width, a_style)` on SW_PAINTER, sibling of `polygon_fill_flat`.

### Finding 8: Palette separates land and water by tint only; coast_color is dead
**Priority:** MEDIUM
**Where:** src/sw_map.e 522-546, 559-563.
**Description:** `coast_color` (line 534) is used nowhere in src or testing. Land is the surface itself; water is the surface mixed 20 percent toward the accent, which is well under 3:1 non-text contrast in most themes and invisible to some color vision deficiencies. The old map used `surface_variant`, a token GW-16 contrast mending already guarantees; the new palette bypasses that guarantee. Rivers are mixed from the water color but run over land, so their contrast is measured against the wrong ground.
**Fix:** stroke coasts with `coast_color`; derive water from a contrast-mended token; add an assault measuring land versus water contrast in every shipped theme, light, dark and high contrast.

### Finding 9: Places are invisible to hover, keyboard and assistive technology
**Priority:** MEDIUM
**Where:** src/sw_map.e 749-785; `marker_at` searches `markers` only.
**Description:** a place whose label is hidden by zoom or overlap cannot be named: no chip, no hit test, no list for a screen reader or keyboard stepping. Route certainty is shown by dash style (good, not color alone) but route names are never exposed.
**Fix:** unify places and markers (14) so `marker_at` and the chip cover them; expose a text summary of visible places and routes and keyboard stepping.

### Finding 10: Two copies of one parser, already drifted
**Priority:** MEDIUM (duplication with drift, D1)
**Classes:** SW_WORLD_GEOMETRY (`parse_block` 32-72, `flush_ring` 80-98, `pending` 100), SW_REGION_GEOMETRY (`parse_block` 66-101, `flush` 103-122, `pending` 124).
**Description:** the same state machine (token accumulation, semicolon ends a ring, white space ends a number, tail carried in `pending`). Divergences: the world flushes its last ring through `is_last_block (a_data) = (a_data = data_5)`, an object-identity test against a named constant that breaks when blocks are added or reordered; the region flushes explicitly at the end of each once function (this should win). The world requires 6 numbers per ring, the region 4 (a two-point ring is a line, not a land ring). Pending capacity differs (2600 vs 4096).
**Suggested action:** a deferred ancestor, for example SW_GEOMETRY_DATA, inherited side by side by both data classes, owning `parse_block`, `flush`, `pending` and a deferred or constant `minimum_numbers`; the generators then emit only data and the once functions. A third generated data class would otherwise be copy number three.
**Effort:** 3 features moved, 1 query added.

### Finding 11: draw_land and draw_ring_list are one loop
**Priority:** MEDIUM
**Where:** src/sw_map.e 789-815 and 669-688.
**Description:** project each point, call `polygon_fill_flat`. `draw_land` can be `draw_ring_list (a_p, geometry.polygons, True, 1.0)`; only the buffer differs (13).

### Finding 12: Stroked-ring branch and draw_routes are one loop
**Priority:** MEDIUM
**Where:** src/sw_map.e 689-695 and 723-745.
**Description:** both build a list of projected tuples and stroke it. Drift: rings index from 1 (`ring [k * 2 + 1]`, wrong for another lower bound), routes use `points.lower` (right). Routes branch on `is_certain` only to pass `Stroke_solid` or `Stroke_dashed` to the same call; a local style variable removes the branch. `polyline` and `dashed_polyline` with `Stroke_solid` are the same stroke in the painter, so the painter has no second dashed implementation to duplicate (checked: routes correctly reuse `dashed_polyline`).
**Fix:** one projection helper honoring `lower`, used by both.

### Finding 13: Two screen buffers; the world one silently skips big rings
**Priority:** LOW
**Where:** src/sw_map.e 643-648 (`screen_buf`, fixed 1..2600 reals) and 655-667 (`ring_buf`, sized from data).
**Description:** the new comment records that a fixed buffer silently skipped the 3,266-point ring. `draw_land` still has that guard (`n * 2 <= screen_buf.count`): a world ring above 1,300 points is skipped without a sound. The `ring_buf` postcondition walks 237 plus 29 rings once, negligible. Size one shared buffer from both data sets (with 11).

### Finding 14: Places versus markers
**Priority:** LOW
**Where:** `markers` (label, lat, lon; dot 3.4, ring 4.0, accent, hover chip) and `places` (adds min_zoom; dot 3.0, ink, no hover).
**Description:** places are markers plus a zoom. Two lists, two radii, two colors for one role; a marker at a place's coordinates draws two dots. Fold `min_zoom` into markers (default 1.0). This also resolves 9.

### Finding 15: Label placement
**Priority:** LOW
**Where:** src/sw_map.e 770-784.
**Description:** the overlap rectangle test is correct (both axes, strict inequalities, label box at px+6, py minus half height). But (a) first added wins, so a minor place added early hides a major one: sort by `min_zoom` before placing; (b) a label near the right plot edge runs under the clip and is cut instead of flipping to the left of its dot; (c) off-view places still measure text and enter `drawn_labels`: test against the plot first.

### Finding 16: Simplification tolerance versus Max_zoom
**Priority:** LOW
**Where:** generator `TOLERANCE = 0.012`; src/sw_map.e 131.
**Description:** at zoom 128 the window is 2.8 degrees; on an 800-pixel plot a pixel is 0.0035 degrees, so a 0.012 error is about 3.4 pixels: faceted coasts and straight river runs at the zoom the item advertises. Douglas-Peucker also runs after the clip on a ring split at its midpoint; out-and-back bridge edges can collapse. Lower the tolerance or cap Max_zoom near the data resolution, and state which in the note.

### Finding 17: Max_zoom 128 side effects
**Priority:** LOW
**Where:** src/sw_map.e 131-132 and 173 (comment still says "1..16").
**Description:** the city hit-test reach is in pixels and unaffected; `set_view` clamps the center to plus or minus (180 minus span/2), so no antimeridian wrap occurs at 128 (the clamp just tightens). The remaining cost is magnitude: the coarse world polygons project to about 128 times the plot width, which the painter backend should be checked against (finding 6 also removes the work). The UTC band is one 15-degree rectangle and stays correct. Update the stale comment.

### Finding 18: Water fill versus world land
**Priority:** LOW (checked, no defect)
The water rectangle is exactly the box (`x_of_lon (West)`..`x_of_lon (East)`, `y_of_lat (North)`..`y_of_lat (South)`), so world land outside the box is not hidden; the only artifact is the seam of finding 4. `is_region_drawn` tests the view against the box on all four sides.

### Finding 19: Hard-coded values that belong in tokens
**Priority:** LOW
**Where:** `draw_places` dot radius 3.0 and label gap 6.0 (markers use 3.4 and 4.0: same role, different values); `draw_routes` width 2.0; `draw_region` river width zoom/24 clamped 1.0..2.5; palette mixes 0.2, 0.3, 0.7; `Region_zoom` 6.0.
**Fix:** theme tokens (map dot radius, label gap, route width, water mix) that scale with the theme size scale; keep zoom thresholds as widget constants.

## Recommended Order

1. Findings 1 and 2 (holes): visible wrong geography; fix in the generator, regenerate, add a Caspian assault.
2. Finding 5 together with 1 (both need point-in-ring).
3. Finding 10 (parser ancestor) before another generated data class.
4. Findings 6, 7, 11, 12, 13 as one refactor: flat projected buffer, bounding boxes, one draw loop.
5. Findings 3, 4, 16 on the next data regeneration.
6. Findings 8, 9, 14, 15, 19 as the accessibility and token pass.
