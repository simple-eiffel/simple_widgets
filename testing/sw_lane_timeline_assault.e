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
	SW_SHAPING_ASSAULT

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
