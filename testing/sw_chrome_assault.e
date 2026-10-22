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

	test_theme_gw28_both_palettes_readable
			-- GW-28: every text-bearing pairing meets its contrast rule in
			-- both palettes, and each palette knows which it is.
		local
			l_light, l_dark: SW_THEME
		do
			create l_light.make_light
			create l_dark.make_dark
			assert ("light is readable", l_light.is_readable)
			assert ("dark is readable", l_dark.is_readable)
			assert ("light is not dark", not l_light.is_dark)
			assert ("dark is dark", l_dark.is_dark)
		end

	test_theme_gw28_fills_take_the_right_ink
			-- GW-28: light fills carry white text; dark fills brighten, so
			-- their text goes dark (white on dark-theme accent is ~3.3:1).
		local
			l_light, l_dark: SW_THEME
		do
			create l_light.make_light
			create l_dark.make_dark
			assert_naturals_equal ("light: white on accent", 0xFFFFFF, l_light.ink_on_accent)
			assert ("dark: white on accent would fail", l_dark.contrast_ratio (0xFFFFFF, l_dark.accent) < l_dark.Body_contrast)
			assert ("dark: ink on accent passes", l_dark.contrast_ratio (l_dark.ink_on_accent, l_dark.accent) >= l_dark.Body_contrast)
			assert ("dark: ink on danger passes", l_dark.contrast_ratio (l_dark.ink_on_danger, l_dark.danger) >= l_dark.Body_contrast)
			assert ("dark: warning ink on its wash", l_dark.contrast_ratio (l_dark.ink_warning, l_dark.wash_warning) >= l_dark.Body_contrast)
		end

	test_theme_gw28_ramp_moves_away
			-- GW-28: each ramp step stands out more than the last, against
			-- a white surface and against a dark one alike.
		local
			l_theme: SW_THEME
			i: INTEGER
		do
			create l_theme.make_light
			from i := 1 until i >= l_theme.Ramp_count loop
				assert ("light step " + i.out, l_theme.contrast_ratio (l_theme.ramp (i), l_theme.surface) < l_theme.contrast_ratio (l_theme.ramp (i + 1), l_theme.surface))
				i := i + 1
			end
			create l_theme.make_dark
			from i := 1 until i >= l_theme.Ramp_count loop
				assert ("dark step " + i.out, l_theme.contrast_ratio (l_theme.ramp (i), l_theme.surface) < l_theme.contrast_ratio (l_theme.ramp (i + 1), l_theme.surface))
				i := i + 1
			end
		end

	test_theme_gw28_unreadable_rejected
			-- GW-28: an unreadable value is refused at the call site, and a
			-- readable one is taken.
		local
			l_theme: SW_THEME
		do
			create l_theme.make_dark
			assert ("white on dark accent refused", call_is_refused (agent l_theme.set_inks_on_fills (0xFFFFFF, l_theme.ink_on_success, l_theme.ink_on_warning, l_theme.ink_on_danger)))
			assert ("surface-coloured soft ink refused", call_is_refused (agent l_theme.set_quiet_tones (l_theme.surface, l_theme.divider, l_theme.selection, l_theme.scrim)))
			assert ("a reversed ramp refused", call_is_refused (agent l_theme.set_ramp (l_theme.ramp (5), l_theme.ramp (4), l_theme.ramp (3), l_theme.ramp (2), l_theme.ramp (1))))
			l_theme.set_inks_on_fills (0x000000, 0x000000, 0x000000, 0x000000)
			assert ("readable value taken", l_theme.ink_on_accent = 0x000000 and l_theme.is_readable)
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

	call_is_refused (a_call: PROCEDURE): BOOLEAN
			-- Does `a_call' raise (a contract refusing its arguments)?
		local
			l_raised: BOOLEAN
		do
			if l_raised then
				Result := True
			else
				a_call.call (Void)
			end
		rescue
			l_raised := True
			retry
		end

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
