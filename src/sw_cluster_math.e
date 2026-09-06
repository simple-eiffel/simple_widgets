note
	description: "[
		The cluster arithmetic every shaped-text widget needs and none
		should carry privately: where a SOURCE character paints inside
		a run, from the cluster map and glyph positions the run
		publishes. Written once here; SW_SHAPED_TEXT, SW_CHAT_THREAD and
		SW_TEXT_BOX inherit it.

		WHY IT IS ITS OWN CLASS. Before 0.8.0 the chat thread and the
		chrome cache each kept a copy of these three queries, identical
		to the character, and the text box was about to become a third.
		A caret law that lives in three places is a caret law that will
		drift in one of them; SHAPED_LINE reserves `character_index_at_x'
		for a future simple_shaping cycle (FR-013) and until that lands
		this is the one boundary walk the toolkit owns.

		THE LAW. A run's `cluster_map' names, for each source character,
		the FIRST glyph of the cluster that renders it; `x_positions'
		says where that glyph sits, run-relative. So a character's LEFT
		edge is its own cluster's x. Its RIGHT edge is the NEXT cluster's
		x in a left-to-right run and the PREVIOUS cluster's x in a
		right-to-left run - and the run's own advance at whichever end
		has no neighbour. An IMAGE_RUN (an emoji) is one indivisible
		picture: every character in it spans the whole box.

		Nothing here raises on a degraded run: a cluster entry that
		names no glyph answers 0.0, which paints nothing rather than
		painting wrong.
	]"
	author: "Larry Rix"

class
	SW_CLUSTER_MATH

feature -- Cluster arithmetic

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
		ensure
			non_negative: Result >= 0.0
		end

	char_right_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- The right pixel edge of run-relative character `a_char':
			-- the NEXT cluster's left edge in a left-to-right run, the
			-- PREVIOUS one's in a right-to-left run, and the run's own
			-- right edge at whichever end that is. An IMAGE_RUN answers
			-- its whole width.
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
		ensure
			non_negative: Result >= 0.0
		end

	cluster_x (a_run: GLYPH_RUN; a_char: INTEGER): REAL_64
			-- The x of the cluster that renders run-relative character
			-- `a_char' (1 .. `source_count'); 0.0 when the map names no
			-- glyph, which a degraded run may.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		local
			g: INTEGER
		do
			g := a_run.cluster_map [a_run.cluster_map.lower + a_char - 1]
			if g >= 1 and then g <= a_run.x_positions.count then
				Result := a_run.x_positions [a_run.x_positions.lower + g - 1]
			end
		ensure
			non_negative: Result >= 0.0
		end

	caret_after_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- Where the caret stands AFTER run-relative character
			-- `a_char' in reading order: its right edge in a
			-- left-to-right run, its LEFT edge in a right-to-left one -
			-- the whole of what "RTL caret placement" means.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		do
			if a_run.is_rtl then
				Result := char_left_x (a_run, a_char)
			else
				Result := char_right_x (a_run, a_char)
			end
		ensure
			non_negative: Result >= 0.0
		end

	caret_before_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- Where the caret stands BEFORE run-relative character
			-- `a_char' in reading order: the mirror of `caret_after_x'.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		do
			if a_run.is_rtl then
				Result := char_right_x (a_run, a_char)
			else
				Result := char_left_x (a_run, a_char)
			end
		ensure
			non_negative: Result >= 0.0
		end

end
