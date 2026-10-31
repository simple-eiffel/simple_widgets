note
	description: "[
		A horizontal scrollbar (0.49.0): SW_SCROLLBAR's arithmetic along x,
		standing across the bottom of the box its owner gives it. First owner:
		SW_LANE_TIMELINE's bar across time, which feeds it the bent coordinate
		under the lens so deep time and a king's reign both get room.
	]"
	author: "Larry Rix"

class
	SW_HSCROLLBAR

inherit
	SW_SCROLLBAR
		rename
			track_start as track_x,
			track_length as track_w,
			thumb_length as thumb_width,
			thumb_start as thumb_left
		end

create
	make

feature -- Geometry

	track_y: REAL_64
			-- The bar's top edge.

	contains (a_px, a_py: REAL_64): BOOLEAN
			-- Is (`a_px', `a_py') on the bar's row, while it is needed?
		do
			Result := is_needed and then a_py >= track_y and then a_py < track_y + bar_width
				and then a_px >= track_x - Track_inset * scale
				and then a_px <= track_x + track_w + Track_inset * scale
		end

feature -- Placement

	place (a_x, a_y, a_width, a_height: REAL_64; a_theme: SW_THEME)
			-- The bar across the middle of the box `a_x', `a_y', `a_width' x `a_height', sized by
			-- `a_theme'.
		do
			scale := a_theme.text_scale
			bar_width := a_theme.scrollbar_width
			min_thumb := a_theme.min_thumb
			track_x := a_x + Track_inset * scale
			track_w := (a_width - 2.0 * Track_inset * scale).max (1.0)
			track_y := a_y + ((a_height - bar_width) / 2.0).max (0.0)
		ensure then
			across_the_box: track_x = a_x + Track_inset * scale
		end

feature -- Drawing

	draw (a_p: SW_PAINTER; a_scroll: REAL_64; a_hot: BOOLEAN)
			-- The track and the thumb for `a_scroll', when needed; the thumb in the accent while held
			-- or `a_hot' (pointer on it).
		local
			t: SW_THEME
		do
			if is_needed then
				t := a_p.theme
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (track_x, track_y, track_w, bar_width - 2.0 * scale, 4.0 * scale)
				if is_dragging or a_hot then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (thumb_left (a_scroll), track_y + 1.5 * scale, thumb_width,
					bar_width - 5.0 * scale, 3.0 * scale)
			end
		end

end
