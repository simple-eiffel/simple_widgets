note
	description: "[
		Stars (0.50.0, simple_bible's Favorites): the theme's gold star drawn
		under a verse row's label, before a grid cell, and as a tree node's
		glyph. Each test renders the widget and counts the pixels near the
		theme's star colour: none before, many after. A starred row keeps its
		layout (the star stands in the label gutter).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SW_STAR_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_star_is_a_glyph
			-- The star is the last glyph, and every glyph user takes it.
		local
			b: SW_BUTTON
		do
			assert_true ("the star and the quotation mark are glyphs", {SW_PAINTER}.Glyph_star <= {SW_PAINTER}.Glyph_last and {SW_PAINTER}.Glyph_quote <= {SW_PAINTER}.Glyph_last)
			create b.make ("", Void)
			b.set_glyph ({SW_PAINTER}.Glyph_star)
			assert_integers_equal ("a button takes it", {SW_PAINTER}.Glyph_star, b.glyph_kind)
		end

	test_a_starred_row_draws_its_star
			-- A verse row's star stands under its label, and the columns do not move.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
			r: INTEGER
			l_left: REAL_64
		do
			create w.make ("stars", 0, 0, 760, 400, create {SW_THEME}.make_light)
			create v.make (380.0)
			v.add_column ("KJV").do_nothing
			r := v.add_row ("16")
			v.set_cell (r, 1, "For God so loved the world")
			r := v.add_row ("17")
			v.set_cell (r, 1, "For God sent not his Son")
			w.set_root (v)
			w.request_render
			l_left := v.column_left (1)
			assert_integers_equal ("no star yet", 0, star_pixels (w, v))
			v.set_row_starred (1, True)
			assert_true ("row 1 starred", v.is_row_starred (1) and not v.is_row_starred (2))
			w.request_render
			assert_true ("the star is drawn", star_pixels (w, v) > 10)
			assert_reals_equal ("the columns stay put", l_left, v.column_left (1), 0.001)
			v.set_row_starred (1, False)
			w.request_render
			assert_integers_equal ("and taken away", 0, star_pixels (w, v))
		end

	test_a_starred_grid_cell_draws_its_star
		local
			w: SW_WINDOW
			g: SW_DATA_GRID [STRING_32]
			l_rows: ARRAYED_LIST [STRING_32]
		do
			create w.make ("stars", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create g.make (200.0)
			g.add_column ((create {SW_GRID_COLUMN [STRING_32]}.make ("Place", 200.0, agent (s: STRING_32): STRING_32 do Result := s end)).with_star (agent (s: STRING_32): BOOLEAN do Result := s.same_string ("John 3:16") end))
			create l_rows.make (2)
			l_rows.extend ({STRING_32} "Genesis 1:1")
			l_rows.extend ({STRING_32} "John 3:16")
			g.set_rows (l_rows)
			w.set_root (g)
			w.request_render
			assert_true ("the starred row's cell draws the star", star_pixels (w, g) > 10)
			assert_true ("the column says which", g.columns.first.is_starred ({STRING_32} "John 3:16") and not g.columns.first.is_starred ({STRING_32} "Genesis 1:1"))
		end

	test_a_tree_node_draws_its_glyph
		local
			w: SW_WINDOW
			t: SW_TREE [STRING_32]
			l_roots: ARRAYED_LIST [STRING_32]
		do
			create w.make ("stars", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create t.make (200.0)
			create l_roots.make (2)
			l_roots.extend ({STRING_32} "Grace")
			l_roots.extend ({STRING_32} "John 3:16")
			t.set_roots (l_roots)
			t.set_label (agent (s: STRING_32): STRING_32 do Result := s end)
			w.set_root (t)
			w.request_render
			assert_integers_equal ("no glyphs, no star", 0, star_pixels (w, t))
			t.set_icon (agent (s: STRING_32): INTEGER do if s.same_string ("Grace") then Result := {SW_PAINTER}.Glyph_folder else Result := {SW_PAINTER}.Glyph_star end end)
			assert_integers_equal ("a folder's glyph", {SW_PAINTER}.Glyph_folder, t.icon_of ({STRING_32} "Grace"))
			w.request_render
			assert_true ("the favorite's star is drawn in gold", star_pixels (w, t) > 10)
		end

	test_a_standing_range_washes_its_text
			-- 0.51.0: a reader's quoted part is washed in the theme's gold, apart from the selection,
			-- and a new document starts with none.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
		do
			create w.make ("standing", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create d.make
			d.add_paragraph ("For God so loved the world, that he gave his only begotten Son.").do_nothing
			d.add_paragraph ("For God sent not his Son into the world to condemn the world.").do_nothing
			create v.make (250.0)
			v.set_document (d)
			w.set_root (v)
			w.request_render
			assert_integers_equal ("no wash yet", 0, colour_pixels (w, v, w.theme.wash_star))
			v.add_standing_range (1, 4, 2, 10)
			assert_integers_equal ("the first item's part", 1, v.standing_in (1).count)
			assert_true ("from its fifth character", v.standing_in (1).first.lo = 4)
			assert_true ("the second item to its tenth", v.standing_in (2).first.lo = 0 and v.standing_in (2).first.hi = 10)
			w.request_render
			assert_true ("the gold wash is drawn", colour_pixels (w, v, w.theme.wash_star) > 50)
			v.set_document (d)
			assert_true ("a new document has none", v.standing_ranges.is_empty)
		end

	test_a_standing_range_shows_over_a_cell_mark
			-- 0.51.1: in a parallel text a quoted part shows on a cell washed by a mark (the selected
			-- verse's blue); the mark's wash was painted over it.
		local
			w: SW_WINDOW
			v: SW_PARALLEL_TEXT
			r, u: INTEGER
		do
			create w.make ("over", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create v.make (250.0)
			v.add_column ("KJV").do_nothing
			r := v.add_row ("16")
			v.set_cell (r, 1, "For God so loved the world, that he gave his only begotten Son")
			v.cell_marks (r, 1).mark_range_with (0, v.cell (r, 1).count, "selected verse", (create {SW_MARK}.make ({SW_MARK}.Hue_blue)).with_wash).do_nothing
			w.set_root (v)
			w.request_render
			from u := 1 until u > v.unit_count or else v.unit_block (u) = r loop
				u := u + 1
			end
			v.add_standing_range (u, 0, u, 20)
			w.request_render
			assert_true ("the gold wash shows on the marked cell", colour_pixels (w, v, w.theme.wash_star) > 50)
		end

	test_a_wrapping_line_wraps_and_breaks_no_line
			-- 0.52.0: a wrapping line grows taller as its text wraps, like a multi-line box, yet Enter
			-- adds no line break and focus selects it all, like a field.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			l_line, l_single: SW_TEXT_BOX
			l_long: STRING_32
		do
			l_long := {STRING_32} "The two are not a part of the eleven. There are other disciples and those with them in the room."
			create w.make ("wrapping", 0, 0, 300, 400, create {SW_THEME}.make_light)
			create l_line.make_wrapping_line (l_long)
			create l_single.make_single_line (l_long)
			create col.make
			col.put (l_line)
			col.put (l_single)
			w.set_root (col)
			w.request_render
			assert_true ("it wraps: taller than one line (" + l_line.height.out + " against " + l_single.height.out + ")", l_line.height > l_single.height + 4.0)
			assert_true ("a field: focus selects it all", l_line.selects_all_on_focus)
			l_line.set_caret (l_line.text.count)
			l_line.handle_char (13)
			assert_false ("Enter adds no line break", l_line.text.has ('%N'))
		end

	test_pinned_rows_stay_first_under_any_sort
			-- 0.53.0: pinned rows (a reader's favorites) come first whatever the sort, in sort order
			-- among themselves; and a select's options can be cleared.
		local
			g: SW_DATA_GRID [STRING_32]
			l_rows: ARRAYED_LIST [STRING_32]
			sel: SW_SELECT
		do
			create g.make (200.0)
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Name", 120.0, agent (s: STRING_32): STRING_32 do Result := s end))
			create l_rows.make (4)
			l_rows.extend ({STRING_32} "delta")
			l_rows.extend ({STRING_32} "alpha")
			l_rows.extend ({STRING_32} "charlie")
			l_rows.extend ({STRING_32} "bravo")
			g.set_rows (l_rows)
			g.set_pinned (agent (s: STRING_32): BOOLEAN do Result := s.same_string ("charlie") or s.same_string ("delta") end)
			assert_true ("unsorted: the pinned first, in model order", g.rows.i_th (g.view.i_th (1)).same_string ("delta") and g.rows.i_th (g.view.i_th (2)).same_string ("charlie"))
			g.sort_by (1, False)
			assert_true ("ascending: charlie, delta, then alpha, bravo",
				g.rows.i_th (g.view.i_th (1)).same_string ("charlie") and g.rows.i_th (g.view.i_th (2)).same_string ("delta")
				and g.rows.i_th (g.view.i_th (3)).same_string ("alpha") and g.rows.i_th (g.view.i_th (4)).same_string ("bravo"))
			g.sort_by (1, True)
			assert_true ("descending: the pinned still first", g.rows.i_th (g.view.i_th (1)).same_string ("delta") and g.rows.i_th (g.view.i_th (3)).same_string ("bravo"))
			g.add_row ({STRING_32} "echo")
			assert_true ("an added row behind the pinned", g.is_pinned (g.rows.i_th (g.view.i_th (2))) and not g.is_pinned (g.rows.i_th (g.view.i_th (3))))
			create sel.make
			sel.add_option ("one")
			sel.add_option ("two")
			sel.select_index (2)
			sel.clear_options
			assert_true ("a select cleared", sel.options.is_empty and sel.selected_index = 0)
		end

feature {NONE} -- Pixels

	colour_pixels (a_window: SW_WINDOW; a_widget: SW_WIDGET; a_colour: NATURAL_32): INTEGER
			-- Pixels of `a_widget''s image within 6 levels of `a_colour'.
		local
			img: CAIRO_SURFACE
			mp: MANAGED_POINTER
			px, py: INTEGER
		do
			img := a_window.widget_image (a_widget, Void, 1.0)
			img.flush.do_nothing
			create mp.share_from_pointer (img.data, img.stride * img.height)
			from py := 0 until py >= img.height loop
				from px := 0 until px >= img.width loop
					if near (mp.read_natural_32 (py * img.stride + px * 4) & 0xFFFFFF, a_colour & 0xFFFFFF, 6) then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
			img.destroy
		end


	star_pixels (a_window: SW_WINDOW; a_widget: SW_WIDGET): INTEGER
			-- Pixels of `a_widget''s image within 24 levels of the theme's star colour.
		local
			img: CAIRO_SURFACE
			mp: MANAGED_POINTER
			l_star, l_pixel: NATURAL_32
			px, py: INTEGER
		do
			l_star := a_window.theme.star & 0xFFFFFF
			img := a_window.widget_image (a_widget, Void, 1.0)
			img.flush.do_nothing
			create mp.share_from_pointer (img.data, img.stride * img.height)
			from py := 0 until py >= img.height loop
				from px := 0 until px >= img.width loop
					l_pixel := mp.read_natural_32 (py * img.stride + px * 4) & 0xFFFFFF
					if near (l_pixel, l_star, 24) then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
			img.destroy
		end

	near (a, b: NATURAL_32; a_tol: INTEGER): BOOLEAN
		do
			Result := (((a |>> 16) & 0xFF).to_integer_32 - ((b |>> 16) & 0xFF).to_integer_32).abs <= a_tol
				and (((a |>> 8) & 0xFF).to_integer_32 - ((b |>> 8) & 0xFF).to_integer_32).abs <= a_tol
				and ((a & 0xFF).to_integer_32 - (b & 0xFF).to_integer_32).abs <= a_tol
		end

end
