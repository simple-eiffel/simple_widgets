note
	description: "[
		Margins and padding: the Vision2 outside/inside model, proven on
		layout arithmetic and on pixels.

		VOCABULARY (EV_BOX, EiffelStudio 25.02,
		library/vision2/interface/widgets/containers/ev_box.e):
		  border_width - "Width of border around container in pixels" (:43)
		  padding      - "Space between children in pixels"           (:54)
		SW_THEME carries both, scaled by `text_scale', plus a third that
		Vision2 has no name for because a NATIVE control owns its own
		margins and a DRAWN one does not: `control_inset', the space
		between a control's edge and its label. Together with the measured
		font it fixes a control's MINIMUM size, the role
		EV_LAYOUT_CONSTANTS.default_button_height plays for Vision2
		(library/vision2/contrib/ev_layout_constants.e:19), except that a
		drawn toolkit can measure instead of converting dialog units.

		THE ANTI-DOUBLE-BORDER RULE. The border is applied ONCE - by
		SW_WINDOW at the root, by SW_DIALOG inside its card - and every
		plain box defaults its own `padding' to 0, exactly as Vision2
		defaults EV_BOX.border_width to 0 and lets the dialog set it
		(EV_BOX_I.Default_border_width = 0; EV_MESSAGE_DIALOG then does
		`vb.set_border_width (10)'). So a tree nested any number deep is
		inset exactly once.

		Every render here is OFFSCREEN, onto a cairo image surface - the
		path that writes evidence/shaped-d015.png. No window is shown.
	]"
	author: "Larry Rix"

class
	SW_MARGINS_ASSAULT

inherit
	TEST_SET_BASE

feature -- The theme's three spacing tokens

	test_theme_carries_border_padding_and_inset
			-- The tokens exist, they are the documented values at 1x, and
			-- every one of them scales with the text.
		local
			th: SW_THEME
		do
			create th.make_light
			assert_reals_equal ("border_width is 12 at 1x", 12.0, th.border_width, 0.000_1)
			assert_reals_equal ("padding is 8 at 1x", 8.0, th.padding, 0.000_1)
			assert_reals_equal ("control_inset is 11 at 1x", 11.0, th.control_inset, 0.000_1)

			th.set_text_scale (2.0)
			assert_reals_equal ("2x text, 2x border", 24.0, th.border_width, 0.000_1)
			assert_reals_equal ("2x text, 2x padding", 16.0, th.padding, 0.000_1)
			assert_reals_equal ("2x text, 2x inside inset", 22.0, th.control_inset, 0.000_1)
			assert_reals_equal ("and 2x rows", 60.0, th.scaled_line_height, 0.000_1)

			th.set_text_scale (1.0)
			th.set_spacing (20.0, 4.0, 5.0)
			assert_reals_equal ("retuned border", 20.0, th.border_width, 0.000_1)
			assert_reals_equal ("retuned padding", 4.0, th.padding, 0.000_1)
			assert_reals_equal ("retuned inset", 5.0, th.control_inset, 0.000_1)
		end

