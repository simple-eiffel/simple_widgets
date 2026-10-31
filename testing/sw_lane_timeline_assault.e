note
	description: "[
		Assault on GW-17, SW_LANE_TIMELINE and its era years: astronomical
		years read as BC/AD or BCE/CE with no year zero anywhere, ticks on
		round displayed years, overlapping items stacked into rows, a
		dispute's positions stacked inside its envelope with a lean marked,
		semantic zoom, folding a group, the synchronism slice, the wheel
		zooming about the pointer, tradition never drawn as a point, and a
		pilot timeline with Hebrew and Greek titles in both themes (evidence
		gw17_timeline_light.png, gw17_timeline_dark.png).
	]"

class
	SW_LANE_TIMELINE_ASSAULT

inherit
	SW_VIRTUAL_GRID_ASSAULT
			-- for the frame budget and the timing harness (Plan 22, 2026-10-30)

feature -- Era years

	test_gw17_years_read_without_a_year_zero
			-- 753 BC is -752, 1 BC is 0, AD 1 is 1; BCE/CE on request; no label
			-- from 3000 BC to AD 3000 shows a year zero.
		local
			e: SW_ERA_YEARS
			yr: INTEGER
			l_clean: BOOLEAN
		do
			create e.make
			assert_true ("753 BC", e.label (-752).same_string ("753 BC"))
			assert_true ("1 BC", e.label (0).same_string ("1 BC"))
			assert_true ("AD 1", e.label (1).same_string ("AD 1"))
			assert_true ("AD 33", e.label (33).same_string ("AD 33"))
			assert_true ("a range across the eras", e.range_label (-3, 30).same_string ("4 BC - AD 30"))
			assert_true ("a range in AD", e.range_label (29, 34).same_string ("AD 29-34"))
			assert_true ("a range in BC", e.range_label (-1649, -1549).same_string ("1650-1550 BC"))
			e.set_common_era (True)
			assert_true ("753 BCE", e.label (-752).same_string ("753 BCE"))
			assert_true ("33 CE", e.label (33).same_string ("33 CE"))
			assert_integers_equal ("round trip", -752, e.astronomical (753, True))
			l_clean := True
			from yr := -3000 until yr > 3000 loop
				l_clean := l_clean and e.display_year (yr) >= 1
				yr := yr + 1
			end
			assert_true ("no year zero from 3000 BC to AD 3000", l_clean)
		end

	test_gw17_ticks_fall_on_round_displayed_years
			-- Step 5 from 11 BC to AD 10: 10 BC, 5 BC, AD 5, AD 10 (astronomical
			-- -9, -4, 5, 10); step 1 across the boundary: 2 BC, 1 BC, AD 1, AD 2.
		local
			e: SW_ERA_YEARS
			t: ARRAYED_LIST [INTEGER]
		do
			create e.make
			t := e.ticks (-10.0, 10.0, 5)
			assert_integers_equal ("four ticks", 4, t.count)
			assert_true ("10 BC, 5 BC, AD 5, AD 10", t [1] = -9 and t [2] = -4 and t [3] = 5 and t [4] = 10)
			t := e.ticks (-1.0, 2.0, 1)
			assert_true ("2 BC, 1 BC, AD 1, AD 2", t.count = 4 and t [1] = -1 and t [2] = 0 and t [3] = 1 and t [4] = 2)
			assert_integers_equal ("a step of 87 years rounds to 100", 100, e.nice_step (87.0))
		end

	test_gw17_axis_labels_are_whole
			-- No year label is cut by the plot's edge (a cut "1000 BC" reads
			-- "0 BC", the year zero there is not), at any of several views.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			views: ARRAY [REAL_64]
			i: INTEGER
		do
			create w.make ("gw17", 0, 0, 1100, 300, create {SW_THEME}.make_light)
			create tl.make
			tl.add_lane ("Rome", "Bible world").do_nothing
			w.set_root (tl)
			views := <<-1000.0, 450.0, -3017.0, 2011.0, -7.3, 9.1, 1499.5, 1601.25>>
			from i := views.lower until i > views.upper loop
				tl.set_view (views [i], views [i + 1])
				w.request_render
				assert_true ("some labels", not tl.axis_labels.is_empty)
				assert_true ("every label whole inside the plot",
					across tl.axis_labels as al all al.lx >= tl.plot_left and al.lx + al.lw <= tl.plot_left + tl.plot_w end)
				i := i + 2
			end
		end

