note
	description: "[
		Assault on simple_gui 1t (navigation): SW_TABS strip positions (none, top, bottom,
		left, right) and SW_SIDEBAR (headings, first page, the user's acts versus code, keys,
		collapse, icon, badge and letter-circle drawing, tooltip).
	]"

class
	SW_NAVIGATION_ASSAULT

inherit
	SW_TABS_ASSAULT

feature -- Fixtures

	nav_changes: INTEGER
	nav_last: INTEGER
	nav_collapses: INTEGER
	nav_last_collapsed: BOOLEAN

	nav_changed (a_i: INTEGER)
		do
			nav_changes := nav_changes + 1
			nav_last := a_i
		end

	nav_collapse_changed (a_collapsed: BOOLEAN)
		do
			nav_collapses := nav_collapses + 1
			nav_last_collapsed := a_collapsed
		end

	three_tabs (a_position: INTEGER): SW_TABS
			-- Alpha, Beta, Gamma at `a_position', arranged in a 600 by 400 window.
		local
			w: SW_WINDOW
		do
			create Result.make
			across <<"Alpha", "Beta", "Gamma">> as l loop
				Result.add_page (l, create {SW_LABEL}.make_ui (l))
			end
			Result.set_strip_position (a_position)
			create w.make ("tabs", 0, 0, 600, 400, create {SW_THEME}.make_light)
			w.set_root (Result)
			w.request_render
			nav_changes := 0
		ensure
			placed: Result.is_placed
		end

	nav_sidebar: SW_SIDEBAR
			-- Heading Main, Home, Mail, heading More, Settings; Home shown; 600 by 400.
		local
			w: SW_WINDOW
		do
			create Result.make
			Result.add_heading ("Main")
			Result.extend (create {SW_LABEL}.make_ui ("home page"), "Home")
			Result.extend (create {SW_LABEL}.make_ui ("mail page"), "Mail")
			Result.add_heading ("More")
			Result.extend (create {SW_LABEL}.make_ui ("settings page"), "Settings")
			Result.set_on_page_change (agent nav_changed)
			Result.set_on_collapse_change (agent nav_collapse_changed)
			nav_changes := 0
			nav_collapses := 0
			create w.make ("sidebar", 0, 0, 600, 400, create {SW_THEME}.make_light)
			w.set_root (Result)
			w.request_render
		end

	rendered_image (a_widget: SW_WIDGET; a_theme: SW_THEME): CAIRO_SURFACE
		local
			w: SW_WINDOW
		do
			create w.make ("image", 0, 0, 600, 400, a_theme)
			w.set_root (a_widget)
			w.request_render
			Result := w.widget_image (a_widget, a_theme, 1.0)
		end

	pixel_of (a_image: CAIRO_SURFACE; a_widget: SW_WIDGET; a_theme: SW_THEME; a_px, a_py: REAL_64): NATURAL_32
			-- The color at window point (`a_px', `a_py') of an image of `a_widget'.
		local
			m: REAL_64
			w: SW_WINDOW
		do
			create w.make ("margin", 0, 0, 10, 10, a_theme)
			m := w.export_margin (a_theme)
			Result := image_pixel (a_image, (a_px - a_widget.x + m).truncated_to_integer, (a_py - a_widget.y + m).truncated_to_integer)
		end

feature -- Tab strip positions

	test_1t_tabs_top_is_the_default
		local
			tb: SW_TABS
			pg: SW_WIDGET
		do
			tb := three_tabs (1)
			pg := tb.pages.first
			assert_integers_equal ("top by default after setting it", 1, tb.strip_position)
			assert_true ("page under the strip", pg.y >= tb.y + tb.bar_h)
			assert_true ("page fills the width", pg.width = tb.width)
		end

	test_1t_tabs_bottom_puts_the_strip_under_the_page
		local
			tb: SW_TABS
			pg: SW_WIDGET
		do
			tb := three_tabs (2)
			pg := tb.pages.first
			assert_true ("page starts at the top", pg.y = tb.y)
			assert_true ("page ends above the strip", pg.y + pg.height <= tb.strip_top)
			assert_true ("strip at the foot", tb.strip_top + tb.bar_h = tb.y + tb.height)
			assert_integers_equal ("a tab at the foot is hit", 2, tb.tab_index_at (tb.tab_lefts [2] + 3.0, tb.strip_top + 3.0))
			assert_integers_equal ("the top is no tab", 0, tb.tab_index_at (tb.tab_lefts [2] + 3.0, tb.y + 3.0))
			assert_true ("a click at the foot selects and notifies", tb.handle_click (tb.tab_lefts [3] + 3.0, tb.strip_top + 3.0))
			assert_integers_equal ("third", 3, tb.selected_index)
		end

	test_1t_tabs_left_makes_a_column
		local
			tb: SW_TABS
			pg: SW_WIDGET
			l_ok: BOOLEAN
		do
			tb := three_tabs (3)
			tb.set_on_change (agent nav_changed)
			pg := tb.pages.first
			assert_true ("page right of the column", pg.x >= tb.x + tb.column_w)
			assert_true ("page spans the height", pg.height = tb.height and pg.y = tb.y)
			assert_true ("column as wide as the widest tab plus padding", tb.column_w >= tb.tab_widths [1])
			assert_true ("rows stack", tb.tab_top (2) > tb.tab_top (1) and tb.tab_top (3) > tb.tab_top (2))
			assert_true ("tabs share the column", tb.tab_lefts [1] = tb.tab_lefts [3] and tb.tab_widths [1] = tb.column_w)
			assert_integers_equal ("hit testing finds row two", 2, tb.tab_index_at (tb.x + 5.0, tb.tab_center_y (2)))
			assert_integers_equal ("the page is no tab", 0, tb.tab_index_at (pg.x + 5.0, tb.tab_center_y (2)))
			assert_true ("widget_at the column is the tabs", tb.widget_at (tb.x + 5.0, tb.tab_center_y (2)) = tb)
			assert_true ("widget_at the page is the page", tb.widget_at (pg.x + 5.0, pg.y + 5.0) = pg)
			l_ok := tb.handle_click (tb.x + 5.0, tb.tab_center_y (3))
			assert_integers_equal ("a click in the left column selects", 3, tb.selected_index)
			assert_integers_equal ("and notifies once", 1, nav_changes)
			assert_integers_equal ("with the tab", 3, nav_last)
			tb.handle_key (38, False)
			assert_integers_equal ("Up moves to the previous tab", 2, tb.selected_index)
			tb.handle_key (40, False)
			tb.handle_key (40, False)
			assert_integers_equal ("Down stops at the last", 3, tb.selected_index)
			assert_true ("the column takes focus", tb.accepts_focus)
			assert_integers_equal ("one accessible item per tab", 3, tb.accessible_item_count)
		end

	test_1t_tabs_right_makes_a_column_beside_the_page
		local
			tb: SW_TABS
			pg: SW_WIDGET
			l_ok: BOOLEAN
		do
			tb := three_tabs (4)
			pg := tb.pages.first
			assert_true ("page at the left", pg.x = tb.x)
			assert_true ("page ends before the column", pg.x + pg.width <= tb.strip_left)
			assert_true ("column at the right edge", tb.strip_left + tb.column_w = tb.x + tb.width)
			l_ok := tb.handle_click (tb.strip_left + 5.0, tb.tab_center_y (2))
			assert_integers_equal ("a click in the right column selects", 2, tb.selected_index)
		end

	test_1t_tabs_none_takes_no_room
		local
			tb: SW_TABS
			pg: SW_WIDGET
		do
			tb := three_tabs (0)
			pg := tb.pages.first
			assert_true ("page fills the area", pg.x = tb.x and pg.y = tb.y and pg.width = tb.width and pg.height = tb.height)
			assert_true ("no strip height", tb.strip_height = 0.0)
			assert_integers_equal ("no tab is hit", 0, tb.tab_index_at (tb.x + 5.0, tb.y + 5.0))
			assert_false ("a click at the old strip does nothing", tb.handle_click (tb.x + 5.0, tb.y + 5.0))
			assert_integers_equal ("still first", 1, tb.selected_index)
			assert_false ("no focus", tb.accepts_focus)
			assert_integers_equal ("no items", 0, tb.accessible_item_count)
			tb.select_tab (2)
			assert_true ("code switches the page", tb.selected_page = tb.pages.i_th (2))
		end

feature -- Sidebar structure

	test_1t_sidebar_headings_are_not_pages
		local
			sb: SW_SIDEBAR
		do
			sb := nav_sidebar
			assert_integers_equal ("three pages", 3, sb.page_count)
			assert_integers_equal ("five rows", 5, sb.row_count)
			assert_true ("row one is a heading", sb.is_heading_row (1))
			assert_false ("row two is a page", sb.is_heading_row (2))
			assert_strings_equal ("titles skip headings", "Settings", sb.page_title (3))
			assert_integers_equal ("a click on a heading chooses nothing", 0,
				sb.page_at (sb.list_left + 10.0, sb.heading_row_box (1).y + 3.0))
		end

	test_1t_sidebar_first_page_shows
		local
			sb: SW_SIDEBAR
		do
			sb := nav_sidebar
			assert_integers_equal ("first page selected", 1, sb.selected_page)
			assert_true ("it is laid out beside the list", sb.pages.first.x >= sb.x + sb.list_w and sb.pages.first.width > 0.0)
			assert_true ("and the others are not", sb.pages.i_th (2).width = 0.0)
		end

	test_1t_sidebar_user_versus_code_notices
		local
			sb: SW_SIDEBAR
			l_ok: BOOLEAN
			l_box: TUPLE [x, y, w, h: REAL_64]
		do
			sb := nav_sidebar
			sb.select_page (2)
			assert_integers_equal ("code selects quietly", 0, nav_changes)
			assert_integers_equal ("page two", 2, sb.selected_page)
			l_box := sb.page_row_box (3)
			l_ok := sb.handle_click (l_box.x + 10.0, l_box.y + 3.0)
			assert_true ("click handled", l_ok)
			assert_integers_equal ("a click notifies", 1, nav_changes)
			assert_integers_equal ("with the page", 3, nav_last)
			sb.press_page (3)
			assert_integers_equal ("choosing the shown page again says nothing", 1, nav_changes)
			sb.press_page (1)
			assert_integers_equal ("press_page is a click", 2, nav_changes)
			sb.collapse
			sb.expand
			assert_integers_equal ("collapse and expand from code are quiet", 0, nav_collapses)
		end

	test_1t_sidebar_keys_skip_headings
		local
			sb: SW_SIDEBAR
		do
			sb := nav_sidebar
			assert_true ("takes focus", sb.accepts_focus)
			sb.handle_key (40, False)
			assert_integers_equal ("Down moves the cursor to page two", 2, sb.cursor_page)
			assert_integers_equal ("without choosing", 1, sb.selected_page)
			sb.handle_key (40, False)
			assert_integers_equal ("the next stop is page three, past the heading", 3, sb.cursor_page)
			sb.handle_key (40, False)
			assert_integers_equal ("no wrapping", 3, sb.cursor_page)
			assert_integers_equal ("nothing chosen yet", 0, nav_changes)
			sb.handle_key (13, False)
			assert_integers_equal ("Return chooses", 3, sb.selected_page)
			assert_integers_equal ("and notifies", 1, nav_changes)
			sb.handle_key (38, False)
			sb.handle_key (32, False)
			assert_integers_equal ("Up then Space chooses page two", 2, sb.selected_page)
			assert_integers_equal ("notified again", 2, nav_changes)
			assert_integers_equal ("with the page", 2, nav_last)
		end

	test_1t_sidebar_collapse_narrows_and_hides
		local
			sb: SW_SIDEBAR
			l_open_w: REAL_64
			w: SW_WINDOW
		do
			sb := nav_sidebar
			sb.set_collapsible (True)
			create w.make ("sidebar", 0, 0, 600, 400, create {SW_THEME}.make_light)
			w.set_root (sb)
			w.request_render
			l_open_w := sb.list_w
			assert_true ("about 200 units open", (l_open_w - 200.0).abs < 1.0)
			assert_true ("a heading shows", sb.heading_row_box (1).h > 0.0)
			sb.press_collapse_button
			assert_true ("the user's button collapses", sb.is_collapsed)
			assert_integers_equal ("and notifies", 1, nav_collapses)
			assert_true ("saying collapsed", nav_last_collapsed)
			w.request_render
			assert_true ("narrower", sb.list_w < l_open_w / 2.0)
			assert_true ("headings hide", sb.heading_row_box (1).h = 0.0)
			assert_true ("a hidden heading is not hit", sb.row_at (sb.list_left + 5.0, sb.heading_row_box (1).y + 1.0) /= 1)
			assert_true ("the page grew", sb.pages.first.width > 600.0 - l_open_w)
			sb.expand
			w.request_render
			assert_true ("expand restores the width", (sb.list_w - l_open_w).abs < 1.0)
			assert_true ("and the headings", sb.heading_row_box (1).h > 0.0)
			assert_integers_equal ("expand from code is quiet", 1, nav_collapses)
			sb.press_collapse_button
			sb.press_collapse_button
			assert_integers_equal ("two more presses, two more notices", 3, nav_collapses)
			assert_false ("open again", nav_last_collapsed)
		end

	test_1t_sidebar_collapsed_tooltip_names_the_row
		local
			sb: SW_SIDEBAR
			w: SW_WINDOW
			l_box: TUPLE [x, y, w, h: REAL_64]
		do
			sb := nav_sidebar
			sb.set_collapsible (True)
			sb.collapse
			create w.make ("sidebar", 0, 0, 600, 400, create {SW_THEME}.make_light)
			w.set_root (sb)
			w.request_render
			l_box := sb.page_row_box (2)
			sb.set_hover_point (l_box.x + 5.0, l_box.y + 5.0)
			assert_strings_equal ("the hovered title is the tip", "Mail", sb.tooltip)
			assert_true ("hanging beside that row", sb.tooltip_anchor.y = l_box.y and sb.tooltip_anchor.x >= l_box.x + l_box.w)
			sb.expand
			w.request_render
			sb.set_hover_point (sb.list_left + 5.0, sb.page_row_box (2).y + 5.0)
			assert_strings_equal ("open, no tip", "", sb.tooltip)
		end

feature -- Sidebar drawing

	test_1t_sidebar_icon_and_badge_draw
		local
			sb: SW_SIDEBAR
			t: SW_THEME
			l_image: CAIRO_SURFACE
			l_box: TUPLE [x, y, w, h: REAL_64]
			l_inset, l_x, l_y: REAL_64
			l_found: BOOLEAN
		do
			create t.make_light
			sb := nav_sidebar
			sb.set_page_icon (1, "home")
			sb.set_page_badge (2, "3")
			assert_true ("home is a known icon", sb.page_glyph (1) > 0)
			assert_integers_equal ("no icon on page two", 0, sb.page_glyph (2))
			l_image := rendered_image (sb, t)
			l_inset := t.padding / 2.0
				-- the selected row's ground is the accent; an icon marks it with another color
			l_box := sb.page_row_box (1)
			from
				l_x := l_box.x + sb.pad + l_inset
			until
				l_x > l_box.x + sb.pad + l_inset + 16.0 or l_found
			loop
				from
					l_y := l_box.y + 4.0
				until
					l_y > l_box.y + l_box.h - 4.0 or l_found
				loop
					if not is_near (pixel_of (l_image, sb, t, l_x, l_y), t.accent) then
						l_found := True
					end
					l_y := l_y + 1.0
				end
				l_x := l_x + 1.0
			end
			assert_true ("the icon drew over the accent ground", l_found)
				-- page two is not selected: its badge pill is the accent on the quiet list ground
			l_box := sb.page_row_box (2)
			assert_true ("the badge pill draws at the trailing edge",
				is_near (pixel_of (l_image, sb, t, l_box.x + l_box.w - l_inset - sb.pad - 3.0, l_box.y + l_box.h / 2.0), t.accent))
			assert_false ("and the row without a badge has none there",
				is_near (pixel_of (l_image, sb, t, sb.page_row_box (3).x + sb.page_row_box (3).w - l_inset - sb.pad - 3.0, sb.page_row_box (3).y + sb.page_row_box (3).h / 2.0), t.accent))
			assert_true ("the selected row is the accent",
				is_near (pixel_of (l_image, sb, t, sb.list_left + sb.list_w - 12.0, sb.page_row_box (1).y + 3.0), t.accent))
			l_image.destroy
		end

	test_1t_sidebar_collapsed_letter_circle
		local
			sb: SW_SIDEBAR
			t: SW_THEME
			l_image: CAIRO_SURFACE
			l_box: TUPLE [x, y, w, h: REAL_64]
			l_cx, l_cy, l_r: REAL_64
		do
			create t.make_light
			sb := nav_sidebar
			sb.set_page_icon (1, "home")
			sb.collapse
			assert_strings_equal ("the letter of Mail", "M", sb.letter_of (2))
			assert_true ("the circle is about 20 units", (sb.circle_diameter (t) - 20.0).abs < 0.001)
			l_image := rendered_image (sb, t)
			l_box := sb.page_row_box (2)
			l_cx := l_box.x + (l_box.w - 1.0) / 2.0
			l_cy := l_box.y + l_box.h / 2.0
			l_r := sb.circle_diameter (t) / 2.0
			assert_true ("a muted filled circle stands for the page with no icon",
				is_near (pixel_of (l_image, sb, t, l_cx - l_r * 0.8, l_cy), t.ink_muted))
			assert_true ("it is a circle: the corner of its square is the list ground",
				is_near (pixel_of (l_image, sb, t, l_cx - l_r * 0.95, l_cy - l_r * 0.95), t.surface_variant))
			assert_true ("and just outside it is the list ground",
				is_near (pixel_of (l_image, sb, t, l_cx - l_r - 3.0, l_cy), t.surface_variant))
			l_box := sb.page_row_box (1)
			assert_true ("a page with an icon draws no circle",
				not is_near (pixel_of (l_image, sb, t, l_box.x + (l_box.w - 1.0) / 2.0 - l_r * 0.8, l_box.y + l_box.h / 2.0), t.ink_muted))
			l_image.destroy
		end

end
