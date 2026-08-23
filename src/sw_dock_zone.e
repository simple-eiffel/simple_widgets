note
	description: "[
		One docking zone: its panels stacked in equal shares, each
		under a title bar. A title bar is a PEBBLE source (middle-
		click lifts the panel id) and the whole zone is a drop hole
		- receiving asks the host to move_panel here, and the
		reflow follows. Hit testing routes THROUGH to panel
		contents, so docked widgets stay fully alive. The title-bar
		row arithmetic (panel_at_bar) is public and assaulted.
	]"

class
	SW_DOCK_ZONE

inherit
	SW_WIDGET
		redefine
			widget_at, pebble_at, accepts_pebble, receive_pebble, arrange
		end

create
	make_on

feature {NONE} -- Initialization

	make_on (a_host: SW_DOCK_HOST; a_zone: INTEGER)
		require
			zone_positive: a_zone >= 1
		do
			host := a_host
			zone_id := a_zone
		ensure
			hosted: host = a_host and zone_id = a_zone
		end

feature -- Access

	host: SW_DOCK_HOST

	zone_id: INTEGER

	Bar_h: REAL_64 = 22.0

	panel_slot_h: REAL_64
			-- Each panel's share of the zone, bar included.
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
			-- The panel id whose TITLE BAR sits under a surface y;
			-- 0 elsewhere. Public bar arithmetic.
		local
			mine: ARRAYED_LIST [INTEGER]
			slot: INTEGER
			within: REAL_64
		do
			mine := host.panels_in (zone_id)
			if not mine.is_empty and then panel_slot_h > 0.0
				and then a_py >= y and then a_py < y + height
			then
				slot := ((a_py - y) / panel_slot_h).truncated_to_integer + 1
				if slot >= 1 and slot <= mine.count then
					within := a_py - y - (slot - 1) * panel_slot_h
					if within <= Bar_h then
						Result := mine.i_th (slot)
					end
				end
			end
		end

feature -- Pebbles

	pebble_at (a_px, a_py: REAL_64): detachable ANY
		local
			id: INTEGER
		do
			id := panel_at_bar (a_py)
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

feature -- Layout

	arrange (a_p: SW_PAINTER)
		local
			mine: ARRAYED_LIST [INTEGER]
			i: INTEGER
			sy: REAL_64
		do
			mine := host.panels_in (zone_id)
			from
				i := 1
			until
				i > mine.count
			loop
				sy := y + (i - 1) * panel_slot_h
				host.panels.i_th (mine.i_th (i)).content.set_bounds
					(x + 2.0, sy + Bar_h, (width - 4.0).max (1.0),
					(panel_slot_h - Bar_h - 2.0).max (1.0))
				host.panels.i_th (mine.i_th (i)).content.arrange (a_p)
				i := i + 1
			end
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- Title bars answer as the zone; contents answer as
			-- themselves - docked widgets stay alive.
		local
			mine: ARRAYED_LIST [INTEGER]
			i: INTEGER
		do
			if contains (a_px, a_py) then
				if panel_at_bar (a_py) > 0 then
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
			i: INTEGER
			sy: REAL_64
		do
			if width > 1.0 and height > 1.0 then
				t := a_p.theme
				a_p.set_color (t.surface)
				a_p.fill_rect (x, y, width, height)
				mine := host.panels_in (zone_id)
				from
					i := 1
				until
					i > mine.count
				loop
					sy := y + (i - 1) * panel_slot_h
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (x + 1.0, sy + 1.0, width - 2.0, Bar_h - 1.0)
					a_p.font ({SW_PAINTER}.Role_ui, 11.5, True)
					a_p.set_color (t.ink_muted)
					a_p.text (x + 8.0, sy + Bar_h - 7.0,
						host.panels.i_th (mine.i_th (i)).title)
					host.panels.i_th (mine.i_th (i)).content.draw (a_p)
					i := i + 1
				end
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, 2.0)
			end
		end

invariant
	hosted: host /= Void
	zone_positive: zone_id >= 1

end
