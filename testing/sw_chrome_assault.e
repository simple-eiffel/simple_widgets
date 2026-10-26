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

feature -- GW-27: the window follows the Windows light/dark setting

	test_gw27_follow_matches_windows
			-- Following picks the member of the pair Windows asks for,
			-- and the caption matches it.
		local
			w: SW_WINDOW
			a: SHELL_APPEARANCE
		do
			create a
			create w.make ("follow", 0, 0, 200, 120, create {SW_THEME}.make_light)
			assert_false ("a light window starts with a light caption", w.title_bar_is_dark)
			w.follow_system_theme (create {SW_THEME}.make_light, create {SW_THEME}.make_dark)
			assert_true ("following", w.is_following_system_theme)
			assert_true ("the theme matches Windows", w.theme.is_dark = a.system_prefers_dark)
			assert_true ("and so does the caption", w.title_bar_is_dark = a.system_prefers_dark)
		end

	test_gw27_flip_swaps_live
			-- Event 53 swaps the theme both ways, repaints in it, tells
			-- the app, and still acts while a dialog is open.
		local
			w: SW_WINDOW
			l_light, l_dark: SW_THEME
			l_told: ARRAYED_LIST [SW_THEME]
			d: SW_DIALOG
		do
			create l_light.make_light
			create l_dark.make_dark
			create l_told.make (2)
			create w.make ("follow", 0, 0, 200, 120, l_light)
			w.follow_system_theme (l_light, l_dark)
			w.set_on_theme_changed (agent l_told.extend)
			l_told.wipe_out
			w.dispatch (w.Event_appearance_changed, 1, 0)
			assert_true ("dark on 1", w.theme = l_dark and w.painter.theme = l_dark and w.title_bar_is_dark)
			assert_integers_equal ("repainted in dark", l_dark.background.to_integer_32, frame_pixel (w, 2, 2))
			w.dispatch (w.Event_appearance_changed, 0, 0)
			assert_true ("light on 0", w.theme = l_light and not w.title_bar_is_dark)
			assert_integers_equal ("repainted in light", l_light.background.to_integer_32, frame_pixel (w, 2, 2))
			assert_integers_equal ("the app was told twice", 2, l_told.count)
			assert_true ("with the right themes", l_told.first = l_dark and l_told.last = l_light)
			create d.make ({SW_DIALOG}.Kind_info, "Title", "Body")
			w.show_dialog (d)
			w.dispatch (w.Event_appearance_changed, 1, 0)
			assert_true ("a dialog does not block the flip", w.theme = l_dark)
			w.close_dialog
		end

	test_gw27_user_choice_stops_following
			-- The user's own choice (set_theme) wins: later flips are ignored.
		local
			w: SW_WINDOW
			l_light, l_dark: SW_THEME
		do
			create l_light.make_light
			create l_dark.make_dark
			create w.make ("follow", 0, 0, 200, 120, l_light)
			w.follow_system_theme (l_light, l_dark)
			w.set_theme (l_light)
			assert_false ("no longer following", w.is_following_system_theme)
			w.dispatch (w.Event_appearance_changed, 1, 0)
			assert_true ("a flip leaves the chosen theme", w.theme = l_light and not w.title_bar_is_dark)
		end

