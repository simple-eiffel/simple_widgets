note
	description: "[
		Assault on the Wave 3 indicator septet: badge caption cap,
		avatar initials derivation, segmented and rating semantics
		(clicks via the headless painter), statistic deltas, empty
		state action zone, skeleton draw smoke.
	]"

class
	SW_INDICATOR_ASSAULT

inherit
	TEST_SET_BASE

feature -- Badge

	test_badge_caption_caps
		local
			b: SW_BADGE
		do
			create b.make_count (7)
			assert ("plain count", b.caption.same_string_general ("7"))
			b.set_count (99)
			assert ("at the cap", b.caption.same_string_general ("99"))
			b.set_count (150)
			assert ("past the cap", b.caption.same_string_general ("99+"))
			create b.make_dot
			assert ("dot is dot", b.is_dot)
		end

feature -- Avatar

	test_avatar_initials
		local
			a: SW_AVATAR
		do
			create a.make ("Larry Rix")
			assert ("two words", a.initials.same_string_general ("LR"))
			create a.make ("cher")
			assert ("one word", a.initials.same_string_general ("C"))
			create a.make ("")
			assert ("blank is a question", a.initials.same_string_general ("?"))
			create a.make ("  spaced   out  ")
			assert ("whitespace survived", a.initials.same_string_general ("SO"))
		end

feature -- Segmented

	test_segmented_first_chosen_at_birth
		local
			s: SW_SEGMENTED
		do
			create s.make
			s := s.with_segment ("List").with_segment ("Grid").with_segment ("Cards")
			assert_integers_equal ("first chosen", 1, s.selected_index)
			assert ("text follows", s.selected_text.same_string_general ("List"))
		end

	test_segmented_select_fires_once
		local
			s: SW_SEGMENTED
		do
			create s.make
			s := s.with_segment ("A").with_segment ("B")
			s.set_on_change (agent record_change)
			changes := 0
			s.select_segment (2)
			s.select_segment (2)
			assert_integers_equal ("same selection is silent", 1, changes)
			s.select_segment (1)
			assert_integers_equal ("real move fires", 2, changes)
		end

	test_segmented_click_zones
		local
			s: SW_SEGMENTED
			p: SW_PAINTER
		do
			p := headless_painter
			create s.make
			s := s.with_segment ("Alpha").with_segment ("Beta")
			s.set_bounds (0.0, 0.0, s.preferred_width (p), 32.0)
			s.draw (p)
			if s.handle_click (s.width - 10.0, 16.0) then end
			assert_integers_equal ("last segment hit", 2, s.selected_index)
			if s.handle_click (10.0, 16.0) then end
			assert_integers_equal ("first segment hit", 1, s.selected_index)
		end

feature -- Rating

	test_rating_click_sets_and_clears
		local
			r: SW_RATING
		do
			create r.make (0, 5, agent record_rating)
			r.set_bounds (0.0, 0.0, r.Star_step * 5.0, 28.0)
			rated := -1
			if r.handle_click (r.Star_step * 2.5, 14.0) then end
			assert_integers_equal ("third star rates 3", 3, r.value)
			assert_integers_equal ("agent told 3", 3, rated)
			if r.handle_click (r.Star_step * 2.5, 14.0) then end
			assert_integers_equal ("same star clears", 0, r.value)
			assert_integers_equal ("agent told 0", 0, rated)
		end

	test_rating_star_at_bounds
		local
			r: SW_RATING
		do
			create r.make (2, 5, Void)
			r.set_bounds (10.0, 0.0, r.Star_step * 5.0, 28.0)
			assert_integers_equal ("left of the field", 0, r.star_at (5.0))
			assert_integers_equal ("first star", 1, r.star_at (11.0))
			assert_integers_equal ("clamped right", 5, r.star_at (10.0 + r.Star_step * 50.0))
		end

feature -- Statistic and empty state

	test_statistic_delta
		local
			s: SW_STATISTIC
		do
			create s.make ("tests", "25")
			assert ("no delta yet", not s.has_delta)
			s.set_delta ("+7", True)
			assert ("delta present", s.has_delta)
			assert ("positive", s.is_delta_positive)
			s.set_delta ("-3", False)
			assert ("negative", not s.is_delta_positive)
		end

	test_empty_state_action_zone
		local
			e: SW_EMPTY_STATE
		do
			create e.make ("Nothing", "Really nothing.")
			e.set_bounds (0.0, 0.0, 400.0, 180.0)
			fired := 0
			if e.handle_click (200.0, 140.0) then end
			assert_integers_equal ("no action, no fire", 0, fired)
			e.set_action ("Make one", agent record_fire)
			if e.handle_click (200.0, 140.0) then end
			assert_integers_equal ("action zone fires", 1, fired)
			if e.handle_click (200.0, 30.0) then end
			assert_integers_equal ("glyph zone does not", 1, fired)
		end

feature -- Skeleton

	test_skeleton_draw_smoke
		local
			k: SW_SKELETON
			p: SW_PAINTER
		do
			p := headless_painter
			create k.make (3)
			k.set_bounds (0.0, 0.0, 300.0, k.preferred_height (p, 300.0))
			k.draw (p)
			k.draw (p)
			k.draw (p)
			assert ("shimmer survived three frames", True)
		end

feature -- Scroll area (two-axis)

	test_scroll_wheel_step_programmable
		local
			sa: SW_SCROLL_AREA
			tall: SW_SKELETON
			p2: SW_PAINTER
		do
			p2 := headless_painter
			create sa.make (150.0)
			create tall.make (40)
			sa.set_child (tall)
			sa.set_bounds (0.0, 0.0, 300.0, 150.0)
			sa.arrange (p2)
			assert ("default step", sa.wheel_step = 96.0)
			if sa.handle_wheel (-120) then end
			assert ("one notch, one step", sa.scroll_y = 96.0)
			sa.set_wheel_step (200.0)
			if sa.handle_wheel (-120) then end
			assert ("programmed step", sa.scroll_y = 296.0)
			if sa.handle_wheel (120000) then end
			assert ("top clamped", sa.scroll_y = 0.0)
		end

	test_scroll_two_axis_clamps
		local
			sa: SW_SCROLL_AREA
			wide: SW_IMAGE
			p2: SW_PAINTER
		do
			p2 := headless_painter
			create sa.make (150.0)
				-- the docs logo announces 1408 natural width: wider
				-- than the viewport, so the horizontal axis engages
			create wide.make_from_file ("D:/prod/simple_widgets/docs/images/logo.png")
			sa.set_child (wide)
			sa.set_bounds (0.0, 0.0, 300.0, 150.0)
			sa.arrange (p2)
			assert ("content announces wide", sa.content_width > 300.0)
			assert ("horizontal axis engaged", sa.max_scroll_x > 0.0)
			sa.scroll_to_x (99999.0)
			assert ("right clamped", sa.scroll_x = sa.max_scroll_x)
			sa.scroll_to_x (-50.0)
			assert ("left clamped", sa.scroll_x = 0.0)
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

	changes: INTEGER

	record_change (a_i: INTEGER)
		do
			changes := changes + 1
		end

	rated: INTEGER

	record_rating (a_v: INTEGER)
		do
			rated := a_v
		end

	fired: INTEGER

	record_fire
		do
			fired := fired + 1
		end

end
