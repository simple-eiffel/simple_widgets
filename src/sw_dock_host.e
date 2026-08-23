note
	description: "[
		True docking, as promised when the overlap law was declared:
		workbench panels that REFLOW content instead of floating
		over it. Three zones - west, east, south - each a real
		widget stacking its panels under title bars, around a
		centre document that takes every pixel the zones do not.
		An EMPTY ZONE COLLAPSES TO NOTHING - that collapse is the
		whole point, and the zone-rectangle math (zone_rect) is
		public and assaulted. Panels move between zones by
		pick-and-drop (middle-click a title bar, drop on another
		zone) or programmatically (move_panel), firing
		on_layout_change either way.
	]"

class
	SW_DOCK_HOST

inherit
	SW_WIDGET
		redefine
			arrange, widget_at, sub_widgets
		end

create
	make

feature -- Zones

	Zone_west: INTEGER = 1
	Zone_east: INTEGER = 2
	Zone_south: INTEGER = 3

feature {NONE} -- Initialization

	make (a_center: SW_WIDGET)
		do
			center := a_center
			create panels.make (6)
			west_fraction := 0.22
			east_fraction := 0.24
			south_fraction := 0.30
			a_center.set_parent (Current)
		ensure
			centred: center = a_center
		end

feature -- Access

	center: SW_WIDGET

	panels: ARRAYED_LIST [TUPLE [title: STRING_32; content: SW_WIDGET; zone: INTEGER]]

	west_fraction, east_fraction, south_fraction: REAL_64

	on_layout_change: detachable PROCEDURE

	panels_in (a_zone: INTEGER): ARRAYED_LIST [INTEGER]
		require
			zone_known: a_zone >= Zone_west and a_zone <= Zone_south
		local
			i: INTEGER
		do
			create Result.make (4)
			from
				i := 1
			until
				i > panels.count
			loop
				if panels.i_th (i).zone = a_zone then
					Result.extend (i)
				end
				i := i + 1
			end
		end

	zone_rect (a_zone: INTEGER): TUPLE [rx, ry, rw, rh: REAL_64]
			-- Where a zone stands right now - COLLAPSED to zero
			-- extent when it holds no panels. Public reflow math.
		require
			zone_known: a_zone >= Zone_west and a_zone <= Zone_south
		local
			ww, ew, sh: REAL_64
		do
			if panels_in (Zone_west).is_empty then
				ww := 0.0
			else
				ww := width * west_fraction
			end
			if panels_in (Zone_east).is_empty then
				ew := 0.0
			else
				ew := width * east_fraction
			end
			if panels_in (Zone_south).is_empty then
				sh := 0.0
			else
				sh := height * south_fraction
			end
			inspect a_zone
			when Zone_west then
				Result := [x, y, ww, height - sh]
			when Zone_east then
				Result := [x + width - ew, y, ew, height - sh]
			else
				Result := [x, y + height - sh, width, sh]
			end
		end

	center_rect: TUPLE [rx, ry, rw, rh: REAL_64]
			-- Every pixel the zones do not take.
		local
			w_r, e_r, s_r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			w_r := zone_rect (Zone_west)
			e_r := zone_rect (Zone_east)
			s_r := zone_rect (Zone_south)
			Result := [x + w_r.rw, y, width - w_r.rw - e_r.rw, height - s_r.rh]
		end

feature -- Element change

	add_panel (a_title: READABLE_STRING_GENERAL; a_content: SW_WIDGET; a_zone: INTEGER): INTEGER
		require
			zone_known: a_zone >= Zone_west and a_zone <= Zone_south
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_title)
			a_content.set_parent (Current)
			panels.extend ([l, a_content, a_zone])
			Result := panels.count
			announce
		ensure
			grew: panels.count = old panels.count + 1
		end

	move_panel (a_panel, a_zone: INTEGER)
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			zone_known: a_zone >= Zone_west and a_zone <= Zone_south
		do
			if panels.i_th (a_panel).zone /= a_zone then
				panels.i_th (a_panel).zone := a_zone
				announce
			end
		ensure
			moved: panels.i_th (a_panel).zone = a_zone
		end

	set_on_layout_change (a_action: PROCEDURE)
		do
			on_layout_change := a_action
		ensure
			set: on_layout_change = a_action
		end

feature -- Layout

	arrange (a_p: SW_PAINTER)
		local
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			r := zone_rect (Zone_west)
			west_zone.set_bounds (r.rx, r.ry, r.rw, r.rh)
			west_zone.arrange (a_p)
			r := zone_rect (Zone_east)
			east_zone.set_bounds (r.rx, r.ry, r.rw, r.rh)
			east_zone.arrange (a_p)
			r := zone_rect (Zone_south)
			south_zone.set_bounds (r.rx, r.ry, r.rw, r.rh)
			south_zone.arrange (a_p)
			r := center_rect
			center.set_bounds (r.rx, r.ry, r.rw, r.rh)
			center.arrange (a_p)
		end

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (4)
			Result.extend (west_zone)
			Result.extend (east_zone)
			Result.extend (south_zone)
			Result.extend (center)
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				Result := west_zone.widget_at (a_px, a_py)
				if Result = Void then
					Result := east_zone.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := south_zone.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := center.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Preferred size

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 420.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			west_zone.draw (a_p)
			east_zone.draw (a_p)
			south_zone.draw (a_p)
			center.draw (a_p)
		end

feature {NONE} -- Organs

	west_zone: SW_DOCK_ZONE
			-- Self-initializing: the mutual Current/zone knot unties
			-- itself on first access, after creation completes.
		attribute
			create Result.make_on (Current, Zone_west)
		end

	east_zone: SW_DOCK_ZONE
		attribute
			create Result.make_on (Current, Zone_east)
		end

	south_zone: SW_DOCK_ZONE
		attribute
			create Result.make_on (Current, Zone_south)
		end

	announce
		do
			if attached on_layout_change as a then
				a.call (Void)
			end
		end

invariant
	organs: center /= Void and panels /= Void
	zones_hold: across panels as p all
		p.zone >= Zone_west and p.zone <= Zone_south end

end
