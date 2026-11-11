note
	description: "[
		1w: SW_WIDGET_STYLE, a widget's own appearance over the theme. Which parts each kind
		of widget shows, what a shown part changes on the surface and in the sizes, that a
		part a widget does not show changes nothing, and when a scroll bar shows by its mode.
		Drawn off screen on the toy text path, so the answers are the same on every platform.
	]"

class
	SW_WIDGET_STYLE_ASSAULT

inherit
	TEST_SET_BASE

feature -- The style

	test_1w_a_style_holds_only_the_parts_it_was_given
		local
			s: SW_WIDGET_STYLE
			i: INTEGER
		do
			create s.make
			assert ("empty when made", s.is_empty)
			from i := {SW_WIDGET_STYLE}.Part_foreground until i > {SW_WIDGET_STYLE}.Part_scroll_bars loop
				assert ("no part " + i.out, not s.has (i))
				i := i + 1
			end
			s.set_background (0xF0E0D0)
			s.set_padding (2.0, 4.0, 6.0, 8.0)
			assert ("no longer empty", not s.is_empty)
			assert ("background held", s.has ({SW_WIDGET_STYLE}.Part_background))
			assert ("padding held", s.has ({SW_WIDGET_STYLE}.Part_padding))
			assert ("foreground not held", not s.has ({SW_WIDGET_STYLE}.Part_foreground))
			assert ("zero is not a part", not s.is_part (0))
			assert ("fourteen is not a part", not s.is_part ({SW_WIDGET_STYLE}.Part_scroll_bars + 1))
		end

feature -- Label

	test_1w_a_label_wears_a_background_and_grows_by_its_padding
		local
			l: SW_LABEL
			s: SW_WIDGET_STYLE
			w0, h0: REAL_64
		do
			open_surface
			create l.make_ui ("Styled")
			w0 := l.preferred_width (painter)
			h0 := l.preferred_height (painter, 200.0)
			create s.make
			s.set_background (0xF0E0D0)
			s.set_padding (2.0, 4.0, 6.0, 8.0)
			l.set_style (s)
			assert ("shows a background", l.shows_style ({SW_WIDGET_STYLE}.Part_background))
			assert ("shows a size", l.shows_style ({SW_WIDGET_STYLE}.Part_size))
			assert ("has no scroll bars to show", not l.shows_style ({SW_WIDGET_STYLE}.Part_scroll_bars))
			assert ("has no placeholder to show", not l.shows_style ({SW_WIDGET_STYLE}.Part_placeholder))
			assert_reals_equal ("wider by start and end", w0 + 12.0, l.preferred_width (painter), 0.001)
			assert_reals_equal ("taller by top and bottom", h0 + 8.0, l.preferred_height (painter, 212.0), 0.001)
			l.set_bounds (10.0, 10.0, 120.0, 40.0)
			l.draw (painter)
			assert ("its background inside its bounds", rgb_at (11, 11) = 0xF0E0D0)
			assert ("the page outside them", rgb_at (5, 5) = 0xFFFFFF)
			l.set_style (Void)
			assert_reals_equal ("back to its own width", w0, l.preferred_width (painter), 0.001)
			close_surface
		end

	test_1w_a_larger_size_makes_a_label_larger
		local
			l: SW_LABEL
			s: SW_WIDGET_STYLE
			w0, h0: REAL_64
		do
			open_surface
			create l.make_ui ("Styled text")
			w0 := l.preferred_width (painter)
			h0 := l.preferred_height (painter, 400.0)
			create s.make
			s.set_size (painter.theme.size_body * 2.0)
			l.set_style (s)
			assert ("wider", l.preferred_width (painter) > w0 * 1.5)
			assert ("taller", l.preferred_height (painter, 400.0) > h0 * 1.5)
			close_surface
		end

