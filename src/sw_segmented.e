note
	description: "[
		One choice among a few, worn as buttons: a pill of segments,
		exactly one selected (the first, at birth - same law as the
		radio group). Radio semantics in button clothes.
	]"

class
	SW_SEGMENTED

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create segments.make (4)
		end

feature -- Access

	segments: ARRAYED_LIST [STRING_32]

	segment_glyphs: ARRAYED_LIST [INTEGER]
			-- Parallel to `segments': a drawn glyph per segment
			-- (0 = text segment).
		attribute
			create Result.make (4)
		end

	selected_index: INTEGER
			-- 1-based; 0 only while empty.

	selected_text: STRING_32
		do
			if selected_index >= 1 and selected_index <= segments.count then
				Result := segments.i_th (selected_index)
			else
				create Result.make_empty
			end
		end

	on_change: detachable PROCEDURE [INTEGER]

feature -- Element change

	add_segment (a_text: READABLE_STRING_GENERAL)
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			segments.extend (s)
			segment_glyphs.extend (0)
			if selected_index = 0 then
				selected_index := 1
			end
		ensure
			grew: segments.count = old segments.count + 1
			something_chosen: selected_index >= 1
		end

	add_icon_segment (a_glyph: INTEGER)
			-- A drawn-glyph segment (no text).
		require
			glyph_known: a_glyph >= 1 and a_glyph <= {SW_PAINTER}.Glyph_error
		local
			s: STRING_32
		do
			create s.make_empty
			segments.extend (s)
			segment_glyphs.extend (a_glyph)
			if selected_index = 0 then
				selected_index := 1
			end
		ensure
			grew: segments.count = old segments.count + 1
			parallel: segment_glyphs.count = segments.count
		end

	with_icon_segment (a_glyph: INTEGER): like Current
		require
			glyph_known: a_glyph >= 1 and a_glyph <= {SW_PAINTER}.Glyph_error
		do
			add_icon_segment (a_glyph)
			Result := Current
		ensure
			chained: Result = Current
		end

	with_segment (a_text: READABLE_STRING_GENERAL): like Current
		do
			add_segment (a_text)
			Result := Current
		ensure
			chained: Result = Current
		end

	select_segment (a_i: INTEGER)
		require
			in_range: a_i >= 1 and a_i <= segments.count
		do
			if a_i /= selected_index then
				selected_index := a_i
				if attached on_change as a then
					a.call (a_i)
				end
			end
		ensure
			selected: selected_index = a_i
		end

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := 4.0
			across
				1 |..| segments.count as k
			loop
				Result := Result + seg_w (a_p, k)
			end
		end

	seg_w (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
			-- One segment's width - THE shared measure: layout, draw
			-- and click zones all ask here, so they can never drift
			-- (this class's own gotcha law).
		require
			in_range: a_i >= 1 and a_i <= segments.count
		do
			if segment_glyphs.i_th (a_i) > 0 then
				Result := 34.0
			else
				Result := a_p.advance (segments.i_th (a_i)) + 26.0
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 32.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tx, tw: REAL_64
			i: INTEGER
		do
			probe_painter := a_p
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.rrect_fill (x, y, width, height, height / 2.0)
			tx := x + 2.0
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			from
				i := 1
			until
				i > segments.count
			loop
				tw := seg_w (a_p, i)
				if i = selected_index then
					a_p.set_color (t.accent)
					a_p.rrect_fill (tx, y + 3.0, tw, height - 6.0, (height - 6.0) / 2.0)
					a_p.set_color (t.surface)
				elseif shows_hover and then hover_px >= tx and then hover_px <= tx + tw then
					a_p.set_color (t.surface)
					a_p.rrect_fill (tx, y + 3.0, tw, height - 6.0, (height - 6.0) / 2.0)
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				if segment_glyphs.i_th (i) > 0 then
					a_p.glyph (segment_glyphs.i_th (i), tx + tw / 2.0, y + height / 2.0, 14.0)
				else
					a_p.text (tx + 13.0, y + height / 2.0 + t.size_label / 2.0 - 2.0, segments.i_th (i))
				end
				tx := tx + tw
				i := i + 1
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			tx, tw: REAL_64
			i: INTEGER
		do
			if is_enabled and then attached probe_painter as p then
				p.font ({SW_PAINTER}.Role_ui, p.theme.size_label, False)
				tx := x + 2.0
				from
					i := 1
				until
					i > segments.count
				loop
					tw := seg_w (p, i)
					if a_px >= tx and a_px < tx + tw then
						select_segment (i)
					end
					tx := tx + tw
					i := i + 1
				end
				Result := True
			end
		end

feature {NONE} -- Measurement support

	probe_painter: detachable SW_PAINTER

invariant
	segments_attached: segments /= Void
	selection_in_range: selected_index >= 0 and selected_index <= segments.count
	selected_when_populated: segments.count > 0 implies selected_index >= 1

end
