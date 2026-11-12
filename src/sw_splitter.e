note
	description: "[
		Two children side by side with a draggable divider. The ratio
		is contract-clamped so neither pane can vanish; the divider
		wears grip dots and consumes its own clicks and drags.
	]"

class
	SW_SPLITTER

inherit
	SW_WIDGET
		redefine
			sub_widgets, cursor_kind,
			arrange, widget_at, handle_click, handle_drag,
			handle_double_click
		end

create
	make

feature {NONE} -- Initialization

	cursor_kind: INTEGER
			-- Resize arrows matching the divider's axis.
		do
			if is_horizontal then
				Result := 4
			else
				Result := 3
			end
		end

	make (a_left, a_right: SW_WIDGET)
		do
			left_child := a_left
			right_child := a_right
			a_left.set_parent (Current)
			a_right.set_parent (Current)
			ratio := 0.5
		ensure
			adopted: a_left.parent = Current and a_right.parent = Current
			balanced: ratio = 0.5
		end

feature -- Access

	left_child: SW_WIDGET
	right_child: SW_WIDGET

	ratio: REAL_64
			-- First pane's share (left, or top when horizontal), 0 .. 1.
			-- A drag and `set_ratio_within' keep each pane at least
			-- `Min_pane' pixels, as GTK and AppKit stop at the panes'
			-- minimum sizes (it was 0.15 .. 0.85 before 1d).

	is_horizontal: BOOLEAN
			-- Does the divider run horizontally (top/bottom panes)?
			-- `left_child' is then the TOP pane, `right_child' the
			-- bottom - the names keep their creation order.

	set_horizontal (a_flag: BOOLEAN)
		do
			is_horizontal := a_flag
		ensure
			set: is_horizontal = a_flag
		end

	with_horizontal: like Current
		do
			set_horizontal (True)
			Result := Current
		ensure
			chained: Result = Current
		end

	Divider_w: REAL_64 = 9.0

	Button_side: REAL_64 = 16.0
			-- The square of a collapse button on the divider, in pixels.

	Min_pane: REAL_64 = 24.0
			-- The narrowest a pane gets from a drag or `set_ratio_within', in pixels.

feature -- Collapsing (1r-c)

	is_pane (a_pane: INTEGER): BOOLEAN
			-- Is `a_pane' 1 (left or top) or 2 (right or bottom)?
		do
			Result := a_pane = 1 or a_pane = 2
		end

	is_collapsible (a_pane: INTEGER): BOOLEAN
			-- May the user collapse pane `a_pane'?
		require
			pane_known: is_pane (a_pane)
		do
			if a_pane = 1 then
				Result := collapsible_first
			else
				Result := collapsible_second
			end
		end

	is_pane_collapsed (a_pane: INTEGER): BOOLEAN
			-- Has pane `a_pane' given all its room to the other?
		require
			pane_known: is_pane (a_pane)
		do
			Result := collapsed_pane = a_pane
		end

	on_collapse_change: detachable PROCEDURE [INTEGER, BOOLEAN]
			-- Called with (pane, is_collapsed) when the USER collapses or expands a pane
			-- (the button, a double click, a drag that opens a collapsed pane); never
			-- for `collapse_pane' or `expand_pane' called from code.

	set_on_collapse_change (a_action: detachable PROCEDURE [INTEGER, BOOLEAN])
		do
			on_collapse_change := a_action
		ensure
			set: on_collapse_change = a_action
		end

	set_collapsible (a_pane: INTEGER; a_on: BOOLEAN)
			-- Let the user collapse pane `a_pane', or stop (a collapsed pane that stops
			-- being collapsible opens again).
		require
			pane_known: is_pane (a_pane)
		do
			if a_pane = 1 then
				collapsible_first := a_on
			else
				collapsible_second := a_on
			end
			if not a_on and then collapsed_pane = a_pane then
				expand_pane (a_pane)
			end
		ensure
			set: is_collapsible (a_pane) = a_on
		end

	collapse_pane (a_pane: INTEGER)
			-- Give all of pane `a_pane's room to the other (ratio 0 or 1); the ratio it
			-- had comes back with `expand_pane'. Not announced.
		require
			pane_known: is_pane (a_pane)
			other_open: not is_pane_collapsed (3 - a_pane)
		do
			if collapsed_pane /= a_pane then
				saved_ratio := ratio
				collapsed_pane := a_pane
				if a_pane = 1 then
					ratio := 0.0
				else
					ratio := 1.0
				end
			end
		ensure
			collapsed: is_pane_collapsed (a_pane)
			room_given: (a_pane = 1 implies ratio = 0.0) and (a_pane = 2 implies ratio = 1.0)
		end

	expand_pane (a_pane: INTEGER)
			-- Open pane `a_pane' again at the ratio it had; nothing when it is not
			-- collapsed. Not announced.
		require
			pane_known: is_pane (a_pane)
		do
			if collapsed_pane = a_pane then
				collapsed_pane := 0
				ratio := saved_ratio
			end
		ensure
			opened: not is_pane_collapsed (a_pane)
		end

