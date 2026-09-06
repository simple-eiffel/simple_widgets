note
	description: "[
		A single line of text in one of the three type roles. The role
		is semantic: ui for the tool's own voice, body for the author's
		prose, mono for machine-produced values.

		THE SHAPED PATH (0.8.1). When the painter carries a shaping kit,
		a ui or body label is laid out and painted through it - the way
		the menu bar's titles have been since 0.7.2 - so a label in
		Hebrew reads right-to-left, Greek keeps its accents and an emoji
		is a picture. The measure is the shaped measure: `preferred_width'
		is the layout's own width, and a wrapping label breaks where the
		kit breaks it, not at blanks. A MONO label stays on cairo's toy
		path whatever the painter carries: mono marks machine-produced
		values - seeds, timings, counts - which are ASCII by definition,
		and the kit's face policy (the theme's ui face for Latin) would
		take the monospace away from them. `shaped_layout' says which
		path a label is on for a given painter: Void is the toy path.
	]"

class
	SW_LABEL

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make, make_ui, make_mono, make_body

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL; a_role: INTEGER; a_size: REAL_64; a_bold: BOOLEAN)
		require
			size_positive: a_size > 0.0
		do
			create text.make_from_string_general (a_text)
			role := a_role
			size := a_size
			is_bold := a_bold
			create shaped.make
		ensure
			text_kept: text.same_string_general (a_text)
		end

	make_ui (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_ui, 13.0, False)
		end

	make_mono (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_mono, 13.0, False)
		end

	make_body (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_body, 16.0, False)
			is_wrapping := True
		ensure
			wraps: is_wrapping
		end

feature -- Access

	text: STRING_32
	role: INTEGER
	size: REAL_64
	is_bold: BOOLEAN
	is_muted: BOOLEAN

	is_wrapping: BOOLEAN
			-- Break into as many lines as the width demands? Body
			-- labels wrap by default; chrome labels stay single-line.
	custom_color: NATURAL_32
			-- 0 means: theme ink (or muted ink).

