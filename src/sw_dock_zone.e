note
	description: "[
		One docking zone. STACKED (the default): its visible panels in
		equal shares, each under a title bar. TABBED (GW-05,
		SW_DOCK_HOST.set_tabbed): one tab strip across the top and the
		active panel filling the rest; a click on a tab shows that
		panel. A title bar or a tab is a PEBBLE source (middle-click
		lifts the panel id) and the whole zone is a drop hole -
		receiving asks the host to move_panel here, and the reflow
		follows. Hit testing routes THROUGH to panel contents, so
		docked widgets stay fully alive. The bar and tab arithmetic
		(panel_at_bar, tab_at) is public and assaulted. The tab boxes
		are SW_TAB_STRIP's, placed by its SHRINK policy (GW-15 pushed
		the geometry up so SW_TABS shares it).
	]"

class
	SW_DOCK_ZONE

inherit
	SW_WIDGET
		redefine
			widget_at, pebble_at, accepts_pebble, receive_pebble, arrange, handle_click, handle_double_click,
			accessible_children, accessible_role, default_accessible_name
		end

	SW_TAB_STRIP

create
	make_on

feature {NONE} -- Initialization

	make_on (a_host: SW_DOCK_HOST; a_zone: INTEGER)
		require
			zone_positive: a_zone >= 1
		do
			host := a_host
			zone_id := a_zone
			create tab_ids.make (4)
			bar_h := 22.0
			tab_pad := 11.0
			content_pad := 12.0
			bar_text_y := 15.0
		ensure
			hosted: host = a_host and zone_id = a_zone
		end

