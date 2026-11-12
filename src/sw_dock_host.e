note
	description: "[
		True docking, as promised when the overlap law was declared:
		workbench panels that REFLOW content instead of floating
		over it. Three zones - west, east, south - each a real
		widget holding its panels, around a center document that
		takes every pixel the zones do not. An EMPTY ZONE COLLAPSES
		TO NOTHING - that collapse is the whole point, and the
		zone-rectangle math (zone_rect) is public and assaulted.
		Panels move between zones by pick-and-drop (middle-click a
		title bar or a tab, drop on another zone) or programmatically
		(move_panel), firing on_layout_change either way.

		GW-05 (for simple_bible's Study layout, five panels in the
		south zone, and its session restore):

		    TABS          a zone stacks its panels in equal shares, or
		                  (set_tabbed) shows one at a time under a tab
		                  strip; activate_panel picks the one shown
		    EDGES         each open zone's inner edge drags to resize
		                  it (set_fraction programmatically); the center
		                  always keeps Min_center pixels
		    HIDE/REMOVE   hide_panel and show_panel keep a panel and
		                  its place; remove_panel lets it go (the ids
		                  after it shift down, so durable identity is
		                  the panel's KEY - add_keyed_panel, panel_by_key)
		    FOLD          (0.46.0) collapse_zone folds a west, east or
		                  south zone to a strip along the window's edge
		                  that still names its panels (a click on a name
		                  brings the zone back showing that panel);
		                  set_panel_marked puts a dot beside a name there
		    MAXIMIZE      (0.46.0) maximize_panel lets a maximizable panel
		                  take the whole host until restore_maximized;
		                  each title bar draws its buttons (SW_DOCK_ZONE)
		    FLOATING      (GW-22) float_panel takes a panel out of its
		                  zone into a floating window (SW_WINDOW does the
		                  window: enable_floating_panels, then a double
		                  click on a tab or title bar); redock_panel puts it
		                  back where it was
		    ORDER         (1r-b) each zone keeps an explicit order of panel
		                  ids; move_panel_to puts a panel at a place among
		                  its zone's panels without changing any id
		    AUTO-HIDE     (1r-b) set_auto_hide stands a zone as its folded
		                  strip; a press (or a dwell) on a name slides
		                  that panel OUT over the center (slide_out,
		                  slide_back, slid_out_panel) without reflow
		    CENTER        (1r-b) maximize_center gives the center the
		                  whole host; restore_center brings every zone
		                  back with its fold, auto-hide and fraction
		    SNAPSHOT      layout_snapshot writes fractions, tab modes,
		                  every panel's key, zone, visibility and order,
		                  and each tabbed zone's active panel as text;
		                  restore_layout reads it back, all or nothing
	]"

class
	SW_DOCK_HOST

inherit
	SW_WIDGET
		redefine
			arrange, widget_at, sub_widgets, handle_click, handle_drag,
			handle_release, wants_hover_point, cursor_kind
		end

create
	make

feature -- Zones

	Zone_west: INTEGER = 1
	Zone_east: INTEGER = 2
	Zone_south: INTEGER = 3
	Zone_north: INTEGER = 4

	Min_fraction: REAL_64 = 0.08
			-- The smallest share a zone may be given.

	Max_fraction: REAL_64 = 0.7
			-- The largest share a zone may be given.

	Min_center: REAL_64 = 120.0
			-- Pixels the center keeps across and down, whatever the
			-- zones ask for.

	Edge_grip: REAL_64 = 4.0
			-- How far either side of a zone's inner edge a press grabs it.

feature {NONE} -- Initialization

	make (a_center: SW_WIDGET)
		local
			l_z: INTEGER
		do
			center := a_center
			create panels.make (6)
			west_fraction := 0.22
			east_fraction := 0.24
			south_fraction := 0.30
			north_fraction := 0.20
			create tabbed_flags.make_filled (False, Zone_west, Zone_north)
			create collapsed_flags.make_filled (False, Zone_west, Zone_north)
			create active_ids.make_filled (0, Zone_west, Zone_north)
			create auto_hide_flags.make_filled (False, Zone_west, Zone_north)
			create zone_orders.make_filled (create {ARRAYED_LIST [INTEGER]}.make (0), Zone_west, Zone_north)
			from
				l_z := Zone_west
			until
				l_z > Zone_north
			loop
				zone_orders [l_z] := create {ARRAYED_LIST [INTEGER]}.make (4)
				l_z := l_z + 1
			end
			a_center.set_parent (Current)
		ensure
			centered: center = a_center
			empty: panels.is_empty
			stacked: not is_tabbed (Zone_west) and not is_tabbed (Zone_east) and not is_tabbed (Zone_south)
				and not is_tabbed (Zone_north)
		end