feature -- The outside model: border once, padding between siblings

	test_column_places_children_from_the_theme
			-- A column of three children in a band inset by the border:
			-- the first child starts at the band's own origin, siblings
			-- are separated by the theme's padding, and the last one does
			-- not touch the bottom of the WINDOW - the border is there.
		local
			th: SW_THEME
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			col: SW_COLUMN
			a, b, c: SW_LABEL
			border: REAL_64
		do
			create th.make_light
			create surf.make (400, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			border := th.border_width

			create a.make_ui ("one")
			create b.make_ui ("two")
			create c.make_ui ("three")
			create col.make
			col.put (a)
			col.put (b)
			col.put (c)

				-- what SW_WINDOW does to its root, in one line
			col.set_bounds (border, border, 400.0 - 2.0 * border, 300.0 - 2.0 * border)
			col.arrange (p)

			assert_reals_equal ("first child at (border, border) - x", border, a.x, 0.000_1)
			assert_reals_equal ("first child at (border, border) - y", border, a.y, 0.000_1)
			assert_reals_equal ("second child is one padding below the first",
				a.y + a.height + th.padding, b.y, 0.000_1)
			assert_reals_equal ("and so is the third",
				b.y + b.height + th.padding, c.y, 0.000_1)
			assert_true ("the last child does not touch the window bottom",
				c.y + c.height <= 300.0 - border + 0.000_1)
			assert_true ("and it clears it by the border",
				300.0 - (c.y + c.height) >= border - 0.000_1)
			assert_reals_equal ("the content is inset on the right too",
				400.0 - 2.0 * border, a.width, 0.000_1)
			ctx.destroy
			surf.destroy
		end

	test_nested_column_adds_no_second_border
			-- The whole point. An inner box separates its children and
			-- adds NOTHING at its own edge, so nesting cannot walk the
			-- content inward one border at a time.
		local
			th: SW_THEME
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			outer, inner: SW_COLUMN
			a, b: SW_LABEL
			border: REAL_64
		do
			create th.make_light
			create surf.make (400, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			border := th.border_width

			create a.make_ui ("inner one")
			create b.make_ui ("inner two")
			create inner.make
			inner.put (a)
			inner.put (b)
			create outer.make
			outer.put (inner)

			outer.set_bounds (border, border, 400.0 - 2.0 * border, 300.0 - 2.0 * border)
			outer.arrange (p)

			assert_reals_equal ("a plain box's own border is zero",
				0.0, inner.effective_padding (p), 0.000_1)
			assert_reals_equal ("so the inner box sits flush in the outer one - x",
				outer.x, inner.x, 0.000_1)
			assert_reals_equal ("and the grandchild is still ONE border in - x",
				border, a.x, 0.000_1)
			assert_reals_equal ("and ONE border down - y",
				border, a.y, 0.000_1)
			assert_reals_equal ("siblings inside the nest are one padding apart",
				a.y + a.height + th.padding, b.y, 0.000_1)
			ctx.destroy
			surf.destroy
		end

	test_explicit_spacing_always_wins
			-- Existing applications keep the layout they asked for: an
			-- explicit value is never overwritten by the theme, at any
			-- scale, and zero counts as explicit.
		local
			th: SW_THEME
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			col: SW_COLUMN
			r: SW_ROW
		do
			create th.make_light
			create surf.make (64, 32)
			create ctx.make (surf)
			create p.make (ctx, th)

			create col.make
			assert_false ("nothing explicit out of the box", col.padding_is_explicit)
			assert_false ("nor a gap", col.gap_is_explicit)
			assert_reals_equal ("so the theme decides the gap",
				th.padding, col.effective_gap (p), 0.000_1)

			col := col.with_padding (3.0).with_gap (0.0)
			assert_true ("with_padding marks it explicit", col.padding_is_explicit)
			assert_true ("with_gap marks it explicit too", col.gap_is_explicit)
			assert_reals_equal ("the explicit border stands", 3.0, col.effective_padding (p), 0.000_1)
			assert_reals_equal ("and an explicit ZERO gap stands", 0.0, col.effective_gap (p), 0.000_1)

			th.set_text_scale (2.0)
			assert_reals_equal ("2x text does not move an explicit border",
				3.0, col.effective_padding (p), 0.000_1)
			assert_reals_equal ("nor an explicit gap", 0.0, col.effective_gap (p), 0.000_1)

			create r.make
			assert_reals_equal ("an untouched row takes the theme's padding, scaled",
				th.padding, r.effective_gap (p), 0.000_1)
			r.set_gap (5.0)
			assert_reals_equal ("a set row gap stands", 5.0, r.effective_gap (p), 0.000_1)
			ctx.destroy
			surf.destroy
		end

	test_card_and_group_carry_their_own_border
			-- The surfaces that ARE a frame keep a border of their own,
			-- from the theme, and it scales.
		local
			th: SW_THEME
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			cd: SW_CARD
			gp: SW_GROUP
		do
			create th.make_light
			create surf.make (64, 32)
			create ctx.make (surf)
			create p.make (ctx, th)
			create cd.make
			create gp.make_titled ("Options")
			assert_reals_equal ("a card's border is the inside inset (11 at 1x)",
				11.0, cd.effective_padding (p), 0.000_1)
			assert_reals_equal ("a group's border is the theme's (12 at 1x)",
				12.0, gp.effective_padding (p), 0.000_1)
			th.set_text_scale (2.0)
			assert_reals_equal ("a card's border scales", 22.0, cd.effective_padding (p), 0.000_1)
			assert_reals_equal ("a group's border scales", 24.0, gp.effective_padding (p), 0.000_1)
			ctx.destroy
			surf.destroy
		end

feature -- The inside model: a control is never smaller than its font

	test_control_minimum_comes_from_the_font
			-- The minimum-size law, stated on the painter and measured
			-- from cairo's own font extents: ascent + descent + twice the
			-- inside inset.
		local
			th: SW_THEME
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			ext, one_x, two_x: REAL_64
		do
			create th.make_light
			create surf.make (64, 32)
			create ctx.make (surf)
			create p.make (ctx, th)

			p.font ({SW_PAINTER}.Role_ui, th.size_label, False)
			ext := p.text_extent
			assert_true ("cairo reports a real ascent", p.font_ascent > 0.0)
			assert_true ("and a real descent", p.font_descent > 0.0)
			assert_reals_equal ("the extent is the sum", p.font_ascent + p.font_descent, ext, 0.000_1)
			assert_reals_equal ("min height = extent + 2 insets",
				ext + 2.0 * th.control_inset, p.min_control_height, 0.000_1)
			assert_reals_equal ("min width = advance + 2 insets",
				p.advance ("Sign In") + 2.0 * th.control_inset,
				p.min_control_width ("Sign In"), 0.000_1)
			one_x := p.min_control_height

			th.set_text_scale (2.0)
			p.font ({SW_PAINTER}.Role_ui, th.size_label, False)
			two_x := p.min_control_height
			assert_true ("2x text at least doubles the minimum control height",
				two_x >= 2.0 * one_x - 1.0)
			ctx.destroy
			surf.destroy
		end

	test_controls_track_the_font_at_1x_and_2x
			-- Larry's test: the SAME controls, the SAME code, twice the
			-- text - and they come out about twice as tall, because the
			-- height is measured, not declared. evidence/margins-1x.png
			-- and margins-2x.png are the same scene at both scales.
		local
			h1, h2: TUPLE [btn, box, chk, num, lbl: REAL_64]
		do
			h1 := control_heights (1.0)
			h2 := control_heights (2.0)
			assert_true ("a button doubles", h2.btn >= 1.8 * h1.btn)
			assert_true ("a text box doubles", h2.box >= 1.8 * h1.box)
			assert_true ("a check box doubles", h2.chk >= 1.8 * h1.chk)
			assert_true ("a number box doubles", h2.num >= 1.8 * h1.num)
			assert_true ("a label doubles", h2.lbl >= 1.8 * h1.lbl)
			print ("    1x: button " + h1.btn.out + "  text box " + h1.box.out
				+ "  check " + h1.chk.out + "  number " + h1.num.out
				+ "  label " + h1.lbl.out + "%N")
			print ("    2x: button " + h2.btn.out + "  text box " + h2.box.out
				+ "  check " + h2.chk.out + "  number " + h2.num.out
				+ "  label " + h2.lbl.out + "%N")
		end

	test_label_line_step_equals_the_painted_line
			-- The defect the client agent found: a wrapped label stepped
			-- by `size + 9.0' - the NOMINAL size plus a constant - while
			-- it PAINTED at `size * text_scale'. The two agreed only at
			-- 1x. Now the step is the MEASURED extent plus the theme's
			-- leading, so it tracks the glyphs at any scale.
		local
			th: SW_THEME
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			lbl: SW_LABEL
			step1, step2, ext1, ext2, h1, h2: REAL_64
			lines: INTEGER
		do
			create th.make_light
			create surf.make (200, 120)
			create ctx.make (surf)
			create p.make (ctx, th)
			create lbl.make_body ("Sign in with the same name and password you use on the server itself.")

			p.font (lbl.role, lbl.size, lbl.is_bold)
			ext1 := p.text_extent
			step1 := lbl.line_step (p)
			lines := lbl.wrapped_lines (p, 180.0).count
			h1 := lbl.preferred_height (p, 180.0)
			assert_true ("the step clears the painted glyphs at 1x", step1 >= ext1)
			assert_reals_equal ("the step is extent + the theme's leading",
				ext1 + th.padding, step1, 0.000_1)
			assert_reals_equal ("and the height is exactly N steps",
				lines * step1, h1, 0.000_1)

			th.set_text_scale (2.0)
			p.font (lbl.role, lbl.size, lbl.is_bold)
			ext2 := p.text_extent
			step2 := lbl.line_step (p)
			assert_true ("the glyphs really did grow", ext2 > 1.8 * ext1)
			assert_true ("the step clears the painted glyphs at 2x too", step2 >= ext2)
			assert_true ("so the step grew with them", step2 > 1.8 * step1)
			h2 := lbl.preferred_height (p, 180.0)
			assert_true ("a wrapped label is taller at 2x", h2 > h1)
			print ("    label line step: 1x " + step1.out + " over extent " + ext1.out
				+ " | 2x " + step2.out + " over extent " + ext2.out + "%N")
			ctx.destroy
			surf.destroy
		end

feature -- Evidence (offscreen only - no window is ever shown)

	test_margins_evidence
			-- The reference scene as the toolkit now lays it out, plus
			-- the same scene at 1x and 2x text for the control-size
			-- proof. Image surfaces only.
		do
			render_scene ("margins-after.png", 1.0, True)
			render_scene ("margins-1x.png", 1.0, True)
			render_scene ("margins-2x.png", 2.0, True)
		end

feature {NONE} -- The reference scene

	Scene_w: INTEGER = 560
	Scene_h: INTEGER = 320

	control_heights (a_scale: REAL_64): TUPLE [btn, box, chk, num, lbl: REAL_64]
			-- Natural heights of one of each control at `a_scale' text.
		require
			sane: a_scale >= 0.5 and a_scale <= 3.0
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			bt: SW_BUTTON
			tb: SW_TEXT_BOX
			cb: SW_CHECK_BOX
			nb: SW_NUMBER_BOX
			lb: SW_LABEL
		do
			create th.make_light
			th.set_text_scale (a_scale)
			create surf.make (64, 32)
			create ctx.make (surf)
			create p.make (ctx, th)
			create bt.make ("Sign In", Void)
			create tb.make_single_line ("larry@example.com")
			create cb.make ("Remember me", False, Void)
			create nb.make (1, 0, 100, Void)
			create lb.make_ui ("Server")
			Result := [bt.preferred_height (p, 200.0), tb.preferred_height (p, 200.0),
				cb.preferred_height (p, 200.0), nb.preferred_height (p, 200.0),
				lb.preferred_height (p, 200.0)]
			ctx.destroy
			surf.destroy
		end

	render_scene (a_name: STRING; a_scale: REAL_64; a_bordered: BOOLEAN)
			-- The login-shaped scene at `a_scale' text, inset the way
			-- SW_WINDOW insets its root when `a_bordered', written to
			-- `evidence/<a_name>'.
		require
			named: not a_name.is_empty
			scaled: a_scale >= 0.5 and a_scale <= 3.0
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			root: SW_COLUMN
			r: SW_ROW
			lbl: SW_LABEL
			user, pass: SW_TEXT_BOX
			cancel, ok: SW_BUTTON
			evidence: STRING_32
			wrote: BOOLEAN
			border, iw, ih: REAL_64
		do
			create th.make_light
			th.set_text_scale (a_scale)
			create surf.make (Scene_w, Scene_h)
			create ctx.make (surf)
			create p.make (ctx, th)
			if a_bordered then
				border := th.border_width
			end

			create lbl.make_ui ("Sign in to the server")
			create user.make_single_line ("larry@example.com")
			create pass.make_password ("secret")
			create cancel.make ("Cancel", Void)
			create ok.make_primary ("Sign In", Void)
			create r.make
			r.put (cancel)
			r.put (ok)
			create root.make
			root.put (lbl)
			root.put (user)
			root.put (pass)
			root.put (r)

			p.set_color (th.background)
			p.fill_rect (0.0, 0.0, Scene_w, Scene_h)
			iw := (Scene_w - 2.0 * border).max (0.0)
			ih := (Scene_h - 2.0 * border).max (0.0)
			root.set_bounds (border, border, iw, ih)
			root.arrange (p)
			root.draw (p)
			surf.flush.do_nothing

			assert_reals_equal ("the root is inset by the border - x", border, root.x, 0.000_1)
			assert_reals_equal ("the first child sits at the border - x", border, lbl.x, 0.000_1)
			assert_reals_equal ("and at the border - y", border, lbl.y, 0.000_1)

			print ("    scene " + a_name + ": root (" + root.x.out + "," + root.y.out
				+ ") " + root.width.out + "x" + root.height.out + "%N")
			print ("      first child at (" + lbl.x.out + "," + lbl.y.out
				+ ") h=" + lbl.height.out + "%N")
			print ("      button h=" + ok.height.out + " w=" + ok.width.out
				+ "  row y=" + r.y.out + "  text box h=" + user.height.out + "%N")

			evidence := evidence_path (a_name)
			if not evidence.is_empty then
				wrote := surf.write_png (evidence)
				print ("      written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end
			ctx.destroy
			surf.destroy
		end

feature {NONE} -- Evidence location (mirrors SW_SHAPING_ASSAULT)

	evidence_path (a_name: STRING): STRING_32
			-- `<repo>/evidence/<a_name>', or empty when the repository is
			-- not underfoot - which simply means no file is written.
		require
			name_not_empty: not a_name.is_empty
		local
			env: EXECUTION_ENVIRONMENT
			starts: ARRAYED_LIST [PATH]
			base, marker, dir: PATH
			d: DIRECTORY
			i, step: INTEGER
			found: BOOLEAN
		do
			create Result.make_empty
			create env
			create starts.make (2)
			starts.extend (env.current_working_path)
			starts.extend ((create {PATH}.make_from_string (env.arguments.command_name)).parent)
			from i := 1 until i > starts.count or found loop
				base := starts [i]
				from step := 0 until step > 6 or found loop
					marker := base.extended ("simple_widgets.ecf")
					if file_exists (marker.name) then
						dir := base.extended ("evidence")
						if not directory_exists (dir.name) then
							create d.make_with_path (dir)
							d.recursive_create_dir
						end
						if directory_exists (dir.name) then
							Result := dir.extended (a_name).name.to_string_32
						end
						found := True
					else
						base := base.parent
					end
					step := step + 1
				end
				i := i + 1
			end
		end

	directory_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			d: DIRECTORY
		do
			create d.make_with_name (a_path)
			Result := d.exists
		end

	file_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			f: RAW_FILE
		do
			create f.make_with_name (a_path)
			Result := f.exists
		end

end