feature -- Access

	host: SW_DOCK_HOST

	zone_id: INTEGER

	bar_h: REAL_64
			-- A title bar's height, and the tab strip's: the title font's
			-- measured box plus the theme's `padding' (set by `arrange', so
			-- it grows with `text_scale').

	tab_pad: REAL_64
			-- Either side of a tab's title: the theme's `control_inset'.

	content_pad: REAL_64
			-- Between a panel's content and the zone's edges and bar: the
			-- theme's `border_width' - a zone is a framed surface, like
			-- SW_GROUP, and owns the one border its content gets.

	bar_text_y: REAL_64
			-- The title baseline below a bar's top.

	is_tabbed: BOOLEAN
		do
			Result := host.is_tabbed (zone_id)
		end

	panel_slot_h: REAL_64
			-- Each stacked panel's share of the zone, bar included.
		local
			n: INTEGER
		do
			n := host.panels_in (zone_id).count
			if n > 0 then
				Result := height / n
			else
				Result := 0.0
			end
		end

	panel_at_bar (a_py: REAL_64): INTEGER
			-- STACKED: the panel id whose TITLE BAR sits under a surface
			-- y; 0 elsewhere (and always 0 in a tabbed zone). Public bar
			-- arithmetic.
		local
			mine: ARRAYED_LIST [INTEGER]
			slot: INTEGER
			within: REAL_64
		do
			mine := host.panels_in (zone_id)
			if not is_tabbed and then not mine.is_empty and then panel_slot_h > 0.0
				and then a_py >= y and then a_py < y + height
			then
				slot := ((a_py - y) / panel_slot_h).truncated_to_integer + 1
				if slot >= 1 and slot <= mine.count then
					within := a_py - y - (slot - 1) * panel_slot_h
					if within <= bar_h then
						Result := mine.i_th (slot)
					end
				end
			end
		end

	tab_at (a_px, a_py: REAL_64): INTEGER
			-- TABBED: the panel id whose tab is under the point; 0
			-- elsewhere. Valid after `arrange'.
		local
			k: INTEGER
		do
			if is_tabbed and then tab_ids.count = tab_lefts.count then
				k := tab_index_at (a_px, a_py)
				if k > 0 then
					Result := tab_ids.i_th (k)
				end
			end
		end

	tab_ids: ARRAYED_LIST [INTEGER]
			-- TABBED: the panel behind each tab, left to right.

	strip_top: REAL_64
			-- The tab strip runs along the zone's top.
		do
			Result := y
		end

	strip_height: REAL_64
			-- As tall as a title bar.
		do
			Result := bar_h
		end

feature -- Accessibility (GW-14)

	accessible_children: ARRAYED_LIST [SW_WIDGET]
			-- The panels shown: in a tabbed zone the active one only (scan 13:
			-- a zone published no panels at all).
		local
			mine: ARRAYED_LIST [INTEGER]
			act: INTEGER
		do
			create Result.make (4)
			mine := host.panels_in (zone_id)
			if is_tabbed then
				act := host.active_panel (zone_id)
				if act > 0 then
					Result.extend (host.panels.i_th (act).content)
				end
			else
				across
					mine as m
				loop
					Result.extend (host.panels.i_th (m).content)
				end
			end
		end

	accessible_role: INTEGER
		do
			if is_tabbed then
				Result := {SW_ACCESSIBILITY}.Role_tab
			else
				Result := {SW_ACCESSIBILITY}.Role_pane
			end
		end

	default_accessible_name: STRING_32
			-- The active panel's title when tabbed, else empty.
		do
			create Result.make_empty
			if is_tabbed and then host.active_panel (zone_id) > 0 then
				Result := host.panels.i_th (host.active_panel (zone_id)).title.twin
			end
		end

feature -- Pebbles

	pebble_at (a_px, a_py: REAL_64): detachable ANY
		local
			id: INTEGER
		do
			if is_tabbed then
				id := tab_at (a_px, a_py)
			else
				id := panel_at_bar (a_py)
			end
			if id > 0 then
				Result := id
			end
		end

	accepts_pebble (a_pebble: ANY): BOOLEAN
		do
			if attached {INTEGER_REF} a_pebble as id then
				Result := id.item >= 1 and id.item <= host.panels.count
			end
		end

	receive_pebble (a_pebble: ANY)
		do
			if attached {INTEGER_REF} a_pebble as id then
				host.move_panel (id.item, zone_id)
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- TABBED: a click on a tab shows its panel.
		local
			id: INTEGER
		do
			id := tab_at (a_px, a_py)
			if id > 0 then
				host.activate_panel (id)
				Result := True
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- A double click on a tab or a title bar floats that panel when the
			-- host offers floating (GW-22); otherwise it is a click.
		local
			id: INTEGER
		do
			if is_tabbed then
				id := tab_at (a_px, a_py)
			else
				id := panel_at_bar (a_py)
			end
			if id > 0 and then host.can_float and then not host.is_floating (id) then
				host.request_float (id)
				Result := True
			else
				Result := handle_click (a_px, a_py)
			end
		end

feature -- Layout

	arrange (a_p: SW_PAINTER)
			-- Seat the panels: each under its bar, or - tabbed - lay out
			-- the tabs and seat the active panel alone.
		local
			mine: ARRAYED_LIST [INTEGER]
			i, act: INTEGER
			sy: REAL_64
			l_naturals: ARRAYED_LIST [REAL_64]
		do
			title_font (a_p)
			bar_h := a_p.text_extent + a_p.theme.padding
			bar_text_y := (bar_h - a_p.text_extent) / 2.0 + a_p.font_ascent
			tab_pad := a_p.theme.control_inset
			content_pad := a_p.theme.border_width
			mine := host.panels_in (zone_id)
			tab_ids.wipe_out
			forget_placement
			if is_tabbed then
				create l_naturals.make (mine.count)
				from
					i := 1
				until
					i > mine.count
				loop
					tab_ids.extend (mine.i_th (i))
					l_naturals.extend (a_p.advance (host.panels.i_th (mine.i_th (i)).title) + 2.0 * tab_pad)
					i := i + 1
				end
				place_tabs_shrinking (l_naturals, x + 2.0, (width - 4.0).max (0.0))
				act := host.active_panel (zone_id)
				if act > 0 then
					host.panels.i_th (act).content.set_bounds (x + content_pad, y + bar_h + content_pad,
						(width - 2.0 * content_pad).max (1.0), (height - bar_h - 2.0 * content_pad).max (1.0))
					host.panels.i_th (act).content.arrange (a_p)
				end
			else
				from
					i := 1
				until
					i > mine.count
				loop
					sy := y + (i - 1) * panel_slot_h
					host.panels.i_th (mine.i_th (i)).content.set_bounds
						(x + content_pad, sy + bar_h + content_pad, (width - 2.0 * content_pad).max (1.0),
						(panel_slot_h - bar_h - 2.0 * content_pad).max (1.0))
					host.panels.i_th (mine.i_th (i)).content.arrange (a_p)
					i := i + 1
				end
			end
		ensure then
			one_tab_per_panel: is_tabbed implies tab_ids.count = host.panels_in (zone_id).count
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- Title bars and the tab strip answer as the zone; contents
			-- answer as themselves - docked widgets stay alive.
		local
			mine: ARRAYED_LIST [INTEGER]
			i, act: INTEGER
		do
			if contains (a_px, a_py) then
				if is_tabbed then
					if a_py < y + bar_h then
						Result := Current
					else
						act := host.active_panel (zone_id)
						if act > 0 then
							Result := host.panels.i_th (act).content.widget_at (a_px, a_py)
						end
						if Result = Void then
							Result := Current
						end
					end
				elseif panel_at_bar (a_py) > 0 then
					Result := Current
				else
					mine := host.panels_in (zone_id)
					from
						i := 1
					until
						i > mine.count or Result /= Void
					loop
						Result := host.panels.i_th (mine.i_th (i)).content.widget_at (a_px, a_py)
						i := i + 1
					end
					if Result = Void then
						Result := Current
					end
				end
			end
		end

feature -- Preferred size

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 200.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			mine: ARRAYED_LIST [INTEGER]
			i, act: INTEGER
			sy: REAL_64
		do
			if width > 1.0 and height > 1.0 then
				t := a_p.theme
				a_p.set_color (t.surface)
				a_p.fill_rect (x, y, width, height)
				mine := host.panels_in (zone_id)
				if is_tabbed then
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, bar_h - 1.0)
					act := host.active_panel (zone_id)
					title_font (a_p)
					from
						i := 1
					until
						i > tab_ids.count
					loop
						a_p.set_color (draw_tab_ground (a_p, i, tab_ids.i_th (i) = act, False))
						a_p.push_clip (tab_lefts.i_th (i), y, tab_widths.i_th (i), bar_h)
						a_p.text (tab_lefts.i_th (i) + tab_pad, y + bar_text_y, host.panels.i_th (tab_ids.i_th (i)).title)
						a_p.pop_clip
						draw_tab_separator (a_p, i)
						i := i + 1
					end
					if act > 0 then
						draw_clipped (a_p, host.panels.i_th (act).content)
					end
				else
					from
						i := 1
					until
						i > mine.count
					loop
						sy := y + (i - 1) * panel_slot_h
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x + 1.0, sy + 1.0, width - 2.0, bar_h - 1.0)
						title_font (a_p)
						a_p.set_color (t.ink_muted)
						a_p.text (x + tab_pad, sy + bar_text_y,
							host.panels.i_th (mine.i_th (i)).title)
						draw_clipped (a_p, host.panels.i_th (mine.i_th (i)).content)
						i := i + 1
					end
				end
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, 2.0)
			end
		end

feature {NONE} -- Implementation

	draw_clipped (a_p: SW_PAINTER; a_content: SW_WIDGET)
			-- Draw a panel's content kept inside the zone: a label wider
			-- than a narrow zone must not paint over the centre.
		do
			a_p.push_clip (x + 1.0, y + 1.0, (width - 2.0).max (0.0), (height - 2.0).max (0.0))
			a_content.draw (a_p)
			a_p.pop_clip
		end

	title_font (a_p: SW_PAINTER)
			-- The font bar titles and tabs are set in: the theme's chip
			-- size, bold, as SW_GROUP sets its title.
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_chip + 1.0, True)
		end

invariant
	hosted: host /= Void
	zone_positive: zone_id >= 1
	parallel_tabs: tab_lefts.count = tab_ids.count and tab_widths.count = tab_ids.count
	spacing_non_negative: bar_h > 0.0 and tab_pad >= 0.0 and content_pad >= 0.0

end
