note
	description: "[
		Assault on the 7GUIs domain engines: CELLS_ENGINE parsing,
		propagation and cycles; CIRCLES_MODEL undo law and hit
		testing; the text box clear X contract.
	]"

class
	SW_7GUIS_ASSAULT

inherit
	TEST_SET_BASE

feature -- Cells

	test_cells_literal_and_formula
		local
			e: CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "10")
			assert ("literal shows", e.display (e.key (0, 1)).same_string_general ("10"))
			e.commit (e.key (0, 2), "=A0*2")
			assert ("formula evaluates", e.display (e.key (0, 2)).same_string_general ("20"))
			e.commit (e.key (0, 3), "=(A0+B0)/3")
			assert ("parens and division", e.display (e.key (0, 3)).same_string_general ("10"))
		end

	test_cells_propagation
		local
			e: CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "10")
			e.commit (e.key (0, 2), "=A0*2")
			e.commit (e.key (1, 1), "=B0+1")
			e.commit (e.key (0, 1), "50")
			assert ("direct dependent", e.display (e.key (0, 2)).same_string_general ("100"))
			assert ("transitive dependent", e.display (e.key (1, 1)).same_string_general ("101"))
			assert ("touched includes the chain",
				e.touched.has (e.key (0, 2)) and e.touched.has (e.key (1, 1)))
		end

	test_cells_cycle_is_error
		local
			e: CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "=B0")
			e.commit (e.key (0, 2), "=A0")
			assert ("cycle shows error", e.display (e.key (0, 2)).same_string_general ("#ERR")
				or e.display (e.key (0, 1)).same_string_general ("#ERR"))
		end

	test_cells_text_and_garbage
		local
			e: CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (4, 1), "hello")
			assert ("text passes through", e.display (e.key (4, 1)).same_string_general ("hello"))
			e.commit (e.key (5, 1), "=)(")
			assert ("garbage formula errors", e.display (e.key (5, 1)).same_string_general ("#ERR"))
		end

feature -- Circles

	test_circles_undo_redo_law
		local
			m: CIRCLES_MODEL
		do
			create m.make
			assert ("virgin", not m.can_undo and not m.can_redo)
			m.add_circle (10.0, 10.0)
			m.add_circle (50.0, 50.0)
			assert_integers_equal ("two placed", 2, m.circles.count)
			m.undo
			assert_integers_equal ("one after undo", 1, m.circles.count)
			assert ("redoable", m.can_redo)
			m.redo
			assert_integers_equal ("two after redo", 2, m.circles.count)
			m.undo
			m.add_circle (90.0, 90.0)
			assert ("new change clears redo", not m.can_redo)
		end

	test_circles_adjustment_is_one_step
		local
			m: CIRCLES_MODEL
		do
			create m.make
			m.add_circle (10.0, 10.0)
			m.begin_adjustment (1)
			m.set_radius (1, 30.0)
			m.set_radius (1, 40.0)
			m.set_radius (1, 55.0)
			m.undo
			assert ("one undo reverts the whole session", m.circles.i_th (1).radius = 15.0)
		end

	test_circles_nearest_hit
		local
			m: CIRCLES_MODEL
		do
			create m.make
			m.add_circle (100.0, 100.0)
			m.add_circle (130.0, 100.0)
			assert_integers_equal ("inside first only", 1, m.nearest_hit (92.0, 100.0))
			assert_integers_equal ("overlap picks nearer centre", 2, m.nearest_hit (122.0, 100.0))
			assert_integers_equal ("open space hits nothing", 0, m.nearest_hit (300.0, 300.0))
		end

feature -- Clear X

	test_clear_button_contract
		local
			b: SW_TEXT_BOX
		do
			create b.make_single_line ("hello")
			assert ("off by default", not b.shows_clear)
			b.set_clear_button (True)
			assert ("armed with text", b.shows_clear)
			b.clear_text
			assert ("cleared", b.text.is_empty)
			assert ("no text, no X", not b.shows_clear)
			create b.make_password ("secret")
			b.set_clear_button (True)
			assert ("masked never shows the X", not b.shows_clear)
		end

end
