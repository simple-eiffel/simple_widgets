note
	description: "[
		Wave 6 media: the gallery - thumbnails flowing into as many
		columns as the width allows, a selection ring, and on_pick
		firing the index. The flow arithmetic (columns_now, cell_at,
		rows_needed) is public and assaulted; missing files draw as
		quiet frames.
	]"

class
	SW_GALLERY

inherit
	SW_WIDGET
		redefine
			handle_click
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create images.make (8)
			selected_index := 0
		end

feature -- Access

	images: ARRAYED_LIST [SW_IMAGE]

	selected_index: INTEGER

	on_pick: detachable PROCEDURE [INTEGER]

	Thumb_w: REAL_64 = 116.0

	Thumb_h: REAL_64 = 84.0

	Gap: REAL_64 = 8.0

	count: INTEGER
		do
			Result := images.count
		end

	columns_now: INTEGER
			-- How many thumbnails fit a row at the current width.
		do
			Result := ((width - Gap) / (Thumb_w + Gap)).truncated_to_integer.max (1)
		ensure
			positive: Result >= 1
		end

	rows_needed: INTEGER
		do
			if count > 0 then
				Result := (count + columns_now - 1) // columns_now
			end
		ensure
			non_negative: Result >= 0
		end

	cell_at (a_px, a_py: REAL_64): INTEGER
			-- The thumbnail under a surface point; 0 in the gaps
			-- and beyond the last.
		local
			c, r: INTEGER
			lx, ly: REAL_64
		do
			lx := a_px - x - Gap
			ly := a_py - y - Gap
			if lx >= 0.0 and ly >= 0.0 then
				c := (lx / (Thumb_w + Gap)).truncated_to_integer
				r := (ly / (Thumb_h + Gap)).truncated_to_integer
				if c < columns_now
					and then lx - c * (Thumb_w + Gap) <= Thumb_w
					and then ly - r * (Thumb_h + Gap) <= Thumb_h
				then
					Result := r * columns_now + c + 1
					if Result > count then
						Result := 0
					end
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

feature -- Element change

	add_image (a_path: READABLE_STRING_GENERAL)
		do
			images.extend (create {SW_IMAGE}.make_from_file (a_path))
		ensure
			grew: count = old count + 1
		end

	set_on_pick (a_action: PROCEDURE [INTEGER])
		do
			on_pick := a_action
		ensure
			set: on_pick = a_action
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Gap + rows_needed.max (1) * (Thumb_h + Gap)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, c, r: INTEGER
			cx, cy: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			from
				i := 1
			until
				i > count
			loop
				c := (i - 1) \\ columns_now
				r := (i - 1) // columns_now
				cx := x + Gap + c * (Thumb_w + Gap)
				cy := y + Gap + r * (Thumb_h + Gap)
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (cx, cy, Thumb_w, Thumb_h, 3.0)
				images.i_th (i).set_bounds (cx + 2.0, cy + 2.0, Thumb_w - 4.0, Thumb_h - 4.0)
				images.i_th (i).draw (a_p)
				if i = selected_index then
					a_p.set_color (t.accent)
					a_p.rrect_stroke (cx - 0.5, cy - 0.5, Thumb_w + 1.0, Thumb_h + 1.0, 4.0)
				end
				i := i + 1
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			k: INTEGER
		do
			if is_enabled then
				k := cell_at (a_px, a_py)
				if k > 0 then
					selected_index := k
					if attached on_pick as a then
						a.call (k)
					end
				end
				Result := True
			end
		end

invariant
	images_attached: images /= Void

end