feature -- Shaped text

	is_shaped_role: BOOLEAN
			-- Does this label's role take the shaped path when a kit is
			-- there? ui and body do; mono keeps cairo's toy path (see
			-- the class note).
		do
			Result := role /= {SW_PAINTER}.Role_mono
		ensure
			definition: Result = (role /= {SW_PAINTER}.Role_mono)
		end

	takes_shaped_path (a_p: SW_PAINTER): BOOLEAN
			-- Will this label measure and paint through `a_p''s kit?
			-- Only with a kit, only for a shaped role, and only when
			-- there is text to shape.
		do
			Result := a_p.has_shaping and is_shaped_role and not text.is_empty
		ensure
			definition: Result = (a_p.has_shaping and is_shaped_role and not text.is_empty)
		end

	pixel_size (a_p: SW_PAINTER): INTEGER
			-- The size this label is SHAPED at: `size' through the
			-- theme's `text_scale', the same number `SW_PAINTER.font'
			-- hands cairo on the toy path.
		do
			Result := (size * a_p.theme.text_scale).rounded.max (1)
		ensure
			positive: Result >= 1
		end

	shaped_layout (a_p: SW_PAINTER; a_width: REAL_64): detachable SHAPED_LAYOUT
			-- `text' through `a_p''s kit: one unbounded line, or broken
			-- to `a_width' when this label wraps (`a_width' under one
			-- pixel means unbounded). Void when the label paints on the
			-- toy path - no kit, a mono role, or nothing to shape.
		do
			if takes_shaped_path (a_p) and then attached a_p.shaping as al_kit then
				if is_wrapping then
					Result := al_kit.layout_for (text, a_width.floor.max (0), pixel_size (a_p))
				else
					Result := shaped.layout_of (al_kit, text, pixel_size (a_p))
				end
			end
		ensure
			shaped_exactly_when: attached Result = takes_shaped_path (a_p)
			at_this_size: attached Result as al_layout implies al_layout.pixel_size = pixel_size (a_p)
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
		do
			create text.make_from_string_general (a_text)
		ensure
			kept: text.same_string_general (a_text)
		end

	set_muted (a_muted: BOOLEAN)
		do
			is_muted := a_muted
		end

	set_color (a_rgb: NATURAL_32)
		do
			custom_color := a_rgb
		end

	with_wrap: like Current
			-- Fluent: wrapping variant of Current.
		do
			is_wrapping := True
			Result := Current
		ensure
			wraps: is_wrapping
			chained: Result = Current
		end

	as_muted: like Current
			-- Fluent: muted variant of Current.
		do
			is_muted := True
			Result := Current
		end

	colored (a_rgb: NATURAL_32): like Current
			-- Fluent: Current drawn in `a_rgb'.
		do
			custom_color := a_rgb
			Result := Current
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- As wide as the text PAINTS: the shaped measure on the
			-- shaped path, cairo's advance on the toy path.
		do
			if attached shaped_layout (a_p, 0.0) as al_layout then
				Result := al_layout.total_width
			else
				a_p.font (role, size, is_bold)
				Result := a_p.advance (text)
			end
		end

	line_step (a_p: SW_PAINTER): REAL_64
			-- Distance from one wrapped line to the next.
			--
			-- MEASURED, at the size actually painted. It used to be
			-- `size + 9.0' - the NOMINAL size plus a constant - while the
			-- glyphs were painted at `size * text_scale'. The two agreed
			-- only at 1x; at simple_chat's 2x the step stayed 22 px under
			-- 26 px text and the lines collided. Ascent + descent comes
			-- from cairo's font extents for the selected font, so it
			-- already carries the scale, and the theme's `padding' is the
			-- leading, which scales too.
			--
			-- On the shaped path the step is the shaped line's own
			-- height plus the same leading.
		do
			if attached shaped_layout (a_p, 0.0) as al_layout then
				Result := al_layout.total_height + a_p.theme.padding
			else
				a_p.font (role, size, is_bold)
				Result := a_p.text_extent + a_p.theme.padding
			end
		ensure
			clears_the_glyphs: not takes_shaped_path (a_p) implies Result >= a_p.text_extent
			leaded: Result >= a_p.theme.padding
		end

	baseline_offset (a_p: SW_PAINTER): REAL_64
			-- Where the first baseline sits below the label's top edge -
			-- the measured ascent plus half the leading, so a line of
			-- text is centred in the step it occupies.
		do
			a_p.font (role, size, is_bold)
			Result := a_p.font_ascent + a_p.theme.padding / 2.0
		ensure
			non_negative: Result >= 0.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- A wrapping label on the shaped path is as tall as the kit
			-- breaks it; on the toy path, as many blank-broken lines as
			-- `a_width' demands.
		do
			if is_wrapping then
				if attached shaped_layout (a_p, a_width) as al_layout then
					Result := al_layout.total_height + a_p.theme.padding
				else
					Result := wrapped_lines (a_p, a_width).count * line_step (a_p)
				end
			else
				Result := line_step (a_p)
			end
		end

	wrapped_lines (a_p: SW_PAINTER; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- `text' broken at word boundaries to fit `a_width'.
		local
			words: LIST [STRING_32]
			line: STRING_32
			cx, ww: REAL_64
		do
			create Result.make (4)
			a_p.font (role, size, is_bold)
			words := text.split (' ')
			create line.make (60)
			across
				words as w
			loop
				ww := a_p.advance (w)
				if line.is_empty then
					line := w.twin
					cx := ww
				elseif cx + space_advance (a_p) + ww > a_width then
					Result.extend (line)
					line := w.twin
					cx := ww
				else
					line.append_character (' ')
					line.append (w)
					cx := cx + space_advance (a_p) + ww
				end
			end
			Result.extend (line)
		ensure
			at_least_one: not Result.is_empty
		end

	space_advance (a_p: SW_PAINTER): REAL_64
			-- Width of one blank in the CURRENT font. Measured, so
			-- wrapping holds at any `text_scale' (it was a flat 4.5,
			-- which under-measured every line at 2x).
		do
			Result := a_p.advance (" ")
		ensure
			non_negative: Result >= 0.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			step, base: REAL_64
		do
			if custom_color /= 0 then
				a_p.set_color (custom_color)
			elseif is_muted then
				a_p.set_color (a_p.theme.ink_muted)
			else
				a_p.set_color (a_p.theme.ink)
			end
			if attached shaped_layout (a_p, width) as al_layout then
					-- The layout's TOP-LEFT goes where the toy path's
					-- glyph box starts: half the leading below the top
					-- edge, so both paths centre a line in its step.
				a_p.draw_shaped_layout (al_layout, x, y + a_p.theme.padding / 2.0)
			else
				step := line_step (a_p)
				base := baseline_offset (a_p)
				a_p.font (role, size, is_bold)
				draw_toy (a_p, step, base)
			end
		end

	draw_toy (a_p: SW_PAINTER; a_step, a_base: REAL_64)
			-- The toy path: cairo's `show_text', one line or blank-broken
			-- lines `a_step' apart, the first baseline at `a_base'.
		local
			lines: ARRAYED_LIST [STRING_32]
			i: INTEGER
			step, base: REAL_64
		do
			step := a_step
			base := a_base
			if is_wrapping then
				lines := wrapped_lines (a_p, width)
				from
					i := 1
				until
					i > lines.count
				loop
					a_p.text (x, y + (i - 1) * step + base, lines.i_th (i))
					i := i + 1
				end
			else
				a_p.text (x, y + base, text)
			end
		end

feature {NONE} -- Shaped text

	shaped: SW_SHAPED_TEXT
			-- The one-line layout cache for the unwrapped label: shaped
			-- once per text and size, then only looked up.

invariant
	text_attached: text /= Void
	shaped_attached: shaped /= Void

end
