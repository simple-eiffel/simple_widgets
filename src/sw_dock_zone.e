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

		BUTTONS (0.46.0). The zone's top bar (or its tab strip) ends in
		a chevron that folds the zone (SW_DOCK_HOST.collapse_zone), and
		a maximizable panel's bar in a square that maximizes it; a
		maximized panel shows alone under a bar whose button restores
		it. A FOLDED zone is a strip along the window's edge: a chevron
		that opens it, then each panel's name - set along the strip on
		the west and east - with a dot when the host marks the panel; a
		click on a name opens the zone showing that panel. A right-click
		on a bar, a tab or the strip offers the same choices and Move to
		another zone. `button_at' and `strip_panel_at' are public.
	]"

class
	SW_DOCK_ZONE

inherit
	SW_WIDGET
		redefine
			widget_at, pebble_at, accepts_pebble, receive_pebble, arrange, handle_click, handle_double_click,
			accessible_children, accessible_role, default_accessible_name, context_menu, wants_hover_point
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
			create buttons.make (3)
			create strip_titles.make (4)
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

feature -- Buttons and the strip (0.46.0)

	Button_collapse: INTEGER = 1
			-- Fold the zone.
	Button_maximize: INTEGER = 2
			-- Maximize the bar's panel.
	Button_restore: INTEGER = 3
			-- Put the maximized panel back.
	Button_expand: INTEGER = 4
			-- Open the folded zone.

	Quarter_turn: REAL_64 = 1.5707963267948966
			-- A strip name's turn on the west and east, in radians.

	solo_panel: INTEGER
			-- The host's maximized panel when it is one of this zone's; 0
			-- otherwise.
		do
			if host.maximized_panel > 0 and then host.panels.i_th (host.maximized_panel).zone = zone_id then
				Result := host.maximized_panel
			end
		ensure
			mine_or_none: Result = 0 or else host.panels.i_th (Result).zone = zone_id
		end

	is_folded: BOOLEAN
			-- Does the zone stand as a strip?
		do
			Result := host.is_folded (zone_id)
		end

	is_across: BOOLEAN
			-- Does a strip run across (the south zone) rather than down?
		do
			Result := zone_id = host.Zone_south
		end

	buttons: ARRAYED_LIST [TUPLE [kind, panel: INTEGER; bx, by, side: REAL_64]]
			-- The bar buttons placed by the last `arrange', each a square.

	strip_titles: ARRAYED_LIST [TUPLE [panel: INTEGER; lo, hi: REAL_64]]
			-- FOLDED: each panel's name along the strip - from `lo' to `hi'
			-- in y on the west and east, in x on the south. By `arrange'.

	button_at (a_px, a_py: REAL_64): TUPLE [kind, panel: INTEGER]
			-- The button under the point and the panel it acts on; [0, 0]
			-- for none. Valid after `arrange'.
		local
			i: INTEGER
			b: TUPLE [kind, panel: INTEGER; bx, by, side: REAL_64]
		do
			Result := [0, 0]
			from
				i := 1
			until
				i > buttons.count or Result.kind > 0
			loop
				b := buttons.i_th (i)
				if a_px >= b.bx and a_px < b.bx + b.side and a_py >= b.by and a_py < b.by + b.side then
					Result := [b.kind, b.panel]
				end
				i := i + 1
			end
		ensure
			known_kind: Result.kind >= 0 and Result.kind <= Button_expand
		end

	strip_panel_at (a_px, a_py: REAL_64): INTEGER
			-- FOLDED: the panel whose name is under the point; 0 elsewhere.
		local
			i: INTEGER
			l_along: REAL_64
		do
			if is_folded and then contains (a_px, a_py) then
				if is_across then
					l_along := a_px
				else
					l_along := a_py
				end
				from
					i := 1
				until
					i > strip_titles.count or Result > 0
				loop
					if l_along >= strip_titles.i_th (i).lo and l_along < strip_titles.i_th (i).hi then
						Result := strip_titles.i_th (i).panel
					end
					i := i + 1
				end
			end
		end

	bar_panel_at (a_px, a_py: REAL_64): INTEGER
			-- The panel a bar, tab or strip name under the point stands
			-- for: the solo panel's bar, a tab (or the active panel
			-- elsewhere on the strip), a stacked title bar, a strip name;
			-- 0 elsewhere.
		do
			if is_folded then
				Result := strip_panel_at (a_px, a_py)
			elseif solo_panel > 0 then
				if a_py >= y and a_py < y + bar_h then
					Result := solo_panel
				end
			elseif is_tabbed then
				if a_py >= y and a_py < y + bar_h then
					Result := tab_at (a_px, a_py)
					if Result = 0 then
						Result := host.active_panel (zone_id)
					end
				end
			else
				Result := panel_at_bar (a_py)
			end
		end

	press_button (a_kind, a_panel: INTEGER)
			-- Do what button `a_kind' does for `a_panel'.
		require
			known_kind: a_kind >= Button_collapse and a_kind <= Button_expand
		do
			inspect a_kind
			when Button_collapse then
				host.collapse_zone (zone_id)
			when Button_maximize then
				if a_panel >= 1 and then a_panel <= host.panels.count and then host.is_maximizable (a_panel)
					and then host.is_panel_visible (a_panel)
				then
					host.maximize_panel (a_panel)
				end
			when Button_restore then
				host.restore_maximized
			else
				host.expand_zone (zone_id)
			end
		end

	open_at_panel (a_panel: INTEGER)
			-- Open the folded zone showing `a_panel'.
		require
			panel_known: a_panel >= 1 and a_panel <= host.panels.count
		do
			host.expand_zone (zone_id)
			if host.is_panel_visible (a_panel) and then host.panels.i_th (a_panel).zone = zone_id then
				host.activate_panel (a_panel)
			end
		ensure
			opened: not host.is_collapsed (zone_id)
		end

feature -- Menu

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- On a bar, a tab or the strip: Maximize or Restore the panel,
			-- fold or open the zone, Move the panel to another zone.
			-- Elsewhere (a panel's own ground) nothing, so the click goes on.
		local
			id, z: INTEGER
			l_title: STRING_32
		do
			id := bar_panel_at (a_px, a_py)
			if id > 0 or else is_folded then
				create Result.make
				if id > 0 then
					l_title := host.panels.i_th (id).title.as_lower
					if solo_panel = id then
						Result.add_item ({STRING_32} "Restore " + l_title, "", True, agent host.restore_maximized)
					elseif host.is_maximizable (id) and then host.is_panel_visible (id) then
						Result.add_item ({STRING_32} "Maximize " + l_title, "", True, agent host.maximize_panel (id))
					end
				end
				if is_folded then
					if id > 0 then
						Result.add_item ({STRING_32} "Show " + host.panels.i_th (id).title.as_lower, "", True, agent open_at_panel (id))
					else
						Result.add_item ({STRING_32} "Open the " + host.zone_title (zone_id), "", True, agent host.expand_zone (zone_id))
					end
				elseif solo_panel = 0 then
					Result.add_item ({STRING_32} "Collapse the " + host.zone_title (zone_id), "", True, agent host.collapse_zone (zone_id))
				end
				if id > 0 and then solo_panel = 0 then
					Result.add_separator
					from
						z := host.Zone_west
					until
						z > host.Zone_south
					loop
						if z /= zone_id then
							Result.add_item ({STRING_32} "Move to the " + host.zone_title (z), "", True, agent host.move_panel (id, z))
						end
						z := z + 1
					end
				end
			end
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
			-- A button does its job; on a strip a name opens the zone at
			-- that panel; TABBED: a click on a tab shows its panel.
		local
			id: INTEGER
			b: TUPLE [kind, panel: INTEGER]
		do
			b := button_at (a_px, a_py)
			if b.kind > 0 then
				press_button (b.kind, b.panel)
				Result := True
			elseif is_folded then
				id := strip_panel_at (a_px, a_py)
				if id > 0 then
					open_at_panel (id)
				end
				Result := True
			elseif solo_panel = 0 then
				id := tab_at (a_px, a_py)
				if id > 0 then
					host.activate_panel (id)
					Result := True
				end
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- A double click on a tab or a title bar floats that panel when the
			-- host offers floating (GW-22), else maximizes or restores a
			-- maximizable panel; otherwise it is a click.
		local
			id: INTEGER
		do
			if button_at (a_px, a_py).kind = 0 and then not is_folded then
				if solo_panel > 0 then
					if a_py < y + bar_h then
						id := solo_panel
					end
				elseif is_tabbed then
					id := tab_at (a_px, a_py)
				else
					id := panel_at_bar (a_py)
				end
			end
			if id > 0 and then solo_panel = id then
				host.restore_maximized
				Result := True
			elseif id > 0 and then host.can_float and then not host.is_floating (id) then
				host.request_float (id)
				Result := True
			elseif id > 0 and then host.is_maximizable (id) and then host.is_panel_visible (id) then
				host.maximize_panel (id)
				Result := True
			else
				Result := handle_click (a_px, a_py)
			end
		end

feature -- Layout

	arrange (a_p: SW_PAINTER)
			-- Seat the panels: each under its bar, or - tabbed - lay out
			-- the tabs and seat the active panel alone; a maximized panel
			-- alone under its bar; FOLDED, the strip's names, every panel
			-- sent away. Place the bar buttons.
		local
			mine: ARRAYED_LIST [INTEGER]
			i, act, l_solo: INTEGER
			sy, l_along, l_len, l_right: REAL_64
			l_naturals: ARRAYED_LIST [REAL_64]
		do
			title_font (a_p)
			bar_h := a_p.text_extent + a_p.theme.padding
			bar_text_y := (bar_h - a_p.text_extent) / 2.0 + a_p.font_ascent
			tab_pad := a_p.theme.control_inset
			content_pad := a_p.theme.border_width
			mine := host.panels_in (zone_id)
			tab_ids.wipe_out
			buttons.wipe_out
			strip_titles.wipe_out
			forget_placement
			l_solo := solo_panel
			if width <= 0.0 or height <= 0.0 or else (host.maximized_panel > 0 and l_solo = 0) then
				send_away (mine, 0)
			elseif is_folded then
				send_away (mine, 0)
				buttons.extend ([Button_expand, 0, x + (width - bar_h) / 2.0, y + 4.0, bar_h])
				if is_across then
					buttons.i_th (1).bx := x + 4.0
					buttons.i_th (1).by := y + (height - bar_h) / 2.0
					l_along := x + 4.0 + bar_h + tab_pad
				else
					l_along := y + 4.0 + bar_h + tab_pad
				end
				across
					mine as m
				loop
					l_len := a_p.advance (host.panels.i_th (m).title) + 2.0 * tab_pad + bar_h / 2.0
					strip_titles.extend ([m.item, l_along, l_along + l_len])
					l_along := l_along + l_len
				end
			elseif l_solo > 0 then
				send_away (mine, l_solo)
				buttons.extend ([Button_restore, l_solo, x + width - bar_h - 2.0, y, bar_h])
				host.panels.i_th (l_solo).content.set_bounds (x + content_pad, y + bar_h + content_pad,
					(width - 2.0 * content_pad).max (1.0), (height - bar_h - 2.0 * content_pad).max (1.0))
				host.panels.i_th (l_solo).content.arrange (a_p)
			elseif is_tabbed then
				act := host.active_panel (zone_id)
				l_right := place_bar_buttons (act, y, True)
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
				place_tabs_shrinking (l_naturals, x + 2.0, (l_right - x - 4.0).max (0.0))
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
					l_right := place_bar_buttons (mine.i_th (i), sy, i = 1)
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
				if is_folded then
					Result := Current
				elseif solo_panel > 0 then
					if a_py < y + bar_h then
						Result := Current
					else
						Result := host.panels.i_th (solo_panel).content.widget_at (a_px, a_py)
						if Result = Void then
							Result := Current
						end
					end
				elseif is_tabbed then
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
				if is_folded then
					draw_strip (a_p)
				elseif solo_panel > 0 then
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, bar_h - 1.0)
					title_font (a_p)
					a_p.set_color (t.ink)
					a_p.text (x + tab_pad, y + bar_text_y, host.panels.i_th (solo_panel).title)
					draw_clipped (a_p, host.panels.i_th (solo_panel).content)
				elseif is_tabbed then
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
				draw_buttons (a_p)
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, 2.0)
			end
		end

feature {NONE} -- Implementation

	wants_hover_point: BOOLEAN
			-- Follow the pointer, to light the button or name under it.
		do
			Result := True
		end

	send_away (a_panels: ARRAYED_LIST [INTEGER]; a_except: INTEGER)
			-- Every panel of `a_panels' but `a_except' off the surface.
		do
			across
				a_panels as m
			loop
				if m.item /= a_except then
					host.panels.i_th (m).content.vanish
				end
			end
		end

	place_bar_buttons (a_panel: INTEGER; a_top: REAL_64; a_with_collapse: BOOLEAN): REAL_64
			-- Place the buttons at the right end of the bar at `a_top':
			-- Maximize when `a_panel' is maximizable, then (`a_with_collapse')
			-- the fold chevron. The x where the bar's own room ends.
		do
			Result := x + width - 2.0
			if a_panel > 0 and then host.is_maximizable (a_panel) then
				Result := Result - bar_h
				buttons.extend ([Button_maximize, a_panel, Result, a_top, bar_h])
			end
			if a_with_collapse then
				Result := Result - bar_h
				buttons.extend ([Button_collapse, 0, Result, a_top, bar_h])
			end
		ensure
			within: Result <= x + width
		end

	draw_buttons (a_p: SW_PAINTER)
			-- Every placed button: a quiet ground under the pointer, then
			-- its glyph in the muted ink (the accent while hovered).
		local
			b: TUPLE [kind, panel: INTEGER; bx, by, side: REAL_64]
			l_hot: BOOLEAN
			cx, cy, s: REAL_64
		do
			across
				buttons as al_b
			loop
				b := al_b
				l_hot := shows_hover and then hover_px >= b.bx and then hover_px < b.bx + b.side
					and then hover_py >= b.by and then hover_py < b.by + b.side
				if l_hot then
					a_p.set_color (a_p.theme.surface)
					a_p.rrect_fill (b.bx + 2.0, b.by + 2.0, b.side - 4.0, b.side - 4.0, 3.0)
					a_p.set_color (a_p.theme.accent)
				else
					a_p.set_color (a_p.theme.ink_muted)
				end
				cx := b.bx + b.side / 2.0
				cy := b.by + b.side / 2.0
				s := b.side * 0.2
				inspect b.kind
				when Button_maximize then
					a_p.rrect_stroke (cx - s, cy - s, 2.0 * s, 2.0 * s, 1.0)
				when Button_restore then
					a_p.rrect_stroke (cx - s, cy - s * 0.4, s * 1.6, s * 1.6, 1.0)
					a_p.line (cx - s * 0.4, cy - s * 0.4, cx - s * 0.4, cy - s, 1.4)
					a_p.line (cx - s * 0.4, cy - s, cx + s, cy - s, 1.4)
					a_p.line (cx + s, cy - s, cx + s, cy + s * 0.6, 1.4)
					a_p.line (cx + s, cy + s * 0.6, cx + s * 0.6, cy + s * 0.6, 1.4)
				when Button_collapse then
					chevron (a_p, cx, cy, s, outward)
				else
					chevron (a_p, cx, cy, s, -outward)
				end
			end
		end

	outward: INTEGER
			-- The direction toward the window's edge: 1 left (west), 2
			-- right (east), 3 down (south); negated for the way back in.
		do
			inspect zone_id
			when 1 then
				Result := 1
			when 2 then
				Result := 2
			else
				Result := 3
			end
		end

	chevron (a_p: SW_PAINTER; a_cx, a_cy, a_s: REAL_64; a_direction: INTEGER)
			-- A two-stroke chevron about (`a_cx', `a_cy') pointing left (1),
			-- right (2), down (3), or - negated - right, left, up.
		local
			h: REAL_64
		do
			h := a_s * 0.6
			inspect a_direction
			when 1, -2 then
				a_p.line (a_cx + h, a_cy - a_s, a_cx - h, a_cy, 1.6)
				a_p.line (a_cx - h, a_cy, a_cx + h, a_cy + a_s, 1.6)
			when 2, -1 then
				a_p.line (a_cx - h, a_cy - a_s, a_cx + h, a_cy, 1.6)
				a_p.line (a_cx + h, a_cy, a_cx - h, a_cy + a_s, 1.6)
			when 3 then
				a_p.line (a_cx - a_s, a_cy - h, a_cx, a_cy + h, 1.6)
				a_p.line (a_cx, a_cy + h, a_cx + a_s, a_cy - h, 1.6)
			else
				a_p.line (a_cx - a_s, a_cy + h, a_cx, a_cy - h, 1.6)
				a_p.line (a_cx, a_cy - h, a_cx + a_s, a_cy + h, 1.6)
			end
		end

	draw_strip (a_p: SW_PAINTER)
			-- The folded zone: its quiet ground, then each panel's name
			-- along the strip - turned a quarter clockwise on the west and
			-- east, so it reads downward - and a dot after a marked one.
		local
			t: SW_THEME
			l_title: STRING_32
			l_hot: BOOLEAN
			l_base, l_adv: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			title_font (a_p)
			across
				strip_titles as al_s
			loop
				l_title := host.panels.i_th (al_s.panel).title
				l_adv := a_p.advance (l_title)
				if is_across then
					l_hot := shows_hover and then hover_px >= al_s.lo and then hover_px < al_s.hi and then contains (hover_px, hover_py)
				else
					l_hot := shows_hover and then hover_py >= al_s.lo and then hover_py < al_s.hi and then contains (hover_px, hover_py)
				end
				if l_hot then
					a_p.set_color (t.surface)
					if is_across then
						a_p.rrect_fill (al_s.lo, y + 3.0, al_s.hi - al_s.lo, height - 6.0, 3.0)
					else
						a_p.rrect_fill (x + 3.0, al_s.lo, width - 6.0, al_s.hi - al_s.lo, 3.0)
					end
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.ink_muted)
				end
				if is_across then
					a_p.text (al_s.lo + tab_pad, y + (height - a_p.text_extent) / 2.0 + a_p.font_ascent, l_title)
					if host.is_panel_marked (al_s.panel) then
						a_p.set_color (t.accent)
						a_p.circle_fill (al_s.lo + tab_pad + l_adv + bar_h / 4.0, y + height / 2.0, 3.5)
					end
				else
						-- turned a quarter clockwise: a glyph's top faces east,
						-- so the line box spans [base - descent, base + ascent]
					l_base := x + width / 2.0 - (a_p.font_ascent - a_p.font_descent) / 2.0
					a_p.push_rotation (l_base, al_s.lo + tab_pad, Quarter_turn)
					a_p.text (0.0, 0.0, l_title)
					if host.is_panel_marked (al_s.panel) then
						a_p.set_color (t.accent)
						a_p.circle_fill (l_adv + bar_h / 4.0, -(a_p.font_ascent - a_p.font_descent) / 2.0, 3.5)
					end
					a_p.pop_transform
				end
			end
		end

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
	buttons_attached: buttons /= Void and strip_titles /= Void

end
