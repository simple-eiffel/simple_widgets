note
	description: "[
		Assault on GW-29: SW_DATA_GRID with the concordance's load - 100,000
		rows of shaped cells (a reference, a Hebrew or Greek word, and a
		line of the text, each line its own). The grid must take the rows,
		sort them, jump to the end and scroll at 60 Hz (a frame in under
		16.7 milliseconds) in both themes, with the Hebrew and Greek shaped
		(evidence gw29_grid_light.png and gw29_grid_dark.png).

		TIMING RUNS WITHOUT CONTRACTS. The frame budget is the shipping
		build's, so every measured step runs inside `without_contracts'
		(simple_testing): contract checking is off for that step only and
		back on after (Larry, 2026-10-25: "Timing needs trump contracts").
		The set-up, the selection and the test's own checks still run under
		contracts. The test also asserts that frames do not grow slower as
		the run goes on (the simple_shaping 0.6.1 defect) and that a frame
		drawn again shapes nothing.

		WHICH BUILD HOLDS THE BUDGET (2026-10-25, a note for the future
		self). Switching contracts off at run time does not make the
		contract build (`ec.sh test', -keep) as fast as the shipped one: on
		this machine a page jump takes 15 to 18 milliseconds there and 5 in
		the lean build, so the 60 Hz assertion failed one run in three -
		and 0.28.2, rebuilt from its own commit, failed the same way, so it
		was the machine and the build, not a regression. The 60 Hz budget is
		therefore asserted where it belongs, in the lean build
		(`ec.sh release', simple_widgets_lean.exe); the contract build
		asserts twice the budget, which still catches a gross regression,
		and reports its numbers. `is_lean_build' tells them apart.
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

	budget_here: REAL_64
			-- The budget this build is held to: 60 Hz in the lean (shipped)
			-- build; twice that in the contract build, whose code stays
			-- slower with contracts switched off.
		do
			if is_lean_build then
				Result := Frame_budget_ms
			else
				Result := 2.0 * Frame_budget_ms
			end
		end

	is_lean_build: BOOLEAN
			-- Were contracts left out of this build? A broken precondition IN
			-- THE LIBRARY raises only where they are compiled in (the testing
			-- cluster runs without assertions, so a test-class precondition
			-- cannot tell).
		once
			Result := not breaks_a_precondition
		end

	breaks_a_precondition: BOOLEAN
		local
			l_tried: BOOLEAN
			l_era: SW_ERA_YEARS
		do
			if not l_tried then
				create l_era.make
				l_era.astronomical (0, True).do_nothing
			else
				Result := True
			end
		rescue
			l_tried := True
			retry
		end

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
			l_rows: ARRAYED_LIST [SW_TEST_CONC_ROW]
			l_wheel, l_page: ARRAYED_LIST [REAL_64]
			l_sort: REAL_64
			l_checked_wheel, l_checked_page: ARRAYED_LIST [REAL_64]
			i, l_calls: INTEGER
			path: STRING_32
		do
			create w.make ("gw29", 0, 0, 900, 420, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			g := new_grid
			w.set_root (g)
			l_rows := new_rows
			report ("set_rows", timed (agent g.set_rows (l_rows)))
			l_sort := timed (agent g.sort_by (1, False))
			report ("sort by reference", l_sort)
			assert_true ("sorted in text order: Ref 1 first",
				g.rows.i_th (g.view.first).citation.same_string ({STRING_32} "Ref 1"))
			report ("first frame", timed (agent w.request_render))
			l_calls := kit.facade.statistics.cache_hits + kit.facade.statistics.cache_misses
			w.request_render
			assert_integers_equal ("a frame drawn again never reaches the facade", l_calls,
				kit.facade.statistics.cache_hits + kit.facade.statistics.cache_misses)
			report ("End key", timed (agent g.handle_key (35, False)))
			assert_integers_equal ("End selects the last row", g.view.last, g.selected_model)
			report ("frame at the end", timed (agent w.request_render))
				-- what 500 earlier tests left behind is collected now, not mid-frame
			(create {MEMORY}).full_collect
			from
				create l_wheel.make (30)
				i := 1
			until
				i > 30
			loop
				g.handle_wheel (120).do_nothing
				l_wheel.extend (timed (agent w.request_render))
				i := i + 1
			end
			from
				create l_page.make (30)
				i := 1
			until
				i > 30
			loop
				g.handle_key (33, False)
				l_page.extend (timed (agent w.request_render))
				i := i + 1
			end
			from
				create l_checked_wheel.make (20)
				create l_checked_page.make (20)
				i := 1
			until
				i > 20
			loop
				g.handle_wheel (120).do_nothing
				time_it (agent w.request_render)
				l_checked_wheel.extend (last_ms)
				g.handle_key (33, False)
				time_it (agent w.request_render)
				l_checked_page.extend (last_ms)
				i := i + 1
			end
			report ("wheel frame with contracts on (median, report only)", median (l_checked_wheel))
			report ("page-jump frame with contracts on (median, report only)", median (l_checked_page))
				-- The guard `without_contracts' would otherwise hide: with every
				-- contract on, frames must not grow slower as the run goes on
				-- (simple_shaping 0.6.1: each shaped string cost more than the last).
				-- Halves of ten frames, not five (2026-10-30): five 60 ms frames let one
				-- burst of other work on the machine fail the light or the dark run.
			assert_true ("with contracts on, wheel frames do not grow slower",
				median_of (l_checked_wheel, 11, 20) <= 2.0 * median_of (l_checked_wheel, 1, 10) + 2.0)
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
			if is_lean_build then
				report_text ("GW-29 measured in the LEAN build: held to 60 Hz")
			else
				report_text ("GW-29 measured in the CONTRACT build: held to twice the 60 Hz budget")
			end
			assert_true ("wheel scrolling holds 60 Hz in the build it is held to", median (l_wheel) < budget_here)
			assert_true ("a page jump holds 60 Hz in the build it is held to", median (l_page) < budget_here)
			assert_true ("100,000 rows sort in under half a second", l_sort < 500.0)
		end

	timed (a_work: PROCEDURE): REAL_64
			-- Milliseconds `a_work' takes, with contract checking off for it.
		do
			without_contracts (agent time_it (a_work))
			Result := last_ms
		end

	time_it (a_work: PROCEDURE)
		local
			clock: SIMPLE_MONOTONIC_CLOCK
			t0: INTEGER_64
			l_memory: MEMORY
		do
				-- no collector pause inside the measured frame (it runs before or
				-- after; a full suite once put 190 milliseconds into one frame)
			create l_memory
			l_memory.collection_off
			create clock
			t0 := clock.nanoseconds
			a_work.call (Void)
			last_ms := clock.elapsed_nanoseconds (t0) / 1.0e6
			l_memory.collection_on
		end

	last_ms: REAL_64
			-- What `time_it' measured last.

	report (a_what: STRING; a_ms: REAL_64)
		do
			io.put_string ("    GW-29 " + a_what + ": " + ((a_ms * 100.0).rounded / 100.0).out + " ms%N")
			io.output.flush
		end

	report_text (a_line: STRING)
		do
			io.put_string ("    " + a_line + "%N")
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

	worst (a_ms: ARRAYED_LIST [REAL_64]): REAL_64
		do
			across a_ms as m loop
				Result := Result.max (m)
			end
		end

end
