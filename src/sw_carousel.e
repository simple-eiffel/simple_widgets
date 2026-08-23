note
	description: "[
		Wave 6 opens - media: the carousel. Image paths become
		SW_IMAGE organs; one shows at a time, arrows and edge
		clicks page it, dots name the count and jump directly,
		and the paging MODEL (next / previous wrap around, go_to
		clamps, dot_at slot math) is public and assaulted without
		a single file existing - missing images draw as quiet
		frames, honestly.
	]"

class
	SW_CAROUSEL

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
			create images.make (6)
			current_index := 1
		end

feature -- Access

	images: ARRAYED_LIST [SW_IMAGE]

	current_index: INTEGER

	count: INTEGER
		do
			Result := images.count
		end

	Dot_zone_h: REAL_64 = 22.0

	dot_at (a_px: REAL_64): INTEGER
			-- Which dot sits under a surface x; 0 between and beyond.
		local
			total_w, start_x: REAL_64
			slot: INTEGER
		do
			if count > 0 then
				total_w := count * 16.0
				start_x := x + width / 2.0 - total_w / 2.0
				if a_px >= start_x and then a_px < start_x + total_w then
					slot := ((a_px - start_x) / 16.0).truncated_to_integer + 1
					Result := slot.min (count)
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

	next
			-- Forward, wrapping past the end.
		require
			aboard: count > 0
		do
			current_index := current_index \\ count + 1
		ensure
			in_range: current_index >= 1 and current_index <= count
		end

	previous
			-- Back, wrapping past the start.
		require
			aboard: count > 0
		do
			if current_index = 1 then
				current_index := count
			else
				current_index := current_index - 1
			end
		ensure
			in_range: current_index >= 1 and current_index <= count
		end

	go_to (a_index: INTEGER)
		require
			aboard: count > 0
		do
			current_index := a_index.max (1).min (count)
		ensure
			in_range: current_index >= 1 and current_index <= count
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 220.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			dx0: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if count > 0 then
				images.i_th (current_index).set_bounds
					(x + 30.0, y + 6.0, (width - 60.0).max (10.0),
					(height - Dot_zone_h - 12.0).max (10.0))
				images.i_th (current_index).draw (a_p)
					-- edge chevrons
				a_p.font ({SW_PAINTER}.Role_ui, 20.0, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 9.0, y + height / 2.0 + 7.0, {STRING_32} "%/8249/")
				a_p.text (x + width - 21.0, y + height / 2.0 + 7.0, {STRING_32} "%/8250/")
					-- the dots
				dx0 := x + width / 2.0 - count * 16.0 / 2.0
				from
					i := 1
				until
					i > count
				loop
					if i = current_index then
						a_p.set_color (t.accent)
						a_p.circle_fill (dx0 + (i - 1) * 16.0 + 8.0, y + height - 11.0, 4.0)
					else
						a_p.set_color (t.outline)
						a_p.circle_fill (dx0 + (i - 1) * 16.0 + 8.0, y + height - 11.0, 3.0)
					end
					i := i + 1
				end
			else
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 12.0, y + height / 2.0, {STRING_32} "no images yet")
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			d: INTEGER
		do
			if is_enabled and then count > 0 then
				d := dot_at (a_px)
				if a_py >= y + height - Dot_zone_h and then d > 0 then
					go_to (d)
				elseif a_px < x + width * 0.25 then
					previous
				elseif a_px > x + width * 0.75 then
					next
				end
				Result := True
			end
		end

invariant
	images_attached: images /= Void
	index_held: count > 0 implies (current_index >= 1 and current_index <= count)

end