feature -- Button

	test_1w_only_a_quiet_button_takes_a_background
		local
			b: SW_BUTTON
			s: SW_WIDGET_STYLE
		do
			open_surface
			create s.make
			s.set_background (0xCC0000)
			create b.make ("Go", Void)
			b.set_style (s)
			assert ("a standard button keeps its own chrome", not b.shows_style ({SW_WIDGET_STYLE}.Part_background))
			assert ("and takes a text color", b.shows_style ({SW_WIDGET_STYLE}.Part_foreground))
			b.set_bounds (10.0, 10.0, 100.0, 40.0)
			b.draw (painter)
			assert ("not red", rgb_at (60, 14) /= 0xCC0000)
			b.set_kind ({SW_BUTTON}.Kind_quiet)
			assert ("a quiet button takes the background", b.shows_style ({SW_WIDGET_STYLE}.Part_background))
			b.draw (painter)
			assert ("red", rgb_at (60, 14) = 0xCC0000)
			b.set_kind ({SW_BUTTON}.Kind_normal)
			assert ("lost with the kind", not b.shows_style ({SW_WIDGET_STYLE}.Part_background))
			close_surface
		end

feature -- Text box

	test_1w_a_text_box_takes_a_ground_a_placeholder_and_a_selection
		local
			f: SW_TEXT_BOX
			s: SW_WIDGET_STYLE
			h0: REAL_64
		do
			open_surface
			create f.make_single_line ("")
			h0 := f.preferred_height (painter, 200.0)
			create s.make
			s.set_background (0x102030)
			s.set_padding (5.0, 5.0, 5.0, 5.0)
			f.set_style (s)
			assert ("placeholder", f.shows_style ({SW_WIDGET_STYLE}.Part_placeholder))
			assert ("selection", f.shows_style ({SW_WIDGET_STYLE}.Part_selection))
			assert ("no scroll bars: the box grows with its text", not f.shows_style ({SW_WIDGET_STYLE}.Part_scroll_bars))
			assert ("taller by its padding", f.preferred_height (painter, 200.0) >= h0 + 10.0 - 0.001)
			f.set_bounds (10.0, 10.0, 200.0, 60.0)
			f.draw (painter)
			assert ("its ground", rgb_at (110, 62) = 0x102030)
			close_surface
		end

feature -- Lists and scroll bars

	test_1w_a_list_takes_a_size_a_selection_and_a_bar_mode_but_no_padding
		local
			l: SW_TEXT_LIST
			s: SW_WIDGET_STYLE
			h0: REAL_64
		do
			open_surface
			create l.make (120.0)
			l.extend ("one")
			l.extend ("two")
			h0 := l.row_height
			assert ("size", l.shows_style ({SW_WIDGET_STYLE}.Part_size))
			assert ("weight", l.shows_style ({SW_WIDGET_STYLE}.Part_weight))
			assert ("selection", l.shows_style ({SW_WIDGET_STYLE}.Part_selection))
			assert ("scroll bars", l.shows_style ({SW_WIDGET_STYLE}.Part_scroll_bars))
			assert ("no padding", not l.shows_style ({SW_WIDGET_STYLE}.Part_padding))
			create s.make
			s.set_size (painter.theme.size_body * 2.0)
			s.set_selection (0x800040)
			s.set_scroll_bars ({SW_WIDGET_STYLE}.Scroll_bars_always)
			l.set_style (s)
			assert_reals_equal ("rows grow with the type", h0 * 2.0, l.row_height, 0.001)
			l.set_style (s)
			assert_reals_equal ("and only once", h0 * 2.0, l.row_height, 0.001)
			l.set_bounds (10.0, 10.0, 200.0, 120.0)
			l.select_row_quietly (1)
			l.draw (painter)
			assert ("the selected row in the style's color", rgb_at (12, 12) = 0x800040)
			assert ("nothing to scroll", not l.bar.is_needed)
			assert ("the bar shows all the same", l.bar.is_shown)
			l.set_style (Void)
			assert_reals_equal ("rows back to their own height", h0, l.row_height, 0.001)
			l.draw (painter)
			assert ("the bar back to the default", not l.bar.is_shown)
			close_surface
		end

	test_1w_a_scroll_bar_shows_by_its_mode
		local
			b: SW_VSCROLLBAR
			th: SW_THEME
		do
			create th.make_light
			create b.make
			b.place (0.0, 0.0, 100.0, 200.0, th)
			b.set_extent (200.0, 100.0)
			assert ("default: hidden with nothing to scroll", not b.is_shown)
			b.set_mode ({SW_WIDGET_STYLE}.Scroll_bars_always)
			assert ("always: shown", b.is_shown)
			assert ("but a press on it scrolls nothing", not b.takes_pointer)
			assert ("so it is not hit", not b.contains (b.track_x + 2.0, 100.0))
			b.set_extent (200.0, 800.0)
			assert ("with something to scroll it is hit", b.contains (b.track_x + 2.0, 100.0))
			b.set_mode ({SW_WIDGET_STYLE}.Scroll_bars_overlay)
			assert ("overlay: shown", b.is_shown)
			assert ("without a track", not b.has_track)
			b.set_mode ({SW_WIDGET_STYLE}.Scroll_bars_hidden)
			assert ("hidden: never shown", not b.is_shown)
			assert ("nor hit", not b.contains (b.track_x + 2.0, 100.0))
			assert ("the content still scrolls", b.max_scroll > 0.0)
			b.set_mode ({SW_WIDGET_STYLE}.Scroll_bars_system)
			assert ("system: shown while there is something to scroll", b.is_shown and b.has_track)
		end

