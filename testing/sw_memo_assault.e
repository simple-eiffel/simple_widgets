note
	description: "[
		The seventh scan's defects (since 24c8a87), each a test that fails on
		the old code: the layout memo serving a layout after the facade
		changed its fonts; labels and menus shaping through another path
		than the painter (another Hebrew face, a cache that never forgot);
		adding rows one at a time re-sorting every row each time.
	]"

class
	SW_MEMO_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- The memo

	test_scan7_memo_forgets_when_the_facade_changes
			-- After the facade drops its cache (or loads a font, or changes
			-- its defaults), the kit shapes again instead of answering from
			-- its memo.
		local
			kit: SW_SHAPING
			l_before, l_after: SHAPED_LAYOUT
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (create {SW_THEME}.make_light)
			l_before := kit.layout_styled (genesis_first_word, 0, 16, {SW_PAINTER}.Role_ui, False)
			assert_true ("asked again, the memo answers",
				kit.layout_styled (genesis_first_word, 0, 16, {SW_PAINTER}.Role_ui, False) = l_before)
			kit.facade.clear_cache
			l_after := kit.layout_styled (genesis_first_word, 0, 16, {SW_PAINTER}.Role_ui, False)
			assert_true ("after the facade changed, a fresh layout", l_after /= l_before)
		end

	test_scan7_label_shapes_like_the_painter
			-- A label's shaped layout is the one SW_PAINTER.text would draw:
			-- same faces (script faces included), same memo. With a Hebrew
			-- script face set, the label used to shape through `layout_for',
			-- which does not apply it.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			l: SW_LABEL
		do
			create w.make ("memo", 0, 0, 400, 120, create {SW_THEME}.make_light)
			kit := gw03_kit (w.theme)
			w.set_shaping (kit)
			create l.make_body (genesis_first_word)
			w.set_root (l)
			w.request_render
			if attached l.shaped_layout (w.painter, 0.0) as al_layout then
				assert_true ("the painter's own layout",
					al_layout = kit.layout_styled (genesis_first_word, 0, l.pixel_size (w.painter), l.role, l.is_bold))
			else
				assert_true ("a body label shapes", False)
			end
		end

feature -- Rows one at a time

	test_scan7_rows_added_one_at_a_time
			-- 2,000 rows added one by one to a sorted grid: quick, and in the
			-- order a full sort gives.
		local
			g: SW_DATA_GRID [SW_TEST_CONC_ROW]
			clock: SIMPLE_MONOTONIC_CLOCK
			t0: INTEGER_64
			i: INTEGER
			l_ms: REAL_64
			l_incremental: ARRAYED_LIST [INTEGER]
		do
			create clock
			create g.make (300.0)
			g.add_column (create {SW_GRID_COLUMN [SW_TEST_CONC_ROW]}.make ("Reference", 110.0, agent {SW_TEST_CONC_ROW}.citation))
			g.sort_by (1, True)
			t0 := clock.nanoseconds
			from i := 1 until i > 2_000 loop
				g.add_row (create {SW_TEST_CONC_ROW}.make (scrambled (i), "", ""))
				i := i + 1
			end
			l_ms := clock.elapsed_nanoseconds (t0) / 1.0e6
			io.put_string ("    2,000 rows added one at a time: " + ((l_ms * 100.0).rounded / 100.0).out + " ms%N")
			l_incremental := g.view.twin
			g.sort_by (1, True)
			assert_integers_equal ("all shown", 2_000, g.view.count)
			assert_true ("the order a full sort gives", across 1 |..| 2_000 as k all l_incremental.i_th (k) = g.view.i_th (k) end)
			assert_true ("quick: no re-sort per row", l_ms < 2_000.0)
		end

feature -- Column alignment

	test_scan7_hebrew_column_sits_flush_right
			-- By default a cell starts where its text's reading starts: a
			-- Hebrew line at the right of the cell, an English one at the left;
			-- Align_right puts any text at the right.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			g: SW_DATA_GRID [SW_TEST_CONC_ROW]
			l_hebrew, l_english, l_numbers: REAL_64
		do
			create w.make ("align", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (w.theme)
			w.set_shaping (kit)
			create g.make (150.0)
			g.add_column (create {SW_GRID_COLUMN [SW_TEST_CONC_ROW]}.make ("Line", 400.0, agent {SW_TEST_CONC_ROW}.line))
			w.set_root (g)
			w.request_render
			w.painter.font ({SW_PAINTER}.Role_ui, w.theme.size_label, False)
			l_hebrew := g.cell_left (w.painter, genesis_first_word, {SHAPING_CONSTANTS}.Align_start, 0.0, 400.0)
			l_english := g.cell_left (w.painter, {STRING_32} "In the beginning", {SHAPING_CONSTANTS}.Align_start, 0.0, 400.0)
			l_numbers := g.cell_left (w.painter, {STRING_32} "1234", {SHAPING_CONSTANTS}.Align_right, 0.0, 400.0)
			assert_true ("English starts at the left pad", (l_english - 8.0).abs < 0.5)
			assert_true ("Hebrew starts well to the right", l_hebrew > 200.0)
			assert_true ("right-aligned numbers end at the right pad",
				(l_numbers + w.painter.advance ({STRING_32} "1234") - 392.0).abs < 0.5)
		end

feature {NONE} -- Fixtures

	scrambled (i: INTEGER): STRING_32
			-- A reference that repeats now and then (equal keys keep their order).
		do
			create Result.make (12)
			Result.append ({STRING_32} "Ref ")
			Result.append_integer ((i * 7919) \\ 1_500)
		end

end
