note
	description: "[
		The legend, drawn: one row per reason in definition order - a
		live SWATCH (sample text painted through SW_MARK_PAINTER with
		that reason's own mark, so the key can never drift from what
		the text shows), the badge if any, and the label. The reader's
		ready reference for a palette of highlights they cannot keep in
		their head.

		Click a row and `on_pick' fires with the reason - the natural
		door for "apply this to the selection". The host that owns the
		selection decides what that means.

		The swatch is measured with the same geometry the widgets use,
		on whichever engine the painter offers, at the body size; the
		painter's size policy applies to it too, so a legend at a small
		scale shows what the text at that scale will actually get.
	]"
	author: "Larry Rix"

class
	SW_MARK_LEGEND_VIEW

inherit
	SW_WIDGET
		redefine
			handle_click, wants_hover_point, accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make (a_legend: SW_MARK_LEGEND)
		do
			legend := a_legend
			create painter.make
			create sample.make_from_string ("Aa")
			create geometry.make
			create marks.make (sample.count)
			swatch_id := marks.mark_range (0, sample.count, "swatch")
			row_h := 26.0
		ensure
			kept: legend = a_legend
		end

feature -- Access

	legend: SW_MARK_LEGEND

	painter: SW_MARK_PAINTER
			-- The one that paints the swatches; set its floors to match
			-- the text widgets' painter.

	sample: STRING_32
			-- What a swatch shows.

	on_pick: detachable PROCEDURE [STRING_32]
			-- A row was clicked: this reason.

	row_h: REAL_64

	Swatch_w: REAL_64 = 44.0
	Badge_w: REAL_64 = 26.0
	Pad: REAL_64 = 6.0

	row_at (a_py: REAL_64): INTEGER
			-- The 1-based row under `a_py'; 0 outside.
		do
			if a_py >= y + Pad and then a_py < y + Pad + legend.count * row_h then
				Result := ((a_py - y - Pad) / row_h).truncated_to_integer + 1
				if Result > legend.count then
					Result := 0
				end
			end
		ensure
			in_range: Result >= 0 and Result <= legend.count
		end

feature -- Element change

	set_sample (a_text: READABLE_STRING_GENERAL)
		require
			not_empty: not a_text.is_empty
		do
			create sample.make_from_string_general (a_text)
			create marks.make (sample.count)
			swatch_id := marks.mark_range (0, sample.count, "swatch")
		ensure
			kept: sample.same_string_general (a_text)
		end

	set_on_pick (a_action: PROCEDURE [STRING_32])
		do
			on_pick := a_action
		ensure
			set: on_pick = a_action
		end

	set_row_height (a_h: REAL_64)
		require
			positive: a_h > 0.0
		do
			row_h := a_h
		ensure
			set: row_h = a_h
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	accepts_focus: BOOLEAN
		do
			Result := False
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := legend.count * row_h + 2.0 * Pad
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			ry, px, sx, sy: REAL_64
			k: STRING_32
			keys: ARRAYED_LIST [STRING_32]
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			px := t.size_body * t.text_scale
			keys := legend.keys
			a_p.font ({SW_PAINTER}.Role_body, t.size_body, False)
			if attached a_p.shaping as al_kit then
				geometry.build_shaped (al_kit, sample, 0, px.rounded.max (1), True)
			else
				geometry.build_toy (a_p, sample, 1000.0, True, False)
			end
			from
				i := 1
			until
				i > keys.count
			loop
				k := keys.i_th (i)
				ry := y + Pad + (i - 1) * row_h
				if shows_hover and then row_at (hover_py) = i then
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (x + 1.0, ry, width - 2.0, row_h)
				end
				if attached legend.mark_of (k) as m then
					marks.restyle (swatch_id, m)
					sx := x + Pad + 4.0
					sy := ry + (row_h - geometry.content_height) / 2.0
					painter.paint_under (a_p, geometry, marks, Void, sx, sy)
					a_p.set_color (t.ink)
					draw_sample (a_p, 0.0, 0.0, sx, sy)
					painter.paint_over (a_p, geometry, marks, Void, sx, sy, px, agent draw_sample (?, ?, ?, sx, sy))
					if not legend.badge_of (k).is_empty then
						a_p.font ({SW_PAINTER}.Role_mono, t.size_chip, True)
						a_p.set_color (painter.palette.ink (m.hue, t))
						a_p.text (x + Pad + Swatch_w + 4.0, a_p.baseline_in (ry, row_h), legend.badge_of (k))
					end
				end
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink)
				a_p.text (x + Pad + Swatch_w + Badge_w, a_p.baseline_in (ry, row_h), legend.label_of (k))
				i := i + 1
			end
			a_p.pop_clip
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			r: INTEGER
		do
			r := row_at (a_py)
			if r > 0 then
				if attached on_pick as al_p then
					al_p.call (legend.keys.i_th (r))
				end
				Result := True
			end
		end

feature {NONE} -- Implementation

	geometry: SW_TEXT_GEOMETRY
	marks: SW_MARKED_TEXT
	swatch_id: INTEGER
			-- The one span over the sample, restyled per row.

	draw_sample (a_p: SW_PAINTER; a_dx, a_dy, a_sx, a_sy: REAL_64)
			-- The sample text at the swatch origin plus an offset, in
			-- the painter's current colour.
		local
			i: INTEGER
		do
			if geometry.is_shaped then
				from
					i := 1
				until
					i > geometry.layouts.count
				loop
					a_p.draw_shaped_layout (geometry.layouts.i_th (i), a_sx + a_dx, a_sy + a_dy + geometry.para_tops.i_th (i))
					i := i + 1
				end
			else
				a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
				from
					i := 1
				until
					i > geometry.count
				loop
					a_p.text (a_sx + a_dx + geometry.x_of (i),
						a_sy + a_dy + geometry.top_of_line (geometry.line_of (i)) + geometry.ascent_of_line (geometry.line_of (i)),
						sample.substring (i, i))
					i := i + 1
				end
			end
		end

invariant
	row_positive: row_h > 0.0
	sample_present: not sample.is_empty

end
