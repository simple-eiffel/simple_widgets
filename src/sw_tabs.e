note
	description: "[
		A notebook: a drawn tab bar over one visible page. Pages are
		(label, widget) pairs; selecting a tab swaps which page is
		laid out, drawn and hit-tested. The change agent fires with
		the new index.

		GW-15 (many Bible tabs):
		- CLOSABLE: a tab marked closable shows a close box; a press
		  and release on it asks `request_close', which consults the
		  close guard (unsaved notes) and then `close_tab'. Closing
		  the selected tab selects its right neighbor, else its left.
		- REORDERABLE: drag a tab sideways and it changes places with
		  each neighbor whose middle the pointer crosses (`move_tab').
		- OVERFLOW: tabs keep their natural widths (capped); when they
		  outrun the bar, the strip scrolls so the selected tab is
		  always whole, and a chevron at the right end opens a menu of
		  every tab.
		- KEYS: `select_next', `select_previous' (wrapping) and
		  `close_selected' are for the application's accelerators
		  (Ctrl+Tab, Ctrl+Shift+Tab, Ctrl+W). The wheel over the strip
		  steps the selection.
		The tab boxes are SW_TAB_STRIP's (SCROLL policy), shared with
		SW_DOCK_ZONE. Spacing comes from the theme tokens.
	]"
	scan_9: "[
		2026-10-25, the design scan since 760abf1. A note for the future
		self: (1) the width cap was twenty `control_inset's, and a theme
		may set that inset to 0, which gave every tab no width - the cap
		is thirteen label-font boxes now (about the same 220 pixels at
		1x) and every natural width is at least one pixel; (2) the first
		placed tab never drops below one pixel, so `arrange''s
		`selected_shown' holds in a bar too narrow for anything; (3)
		`close_tab' no longer promises the closed page has no parent,
		because `on_close' may adopt it elsewhere - it lets go BEFORE
		the call; (4) a swap involving a tab scrolled off the strip
		forgets the placement instead of inventing a gap. Guarded by the
		scan9_* tests in SW_TABS_ASSAULT.
	]"

class
	SW_TABS

inherit
	SW_WIDGET
		redefine
			sub_widgets,
			arrange, widget_at, handle_click, wants_hover_point,
			handle_drag, handle_release, handle_wheel,
			accessible_role, accessible_value, accessible_children,
			accessible_item_count, publish_accessible_items,
			responds_to_pick, pick_hover, pick_tick, pick_click, pick_ended,
			accepts_focus, handle_key
		end

	SW_TAB_STRIP
		redefine
			tab_index_at
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create labels.make (4)
			create pages.make (4)
			create closables.make (4)
			selected_index := 0
			bar_h := 40.0
			tab_pad := 11.0
			tab_gap := 4.0
			close_size := 17.0
			chevron_w := 32.0
			strip_position := Position_top
			column_w := 100.0
		end