feature -- Element change

	set_ratio (a_ratio: REAL_64)
			-- The first pane's share, kept within 0 .. 1; a collapsed pane opens.
		do
			collapsed_pane := 0
			ratio := a_ratio.max (0.0).min (1.0)
		ensure
			in_unit: ratio >= 0.0 and ratio <= 1.0
			none_collapsed: not is_pane_collapsed (1) and not is_pane_collapsed (2)
		end

	set_ratio_within (a_ratio: REAL_64; a_extent: REAL_64)
			-- The first pane's share of `a_extent' (the panes' room, the divider
			-- left out), keeping each pane at least `Min_pane' pixels; half and
			-- half when there is not room for both.
		require
			non_negative_extent: a_extent >= 0.0
		do
			if a_extent > 2.0 * Min_pane then
				set_ratio (a_ratio.max (Min_pane / a_extent).min (1.0 - Min_pane / a_extent))
			else
				set_ratio (0.5)
			end
		ensure
			first_pane_wide_enough: a_extent > 2.0 * Min_pane implies ratio * a_extent >= Min_pane - 0.001
			second_pane_wide_enough: a_extent > 2.0 * Min_pane implies (1.0 - ratio) * a_extent >= Min_pane - 0.001
		end

	divider_left: REAL_64
			-- The left edge of the side-by-side divider: after the first pane, which is at the
			-- right in right-to-left layout (W4c; GtkPaned and NSSplitView count from the
			-- leading edge too).
		do
			if mirrors_layout then
				Result := x + width - Divider_w - (width - Divider_w) * ratio
			else
				Result := x + (width - Divider_w) * ratio
			end
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (2)
			Result.extend (left_child)
			Result.extend (right_child)
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			lw: REAL_64
		do
			if is_horizontal then
				Result := left_child.preferred_height (a_p, a_width) + Divider_w
					+ right_child.preferred_height (a_p, a_width)
			else
				lw := (a_width - Divider_w) * ratio
				Result := left_child.preferred_height (a_p, lw)
					.max (right_child.preferred_height (a_p, a_width - Divider_w - lw))
			end
		end

	arrange (a_p: SW_PAINTER)
		local
			lw: REAL_64
		do
			if is_horizontal then
				lw := (height - Divider_w) * ratio
				left_child.set_bounds (x, y, width, lw)
				right_child.set_bounds (x, y + lw + Divider_w, width, height - lw - Divider_w)
			else
				lw := (width - Divider_w) * ratio
				left_child.set_bounds (mirrored_x (x, lw), y, lw, height)
				right_child.set_bounds (mirrored_x (x + lw + Divider_w, width - lw - Divider_w), y, width - lw - Divider_w, height)
			end
			if collapsed_pane = 1 then
				left_child.vanish
			else
				left_child.arrange (a_p)
			end
			if collapsed_pane = 2 then
				right_child.vanish
			else
				right_child.arrange (a_p)
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			dx, cy: REAL_64
			i: INTEGER
		do
			t := a_p.theme
			if collapsed_pane /= 1 then
				left_child.paint (a_p)
			end
			if collapsed_pane /= 2 then
				right_child.paint (a_p)
			end
			if is_horizontal then
				cy := y + (height - Divider_w) * ratio + Divider_w / 2.0
				if shows_hover then
					a_p.set_color (t.wash_accent)
					a_p.rrect_fill (x + 2.0, cy - Divider_w / 2.0 + 1.0, width - 4.0, Divider_w - 2.0, 3.0)
					a_p.set_color (t.accent)
					a_p.fill_rect (x + 2.0, cy - 1.0, width - 4.0, 2.0)
				else
					a_p.set_color (t.outline)
					a_p.fill_rect (x + 2.0, cy - 0.5, width - 4.0, 1.0)
				end
				dx := x + width / 2.0 - 12.0
				from
					i := 1
				until
					i > 3
				loop
					if shows_hover then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.rrect_fill (dx + i * 6.0, cy - 1.5, 3.0, 3.0, 1.5)
					i := i + 1
				end
			else
				dx := divider_left + Divider_w / 2.0
				if shows_hover then
						-- announce draggability: a wide accent bar under the
						-- pointer says push me, pull me
					a_p.set_color (t.wash_accent)
					a_p.rrect_fill (dx - Divider_w / 2.0 + 1.0, y + 2.0, Divider_w - 2.0, height - 4.0, 3.0)
					a_p.set_color (t.accent)
					a_p.fill_rect (dx - 1.0, y + 2.0, 2.0, height - 4.0)
				else
					a_p.set_color (t.outline)
					a_p.fill_rect (dx - 0.5, y + 2.0, 1.0, height - 4.0)
				end
				cy := y + height / 2.0 - 12.0
				from
					i := 1
				until
					i > 3
				loop
					if shows_hover then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.rrect_fill (dx - 1.5, cy + i * 6.0, 3.0, 3.0, 1.5)
					i := i + 1
				end
			end
			draw_collapse_buttons (a_p)
		end

feature -- Collapse buttons (1r-c)

	is_button_shown (a_pane: INTEGER): BOOLEAN
			-- Does the divider carry pane `a_pane's arrow button? A collapsed pane
			-- keeps its button (it opens); the other pane's is hidden then.
		require
			pane_known: is_pane (a_pane)
		do
			Result := is_collapsible (a_pane) and then (collapsed_pane = 0 or collapsed_pane = a_pane)
				and then (if is_horizontal then width else height end) >= 2.0 * Button_side + 12.0
		end

	button_center_x, button_center_y: REAL_64
			-- Set by `locate_button'.

	locate_button (a_pane: INTEGER)
			-- Put the centre of pane `a_pane's button in `button_center_x', `button_center_y':
			-- on the divider, near its start; the second pane's after the first's.
		require
			pane_known: is_pane (a_pane)
		local
			l_along: REAL_64
		do
			l_along := 6.0 + Button_side / 2.0
			if a_pane = 2 and then is_button_shown (1) then
				l_along := l_along + Button_side + 2.0
			end
			if is_horizontal then
				button_center_x := x + l_along
				button_center_y := y + (height - Divider_w) * ratio + Divider_w / 2.0
			else
				button_center_x := divider_left + Divider_w / 2.0
				button_center_y := y + l_along
			end
		end

	button_pane_at (a_px, a_py: REAL_64): INTEGER
			-- The pane whose divider button is under the point; 0 for none.
		local
			l_pane: INTEGER
		do
			from
				l_pane := 1
			until
				l_pane > 2 or Result > 0
			loop
				if is_button_shown (l_pane) then
					locate_button (l_pane)
					if (a_px - button_center_x).abs <= Button_side / 2.0 and (a_py - button_center_y).abs <= Button_side / 2.0 then
						Result := l_pane
					end
				end
				l_pane := l_pane + 1
			end
		ensure
			pane_or_none: Result >= 0 and Result <= 2
			shown: Result > 0 implies is_button_shown (Result)
		end

	arrow_sign (a_pane: INTEGER): INTEGER
			-- The way pane `a_pane's arrow points along the divider's axis: -1 toward the
			-- left or top, 1 toward the right or bottom. It points toward the pane while the
			-- pane is open (a press collapses it that way) and the other way while collapsed.
		require
			pane_known: is_pane (a_pane)
		do
			if a_pane = 1 then
				Result := -1
			else
				Result := 1
			end
			if mirrors_layout and then not is_horizontal then
				Result := -Result
			end
			if collapsed_pane = a_pane then
				Result := -Result
			end
		ensure
			sign: Result = -1 or Result = 1
		end

	draw_collapse_buttons (a_p: SW_PAINTER)
		local
			t: SW_THEME
			l_pane, l_s: INTEGER
			l_half: REAL_64
		do
			t := a_p.theme
			l_half := Button_side / 2.0
			from
				l_pane := 1
			until
				l_pane > 2
			loop
				if is_button_shown (l_pane) then
					locate_button (l_pane)
					l_s := arrow_sign (l_pane)
					a_p.set_color (t.surface)
					a_p.rrect_fill (button_center_x - l_half, button_center_y - l_half, Button_side, Button_side, 3.0)
					a_p.set_color (t.outline)
					a_p.rrect_stroke (button_center_x - l_half + 0.5, button_center_y - l_half + 0.5, Button_side - 1.0, Button_side - 1.0, 3.0)
					a_p.set_color (t.ink_muted)
					if is_horizontal then
						a_p.triangle_fill (button_center_x, button_center_y + l_s * 3.5,
							button_center_x - 4.5, button_center_y - l_s * 2.5, button_center_x + 4.5, button_center_y - l_s * 2.5)
					else
						a_p.triangle_fill (button_center_x + l_s * 3.5, button_center_y,
							button_center_x - l_s * 2.5, button_center_y - 4.5, button_center_x - l_s * 2.5, button_center_y + 4.5)
					end
				end
				l_pane := l_pane + 1
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		local
			dx: REAL_64
		do
			if contains (a_px, a_py) then
				if is_horizontal then
					dx := y + (height - Divider_w) * ratio
					if a_py >= dx - 2.0 and a_py <= dx + Divider_w + 2.0 then
						Result := Current
					elseif a_py < dx and collapsed_pane /= 1 then
						Result := left_child.widget_at (a_px, a_py)
					elseif a_py >= dx and collapsed_pane /= 2 then
						Result := right_child.widget_at (a_px, a_py)
					end
				else
					dx := divider_left
					if a_px >= dx - 2.0 and a_px <= dx + Divider_w + 2.0 then
						Result := Current
					elseif collapsed_pane /= 1 and then left_child.contains (a_px, a_py) then
						Result := left_child.widget_at (a_px, a_py)
					elseif collapsed_pane /= 2 then
						Result := right_child.widget_at (a_px, a_py)
					end
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A press on the divider begins the drag (the window's
			-- capture routes the moves back here); a press on a collapse
			-- button toggles that pane instead, and the drag it starts is ignored.
		local
			dx: REAL_64
			l_pane: INTEGER
		do
			if is_horizontal then
				dx := y + (height - Divider_w) * ratio
				Result := a_py >= dx - 2.0 and a_py <= dx + Divider_w + 2.0
			else
				dx := divider_left
				Result := a_px >= dx - 2.0 and a_px <= dx + Divider_w + 2.0
			end
			button_held := False
			if Result then
				l_pane := button_pane_at (a_px, a_py)
				if l_pane > 0 then
					button_held := True
					toggle_by_user (l_pane)
				end
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Double-click the divider: a collapsible pane collapses (the first when both
			-- are; a collapsed one opens); with none the ratio snaps home to 0.5. On a
			-- collapse button it does no more than the press did.
		do
			Result := handle_click (a_px, a_py)
			if Result and then not button_held then
				if collapsed_pane > 0 then
					toggle_by_user (collapsed_pane)
				elseif collapsible_first then
					toggle_by_user (1)
				elseif collapsible_second then
					toggle_by_user (2)
				else
					set_ratio (0.5)
				end
			end
		ensure then
			reset: Result and not (collapsible_first or collapsible_second) implies ratio = 0.5
		end

	handle_drag (a_px, a_py: REAL_64)
			-- Move the divider; a drag on a collapsed pane's divider opens that pane.
			-- A drag toward an edge stops at the minimum pane size: it never collapses.
		local
			l_opened: INTEGER
		do
			if not button_held then
				l_opened := collapsed_pane
				if is_horizontal then
					if height > Divider_w then
						set_ratio_within ((a_py - y) / (height - Divider_w), height - Divider_w)
					end
				elseif width > Divider_w then
					if mirrors_layout then
						set_ratio_within ((x + width - a_px) / (width - Divider_w), width - Divider_w)
					else
						set_ratio_within ((a_px - x) / (width - Divider_w), width - Divider_w)
					end
				end
				if l_opened > 0 and then collapsed_pane = 0 then
					notify_collapse (l_opened, False)
				end
			end
		end

