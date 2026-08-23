note
	description: "[
		Stars out of five (or any max): click the k-th star to rate
		k, click the current rating again to clear to zero. Hover
		previews the would-be rating in accent.
	]"

class
	SW_RATING

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make (a_value, a_max: INTEGER; a_on_change: detachable PROCEDURE [INTEGER])
		require
			sane_max: a_max >= 1
			in_range: a_value >= 0 and a_value <= a_max
		do
			max_stars := a_max
			value := a_value
			on_change := a_on_change
		ensure
			kept: value = a_value and max_stars = a_max
		end

feature -- Access

	value: INTEGER

	is_read_only: BOOLEAN
			-- Display-only mode: clicks are inert.

	display_value: REAL_64
			-- When read-only and non-zero, HALF-star precision
			-- display (4.5 draws four and a half stars).

	caption: detachable STRING_32
			-- Optional trailing text ('4.2 (128)').

	set_read_only (a_read_only: BOOLEAN)
		do
			is_read_only := a_read_only
		ensure
			set: is_read_only = a_read_only
		end

	set_display_value (a_value: REAL_64)
		require
			sane: a_value >= 0.0
		do
			display_value := a_value
		ensure
			set: display_value = a_value
		end

	set_caption (a_text: READABLE_STRING_GENERAL)
		do
			create caption.make_from_string_general (a_text)
		end

	max_stars: INTEGER

	on_change: detachable PROCEDURE [INTEGER]

	Star_step: REAL_64 = 26.0

feature -- Element change

	set_value (a_v: INTEGER)
		require
			in_range: a_v >= 0 and a_v <= max_stars
		do
			value := a_v
		ensure
			set: value = a_v
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

	star_at (a_px: REAL_64): INTEGER
			-- Which star the point is over; 0 left of the first,
			-- clamped to max on the right.
		do
			if a_px >= x then
				Result := (((a_px - x) / Star_step).truncated_to_integer + 1).min (max_stars)
			end
		ensure
			in_range: Result >= 0 and Result <= max_stars
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			Result := max_stars * Star_step
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 28.0
		end

feature -- Drawing

	shown_stars: REAL_64
			-- What the stars display: the live value, or the half-
			-- precision display_value in read-only mode.
		do
			if is_read_only and then display_value > 0.0 then
				Result := display_value.min (max_stars.to_double)
			else
				Result := value.to_double
			end
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			cx, cy: REAL_64
		do
			t := a_p.theme
			cy := y + height / 2.0
			if shows_hover then
				hot := star_at (hover_px)
			end
			from
				i := 1
			until
				i > max_stars
			loop
				cx := x + (i - 1) * Star_step + Star_step / 2.0
				if not is_read_only and then hot > 0 and then i <= hot then
					a_p.set_color (t.accent)
					a_p.star_fill (cx, cy, 11.0)
				elseif shown_stars >= i.to_double then
					a_p.set_color (t.warning)
					a_p.star_fill (cx, cy, 11.0)
				elseif shown_stars >= i.to_double - 0.5 then
						-- the half: a filled star clipped to its left half
					a_p.set_color (t.outline)
					a_p.star_stroke (cx, cy, 10.0)
					a_p.push_clip (cx - 12.0, cy - 12.0, 12.0, 24.0)
					a_p.set_color (t.warning)
					a_p.star_fill (cx, cy, 11.0)
					a_p.pop_clip
				else
					a_p.set_color (t.outline)
					a_p.star_stroke (cx, cy, 10.0)
				end
				i := i + 1
			end
			if attached caption as cap then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + max_stars * Star_step + 8.0, cy + 5.0, cap)
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			k: INTEGER
		do
			if is_enabled and then not is_read_only then
				k := star_at (a_px)
				if k > 0 then
					if k = value then
						value := 0
					else
						value := k
					end
					if attached on_change as a then
						a.call (value)
					end
				end
				Result := True
			end
		end

invariant
	max_sane: max_stars >= 1
	value_in_range: value >= 0 and value <= max_stars

end
