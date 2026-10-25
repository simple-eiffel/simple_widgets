note
	description: "[
		Assault on GW-16, following Windows high contrast: themes painted
		from the four Windows contrast palettes are readable and keep the
		user's colors; an unreadable custom palette is mended; a window
		following Windows wears the contrast theme while it is on, keeps
		the application's sizes and faces, follows a palette change, lets
		the contrast theme outrank a light/dark flip, and goes back when
		it is off. Scripture in both the black and the white contrast
		palettes (evidence gw16_contrast_black.png, gw16_contrast_white.png).
		Inherits the shaping assault for its scripture fixtures and kit.
	]"

class
	SW_HIGH_CONTRAST_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Themes

	test_gw16_windows_contrast_palettes_are_readable
			-- High Contrast Black, High Contrast White, Desert and Aquatic as
			-- Windows paints them: each makes a readable contrast theme that
			-- keeps the window, its text and the highlight as given.
		do
			palette_gate ("black", 0x000000, 0xFFFFFF, 0x1AEBFF, 0x000000, 0x000000, 0xFFFF00, True)
			palette_gate ("white", 0xFFFFFF, 0x000000, 0x37006E, 0xFFFFFF, 0xFFFFFF, 0x00009F, False)
			palette_gate ("desert", 0xFFFAEF, 0x3D3D3D, 0x903909, 0xFFF5E3, 0xFFFAEF, 0x1C5E75, False)
			palette_gate ("aquatic", 0x202020, 0xFFFFFF, 0x8EE3F0, 0x263B50, 0x202020, 0x75E9FC, True)
		end

	test_gw16_an_unreadable_palette_is_mended
			-- Grey text on a grey window, white text on a pale highlight: the
			-- theme is still readable, with the ink and the text on accent
			-- fills replaced by black or white.
		local
			th: SW_THEME
		do
			create th.make_high_contrast (0x777777, 0x888888, 0xF0F0F0, 0xFFFFFF, 0x777777, 0x808080)
			assert_true ("readable", th.is_readable)
			assert_true ("the ink was replaced", th.ink /= 0x888888)
			assert_true ("and reads at 4.5:1", th.contrast_ratio (th.ink, th.surface) >= 4.5)
			assert_true ("the text on accent fills was replaced", th.ink_on_accent /= 0xFFFFFF)
			assert_true ("a selection ground the ink reads on", th.contrast_ratio (th.ink, th.selection) >= 4.5)
			create th.make_high_contrast (0x777777, 0x000000, 0x7A7A7A, 0xFFFFFF, 0x777777, 0x000000)
			assert_true ("a highlight lost in the window is replaced", th.accent /= 0x7A7A7A)
			assert_true ("the accent shows on the window", th.contrast_ratio (th.accent, th.surface) >= 3.0)
			assert_true ("still readable", th.is_readable)
		end