feature -- Containers

	test_1w_a_row_insets_its_content_by_the_padding
		local
			r: SW_ROW
			l: SW_LABEL
			s: SW_WIDGET_STYLE
			w0, h0, x0, y0: REAL_64
		do
			open_surface
			create r.make
			create l.make_ui ("In a row")
			r.put (l)
			w0 := r.preferred_width (painter)
			h0 := r.preferred_height (painter, 300.0)
			r.set_bounds (10.0, 10.0, 300.0, 60.0)
			r.arrange (painter)
			x0 := l.x
			y0 := l.y
			create s.make
			s.set_padding (3.0, 5.0, 3.0, 9.0)
			s.set_background (0x204060)
			r.set_style (s)
			assert ("a container shows no text color", not r.shows_style ({SW_WIDGET_STYLE}.Part_foreground))
			assert_reals_equal ("wider by start and end", w0 + 14.0, r.preferred_width (painter), 0.001)
			assert_reals_equal ("taller by top and bottom", h0 + 6.0, r.preferred_height (painter, 314.0), 0.001)
			r.arrange (painter)
			assert_reals_equal ("the child moves in by the start padding", x0 + 9.0, l.x, 0.001)
			assert_reals_equal ("the row keeps its bounds", 10.0, r.x, 0.0)
			assert_reals_equal ("and its width", 300.0, r.width, 0.0)
			r.draw (painter)
			assert ("the background reaches the row's corner", rgb_at (11, 11) = 0x204060)
			close_surface
		end

feature {NONE} -- Surface

	surface: detachable CAIRO_SURFACE

	context: detachable CAIRO_CONTEXT

	surface_painter: detachable SW_PAINTER

	painter: SW_PAINTER
			-- The painter on the open surface.
		require
			open: attached surface_painter
		do
			check attached surface_painter as al_p then
				Result := al_p
			end
		end

	open_surface
			-- A white page, 320 by 200, under the light theme, with no shaping kit.
		local
			l_surf: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_theme: SW_THEME
		do
			create l_theme.make_light
			create l_surf.make (320, 200)
			create l_ctx.make (l_surf)
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			surface := l_surf
			context := l_ctx
			create surface_painter.make (l_ctx, l_theme)
		ensure
			open: attached surface_painter
		end

	close_surface
		do
			if attached context as al_ctx then
				al_ctx.destroy
			end
			if attached surface as al_surf then
				al_surf.destroy
			end
			context := Void
			surface := Void
			surface_painter := Void
		ensure
			closed: surface_painter = Void
		end

	rgb_at (a_x, a_y: INTEGER): NATURAL_32
			-- The color of the pixel at (`a_x', `a_y') of the open surface, without its alpha.
		require
			open: attached surface
		local
			mp: MANAGED_POINTER
		do
			if attached surface as al_surf then
				al_surf.flush.do_nothing
				create mp.share_from_pointer (al_surf.data, al_surf.stride * al_surf.height)
				Result := mp.read_natural_32 (a_y * al_surf.stride + a_x * 4) & 0xFFFFFF
			end
		end

end