feature -- GW-26: a worker's wake reaches the app

	test_gw26_wake_calls_the_app_even_under_a_dialog
			-- Event 54 runs `on_wake' and repaints, with or without an open
			-- dialog; with no handler it is harmless. The heartbeat setting
			-- passes through to the shell.
		local
			w: SW_WINDOW
			d: SW_DIALOG
			l_calls: CELL [INTEGER]
		do
			create l_calls.put (0)
			create w.make ("wake", 0, 0, 200, 120, create {SW_THEME}.make_light)
			w.dispatch (w.Event_wake, 0, 0)
			w.set_on_wake (agent (a_calls: CELL [INTEGER]) do a_calls.put (a_calls.item + 1) end (l_calls))
			w.dispatch (w.Event_wake, 0, 0)
			assert_integers_equal ("the app was called", 1, l_calls.item)
			create d.make ({SW_DIALOG}.Kind_info, "Title", "Body")
			w.show_dialog (d)
			w.dispatch (w.Event_wake, 0, 0)
			assert_integers_equal ("a dialog does not hold it back", 2, l_calls.item)
			w.close_dialog
			w.set_heartbeat_ms (100)
			assert_integers_equal ("heartbeat settable", 100, w.heartbeat_ms)
			w.set_heartbeat_ms (250)
		end

feature -- GW-11: status-bar sections

	test_gw11_sections_lay_out_and_answer
			-- Left message, two leading text sections, then trailing:
			-- edition text, a progress bar, a Cancel button. Leading packs
			-- left to right after the left message; trailing ends at the
			-- right pad in the order added; nothing overlaps; the hosted
			-- widgets sit inside the bar. A clickable section runs its
			-- agent through the window's own click path, the Cancel button
			-- fires through it too, and a hidden section takes no room and
			-- answers nothing.
		local
			w: SW_WINDOW
			root: SW_COLUMN
			bar: SW_STATUS_BAR
			l_prog: SW_PROGRESS
			l_cancel: SW_BUTTON
			l_links, l_note, l_ed, l_pg, l_cn: INTEGER
			l_clicks, l_cancels: CELL [INTEGER]
			l_old_left: REAL_64
		do
			create l_clicks.put (0)
			create l_cancels.put (0)
			create w.make ("status", 0, 0, 900, 200, create {SW_THEME}.make_light)
			create root.make
			create bar.make
			root.put (create {SW_LABEL}.make_ui ("body"))
			root.put (bar)
			w.set_root (root)
			bar.set_left ("Gen 1:1 · WLC")
			l_links := bar.add_text ("Links: Default", False)
			l_note := bar.add_text ("LXX Ps 22:1 = MT Ps 23:1", False)
			l_ed := bar.add_text ("Edition 2026.10", True)
			create l_prog.make (0.4)
			l_pg := bar.add_widget (l_prog, 120.0, True)
			create l_cancel.make ("Cancel", agent (a_c: CELL [INTEGER]) do a_c.put (a_c.item + 1) end (l_cancels))
			l_cn := bar.add_widget (l_cancel, 80.0, True)
			bar.set_on_section_click (l_links, agent (a_c: CELL [INTEGER]) do a_c.put (a_c.item + 1) end (l_clicks))
			w.request_render
			assert_true ("leading after the left message", bar.section (l_links).left > bar.x + 12.0)
			assert_true ("leading in order, no overlap",
				bar.section (l_note).left >= bar.section (l_links).left + bar.section (l_links).span)
			assert_true ("trailing in order, no overlap",
				bar.section (l_pg).left >= bar.section (l_ed).left + bar.section (l_ed).span
				and bar.section (l_cn).left >= bar.section (l_pg).left + bar.section (l_pg).span)
			assert_true ("the last trailing section ends at the right pad",
				(bar.section (l_cn).left + bar.section (l_cn).span - (bar.x + bar.width - 12.0)).abs < 0.5)
			assert_true ("leading never runs into trailing",
				bar.section (l_note).left + bar.section (l_note).span < bar.section (l_ed).left)
			assert_true ("the progress bar sits in its section, inside the bar",
				l_prog.x = bar.section (l_pg).left and l_prog.width = 120.0
				and l_prog.y >= bar.y and l_prog.y + l_prog.height <= bar.y + bar.height)
			assert_true ("a clickable section shows the hand", bar.wants_hover_point)
			w.dispatch (2, mid (bar.section (l_links)), (bar.y + bar.height / 2.0).truncated_to_integer)
			assert_integers_equal ("the link-set section ran its agent", 1, l_clicks.item)
			w.dispatch (2, mid (bar.section (l_note)), (bar.y + bar.height / 2.0).truncated_to_integer)
			assert_integers_equal ("a plain section does nothing", 1, l_clicks.item)
			w.dispatch (2, mid (bar.section (l_cn)), (bar.y + bar.height / 2.0).truncated_to_integer)
			assert_integers_equal ("the hosted Cancel button fired", 1, l_cancels.item)
			assert_true ("the hosted widgets are children", bar.sub_widgets.has (l_prog) and bar.sub_widgets.has (l_cancel))
			l_old_left := bar.section (l_pg).left
			bar.set_section_visible (l_pg, False)
			w.request_render
			assert_true ("a hidden section takes no room", bar.section (l_pg).span = 0.0)
			assert_integers_equal ("and answers nothing where it was", 0,
				(bar.section_at (l_old_left + 1.0) = l_pg).to_integer)
			assert_false ("and is no longer a child", bar.sub_widgets.has (l_prog))
			assert_true ("the trailing side closed up",
				(bar.section (l_cn).left + bar.section (l_cn).span - (bar.x + bar.width - 12.0)).abs < 0.5
				and bar.section (l_cn).left >= bar.section (l_ed).left + bar.section (l_ed).span)
		end

feature -- Spacing from the theme (Vision2 tokens)

	test_reference_marks_sit_on_corners_and_tip
			-- Pills name parts of a window for screenshots: hidden until shown, each at its
			-- widget's chosen corner, and the one under the pointer shows its tip.
		local
			w: SW_WINDOW
			root: SW_COLUMN
			l_top, l_bottom: SW_LABEL
		do
			create w.make ("marks", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create root.make
			create l_top.make_ui ("top")
			create l_bottom.make_ui ("bottom")
			root.put (l_top)
			root.put (l_bottom)
			w.set_root (root)
			w.add_reference_mark (l_top, "C4", "Reference box", w.Corner_top_left)
			w.add_reference_mark (l_bottom, "S3", "Lexicon, south", w.Corner_bottom_right)
			w.request_render
			assert_integers_equal ("hidden: no pill answers", 0, w.reference_mark_at (l_top.x.rounded, l_top.y.rounded + 2))
			w.set_reference_marks_shown (True)
			w.request_render
			assert_integers_equal ("top-left pill on the top widget's corner", 1,
				w.reference_mark_at ((l_top.x + 4.0).rounded, (l_top.y + 4.0).rounded))
			assert_integers_equal ("bottom-right pill on the bottom widget's corner", 2,
				w.reference_mark_at ((l_bottom.x + l_bottom.width - 6.0).rounded, (l_bottom.y + l_bottom.height - 4.0).rounded))
			assert_integers_equal ("nothing in the middle of the window", 0, w.reference_mark_at (300, 150))
			w.dispatch (w.Event_window_move, (l_top.x + 4.0).rounded, (l_top.y + 4.0).rounded)
			assert_integers_equal ("pointer on C4 shows its tip", 1, w.hovered_reference_mark)
			w.dispatch (w.Event_window_move, 300, 150)
			assert_integers_equal ("pointer off every pill: no tip", 0, w.hovered_reference_mark)
			w.set_reference_marks_shown (False)
			assert_integers_equal ("hidden again", 0, w.reference_mark_at ((l_top.x + 4.0).rounded, (l_top.y + 4.0).rounded))
		end

	test_status_bar_and_hover_card_spacing_scale
			-- The status bar's end pad is the theme's border_width and its
			-- height the measured font plus padding; the hover card's inset
			-- is border_width. At 2x text all of it doubles.
		local
			w1, w2: SW_WINDOW
			t2: SW_THEME
			b1, b2: SW_STATUS_BAR
			n1, n2: INTEGER
			c: SW_HOVER_CARD
		do
			create w1.make ("s1", 0, 0, 800, 300, create {SW_THEME}.make_light)
			create t2.make_light
			t2.set_text_scale (2.0)
			create w2.make ("s2", 0, 0, 1600, 600, t2)
			create b1.make
			create b2.make
			n1 := b1.add_text ("Links: Default", False)
			n2 := b2.add_text ("Links: Default", False)
			w1.set_root (b1)
			w2.set_root (b2)
			w1.request_render
			w2.request_render
			assert_reals_equal ("the end pad is the theme's border", w1.theme.border_width, b1.section (n1).left - b1.x, 0.000_1)
			assert_reals_equal ("and doubles at 2x", 2.0 * (b1.section (n1).left - b1.x), b2.section (n2).left - b2.x, 0.000_1)
			assert_true ("the bar grows with the text",
				b2.preferred_height (w2.painter, 1000.0) > 1.8 * b1.preferred_height (w1.painter, 1000.0))
			create c.make (create {SW_LABEL}.make_ui ("card"), 200.0)
			w2.show_hover_card (c)
			assert_reals_equal ("the card's inset is the 2x border", 2.0 * 2.0 * w1.theme.border_width,
				w2.hover_card_pw - 200.0, 0.000_1)
		end

feature {NONE} -- GW-11 helpers

	mid (a_section: SW_STATUS_SECTION): INTEGER
			-- The horizontal middle of a placed section.
		do
			Result := (a_section.left + a_section.span / 2.0).truncated_to_integer
		end

feature {NONE} -- GW-27 helpers

	frame_pixel (a_window: SW_WINDOW; a_x, a_y: INTEGER): INTEGER
			-- RGB of the window's last frame at (`a_x', `a_y').
		local
			mp: MANAGED_POINTER
			s: CAIRO_SURFACE
		do
			s := a_window.offscreen
			s.flush.do_nothing
			create mp.share_from_pointer (s.data, s.stride * s.height)
			Result := (mp.read_natural_32 (a_y * s.stride + a_x * 4).bit_and (0xFFFFFF)).to_integer_32
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
