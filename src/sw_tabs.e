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
			accessible_role, accessible_value, accessible_children
		end

	SW_TAB_STRIP

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
			-- The strip runs along the widget's top.
		do
			Result := y
		end

	strip_height: REAL_64
		do
			Result := bar_h
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
					l_cy := y + bar_h / 2.0
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
			Result := has_overflow and then a_py >= y and then a_py < y + bar_h
				and then a_px >= x + width - chevron_w and then a_px <= x + width
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

feature -- Element change

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
		do
			measure (a_p)
			Result := bar_h + 8.0
			if attached selected_page as pg then
				Result := Result + pg.clamped_height (pg.preferred_height (a_p, a_width))
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Measure, place the tabs (scrolled so the selected one is
			-- whole), then lay out the selected page under the bar.
		local
			l_naturals: ARRAYED_LIST [REAL_64]
			l_room: REAL_64
		do
			measure (a_p)
			l_naturals := natural_widths (a_p)
			l_room := (width - 2.0).max (0.0)
			has_overflow := not l_naturals.is_empty and then run_width (l_naturals, 1, l_naturals.count, tab_gap) > l_room
			if has_overflow then
				l_room := (l_room - chevron_w - tab_gap).max (0.0)
			end
			if not l_naturals.is_empty then
				first_visible := first_showing (l_naturals, l_room, tab_gap, first_visible.max (1), selected_index)
			end
			place_tabs_scrolling (l_naturals, x, l_room, tab_gap, first_visible)
			if attached selected_page as pg then
				pg.set_bounds (x, y + bar_h + 8.0, width,
					(height - bar_h - 8.0).max (0.0))
				pg.arrange (a_p)
			end
		ensure then
			placed: is_placed
			selected_shown: selected_index >= 1 implies is_tab_shown (selected_index)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tx, tw, l_label_w: REAL_64
			i: INTEGER
			l_ink: NATURAL_32
		do
			t := a_p.theme
			a_p.hline (x, y + bar_h - 1.0, width)
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
						l_ink := draw_tab_ground (a_p, i, i = selected_index,
							shows_hover and then hover_py < y + bar_h and then hover_px >= tx and then hover_px <= tx + tw)
						if is_dragging and then i = drag_index then
							a_p.set_color (t.accent)
							a_p.rrect_stroke (tx + 0.5, y + 4.5, tw - 1.0, bar_h - 6.0, t.radius)
						end
						a_p.set_color (l_ink)
						l_label_w := (tw - 2.0 * tab_pad).max (1.0)
						if closables.i_th (i) then
							l_label_w := (l_label_w - close_size - tab_pad / 2.0).max (1.0)
						end
						a_p.push_clip (tx + tab_pad, y, l_label_w, bar_h)
						a_p.text (tx + tab_pad, y + (bar_h - a_p.text_extent) / 2.0 + a_p.font_ascent, labels.i_th (i))
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
					a_p.glyph ({SW_PAINTER}.Glyph_chevron_down, x + width - chevron_w / 2.0, y + bar_h / 2.0, close_size * 0.8)
				end
			end
			if attached selected_page as pg then
				pg.draw (a_p)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if a_py < y + bar_h then
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
			if is_enabled and then a_py < y + bar_h then
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
						drag_index := k
						drag_origin_x := a_px
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
							and then a_px > tab_lefts.i_th (drag_index + 1) + tab_widths.i_th (drag_index + 1) / 2.0)
					loop
						move_tab (drag_index, drag_index + 1)
						drag_index := drag_index + 1
					end
					from
					until
						not (drag_index > 1 and then is_tab_shown (drag_index - 1)
							and then a_px < tab_lefts.i_th (drag_index - 1) + tab_widths.i_th (drag_index - 1) / 2.0)
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
			if is_enabled and then is_hovered and then hover_py < y + bar_h and then not pages.is_empty then
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
			Result := tab_lefts.i_th (a_i) + tab_widths.i_th (a_i) - tab_pad - close_size / 2.0
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
			l_cy := y + bar_h / 2.0
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


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_tab
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
