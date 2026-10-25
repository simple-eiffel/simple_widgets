note
	description: "[
		Paints the highlights of a SW_MARKED_TEXT over a text whose
		geometry is known (SW_TEXT_GEOMETRY), resolving each span's look
		through its explicit mark or the legend. Two calls bracket the
		widget's own text drawing:

		    paint_under   the washes - tints BEHIND the text
		    paint_over    the text effects (colorized, outlined, bold,
		                  italic) and the boxes AROUND it

		THE TEXT EFFECTS ARE A REDRAW. Cairo here strokes no glyph
		paths and the shaping facade shapes everything regular and
		upright, so a coloured, outlined, bold or slanted span is made
		by clipping to the span's rectangles and drawing the text
		AGAIN through the widget's own `a_draw_text' agent -
		(painter, dx, dy) draws the whole text shifted by (dx, dy) in
		the painter's current colour:

		    outline   eight offset passes in the outline colour, then
		              the fill (a double outline: an outer ring in the
		              hue's ink, an inner ring in the surface colour)
		    bold      a second pass offset by a fraction of a pixel
		    italic    a shear about the line's baseline (one packed
		              CAIRO_MATRIX through `transform')
		    colorized the fill in the hue's ink instead of the theme's

		None of these change a glyph's advance, so the layout the
		caret and the hit-test use is untouched - which is the whole
		reason to approximate rather than re-shape.

		Colour choices keep the text readable: a colorized span's
		outline is drawn in the theme's ink so the two never merge; a
		wash is the palette's wash, held to 4.5:1 against the theme's
		ink by SW_MARK_PALETTE's own contract.

		SIZE POLICY. Small type cannot carry outlines, slants and tags
		without turning to clutter, so `paint_over' takes the text's
		pixel size and applies a floor: below `min_effect_size' the
		glyph effects and badges are dropped and a box is at most one
		rule (wash, single box and colour stay legible small); below
		`min_mark_size' nothing but the wash is painted. Both floors
		are settable; `effects_allowed' and `badges_allowed' say what
		the current size permits, so a host can grey its own palette.

		BADGES. A reason's badge (SW_MARK_LEGEND.badge_of) is painted
		once per span, as a small chip in the hue's ink at the top-left
		of the span's first segment, in the mono face at chip size.
	]"
	author: "Larry Rix"

class
	SW_MARK_PAINTER

create
	make

feature {NONE} -- Initialization

	make
		do
			create palette
			min_effect_size := 11.0
			min_mark_size := 7.0
			min_badge_size := 12.0
		ensure
			default_floors: min_effect_size = 11.0 and min_mark_size = 7.0 and min_badge_size = 12.0
		end

feature -- Access

	palette: SW_MARK_PALETTE

	min_effect_size: REAL_64
			-- Pixel size below which outlines, bold, italic are dropped
			-- and a box is at most one rule.

	min_mark_size: REAL_64
			-- Pixel size below which only the wash is painted.

	min_badge_size: REAL_64
			-- Pixel size below which badges are dropped.

	effects_allowed (a_px: REAL_64): BOOLEAN
		do
			Result := a_px >= min_effect_size
		end

	marks_allowed (a_px: REAL_64): BOOLEAN
		do
			Result := a_px >= min_mark_size
		end

	badges_allowed (a_px: REAL_64): BOOLEAN
		do
			Result := a_px >= min_badge_size
		end