feature -- Following Windows

	test_gw16_window_follows_high_contrast
			-- Following Windows: off, the light member; switched on (event
			-- 56), the contrast theme with the light member's text scale and
			-- faces, a dark caption on a black window; a palette change
			-- follows; a light/dark flip (event 53) does not unseat it;
			-- switched off, the pair again.
		local
			w: SW_WINDOW
			fake: SW_TEST_APPEARANCE
			l_light: SW_THEME
		do
			create w.make ("gw16", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create fake
			fake.set_palette (0x000000, 0xFFFFFF, 0x1AEBFF, 0x000000, 0x000000, 0xFFFF00)
			w.set_system_appearance (fake)
			create l_light.make_light
			l_light.set_text_scale (1.25)
			l_light.set_families ("Archivo", "Noto Serif", "IBM Plex Mono")
			told := 0
			w.set_on_theme_changed (agent (t: SW_THEME) do told := told + 1 end)
			w.follow_system_theme (l_light, create {SW_THEME}.make_dark)
			assert_true ("off: the light member", w.theme = l_light)
			assert_false ("not contrast", w.is_wearing_high_contrast)
			fake.set_high_contrast (True)
			w.dispatch (w.Event_contrast_changed, 1, 0)
			assert_true ("on: the contrast theme", w.is_wearing_high_contrast)
			assert_true ("painted black", w.theme.surface = 0x000000)
			assert_true ("ink white", w.theme.ink = 0xFFFFFF)
			assert_true ("a dark caption", w.title_bar_is_dark)
			assert_true ("the light member's text scale", w.theme.text_scale = 1.25)
			assert_true ("and its body face", w.theme.family_body.same_string ("Noto Serif"))
			assert_integers_equal ("told twice (light, then contrast)", 2, told)
			fake.set_palette (0xFFFFFF, 0x000000, 0x37006E, 0xFFFFFF, 0xFFFFFF, 0x00009F)
			w.dispatch (w.Event_contrast_changed, 1, 0)
			assert_true ("a palette change follows: white", w.theme.surface = 0xFFFFFF)
			assert_false ("a light caption", w.title_bar_is_dark)
			fake.set_dark (True)
			w.dispatch (w.Event_appearance_changed, 1, 0)
			assert_true ("a light/dark flip does not unseat contrast", w.is_wearing_high_contrast)
			fake.set_high_contrast (False)
			w.dispatch (w.Event_contrast_changed, 0, 0)
			assert_false ("off again", w.is_wearing_high_contrast)
			assert_true ("the dark member, as Windows now asks", w.theme.is_dark)
		end

	test_gw16_following_starts_in_contrast
			-- When following begins while a contrast theme is on, the window
			-- starts in it.
		local
			w: SW_WINDOW
			fake: SW_TEST_APPEARANCE
		do
			create w.make ("gw16", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create fake
			fake.set_palette (0xFFFAEF, 0x3D3D3D, 0x903909, 0xFFF5E3, 0xFFFAEF, 0x1C5E75)
			fake.set_high_contrast (True)
			w.set_system_appearance (fake)
			w.follow_system_theme (create {SW_THEME}.make_light, create {SW_THEME}.make_dark)
			assert_true ("starts in contrast", w.is_wearing_high_contrast)
			assert_true ("Desert's window", w.theme.surface = 0xFFFAEF)
		end

feature -- Scripture in contrast

	test_gw16_contrast_black
		do
			scripture_contrast_gate (0x000000, 0xFFFFFF, 0x1AEBFF, 0x000000, 0x000000, 0xFFFF00, "gw16_contrast_black.png")
		end

	test_gw16_contrast_white
		do
			scripture_contrast_gate (0xFFFFFF, 0x000000, 0x37006E, 0xFFFFFF, 0xFFFFFF, 0x00009F, "gw16_contrast_white.png")
		end

feature {NONE} -- Fixtures

	told: INTEGER

	palette_gate (a_name: STRING; a_window, a_text, a_highlight, a_highlight_text, a_face, a_link: NATURAL_32; a_dark: BOOLEAN)
		local
			th: SW_THEME
		do
			create th.make_high_contrast (a_window, a_text, a_highlight, a_highlight_text, a_face, a_link)
			assert_true (a_name + ": readable", th.is_readable)
			assert_true (a_name + ": contrast", th.is_high_contrast)
			assert_true (a_name + ": dark as its window", th.is_dark = a_dark)
			assert_true (a_name + ": the window kept", th.surface = a_window and th.background = a_window)
			assert_true (a_name + ": its text kept", th.ink = a_text and th.ink_muted = a_text)
			assert_true (a_name + ": the highlight kept", th.accent = a_highlight)
			assert_true (a_name + ": outlines in the ink", th.outline = a_text)
		end

	scripture_contrast_gate (a_window, a_text, a_highlight, a_highlight_text, a_face, a_link: NATURAL_32; a_evidence: STRING)
			-- Tabs, pointed Hebrew, polytonic Greek, a mixed line and a
			-- primary button in a contrast palette: shaped with nothing
			-- skipped, written as evidence.
		local
			w: SW_WINDOW
			th: SW_THEME
			kit: SW_SHAPING
			tb: SW_TABS
			col: SW_COLUMN
			path: STRING_32
		do
			create th.make_high_contrast (a_window, a_text, a_highlight, a_highlight_text, a_face, a_link)
			create w.make ("gw16", 0, 0, 900, 300, th)
			kit := gw03_kit (th)
			w.set_shaping (kit)
			create col.make
			col.add (create {SW_LABEL}.make_body (genesis_1_1_wlc)).do_nothing
			col.add (create {SW_LABEL}.make_body (john_1_1_wh_nfc)).do_nothing
			col.add (create {SW_LABEL}.make_body (mixed_english_hebrew)).do_nothing
			col.add (create {SW_BUTTON}.make_primary ("Search", Void)).do_nothing
			create tb.make
			tb.set_closable_by_default (True)
			tb.add_page ({STRING_32} "Genesis 1", col)
			tb.add_page (genesis_first_word, create {SW_SPACER}.make)
			tb.add_page ({STRING_32} "John 1", create {SW_SPACER}.make)
			w.set_root (tb)
			w.request_render
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