feature -- Layout

	test_gw17_overlaps_stack_and_disputes_stay_together
			-- In one lane two overlapping reigns take two rows and a later one
			-- reuses the first; a dispute's two positions sit on consecutive
			-- rows inside one envelope.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			a, b, c, p30, p33: SW_TIMELINE_ITEM
			l, d: INTEGER
		do
			create w.make ("gw17", 0, 0, 900, 400, create {SW_THEME}.make_light)
			create tl.make
			l := tl.add_lane ("Rome", "Bible world")
			a := tl.add_item (l, "Augustus", -26, 14, 2)
			b := tl.add_item (l, "Herod", -36, -3, 2)
			c := tl.add_item (l, "Claudius", 41, 54, 2)
			d := tl.add_dispute ("Crucifixion", 29, 34)
			p30 := tl.add_position (d, l, "7 April AD 30", 30, 30, 1)
			p33 := tl.add_position (d, l, "3 April AD 33", 33, 33, 1)
			p33.set_lean ("AD 33 over AD 30: 0.60, a lean, not consensus")
			tl.set_view (-60.0, 70.0)
			w.set_root (tl)
			w.request_render
			assert_true ("all shown", tl.is_item_shown (a) and tl.is_item_shown (b) and tl.is_item_shown (c))
			assert_true ("overlapping reigns on different rows", tl.item_boxes [a.id].by /= tl.item_boxes [b.id].by)
			assert_true ("the two positions on consecutive rows",
				(tl.item_boxes [p33.id].by - tl.item_boxes [p30.id].by).abs = tl.row_h)
			assert_true ("the envelope holds both",
				tl.envelope_boxes [d].ey <= tl.item_boxes [p30.id].by.min (tl.item_boxes [p33.id].by)
				and tl.envelope_boxes [d].ey + tl.envelope_boxes [d].eh >= tl.item_boxes [p30.id].by.max (tl.item_boxes [p33.id].by) + tl.item_boxes [p30.id].bh - 1.0)
			assert_true ("the lean is marked, not chosen", p33.is_lean and tl.selected = Void)
		end

	test_gw17_semantic_zoom_and_folding
			-- A detail event shows at decade scale, not at millennium scale; a
			-- folded group's lanes take no room and drop from the slice.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l1, l2: INTEGER
			reign, detail, han: SW_TIMELINE_ITEM
		do
			create w.make ("gw17", 0, 0, 900, 400, create {SW_THEME}.make_light)
			create tl.make
			l1 := tl.add_lane ("Rome", "Bible world")
			l2 := tl.add_lane ("Han China", "Asia")
			reign := tl.add_item (l1, "Principate", -26, 284, 2)
			reign.set_importance (reign.Importance_period)
			detail := tl.add_item (l1, "Gallio in Corinth", 51, 52, 2)
			detail.set_importance (detail.Importance_detail)
			han := tl.add_item (l2, "Gan Ying sent west", 97, 97, 1)
			w.set_root (tl)
			tl.set_view (-3000.0, 2000.0)
			w.request_render
			assert_true ("millennium scale: the period shows", tl.is_item_shown (reign))
			assert_false ("the detail does not", tl.is_item_shown (detail))
			tl.set_view (40.0, 110.0)
			w.request_render
			assert_true ("decade scale: the detail shows", tl.is_item_shown (detail))
			assert_integers_equal ("AD 97: the period and Gan Ying", 2, tl.slice (97).count)
			tl.toggle_group ("Asia")
			w.request_render
			assert_true ("a folded lane takes no room", tl.lane_heights [l2] = 0.0)
			assert_integers_equal ("and leaves the slice", 1, tl.slice (97).count)
			tl.handle_click (tl.x + 10.0, tl.headers [2].hy + 2.0).do_nothing
			assert_false ("a click on its header unfolds it", tl.is_group_collapsed ("Asia"))
		end

	test_gw17_cursor_wheel_and_tradition
			-- A click on the plot sets the cursor at that year; the wheel zooms
			-- in about the pointer, keeping its year; a one-year tradition is a
			-- band, never a point.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l: INTEGER
			th: SW_TIMELINE_ITEM
			px, py: INTEGER
			l_year, l_span: REAL_64
		do
			create w.make ("gw17", 0, 0, 900, 400, create {SW_THEME}.make_light)
			create tl.make
			l := tl.add_lane ("Church", "Church")
			th := tl.add_item (l, "Thomas in India", 52, 52, 7)
			tl.set_view (-500.0, 500.0)
			w.set_root (tl)
			w.request_render
			assert_false ("tradition is never a point", th.is_point)
			assert_true ("drawn at least six pixels wide", tl.item_boxes [th.id].bw >= 6.0)
			px := (tl.year_x (200.5)).truncated_to_integer
			py := (tl.y + tl.axis_h + tl.row_h * 3.0).truncated_to_integer
			w.dispatch (2, px, py)
			w.dispatch (10, px, py)
			assert_true ("the cursor stands at AD 200", tl.has_cursor and (tl.cursor_year - 200).abs <= 1)
			l_span := tl.view_to - tl.view_from
			l_year := tl.year_at (px)
			w.dispatch (13, px, py)
			w.simulate_wheel (px, py, 120)
			assert_true ("zoomed in", tl.view_to - tl.view_from < l_span)
			assert_true ("the year under the pointer stays", (tl.year_at (px) - l_year).abs < 1.0)
		end

