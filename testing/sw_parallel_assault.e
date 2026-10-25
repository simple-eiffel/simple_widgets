note
	description: "[
		Assault on GW-06, SW_PARALLEL_TEXT: rows as tall as their tallest
		cell, columns by weight, Hebrew flush right in its column, cells
		and notes hit and clicked, selection copying rows and cells, the
		title band staying put while the rows scroll, spacing from the
		theme at 1x and 2x, and the They Chose gate in both themes
		(evidence gw06_parallel_light.png and gw06_parallel_dark.png).
		Inherits the shaping assault for its scripture fixtures and kit.
	]"

class
	SW_PARALLEL_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Layout

	test_gw06_rows_follow_their_tallest_cell
			-- Each row is as tall as its tallest cell; the cells of a row
			-- start at the same top; equal weights give equal columns.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
			b1, b2: TUPLE [x, y, width, height: REAL_64]
		do
			create w.make ("par", 0, 0, 760, 400, create {SW_THEME}.make_light)
			attach_parallel_kit (w)
			v := three_columns
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_integers_equal ("two rows, three cells each", 6, v.unit_count)
			assert_reals_equal ("equal columns", v.column_width (1), v.column_width (3), 0.000_1)
			b1 := v.text_boxes (1, 0, 1).first
			b2 := v.text_boxes (3, 0, 1).first
			assert_reals_equal ("a row's cells start level", b1.y, b2.y, 0.5)
			assert_true ("the long cell wraps, so the row is taller than a line",
				v.unit_geometry (3).line_count > 1)
			assert_true ("and the short cell's row is as tall as the long one",
				(v.stacked_top (2) - v.stacked_top (1)) >= v.unit_geometry (3).content_height)
		end

	test_gw06_cells_hit_click_and_copy
			-- `cell_at' names the verse and version; a press and release on a
			-- cell is a click; a selection copies cells tab-separated and rows
			-- line by line.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
			b: TUPLE [x, y, width, height: REAL_64]
			l_cell: TUPLE [row, column: INTEGER]
		do
			create w.make ("par", 0, 0, 760, 400, create {SW_THEME}.make_light)
			attach_parallel_kit (w)
			v := three_columns
			v.set_on_cell_click (agent note_cell)
			w.set_root (v)
			w.request_render
			b := v.text_boxes (5, 0, 1).first
			l_cell := v.cell_at (b.x + 1.0, b.y + 2.0)
			assert_true ("row 2, column 2", l_cell.row = 2 and l_cell.column = 2)
			clicked_row := 0
			assert_true ("press taken", v.handle_click (b.x + 1.0, b.y + 2.0))
			v.handle_release ((b.x + 1.0).truncated_to_integer, (b.y + 2.0).truncated_to_integer)
			assert_true ("clicked (2, 2)", clicked_row = 2 and clicked_column = 2)
			v.select_range (1, 0, 5, 3)
			assert_strings_equal ("cells by tabs, rows by lines",
				{STRING_32} "In the beginning%TAt first%TBefore all things were made, there was a beginning in which the Word already stood.%NAnd%TAnd", v.selected_text)
		end

	test_gw06_hebrew_column_and_note
			-- A Hebrew cell sits flush right in its column; a note row spans
			-- every column in muted text.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
			r, n: INTEGER
			b: TUPLE [x, y, width, height: REAL_64]
		do
			create w.make ("par", 0, 0, 760, 400, create {SW_THEME}.make_light)
			attach_parallel_kit (w)
			create v.make (380.0)
			v.add_column ("KJV").do_nothing
			v.add_column ("WLC").do_nothing
			v.set_column_scale (2, 1.25)
			r := v.add_row ("1:1")
			v.set_cell (r, 1, "In the beginning God created the heaven and the earth.")
			v.set_cell (r, 2, genesis_first_word)
			n := v.add_note ("LXX 9 = MT 9-10")
			w.set_root (v)
			w.request_render
			b := v.text_boxes (2, 0, 1).first
			assert_true ("the Hebrew word ends at its column's right edge",
				(v.unit_origin_x (2) + v.column_width (2)) - (b.x + b.width) < 4.0)
			assert_true ("a note", v.is_note_row (n) and v.unit_column (3) = 0)
			assert_true ("it spans the columns", v.unit_geometry (3).count = v.note_text (n).count)
		end

	test_gw06_title_band_stays_while_rows_scroll
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
			i: INTEGER
			h: REAL_64
		do
			create w.make ("par", 0, 0, 600, 300, create {SW_THEME}.make_light)
			attach_parallel_kit (w)
			create v.make (300.0)
			v.add_column ("A").do_nothing
			v.add_column ("B").do_nothing
			from i := 1 until i > 80 loop
				v.set_cell (v.add_row (i.out), 1, "Verse text " + i.out)
				i := i + 1
			end
			w.set_root (v)
			w.request_render
			h := v.header_height
			assert_true ("a title band", h > 0.0)
			assert_integers_equal ("starts at row 1", 1, v.first_visible)
			v.scroll_to_row (60)
			w.request_render
			assert_true ("row 60 is in view", 60 >= v.first_visible and 60 <= v.last_visible)
			assert_reals_equal ("the band did not move or change", h, v.header_height, 0.0)
			assert_true ("row 60 stands below the band", v.stacked_top (60) >= v.y + h - 0.5)
		end

	test_gw06_spacing_follows_the_theme
			-- The column gap is the theme's padding and the title band grows
			-- with the text: both double at 2x.
		local
			w1, w2: SW_WINDOW
			v1, v2: SW_PARALLEL_TEXT
			t2: SW_THEME
		do
			create w1.make ("s1", 0, 0, 760, 400, create {SW_THEME}.make_light)
			attach_parallel_kit (w1)
			v1 := three_columns
			w1.set_root (v1)
			w1.request_render
			create t2.make_light
			t2.set_text_scale (2.0)
			create w2.make ("s2", 0, 0, 1520, 800, t2)
			attach_parallel_kit (w2)
			v2 := three_columns
			w2.set_root (v2)
			w2.request_render
			assert_reals_equal ("the column gap is the padding", w1.theme.padding,
				v1.column_left (2) - v1.column_left (1) - v1.column_width (1), 0.000_1)
			assert_reals_equal ("and doubles", 2.0 * w1.theme.padding,
				v2.column_left (2) - v2.column_left (1) - v2.column_width (1), 0.000_1)
			assert_true ("the band about doubles", v2.header_height > 1.8 * v1.header_height)
		end

	test_gw06_band_is_not_content
			-- The title band hides the rows scrolled under it: a point on the
			-- band names no cell.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
		do
			create w.make ("band", 0, 0, 600, 300, create {SW_THEME}.make_light)
			attach_parallel_kit (w)
			v := long_parallel
			w.set_root (v)
			w.request_render
			v.scroll_to (120.0)
			w.request_render
			assert_true ("scrolled", v.scroll_y > 0.0)
			assert_integers_equal ("no cell under the band", 0, v.cell_at (v.x + 80.0, v.y + v.header_height / 2.0).row)
		end

	test_gw06_scroll_to_row_shows_it_below_the_band
			-- Scrolling to a row puts it below the band, and row 1 is at the
			-- very top.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
		do
			create w.make ("band", 0, 0, 600, 300, create {SW_THEME}.make_light)
			attach_parallel_kit (w)
			v := long_parallel
			w.set_root (v)
			w.request_render
			v.scroll_to (v.max_scroll)
			w.request_render
			v.scroll_to_row (1)
			w.request_render
			assert_reals_equal ("row 1 at the top", 0.0, v.scroll_y, 0.000_1)
			v.scroll_to (0.0)
			w.request_render
			v.scroll_to_row (40)
			w.request_render
			assert_true ("row 40 below the band", v.stacked_top (40) >= v.y + v.header_height - 0.5)
			assert_true ("and inside the view", v.stacked_top (40) + 1.0 < v.y + v.height)
		end

feature -- They Chose, both themes

	test_gw06_parallel_light
		do
			parallel_gate (create {SW_THEME}.make_light, "gw06_parallel_light.png")
		end

	test_gw06_parallel_dark
		do
			parallel_gate (create {SW_THEME}.make_dark, "gw06_parallel_dark.png")
		end

feature {NONE} -- Fixtures

	clicked_row, clicked_column: INTEGER

	note_cell (a_row, a_column: INTEGER)
		do
			clicked_row := a_row
			clicked_column := a_column
		end

	attach_parallel_kit (a_window: SW_WINDOW)
		local
			kit: SW_SHAPING
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_window.theme)
			a_window.set_shaping (kit)
		end

	long_parallel: SW_PARALLEL_TEXT
			-- Two columns, sixty rows.
		local
			i: INTEGER
		do
			create Result.make (300.0)
			Result.add_column ("A").do_nothing
			Result.add_column ("B").do_nothing
			from i := 1 until i > 60 loop
				Result.set_cell (Result.add_row (i.out), 1, "Verse text " + i.out)
				i := i + 1
			end
		end

	three_columns: SW_PARALLEL_TEXT
			-- Three columns, two rows; one long cell that wraps.
		local
			r: INTEGER
		do
			create Result.make (380.0)
			Result.add_column ("KJV").do_nothing
			Result.add_column ("YLT").do_nothing
			Result.add_column ("Paraphrase").do_nothing
			r := Result.add_row ("1:1")
			Result.set_cell (r, 1, "In the beginning")
			Result.set_cell (r, 2, "At first")
			Result.set_cell (r, 3, "Before all things were made, there was a beginning in which the Word already stood.")
			r := Result.add_row ("1:2")
			Result.set_cell (r, 1, "And")
			Result.set_cell (r, 2, "And the Earth")
			Result.set_cell (r, 3, "The earth lay unformed.")
		end

	parallel_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- They Chose: NT | LXX (Swete) | MT (WLC) - Heb 8:8, LXX Jer 38:31,
			-- MT Jer 31:31 - "new covenant" marked by agreement through a
			-- legend with text labels, a note row, and Genesis and John
			-- wrapping in their columns. Nothing skipped; evidence written.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			v: SW_PARALLEL_TEXT
			lg: SW_MARK_LEGEND
			m1, m2: SW_MARK
			r: INTEGER
			path: STRING_32
		do
			create w.make ("gw06", 0, 0, 900, 420, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			create lg.make
			create m1.make ({SW_MARK}.Hue_teal)
			m1 := m1.with_wash
			create m2.make ({SW_MARK}.Hue_amber)
			m2 := m2.with_wash
			lg.define ("lxx", m1, "agrees with LXX")
			lg.define ("both", m2, "agrees with both")
			create v.make (420.0)
			v.set_legend (lg)
			v.add_column ("NT (Heb 8:8)").do_nothing
			v.add_column ("LXX (Jer 38:31)").do_nothing
			v.add_column ("MT (Jer 31:31)").do_nothing
			v.set_column_scale (3, 1.2)
			r := v.add_row ("8:8")
			v.set_cell (r, 1, new_covenant_greek)
			v.set_cell (r, 2, new_covenant_greek)
			v.set_cell (r, 3, new_covenant_hebrew)
			v.cell_marks (r, 1).mark_range (0, new_covenant_greek.count, "lxx").do_nothing
			v.cell_marks (r, 2).mark_range (0, new_covenant_greek.count, "lxx").do_nothing
			v.cell_marks (r, 3).mark_range (0, new_covenant_hebrew.count, "both").do_nothing
			v.add_note ("LXX Jer 38 = MT Jer 31").do_nothing
			r := v.add_row ("1:1")
			v.set_cell (r, 1, john_1_1_wh)
			v.set_cell (r, 2, "In the beginning God made the heaven and the earth.")
			v.set_cell (r, 3, genesis_1_1_wlc)
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_integers_equal ("seven units", 7, v.unit_count)
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_true ("runs painted", kit.bridge.painted_runs > 10)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

	new_covenant_greek: STRING_32
			-- diatheken kainen.
		once
			create Result.make (16)
			across <<0x03B4, 0x03B9, 0x03B1, 0x03B8, 0x03AE, 0x03BA, 0x03B7, 0x03BD, 0x0020,
				0x03BA, 0x03B1, 0x03B9, 0x03BD, 0x03AE, 0x03BD>> as c loop
				Result.append_code (c.to_natural_32)
			end
		end

	new_covenant_hebrew: STRING_32
			-- berit hadashah, pointed.
		once
			create Result.make (20)
			across <<0x05D1, 0x05BC, 0x05B0, 0x05E8, 0x05B4, 0x05D9, 0x05EA, 0x0020,
				0x05D7, 0x05B2, 0x05D3, 0x05B8, 0x05E9, 0x05B8, 0x05C1, 0x05D4>> as c loop
				Result.append_code (c.to_natural_32)
			end
		end

end
