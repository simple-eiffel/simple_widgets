note
	description: "[
		A slider: track, filled portion, draggable knob; horizontal, or vertical with the
		start at the bottom. The fraction is contract-bounded to [0, 1]; the change agent
		fires on every move with the new fraction. It takes the keyboard focus: the arrows
		move it by `key_step', Page Up and Page Down by ten of those, Home and End to the ends.
	]"

class
	SW_SLIDER

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag, handle_wheel, handle_key, wants_hover_point,
			accepts_focus, preferred_width, accessible_role, accessible_value
		end

create
	make

feature {NONE} -- Initialization

	make (a_fraction: REAL_64; a_on_change: detachable PROCEDURE [REAL_64])
		require
			in_range: a_fraction >= 0.0 and a_fraction <= 1.0
		do
			fraction := a_fraction
			on_change := a_on_change
			key_step := 0.01
		ensure
			kept: fraction = a_fraction
			horizontal: not is_vertical
		end

feature -- Access

	fraction: REAL_64

	is_vertical: BOOLEAN
			-- Drawn and dragged up and down, the start (0) at the bottom?

	key_step: REAL_64
			-- How far one arrow key moves the knob.

	tick_count: INTEGER
			-- Number of intervals marked; 0 = no ticks.

	snaps_to_ticks: BOOLEAN

	set_ticks (a_count: INTEGER; a_snap: BOOLEAN)
		require
			sane: a_count >= 0
		do
			tick_count := a_count
			snaps_to_ticks := a_snap
		ensure
			kept: tick_count = a_count and snaps_to_ticks = a_snap
		end

	snapped (a_fraction: REAL_64): REAL_64
			-- The nearest tick fraction when snapping; else as given.
		require
			unit: a_fraction >= 0.0 and a_fraction <= 1.0
		do
			if snaps_to_ticks and then tick_count > 0 then
				Result := ((a_fraction * tick_count) + 0.5).floor / tick_count
				Result := Result.max (0.0).min (1.0)
			else
				Result := a_fraction
			end
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

	on_change: detachable PROCEDURE [REAL_64]

feature -- Element change

	set_fraction (a_fraction: REAL_64)
		require
			in_range: a_fraction >= 0.0 and a_fraction <= 1.0
		do
			fraction := a_fraction
		ensure
			set: fraction = a_fraction
		end

	set_vertical (a_vertical: BOOLEAN)
		do
			is_vertical := a_vertical
		ensure
			set: is_vertical = a_vertical
		end

	set_key_step (a_step: REAL_64)
		require
			in_unit: a_step > 0.0 and a_step <= 1.0
		do
			key_step := a_step
		ensure
			set: key_step = a_step
		end

	set_on_change (a_action: PROCEDURE [REAL_64])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	Knob_r: REAL_64 = 9.0

	Thickness: REAL_64 = 30.0
			-- Across the track.

	Vertical_length: REAL_64 = 160.0
			-- A vertical slider's natural height.

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			if is_vertical then
				Result := Thickness
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			if is_vertical then
				Result := Vertical_length
			else
				Result := Thickness
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			c, l_start, l_len, k_pos: REAL_64
		do
			t := a_p.theme
			if is_vertical then
				c := x + width / 2.0
				l_start := y + height - Knob_r
				l_len := (height - 2.0 * Knob_r).max (0.0)
			else
				c := y + height / 2.0
				l_start := x + Knob_r
				l_len := (width - 2.0 * Knob_r).max (0.0)
			end
			a_p.set_color (t.outline)
			track (a_p, l_start, c, l_len)
			if tick_count > 0 then
				across
					0 |..| tick_count as k
				loop
					if is_vertical then
						a_p.hline (c + 5.0, l_start - l_len * k / tick_count, 5.0)
					else
						a_p.vline (l_start + l_len * k / tick_count, c + 5.0, 5.0)
					end
				end
			end
			if is_enabled then
				a_p.set_color (t.accent)
			else
				a_p.set_color (t.ink_muted)
			end
			if fraction > 0.0 then
				track (a_p, l_start, c, l_len * fraction)
			end
			if is_vertical then
				k_pos := l_start - l_len * fraction
				knob (a_p, c, k_pos, t)
			else
				k_pos := l_start + l_len * fraction
				knob (a_p, k_pos, c, t)
			end
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				move_to (a_px, a_py)
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if is_enabled then
				move_to (a_px, a_py)
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			if is_enabled then
				set_fraction ((fraction + a_delta / 120.0 * 0.05).max (0.0).min (1.0))
				notify
				Result := True
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Left and Down lower it, Right and Up raise it; Page Down and Page Up by ten
			-- steps; Home to the start, End to the end.
		local
			l_to: REAL_64
		do
			if is_enabled then
				l_to := fraction
				inspect a_vk
				when 37, 40 then
					l_to := fraction - key_step
				when 39, 38 then
					l_to := fraction + key_step
				when 34 then
					l_to := fraction - 10.0 * key_step
				when 33 then
					l_to := fraction + 10.0 * key_step
				when 36 then
					l_to := 0.0
				when 35 then
					l_to := 1.0
				else
				end
				l_to := l_to.max (0.0).min (1.0)
				if l_to /= fraction then
					set_fraction (l_to)
					notify
				end
			end
		end

feature {NONE} -- Implementation

	track (a_p: SW_PAINTER; a_start, a_center, a_len: REAL_64)
			-- The track from `a_start' for `a_len' (upward when vertical), centered across on `a_center'.
		do
			if is_vertical then
				a_p.rrect_fill (a_center - 2.5, a_start - a_len, 5.0, a_len, 2.5)
			else
				a_p.rrect_fill (a_start, a_center - 2.5, a_len, 5.0, 2.5)
			end
		end

	knob (a_p: SW_PAINTER; a_kx, a_ky: REAL_64; t: SW_THEME)
		do
			a_p.circle_fill (a_kx, a_ky, Knob_r - (if shows_hover or is_pressed or is_focused then 0.0 else 2.0 end))
			a_p.set_color (t.surface)
			a_p.circle_fill (a_kx, a_ky, 3.0)
		end

	move_to (a_px, a_py: REAL_64)
		do
			if is_vertical then
				if height > 2.0 * Knob_r then
					set_fraction (snapped (((y + height - Knob_r - a_py) / (height - 2.0 * Knob_r)).max (0.0).min (1.0)))
					notify
				end
			elseif width > 2.0 * Knob_r then
				set_fraction (snapped (((a_px - x - Knob_r) / (width - 2.0 * Knob_r)).max (0.0).min (1.0)))
				notify
			end
		end

	notify
		do
			if attached on_change as a then
				a.call (fraction)
			end
		end


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_slider
		end

	accessible_value: detachable STRING_32
		do
			create Result.make (5)
			Result.append_integer ((fraction * 100.0).rounded)
			Result.append_character ('%%')
		end

invariant
	fraction_bounded: fraction >= 0.0 and fraction <= 1.0
	key_step_in_unit: key_step > 0.0 and key_step <= 1.0

end