feature {NONE} -- Collapsing internals

	collapsible_first, collapsible_second: BOOLEAN
			-- May the user collapse pane 1, pane 2?

	collapsed_pane: INTEGER
			-- The collapsed pane, 0 for none.

	saved_ratio: REAL_64
			-- The ratio `expand_pane' restores.

	button_held: BOOLEAN
			-- Did the press now being dragged land on a collapse button?

	toggle_by_user (a_pane: INTEGER)
			-- A collapsed pane opens, an open one collapses, and the notice goes out.
		require
			pane_known: is_pane (a_pane)
		do
			if collapsed_pane = a_pane then
				expand_pane (a_pane)
				notify_collapse (a_pane, False)
			elseif collapsed_pane = 0 then
				collapse_pane (a_pane)
				notify_collapse (a_pane, True)
			end
		end

	notify_collapse (a_pane: INTEGER; a_collapsed: BOOLEAN)
		do
			if attached on_collapse_change as al_action then
				al_action.call ([a_pane, a_collapsed])
			end
		end

invariant
	children_adopted: left_child.parent = Current and right_child.parent = Current
	ratio_in_unit: ratio >= 0.0 and ratio <= 1.0
	collapsed_known: collapsed_pane >= 0 and collapsed_pane <= 2
	collapsed_first_at_edge: collapsed_pane = 1 implies ratio = 0.0
	collapsed_second_at_edge: collapsed_pane = 2 implies ratio = 1.0

end