feature -- Scan 15 (since c9d5571)

	test_scan15_a_dispute_across_lanes_is_enveloped_in_each
			-- H1: one envelope box per dispute kept only the last lane's, so
			-- the positions in the other lanes stood unbracketed.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l1, l2, d: INTEGER
			p1, p2: SW_TIMELINE_ITEM
		do
			create w.make ("gw17", 0, 0, 900, 400, create {SW_THEME}.make_light)
			create tl.make
			l1 := tl.add_lane ("Rome", "Bible world")
			l2 := tl.add_lane ("Church", "Church")
			d := tl.add_dispute ("Crucifixion", 29, 34)
			p1 := tl.add_position (d, l1, "AD 30", 30, 30, 1)
			p2 := tl.add_position (d, l2, "AD 33", 33, 33, 1)
			tl.set_view (0.0, 60.0)
			w.set_root (tl)
			w.request_render
			assert_true ("the Rome position is enveloped", enveloped (tl, p1))
			assert_true ("the Church position is enveloped", enveloped (tl, p2))
		end

	test_scan15_a_one_year_bar_is_not_a_tick
			-- H2: a one-year item of class B (Qarqar, fixed to the year) was
			-- drawn as class A's tick, claiming a day it does not have.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l: INTEGER
			qarqar: SW_TIMELINE_ITEM
		do
			create w.make ("gw17", 0, 0, 900, 300, create {SW_THEME}.make_light)
			create tl.make
			l := tl.add_lane ("Israel and Judah", "Bible world")
			qarqar := tl.add_item (l, "Qarqar", -852, -852, 2)
			tl.set_view (-1000.0, 0.0)
			w.set_root (tl)
			w.request_render
			assert_false ("class B is a bar, not a tick", qarqar.is_point)
			assert_true ("wide enough to read as a bar", tl.item_boxes [qarqar.id].bw >= 6.0)
		end

	test_scan15_a_dispute_never_loses_a_position
			-- H3: positions were shown one by one, so at millennium scale a
			-- dispute of detail positions vanished. Disputes are drawn, not
			-- hidden: all positions show while the envelope is on the view.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l, d: INTEGER
			p1, p2: SW_TIMELINE_ITEM
		do
			create w.make ("gw17", 0, 0, 900, 300, create {SW_THEME}.make_light)
			create tl.make
			l := tl.add_lane ("Rome", "Bible world")
			d := tl.add_dispute ("Crucifixion", 29, 34)
			p1 := tl.add_position (d, l, "AD 30", 30, 30, 1)
			p2 := tl.add_position (d, l, "AD 33", 33, 33, 1)
			p1.set_importance (p1.Importance_detail)
			p2.set_importance (p2.Importance_detail)
			tl.set_view (-3000.0, 2000.0)
			w.set_root (tl)
			w.request_render
			assert_true ("both positions show at millennium scale", tl.is_item_shown (p1) and tl.is_item_shown (p2))
		end

	test_scan15_a_tick_stands_where_the_cursor_stands
			-- H4: a tick stood at the start of its year, the cursor and the
			-- axis at its middle - 200 pixels apart at a two-year view.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l: INTEGER
			ev: SW_TIMELINE_ITEM
		do
			create w.make ("gw17", 0, 0, 900, 300, create {SW_THEME}.make_light)
			create tl.make
			l := tl.add_lane ("Rome", "Bible world")
			ev := tl.add_item (l, "Ides of March", 10, 10, 1)
			tl.set_view (9.0, 11.0)
			tl.set_cursor (10)
			w.set_root (tl)
			w.request_render
			assert_true ("the tick at the cursor",
				((tl.item_boxes [ev.id].bx + tl.item_boxes [ev.id].bw / 2.0) - tl.year_x (10.5)).abs < 1.5)
		end

	test_scan15_preferred_height_counts_rows_and_headers
			-- H5: the preferred height counted one row per lane, not the
			-- stacked rows and the group headers, so lanes fell off the bottom.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l1, l2: INTEGER
		do
			create w.make ("gw17", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create tl.make
			l1 := tl.add_lane ("Rome", "Bible world")
			l2 := tl.add_lane ("Church", "Church")
			tl.add_item (l1, "Augustus", -26, 14, 2).do_nothing
			tl.add_item (l1, "Herod", -36, -3, 2).do_nothing
			tl.add_item (l1, "Tiberius", 14, 37, 2).do_nothing
			tl.add_item (l1, "Varus", -6, 9, 2).do_nothing
			tl.add_item (l2, "Pentecost", 30, 33, 6).do_nothing
			tl.set_view (-60.0, 60.0)
			w.set_root (tl)
			w.request_render
			assert_true ("tall enough for every row: " + tl.preferred_height (w.painter, tl.width).out + " against " + (tl.lane_tops [l2] + tl.lane_heights [l2] - tl.y).out,
				tl.preferred_height (w.painter, tl.width) >= tl.lane_tops [l2] + tl.lane_heights [l2] - tl.y)
		end

	test_scan15_lanes_below_the_bottom_can_be_reached
			-- H5: with no vertical scroll, lanes past the widget's height could
			-- not be reached. The timeline scrolls under a bar; the wheel still
			-- zooms; Page Down and the bar reach the last lane.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			i, l: INTEGER
		do
			create w.make ("gw17", 0, 0, 900, 240, create {SW_THEME}.make_light)
			create tl.make
			from i := 1 until i > 30 loop
				l := tl.add_lane ("Lane " + i.out, "Group " + ((i - 1) // 5).out)
				tl.add_item (l, "event " + i.out, i * 10, i * 10 + 5, 2).do_nothing
				i := i + 1
			end
			tl.set_view (0.0, 320.0)
			w.set_root (tl)
			w.request_render
			assert_true ("more than fits", tl.max_scroll > 0.0)
			assert_true ("the last lane starts below the bottom", tl.lane_tops [30] > tl.y + tl.height)
			from i := 1 until i > 40 loop
				tl.handle_key (34, False)
				i := i + 1
			end
			w.request_render
			assert_true ("scrolled to the end", tl.scroll_y = tl.max_scroll)
			assert_true ("the last lane is in view",
				tl.lane_tops [30] >= tl.y + tl.axis_h and tl.lane_tops [30] + tl.lane_heights [30] <= tl.y + tl.height + 0.5)
		end

feature -- The river (Plan 22 phase 1, 2026-10-30)

	test_river_deep_time_labels_have_separators
			-- Deep time reads with US thousands separators ("175,000 BC"); a year of four
			-- digits reads as before ("1446 BC").
		local
			e: SW_ERA_YEARS
		do
			create e.make
			assert_strings_equal ("175,000 BC", {STRING_32} "175,000 BC", e.label (-174999))
			assert_strings_equal ("10,000 BC", {STRING_32} "10,000 BC", e.label (-9999))
			assert_strings_equal ("four digits as before", {STRING_32} "1446 BC", e.label (-1445))
			assert_strings_equal ("a deep range", {STRING_32} "200,000-190,000 BC", e.range_label (-199999, -189999))
		end

	test_river_ten_thousand_items_hold_the_frame_budget
			-- Spike S1: 10,000 items in 16 lanes, a dispute of three positions in every 70,
			-- wheel frames at three views, each median inside the budget of the build (60 Hz
			-- lean, twice that with contracts). The original took 753 ms at the whole span.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			views: ARRAY [REAL_64]
			i, k: INTEGER
			l_frames: ARRAYED_LIST [REAL_64]
		do
			create w.make ("river-10k", 0, 0, 1600, 900, create {SW_THEME}.make_dark)
			tl := river (10_000)
			w.set_root (tl)
			views := <<-3000.0, 135.0, -1000.0, -500.0, -720.0, -680.0>>
			from i := views.lower until i > views.upper loop
				tl.set_view (views [i], views [i + 1])
				w.request_render
				create l_frames.make (12)
				from k := 1 until k > 12 loop
					tl.zoom_about ((views [i] + views [i + 1]) / 2.0, (if k \\ 2 = 0 then 0.97 else 1.03 end))
					l_frames.extend (timed (agent w.request_render))
					k := k + 1
				end
				io.put_string ("    river 10,000 items, view " + views [i].out + " .. " + views [i + 1].out + ": wheel frame median " + ((median (l_frames) * 100.0).rounded / 100.0).out + " ms%N")
				assert_true ("a wheel frame holds the budget at " + views [i].out, median (l_frames) < budget_here)
				i := i + 2
			end
		end

	test_river_band_label_stays_in_view
			-- A band that starts left of the view keeps its label at the plot's left edge
			-- (spike S2: the Paleolithic and the Iron Age lost theirs).
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			l_band: SW_TIMELINE_ITEM
		do
			create w.make ("river-band", 0, 0, 900, 300, create {SW_THEME}.make_light)
			create tl.make
			tl.add_lane ("Levant", "Near East").do_nothing
			l_band := tl.add_item (1, "Iron Age", -1199, -538, {SW_TIMELINE_ITEM}.Class_e)
			l_band.set_importance ({SW_TIMELINE_ITEM}.Importance_period)
			tl.set_view (-900.0, -600.0)
			w.set_root (tl)
			w.request_render
			assert_true ("the band is laid out from left of the plot", tl.item_boxes.i_th (l_band.id).bx < tl.plot_left)
			assert_true ("its label starts inside the plot", tl.label_left (l_band) >= tl.plot_left)
				-- mostly off the edge: too little of it in view for its label, which follows its end
			tl.set_view (-545.0, -245.0)
			w.request_render
			assert_reals_equal ("a sliver of band labels itself after its end",
				tl.item_boxes.i_th (l_band.id).bx + tl.item_boxes.i_th (l_band.id).bw + 4.0, tl.label_left (l_band), 0.001)
		end

	test_river_a_lean_keeps_its_room
			-- A lean's marker and wording are drawn after the label; an item that starts in the
			-- middle of that wording must go to another row (the seed's "shown first" ran into
			-- "Ashurbanipal sacks Susa").
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			d: INTEGER
			p, q: SW_TIMELINE_ITEM
			l_mid: REAL_64
		do
			create w.make ("river-lean", 0, 0, 1200, 300, create {SW_THEME}.make_light)
			create tl.make
			tl.add_lane ("Mesopotamia", "Near East").do_nothing
			d := tl.add_dispute ("Fall of Ur", -2003, -1939)
			p := tl.add_position (d, 1, "Fall of Ur: Middle chronology", -2003, -2003, {SW_TIMELINE_ITEM}.Class_c)
			p.set_lean ("shown first")
			tl.set_view (-2100.0, -1700.0)
			w.set_root (tl)
			w.request_render
				-- the middle of the wording, measured as the timeline draws it
			w.painter.font ({SW_PAINTER}.Role_ui, w.painter.theme.size_label, False)
			l_mid := tl.label_left (p) + w.painter.advance (p.title) + 8.0 + 12.0 + w.painter.advance ("shown first") / 2.0
			q := tl.add_item (1, "Ashurbanipal sacks Susa", tl.year_at (l_mid).floor, tl.year_at (l_mid).floor, {SW_TIMELINE_ITEM}.Class_b)
			w.request_render
			assert_true ("the item starts inside the wording", tl.item_boxes.i_th (q.id).bx < l_mid + 4.0)
			assert_true ("so it is not on the lean's row", tl.item_boxes.i_th (q.id).by /= tl.item_boxes.i_th (p.id).by)
		end

	test_river_lens_spans_deep_time_and_turns_linear
			-- Spike S2: the lens reaches 200,000 years ago and still gives the biblical span room;
			-- positions round-trip; the scale only increases; zoomed to 1,000 years or less it
			-- is exactly linear.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			px, l_prev, l_err, l_share, a, b, m: REAL_64
			i, k, l_bad: INTEGER
		do
			create w.make ("river-lens", 0, 0, 1600, 400, create {SW_THEME}.make_dark)
			create tl.make
			tl.add_lane ("World", "World").do_nothing
			tl.add_item (1, "Denisovans", -193000, -193000, {SW_TIMELINE_ITEM}.Class_b).set_importance ({SW_TIMELINE_ITEM}.Importance_period)
			tl.add_item (1, "Bar Kokhba", 132, 135, {SW_TIMELINE_ITEM}.Class_b).set_importance ({SW_TIMELINE_ITEM}.Importance_period)
			tl.set_lens (True)
			tl.set_view (-200000.0, 135.0)
			w.set_root (tl)
			w.request_render
			assert_true ("the lens reaches deep time", tl.view_from <= -199999.0)
			l_prev := -1.0e9
			from i := 0 until i > 400 loop
				px := tl.plot_left + tl.plot_w * i / 400.0
				l_err := l_err.max ((tl.year_x (tl.year_at (px)) - px).abs)
				i := i + 1
			end
			assert_true ("positions round-trip within half a pixel: " + l_err.out, l_err < 0.5)
			from i := 0 until i > 2000 loop
				px := tl.year_x (-200000.0 + 200134.0 * ((i / 2000.0) ^ 3))
				if px < l_prev then
					l_bad := l_bad + 1
				end
				l_prev := px
				i := i + 1
			end
			assert_integers_equal ("the scale only increases", 0, l_bad)
			l_share := (tl.year_x (135.0) - tl.year_x (-999.0)) / tl.plot_w
			assert_true ("1000 BC to AD 135 gets room: " + l_share.out, l_share > 0.10)
			from k := 1 until k > 25 loop
				tl.zoom_about (-700.0, 0.7)
				w.request_render
				k := k + 1
			end
			assert_true ("zoomed in, the view stays ordered and wide enough", tl.view_to - tl.view_from >= tl.Min_span)
			tl.set_view (-1000.0, -500.0)
			w.request_render
			a := tl.year_x (-1000.0)
			b := tl.year_x (-500.0)
			m := tl.year_x (-750.0)
			assert_true ("at 500 years the scale is linear", (m - (a + b) / 2.0).abs < 0.5)
		end

	test_river_hover_card_on_an_item
			-- Spike S6: a rest on an item opens its card (its title, then its years), anchored
			-- at its box, through the window's own event path.
		local
			w: SW_WINDOW
			tl: SW_LANE_TIMELINE
			it: SW_TIMELINE_ITEM
			b: TUPLE [bx, by, bw, bh: REAL_64]
		do
			create w.make ("river-card", 0, 0, 900, 300, create {SW_THEME}.make_light)
			create tl.make
			tl.add_lane ("Mesopotamia", "Near East").do_nothing
			it := tl.add_item (1, "Sennacherib besieges Lachish", -700, -700, {SW_TIMELINE_ITEM}.Class_a)
			tl.set_view (-760.0, -640.0)
			w.set_root (tl)
			w.request_render
			b := tl.item_boxes.i_th (it.id)
			w.dispatch (13, (b.bx + b.bw / 2.0).truncated_to_integer, (b.by + b.bh / 2.0).truncated_to_integer)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_true ("the rest opened a card", w.has_hover_card)
			if attached w.hover_card as al_c then
				assert_true ("anchored at the item", al_c.anchor_x = b.bx and al_c.anchor_y = b.by)
				assert_true ("its title first", attached {SW_COLUMN} al_c.content as al_col and then attached {SW_LABEL} al_col.children.first as al_l
					and then al_l.text.same_string_general ("Sennacherib besieges Lachish"))
			end
		end

feature -- Evidence

	test_gw17_timeline_light
		do
			pilot (create {SW_THEME}.make_light, "gw17_timeline_light.png")
		end

	test_gw17_timeline_dark
		do
			pilot (create {SW_THEME}.make_dark, "gw17_timeline_dark.png")
		end

feature {NONE} -- Fixtures

	river (a_count: INTEGER): SW_LANE_TIMELINE
			-- 16 lanes in 4 groups; `a_count' items from 3000 BC to AD 135 (3% periods, 27% major,
			-- 70% detail); one dispute of three positions per 70 items (spike S1's load).
		local
			i, l, f, len, d, l_seed: INTEGER
			it: SW_TIMELINE_ITEM
		do
			create Result.make
			from i := 1 until i > 16 loop
				Result.add_lane ("Lane " + i.out, "Group " + ((i - 1) // 4 + 1).out).do_nothing
				i := i + 1
			end
			l_seed := 12345
			from i := 1 until i > a_count loop
				l_seed := ((l_seed.to_integer_64 * 1103515245 + 12345) \\ 2147483648).to_integer_32
				l := (i \\ 16) + 1
				f := -3000 + l_seed.abs \\ 3135
				if i \\ 70 = 0 then
					d := Result.add_dispute ("Dispute " + i.out, f, f + 120)
					Result.add_position (d, l, "Position A " + i.out, f, f + 10, {SW_TIMELINE_ITEM}.Class_c).do_nothing
					Result.add_position (d, l, "Position B " + i.out, f + 40, f + 60, {SW_TIMELINE_ITEM}.Class_c).do_nothing
					Result.add_position (d, l, "Position C " + i.out, f + 100, f + 120, {SW_TIMELINE_ITEM}.Class_f).do_nothing
					i := i + 3
				else
					if i \\ 33 = 0 then
						len := 100 + l_seed.abs \\ 500
					else
						len := l_seed.abs \\ 60
					end
					it := Result.add_item (l, "Item " + i.out, f, f + len, (l_seed.abs \\ 6) + 1)
					if i \\ 33 = 0 then
						it.set_importance ({SW_TIMELINE_ITEM}.Importance_period)
					elseif l_seed.abs \\ 100 < 28 then
						it.set_importance ({SW_TIMELINE_ITEM}.Importance_major)
					else
						it.set_importance ({SW_TIMELINE_ITEM}.Importance_detail)
					end
					i := i + 1
				end
			end
		end

	enveloped (a_tl: SW_LANE_TIMELINE; a_item: SW_TIMELINE_ITEM): BOOLEAN
			-- Is `a_item''s box inside some envelope box?
		local
			b: TUPLE [bx, by, bw, bh: REAL_64]
		do
			b := a_tl.item_boxes [a_item.id]
			across
				a_tl.envelope_boxes as e
			loop
				if b.bx >= e.ex and b.bx + b.bw <= e.ex + e.ew and b.by >= e.ey and b.by + b.bh <= e.ey + e.eh then
					Result := True
				end
			end
		end

	pilot (a_theme: SW_THEME; a_name: STRING)
			-- A few pilot rows (11-timeline-pilot): every certainty class, a
			-- dispute with a lean, a Hebrew and a Greek title, a cursor at AD 30.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			tl: SW_LANE_TIMELINE
			l_isr, l_rome, l_church, l_asia, d: INTEGER
			it: SW_TIMELINE_ITEM
			path: STRING_32
		do
			create w.make ("gw17", 0, 0, 1100, 420, a_theme)
			kit := gw03_kit (a_theme)
			w.set_shaping (kit)
			create tl.make
			l_isr := tl.add_lane ("Israel and Judah", "Bible world")
			l_rome := tl.add_lane ("Rome", "Bible world")
			l_church := tl.add_lane ("Church", "Church")
			l_asia := tl.add_lane ("Han China", "Asia")
			tl.add_item (l_isr, "Babylonian Chronicle: Jerusalem taken", -596, -596, 1).do_nothing
			tl.add_item (l_isr, "Qarqar", -852, -852, 2).do_nothing
			it := tl.add_item (l_isr, "Division of the kingdom", -930, -927, 3)
			it.set_badge ("Thiele")
			tl.add_item (l_isr, genesis_first_word, -950, -900, 6).do_nothing
			tl.add_item (l_rome, "Augustus", -26, 14, 2).do_nothing
			tl.add_item (l_rome, "Rome founded", -752, -752, 7).do_nothing
			d := tl.add_dispute ("Crucifixion", 29, 34)
			tl.add_position (d, l_rome, "AD 30", 30, 30, 1).do_nothing
			it := tl.add_position (d, l_rome, "AD 33", 33, 33, 1)
			it.set_lean ("0.60, a lean")
			tl.add_item (l_church, john_1_1_wh_nfc.substring (1, 7), 85, 95, 6).do_nothing
			tl.add_item (l_church, "Thomas in India", 52, 52, 7).do_nothing
			tl.add_item (l_asia, "Hopewell", 1, 400, 5).do_nothing
			tl.add_item (l_asia, "Teotihuacan Sun Pyramid", 100, 250, 4).do_nothing
			tl.set_view (-1000.0, 450.0)
			tl.set_cursor (30)
			w.set_root (tl)
			w.request_render
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_true ("the slice at AD 30 holds the crucifixion position and Hopewell",
				tl.slice (30).count >= 2)
			path := evidence_path (a_name)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
