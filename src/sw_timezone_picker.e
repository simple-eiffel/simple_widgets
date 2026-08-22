note
	description: "[
		Larry's idea, kept: the pickable timezone map. The coarse
		world with clicking - a click reads its longitude, rounds to
		the nearest 15-degree band, highlights it and fires
		on_change with the UTC offset. The band arithmetic
		(offset_at) is public and assaulted; the selection caption
		names itself. Bands are nominal meridians: political zone
		law (and DST) is deliberately not computed here - pair with
		SW_WORLD_CLOCK, whose offsets are yours to supply.
	]"

class
	SW_TIMEZONE_PICKER

inherit
	SW_MAP
		redefine
			draw, handle_click
		end

create
	make

feature -- Access

	selected_offset: INTEGER
			-- The picked UTC offset in hours; meaningful when
			-- has_zone (picking always sets both).

	on_change: detachable PROCEDURE [INTEGER]
			-- Fired with the offset when a band is picked.

	offset_at (a_px: REAL_64): INTEGER
			-- The UTC hour band under a surface x: longitude rounded
			-- to the nearest 15 degrees, clamped to -12 .. 12.
		do
			Result := (lon_at_x (a_px) / 15.0).rounded.max (-12).min (12)
		ensure
			banded: Result >= -12 and Result <= 12
		end

feature -- Element change

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled and then a_px >= plot_x and then a_px <= plot_x + plot_w
				and then a_py >= plot_y and then a_py <= plot_y + plot_h
			then
				selected_offset := offset_at (a_px)
				highlight_utc (selected_offset)
				if attached on_change as a then
					a.call (selected_offset)
				end
				Result := True
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			cap: STRING_32
		do
			Precursor (a_p)
			if has_zone then
				create cap.make (12)
				cap.append ({STRING_32} "UTC")
				if selected_offset >= 0 then
					cap.append_character ('+')
				end
				cap.append_string_general (selected_offset.out)
				a_p.font ({SW_PAINTER}.Role_mono, 12.0, True)
				a_p.set_color (a_p.theme.surface_variant)
				a_p.rrect_fill (x + width - a_p.advance (cap) - 26.0, y + height - 24.0,
					a_p.advance (cap) + 12.0, 17.0, 3.0)
				a_p.set_color (a_p.theme.accent)
				a_p.text (x + width - a_p.advance (cap) - 20.0, y + height - 11.0, cap)
			end
		end

end
