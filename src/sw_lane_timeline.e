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
	river: "[
		2026-10-30, Plan 22 phase 1 (the River of Time), from its spikes; a note
		for the future self. (1) An index kept as items are added: each lane's
		items outside disputes sorted by start (binary-search insertion, stable),
		each lane's disputes with their positions; `arrange' places rows and
		envelopes in one pass from it and remembers what it laid out
		(`shown_ids'), and only items in the visible rows are drawn. The
		original re-sorted every lane each frame and scanned every item per
		dispute: 753 ms a frame at 10,000 items, now about 11 ms (spike S1),
		the same boxes. (2) Label widths are measured once per item and size.
		(3) A band that starts left of the plot keeps its label at the plot's
		edge. (4) Hover cards: an item's title and years. (5) The lens
		(`set_lens'): a bent scale u = -ln (1 + (anchor - year) / knee) blended
		with the linear one by the width of the view, exactly linear at 1,000
		years or less, fully bent at 20,000 or more, so one sweep reaches
		200,000 years ago; zoom, pan and drag work in the bent coordinate and
		the axis picks its round years stretch by stretch (spike S2).
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
			wants_hover_point, accessible_role, default_accessible_name, accessible_value,
			dwell_ms, hover_card_at
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
			lens_anchor := 136.0
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

	lane_ids: ARRAYED_LIST [ARRAYED_LIST [INTEGER]]
			-- Per lane: its items outside any dispute, by start year (equal starts in the order added).
		attribute
			create Result.make (8)
		end

	lane_disputes: ARRAYED_LIST [ARRAYED_LIST [INTEGER]]
			-- Per lane: the disputes with a position in it, in dispute order.
		attribute
			create Result.make (8)
		end

	dispute_positions: HASH_TABLE [ARRAYED_LIST [INTEGER], INTEGER]
			-- Key dispute * 65536 + lane: that dispute's positions in that lane, by start year.
		attribute
			create Result.make (8)
		end

	indexed_count: INTEGER
			-- `items.count' when the index was last complete.

	add_lane (a_title, a_group: READABLE_STRING_GENERAL): INTEGER
			-- A new lane in group `a_group'; its number.
		require
			room: lane_titles.count < 65535
		do
			lane_titles.extend (create {STRING_32}.make_from_string_general (a_title))
			lane_groups.extend (create {STRING_32}.make_from_string_general (a_group))
			lane_ids.extend (create {ARRAYED_LIST [INTEGER]}.make (16))
			lane_disputes.extend (create {ARRAYED_LIST [INTEGER]}.make (2))
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
			index_plain (Result)
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
			create Result.make (items.count + 1, a_lane, a_title, a_from, a_to, a_class)
			items.extend (Result)
			Result.set_dispute (a_dispute)
			index_position (Result)
		ensure
			a_position: Result.dispute = a_dispute
			added: items.last = Result and Result.id = items.count
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
			view_to := a_to.min (a_from + span_limit)
			if is_lens then
				view_to := view_to.min (lens_anchor + Lens_knee / 2.0).max (view_from + Min_span)
			end
		ensure
			set: view_from = a_from
		end

	span_limit: REAL_64
			-- The widest view: `Max_span', or `Lens_max_span' through the lens.
		do
			if is_lens then
				Result := Lens_max_span
			else
				Result := Max_span
			end
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
			l_span, l_new, l_t, l_u, l_us, l_un, l_lo, l_hi: REAL_64
		do
			if is_lens then
					-- in the bent coordinate, so the year stays where it is
				l_u := u_of (a_year.min (lens_anchor - 1.0))
				l_us := u_of (view_to) - u_of (view_from)
				l_t := ((l_u - u_of (view_from)) / l_us).max (0.0).min (1.0)
				l_un := l_us * a_factor
				l_lo := year_of_u (l_u - l_t * l_un)
				l_hi := year_of_u (l_u - l_t * l_un + l_un)
				if l_hi - l_lo >= Min_span and l_hi - l_lo <= Lens_max_span then
					view_from := l_lo.max (Lens_deepest)
					view_to := l_hi.min (lens_anchor + Lens_knee / 2.0).max (view_from + Min_span)
				end
			else
				l_span := view_to - view_from
				l_new := (l_span * a_factor).max (Min_span).min (Max_span)
				l_t := ((a_year - view_from) / l_span).max (0.0).min (1.0)
				view_from := a_year - l_t * l_new
				view_to := view_from + l_new
			end
		ensure
			ordered: view_from < view_to
		end

	pan (a_years: REAL_64)
			-- Move by `a_years' (through the lens, as measured at the middle of the view).
		local
			l_mid: REAL_64
		do
			if is_lens then
				l_mid := (view_from + view_to) / 2.0
				shift_u (u_of ((l_mid + a_years).min (lens_anchor - 1.0)) - u_of (l_mid.min (lens_anchor - 1.0)))
			else
				view_from := view_from + a_years
				view_to := view_to + a_years
			end
		end

	years_per_pixel: REAL_64
			-- Years a pixel spans (through the lens, at the middle of the plot).
		local
			cx: REAL_64
		do
			if is_lens and plot_w > 1.0 then
				cx := plot_left + plot_w / 2.0
				Result := year_at (cx + 1.0) - year_at (cx)
			else
				Result := (view_to - view_from) / plot_w.max (1.0)
			end
		end

feature -- The lens (Plan 22, spike S2)

	is_lens: BOOLEAN
			-- Is the scale bent toward deep time?

	lens_anchor: REAL_64
			-- The year the bend is measured from (the river's end), astronomical; AD 135 + 1 at first.

	set_lens (a_on: BOOLEAN)
		do
			is_lens := a_on
		ensure
			set: is_lens = a_on
		end

	set_lens_anchor (a_year: REAL_64)
		do
			lens_anchor := a_year
		ensure
			set: lens_anchor = a_year
		end

	Lens_knee: REAL_64 = 1000.0
			-- Years from the anchor over which the bent scale is still close to linear.

	Lens_max_span: REAL_64 = 250000.0
	Lens_deepest: REAL_64 = -260000.0

	lens_blend: REAL_64
			-- 0 (exactly linear) at a view of 1,000 years or less, 1 (fully bent) at 20,000 or more.
		local
			l_span: REAL_64
		do
			if is_lens then
				l_span := view_to - view_from
				if l_span > 1000.0 then
					Result := ((math.log10 (l_span) - 3.0) / (math.log10 (20000.0) - 3.0)).min (1.0)
				end
			end
		ensure
			between: Result >= 0.0 and Result <= 1.0
		end

	u_of (a_year: REAL_64): REAL_64
			-- The bent coordinate of `a_year'.
		do
			Result := - math.log (1.0 + (lens_anchor - a_year.min (lens_anchor + Lens_knee * 0.9)) / Lens_knee)
		end

	year_of_u (a_u: REAL_64): REAL_64
		do
			Result := lens_anchor - Lens_knee * (math.exp (- a_u) - 1.0)
		end

	math: DOUBLE_MATH
		once
			create Result
		end

	shift_u (a_du: REAL_64)
			-- Move the view by `a_du' in the bent coordinate.
		local
			l_lo, l_hi: REAL_64
		do
			l_lo := year_of_u (u_of (view_from) + a_du)
			l_hi := year_of_u (u_of (view_to) + a_du)
			if l_lo >= Lens_deepest and l_hi <= lens_anchor + Lens_knee / 2.0 and l_hi - l_lo >= Min_span then
				view_from := l_lo
				view_to := l_hi
			end
		end

	position (a_year: REAL_64): REAL_64
			-- Where `a_year' falls across the plot, 0 at the left edge and 1 at the right.
		local
			a: REAL_64
		do
			Result := (a_year - view_from) / (view_to - view_from)
			a := lens_blend
			if a > 0.0 then
				Result := (1.0 - a) * Result + a * (u_of (a_year) - u_of (view_from)) / (u_of (view_to) - u_of (view_from))
			end
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
			-- The plot x of `a_year' (through the lens when it is on).
		do
			if is_lens then
				Result := plot_left + position (a_year) * plot_w
			else
				Result := plot_left + (a_year - view_from) / (view_to - view_from) * plot_w
			end
		end

	year_at (a_px: REAL_64): REAL_64
			-- The year under plot x `a_px' (through the lens, by bisection: the scale only increases).
		local
			t, lo, hi, mid, l_span: REAL_64
			i: INTEGER
		do
			t := (a_px - plot_left) / plot_w.max (1.0)
			if not is_lens or else lens_blend = 0.0 then
				Result := view_from + t * (view_to - view_from)
			else
				l_span := view_to - view_from
				if t < 0.0 then
					lo := view_from - l_span
					hi := view_from
				elseif t > 1.0 then
					lo := view_to
					hi := (view_to + l_span).min (lens_anchor + Lens_knee * 0.85)
				else
					lo := view_from
					hi := view_to
				end
				from i := 1 until i > 60 loop
					mid := (lo + hi) / 2.0
					if position (mid) < t then
						lo := mid
					else
						hi := mid
					end
					i := i + 1
				end
				Result := (lo + hi) / 2.0
			end
		end

	label_left (a_item: SW_TIMELINE_ITEM): REAL_64
			-- Where `a_item''s label starts as last laid out: inside its box, kept at the plot's
			-- left edge when the box starts left of it; else just right of the box.
		require
			laid_out: item_boxes.count = items.count
			known: items.has (a_item)
		local
			b: TUPLE [bx, by, bw, bh: REAL_64]
		do
			b := item_boxes.i_th (a_item.id)
			if not a_item.is_point and then b.bw >= label_widths.i_th (a_item.id) + 8.0 then
				Result := (b.bx + 4.0).max ((plot_left + 4.0).min (b.bx + b.bw - label_widths.i_th (a_item.id) - 4.0))
			else
				Result := b.bx + b.bw + 4.0
			end
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
		do
			if item_boxes.count = items.count then
				across shown_ids as ic loop
					if a_px >= item_boxes.i_th (ic).bx and then a_px <= item_boxes.i_th (ic).bx + item_boxes.i_th (ic).bw
						and then a_py >= item_boxes.i_th (ic).by and then a_py <= item_boxes.i_th (ic).by + item_boxes.i_th (ic).bh
					then
						Result := items.i_th (ic)
					end
				end
			end
		end

	shown_ids: ARRAYED_LIST [INTEGER]
			-- The items the last `arrange' laid out, in the order it placed them.
		attribute
			create Result.make (64)
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
			-- consecutive rows inside its envelope, then the rest by start. From
			-- the index, in one pass (Plan 22, spike S1).
		local
			l, k, l_first, r: INTEGER
			cy, l_left, l_right: REAL_64
			l_group: detachable STRING_32
			l_ends: ARRAYED_LIST [REAL_64]
			l_span: like item_span
			it: SW_TIMELINE_ITEM
		do
			ensure_index
			measure (a_p)
			from until item_boxes.count >= items.count loop
				item_boxes.extend ([0.0, 0.0, 0.0, 0.0])
			end
			across shown_ids as ic loop
				item_boxes.i_th (ic).bx := 0.0
				item_boxes.i_th (ic).by := 0.0
				item_boxes.i_th (ic).bw := 0.0
				item_boxes.i_th (ic).bh := 0.0
			end
			shown_ids.wipe_out
			envelope_boxes.wipe_out
			lane_tops.wipe_out
			lane_heights.wipe_out
			headers.wipe_out
			cy := y + axis_h - scroll_y
			from l := 1 until l > lane_titles.count loop
				if l_group = Void or else not l_group.same_string (lane_groups.i_th (l)) then
					l_group := lane_groups.i_th (l)
					headers.extend ([l_group, cy])
					cy := cy + row_h
				end
				lane_tops.extend (cy)
				if is_lane_shown (l) then
					create l_ends.make (4)
						-- disputes, each as a block of consecutive rows
					across lane_disputes.i_th (l) as d loop
						if attached dispute_positions.item (d * 65536 + l) as al_positions then
							k := 0
							across al_positions as ps loop
								if is_shown_now (items.i_th (ps)) then
									k := k + 1
								end
							end
							if k > 0 then
								l_first := free_block (l_ends, year_x (dispute_from.i_th (d)) - Gap, k)
								l_left := year_x (dispute_from.i_th (d))
								l_right := year_x (dispute_to.i_th (d) + 1)
								r := l_first
								across al_positions as ps loop
									it := items.i_th (ps)
									if is_shown_now (it) then
										l_span := item_span (a_p, it)
										put_box (it.id, l_span.sx, cy + (r - 1) * row_h + 3.0, l_span.sw)
										claim (l_ends, r, l_span.reach.max (l_right))
										r := r + 1
									end
								end
								envelope_boxes.extend ([l_left - 2.0, cy + (l_first - 1) * row_h + 1.0, (l_right - l_left) + 4.0, (r - l_first) * row_h - 2.0, d.item, l])
							end
						end
					end
						-- the rest, by start; nothing that starts after the view can show
					across lane_ids.i_th (l) as o until items.i_th (o).year_from > view_to loop
						it := items.i_th (o)
						if is_shown_now (it) then
							l_span := item_span (a_p, it)
							r := free_block (l_ends, l_span.sx - Gap, 1)
							claim (l_ends, r, l_span.reach)
							put_box (it.id, l_span.sx, cy + (r - 1) * row_h + 3.0, l_span.sw)
						end
					end
					lane_heights.extend (l_ends.count.max (1) * row_h)
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
			across shown_ids as ic loop
				if item_boxes.i_th (ic).by + item_boxes.i_th (ic).bh >= y + axis_h and then item_boxes.i_th (ic).by <= y + height then
					draw_item (a_p, items.i_th (ic))
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

	dwell_ms: INTEGER
			-- A rest of 400 ms on an item opens its card.
		do
			Result := 400
		end

	hover_card_at (a_px, a_py: REAL_64): detachable SW_HOVER_CARD
			-- The item under the point: its title, its years, and a dispute's name and other positions.
		local
			l_col: SW_COLUMN
			l_others: STRING_32
			b: TUPLE [bx, by, bw, bh: REAL_64]
		do
			if attached item_at (a_px, a_py) as al_item then
				create l_col.make
				l_col.put (create {SW_LABEL}.make_ui (al_item.title))
				l_col.put (create {SW_LABEL}.make_ui (era.range_label (al_item.year_from, al_item.year_to)))
				if al_item.dispute > 0 then
					create l_others.make_from_string_general ({STRING_32} "Disputed: " + dispute_titles.i_th (al_item.dispute))
					if attached dispute_positions.item (al_item.dispute * 65536 + al_item.lane) as al_ps then
						across al_ps as ps loop
							if ps /= al_item.id then
								l_others.append ({STRING_32} "; also " + items.i_th (ps).title)
							end
						end
					end
					l_col.put (create {SW_LABEL}.make_ui (l_others))
				end
				create Result.make (l_col, 320.0)
				b := item_boxes.i_th (al_item.id)
				Result.set_anchor (b.bx, b.by, b.bw.max (1.0), b.bh)
			end
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
				press_to := view_to
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
				if is_lens then
						-- in the bent coordinate, from where the press found the view
					view_from := press_from
					view_to := press_to
					shift_u (- (a_px - press_x) * (u_of (press_to) - u_of (press_from)) / plot_w.max (1.0))
				else
					l_span := view_to - view_from
					view_from := press_from - (a_px - press_x) * l_span / plot_w.max (1.0)
					view_to := view_from + l_span
				end
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

	press_x, press_from, press_to: REAL_64
	is_panning: BOOLEAN

	Gap: REAL_64 = 6.0
			-- Between items stacked on one row.

	index_plain (a_item: SW_TIMELINE_ITEM)
			-- Put `a_item' into its lane's list, after every item that starts no later.
		local
			l_list: ARRAYED_LIST [INTEGER]
			lo, hi, mid: INTEGER
		do
			l_list := lane_ids.i_th (a_item.lane)
			lo := 1
			hi := l_list.count + 1
			from until lo >= hi loop
				mid := (lo + hi) // 2
				if items.i_th (l_list.i_th (mid)).year_from <= a_item.year_from then
					lo := mid + 1
				else
					hi := mid
				end
			end
			if lo > l_list.count then
				l_list.extend (a_item.id)
			else
				l_list.go_i_th (lo)
				l_list.put_left (a_item.id)
			end
			indexed_count := indexed_count + 1
		end

	index_position (a_item: SW_TIMELINE_ITEM)
			-- Put dispute position `a_item' into its dispute's list for its lane, by start.
		local
			l_key, i: INTEGER
			l_list: ARRAYED_LIST [INTEGER]
		do
			l_key := a_item.dispute * 65536 + a_item.lane
			if attached dispute_positions.item (l_key) as al_list then
				l_list := al_list
			else
				create l_list.make (3)
				dispute_positions.put (l_list, l_key)
				lane_disputes.i_th (a_item.lane).extend (a_item.dispute)
			end
			from i := l_list.count until i < 1 or else items.i_th (l_list.i_th (i)).year_from <= a_item.year_from loop
				i := i - 1
			end
			if i >= l_list.count then
				l_list.extend (a_item.id)
			else
				l_list.go_i_th (i + 1)
				l_list.put_left (a_item.id)
			end
			indexed_count := indexed_count + 1
		end

	ensure_index
			-- Rebuild the index when it no longer matches the items (items added another way).
		do
			if indexed_count /= items.count then
				across lane_ids as ic loop
					ic.wipe_out
				end
				across lane_disputes as ic loop
					ic.wipe_out
				end
				dispute_positions.wipe_out
				indexed_count := 0
				across items as it loop
					if it.dispute = 0 then
						index_plain (it)
					else
						index_position (it)
					end
				end
			end
		ensure
			complete: indexed_count = items.count
		end

	put_box (a_id: INTEGER; a_x, a_y, a_w: REAL_64)
		do
			item_boxes.i_th (a_id).bx := a_x
			item_boxes.i_th (a_id).by := a_y
			item_boxes.i_th (a_id).bw := a_w
			item_boxes.i_th (a_id).bh := row_h - 6.0
			shown_ids.extend (a_id)
		end

	label_widths: ARRAYED_LIST [REAL_64]
			-- Per item: its label's advance at `widths_size'; 0 when not yet measured.
		attribute
			create Result.make (64)
		end

	widths_size: REAL_64
			-- The label size `label_widths' were measured at.

	label_width (a_p: SW_PAINTER; a_item: SW_TIMELINE_ITEM): REAL_64
			-- `a_item''s label advance, measured once per item and size.
		local
			i: INTEGER
		do
			from until label_widths.count >= items.count loop
				label_widths.extend (0.0)
			end
			if widths_size /= a_p.theme.size_label then
				from i := 1 until i > label_widths.count loop
					label_widths.put_i_th (0.0, i)
					i := i + 1
				end
				widths_size := a_p.theme.size_label
			end
			Result := label_widths.i_th (a_item.id)
			if Result = 0.0 then
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
				Result := a_p.advance (item_label (a_item)).max (0.001)
				label_widths.put_i_th (Result, a_item.id)
			end
		end

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
			l_text := label_width (a_p, a_item) + 8.0
			if x2 - x1 >= l_text then
				Result := [x1, x2 - x1, x2]
			else
				Result := [x1, x2 - x1, x2 + l_text]
			end
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
			l_inside := not a_item.is_point and then b.bw >= label_width (a_p, a_item) + 8.0
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
			l_text_x := label_left (a_item)
			a_p.text (l_text_x, b.by + (b.bh - a_p.text_extent) / 2.0 + a_p.font_ascent, a_item.title)
			if not item_suffix (a_item).is_empty then
				a_p.text (l_text_x + a_p.advance (a_item.title), b.by + (b.bh - a_p.text_extent) / 2.0 + a_p.font_ascent,
					item_suffix (a_item))
			end
			if attached a_item.lean_note as al_note then
				l_text_x := l_text_x + label_width (a_p, a_item) + 8.0
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
			if is_lens and then lens_blend > 0.0 then
				place_lens_labels (a_p)
			elseif plot_w > 0.0 then
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

	place_lens_labels (a_p: SW_PAINTER)
			-- Through the lens: every 100 px, the first round year of that stretch at its own
			-- step, kept when it is whole inside the plot and clear of the last label.
		local
			l_x, l_w, l_last_end, l_lx, l_from, l_to: REAL_64
			l_step: INTEGER
			l_done: BOOLEAN
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			l_last_end := plot_left - 1000.0
			from l_x := plot_left until l_x >= plot_left + plot_w loop
				l_from := year_at (l_x)
				l_to := year_at ((l_x + 100.0).min (plot_left + plot_w))
				l_step := era.nice_step ((l_to - l_from) / 100.0 * 90.0).max (1)
				l_done := False
				across era.ticks (l_from, l_to, l_step) as yr until l_done loop
					l_lx := year_x (yr + 0.5)
					l_w := a_p.advance (era.label (yr))
					if l_lx - l_w / 2.0 >= plot_left and then l_lx + l_w / 2.0 <= plot_left + plot_w
						and then l_lx - l_w / 2.0 >= l_last_end + 12.0
					then
						axis_labels.extend ([yr.item, l_lx - l_w / 2.0, l_w])
						l_last_end := l_lx + l_w / 2.0
						l_done := True
					end
				end
				l_x := l_x + 100.0
			end
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
