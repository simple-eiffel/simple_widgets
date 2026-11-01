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
			assert_integers_equal ("the star is the last glyph", {SW_PAINTER}.Glyph_star, {SW_PAINTER}.Glyph_last)
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

feature {NONE} -- Pixels

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
