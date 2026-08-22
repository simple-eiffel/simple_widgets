note
	description: "[
		A horizontal slider: track, filled portion, draggable knob.
		The fraction is contract-bounded to [0, 1]; the change agent
		fires on every move with the new fraction.
	]"

class
	SW_SLIDER

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag, handle_wheel, wants_hover_point
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
		ensure
			kept: fraction = a_fraction
		end

feature -- Access

	fraction: REAL_64

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

	set_on_change (a_action: PROCEDURE [REAL_64])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	Knob_r: REAL_64 = 9.0

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 30.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cy, kx: REAL_64
		do
			t := a_p.theme
			cy := y + height / 2.0
			a_p.set_color (t.outline)
			a_p.rrect_fill (x + Knob_r, cy - 2.5, width - 2.0 * Knob_r, 5.0, 2.5)
			if fraction > 0.0 then
				if is_enabled then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.rrect_fill (x + Knob_r, cy - 2.5, (width - 2.0 * Knob_r) * fraction, 5.0, 2.5)
			end
			kx := x + Knob_r + (width - 2.0 * Knob_r) * fraction
			if is_enabled then
				a_p.set_color (t.accent)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.context.arc (kx, cy, Knob_r - (if shows_hover or is_pressed then 0.0 else 2.0 end), 0.0, 6.2832).do_nothing
			a_p.context.fill.do_nothing
			a_p.set_color (t.surface)
			a_p.context.arc (kx, cy, 3.0, 0.0, 6.2832).do_nothing
			a_p.context.fill.do_nothing
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				move_to (a_px)
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if is_enabled then
				move_to (a_px)
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

feature {NONE} -- Implementation

	move_to (a_px: REAL_64)
		do
			if width > 2.0 * Knob_r then
				set_fraction (((a_px - x - Knob_r) / (width - 2.0 * Knob_r)).max (0.0).min (1.0))
				notify
			end
		end

	notify
		do
			if attached on_change as a then
				a.call (fraction)
			end
		end

invariant
	fraction_bounded: fraction >= 0.0 and fraction <= 1.0

end