feature -- Element change

	set_floors (a_mark, a_effect, a_badge: REAL_64)
			-- The three size floors, in ascending order.
		require
			ordered: a_mark >= 0.0 and a_mark <= a_effect and a_effect <= a_badge
		do
			min_mark_size := a_mark
			min_effect_size := a_effect
			min_badge_size := a_badge
		ensure
			set: min_mark_size = a_mark and min_effect_size = a_effect and min_badge_size = a_badge
		end

	resolve (a_span: SW_MARK_SPAN; a_legend: detachable SW_MARK_LEGEND): detachable SW_MARK
			-- The look for `a_span': its own, else the legend's, else
			-- nothing.
		do
			if attached a_span.mark as m then
				Result := m
			elseif attached a_legend as l then
				Result := l.mark_of (a_span.reason)
			end
		end

feature -- Painting

	paint_under (a_p: SW_PAINTER; a_geo: SW_TEXT_GEOMETRY; a_marks: SW_MARKED_TEXT;
			a_legend: detachable SW_MARK_LEGEND; a_ox, a_oy: REAL_64)
			-- The washes, bottom span first, over the text origin (a_ox, a_oy).
		require
			same_text: a_marks.text_count = a_geo.count
		local
			i: INTEGER
			s: SW_MARK_SPAN
		do
			from
				i := 1
			until
				i > a_marks.count
			loop
				s := a_marks.i_th (i)
				if attached resolve (s, a_legend) as m and then m.has_wash then
					a_p.set_color (palette.wash (m.hue, a_p.theme))
					across
						a_geo.segments (s.lo, s.hi) as g
					loop
						a_p.fill_rect (a_ox + g.left - 1.0, a_oy + a_geo.top_of_line (g.line),
							g.width + 2.0, a_geo.height_of_line (g.line))
					end
				end
				i := i + 1
			end
		end

	paint_over (a_p: SW_PAINTER; a_geo: SW_TEXT_GEOMETRY; a_marks: SW_MARKED_TEXT;
			a_legend: detachable SW_MARK_LEGEND; a_ox, a_oy, a_px: REAL_64;
			a_draw_text: PROCEDURE [SW_PAINTER, REAL_64, REAL_64])
			-- The text effects, then the boxes, then the badges, bottom
			-- span first, under the size policy for type `a_px' tall.
		require
			same_text: a_marks.text_count = a_geo.count
			size_positive: a_px > 0.0
		local
			i, lines: INTEGER
			s: SW_MARK_SPAN
			effects, badges: BOOLEAN
			segs: ARRAYED_LIST [TUPLE [line: INTEGER; left, width: REAL_64]]
		do
			if marks_allowed (a_px) then
				effects := effects_allowed (a_px)
				badges := badges_allowed (a_px)
				from
					i := 1
				until
					i > a_marks.count
				loop
					s := a_marks.i_th (i)
					if attached resolve (s, a_legend) as m then
						segs := a_geo.segments (s.lo, s.hi)
						if effects and then m.changes_glyphs then
							across
								segs as g
							loop
								paint_effect_segment (a_p, a_geo, m, g.line, a_ox + g.left, g.width, a_ox, a_oy, a_draw_text)
							end
						elseif m.is_colorized then
								-- colour alone stays legible small
							across
								segs as g
							loop
								paint_colour_only (a_p, a_geo, m, g.line, a_ox + g.left, g.width, a_oy, a_draw_text)
							end
						end
						if m.box_lines > 0 then
							lines := m.box_lines
							if not effects then
								lines := 1
							end
							a_p.set_color (palette.ink (m.hue, a_p.theme))
							a_p.set_line_width (1.0)
							across
								segs as g
							loop
								paint_box (a_p, a_ox + g.left, a_oy + a_geo.top_of_line (g.line),
									g.width, a_geo.height_of_line (g.line), lines)
							end
						end
						if badges and then attached a_legend as l and then not segs.is_empty then
							paint_badge (a_p, l.badge_of (s.reason), m, a_ox + segs.first.left,
								a_oy + a_geo.top_of_line (segs.first.line))
						end
					end
					i := i + 1
				end
			end
		end