feature -- Access

	center: SW_WIDGET

	panels: ARRAYED_LIST [TUPLE [title: STRING_32; content: SW_WIDGET; zone: INTEGER; key: STRING_32; is_visible: BOOLEAN]]
			-- Every panel, visible or hidden, in order; a panel's id is its
			-- index here.

	west_fraction, east_fraction, south_fraction, north_fraction: REAL_64
			-- Each zone's share of the host (west and east across, south
			-- and north down) while it holds a visible panel.

	fraction (a_zone: INTEGER): REAL_64
		require
			zone_known: is_zone (a_zone)
		do
			inspect a_zone
			when Zone_west then
				Result := west_fraction
			when Zone_east then
				Result := east_fraction
			when Zone_north then
				Result := north_fraction
			else
				Result := south_fraction
			end
		end

	on_layout_change: detachable PROCEDURE

	is_zone (a_zone: INTEGER): BOOLEAN
		do
			Result := a_zone >= Zone_west and a_zone <= Zone_north
		end

	is_usable_key (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_key' stand in a snapshot line: not empty, no tab, no
			-- line break, no outer spaces?
		do
			Result := not a_key.is_empty and then not a_key.has ('%T') and then not a_key.has ('%N')
				and then not a_key.has ('%R') and then a_key [1] /= ' ' and then a_key [a_key.count] /= ' '
		end

	panels_in (a_zone: INTEGER): ARRAYED_LIST [INTEGER]
			-- The VISIBLE panels of `a_zone', in the zone's order.
		require
			zone_known: is_zone (a_zone)
		do
			create Result.make (4)
			across
				zone_orders [a_zone] as ic
			loop
				if panels.i_th (ic).is_visible then
					Result.extend (ic)
				end
			end
		end

	all_panels_in (a_zone: INTEGER): ARRAYED_LIST [INTEGER]
			-- Every panel of `a_zone', hidden ones too, in the zone's order
			-- (`move_panel_to' changes it).
		require
			zone_known: is_zone (a_zone)
		do
			create Result.make (4)
			across
				zone_orders [a_zone] as ic
			loop
				Result.extend (ic)
			end
		ensure
			all_there: Result.count >= panels_in (a_zone).count
		end

	panel_by_key (a_key: READABLE_STRING_GENERAL): INTEGER
			-- The panel whose key is `a_key'; 0 for none.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > panels.count or Result > 0
			loop
				if panels.i_th (i).key.same_string_general (a_key) then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= panels.count
		end

	is_panel_visible (a_panel: INTEGER): BOOLEAN
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := panels.i_th (a_panel).is_visible
		end

	is_tabbed (a_zone: INTEGER): BOOLEAN
			-- Does `a_zone' show one panel at a time under tabs?
		require
			zone_known: is_zone (a_zone)
		do
			Result := tabbed_flags [a_zone]
		end

	active_panel (a_zone: INTEGER): INTEGER
			-- The panel a tabbed zone shows: the one last activated while
			-- it is still visible there, else the zone's first; 0 when the
			-- zone shows nothing.
		require
			zone_known: is_zone (a_zone)
		local
			l_id: INTEGER
		do
			l_id := active_ids [a_zone]
			if l_id >= 1 and then l_id <= panels.count and then panels.i_th (l_id).zone = a_zone
				and then panels.i_th (l_id).is_visible
			then
				Result := l_id
			elseif not panels_in (a_zone).is_empty then
				Result := panels_in (a_zone).first
			end
		ensure
			shown_or_none: Result = 0 or else (panels.i_th (Result).zone = a_zone and panels.i_th (Result).is_visible)
		end

	zone_rect (a_zone: INTEGER): TUPLE [rx, ry, rw, rh: REAL_64]
			-- Where a zone stands right now - COLLAPSED to zero extent
			-- when it shows no panel, and never so wide or tall that the
			-- center keeps less than `Min_center'. Public reflow math.
		require
			zone_known: is_zone (a_zone)
		local
			ww, ew, sh, nh, l_room, l_scale: REAL_64
		do
			if center_maximized then
					-- the center has the host; every zone stands nowhere
				Result := [x, y, 0.0, 0.0]
			elseif maximized_panel > 0 then
					-- a maximized panel's zone takes the host; the rest stand nowhere
				if panels.i_th (maximized_panel).zone = a_zone then
					Result := [x, y, width, height]
				else
					Result := [x, y, 0.0, 0.0]
				end
			else
				ww := zone_extent (Zone_west, width)
				ew := zone_extent (Zone_east, width)
				sh := zone_extent (Zone_south, height)
				l_room := (width - Min_center).max (0.0)
				if ww + ew > l_room and then ww + ew > 0.0 then
					l_scale := l_room / (ww + ew)
					ww := ww * l_scale
					ew := ew * l_scale
				end
				nh := zone_extent (Zone_north, height)
				l_room := (height - Min_center).max (0.0)
				if sh + nh > l_room and then sh + nh > 0.0 then
					l_scale := l_room / (sh + nh)
					sh := sh * l_scale
					nh := nh * l_scale
				end
				inspect a_zone
				when Zone_west then
					Result := [x, y + nh, ww, height - nh - sh]
				when Zone_east then
					Result := [x + width - ew, y + nh, ew, height - nh - sh]
				when Zone_north then
					Result := [x, y, width, nh]
				else
					Result := [x, y + height - sh, width, sh]
				end
			end
		end

	center_rect: TUPLE [rx, ry, rw, rh: REAL_64]
			-- Every pixel the zones do not take.
		local
			w_r, e_r, s_r, n_r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			w_r := zone_rect (Zone_west)
			e_r := zone_rect (Zone_east)
			s_r := zone_rect (Zone_south)
			n_r := zone_rect (Zone_north)
			if center_maximized then
				Result := [x, y, width, height]
			elseif maximized_panel > 0 then
				Result := [x, y, 0.0, 0.0]
			else
				Result := [x + w_r.rw, y + n_r.rh, width - w_r.rw - e_r.rw, height - n_r.rh - s_r.rh]
			end
		end

	edge_at (a_px, a_py: REAL_64): INTEGER
			-- The zone whose inner edge is under the point (within
			-- `Edge_grip'); 0 when none. An empty or folded zone has no
			-- edge, and none has while a panel is maximized.
		local
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			if contains (a_px, a_py) and then maximized_panel = 0 and then not center_maximized then
				r := zone_rect (Zone_south)
				if r.rh > 0.0 and then not stands_as_strip (Zone_south) and then (a_py - r.ry).abs <= Edge_grip then
					Result := Zone_south
				end
				r := zone_rect (Zone_north)
				if Result = 0 and then r.rh > 0.0 and then not stands_as_strip (Zone_north) and then (a_py - (r.ry + r.rh)).abs <= Edge_grip then
					Result := Zone_north
				end
				r := zone_rect (Zone_west)
				if Result = 0 and then r.rw > 0.0 and then not stands_as_strip (Zone_west) and then a_py >= r.ry and then a_py < r.ry + r.rh
					and then (a_px - (r.rx + r.rw)).abs <= Edge_grip
				then
					Result := Zone_west
				end
				r := zone_rect (Zone_east)
				if Result = 0 and then r.rw > 0.0 and then not stands_as_strip (Zone_east) and then a_py >= r.ry and then a_py < r.ry + r.rh
					and then (a_px - r.rx).abs <= Edge_grip
				then
					Result := Zone_east
				end
			end
		ensure
			zone_or_none: Result = 0 or else is_zone (Result)
		end

	dragging_edge: INTEGER
			-- The zone whose edge is being dragged; 0 = none.

	zone_widget (a_zone: INTEGER): SW_DOCK_ZONE
			-- The widget that draws `a_zone' (its tabs, its bars).
		require
			zone_known: is_zone (a_zone)
		do
			inspect a_zone
			when Zone_west then
				Result := west_zone
			when Zone_east then
				Result := east_zone
			when Zone_north then
				Result := north_zone
			else
				Result := south_zone
			end
		ensure
			that_zone: Result.zone_id = a_zone
		end

feature -- Element change

	add_panel (a_title: READABLE_STRING_GENERAL; a_content: SW_WIDGET; a_zone: INTEGER): INTEGER
			-- A visible panel titled (and keyed) `a_title' at the end of
			-- `a_zone'; its id.
		require
			zone_known: is_zone (a_zone)
			title_usable_as_key: is_usable_key (a_title)
		do
			Result := add_keyed_panel (a_title, a_title, a_content, a_zone)
		ensure
			grew: panels.count = old panels.count + 1
			last: Result = panels.count
		end

	add_keyed_panel (a_key, a_title: READABLE_STRING_GENERAL; a_content: SW_WIDGET; a_zone: INTEGER): INTEGER
			-- `add_panel', with a key that names the panel in a snapshot
			-- (titles may be translated; keys stay put).
		require
			zone_known: is_zone (a_zone)
			key_usable: is_usable_key (a_key)
		local
			l_title, l_key: STRING_32
		do
			create l_title.make_from_string_general (a_title)
			create l_key.make_from_string_general (a_key)
			a_content.set_parent (Current)
			panels.extend ([l_title, a_content, a_zone, l_key, True])
			Result := panels.count
			zone_orders [a_zone].extend (Result)
			announce
		ensure
			grew: panels.count = old panels.count + 1
			last: Result = panels.count
			visible: is_panel_visible (Result)
			ends_its_zone: all_panels_in (a_zone).last = Result
		end

	move_panel (a_panel, a_zone: INTEGER)
			-- Put panel `a_panel' in `a_zone' (where a tabbed zone shows it).
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			zone_known: is_zone (a_zone)
		do
				-- 2026-11-11 (port-coordination#58): a panel already in `a_zone' but not last
				-- moves to its end too, as `ends_its_zone' promises; it used to stay put.
			if panels.i_th (a_panel).zone /= a_zone or else zone_orders [a_zone].last /= a_panel then
				relocate (a_panel, a_zone)
				announce
			end
		ensure
			moved: panels.i_th (a_panel).zone = a_zone
			ends_its_zone: all_panels_in (a_zone).last = a_panel
		end

	move_panel_to (a_panel, a_zone, a_position: INTEGER)
			-- Put panel `a_panel' at place `a_position' (from 1) among the
			-- panels of `a_zone', hidden ones counted, moving it there first
			-- when it is elsewhere. No panel's id changes.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			zone_known: is_zone (a_zone)
			position_in_range: a_position >= 1 and a_position <= all_panels_in (a_zone).count
				+ (if panels.i_th (a_panel).zone = a_zone then 0 else 1 end)
		local
			l_changed: BOOLEAN
			l_order: ARRAYED_LIST [INTEGER]
		do
			if panels.i_th (a_panel).zone /= a_zone then
				relocate (a_panel, a_zone)
				l_changed := True
			end
			l_order := zone_orders [a_zone]
			if l_order.i_th (a_position) /= a_panel then
				l_order.prune_all (a_panel)
				if a_position > l_order.count then
					l_order.extend (a_panel)
				else
					l_order.go_i_th (a_position)
					l_order.put_left (a_panel)
				end
				l_changed := True
			end
			if l_changed then
				announce
			end
		ensure
			placed: all_panels_in (a_zone).i_th (a_position) = a_panel
			in_zone: panels.i_th (a_panel).zone = a_zone
			ids_stay: panels.count = old panels.count
		end

	hide_panel (a_panel: INTEGER)
			-- Take panel `a_panel' off screen; it keeps its zone and place.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			if panels.i_th (a_panel).is_visible then
				panels.i_th (a_panel).is_visible := False
				if maximized_panel = a_panel then
					maximized_panel := 0
				end
				if slid_out_panel = a_panel then
					slid_out_panel := 0
				end
				announce
			end
		ensure
			hidden: not is_panel_visible (a_panel)
			not_maximized: maximized_panel /= a_panel
		end

	show_panel (a_panel: INTEGER)
			-- Bring panel `a_panel' back where it was (shown, in a tabbed zone).
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			not_floating: not is_floating (a_panel)
		do
			if not panels.i_th (a_panel).is_visible then
				panels.i_th (a_panel).is_visible := True
				active_ids [panels.i_th (a_panel).zone] := a_panel
				announce
			end
		ensure
			shown: is_panel_visible (a_panel)
		end

	remove_panel (a_panel: INTEGER)
			-- Let panel `a_panel' go; the ids after it shift down by one.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		local
			z: INTEGER
		do
			panels.i_th (a_panel).content.set_parent (Void)
			forget_floating_key (panels.i_th (a_panel).key)
			forget_key (maximizable_keys, panels.i_th (a_panel).key)
			forget_key (marked_keys, panels.i_th (a_panel).key)
			panel_fields.remove (panels.i_th (a_panel).key)
			if maximized_panel = a_panel then
				maximized_panel := 0
			elseif maximized_panel > a_panel then
				maximized_panel := maximized_panel - 1
			end
			if slid_out_panel = a_panel then
				slid_out_panel := 0
			elseif slid_out_panel > a_panel then
				slid_out_panel := slid_out_panel - 1
			end
			panels.go_i_th (a_panel)
			panels.remove
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				zone_orders [z].prune_all (a_panel)
				from
					zone_orders [z].start
				until
					zone_orders [z].after
				loop
					if zone_orders [z].item > a_panel then
						zone_orders [z].put (zone_orders [z].item - 1)
					end
					zone_orders [z].forth
				end
				if active_ids [z] = a_panel then
					active_ids [z] := 0
				elseif active_ids [z] > a_panel then
					active_ids [z] := active_ids [z] - 1
				end
				z := z + 1
			end
			announce
		ensure
			one_fewer: panels.count = old panels.count - 1
		end

	activate_panel (a_panel: INTEGER)
			-- Show panel `a_panel' in its tabbed zone.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			visible: is_panel_visible (a_panel)
		do
			if active_panel (panels.i_th (a_panel).zone) /= a_panel then
				active_ids [panels.i_th (a_panel).zone] := a_panel
				announce
			end
		ensure
			shown: active_panel (panels.i_th (a_panel).zone) = a_panel
		end

	set_fraction (a_zone: INTEGER; a_fraction: REAL_64)
			-- Give `a_zone' `a_fraction' of the host.
		require
			zone_known: is_zone (a_zone)
			in_range: a_fraction >= Min_fraction and a_fraction <= Max_fraction
		do
			if fraction (a_zone) /= a_fraction then
				put_fraction (a_zone, a_fraction)
				announce
			end
		ensure
			set: fraction (a_zone) = a_fraction
		end

	set_tabbed (a_zone: INTEGER; a_tabbed: BOOLEAN)
			-- One panel at a time under tabs, or stacked in equal shares.
		require
			zone_known: is_zone (a_zone)
		do
			if tabbed_flags [a_zone] /= a_tabbed then
				tabbed_flags [a_zone] := a_tabbed
				announce
			end
		ensure
			set: is_tabbed (a_zone) = a_tabbed
		end

	set_on_layout_change (a_action: PROCEDURE)
		do
			on_layout_change := a_action
		ensure
			set: on_layout_change = a_action
		end

feature -- Folding and maximizing (0.46.0)

	is_collapsed (a_zone: INTEGER): BOOLEAN
			-- Was `a_zone' folded to a strip (`collapse_zone')? It shows as
			-- one only while it holds a visible panel (`is_folded').
		require
			zone_known: is_zone (a_zone)
		do
			Result := collapsed_flags [a_zone]
		end

	is_folded (a_zone: INTEGER): BOOLEAN
			-- Does `a_zone' stand as a strip right now: collapsed or auto-hide,
			-- holding a visible panel, and neither a panel nor the center maximized?
		require
			zone_known: is_zone (a_zone)
		do
			Result := stands_as_strip (a_zone) and then maximized_panel = 0 and then not center_maximized
				and then not panels_in (a_zone).is_empty
		end

	strip_extent (a_zone: INTEGER): REAL_64
			-- How wide (west, east) or tall (south, north) a folded zone stands:
			-- its title bar's height and a margin, so it grows with the text.
		require
			zone_known: is_zone (a_zone)
		do
			Result := zone_widget (a_zone).bar_h + 8.0
		ensure
			positive: Result > 0.0
		end

	collapse_zone (a_zone: INTEGER)
			-- Fold `a_zone' to a strip along the host's edge; its panels keep
			-- their places and the center takes the room.
		require
			zone_known: is_zone (a_zone)
		do
			if not collapsed_flags [a_zone] then
				collapsed_flags [a_zone] := True
				announce
			end
		ensure
			collapsed: is_collapsed (a_zone)
		end

	expand_zone (a_zone: INTEGER)
			-- Bring folded `a_zone' back at its fraction; auto-hide ends too.
		require
			zone_known: is_zone (a_zone)
		do
			if collapsed_flags [a_zone] or auto_hide_flags [a_zone] then
				collapsed_flags [a_zone] := False
				auto_hide_flags [a_zone] := False
				if slid_out_panel > 0 and then panels.i_th (slid_out_panel).zone = a_zone then
					slid_out_panel := 0
				end
				announce
			end
		ensure
			opened: not is_collapsed (a_zone) and not is_auto_hide (a_zone)
		end

	toggle_zone (a_zone: INTEGER)
			-- Fold `a_zone' when open, open it when folded.
		require
			zone_known: is_zone (a_zone)
		do
			if collapsed_flags [a_zone] then
				expand_zone (a_zone)
			else
				collapse_zone (a_zone)
			end
		ensure
			toggled: is_collapsed (a_zone) = not old is_collapsed (a_zone)
		end

	set_all_collapsed (a_collapsed: BOOLEAN)
			-- Fold every zone, or open every zone, with one
			-- `on_layout_change' - a reader's "focus" on the center.
		local
			z: INTEGER
			l_changed: BOOLEAN
		do
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				if collapsed_flags [z] /= a_collapsed then
					collapsed_flags [z] := a_collapsed
					l_changed := True
				end
				z := z + 1
			end
			if l_changed then
				announce
			end
		ensure
			west: is_collapsed (Zone_west) = a_collapsed
			east: is_collapsed (Zone_east) = a_collapsed
			south: is_collapsed (Zone_south) = a_collapsed
			north: is_collapsed (Zone_north) = a_collapsed
		end

	is_focused_on_center: BOOLEAN
			-- Is every zone that holds a visible panel folded?
		local
			z: INTEGER
		do
			Result := True
			from
				z := Zone_west
			until
				z > Zone_north or not Result
			loop
				Result := panels_in (z).is_empty or else stands_as_strip (z)
				z := z + 1
			end
		end

	maximized_panel: INTEGER
			-- The panel taking the whole host; 0 = none.

	is_maximizable (a_panel: INTEGER): BOOLEAN
			-- Does panel `a_panel''s title bar offer Maximize?
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := has_key (maximizable_keys, panels.i_th (a_panel).key)
		end

	set_maximizable (a_panel: INTEGER; a_maximizable: BOOLEAN)
			-- Offer Maximize on panel `a_panel''s title bar, or stop.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			forget_key (maximizable_keys, panels.i_th (a_panel).key)
			if a_maximizable then
				maximizable_keys.extend (panels.i_th (a_panel).key.twin)
			elseif maximized_panel = a_panel then
				restore_maximized
			end
		ensure
			set: is_maximizable (a_panel) = a_maximizable
		end

	maximize_panel (a_panel: INTEGER)
			-- Let panel `a_panel' take the whole host - the center and the
			-- other zones step aside - until `restore_maximized'.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			maximizable: is_maximizable (a_panel)
			visible: is_panel_visible (a_panel)
		do
			if maximized_panel /= a_panel or center_maximized then
				center_maximized := False
				slid_out_panel := 0
				maximized_panel := a_panel
				active_ids [panels.i_th (a_panel).zone] := a_panel
				announce
			end
		ensure
			maximized: maximized_panel = a_panel
			center_restored: not center_maximized
		end

	restore_maximized
			-- Put a maximized panel back in its zone, beside the others.
		do
			if maximized_panel > 0 then
				maximized_panel := 0
				announce
			end
		ensure
			restored: maximized_panel = 0
		end

	toggle_maximized (a_panel: INTEGER)
			-- Maximize panel `a_panel', or restore it when it is maximized.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			maximizable: is_maximizable (a_panel)
			visible: is_panel_visible (a_panel)
		do
			if maximized_panel = a_panel then
				restore_maximized
			else
				maximize_panel (a_panel)
			end
		end

	is_panel_marked (a_panel: INTEGER): BOOLEAN
			-- Does panel `a_panel''s name carry a dot on a folded strip -
			-- "there is something here for what you are looking at"?
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := has_key (marked_keys, panels.i_th (a_panel).key)
		end

	set_panel_marked (a_panel: INTEGER; a_marked: BOOLEAN)
			-- Put the dot beside panel `a_panel''s name, or take it away.
			-- Not a layout change: `on_layout_change' is not called.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			forget_key (marked_keys, panels.i_th (a_panel).key)
			if a_marked then
				marked_keys.extend (panels.i_th (a_panel).key.twin)
			end
		ensure
			set: is_panel_marked (a_panel) = a_marked
		end

feature -- Panel fields and pills (1r-c)

	panel_short_title (a_panel: INTEGER): STRING_32
			-- What tabs and strip names call panel `a_panel' when set; empty when not.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := field_of (a_panel, 1)
		end

	panel_description (a_panel: INTEGER): STRING_32
			-- The panel's description, the tip of its pill; empty when not set.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := field_of (a_panel, 2)
		end

	panel_tooltip (a_panel: INTEGER): STRING_32
			-- The tooltip on the panel's tab and strip name; empty when not set.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := field_of (a_panel, 3)
		end

	panel_pill (a_panel: INTEGER): STRING_32
			-- The reference pill code shown on the panel's title bar and tab; empty for none.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := field_of (a_panel, 4)
		end

	set_panel_short_title (a_panel: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Tabs and strip names call panel `a_panel' `a_text'; the title bars keep the title.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			put_field (a_panel, 1, a_text)
		ensure
			set: panel_short_title (a_panel).same_string_general (a_text)
		end

	set_panel_description (a_panel: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			put_field (a_panel, 2, a_text)
		ensure
			set: panel_description (a_panel).same_string_general (a_text)
		end

	set_panel_tooltip (a_panel: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			put_field (a_panel, 3, a_text)
		ensure
			set: panel_tooltip (a_panel).same_string_general (a_text)
		end

	set_panel_pill (a_panel: INTEGER; a_code: READABLE_STRING_GENERAL)
			-- Name panel `a_panel' with the reference pill `a_code' (empty: none).
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			put_field (a_panel, 4, a_code)
		ensure
			set: panel_pill (a_panel).same_string_general (a_code)
		end

	tab_text (a_panel: INTEGER): STRING_32
			-- What panel `a_panel's tab and strip name show: the short title when set, else the title.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			if panel_short_title (a_panel).is_empty then
				Result := panels.i_th (a_panel).title.twin
			else
				Result := panel_short_title (a_panel)
			end
		ensure
			never_empty_when_titled: not panels.i_th (a_panel).title.is_empty implies not Result.is_empty
		end

	tab_tip (a_panel: INTEGER): STRING_32
			-- The tooltip on panel `a_panel's tab: its tooltip when set, else its description.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			if panel_tooltip (a_panel).is_empty then
				Result := panel_description (a_panel)
			else
				Result := panel_tooltip (a_panel)
			end
		end

feature {NONE} -- Panel field internals

	panel_fields: HASH_TABLE [ARRAY [STRING_32], STRING_32]
			-- Each panel's short title, description, tooltip and pill (in that order), by
			-- the panel's KEY, so ids may shift on a removal and the fields stay.
		attribute
			create Result.make (8)
		end

	field_of (a_panel, a_field: INTEGER): STRING_32
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			field_known: a_field >= 1 and a_field <= 4
		do
			if attached panel_fields.item (panels.i_th (a_panel).key) as al_fields then
				Result := al_fields [a_field].twin
			else
				create Result.make_empty
			end
		end

	put_field (a_panel, a_field: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			field_known: a_field >= 1 and a_field <= 4
		local
			l_fields: detachable ARRAY [STRING_32]
			l_key: STRING_32
		do
			l_key := panels.i_th (a_panel).key
			l_fields := panel_fields.item (l_key)
			if not attached l_fields then
				create l_fields.make_filled (create {STRING_32}.make_empty, 1, 4)
				panel_fields.force (l_fields, l_key.twin)
			end
			if attached l_fields as al_f then
				al_f [a_field] := create {STRING_32}.make_from_string_general (a_text)
			end
		end

feature -- Menu words

	zone_title (a_zone: INTEGER): STRING_32
			-- What a menu calls `a_zone': "left side", "right side", "bottom", "top panel area".
		require
			zone_known: is_zone (a_zone)
		do
			inspect a_zone
			when Zone_west then
				Result := "left side"
			when Zone_east then
				Result := "right side"
			when Zone_north then
				Result := "top panel area"
			else
				Result := "bottom"
			end
		end

feature -- Auto-hide and the maximized center (1r-b)

	is_auto_hide (a_zone: INTEGER): BOOLEAN
			-- Does `a_zone' stand as its strip, sliding a panel out over the
			-- center on a press or a rest on its name? It is not `is_collapsed'.
		require
			zone_known: is_zone (a_zone)
		do
			Result := auto_hide_flags [a_zone]
		end

	set_auto_hide (a_zone: INTEGER; a_on: BOOLEAN)
			-- Stand `a_zone' as an auto-hide strip, or bring it back.
		require
			zone_known: is_zone (a_zone)
		do
			if auto_hide_flags [a_zone] /= a_on then
				auto_hide_flags [a_zone] := a_on
				if not a_on and then slid_out_panel > 0 and then panels.i_th (slid_out_panel).zone = a_zone then
					slid_out_panel := 0
				end
				announce
			end
		ensure
			set: is_auto_hide (a_zone) = a_on
			collapse_untouched: is_collapsed (a_zone) = old is_collapsed (a_zone)
		end

	slid_out_panel: INTEGER
			-- The panel slid out over the center from an auto-hide strip; 0 = none.

	slide_out (a_panel: INTEGER)
			-- Show panel `a_panel' OVER the center, at its zone's size along
			-- the window's edge; the center does not reflow.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			visible: is_panel_visible (a_panel)
			auto_hidden: is_auto_hide (panels.i_th (a_panel).zone)
		do
			if slid_out_panel /= a_panel then
				slid_out_panel := a_panel
				active_ids [panels.i_th (a_panel).zone] := a_panel
				announce
			end
		ensure
			slid: slid_out_panel = a_panel
		end

	slide_back
			-- Take the slid-out panel back into its strip.
		do
			if slid_out_panel > 0 then
				slid_out_panel := 0
				announce
			end
		ensure
			none: slid_out_panel = 0
		end

	slide_rect: TUPLE [rx, ry, rw, rh: REAL_64]
			-- Where the slid-out panel stands, over the center and beside
			-- its strip; zero extent when none is out.
		local
			r: TUPLE [rx, ry, rw, rh: REAL_64]
			l_size: REAL_64
			l_zone: INTEGER
		do
			Result := [x, y, 0.0, 0.0]
			if slid_out_panel > 0 and then maximized_panel = 0 and then not center_maximized then
				l_zone := panels.i_th (slid_out_panel).zone
				r := zone_rect (l_zone)
				inspect l_zone
				when Zone_west then
					l_size := (width * west_fraction).min ((width - r.rw).max (0.0))
					Result := [r.rx + r.rw, r.ry, l_size, r.rh]
				when Zone_east then
					l_size := (width * east_fraction).min ((width - r.rw).max (0.0))
					Result := [r.rx - l_size, r.ry, l_size, r.rh]
				when Zone_north then
					l_size := (height * north_fraction).min ((height - r.rh).max (0.0))
					Result := [r.rx, r.ry + r.rh, r.rw, l_size]
				else
					l_size := (height * south_fraction).min ((height - r.rh).max (0.0))
					Result := [r.rx, r.ry - l_size, r.rw, l_size]
				end
			end
		end

	center_maximized: BOOLEAN
			-- Does the center have the whole host? Every zone stands nowhere
			-- (as under `maximize_panel'); each keeps its fold, auto-hide
			-- state and fraction, so `restore_center' gives them back.

	is_center_maximized: BOOLEAN
			-- Has `maximize_center' given the center the whole host?
		do
			Result := center_maximized
		end

	maximize_center
			-- The center takes the whole host; every zone folds away.
		do
			if not center_maximized then
				center_maximized := True
				maximized_panel := 0
				slid_out_panel := 0
				announce
			end
		ensure
			maximized: is_center_maximized
			no_panel_maximized: maximized_panel = 0
			nothing_slid: slid_out_panel = 0
		end

	restore_center
			-- Give every zone back, with its fold, auto-hide state and fraction.
		do
			if center_maximized then
				center_maximized := False
				announce
			end
		ensure
			restored: not is_center_maximized
		end

feature -- Floating (GW-22)

	is_floating (a_panel: INTEGER): BOOLEAN
			-- Is panel `a_panel' out of its zone, in a floating window?
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
		do
			Result := across floating_keys as al_key some al_key.same_string (panels.i_th (a_panel).key) end
		end

	can_float: BOOLEAN
			-- Does a double click on a tab or title bar float its panel?
		do
			Result := on_float_request /= Void
		end

	on_float_request: detachable PROCEDURE [INTEGER]
			-- Asked to float a panel (SW_WINDOW.enable_floating_panels).

	set_on_float_request (a_action: PROCEDURE [INTEGER])
		do
			on_float_request := a_action
		ensure
			set: on_float_request = a_action
		end

	request_float (a_panel: INTEGER)
			-- The gesture: ask `on_float_request' to float panel `a_panel'.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			docked: not is_floating (a_panel)
		do
			if attached on_float_request as al_request then
				al_request.call (a_panel)
			end
		end

	float_panel (a_panel: INTEGER)
			-- Take panel `a_panel' out of its zone (it keeps its zone and
			-- place for `redock_panel') and let its content go.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			docked: not is_floating (a_panel)
		do
			floating_keys.extend (panels.i_th (a_panel).key.twin)
			panels.i_th (a_panel).content.set_parent (Void)
			hide_panel (a_panel)
			announce
		ensure
			floating: is_floating (a_panel)
			off_the_zone: not is_panel_visible (a_panel)
			let_go: panels.i_th (a_panel).content.parent = Void
		end

	redock_panel (a_panel: INTEGER)
			-- Put floating panel `a_panel' back in its zone, shown.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			floating: is_floating (a_panel)
		do
			forget_floating_key (panels.i_th (a_panel).key)
			panels.i_th (a_panel).content.set_parent (Current)
			show_panel (a_panel)
			announce
		ensure
			docked: not is_floating (a_panel)
			shown: is_panel_visible (a_panel)
			adopted: panels.i_th (a_panel).content.parent = Current
		end

feature -- Snapshot

	Snapshot_header: STRING_32 = "sw_dock 1"

	layout_snapshot: STRING_32
			-- The layout as text, one fact a line: fractions, tab modes,
			-- every panel's key, zone and visibility in order, each zone's
			-- order of panels, auto-hide, the maximized center, and each
			-- tabbed zone's active panel. A host saves it with the session.
		local
			z, i: INTEGER
		do
			create Result.make (200)
			Result.append (Snapshot_header)
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				Result.append ({STRING_32} "%Nfraction%T" + zone_name (z) + {STRING_32} "%T" + fraction (z).out)
				if is_tabbed (z) then
					Result.append ({STRING_32} "%Ntabbed%T" + zone_name (z))
				end
				if is_collapsed (z) then
					Result.append ({STRING_32} "%Ncollapsed%T" + zone_name (z))
				end
				if is_auto_hide (z) then
					Result.append ({STRING_32} "%Nautohide%T" + zone_name (z))
				end
				z := z + 1
			end
			if center_maximized then
				Result.append ({STRING_32} "%Ncenter_maximized")
			end
			from
				i := 1
			until
				i > panels.count
			loop
				Result.append ({STRING_32} "%Npanel%T" + panels.i_th (i).key + {STRING_32} "%T" + zone_name (panels.i_th (i).zone))
				if panels.i_th (i).is_visible then
					Result.append ({STRING_32} "%Tshown")
				else
					Result.append ({STRING_32} "%Thidden")
				end
				i := i + 1
			end
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				if not zone_orders [z].is_empty then
					Result.append ({STRING_32} "%Norder%T" + zone_name (z))
					across
						zone_orders [z] as ic
					loop
						Result.append ({STRING_32} "%T" + panels.i_th (ic).key)
					end
				end
				z := z + 1
			end
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				if is_tabbed (z) and then active_panel (z) > 0 then
					Result.append ({STRING_32} "%Nactive%T" + zone_name (z) + {STRING_32} "%T" + panels.i_th (active_panel (z)).key)
				end
				z := z + 1
			end
		ensure
			headed: Result.starts_with (Snapshot_header)
		end

	last_restore_ok: BOOLEAN
			-- Did the last `restore_layout' read its text and apply it?

	restore_layout (a_snapshot: READABLE_STRING_GENERAL)
			-- Apply a `layout_snapshot': fractions (clamped to the allowed
			-- range), tab modes, each named panel's zone and visibility in
			-- the snapshot's order (panels it does not name keep their state
			-- and follow), and the active tabs. A snapshot that does not
			-- read changes nothing (`last_restore_ok' False). One
			-- `on_layout_change' for the whole restore.
		local
			l_lines: LIST [READABLE_STRING_GENERAL]
			l_fields: LIST [READABLE_STRING_GENERAL]
			l_fracs: ARRAY [REAL_64]
			l_tabbed: ARRAY [BOOLEAN]
			l_collapsed: ARRAY [BOOLEAN]
			l_auto: ARRAY [BOOLEAN]
			l_center: BOOLEAN
			l_orders: ARRAY [ARRAYED_LIST [STRING_32]]
			l_entries: ARRAYED_LIST [TUPLE [key: STRING_32; zone: INTEGER; shown: BOOLEAN]]
			l_actives: ARRAYED_LIST [TUPLE [zone: INTEGER; key: STRING_32]]
			l_ok: BOOLEAN
			l_line: STRING_32
			l_kind: STRING_32
			z, i, id: INTEGER
			l_new: like panels
			l_placed: ARRAY [BOOLEAN]
		do
			l_lines := a_snapshot.to_string_32.split ('%N')
			l_ok := not l_lines.is_empty and then trimmed (l_lines.first).same_string (Snapshot_header)
			create l_fracs.make_filled (-1.0, Zone_west, Zone_north)
			create l_tabbed.make_filled (False, Zone_west, Zone_north)
			create l_collapsed.make_filled (False, Zone_west, Zone_north)
			create l_auto.make_filled (False, Zone_west, Zone_north)
			create l_orders.make_filled (create {ARRAYED_LIST [STRING_32]}.make (0), Zone_west, Zone_north)
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				l_orders [z] := create {ARRAYED_LIST [STRING_32]}.make (4)
				z := z + 1
			end
			create l_entries.make (panels.count)
			create l_actives.make (3)
			if l_ok then
				from
					l_lines.start
					l_lines.forth
				until
					l_lines.after or not l_ok
				loop
					l_line := trimmed (l_lines.item)
					if not l_line.is_empty then
						l_fields := l_line.split ('%T')
						l_kind := l_fields.first.to_string_32
						if l_fields.count = 3 and then l_kind.same_string ("fraction")
							and then zone_named (l_fields [2]) > 0 and then l_fields [3].is_double
						then
							l_fracs [zone_named (l_fields [2])] := l_fields [3].to_string_32.to_double
						elseif l_fields.count = 2 and then l_kind.same_string ("tabbed") and then zone_named (l_fields [2]) > 0 then
							l_tabbed [zone_named (l_fields [2])] := True
						elseif l_fields.count = 2 and then l_kind.same_string ("collapsed") and then zone_named (l_fields [2]) > 0 then
							l_collapsed [zone_named (l_fields [2])] := True
						elseif l_fields.count = 2 and then l_kind.same_string ("autohide") and then zone_named (l_fields [2]) > 0 then
							l_auto [zone_named (l_fields [2])] := True
						elseif l_fields.count = 1 and then l_kind.same_string ("center_maximized") then
							l_center := True
						elseif l_fields.count >= 3 and then l_kind.same_string ("order") and then zone_named (l_fields [2]) > 0 then
							from
								i := 3
							until
								i > l_fields.count
							loop
								l_orders [zone_named (l_fields [2])].extend (l_fields [i].to_string_32)
								i := i + 1
							end
						elseif l_fields.count = 4 and then l_kind.same_string ("panel") and then zone_named (l_fields [3]) > 0
							and then (l_fields [4].same_string ("shown") or l_fields [4].same_string ("hidden"))
						then
							l_entries.extend ([l_fields [2].to_string_32, zone_named (l_fields [3]), l_fields [4].same_string ("shown")])
						elseif l_fields.count = 3 and then l_kind.same_string ("active") and then zone_named (l_fields [2]) > 0 then
							l_actives.extend ([zone_named (l_fields [2]), l_fields [3].to_string_32])
						else
							l_ok := False
						end
					end
					l_lines.forth
				end
			end
			if l_ok then
				from
					z := Zone_west
				until
					z > Zone_north
				loop
					if l_fracs [z] >= 0.0 then
						put_fraction (z, l_fracs [z].max (Min_fraction).min (Max_fraction))
					end
					tabbed_flags [z] := l_tabbed [z]
					collapsed_flags [z] := l_collapsed [z]
					auto_hide_flags [z] := l_auto [z]
					active_ids [z] := 0
					z := z + 1
				end
				create l_new.make (panels.count)
				create l_placed.make_filled (False, 1, panels.count.max (1))
				across l_entries as e loop
					id := panel_by_key (e.key)
					if id > 0 and then not l_placed [id] then
						panels.i_th (id).zone := e.zone
							-- a floating panel stays out of its zone (scan 19)
						panels.i_th (id).is_visible := e.shown and not is_floating (id)
						l_new.extend (panels.i_th (id))
						l_placed [id] := True
					end
				end
				from
					i := 1
				until
					i > panels.count
				loop
					if not l_placed [i] then
						l_new.extend (panels.i_th (i))
					end
					i := i + 1
				end
				maximized_panel := 0
				slid_out_panel := 0
				center_maximized := l_center
				panels.wipe_out
				panels.append (l_new)
				rebuild_orders (l_orders)
				across l_actives as a loop
					id := panel_by_key (a.key)
					if id > 0 and then panels.i_th (id).zone = a.zone then
						active_ids [a.zone] := id
					end
				end
				announce
			end
			last_restore_ok := l_ok
		ensure
			same_panels: panels.count = old panels.count
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
			r := zone_rect (Zone_north)
			north_zone.set_bounds (r.rx, r.ry, r.rw, r.rh)
			north_zone.arrange (a_p)
			if maximized_panel > 0 then
				center.vanish
			else
				r := center_rect
				center.set_bounds (r.rx, r.ry, r.rw, r.rh)
				center.arrange (a_p)
				if slid_out_panel > 0 then
					zone_widget (panels.i_th (slid_out_panel).zone).arrange_slid_out (a_p, slide_rect)
				end
			end
		end

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (5)
			Result.extend (west_zone)
			Result.extend (east_zone)
			Result.extend (south_zone)
			Result.extend (north_zone)
			Result.extend (center)
		end

	wants_hover_point: BOOLEAN
			-- Follow the pointer, for the resize cursor over an edge.
		do
			Result := True
		end

	cursor_kind: INTEGER
			-- Left-right arrows over a west or east edge, up-down over the
			-- south edge (and while one is dragged).
		local
			e: INTEGER
		do
			e := dragging_edge
			if e = 0 then
				e := edge_at (hover_px, hover_py)
			end
			if e = Zone_south or e = Zone_north then
				Result := 4
			elseif e > 0 then
				Result := 3
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- An edge answers as the host; elsewhere the zones and the
			-- center answer for themselves.
		do
			if contains (a_px, a_py) then
				if maximized_panel > 0 then
					Result := zone_widget (panels.i_th (maximized_panel).zone).widget_at (a_px, a_py)
					if Result = Void then
						Result := Current
					end
				elseif slid_out_panel > 0 and then in_rect (slide_rect, a_px, a_py) then
					Result := panels.i_th (slid_out_panel).content.widget_at (a_px, a_py)
					if Result = Void then
						Result := Current
					end
				elseif edge_at (a_px, a_py) > 0 then
					Result := Current
				else
					Result := west_zone.widget_at (a_px, a_py)
					if Result = Void then
						Result := east_zone.widget_at (a_px, a_py)
					end
					if Result = Void then
						Result := south_zone.widget_at (a_px, a_py)
					end
					if Result = Void then
						Result := north_zone.widget_at (a_px, a_py)
					end
					if Result = Void then
						Result := center.widget_at (a_px, a_py)
					end
					if Result = Void then
						Result := Current
					end
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A press on an edge grabs it; one outside the slid-out panel
			-- (that no widget took) slides it back.
		do
			if slid_out_panel > 0 and then not in_rect (slide_rect, a_px, a_py) then
					-- a press outside the slid-out panel sends it back
				slide_back
			end
			dragging_edge := edge_at (a_px, a_py)
			Result := dragging_edge > 0
		end

	handle_drag (a_px, a_py: REAL_64)
			-- The grabbed edge follows the pointer, inside the allowed range.
		local
			f: REAL_64
		do
			if dragging_edge > 0 and then width > 0.0 and then height > 0.0 then
				inspect dragging_edge
				when Zone_west then
					f := (a_px - x) / width
				when Zone_east then
					f := (x + width - a_px) / width
				when Zone_north then
					f := (a_py - y) / height
				else
					f := (y + height - a_py) / height
				end
				put_fraction (dragging_edge, f.max (Min_fraction).min (Max_fraction))
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Letting go of an edge settles the layout.
		do
			if dragging_edge > 0 then
				dragging_edge := 0
				announce
			end
		ensure then
			released: dragging_edge = 0
		end

feature -- Preferred size

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 420.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The zones, the center, and an accent line on the edge under
			-- the pointer or in the hand.
		local
			e: INTEGER
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			if maximized_panel > 0 then
				zone_widget (panels.i_th (maximized_panel).zone).paint (a_p)
			else
				west_zone.paint (a_p)
				east_zone.paint (a_p)
				south_zone.paint (a_p)
				north_zone.paint (a_p)
				center.paint (a_p)
				if slid_out_panel > 0 then
					zone_widget (panels.i_th (slid_out_panel).zone).draw_slid_out (a_p)
				end
			end
			e := dragging_edge
			if e = 0 and then shows_hover then
				e := edge_at (hover_px, hover_py)
			end
			if e > 0 then
				r := zone_rect (e)
				a_p.set_color (a_p.theme.accent)
				inspect e
				when Zone_west then
					a_p.fill_rect (r.rx + r.rw - 1.0, r.ry, 2.0, r.rh)
				when Zone_east then
					a_p.fill_rect (r.rx - 1.0, r.ry, 2.0, r.rh)
				when Zone_north then
					a_p.fill_rect (r.rx, r.ry + r.rh - 1.0, r.rw, 2.0)
				else
					a_p.fill_rect (r.rx, r.ry - 1.0, r.rw, 2.0)
				end
			end
		end

feature {NONE} -- Organs

	floating_keys: ARRAYED_LIST [STRING_32]
			-- The keys of the panels out in floating windows.
		attribute
			create Result.make (2)
		end

	forget_floating_key (a_key: READABLE_STRING_GENERAL)
		do
			from
				floating_keys.start
			until
				floating_keys.after
			loop
				if floating_keys.item.same_string_general (a_key) then
					floating_keys.remove
				else
					floating_keys.forth
				end
			end
		end

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

	north_zone: SW_DOCK_ZONE
		attribute
			create Result.make_on (Current, Zone_north)
		end

	tabbed_flags: ARRAY [BOOLEAN]
			-- Per zone: tabs?

	collapsed_flags: ARRAY [BOOLEAN]
			-- Per zone: folded to a strip?

	auto_hide_flags: ARRAY [BOOLEAN]
			-- Per zone: auto-hide?

	zone_orders: ARRAY [ARRAYED_LIST [INTEGER]]
			-- Per zone: the ids of its panels (hidden ones too), in order.

	stands_as_strip (a_zone: INTEGER): BOOLEAN
			-- Is `a_zone' collapsed or auto-hide, so that it takes a strip?
		require
			zone_known: is_zone (a_zone)
		do
			Result := collapsed_flags [a_zone] or auto_hide_flags [a_zone]
		end

	in_rect (a_rect: TUPLE [rx, ry, rw, rh: REAL_64]; a_px, a_py: REAL_64): BOOLEAN
			-- Is the point inside `a_rect' (which has some extent)?
		do
			Result := a_rect.rw > 0.0 and then a_rect.rh > 0.0 and then a_px >= a_rect.rx and then a_px < a_rect.rx + a_rect.rw
				and then a_py >= a_rect.ry and then a_py < a_rect.ry + a_rect.rh
		end

	relocate (a_panel, a_zone: INTEGER)
			-- Move panel `a_panel' to the end of `a_zone', silently.
		require
			panel_known: a_panel >= 1 and a_panel <= panels.count
			zone_known: is_zone (a_zone)
		do
			zone_orders [panels.i_th (a_panel).zone].prune_all (a_panel)
			panels.i_th (a_panel).zone := a_zone
			zone_orders [a_zone].extend (a_panel)
			if slid_out_panel = a_panel then
				slid_out_panel := 0
			end
			if not is_floating (a_panel) then
					-- a floating panel only changes where it will dock (scan 19)
				active_ids [a_zone] := a_panel
			end
		ensure
			moved: panels.i_th (a_panel).zone = a_zone
			ends_its_zone: zone_orders [a_zone].last = a_panel
		end

	rebuild_orders (a_orders: ARRAY [ARRAYED_LIST [STRING_32]])
			-- Each zone's order from the keys in `a_orders' (those that name
			-- a panel of the zone), then the zone's other panels by id.
		local
			z, i, l_id: INTEGER
			l_list: ARRAYED_LIST [INTEGER]
		do
			from
				z := Zone_west
			until
				z > Zone_north
			loop
				create l_list.make (4)
				across
					a_orders [z] as ic
				loop
					l_id := panel_by_key (ic)
					if l_id > 0 and then panels.i_th (l_id).zone = z and then not l_list.has (l_id) then
						l_list.extend (l_id)
					end
				end
				from
					i := 1
				until
					i > panels.count
				loop
					if panels.i_th (i).zone = z and then not l_list.has (i) then
						l_list.extend (i)
					end
					i := i + 1
				end
				zone_orders [z] := l_list
				z := z + 1
			end
		end

	maximizable_keys: ARRAYED_LIST [STRING_32]
			-- The keys of the panels whose bars offer Maximize.
		attribute
			create Result.make (4)
		end

	marked_keys: ARRAYED_LIST [STRING_32]
			-- The keys of the panels whose names carry a dot.
		attribute
			create Result.make (4)
		end

	has_key (a_keys: ARRAYED_LIST [STRING_32]; a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_key' one of `a_keys'?
		do
			Result := across a_keys as al_key some al_key.same_string_general (a_key) end
		end

	forget_key (a_keys: ARRAYED_LIST [STRING_32]; a_key: READABLE_STRING_GENERAL)
			-- `a_keys' without `a_key'.
		do
			from
				a_keys.start
			until
				a_keys.after
			loop
				if a_keys.item.same_string_general (a_key) then
					a_keys.remove
				else
					a_keys.forth
				end
			end
		ensure
			gone: not has_key (a_keys, a_key)
		end

	zone_extent (a_zone: INTEGER; a_whole: REAL_64): REAL_64
			-- How much of `a_whole' (the host's width, or its height for
			-- the south zone) `a_zone' asks for: nothing when empty, a strip
			-- when folded, else its fraction.
		require
			zone_known: is_zone (a_zone)
		do
			if panels_in (a_zone).is_empty then
				Result := 0.0
			elseif stands_as_strip (a_zone) then
				Result := strip_extent (a_zone).min (a_whole.max (0.0))
			else
				Result := a_whole * fraction (a_zone)
			end
		ensure
			non_negative: Result >= 0.0
		end

	active_ids: ARRAY [INTEGER]
			-- Per zone: the panel last activated there (0 = none yet).

	announce
		do
			if attached on_layout_change as a then
				a.call (Void)
			end
		end

	put_fraction (a_zone: INTEGER; a_fraction: REAL_64)
		require
			zone_known: is_zone (a_zone)
			in_range: a_fraction >= Min_fraction and a_fraction <= Max_fraction
		do
			inspect a_zone
			when Zone_west then
				west_fraction := a_fraction
			when Zone_east then
				east_fraction := a_fraction
			when Zone_north then
				north_fraction := a_fraction
			else
				south_fraction := a_fraction
			end
		ensure
			set: fraction (a_zone) = a_fraction
		end

	zone_name (a_zone: INTEGER): STRING_32
		require
			zone_known: is_zone (a_zone)
		do
			inspect a_zone
			when Zone_west then
				Result := "west"
			when Zone_east then
				Result := "east"
			when Zone_north then
				Result := "north"
			else
				Result := "south"
			end
		end

	zone_named (a_name: READABLE_STRING_GENERAL): INTEGER
			-- The zone called `a_name'; 0 for none.
		do
			if a_name.same_string ("west") then
				Result := Zone_west
			elseif a_name.same_string ("east") then
				Result := Zone_east
			elseif a_name.same_string ("south") then
				Result := Zone_south
			elseif a_name.same_string ("north") then
				Result := Zone_north
			end
		ensure
			zone_or_none: Result = 0 or else is_zone (Result)
		end

	trimmed (a_s: READABLE_STRING_GENERAL): STRING_32
			-- `a_s' without a carriage return or spaces at either end.
		do
			Result := a_s.to_string_32
			Result.prune_all ('%R')
			Result.left_adjust
			Result.right_adjust
		end

invariant
	organs: center /= Void and panels /= Void
	fractions_in_range: west_fraction >= Min_fraction and west_fraction <= Max_fraction
		and east_fraction >= Min_fraction and east_fraction <= Max_fraction
		and south_fraction >= Min_fraction and south_fraction <= Max_fraction
		and north_fraction >= Min_fraction and north_fraction <= Max_fraction
	per_zone_tables: tabbed_flags.lower = Zone_west and tabbed_flags.upper = Zone_north
		and active_ids.lower = Zone_west and active_ids.upper = Zone_north
		and collapsed_flags.lower = Zone_west and collapsed_flags.upper = Zone_north
	maximized_known: maximized_panel >= 0 and maximized_panel <= panels.count
	per_zone_orders: auto_hide_flags.lower = Zone_west and auto_hide_flags.upper = Zone_north
		and zone_orders.lower = Zone_west and zone_orders.upper = Zone_north
	slid_known: slid_out_panel >= 0 and slid_out_panel <= panels.count
	slid_is_auto_hidden: slid_out_panel > 0 implies
		(auto_hide_flags [panels.i_th (slid_out_panel).zone] and panels.i_th (slid_out_panel).is_visible)
	dragging_a_zone: dragging_edge >= 0 and dragging_edge <= Zone_north

end
