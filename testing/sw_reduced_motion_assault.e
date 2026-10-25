note
	description: "[
		Assault on GW-14's reduce-motion flag: the skeleton shimmer and the
		indeterminate progress band move from frame to frame, and hold
		still when the theme reduces motion; a window following Windows
		carries the animation setting into the theme it wears, live, the
		contrast theme included.
	]"

class
	SW_REDUCED_MOTION_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Holding still

	test_gw14_skeleton_holds_still
			-- Two frames of a skeleton differ (the shimmer drifts); with the
			-- theme reducing motion they are the same.
		do
			assert_true ("the shimmer moves", frames_differ (create {SW_SKELETON}.make (3), False))
			assert_false ("held still", frames_differ (create {SW_SKELETON}.make (3), True))
		end

	test_gw14_progress_band_holds_still
			-- Two frames of an indeterminate progress bar differ (the band
			-- travels); with the theme reducing motion they are the same, and
			-- the bar still shows it is working.
		local
			p1, p2: SW_PROGRESS
		do
			create p1.make (0.0)
			p1.set_indeterminate_mode (True)
			assert_true ("the band travels", frames_differ (p1, False))
			create p2.make (0.0)
			p2.set_indeterminate_mode (True)
			assert_false ("held still", frames_differ (p2, True))
		end

feature -- Following Windows

	test_gw14_window_follows_the_animation_setting
			-- Following Windows with animation off, the worn theme reduces
			-- motion; the setting turned on (event 57) lets it move; a
			-- contrast theme worn meanwhile keeps the preference.
		local
			w: SW_WINDOW
			fake: SW_TEST_APPEARANCE
		do
			create w.make ("gw14", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create fake
			fake.set_reduces_motion (True)
			fake.set_palette (0x000000, 0xFFFFFF, 0x1AEBFF, 0x000000, 0x000000, 0xFFFF00)
			w.set_system_appearance (fake)
			w.follow_system_theme (create {SW_THEME}.make_light, create {SW_THEME}.make_dark)
			assert_true ("animation off: held still", w.theme.reduces_motion)
			fake.set_reduces_motion (False)
			w.dispatch (w.Event_motion_changed, 0, 0)
			assert_false ("animation on: moving", w.theme.reduces_motion)
			fake.set_reduces_motion (True)
			w.dispatch (w.Event_motion_changed, 1, 0)
			fake.set_high_contrast (True)
			w.dispatch (w.Event_contrast_changed, 1, 0)
			assert_true ("in contrast", w.is_wearing_high_contrast)
			assert_true ("and still held", w.theme.reduces_motion)
		end

feature {NONE} -- Frames

	frames_differ (a_widget: SW_WIDGET; a_still: BOOLEAN): BOOLEAN
			-- Do two consecutive frames of `a_widget' differ, with the theme
			-- reducing motion or not?
		local
			w: SW_WINDOW
			th: SW_THEME
			col: SW_COLUMN
			f1, f2: CAIRO_SURFACE
		do
			create th.make_light
			th.set_reduces_motion (a_still)
			create w.make ("gw14", 0, 0, 400, 200, th)
			w.set_exports_in_screen_theme (True)
			create col.make
			col.add (a_widget).do_nothing
			w.set_root (col)
			w.request_render
			f1 := w.widget_image (a_widget, Void, 1.0)
			f2 := w.widget_image (a_widget, Void, 1.0)
			Result := not same_frames (f1, f2)
			f1.destroy
			f2.destroy
		end

	same_frames (a, b: CAIRO_SURFACE): BOOLEAN
		local
			ma, mb: MANAGED_POINTER
			i, n: INTEGER
		do
			a.flush.do_nothing
			b.flush.do_nothing
			Result := a.width = b.width and a.height = b.height and a.stride = b.stride
			if Result then
				n := a.stride * a.height
				create ma.share_from_pointer (a.data, n)
				create mb.share_from_pointer (b.data, n)
				from i := 0 until i >= n or not Result loop
					Result := ma.read_natural_8 (i) = mb.read_natural_8 (i)
					i := i + 1
				end
			end
		end

end
