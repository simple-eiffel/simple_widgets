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
		kit breaks it, not at blanks. A MONO label builds no layout of
		its own: mono marks machine-produced values - seeds, timings,
		counts - and the kit's ui policy would take the monospace away
		from them. It paints and measures through `SW_PAINTER.text' and
		`advance', which since GW-04 (0.9.x) shape with the theme's MONO
		face whenever the painter carries a kit, so the monospace holds
		whenever that face is present (ship it with
		`SIMPLE_SHAPING.load_font_file'). `shaped_layout' says whether a
		label lays itself out: Void means it goes through the painter.
	]"

class
	SW_LABEL

inherit
	SW_WIDGET
		redefine
			preferred_width,
			accessible_role, default_accessible_name, context_menu
		end

	SW_COPYING

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
			text_alignment := {SHAPING_CONSTANTS}.Align_left
		ensure
			text_kept: text.same_string_general (a_text)
			flush_left: text_alignment = {SHAPING_CONSTANTS}.Align_left
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

	wrap_chars: INTEGER
			-- Wrap at about this many characters (0: at the laid-out width only). Its natural
			-- width is at most this many average characters, and lines break there even when
			-- the label is laid out wider - simple_gui's GUI_LABEL.set_wrap_width.
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

	takes_shaped_path_of (a_p: SW_PAINTER; a_line: READABLE_STRING_32): BOOLEAN
			-- `takes_shaped_path' for the one line `a_line' of the text.
		do
			Result := a_p.has_shaping and is_shaped_role and not a_line.is_empty
		ensure
			definition: Result = (a_p.has_shaping and is_shaped_role and not a_line.is_empty)
		end

	shaped_layout (a_p: SW_PAINTER; a_width: REAL_64): detachable SHAPED_LAYOUT
			-- `text' through `a_p''s kit: one unbounded line, or broken
			-- to `a_width' when this label wraps (`a_width' under one
			-- pixel means unbounded). Void when the label paints on the
			-- toy path - no kit, a mono role, or nothing to shape. A text
			-- with line breaks is laid out line by line (`shaped_layout_of').
		do
			Result := shaped_layout_of (a_p, text, a_width)
		ensure
			shaped_exactly_when: attached Result = takes_shaped_path (a_p)
			at_this_size: attached Result as al_layout implies al_layout.pixel_size = pixel_size (a_p)
		end

	shaped_layout_of (a_p: SW_PAINTER; a_line: READABLE_STRING_32; a_width: REAL_64): detachable SHAPED_LAYOUT
			-- The one line `a_line' through `a_p''s kit, wrapped within
			-- `a_width' when this label wraps; Void on the toy path.
		do
			if takes_shaped_path_of (a_p, a_line) and then attached a_p.shaping as al_kit then
				if is_wrapping then
					Result := al_kit.layout_styled (a_line, wrap_width (a_p, a_width).floor.max (0), pixel_size (a_p), role, is_bold)
				else
					Result := shaped.layout_styled_of (al_kit, a_line, pixel_size (a_p), role, is_bold)
				end
			end
		ensure
			shaped_exactly_when: attached Result = takes_shaped_path_of (a_p, a_line)
			at_this_size: attached Result as al_layout implies al_layout.pixel_size = pixel_size (a_p)
		end

feature -- Line breaks

	has_line_breaks: BOOLEAN
			-- Does `text' carry a line break (LF, CR LF or a lone CR)?
		do
			Result := text.has ('%N') or text.has ('%R')
		ensure
			definition: Result = (text.has ('%N') or text.has ('%R'))
		end

	text_lines: ARRAYED_LIST [STRING_32]
			-- `text' cut at each line break: LF, CR LF (ONE break) or a
			-- lone CR. A text without breaks is one line; a trailing break
			-- opens a final empty line, as GtkLabel shows it.
		do
			Result := (create {SW_LINE_BREAKS}).lines_of (text)
		ensure
			at_least_one: not Result.is_empty
			one_line_without_breaks: not has_line_breaks implies Result.count = 1
		end

	line_break_count: INTEGER
			-- How many breaks `text' holds: one fewer than `text_lines'.
		do
			Result := text_lines.count - 1
		ensure
			non_negative: Result >= 0
		end

feature -- Alignment (GW-02)

	text_alignment: INTEGER
			-- How a shaped label's lines sit in its width: a
			-- SHAPING_CONSTANTS Align_* code. Align_left by default;
			-- Align_start sets a Hebrew label flush right.

	effective_text_alignment: INTEGER
			-- `text_alignment' as drawn: left and right swap when this widget `mirrors_layout'
			-- (W4c; GTK mirrors a label's xalign the same way). Start and center are unchanged.
		do
			Result := text_alignment
			if mirrors_layout then
				if Result = {SHAPING_CONSTANTS}.Align_left then
					Result := {SHAPING_CONSTANTS}.Align_right
				elseif Result = {SHAPING_CONSTANTS}.Align_right then
					Result := {SHAPING_CONSTANTS}.Align_left
				end
			end
		end

	set_text_alignment (a_alignment: INTEGER)
			-- Place this label's lines by `a_alignment'.
		require
			alignment_valid: a_alignment >= {SHAPING_CONSTANTS}.Align_start
				and a_alignment <= {SHAPING_CONSTANTS}.Align_center
		do
			text_alignment := a_alignment
		ensure
			set: text_alignment = a_alignment
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

	set_wrap_chars (a_chars: INTEGER)
			-- Wrap at about `a_chars' characters; 0 goes back to one line.
		require
			non_negative: a_chars >= 0
		do
			wrap_chars := a_chars
			is_wrapping := a_chars > 0
		ensure
			set: wrap_chars = a_chars
			wraps_when_set: is_wrapping = (a_chars > 0)
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

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- Copy, while there is text; otherwise nothing, so the
			-- right-click goes on to the parent.
		do
			if not text.is_empty then
				create Result.make
				Result.add_item ("Copy", "", True, agent copy_text (text))
			end
		ensure then
			only_with_text: attached Result = not text.is_empty
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- As wide as the text PAINTS: the shaped measure on the
			-- shaped path, cairo's advance on the toy path; the WIDEST line
			-- when the text has line breaks.
		local
			l_w: REAL_64
		do
			if has_line_breaks then
				across
					text_lines as ln
				loop
					l_w := line_width_of (a_p, ln)
					if l_w > Result then
						Result := l_w
					end
				end
			else
				Result := line_width_of (a_p, text)
			end
			if wrap_chars > 0 then
				Result := Result.min (wrap_chars * average_char_width (a_p))
			end
		end

	line_width_of (a_p: SW_PAINTER; a_line: READABLE_STRING_32): REAL_64
			-- The unwrapped width of the one line `a_line'.
		do
			if attached shaped_layout_of (a_p, a_line, 0.0) as al_layout then
				Result := al_layout.total_width
			else
				a_p.font (role, size, is_bold)
				Result := a_p.advance (a_line)
			end
		end

	average_char_width (a_p: SW_PAINTER): REAL_64
			-- The advance of an average lowercase letter in this label's font.
		do
			a_p.font (role, size, is_bold)
			Result := a_p.advance ("abcdefghijklmnopqrstuvwxyz") / 26.0
		ensure
			non_negative: Result >= 0.0
		end

	wrap_width (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The width lines break at: `a_width', or less when `wrap_chars' caps it
			-- (`a_width' under one pixel means unbounded, and stays so).
		do
			Result := a_width
			if wrap_chars > 0 and a_width >= 1.0 then
				Result := a_width.min (wrap_chars * average_char_width (a_p))
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
			Result := line_step_of (a_p, text)
		ensure
			clears_the_glyphs: not takes_shaped_path (a_p) implies Result >= a_p.text_extent
			leaded: Result >= a_p.theme.padding
		end

	line_step_of (a_p: SW_PAINTER; a_line: READABLE_STRING_32): REAL_64
			-- `line_step' for the one line `a_line' (an empty line takes
			-- the font's own step, so a blank line is as tall as the rest).
		do
			if attached shaped_layout_of (a_p, a_line, 0.0) as al_layout then
				Result := al_layout.total_height + a_p.theme.padding
			else
				a_p.font (role, size, is_bold)
				Result := a_p.text_extent + a_p.theme.padding
			end
		ensure
			leaded: Result >= a_p.theme.padding
		end

	baseline_offset (a_p: SW_PAINTER): REAL_64
			-- Where the first baseline sits below the label's top edge -
			-- the measured ascent plus half the leading, so a line of
			-- text is centered in the step it occupies.
		do
			a_p.font (role, size, is_bold)
			Result := a_p.font_ascent + a_p.theme.padding / 2.0
		ensure
			non_negative: Result >= 0.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- A wrapping label on the shaped path is as tall as the kit
			-- breaks it; on the toy path, as many blank-broken lines as
			-- `a_width' demands. A text with line breaks stacks its lines:
			-- one block per line, each wrapped within `a_width'.
		do
			if has_line_breaks then
				across
					text_lines as ln
				loop
					Result := Result + block_height_of (a_p, ln, a_width)
				end
			else
				Result := block_height_of (a_p, text, a_width)
			end
		end

	block_height_of (a_p: SW_PAINTER; a_line: READABLE_STRING_32; a_width: REAL_64): REAL_64
			-- The height the one line `a_line' takes: its step, times the
			-- rows it wraps into when this label wraps.
		do
			if is_wrapping then
				if attached shaped_layout_of (a_p, a_line, a_width) as al_layout then
					Result := al_layout.total_height + a_p.theme.padding
				else
					Result := wrapped_lines_of (a_p, a_line, a_width).count * line_step_of (a_p, a_line)
				end
			else
				Result := line_step_of (a_p, a_line)
			end
		ensure
			positive: Result > 0.0
		end

	wrapped_lines (a_p: SW_PAINTER; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- `text' broken at word boundaries to fit `a_width'.
		do
			Result := wrapped_lines_of (a_p, text, a_width)
		ensure
			at_least_one: not Result.is_empty
		end

	wrapped_lines_of (a_p: SW_PAINTER; a_line: READABLE_STRING_32; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- `a_line' broken at word boundaries to fit `a_width'.
		local
			words: LIST [STRING_32]
			line: STRING_32
			cx, ww: REAL_64
		do
			create Result.make (4)
			a_p.font (role, size, is_bold)
			words := a_line.to_string_32.split (' ')
			create line.make (60)
			across
				words as w
			loop
				ww := a_p.advance (w)
				if line.is_empty then
					line := w.twin
					cx := ww
				elseif cx + space_advance (a_p) + ww > wrap_width (a_p, a_width) then
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
			l_top: REAL_64
		do
			if custom_color /= 0 then
				a_p.set_color (custom_color)
			elseif is_muted then
				a_p.set_color (a_p.theme.ink_muted)
			else
				a_p.set_color (a_p.theme.ink)
			end
			if has_line_breaks then
				l_top := y
				across
					text_lines as ln
				loop
					l_top := l_top + draw_line (a_p, ln, l_top)
				end
			else
				l_top := draw_line (a_p, text, y)
			end
		end

	draw_line (a_p: SW_PAINTER; a_line: READABLE_STRING_32; a_top: REAL_64): REAL_64
			-- Draw the one line `a_line' (wrapped within the width when
			-- this label wraps) with its block top edge at `a_top', in
			-- the painter current color, each row placed by the
			-- alignment; the height the block took.
		local
			step, base, l_dx: REAL_64
			l_align, i: INTEGER
			l_rows: ARRAYED_LIST [STRING_32]
		do
			l_align := effective_text_alignment
			if attached shaped_layout_of (a_p, a_line, width) as al_layout then
					-- The layout TOP-LEFT goes where the toy path
					-- glyph box starts: half the leading below the top
					-- edge, so both paths center a line in its step.
				if l_align /= {SHAPING_CONSTANTS}.Align_left then
						-- GW-02: placed in the label own width.
					a_p.draw_shaped_layout_aligned (al_layout, x, a_top + a_p.theme.padding / 2.0,
						width.max (0.0), l_align)
				else
					a_p.draw_shaped_layout (al_layout, x, a_top + a_p.theme.padding / 2.0)
				end
			else
				step := line_step_of (a_p, a_line)
				base := baseline_offset (a_p)
				a_p.font (role, size, is_bold)
				if is_wrapping then
					l_rows := wrapped_lines_of (a_p, a_line, width)
				else
					create l_rows.make (1)
					l_rows.extend (a_line.to_string_32)
				end
				from
					i := 1
				until
					i > l_rows.count
				loop
					l_dx := 0.0
					if l_align = {SHAPING_CONSTANTS}.Align_center or l_align = {SHAPING_CONSTANTS}.Align_right
						or l_align = {SHAPING_CONSTANTS}.Align_end
					then
						l_dx := (width - a_p.advance (l_rows.i_th (i))).max (0.0)
						if l_align = {SHAPING_CONSTANTS}.Align_center then
							l_dx := l_dx / 2.0
						end
					end
					a_p.text (x + l_dx, a_top + (i - 1) * step + base, l_rows.i_th (i))
					i := i + 1
				end
			end
			Result := block_height_of (a_p, a_line, width)
		ensure
			positive: Result > 0.0
		end

feature {NONE} -- Shaped text

	shaped: SW_SHAPED_TEXT
			-- The one-line layout cache for the unwrapped label: shaped
			-- once per text and size, then only looked up.


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_text
		end

	default_accessible_name: STRING_32
		do
			Result := text.twin
		end

invariant
	text_attached: text /= Void
	shaped_attached: shaped /= Void

end
