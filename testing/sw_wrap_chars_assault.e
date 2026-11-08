note
	description: "SW_LABEL.set_wrap_chars: wrap at about n characters, even when laid out wider (simple_gui's wrapping_label_grows_taller on Windows)."

class
	SW_WRAP_CHARS_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_label_wraps_at_about_n_characters
			-- The shared test's shape: in a wide column, one label stays one line and the same
			-- text set to 20 characters is at least twice as tall.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			l_one, l_wrapped: SW_LABEL
			l_text: STRING
		do
			l_text := "The quick brown fox jumps over the lazy dog and keeps running far away"
			create w.make ("wrap", 0, 0, 900, 400, create {SW_THEME}.make_light)
			create col.make
			create l_one.make_ui (l_text)
			create l_wrapped.make_ui (l_text)
			l_wrapped.set_wrap_chars (20)
			col.put (l_one)
			col.put (l_wrapped)
			w.set_root (col)
			w.request_render
			assert ("one line has height", l_one.height > 0.0)
			assert ("wrapped is at least twice as tall: " + l_wrapped.height.out + " vs " + l_one.height.out,
				l_wrapped.height >= 2.0 * l_one.height)
			assert ("recorded", l_wrapped.wrap_chars = 20 and l_wrapped.is_wrapping)
			l_wrapped.set_wrap_chars (0)
			assert ("0 goes back to one line", not l_wrapped.is_wrapping)
		end

end
