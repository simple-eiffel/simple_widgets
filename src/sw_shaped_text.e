note
	description: "[
		ONE-LINE shaped layouts, and the cluster arithmetic that goes
		with them: what the toolkit's CHROME needs
		to paint a label through simple_shaping instead of through
		cairo's toy `show_text'.

		WHY CHROME NEEDED THIS AT ALL. SW_CHAT_THREAD has drawn shaped
		text since 0.4.0, but it shapes PARAGRAPHS at a wrap width and
		keeps its layouts in a frame cache tied to a revision counter.
		A menu item is not a paragraph: it is one short string, never
		wrapped, redrawn every frame while the menu is up, and it lives
		on an object that is built fresh on every open. So the menu was
		left on the toy path - and the toy path resolves no colour-emoji
		artwork and shapes no complex script. A menu item whose label is
		an emoji drew as an empty box in every consumer with shaped text on.

		NO CACHE OF ITS OWN (0.28.2). It kept 64 layouts, wiped only when the
		kit OBJECT changed, and shaped through `layout_for', which ignores
		the script faces - so a menu could keep a stale layout after a font
		change and draw Hebrew in another face than `SW_PAINTER.text'. It now
		shapes through `SW_SHAPING.layout_styled', whose memo follows every
		font change, and keeps only the cluster arithmetic.

		WHAT IT IS NOT. It does not wrap, it does not elide, and it
		does not measure a paragraph. SW_CHAT_THREAD keeps its own
		per-RUN twins of `char_left_x' and `char_right_x' because it
		asks them run-by-run while washing a selection across a line;
		this class asks the same question of a whole layout by source
		index, which is the question a mnemonic underline asks.

		NOTHING HERE RAISES. `SW_SHAPING.layout_for' is total and every
		query answers for the empty string and for an index no run
		covers (a zero-width span at the origin).
	]"
	author: "Larry Rix"

class
	SW_SHAPED_TEXT

inherit
	SW_CLUSTER_MATH

create
	make

feature {NONE} -- Initialization

	make
			-- Nothing to set up: the layouts come from the kit's memo.
		do
		end

feature -- Access

	layout_of (a_kit: SW_SHAPING; a_text: READABLE_STRING_GENERAL; a_pixel_size: INTEGER): SHAPED_LAYOUT
			-- `a_text' shaped to ONE unbounded line at `a_pixel_size', in the
			-- UI face at regular weight.
		require
			size_positive: a_pixel_size > 0
		do
			Result := layout_styled_of (a_kit, a_text, a_pixel_size, {SW_PAINTER}.Role_ui, False)
		ensure
			at_that_size: Result.pixel_size = a_pixel_size
			unbounded: Result.width_pixels = {SHAPING_CONSTANTS}.No_wrap
		end

	layout_styled_of (a_kit: SW_SHAPING; a_text: READABLE_STRING_GENERAL; a_pixel_size, a_role: INTEGER;
			a_bold: BOOLEAN): SHAPED_LAYOUT
			-- `a_text' shaped to ONE unbounded line at `a_pixel_size' in the
			-- face of `a_role' - through `SW_SHAPING.layout_styled', the path
			-- `SW_PAINTER.text' takes, so a menu or a label gets the same
			-- faces (script faces included) and the same memo, invalidated
			-- the same way.
		require
			size_positive: a_pixel_size > 0
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
		do
			Result := a_kit.layout_styled (a_text, {SHAPING_CONSTANTS}.No_wrap, a_pixel_size, a_role, a_bold)
		ensure
			at_that_size: Result.pixel_size = a_pixel_size
			unbounded: Result.width_pixels = {SHAPING_CONSTANTS}.No_wrap
		end

	width_of (a_kit: SW_SHAPING; a_text: READABLE_STRING_GENERAL; a_pixel_size: INTEGER): REAL_64
			-- How wide `a_text' actually PAINTS at `a_pixel_size' - the
			-- shaped measure, which for an emoji-only label is the
			-- picture's box and for cairo's toy path was nothing at all.
		require
			size_positive: a_pixel_size > 0
		do
			Result := layout_of (a_kit, a_text, a_pixel_size).total_width
		ensure
			non_negative: Result >= 0.0
		end

feature -- Geometry

	top_for_baseline (a_layout: SHAPED_LAYOUT; a_baseline: REAL_64): REAL_64
			-- The y `SW_PAINTER.draw_shaped_layout' wants for a layout
			-- whose first baseline is to land on `a_baseline'.
			--
			-- `draw_shaped_layout' takes a TOP-LEFT, `text' takes a
			-- BASELINE. Every chrome widget in this toolkit was written
			-- against the baseline, so this converts rather than asking
			-- each of them to be rewritten around a different origin -
			-- which is also what keeps the toy path and the shaped path
			-- putting the type in the same place.
		do
			if a_layout.lines.is_empty then
				Result := a_baseline
			else
				Result := a_baseline - a_layout.lines.first.ascent
			end
		end

	baseline_for_top (a_layout: SHAPED_LAYOUT; a_top: REAL_64): REAL_64
			-- Where the first baseline lands when the layout's TOP-LEFT
			-- is put at `a_top' - the inverse of `top_for_baseline', for
			-- a caller that places the box and then has to know where
			-- the type sits inside it (a mnemonic underline does).
		do
			if a_layout.lines.is_empty then
				Result := a_top
			else
				Result := a_top + a_layout.lines.first.ascent
			end
		end

	character_span (a_layout: SHAPED_LAYOUT; a_index: INTEGER): TUPLE [left, width: REAL_64]
			-- Where the character at SOURCE index `a_index' actually
			-- paints on `a_layout''s first line: its left edge measured
			-- from the layout's own left edge, and how wide it draws.
			--
			-- THIS IS THE MNEMONIC UNDERLINE. The toy path computed it
			-- as `advance (label.substring (1, ul - 1))' - the width of
			-- the text BEFORE the letter - which is a statement that
			-- source order and paint order are the same thing. In a
			-- Hebrew title they are opposite: the first character paints
			-- RIGHTMOST, and a prefix advance would put the underline at
			-- the wrong end of the word. Cluster positions do not
			-- guess: a run says where it sits, `cluster_map' says which
			-- glyph renders the character, and `x_positions' says where
			-- that glyph is.
			--
			-- Zero width when no run covers `a_index' (there is no such
			-- character), which draws nothing rather than raising.
		require
			positive: a_index >= 1
		local
			ln: SHAPED_LINE
			rn: SHAPED_RUN
			r, c: INTEGER
			run_left, cl, cr: REAL_64
			found: BOOLEAN
		do
			Result := [0.0, 0.0]
			if not a_layout.lines.is_empty then
				ln := a_layout.lines.first
				from
					r := 1
				until
					r > ln.runs.count or found
				loop
					rn := ln.runs.i_th (r)
					if a_index >= rn.source_start
						and then a_index <= rn.source_start + rn.source_count - 1
					then
						c := a_index - rn.source_start + 1
						cl := char_left_x (rn, c)
						cr := char_right_x (rn, c)
						Result := [run_left + cl.min (cr), (cr - cl).abs]
						found := True
					end
					run_left := run_left + rn.advance_width
					r := r + 1
				end
			end
		ensure
			non_negative: Result.width >= 0.0
		end

end
