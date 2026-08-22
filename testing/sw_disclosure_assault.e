note
	description: "[
		Assault on the disclosure batch: accordion exclusivity law,
		stepper movement clamps and the done-ground-only rule,
		timeline row math, drawer header zones.
	]"

class
	SW_DISCLOSURE_ASSAULT

inherit
	TEST_SET_BASE

feature -- Accordion

	test_accordion_exclusive_law
		local
			a: SW_ACCORDION
		do
			create a.make
			a.add_section ("One", create {SW_SEPARATOR}.make)
			a.add_section ("Two", create {SW_SEPARATOR}.make)
			a.add_section ("Three", create {SW_SEPARATOR}.make)
			assert_integers_equal ("born shut", 0, a.open_count)
			a.toggle_section (1)
			assert ("one open", a.is_section_open (1) and a.open_count = 1)
			a.toggle_section (2)
			assert ("two displaced one", a.is_section_open (2) and not a.is_section_open (1))
			assert_integers_equal ("still exactly one", 1, a.open_count)
			a.toggle_section (2)
			assert_integers_equal ("toggled shut", 0, a.open_count)
		end

	test_accordion_multi_mode
		local
			a: SW_ACCORDION
		do
			create a.make
			a.set_exclusive (False)
			a.add_section ("One", create {SW_SEPARATOR}.make)
			a.add_section ("Two", create {SW_SEPARATOR}.make)
			a.toggle_section (1)
			a.toggle_section (2)
			assert_integers_equal ("both open", 2, a.open_count)
		end

	test_accordion_height_follows_disclosure
		local
			a: SW_ACCORDION
			p: SW_PAINTER
			shut, open_h: REAL_64
		do
			p := headless_painter
			create a.make
			a.add_section ("One", create {SW_SKELETON}.make (4))
			shut := a.preferred_height (p, 400.0)
			a.toggle_section (1)
			open_h := a.preferred_height (p, 400.0)
			assert ("opening grows the accordion", open_h > shut)
		end

feature -- Stepper

	test_stepper_starts_and_clamps
		local
			s: SW_STEPPER
		do
			create s.make
			s := s.with_step ("A").with_step ("B").with_step ("C")
			assert_integers_equal ("starts at one", 1, s.current_step)
			s.advance
			s.advance
			s.advance
			assert_integers_equal ("clamped at last", 3, s.current_step)
			s.retreat
			s.retreat
			s.retreat
			assert_integers_equal ("clamped at first", 1, s.current_step)
		end

	test_stepper_only_done_ground_is_clickable
		local
			s: SW_STEPPER
		do
			create s.make
			s := s.with_step ("A").with_step ("B").with_step ("C")
			s.set_current_step (2)
			s.set_bounds (0.0, 0.0, s.Step_w * 3.0, 58.0)
			if s.handle_click (s.Step_w * 2.5, 20.0) then end
			assert_integers_equal ("the future refused the click", 2, s.current_step)
			if s.handle_click (s.Step_w * 0.5, 20.0) then end
			assert_integers_equal ("done ground welcomed it", 1, s.current_step)
		end

feature -- Timeline

	test_timeline_row_math
		local
			tl: SW_TIMELINE
			p: SW_PAINTER
		do
			p := headless_painter
			create tl.make
			tl.add_entry ("09:00", "Plain", "", {SW_TIMELINE}.Kind_neutral)
			tl.add_entry ("10:00", "Detailed", "with a second line", {SW_TIMELINE}.Kind_success)
			assert_integers_equal ("two entries", 2, tl.entries.count)
			assert ("plain rows are short", tl.row_height (1) = 30.0)
			assert ("detailed rows are tall", tl.row_height (2) = 48.0)
			assert ("height sums the rows", tl.preferred_height (p, 400.0) = 30.0 + 48.0 + 8.0)
		end

feature -- Drawer

	test_drawer_close_zone
		local
			d: SW_DRAWER
		do
			create d.make_titled ("Settings")
			d.set_on_close (agent record_close)
			d.set_bounds (0.0, 0.0, 300.0, 400.0)
			closed := 0
			if d.handle_click (290.0, 14.0) then end
			assert_integers_equal ("the X fires", 1, closed)
			if d.handle_click (100.0, 14.0) then end
			assert_integers_equal ("plain header does not", 1, closed)
		end

feature {NONE} -- Fixture

	headless_painter: SW_PAINTER
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

	closed: INTEGER

	record_close
		do
			closed := closed + 1
		end

end
