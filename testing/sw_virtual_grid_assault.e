note
	description: "[
		Assault on GW-29: SW_DATA_GRID with the concordance's load - 100,000
		rows of shaped cells (a reference, a Hebrew or Greek word, and a
		line of the text, each line its own). The grid must take the rows,
		sort them, jump to the end and scroll at 60 Hz (a frame in under
		16.7 milliseconds) in both themes, with the Hebrew and Greek shaped
		(evidence gw29_grid_light.png and gw29_grid_dark.png).

		WHICH BUILD. The frame budget is the shipping build's: it is
		asserted when contracts are off (`ec.sh release', the _lean
		binary). With contracts on (`ec.sh test'), every call checks its
		postconditions, and the test asserts what must hold there too:
		frames do not grow slower as the run goes on (the simple_shaping
		0.6.1 defect), and a frame drawn again shapes nothing.
	]"

class
	SW_VIRTUAL_GRID_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- The load

	test_gw29_hundred_thousand_rows_light
		do
			load_gate (create {SW_THEME}.make_light, "gw29_grid_light.png")
		end

	test_gw29_hundred_thousand_rows_dark
		do
			load_gate (create {SW_THEME}.make_dark, "gw29_grid_dark.png")
		end

feature {NONE} -- Fixtures

	Row_count: INTEGER = 100_000

	Frame_budget_ms: REAL_64 = 16.7
			-- One frame at 60 Hz.

	new_rows: ARRAYED_LIST [SW_TEST_CONC_ROW]
			-- `Row_count' rows; every line differs, as a concordance's do.
		local
			i: INTEGER
			l_line: STRING_32
		do
			create Result.make (Row_count)
			from
				i := 1
			until
				i > Row_count
			loop
				if i \\ 2 = 0 then
					create l_line.make_from_string (genesis_1_1_wlc)
				else
					create l_line.make_from_string (john_1_1_wh_nfc.substring (1, 40))
				end
				l_line.append ({STRING_32} " ")
				l_line.append_integer (i)
				Result.extend (create {SW_TEST_CONC_ROW}.make (reference_of (i),
					if i \\ 2 = 0 then genesis_first_word else john_1_1_wh_nfc.substring (1, 2) end, l_line))
				i := i + 1
			end
		end

	reference_of (i: INTEGER): STRING_32
		do
			create Result.make (16)
			Result.append ({STRING_32} "Ref ")
			Result.append_integer (Row_count - i + 1)
		end

	new_grid: SW_DATA_GRID [SW_TEST_CONC_ROW]
		do
			create Result.make (360.0)
			Result.add_column (create {SW_GRID_COLUMN [SW_TEST_CONC_ROW]}.make ("Reference", 110.0, agent {SW_TEST_CONC_ROW}.citation))
			Result.add_column (create {SW_GRID_COLUMN [SW_TEST_CONC_ROW]}.make ("Word", 110.0, agent {SW_TEST_CONC_ROW}.word))
			Result.add_column ((create {SW_GRID_COLUMN [SW_TEST_CONC_ROW]}.make ("Line", 520.0, agent {SW_TEST_CONC_ROW}.line)).growing)
		end

	load_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- Take, sort, jump to the end, then time frames: wheel scrolling
			-- (a notch a frame, the 60 Hz case) and page jumps (every row new).
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			g: SW_DATA_GRID [SW_TEST_CONC_ROW]
			clock: SIMPLE_MONOTONIC_CLOCK
			t0: INTEGER_64
			l_rows: ARRAYED_LIST [SW_TEST_CONC_ROW]
			l_wheel, l_page: ARRAYED_LIST [REAL_64]
			l_sort: REAL_64
			i, l_calls: INTEGER
			path: STRING_32
		do
			create clock
			create w.make ("gw29", 0, 0, 900, 420, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			g := new_grid
			w.set_root (g)
			l_rows := new_rows
			t0 := clock.nanoseconds
			g.set_rows (l_rows)
			report ("set_rows", clock.elapsed_nanoseconds (t0) / 1.0e6)
			t0 := clock.nanoseconds
			g.sort_by (1, False)
			l_sort := clock.elapsed_nanoseconds (t0) / 1.0e6
			report ("sort by reference", l_sort)
			assert_true ("sorted in text order: Ref 1 first",
				g.rows.i_th (g.view.first).citation.same_string ({STRING_32} "Ref 1"))
			t0 := clock.nanoseconds
			w.request_render
			report ("first frame", clock.elapsed_nanoseconds (t0) / 1.0e6)
			l_calls := kit.facade.statistics.cache_hits + kit.facade.statistics.cache_misses
			w.request_render
			assert_integers_equal ("a frame drawn again never reaches the facade", l_calls,
				kit.facade.statistics.cache_hits + kit.facade.statistics.cache_misses)
			t0 := clock.nanoseconds
			g.handle_key (35, False)
			report ("End key", clock.elapsed_nanoseconds (t0) / 1.0e6)
			assert_integers_equal ("End selects the last row", g.view.last, g.selected_model)
			t0 := clock.nanoseconds
			w.request_render
			report ("frame at the end", clock.elapsed_nanoseconds (t0) / 1.0e6)
			from
				create l_wheel.make (30)
				i := 1
			until
				i > 30
			loop
				g.handle_wheel (120).do_nothing
				t0 := clock.nanoseconds
				w.request_render
				l_wheel.extend (clock.elapsed_nanoseconds (t0) / 1.0e6)
				i := i + 1
			end
			from
				create l_page.make (30)
				i := 1
			until
				i > 30
			loop
				g.handle_key (33, False)
				t0 := clock.nanoseconds
				w.request_render
				l_page.extend (clock.elapsed_nanoseconds (t0) / 1.0e6)
				i := i + 1
			end
			report ("wheel frame (median)", median (l_wheel))
			report ("wheel frame (worst)", worst (l_wheel))
			report ("page-jump frame (median)", median (l_page))
			report ("page-jump frame (worst)", worst (l_page))
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_true ("wheel frames do not grow slower", median_of (l_wheel, 21, 30) <= 2.0 * median_of (l_wheel, 1, 10) + 2.0)
				-- The first page jumps revisit rows the wheel just drew (the memo
				-- serves them); from the eleventh on, every row is new.
			assert_true ("page frames do not grow slower", median_of (l_page, 21, 30) <= 2.0 * median_of (l_page, 11, 20) + 2.0)
			if contracts_checked then
				report ("(contracts on: the 60 Hz budget is the lean build's)", 0.0)
			else
				assert_true ("wheel scrolling holds 60 Hz", median (l_wheel) < Frame_budget_ms)
				assert_true ("a page jump holds 60 Hz", median (l_page) < Frame_budget_ms)
				assert_true ("100,000 rows sort in under half a second", l_sort < 500.0)
			end
		end

	report (a_what: STRING; a_ms: REAL_64)
		do
			io.put_string ("    GW-29 " + a_what + ": " + ((a_ms * 100.0).rounded / 100.0).out + " ms%N")
			io.output.flush
		end

	median (a_ms: ARRAYED_LIST [REAL_64]): REAL_64
		local
			l: SORTED_TWO_WAY_LIST [REAL_64]
		do
			create l.make
			across a_ms as m loop
				l.extend (m)
			end
			Result := l.i_th ((l.count + 1) // 2)
		end

	median_of (a_ms: ARRAYED_LIST [REAL_64]; a_from, a_to: INTEGER): REAL_64
			-- The median of frames `a_from' .. `a_to'.
		local
			l: ARRAYED_LIST [REAL_64]
			i: INTEGER
		do
			create l.make (a_to - a_from + 1)
			from i := a_from until i > a_to loop
				l.extend (a_ms.i_th (i))
				i := i + 1
			end
			Result := median (l)
		end

	contracts_checked: BOOLEAN
			-- Is this build checking the LIBRARY's contracts (where their
			-- cost lives)? A grid of no height breaks SW_DATA_GRID.make's
			-- precondition, which raises only when it is checked. (This test
			-- cluster's own assertions are not a guide: an extending target
			-- may run its clusters contract-free.)
		local
			l_tried: BOOLEAN
			l_grid: SW_DATA_GRID [INTEGER]
		do
			if not l_tried then
				create l_grid.make (0.0)
			end
			Result := l_tried
		rescue
			l_tried := True
			retry
		end

	worst (a_ms: ARRAYED_LIST [REAL_64]): REAL_64
		do
			across a_ms as m loop
				Result := Result.max (m)
			end
		end

end
