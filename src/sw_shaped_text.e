note
	description: "[
		A small cache of ONE-LINE shaped layouts, and the cluster
		arithmetic that goes with them: what the toolkit's CHROME needs
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

		THE CACHE IS BY VALUE. The key is the text and the PIXEL SIZE,
		and the pixel size is where the theme's `text_scale' already
		is - `(size * text_scale).rounded' is the number the glyphs are
		shaped at, so a scale change is a different key by construction
		and there is nothing extra to remember. A kit swap (a theme
		swap rebuilds the faces) empties the cache, and `Cap' bounds it
		so a long-lived menu bar cannot grow one entry per frame under
		an animated scale.

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

create
	make

feature {NONE} -- Initialization

	make
			-- An empty cache.
		do
			create keys.make (Cap)
			create layouts.make (Cap)
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
			-- How many layouts are remembered.
		do
			Result := layouts.count
		ensure
			non_negative: Result >= 0
		end

	layout_of (a_kit: SW_SHAPING; a_text: READABLE_STRING_GENERAL; a_pixel_size: INTEGER): SHAPED_LAYOUT
			-- `a_text' shaped to ONE unbounded line at `a_pixel_size' -
			-- from the cache when this pair has been asked for before,
			-- freshly shaped and remembered when it has not.
		require
			size_positive: a_pixel_size > 0
		local
			k: STRING_32
			i: INTEGER
		do
			if a_kit /= last_kit then
					-- A different kit is a different font policy, so every
					-- layout in hand was shaped under an answer that no
					-- longer applies.
				wipe_out
				last_kit := a_kit
			end
			k := key (a_text, a_pixel_size)
			i := index_of (k)
			if i > 0 then
				Result := layouts.i_th (i)
			else
				if count >= Cap then
					wipe_out
				end
				Result := a_kit.layout_for (a_text, {SHAPING_CONSTANTS}.No_wrap, a_pixel_size)
				keys.extend (k)
				layouts.extend (Result)
			end
		ensure
			at_that_size: Result.pixel_size = a_pixel_size
			unbounded: Result.width_pixels = {SHAPING_CONSTANTS}.No_wrap
			remembered: is_cached (a_text, a_pixel_size)
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

	is_cached (a_text: READABLE_STRING_GENERAL; a_pixel_size: INTEGER): BOOLEAN
			-- Is this pair remembered right now?
		require
			size_positive: a_pixel_size > 0
		do
			Result := index_of (key (a_text, a_pixel_size)) > 0
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

feature -- Removal

	wipe_out
			-- Forget every layout.
		do
			keys.wipe_out
			layouts.wipe_out
		ensure
			empty: count = 0
		end

feature {NONE} -- Implementation

	keys: ARRAYED_LIST [STRING_32]
			-- One key per cached layout, parallel to `layouts'.

	layouts: ARRAYED_LIST [SHAPED_LAYOUT]
			-- The cached layouts, parallel to `keys'.

	last_kit: detachable SW_SHAPING
			-- The kit every cached layout was shaped by.

	Cap: INTEGER = 64
			-- How many layouts one cache holds before it starts over.
			-- A menu bar of a dozen pads at two scales is nowhere near
			-- it; an animated scale would be, and this is what stops
			-- that becoming a leak.

	key (a_text: READABLE_STRING_GENERAL; a_pixel_size: INTEGER): STRING_32
			-- The cache key for `a_text' at `a_pixel_size'. The size
			-- goes FIRST and is followed by a character no size can
			-- produce, so no text can ever forge another pair's key.
		require
			size_positive: a_pixel_size > 0
		do
			create Result.make (a_text.count + 8)
			Result.append_string_general (a_pixel_size.out)
			Result.append_character ('|')
			Result.append_string_general (a_text.to_string_32)
		ensure
			not_empty: not Result.is_empty
		end

	index_of (a_key: READABLE_STRING_32): INTEGER
			-- 1-based position of `a_key' in `keys'; 0 when absent.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > keys.count or Result /= 0
			loop
				if keys.i_th (i).same_string (a_key) then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= keys.count
		end

	char_left_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- The left pixel edge of run-relative character `a_char',
			-- measured from the run's own left edge. An IMAGE_RUN is one
			-- indivisible box, so its characters all start at 0.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		do
			if attached {GLYPH_RUN} a_run as g then
				Result := cluster_x (g, a_char)
			end
		end

	char_right_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- The right pixel edge of run-relative character `a_char':
			-- the NEXT cluster's left edge in a left-to-right run, the
			-- PREVIOUS one's in a right-to-left run, and the run's own
			-- right edge at whichever end that is. An IMAGE_RUN answers
			-- its whole width, which is what an emoji underlines as.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		do
			Result := a_run.advance_width
			if attached {GLYPH_RUN} a_run as g then
				if g.is_rtl then
					if a_char > 1 then
						Result := cluster_x (g, a_char - 1)
					end
				elseif a_char < g.source_count then
					Result := cluster_x (g, a_char + 1)
				end
			end
		end

	cluster_x (a_run: GLYPH_RUN; a_char: INTEGER): REAL_64
			-- The x of the cluster that renders run-relative character
			-- `a_char' (1 .. `source_count').
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		local
			g: INTEGER
		do
			g := a_run.cluster_map [a_run.cluster_map.lower + a_char - 1]
			if g >= 1 and then g <= a_run.x_positions.count then
				Result := a_run.x_positions [a_run.x_positions.lower + g - 1]
			end
		end

invariant
	keys_attached: keys /= Void
	layouts_attached: layouts /= Void
	parallel: keys.count = layouts.count
	bounded: count <= Cap

end