feature {NONE} -- Implementation

	paint_colour_only (a_p: SW_PAINTER; a_geo: SW_TEXT_GEOMETRY; a_m: SW_MARK; a_line: INTEGER;
			a_x, a_w, a_oy: REAL_64; a_draw_text: PROCEDURE [SW_PAINTER, REAL_64, REAL_64])
			-- The text again in the hue's ink, clipped to one segment.
		do
			a_p.push_clip (a_x - 1.0, a_oy + a_geo.top_of_line (a_line), a_w + 2.0, a_geo.height_of_line (a_line))
			a_p.set_color (palette.ink (a_m.hue, a_p.theme))
			a_draw_text.call (a_p, 0.0, 0.0)
			a_p.pop_clip
		end

	paint_badge (a_p: SW_PAINTER; a_badge: STRING_32; a_m: SW_MARK; a_x, a_top: REAL_64)
			-- A small chip wearing `a_badge' at the top-left of a span.
		local
			t: SW_THEME
			w, h, sz: REAL_64
		do
			if not a_badge.is_empty then
				t := a_p.theme
				sz := t.size_chip * 0.8
				a_p.font ({SW_PAINTER}.Role_mono, sz, True)
				w := a_p.advance (a_badge) + 4.0
				h := a_p.text_extent + 2.0
				a_p.set_color (palette.ink (a_m.hue, t))
				a_p.rrect_fill (a_x - 1.0, a_top - h * 0.55, w, h, 2.0)
				a_p.set_color (t.surface)
				a_p.text (a_x + 1.0, a_top - h * 0.55 + 1.0 + a_p.font_ascent, a_badge)
			end
		end

	Outline_radius: REAL_64 = 1.1
	Outer_radius: REAL_64 = 2.3
	Bold_shift: REAL_64 = 0.65
	Italic_shear: REAL_64 = 0.21

	paint_box (a_p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64; a_lines: INTEGER)
			-- `a_lines' nested rules around the rectangle, 2 px apart.
		require
			lines: a_lines >= 1
		local
			k: INTEGER
			d: REAL_64
		do
			from
				k := 1
			until
				k > a_lines
			loop
				d := 2.0 * k - 1.0
				a_p.rrect_stroke (a_x - d + 0.5, a_y - d + 0.5, a_w + 2.0 * d - 1.0, a_h + 2.0 * d - 1.0, 2.0)
				k := k + 1
			end
		end

	paint_effect_segment (a_p: SW_PAINTER; a_geo: SW_TEXT_GEOMETRY; a_m: SW_MARK; a_line: INTEGER;
			a_x, a_w, a_ox, a_oy: REAL_64; a_draw_text: PROCEDURE [SW_PAINTER, REAL_64, REAL_64])
			-- Redraw the text inside one segment with the mark's effects.
		local
			t: SW_THEME
			top, h, baseline: REAL_64
			fill, ring, inner: NATURAL_32
			sheared: BOOLEAN
			shear: CAIRO_MATRIX
			buf: MANAGED_POINTER
		do
			t := a_p.theme
			top := a_oy + a_geo.top_of_line (a_line)
			h := a_geo.height_of_line (a_line)
			baseline := top + a_geo.ascent_of_line (a_line)
			if a_m.is_colorized then
				fill := palette.ink (a_m.hue, t)
				ring := t.ink
			else
				fill := t.ink
				ring := palette.ink (a_m.hue, t)
			end
			inner := t.surface
			a_p.push_clip (a_x - Outer_radius - 1.0, top - 1.0, a_w + 2.0 * Outer_radius + 2.0, h + 2.0)
			if a_m.is_italic then
					-- x' = x - shear * (y - baseline): the top leans right
				create buf.make (48)
				buf.put_real_64 (1.0, 0)
				buf.put_real_64 (0.0, 8)
				buf.put_real_64 (- Italic_shear, 16)
				buf.put_real_64 (1.0, 24)
				buf.put_real_64 (Italic_shear * baseline, 32)
				buf.put_real_64 (0.0, 40)
				create shear.make_from_buffer (buf)
				a_p.context.save.do_nothing
				a_p.context.transform (shear).do_nothing
				sheared := True
			end
			if a_m.text_outlines >= 2 then
				a_p.set_color (ring)
				draw_ring (a_p, Outer_radius, a_m.is_bold, a_draw_text)
				a_p.set_color (inner)
				draw_ring (a_p, Outline_radius, a_m.is_bold, a_draw_text)
			elseif a_m.text_outlines = 1 then
				a_p.set_color (ring)
				draw_ring (a_p, Outline_radius, a_m.is_bold, a_draw_text)
			end
			a_p.set_color (fill)
			a_draw_text.call (a_p, 0.0, 0.0)
			if a_m.is_bold then
				a_draw_text.call (a_p, Bold_shift, 0.0)
			end
			if sheared then
				a_p.context.restore.do_nothing
			end
			a_p.pop_clip
		end

	draw_ring (a_p: SW_PAINTER; a_r: REAL_64; a_bold: BOOLEAN; a_draw_text: PROCEDURE [SW_PAINTER, REAL_64, REAL_64])
			-- The text at eight offsets on a circle of radius `a_r' (a
			-- faux outline), doubled when bold so the ring stays closed.
		local
			d: REAL_64
		do
			d := a_r * 0.7071
			a_draw_text.call (a_p, a_r, 0.0)
			a_draw_text.call (a_p, - a_r, 0.0)
			a_draw_text.call (a_p, 0.0, a_r)
			a_draw_text.call (a_p, 0.0, - a_r)
			a_draw_text.call (a_p, d, d)
			a_draw_text.call (a_p, - d, d)
			a_draw_text.call (a_p, d, - d)
			a_draw_text.call (a_p, - d, - d)
			if a_bold then
				a_draw_text.call (a_p, a_r + Bold_shift, 0.0)
				a_draw_text.call (a_p, Bold_shift, a_r)
				a_draw_text.call (a_p, Bold_shift, - a_r)
			end
		end

end
