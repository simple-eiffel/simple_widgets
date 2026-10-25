note
	description: "[
		A world timeline (GW-17): time runs left to right on astronomical
		years (read as BC/AD or BCE/CE, never a year zero), lanes stack top
		to bottom in collapsible groups, and every item draws its certainty
		class as a pattern with a label (SW_TIMELINE_ITEM). Items that
		overlap in a lane take separate rows. A disputed event draws every
		position, stacked inside the dispute's envelope; the owner's lean is
		marked with its wording and never pre-selected. Zoom is semantic:
		periods at millennium scale, major events at century scale,
		everything at decade scale. A synchronism cursor stands at a year
		and `slice' lists every visible item at that moment, each with its
		own certainty. Lanes, items and disputes are data, not code.

		Input: the wheel zooms about the pointer; a drag pans; a click on an
		item selects it (`on_select'), on a group header folds the group,
		elsewhere sets the cursor (`on_cursor'); Left/Right pan, plus and
		minus zoom, Home fits everything. Lanes scroll up and down under a
		scrollbar (SW_VSCROLLING): Up/Down, Page Up/Page Down and the bar.
	]"
	scan_15: "[
		2026-10-25, the design scan since c9d5571; a note for the future
		self. (1) An envelope is per dispute AND lane: a dispute whose
		positions sit in several lanes is bracketed in each. (2) Only class
		A is a tick; one year of B, C, D or F is a bar six pixels wide at
		least. (3) A dispute shows all its positions while its envelope is
		on the view, whatever their importance: disputes are drawn, not
		hidden. (4) Every year mark - tick, cursor, axis label - stands at
		the middle of its year. (5) The lanes scroll vertically, and the
		preferred height is the laid-out height. Guarded by the scan15_*
		tests in SW_LANE_TIMELINE_ASSAULT.
	]"

class
	SW_LANE_TIMELINE

inherit
	SW_VSCROLLING
		redefine
			arrange, handle_click, handle_drag, handle_release, handle_wheel, handle_key, accepts_focus,
			wants_hover_point, accessible_role, default_accessible_name, accessible_value
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create lane_titles.make (8)
			create lane_groups.make (8)
			create items.make (32)
			create dispute_titles.make (4)
			create dispute_from.make (4)
			create dispute_to.make (4)
			create collapsed_groups.make (2)
			create era.make
			create item_boxes.make (32)
			create lane_tops.make (8)
			create lane_heights.make (8)
			create headers.make (4)
			create envelope_boxes.make (4)
			view_from := -1000.0
			view_to := 500.0
			row_h := 24.0
			axis_h := 30.0
			label_w := 120.0
		end

feature -- Data

	lane_titles: ARRAYED_LIST [STRING_32]
	lane_groups: ARRAYED_LIST [STRING_32]
			-- Parallel: each lane's title and group (lanes are numbered from 1).

	items: ARRAYED_LIST [SW_TIMELINE_ITEM]

	dispute_titles: ARRAYED_LIST [STRING_32]
	dispute_from, dispute_to: ARRAYED_LIST [INTEGER]
			-- Parallel: each dispute's title and envelope (the outer bound
			-- every position sits inside), astronomical years.

	era: SW_ERA_YEARS
			-- How years read (BC/AD or BCE/CE).

	add_lane (a_title, a_group: READABLE_STRING_GENERAL): INTEGER
			-- A new lane in group `a_group'; its number.
		do
			lane_titles.extend (create {STRING_32}.make_from_string_general (a_title))
			lane_groups.extend (create {STRING_32}.make_from_string_general (a_group))
			Result := lane_titles.count
		ensure
			numbered: Result = lane_titles.count
			parallel: lane_groups.count = lane_titles.count
		end

	add_item (a_lane: INTEGER; a_title: READABLE_STRING_GENERAL; a_from, a_to, a_class: INTEGER): SW_TIMELINE_ITEM
			-- A new item in lane `a_lane' from `a_from' to `a_to' (astronomical
			-- years) of certainty `a_class'.
		require
			known_lane: a_lane >= 1 and a_lane <= lane_titles.count
			ordered: a_from <= a_to
			known_class: a_class >= {SW_TIMELINE_ITEM}.Class_a and a_class <= {SW_TIMELINE_ITEM}.Class_g
		do
			create Result.make (items.count + 1, a_lane, a_title, a_from, a_to, a_class)
			items.extend (Result)
		ensure
			added: items.last = Result and Result.id = items.count
		end

	add_dispute (a_title: READABLE_STRING_GENERAL; a_from, a_to: INTEGER): INTEGER
			-- A dispute whose positions all sit inside `a_from'..`a_to'; its
			-- number, for `add_position'.
		require
			ordered: a_from <= a_to
		do
			dispute_titles.extend (create {STRING_32}.make_from_string_general (a_title))
			dispute_from.extend (a_from)
			dispute_to.extend (a_to)
			Result := dispute_titles.count
		ensure
			numbered: Result = dispute_titles.count
		end

	add_position (a_dispute, a_lane: INTEGER; a_title: READABLE_STRING_GENERAL; a_from, a_to, a_class: INTEGER): SW_TIMELINE_ITEM
			-- One position of dispute `a_dispute', inside its envelope.
		require
			known_dispute: a_dispute >= 1 and a_dispute <= dispute_titles.count
			known_lane: a_lane >= 1 and a_lane <= lane_titles.count
			ordered: a_from <= a_to
			inside_the_envelope: a_from >= dispute_from.i_th (a_dispute) and a_to <= dispute_to.i_th (a_dispute)
			known_class: a_class >= {SW_TIMELINE_ITEM}.Class_a and a_class <= {SW_TIMELINE_ITEM}.Class_g
		do
			Result := add_item (a_lane, a_title, a_from, a_to, a_class)
			Result.set_dispute (a_dispute)
		ensure
			a_position: Result.dispute = a_dispute
		end

feature -- View

	view_from, view_to: REAL_64
			-- The years at the plot's left and right edges.

	set_view (a_from, a_to: REAL_64)
		require
			ordered: a_from < a_to
			not_too_close: a_to - a_from >= Min_span
		do
			view_from := a_from
			view_to := a_to.min (a_from + Max_span)
		ensure
			set: view_from = a_from
		end

	fit_all
			-- Show every item, with a margin.
		local
			l_lo, l_hi, l_pad: REAL_64
		do
			if not items.is_empty then
				l_lo := items.first.year_from
				l_hi := items.first.year_to + 1
				across
					items as it
				loop
					l_lo := l_lo.min (it.year_from)
					l_hi := l_hi.max (it.year_to + 1)
				end
				l_pad := ((l_hi - l_lo) * 0.05).max (1.0)
				set_view (l_lo - l_pad, (l_hi + l_pad).max (l_lo - l_pad + Min_span))
			end
		end

	zoom_about (a_year, a_factor: REAL_64)
			-- Scale the span by `a_factor' (under 1 zooms in) keeping `a_year'
			-- where it is on the plot.
		require
			positive: a_factor > 0.0
		local
			l_span, l_new, l_t: REAL_64
		do
			l_span := view_to - view_from
			l_new := (l_span * a_factor).max (Min_span).min (Max_span)
			l_t := ((a_year - view_from) / l_span).max (0.0).min (1.0)
			view_from := a_year - l_t * l_new
			view_to := view_from + l_new
		ensure
			ordered: view_from < view_to
		end

	pan (a_years: REAL_64)
		do
			view_from := view_from + a_years
			view_to := view_to + a_years
		end

	years_per_pixel: REAL_64
		do
			Result := (view_to - view_from) / plot_w.max (1.0)
		end

	zoom_level: INTEGER
			-- Semantic zoom: 0 millennium scale (periods), 1 century scale
			-- (major events too), 2 decade scale (everything).
		do
			if years_per_pixel >= Millennium_scale then
				Result := {SW_TIMELINE_ITEM}.Importance_period
			elseif years_per_pixel >= Century_scale then
				Result := {SW_TIMELINE_ITEM}.Importance_major
			else
				Result := {SW_TIMELINE_ITEM}.Importance_detail
			end
		end

	Min_span: REAL_64 = 2.0
	Max_span: REAL_64 = 20000.0
	Millennium_scale: REAL_64 = 4.0
			-- Years per pixel from which only periods show.
	Century_scale: REAL_64 = 0.4
			-- Years per pixel from which major events show; finer, everything.

feature -- Groups

	collapsed_groups: ARRAYED_LIST [STRING_32]

	is_group_collapsed (a_group: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := across collapsed_groups as g some g.same_string_general (a_group) end
		end

	toggle_group (a_group: READABLE_STRING_GENERAL)
			-- Fold or unfold every lane of `a_group'.
		local
			i: INTEGER
		do
			if is_group_collapsed (a_group) then
				from
					i := collapsed_groups.count
				until
					i < 1
				loop
					if collapsed_groups.i_th (i).same_string_general (a_group) then
						collapsed_groups.go_i_th (i)
						collapsed_groups.remove
					end
					i := i - 1
				end
			else
				collapsed_groups.extend (create {STRING_32}.make_from_string_general (a_group))
			end
		ensure
			flipped: is_group_collapsed (a_group) = not old is_group_collapsed (a_group)
		end

	is_lane_shown (a_lane: INTEGER): BOOLEAN
		require
			known_lane: a_lane >= 1 and a_lane <= lane_titles.count
		do
			Result := not is_group_collapsed (lane_groups.i_th (a_lane))
		end

feature -- Synchronism

	has_cursor: BOOLEAN
	cursor_year: INTEGER

	set_cursor (a_year: INTEGER)
		do
			cursor_year := a_year
			has_cursor := True
			if attached on_cursor as al_cursor then
				al_cursor.call (a_year)
			end
		ensure
			at: has_cursor and cursor_year = a_year
		end

	clear_cursor
		do
			has_cursor := False
		ensure
			cleared: not has_cursor
		end

	slice (a_year: INTEGER): ARRAYED_LIST [SW_TIMELINE_ITEM]
			-- Every item of a shown lane, at the current semantic zoom, whose
			-- range holds `a_year', in lane order - each keeps its own
			-- certainty, so a firm date lends nothing to a soft one beside it.
		local
			l: INTEGER
		do
			create Result.make (8)
			from
				l := 1
			until
				l > lane_titles.count
			loop
				if is_lane_shown (l) then
					across
						items as it
					loop
						if it.lane = l and then it.importance <= zoom_level and then it.contains (a_year) then
							Result.extend (it)
						end
					end
				end
				l := l + 1
			end
		ensure
			all_hold_it: across Result as r all r.contains (a_year) and is_lane_shown (r.lane) end
		end

	on_cursor: detachable PROCEDURE [INTEGER]
	on_select: detachable PROCEDURE [SW_TIMELINE_ITEM]

	selected: detachable SW_TIMELINE_ITEM

	set_on_cursor (a_action: PROCEDURE [INTEGER])
		do
			on_cursor := a_action
		end

	set_on_select (a_action: PROCEDURE [SW_TIMELINE_ITEM])
		do
			on_select := a_action
		end

feature -- Measurement (after arrange)

	row_h, axis_h, label_w: REAL_64

	plot_left: REAL_64
		do
			Result := x + label_w
		end

	plot_w: REAL_64
		do
			Result := (width - label_w).max (0.0)
		end

	year_x (a_year: REAL_64): REAL_64
			-- The plot x of `a_year'.
		do
			Result := plot_left + (a_year - view_from) / (view_to - view_from) * plot_w
		end

	year_at (a_px: REAL_64): REAL_64
			-- The year under plot x `a_px'.
		do
			Result := view_from + (a_px - plot_left) / plot_w.max (1.0) * (view_to - view_from)
		end

	item_boxes: ARRAYED_LIST [TUPLE [bx, by, bw, bh: REAL_64]]
			-- Parallel to `items': where each was laid out; no width when it
			-- is not shown (folded lane, finer zoom, off the view).

	lane_tops, lane_heights: ARRAYED_LIST [REAL_64]
			-- Parallel to the lanes; no height when folded.

	headers: ARRAYED_LIST [TUPLE [group: STRING_32; hy: REAL_64]]
			-- Each group header's row.

	envelope_boxes: ARRAYED_LIST [TUPLE [ex, ey, ew, eh: REAL_64; dispute, lane: INTEGER]]
			-- One per dispute and lane holding shown positions: the envelope
			-- drawn round them there.

	axis_labels: ARRAYED_LIST [TUPLE [year: INTEGER; lx, lw: REAL_64]]
			-- The year labels the axis draws, each wholly inside the plot: a
			-- label the edge would cut is left out ("1000 BC" cut to "0 BC"
			-- read as the year zero there is not).
		attribute
			create Result.make (16)
		end

	is_item_shown (a_item: SW_TIMELINE_ITEM): BOOLEAN
		require
			laid_out: item_boxes.count = items.count
			known: items.has (a_item)
		do
			Result := item_boxes.i_th (a_item.id).bw > 0.0
		end

	item_at (a_px, a_py: REAL_64): detachable SW_TIMELINE_ITEM
			-- The shown item whose box holds the point; the last drawn wins.
		local
			i: INTEGER
		do
			if item_boxes.count = items.count then
				from
					i := 1
				until
					i > items.count
				loop
					if item_boxes.i_th (i).bw > 0.0 and then a_px >= item_boxes.i_th (i).bx
						and then a_px <= item_boxes.i_th (i).bx + item_boxes.i_th (i).bw
						and then a_py >= item_boxes.i_th (i).by and then a_py <= item_boxes.i_th (i).by + item_boxes.i_th (i).bh
					then
						Result := items.i_th (i)
					end
					i := i + 1
				end
			end
		end

	header_at (a_py: REAL_64): detachable STRING_32
			-- The group whose header row holds `a_py'.
		do
			across
				headers as h
			loop
				if a_py >= h.hy and then a_py < h.hy + row_h then
					Result := h.group
				end
			end
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The laid-out height (axis, headers, every stacked row) once laid
			-- out; before that an estimate.
		do
			measure (a_p)
			if content_extent > 0.0 then
				Result := content_extent
			else
				Result := axis_h + (lane_titles.count + 2) * row_h
			end
		end

	scroll_extent: REAL_64
			-- SW_VSCROLLING: everything the lanes would take.
		do
			Result := content_extent
		end

	wheel_line: REAL_64
			-- SW_VSCROLLING: one row.
		do
			Result := row_h.max (1.0)
		end

	content_extent: REAL_64
			-- The axis, the headers and every lane's rows, as last laid out.

	arrange (a_p: SW_PAINTER)
			-- Measure, place the group headers and lanes, and stack each lane's
			-- shown items into rows: disputes first, each as one block of
			-- consecutive rows inside its envelope, then the rest by start.
		local
			l, i, k, l_rows: INTEGER
			cy: REAL_64
			l_group: detachable STRING_32
			l_ends: ARRAYED_LIST [REAL_64]
			l_order: ARRAYED_LIST [INTEGER]
			l_rows_of: ARRAYED_LIST [INTEGER]
		do
			measure (a_p)
			item_boxes.wipe_out
			from i := 1 until i > items.count loop
				item_boxes.extend ([0.0, 0.0, 0.0, 0.0])
				i := i + 1
			end
			create l_rows_of.make_filled (items.count)
			envelope_boxes.wipe_out
			lane_tops.wipe_out
			lane_heights.wipe_out
			headers.wipe_out
			cy := y + axis_h - scroll_y
			from
				l := 1
			until
				l > lane_titles.count
			loop
				if l_group = Void or else not l_group.same_string (lane_groups.i_th (l)) then
					l_group := lane_groups.i_th (l)
					headers.extend ([l_group, cy])
					cy := cy + row_h
				end
				lane_tops.extend (cy)
				if is_lane_shown (l) then
					create l_ends.make (4)
					l_order := lane_order (l)
						-- disputes, each as a block
					from i := 1 until i > dispute_titles.count loop
						k := positions_shown (i, l)
						if k > 0 then
							l_rows := free_block (l_ends, year_x (dispute_from.i_th (i)) - Gap, k)
							place_dispute (a_p, i, l, l_rows, l_ends, l_rows_of)
						end
						i := i + 1
					end
						-- the rest, by start
					across
						l_order as o
					loop
						if items.i_th (o).dispute = 0 then
							place_item (a_p, items.i_th (o), l_ends, l_rows_of)
						end
					end
					lane_heights.extend (l_ends.count.max (1) * row_h)
					across
						items as it
					loop
						if it.lane = l and then l_rows_of.i_th (it.id) > 0 then
							item_boxes.i_th (it.id).by := cy + (l_rows_of.i_th (it.id) - 1) * row_h + 3.0
						end
					end
					across
						envelope_boxes as e
					loop
						if e.lane = l then
							e.ey := cy + (first_row_of (e.dispute, l, l_rows_of) - 1) * row_h + 1.0
						end
					end
					cy := cy + lane_heights.last
				else
					lane_heights.extend (0.0)
				end
				l := l + 1
			end
			content_extent := cy + scroll_y - y
			place_bar (a_p.theme)
			place_axis_labels (a_p)
		ensure then
			one_box_per_item: item_boxes.count = items.count
			one_top_per_lane: lane_tops.count = lane_titles.count and lane_heights.count = lane_titles.count
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			l: INTEGER
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.fill_rect (x, y, width, height)
			draw_axis (a_p)
			a_p.push_clip (x, y + axis_h, width, (height - axis_h).max (0.0))
			across
				headers as h
			loop
				a_p.set_color (t.surface_variant)
				a_p.fill_rect (x, h.hy, width, row_h)
				if is_group_collapsed (h.group) then
					a_p.set_color (t.ink_muted)
					a_p.glyph ({SW_PAINTER}.Glyph_chevron_right, x + row_h / 2.0, h.hy + row_h / 2.0, row_h * 0.45)
				else
					a_p.set_color (t.ink_muted)
					a_p.glyph ({SW_PAINTER}.Glyph_chevron_down, x + row_h / 2.0, h.hy + row_h / 2.0, row_h * 0.45)
				end
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
				a_p.set_color (t.ink)
				a_p.text (x + row_h, baseline (a_p, h.hy), h.group)
			end
			from
				l := 1
			until
				l > lane_titles.count
			loop
				if lane_heights.i_th (l) > 0.0 then
					a_p.set_color (t.divider)
					a_p.fill_rect (x, lane_tops.i_th (l) + lane_heights.i_th (l) - 1.0, width, 1.0)
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
					a_p.set_color (t.ink_muted)
					a_p.push_clip (x, lane_tops.i_th (l), label_w - 4.0, lane_heights.i_th (l))
					a_p.text (x + t.control_inset, baseline (a_p, lane_tops.i_th (l)), lane_titles.i_th (l))
					a_p.pop_clip
				end
				l := l + 1
			end
			a_p.push_clip (plot_left, y + axis_h, plot_w, (height - axis_h).max (0.0))
			across
				envelope_boxes as e
			loop
				if e.ew > 0.0 then
					a_p.set_color (t.ink_muted)
					a_p.dashed_rrect_stroke (e.ex + 0.5, e.ey + 0.5, e.ew - 1.0, e.eh - 1.0, t.radius, 1.0, a_p.Stroke_dashed)
				end
			end
			across
				items as it
			loop
				if item_boxes.i_th (it.id).bw > 0.0 then
					draw_item (a_p, it)
				end
			end
			if has_cursor then
				a_p.set_color (t.accent)
				a_p.line (year_x (cursor_year + 0.5), y + axis_h, year_x (cursor_year + 0.5), y + height, 2.0)
			end
			a_p.pop_clip
			a_p.pop_clip
			if has_cursor then
				draw_cursor_label (a_p)
			end
			draw_bar (a_p)
			if is_focused then
				a_p.set_color (t.accent)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			end
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- Fold a group, select an item, or set the cursor; start a pan.
		do
			if is_enabled and then press_bar (a_px, a_py) then
				Result := True
			elseif is_enabled and then contains (a_px, a_py) then
				Result := True
				press_x := a_px
				press_from := view_from
				is_panning := False
				if attached header_at (a_py) as al_group then
					toggle_group (al_group)
				elseif attached item_at (a_px, a_py) as al_item then
					selected := al_item
					if attached on_select as al_select then
						al_select.call (al_item)
					end
				elseif a_px >= plot_left then
					set_cursor (year_at (a_px).floor)
				end
			end
		end

	handle_drag (a_px, a_py: REAL_64)
			-- Pan with the pointer once it has moved a few pixels.
		local
			l_span: REAL_64
		do
			if drag_bar (a_py) then
				-- the scrollbar took it
			elseif is_panning or else (a_px - press_x).abs >= 4.0 then
				is_panning := True
				l_span := view_to - view_from
				view_from := press_from - (a_px - press_x) * l_span / plot_w.max (1.0)
				view_to := view_from + l_span
			end
		end

	handle_release (a_x, a_y: INTEGER)
		do
			release_bar
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- Zoom about the year under the pointer.
		do
			if is_enabled then
				if a_delta > 0 then
					zoom_about (year_at (hover_px), 0.8)
				else
					zoom_about (year_at (hover_px), 1.25)
				end
				Result := True
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			inspect a_vk
			when 37 then
				pan (- (view_to - view_from) * 0.1)
			when 39 then
				pan ((view_to - view_from) * 0.1)
			when 107, 187 then
				zoom_about ((view_from + view_to) / 2.0, 0.8)
			when 109, 189 then
				zoom_about ((view_from + view_to) / 2.0, 1.25)
			when 36 then
				fit_all
			when 33, 34 then
				scroll_key (a_vk).do_nothing
			when 38 then
				scroll_to (scroll_y - row_h)
			when 40 then
				scroll_to (scroll_y + row_h)
			else
			end
		end

feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_custom
		end

	default_accessible_name: STRING_32
		do
			Result := {STRING_32} "Timeline"
		end

	accessible_value: detachable STRING_32
			-- The cursor's year, and what stands there.
		do
			if has_cursor then
				Result := era.label (cursor_year)
				Result.append ({STRING_32} ": ")
				Result.append_integer (slice (cursor_year).count)
				Result.append ({STRING_32} " items")
			end
		end

feature {NONE} -- Implementation

	press_x, press_from: REAL_64
	is_panning: BOOLEAN

	Gap: REAL_64 = 6.0
			-- Between items stacked on one row.

	measure (a_p: SW_PAINTER)
		local
			l_w: REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			row_h := a_p.text_extent + a_p.theme.control_inset
			axis_h := a_p.text_extent + 2.0 * a_p.theme.padding
			l_w := 0.0
			across
				lane_titles as lt
			loop
				l_w := l_w.max (a_p.advance (lt))
			end
			label_w := (l_w + 2.0 * a_p.theme.control_inset).min (width * 0.3).max (row_h * 2.0)
		end

	baseline (a_p: SW_PAINTER; a_top: REAL_64): REAL_64
		do
			Result := a_top + (row_h - a_p.text_extent) / 2.0 + a_p.font_ascent
		end

	lane_order (a_lane: INTEGER): ARRAYED_LIST [INTEGER]
			-- Item numbers of lane `a_lane', by start year (insertion sort:
			-- lanes hold tens to hundreds of items).
		local
			i, j: INTEGER
		do
			create Result.make (8)
			across
				items as it
			loop
				if it.lane = a_lane then
					from
						j := Result.count
					until
						j < 1 or else items.i_th (Result.i_th (j)).year_from <= it.year_from
					loop
						j := j - 1
					end
					Result.go_i_th (j)
					Result.put_right (it.id)
				end
			end
			i := Result.count
		end

	is_shown_now (a_item: SW_TIMELINE_ITEM): BOOLEAN
			-- At this zoom and on the view? A dispute's position shows while
			-- the dispute's envelope is on the view, whatever its importance.
		do
			if a_item.dispute > 0 then
				Result := dispute_to.i_th (a_item.dispute) + 1 >= view_from and then dispute_from.i_th (a_item.dispute) <= view_to
			else
				Result := a_item.importance <= zoom_level and then a_item.year_to + 1 >= view_from and then a_item.year_from <= view_to
			end
		end

	positions_shown (a_dispute, a_lane: INTEGER): INTEGER
		do
			across
				items as it
			loop
				if it.dispute = a_dispute and then it.lane = a_lane and then is_shown_now (it) then
					Result := Result + 1
				end
			end
		end

	first_row_of (a_dispute, a_lane: INTEGER; a_rows: ARRAYED_LIST [INTEGER]): INTEGER
		do
			across
				items as it
			loop
				if it.dispute = a_dispute and then it.lane = a_lane and then a_rows.i_th (it.id) > 0
					and then (Result = 0 or else a_rows.i_th (it.id) < Result)
				then
					Result := a_rows.i_th (it.id)
				end
			end
		end

	free_block (a_ends: ARRAYED_LIST [REAL_64]; a_left: REAL_64; a_count: INTEGER): INTEGER
			-- The first row of `a_count' consecutive rows all free from
			-- `a_left' on (rows past the last are free).
		require
			at_least_one: a_count >= 1
		local
			r, k: INTEGER
			l_ok: BOOLEAN
		do
			from
				r := 1
			until
				Result > 0
			loop
				l_ok := True
				from k := r until k > r + a_count - 1 or not l_ok loop
					if k <= a_ends.count and then a_ends.i_th (k) > a_left then
						l_ok := False
					end
					k := k + 1
				end
				if l_ok then
					Result := r
				end
				r := r + 1
			end
		ensure
			positive: Result >= 1
		end

	claim (a_ends: ARRAYED_LIST [REAL_64]; a_row: INTEGER; a_right: REAL_64)
			-- Row `a_row' is taken up to `a_right'.
		require
			positive: a_row >= 1
		do
			from until a_ends.count >= a_row loop
				a_ends.extend (-1.0e12)
			end
			a_ends.put_i_th (a_ends.i_th (a_row).max (a_right), a_row)
		end

	item_span (a_p: SW_PAINTER; a_item: SW_TIMELINE_ITEM): TUPLE [sx, sw, reach: REAL_64]
			-- The item's box left and width, and how far right its label
			-- reaches when it does not fit inside.
		local
			x1, x2, l_text: REAL_64
		do
			x1 := year_x (a_item.year_from)
			x2 := year_x (a_item.year_to + 1)
			if a_item.is_point then
					-- at the middle of its year, where the cursor and labels stand
				x1 := year_x (a_item.year_from + 0.5) - 3.0
				x2 := x1 + 6.0
			else
				x2 := x2.max (x1 + 6.0)
			end
			l_text := a_p.advance (item_label (a_item)) + 8.0
			if x2 - x1 >= l_text then
				Result := [x1, x2 - x1, x2]
			else
				Result := [x1, x2 - x1, x2 + l_text]
			end
		end

	place_item (a_p: SW_PAINTER; a_item: SW_TIMELINE_ITEM; a_ends: ARRAYED_LIST [REAL_64]; a_rows: ARRAYED_LIST [INTEGER])
		local
			l_span: like item_span
			r: INTEGER
		do
			if is_shown_now (a_item) then
				l_span := item_span (a_p, a_item)
				r := free_block (a_ends, l_span.sx - Gap, 1)
				claim (a_ends, r, l_span.reach)
				a_rows.put_i_th (r, a_item.id)
				item_boxes.i_th (a_item.id).bx := l_span.sx
				item_boxes.i_th (a_item.id).bw := l_span.sw
				item_boxes.i_th (a_item.id).bh := row_h - 6.0
			end
		end

	place_dispute (a_p: SW_PAINTER; a_dispute, a_lane, a_first: INTEGER; a_ends: ARRAYED_LIST [REAL_64]; a_rows: ARRAYED_LIST [INTEGER])
			-- The shown positions of `a_dispute' in `a_lane' on consecutive
			-- rows from `a_first', inside one envelope box.
		local
			r: INTEGER
			l_span: like item_span
			l_right, l_left: REAL_64
		do
			r := a_first
			l_left := year_x (dispute_from.i_th (a_dispute))
			l_right := year_x (dispute_to.i_th (a_dispute) + 1)
			across
				lane_order (a_lane) as o
			loop
				if items.i_th (o).dispute = a_dispute and then is_shown_now (items.i_th (o)) then
					l_span := item_span (a_p, items.i_th (o))
					a_rows.put_i_th (r, o)
					item_boxes.i_th (o).bx := l_span.sx
					item_boxes.i_th (o).bw := l_span.sw
					item_boxes.i_th (o).bh := row_h - 6.0
					claim (a_ends, r, l_span.reach.max (l_right))
					r := r + 1
				end
			end
			envelope_boxes.extend ([l_left - 2.0, 0.0, (l_right - l_left) + 4.0, (r - a_first) * row_h - 2.0, a_dispute, a_lane])
		end

	item_label (a_item: SW_TIMELINE_ITEM): STRING_32
			-- Its title with its class label ("per the text", "tradition") and
			-- badge, for measuring.
		do
			Result := a_item.title.twin
			Result.append (item_suffix (a_item))
		end

	item_suffix (a_item: SW_TIMELINE_ITEM): STRING_32
			-- The class label and badge, drawn as their own run after the title
			-- so a right-to-left title does not carry them to its other side.
		do
			create Result.make_empty
			if a_item.certainty = {SW_TIMELINE_ITEM}.Class_f then
				Result.append ({STRING_32} " (per the text)")
			elseif a_item.certainty = {SW_TIMELINE_ITEM}.Class_g then
				Result.append ({STRING_32} " (tradition)")
			end
			if not a_item.badge.is_empty then
				Result.append ({STRING_32} " [")
				Result.append (a_item.badge)
				Result.append ({STRING_32} "]")
			end
		end


	draw_item (a_p: SW_PAINTER; a_item: SW_TIMELINE_ITEM)
			-- The certainty pattern, then the label inside or beside it, then a
			-- lean's marker and wording.
		local
			t: SW_THEME
			b: TUPLE [bx, by, bw, bh: REAL_64]
			l_label: STRING_32
			l_inside: BOOLEAN
			l_text_x: REAL_64
		do
			t := a_p.theme
			b := item_boxes.i_th (a_item.id)
			l_label := item_label (a_item)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			l_inside := not a_item.is_point and then b.bw >= a_p.advance (l_label) + 8.0
			inspect a_item.certainty
			when {SW_TIMELINE_ITEM}.Class_b, {SW_TIMELINE_ITEM}.Class_c then
				if a_item.is_point then
					draw_tick (a_p, b)
				else
					a_p.set_color (t.accent)
					a_p.rrect_fill (b.bx, b.by, b.bw, b.bh, t.radius)
				end
			when {SW_TIMELINE_ITEM}.Class_d then
				if a_item.is_point then
					draw_tick (a_p, b)
				else
					a_p.fade_rect (b.bx, b.by, b.bw / 2.0, b.bh, t.accent, 0.2, 1.0, False)
					a_p.fade_rect (b.bx + b.bw / 2.0, b.by, b.bw / 2.0, b.bh, t.accent, 1.0, 0.2, False)
				end
			when {SW_TIMELINE_ITEM}.Class_e then
				a_p.set_color_alpha (t.accent, 0.18)
				a_p.rrect_fill (b.bx, b.by, b.bw, b.bh, t.radius)
			when {SW_TIMELINE_ITEM}.Class_f then
				if a_item.is_point then
					draw_tick (a_p, b)
				else
					a_p.set_color (t.accent)
					a_p.dashed_rrect_stroke (b.bx + 0.5, b.by + 0.5, b.bw - 1.0, b.bh - 1.0, t.radius, 1.5, a_p.Stroke_dashed)
				end
			when {SW_TIMELINE_ITEM}.Class_g then
				a_p.set_color (t.accent)
				a_p.hatch_rrect (b.bx, b.by, b.bw, b.bh, t.radius, a_p.Hatch_forward, 5.0)
				a_p.set_color (t.outline)
				a_p.rrect_stroke (b.bx + 0.5, b.by + 0.5, b.bw - 1.0, b.bh - 1.0, t.radius)
			else
				draw_tick (a_p, b)
			end
			if l_inside and then (a_item.certainty = {SW_TIMELINE_ITEM}.Class_b or a_item.certainty = {SW_TIMELINE_ITEM}.Class_c) then
				a_p.set_color (t.ink_on_accent)
			else
				a_p.set_color (t.ink)
			end
			if l_inside then
				l_text_x := b.bx + 4.0
			else
				l_text_x := b.bx + b.bw + 4.0
			end
			a_p.text (l_text_x, b.by + (b.bh - a_p.text_extent) / 2.0 + a_p.font_ascent, a_item.title)
			if not item_suffix (a_item).is_empty then
				a_p.text (l_text_x + a_p.advance (a_item.title), b.by + (b.bh - a_p.text_extent) / 2.0 + a_p.font_ascent,
					item_suffix (a_item))
			end
			if attached a_item.lean_note as al_note then
				l_text_x := l_text_x + a_p.advance (l_label) + 8.0
				a_p.set_color (t.ink_accent)
				a_p.triangle_fill (l_text_x, b.by + b.bh, l_text_x + 4.0, b.by + 2.0, l_text_x + 8.0, b.by + b.bh)
				a_p.text (l_text_x + 12.0, b.by + (b.bh - a_p.text_extent) / 2.0 + a_p.font_ascent, al_note)
			end
		end

	draw_tick (a_p: SW_PAINTER; a_box: TUPLE [bx, by, bw, bh: REAL_64])
			-- Class A: a solid tick with a diamond.
		local
			cx: REAL_64
		do
			cx := a_box.bx + a_box.bw / 2.0
			a_p.set_color (a_p.theme.accent)
			a_p.line (cx, a_box.by - 2.0, cx, a_box.by + a_box.bh + 2.0, 2.0)
			a_p.triangle_fill (cx - 4.0, a_box.by + a_box.bh / 2.0, cx, a_box.by + a_box.bh / 2.0 - 4.0, cx + 4.0, a_box.by + a_box.bh / 2.0)
			a_p.triangle_fill (cx - 4.0, a_box.by + a_box.bh / 2.0, cx, a_box.by + a_box.bh / 2.0 + 4.0, cx + 4.0, a_box.by + a_box.bh / 2.0)
		end

	place_axis_labels (a_p: SW_PAINTER)
			-- The round years to label, each wholly inside the plot.
		local
			l_step: INTEGER
			l_x, l_w: REAL_64
		do
			axis_labels.wipe_out
			if plot_w > 0.0 then
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
				l_step := era.nice_step (years_per_pixel * 90.0)
				across
					era.ticks (view_from, view_to, l_step) as yr
				loop
					l_x := year_x (yr + 0.5)
					l_w := a_p.advance (era.label (yr))
					if l_x - l_w / 2.0 >= plot_left and then l_x + l_w / 2.0 <= plot_left + plot_w then
						axis_labels.extend ([yr.item, l_x - l_w / 2.0, l_w])
					end
				end
			end
		ensure
			whole: across axis_labels as al all al.lx >= plot_left and al.lx + al.lw <= plot_left + plot_w end
		end

	draw_axis (a_p: SW_PAINTER)
			-- The year strip: round years labelled BC/AD (never a year zero),
			-- with faint gridlines down the lanes.
		local
			t: SW_THEME
			l_x: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, axis_h)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			across
				axis_labels as al
			loop
				l_x := al.lx + al.lw / 2.0
				a_p.set_color (t.divider)
				a_p.fill_rect (l_x, y + axis_h, 1.0, height - axis_h)
				a_p.set_color (t.outline)
				a_p.fill_rect (l_x, y + axis_h - 6.0, 1.0, 6.0)
				a_p.set_color (t.ink_muted)
				a_p.text (al.lx, y + t.padding + a_p.font_ascent, era.label (al.year))
			end
			a_p.set_color (t.outline)
			a_p.fill_rect (x, y + axis_h - 1.0, width, 1.0)
		end

	draw_cursor_label (a_p: SW_PAINTER)
			-- The cursor's year in a chip on the axis.
		local
			t: SW_THEME
			l_label: STRING_32
			l_w, l_x: REAL_64
		do
			t := a_p.theme
			l_label := era.label (cursor_year)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
			l_w := a_p.advance (l_label) + 2.0 * t.control_inset
			l_x := (year_x (cursor_year + 0.5) - l_w / 2.0).max (plot_left).min (plot_left + plot_w - l_w)
			a_p.set_color (t.accent)
			a_p.rrect_fill (l_x, y + 2.0, l_w, axis_h - 4.0, t.radius)
			a_p.set_color (t.ink_on_accent)
			a_p.text (l_x + t.control_inset, y + (axis_h - a_p.text_extent) / 2.0 + a_p.font_ascent, l_label)
		end

invariant
	parallel_lanes: lane_groups.count = lane_titles.count
	parallel_disputes: dispute_from.count = dispute_titles.count and dispute_to.count = dispute_titles.count
	view_ordered: view_from < view_to

end
