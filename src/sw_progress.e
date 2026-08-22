note
	description: "[
		A determinate progress bar: a track in the outline token, a
		fill in the accent, an optional percentage caption in mono.
		The fraction is contract-bounded to [0, 1].
	]"

class
	SW_PROGRESS

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make (a_fraction: REAL_64)
		require
			in_range: a_fraction >= 0.0 and a_fraction <= 1.0
		do
			fraction := a_fraction
		ensure
			kept: fraction = a_fraction
		end

feature -- Access

	fraction: REAL_64

	shows_caption: BOOLEAN

feature -- Element change

	set_fraction (a_fraction: REAL_64)
		require
			in_range: a_fraction >= 0.0 and a_fraction <= 1.0
		do
			fraction := a_fraction
		ensure
			set: fraction = a_fraction
		end

	set_shows_caption (a_shows: BOOLEAN)
		do
			shows_caption := a_shows
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 18.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cap: STRING_32
			bar_w: REAL_64
		do
			t := a_p.theme
			bar_w := width
			if shows_caption then
				bar_w := width - 52.0
			end
			a_p.set_color (t.outline)
			a_p.rrect_fill (x, y + height / 2.0 - 4.0, bar_w, 8.0, 3.0)
			if fraction > 0.0 then
				a_p.set_color (t.accent)
				a_p.rrect_fill (x, y + height / 2.0 - 4.0, (bar_w * fraction).max (8.0), 8.0, 3.0)
			end
			if shows_caption then
				create cap.make (5)
				cap.append_string_general (((fraction * 100.0).rounded).out)
				cap.append_character ('%%')
				a_p.font ({SW_PAINTER}.Role_mono, t.size_label, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + bar_w + 10.0, y + height - 5.0, cap)
			end
		end

invariant
	fraction_bounded: fraction >= 0.0 and fraction <= 1.0

end