feature -- Access

	labels: ARRAYED_LIST [STRING_32]
	pages: ARRAYED_LIST [SW_WIDGET]

	selected_index: INTEGER
			-- 1-based selected page; 0 only while empty. Closing or moving
			-- an EARLIER tab shifts it without firing `on_change' - the
			-- selected page is the same page.

	on_change: detachable PROCEDURE [INTEGER]
			-- Fires when a different page becomes the selected one.

	on_close: detachable PROCEDURE [SW_WIDGET]
			-- Fires after a tab is closed, with its page.

	on_move: detachable PROCEDURE [INTEGER, INTEGER]
			-- Fires after a tab moves, with its old and new places.

	close_guard: detachable FUNCTION [INTEGER, BOOLEAN]
			-- Asked by `request_close' whether tab i may close (an unsaved
			-- note says no); Void lets every closable tab close.

	selected_page: detachable SW_WIDGET
		do
			if selected_index >= 1 and selected_index <= pages.count then
				Result := pages.i_th (selected_index)
			end
		end

	is_tab_closable (a_i: INTEGER): BOOLEAN
			-- Does tab `a_i' show a close box?
		require
			in_range: a_i >= 1 and a_i <= pages.count
		do
			Result := closables.i_th (a_i)
		end

	closable_by_default: BOOLEAN
			-- Are tabs added from now on closable?

	first_visible: INTEGER
			-- The first tab on the strip (the strip scrolls to keep the
			-- selected tab whole); 0 only while empty.

	has_overflow: BOOLEAN
			-- Did the latest arrange find more tabs than the bar holds? The
			-- chevron then shows.

	is_dragging: BOOLEAN
			-- Is a tab being dragged to a new place?

feature -- Strip position (simple_gui 1t)

	Position_none: INTEGER = 0
			-- No strip: the page fills the whole area and changes only from code.

	Position_top: INTEGER = 1
			-- The strip above the page (the default).

	Position_bottom: INTEGER = 2
			-- The strip under the page.

	Position_left: INTEGER = 3
			-- A column of tabs left of the page, each a horizontal row.

	Position_right: INTEGER = 4
			-- A column of tabs right of the page.

	strip_position: INTEGER
			-- Where the strip stands: one of the `Position_' constants.

	strip_takes_focus: BOOLEAN
			-- Does a click on the strip give it the keyboard focus (arrows then move
			-- between tabs)? Off for the top strip, which older programs drive with
			-- accelerators and which stays out of the Tab ring; `set_strip_position'
			-- turns it on for the other positions.

	is_vertical: BOOLEAN
			-- Is the strip a column beside the page?
		do
			Result := strip_position = Position_left or strip_position = Position_right
		end

	has_strip: BOOLEAN
			-- Is a strip drawn and hit-tested?
		do
			Result := strip_position /= Position_none
		end

	column_w: REAL_64
			-- The column's width in a left or right position: the widest tab (set by arrange).

	strip_left: REAL_64
			-- The strip's left edge.
		do
			if strip_position = Position_right then
				Result := x + width - column_w
			else
				Result := x
			end
		end

	strip_span: REAL_64
			-- The strip's width.
		do
			if is_vertical then
				Result := column_w
			else
				Result := width
			end
		end

	tab_top (a_i: INTEGER): REAL_64
			-- The top of tab `a_i''s box: the strip's top in a row, the row's own in a column.
		do
			if is_vertical then
				Result := y + (a_i - 1) * (bar_h + tab_gap)
			else
				Result := strip_top
			end
		end

	tab_center_y (a_i: INTEGER): REAL_64
			-- The middle of tab `a_i''s box, top to bottom.
		do
			Result := tab_top (a_i) + bar_h / 2.0
		end

	on_strip (a_px, a_py: REAL_64): BOOLEAN
			-- Is the point on the strip's band (a tab, or the room between tabs)?
		do
			Result := has_strip and then contains (a_px, a_py)
				and then a_px >= strip_left and then a_px < strip_left + strip_span
				and then a_py >= strip_top and then a_py < strip_top + strip_height
		end

	tab_index_at (a_px, a_py: REAL_64): INTEGER
			-- As the strip's, and in a column by the row under the point.
		local
			k: INTEGER
			l_pitch, l_into: REAL_64
		do
			if is_vertical then
				if is_placed and then on_strip (a_px, a_py) then
					l_pitch := bar_h + tab_gap
					k := ((a_py - y) / l_pitch).floor + 1
					l_into := (a_py - y) - (k - 1) * l_pitch
					if k >= 1 and then k <= labels.count and then l_into < bar_h and then tab_widths.i_th (k) > 0.0 then
						Result := k
					end
				end
			else
				Result := Precursor (a_px, a_py)
			end
		end

feature -- Measurement

	bar_h: REAL_64
			-- The tab bar's height: the label font's box plus the theme's
			-- `control_inset' above and below (set by measuring, so it grows
			-- with `text_scale').

	tab_pad: REAL_64
			-- Either side of a label: the theme's `control_inset'.

	tab_gap: REAL_64
			-- Between tabs: half the theme's `padding'.

	close_size: REAL_64
			-- A close box's side: the label font's box.

	chevron_w: REAL_64
			-- The overflow chevron's width.

	strip_top: REAL_64
			-- The strip's top edge: the widget's top, or `bar_h' above its foot at the bottom.
		do
			if strip_position = Position_bottom then
				Result := y + height - bar_h
			else
				Result := y
			end
		end

	strip_height: REAL_64
			-- The strip's height: a row's, the whole column's, or nothing without a strip.
		do
			if strip_position = Position_none then
				Result := 0.0
			elseif is_vertical then
				Result := height
			else
				Result := bar_h
			end
		end

	is_placed: BOOLEAN
			-- Do the tab boxes match the tabs (an arrange has run since the
			-- tabs last changed in number)?
		do
			Result := tab_lefts.count = labels.count
		end

	close_box_at (a_px, a_py: REAL_64): INTEGER
			-- The closable tab whose close box holds the point; 0 elsewhere.
		local
			k: INTEGER
			l_cx, l_cy: REAL_64
		do
			if is_placed then
				k := tab_index_at (a_px, a_py)
				if k > 0 and then closables.i_th (k) then
					l_cx := close_center_x (k)
					l_cy := tab_center_y (k)
					if (a_px - l_cx).abs <= close_size / 2.0 and then (a_py - l_cy).abs <= close_size / 2.0 then
						Result := k
					end
				end
			end
		ensure
			closable: Result > 0 implies is_tab_closable (Result)
		end

	is_on_chevron (a_px, a_py: REAL_64): BOOLEAN
			-- Is the point on the overflow chevron?
		do
			Result := has_overflow and then a_py >= strip_top and then a_py < strip_top + bar_h
				and then a_px >= chevron_left and then a_px <= chevron_left + chevron_w
		end

	overflow_menu: SW_MENU
			-- Every tab, in order; picking one selects it.
		local
			i: INTEGER
			l_hint: STRING_32
		do
			create Result.make
			from
				i := 1
			until
				i > labels.count
			loop
				if i = selected_index then
					l_hint := {STRING_32} "shown"
				else
					create l_hint.make_empty
				end
				Result.add_item (menu_safe (labels.i_th (i)), l_hint, True, agent select_tab (i))
				i := i + 1
			end
		ensure
			one_item_per_tab: Result.items.count = labels.count
		end

	page_glyphs: HASH_TABLE [INTEGER, INTEGER]
			-- A glyph drawn before a tab's label, by tab number (simple_gui 1n).
		attribute
			create Result.make (0)
		end

	page_badges: HASH_TABLE [STRING_32, INTEGER]
			-- A short text in a small red bubble after a tab's label, by tab number (simple_gui 1n).
		attribute
			create Result.make (0)
		end

	Tab_glyph_room: REAL_64 = 18.0

feature -- Element change

	set_page_glyph (i: INTEGER; a_glyph: INTEGER)
			-- Draw `a_glyph' before tab `i''s label (0 removes it).
		require
			valid: i >= 1 and i <= labels.count
			known: a_glyph >= 0 and a_glyph <= {SW_PAINTER}.Glyph_last
		do
			if a_glyph = 0 then
				page_glyphs.remove (i)
			else
				page_glyphs.force (a_glyph, i)
			end
		end

	set_page_badge (i: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Show `a_text' as a badge after tab `i''s label (empty removes it).
		require
			valid: i >= 1 and i <= labels.count
			short: a_text.count <= 8
		do
			if a_text.is_empty then
				page_badges.remove (i)
			else
				page_badges.force (a_text.to_string_32, i)
			end
		end

	set_strip_position (a_position: INTEGER)
			-- Put the strip at `a_position' (a `Position_' constant); `Position_none' hides it and
			-- the page takes the whole area. Left and right show a column of tabs; the tab
			-- being dragged, if any, is let go (columns do not reorder by drag).
		require
			known: a_position >= Position_none and a_position <= Position_right
		do
			strip_position := a_position
			strip_takes_focus := a_position >= Position_bottom
			forget_placement
			end_drag
			has_overflow := False
		ensure
			set: strip_position = a_position
			unplaced: not is_placed or labels.is_empty
		end

	set_strip_takes_focus (a_on: BOOLEAN)
			-- Let a click on the strip take the keyboard focus (or not).
		do
			strip_takes_focus := a_on
		ensure
			set: strip_takes_focus = a_on
		end

	add_page (a_label: READABLE_STRING_GENERAL; a_page: SW_WIDGET)
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			labels.extend (l)
			pages.extend (a_page)
			builders.extend (Void)
			closables.extend (closable_by_default)
			a_page.set_parent (Current)
			if selected_index = 0 then
				selected_index := 1
				first_visible := 1
			end
		ensure
			grew: pages.count = old pages.count + 1
			adopted: a_page.parent = Current
			something_selected: selected_index >= 1
			closable_as_default: is_tab_closable (pages.count) = closable_by_default
		end

	add_lazy_page (a_label: READABLE_STRING_GENERAL; a_builder: FUNCTION [SW_WIDGET])
			-- The page is BUILT on first selection (menus-style):
			-- until then a weightless spacer stands in. Ten heavy
			-- tabs cost one page's construction at startup.
		local
			l: STRING_32
			stub: SW_SPACER
		do
			create l.make_from_string_general (a_label)
			labels.extend (l)
			create stub.make
			stub.set_parent (Current)
			pages.extend (stub)
			builders.extend (a_builder)
			closables.extend (closable_by_default)
			if selected_index = 0 then
				selected_index := 1
				first_visible := 1
			end
		ensure
			grew: pages.count = old pages.count + 1
			armed: builders.last = a_builder
			something_selected: selected_index >= 1
			closable_as_default: is_tab_closable (pages.count) = closable_by_default
		end

	builders: ARRAYED_LIST [detachable FUNCTION [SW_WIDGET]]
			-- Parallel to `pages': the pending constructor, consumed
			-- by `ensure_built' on first selection; Void = eager.
		attribute
			create Result.make (4)
		end

	ensure_built (a_i: INTEGER)
			-- Materialize page `a_i' if a builder is still pending.
		require
			in_range: a_i >= 1 and a_i <= pages.count
		local
			pg: SW_WIDGET
		do
			if attached builders.i_th (a_i) as b then
				pg := b.item ([])
				pg.set_parent (Current)
				pages.put_i_th (pg, a_i)
				builders.put_i_th (Void, a_i)
			end
		ensure
			built: builders.i_th (a_i) = Void
		end

	select_tab (a_i: INTEGER)
		require
			in_range: a_i >= 1 and a_i <= pages.count
		do
			ensure_built (a_i)
			if a_i /= selected_index then
				selected_index := a_i
				if attached on_change as a then
					a.call (a_i)
				end
			end
		ensure
			selected: selected_index = a_i
		end

	select_next
			-- The tab after the selected one; after the last, the first.
		require
			not_empty: not pages.is_empty
		do
			select_tab (selected_index \\ pages.count + 1)
		end

	select_previous
			-- The tab before the selected one; before the first, the last.
		require
			not_empty: not pages.is_empty
		do
			if selected_index <= 1 then
				select_tab (pages.count)
			else
				select_tab (selected_index - 1)
			end
		end

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

	set_on_close (a_action: PROCEDURE [SW_WIDGET])
		do
			on_close := a_action
		ensure
			set: on_close = a_action
		end

	set_on_move (a_action: PROCEDURE [INTEGER, INTEGER])
		do
			on_move := a_action
		ensure
			set: on_move = a_action
		end

	set_close_guard (a_guard: FUNCTION [INTEGER, BOOLEAN])
		do
			close_guard := a_guard
		ensure
			set: close_guard = a_guard
		end

	set_closable_by_default (a_on: BOOLEAN)
			-- Make tabs added from now on closable, or not.
		do
			closable_by_default := a_on
		ensure
			set: closable_by_default = a_on
		end

	set_tab_closable (a_i: INTEGER; a_on: BOOLEAN)
			-- Give tab `a_i' a close box, or take it away (a pinned tab).
		require
			in_range: a_i >= 1 and a_i <= pages.count
		do
			closables.put_i_th (a_on, a_i)
		ensure
			set: is_tab_closable (a_i) = a_on
		end

feature -- Closing and moving

	request_close (a_i: INTEGER)
			-- The user asks to close tab `a_i': it closes if it is closable
			-- and the close guard agrees.
		require
			in_range: a_i >= 1 and a_i <= pages.count
		do
			if closables.i_th (a_i) and then (not attached close_guard as g or else g.item ([a_i])) then
				close_tab (a_i)
			end
		end

	close_selected
			-- Ctrl+W: ask to close the selected tab.
		do
			if selected_index >= 1 then
				request_close (selected_index)
			end
		end

	close_tab (a_i: INTEGER)
			-- Remove tab `a_i' and its page. If it was selected, its right
			-- neighbor is selected, else its left.
		require
			in_range: a_i >= 1 and a_i <= pages.count
		local
			l_page: SW_WIDGET
			l_was_selected: BOOLEAN
		do
			l_page := pages.i_th (a_i)
			l_was_selected := a_i = selected_index
			labels.go_i_th (a_i)
			labels.remove
			pages.go_i_th (a_i)
			pages.remove
			builders.go_i_th (a_i)
			builders.remove
			closables.go_i_th (a_i)
			closables.remove
			forget_placement
			end_drag
			if pages.is_empty then
				selected_index := 0
				first_visible := 0
			else
				if l_was_selected then
					selected_index := a_i.min (pages.count)
					ensure_built (selected_index)
				elseif a_i < selected_index then
					selected_index := selected_index - 1
				end
				first_visible := first_visible.min (pages.count).max (1)
			end
			l_page.set_parent (Void)
			if attached on_close as c then
				c.call (l_page)
			end
			if l_was_selected and then selected_index >= 1 and then attached on_change as a then
				a.call (selected_index)
			end
		ensure
			shrank: pages.count = old pages.count - 1
			others_keep_their_selection: old selected_index /= a_i implies selected_page = old selected_page
			neighbor_selected: (old selected_index = a_i and not pages.is_empty) implies selected_index = a_i.min (pages.count)
		end

	move_tab (a_from, a_to: INTEGER)
			-- Move tab `a_from' to place `a_to'; the tabs between shift one
			-- place. The selected page stays selected.
		require
			from_in_range: a_from >= 1 and a_from <= pages.count
			to_in_range: a_to >= 1 and a_to <= pages.count
		local
			i: INTEGER
		do
			if a_from < a_to then
				from
					i := a_from
				until
					i = a_to
				loop
					swap_with_next (i)
					i := i + 1
				end
			else
				from
					i := a_from - 1
				until
					i < a_to
				loop
					swap_with_next (i)
					i := i - 1
				end
			end
			if a_from /= a_to and then attached on_move as m then
				m.call (a_from, a_to)
			end
		ensure
			same_count: pages.count = old pages.count
			moved: pages.i_th (a_to) = old pages.i_th (a_from)
			selection_follows: selected_page = old selected_page
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (pages.count)
			across
				pages as pg
			loop
				Result.extend (pg)
			end
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			l_col: REAL_64
		do
			measure (a_p)
			if is_vertical then
				l_col := column_width (a_p, a_width)
				Result := labels.count * (bar_h + tab_gap)
				if attached selected_page as pg then
					Result := Result.max (pg.slot_height (pg.preferred_height (a_p, (a_width - l_col - 8.0).max (1.0))))
				end
			else
				if has_strip then
					Result := bar_h + 8.0
				end
				if attached selected_page as pg then
					Result := Result + pg.slot_height (pg.preferred_height (a_p, a_width))
				end
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Measure, place the tabs (scrolled so the selected one is
			-- whole, in a row; stacked, in a column; none without a strip),
			-- then lay out the selected page beside or under the strip.
		local
			l_naturals: ARRAYED_LIST [REAL_64]
			l_room, l_px, l_py, l_pw, l_ph: REAL_64
			i: INTEGER
		do
			measure (a_p)
			l_naturals := natural_widths (a_p)
			has_overflow := False
			l_px := x
			l_py := y
			l_pw := width
			l_ph := height
			inspect strip_position
			when 0 then
				tab_lefts.wipe_out
				tab_widths.wipe_out
				from i := 1 until i > l_naturals.count loop
					tab_lefts.extend (x)
					tab_widths.extend (0.0)
					i := i + 1
				end
				last_placed := 0
			when 3, 4 then
				column_w := column_width (a_p, width)
				tab_lefts.wipe_out
				tab_widths.wipe_out
				from i := 1 until i > l_naturals.count loop
					tab_lefts.extend (strip_left)
					tab_widths.extend (column_w)
					i := i + 1
				end
				last_placed := l_naturals.count
				l_pw := (width - column_w - 8.0).max (0.0)
				if strip_position = Position_left then
					l_px := x + column_w + 8.0
				end
			else
				l_room := (width - 2.0).max (0.0)
				has_overflow := not l_naturals.is_empty and then run_width (l_naturals, 1, l_naturals.count, tab_gap) > l_room
				if has_overflow then
					l_room := (l_room - chevron_w - tab_gap).max (0.0)
				end
				if not l_naturals.is_empty then
					first_visible := first_showing (l_naturals, l_room, tab_gap, first_visible.max (1), selected_index)
				end
				place_tabs_scrolling (l_naturals, x, l_room, tab_gap, first_visible)
				if mirrors_layout then
					mirror_tab_boxes
				end
				l_ph := (height - bar_h - 8.0).max (0.0)
				if strip_position = Position_top then
					l_py := y + bar_h + 8.0
				end
			end
			if attached selected_page as pg then
				pg.set_bounds (l_px, l_py, l_pw, l_ph)
				pg.arrange (a_p)
			end
		ensure then
			placed: is_placed
			selected_shown: (selected_index >= 1 and has_strip) implies is_tab_shown (selected_index)
		end

	column_width (a_p: SW_PAINTER; a_room: REAL_64): REAL_64
			-- The column's width: the widest tab, at most half of `a_room', at least one pixel.
		local
			l_naturals: ARRAYED_LIST [REAL_64]
		do
			l_naturals := natural_widths (a_p)
			Result := 1.0
			across l_naturals as n loop
				Result := Result.max (n)
			end
			Result := Result.min ((a_room / 2.0).max (1.0))
		ensure
			positive: Result >= 1.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tx, tw, l_label_w, l_text_x: REAL_64
			i: INTEGER
			l_ink: NATURAL_32
		do
			t := a_p.theme
			inspect strip_position
			when 1 then
				a_p.hline (x, y + bar_h - 1.0, width)
			when 2 then
				a_p.hline (x, strip_top, width)
			when 3 then
				a_p.vline (x + column_w - 1.0, y, height)
			when 4 then
				a_p.vline (strip_left, y, height)
			else
			end
			label_font (a_p)
			if is_placed then
				from
					i := 1
				until
					i > labels.count
				loop
					tw := tab_widths.i_th (i)
					if tw > 0.0 then
						tx := tab_lefts.i_th (i)
						if strip_position = Position_top then
							l_ink := draw_tab_ground (a_p, i, i = selected_index,
								shows_hover and then hover_py < y + bar_h and then hover_px >= tx and then hover_px <= tx + tw)
						else
							l_ink := draw_edge_ground (a_p, i, i = selected_index,
								shows_hover and then tab_index_at (hover_px, hover_py) = i)
						end
						if is_focused and then i = selected_index then
							a_p.set_color (t.accent)
							a_p.rrect_stroke (tx + 0.5, tab_top (i) + 0.5, tw - 1.0, bar_h - 1.0, t.radius)
							a_p.set_color (l_ink)
						end
						if (is_dragging and then i = drag_index) or else i = spring_tab then
								-- 0.55.0: also the tab a pick rests on
							draw_tab_outline (a_p, i)
						end
						a_p.set_color (l_ink)
						l_label_w := (tw - 2.0 * tab_pad).max (1.0)
						if closables.i_th (i) then
							l_label_w := (l_label_w - close_size - tab_pad / 2.0).max (1.0)
						end
						a_p.push_clip (label_left (i), tab_top (i), l_label_w, bar_h)
						l_text_x := label_left (i)
						if page_glyphs.has (i) then
							a_p.glyph (page_glyphs.item (i), l_text_x + 7.0, tab_center_y (i), 13.0)
							l_text_x := l_text_x + Tab_glyph_room
						end
						a_p.text (l_text_x, tab_top (i) + (bar_h - a_p.text_extent) / 2.0 + a_p.font_ascent, labels.i_th (i))
						if attached page_badges.item (i) as al_badge then
							l_text_x := l_text_x + a_p.advance (labels.i_th (i)) + 4.0
							a_p.set_color (0xE01B24)
							a_p.rrect_fill (l_text_x, tab_center_y (i) - 8.0, a_p.advance (al_badge) + 10.0, 16.0, 8.0)
							a_p.set_color (0xFFFFFF)
							a_p.text (l_text_x + 5.0, tab_top (i) + (bar_h - a_p.text_extent) / 2.0 + a_p.font_ascent, al_badge)
							a_p.set_color (l_ink)
						end
						a_p.pop_clip
						if closables.i_th (i) then
							draw_close_box (a_p, i, l_ink)
						end
					end
					i := i + 1
				end
				if has_overflow then
					if shows_hover and then is_on_chevron (hover_px, hover_py) then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.glyph ({SW_PAINTER}.Glyph_chevron_down, chevron_left + chevron_w / 2.0, strip_top + bar_h / 2.0, close_size * 0.8)
				end
			end
			if attached selected_page as pg then
				pg.paint (a_p)
			end
		end

feature -- Under a pick (0.55.0)

	Spring_beats: INTEGER = 2
			-- Heartbeats (250 ms each) a pick must rest on a tab before it
			-- springs open: about half a second.

	spring_tab: INTEGER
			-- The tab a pick rests on; 0 = none.

	tab_before_spring: INTEGER
			-- The tab shown before a pick sprang another open; 0 = none
			-- sprang.

	responds_to_pick (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- A pick over a tab in the bar.
		do
			Result := is_enabled and then is_placed and then contains (a_px, a_py)
				and then tab_index_at (a_px, a_py) > 0
		end

	pick_hover (a_pebble: ANY; a_px, a_py: REAL_64)
		local
			k: INTEGER
		do
			if is_placed then
				k := tab_index_at (a_px, a_py)
			end
			if k /= spring_tab then
				spring_tab := k
				spring_count := 0
			end
		end

	pick_tick (a_pebble: ANY): BOOLEAN
			-- After `Spring_beats', the tab rested on opens.
		do
			if spring_tab > 0 and then spring_tab /= selected_index and then spring_tab <= labels.count then
				spring_count := spring_count + 1
				if spring_count >= Spring_beats then
					if tab_before_spring = 0 then
						tab_before_spring := selected_index
					end
					select_tab (spring_tab)
					spring_count := 0
					Result := True
				end
			end
		end

	pick_click (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- A press on a tab opens it, and it stays open after the drop.
		local
			k: INTEGER
		do
			if is_placed then
				k := tab_index_at (a_px, a_py)
				if k > 0 then
					select_tab (k)
					tab_before_spring := 0
					Result := True
				end
			end
		end

	pick_ended
			-- A tab the pick sprang open closes again: the one shown before
			-- returns.
		do
			if tab_before_spring > 0 and then tab_before_spring <= labels.count
				and then tab_before_spring /= selected_index
			then
				select_tab (tab_before_spring)
			end
			tab_before_spring := 0
			spring_tab := 0
			spring_count := 0
		ensure then
			none_resting: spring_tab = 0
		end

feature {NONE} -- Pick internals

	spring_count: INTEGER
			-- Beats the pick has rested on `spring_tab'.

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if on_strip (a_px, a_py) then
					Result := Current
				elseif attached selected_page as pg then
					Result := pg.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A press on the bar: the chevron offers the overflow menu, a
			-- close box arms a close (it happens on release, over the same
			-- box), a tab is selected and may then be dragged.
		local
			k: INTEGER
		do
			if is_enabled and then on_strip (a_px, a_py) then
				Result := True
				end_drag
				if is_on_chevron (a_px, a_py) then
					pending_menu := overflow_menu
				elseif close_box_at (a_px, a_py) > 0 then
					armed_close := close_box_at (a_px, a_py)
				elseif is_placed then
					k := tab_index_at (a_px, a_py)
					if k > 0 then
						select_tab (k)
						if not is_vertical then
							drag_index := k
							drag_origin_x := a_px
						end
					end
				end
			end
		end

	handle_drag (a_px, a_py: REAL_64)
			-- Past a few pixels, the pressed tab follows the pointer: it
			-- changes places with each shown neighbor whose middle the
			-- pointer crosses.
		do
			if drag_index > 0 and then is_placed then
				if not is_dragging and then (a_px - drag_origin_x).abs >= drag_threshold then
					is_dragging := True
				end
				if is_dragging then
					from
					until
						not (drag_index < labels.count and then is_tab_shown (drag_index + 1)
							and then pointer_past_middle (a_px, drag_index + 1, True))
					loop
						move_tab (drag_index, drag_index + 1)
						drag_index := drag_index + 1
					end
					from
					until
						not (drag_index > 1 and then is_tab_shown (drag_index - 1)
							and then pointer_past_middle (a_px, drag_index - 1, False))
					loop
						move_tab (drag_index, drag_index - 1)
						drag_index := drag_index - 1
					end
				end
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- A close box pressed and released on closes its tab; a drag
			-- ends where it is.
		local
			k: INTEGER
		do
			k := armed_close
			armed_close := 0
			end_drag
			if k > 0 and then k <= labels.count and then close_box_at (a_x, a_y) = k then
				request_close (k)
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- Over the strip, the wheel steps the selection (no wrapping).
		do
			if is_enabled and then is_hovered and then on_strip (hover_px, hover_py) and then not pages.is_empty then
				if a_delta > 0 and then selected_index > 1 then
					select_tab (selected_index - 1)
				elseif a_delta < 0 and then selected_index < pages.count then
					select_tab (selected_index + 1)
				end
				Result := True
			end
		end

feature {NONE} -- Implementation

	closables: ARRAYED_LIST [BOOLEAN]
			-- Parallel to `pages': does the tab show a close box?

	drag_index: INTEGER
			-- The tab under a press, followed while it is dragged; 0 none.

	drag_origin_x: REAL_64

	armed_close: INTEGER
			-- The tab whose close box took the press; 0 none.

	drag_threshold: REAL_64
			-- How far the pointer travels before a press becomes a drag:
			-- half the theme's `padding'.
		do
			Result := tab_gap
		end

	mirror_tab_boxes
			-- Right to left: reflect every placed tab about the bar's center line, so the first
			-- tab sits at the right and the overflow room (the chevron's) at the left.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > tab_lefts.count
			loop
				if tab_widths.i_th (i) > 0.0 then
					tab_lefts.put_i_th (mirrored_x (tab_lefts.i_th (i), tab_widths.i_th (i)), i)
				end
				i := i + 1
			end
		end

	chevron_left: REAL_64
			-- The overflow chevron's left edge: at the bar's right end, or its left end when
			-- the bar is mirrored.
		do
			Result := mirrored_x (x + width - chevron_w, chevron_w)
		end

	label_left (a_i: INTEGER): REAL_64
			-- Where tab `a_i''s label starts: after the padding, and after the close box too
			-- when the tab is mirrored (the box is then on its left).
		require
			placed: a_i >= 1 and a_i <= tab_lefts.count
		do
			Result := tab_lefts.i_th (a_i) + tab_pad
			if mirrors_layout and then closables.i_th (a_i) then
				Result := Result + close_size + tab_pad / 2.0
			end
		end

	pointer_past_middle (a_px: REAL_64; a_k: INTEGER; a_toward_later: BOOLEAN): BOOLEAN
			-- Has a dragged tab's pointer crossed the middle of tab `a_k', moving toward later
			-- tabs (`a_toward_later') or earlier ones? Later tabs sit to the right, or to the
			-- left when the bar is mirrored.
		require
			placed: a_k >= 1 and a_k <= tab_lefts.count
		local
			l_middle: REAL_64
		do
			l_middle := tab_lefts.i_th (a_k) + tab_widths.i_th (a_k) / 2.0
			if a_toward_later /= mirrors_layout then
				Result := a_px > l_middle
			else
				Result := a_px < l_middle
			end
		end

	measure (a_p: SW_PAINTER)
			-- Take the bar's measurements from the theme and the label font.
		do
			label_font (a_p)
			tab_pad := a_p.theme.control_inset
			tab_gap := a_p.theme.padding / 2.0
			close_size := a_p.text_extent
			bar_h := a_p.text_extent + 2.0 * tab_pad
			chevron_w := bar_h * 0.8
		end

	natural_widths (a_p: SW_PAINTER): ARRAYED_LIST [REAL_64]
			-- Each tab's width with room for its label (and close box),
			-- capped at thirteen label-font boxes so one long title cannot
			-- fill the bar, and never below one pixel.
		local
			i: INTEGER
			l_w: REAL_64
		do
			create Result.make (labels.count)
			from
				i := 1
			until
				i > labels.count
			loop
				l_w := a_p.advance (labels.i_th (i)) + 2.0 * tab_pad
				if page_glyphs.has (i) then
					l_w := l_w + Tab_glyph_room
				end
				if attached page_badges.item (i) as al_badge then
					l_w := l_w + a_p.advance (al_badge) + 14.0
				end
				if closables.i_th (i) then
					l_w := l_w + close_size + tab_pad / 2.0
				end
				Result.extend (l_w.min (13.0 * close_size).max (1.0))
				i := i + 1
			end
		ensure
			one_per_tab: Result.count = labels.count
		end

	label_font (a_p: SW_PAINTER)
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
		end

	close_center_x (a_i: INTEGER): REAL_64
			-- The middle of tab `a_i''s close box: one inset from its right.
		require
			placed: a_i >= 1 and a_i <= tab_lefts.count
		do
			if mirrors_layout then
					-- the close box at the tab's left, the label after it
				Result := tab_lefts.i_th (a_i) + tab_pad + close_size / 2.0
			else
				Result := tab_lefts.i_th (a_i) + tab_widths.i_th (a_i) - tab_pad - close_size / 2.0
			end
		end

	draw_close_box (a_p: SW_PAINTER; a_i: INTEGER; a_ink: NATURAL_32)
			-- The close glyph in the tab's ink `a_ink', with a disc behind it
			-- while hovered.
		require
			placed: a_i >= 1 and a_i <= tab_lefts.count
		local
			l_cx, l_cy: REAL_64
		do
			l_cx := close_center_x (a_i)
			l_cy := tab_center_y (a_i)
			if shows_hover and then close_box_at (hover_px, hover_py) = a_i then
				a_p.set_color (a_p.theme.divider)
				a_p.circle_fill (l_cx, l_cy, close_size / 2.0)
			end
			a_p.set_color (a_ink)
			a_p.glyph ({SW_PAINTER}.Glyph_close, l_cx, l_cy, close_size * 0.6)
		end

	swap_with_next (a_i: INTEGER)
			-- Tabs `a_i' and `a_i' + 1 change places, in every parallel
			-- list and in the placed boxes; the selection follows its page.
		require
			pair_in_range: a_i >= 1 and a_i < pages.count
		local
			l_label: STRING_32
			l_page: SW_WIDGET
			l_builder: detachable FUNCTION [SW_WIDGET]
			l_closable: BOOLEAN
		do
			l_label := labels.i_th (a_i)
			labels.put_i_th (labels.i_th (a_i + 1), a_i)
			labels.put_i_th (l_label, a_i + 1)
			l_page := pages.i_th (a_i)
			pages.put_i_th (pages.i_th (a_i + 1), a_i)
			pages.put_i_th (l_page, a_i + 1)
			l_builder := builders.i_th (a_i)
			builders.put_i_th (builders.i_th (a_i + 1), a_i)
			builders.put_i_th (l_builder, a_i + 1)
			l_closable := closables.i_th (a_i)
			closables.put_i_th (closables.i_th (a_i + 1), a_i)
			closables.put_i_th (l_closable, a_i + 1)
			if is_placed then
				if is_tab_shown (a_i) and is_tab_shown (a_i + 1) then
					swap_adjacent_boxes (a_i)
				else
						-- a tab off the strip has no gap to keep: place again
					forget_placement
				end
			end
			if selected_index = a_i then
				selected_index := a_i + 1
			elseif selected_index = a_i + 1 then
				selected_index := a_i
			end
		ensure
			swapped: pages.i_th (a_i) = old pages.i_th (a_i + 1) and pages.i_th (a_i + 1) = old pages.i_th (a_i)
			selection_follows: selected_page = old selected_page
		end

	end_drag
		do
			is_dragging := False
			drag_index := 0
		ensure
			ended: not is_dragging and drag_index = 0
		end

	menu_safe (a_label: STRING_32): STRING_32
			-- `a_label' with each ampersand doubled, so a menu shows it as
			-- written instead of reading it as a mnemonic.
		do
			Result := a_label.twin
			Result.replace_substring_all ({STRING_32} "&", {STRING_32} "&&")
		end


feature -- Keys (simple_gui 1t)

	accepts_focus: BOOLEAN
			-- A strip that takes focus joins the Tab ring.
		do
			Result := strip_takes_focus and then has_strip
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Up and Down in a column, Left and Right in a row, move to the neighbor tab (no
			-- wrapping; the selection follows, as a Windows tab control's does); Home and End go
			-- to the first and the last.
		local
			l_back, l_forward: INTEGER
		do
			if is_enabled and then not pages.is_empty then
				if is_vertical then
					l_back := 38
					l_forward := 40
				elseif mirrors_layout then
					l_back := 39
					l_forward := 37
				else
					l_back := 37
					l_forward := 39
				end
				if a_vk = l_back and then selected_index > 1 then
					select_tab (selected_index - 1)
				elseif a_vk = l_forward and then selected_index < pages.count then
					select_tab (selected_index + 1)
				elseif a_vk = 36 then
					select_tab (1)
				elseif a_vk = 35 then
					select_tab (pages.count)
				end
			end
		end

feature {NONE} -- Edge strips

	draw_edge_ground (a_p: SW_PAINTER; a_i: INTEGER; a_selected, a_hovered: BOOLEAN): NATURAL_32
			-- Paint tab `a_i''s ground for a strip that is not on top, and answer its ink: the
			-- selected tab on the surface with the accent rule on the edge facing the page, a
			-- hovered one on the quiet surface.
		require
			placed: a_i >= 1 and a_i <= tab_widths.count
			shown: tab_widths.i_th (a_i) > 0.0
		local
			t: SW_THEME
			l_inset, l_rule, l_l, l_w, l_t: REAL_64
		do
			t := a_p.theme
			l_inset := tab_inset (t)
			l_rule := (t.border_width / 4.0).max (2.0)
			l_l := tab_lefts.i_th (a_i)
			l_w := tab_widths.i_th (a_i)
			l_t := tab_top (a_i)
			if a_selected or a_hovered then
				if a_selected then
					a_p.set_color (t.surface)
				else
					a_p.set_color (t.surface_variant)
				end
				if is_vertical then
					a_p.rrect_fill (l_l + l_inset, l_t, l_w - 2.0 * l_inset, bar_h, t.radius)
				else
					a_p.rrect_fill (l_l, l_t + 1.0, l_w, bar_h - l_inset - 1.0, t.radius)
				end
				Result := t.ink
			else
				Result := t.ink_muted
			end
			if a_selected then
				a_p.set_color (t.accent)
				inspect strip_position
				when 2 then
					a_p.fill_rect (l_l + l_inset, l_t + 1.0, (l_w - 2.0 * l_inset).max (1.0), l_rule)
				when 3 then
					a_p.fill_rect (l_l + l_w - l_rule - 1.0, l_t + l_inset, l_rule, (bar_h - 2.0 * l_inset).max (1.0))
				else
					a_p.fill_rect (l_l + 1.0, l_t + l_inset, l_rule, (bar_h - 2.0 * l_inset).max (1.0))
				end
			end
		end

feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_tab
		end

	accessible_item_count: INTEGER
			-- Each tab, published as a tab item (simple_gui reads "tab: <title>").
		do
			if has_strip then
				Result := labels.count.min (2_047)
			end
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
		local
			i: INTEGER
			l_value: detachable STRING_32
		do
			from
				i := 1
			until
				i > accessible_item_count
			loop
				if i = selected_index then
					l_value := {STRING_32} "selected"
				else
					l_value := Void
				end
				if is_vertical and then is_placed then
						a_accessibility.add_node (accessible_item_id (i), accessible_node_id, {SW_ACCESSIBILITY}.Role_tab_item,
							labels.i_th (i), l_value, tab_lefts.i_th (i), tab_top (i), tab_widths.i_th (i), bar_h, False, is_enabled)
					else
						a_accessibility.add_node (accessible_item_id (i), accessible_node_id, {SW_ACCESSIBILITY}.Role_tab_item,
							labels.i_th (i), l_value, x, strip_top, width, bar_h, False, is_enabled)
					end
				i := i + 1
			end
		end

	accessible_value: detachable STRING_32
		do
			if selected_index >= 1 and selected_index <= labels.count then
				Result := labels.i_th (selected_index).twin
			end
		end

	accessible_children: ARRAYED_LIST [SW_WIDGET]
			-- Only the shown page: the others are not on the screen.
		do
			create Result.make (1)
			if attached selected_page as al_page then
				Result.extend (al_page)
			end
		end

invariant
	parallel_pages: labels.count = pages.count
	parallel_builders: builders.count = pages.count
	parallel_closables: closables.count = pages.count
	selection_in_range: selected_index >= 0 and selected_index <= pages.count
	selected_when_populated: pages.count > 0 implies selected_index >= 1
	first_in_range: first_visible >= 0 and first_visible <= pages.count
	first_when_populated: pages.count > 0 implies first_visible >= 1
	drag_in_range: drag_index >= 0 and drag_index <= pages.count
	dragging_a_tab: is_dragging implies drag_index >= 1

end
