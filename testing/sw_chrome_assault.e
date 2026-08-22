note
	description: "[
		Assault on chrome and theming - including drawing, run
		HEADLESS: an offscreen cairo image surface gives the painter
		a real context, so layout and draw paths execute with every
		assertion live and no window anywhere.
	]"

class
	SW_CHROME_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_radio_auto_selects_first
		local
			r: SW_RADIO_GROUP
		do
			r := (create {SW_RADIO_GROUP}.make).with_option ("Alpha").with_option ("Beta").with_option ("Gamma")
			assert_integers_equal ("first is chosen", 1, r.selected_index)
		end

	test_toolbar_by_label_state
		local
			tb: SW_TOOLBAR
		do
			create tb.make
			tb.add_tool ("New", "", True, Void)
			tb.add_gap
			tb.add_toggle ("Bold", "", False, Void)
			tb.add_toggle ("Italic", "", True, Void)
			assert ("bold off", not tb.is_tool_on ("Bold"))
			assert ("italic on", tb.is_tool_on ("Italic"))
			assert ("unknown label is off", not tb.is_tool_on ("Ghost"))
			assert ("plain tool is never on", not tb.is_tool_on ("New"))
		end

	test_toolbar_click_fires_and_latches
		local
			tb: SW_TOOLBAR
			p: SW_PAINTER
		do
			p := headless_painter
			create tb.make
			tb.add_toggle ("Bold", "hint", False, agent record_fire)
			tb.set_bounds (0.0, 0.0, 400.0, 34.0)
			tb.draw (p)
			fired := 0
			if tb.handle_click (16.0, 17.0) then end
			assert_integers_equal ("action fired", 1, fired)
			assert ("latched on", tb.is_tool_on ("Bold"))
			if tb.handle_click (16.0, 17.0) then end
			assert ("latched off again", not tb.is_tool_on ("Bold"))
			assert_integers_equal ("fired both times", 2, fired)
		end

	test_theme_invariants_both_ways
			-- Creating each palette runs the WCAG invariants; setters
			-- must hold them too.
		local
			t: SW_THEME
		do
			create t.make_light
			assert ("light body readable", t.size_body >= 12.0)
			create t.make_dark
			assert ("dark body readable", t.size_body >= 12.0)
			t.set_washes (t.wash_accent, t.wash_success, t.wash_warning, t.wash_danger)
			assert ("washes survive identity swap", True)
		end

	test_painter_circles_and_text
			-- The circle primitives (born from the dash-through-the-
			-- circles bug) and text advance, headless.
		local
			p: SW_PAINTER
		do
			p := headless_painter
			p.set_color (0xFF0000)
			p.circle_stroke (50.0, 50.0, 10.0)
			p.circle_fill (50.0, 50.0, 4.0)
			p.font ({SW_PAINTER}.Role_ui, 16.0, False)
			assert ("advance measures", p.advance ("simple_widgets") > 0.0)
			assert ("wider text is wider", p.advance ("simple_widgets!") > p.advance ("simple"))
		end

	test_layout_clamps
		local
			b: SW_BUTTON
		do
			create b.make ("Clamp", Void)
			b := b.with_min_size (100.0, 40.0)
			b := b.with_max_size (120.0, 44.0)
			assert ("width clamped up", b.clamped_width (10.0) = 100.0)
			assert ("width clamped down", b.clamped_width (500.0) = 120.0)
			assert ("width passes inside", b.clamped_width (110.0) = 110.0)
			assert ("height clamped up", b.clamped_height (1.0) = 40.0)
			assert ("height clamped down", b.clamped_height (99.0) = 44.0)
		end

feature {NONE} -- Fixture

	headless_painter: SW_PAINTER
			-- A painter over an offscreen image surface: real cairo,
			-- real fonts, no window.
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (800, 600)
			create ctx.make (surf)
			create th.make_dark
			create Result.make (ctx, th)
		end

	fired: INTEGER

	record_fire
		do
			fired := fired + 1
		end

end
